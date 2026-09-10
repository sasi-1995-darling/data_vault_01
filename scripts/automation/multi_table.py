"""
multi_table.py — Multi-table (secondary/lookup table) support for v_psa_stg pipeline.

This module extracts all secondary-table logic into a standalone module
imported by pipeline_orchestrator.py. It handles:
- CLI argument registration for secondary table params
- State parsing and validation
- Secondary table mini-profiling (column discovery, ingestion detection)
- Column collision detection and auto-renaming
- YAML config extension (sources + columns)
- BK reference validation against renamed columns
"""
from __future__ import annotations

import re
from pathlib import Path
from typing import Any, Callable

# Metadata columns excluded from user-facing column prompts
_METADATA_COLS = {
    "_FIVETRAN_DELETED", "_FIVETRAN_SYNCED", "_FIVETRAN_ID",
    "PSA_LOAD_DTS", "PSA_RECORD_SOURCE", "PSA_DELETE_IND",
    "GLREQUEST", "GLSOURCESYSTEM", "GLDELFLAG", "GLCHANGETIME",
}


# ── 1. add_secondary_args ─────────────────────────────────────────────────────

def add_secondary_args(parser):
    """Register argparse arguments for secondary (lookup) table on a subparser."""
    parser.add_argument(
        "--secondary-schema",
        help="Secondary table schema (defaults to --schema if omitted)",
    )
    parser.add_argument(
        "--secondary-table",
        help="Secondary table name (e.g., order)",
    )
    parser.add_argument(
        "--secondary-alias",
        help="CTE alias for secondary table (auto-derived if omitted, e.g., ORD)",
    )
    parser.add_argument(
        "--join-type",
        choices=["LEFT JOIN", "INNER JOIN", "LEFT OUTER JOIN"],
        default="LEFT JOIN",
        help="Join type for secondary table (default: LEFT JOIN)",
    )
    parser.add_argument(
        "--join-on",
        help='Join predicate (e.g., "ORDER_ID = ORD.ID")',
    )
    parser.add_argument(
        "--secondary-bk",
        help='Secondary BK expression (e.g., "COALESCE(ORD_NAME, \'\\-1\')")',
    )
    parser.add_argument(
        "--secondary-bk-name",
        help="Secondary BK alias name (e.g., ORDER_HEADER_BK)",
    )
    parser.add_argument(
        "--secondary-columns",
        nargs="*",
        help="Columns to pull from secondary table (e.g., ID NAME)",
    )


# ── 2. parse_secondary_state ──────────────────────────────────────────────────

def _derive_alias(table_name: str) -> str:
    """Derive a short CTE alias from a table name.

    Rules:
    - If table has underscores, take first letter of each segment.
    - Otherwise take first 3 chars.
    - Always uppercase.

    Examples:
        "order"            → "ORD"
        "fulfillment_line" → "FL"
        "customer_address" → "CA"
        "item"             → "ITE"
    """
    if "_" in table_name:
        parts = table_name.split("_")
        return "".join(p[0] for p in parts if p).upper()
    return table_name[:3].upper()



def _resolve_source_name(schema: str, table: str) -> str:
    """Resolve the exact source table name from _sources_staging_psa.yml.

    dbt source() lookups are case-sensitive, so we must use the exact name
    from the YAML definition. Falls back to user-provided case if not found.
    """
    import yaml
    sources_path = Path(__file__).resolve().parents[2] / "models" / "sources" / "_sources_staging_psa.yml"
    if not sources_path.exists():
        return table  # Fallback: use provided case

    try:
        with open(sources_path) as f:
            data = yaml.safe_load(f)
    except Exception:
        return table

    sources = data.get("sources", [])
    for src in sources:
        if src.get("name", "").lower() == schema.lower() or src.get("schema", "").lower() == schema.lower():
            for tbl in src.get("tables", []):
                if tbl.get("name", "").upper() == table.upper():
                    return tbl["name"]  # Return exact case from YAML
    return table  # Not found — use provided case


