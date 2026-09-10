{{ config(alias='fact_competitive_share_weekly') }}
---- SRC LAYER ----
WITH
SRC_PB             as ( SELECT * FROM {{ ref('fact_competitive_share_weekly') }} as SRC  )

/*
SRC_PB             as ( SELECT * FROM bus_vault.PB_COMPETITIVE_SHARE_WEEKLY )
*/
---- LOGIC LAYER ----

, LOGIC_PB as (
    SELECT
        DATE
      , ASIN
      , ASIN_KEY
      , PLATFORM
      , SUM_FIRST_PARTY_SALES
      , SUM_THIRD_PARTY_SALES
      , SUM_TOTAL_SALES
      , SUM_FIRST_PARTY_UNITS
      , SUM_THIRD_PARTY_UNITS
      , SUM_TOTAL_UNITS
      , CATEGORY_NAME
      , CATEGORY_TYPE
      , PRODUCT_NAME
      , UPC
      , MODEL
      , BRAND_ID
      , BRAND_BK
      , BRAND_KEY
      , MAX_BULK_PRICE
      , MAX_BULK_UNIT_THRESHOLD
      , MIN_BULK_PRICE
      , MIN_BULK_UNIT_THRESHOLD
      , UNITS_ON_HAND_MEDIAN
      , UNITS_REPLENISHED
      , VALUE_ON_HAND
      , VALUE_REPLENISHED
      , REGION
      , STATE
      , HOMEDEPOT_REGION
      , LOWES_REGION
      , RETAILER
      , BUSINESS_UNIT
      , STORES       
      , SOURCE
    FROM SRC_PB
)
---- RENAME LAYER ----

, RENAME_PB as (
    SELECT
        DATE
      , ASIN
      , ASIN_KEY
      , PLATFORM
      , SUM_FIRST_PARTY_SALES
      , SUM_THIRD_PARTY_SALES
      , SUM_TOTAL_SALES
      , SUM_FIRST_PARTY_UNITS
      , SUM_THIRD_PARTY_UNITS
      , SUM_TOTAL_UNITS
      , CATEGORY_NAME
      , CATEGORY_TYPE
      , PRODUCT_NAME
      , UPC
      , MODEL
      , BRAND_ID
      , BRAND_BK
      , BRAND_KEY
      , MAX_BULK_PRICE
      , MAX_BULK_UNIT_THRESHOLD
      , MIN_BULK_PRICE
      , MIN_BULK_UNIT_THRESHOLD
      , UNITS_ON_HAND_MEDIAN
      , UNITS_REPLENISHED
      , VALUE_ON_HAND
      , VALUE_REPLENISHED
      , REGION
      , STATE
      , HOMEDEPOT_REGION
      , LOWES_REGION
      , RETAILER
      , BUSINESS_UNIT
      , STORES       
      , SOURCE
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
          DATE
        , ASIN
        , ASIN_KEY
        , PLATFORM
        , SUM_FIRST_PARTY_SALES
        , SUM_THIRD_PARTY_SALES
        , SUM_TOTAL_SALES
        , SUM_FIRST_PARTY_UNITS
        , SUM_THIRD_PARTY_UNITS
        , SUM_TOTAL_UNITS
        , CATEGORY_NAME
        , CATEGORY_TYPE
        , PRODUCT_NAME
        , UPC
        , MODEL
        , BRAND_ID
        , BRAND_BK
        , BRAND_KEY
        , MAX_BULK_PRICE
        , MAX_BULK_UNIT_THRESHOLD
        , MIN_BULK_PRICE
        , MIN_BULK_UNIT_THRESHOLD
        , UNITS_ON_HAND_MEDIAN
        , UNITS_REPLENISHED
        , VALUE_ON_HAND
        , VALUE_REPLENISHED
        , REGION
        , STATE
        , HOMEDEPOT_REGION
        , LOWES_REGION
        , RETAILER
        , BUSINESS_UNIT
        , STORES         
        , SOURCE
FROM JOIN_RESULT