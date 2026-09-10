---- SRC LAYER ----
WITH
SRC_a              as ( SELECT AGED_90DAYS_SELLABLE_INVAMT, AGED_90DAYS_SELLABLE_INVCURRCD, AGED_90DAYS_SELLABLE_INVUNITS, ASIN, AVG_VENDOR_LEADTIME_DAYS, NET_RECEIVED_INV_AMT, NET_RECEIVED_INV_CURRCD, NET_RECEIVED_INV_UNITS, OPEN_PO_UNITS, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, REPORT_END_DATE, REPORT_START_DATE, RUN_DATE, SELLABLE_OH_INV_AMT, SELLABLE_OH_INV_CURRCODE, SELLABLE_OH_INV_UNITS, SELL_THROUGH_RATE, UNFILLED_CUST_ORDRD_UNITS, UNHEALTHY_INV_AMT, UNHEALTHY_INV_CURRCODE, UNHEALTHY_INV_UNITS, UNSELLABLE_OH_INV_AMT, UNSELLABLE_OH_INV_CURRCODE, UNSELLABLE_OH_INV_UNITS, VENDORCENTRAL_ACCOUNT 
                        FROM {{ source('amazon_vc', 'inventory') }} as SRC 
                        QUALIFY 1 = ROW_NUMBER() OVER (PARTITION BY HASH(AGED_90DAYS_SELLABLE_INVAMT, AGED_90DAYS_SELLABLE_INVCURRCD, AGED_90DAYS_SELLABLE_INVUNITS, ASIN, AVG_VENDOR_LEADTIME_DAYS, NET_RECEIVED_INV_AMT, NET_RECEIVED_INV_CURRCD, NET_RECEIVED_INV_UNITS, OPEN_PO_UNITS, REPORT_END_DATE, REPORT_START_DATE, RUN_DATE, SELLABLE_OH_INV_AMT, SELLABLE_OH_INV_CURRCODE, SELLABLE_OH_INV_UNITS, SELL_THROUGH_RATE, UNFILLED_CUST_ORDRD_UNITS, UNHEALTHY_INV_AMT, UNHEALTHY_INV_CURRCODE, UNHEALTHY_INV_UNITS, UNSELLABLE_OH_INV_AMT, UNSELLABLE_OH_INV_CURRCODE, UNSELLABLE_OH_INV_UNITS, VENDORCENTRAL_ACCOUNT) ORDER BY PSA_LOAD_DTS DESC)),
-- Expected behavior is the catalog filters the data (items, forecasting) for the records via an inner join found within this file
SRC_b              as ( SELECT ASIN, MODEL_STYLE_NUMBER, MODEL_NUMBER 
                        FROM {{ source('amazon_xref_prd', 'amazon_moen_catalog_hist') }} as SRC 
                        qualify 1 = row_number() over (partition by ASIN order by psa_load_dts desc) ),
SRC_mara           as ( SELECT matnr FROM {{ source('sap_ecc_prd', 'z_mara') }} as SRC 
                        qualify 1 = row_number() over (partition by matnr order by psa_load_dts desc)  ),
SRC_bkcc           as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC ),
SRC_bkcc_mara      as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC )

/*
SRC_a              as ( SELECT * FROM amazon_vc.INVENTORY )
SRC_b              as ( SELECT * FROM amazon_xref.amazon_moen_catalog_hist )
SRC_mara           as ( SELECT * FROM sap_ecc_prd.z_mara )
SRC_bkcc           as ( SELECT * FROM raw_vault.ref_business_key_collision )
SRC_bkcc_mara      as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_a as (
    SELECT
        REPORT_START_DATE
      , REPORT_END_DATE
      , ASIN
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
      , RUN_DATE
      , VENDORCENTRAL_ACCOUNT
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , IFF(
            PSA_DELETE_IND = 'Y',
        PSA_LOAD_DTS, CONVERT_TIMEZONE('UTC', RUN_DATE))              as                                           LOAD_DTS
      , 'AMAZON'                                                      as                                           STORE_BK
    FROM SRC_a
)

, LOGIC_b as (
    SELECT
        ASIN                                                         as                                          ASIN_XREF
      , MODEL_STYLE_NUMBER
      , MODEL_NUMBER
      , COALESCE(NULLIF(UPPER(TRIM(COALESCE(MODEL_STYLE_NUMBER, MODEL_NUMBER))), ''), '-1')  as                    ITEM_BK
    FROM SRC_b
)

, LOGIC_mara as (
    SELECT
        matnr
    FROM SRC_mara
)

, LOGIC_bkcc as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_bkcc
)

, LOGIC_bkcc_mara as (
    SELECT
        REC_SRC                                                      as                                       REC_SRC_MARA
      , BKCC                                                         as                                          BKCC_MARA
    FROM SRC_bkcc_mara
)

---- RENAME LAYER ----

, RENAME_a as (
    SELECT
        REPORT_START_DATE
      , REPORT_END_DATE
      , ASIN
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
      , RUN_DATE
      , VENDORCENTRAL_ACCOUNT
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , STORE_BK
    FROM LOGIC_a
)

, RENAME_b as (
    SELECT
        ASIN_XREF
      , MODEL_STYLE_NUMBER
      , MODEL_NUMBER
      , ITEM_BK
    FROM LOGIC_b
)

, RENAME_mara as (
    SELECT
        matnr
    FROM LOGIC_mara
)

, RENAME_bkcc as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_bkcc
)

, RENAME_bkcc_mara as (
    SELECT
        REC_SRC_MARA
      , BKCC_MARA
    FROM LOGIC_bkcc_mara
)

---- FILTER LAYER ----

, FILTER_a as (
    SELECT *
    FROM RENAME_a
)

, FILTER_b as (
    SELECT *
    FROM RENAME_b
)

, FILTER_mara as (
    SELECT *
    FROM RENAME_mara
)

, FILTER_bkcc as (
    SELECT *
    FROM RENAME_bkcc
    WHERE rec_src = 'US.API.AMAZON_VC.INVENTORY'
)

, FILTER_bkcc_mara as (
    SELECT *
    FROM RENAME_bkcc_mara
    WHERE rec_src_mara = 'USOHNO.SAP.ECCPRD.Z_MARA'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_a
    INNER JOIN FILTER_b
        ON FILTER_a.asin = FILTER_b.asin_xref
    INNER JOIN FILTER_mara
        ON FILTER_b.ITEM_BK = FILTER_mara.matnr
    INNER JOIN FILTER_bkcc
        ON '1' = '1'
    INNER JOIN FILTER_bkcc_mara
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          REPORT_START_DATE
        , REPORT_END_DATE
        , ASIN
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
        , RUN_DATE
        , VENDORCENTRAL_ACCOUNT
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , REC_SRC_MARA
        , BKCC_MARA
        , STORE_BK
        , ITEM_BK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ITEM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(STORE_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC_MARA as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as CHANNEL_ITEM_INVENTORY_LHK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ITEM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC_MARA as VARCHAR)),''), '^^')
        ))) as ITEM_HK
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
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
