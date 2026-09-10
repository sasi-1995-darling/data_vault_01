import logging
import traceback
import yaml
import re
from pathlib import Path
from make_yml import make_yml
from sheets import get_source_sql, get_config
from config import determine_subdir

logger = logging.getLogger(__name__)


# ── Ghost-row sentinel map ───────────────────────────────────────────────────
# Used by `generate_union_all_block` to fill NOT NULL payload columns on a
# satellite ghost row (otherwise the ghost row violates the model's own
# not_null test) and to defensively populate HK/BK columns on hub/link ghost
# rows when the XLSX GHOST RECORD directive was left blank.
#
# Matches the convention used elsewhere in the generator:
#   - text → 'GHOST RECORD'   (mirrors the BKCC DECODE strings)
#   - numeric → 0              (smallest non-null sentinel that survives any cast)
#   - date/timestamp → '1900-01-01' (matches LOAD_DTS ghost convention)
#   - boolean → FALSE
#   - binary → TO_BINARY('00')

_GHOST_TEXT_FAMILY = frozenset({
    "VARCHAR", "TEXT", "STRING", "CHAR", "CHARACTER",
})
_GHOST_NUMERIC_FAMILY = frozenset({
    "NUMBER", "NUMERIC", "DECIMAL", "DEC",
    "INT", "INTEGER", "BIGINT", "SMALLINT", "TINYINT", "BYTEINT",
    "FLOAT", "FLOAT4", "FLOAT8", "DOUBLE", "DOUBLE PRECISION", "REAL",
})
_GHOST_DATE_FAMILY = frozenset({"DATE"})
_GHOST_TIMESTAMP_NTZ_FAMILY = frozenset({"TIMESTAMP", "TIMESTAMP_NTZ", "DATETIME"})
_GHOST_TIMESTAMP_TZ_FAMILY = frozenset({"TIMESTAMP_TZ", "TIMESTAMP_LTZ"})
_GHOST_BOOLEAN_FAMILY = frozenset({"BOOLEAN", "BOOL"})
_GHOST_BINARY_FAMILY = frozenset({"BINARY", "VARBINARY"})


def _ghost_sentinel_for_datatype(datatype):
    """Return a non-null SQL expression appropriate for `datatype`.

    Returns None if the datatype is unknown — the caller is expected to fall
    back to a STRING sentinel and emit a warning.

    The returned expression is type-matched to `datatype` so Snowflake won't
    widen ghost rows. The mechanism varies by family:
      - TEXT, NUMERIC, DATE, TIMESTAMP_NTZ, TIMESTAMP_TZ → explicit `::<type>`
        cast on a literal (e.g. ``'GHOST RECORD'::VARCHAR(100)``).
      - BOOLEAN → bare literal ``FALSE`` (Snowflake parses this as boolean,
        no cast required).
      - BINARY → typed constructor ``TO_BINARY('00')`` (returns BINARY).
    Callers that need a uniformly cast expression should wrap the result.
    """
    if not datatype:
        return None
    raw = str(datatype).strip()
    if not raw:
        return None
    base = re.sub(r"\s*\(.*\)\s*$", "", raw).upper()
    if base in _GHOST_TEXT_FAMILY:
        return f"'GHOST RECORD'::{raw}"
    if base in _GHOST_NUMERIC_FAMILY:
        return f"0::{raw}"
    if base in _GHOST_DATE_FAMILY:
        return "'1900-01-01'::DATE"
    if base in _GHOST_TIMESTAMP_NTZ_FAMILY:
        return f"'1900-01-01'::{raw}"
    if base in _GHOST_TIMESTAMP_TZ_FAMILY:
        return f"CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP_NTZ)::{raw}"
    if base in _GHOST_BOOLEAN_FAMILY:
        return "FALSE"
    if base in _GHOST_BINARY_FAMILY:
        return "TO_BINARY('00')"
    return None


def _is_numeric_datatype(datatype):
    """True if `datatype` is in the numeric family (used for hub BK ghost
    selection between GR.VALUE::number and GR.VALUE::text)."""
    if not datatype:
        return False
    base = re.sub(r"\s*\(.*\)\s*$", "", str(datatype).strip()).upper()
    return base in _GHOST_NUMERIC_FAMILY


def _coldata_get(col_data, header):
    """Case-insensitive lookup on a column row dict for the given HEADER."""
    upper = header.upper()
    for k in col_data.keys():
        if k and k.upper() == upper:
            return col_data.get(k)
    return None


# Cache for source name resolution (schema -> dbt source name)
_source_name_cache = {}

def _resolve_source_name(physical_schema: str, rootdir=None) -> str:
    """Resolve a physical schema name to its dbt source name.

    Resolution order (lesson #97):
      1. If physical_schema matches a source NAME directly -> return it (common case)
      2. If physical_schema matches a source's schema: override -> return that source's name
      3. If no match -> return physical_schema as-is (new/unregistered source)

    Args:
        physical_schema: The physical Snowflake schema name.
        rootdir: Project root directory (Path). Uses cwd() if not provided.
    """
    if physical_schema in _source_name_cache:
        return _source_name_cache[physical_schema]

    # Locate dbt project root: walk up from rootdir (or cwd) until dbt_project.yml found
    start = Path(rootdir).resolve() if rootdir else Path.cwd().resolve()
    project_root = None
    current = start
    for _ in range(10):  # Max 10 levels up
        if (current / "dbt_project.yml").exists():
            project_root = current
            break
        parent = current.parent
        if parent == current:
            break
        current = parent

    if project_root is None:
        logger.warning(
            f"dbt_project.yml not found walking up from {start}; "
            f"using '{physical_schema.lower()}' as source name"
        )
        _source_name_cache[physical_schema] = physical_schema.lower()
        return physical_schema.lower()

    sources_path = project_root / "models" / "sources" / "_sources_staging_psa.yml"
    if not sources_path.exists():
        logger.warning(f"Sources file not found: {sources_path}; using physical schema as source name")
        _source_name_cache[physical_schema] = physical_schema.lower()
        return physical_schema.lower()

    try:
        with open(sources_path) as f:
            data = yaml.safe_load(f) or {}
    except Exception as e:
        logger.warning(f"Failed to parse sources YAML: {e}; using physical schema as source name")
        _source_name_cache[physical_schema] = physical_schema.lower()
        return physical_schema.lower()

    sources_list = data.get("sources", [])
    schema_lower = physical_schema.lower()

    # Step 1: Check if physical_schema matches a source name directly
    for src in sources_list:
        if (src.get("name") or "").lower() == schema_lower:
            _source_name_cache[physical_schema] = src["name"]
            return src["name"]

    # Step 2: Check if physical_schema matches any source's schema: override
    for src in sources_list:
        if (src.get("schema") or "").lower() == schema_lower:
            resolved = src["name"]
            logger.info(f"Resolved source name: '{physical_schema}' -> '{resolved}' (via schema: override)")
            _source_name_cache[physical_schema] = resolved
            return resolved

    # Step 3: No match -> use physical_schema lowercased (dbt convention)
    _source_name_cache[physical_schema] = physical_schema.lower()
    return physical_schema.lower()


