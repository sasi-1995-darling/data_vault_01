---- SRC LAYER ----
WITH
SRC_S              as ( SELECT * FROM {{ source('stock_market_psa', 'tsm_lowes_us') }} as SRC  ),
SRC_A              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S              as ( SELECT * FROM stock_market_psa.tsm_lowes_us )
, SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        NVL(LOCATION_ID::varchar,'0')                                as                                           STORE_BK
      , ITEM_NUMBER::varchar                                         as                                        ITEM_NUMBER
      , END_DATE
      , COALESCE(TRY_TO_DATE(END_DATE,'YYYY-MM-DD'), TRY_TO_DATE(END_DATE,'MM/DD/YYYY')) as                    END_DATE_DT
      , _LINE::varchar                                               as                                              _LINE
      , _FILE
      , CONVERT_TIMEZONE('UTC',_FIVETRAN_SYNCED)                     as                                           LOAD_DTS
      , _MODIFIED
      , ITEM_NAME
      , ADVERTISING_PATCH_AREA_ID
      , DISTRICT_ID
      , DIVISION_DESC
      , GEO_ZONE_ID
      , LOCATION_DESC
      , LOCATION_TYPE_DESC
      , REGION_DESC
      , STATE_ID
      , SUPPORTING_FDC_ID
      , SUPPORTING_FDC_DESC
      , SUPPORTING_REGIONAL_DISTRIBUTION_CENTER_ID
      , SALES_UNITS_TY
      , SALES_UNITS_LY
      , INTERNET_UNITS_TY
      , INTERNET_UNITS_LY
      , AVAILABLE_INVENTORY_UNITS_TY
      , AVAILABLE_INVENTORY_UNITS_LY
      , AVAILABLE_INVENTORY_UNITS_DC_
      , AVAILABLE_INVENTORY_UNITS_RETAIL_STORES
      , INVENTORY_ON_DIRECT_ORDER_UNITS_TY
      , INVENTORY_ON_DIRECT_ORDER_UNITS_LY
      , INVENTORY_ON_DIRECT_ORDER_LY
      , INVENTORY_UNITS_IN_REQ_TY
      , INVENTORY_UNITS_IN_REQ_LY
      , INVENTORY_UNITS_ON_BILL_TY
      , INVENTORY_UNITS_ON_BILL_LY
      , AVG_INVENTORY_ON_HAND_UNITS_TY
      , AVG_INVENTORY_ON_HAND_UNITS_LY
      , AVG_INVENTORY_ON_DIRECT_ORDER_UNITS_TY
      , AVG_INVENTORY_ON_DIRECT_ORDER_UNITS_LY
      , AVG_INVENTORY_ON_REQUISITION_UNITS_TY
      , AVG_INVENTORY_ON_REQUISITION_UNITS_LY
      , WEEKS_OF_SUPPLY_ON_HAND
      , WEEKS_OF_SUPPLY_ON_ORDER
      , JDA_LOST_SALES_UNITS_TY_WEEKLY_
      , TURN_RATES_WEEKLY_
      , _FIVETRAN_SYNCED
      , TY_TURN_RATE
      , LY_TURN_RATE
      , YTD_TOTAL_SALES_
      , GROSS_TRANSACTION_SALES_UNITS_TY
      , GROSS_TRANSACTION_SALES_UNITS_LY
      , GROSS_TRANSACTION_SALES_UNITS_CHANGE
      , YTD_WEEKLY_AVERAGE_SALES_
      , INVENTORY_ON_DIRECT_ORDER_TY
      , SALES_UNITS_TY_VS_LY
      , AVG_INVENTORY_ON_DIRECT_ORDER_LY
      , INTERNET_UNITS_TY_VS_LY
      , AVG_INVENTORY_ON_HAND_LY
      , AVG_INVENTORY_ON_REQUISITION_LY
      , SALES_TY_VS_LY
      , SALES_TY
      , YTD_SALES_
      , AVG_INVENTORY_ON_HAND_TY
      , AVAILABLE_INVENTORY_LY
      , INTERNET_SALES_LY
      , AVG_INVENTORY_ON_REQUISITION_TY
      , YTD_TY_VS_LY
      , SALES_LY
      , LYTD_SALES_
      , INTERNET_SALES_TY_VS_LY
      , AVAILABLE_INVENTORY_TY
      , INTERNET_SALES_TY
      , GROSS_TRANSACTIONS_SALES_
      , AVG_INVENTORY_ON_DIRECT_ORDER_TY
      , LYTD_UNITS
      , YTD_UNITS
      , AVAILABLE_INVENTORY_UNITS_N_RETAIL_STORES
      , YTD_WEEKLY_AVERAGE_UNITS
      , START_DATE
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
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
      , ITEM_NUMBER
      , END_DATE
      , END_DATE_DT
      , _LINE
      , _FILE
      , LOAD_DTS
      , _MODIFIED
      , ITEM_NAME
      , ADVERTISING_PATCH_AREA_ID
      , DISTRICT_ID
      , DIVISION_DESC
      , GEO_ZONE_ID
      , LOCATION_DESC
      , LOCATION_TYPE_DESC
      , REGION_DESC
      , STATE_ID
      , SUPPORTING_FDC_ID
      , SUPPORTING_FDC_DESC
      , SUPPORTING_REGIONAL_DISTRIBUTION_CENTER_ID
      , SALES_UNITS_TY
      , SALES_UNITS_LY
      , INTERNET_UNITS_TY
      , INTERNET_UNITS_LY
      , AVAILABLE_INVENTORY_UNITS_TY
      , AVAILABLE_INVENTORY_UNITS_LY
      , AVAILABLE_INVENTORY_UNITS_DC_
      , AVAILABLE_INVENTORY_UNITS_RETAIL_STORES
      , INVENTORY_ON_DIRECT_ORDER_UNITS_TY
      , INVENTORY_ON_DIRECT_ORDER_UNITS_LY
      , INVENTORY_ON_DIRECT_ORDER_LY
      , INVENTORY_UNITS_IN_REQ_TY
      , INVENTORY_UNITS_IN_REQ_LY
      , INVENTORY_UNITS_ON_BILL_TY
      , INVENTORY_UNITS_ON_BILL_LY
      , AVG_INVENTORY_ON_HAND_UNITS_TY
      , AVG_INVENTORY_ON_HAND_UNITS_LY
      , AVG_INVENTORY_ON_DIRECT_ORDER_UNITS_TY
      , AVG_INVENTORY_ON_DIRECT_ORDER_UNITS_LY
      , AVG_INVENTORY_ON_REQUISITION_UNITS_TY
      , AVG_INVENTORY_ON_REQUISITION_UNITS_LY
      , WEEKS_OF_SUPPLY_ON_HAND
      , WEEKS_OF_SUPPLY_ON_ORDER
      , JDA_LOST_SALES_UNITS_TY_WEEKLY_
      , TURN_RATES_WEEKLY_
      , _FIVETRAN_SYNCED
      , TY_TURN_RATE
      , LY_TURN_RATE
      , YTD_TOTAL_SALES_
      , GROSS_TRANSACTION_SALES_UNITS_TY
      , GROSS_TRANSACTION_SALES_UNITS_LY
      , GROSS_TRANSACTION_SALES_UNITS_CHANGE
      , YTD_WEEKLY_AVERAGE_SALES_
      , INVENTORY_ON_DIRECT_ORDER_TY
      , SALES_UNITS_TY_VS_LY
      , AVG_INVENTORY_ON_DIRECT_ORDER_LY
      , INTERNET_UNITS_TY_VS_LY
      , AVG_INVENTORY_ON_HAND_LY
      , AVG_INVENTORY_ON_REQUISITION_LY
      , SALES_TY_VS_LY
      , SALES_TY
      , YTD_SALES_
      , AVG_INVENTORY_ON_HAND_TY
      , AVAILABLE_INVENTORY_LY
      , INTERNET_SALES_LY
      , AVG_INVENTORY_ON_REQUISITION_TY
      , YTD_TY_VS_LY
      , SALES_LY
      , LYTD_SALES_
      , INTERNET_SALES_TY_VS_LY
      , AVAILABLE_INVENTORY_TY
      , INTERNET_SALES_TY
      , GROSS_TRANSACTIONS_SALES_
      , AVG_INVENTORY_ON_DIRECT_ORDER_TY
      , LYTD_UNITS
      , YTD_UNITS
      , AVAILABLE_INVENTORY_UNITS_N_RETAIL_STORES
      , YTD_WEEKLY_AVERAGE_UNITS
      , START_DATE
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
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
    WHERE TRUE
