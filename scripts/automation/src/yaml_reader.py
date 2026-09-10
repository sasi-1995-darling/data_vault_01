"""
yaml_reader.py — Bridge YAML config files to build()'s expected dict format.

Reads YAML configs produced by Stage 1 (Tech Design Creator) and converts
them into the tables/columns dict structures that build.py, make_yml.py,
and tests.py expect. Also validates configs against input-schema.yml and
generates source entry snippets for _sources_staging_psa.yml.

Usage:
    from yaml_reader import load_yaml_config, yaml_to_tables_dict, yaml_to_columns_dict
"""

import logging
import yaml
from pathlib import Path

from source_column_utils import source_columns_to_str

logger = logging.getLogger(__name__)

SUPPORTED_SCHEMA_VERSIONS = {"1.0"}

# Maps YAML snake_case keys to the UPPER CASE headers that build.py expects
# in the tables dict (from process_tables output).
TABLES_KEY_MAP = {
    "source_schema": "SOURCE SCHEMA",
    "source_table": "SOURCE TABLE",
    "alias": "ALIAS",
    "source_layer_filter": "SOURCE LAYER FILTER",
    "filter_conditions": "FILTER CONDITIONS",
    "filter_restriction_rule": "FILTER RESTRICTION RULE",
    "parent_join_number": "PARENT JOIN NUMBER",
    "parent_table_join": "PARENT TABLE JOIN",
    "child_table_join": "CHILD TABLE JOIN",
    "final_layer_filter": "FINAL LAYER FILTER",
    "join_type": "JOIN TYPE",
    "target_schema": "TARGET SCHEMA",
    "model_config": "MODEL CONFIG",
    "qualify_order_by": "QUALIFY ORDER BY",
}

# Maps YAML snake_case keys to the UPPER CASE headers that build.py expects
# in the columns dict (from process_columns output).
COLUMNS_KEY_MAP = {
    "source_schema": "SOURCE SCHEMA",
    "source_table": "SOURCE TABLE",
    "source_column": "SOURCE COLUMN",
    "datatype": "DATATYPE",
    "automated_logic": "AUTOMATED LOGIC",
    "manual_logic": "MANUAL LOGIC",
    "order": "ORDER#",
    "staging_column_name": "STAGING LAYER COLUMN NAME",
    "staging_datatype": "STAGING LAYER DATATYPE",
    "hashdiff": "HASHDIFF",
    "unique": "UNIQUE",
    "not_null": "NOT NULL",
    "pk": "PK",
    "set_default": "SET DEFAULT",
    "remove_column": "REMOVE COLUMN",
    "test_expression": "TEST EXPRESSION",
    "accepted_values": "ACCEPTED VALUES",
    "relationship": "RELATIONSHIP",
    "mapping_notes": "MAPPING NOTES",
    "ghost_record": "GHOST RECORD",
    "scd": "SCD",
    "model_equality": "MODEL EQUALITY",
    "model_equal_rowcount": "MODEL EQUAL ROWCOUNT",
}


def validate_config(config):
    """Validate a parsed YAML config dict. Raises ValueError on problems."""
    errors = []

    # schema_version
    version = config.get("schema_version")
    if not version:
        errors.append("Missing required field: schema_version")
    elif str(version) not in SUPPORTED_SCHEMA_VERSIONS:
        errors.append(
            f"Unsupported schema_version '{version}'. "
            f"Supported: {SUPPORTED_SCHEMA_VERSIONS}"
        )

    # filename
    if not config.get("filename"):
        errors.append("Missing required field: filename")

    # models
    models = config.get("models")
    if not models or not isinstance(models, list):
        errors.append("Missing or empty 'models' list")
    else:
        for i, model in enumerate(models):
            prefix = f"models[{i}]"
            if not model.get("layer"):
                errors.append(f"{prefix}: missing 'layer'")
            if not model.get("derived_name"):
                errors.append(f"{prefix}: missing 'derived_name'")
            if not model.get("sources") or not isinstance(model.get("sources"), list):
                errors.append(f"{prefix}: missing or empty 'sources' list")
            else:
                for j, src in enumerate(model["sources"]):
                    src_prefix = f"{prefix}.sources[{j}]"
                    if not src.get("source_table"):
                        errors.append(f"{src_prefix}: missing 'source_table'")
                    if not src.get("alias"):
                        errors.append(f"{src_prefix}: missing 'alias'")
            if not model.get("columns") or not isinstance(model.get("columns"), list):
                errors.append(f"{prefix}: missing or empty 'columns' list")

    # _pipeline_metadata (optional but validated if present)
    meta = config.get("_pipeline_metadata", {})
    if meta:
        _validate_pipeline_metadata(meta, errors)

    if errors:
        raise ValueError(
            "YAML config validation failed:\n  - " + "\n  - ".join(errors)
        )

    logger.info("YAML config validation passed")