def build(args, modeldir, table_name, tables, columns, wb=None, large_volume=False, bkcc_rec_src=None):
    logger.debug('FUNCTION: build')
    logging.info(f'-- Building {table_name} ...')

    try:
        # Access the first table entry to get the derived name and target schema
        first_table_entry = next(iter(tables.values()))[0]
        derived_name = first_table_entry['DERIVED_NAME']
        target_schema = (first_table_entry.get('TARGET SCHEMA') or 'default_schema').replace(' ', '_').lower()
        model_config = first_table_entry.get('MODEL CONFIG', '')
        output_name = derived_name.replace(' ', '_').lower()
        print(f"Building {output_name} ...")

        # Auto-detect large_volume from MODEL CONFIG if not explicitly passed
        if not large_volume and model_config:
            large_volume = 'large_volume' in str(model_config).lower()
            if large_volume:
                logger.info(f"Auto-detected large_volume from MODEL CONFIG for {table_name}")

        yml = make_yml(table_name, tables, columns)
        all_sql = []

        current_layer = table_name.split('_')[0]
        is_hub = table_name.startswith('HUB_')
        is_link = table_name.startswith(('LNK_', 'LINK_', 'TLINK_'))
        # Hub/link watermark: triggered by QUALIFY ORDER BY in Tables tab
        # (volume ≥50M) OR by large_volume flag (≥150M legacy path).
        qualify_order_by = (first_table_entry.get('QUALIFY ORDER BY') or '').strip()
        use_watermark = (large_volume or (qualify_order_by and is_hub)) and (is_hub or is_link)
        columns = get_source_sql(table_name, columns, tables)

        # For large volume hubs, use INCR_WATERMARK pattern with conditional WITH block
        if use_watermark:
            watermark_days = 3 if is_hub else 1
            all_sql.append(f"""---- SRC LAYER ----
{{% if is_incremental() %}}
WITH INCR_WATERMARK AS (
    SELECT REC_SRC as wm_REC_SRC,
           DATEADD(DAY, -{watermark_days}, MAX(LOAD_DTS)) AS watermark_dts
    FROM {{{{ this }}}}
    GROUP BY REC_SRC
),
{{% else %}}
WITH
{{% endif %}}""")
        else:
            all_sql.append('---- SRC LAYER ----\nWITH')
        src_sql = build_src_layer(args, tables, current_layer, table_name=table_name, columns=columns, large_volume=use_watermark, bkcc_rec_src=bkcc_rec_src)
        all_sql.append(src_sql)

        all_sql.append('---- LOGIC LAYER ----')
        logic_sql = build_logic_layer(columns, tables, current_layer)
        all_sql.append(logic_sql)

        join_sql, base_join_alias = build_join_layer(tables, columns, current_layer, bkcc_rec_src=bkcc_rec_src)
        all_sql.append(join_sql)

        final_sql = build_final_layer(tables, columns, current_layer, base_join_alias)
        all_sql.append(final_sql)

        sql_str = '\n'.join(all_sql)

        # Append union all code block for specific prefixes
        if table_name.startswith(('SAT_', 'HUB_', 'LSAT_', 'MSAT_', 'ESAT_', 'LMSAT_', 'LNK_', 'LINK_', 'TLINK_')):
            union_all_block = generate_union_all_block(columns, table_name)
            sql_str += union_all_block

        subdir = determine_subdir(output_name, target_schema)
        modeldir = modeldir / subdir

        # Create the directory if it does not exist
        modeldir.mkdir(parents=True, exist_ok=True)

        yml_file = modeldir / (output_name + '.yml')
        sql_file = modeldir / (output_name + '.sql')

        # Only write files if no exception occurred
        with open(yml_file, 'w') as fw:
            yaml.dump(yml, fw, sort_keys=False)
            logging.info(f'-- Created YAML file: {yml_file}')

        with open(sql_file, 'w') as fw:
            # Write config() block only when MODEL CONFIG is non-empty.
            # Tags-only hubs (50-150M) have empty MODEL CONFIG — tags go in YAML.
            if model_config:
                fw.write(f"{{{{ config({model_config}) }}}}\n")
                if use_watermark:
                    fw.write("\n")  # Extra blank line after config for watermark models
            # Large volume v_psa_stg views: header comment only (views don't use config())
            if large_volume and current_layer == 'STG':
                fw.write("-- LARGE VOLUME (>300M rows): Downstream hub/sat should use INCR_WATERMARK, full_refresh = var(\"force_full_refresh\", false), tags=['large_volume']\n\n")
            fw.write(sql_str)
            logging.info(f'-- Created SQL file: {sql_file}')

    except Exception as e:
        logging.error(f'-- Error building {table_name}: {str(e)}')
        traceback.print_exc()
        # Abort further processing for this model
        raise

    logging.info(f'-- Finished building {table_name}')


