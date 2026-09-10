# CODE_REVIEW_CHECKS.md — Deterministic Pre-PR Review Inventory

> **Purpose**: Each row = one deterministic check function in `code_reviewer.py` + one unit test.
> This inventory IS the spec. No code until this document is approved.
>
> **Methodology**: Every check was validated by grepping ≥3 files in the live repo (2,141+ models).
> Example violations and passes are drawn from the most common variant; footnotes note significant variations.
>
> **Severity Key**: `FAIL` = blocks merge | `WARN` = advisory, does not block
>
> **Status**: APPROVED (2025-05-12). Proceed to implementation.

---

## Configuration Decisions

These decisions govern how `code_reviewer.py` handles edge cases. They must be implemented before writing check functions.

### CD-1. `link_` vs `lnk_` (Legacy Prefix Transition)

**Decision**: Graduated enforcement.
- **Modified `link_` files** (file exists on `main`, touched in PR diff): **WARN** — "Legacy prefix `link_` detected. Standard is `lnk_`. Consider renaming."
- **New `link_` files** (file does NOT exist on `main`): **FAIL** — "New models must use `lnk_` prefix, not `link_`."
- **Implementation**: Check G4 must accept a `diff_context` parameter (or equivalent) that indicates whether each file is new vs modified. The reviewer CLI must compute this from `git diff --name-status` against the PR's base branch.
- **Standard going forward**: `lnk_` only. The 31 existing `link_` models are grandfathered.

### CD-2. Legacy AutomateDV Models (Path Exclusion)

**Decision**: Exclude via path filter.
- **Excluded paths**: `models/staging/base/` (173 files) and `models/staging/stage/` (163 files)
- **Rationale**: These are AutomateDV-generated Jinja templates — they cannot conform to hand-written SQL standards (4-layer CTE, HK formula, naming). They're scheduled for retirement.
- **NOT excluded**: `stg_` files in `models/bus_vault/` (66 PIT staging helpers) — these are active bus_vault models and must pass all applicable checks.
- **Implementation**: `code_reviewer.py` reads a hardcoded `EXCLUDED_PATHS` list at startup. Files matching any excluded path prefix are skipped entirely (no checks run, no findings emitted). The path list is:
  ```python
  EXCLUDED_PATHS = [
      "models/staging/base/",
      "models/staging/stage/",
  ]
  ```

### CD-3. `.code_review_ignore` (Extensible Exception File)

**Decision**: Create a `.code_review_ignore` config file for naming convention exceptions.
- **Location**: `scripts/automation/.code_review_ignore`
- **Scope**: Only **Category G (Naming Conventions)** checks are suppressed. All other checks (HK, HASHDIFF, CTE, tests, etc.) still run on ignored files.
- **Format**: One relative path per line (from repo root). Comments with `#`. Glob patterns supported.
  ```
  # One-off legacy models with non-standard names
  models/bus_vault/flat_logic/shipment.sql
  models/bus_vault/flat_logic/ferguson_items_active_customer.sql
  models/bus_vault/dim/date_spine.sql
  models/bus_vault/flat_logic/t_*.sql
  ```
- **Implementation**: `code_reviewer.py` reads this file at startup. For each file in the PR, if it matches any `.code_review_ignore` entry, skip Category G checks only. Log a debug message: "Skipping naming checks for {path} (listed in .code_review_ignore)".
- **Extensibility**: Future category-specific ignore files (e.g., `.code_review_ignore_tests`) can follow the same pattern if needed.

---

## Check Inventory

### Category A — Hash Key (HK) Formula

| # | Check Name | Severity | Files Inspected | What It Inspects | Example Violation | Example Pass | Lesson # |
|---|-----------|----------|-----------------|------------------|-------------------|--------------|----------|
| A1 | `hk_uses_concat_ws` | FAIL | .sql | HK formula must use `MD5_BINARY(UPPER(CONCAT_WS('||', ...)))` — not plain `CONCAT` | `MD5_BINARY(CONCAT('||', col1, col2))` | `MD5_BINARY(UPPER(CONCAT_WS('||', COALESCE(NULLIF(TRIM(CAST(LIFNR AS VARCHAR)), ''), '^^'), COALESCE(NULLIF(TRIM(CAST(BKCC AS VARCHAR)), ''), '^^'))))` | #1, #16 |
| A2 | `hk_coalesce_nullif_trim` | FAIL | .sql | Each HK component must use `COALESCE(NULLIF(TRIM(CAST(col AS VARCHAR)), ''), '^^')` | `COALESCE(TRIM(col), '^^')` — missing NULLIF (empty string passes through) | `COALESCE(NULLIF(TRIM(CAST(LIFNR AS VARCHAR)), ''), '^^')` | #1 |
| A3 | `hk_uses_raw_column_names` | FAIL | .sql | HK components reference raw source column names, NOT BK aliases¹ | `CONCAT_WS('||', COALESCE(...CAST(SUPPLIER_BK...), '^^'))` — uses alias | `CONCAT_WS('||', COALESCE(...CAST(LIFNR...), '^^'))` — uses raw source col | #1, #89 |
| A4 | `hk_bkcc_last_component` | FAIL | .sql | BKCC must be the last argument in every HK `CONCAT_WS` | `CONCAT_WS('||', COALESCE(...BKCC...), COALESCE(...LIFNR...))` | `CONCAT_WS('||', COALESCE(...LIFNR...), COALESCE(...BKCC...))` | #12 |
| A5 | `hk_has_upper_wrapper` | FAIL | .sql | HK formula must be wrapped in `UPPER(...)` | `MD5_BINARY(CONCAT_WS('||', ...))` | `MD5_BINARY(UPPER(CONCAT_WS('||', ...)))` | — |

> ¹ Exception per lesson #89: derived BKs from complex expressions use the BK alias; simple casts use the raw column.
>
> **Confirmed in repo**: 441 v_psa_stg files use `MD5_BINARY(UPPER(CONCAT_WS(` for HK. 0 non-standard variants found.

---

### Category B — HASHDIFF Formula

| # | Check Name | Severity | Files Inspected | What It Inspects | Example Violation | Example Pass | Lesson # |
|---|-----------|----------|-----------------|------------------|-------------------|--------------|----------|
| B1 | `hashdiff_uses_nullif_concat` | FAIL | .sql | HASHDIFF must use `MD5_BINARY(UPPER(NULLIF(CONCAT(...), '^^||^^')))` | `MD5_BINARY(CONCAT(...))` — missing NULLIF+UPPER | `MD5_BINARY(UPPER(NULLIF(CONCAT(IFNULL(TRIM(col::text), '^^'), '||', ...), '^^||^^')))` | — |
| B2 | `hashdiff_ifnull_trim_pattern` | FAIL | .sql | Each HASHDIFF component must use `IFNULL(TRIM(col::text), '^^')` | `COALESCE(col, '^^')` — wrong null-handler for HASHDIFF | `IFNULL(TRIM(LAND1::text), '^^')` | — |
| B3 | `hashdiff_separator_pattern` | WARN | .sql | HASHDIFF components separated by `'||'` between each IFNULL — not leading | `'||' IFNULL(TRIM(col::text), '^^')` (leading separator, no comma) | `, '||', IFNULL(TRIM(col::text), '^^')` | — |
| B4 | `hashdiff_excludes_metadata` | FAIL | .sql | HASHDIFF must NOT include: `_HK`, `_BK`, `LOAD_DTS`, `REC_SRC`, `BKCC`, `_FIVETRAN_SYNCED`, `_FIVETRAN_ID`, `PSA_LOAD_DTS`, `PSA_RECORD_SOURCE` | `IFNULL(TRIM(SUPPLIER_HK::text), '^^')` inside HASHDIFF block | (no metadata columns in HASHDIFF block) | #4 |
| B5 | `hashdiff_includes_psa_delete_ind` | FAIL | .sql | `PSA_DELETE_IND` is DATA — must be included in HASHDIFF when column exists in source | HASHDIFF block present but `PSA_DELETE_IND` absent (for SNP GLUE source) | `IFNULL(TRIM(PSA_DELETE_IND::text), '^^')` as last HASHDIFF component | #4 |
| B6 | `hashdiff_includes_fivetran_deleted` | FAIL | .sql | `_FIVETRAN_DELETED` is DATA — must be included in HASHDIFF when column exists in source | HASHDIFF block present but `_FIVETRAN_DELETED` absent (for Fivetran source) | `IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^')` in HASHDIFF block | #5 |
| B7 | `hashdiff_ends_with_sentinel` | FAIL | .sql | HASHDIFF NULLIF must close with `'^^||^^'` sentinel to handle all-null rows | `MD5_BINARY(UPPER(CONCAT(...)))` — missing NULLIF sentinel | `MD5_BINARY(UPPER(NULLIF(CONCAT(...), '^^||^^')))` | — |
| B8 | `hashdiff_delete_flag_explicit_cast` | FAIL | .sql | Delete-flag columns (`_FIVETRAN_DELETED`, `PSA_DELETE_IND`, `GLDELFLAG`) in HASHDIFF must carry an explicit text cast so BOOLEAN states (TRUE/FALSE/NULL) tokenize distinctly | `IFNULL(TRIM(_FIVETRAN_DELETED), '^^')` — delete flag in block without `::text`/`CAST` | `IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^')` | — |

