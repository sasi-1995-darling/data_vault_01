{{ config(materialized='table',
    transient = true) }}
-- Intentional materialization override to avoid performance bottlenecks caused by chained ephemeral models.
---- SRC LAYER ----
WITH
SRC_LCPR           as ( SELECT COMPETITIVE_PRODUCT_HK, RETAILER_HK FROM {{ ref('lnk_competitive_product_retailer') }} as SRC  ),
SRC_HC             as ( SELECT BKCC, COMPETITIVE_PRODUCT_HK, REC_SRC FROM {{ ref('hub_competitive_product') }} as SRC  ),
SRC_HR             as ( SELECT RETAILER_HK FROM {{ ref('hub_retailer') }} as SRC  ),
SRC_SID            as ( SELECT BRAND, COMPETITIVE_PRODUCT_HK, ITEM_ID, ITEM_NAME, STORE_ITEM_ID FROM {{ ref('pb_item_details__datavations') }} as SRC  ),
SRC_LD             as ( SELECT COMPETITIVE_PRODUCT_HK, HOMEDEPOT_REGION, LOCATIONS_WITH_INVENTORY, LOWES_REGION, MAX_BULK_PRICE, MAX_BULK_UNIT_THRESHOLD, MIN_BULK_PRICE, MIN_BULK_UNIT_THRESHOLD, REGION, REPORTING_PERIOD, RETAILER, RETAILER_HK, SECTOR, STATE, UNITS_ON_HAND_MEDIAN, UNITS_REPLENISHED, UNITS_SOLD, UPC, VALUE_ON_HAND, VALUE_REPLENISHED, VALUE_SOLD FROM {{ ref('pb_pos_main_weekly__datavations') }} as SRC  )

/*
SRC_LCPR           as ( SELECT * FROM raw_vault.lnk_competitive_product_retailer )
SRC_HC             as ( SELECT * FROM raw_vault.hub_competitive_product )
SRC_HR             as ( SELECT * FROM raw_vault.hub_retailer )
SRC_SID            as ( SELECT * FROM bus_vault.PB_ITEM_DETAILS__DATAVATIONS )
SRC_LD             as ( SELECT * FROM bus_vault.PB_POS_MAIN_WEEKLY__DATAVATIONS )
*/
---- LOGIC LAYER ----

, LOGIC_LCPR as (
    SELECT
        COMPETITIVE_PRODUCT_HK                                       as                        LCPR_COMPETITIVE_PRODUCT_HK
      , RETAILER_HK                                                  as                                   LCPR_RETAILER_HK
    FROM SRC_LCPR
)

, LOGIC_HC as (
    SELECT
        COMPETITIVE_PRODUCT_HK                                       as                          HC_COMPETITIVE_PRODUCT_HK
      , BKCC
      , REC_SRC
    FROM SRC_HC
)

, LOGIC_HR as (
    SELECT
        RETAILER_HK                                                  as                                     HR_RETAILER_HK
    FROM SRC_HR
)

, LOGIC_SID as (
    SELECT
        COMPETITIVE_PRODUCT_HK                                       as                         SID_COMPETITIVE_PRODUCT_HK
      , ITEM_NAME                                                    as                                      SID_ITEM_NAME
      , ITEM_ID                                                      as                                        SID_ITEM_ID
      , BRAND                                                        as                                          SID_BRAND
      , STORE_ITEM_ID                                                as                                  SID_STORE_ITEM_ID
    FROM SRC_SID
)

, LOGIC_LD as (
    SELECT
        COMPETITIVE_PRODUCT_HK                                       as                          LD_COMPETITIVE_PRODUCT_HK
      , RETAILER_HK                                                  as                                     LD_RETAILER_HK
      , REPORTING_PERIOD                                             as                                LD_REPORTING_PERIOD
      , VALUE_SOLD                                                   as                                      LD_VALUE_SOLD
      , UNITS_SOLD                                                   as                                      LD_UNITS_SOLD
      , UPC                                                          as                                             LD_UPC
      , MAX_BULK_PRICE                                               as                                  LD_MAX_BULK_PRICE
      , MAX_BULK_UNIT_THRESHOLD                                      as                         LD_MAX_BULK_UNIT_THRESHOLD
      , MIN_BULK_PRICE                                               as                                  LD_MIN_BULK_PRICE
      , MIN_BULK_UNIT_THRESHOLD                                      as                         LD_MIN_BULK_UNIT_THRESHOLD
      , UNITS_ON_HAND_MEDIAN                                         as                            LD_UNITS_ON_HAND_MEDIAN
      , UNITS_REPLENISHED                                            as                               LD_UNITS_REPLENISHED
      , VALUE_ON_HAND                                                as                                   LD_VALUE_ON_HAND
      , VALUE_REPLENISHED                                            as                               LD_VALUE_REPLENISHED
      , REGION                                                       as                                          LD_REGION
      , STATE                                                        as                                           LD_STATE
      , HOMEDEPOT_REGION                                             as                                LD_HOMEDEPOT_REGION
      , LOWES_REGION                                                 as                                    LD_LOWES_REGION
      , RETAILER                                                     as                                        LD_RETAILER
      , SECTOR                                                       as                                          LD_SECTOR
      , LOCATIONS_WITH_INVENTORY                                     as                        LD_LOCATIONS_WITH_INVENTORY
    FROM SRC_LD
)
---- RENAME LAYER ----

, RENAME_LCPR as (
    SELECT
        LCPR_COMPETITIVE_PRODUCT_HK
      , LCPR_RETAILER_HK
    FROM LOGIC_LCPR
)

, RENAME_HC as (
    SELECT
        HC_COMPETITIVE_PRODUCT_HK
      , BKCC
      , REC_SRC
    FROM LOGIC_HC
)