def parse_secondary_state(args) -> dict | None:
    """Build a secondary state dict from parsed CLI args.

    Returns None when no --secondary-table is specified (single-table flow).
    Raises ValueError if --secondary-table given without --join-on.
    """
    secondary_table = getattr(args, "secondary_table", None)
    if not secondary_table:
        return None

    join_on = getattr(args, "join_on", None)
    if not join_on:
        raise ValueError(
            "--join-on is required when --secondary-table is specified "
            '(e.g., --join-on "ORDER_ID = ORD.ID")'
        )

    schema = getattr(args, "secondary_schema", None) or getattr(args, "schema", "")
    alias = getattr(args, "secondary_alias", None) or _derive_alias(secondary_table)
    bk = getattr(args, "secondary_bk", None)
    bk_name = getattr(args, "secondary_bk_name", None)
    raw_columns = getattr(args, "secondary_columns", None)

    # Uppercase columns for Snowflake matching
    columns = [c.upper() for c in raw_columns] if raw_columns else None

    return {
        "schema": schema.lower(),       # lesson #53: lowercase
        "table": _resolve_source_name(schema, secondary_table),  # preserve source YAML case
        "alias": alias.upper(),
        "join_type": getattr(args, "join_type", "LEFT JOIN"),
        "join_on": join_on,
        "bk": bk,
        "bk_name": bk_name,
        "columns": columns,
    }


# ── 3. profile_secondary_table ────────────────────────────────────────────────

def profile_secondary_table(
    state: dict,
    driver_profile: dict,
    run_query_fn: Callable,
) -> None:
    """Mini-profile the secondary table.

    Queries INFORMATION_SCHEMA.COLUMNS, detects ingestion type,
    validates requested columns, and detects/resolves column collisions.

    Mutates state['secondary'] in-place with:
        col_names, col_types, ingestion, rename_map, collisions
    """
    sec = state["secondary"]
    schema = sec["schema"]
    table = sec["table"]
    alias = sec["alias"]

    # Query secondary table columns
    sql = (
        f"SELECT COLUMN_NAME, DATA_TYPE "
        f"FROM PSA_PROD.INFORMATION_SCHEMA.COLUMNS "
        f"WHERE TABLE_SCHEMA = UPPER('{schema}') "
        f"AND TABLE_NAME = UPPER('{table}') "
        f"ORDER BY ORDINAL_POSITION"
    )
    rows = run_query_fn(sql, state)

    if not rows:
        raise ValueError(
            f"Secondary table not found: PSA_PROD.{schema}.{table} "
            f"(no columns returned from INFORMATION_SCHEMA)"
        )

    all_col_names = [r[0] for r in rows]
    all_col_types = {r[0]: r[1] for r in rows}

    # Detect ingestion type (lesson #79, #83)
    col_set = set(c.upper() for c in all_col_names)
    if "_FIVETRAN_SYNCED" in col_set:
        ingestion = "fivetran"
    elif "GLCHANGETIME" in col_set:
        ingestion = "snp_glue"
    else:
        ingestion = "custom"

    sec["col_names"] = all_col_names
    sec["col_types"] = all_col_types
    sec["ingestion"] = ingestion

    # If columns not yet specified, return early (caller will prompt)
    if sec["columns"] is None:
        return

    # Validate requested columns exist in secondary table
    available = set(c.upper() for c in all_col_names)
    missing = [c for c in sec["columns"] if c.upper() not in available]
    if missing:
        raise ValueError(
            f"Columns not found in {schema}.{table}: {', '.join(missing)}. "
            f"Available: {', '.join(sorted(available - _METADATA_COLS))}"
        )

    # Detect column collisions with driver table
    driver_col_names = set(
        c["name"].upper() for c in driver_profile.get("columns", [])
    )

    rename_map = {}
    collisions = []
    for col in sec["columns"]:
        col_upper = col.upper()
        if col_upper in driver_col_names:
            renamed = f"{alias}_{col_upper}"
            rename_map[col_upper] = renamed
            collisions.append(col_upper)
        else:
            rename_map[col_upper] = col_upper  # no rename needed

    sec["rename_map"] = rename_map
    sec["collisions"] = collisions