def extract_pk_columns_from_existing_logic(columns):
    """
    Use the same PK extraction logic that successfully works for test generation.
    This mirrors the logic in tests.py that correctly generates the YAML constraints.
    """
    pk_columns = []
    # Mirror the logic from tests.py get_model_tests()
    for row in columns.values():
        if 'PK' in row and row['PK']:
            pk_value = row['PK']
            # If PK is a dict with column_names, extract those
            if isinstance(pk_value, dict):
                if 'dbt_constraints.primary_key' in pk_value and 'column_names' in pk_value['dbt_constraints.primary_key']:
                    pk_columns = pk_value['dbt_constraints.primary_key']['column_names']
                elif 'column_names' in pk_value:
                    pk_columns = pk_value['column_names']
                else:
                    pk_columns = [str(v) for v in pk_value.values()]
                pk_columns_filtered = list(dict.fromkeys(  # dedup preserving order
                    col for col in pk_columns if col and col.upper() not in ('LOAD_DTS',)
                ))
                return pk_columns_filtered
            if ':' in str(pk_value):
                test = str(pk_value).replace('PK:', '').strip()
                pk_columns = [each.strip() for each in test.split(',')]
                pk_columns_filtered = list(dict.fromkeys(  # dedup preserving order
                    col for col in pk_columns if col and col.upper() not in ('LOAD_DTS',)
                ))
                return pk_columns_filtered
            else:
                if pk_value and isinstance(pk_value, str):
                    pk_columns = [each.strip() for each in str(pk_value).split(',')]
                    pk_columns_filtered = list(dict.fromkeys(  # dedup preserving order
                        col for col in pk_columns if col and col.upper() not in ('LOAD_DTS',)
                    ))
                    if pk_columns_filtered:
                        return pk_columns_filtered
    return []


def extract_bk_columns_for_hub_qualify(columns):
    """Extract BK columns for hub SRC QUALIFY (partitions by BK+BKCC, not HK).

    HK is a derived column that doesn't exist in the SRC CTE, so we partition
    by the individual BK columns (ghost_record=value_text) plus BKCC.
    """
    bk_cols = []
    for row in columns.values():
        if not isinstance(row, dict):
            continue
        ghost_key = next((k for k in row.keys() if k and k.upper() == 'GHOST RECORD'), None)
        staging_key = next((k for k in row.keys() if k and k.upper() == 'STAGING LAYER COLUMN NAME'), None)
        if not ghost_key or not staging_key:
            continue
        ghost_val = str(row.get(ghost_key, '')).strip().lower()
        staging_name = (row.get(staging_key) or '').upper()
        if ghost_val in ('value_text', 'value_number', 'bkcc') and staging_name:
            bk_cols.append(staging_name)
    return bk_cols


