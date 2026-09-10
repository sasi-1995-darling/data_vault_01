---- SRC LAYER ----
WITH
SRC_S              as ( SELECT * FROM {{ source('amazon_vc', 'inventory') }} as SRC  ),
SRC_A              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  ),
SRC_C              as ( SELECT * FROM {{ ref('v_psa_stg_ref_avc_talend_migration_cutoff_date') }} as SRC  )
/*
SRC_S              as ( SELECT * FROM amazon_vc_psa.inventory )
SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
SRC_C              as ( SELECT * FROM raw_vault.v_psa_stg_ref_avc_talend_migration_cutoff_date )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        REPORT_END_DATE
      , ASIN
      , VENDORCENTRAL_ACCOUNT
      , CONVERT_TIMEZONE('UTC', PSA_LOAD_DTS)                            as                                           LOAD_DTS
      , REPORT_START_DATE
      , OPEN_PO_UNITS
      , AVG_VENDOR_LEADTIME_DAYS
      , SELL_THROUGH_RATE
      , UNFILLED_CUST_ORDRD_UNITS
      , NET_RECEIVED_INV_AMT
      , NET_RECEIVED_INV_CURRCD
      , NET_RECEIVED_INV_UNITS
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
        REPORT_END_DATE
      , ASIN
      , VENDORCENTRAL_ACCOUNT
      , LOAD_DTS
      , REPORT_START_DATE
      , OPEN_PO_UNITS
      , AVG_VENDOR_LEADTIME_DAYS
      , SELL_THROUGH_RATE
      , UNFILLED_CUST_ORDRD_UNITS
      , NET_RECEIVED_INV_AMT
      , NET_RECEIVED_INV_CURRCD
      , NET_RECEIVED_INV_UNITS
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
    WHERE rec_src = 'US.API.AMAZON_VC.INVENTORY'
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
          'AMAZON'                                                     as STORE_BK
        , REPORT_END_DATE
        , ASIN
        , VENDORCENTRAL_ACCOUNT
        , LOAD_DTS
        , REPORT_START_DATE
        , OPEN_PO_UNITS
        , AVG_VENDOR_LEADTIME_DAYS
        , SELL_THROUGH_RATE
        , UNFILLED_CUST_ORDRD_UNITS
        , NET_RECEIVED_INV_AMT
        , NET_RECEIVED_INV_CURRCD
        , NET_RECEIVED_INV_UNITS
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
            , '||', IFNULL(TRIM(OPEN_PO_UNITS::text), '^^') 
            , '||', IFNULL(TRIM(AVG_VENDOR_LEADTIME_DAYS::text), '^^') 
            , '||', IFNULL(TRIM(SELL_THROUGH_RATE::text), '^^') 
            , '||', IFNULL(TRIM(UNFILLED_CUST_ORDRD_UNITS::text), '^^') 
            , '||', IFNULL(TRIM(NET_RECEIVED_INV_AMT::text), '^^') 
            , '||', IFNULL(TRIM(NET_RECEIVED_INV_CURRCD::text), '^^') 
            , '||', IFNULL(TRIM(NET_RECEIVED_INV_UNITS::text), '^^') 
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
where to_date(report_end_date) <= cutoff_dt