# ── 4. build_user_column_prompt ───────────────────────────────────────────────

def build_user_column_prompt(state: dict) -> str:
    """Generate a prompt string when --secondary-columns was omitted.

    Shows available non-metadata columns from the secondary table.
    """
    sec = state["secondary"]
    all_cols = sec.get("col_names", [])

    # Filter out metadata columns
    available = [c for c in all_cols if c.upper() not in _METADATA_COLS]

    lines = [
        f"\n  Secondary table: {sec['schema']}.{sec['table']} (alias: {sec['alias']})",
        f"  Available columns ({len(available)}):",
    ]
    # Display in rows of 5
    for i in range(0, len(available), 5):
        chunk = available[i : i + 5]
        lines.append("    " + ", ".join(chunk))

    lines.append("")
    lines.append("  Which columns do you need from this table?")
    lines.append("  (At minimum: join key + BK source columns)")

    return "\n".join(lines)


# ── 5. resolve_driver_qualify ─────────────────────────────────────────────────

def resolve_driver_qualify(
    profile: dict,
    partition_cols: str,
    order_col: str,
) -> str:
    """Return QUALIFY clause for driver table, gated by grain_valid.

    Returns empty string when grain is valid (no dedup needed).
    Returns QUALIFY clause with diagnostic comment when grain is invalid.
    """
    if profile.get("grain_valid", True):
        return ""

    row_count = profile.get("row_count", 0)
    grain_distinct = profile.get("grain_distinct", 0)
    dupes = row_count - grain_distinct if row_count and grain_distinct else "unknown"

    return (
        f"/* grain_valid=False: {dupes} duplicate BK+LOAD_DTS rows detected */\n"
        f"QUALIFY ROW_NUMBER() OVER(PARTITION BY {partition_cols} "
        f"ORDER BY {order_col} DESC) = 1"
    )


# ── 6. build_secondary_qualify ────────────────────────────────────────────────

def build_secondary_qualify(state: dict) -> str:
    """Generate QUALIFY clause for secondary table.

    ORDER BY determined by ingestion type.
    PARTITION BY is the child join column (parsed from join_on).
    """
    sec = state["secondary"]
    ingestion = sec.get("ingestion", "custom")
    alias = sec["alias"]

    # Determine ORDER BY column based on ingestion type
    # No alias prefix — build.py aliases the source as SRC, not the secondary alias.
    # QUALIFY runs inside the SRC CTE, so column names must be unqualified.
    if ingestion == "fivetran":
        order_col = "_FIVETRAN_SYNCED"
    elif ingestion == "snp_glue":
        order_col = "GLCHANGETIME"
    else:
        order_col = "PSA_LOAD_DTS"

    # Parse join predicate to get the child column for PARTITION BY
    join_info = parse_join_predicate(sec["join_on"], alias)
    child_col = join_info["child"]

    return (
        f"QUALIFY ROW_NUMBER() OVER(PARTITION BY {child_col} "
        f"ORDER BY {order_col} DESC) = 1"
    )


# ── 7. parse_join_predicate ──────────────────────────────────────────────────

