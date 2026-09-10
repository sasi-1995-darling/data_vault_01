{{ config(alias='dim_brand_v2' + ('_competitive_share' if target.schema not in ['dev', 'qa', 'prod'] else '')) }}
---- SRC LAYER ----
WITH
SRC_DB             as ( SELECT * FROM {{ ref('dim_brand_v2') }} as SRC  )

/*
SRC_DB             as ( SELECT * FROM bus_vault.DIM_BRAND_V2 )
*/
---- LOGIC LAYER ----

, LOGIC_DB as (
    SELECT
        BRAND_BK
      , FULL_NAME
      , BKCC
      , REC_SRC
      , OWNER
      , BRAND
      , SUBBRAND
      , SUBSUBBRAND
      , SYSTEM_BRAND
      , BUSINESS_UNIT
      , COMPETITOR_IND
    FROM SRC_DB
)
---- RENAME LAYER ----

, RENAME_DB as (
    SELECT
        BRAND_BK
      , FULL_NAME
      , BKCC
      , REC_SRC
      , OWNER
      , BRAND
      , SUBBRAND
      , SUBSUBBRAND
      , SYSTEM_BRAND
      , BUSINESS_UNIT
      , COMPETITOR_IND
    FROM LOGIC_DB
)
---- FILTER LAYER ----

, FILTER_DB as (
    SELECT *
    FROM RENAME_DB
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_DB
)

---- FINAL LAYER ----
SELECT
          BRAND_BK
        , FULL_NAME
        , BKCC
        , REC_SRC
        , OWNER
        , BRAND
        , SUBBRAND
        , SUBSUBBRAND
        , SYSTEM_BRAND
        , BUSINESS_UNIT
        , COMPETITOR_IND
FROM JOIN_RESULT