def _validate_pipeline_metadata(meta, errors):
    """Validate _pipeline_metadata fields."""
    # Boolean fields
    for key in ("has_fivetran_deleted", "has_psa_delete_ind",
                "null_bk_coalesced", "large_volume", "psa_delete_filter",
                "hub_use_watermark", "hub_full_refresh"):
        val = meta.get(key)
        if val is not None and not isinstance(val, bool):
            errors.append(f"_pipeline_metadata.{key} must be boolean, got {type(val).__name__}")

    # Numeric fields
    for key in ("row_count", "null_bk_count"):
        val = meta.get(key)
        if val is not None and not isinstance(val, (int, float)):
            errors.append(f"_pipeline_metadata.{key} must be numeric, got {type(val).__name__}")

    # null_bk_pct: 0-100
    pct = meta.get("null_bk_pct")
    if pct is not None:
        if not isinstance(pct, (int, float)):
            errors.append(f"_pipeline_metadata.null_bk_pct must be numeric, got {type(pct).__name__}")
        elif not (0 <= pct <= 100):
            errors.append(f"_pipeline_metadata.null_bk_pct must be 0-100, got {pct}")

    # null_bk_sentinel: string
    sentinel = meta.get("null_bk_sentinel")
    if sentinel is not None and not isinstance(sentinel, (str, int, float)):
        errors.append(f"_pipeline_metadata.null_bk_sentinel must be string or number")

    # bkcc_rec_src: string
    rec_src = meta.get("bkcc_rec_src")
    if rec_src is not None and not isinstance(rec_src, str):
        errors.append(f"_pipeline_metadata.bkcc_rec_src must be string")


def load_yaml_config(config_path):
    """Load and validate a YAML config file. Returns parsed dict."""
    config_path = Path(config_path)
    if not config_path.exists():
        raise FileNotFoundError(f"YAML config not found: {config_path}")

    logger.info(f"Loading YAML config: {config_path}")
    with open(config_path, "r") as f:
        config = yaml.safe_load(f)

    if not config or not isinstance(config, dict):
        raise ValueError(f"YAML config is empty or not a dict: {config_path}")

    validate_config(config)
    return config


def yaml_to_tables_dict(model_config, derived_name=None):
    """
    Convert a single model's 'sources' list into the tables dict format
    that build.py expects (matching process_tables() output).

    Args:
        model_config: One entry from config['models']
        derived_name: Override derived name (defaults to model_config['derived_name'])

    Returns:
        dict keyed by SOURCE TABLE, values are lists of table entry dicts
        with UPPER CASE keys matching XLSX headers.
    """
    if derived_name is None:
        derived_name = model_config["derived_name"]

    tables_dict = {}
    for src in model_config["sources"]:
        source_table = src["source_table"]

        entry = {}
        for yaml_key, xlsx_key in TABLES_KEY_MAP.items():
            entry[xlsx_key] = src.get(yaml_key, "") or ""

        # Ensure SOURCE TABLE is set
        entry["SOURCE TABLE"] = source_table
        entry["DERIVED_NAME"] = derived_name

        # Default PARENT JOIN NUMBER to "1" if empty (build_join_layer expects int-castable)
        if not entry.get("PARENT JOIN NUMBER"):
            entry["PARENT JOIN NUMBER"] = "1"

        if source_table not in tables_dict:
            tables_dict[source_table] = []
        tables_dict[source_table].append(entry)

    return tables_dict