def parse_join_predicate(join_on: str, alias: str) -> dict:
    """Parse join predicate into parent and child column names.

    Handles formats:
        "ORDER_ID = ORD.ID"       → {"parent": "ORDER_ID", "child": "ID"}
        "ORD.ID = ORDER_ID"       → {"parent": "ORDER_ID", "child": "ID"}
        "ORDER_ID=ORD.ID"         → {"parent": "ORDER_ID", "child": "ID"}
        "SRC.ORDER_ID = ORD.ID"   → {"parent": "ORDER_ID", "child": "ID"}

    Raises ValueError if format is unrecognized.
    """
    # Normalize whitespace
    join_on = join_on.strip()

    # Split on =
    parts = [p.strip() for p in join_on.split("=")]
    if len(parts) != 2:
        raise ValueError(
            f"Invalid join predicate: '{join_on}'. "
            "Expected format: 'PARENT_COL = ALIAS.CHILD_COL'"
        )

    left, right = parts[0], parts[1]
    alias_upper = alias.upper()

    def _strip_alias(col: str, target_alias: str) -> tuple[str, bool]:
        """Strip alias prefix from column. Returns (col_name, had_alias)."""
        if "." in col:
            prefix, name = col.rsplit(".", 1)
            if prefix.upper() == target_alias:
                return name.upper(), True
            # Has a different alias (e.g., SRC.ORDER_ID)
            return name.upper(), False
        return col.upper(), False

    left_name, left_has_alias = _strip_alias(left, alias_upper)
    right_name, right_has_alias = _strip_alias(right, alias_upper)

    # Determine which side is the child (secondary) table
    if left_has_alias:
        return {"parent": right_name, "child": left_name}
    elif right_has_alias:
        return {"parent": left_name, "child": right_name}
    else:
        # No alias prefix — right side is assumed to be child if it has a dot
        if "." in right:
            _, child = right.rsplit(".", 1)
            return {"parent": left_name, "child": child.upper()}
        elif "." in left:
            _, child = left.rsplit(".", 1)
            return {"parent": right_name, "child": child.upper()}
        else:
            # Neither side has alias — convention: left=parent, right=child
            return {"parent": left_name, "child": right_name}


# ── 8. extend_yaml_sources ───────────────────────────────────────────────────

def extend_yaml_sources(sources: list, state: dict) -> list:
    """Insert secondary table source row at index 1 (between driver and BKCC).

    Includes: source_schema, source_table, alias, source_layer_filter (QUALIFY),
    parent_table_join, child_table_join (column name only), join_type.
    """
    sec = state["secondary"]
    alias = sec["alias"]
    join_info = parse_join_predicate(sec["join_on"], alias)

    # Build QUALIFY for the secondary source
    qualify = build_secondary_qualify(state)

    # The child_table_join uses the RENAMED column name (lesson #84)
    child_col = join_info["child"]
    rename_map = sec.get("rename_map", {})
    renamed_child = rename_map.get(child_col, child_col)

    secondary_source = {
        "source_schema": sec["schema"],
        "source_table": sec["table"],
        "alias": alias,
        "join_type": sec["join_type"],
        "source_layer_filter": qualify,
        "parent_table_join": join_info["parent"],
        "child_table_join": renamed_child,
    }

    # Insert at index 1 (after driver, before BKCC)
    result = list(sources)
    result.insert(1, secondary_source)
    return result


# ── 9. extend_yaml_columns ──────────────────────────────────────────────────

def extend_yaml_columns(columns: list, state: dict) -> list:
    """Append secondary table columns with rename logic.

    Renamed columns get manual_logic = "ID AS ORD_ID" for collisions.
    Secondary BK appended as derived column.
    All column dicts include hashdiff field for compatibility.
    """
    sec = state["secondary"]
    alias = sec["alias"]
    rename_map = sec.get("rename_map", {})
    col_types = sec.get("col_types", {})
    requested_cols = sec.get("columns", [])

    result = list(columns)

    # Append secondary data columns
    for col in requested_cols:
        col_upper = col.upper()
        renamed = rename_map.get(col_upper, col_upper)
        is_collision = col_upper in sec.get("collisions", [])
        dtype = col_types.get(col_upper, "TEXT")

        entry = {
            "source_table": alias,
            "source_column": col_upper,
            "staging_column_name": renamed,
            "datatype": dtype,
            "hashdiff": "",
            "not_null": "",
            "unique": "",
            "manual_logic": "" if not is_collision else "",
        }
        result.append(entry)

    # Append secondary BK as derived column (if specified)
    if sec.get("bk_name"):
        result.append({
            "source_table": "",
            "source_column": "(DERIVED)",
            "staging_column_name": sec["bk_name"].upper(),
            "datatype": "TEXT",
            "hashdiff": "",
            "not_null": "yes",
            "unique": "",
            "manual_logic": sec["bk"],
        })

    return result


