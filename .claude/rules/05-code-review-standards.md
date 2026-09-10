---
paths:
  - "models/**"
  - "scripts/automation/src/**"
---

# Code Review Standards

## CTE Structure Enforcement
- New models: 4-layer CTE pattern (SRC → LOGIC → JOIN → FINAL)
- Legacy models (448+): 6-layer — do NOT convert existing models
- SRC driver table uses `SELECT *` for v_psa_stg and sat builds only
- All other model types use explicit column lists in SRC

## HASHDIFF Composition
- Excludes: BK columns, HK columns, BKCC, REC_SRC, LOAD_DTS, `_FIVETRAN_ID`, `_FIVETRAN_SYNCED`, `PSA_LOAD_DTS`, `PSA_RECORD_SOURCE`
- Includes: `PSA_DELETE_IND`, `_FIVETRAN_DELETED` (these are data, not metadata)
- Uses `CONCAT(...)` with `IFNULL(TRIM(...), '^^')` and `'||'` separators
- Wrapped in `MD5_BINARY(UPPER(NULLIF(..., '^^||^^')))`

## Ghost Records
- Ghost record values use binary literals (`MD5_BINARY(GR.VALUE)`)
- Ghost records are inside `{% if not is_incremental() %}` block
- Three ghost records: 0 (SYSTEM), -1 (nullkey-required), -2 (nullkey-optional)

## Source References
- `source()` references in staging views only
- Raw vault and above use `ref()` exclusively
- PSA source config: `psa_{{env_var('DBT_SOURCE_ENV')}}` (always PSA_PROD)

## Watermark Patterns
- SAT incremental: `WHERE src.load_dts > (SELECT DATEADD('HOUR', -1, MAX(load_dts)) FROM {{ this }} WHERE rec_src = '<REC_SRC>')`
- HUB/LNK large volume: per-REC_SRC watermark with `DATEADD(DAY, -3, MAX(LOAD_DTS))`
- Non-watermark HUB/LNK: QUALIFY dedup in SRC, NOT EXISTS in FINAL

## Test Severity
- Global test severity: `warn` (tests inform, don't block builds)
- Use `data_tests:` (not deprecated `tests:`)
- Staging tests OFF by default (enable with vars)

## SQL Formatting
- Capitalize SQL keywords (`SELECT`, `FROM`, `WHERE`, `JOIN`)
- Left-align main clauses
- Indent subqueries and CASE statements
- Use consistent alias patterns
- QUALIFY instead of SELECT DISTINCT

## CI/CD Pipeline
- CI/CD is driven by **GitHub Actions + dbt Cloud API**
- QA uses PR-isolated schemas: `dbt_cloud_pr_786808_{PR_NUMBER}`
- Test-only PRs (no `.sql` model changes) skip QA and PROD deployment
- Global test severity: `warn` (tests inform, don't block builds)
