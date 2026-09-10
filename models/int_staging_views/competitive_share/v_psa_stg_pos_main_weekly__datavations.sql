---- SRC LAYER ----
WITH
SRC_S              as ( SELECT AVG_SELLING_PRICE, BRAND, CATEGORY, DEPARTMENT, HOMEDEPOT_REGION, INVENTORY_CREATED_AT, INVENTORY_MODIFIED_AT, ITEM_ID, ITEM_NAME, LOCATIONS_WITH_INVENTORY, LOCATION_TYPE, LOWES_REGION, MAX_BULK_PRICE, MAX_BULK_UNIT_THRESHOLD, MAX_PRICE, MIN_BULK_PRICE, MIN_BULK_UNIT_THRESHOLD, MIN_PRICE, PARENT_CATEGORY, PRICE_CREATED_AT, PRICE_MODIFIED_AT, PSA_DELETE_IND, PSA_LOAD_DTS, REGION, REPORTING_PERIOD, REPORTING_PERIOD_MONTH, RETAILER, RETAILER_CATEGORIES, RETAILER_FRIENDLY, SECTOR, STATE, STORE_ITEM_ID, UNITS_ON_HAND, UNITS_ON_HAND_MEDIAN, UNITS_REPLENISHED, UNITS_SOLD, UPC, VALUE_ON_HAND, VALUE_REPLENISHED, VALUE_SOLD FROM {{ source('incoming_pos', 'main_weekly') }} as SRC  ),
SRC_a              as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  )
/*
SRC_S              as ( SELECT * FROM datavations.main_weekly_vw )
SRC_a              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        coalesce(nullif(trim(ITEM_ID), ''), '-1')                    as                             COMPETITIVE_PRODUCT_BK
      , coalesce(nullif(trim(RETAILER), ''), '-1')                   as                                        RETAILER_BK
      , REPORTING_PERIOD
      , BRAND
      , DEPARTMENT
      , CATEGORY
      , STATE
      , LOWES_REGION
      , HOMEDEPOT_REGION
      , ITEM_ID::VARCHAR                                             as                                            ITEM_ID
      , REGION
      , CONVERT_TIMEZONE('UTC', INVENTORY_MODIFIED_AT)                        as                                           LOAD_DTS
      , PSA_LOAD_DTS
      , AVG_SELLING_PRICE
      , UNITS_ON_HAND
      , INVENTORY_CREATED_AT
      , INVENTORY_MODIFIED_AT
      , ITEM_NAME
      , LOCATION_TYPE
      , LOCATIONS_WITH_INVENTORY
      , MAX_BULK_PRICE
      , MAX_BULK_UNIT_THRESHOLD
      , MAX_PRICE
      , MIN_BULK_PRICE
      , MIN_BULK_UNIT_THRESHOLD
      , MIN_PRICE
      , PARENT_CATEGORY
      , PRICE_CREATED_AT
      , PRICE_MODIFIED_AT
      , REPORTING_PERIOD_MONTH
      , RETAILER
      , RETAILER_CATEGORIES
      , RETAILER_FRIENDLY
      , SECTOR
      , STORE_ITEM_ID
      , UNITS_ON_HAND_MEDIAN
      , UNITS_REPLENISHED
      , UNITS_SOLD
      , UPC
      , VALUE_ON_HAND
      , VALUE_REPLENISHED
      , VALUE_SOLD
      , PSA_DELETE_IND
    FROM SRC_S
)

, LOGIC_a as (
    SELECT
        BKCC
      , REC_SRC
    FROM SRC_a
)
---- RENAME LAYER ----

, RENAME_S as (
    SELECT
        COMPETITIVE_PRODUCT_BK
      , RETAILER_BK
      , REPORTING_PERIOD
      , BRAND
      , DEPARTMENT
      , CATEGORY
      , STATE
      , LOWES_REGION
      , HOMEDEPOT_REGION
      , ITEM_ID
      , REGION
      , LOAD_DTS
      , PSA_LOAD_DTS
      , AVG_SELLING_PRICE
      , UNITS_ON_HAND
      , INVENTORY_CREATED_AT
      , INVENTORY_MODIFIED_AT
      , ITEM_NAME
      , LOCATION_TYPE
      , LOCATIONS_WITH_INVENTORY
      , MAX_BULK_PRICE
      , MAX_BULK_UNIT_THRESHOLD
      , MAX_PRICE
      , MIN_BULK_PRICE
      , MIN_BULK_UNIT_THRESHOLD
      , MIN_PRICE
      , PARENT_CATEGORY
      , PRICE_CREATED_AT
      , PRICE_MODIFIED_AT
      , REPORTING_PERIOD_MONTH
      , RETAILER
      , RETAILER_CATEGORIES
      , RETAILER_FRIENDLY
      , SECTOR
      , STORE_ITEM_ID
      , UNITS_ON_HAND_MEDIAN
      , UNITS_REPLENISHED
      , UNITS_SOLD
      , UPC
      , VALUE_ON_HAND
      , VALUE_REPLENISHED
      , VALUE_SOLD
      , PSA_DELETE_IND
    FROM LOGIC_S
)

, RENAME_a as (
    SELECT
        BKCC
      , REC_SRC
    FROM LOGIC_a
)
---- FILTER LAYER ----

, FILTER_S as (
    SELECT *
    FROM RENAME_S
)

, FILTER_a as (
    SELECT *
    FROM RENAME_a
    WHERE rec_src = 'US.DATAVATIONS.MAIN_WEEKLY'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_S
    INNER JOIN FILTER_a
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          COMPETITIVE_PRODUCT_BK
        , RETAILER_BK
        , REPORTING_PERIOD
        , BRAND
        , DEPARTMENT
        , CATEGORY
        , STATE
        , LOWES_REGION
        , HOMEDEPOT_REGION
        , ITEM_ID
        , REGION
        , LOAD_DTS
        , PSA_LOAD_DTS
        , AVG_SELLING_PRICE
        , UNITS_ON_HAND
        , INVENTORY_CREATED_AT
        , INVENTORY_MODIFIED_AT
        , ITEM_NAME
        , LOCATION_TYPE
        , LOCATIONS_WITH_INVENTORY
        , MAX_BULK_PRICE
        , MAX_BULK_UNIT_THRESHOLD
        , MAX_PRICE
        , MIN_BULK_PRICE
        , MIN_BULK_UNIT_THRESHOLD
        , MIN_PRICE
        , PARENT_CATEGORY
        , PRICE_CREATED_AT
        , PRICE_MODIFIED_AT
        , REPORTING_PERIOD_MONTH
        , RETAILER
        , RETAILER_CATEGORIES
        , RETAILER_FRIENDLY
        , SECTOR
        , STORE_ITEM_ID
        , UNITS_ON_HAND_MEDIAN
        , UNITS_REPLENISHED
        , UNITS_SOLD
        , UPC
        , VALUE_ON_HAND
        , VALUE_REPLENISHED
        , VALUE_SOLD
        , PSA_DELETE_IND
        , BKCC
        , REC_SRC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(RETAILER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as RETAILER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(COMPETITIVE_PRODUCT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as COMPETITIVE_PRODUCT_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(COMPETITIVE_PRODUCT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(RETAILER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as LNK_COMPETITIVE_PRODUCT_RETAILER_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(AVG_SELLING_PRICE::text), '^^') 
            , '||', IFNULL(TRIM(BRAND::text), '^^') 
            , '||', IFNULL(TRIM(CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(DEPARTMENT::text), '^^') 
            , '||', IFNULL(TRIM(UNITS_ON_HAND::text), '^^') 
            , '||', IFNULL(TRIM(INVENTORY_CREATED_AT::text), '^^') 
            , '||', IFNULL(TRIM(INVENTORY_MODIFIED_AT::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_ID::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_NAME::text), '^^') 
            , '||', IFNULL(TRIM(LOCATION_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(LOCATIONS_WITH_INVENTORY::text), '^^') 
            , '||', IFNULL(TRIM(MAX_BULK_PRICE::text), '^^') 
            , '||', IFNULL(TRIM(MAX_BULK_UNIT_THRESHOLD::text), '^^') 
            , '||', IFNULL(TRIM(MAX_PRICE::text), '^^') 
            , '||', IFNULL(TRIM(MIN_BULK_PRICE::text), '^^') 
            , '||', IFNULL(TRIM(MIN_BULK_UNIT_THRESHOLD::text), '^^') 
            , '||', IFNULL(TRIM(MIN_PRICE::text), '^^') 
            , '||', IFNULL(TRIM(PARENT_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(PRICE_CREATED_AT::text), '^^') 
            , '||', IFNULL(TRIM(PRICE_MODIFIED_AT::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
            , '||', IFNULL(TRIM(REPORTING_PERIOD_MONTH::text), '^^') 
            , '||', IFNULL(TRIM(RETAILER::text), '^^') 
            , '||', IFNULL(TRIM(RETAILER_CATEGORIES::text), '^^') 
            , '||', IFNULL(TRIM(RETAILER_FRIENDLY::text), '^^') 
            , '||', IFNULL(TRIM(SECTOR::text), '^^') 
            , '||', IFNULL(TRIM(STORE_ITEM_ID::text), '^^') 
            , '||', IFNULL(TRIM(UNITS_ON_HAND_MEDIAN::text), '^^') 
            , '||', IFNULL(TRIM(UNITS_REPLENISHED::text), '^^') 
            , '||', IFNULL(TRIM(UNITS_SOLD::text), '^^') 
            , '||', IFNULL(TRIM(UPC::text), '^^') 
            , '||', IFNULL(TRIM(VALUE_ON_HAND::text), '^^') 
            , '||', IFNULL(TRIM(VALUE_REPLENISHED::text), '^^') 
            , '||', IFNULL(TRIM(VALUE_SOLD::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
