---- SRC LAYER ----
WITH
SRC_S              as ( SELECT AGED_90_PLUS_DAYS_SELLABLE_INVENTORY_COST_AMOUNT, AGED_90_PLUS_DAYS_SELLABLE_INVENTORY_COST_CURRENCY_CODE, AGED_90_PLUS_DAYS_SELLABLE_INVENTORY_UNITS, ASIN, AVERAGE_VENDOR_LEAD_TIME_DAYS, END_DATE, NET_RECEIVED_INVENTORY_COST_AMOUNT, NET_RECEIVED_INVENTORY_COST_CURRENCY_CODE, NET_RECEIVED_INVENTORY_UNITS, OPEN_PURCHASE_ORDER_UNITS, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, SELLABLE_ON_HAND_INVENTORY_COST_AMOUNT, SELLABLE_ON_HAND_INVENTORY_COST_CURRENCY_CODE, SELLABLE_ON_HAND_INVENTORY_UNITS, SELL_THROUGH_RATE, START_DATE, UNFILLED_CUSTOMER_ORDERED_UNITS, UNHEALTHY_INVENTORY_COST_AMOUNT, UNHEALTHY_INVENTORY_COST_CURRENCY_CODE, UNHEALTHY_INVENTORY_UNITS, UNSELLABLE_ON_HAND_INVENTORY_COST_AMOUNT, UNSELLABLE_ON_HAND_INVENTORY_COST_CURRENCY_CODE, UNSELLABLE_ON_HAND_INVENTORY_UNITS, _FIVETRAN_SYNCED FROM {{ source('amazon_sp_ft_moen_anaheim', 'vendor_inventory_manufacturing_retail_asin_report_daily') }} as SRC  ),
SRC_A              as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  ),
SRC_C              as ( SELECT cutoff_dt FROM {{ ref('v_psa_stg_ref_avc_talend_migration_cutoff_date') }} as SRC  )