, RENAME_HR as (
    SELECT
        HR_RETAILER_HK
    FROM LOGIC_HR
)

, RENAME_SID as (
    SELECT
        SID_COMPETITIVE_PRODUCT_HK
      , SID_ITEM_NAME
      , SID_ITEM_ID
      , SID_BRAND
      , SID_STORE_ITEM_ID
    FROM LOGIC_SID
)

, RENAME_LD as (
    SELECT
        LD_COMPETITIVE_PRODUCT_HK
      , LD_RETAILER_HK
      , LD_REPORTING_PERIOD
      , LD_VALUE_SOLD
      , LD_UNITS_SOLD
      , LD_UPC
      , LD_MAX_BULK_PRICE
      , LD_MAX_BULK_UNIT_THRESHOLD
      , LD_MIN_BULK_PRICE
      , LD_MIN_BULK_UNIT_THRESHOLD
      , LD_UNITS_ON_HAND_MEDIAN
      , LD_UNITS_REPLENISHED
      , LD_VALUE_ON_HAND
      , LD_VALUE_REPLENISHED
      , LD_REGION
      , LD_STATE
      , LD_HOMEDEPOT_REGION
      , LD_LOWES_REGION
      , LD_RETAILER
      , LD_SECTOR
      , LD_LOCATIONS_WITH_INVENTORY
    FROM LOGIC_LD
)
---- FILTER LAYER ----

, FILTER_LCPR as (
    SELECT *
    FROM RENAME_LCPR
)

, FILTER_HC as (
    SELECT *
    FROM RENAME_HC
)

, FILTER_HR as (
    SELECT *
    FROM RENAME_HR
)

, FILTER_SID as (
    SELECT *
    FROM RENAME_SID
)

, FILTER_LD as (
    SELECT *
    FROM RENAME_LD
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_LCPR
    INNER JOIN FILTER_HC
        ON LCPR_COMPETITIVE_PRODUCT_HK = HC_COMPETITIVE_PRODUCT_HK
    INNER JOIN FILTER_HR
        ON LCPR_RETAILER_HK = HR_RETAILER_HK
    INNER JOIN FILTER_SID
        ON LCPR_COMPETITIVE_PRODUCT_HK = SID_COMPETITIVE_PRODUCT_HK
    INNER JOIN FILTER_LD
        ON LCPR_COMPETITIVE_PRODUCT_HK = LD_COMPETITIVE_PRODUCT_HK AND LCPR_RETAILER_HK=LD_RETAILER_HK
)

---- FINAL LAYER ----
SELECT
          COALESCE(LD_REPORTING_PERIOD+5,'1900-01-01')                 as DATE
        , 'N/A'                                                        as ASIN
        , MD5_BINARY(0::varchar)                                       as ASIN_KEY
        , 'N/A'                                                        as PLATFORM
        , NULL                                                         as SUM_FIRST_PARTY_SALES
        , NULL                                                         as SUM_THIRD_PARTY_SALES
        , LD_VALUE_SOLD::NUMBER                                        as SUM_TOTAL_SALES
        , NULL                                                         as SUM_FIRST_PARTY_UNITS
        , NULL                                                         as SUM_THIRD_PARTY_UNITS
        , LD_UNITS_SOLD::NUMBER                                        as SUM_TOTAL_UNITS
        , 'N/A'                                                        as CATEGORY_NAME
        , 'N/A'                                                        as CATEGORY_TYPE
        , COALESCE(SID_ITEM_NAME,'N/A')                                as PRODUCT_NAME
        , COALESCE(LD_UPC,'N/A')                                       as UPC
        , COALESCE(SID_ITEM_ID::VARCHAR,'N/A')                         as MODEL
        , COALESCE(SID_BRAND::VARCHAR,'N/A')                           as BRAND_ID
        , 'N/A'                                                        as BRAND_BK
        , MD5_BINARY(0::varchar)                                       as BRAND_KEY
        , LD_MAX_BULK_PRICE::NUMBER                                    as MAX_BULK_PRICE
        , LD_MAX_BULK_UNIT_THRESHOLD::NUMBER                           as MAX_BULK_UNIT_THRESHOLD
        , LD_MIN_BULK_PRICE::NUMBER                                    as MIN_BULK_PRICE
        , LD_MIN_BULK_UNIT_THRESHOLD::NUMBER                           as MIN_BULK_UNIT_THRESHOLD
        , LD_UNITS_ON_HAND_MEDIAN::NUMBER                              as UNITS_ON_HAND_MEDIAN
        , LD_UNITS_REPLENISHED::NUMBER                                 as UNITS_REPLENISHED
        , LD_VALUE_ON_HAND::NUMBER                                     as VALUE_ON_HAND
        , LD_VALUE_REPLENISHED::NUMBER                                 as VALUE_REPLENISHED
        , COALESCE(LD_REGION,'N/A')                                    as REGION
        , COALESCE(LD_STATE,'N/A')                                     as STATE
        , COALESCE(LD_HOMEDEPOT_REGION,'N/A')                          as HOMEDEPOT_REGION
        , COALESCE(LD_LOWES_REGION,'N/A')                              as LOWES_REGION
        , COALESCE(LD_RETAILER,'N/A')                                  as RETAILER
        , COALESCE(LD_SECTOR,'N/A')                                    as SECTOR
        , COALESCE(LD_LOCATIONS_WITH_INVENTORY::NUMBER,0)              as LOCATIONS_WITH_INVENTORY
        , 'DATAVATIONS'                                                as SOURCE
        , BKCC
        , SID_STORE_ITEM_ID::NUMBER                                    as STORE_ITEM_ID
        , REC_SRC
FROM JOIN_RESULT
