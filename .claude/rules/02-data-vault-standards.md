---
paths:
  - "models/raw_vault/**"
  - "models/int_staging_views/**"
  - "scripts/automation/**"
---

# Data Vault 2.x Standards

## Column Naming Standards
- ALL column names in SQL must be **UPPERCASE** (e.g., `CUSTOMER_BK`, `INVOICE_HK`)
- Table names use **lowercase with underscores** (e.g., `hub_customer`, `sat_po_header`)
- Hash key suffix: `_HK` (e.g., `PO_ITEM_HK`)
- Business key suffix: `_BK` (e.g., `PO_ITEM_BK`)
- Link hash key prefix: `LNK_` (e.g., `LNK_PO_ITEM_HK`)
- `BKCC` — Business Key Control Column
- `LOAD_DTS` — Load timestamp
- `REC_SRC` — Record source (format: `Location.System.Application.Table`, e.g., `USOHNO.SAP.ECCPRD.Z_EKPO`)
- `HASHDIFF` — Hash difference column in satellites

## Hash Key Formulas
```sql
-- HK: MD5_BINARY of raw source columns + BKCC, using CONCAT_WS
MD5_BINARY(UPPER(CONCAT_WS('||',
    COALESCE(NULLIF(TRIM(CAST(col1 AS VARCHAR)), ''), '^^')
  , COALESCE(NULLIF(TRIM(CAST(col2 AS VARCHAR)), ''), '^^')
  , COALESCE(NULLIF(TRIM(CAST(BKCC AS VARCHAR)), ''), '^^')
)))

-- HASHDIFF: MD5_BINARY of data columns (excluding BKs, technical metadata)
MD5_BINARY(UPPER(NULLIF(CONCAT(
    IFNULL(TRIM(data_col1::text), '^^'), '||', IFNULL(TRIM(data_col2::text), '^^')
), '^^||^^')))
```

### Hash Key Rules
- HK uses `CONCAT_WS('||', ...)` with `COALESCE(NULLIF(TRIM(...), ''), '^^')` (catches empty strings)
- HASHDIFF uses `CONCAT(...)` with interleaved `'||'` separators and `IFNULL(TRIM(...), '^^')`
- HK components use **raw source column names**, NOT BK aliases
- BKCC must always be the last component in a **hub** HK. **Link HKs carry no BKCC** — they
  compose from the participating hub HK values (`TO_VARCHAR(hub_HK)`), each of which already
  embeds its own BKCC (DV 2.1, #1907)
- HASHDIFF excludes: HK columns, BK columns, `_FIVETRAN_ID`, `_FIVETRAN_SYNCED`, `PSA_LOAD_DTS`, `PSA_RECORD_SOURCE`, `LOAD_DTS`, `BKCC`, `REC_SRC`, `GLREQUEST`, `GLSOURCESYSTEM`, `GLCHANGETIME`
- HASHDIFF excludes: **Grain columns** (multi-active key columns — PK components, not change-tracked)
- HASHDIFF excludes: **Custom LOAD_DTS column** (if user specifies e.g. MODIFIED_DT as LOAD_DTS source)
- HASHDIFF **includes**: `PSA_DELETE_IND`, `_FIVETRAN_DELETED`, `GLDELFLAG` — these are data, not metadata

## BKCC Rules
- BKCC is 1:1 with **business concept**, NOT source system
- The grain of `REF_BUSINESS_KEY_COLLISION` is at **REC_SRC** level (one row per REC_SRC)
- BKCC + REC_SRC must be registered in DEV via Streamlit app BEFORE any `dbt build`
- BKCC INNER JOIN: `INNER JOIN SRC_BKCC ON '1' = '1'`
- Never override BKCC in staging SQL — register correctly in REF_BUSINESS_KEY_COLLISION table

## Ghost Records
- Raw vault models (hub/sat/link) include ghost records via `UNION ALL` wrapped in `{% if not is_incremental() %}`
- Ghost record HK: `MD5_BINARY(GR.VALUE)` for values 0, -1, -2
- Ghost record BKCC: `DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')`
- Ghost record HASHDIFF: `MD5_BINARY('')`
- Ghost record LOAD_DTS: `'1900-01-01T00:00:00'::TIMESTAMP_NTZ`

## Hub/Link/SAT Column Standards

### Hubs
Columns: `<entity>_HK`, `<entity>_BK`, `BKCC`, `LOAD_DTS`, `REC_SRC`

### Links
Columns: `<link>_HK`, referenced hub keys (`<entity>_HK` for each parent), `LOAD_DTS`, `REC_SRC`
- Links do NOT have BKCC

### Satellites
Columns: `<parent>_HK`, `HASHDIFF`, `LOAD_DTS`, `REC_SRC`, data attributes, `BKCC`

**MSAT deviation from DV 2.1**: FBIN's multi-active satellite NOT EXISTS block checks
HK + multi-active key + HASHDIFF (standard DV 2.1 checks HK + multi-active key only).
This prevents duplicate rows when the same multi-active key arrives with identical data.

## Testing Standards by Layer

### v_psa_stg (views)
```yaml
data_tests:
  - dbt_utils.unique_combination_of_columns:
      combination_of_columns: [ENTITY_BK, LOAD_DTS]
columns:
  - name: ENTITY_BK
    data_tests:
      - not_null
```

### Raw Vault (hub/sat/link)
- `dbt_constraints.primary_key` — required
- `dbt_constraints.foreign_key` — required (sat→hub, link→hub)
- `dbt_expectations.expect_table_row_count_to_be_between` (min_value: 4)

### Business Vault tables (PIT/PB/REF)
- PK constraints required
- Metrics tests (`dbt_expectations`) on critical business fields

### Business Vault views (dim/fact)
- QA team runs singular tests — do NOT duplicate with YAML schema tests

### Info Mart / Reports
- `rep_` models: No tests needed

## Guardrails
- **DO NOT** modify raw vault models directly — they are incremental and require careful handling
- **DO NOT** hardcode BKCC values in SQL — use REF_BUSINESS_KEY_COLLISION table
- **DO NOT** use `SELECT DISTINCT` — use `ROW_NUMBER()` with QUALIFY
- **DO NOT** create `_FIVETRAN_*` columns in staging — they are metadata, not business data
- Always use `CONVERT_TIMEZONE('UTC', ...)` for timestamp conversions
- Replace NULL dates with `'1900-01-01'::TIMESTAMP` placeholder
