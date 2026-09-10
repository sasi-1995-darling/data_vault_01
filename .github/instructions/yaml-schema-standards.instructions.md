---
applyTo: "**/v_psa_stg_*.yml,**/_hub_*.yml,**/_sat_*.yml,**/_lsat_*.yml,**/_msat_*.yml,**/_esat_*.yml,**/_link_*.yml,**/_lnk_*.yml,**/_pit_*.yml,**/_pb_*.yml,**/_dim_*.yml,**/_fact_*.yml,**/_ref_*.yml,**/_sources*.yml"
description: "YAML schema standards for dbt models and sources in Data Vault 2.0"
---

# YAML Schema Standards

## File Naming Convention
- Schema files: `<model_name>.yml` (matches model name, co-located with SQL file)
  - Exception: raw vault and business vault layers may use `_<model_name>.yml` (leading underscore)
- Source files: `_sources__<source_system>.yml`
- One schema file per model (exception: multiple related models can share one file)

## General Structure
```yaml
version: 2
models:
  - name: model_name
    description: "Clear description of the model's purpose"
    data_tests:   # Model-level tests (NOT 'tests:' which is deprecated)
      - test_name:
          ...
    columns:
      - name: COLUMN_NAME    # UPPERCASE
        description: "Column description"
        data_tests:
          - test_name
```

**Important**: Use `data_tests:` not `tests:` — the `tests:` key is deprecated in dbt 1.5+.

## Layer-Specific Test Requirements

### v_psa_stg (Staging Views)
Required tests:
```yaml
data_tests:
  - dbt_utils.unique_combination_of_columns:
      config:
        severity: warn
      arguments:
        combination_of_columns:
          - ENTITY_BK
          - LOAD_DTS
columns:
  - name: ENTITY_BK
    data_tests:
      - not_null:
          config:
            severity: warn
```
- BK `not_null` is required
- `unique_combination_of_columns` on **BK + LOAD_DTS** = effective PK (BK + LOAD_DTS is the true grain; HK uniqueness enforced at hub/sat level)
- `arguments:` wrapper is required for dbt 2.0 / Fusion compatibility
- HK `not_null` is NOT needed (IFNULL in derivation guarantees non-null)

### Raw Vault (hub/sat/link)
Required tests:
```yaml
data_tests:
  - dbt_constraints.primary_key:
      column_name: ENTITY_HK
  - dbt_constraints.foreign_key:       # sat/link only
      pk_table_name: ref('hub_entity')
      pk_column_name: ENTITY_HK
      fk_column_name: ENTITY_HK
  - dbt_expectations.expect_table_row_count_to_be_between:
      min_value: 4
```
- PK constraint is DB-enforced
- FK constraint on sat→hub and link→hub
- Min row count (4) validates data exists

### Business Vault — Tables (PIT/PB/REF)
```yaml
data_tests:
  - dbt_constraints.primary_key:
      column_name: ENTITY_HK
```
- PK constraints required
- Add metrics tests (`dbt_expectations`) on critical business fields where applicable:
  ```yaml
  - name: TOTAL_AMOUNT
    data_tests:
      - dbt_expectations.expect_column_values_to_be_between:
          min_value: 0
  ```

### Business Vault — Views (dim/fact)
- **Caution**: QA team runs singular tests on these models
- Do NOT duplicate with YAML schema tests to avoid running the same validation twice
- Only add YAML tests if the grain differs from upstream or there's a specific business rule not covered by QA
- Most dim/fact views are `SELECT *` from upstream — they inherit upstream test coverage

### Info Mart / Reports
- `rep_` and `rpt_` models: No tests needed (empty YAML is acceptable)
- `fact_` and `im_` models: Same caution as BV views — QA singular tests take precedence

## Source YAML Standards
```yaml
version: 2
sources:
  - name: source_system
    database: "psa_{{ env_var('DBT_SOURCE_ENV') }}"
    schema: schema_name
    tables:
      - name: table_name
        description: "Source table description"
```

## Column Description Conventions
- BK columns: "Business key for \<entity\>"
- HK columns: "Hash key for \<entity\>"
- LNK_HK columns: "Link hash key for \<relationship\>"
- HASHDIFF: "Hash diff for change detection"
- LOAD_DTS: "Load timestamp (UTC)"
- REC_SRC: "Record source identifier"
- BKCC: "Business key control column"
