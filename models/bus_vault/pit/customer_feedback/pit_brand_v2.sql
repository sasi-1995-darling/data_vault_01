---- SRC LAYER ----
WITH
SRC_PBP            as ( SELECT BKCC, BRAND, BRAND_BK, BRAND_HK, BUSINESS_UNIT, COMPETITOR_IND, FULL_NAME, ID, OWNER, REC_SRC, SUBBRAND, SUBSUBBRAND, SYSTEM_BRAND FROM {{ ref('pit_stg_brand__profitero') }} as SRC  ),
SRC_PBA            as ( SELECT BKCC, BRAND, BRAND_BK, BRAND_HK, BUSINESS_UNIT, COMPETITOR_IND, FULL_NAME, ID, OWNER, REC_SRC, SUBBRAND, SUBSUBBRAND, SYSTEM_BRAND FROM {{ ref('pit_stg_brand__appbot') }} as SRC  ),
SRC_PSBP           as ( SELECT BKCC, BRAND, BRAND_BK, BRAND_HK, BUSINESS_UNIT, COMPETITOR_IND, FULL_NAME, ID, OWNER, REC_SRC, SUBBRAND, SUBSUBBRAND, SYSTEM_BRAND FROM {{ ref('pit_stg_brand__profitero_share') }} as SRC  )

/*
SRC_PBP            as ( SELECT * FROM BUS_VAULT.PIT_STG_BRAND__PROFITERO )
SRC_PBA            as ( SELECT * FROM BUS_VAULT.PIT_STG_BRAND__APPBOT )
SRC_PSBP           as ( SELECT * FROM BUS_VAULT.PIT_STG_BRAND__PROFITERO_SHARE )
*/
---- LOGIC LAYER ----

, LOGIC_PBP as (
    SELECT
        BRAND_HK
      , BRAND_BK
      , BKCC
      , REC_SRC
      , ID
      , FULL_NAME
      , OWNER
      , BRAND
      , SUBBRAND
      , SUBSUBBRAND
      , SYSTEM_BRAND
      , BUSINESS_UNIT
      , COMPETITOR_IND
      , 2 AS SRC_PRIORITY   -- old profitero: loses to share on BRAND_HK+BKCC collision
    FROM SRC_PBP
)

, LOGIC_PBA as (
    SELECT
        BRAND_HK
      , BRAND_BK
      , BKCC
      , REC_SRC
      , ID
      , FULL_NAME
      , OWNER
      , BRAND
      , SUBBRAND
      , SUBSUBBRAND
      , SYSTEM_BRAND
      , BUSINESS_UNIT
      , COMPETITOR_IND
      , 1 AS SRC_PRIORITY   -- appbot: no overlap with share, treated as preferred
    FROM SRC_PBA
)

, LOGIC_PSBP as (
    SELECT
        BRAND_HK
      , BRAND_BK
      , BKCC
      , REC_SRC
      , ID
      , FULL_NAME
      , OWNER
      , BRAND
      , SUBBRAND
      , SUBSUBBRAND
      , SYSTEM_BRAND
      , BUSINESS_UNIT
      , COMPETITOR_IND
      , 1 AS SRC_PRIORITY  -- profitero_share: preferred over old profitero on collision
    FROM SRC_PSBP
)
---- RENAME LAYER ----

, RENAME_PBP as (
    SELECT
        BRAND_HK
      , BRAND_BK
      , BKCC
      , REC_SRC
      , ID
      , FULL_NAME
      , OWNER
      , BRAND
      , SUBBRAND
      , SUBSUBBRAND
      , SYSTEM_BRAND
      , BUSINESS_UNIT
      , COMPETITOR_IND
      , SRC_PRIORITY
    FROM LOGIC_PBP
)

, RENAME_PBA as (
    SELECT
        BRAND_HK
      , BRAND_BK
      , BKCC
      , REC_SRC
      , ID
      , FULL_NAME
      , OWNER
      , BRAND
      , SUBBRAND
      , SUBSUBBRAND
      , SYSTEM_BRAND
      , BUSINESS_UNIT
      , COMPETITOR_IND
      , SRC_PRIORITY
    FROM LOGIC_PBA
)

, RENAME_PSBP as (
    SELECT
        BRAND_HK
      , BRAND_BK
      , BKCC
      , REC_SRC
      , ID
      , FULL_NAME
      , OWNER
      , BRAND
      , SUBBRAND
      , SUBSUBBRAND
      , SYSTEM_BRAND
      , BUSINESS_UNIT
      , COMPETITOR_IND
      , SRC_PRIORITY
    FROM LOGIC_PSBP
)
---- FILTER LAYER ----

, FILTER_PBP as (
    SELECT *
    FROM RENAME_PBP
)

, FILTER_PBA as (
    SELECT *
    FROM RENAME_PBA
)

, FILTER_PSBP as (
    SELECT *
    FROM RENAME_PSBP
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_PBP
    UNION ALL
    SELECT * FROM FILTER_PBA
    UNION ALL
    SELECT * FROM FILTER_PSBP
)

---- FINAL LAYER ----
SELECT
              row_number() over(order by 1)                            as SEQ_ID
        , CURRENT_DATE                                                 as SNAPSHOTDATE
        , CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP )                  as PIT_LOAD_DTS
        , BRAND_HK
        , BRAND_BK
        , BKCC
        , REC_SRC
        , ID
        , FULL_NAME
        , OWNER
        , BRAND
        , SUBBRAND
        , SUBSUBBRAND
        , SYSTEM_BRAND
        , BUSINESS_UNIT
        , COMPETITOR_IND
FROM JOIN_RESULT
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY BRAND_HK, BKCC
    ORDER BY SRC_PRIORITY ASC
) = 1