def generate_union_all_block(columns, table_name):
    """
    Generate union all block using the same PK logic that works for tests.
    """
    logger.debug('FUNCTION: generate_union_all_block')
    
    # Check if any columns have Ghost Record values
    has_ghost_records = False
    for _, col_data in columns.items():
        if isinstance(col_data, dict):
            ghost_record_key = next((k for k in col_data.keys() if k and k.upper() == 'GHOST RECORD'), None)
            if ghost_record_key and col_data.get(ghost_record_key):
                has_ghost_records = True
                break
    
    if not has_ghost_records:
        logger.info('No Ghost Record columns found. Skipping union_all_block generation.')
        return ""
    
    # Use the same PK extraction logic that works for tests
    pk_columns = extract_pk_columns_from_existing_logic(columns)
    
    # Add HASHDIFF for satellite tables (with variant-specific guardrails)
    is_satellite = table_name.startswith(('SAT_', 'LSAT_', 'MSAT_', 'ESAT_', 'LMSAT_'))
    is_esat = table_name.startswith('ESAT_')
    is_msat = table_name.startswith(('MSAT_', 'LMSAT_'))
    is_lsat = table_name.startswith(('LSAT_', 'LMSAT_'))

    if is_satellite:
        # Check if HASHDIFF (or named variant HASHDIFF_*) exists in the columns
        hashdiff_exists = False
        hashdiff_col_name = 'HASHDIFF'  # default; may be overridden by named variant
        for col_key, col_data in columns.items():
            if isinstance(col_data, dict):
                staging_column_key = next((k for k in col_data.keys() if k and k.upper() == 'STAGING LAYER COLUMN NAME'), None)
                if staging_column_key:
                    col_name = col_data.get(staging_column_key, '')
                    if col_name:
                        cn_upper = str(col_name).upper()
                        if cn_upper == 'HASHDIFF' or cn_upper.startswith('HASHDIFF_'):
                            hashdiff_exists = True
                            hashdiff_col_name = cn_upper
                            break

        # ESAT guardrail: Effectivity satellites should NOT have HASHDIFF
        # (they track relationship validity only, no descriptive attributes)
        if is_esat and hashdiff_exists:
            logger.warning(
                f"ESAT '{table_name}' has HASHDIFF in mapping spec. "
                "Effectivity satellites track relationship validity only — "
                "HASHDIFF is unexpected. Verify the mapping spec is correct."
            )

        # MSAT awareness: Multi-active satellites need correct partition columns
        if is_msat:
            logger.info(
                f"MSAT '{table_name}': Multi-active satellite detected. "
                f"Verify QUALIFY partition columns include the multi-active key(s). "
                f"Current PK columns: {pk_columns}"
            )

        # LSAT awareness: Link-satellite parent is a LNK, not a HUB
        if is_lsat:
            logger.info(
                f"LSAT '{table_name}': Link-satellite detected. "
                "Parent entity is a link (LNK), not a hub — FK references should point to a link table."
            )

        if hashdiff_exists and hashdiff_col_name not in pk_columns:
            pk_columns.append(hashdiff_col_name)
            logger.debug(f"Added {hashdiff_col_name} to PK columns for qualify clause (tests don't include this)")
    
    # logger.info(f"Final PK columns for qualify clause: {pk_columns}")
    
    # Generate qualify clause
    qualify_clause = ""
    if is_satellite and pk_columns:
        pk_columns_str = ", ".join(pk_columns)
        qualify_clause = f"""
/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per HK and hashdiff. */
qualify 1 = row_number() over (partition by {pk_columns_str} order by PSA_LOAD_DTS)
"""
        logger.info(f"Generated qualify clause with columns: {pk_columns_str}")
    
    # Process union columns (existing ghost record logic)
    # Model-class flags used by the ghost defensive sweep below.
    is_sat_variant = table_name.startswith(('SAT_', 'LSAT_', 'MSAT_', 'ESAT_', 'LMSAT_', 'RSAT_'))
    is_hub = table_name.startswith('HUB_')
    is_link = table_name.startswith(('LNK_', 'LINK_', 'TLINK_'))

    union_columns = []
    for col_key, col_data in columns.items():
        if isinstance(col_data, dict):
            staging_column_key = next((k for k in col_data.keys() if k and k.upper() == 'STAGING LAYER COLUMN NAME'), None)
            ghost_record_key = next((k for k in col_data.keys() if k and k.upper() == 'GHOST RECORD'), None)
            remove_column_key = next((k for k in col_data.keys() if k and k.upper() == 'REMOVE COLUMN'), None)
            
            col_name = col_data.get(staging_column_key, '').upper() if staging_column_key else ''
            # Guard: reject SQL expressions as column names (Bug #31)
            if col_name and re.search(r'[()]', col_name):
                raise ValueError(
                    f"BUG: Column name '{col_name}' contains SQL expression syntax. "
                    f"Derived BKs must use the alias name (e.g., PRODUCT_VARIANT_BK), "
                    f"not the expression (e.g., TO_CHAR(ID)). "
                    f"Fix the YAML config or generate_tech_spec.py."
                )
            ghost_record = str(col_data.get(ghost_record_key, 'NULL')).strip().lower() if ghost_record_key else 'NULL'
            remove_column = str(col_data.get(remove_column_key, '')).strip().lower() if remove_column_key else ''
            
            if remove_column not in ('yes', 'y'):
                if ghost_record == 'hash':
                    union_columns.append(f"MD5_BINARY(GR.VALUE) AS {col_name}")
                elif ghost_record == 'value_text':
                    union_columns.append(f"GR.VALUE::text AS {col_name}")
                elif ghost_record == 'value_number':
                    union_columns.append(f"GR.VALUE::number AS {col_name}")
                elif ghost_record.startswith('custom_value:'):
                    custom_expr = ghost_record[len('custom_value:'):].strip()
                    union_columns.append(f"{custom_expr} AS {col_name}")
                    logger.debug(f"Using custom value expression: {custom_expr} for column {col_name}")
                elif ghost_record == 'load_dts':
                    union_columns.append(f"'1900-01-01T00:00:00'::TIMESTAMP_NTZ AS {col_name}")
                elif ghost_record == 'rec_src':
                    union_columns.append(f"'USAZET.SNOWFLAKE.FBIN.DERIVED' AS {col_name}")
                elif ghost_record == 'psa_load_dts':
                    union_columns.append(f"'1900-01-01'::TIMESTAMP AS {col_name}")
                elif ghost_record == 'psa_delete_ind':
                    union_columns.append(f"'N' AS {col_name}")
                elif ghost_record == 'bkcc':
                    union_columns.append(f"DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS {col_name}")
                elif ghost_record == 'hashdiff':
                    union_columns.append(f"MD5_BINARY('') AS {col_name}")
                elif ghost_record in ('null', ''):
                    # NORMALIZATION: XLSX reader stores blank cells as 'NULL'
                    # (string), YAML reader stores them as '' (empty). Both
                    # represent the "no GHOST RECORD directive set" case and
                    # must trigger the defensive sweep below.
                    #
                    # NOTE — LATENT READER DIVERGENCE (surfaced 2026-06-22):
                    # The XLSX reader (`process.py::process_columns`) converts
                    # any falsy cell value to the literal string 'NULL':
                    #     columns_dict[idx]['GHOST RECORD'] = ghost_record_value if ghost_record_value else 'NULL'
                    # The YAML reader (`yaml_reader.py::yaml_to_columns_dict`)
                    # converts missing values to the empty string '':
                    #     entry[xlsx_key] = "" if xlsx_key not in ("ORDER#",) else None
                    # Independent of ghost-record handling, this means downstream
                    # consumers that compare `col_data['GHOST RECORD']` to a
                    # specific sentinel must handle BOTH 'NULL' (str) and '' to
                    # stay reader-agnostic. The two readers should ideally be
                    # reconciled in a separate pass (out of scope here — flagged
                    # for later refactor).
                    #
                    # ── Defensive sweep ──────────────────────────────────────
                    # Emitting NULL is unsafe when:
                    #   (a) the column is a hub/link HK or hub BK (ghost rows
                    #       MUST populate keys — otherwise FK joins from child
                    #       tables to the ghost parent return NULL HK), or
                    #   (b) the column is a satellite payload marked NOT NULL
                    #       (the model's own not_null test would fail on its
                    #       ghost row).
                    # The default NULL emission is preserved for everything
                    # else (truly-nullable payload, optional metadata).
                    not_null_val = str(_coldata_get(col_data, 'NOT NULL') or '').strip().lower()
                    staging_dt = _coldata_get(col_data, 'STAGING LAYER DATATYPE') or _coldata_get(col_data, 'DATATYPE')

                    # (a) Hub/Link/Sat HK consistency sweep — ANY model whose
                    #     ghost row has an _HK column without a directive must
                    #     emit MD5_BINARY(GR.VALUE). For sats this is critical:
                    #     the sat ghost HK MUST match the hub's ghost HK
                    #     (also MD5_BINARY(GR.VALUE)) or FK joins from sat to
                    #     ghost parent return no row.
                    if (is_hub or is_link or is_sat_variant) and col_name.endswith('_HK'):
                        union_columns.append(f"MD5_BINARY(GR.VALUE) AS {col_name}")
                        logger.warning(
                            f"Ghost row: {col_name} on {table_name} had GHOST RECORD blank/null; "
                            "substituted MD5_BINARY(GR.VALUE) so the HK is populated. "
                            "Set GHOST RECORD='hash' in the XLSX to silence this warning."
                        )

                    # (a) Hub BK consistency sweep (links have no BK)
                    elif is_hub and col_name.endswith('_BK'):
                        if _is_numeric_datatype(staging_dt):
                            union_columns.append(f"GR.VALUE::number AS {col_name}")
                            directive = "value_number"
                        else:
                            union_columns.append(f"GR.VALUE::text AS {col_name}")
                            directive = "value_text"
                        logger.warning(
                            f"Ghost row: {col_name} on {table_name} had GHOST RECORD blank/null; "
                            f"substituted GR.VALUE cast for the BK based on datatype '{staging_dt}'. "
                            f"Set GHOST RECORD='{directive}' in the XLSX to silence this warning."
                        )

                    # (b) Satellite NOT NULL payload sweep
                    elif is_sat_variant and not_null_val in ('yes', 'y'):
                        sentinel = _ghost_sentinel_for_datatype(staging_dt)
                        if sentinel:
                            union_columns.append(f"{sentinel} AS {col_name}")
                            logger.warning(
                                f"Ghost row: NOT NULL payload {col_name} on {table_name} had GHOST RECORD blank/null; "
                                f"substituted type-appropriate sentinel for datatype '{staging_dt}'. "
                                "Set GHOST RECORD explicitly in the XLSX to silence this warning."
                            )
                        else:
                            union_columns.append(f"'GHOST RECORD'::TEXT AS {col_name}")
                            logger.warning(
                                f"Ghost row: NOT NULL payload {col_name} on {table_name} has unknown datatype "
                                f"'{staging_dt}'; defaulting to a STRING sentinel. Extend the type-sentinel "
                                "map in build.py or set GHOST RECORD explicitly."
                            )

                    # Nullable payload / nullable metadata — keep NULL.
                    else:
                        union_columns.append(f"NULL AS {col_name}")
                else:
                    if not ghost_record.isdigit():
                        union_columns.append(f"'{ghost_record}' AS {col_name}")
                    else:
                        union_columns.append(f"{ghost_record} AS {col_name}")
    
    union_columns_str = ',\n'.join(union_columns)
    
    # Build the final union all block
    union_all_block = f"""
{{% if not is_incremental() %}}
{qualify_clause}
union all
SELECT 
{union_columns_str}
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{{% endif %}}
"""
    
    return union_all_block


