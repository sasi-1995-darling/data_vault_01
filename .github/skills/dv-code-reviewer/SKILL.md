---
name: dv-code-reviewer
description: >
  Reviews Data Vault 2.x dbt models for compliance with FBIN standards.
  Use when reviewing PRs, validating generated code, or checking existing
  models against current standards. Covers hash key formulas, CTE structure,
  BKCC patterns, naming conventions, test coverage, and guardrails.
allowed-tools: "Read Grep Glob"
activation: auto
disable-model-invocation: false
paths:
  - "models/**"
  - "tests/**"
arguments: "$ARGUMENTS contains the model name or file path to review"
metadata:
  author: FBIN Data Engineering
  version: 1.0.0
  category: data-vault
---

# DV Code Reviewer

> **Standards:** See `CLAUDE.md` Navigation Guide for rules file locations.

## When to Use
- Reviewing a PR that touches `models/` or `tests/`
- Validating generated v_psa_stg, hub, sat, or link models
- Checking existing models against current DV 2.x standards
- Pre-merge quality gate

## Review Checklist

### 1. Naming Conventions
- [ ] Table prefix matches layer (`v_psa_stg_`, `hub_`, `sat_`, `lnk_`, `pit_`, `dim_`, `fact_`)
- [ ] Column names are UPPERCASE in SQL
- [ ] Table names are lowercase with underscores
- [ ] HK suffix: `_HK`, BK suffix: `_BK`, Link HK prefix: `LNK_`
- [ ] Standard columns present: `BKCC`, `LOAD_DTS`, `REC_SRC`, `HASHDIFF` (where applicable)

### 2. Hash Key Formulas
- [ ] HK uses `MD5_BINARY(UPPER(CONCAT_WS('||', ...)))` pattern
- [ ] HK wraps each component: `COALESCE(NULLIF(TRIM(CAST(col AS VARCHAR)), ''), '^^')`
- [ ] HK uses **raw source column names**, NOT BK aliases
- [ ] BKCC is the **last** component in every HK
- [ ] HASHDIFF uses `MD5_BINARY(UPPER(NULLIF(CONCAT(...), '^^||^^')))`
- [ ] HASHDIFF wraps each component: `IFNULL(TRIM(col::text), '^^')`
- [ ] HASHDIFF excludes: HK, BK, `_FIVETRAN_ID`, `_FIVETRAN_SYNCED`, `PSA_LOAD_DTS`, `PSA_RECORD_SOURCE`, `LOAD_DTS`, `BKCC`, `REC_SRC`
- [ ] HASHDIFF includes: `PSA_DELETE_IND`, `_FIVETRAN_DELETED` (data, not metadata)

### 3. CTE Structure
- [ ] New models use 4-layer: `SRC → LOGIC → JOIN → FINAL`
- [ ] Legacy models (6-layer) NOT converted — leave as-is
- [ ] SRC driver table: `SELECT *` for v_psa_stg and sat builds only
- [ ] SRC BKCC: `SELECT BKCC, REC_SRC` with WHERE filter
- [ ] BKCC JOIN: `INNER JOIN SRC_BKCC ON '1' = '1'`

### 4. BKCC & REC_SRC
- [ ] No hardcoded BKCC values in SQL
- [ ] BKCC sourced from `REF_BUSINESS_KEY_COLLISION` table
- [ ] REC_SRC format: `Location.System.Application.Table`
- [ ] BKCC + REC_SRC registered in DEV before build

### 5. Date & Timestamp Handling
- [ ] `CONVERT_TIMEZONE('UTC', ...)` for all timestamp conversions
- [ ] NULL dates replaced with `'1900-01-01'::TIMESTAMP`
- [ ] LOAD_DTS derivation matches ingestion type (Fivetran vs SNP GLUE vs custom)

### 6. Dedup & Filtering
- [ ] Uses `QUALIFY ROW_NUMBER()` — never `SELECT DISTINCT`
- [ ] QUALIFY only when grain is invalid (not unconditionally)
- [ ] Window function ORDER BY matches ingestion type