def yaml_to_columns_dict(model_config, pipeline_metadata=None):
    """
    Convert a single model's 'columns' list into the columns dict format
    that build.py expects (matching process_columns() output).

    When pipeline_metadata is provided, injects HASHDIFF flags on
    _FIVETRAN_DELETED and PSA_DELETE_IND columns based on explicit
    boolean flags (has_fivetran_deleted, has_psa_delete_ind).

    Args:
        model_config: One entry from config['models']
        pipeline_metadata: Optional dict from get_pipeline_metadata()

    Returns:
        dict keyed by sequential integer index, values are column entry dicts
        with UPPER CASE keys matching XLSX headers.
    """
    if pipeline_metadata is None:
        pipeline_metadata = {}

    columns_dict = {}
    for idx, col in enumerate(model_config["columns"]):
        entry = {}
        for yaml_key, xlsx_key in COLUMNS_KEY_MAP.items():
            val = col.get(yaml_key)
            if val is not None:
                entry[xlsx_key] = val
            else:
                entry[xlsx_key] = "" if xlsx_key not in ("ORDER#",) else None

        # ``source_column`` is authoritative as a list; flatten it to the legacy
        # single-cell string that build.py's uppercase 'SOURCE COLUMN' expects.
        # Length-1 lists return the bare token, preserving single-column SQL.
        entry["SOURCE COLUMN"] = source_columns_to_str(col.get("source_column"))

        # Alias 'source_table' in columns maps to the alias (not the full table name)
        entry["SOURCE TABLE"] = col.get("source_table", "")

        # Flag-driven HASHDIFF injection:
        # If the column is _FIVETRAN_DELETED or PSA_DELETE_IND and the
        # corresponding pipeline_metadata flag is true, mark it for HASHDIFF.
        # Match on STAGING LAYER COLUMN NAME first, then SOURCE COLUMN as fallback
        # (in case the column is aliased differently in the YAML config).
        staging_name = (entry.get("STAGING LAYER COLUMN NAME") or "").upper()
        source_col = (entry.get("SOURCE COLUMN") or "").upper()
        if (staging_name == "_FIVETRAN_DELETED" or source_col == "_FIVETRAN_DELETED") and pipeline_metadata.get("has_fivetran_deleted"):
            entry["HASHDIFF"] = "yes"
            logger.debug("HASHDIFF flag injected for _FIVETRAN_DELETED (has_fivetran_deleted=true)")
        elif (staging_name == "PSA_DELETE_IND" or source_col == "PSA_DELETE_IND") and pipeline_metadata.get("has_psa_delete_ind"):
            entry["HASHDIFF"] = "yes"
            logger.debug("HASHDIFF flag injected for PSA_DELETE_IND (has_psa_delete_ind=true)")

        # null_bk_coalesced: if true and this column is a BK column with a not_null test,
        # mark it so tests.py can skip the not_null test.
        # Only applies to BK columns (staging name ends with _BK), NOT other not_null columns
        # like LOAD_DTS, to avoid accidentally suppressing valid tests.
        if pipeline_metadata.get("null_bk_coalesced") and entry.get("NOT NULL"):
            if staging_name.endswith("_BK"):
                entry["_NULL_BK_COALESCED"] = True
                logger.debug(f"null_bk_coalesced flag set on BK column {staging_name}")
            else:
                logger.debug(f"null_bk_coalesced: skipping non-BK column {staging_name}")

        columns_dict[idx] = entry

    return columns_dict


def get_pipeline_metadata(config):
    """
    Extract _pipeline_metadata from config, with defaults.

    Returns dict with all metadata fields, defaulting missing ones.
    """
    meta = config.get("_pipeline_metadata", {})
    return {
        "schema_version": str(config.get("schema_version", "1.0")),
        "bkcc_rec_src": meta.get("bkcc_rec_src"),
        "has_fivetran_deleted": meta.get("has_fivetran_deleted", False),
        "has_psa_delete_ind": meta.get("has_psa_delete_ind", True),
        "psa_delete_filter": meta.get("psa_delete_filter", False),
        "null_bk_coalesced": meta.get("null_bk_coalesced", False),
        "null_bk_sentinel": meta.get("null_bk_sentinel"),
        "null_bk_count": meta.get("null_bk_count"),
        "null_bk_pct": meta.get("null_bk_pct"),
        "large_volume": meta.get("large_volume", False),
        "hub_use_watermark": meta.get("hub_use_watermark", False),
        "hub_full_refresh": meta.get("hub_full_refresh", False),
        "row_count": meta.get("row_count"),
    }


def generate_source_entry(model_config, pipeline_metadata=None):
    """
    Generate the YAML source entry snippet for _sources_staging_psa.yml.

    For v_psa_stg models, the driver table needs to be registered as a source.
    Returns a dict with 'source_name' (schema) and 'table_entry' (the YAML snippet).

    Args:
        model_config: One entry from config['models']
        pipeline_metadata: Optional metadata dict (from get_pipeline_metadata)

    Returns:
        dict with keys:
            source_name: str — the dbt source name (lowercase schema)
            table_name: str — the PSA table name (lowercase)
            entry: dict — the structured entry for YAML insertion
        Or None if not a STG layer model.
    """
    layer = model_config.get("layer", "").upper()
    if layer != "STG":
        logger.debug(f"Skipping source entry for non-STG layer: {layer}")
        return None

    # Driver table is the first source
    driver = model_config["sources"][0]
    source_schema = (driver.get("source_schema") or "").lower()
    source_table = (driver.get("source_table") or "").lower()

    if not source_schema or not source_table:
        logger.warning("Cannot generate source entry: missing schema or table")
        return None

    return {
        "source_name": source_schema,
        "table_name": source_table,
        "entry": {
            "name": source_table,
            "description": "",
        },
    }