/*
SRC_S              as ( SELECT * FROM amazon_sp_ft_moen_anaheim.vendor_inventory_manufacturing_retail_asin_report_daily )
SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
SRC_C              as ( SELECT * FROM raw_vault.v_psa_stg_ref_avc_talend_migration_cutoff_date )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        'AMAZON'                                                     as                                           STORE_BK
      , CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED)                    as                                           LOAD_DTS
      , END_DATE                                                     as                                    REPORT_END_DATE
      , 'Moen Anaheim'                                               as                              VENDORCENTRAL_ACCOUNT
      , ASIN
      , START_DATE                                                   as                                  REPORT_START_DATE
      , NET_RECEIVED_INVENTORY_COST_AMOUNT                           as                               NET_RECEIVED_INV_AMT
      , NET_RECEIVED_INVENTORY_COST_CURRENCY_CODE                    as                            NET_RECEIVED_INV_CURRCD
      , NET_RECEIVED_INVENTORY_UNITS                                 as                             NET_RECEIVED_INV_UNITS
      , OPEN_PURCHASE_ORDER_UNITS                                    as                                      OPEN_PO_UNITS
      , AVERAGE_VENDOR_LEAD_TIME_DAYS                                as                           AVG_VENDOR_LEADTIME_DAYS
      , SELL_THROUGH_RATE
      , UNFILLED_CUSTOMER_ORDERED_UNITS                              as                          UNFILLED_CUST_ORDRD_UNITS
      , SELLABLE_ON_HAND_INVENTORY_COST_AMOUNT                       as                                SELLABLE_OH_INV_AMT
      , SELLABLE_ON_HAND_INVENTORY_COST_CURRENCY_CODE                as                           SELLABLE_OH_INV_CURRCODE
      , SELLABLE_ON_HAND_INVENTORY_UNITS                             as                              SELLABLE_OH_INV_UNITS
      , UNSELLABLE_ON_HAND_INVENTORY_COST_AMOUNT                     as                              UNSELLABLE_OH_INV_AMT
      , UNSELLABLE_ON_HAND_INVENTORY_COST_CURRENCY_CODE              as                         UNSELLABLE_OH_INV_CURRCODE
      , UNSELLABLE_ON_HAND_INVENTORY_UNITS                           as                            UNSELLABLE_OH_INV_UNITS
      , AGED_90_PLUS_DAYS_SELLABLE_INVENTORY_COST_AMOUNT             as                        AGED_90DAYS_SELLABLE_INVAMT
      , AGED_90_PLUS_DAYS_SELLABLE_INVENTORY_COST_CURRENCY_CODE      as                     AGED_90DAYS_SELLABLE_INVCURRCD
      , AGED_90_PLUS_DAYS_SELLABLE_INVENTORY_UNITS                   as                      AGED_90DAYS_SELLABLE_INVUNITS
      , UNHEALTHY_INVENTORY_COST_AMOUNT                              as                                  UNHEALTHY_INV_AMT
      , UNHEALTHY_INVENTORY_COST_CURRENCY_CODE                       as                             UNHEALTHY_INV_CURRCODE
      , UNHEALTHY_INVENTORY_UNITS                                    as                                UNHEALTHY_INV_UNITS
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , _FIVETRAN_SYNCED
    FROM SRC_S
)

, LOGIC_A as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_A
)

, LOGIC_C as (
    SELECT
        cutoff_dt
    FROM SRC_C
)
---- RENAME LAYER ----

, RENAME_S as (
    SELECT
        STORE_BK
      , LOAD_DTS
      , REPORT_END_DATE
      , VENDORCENTRAL_ACCOUNT
      , ASIN
      , REPORT_START_DATE
      , NET_RECEIVED_INV_AMT
      , NET_RECEIVED_INV_CURRCD
      , NET_RECEIVED_INV_UNITS
      , OPEN_PO_UNITS
      , AVG_VENDOR_LEADTIME_DAYS
      , SELL_THROUGH_RATE
      , UNFILLED_CUST_ORDRD_UNITS
      , SELLABLE_OH_INV_AMT
      , SELLABLE_OH_INV_CURRCODE
      , SELLABLE_OH_INV_UNITS
      , UNSELLABLE_OH_INV_AMT
      , UNSELLABLE_OH_INV_CURRCODE
      , UNSELLABLE_OH_INV_UNITS
      , AGED_90DAYS_SELLABLE_INVAMT
      , AGED_90DAYS_SELLABLE_INVCURRCD
      , AGED_90DAYS_SELLABLE_INVUNITS
      , UNHEALTHY_INV_AMT
      , UNHEALTHY_INV_CURRCODE
      , UNHEALTHY_INV_UNITS
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , _FIVETRAN_SYNCED
    FROM LOGIC_S
)

, RENAME_A as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_A
)

, RENAME_C as (
    SELECT
        cutoff_dt
    FROM LOGIC_C
)
---- FILTER LAYER ----

, FILTER_S as (
    SELECT *
    FROM RENAME_S
)

, FILTER_A as (
    SELECT *
    FROM RENAME_A
    WHERE rec_src = 'US.API_FT.AMAZON_VC.INVENTORY'
)

, FILTER_C as (
    SELECT *
    FROM RENAME_C
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_S
    INNER JOIN FILTER_A
        ON '1' = '1'
    INNER JOIN FILTER_C
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          STORE_BK
        , LOAD_DTS
        , REPORT_END_DATE
        , VENDORCENTRAL_ACCOUNT
        , ASIN
        , REPORT_START_DATE
        , NET_RECEIVED_INV_AMT
        , NET_RECEIVED_INV_CURRCD
        , NET_RECEIVED_INV_UNITS
        , OPEN_PO_UNITS
        , AVG_VENDOR_LEADTIME_DAYS
        , SELL_THROUGH_RATE
        , UNFILLED_CUST_ORDRD_UNITS
        , SELLABLE_OH_INV_AMT
        , SELLABLE_OH_INV_CURRCODE
        , SELLABLE_OH_INV_UNITS
        , UNSELLABLE_OH_INV_AMT
        , UNSELLABLE_OH_INV_CURRCODE
        , UNSELLABLE_OH_INV_UNITS
        , AGED_90DAYS_SELLABLE_INVAMT
        , AGED_90DAYS_SELLABLE_INVCURRCD
        , AGED_90DAYS_SELLABLE_INVUNITS
        , UNHEALTHY_INV_AMT
        , UNHEALTHY_INV_CURRCODE
        , UNHEALTHY_INV_UNITS
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(STORE_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as STORE_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(REPORT_START_DATE::text), '^^') 
            , '||', IFNULL(TRIM(NET_RECEIVED_INV_AMT::text), '^^') 
            , '||', IFNULL(TRIM(NET_RECEIVED_INV_CURRCD::text), '^^') 
            , '||', IFNULL(TRIM(NET_RECEIVED_INV_UNITS::text), '^^') 
            , '||', IFNULL(TRIM(OPEN_PO_UNITS::text), '^^') 
            , '||', IFNULL(TRIM(AVG_VENDOR_LEADTIME_DAYS::text), '^^') 
            , '||', IFNULL(TRIM(SELL_THROUGH_RATE::text), '^^') 
            , '||', IFNULL(TRIM(UNFILLED_CUST_ORDRD_UNITS::text), '^^') 
            , '||', IFNULL(TRIM(SELLABLE_OH_INV_AMT::text), '^^') 
            , '||', IFNULL(TRIM(SELLABLE_OH_INV_CURRCODE::text), '^^') 
            , '||', IFNULL(TRIM(SELLABLE_OH_INV_UNITS::text), '^^') 
            , '||', IFNULL(TRIM(UNSELLABLE_OH_INV_AMT::text), '^^') 
            , '||', IFNULL(TRIM(UNSELLABLE_OH_INV_CURRCODE::text), '^^') 
            , '||', IFNULL(TRIM(UNSELLABLE_OH_INV_UNITS::text), '^^') 
            , '||', IFNULL(TRIM(AGED_90DAYS_SELLABLE_INVAMT::text), '^^') 
            , '||', IFNULL(TRIM(AGED_90DAYS_SELLABLE_INVCURRCD::text), '^^') 
            , '||', IFNULL(TRIM(AGED_90DAYS_SELLABLE_INVUNITS::text), '^^') 
            , '||', IFNULL(TRIM(UNHEALTHY_INV_AMT::text), '^^') 
            , '||', IFNULL(TRIM(UNHEALTHY_INV_CURRCODE::text), '^^') 
            , '||', IFNULL(TRIM(UNHEALTHY_INV_UNITS::text), '^^')             
            , '||', IFNULL(TRIM(PSA_RECORD_SOURCE::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
where to_date(report_end_date) > cutoff_dt