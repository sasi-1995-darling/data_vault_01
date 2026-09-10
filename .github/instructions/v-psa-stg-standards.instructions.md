---
applyTo: "**/v_psa_stg_*.sql"
description: "Standards and patterns for v_psa_stg PSA staging view models"
---

# v_psa_stg Model Standards

## CTE Structure
All new v_psa_stg models must use the **4-layer CTE pattern**:

```
SRC → LOGIC → JOIN → FINAL
```

Legacy models (448+ existing) use 6-layer (SRC/LOGIC/RENAME/FILTER/JOIN/FINAL). Do NOT convert existing models.

## SRC Layer
- **Driver table**: Always `SELECT *` — never explicit columns
- **Lookup tables**: Always explicit column list (join key + needed columns only)
- **BKCC**: Always `SELECT BKCC, REC_SRC FROM ref_business_key_collision WHERE rec_src = '...'`
- Lookup dedup: `QUALIFY (ROW_NUMBER() OVER(PARTITION BY key ORDER BY PSA_LOAD_DTS DESC)) = 1`

## LOGIC Layer
- Alias all columns to UPPERCASE business names
- Derive HK, BK, HASHDIFF, LOAD_DTS here
- HK uses **raw source column names**, NOT BK aliases
- HASHDIFF excludes: HK columns, BK columns, `_FIVETRAN_ID`, `_FIVETRAN_SYNCED`, `PSA_LOAD_DTS`, `PSA_RECORD_SOURCE`, `LOAD_DTS`, `BKCC`, `REC_SRC`, `GLREQUEST`, `GLSOURCESYSTEM`, `GLCHANGETIME`
- `PSA_DELETE_IND`, `_FIVETRAN_DELETED`, and `GLDELFLAG` are data — **include** in HASHDIFF

## JOIN Layer
- BKCC: `INNER JOIN SRC_BKCC ON '1' = '1'` (always)
- Lookups: `LEFT JOIN` (default) or `INNER JOIN` (requires inline comment)

## FINAL Layer
- `SELECT * FROM JOIN_RESULT`
- **PROHIBITED**: Do NOT add QUALIFY in FINAL for new v_psa_stg models. Fix grain issues upstream in SRC CTE (Pattern A/B).

## Hash Key Formulas
```sql
-- HK: raw columns + BKCC, with UPPER() and CONCAT_WS
MD5_BINARY(UPPER(CONCAT_WS('||',
    COALESCE(NULLIF(TRIM(CAST(raw_col AS VARCHAR)), ''), '^^')
  , COALESCE(NULLIF(TRIM(CAST(BKCC AS VARCHAR)), ''), '^^')
)))

-- HASHDIFF: data columns only, with UPPER() (same as HK)
MD5_BINARY(UPPER(NULLIF(CONCAT(
    IFNULL(TRIM(data_col::text), '^^'), '||', IFNULL(TRIM(data_col2::text), '^^')
), '^^||^^')))

-- LOAD_DTS
CONVERT_TIMEZONE('UTC', PSA_LOAD_DTS) AS LOAD_DTS
```

## BK Naming
- Always entity-specific: `PO_HEADER_BK`, `SUPPLIER_BK`, `INVOICE_LINE_BK`
- Never generic: Do NOT use `ACCOUNT_BK` for statement lines → use `STATEMENT_LINE_BK`

## NULL Handling
- VARCHAR: `IFNULL(CAST(col AS VARCHAR), '')`
- NUMBER: `IFNULL(CAST(col AS NUMBER(38,0)), 0)`
- DATE: `IFNULL(CONVERT_TIMEZONE('UTC', date_col), '1900-01-01'::TIMESTAMP)`
- HK NULL: `COALESCE(TRIM(CAST(col AS VARCHAR)), '^^')`

## File Placement
- SQL: `models/int_staging_views/<domain>/v_psa_stg_<entity>__<source>.sql`
- YAML: `models/int_staging_views/<domain>/v_psa_stg_<entity>__<source>.yml`

## Dedup: Use QUALIFY, Never DISTINCT
```sql
-- Correct
QUALIFY (ROW_NUMBER() OVER(PARTITION BY key ORDER BY PSA_LOAD_DTS DESC)) = 1

-- Wrong
SELECT DISTINCT ...
```