# ── 10. has_secondary ────────────────────────────────────────────────────────

def has_secondary(state: dict) -> bool:
    """Guard check: True only when state has a non-None 'secondary' key."""
    return state.get("secondary") is not None


# ── 11. validate_bk_references_renamed_columns ──────────────────────────────

def validate_bk_references_renamed_columns(state: dict) -> None:
    """Check that secondary BK expression uses valid column names.

    Raises ValueError if:
    1. BK references original (pre-rename) column names that were
       renamed due to collision (existing check).
    2. BK references column names that don't exist at all in the
       post-rename column set (lesson #92).
    """
    sec = state.get("secondary")
    if not sec or not sec.get("bk"):
        return

    bk_expr = sec["bk"]
    rename_map = sec.get("rename_map", {})
    collisions = sec.get("collisions", [])

    # ── Check 1: collision-renamed columns must use the renamed name ──
    for original in collisions:
        renamed = rename_map.get(original, original)
        pattern = rf'\b{re.escape(original)}\b'
        if re.search(pattern, bk_expr, re.IGNORECASE):
            renamed_pattern = rf'\b{re.escape(renamed)}\b'
            if not re.search(renamed_pattern, bk_expr, re.IGNORECASE):
                raise ValueError(
                    f"Secondary BK expression references original column '{original}' "
                    f"which was renamed to '{renamed}' due to collision.\n"
                    f"  Current:  --secondary-bk \"{bk_expr}\"\n"
                    f"  Fix:      --secondary-bk \"{re.sub(pattern, renamed, bk_expr)}\""
                )

    # ── Check 2: all column refs in BK expr must exist post-rename (lesson #92) ──
    if not rename_map:
        return  # No column info yet — can't validate

    _SQL_KEYWORDS = {
        "COALESCE", "CONCAT", "CONCAT_WS", "TO_CHAR", "TO_NUMBER", "TO_DATE",
        "TO_TIMESTAMP", "CAST", "TRIM", "UPPER", "LOWER", "IFNULL", "NULLIF",
        "IFF", "CASE", "WHEN", "THEN", "ELSE", "END", "AS", "VARCHAR", "TEXT",
        "NUMBER", "INT", "INTEGER", "FLOAT", "BOOLEAN", "DATE", "TIMESTAMP",
        "NTZ", "TIMESTAMP_NTZ", "AND", "OR", "NOT", "IS", "NULL", "LIKE",
        "SUBSTR", "SUBSTRING", "REPLACE", "LPAD", "RPAD", "LENGTH", "LEN",
        "LEFT", "RIGHT", "MD5", "SHA1", "SHA2", "DECODE", "NVL", "NVL2",
    }
    valid_columns = {v.upper() for v in rename_map.values()}
    tokens = re.findall(r'\b([A-Za-z_][A-Za-z0-9_]*)\b', bk_expr)
    for token in tokens:
        token_upper = token.upper()
        if token_upper in _SQL_KEYWORDS:
            continue
        if token_upper in valid_columns:
            continue
        candidates = sorted(valid_columns)
        suggestion = ""
        for col in candidates:
            if token_upper in col or col in token_upper:
                suggestion = f"  Did you mean: {col}?"
                break
        raise ValueError(
            f"Secondary BK expression references '{token}' which is not a valid "
            f"column after collision rename.\n"
            f"  Expression: --secondary-bk \"{bk_expr}\"\n"
            f"  Available columns: {', '.join(candidates)}\n"
            f"{suggestion}"
        )
