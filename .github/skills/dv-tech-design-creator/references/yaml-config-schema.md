# YAML Config Schema — Stage 1 → Stage 2 Contract

The YAML config file is the handoff artifact between Stage 1 (Tech Design Creator) and Stage 2 (Code Generator). It is version-controlled, diffable, and machine-readable.

## Location

`scripts/automation/configs/<entity>__<source>.yml`

Example: `scripts/automation/configs/payment_term_line__emtk_ebs.yml`

## Full Schema

```yaml
# Required — checked by yaml_reader.validate_config()
schema_version: "1.0"
filename: "v_psa_stg_<entity>__<source>"

# Pipeline metadata — set by Stage 1, consumed by Stage 2
_pipeline_metadata:
  # BKCC REC_SRC value for WHERE clause in SRC_BKCC CTE
  # Regex-validated: only [A-Za-z0-9._] allowed (prevents SQL injection)
  bkcc_rec_src: "LOCATION.SYSTEM.APP.TABLE"

  # Flag-driven HASHDIFF routing (no AI inference at code gen time)
  has_fivetran_deleted: false   # If true → include _FIVETRAN_DELETED in HASHDIFF
  has_psa_delete_ind: true      # If true → include PSA_DELETE_IND in HASHDIFF

  # PSA_DELETE_IND and _FIVETRAN_DELETED are DATA — never filter them at staging
  # These flow through as HASHDIFF columns so satellites track deletion history
  psa_delete_filter: false      # DEPRECATED: always false — do NOT set to true (lesson #28)

  # NULL BK handling
  null_bk_coalesced: false      # If true → Stage 2 skips not_null test on BK
  null_bk_sentinel: "-1"        # Type-appropriate: '-1' (VARCHAR), -1 (NUMBER), '1900-01-01' (DATE)
  null_bk_count: 0              # Number of NULL BK rows (informational)
  null_bk_pct: 0.0              # Percentage NULL (0-100, informational)

  # Volume classification
  large_volume: false            # >300M rows — downstream metadata only for views
  row_count: 1500000             # Approximate row count (informational)

# Model definitions — one per YAML config for v_psa_stg
models:
  - layer: STG                    # Required: STG for v_psa_stg models
    derived_name: "v_psa_stg_<entity>__<source>"
    short_name: "<entity>__<source>"

    # Source tables
    sources:
      # Driver table (first entry) — Stage 2 uses SELECT *
      - source_schema: "<SCHEMA>"
        source_table: "<TABLE>"
        alias: "<ALIAS>"
        source_layer_filter: ""     # Optional: WHERE clause for context-specific dummy records ONLY
                                    # NEVER use for _FIVETRAN_DELETED or PSA_DELETE_IND (lesson #28)
        filter_conditions: ""       # Optional: additional filter
        target_schema: ""           # Optional: target schema override

      # Lookup tables (if any) — Stage 2 uses explicit column list
      - source_schema: "<SCHEMA>"
        source_table: "<LOOKUP_TABLE>"
        alias: "<LOOKUP_ALIAS>"
        parent_join_number: "1"     # Join order
        parent_table_join: "<DRIVER_ALIAS>.<JOIN_COL>"
        child_table_join: "<LOOKUP_ALIAS>.<JOIN_COL>"
        join_type: "LEFT"           # LEFT (default) or INNER
        source_layer_filter: ""

    # Column definitions
    columns:
      - source_table: "<ALIAS>"           # Which source this column comes from
        source_column: "<RAW_COL_NAME>"   # Original column name in source
        datatype: "VARCHAR(100)"          # Source datatype
        staging_column_name: "ENTITY_BK"  # Uppercase alias in staging view
        staging_datatype: "VARCHAR(100)"  # Staging datatype
        order: 1                          # Column order in output
        hashdiff: "no"                    # "yes" or "no" — include in HASHDIFF
        unique: "Unique: ENTITY_BK, LOAD_DTS"  # unique_combination spec
        not_null: "Y"                     # not_null test
        pk: ""                            # primary key constraint
        set_default: ""                   # default value
        remove_column: ""                 # "Y" to exclude from output
        automated_logic: ""               # Auto-derived logic (HK, LOAD_DTS, etc.)
        manual_logic: ""                  # Custom SQL logic
        ghost_record: ""                  # Ghost record value
        test_expression: ""               # dbt_utils.expression_is_true
        accepted_values: ""               # accepted_values test
        relationship: ""                  # dbt_constraints.foreign_key ref
        mapping_notes: ""                 # Documentation
```

## Key Conventions

### HASHDIFF Flag Routing
The `has_fivetran_deleted` and `has_psa_delete_ind` flags drive code generation:
- `yaml_reader.yaml_to_columns_dict()` reads these flags
- If `has_fivetran_deleted: true` → sets `HASHDIFF: "yes"` on the `_FIVETRAN_DELETED` column entry
- If `has_psa_delete_ind: true` → sets `HASHDIFF: "yes"` on the `PSA_DELETE_IND` column entry
- `build.py`'s existing HASHDIFF logic picks up `HASHDIFF: "yes"` columns — no special handling needed

### NULL BK Handling
When `null_bk_coalesced: true`:
- `yaml_reader.yaml_to_columns_dict()` sets `_NULL_BK_COALESCED: True` on BK columns with `not_null` tests
- `tests.py`'s `get_column_tests()` skips the `not_null` test when this flag is set
- The COALESCE is applied in the LOGIC layer SQL, not in YAML schema

### Unique Test on BK + LOAD_DTS
The `unique_combination_of_columns` test uses **BK + LOAD_DTS** (not HK + LOAD_DTS):
- BK + LOAD_DTS is the true grain of a v_psa_stg view
- HK uniqueness is enforced at hub/sat level
- Testing on HK's `MD5_BINARY(UPPER(COALESCE(TRIM(CAST(...)))))` forces computation per row

### large_volume for Views
`large_volume: true` adds a downstream recommendation comment only. v_psa_stg models are views — `on_schema_change`, `full_refresh=false`, and `{{ config() }}` do NOT apply.

## Validation

`yaml_reader.validate_config()` checks:
- `schema_version` in supported set (`{"1.0"}`)
- `filename` present
- `models` list non-empty, each with `layer`, `derived_name`, `sources`, `columns`
- `_pipeline_metadata` field types (booleans, numerics, pct range 0-100)

## Forward Compatibility

The `schema_version: "1.0"` field enables future schema changes:
- Minor changes (new optional fields): bump to `"1.1"` and add to `SUPPORTED_SCHEMA_VERSIONS`
- Breaking changes (field renames, required→optional): bump to `"2.0"` with migration logic