> **Confirmed in repo**: 480 v_psa_stg files use `MD5_BINARY(UPPER(NULLIF(CONCAT(` for HASHDIFF. 478 use `'^^||^^'` sentinel. 489 files include `PSA_DELETE_IND`. 145 Fivetran models include `_FIVETRAN_DELETED`.
> No violations found for B4 (HK/BK in HASHDIFF) in sampled 50 files.

---

### Category C — CTE Structure

| # | Check Name | Severity | Files Inspected | What It Inspects | Example Violation | Example Pass | Lesson # |
|---|-----------|----------|-----------------|------------------|-------------------|--------------|----------|
| C1 | `cte_4layer_new_models` | WARN | .sql | New models (orchestrator-generated) should use 4-layer: `SRC → LOGIC → JOIN → FINAL` | New model with 6-layer CTE (RENAME, FILTER passthroughs) | `SRC_S AS (...), LOGIC AS (...), JOIN_RESULT AS (...), FINAL AS (...)` | #8 |
| C2 | `cte_no_nonstandard_names` | WARN | .sql | CTE names must follow standard patterns: `SRC_*`, `LOGIC_*`, `RENAME_*`, `FILTER_*`, `JOIN_RESULT`, `FINAL` | `TEMP_CTE AS (...)`, `CLEANUP AS (...)` | `SRC_S AS (...), LOGIC_S AS (...)` | — |
| C3 | `final_select_from_join_result` | WARN | .sql | Final SELECT should reference `JOIN_RESULT` (6-layer) or `FINAL` (4-layer) — not intermediate CTEs | `SELECT ... FROM RENAME_S` as the final output | `SELECT ... FROM JOIN_RESULT` | — |

> **Confirmed in repo**: All 517 legacy v_psa_stg models use 6-layer pattern (`SRC_*`, `LOGIC_*`, `RENAME_*`, `FILTER_*`, `JOIN_RESULT`). Final SELECT references `JOIN_RESULT` in 517 files. Zero models use the new 4-layer yet (all orchestrator-generated models are pending).
> Legacy CTE naming uses suffix convention: `SRC_S` (source), `SRC_A` (BKCC ref), `LOGIC_S`, `RENAME_S`, `FILTER_S`, `FILTER_A`, `JOIN_RESULT`.

---

### Category D — BKCC Standards

| # | Check Name | Severity | Files Inspected | What It Inspects | Example Violation | Example Pass | Lesson # |
|---|-----------|----------|-----------------|------------------|-------------------|--------------|----------|
| D1 | `bkcc_join_on_1_equals_1` | FAIL | .sql | BKCC must be joined via `INNER JOIN ... ON '1' = '1'` — never hardcoded | `WHERE BKCC = 'FBIN'` — hardcoded value | `INNER JOIN FILTER_A ON '1' = '1'` | #10 |
| D2 | `bkcc_from_ref_table` | FAIL | .sql | BKCC must be sourced from `ref('ref_business_key_collision')` or `{{ source(...) }}` — not a literal | `'FBIN' AS BKCC` | `SRC_A AS (SELECT * FROM {{ ref('ref_business_key_collision') }} ...)` | #10 |
| D3 | `bkcc_column_present` | FAIL | .sql | Every v_psa_stg model must output a `BKCC` column (raw vault links excluded) | Model with no BKCC in output columns | `BKCC` appears in JOIN_RESULT / final SELECT | — |