def dedup_preserve_order(seq):
    seen = set()
    return [x for x in seq if not (x in seen or seen.add(x))]

# Detects an already-present SAT SRC watermark so build_src_layer does not
# double-inject its default incremental_block. SINGLE SOURCE OF TRUTH -- imported
# by tests to verify the orchestrator's generated watermark shapes are detected
# here (a shape this regex misses would be given a second, duplicate watermark).
# Matches both `src.load_dts > (` and `src.load_dts >= (`: existing SATs use the
# `>=` shape, and missing it would double-inject a second watermark (#1929).
SAT_INCREMENTAL_PATTERN = re.compile(
    r"{%\s*if\s*is_incremental\s*\(\)\s*%}.*?where\s+src\.load_dts\s*>=?\s*\(.*?{{\s*this\s*}}.*?\).*?{%\s*endif\s*%}",
    re.IGNORECASE | re.DOTALL,
)


def build_src_layer(args, tables, current_layer, table_name=None, columns=None, large_volume=False, bkcc_rec_src=None):
    logger.debug('FUNCTION: build_src_layer')
    logging.debug(f'==== Build SOURCE SQL for {current_layer} layer.')

    all_sql = []
    comment_sql = []  # For direct Snowflake debug
    is_satellite = table_name and table_name.startswith(('SAT_', 'LSAT_', 'MSAT_', 'ESAT_', 'LMSAT_'))
    is_hub_model = table_name and table_name.startswith('HUB_')

    # Extract columns for large_volume QUALIFY clause (PARTITION BY).
    # For hubs, partition by BK+BKCC (HK is derived and not yet available in SRC).
    pk_columns_for_qualify = []
    if large_volume and columns:
        if is_hub_model:
            pk_columns_for_qualify = extract_bk_columns_for_hub_qualify(columns)
        else:
            pk_columns_for_qualify = extract_pk_columns_from_existing_logic(columns)

    # Build alias to source column mapping
    alias_to_columns = {}
    is_stg = current_layer == 'STG'
    if columns and not is_satellite:
        for row in columns.values():
            alias = row.get('SOURCE TABLE')
            src_col = row.get('SOURCE COLUMN', '')
            if alias and src_col and src_col != '(DERIVED)':
                alias_to_columns.setdefault(alias, []).append(src_col)
        # Sort the column lists for each alias for consistency.
        # Hub models preserve insertion order (HK first, then BK, then meta).
        if not is_hub_model:
            for alias in alias_to_columns:
                alias_to_columns[alias] = sorted(alias_to_columns[alias])

    # For v_psa_stg models, the driver table should use SELECT * (not explicit columns).
    # Identify the driver alias (first source table) and remove it from the mapping.
    if is_stg and alias_to_columns:
        driver_alias = None
        for table_list in tables.values():
            for table in table_list:
                a = table.get('ALIAS')
                if a:
                    driver_alias = a
                    break
            if driver_alias:
                break
        if driver_alias and driver_alias in alias_to_columns:
            del alias_to_columns[driver_alias]

    incremental_block = """{% if is_incremental() %}
      where src.load_dts > (select dateadd('HOUR',-1,max(load_dts)) from {{ this }})
    {% endif %}"""

    incremental_pattern = SAT_INCREMENTAL_PATTERN

    for table_list in tables.values():
        for table in table_list:
            source_schema = table.get('SOURCE SCHEMA')
            source_table = table.get('SOURCE TABLE')
            alias = table.get('ALIAS')
            if not (source_schema and source_table):
                logging.warning(f"Missing SOURCE SCHEMA or SOURCE TABLE for {current_layer} layer table {alias}")
                continue

            src_filter_condition = table.get('SOURCE LAYER FILTER') or ''
            dbt_where = ''
            if src_filter_condition:
                clean_src_filter = '\n' + (' ' * 24) + ('\n'+ ' ' * 24).join(src_filter_condition.split('\n'))
                dbt_where = f"{clean_src_filter}"

            if is_satellite and not incremental_pattern.search(src_filter_condition):
                dbt_where += ("\n" + incremental_block)

            if not is_satellite and alias in alias_to_columns and alias_to_columns[alias]:
                # Columns are already sorted above
                explicit_cols = ', '.join(dedup_preserve_order(alias_to_columns[alias]))
                if current_layer == 'STG' and (source_schema or '').lower() != 'raw_vault':
                    sql = f"SRC_{alias:<14} as ( SELECT {explicit_cols} FROM {{{{ source('{_resolve_source_name(source_schema, getattr(args, 'rootdir', None))}', '{source_table}') }}}} as SRC {dbt_where} )"
                else:
                    sql = f"SRC_{alias:<14} as ( SELECT {explicit_cols} FROM {{{{ ref('{source_table.lower()}') }}}} as SRC {dbt_where} )"
            else:
                if current_layer == 'STG' and (source_schema or '').lower() != 'raw_vault':
                    sql = f"SRC_{alias:<14} as ( SELECT * FROM {{{{ source('{_resolve_source_name(source_schema, getattr(args, 'rootdir', None))}', '{source_table}') }}}} as SRC {dbt_where} )"
                else:
                    sql = f"SRC_{alias:<14} as ( SELECT * FROM {{{{ ref('{source_table.lower()}') }}}} as SRC {dbt_where} )"
            # For large volume hubs, inject INCR_WATERMARK filter inside the SRC CTE
            if large_volume and pk_columns_for_qualify:
                pk_str = ', '.join(pk_columns_for_qualify)
                # Read QUALIFY ORDER BY from table dict (snp_glue→GLCHANGETIME, fivetran→_FIVETRAN_SYNCED)
                qualify_order = table.get('QUALIFY ORDER BY', '').strip() or 'LOAD_DTS'
                # Remove the trailing ) and inject watermark block inside the CTE
                if sql.endswith(')'):
                    sql = sql[:-1]
                sql += f"""
                        {{% if is_incremental() %}}
                        LEFT JOIN INCR_WATERMARK AS wm ON SRC.REC_SRC = wm.wm_REC_SRC
                        WHERE (wm.watermark_dts IS NULL OR SRC.LOAD_DTS >= wm.watermark_dts)
                        {{% else %}}
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY {pk_str} ORDER BY {qualify_order})) = 1
                        {{% endif %}}
)"""

            all_sql.append(sql)

            # Build debug comments block for direct Snowflake query execution
            if alias and source_schema and source_table:
                comment_sql.append(f"SRC_{alias:<14} as ( SELECT * FROM {source_schema}.{source_table} )")

    all_sql_str = ',\n'.join(all_sql)

    # Append BKCC CTE for v_psa_stg models when bkcc_rec_src is provided
    # Skip if a BKCC source row already exists in the Tables tab (avoids duplicate CTE)
    has_bkcc_table_row = any(
        'ref_business_key_collision' in (t.get('SOURCE TABLE') or '').lower()
        for tl in tables.values() for t in tl
    )
    if bkcc_rec_src and current_layer == 'STG' and not has_bkcc_table_row:
        # Sanitize rec_src to prevent injection: only allow alphanumeric, dots, underscores
        import re as _re
        if not _re.match(r'^[A-Za-z0-9._]+$', bkcc_rec_src):
            raise ValueError(f"Invalid bkcc_rec_src value (contains disallowed characters): {bkcc_rec_src}")
        bkcc_cte = f",\nSRC_BKCC          as ( SELECT BKCC, REC_SRC FROM {{{{ ref('ref_business_key_collision') }}}} WHERE rec_src = '{bkcc_rec_src}' )"
        all_sql_str += bkcc_cte
        comment_sql.append(f"SRC_BKCC          as ( SELECT BKCC, REC_SRC FROM RAW_VAULT.REF_BUSINESS_KEY_COLLISION WHERE rec_src = '{bkcc_rec_src}' )")

    comment_sql_str = '\n'.join(comment_sql)

    # Place the debug block after the SRC layer, before the Logic layer
    final_sql = f"{all_sql_str}\n\n/*\n{comment_sql_str}\n*/"

    logging.debug(f"Generated Source SQL:\n{final_sql}")
    return final_sql


