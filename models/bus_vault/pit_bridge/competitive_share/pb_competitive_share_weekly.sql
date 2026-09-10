---- SRC LAYER ----
WITH
SRC_CS             as ( SELECT ASIN, ASIN_KEY, BKCC, BRAND_BK, BRAND_ID, BRAND_KEY, BUSINESS_UNIT, CATEGORY_NAME, CATEGORY_TYPE, DATE, HOMEDEPOT_REGION, LOWES_REGION, MAX_BULK_PRICE, MAX_BULK_UNIT_THRESHOLD, MIN_BULK_PRICE, MIN_BULK_UNIT_THRESHOLD, MODEL, PLATFORM, PRODUCT_NAME, REC_SRC, REGION, RETAILER, SOURCE, STATE, STORES, SUM_FIRST_PARTY_SALES, SUM_FIRST_PARTY_UNITS, SUM_THIRD_PARTY_SALES, SUM_THIRD_PARTY_UNITS, SUM_TOTAL_SALES, SUM_TOTAL_UNITS, UNITS_ON_HAND_MEDIAN, UNITS_REPLENISHED, UPC, VALUE_ON_HAND, VALUE_REPLENISHED FROM {{ ref('pb_stg_competitive_share_union_weekly') }} as SRC  )

/*
SRC_CS             as ( SELECT * FROM bus_vault.PB_STG_COMPETITIVE_SHARE_UNION_WEEKLY )
*/
---- LOGIC LAYER ----

, LOGIC_CS as (
    SELECT
        DATE
      , ASIN                                                         as                                            CS_ASIN
      , CS_ASIN                                as                                               ASIN
      , ASIN_KEY
      , PLATFORM                                                     as                                        CS_PLATFORM
      , CS_PLATFORM                            as                                           PLATFORM
      , SUM_FIRST_PARTY_SALES
      , SUM_THIRD_PARTY_SALES
      , SUM_TOTAL_SALES
      , SUM_FIRST_PARTY_UNITS
      , SUM_THIRD_PARTY_UNITS
      , SUM_TOTAL_UNITS
      , CATEGORY_NAME                                                as                                   CS_CATEGORY_NAME
      , CATEGORY_TYPE                                                as                                   CS_CATEGORY_TYPE
      , PRODUCT_NAME                                                 as                                    CS_PRODUCT_NAME
      , UPC                                                          as                                             CS_UPC
      , MODEL                                                        as                                           CS_MODEL
      , BRAND_ID                                                     as                                        CS_BRAND_ID
      , BRAND_BK                                                     as                                        CS_BRAND_BK
      , BRAND_KEY                                                    as                                       CS_BRAND_KEY
      , MAX_BULK_PRICE
      , MAX_BULK_UNIT_THRESHOLD
      , MIN_BULK_PRICE
      , MIN_BULK_UNIT_THRESHOLD
      , UNITS_ON_HAND_MEDIAN
      , UNITS_REPLENISHED
      , VALUE_ON_HAND
      , VALUE_REPLENISHED
      , REGION                                                       as                                          CS_REGION
      , STATE                                                        as                                           CS_STATE
      , HOMEDEPOT_REGION                                             as                                CS_HOMEDEPOT_REGION
      , LOWES_REGION                                                 as                                    CS_LOWES_REGION
      , SOURCE                                                       as                                          CS_SOURCE
      , RETAILER
      , BUSINESS_UNIT                                                as                                   CS_BUSINESS_UNIT
      , STORES
      , BKCC
      , REC_SRC
    FROM SRC_CS
)
---- RENAME LAYER ----

, RENAME_CS as (
    SELECT
        DATE
      , CS_ASIN
      , ASIN
      , ASIN_KEY
      , CS_PLATFORM
      , PLATFORM
      , SUM_FIRST_PARTY_SALES
      , SUM_THIRD_PARTY_SALES
      , SUM_TOTAL_SALES
      , SUM_FIRST_PARTY_UNITS
      , SUM_THIRD_PARTY_UNITS
      , SUM_TOTAL_UNITS
      , CS_CATEGORY_NAME
      , CS_CATEGORY_TYPE
      , CS_PRODUCT_NAME
      , CS_UPC
      , CS_MODEL
      , CS_BRAND_ID
      , CS_BRAND_BK
      , CS_BRAND_KEY
      , MAX_BULK_PRICE
      , MAX_BULK_UNIT_THRESHOLD
      , MIN_BULK_PRICE
      , MIN_BULK_UNIT_THRESHOLD
      , UNITS_ON_HAND_MEDIAN
      , UNITS_REPLENISHED
      , VALUE_ON_HAND
      , VALUE_REPLENISHED
      , CS_REGION
      , CS_STATE
      , CS_HOMEDEPOT_REGION
      , CS_LOWES_REGION
      , CS_SOURCE
      , RETAILER
      , CS_BUSINESS_UNIT
      , STORES
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
          SEQ8()                                as SEQ_ID
        , current_timestamp                                            as SNAPSHOT_DTS
        , DATE
        , ASIN
        , ASIN_KEY
        , PLATFORM
        , SUM_FIRST_PARTY_SALES
        , SUM_THIRD_PARTY_SALES
        , SUM_TOTAL_SALES
        , SUM_FIRST_PARTY_UNITS
        , SUM_THIRD_PARTY_UNITS
        , SUM_TOTAL_UNITS
        , CS_CATEGORY_NAME                       as CATEGORY_NAME
        , CS_CATEGORY_TYPE                       as CATEGORY_TYPE
        , CS_PRODUCT_NAME                        as PRODUCT_NAME
        , CS_UPC                                 as UPC
        , CS_MODEL                               as MODEL
        , CS_BRAND_ID                            as BRAND_ID
        , CS_BRAND_BK                            as BRAND_BK
        , NVL(CS_BRAND_KEY,MD5_BINARY('N/A'))                          as BRAND_KEY
        , MAX_BULK_PRICE
        , MAX_BULK_UNIT_THRESHOLD
        , MIN_BULK_PRICE
        , MIN_BULK_UNIT_THRESHOLD
        , UNITS_ON_HAND_MEDIAN
        , UNITS_REPLENISHED
        , VALUE_ON_HAND
        , VALUE_REPLENISHED
        , CS_REGION
        , CS_STATE
        , CS_HOMEDEPOT_REGION
        , CS_LOWES_REGION
        , CS_SOURCE
        , CS_REGION                              as REGION
        , CS_STATE                               as STATE
        , CS_HOMEDEPOT_REGION                    as HOMEDEPOT_REGION
        , CS_LOWES_REGION                        as LOWES_REGION
        , CS_SOURCE                              as SOURCE
        , RETAILER
        , CS_BUSINESS_UNIT                       as BUSINESS_UNIT
        , STORES
        , BKCC
        , REC_SRC
FROM JOIN_RESULT