/* The following qualify clause is required to pull the first row pushed to PSA based on these PK columns*/
qualify 1 = row_number()over (partition by store_bk,item_number,end_date, _line, _file, load_dts order by psa_load_dts)
)

, FILTER_A as (
    SELECT *
    FROM RENAME_A
    WHERE rec_src = 'US.EXCEL.STOCK_MARKET.TSM_LOWES_US'
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
        , ITEM_NUMBER
        , END_DATE
        , END_DATE_DT
        , _LINE
        , _FILE
        , LOAD_DTS
        , _MODIFIED
        , ITEM_NAME
        , ADVERTISING_PATCH_AREA_ID
        , DISTRICT_ID
        , DIVISION_DESC
        , GEO_ZONE_ID
        , LOCATION_DESC
        , LOCATION_TYPE_DESC
        , REGION_DESC
        , STATE_ID
        , SUPPORTING_FDC_ID
        , SUPPORTING_FDC_DESC
        , SUPPORTING_REGIONAL_DISTRIBUTION_CENTER_ID
        , SALES_UNITS_TY
        , SALES_UNITS_LY
        , INTERNET_UNITS_TY
        , INTERNET_UNITS_LY
        , AVAILABLE_INVENTORY_UNITS_TY
        , AVAILABLE_INVENTORY_UNITS_LY
        , AVAILABLE_INVENTORY_UNITS_DC_
        , AVAILABLE_INVENTORY_UNITS_RETAIL_STORES
        , INVENTORY_ON_DIRECT_ORDER_UNITS_TY
        , INVENTORY_ON_DIRECT_ORDER_UNITS_LY
        , INVENTORY_ON_DIRECT_ORDER_LY
        , INVENTORY_UNITS_IN_REQ_TY
        , INVENTORY_UNITS_IN_REQ_LY
        , INVENTORY_UNITS_ON_BILL_TY
        , INVENTORY_UNITS_ON_BILL_LY
        , AVG_INVENTORY_ON_HAND_UNITS_TY
        , AVG_INVENTORY_ON_HAND_UNITS_LY
        , AVG_INVENTORY_ON_DIRECT_ORDER_UNITS_TY
        , AVG_INVENTORY_ON_DIRECT_ORDER_UNITS_LY
        , AVG_INVENTORY_ON_REQUISITION_UNITS_TY
        , AVG_INVENTORY_ON_REQUISITION_UNITS_LY
        , WEEKS_OF_SUPPLY_ON_HAND
        , WEEKS_OF_SUPPLY_ON_ORDER
        , JDA_LOST_SALES_UNITS_TY_WEEKLY_
        , TURN_RATES_WEEKLY_
        , _FIVETRAN_SYNCED
        , TY_TURN_RATE
        , LY_TURN_RATE
        , YTD_TOTAL_SALES_
        , GROSS_TRANSACTION_SALES_UNITS_TY
        , GROSS_TRANSACTION_SALES_UNITS_LY
        , GROSS_TRANSACTION_SALES_UNITS_CHANGE
        , YTD_WEEKLY_AVERAGE_SALES_
        , INVENTORY_ON_DIRECT_ORDER_TY
        , SALES_UNITS_TY_VS_LY
        , AVG_INVENTORY_ON_DIRECT_ORDER_LY
        , INTERNET_UNITS_TY_VS_LY
        , AVG_INVENTORY_ON_HAND_LY
        , AVG_INVENTORY_ON_REQUISITION_LY
        , SALES_TY_VS_LY
        , SALES_TY
        , YTD_SALES_
        , AVG_INVENTORY_ON_HAND_TY
        , AVAILABLE_INVENTORY_LY
        , INTERNET_SALES_LY
        , AVG_INVENTORY_ON_REQUISITION_TY
        , YTD_TY_VS_LY
        , SALES_LY
        , LYTD_SALES_
        , INTERNET_SALES_TY_VS_LY
        , AVAILABLE_INVENTORY_TY
        , INTERNET_SALES_TY
        , GROSS_TRANSACTIONS_SALES_
        , AVG_INVENTORY_ON_DIRECT_ORDER_TY
        , LYTD_UNITS
        , YTD_UNITS
        , AVAILABLE_INVENTORY_UNITS_N_RETAIL_STORES
        , YTD_WEEKLY_AVERAGE_UNITS
        , START_DATE
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(STORE_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as STORE_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(_MODIFIED::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_NAME::text), '^^') 
            , '||', IFNULL(TRIM(ADVERTISING_PATCH_AREA_ID::text), '^^') 
            , '||', IFNULL(TRIM(DISTRICT_ID::text), '^^') 
            , '||', IFNULL(TRIM(DIVISION_DESC::text), '^^') 
            , '||', IFNULL(TRIM(GEO_ZONE_ID::text), '^^') 
            , '||', IFNULL(TRIM(LOCATION_DESC::text), '^^') 
            , '||', IFNULL(TRIM(LOCATION_TYPE_DESC::text), '^^') 
            , '||', IFNULL(TRIM(REGION_DESC::text), '^^') 
            , '||', IFNULL(TRIM(STATE_ID::text), '^^') 
            , '||', IFNULL(TRIM(SUPPORTING_FDC_ID::text), '^^') 
            , '||', IFNULL(TRIM(SUPPORTING_FDC_DESC::text), '^^') 
            , '||', IFNULL(TRIM(SUPPORTING_REGIONAL_DISTRIBUTION_CENTER_ID::text), '^^') 
            , '||', IFNULL(TRIM(SALES_UNITS_TY::text), '^^') 
            , '||', IFNULL(TRIM(SALES_UNITS_LY::text), '^^') 
            , '||', IFNULL(TRIM(INTERNET_UNITS_TY::text), '^^') 
            , '||', IFNULL(TRIM(INTERNET_UNITS_LY::text), '^^') 
            , '||', IFNULL(TRIM(AVAILABLE_INVENTORY_UNITS_TY::text), '^^') 
            , '||', IFNULL(TRIM(AVAILABLE_INVENTORY_UNITS_LY::text), '^^') 
            , '||', IFNULL(TRIM(AVAILABLE_INVENTORY_UNITS_DC_::text), '^^') 
            , '||', IFNULL(TRIM(AVAILABLE_INVENTORY_UNITS_RETAIL_STORES::text), '^^') 
            , '||', IFNULL(TRIM(INVENTORY_ON_DIRECT_ORDER_UNITS_TY::text), '^^') 
            , '||', IFNULL(TRIM(INVENTORY_ON_DIRECT_ORDER_UNITS_LY::text), '^^') 
            , '||', IFNULL(TRIM(INVENTORY_ON_DIRECT_ORDER_LY::text), '^^') 
            , '||', IFNULL(TRIM(INVENTORY_UNITS_IN_REQ_TY::text), '^^') 
            , '||', IFNULL(TRIM(INVENTORY_UNITS_IN_REQ_LY::text), '^^') 
            , '||', IFNULL(TRIM(INVENTORY_UNITS_ON_BILL_TY::text), '^^') 
            , '||', IFNULL(TRIM(INVENTORY_UNITS_ON_BILL_LY::text), '^^') 
            , '||', IFNULL(TRIM(AVG_INVENTORY_ON_HAND_UNITS_TY::text), '^^') 
            , '||', IFNULL(TRIM(AVG_INVENTORY_ON_HAND_UNITS_LY::text), '^^') 
            , '||', IFNULL(TRIM(AVG_INVENTORY_ON_DIRECT_ORDER_UNITS_TY::text), '^^') 
            , '||', IFNULL(TRIM(AVG_INVENTORY_ON_DIRECT_ORDER_UNITS_LY::text), '^^') 
            , '||', IFNULL(TRIM(AVG_INVENTORY_ON_REQUISITION_UNITS_TY::text), '^^') 
            , '||', IFNULL(TRIM(AVG_INVENTORY_ON_REQUISITION_UNITS_LY::text), '^^') 
            , '||', IFNULL(TRIM(WEEKS_OF_SUPPLY_ON_HAND::text), '^^') 
            , '||', IFNULL(TRIM(WEEKS_OF_SUPPLY_ON_ORDER::text), '^^') 
            , '||', IFNULL(TRIM(JDA_LOST_SALES_UNITS_TY_WEEKLY_::text), '^^') 
            , '||', IFNULL(TRIM(TURN_RATES_WEEKLY_::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_SYNCED::text), '^^') 
            , '||', IFNULL(TRIM(TY_TURN_RATE::text), '^^') 
            , '||', IFNULL(TRIM(LY_TURN_RATE::text), '^^') 
            , '||', IFNULL(TRIM(YTD_TOTAL_SALES_::text), '^^') 
            , '||', IFNULL(TRIM(GROSS_TRANSACTION_SALES_UNITS_TY::text), '^^') 
            , '||', IFNULL(TRIM(GROSS_TRANSACTION_SALES_UNITS_LY::text), '^^') 
            , '||', IFNULL(TRIM(GROSS_TRANSACTION_SALES_UNITS_CHANGE::text), '^^') 
            , '||', IFNULL(TRIM(YTD_WEEKLY_AVERAGE_SALES_::text), '^^') 
            , '||', IFNULL(TRIM(INVENTORY_ON_DIRECT_ORDER_TY::text), '^^') 
            , '||', IFNULL(TRIM(SALES_UNITS_TY_VS_LY::text), '^^') 
            , '||', IFNULL(TRIM(AVG_INVENTORY_ON_DIRECT_ORDER_LY::text), '^^') 
            , '||', IFNULL(TRIM(INTERNET_UNITS_TY_VS_LY::text), '^^') 
            , '||', IFNULL(TRIM(AVG_INVENTORY_ON_HAND_LY::text), '^^') 
            , '||', IFNULL(TRIM(AVG_INVENTORY_ON_REQUISITION_LY::text), '^^') 
            , '||', IFNULL(TRIM(SALES_TY_VS_LY::text), '^^') 
            , '||', IFNULL(TRIM(SALES_TY::text), '^^') 
            , '||', IFNULL(TRIM(YTD_SALES_::text), '^^') 
            , '||', IFNULL(TRIM(AVG_INVENTORY_ON_HAND_TY::text), '^^') 
            , '||', IFNULL(TRIM(AVAILABLE_INVENTORY_LY::text), '^^') 
            , '||', IFNULL(TRIM(INTERNET_SALES_LY::text), '^^') 
            , '||', IFNULL(TRIM(AVG_INVENTORY_ON_REQUISITION_TY::text), '^^') 
            , '||', IFNULL(TRIM(YTD_TY_VS_LY::text), '^^') 
            , '||', IFNULL(TRIM(SALES_LY::text), '^^') 
            , '||', IFNULL(TRIM(LYTD_SALES_::text), '^^') 
            , '||', IFNULL(TRIM(INTERNET_SALES_TY_VS_LY::text), '^^') 
            , '||', IFNULL(TRIM(AVAILABLE_INVENTORY_TY::text), '^^') 
            , '||', IFNULL(TRIM(INTERNET_SALES_TY::text), '^^') 
            , '||', IFNULL(TRIM(GROSS_TRANSACTIONS_SALES_::text), '^^') 
            , '||', IFNULL(TRIM(AVG_INVENTORY_ON_DIRECT_ORDER_TY::text), '^^') 
            , '||', IFNULL(TRIM(LYTD_UNITS::text), '^^') 
            , '||', IFNULL(TRIM(YTD_UNITS::text), '^^') 
            , '||', IFNULL(TRIM(AVAILABLE_INVENTORY_UNITS_N_RETAIL_STORES::text), '^^') 
            , '||', IFNULL(TRIM(YTD_WEEKLY_AVERAGE_UNITS::text), '^^') 
            , '||', IFNULL(TRIM(START_DATE::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
