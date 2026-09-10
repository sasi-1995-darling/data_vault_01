{{ config(materialized='table') }}
---- SRC LAYER ----
WITH
SRC_LMWD           as ( SELECT BKCC, LNK_COMPETITIVE_PRODUCT_RETAILER_HK, HOMEDEPOT_REGION, LOAD_DTS, LOCATIONS_WITH_INVENTORY, LOWES_REGION, MAX_BULK_PRICE, MAX_BULK_UNIT_THRESHOLD, MIN_BULK_PRICE, MIN_BULK_UNIT_THRESHOLD, REGION, REPORTING_PERIOD, RETAILER, SECTOR, STATE, UNITS_ON_HAND_MEDIAN, UNITS_REPLENISHED, UNITS_SOLD, UPC, VALUE_ON_HAND, VALUE_REPLENISHED, VALUE_SOLD, PSA_DELETE_IND FROM {{ ref('lmsat_pos_main_weekly__datavations') }} as SRC 
                        qualify row_number() over(partition by lnk_competitive_product_retailer_hk, reporting_period, region, state, lowes_region, homedepot_region order by load_dts desc)=1 )

, SRC_HC           as ( SELECT COMPETITIVE_PRODUCT_HK, COMPETITIVE_PRODUCT_BK FROM {{ ref('hub_competitive_product') }} as SRC )

, SRC_HR           as ( SELECT RETAILER_HK, RETAILER_BK FROM {{ ref('hub_retailer') }} as SRC )

, SRC_LNK          as ( SELECT COMPETITIVE_PRODUCT_RETAILER_HK, COMPETITIVE_PRODUCT_HK, RETAILER_HK, LOAD_DTS, REC_SRC,BKCC FROM {{ref('lnk_competitive_product_retailer')}} as SRC)
/*
SRC_LMWD           as ( SELECT * FROM raw_vault.lsat_pos_main_weekly__datavations )
SRC_HC             as ( SELECT * FROM raw_vault.hub_competitive_product )
SRC_HR             as ( SELECT * FROM raw_vault.hub_retailer )
SRC_LNK            as ( SELECT * FROM raw_vault.lnk_competitive_product_retailer )
*/
---- LOGIC LAYER ----
, LOGIC_LNK as (
    SELECT 
        COMPETITIVE_PRODUCT_RETAILER_HK
      , COMPETITIVE_PRODUCT_HK
      , RETAILER_HK
      , LOAD_DTS
      , REC_SRC
      , BKCC
      FROM  SRC_LNK 
)

, LOGIC_HC as (
    SELECT
        COMPETITIVE_PRODUCT_HK
      , COMPETITIVE_PRODUCT_BK
     FROM SRC_HC  
)

, LOGIC_HR as (
    SELECT 
        RETAILER_HK
      , RETAILER_BK 
     FROM SRC_HR
)

, LOGIC_LMWD as (
    SELECT
        LNK_COMPETITIVE_PRODUCT_RETAILER_HK
      , UPC
      , REPORTING_PERIOD
      , VALUE_SOLD::NUMBER                as VALUE_SOLD
      , UNITS_SOLD::NUMBER                as UNITS_SOLD  
      , MAX_BULK_PRICE::NUMBER            as MAX_BULK_PRICE
      , MAX_BULK_UNIT_THRESHOLD::NUMBER   as MAX_BULK_UNIT_THRESHOLD
      , MIN_BULK_PRICE::NUMBER            as MIN_BULK_PRICE
      , MIN_BULK_UNIT_THRESHOLD::NUMBER   as MIN_BULK_UNIT_THRESHOLD
      , UNITS_ON_HAND_MEDIAN::NUMBER      as UNITS_ON_HAND_MEDIAN
      , UNITS_REPLENISHED::NUMBER         as UNITS_REPLENISHED
      , VALUE_ON_HAND::NUMBER             as VALUE_ON_HAND
      , VALUE_REPLENISHED::NUMBER         as VALUE_REPLENISHED
      , REGION
      , STATE
      , HOMEDEPOT_REGION
      , LOWES_REGION
      , RETAILER
      , SECTOR
      , LOCATIONS_WITH_INVENTORY::NUMBER  as LOCATIONS_WITH_INVENTORY
      , LOAD_DTS
      , BKCC
      , PSA_DELETE_IND
    FROM SRC_LMWD
)

, RENAME_LNK as (
    SELECT *
      FROM  LOGIC_LNK 
)

, RENAME_HC as (
    SELECT * 
      FROM LOGIC_HC
)

, RENAME_HR as (
    SELECT * 
      FROM LOGIC_HR
)

, RENAME_LMWD as (
    SELECT *
      FROM LOGIC_LMWD
)

, FILTER_LNK as (
    SELECT * 
      FROM RENAME_LNK
     WHERE rec_src = 'US.DATAVATIONS.MAIN_WEEKLY'
)

, FILTER_HC as (
    SELECT * 
      FROM RENAME_HC
)

, FILTER_HR as (
    SELECT *
      FROM RENAME_HR
)

, FILTER_LMWD as (
    SELECT * 
      FROM RENAME_LMWD
     WHERE PSA_DELETE_IND = 'N' 
)

, JOIN_RESULT as (
    SELECT 
        lnk.COMPETITIVE_PRODUCT_RETAILER_HK
      , hc.COMPETITIVE_PRODUCT_HK
      , hc.COMPETITIVE_PRODUCT_BK
      , hr.RETAILER_BK
      , hr.RETAILER_HK
      , lmwd.UPC
      , lmwd.REPORTING_PERIOD
      , lmwd.VALUE_SOLD
      , lmwd.UNITS_SOLD 
      , lmwd.MAX_BULK_PRICE
      , lmwd.MAX_BULK_UNIT_THRESHOLD
      , lmwd.MIN_BULK_PRICE
      , lmwd.MIN_BULK_UNIT_THRESHOLD
      , lmwd.UNITS_ON_HAND_MEDIAN
      , lmwd.UNITS_REPLENISHED
      , lmwd.VALUE_ON_HAND
      , lmwd.VALUE_REPLENISHED
      , lmwd.REGION
      , lmwd.STATE
      , lmwd.HOMEDEPOT_REGION
      , lmwd.LOWES_REGION
      , lmwd.RETAILER
      , lmwd.SECTOR
      , lmwd.LOCATIONS_WITH_INVENTORY
      , lmwd.LOAD_DTS
      , lnk.BKCC
      , lnk.REC_SRC
      , lmwd.PSA_DELETE_IND      
      FROM FILTER_LNK lnk
      JOIN FILTER_HC  hc
        ON lnk.COMPETITIVE_PRODUCT_HK = hc.COMPETITIVE_PRODUCT_HK
      JOIN FILTER_HR hr 
        ON lnk.RETAILER_HK = hr.RETAILER_HK
      JOIN FILTER_LMWD lmwd 
        ON lnk.COMPETITIVE_PRODUCT_RETAILER_HK = lmwd.lnk_competitive_product_retailer_hk      

)

---- FINAL LAYER ----
SELECT
          row_number() over(order by 1)                                as SEQ_ID
        , current_timestamp                                            as SNAPSHOT_DTS
        , COMPETITIVE_PRODUCT_HK
        , COMPETITIVE_PRODUCT_BK
        , RETAILER_HK
        , RETAILER_BK
        , UPC
        , REPORTING_PERIOD
        , VALUE_SOLD
        , UNITS_SOLD
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
        , SECTOR
        , LOCATIONS_WITH_INVENTORY
        , LOAD_DTS
        , BKCC
        , REC_SRC
        , PSA_DELETE_IND
FROM JOIN_RESULT        

