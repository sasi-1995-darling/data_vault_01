{{ config(materialized='ephemeral') }}
---- SRC LAYER ----
WITH
SRC_CS             as ( SELECT ASIN, ASIN_KEY, BKCC, BRAND_BK, BRAND_ID, BRAND_KEY, BUSINESS_UNIT, CATEGORY_NAME, CATEGORY_TYPE, DATE_DATEKEY, FIRST_PARTY_SALES, FIRST_PARTY_UNITS, MODEL, PLATFORM, PRODUCT_NAME, REC_SRC, SOURCE, THIRD_PARTY_SALES, THIRD_PARTY_UNITS, TOTAL_SALES, TOTAL_UNITS, UPC FROM {{ ref('pb_stg_competitive_share__profitero') }} as SRC  ),
SRC_D              as ( SELECT DATE, DATE_DATEKEY, TRANSACTION_DATE, TRANSACTION_DATEKEY FROM {{ ref('pb_stg_pos_dim_date_comp_share') }} as SRC  )

/*
SRC_CS             as ( SELECT * FROM bus_vault.PB_STG_COMPETITIVE_SHARE__PROFITERO )
SRC_D              as ( SELECT * FROM bus_vault.PB_STG_POS_DIM_DATE_COMP_SHARE )
*/
---- LOGIC LAYER ----

, LOGIC_CS as (
    SELECT
        DATE_DATEKEY
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
      , SOURCE
      , BUSINESS_UNIT
      , BKCC
      , REC_SRC
    FROM SRC_CS
)

, LOGIC_D as (
    SELECT
        TRANSACTION_DATE
      , TRANSACTION_DATEKEY                                          as                                           DATE_KEY
      , DATE
      , DATE_DATEKEY                                                 as                                     D_DATE_DATEKEY
    FROM SRC_D
)
---- RENAME LAYER ----

, RENAME_D as (
    SELECT
        TRANSACTION_DATE
      , DATE_KEY
      , DATE
      , D_DATE_DATEKEY
    FROM LOGIC_D
)

, RENAME_CS as (
    SELECT
        DATE_DATEKEY
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
      , SOURCE
      , BUSINESS_UNIT
      , BKCC
      , REC_SRC
    FROM LOGIC_CS
)
---- FILTER LAYER ----

, FILTER_CS as (
    SELECT *
    FROM RENAME_CS
)

, FILTER_D as (
    SELECT *
    FROM RENAME_D
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_CS
    LEFT JOIN FILTER_D
        ON FILTER_CS.DATE_DATEKEY = D_DATE_DATEKEY
)

---- FINAL LAYER ----
SELECT
          TRANSACTION_DATE
        , DATE_KEY
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
        , SOURCE
        , BUSINESS_UNIT
        , BKCC
        , REC_SRC
FROM JOIN_RESULT
