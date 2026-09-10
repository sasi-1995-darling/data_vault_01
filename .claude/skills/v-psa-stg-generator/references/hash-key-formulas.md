# Hash Key Formulas Reference

## HK (Hash Key) — Surrogate Key for Hubs/Links

### Formula
```sql
MD5_BINARY(UPPER(CONCAT_WS('||',
    COALESCE(NULLIF(TRIM(CAST(raw_col1 AS VARCHAR)), ''), '^^')
  , COALESCE(NULLIF(TRIM(CAST(raw_col2 AS VARCHAR)), ''), '^^')
  , COALESCE(NULLIF(TRIM(CAST(BKCC AS VARCHAR)), ''), '^^')
))) AS ENTITY_HK
```

### Rules
1. **Use raw source column names**, NOT BK aliases
   - Correct: `CAST(PO_HEADER_ID AS VARCHAR)` (raw column)
   - Wrong: `CAST(PO_ITEM_BK AS VARCHAR)` (alias)
2. Components: individual raw columns + BKCC (always last)
3. All VARCHAR components wrapped in `UPPER()` via outer `UPPER()` on `CONCAT_WS`
4. NULL handling: `COALESCE(NULLIF(TRIM(CAST(... AS VARCHAR)), ''), '^^')` (catches empty strings after trim)
5. Separator: `'||'` (double pipe) as first arg to `CONCAT_WS`
6. BKCC is always the **last** component

### Naming Convention
- Entity HK: `<ENTITY>_HK` (e.g., `PO_ITEM_HK`, `CUSTOMER_HK`)
- Link HK: `LNK_<LINK_NAME>_HK` (e.g., `LNK_PO_ITEM_HK`)

### Examples from Production Models
```sql
-- Simple: single-column BK
MD5_BINARY(UPPER(CONCAT_WS('||',
    COALESCE(NULLIF(TRIM(CAST(EBELN AS VARCHAR)), ''), '^^')
  , COALESCE(NULLIF(TRIM(CAST(BKCC AS VARCHAR)), ''), '^^')
))) AS PO_HEADER_HK

-- Composite: multi-column BK
MD5_BINARY(UPPER(CONCAT_WS('||',
    COALESCE(NULLIF(TRIM(CAST(PO_HEADER_ID AS VARCHAR)), ''), '^^')
  , COALESCE(NULLIF(TRIM(CAST(LINE_NUM AS VARCHAR)), ''), '^^')
  , COALESCE(NULLIF(TRIM(CAST(BKCC AS VARCHAR)), ''), '^^')
))) AS PO_ITEM_HK

-- Link HK: composes from the participating HUB HK VALUES (DV 2.1, #1907), not raw
-- columns, and carries NO BKCC (each hub HK already embeds its own). A SELECT cannot
-- reference a sibling alias, so the generator pre-computes the hub HKs in a HASH_STG
-- CTE and builds the link in FINAL. Declared via the auto multi-table path or
-- --hk "LNK_PO_ITEM_HK:@PO_ITEM_HK,@SUPPLIER_HK". Because the components are hub-HK
-- values (distinct hashes), this cannot byte-collide with a composite-BK hub HK (TRAP-01).
MD5_BINARY(UPPER(CONCAT_WS('||',
    TO_VARCHAR(PO_ITEM_HK)
  , TO_VARCHAR(SUPPLIER_HK)
))) AS LNK_PO_ITEM_HK
```

## BK (Business Key)

### Formula
```sql
CAST(raw_col AS VARCHAR) AS ENTITY_BK

-- Composite BK (concatenated)
CAST(raw_col1 AS VARCHAR) || '-' || CAST(raw_col2 AS VARCHAR) AS ENTITY_BK
```

### Naming Convention
- Always entity-specific: `PO_HEADER_BK`, `SUPPLIER_BK`, `INVOICE_LINE_BK`
- Never generic: `ACCOUNT_BK` for a statement lines table → use `STATEMENT_LINE_BK`

## HASHDIFF — Change Detection for Satellites

### Formula
```sql
MD5_BINARY(UPPER(NULLIF(CONCAT(
      IFNULL(TRIM(data_col1::text), '^^')
    , '||', IFNULL(TRIM(data_col2::text), '^^')
    , '||', IFNULL(TRIM(data_col3::text), '^^')
), '^^||^^'))) AS HASHDIFF
```

### Rules
- Uses `UPPER()` wrapper (same as HK)
- Includes only **data columns from the primary/driver table**
- See `hashdiff-rules.md` for exclusion rules
- Order: alphabetical by column name (convention)

## LOAD_DTS — Load Timestamp

### Formula
```sql
-- Fivetran-ingested sources:
CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED) AS LOAD_DTS
-- SNP GLUE sources:
IFF(PSA_DELETE_IND = 'Y', PSA_LOAD_DTS, CONVERT_TIMEZONE('UTC', TO_TIMESTAMP_NTZ(SUBSTR(GLCHANGETIME, 1, 14) || '.' || SUBSTR(GLCHANGETIME, 16), 'YYYYMMDDHH24MISS.FF9'))) AS LOAD_DTS
-- Custom / non-Fivetran sources:
CONVERT_TIMEZONE('UTC', PSA_LOAD_DTS) AS LOAD_DTS
```
- Always UTC timezone conversion
- **Fivetran sources**: use `_FIVETRAN_SYNCED` (provides true per-record change timestamp, resolves grain at BK + LOAD_DTS)
- **SNP GLUE sources**: use `GLCHANGETIME` for non-deletes
- **Custom sources**: use `PSA_LOAD_DTS` as fallback

## REC_SRC — Record Source
- Derived from BKCC table join, NOT hardcoded
- Format: `Location.System.Application.Table`
- See `bkcc-reference.md` for naming conventions