### 7. Test Coverage (by layer)
- [ ] **v_psa_stg**: BK `not_null` + `unique_combination_of_columns` on BK+LOAD_DTS
- [ ] **Hub/Sat/Link**: `dbt_constraints.primary_key`, `foreign_key`, row count >= 4
- [ ] **PIT/PB**: PK constraints + metrics tests
- [ ] **dim/fact**: No YAML tests (QA team handles singular tests)
- [ ] Uses `data_tests:` (not deprecated `tests:`)
- [ ] **H10** Grain test column lists (`primary_key` / `unique_combination_of_columns`)
      contain ONLY `*_HK` + `LOAD_DTS` + dependent child keys. No `HASHDIFF`,
      `REC_SRC`, `BKCC`, `PSA_DELETE_IND`, `PSA_LOAD_DTS`, `PSA_RECORD_SOURCE`,
      `_FIVETRAN_SYNCED`, `_FIVETRAN_ID`, `_FIVETRAN_DELETED` (HASHDIFF in a PK
      silently masks true duplicates). **`LOAD_DTS` is REQUIRED** — the canonical
      DV 2.0 sat grain is `(parent_HK, LOAD_DTS)`.
- [ ] **H11** Every satellite YAML in `raw_vault/sat/` declares a
      `dbt_constraints.foreign_key` test (presence-only; missing FK means the
      model bypassed the generator pipeline)

### 8. Ghost Records (Raw Vault only)
- [ ] Ghost records present via `UNION ALL` in `{% if not is_incremental() %}` block
- [ ] Three ghost values: 0 (SYSTEM), -1 (nullkey-required), -2 (nullkey-optional)
- [ ] Ghost LOAD_DTS: `'1900-01-01T00:00:00'::TIMESTAMP_NTZ`

### 9. Business Logic Layer
- [ ] DIM/FACT views contain **no business logic** — only column selection/aliasing
- [ ] All logic in PIT/PB layer
- [ ] No `CASE WHEN` or `WHERE` filters in DIM/FACT models

### 10. Materialization
- [ ] v_psa_stg: `view`
- [ ] Hub/Sat/Link: `incremental`
- [ ] PIT/PB: `table` (or `incremental` for large volume)
- [ ] Dim/Fact: `view` (or `incremental` for large volume)

### 11. Source & Layer Integrity (Category I)

> These are computed automatically by `code_reviewer.py`. Report findings;
> do not adjudicate. Specifically: I2/I4 are layer-direction rules and I5
> is the repo-wide governed-allowlist backstop, all driven by
> `governance_allowlist.yml` at the repo root.
>
> **BKCC permanent exemption** (code-level, NOT on any list):
> `models/raw_vault/reference_table/ref_business_key_collision.sql` is the
> BKCC source-of-truth and legitimately MUST use `source()`. I4 skips this
> file by basename — correct-by-design, not a grandfathered violation.
>
> **Named ref() exemptions for staging** (config-driven, in
> `governance_allowlist.yml` under `staging_ref_exemptions:`):
> A short, explicitly-enumerated list of v_psa_stg model names that may be
> `ref()`'d from inside `int_staging_views/`. Same precedent as the BKCC
> code-level exemption, but config-driven so additions/removals don't
> require a code change. Currently used for the two Talend migration
> cutoff-date reference models
> (`v_psa_stg_ref_avc_talend_migration_cutoff_date`,
> `v_psa_stg_ref_appbot_talend_migration_cutoff_date`) which are shared
> by ~18 amazon/appbot staging models for a one-shot legacy-data cutoff
> join. The YAML entry is marked EXPECTED-TEMPORARY and is scoped to be
> removed once the Talend migration is complete. NEW entries require
> explicit review and a documented expiry. This is a **named exemption**,
> not a wildcard — `ref()` to any model NOT on the list still FAILs.
>
> **Grandfather list** (`scripts/automation/.code_review_grandfather`):
> Pre-existing I2/I4 violations are enumerated as `(check_id, file_path)`
> pairs. Listed findings downgrade FAIL → WARN with a `[GRANDFATHERED]`
> message prefix and a `BURN-DOWN` suggestion hint. The list is **frozen**
> — entries are only ever REMOVED (when a file is cleaned up), never
> added. Run `code_reviewer.py --validate-grandfather` to surface stale
> entries (files that no longer violate). NEW violations (file not on the
> list) still FAIL normally.