def build_logic_layer(columns, tables, current_layer):
    logger.debug('FUNCTION: build_logic_layer')
    logging.info(f'==== Build LOGIC SQL ..')
    alias_list = []
    final_sql = []

    # Build a lookup from alias -> table entry (for FILTER CONDITIONS)
    alias_to_table = {}
    for table_list in tables.values():
        for table in table_list:
            alias = table.get('ALIAS')
            if alias:
                alias_to_table[alias] = table

    def format_manual_logic(logic, indent):
        lines = logic.strip().split('\n')
        if len(lines) > 1:
            formatted_lines = [lines[0]] + [f"{indent}{line.strip()}" for line in lines[1:-1]]
            last_line = lines[-1].strip()
            return '\n'.join(formatted_lines), last_line
        return logic.strip(), logic.strip()

    for table_list in tables.values():
        for table in table_list:
            alias = table.get('ALIAS')
            if alias and alias not in alias_list:
                alias_list.append(alias)

    for alias in alias_list:
        src_tbl = f'SRC_{alias}'
        tgt_tbl = f'LOGIC_{alias}'

        table_cols = []
        for idx, row in enumerate(columns.values()):
            if row.get('SOURCE TABLE') == alias:
                staging_col_name = row.get('STAGING LAYER COLUMN NAME', '')
                is_derived = row.get('IS_DERIVED', False)
                datatype = row.get('DATATYPE')
                col_str = row['SQL']

                if '\n' in col_str:
                    formatted_logic, last_line = format_manual_logic(col_str, ' ' * 12)
                    col_str = f"{formatted_logic}\n{' ' * 8}{last_line:<60} as {staging_col_name:>50}"
                else:
                    col_str = col_str

                    if col_str != staging_col_name:
                        col_str = f"{col_str:<60} as {staging_col_name:>50}"
                    else:
                        col_str = f"{col_str:<60}"

                if idx == 0 or not table_cols:
                    table_cols.append(f"        {col_str.strip()}")
                else:
                    table_cols.append(f"      , {col_str.strip()}")

                row['RENAMED_TO'] = staging_col_name

        if table_cols:
            cols_str = '\n'.join(table_cols)

            # Absorb FILTER CONDITIONS from the tables sheet (previously in build_filter_layer)
            where_clause = ''
            table_entry = alias_to_table.get(alias)
            if table_entry:
                filter_conditions = table_entry.get('FILTER CONDITIONS') or ''
                if filter_conditions:
                    filters = filter_conditions.split(';')
                    # Exclude DBT_VALID_TO/NULL snapshot conditions (legacy exclusion)
                    filters = [f.strip() for f in filters if f.strip()]
                    filters = [f for f in filters if 'DBT_VALID_TO' not in f.upper() or 'NULL' not in f.upper()]
                    if filters:
                        filters_str = ' AND '.join(filters)
                        where_clause = f"\n    WHERE {filters_str}"

            sql = f"""
, {tgt_tbl} as (
    SELECT
{cols_str}
    FROM {src_tbl}{where_clause}
)"""
            final_sql.append(sql)

    return '\n'.join(final_sql)


