---- SRC LAYER ----
WITH
SRC_S              as ( SELECT * FROM {{ source('menards_psa', 'moen_sales_and_inventory_history') }} as SRC 
                        where replace(replace(location, chr(0), ''), '"', '')  not in( '','Total') ),
SRC_A              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S              as ( SELECT * FROM menards_psa.moen_sales_and_inventory_history )
, SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        LOCATION                                                     as                                           STORE_BK
      , ITEM
      , FILE_NAME
      , CONVERT_TIMEZONE('UTC', LOAD_DATE)                           as                                           LOAD_DTS
      , LOCATION
      , FILE_ROW_NUMBER::VARCHAR                                     as                                    FILE_ROW_NUMBER
      , LOCATION_NAME
      , ITEM_NAME
      , SKU
      , METRICS
      , UNIT_SALES
      , DOLLAR_SALES
      , DOLLAR_MARGIN
      , MARGIN_PERCENT
      , TOTAL_UNITS_ON_HAND
      , TOTAL_DOLLAR_COST_ON_HAND
      , TOTAL_UNITS_ON_ORDER
      , TOTAL_DOLLAR_COST_ON_ORDER
      , STORE_CURRENT_UNITS_ON_HAND
      , STORE_DOLLAR_COST_ON_HAND
      , STORE_UNITS_ON_ORDER
      , STORE_DOLLAR_COST_ON_ORDER
      , FILE_LAST_MODIFIED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
    FROM SRC_S
)

, LOGIC_A as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_A
)
---- RENAME LAYER ----

, RENAME_S as (
    SELECT
        STORE_BK
      , ITEM
      , FILE_NAME
      , LOAD_DTS
      , LOCATION
      , FILE_ROW_NUMBER
      , LOCATION_NAME
      , ITEM_NAME
      , SKU
      , METRICS
      , UNIT_SALES
      , DOLLAR_SALES
      , DOLLAR_MARGIN
      , MARGIN_PERCENT
      , TOTAL_UNITS_ON_HAND
      , TOTAL_DOLLAR_COST_ON_HAND
      , TOTAL_UNITS_ON_ORDER
      , TOTAL_DOLLAR_COST_ON_ORDER
      , STORE_CURRENT_UNITS_ON_HAND
      , STORE_DOLLAR_COST_ON_HAND
      , STORE_UNITS_ON_ORDER
      , STORE_DOLLAR_COST_ON_ORDER
      , FILE_LAST_MODIFIED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
    FROM LOGIC_S
)

, RENAME_A as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_A
)
---- FILTER LAYER ----

, FILTER_S as (
    SELECT *
    FROM RENAME_S
)

, FILTER_A as (
    SELECT *
    FROM RENAME_A
    WHERE rec_src = 'US.EXCEL.MENARDS.MOEN_SALES_AND_INVENTORY_HISTORY'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_S
    INNER JOIN FILTER_A
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          STORE_BK
        , ITEM
        , FILE_NAME
        , LOAD_DTS
        , LOCATION
        , FILE_ROW_NUMBER
        , LOCATION_NAME
        , ITEM_NAME
        , SKU
        , METRICS
        , UNIT_SALES
        , DOLLAR_SALES
        , DOLLAR_MARGIN
        , MARGIN_PERCENT
        , TOTAL_UNITS_ON_HAND
        , TOTAL_DOLLAR_COST_ON_HAND
        , TOTAL_UNITS_ON_ORDER
        , TOTAL_DOLLAR_COST_ON_ORDER
        , STORE_CURRENT_UNITS_ON_HAND
        , STORE_DOLLAR_COST_ON_HAND
        , STORE_UNITS_ON_ORDER
        , STORE_DOLLAR_COST_ON_ORDER
        , FILE_LAST_MODIFIED
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(LOCATION as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as STORE_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(LOCATION_NAME::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_NAME::text), '^^') 
            , '||', IFNULL(TRIM(SKU::text), '^^') 
            , '||', IFNULL(TRIM(METRICS::text), '^^') 
            , '||', IFNULL(TRIM(UNIT_SALES::text), '^^') 
            , '||', IFNULL(TRIM(DOLLAR_SALES::text), '^^') 
            , '||', IFNULL(TRIM(DOLLAR_MARGIN::text), '^^') 
            , '||', IFNULL(TRIM(MARGIN_PERCENT::text), '^^') 
            , '||', IFNULL(TRIM(TOTAL_UNITS_ON_HAND::text), '^^') 
            , '||', IFNULL(TRIM(TOTAL_DOLLAR_COST_ON_HAND::text), '^^') 
            , '||', IFNULL(TRIM(TOTAL_UNITS_ON_ORDER::text), '^^') 
            , '||', IFNULL(TRIM(TOTAL_DOLLAR_COST_ON_ORDER::text), '^^') 
            , '||', IFNULL(TRIM(STORE_CURRENT_UNITS_ON_HAND::text), '^^') 
            , '||', IFNULL(TRIM(STORE_DOLLAR_COST_ON_HAND::text), '^^') 
            , '||', IFNULL(TRIM(STORE_UNITS_ON_ORDER::text), '^^') 
            , '||', IFNULL(TRIM(STORE_DOLLAR_COST_ON_ORDER::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