- [ ] **I1** All `FROM` clauses use `{{ source(...) }}` or `{{ ref(...) }}` —
      no direct `SCHEMA.TABLE` literals
- [ ] **I2** **Staging discipline** (`int_staging_views/` only):
  - `source()` resolves to `staging_source_db_default` (PSA_PROD)
  - Exception: sources registered in `legacy_sources_yaml`
    (`_sources_base_legacy.yml`) may resolve to any DB in
    `staging_source_db_legacy` (PSA_PROD + EDP_BRONZE_PROD)
  - `ref()` is forbidden in staging EXCEPT (a)
    `ref('ref_business_key_collision')` (BKCC cross-join driver,
    code-level exemption), and (b) any model listed in
    `staging_ref_exemptions:` in `governance_allowlist.yml`
    (config-driven named exemptions; currently scoped to Talend
    migration cutoff-date reference models)
- [ ] **I3** `dim_*` / `fact_*` models contain **no business logic**
      (no `CASE WHEN`, no `WHERE`)
- [ ] **I4** **Downstream ref-only** (`raw_vault/`, `bus_vault/`,
      `info_mart/`): any `source()` FAILs — downstream layers must use `ref()`
- [ ] **I5** **Governed allowlist** (repo-wide backstop): every `source()`
      resolves to a database in `allowed_databases` (or `DB.SCHEMA` in
      `allowed_schemas`); two-arg cross-project `ref('project','model')`
      references a project in `allowed_projects`

## How to Review

1. Read the model SQL file
2. Walk through the checklist above, checking each item
3. For each violation, cite the specific line and the rule being violated
4. Classify severity: **BLOCK** (must fix before merge) vs **WARN** (technical debt)
5. Summarize: total checks passed, total violations, BLOCK count

### Severity Guide
| Severity | Examples |
|----------|---------|
| **BLOCK** | Wrong HK formula, missing BKCC join, hardcoded BKCC, missing PK test, `SELECT DISTINCT` in staging/raw_vault (BV is WARN — see E1) |
| **BLOCK (E1)** | `SELECT DISTINCT` in `int_staging_views/` or `raw_vault/`. In `bus_vault/` it downgrades to **WARN** — acceptable for derivations but reviewer confirms it expresses grain intent rather than masking a join-cardinality bug |
| **BLOCK (H10)** | Grain test (PK / `unique_combination_of_columns`) includes a metadata/payload column — grain must be `*_HK` + child keys only |
| **BLOCK (H11)** | Satellite YAML missing a `dbt_constraints.foreign_key` declaration |
| **BLOCK (I2)** | Staging `source()` outside PSA_PROD / legacy allowance; staging `ref()` other than `ref_business_key_collision` |
| **BLOCK (I4)** | `raw_vault/` / `bus_vault/` / `info_mart/` model uses `source()` (must use `ref()`) |
| **BLOCK (I5)** | `source()` resolves to a non-governed database (e.g. `BI_SANDBOX`) or undeclared source; two-arg cross-project `ref()` to an unallowlisted project |
| **BLOCK (N1)** | Staging filters on `PSA_DELETE_IND` / `_FIVETRAN_DELETED`. Downgrades to **WARN** when a `-- DV-EXCEPTION: <reason>` marker appears on the filter line or the line immediately above/below (bare `--` or `-- DV-EXCEPTION:` with no reason does NOT downgrade) |
| **WARN** | Missing header comment, suboptimal alias pattern, missing row count test |

## Output Format

```
## Code Review: <model_name>

### Summary
- Checks passed: X/Y
- Violations: Z (N BLOCK, M WARN)

### Violations
1. [BLOCK] Line XX: <description> — Rule: <checklist item>
2. [WARN] Line XX: <description> — Rule: <checklist item>

### Verdict: APPROVE / REQUEST CHANGES
```