def build_join_levels(tables):
    logger.debug('FUNCTION: build_join_levels')
    lvls = {}
    for table_list in tables.values():
        for table in table_list:
            if not table[ 'PARENT TABLE JOIN' ]:
                continue
            lvl = table[ 'PARENT JOIN NUMBER' ]
            if not lvl: lvl = 0
            if lvl not in lvls:
                lvls[ lvl ] = []
            table[ 'PARENT JOIN ALIAS' ] = table[ 'PARENT TABLE JOIN'].split('.')[0]
            lvls[ lvl ].append(table)

    return lvls


def build_join_layer(tables, columns, current_layer, bkcc_rec_src=None):
    logger.debug('FUNCTION: build_join_layer')
    logging.debug("Entering build_join_layer function")
    join_sql = []

    sorted_tables = sorted([table for table_list in tables.values() for table in table_list], key=lambda x: int(x.get('PARENT JOIN NUMBER', '1')))

    all_union = all(table.get('JOIN TYPE', '').strip().upper() in ('UNION', 'UNION ALL') if table.get('JOIN TYPE') else False for table in sorted_tables)

    if all_union:
        join_sql.append("---- JOIN LAYER ----")
        union_cte = ", JOIN_RESULT as (\n"
        for idx, table in enumerate(sorted_tables):
            alias = table['ALIAS']
            join_type = table.get('JOIN TYPE', '').strip().upper() if table.get('JOIN TYPE') else 'UNION ALL'
            union_cte += f"    SELECT * FROM LOGIC_{alias}"
            if idx < len(sorted_tables) - 1:
                union_cte += f"\n    {join_type}\n"
        union_cte += "\n)"
        join_sql.append(union_cte)
    else:
        base_table = next((table for table in sorted_tables if table.get('PARENT TABLE JOIN') is None), sorted_tables[0])
        base_alias = base_table['ALIAS']

        join_cte = f"""
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM LOGIC_{base_alias}"""

        for table in sorted_tables:
            if table == base_table:
                continue
            
            join_type = table.get('JOIN TYPE', '').strip().upper() if table.get('JOIN TYPE') else ''
            if not join_type:
                logging.warning(f"Missing JOIN TYPE for table {table.get('ALIAS')}. Skipping this join.")
                continue
            
            alias = table['ALIAS']
            parent_join = table.get('PARENT TABLE JOIN')
            child_join = table.get('CHILD TABLE JOIN')
            
            if parent_join and child_join:
                parent_join_parts = parent_join.split('.')
                child_join_parts = child_join.split('.')
                
                if len(parent_join_parts) > 1:
                    parent_join = f"LOGIC_{parent_join_parts[0]}.{'.'.join(parent_join_parts[1:])}"
                if len(child_join_parts) > 1:
                    child_join = f"LOGIC_{child_join_parts[0]}.{'.'.join(child_join_parts[1:])}"
                elif not child_join.startswith("'"):
                    # No alias prefix — qualify with LOGIC_{alias} (build.py knows alias from table row)
                    child_join = f"LOGIC_{alias}.{child_join}"
                
                join_condition = f"    ON {parent_join} = {child_join}"
                join_cte += f"""
    {join_type} LOGIC_{alias}
    {join_condition}"""
            else:
                logging.warning(f"Incomplete join information for table {alias}. Skipping this join.")

        # Append BKCC cross join for v_psa_stg models
        # Skip if BKCC already joined via Tables-tab row (avoids duplicate join)
        has_bkcc_table_row = any(
            'ref_business_key_collision' in (t.get('SOURCE TABLE') or '').lower()
            for tl in tables.values() for t in tl
        )
        if bkcc_rec_src and current_layer == 'STG' and not has_bkcc_table_row:
            join_cte += """
    INNER JOIN SRC_BKCC ON '1' = '1'"""

        join_cte += "\n)"
        join_sql.append(join_cte)

    logging.debug(f"Exiting build_join_layer function. Generated SQL:\n{' '.join(join_sql)}")
    return '\n'.join(join_sql), "JOIN_RESULT"


