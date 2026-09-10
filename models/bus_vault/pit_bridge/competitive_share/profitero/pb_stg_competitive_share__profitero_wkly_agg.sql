{{ config(materialized='table',
    transient = true) }}
-- Intentional materialization override to avoid performance bottlenecks caused by chained ephemeral models.


---- SRC LAYER ----
WITH
SRC_CS             as ( SELECT ASIN, ASIN_KEY, BKCC, BRAND_BK, BRAND_ID, BRAND_KEY, BUSINESS_UNIT, CATEGORY_NAME, CATEGORY_TYPE, FIRST_PARTY_SALES, FIRST_PARTY_UNITS, MODEL, PLATFORM, PRODUCT_NAME, REC_SRC, SOURCE, THIRD_PARTY_SALES, THIRD_PARTY_UNITS, TOTAL_SALES, TOTAL_UNITS, TRANSACTION_DATE, UPC FROM {{ ref('pb_stg_competitive_share__profitero_wkly') }} as SRC  )

/*
SRC_CS             as ( SELECT * FROM bus_vault.PB_STG_COMPETITIVE_SHARE__PROFITERO_WKLY )
*/
---- LOGIC LAYER ----

, LOGIC_CS as (
    SELECT
        TRANSACTION_DATE                                             as                                CS_TRANSACTION_DATE
      , ASIN                                                         as                                            CS_ASIN
      , ASIN_KEY                                                     as                                        CS_ASIN_KEY
      , PLATFORM                                                     as                                        CS_PLATFORM
      , FIRST_PARTY_SALES                                            as                               CS_FIRST_PARTY_SALES
      , THIRD_PARTY_SALES                                            as                               CS_THIRD_PARTY_SALES
      , TOTAL_SALES                                                  as                                     CS_TOTAL_SALES
      , FIRST_PARTY_UNITS                                            as                               CS_FIRST_PARTY_UNITS
      , THIRD_PARTY_UNITS                                            as                               CS_THIRD_PARTY_UNITS
      , TOTAL_UNITS                                                  as                                     CS_TOTAL_UNITS
      , CATEGORY_NAME                                                as                                   CS_CATEGORY_NAME
      , CATEGORY_TYPE                                                as                                   CS_CATEGORY_TYPE
      , PRODUCT_NAME                                                 as                                    CS_PRODUCT_NAME
      , UPC                                                          as                                             CS_UPC
      , MODEL                                                        as                                           CS_MODEL
      , BRAND_ID                                                     as                                        CS_BRAND_ID
      , BRAND_BK                                                     as                                        CS_BRAND_BK
      , BRAND_KEY                                                    as                                       CS_BRAND_KEY
      , COALESCE(CS_TRANSACTION_DATE,'1900-01-01')                   as                                               DATE
      , COALESCE(CS_ASIN,'N/A')                                      as                                               ASIN
      , COALESCE(CS_ASIN_KEY,MD5_BINARY(0::varchar))                 as                                           ASIN_KEY
      , COALESCE(CS_PLATFORM,'N/A')                                  as                                           PLATFORM
      , COALESCE(CS_CATEGORY_NAME,'N/A')                             as                                      CATEGORY_NAME
      , COALESCE(CS_CATEGORY_TYPE,'N/A')                             as                                      CATEGORY_TYPE
      , COALESCE(CS_PRODUCT_NAME,'N/A')                              as                                       PRODUCT_NAME
      , COALESCE(CS_UPC,'N/A')                                       as                                                UPC
      , COALESCE(CS_MODEL,'N/A')                                     as                                              MODEL
      , COALESCE(CS_BRAND_ID::VARCHAR,'N/A')                         as                                           BRAND_ID
      , COALESCE(CS_BRAND_BK,'0')                                    as                                           BRAND_BK
      , COALESCE(CS_BRAND_KEY,MD5_BINARY(0::varchar))                as                                          BRAND_KEY
      , BUSINESS_UNIT
      , SOURCE
      , BKCC
      , REC_SRC
    FROM SRC_CS
)
---- RENAME LAYER ----

, RENAME_CS as (
    SELECT
        CS_TRANSACTION_DATE
      , CS_ASIN
      , CS_ASIN_KEY
      , CS_PLATFORM
      , CS_FIRST_PARTY_SALES
      , CS_THIRD_PARTY_SALES
      , CS_TOTAL_SALES
      , CS_FIRST_PARTY_UNITS
      , CS_THIRD_PARTY_UNITS
      , CS_TOTAL_UNITS
      , CS_CATEGORY_NAME
      , CS_CATEGORY_TYPE
      , CS_PRODUCT_NAME
      , CS_UPC
      , CS_MODEL
      , CS_BRAND_ID
      , CS_BRAND_BK
      , CS_BRAND_KEY
      , DATE
      , ASIN
      , ASIN_KEY
      , PLATFORM
      , CATEGORY_NAME
      , CATEGORY_TYPE
      , PRODUCT_NAME
      , UPC
      , MODEL
      , BRAND_ID
      , BRAND_BK
      , BRAND_KEY
      , BUSINESS_UNIT
      , SOURCE
      , BKCC
      , REC_SRC
    FROM LOGIC_CS
)
---- FILTER LAYER ----

, FILTER_CS as (
    SELECT *
    FROM RENAME_CS
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_CS
)

---- FINAL LAYER ----
SELECT
          DATE
        , ASIN
        , ASIN_KEY
        , PLATFORM
        , SUM(CS_FIRST_PARTY_SALES::NUMBER)                            as SUM_FIRST_PARTY_SALES
        , SUM(CS_THIRD_PARTY_SALES::NUMBER)                            as SUM_THIRD_PARTY_SALES
        , SUM(CS_TOTAL_SALES::NUMBER)                                  as SUM_TOTAL_SALES
        , SUM(CS_FIRST_PARTY_UNITS::NUMBER)                            as SUM_FIRST_PARTY_UNITS
        , SUM(CS_THIRD_PARTY_UNITS::NUMBER)                            as SUM_THIRD_PARTY_UNITS
        , SUM(CS_TOTAL_UNITS::NUMBER)                                  as SUM_TOTAL_UNITS
        , CATEGORY_NAME
        , CATEGORY_TYPE
        , PRODUCT_NAME
        , UPC
        , MODEL
        , BRAND_ID
        , BRAND_BK
        , BRAND_KEY
        , NULL                                                         as MAX_BULK_PRICE
        , NULL                                                         as MAX_BULK_UNIT_THRESHOLD
        , NULL                                                         as MIN_BULK_PRICE
        , NULL                                                         as MIN_BULK_UNIT_THRESHOLD
        , NULL                                                         as UNITS_ON_HAND_MEDIAN
        , NULL                                                         as UNITS_REPLENISHED
        , NULL                                                         as VALUE_ON_HAND
        , NULL                                                         as VALUE_REPLENISHED
        , 'N/A'                                                        as REGION
        , 'N/A'                                                        as STATE
        , 'N/A'                                                        as HOMEDEPOT_REGION
        , 'N/A'                                                        as LOWES_REGION
        , BUSINESS_UNIT
        , SOURCE
        , BKCC
        , REC_SRC
FROM JOIN_RESULT
GROUP BY ALL