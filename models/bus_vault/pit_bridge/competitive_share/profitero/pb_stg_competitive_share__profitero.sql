{{ config(materialized='table',
    transient = true) }}
-- Intentional materialization override to avoid performance bottlenecks caused by chained ephemeral models.
-- ENHANCED 2026-07: fact-driven join order + join-key dedup to eliminate M:N fan-out
-- (prior version spilled 2.93TB local / 401GB remote, canceled at 53 min).


-- REMOVED: SRC_LAS (driver replaced by SS, which already carries ASIN_HK + SNS_CATEGORY_HK)
-- REMOVED: SRC_HA  (dead join — contributed no columns)

---- SRC LAYER (renames inlined) ----
WITH
SRC_SS as (
    SELECT
        SNS_CATEGORY_HK                as SS_SNS_CATEGORY_HK
      , ASIN_HK                        as SS_ASIN_HK
      , DATE
      , TO_CHAR(DATE, 'YYYYMMDD')      as DATE_DATEKEY
      , ASIN
      , ASIN_HK                        as ASIN_KEY
      , PLATFORM
      , FIRST_PARTY_SALES
      , THIRD_PARTY_SALES
      , TOTAL_SALES
      , FIRST_PARTY_UNITS
      , THIRD_PARTY_UNITS
      , TOTAL_UNITS
      , BUSINESS_UNIT
    FROM {{ ref('pb_stg_sns_sales__profitero') }}
)

, SRC_SC as (
    SELECT
        SNS_CATEGORY_HK                as SC_SNS_CATEGORY_HK
      , NAME                           as CATEGORY_NAME
      , TYPE                           as CATEGORY_TYPE
    FROM {{ ref('pb_stg_sns_categories__profitero') }}
)

, SRC_SP as (
    SELECT
        ASIN_HK                        as SP_ASIN_HK
      , COALESCE(NULLIF(TRIM(NAME), ''), 'N/A')    as PRODUCT_NAME
      -- Conform unknown markers to the mart contract ('N/A'): legacy feed sent the
      -- literal, re-platformed feed sends blanks/whitespace — applies to PRODUCT_NAME/UPC/MODEL
      , COALESCE(NULLIF(TRIM(UPC),   ''), 'N/A')   as UPC
      , COALESCE(NULLIF(TRIM(MODEL), ''), 'N/A')   as MODEL
      , BRAND_ID
    FROM {{ ref('pb_stg_sns_products__profitero') }}
)

, SRC_HC as (
    SELECT
        SNS_CATEGORY_HK                as HC_SNS_CATEGORY_HK
      , BKCC
      , REC_SRC
    FROM {{ ref('hub_sns_category') }}
)

, SRC_LPA as ( SELECT ASIN_HK, PRODUCT_HK FROM {{ ref('lnk_product_asin') }} )
, SRC_LPB as ( SELECT PRODUCT_HK, BRAND_HK FROM {{ ref('lnk_product_brand') }} )
, SRC_HB  as ( SELECT BRAND_HK, BRAND_BK, BRAND_HK as BRAND_KEY FROM {{ ref('hub_brand_v2') }} )

---- DEDUP LAYER ----
-- Every dimensional join into the 486M-row fact must be key -> 1 row.
-- Links verified pair-unique but M:N per single key; STOPGAP until the
-- effectivity satellite on lnk_product_asin (driving key = ASIN_HK) lands.

-- Stage 1: one brand per PRODUCT (collapses the LPB side to unique join key)
, DEDUP_PRODUCT_BRAND as (
    SELECT
        LPB.PRODUCT_HK
      , HB.BRAND_BK
      , HB.BRAND_KEY
    FROM SRC_LPB LPB
    INNER JOIN SRC_HB HB ON LPB.BRAND_HK = HB.BRAND_HK
    -- Ghost/unknown members never join in BV; also removes the hot key
    WHERE NULLIF(TRIM(HB.BRAND_BK), '') IS NOT NULL
      AND HB.BRAND_BK NOT IN ('0', '-1')
    QUALIFY ROW_NUMBER() OVER (PARTITION BY LPB.PRODUCT_HK ORDER BY HB.BRAND_BK) = 1
)

-- Stage 2: one brand per ASIN — right side now unique on PRODUCT_HK,
-- so this join is provably <= LPA row count. No explosion possible.
, DEDUP_ASIN_BRAND as (
    SELECT
        LPA.ASIN_HK                    as AB_ASIN_HK
      , PB.BRAND_BK
      , PB.BRAND_KEY
    FROM SRC_LPA LPA
    INNER JOIN DEDUP_PRODUCT_BRAND PB ON LPA.PRODUCT_HK = PB.PRODUCT_HK
    QUALIFY ROW_NUMBER() OVER (PARTITION BY LPA.ASIN_HK ORDER BY PB.BRAND_BK) = 1
)

, DEDUP_SC as (
    SELECT * FROM SRC_SC
    QUALIFY ROW_NUMBER() OVER (PARTITION BY SC_SNS_CATEGORY_HK ORDER BY CATEGORY_NAME) = 1
)

, DEDUP_SP as (
    SELECT * FROM SRC_SP
    QUALIFY ROW_NUMBER() OVER (PARTITION BY SP_ASIN_HK ORDER BY PRODUCT_NAME) = 1
)

, DEDUP_HC as (
    SELECT * FROM SRC_HC
    QUALIFY ROW_NUMBER() OVER (PARTITION BY HC_SNS_CATEGORY_HK ORDER BY REC_SRC) = 1
)

---- JOIN LAYER ----
-- Fact (SS) drives; grain = SS grain. All joins provably 1:1 via DEDUP -> output rows = SS rows.
, JOIN_RESULT as (
    SELECT *
    FROM SRC_SS
    LEFT JOIN DEDUP_SC         ON SS_SNS_CATEGORY_HK = SC_SNS_CATEGORY_HK
    LEFT JOIN DEDUP_HC         ON SS_SNS_CATEGORY_HK = HC_SNS_CATEGORY_HK
    LEFT JOIN DEDUP_SP         ON SS_ASIN_HK         = SP_ASIN_HK
    LEFT JOIN DEDUP_ASIN_BRAND ON SS_ASIN_HK         = AB_ASIN_HK
)

---- FINAL LAYER ----
SELECT
      DATE
    , DATE_DATEKEY
    , ASIN
    , ASIN_KEY
    , PLATFORM
    , FIRST_PARTY_SALES
    , THIRD_PARTY_SALES
    , TOTAL_SALES
    , FIRST_PARTY_UNITS
    , THIRD_PARTY_UNITS
    , TOTAL_UNITS
    , CATEGORY_NAME
    , CATEGORY_TYPE
    , PRODUCT_NAME
    , UPC
    , MODEL
    , BRAND_ID
    , BRAND_BK
    , BRAND_KEY
    , BUSINESS_UNIT
    , 'PROFITERO'                      as SOURCE
    , BKCC
    , REC_SRC
FROM JOIN_RESULT