def build_final_layer(tables, columns, current_layer, base_join_alias):
    logger.debug('FUNCTION: build_final_layer')
    final_columns = []
    hashdiff_cols = []
    deferred_hashes = []
    has_hashdiff = False

    for col in columns.values():
        colname = col.get('STAGING LAYER COLUMN NAME', '').upper()
        remove_column = (col.get('REMOVE COLUMN') or '').strip().lower()
        hashdiff = (col.get('HASHDIFF') or '').strip().lower()
        src_col = col.get('SOURCE COLUMN', '')
        is_derived = src_col == '(DERIVED)'
        manual_logic = col.get('MANUAL LOGIC', '')
        source_table = col.get('SOURCE TABLE')
        defer_hash = col.get('DEFER_HASH', False)

        if remove_column not in ('yes', 'y'):
            if colname == 'HASHDIFF':
                if current_layer == 'STG':
                    has_hashdiff = True
                    if hashdiff in ('yes', 'y'):
                        hashdiff_cols.append(f"IFNULL(TRIM({colname}::text), '^^') ")
                else:
                    final_columns.append((colname, colname, False))
            elif defer_hash:
                # Link HKs (issue #1907) compose from participating hub HK values via
                # HASH_FROM_HKS. Hub HKs are BINARY(16); TO_VARCHAR renders the hex form
                # CONCAT_WS requires (bare BINARY args do not compile). TO_VARCHAR — vs the
                # hub components' CAST — also keeps the reverse-parser regexes disjoint.
                if manual_logic.strip().upper().startswith('HASH_FROM_HKS:'):
                    hashcol = manual_logic.strip()[len('HASH_FROM_HKS:'):].strip()
                    hash_components = [c.strip().upper() for c in hashcol.split(',') if c.strip()]
                    hash_sql = []
                    for idx, component in enumerate(hash_components):
                        if idx == 0:
                            hash_sql.append(f"          TO_VARCHAR({component})")
                        else:
                            hash_sql.append(f"        , TO_VARCHAR({component})")
                    hash_str = "\n".join(hash_sql)
                    deferred_hashes.append((colname, f"""MD5_BINARY(UPPER(CONCAT_WS('||',
{hash_str}
        )))""", True))
                else:
                    hashcol = manual_logic.replace('HASH:', '').replace('COMPOSITE:', '').strip()
                    hash_components = [comp.strip() for comp in hashcol.split(',')]
                    # HK uses raw source column names (DV 2.x standard: source columns preserved through pipeline)
                    # Only resolve non-source columns (e.g., BKCC which is derived, not renamed)
                    hash_components = [c.upper() for c in hash_components]
                    hash_sql = []
                    for idx, component in enumerate(hash_components):
                        if idx == 0:
                            hash_sql.append(f"          COALESCE(NULLIF(TRIM(CAST({component} as VARCHAR)),''), '^^')")
                        else:
                            hash_sql.append(f"        , COALESCE(NULLIF(TRIM(CAST({component} as VARCHAR)),''), '^^')")

                    hash_str = "\n".join(hash_sql)
                    deferred_hashes.append((colname, f"""MD5_BINARY(UPPER(CONCAT_WS('||',
{hash_str}
        )))""", False))
            elif is_derived and not source_table:
                final_columns.append((colname, manual_logic, True))
            else:
                final_columns.append((colname, colname, False))

            if hashdiff in ('yes', 'y') and current_layer == 'STG':
                has_hashdiff = True
                hashdiff_cols.append(f"IFNULL(TRIM({colname}::text), '^^') ")

    select_columns = []
    
    for idx, (col, logic, needs_alias) in enumerate(final_columns):
        if logic is None or col is None:
            continue
        if needs_alias:
            if idx == 0:
                select_columns.append(f"          {logic:<60} as {col}")
            else:
                select_columns.append(f"        , {logic:<60} as {col}")
        else:
            if idx == 0:
                select_columns.append(f"          {col}")
            else:
                select_columns.append(f"        , {col}")

    # CTE-staged link HK derivation (issue #1907): when a link HK composes from hub
    # HK values, hub HKs must be pre-computed in an earlier CTE (HASH_STG) so the link
    # HK can reference them — a SELECT cannot reference a sibling alias. Hub/sat-only
    # models (no link HK) keep the original inline single-SELECT form unchanged.
    has_link_hash = any(is_link for _, _, is_link in deferred_hashes)
    hash_stg_cte = ""
    if has_link_hash:
        hub_hash_lines = [
            f"        , {hash_logic} as {col}"
            for col, hash_logic, is_link in deferred_hashes if not is_link
        ]
        hub_hash_str = "\n".join(hub_hash_lines)
        hash_stg_cte = f"""
, HASH_STG as (
    SELECT {base_join_alias}.*
{hub_hash_str}
    FROM {base_join_alias}
)"""

    for col, hash_logic, is_link in deferred_hashes:
        # Hub HKs are pre-computed in HASH_STG when a link is present — emit them as
        # passthrough here (same column position) so FINAL's column order is unchanged.
        emitted = col if (has_link_hash and not is_link) else f"{hash_logic} as {col}"
        if not select_columns:
            select_columns.append(f"          {emitted}")
        else:
            select_columns.append(f"        , {emitted}")
    
    if has_hashdiff and current_layer == 'STG':
        formatted_hashdiff_cols = []
        for idx, col in enumerate(hashdiff_cols):
            if idx == 0:
                formatted_hashdiff_cols.append(f"              {col}")
            else:
                formatted_hashdiff_cols.append(f"            , '||', {col}")
        hashdiff_str = '\n'.join(formatted_hashdiff_cols)

        select_columns.append(f"""        , MD5_BINARY(UPPER(NULLIF(CONCAT(
{hashdiff_str}
        ), '^^||^^')))  as HASHDIFF""")
        
    formatted_cols = '\n'.join(select_columns)
    final_from = "HASH_STG" if has_link_hash else base_join_alias

    final_sql = f"""{hash_stg_cte}
---- FINAL LAYER ----
SELECT
{formatted_cols}
FROM {final_from}\n"""

    final_filter_str, filter_comment, final_filter = '','',''
    for table_list in tables.values():
        for table in table_list:
            filter_comment += table.get('FILTER RESTRICTION RULE') or ''
            final_filter += table.get('FINAL LAYER FILTER') or  ''
    if filter_comment:
        filter_comment = filter_comment.replace("\n", " ")
        final_filter_str += f'\n/* {filter_comment} */\n'
    if final_filter:
        final_filter_str = final_filter.strip()

    # --- Check for incremental block for Raw Vault models ---
    # Only for RAW_VAULT models (satellite, hub, links, etc.)
    raw_vault_prefixes = ('sat', 'lsat', 'msat', 'lmsat', 'rsat', 'esat', 'hub', 'lnk', 'link', 'tlink')
    derived_model_name = None
    for table_list in tables.values():
        for table in table_list:
            if table.get('DERIVED_NAME'):
                derived_model_name = table.get('DERIVED_NAME')
                break
        if derived_model_name:
            break
    if not derived_model_name:
        derived_model_name = base_join_alias  # fallback

    # Only check the mapping spec's Final Layer Filter (not the generated SQL)
    if any(derived_model_name.startswith(prefix) for prefix in raw_vault_prefixes):
        # Require the incremental block in the Final Layer Filter
        incremental_pattern = re.compile(
            r"{%\s*if\s*is_incremental\s*\(\)\s*%}\s*WHERE\s+NOT\s+EXISTS",
            re.IGNORECASE
        )
        if not incremental_pattern.search(final_filter):
            error_msg = (
                f"ERROR: Raw Vault model '{derived_model_name}' missing required incremental block "
                "in Final Layer Filter in mapping spec."
            )
            logging.error(error_msg)
            raise RuntimeError(error_msg)

    final_sql += final_filter_str

    logging.debug(f"Exiting build_final_layer function. Generated SQL:\n{final_sql}")
    return final_sql
