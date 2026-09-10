{{ config(alias='dim_brand_v2') }}
---- SRC LAYER ----
WITH
SRC_PB             as ( SELECT * FROM {{ ref('dim_brand_v2') }} as SRC  )

/*
SRC_PB             as ( SELECT * FROM BUS_VAULT.DIM_BRAND_V2 )
*/
---- LOGIC LAYER ----

, LOGIC_PB as (
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
    FROM SRC_PB
)
---- RENAME LAYER ----

, RENAME_PB as (
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
    FROM LOGIC_PB
)
---- FILTER LAYER ----

, FILTER_PB as (
    SELECT *
    FROM RENAME_PB
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_PB
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