> **Confirmed in repo**: 503 v_psa_stg files use `ON '1' = '1'` pattern. 504 files ref() the BKCC table.
> No hardcoded BKCC violations found in the sampled models (one file references `MDM_REF_BKCC_REC_SRC` but it's a WHERE filter on a different column, not hardcoding BKCC itself).

---

### Category E — Dedup & QUALIFY

| # | Check Name | Severity | Files Inspected | What It Inspects | Example Violation | Example Pass | Lesson # |
|---|-----------|----------|-----------------|------------------|-------------------|--------------|----------|
| E1 | `no_select_distinct` | FAIL | .sql | `SELECT DISTINCT` is prohibited — use `QUALIFY ROW_NUMBER()` instead | `SELECT DISTINCT col1, col2 FROM ...` | `SELECT col1, col2 FROM ... QUALIFY ROW_NUMBER() OVER (PARTITION BY col1 ORDER BY LOAD_DTS DESC) = 1` | #11 |
| E2 | `qualify_has_row_number` | WARN | .sql | QUALIFY clauses should use `ROW_NUMBER()` (preferred) or `RANK()` | `QUALIFY DENSE_RANK() OVER (...)` — unusual, may be intentional | `QUALIFY ROW_NUMBER() OVER (PARTITION BY ... ORDER BY ...) = 1` | #11, #14 |

> **Confirmed in repo**: 0 `SELECT DISTINCT` in v_psa_stg or raw vault. 3 violations in bus_vault (`pb_bom_hierarchy`, `pb_bill_of_operation`, `pb_product_sales`). 60 v_psa_stg files use QUALIFY. 219 raw vault files use QUALIFY.

---

### Category F — Date & Timezone Handling

| # | Check Name | Severity | Files Inspected | What It Inspects | Example Violation | Example Pass | Lesson # |
|---|-----------|----------|-----------------|------------------|-------------------|--------------|----------|
| F1 | `convert_timezone_utc` | FAIL | .sql | All `CONVERT_TIMEZONE` calls must specify `'UTC'` as target | `CONVERT_TIMEZONE('America/New_York', col)` | `CONVERT_TIMEZONE('UTC', PSA_LOAD_DTS)` | — |
| F2 | `null_date_1900_placeholder` | WARN | .sql | NULL dates should use `'1900-01-01'::TIMESTAMP` placeholder via `IFNULL` | `IFNULL(date_col, '9999-12-31')` — wrong sentinel | `IFNULL(CONVERT_TIMEZONE('UTC', date_col), '1900-01-01'::TIMESTAMP)` | — |
| F3 | `load_dts_derivation_fivetran` | FAIL | .sql | Fivetran-sourced models: `LOAD_DTS` must derive from `CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED)` | `PSA_LOAD_DTS AS LOAD_DTS` in a Fivetran model | `CONVERT_TIMEZONE('UTC', IFF(PSA_DELETE_IND = 'Y', PSA_LOAD_DTS, _FIVETRAN_SYNCED)) AS LOAD_DTS` | — |
| F4 | `load_dts_derivation_snp_glue` | FAIL | .sql | SNP GLUE models: `LOAD_DTS` must derive from `GLCHANGETIME` using `SUBSTR`+`FF9` mask, with `PSA_DELETE_IND = 'Y'` fallback | `CONVERT_TIMEZONE('UTC', GLCHANGETIME) AS LOAD_DTS` — wrong, GLCHANGETIME is NUMBER | `IFF(PSA_DELETE_IND = 'Y', PSA_LOAD_DTS, CONVERT_TIMEZONE('UTC', TO_TIMESTAMP_NTZ(SUBSTR(GLCHANGETIME,1,14) || '.' || SUBSTR(GLCHANGETIME,16), 'YYYYMMDDHH24MISS.FF9')))` | — |
| F5 | `load_dts_has_convert_timezone` | FAIL | .sql | Every `LOAD_DTS` alias must include `CONVERT_TIMEZONE` | `PSA_LOAD_DTS AS LOAD_DTS` — raw passthrough without UTC conversion | `CONVERT_TIMEZONE('UTC', PSA_LOAD_DTS) AS LOAD_DTS` | — |

> **Confirmed in repo**: 496 v_psa_stg files use `CONVERT_TIMEZONE`. All 516 CONVERT_TIMEZONE calls found include `'UTC'` (confirmed via grep -A1). 215 models are Fivetran-sourced; 162 are SNP GLUE-sourced; ~144 are custom/other.
> Footnote: Some SNP GLUE models use an older `SUBSTR` pattern (concatenating with `||` and spaces) instead of the `TO_TIMESTAMP_NTZ` mask. See pre-existing violations section.

---

### Category G — Naming Conventions

| # | Check Name | Severity | Files Inspected | What It Inspects | Example Violation | Example Pass | Lesson # |
|---|-----------|----------|-----------------|------------------|-------------------|--------------|----------|
| G1 | `vpsa_stg_prefix` | FAIL | .sql | All SQL files in `int_staging_views/` must start with `v_psa_stg_` | `v_psa_pos_sellthrough_stages__win.sql` | `v_psa_stg_supplier__winn_sap.sql` | — |
| G2 | `hub_prefix` | FAIL | .sql | All SQL files in `raw_vault/hub/` must start with `hub_` | `dim_hub_customer.sql` | `hub_installation.sql` | — |
| G3 | `sat_prefix` | FAIL | .sql | All SQL files in `raw_vault/sat/` must start with `sat_`, `lsat_`, `msat_`, `esat_`, `lmsat_`, or `rsat_`² | `data_satellite_customer.sql` | `sat_supplier_mdm.sql`, `lsat_cbsa_zip__snfl_usps.sql`, `lmsat_mrp_lines__winn_sap.sql` | — |
| G4 | `link_prefix` | FAIL/WARN | .sql | All SQL files in `raw_vault/link/` must start with `lnk_` or `tlink_`. `link_` is accepted on **modified** files (WARN) but rejected on **new** files (FAIL). See CD-1. | `rel_customer_order.sql` (FAIL), new `link_foo.sql` (FAIL) | `lnk_goods_movement.sql`, modified `link_plant_item_v1.sql` (WARN) | — |
| G5 | `double_underscore_separator` | WARN | .sql | v_psa_stg model names should use `entity__source` pattern (double underscore) | `v_psa_stg_supplier_mdm.sql` — no source system suffix | `v_psa_stg_supplier__winn_sap.sql` | — |
| G6 | `column_names_uppercase` | WARN | .sql | Column aliases in final SELECT should be UPPERCASE | `supplier_name AS supplier_name` | `SUPPLIER_NAME AS SUPPLIER_NAME` | — |

> ² Accepted prefixes in `raw_vault/sat/`: `sat_` (325), `lsat_` (70), `msat_` (34), `lmsat_` (21), `esat_` (1), `rsat_` (1).
> `lmsat_` = Link Multi-Active Satellite — a legitimate DV 2.1 pattern with 41 files (21 SQL + 20 YAML). `rsat_` = Record Tracking Satellite (1 model).
>
> **Full FBIN model prefix inventory** (verified via `find models/ -name "*.sql"`): `v_psa_stg_` (520), `hub_` (162), `lnk_` (100), `link_` (31), `tlink_` (2), `sat_` (325), `lsat_` (70), `msat_` (34), `lmsat_` (21), `esat_` (1), `rsat_` (1), `pit_` (87), `pb_` (150), `dim_` (97), `fact_` (73), `ref_` (164), `im_` (75), `rep_` (17), `rpt_` (8), `stg_` (229 staging/base + 66 bus_vault PIT staging), `base_` (173), `bridge_` (1), `t_` (2 flat_logic temp). Non-standard one-offs: `shipment.sql` (1), `ferguson_*.sql` (1), `date_spine.sql` (1) — these are legacy bus_vault/info_mart models.
>
> **Confirmed in repo**: 1 non-v_psa_stg file in int_staging_views (`v_psa_pos_sellthrough_stages__win.sql`). 0 prefix violations in hub/. 0 violations in link/. 60 v_psa_stg files lack double underscore separator (mostly legacy/reference models).
> Footnote: Column aliases use lowercase `as` keyword (18 per file average) — this is consistent across the codebase. The CHECK validates column name case, not keyword case.

---

### Category H — Test Coverage (YAML)

| # | Check Name | Severity | Files Inspected | What It Inspects | Example Violation | Example Pass | Lesson # |
|---|-----------|----------|-----------------|------------------|-------------------|--------------|----------|
| H1 | `yaml_exists_for_sql` | FAIL | .yml | Every `.sql` model must have a corresponding `.yml` file | `v_psa_stg_supplier__winn_sap.sql` exists but no `.yml` | Both `.sql` and `.yml` exist side-by-side | #13 |
| H2 | `data_tests_not_deprecated` | FAIL | .yml | Use `data_tests:` — not deprecated `tests:` key | `tests:` at model level in YAML | `data_tests:` at model level in YAML | #7 |
| H3 | `vpsa_bk_not_null_test` | FAIL | .yml | v_psa_stg YAML must have `not_null` test on BK column(s) | No `not_null` test defined for BK | `- not_null` under BK column in data_tests | — |
| H4 | `vpsa_unique_combo_bk_load_dts` | FAIL | .yml | v_psa_stg YAML must have `unique_combination_of_columns` on BK + LOAD_DTS | No unique combo test | `- dbt_utils.unique_combination_of_columns: combination_of_columns: [SUPPLIER_BK, LOAD_DTS]` | — |
| H5 | `rv_primary_key_constraint` | FAIL | .yml | Raw vault YAML must have `dbt_constraints.primary_key` | No PK constraint defined | `- dbt_constraints.primary_key: column_name: SUPPLIER_HK` | — |
| H6 | `rv_foreign_key_constraint` | FAIL | .yml | Sat/link YAML must have `dbt_constraints.foreign_key` referencing parent hub | No FK constraint defined for sat → hub | `- dbt_constraints.foreign_key: pk_table_name: ref('hub_supplier')` | — |
| H7 | `rv_row_count_test` | WARN | .yml | Raw vault YAML should have `dbt_expectations.expect_table_row_count_to_be_between` with `min_value: 4` | No row count expectation | `- dbt_expectations.expect_table_row_count_to_be_between: min_value: 4` | — |
| H8 | `no_constraints_on_views` | FAIL | .yml | `dbt_constraints.primary_key` / `foreign_key` must NOT be defined on views (v_psa_stg) — constraints are only enforceable on tables⁴ | `dbt_constraints.primary_key` in a v_psa_stg YAML | No `dbt_constraints` entries in v_psa_stg YAML — use `not_null` + `unique_combination_of_columns` instead | — |
| H9 | `sat_grain_suggests_msat` | WARN | .yml | `sat_` or `lsat_` PK contains columns beyond parent_HK + LOAD_DTS — suggests multi-active satellite naming (msat_ / lmsat_)⁵ | `sat_foo` PK = [FOO_HK, PHONE_TYPE, LOAD_DTS] | Rename to `msat_foo` (DV 2.0: sat_ grain = HK + LOAD_DTS; msat_ grain = HK + child_key(s) + LOAD_DTS) | — |

> ⁴ Snowflake cannot enforce PK/FK constraints on views — defining them creates misleading metadata and wastes CI time. Found in Pegasus/Corvus POD reviews.
>
> ⁵ DV 2.0 standard: `sat_` grain = parent_HK + LOAD_DTS (one record per key per load). If the PK includes additional columns (e.g., PHONE_TYPE, SEQUENCE_NUM), the table is multi-active and should be named `msat_` (or `lmsat_` for link satellites). This is advisory (WARN) — some edge cases may intentionally use sat_ with extended grain.
>
> **Confirmed in repo**: 26 v_psa_stg YAML files have `dbt_constraints` entries (violation). 7 v_psa_stg SQL files missing YAML. 13 raw vault link files missing YAML (of 50 checked). 234 v_psa_stg YAMLs have `data_tests:`. 389 raw vault YAMLs have `not_null`. 677 raw vault YAMLs have `primary_key`. 353 have `foreign_key`. 507 have `row_count` test. 485 v_psa_stg YAMLs have `unique_combination_of_columns`.
> **Major finding**: 1,167 YAML files across all layers still use deprecated `tests:` instead of `data_tests:`. 408 of these are in raw vault alone.

---

### Category I — Source & Layer Integrity

| # | Check Name | Severity | Files Inspected | What It Inspects | Example Violation | Example Pass | Lesson # |
|---|-----------|----------|-----------------|------------------|-------------------|--------------|----------|
| I1 | `uses_source_or_ref` | FAIL | .sql | All FROM clauses must use `{{ source(...) }}` or `{{ ref(...) }}` — no direct `SCHEMA.TABLE` | `FROM SAP_ECC_PRD.Z_VBUP` | `FROM {{ source('sap_ecc_prd', 'z_vbup') }}` | — |
| I2 | `no_cross_layer_ref_down` | FAIL | .sql | Raw vault/bus vault must NOT ref() info_mart models (layer violation) | `{{ ref('im_pos_dim_date_fiscal_445') }}` in a bus_vault PIT model | Only ref() models in the same or lower layer | — |
| I3 | `dim_fact_no_business_logic` | WARN | .sql | `dim_*` and `fact_*` models should NOT contain `CASE WHEN` or filtering `WHERE` clauses — logic belongs in PIT/PB | `CASE WHEN status = 'Active' THEN ...` in a dim_ model | `SELECT * FROM {{ ref('pit_customer') }}` — simple wrapper | — |
| I4 | `source_registered_in_yaml` | WARN | .yml | Every `{{ source() }}` call should have a matching entry in `_sources_staging_psa.yml` | Source used but not declared in sources YAML | Source declared in `_sources_staging_psa.yml` | #13 |

> **Confirmed in repo**: 41 direct `SCHEMA.TABLE` references in v_psa_stg (all in quality/ and one in shipments/). 5 bus_vault PIT models ref() info_mart (`im_pos_dim_date_fiscal_445`). 3 fact_ models have `CASE WHEN`. 5 dim_ models have `WHERE` filters. 5 fact_ models have `WHERE` filters.

---

### Category J — Incremental Model Config

| # | Check Name | Severity | Files Inspected | What It Inspects | Example Violation | Example Pass | Lesson # |
|---|-----------|----------|-----------------|------------------|-------------------|--------------|----------|
| J1 | `where_not_exists_uses_hashdiff` | FAIL | .sql | Satellite `WHERE NOT EXISTS` must compare on HK **AND** HASHDIFF (not just HK) | `WHERE NOT EXISTS (SELECT 1 FROM existing WHERE existing.HK = new.HK)` — misses HASHDIFF | `WHERE NOT EXISTS (SELECT 1 FROM existing WHERE existing.HK = new.HK AND existing.HASHDIFF = new.HASHDIFF)` | — |
| J2 | `hub_where_not_exists_hk_only` | WARN | .sql | Hub `WHERE NOT EXISTS` should compare on HK only (no HASHDIFF — hubs have no attributes) | `AND existing.HASHDIFF = ...` in a hub model | `WHERE NOT EXISTS (SELECT 1 FROM existing WHERE existing.HK = new.HK)` | — |
| J3 | `on_schema_change_config` | WARN | .sql/.yml | Incremental raw vault models should inherit `on_schema_change: sync_all_columns` from `dbt_project.yml` — explicit override only if different | Per-model override without justification | Inherits from `dbt_project.yml` default: `+on_schema_change: "sync_all_columns"` | — |
| J4 | `full_refresh_guard` | WARN | .sql | Large-volume models should have `full_refresh = var('force_full_refresh', false)` | Large table (>50M rows) with no full_refresh guard | `full_refresh = var('force_full_refresh', false)` in config block | — |
| J5 | `watermark_scoped_per_rec_src` | FAIL | .sql | Incremental watermark must be scoped per `REC_SRC` (with `GROUP BY REC_SRC`) — global `MAX(LOAD_DTS)` causes full-table scans masquerading as incremental⁵ | `WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})` — global watermark, no REC_SRC filter | `INCR_WATERMARK AS (SELECT REC_SRC AS wm_REC_SRC, DATEADD(DAY, -1, MAX(LOAD_DTS)) AS watermark_dts FROM {{this}} GROUP BY REC_SRC)` with `INNER JOIN INCR_WATERMARK ON SRC.REC_SRC = wm_REC_SRC AND SRC.LOAD_DTS > watermark_dts` | — |

> ⁵ When a multi-source model has sources with different load cadences, a global MAX(LOAD_DTS) uses the most recent source's timestamp as the watermark for ALL sources — causing older sources to be filtered out entirely. Per-REC_SRC scoping ensures each source has its own watermark.
>
> **Confirmed in repo**: 8 hub models use per-REC_SRC watermark (`GROUP BY REC_SRC`). **303 sat models use global watermark** (no REC_SRC scoping) — however, per V11 analysis, satellites are single-source by DV 2.0/2.1 standard, so global watermarks are functionally correct for sats. J5 is therefore scoped to hubs and links only (the layers where multiple REC_SRC values can coexist). 366 sats use `WHERE NOT EXISTS` with HASHDIFF comparison. 122 hubs use HK-only comparison. 103 links use `WHERE NOT EXISTS`. `dbt_project.yml` sets `+on_schema_change: "sync_all_columns"` globally for raw_vault. 14 models have explicit `full_refresh` override — all use the `var('force_full_refresh', false)` pattern.

---

### Category K — Ghost Record Standards

| # | Check Name | Severity | Files Inspected | What It Inspects | Example Violation | Example Pass | Lesson # |
|---|-----------|----------|-----------------|------------------|-------------------|--------------|----------|
| K1 | `ghost_record_decode_pattern` | FAIL | .sql | Ghost records must use `DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')` for BKCC. **Fires only when model contains BKCC column** — satellites without BKCC are skipped | Custom ghost BKCC strings | `DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC` | — |
| K2 | `ghost_record_three_sentinels` | FAIL | .sql | Ghost records must include all three sentinel values (0, -1, -2) | Only sentinel 0 (SYSTEM) present | `strtok_split_to_table('0|-1|-2', '|')` generating all three | — |
| K3 | `ghost_record_load_dts` | WARN | .sql | Ghost record LOAD_DTS should be `CONVERT_TIMEZONE('UTC', '1900-01-01'::TIMESTAMP)` | `'1970-01-01'::TIMESTAMP` or `CURRENT_TIMESTAMP()` | `CONVERT_TIMEZONE('UTC', '1900-01-01'::TIMESTAMP) AS LOAD_DTS` | — |
| K4 | `ghost_record_rec_src` | WARN | .sql | Ghost record REC_SRC should be `'USAZET.SNOWFLAKE.FBIN.DERIVED'` | `'SYSTEM' AS REC_SRC` | `'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC` | — |
| K5 | `ghost_record_hk_formula` | FAIL | .sql | Ghost record HK must use `MD5_BINARY(GR.VALUE)` — not a binary literal | `x'0000000000000000' AS HK` | `MD5_BINARY(GR.VALUE) AS INSTALLATION_HK` | — |

> **Confirmed in repo**: 119 hub files, 226 sat files, and 4 link files have ghost record DECODE pattern. All use the standard 3-sentinel pattern. All use `MD5_BINARY(GR.VALUE)` — zero binary literal ghost HKs found. Ghost records use `strtok_split_to_table('0|-1|-2', '|')` for generation.

---

### Category L — Join Patterns

| # | Check Name | Severity | Files Inspected | What It Inspects | Example Violation | Example Pass | Lesson # |
|---|-----------|----------|-----------------|------------------|-------------------|--------------|----------|
| L1 | `inner_join_has_comment` | WARN | .sql | Non-BKCC `INNER JOIN` should have an inline `--` comment explaining why | `INNER JOIN dim_product ON ...` — no explanation | `INNER JOIN dim_product ON ... -- required: 1:1 match guaranteed` | #9 |
| L2 | `left_join_default_lookups` | WARN | .sql | Lookup joins should default to `LEFT JOIN` — INNER JOIN only with justification | INNER JOIN on a lookup where NULLs are possible | `LEFT JOIN ref_table ON ...` | #9 |

> **Confirmed in repo**: 502 v_psa_stg files use INNER JOIN. The vast majority are BKCC joins (`ON '1' = '1'`). Non-BKCC INNER JOINs rarely have inline comments. LEFT JOIN is used for lookup joins across the codebase.

---

### Category M — Miscellaneous Standards

| # | Check Name | Severity | Files Inspected | What It Inspects | Example Violation | Example Pass | Lesson # |
|---|-----------|----------|-----------------|------------------|-------------------|--------------|----------|
| M1 | `no_hardcoded_env` | FAIL | .sql | No hardcoded environment names (`'DEV'`, `'QA'`, `'PRD'`) — use `env_var()` or Jinja | `WHERE environment = 'PRD'` | `{{ env_var('DBT_ENVIRON') }}` | — |
| M2 | `no_select_star_outside_src` | WARN | .sql | `SELECT *` should only appear in SRC CTEs and passthrough RENAME/FILTER CTEs³ | `SELECT * FROM hub_customer` in a business vault model | `SELECT * FROM {{ source(...) }}` in SRC CTE only | #3, #15 |
| M3 | `rec_src_format` | WARN | .sql | REC_SRC should follow `Location.System.Application.Table` format | `'SAP' AS REC_SRC` | `'USOHNO.SAP.ECCPRD.Z_LFA1' AS REC_SRC` | — |
| M4 | `header_comment_present` | WARN | .sql | SQL files should have a header comment (`---- SRC LAYER ----` or equivalent) | No comment at line 1 | `---- SRC LAYER ----` at top of file | — |
| M5 | `fix_proof_atomicity_prompt` | WARN | .py | Confirm-style reviewer prompt when triage source code changes, to verify fix+proof atomicity in the same commit | Changed `scripts/automation/src/triage/*.py` with no explicit reviewer check | Same commit includes behavior change and proving test (reviewer-confirmed) | Approved lesson: Fix+proof |

> ³ In the 6-layer pattern, RENAME/FILTER/JOIN CTEs use `SELECT *` as passthroughs — this is expected and correct for legacy models.
>
> **Confirmed in repo**: 0 hardcoded env references found. Legacy models use `SELECT *` in RENAME/FILTER/JOIN CTEs (expected). All sampled files have `---- SRC LAYER ----` header comment.

---

### Category N — Staging Data Integrity

| # | Check Name | Severity | Files Inspected | What It Inspects | Example Violation | Example Pass | Lesson # |
|---|-----------|----------|-----------------|------------------|-------------------|--------------|----------|
| N1 | `no_delete_flag_filter` | FAIL | .sql | NEVER filter on `_FIVETRAN_DELETED` or `PSA_DELETE_IND` at the staging layer — these are DATA columns tracked in HASHDIFF | `WHERE PSA_DELETE_IND = 'N'`, `WHERE ... AND _FIVETRAN_DELETED = FALSE` | Delete flags in SELECT/HASHDIFF but NOT in WHERE | #28 |
| N2 | `coalesce_on_payload_in_staging` | WARN | .sql | COALESCE/IFNULL on payload (non-BK) columns in LOGIC CTE is prohibited — null replacement belongs in Business Vault | `COALESCE(VENDOR_STATUS, 'UNKNOWN') AS VENDOR_STATUS` in LOGIC | BK columns may use COALESCE; payload columns pass through as-is | #58 |
| N3 | `primary_src_no_business_rules` | WARN | .sql | Primary/driver source CTE (first non-BKCC `SRC_*` CTE) must NOT have WHERE or QUALIFY without an inline comment explaining intent — staging has no soft business rules | `SRC_S as ( SELECT ... FROM {{ source(...) }} WHERE PSA_DELETE_IND = 'N' QUALIFY ROW_NUMBER()... )` without comments | Same SQL with `-- exclude deletes per JIRA-1234` comment on the WHERE line | — |

> **Scope**: N1 and N2 are scoped to `int_staging_views/` ONLY. Bus vault models CAN legitimately filter on delete flags and apply COALESCE.
> N3 is scoped to `int_staging_views/` ONLY. Secondary source CTEs (SRC_FAR, SRC_AP, etc.) are exempt — they need QUALIFY for 1:1 join cardinality.
>
> **Confirmed in repo**: 10+ v_psa_stg files have WHERE clauses on PSA_DELETE_IND or _FIVETRAN_DELETED (pre-existing violations). N2 targets new models — existing LOGIC CTEs rarely use standalone COALESCE on payload columns.

---

### Additional CTE & QUALIFY Checks (added to existing categories)

| # | Check Name | Severity | Files Inspected | What It Inspects | Example Violation | Example Pass | Lesson # |
|---|-----------|----------|-----------------|------------------|-------------------|--------------|----------|
| C4 | `where_in_src_cte_only` | WARN | .sql | WHERE clause must be in SRC CTE, not LOGIC layer. WHERE in FILTER CTEs is acceptable (legacy 6-layer). | `WHERE VENDOR_STATUS = 'ACTIVE'` inside LOGIC_S CTE | `WHERE BU = 'WATER'` inside SRC_S CTE | #20 |
| E3 | `qualify_order_by_load_dts` | WARN | .sql | Hub and LNK QUALIFY ORDER BY must use LOAD_DTS — never raw ingestion columns | `QUALIFY ROW_NUMBER() OVER(... ORDER BY GLCHANGETIME)` in hub | `QUALIFY ROW_NUMBER() OVER(... ORDER BY LOAD_DTS)` | #61 |

> **Scope**: C4 scoped to `int_staging_views/`. E3 scoped to `raw_vault/hub/` and `raw_vault/link/`.
> E3 exempts `DECODE()` ORDER BY (intentional multi-source precedence pattern in links).
>
> **Confirmed in repo**: Multiple legacy hubs use GLCHANGETIME/ZEXTRACTDATE/_FIVETRAN_SYNCED in QUALIFY (pre-existing violations). WHERE in FILTER CTEs is the standard legacy pattern (not flagged).

---

### Category O — Multi-Source Model Safety

> **Context**: These checks were derived from Copilot PR Reviewer + human review comments on PRs #1744, #1752, #1753 (May 2026). They address data loss risks specific to models that UNION multiple source systems.

| # | Check Name | Severity | Files Inspected | What It Inspects | Example Violation | Example Pass | Lesson # |
|---|-----------|----------|-----------------|------------------|-------------------|--------------|----------|
| O1 | `multi_source_not_exists_includes_rec_src` | FAIL | .sql | Multi-source incremental `NOT EXISTS` must include REC_SRC/BKCC (or use HK) in the match criteria — plain BK/ID matching can suppress valid rows when IDs overlap between sources | `WHERE NOT EXISTS (SELECT 1 FROM {{this}} WHERE PRODUCT_ID = src.PRODUCT_ID AND HASHDIFF = src.HASHDIFF)` — no REC_SRC | `WHERE NOT EXISTS (SELECT 1 FROM {{this}} WHERE COMPETITIVE_PRODUCT_HK = src.COMPETITIVE_PRODUCT_HK AND HASHDIFF = src.HASHDIFF)` — HK incorporates BKCC | — |
| O2 | `multi_source_qualify_includes_rec_src` | FAIL | .sql | Multi-source QUALIFY `PARTITION BY` must include REC_SRC when deduplicating — without it, one source can eliminate another's valid rows when natural keys overlap | `QUALIFY ROW_NUMBER() OVER (PARTITION BY PRODUCT_ID, HASHDIFF ORDER BY LOAD_DTS DESC) = 1` — no REC_SRC | `QUALIFY ROW_NUMBER() OVER (PARTITION BY PRODUCT_ID, REC_SRC ORDER BY LOAD_DTS DESC) = 1` | — |
| O3 | `qualify_no_hashdiff_in_partition` | FAIL | .sql | HASHDIFF must NOT appear in QUALIFY `PARTITION BY` — it defeats dedup and preserves duplicate attribute versions. If intentional (e.g., collapsing duplicate loads of the same change), an inline `--` comment is required | `QUALIFY ROW_NUMBER() OVER (PARTITION BY SUPPLIER_HK, HASHDIFF ORDER BY LOAD_DTS DESC) = 1` — keeps one per attribute combo (no actual dedup) | `QUALIFY ROW_NUMBER() OVER (PARTITION BY SUPPLIER_HK ORDER BY LOAD_DTS DESC) = 1` | — |
| O4 | `ghost_union_column_order_matches_main` | FAIL | .sql | Ghost record `UNION ALL` branch must have columns in the same positional order as the main SELECT — UNION aligns by position, mismatches silently swap values (e.g., BKCC ↔ REC_SRC) | Ghost SELECT: `REC_SRC, BKCC` when main SELECT has `BKCC, REC_SRC` | Column order in ghost matches main SELECT exactly | — |
| O5 | `qualify_no_literal_order_by` | FAIL | .sql | QUALIFY `ORDER BY` must NOT use literal constants (`ORDER BY 1`, `ORDER BY 2`) — produces non-deterministic row selection. Use a meaningful column (LOAD_DTS, REC_SRC) | `QUALIFY ROW_NUMBER() OVER (PARTITION BY BRAND_BK ORDER BY 1) = 1` — random selection | `QUALIFY ROW_NUMBER() OVER (PARTITION BY BRAND_BK ORDER BY LOAD_DTS DESC) = 1` | — |

> **Scope**: O1 and O2 apply only to multi-source models (detected by presence of UNION/UNION ALL of 2+ source CTEs in the same file). O3 and O5 apply to ALL models with QUALIFY. O4 applies to all raw vault models with ghost record UNION ALL.
>
> **Detection heuristic for "multi-source"**: File contains `UNION ALL` (or `UNION`) joining 2+ named source CTEs (e.g., `SRC_FIBERON`, `SRC_WINN`), OR the `JOIN_RESULT`/`FINAL` CTE selects from multiple source CTEs via UNION.
>
> **O3 exception**: HASHDIFF in PARTITION BY is accepted IF an inline comment (`--`) exists on the same line or preceding line explaining the intent. The check should scan for a comment token within ±1 line of the PARTITION BY clause containing HASHDIFF.

---

### Category P — Business Vault Quality

> **Context**: Derived from human reviewer (Kumar-ganap) comments on PR #1744 (May 2026). Addresses patterns in PIT, PB, and pit_stg models that waste compute or provide false test confidence.

| # | Check Name | Severity | Files Inspected | What It Inspects | Example Violation | Example Pass | Lesson # |
|---|-----------|----------|-----------------|------------------|-------------------|--------------|----------|
| P1 | `pk_not_on_generated_column` | FAIL | .yml + .sql | PK/uniqueness test must NOT target a column generated via `ROW_NUMBER()` (e.g., SEQ_ID) — such tests are tautologically true and provide no grain validation | YAML: `combination_of_columns: [SEQ_ID]` where SQL has `ROW_NUMBER() ... AS SEQ_ID` | `combination_of_columns: [BRAND_BK]` — tests the actual business grain | — |
| P2 | `bv_primary_key_defined` | FAIL | .yml | PIT and PB models must have a `dbt_constraints.primary_key` or `dbt_utils.unique_combination_of_columns` test — cannot be empty | PB YAML with no PK or uniqueness test at all | `- dbt_constraints.primary_key: column_name: LNK_PO_ITEM_HK` or `- dbt_utils.unique_combination_of_columns: ...` | — |
| P3 | `pit_stg_no_pit_metadata` | WARN | .sql | `pit_stg_*` / `stg_pit_*` ephemeral models must NOT compute `SEQ_ID`, `SNAPSHOTDATE`, or `PIT_LOAD_DTS` in their output — the downstream PIT model generates its own metadata | `ROW_NUMBER() ... AS SEQ_ID, CURRENT_TIMESTAMP() AS PIT_LOAD_DTS` in a stg_pit_ model | stg_pit_ model outputs only business columns (no SEQ_ID, SNAPSHOTDATE, PIT_LOAD_DTS) | — |
| P4 | `pit_has_qualify_dedup` | WARN | .sql | PIT models that UNION multiple source staging models should have a QUALIFY dedup on the business grain — prevents duplicates when the same entity exists in multiple sources | `pit_brand_v2.sql` UNIONs profitero + profitero_share with no QUALIFY | `QUALIFY ROW_NUMBER() OVER (PARTITION BY BRAND_BK ORDER BY LOAD_DTS DESC) = 1` after UNION | — |
| P5 | `unreferenced_ephemeral_model` | FAIL | .sql | Ephemeral models (`materialized='ephemeral'`) must be referenced by at least one other model via `ref()` — otherwise they are dead code that never builds | `stg_pit_order_line__tt_e21.sql` with `materialized='ephemeral'` but no `ref('stg_pit_order_line__tt_e21')` anywhere | At least one downstream model contains `{{ ref('stg_pit_order_line__tt_e21') }}` | — |
| P6 | `unused_yaml_schema_file` | WARN | .yml | YAML schema files must correspond to an existing `.sql` model file — orphan YAMLs add confusion | `pit_stg_product__profitero_share.yml` exists but no matching `.sql` file (or the SQL file was deleted) | Both `.yml` and `.sql` coexist | — |

> **Scope**: P1 cross-references `.yml` PK/uniqueness test column names against the `.sql` file to detect `ROW_NUMBER() ... AS <column>` patterns. P2 scoped to `bus_vault/pit*/` and `bus_vault/pit_bridge/` paths. P3 scoped to files matching `stg_pit_*` or `pit_stg_*` prefix. P4 scoped to `bus_vault/pit/` models containing UNION. P5 requires a repo-wide `grep -r "ref('model_name')"` for each ephemeral model. P6 checks for matching `.sql` file existence.
>
> **P1 detection**: Parse YAML for `combination_of_columns` or `column_name` in PK tests → for each column, grep the corresponding SQL for `ROW_NUMBER().*AS\s+{column}` — if found, flag.
>
> **P5 detection**: For each file with `materialized='ephemeral'` in config(), extract model name from filename, then `grep -r "ref('{model_name}')" models/` — if 0 hits, flag as dead code.

---

### Category Q — Conceptual Modeling

> **Context**: DESIGN-level modeling risks that pass every syntactic check but corrupt data — the conceptual layer documented in `.github/knowledge/data-vault/`. All WARN (advisory): design decisions belong to the engineer, so the reviewer surfaces the risk and cites the trap, never blocks. **Implemented** (Q1–Q2); extensible per `08-modeling-traps.md`. Introduced in PR #1910. (Distinct from Category O — Multi-Source Model Safety — and Category P — Business Vault Quality, both documented-pending.)

| # | Check Name | Severity | Files Inspected | What It Inspects | Example Violation | Example Pass | Lesson # |
|---|-----------|----------|-----------------|------------------|-------------------|--------------|----------|
| Q1 | `link_hk_component_collision` | WARN | .sql | Two distinct hash keys in one v_psa_stg model must not share an identical ordered raw-column component list — `CONCAT_WS('||', 'A||B', 'C') == CONCAT_WS('||', 'A', 'B', 'C')`, so a link HK over a composite BK's raw columns can hash byte-identical to the line hub HK (TRAP-01). Matches `'^^'`/`'-1'`/`'-2'` sentinels; compares only on complete extraction | `INVOICE_LINE_HK` and `LNK_INVOICE_LINE_HK` both = `[INVOICE_ID, LINE_NUMBER, BKCC]` | Duplicate the shared leading component in the link HK: `[INVOICE_ID, INVOICE_ID, LINE_NUMBER, BKCC]` (duplicate intentional) | — |
| Q2 | `satellite_pii_not_split` | WARN | .sql | PII attributes in a non-PII descriptive satellite should be split into a sibling `*_pii__*` satellite so a column-level masking policy can target it. Treats `_` as a token separator (so `CUSTOMER_EMAIL` matches) | `sat_customer__crm.sql` containing `EMAIL`/`SSN` alongside non-PII columns | PII split into `sat_customer_pii__crm.sql` (same parent HK) | — |

> **Scope**: Q1 runs on `int_staging_views/` models only (where HK formulas live); it compares HK component lists **within a single model**. Q2 runs on descriptive satellites (`sat_`/`lsat_`/`msat_`/`lmsat_`) under `raw_vault/sat/`, skipping models whose name already contains `pii`. Both are advisory (WARN); cross-model reasoning (TRAP-02 cross-domain BKCC, TRAP-03 non-co-occurring links) stays with the DV Knowledge Advisor.

---

## Summary Statistics

| Metric | Value |
|--------|-------|
| Total checks | 63 |
| FAIL severity | 43 |
| WARN severity | 20 |
| Categories | 17 (A–Q) |
| Check functions implemented | A–N + Q1–Q2 registered; O1–O5, P1–P6 pending |
| Unit tests implemented | A–N + Q1–Q2 covered; O1–O5, P1–P6 pending |

### Checks by Category

| Category | Count | Focus |
|----------|-------|-------|
| A — Hash Key (HK) | 5 | CONCAT_WS, COALESCE, raw col names, BKCC position |
| B — HASHDIFF | 7 | NULLIF+CONCAT, exclusions, PSA_DELETE_IND, sentinel |
| C — CTE Structure | 4 | 4-layer vs 6-layer, naming, final SELECT, WHERE placement |
| D — BKCC | 3 | Join pattern, ref table, presence |
| E — Dedup/QUALIFY | 3 | No SELECT DISTINCT, ROW_NUMBER, ORDER BY LOAD_DTS |
| F — Date/Timezone | 5 | UTC, 1900-01-01, LOAD_DTS derivation |
| G — Naming | 6 | Prefixes, double underscore, uppercase |
| H — Test Coverage | 8 | YAML exists, data_tests, PK/FK/row count, no constraints on views |
| I — Source/Layer | 4 | source()/ref(), cross-layer, dim/fact logic |
| J — Incremental Config | 5 | WHERE NOT EXISTS, on_schema_change, full_refresh, watermark per REC_SRC |
| K — Ghost Records | 5 | DECODE, 3 sentinels, LOAD_DTS, HK formula |
| L — Join Patterns | 2 | INNER JOIN comment, LEFT JOIN default |
| M — Miscellaneous | 4 | Hardcoded env, SELECT *, REC_SRC format, header |
| N — Staging Data Integrity | 2 | Delete flag filtering, COALESCE placement |
| O — Multi-Source Safety | 5 | NOT EXISTS REC_SRC, QUALIFY REC_SRC, HASHDIFF in partition, ghost col order, literal ORDER BY |
| P — Business Vault Quality | 6 | PK on generated col, BV PK defined, pit_stg metadata, PIT dedup, dead ephemeral, orphan YAML |
| Q — Conceptual Modeling | 2 | Link HK component collision (TRAP-01), PII satellite split |

---

## Pre-existing Violations Found During Inventory

These violations exist in the current codebase. They are NOT blockers for new code review but should be tracked for remediation.

### V1. Direct table references (no `source()` or `ref()`) — 41 files

All in `models/int_staging_views/quality/` and one in `shipments/`:
- `models/int_staging_views/shipments/v_psa_stg_order_line_status__winn_sap.sql` → `FROM SAP_ECC_PRD.Z_VBUP`
- `models/int_staging_views/quality/v_psa_stg_quality_notifications.sql` → `FROM SAP_ECC_PRD.Z_QMEL`
- `models/int_staging_views/quality/v_psa_stg_quality_messages.sql` → `FROM SAP_ECC_PRD.Z_QMIH`
- `models/int_staging_views/quality/v_psa_stg_plant_maintenance_partners.sql` → `FROM SAP_ECC_PRD.Z_IHPA`
- `models/int_staging_views/quality/v_psa_stg_object_location_account_assignment.sql` → `FROM SAP_ECC_PRD.Z_ILOA`
- `models/int_staging_views/quality/v_psa_stg_notification_types.sql` → `FROM SAP_ECC_PRD.Z_TQ80`
- *(and ~35 more in quality/)*

### V2. Deprecated `tests:` key in YAML — ~1,167 files across all layers

Most prevalent in raw vault (408 files) and legacy models. Should be migrated to `data_tests:`.
- `models/raw_vault/link/lnk_goods_movement.yml`
- `models/raw_vault/link/lnk_purchase_requisition.yml`
- `models/raw_vault/link/lnk_planned_order.yml`
- *(systemic across all raw vault link/sat/hub YAMLs)*

### V3. Missing YAML files — 7 v_psa_stg + 13+ raw vault

**v_psa_stg missing YAML**:
- `models/int_staging_views/shipments/v_psa_stg_customer_site__ml_ebs.sql`
- `models/int_staging_views/shipments/v_psa_stg_copa_sales_history__winn_sap.sql`
- `models/int_staging_views/connected_device/v_psa_stg_flow_event_daily.sql`
- `models/int_staging_views/competitive_share/v_psa_stg_item_details__datavations.sql`
- `models/int_staging_views/pricing/v_psa_stg_price_availability__profitero_winn.sql`
- `models/int_staging_views/reference/v_psa_stg_ref_avc_talend_migration_cutoff_date.sql`
- `models/int_staging_views/reference/v_psa_stg_ref_appbot_talend_migration_cutoff_date.sql`

**Raw vault missing YAML** (sample of 50 checked):
- `models/raw_vault/link/lnk_category_products.sql`
- `models/raw_vault/link/link_invoice_adj_sales_agency.sql`
- `models/raw_vault/link/link_invoice_delivery.sql`
- `models/raw_vault/link/link_review_brand_appbot.sql`
- *(13 total in the 50 checked — likely more across full set)*

### V4. `SELECT DISTINCT` in bus_vault — 3 files

- `models/bus_vault/pit_bridge/bom/pb_bom_hierarchy.sql` (lines 24, 165)
- `models/bus_vault/pit_bridge/boo/pb_bill_of_operation.sql` (line 170)
- `models/bus_vault/pit_bridge/general_ledger/pb_product_sales.sql` (line 11)

### V5. Non-standard v_psa_stg prefix — 1 file

- `models/int_staging_views/pos/v_psa_pos_sellthrough_stages__win.sql` — uses `v_psa_pos_` instead of `v_psa_stg_`

### V6. Bus vault PIT models referencing info_mart (cross-layer) — 5 occurrences

- `models/bus_vault/pit/pos/amazon/stg_pit_pos_amazon_weekly.sql` → refs `im_pos_dim_date_fiscal_445`
- `models/bus_vault/pit/pos/homedepot/stg_pit_pos_homedepot_weekly.sql` → refs `im_pos_dim_date_fiscal_445`
- `models/bus_vault/pit/pos/menards/stg_pit_pos_fbin_larson_menards_weekly.sql` → refs `im_pos_dim_date_fiscal_445`

### V7. Business logic in dim_/fact_ models

**dim_ with WHERE filter** (should be in PIT):
- `models/bus_vault/dim/dim_gl_account.sql`
- `models/bus_vault/dim/dim_items_by_plant.sql`
- `models/bus_vault/dim/dim_sales_order_header.sql`

**fact_ with CASE WHEN** (should be in PB):
- `models/bus_vault/fact/fact_device_telemetry_coverage_period.sql`
- `models/bus_vault/fact/fact_daily_location_counts.sql`
- `models/bus_vault/fact/fact_incident_false_alarm_device_period.sql`

**fact_ with WHERE filter** (should be in PB):
- `models/bus_vault/fact/fact_controlling_ledger_entry.sql`
- `models/bus_vault/fact/fact_gl_account_details.sql`
- `models/bus_vault/fact/fact_open_po_spend_summary.sql`
- `models/bus_vault/fact/fact_global_direct_spend_daily_summary.sql`
- `models/bus_vault/fact/fact_delivery_line_item.sql`

### V8. v_psa_stg models without double underscore separator — 60 files

Mostly legacy consumer_feedback and reference models:
- `models/int_staging_views/consumer_feedback/v_psa_stg_dim_categories.sql`
- `models/int_staging_views/consumer_feedback/v_psa_stg_sentiment_output.sql`
- `models/int_staging_views/consumer_feedback/v_psa_stg_centercode.sql`
- *(57 more)*

### V9. ~~`lmsat_` prefix (non-standard but accepted)~~ — RESOLVED

`lmsat_` = Link Multi-Active Satellite — accepted as legitimate DV 2.1 pattern. Added to G3 accepted prefix list alongside `rsat_` (Record Tracking Satellite, 1 model).

> V9 resolved — `lmsat_` added to G3 accepted prefix list.

### V10. `dbt_constraints` on views (v_psa_stg) — 26 files

Snowflake cannot enforce PK/FK constraints on views. These create misleading metadata.
- `models/int_staging_views/shipments/v_psa_stg_logistics_shipment_stage__winn_sap.yml`
- `models/int_staging_views/bom/v_psa_stg_bom_component_item__winn_sap.yml`
- `models/int_staging_views/bom/v_psa_stg_bom_plant_item__winn_sap.yml`
- `models/int_staging_views/bom/v_psa_stg_bom_header__winn_sap.yml`
- `models/int_staging_views/bom/v_psa_stg_bom_component_selection__winn_sap.yml`
- *(21 more across bom/, shipments/, and other domains)*

### ~~V11. Global watermark without per-REC_SRC scoping — 303 sat files~~ INVALID

**Status: INVALID — false positive (resolved in commit eb2fa4ef).**

Per DV 2.0/2.1 standard, satellites are bound to a single REC_SRC by design — one satellite per source system. A global `MAX(LOAD_DTS)` watermark is functionally correct for all satellites because there is only one source. J5 has been scoped to hubs and links only (the layers where multiple `REC_SRC` values can coexist in a single model).

The 303 satellite models are **correctly** using global watermarks. No remediation needed.

~~**V11 is the highest-impact pre-existing finding.** Recommend creating a JIRA epic for per-REC_SRC watermark remediation across all 303 satellites, prioritized by Snowflake compute cost. Multi-source sats (those with >1 distinct REC_SRC in production data) should be remediated first — these are the models where global watermarks cause actual data quality risk. Single-source sats are functionally correct but should be migrated for consistency and to prevent regressions if a second source is added later.~~

---

## Golden-file Regression Test Plan

### Purpose
Snapshot generated SQL/YAML for validated E2E pipelines. When `pipeline_orchestrator.py` or `build.py` changes, diff the re-generated output against the golden snapshot. Catches unintended regressions.

### Candidate Golden Files

| Pipeline | Source Table | Model Name | Covers |
|----------|-------------|------------|--------|
| Fivetran single-BK | `ps_l_rep_cust` | `v_psa_stg_customer__lrsn_psft` | Fivetran LOAD_DTS, standard HK/HASHDIFF |
| SNP GLUE single-BK | `z_lfa1` | `v_psa_stg_supplier__winn_sap` | GLCHANGETIME parsing, 6-layer CTE |
| Multi-BK | `consolidated_promo_flow_input` | `v_psa_stg_consolidated_promo_flow_input__winn_rgm` | Multi-BK, complex joins |
| Hub + Sat | (from above) | `hub_supplier` + `sat_supplier__winn_sap` | Ghost records, WHERE NOT EXISTS |

### Test Structure

```
tests/golden/
  fixtures/
    v_psa_stg_customer__lrsn_psft.sql.expected    # Snapshot of generated SQL
    v_psa_stg_customer__lrsn_psft.yml.expected    # Snapshot of generated YAML
    v_psa_stg_supplier__winn_sap.sql.expected
    ...
  test_golden_regression.py                        # pytest: regenerate → diff
```

### Test Flow
1. Store known-good output as `.expected` files
2. On each test run: re-generate from same YAML config via `build.py`
3. `diff` generated vs expected — any delta = test failure
4. Maintainer reviews delta and updates `.expected` if the change is intentional

---

## Implementation Phases (Post-Approval)

| Phase | Timeline | Deliverable |
|-------|----------|-------------|
| 1 | Week 1-2 | `Finding` dataclass, 46 check functions in `code_reviewer.py`, CLI entry point, `.code_review_ignore` loader, `EXCLUDED_PATHS` filter, `git diff` new-vs-modified detection (CD-1/CD-2/CD-3), pytest unit tests (46 checks × pass + fail = 92+ test cases) |
| 2 | Week 3 | GitHub Actions workflow step, PR comment formatting, severity-based status checks, auto-approve when 0 FAILs |
| 3 | Week 4 | Battle-test on 10-15 real PRs, tune false positives, update thresholds |
| 4 | Week 5+ | Extract to Skills Library if function count > 80 or team requests modularity |
