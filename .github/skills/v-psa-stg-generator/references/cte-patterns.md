# 4-Layer CTE Pattern Reference

## Standard Structure
All new v_psa_stg models use 4 layers: **SRC → LOGIC → JOIN → FINAL**

```sql
WITH
--------------------------------------------------------------------
-- SRC LAYER: Source data extraction
--------------------------------------------------------------------
SRC_S as (
    SELECT * FROM {{ source('schema', 'driver_table') }} as SRC
    -- Optional: QUALIFY for source-level dedup (Pattern B)
),

SRC_R as (
    SELECT join_key, needed_col1, needed_col2
    FROM {{ source('schema', 'lookup_table') }} as SRC
    QUALIFY (ROW_NUMBER() OVER(PARTITION BY join_key ORDER BY PSA_LOAD_DTS DESC)) = 1
),

SRC_BKCC as (
    SELECT BKCC, REC_SRC
    FROM {{ ref('ref_business_key_collision') }}
    WHERE rec_src = 'LOCATION.SYSTEM.APP.TABLE'
),

--------------------------------------------------------------------
-- LOGIC LAYER: Business logic, column aliasing, derived columns
--------------------------------------------------------------------
LOGIC_S as (
    SELECT
        -- Business Key
        CAST(raw_col AS VARCHAR) AS ENTITY_BK,

        -- Hash Key (uses raw column names, NOT BK aliases)
        MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(raw_col AS VARCHAR)), ''), '^^')
          , COALESCE(NULLIF(TRIM(CAST(BKCC AS VARCHAR)), ''), '^^')
        ))) AS ENTITY_HK,

        -- HASHDIFF (data columns only, wrapped in UPPER — same as HK)
        MD5_BINARY(UPPER(NULLIF(CONCAT(
                   IFNULL(TRIM(data_col1::text), '^^'), '||',
                   IFNULL(TRIM(data_col2::text), '^^')
        ), '^^||^^'))) AS HASHDIFF,

        -- LOAD_DTS derivation
        CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED) AS LOAD_DTS,  -- Fivetran sources; use PSA_LOAD_DTS for non-Fivetran

        -- Data columns (UPPERCASE aliases)
        IFNULL(CAST(col1 AS VARCHAR), '') AS COL1_NAME,
        IFNULL(CAST(col2 AS NUMBER(38,0)), 0) AS COL2_NAME,
        -- Dates: use '1900-01-01' for NULL
        IFNULL(CONVERT_TIMEZONE('UTC', date_col), '1900-01-01'::TIMESTAMP) AS DATE_COL_NAME

    FROM SRC_S
),

--------------------------------------------------------------------
-- JOIN LAYER: Combine data + lookups + BKCC
--------------------------------------------------------------------
JOIN_RESULT as (
    SELECT
        LOGIC_S.*,
        SRC_R.needed_col1 AS LOOKUP_COL1,
        SRC_R.needed_col2 AS LOOKUP_COL2,
        SRC_BKCC.BKCC,
        SRC_BKCC.REC_SRC
    FROM LOGIC_S
    LEFT JOIN SRC_R ON LOGIC_S.JOIN_KEY = SRC_R.join_key
    INNER JOIN SRC_BKCC ON '1' = '1'
),

--------------------------------------------------------------------
-- FINAL LAYER: Final SELECT — NO QUALIFY for new v_psa_stg
--------------------------------------------------------------------
FINAL as (
    SELECT * FROM JOIN_RESULT
    -- PROHIBITED: Do NOT add QUALIFY here for new v_psa_stg models
    -- Fix grain issues upstream in SRC CTE (Pattern A/B)
)

SELECT * FROM FINAL
```

## SRC Layer Rules

### Driver Table (SRC_S)
- Always `SELECT *` — never list explicit columns
- **No WHERE clause by default.** Add only for confirmed system dummy/placeholder records with explicit business justification. **NEVER filter on `_FIVETRAN_DELETED` or `PSA_DELETE_IND`** — these are data attributes, not filter criteria (lesson #28)
- Optional QUALIFY Pattern B if source has duplicates

### Secondary/Lookup Table (SRC_R, SRC_T, etc.)
- Always **explicit column list**: join key + only needed columns
- Always QUALIFY Pattern A: `ROW_NUMBER() OVER(PARTITION BY key ORDER BY PSA_LOAD_DTS DESC) = 1`
- Use single-letter suffixes: `SRC_R`, `SRC_T`, `SRC_U`, etc.
- **No filter on `PSA_DELETE_IND` or `_FIVETRAN_DELETED`** — these are data, not filter criteria (lesson #28)

### BKCC Table (SRC_BKCC)
- Always: `SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }}`
- Always: `WHERE rec_src = '<full_REC_SRC_value>'`
- Never: SELECT * or additional columns

## LOGIC Layer Rules
- Alias ALL columns to UPPERCASE business names
- Derive HK, BK, HASHDIFF, LOAD_DTS here (NOT in JOIN or FINAL)
- One LOGIC CTE per source table: `LOGIC_S`, `LOGIC_R`, etc.
- No WHERE clause in LOGIC — column aliasing and derivations only. Context filters (if any) belong in SRC CTE, never in LOGIC (lesson #20)

## JOIN Layer Rules
- Single `JOIN_RESULT` CTE combining all paths
- BKCC: `INNER JOIN SRC_BKCC ON '1' = '1'` (always)
- Lookups: `LEFT JOIN` (default) or `INNER JOIN` (requires inline comment)
- Reference: `references/lookup-join-patterns.md`

## FINAL Layer Rules
- Usually `SELECT * FROM JOIN_RESULT`
- **PROHIBITED**: Do NOT add QUALIFY in FINAL for new v_psa_stg models. Fix grain issues upstream in SRC CTE (Pattern A/B).
- No additional transformations — all logic belongs in LOGIC layer

## Legacy 6-Layer (Existing 448+ Models)
Existing models use: SRC → LOGIC → RENAME → FILTER → JOIN → FINAL
- RENAME: Pure passthrough (LOGIC already aliases columns)
- FILTER: Passthrough with occasional WHERE clause (now absorbed into LOGIC)
- Do NOT convert existing models — only new models use 4-layer
