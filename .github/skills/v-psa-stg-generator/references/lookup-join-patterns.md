# Lookup Join Patterns Reference

## Join Types in v_psa_stg Models

### BKCC Join (Always Required)
```sql
INNER JOIN SRC_BKCC ON '1' = '1'
```
- Always INNER JOIN with cross-join condition
- Adds BKCC and REC_SRC columns to every row
- Must be present in every v_psa_stg model

### LEFT JOIN (Default for Lookups)
```sql
LEFT JOIN SRC_R ON LOGIC_S.JOIN_KEY = SRC_R.join_key
```
- Default join type for all lookup/secondary tables
- Preserves all driver table rows even if lookup has no match
- Common: terms lookup, plant lookup, currency lookup

### INNER JOIN (Exception — Requires Justification)
```sql
INNER JOIN SRC_R ON LOGIC_S.RETAILER_ID = SRC_R.retailer_id
-- INNER JOIN: retailer-specific dataset, non-matching records are invalid
```
- Used only when non-matching records are meaningless
- **Must include inline SQL comment** explaining why INNER JOIN is appropriate
- Common: retailer-specific datasets where records without retailer context are invalid

## Multi-Table Join Patterns

### Simple (1 lookup)
```sql
JOIN_RESULT as (
    SELECT
        LOGIC_S.*,
        SRC_R.LOOKUP_COL AS LOOKUP_COL_NAME,
        SRC_BKCC.BKCC,
        SRC_BKCC.REC_SRC
    FROM LOGIC_S
    LEFT JOIN SRC_R ON LOGIC_S.KEY = SRC_R.key
    INNER JOIN SRC_BKCC ON '1' = '1'
)
```

### Complex (Multiple lookups)
```sql
JOIN_RESULT as (
    SELECT
        LOGIC_S.*,
        SRC_R.COL1 AS LOOKUP1_NAME,
        SRC_T.COL2 AS LOOKUP2_NAME,
        SRC_U.COL3 AS LOOKUP3_NAME,
        SRC_BKCC.BKCC,
        SRC_BKCC.REC_SRC
    FROM LOGIC_S
    LEFT JOIN SRC_R ON LOGIC_S.KEY1 = SRC_R.key
    LEFT JOIN SRC_T ON LOGIC_S.KEY2 = SRC_T.key
    LEFT JOIN SRC_U ON LOGIC_S.KEY3 = SRC_U.key
    INNER JOIN SRC_BKCC ON '1' = '1'
)
```

### Chained Lookup (Multi-Step Resolution)
```sql
-- Step 1: PO number → VBELN
SRC_R as (
    SELECT EBELN, VBELN FROM {{ source('sap', 'Z_EKBE') }} as SRC
    QUALIFY (ROW_NUMBER() OVER(PARTITION BY EBELN ORDER BY PSA_LOAD_DTS DESC)) = 1
),
-- Step 2: VBELN → EAN11
SRC_T as (
    SELECT VBELN, EAN11 FROM {{ source('sap', 'Z_LIPS') }} as SRC
    QUALIFY (ROW_NUMBER() OVER(PARTITION BY VBELN ORDER BY PSA_LOAD_DTS DESC)) = 1
),
-- Join chain
JOIN_RESULT as (
    SELECT LOGIC_S.*, SRC_T.EAN11, SRC_BKCC.BKCC, SRC_BKCC.REC_SRC
    FROM LOGIC_S
    LEFT JOIN SRC_R ON LOGIC_S.EBELN = SRC_R.EBELN
    LEFT JOIN SRC_T ON SRC_R.VBELN = SRC_T.VBELN
    INNER JOIN SRC_BKCC ON '1' = '1'
)
```

## Join Column Selection
- Only SELECT needed columns from lookup tables in the JOIN_RESULT
- Alias lookup columns to UPPERCASE business names
- Avoid `SRC_R.*` — always explicit column list from lookups
