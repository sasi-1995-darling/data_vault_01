---- SRC LAYER ----
WITH
SRC_a              as ( SELECT ASIN, CUSTOMER_RETURNS, END_DATE, MARKETPLACE_ID, ORDERED_REVENUE_AMOUNT, ORDERED_REVENUE_CURRENCY_CODE, ORDERED_UNITS, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, SHIPPED_COGS_AMOUNT, SHIPPED_COGS_CURRENCY_CODE, SHIPPED_REVENUE_AMOUNT, SHIPPED_REVENUE_CURRENCY_CODE, SHIPPED_UNITS, START_DATE, _FIVETRAN_SYNCED FROM {{ source('amazon_sp_ft_moen_anaheim', 'vendor_sales_manufacturing_retail_asin_report_daily') }} as SRC ),
SRC_bkcc           as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  ),
SRC_bkcc_mara      as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  ),
-- Expected behavior is the catalog filters the data (items, forecasting) for the records via an inner join found within this file
SRC_b              as ( SELECT ASIN, MODEL_STYLE_NUMBER, MODEL_NUMBER FROM {{ source('amazon_xref_prd', 'amazon_moen_catalog_hist') }} as SRC  
                        qualify 1 = row_number() over (partition by ASIN order by PSA_LOAD_DTS desc) ),
SRC_mara           as ( SELECT MATNR FROM {{ source('sap_ecc_prd', 'z_mara') }} as SRC 
                        qualify 1 = row_number() over (partition by matnr order by PSA_LOAD_DTS desc) )

/*
SRC_a              as ( SELECT * FROM amazon_sp_ft_moen_inc.VENDOR_SALES_MANUFACTURING_RETAIL_ASIN_REPORT_DAILY )
SRC_bkcc           as ( SELECT * FROM raw_vault.ref_business_key_collision )
SRC_b              as ( SELECT * FROM amazon_xref.AMAZON_MOEN_CATALOG_HIST )
SRC_mara           as ( SELECT * FROM sap_ecc_prd.z_mara )
SRC_bkcc_mara      as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_a as (
    SELECT
        'AMAZON'                                                      as                                           STORE_BK
      , ASIN
      , END_DATE
      , MARKETPLACE_ID
      , START_DATE
      , CUSTOMER_RETURNS
      , ORDERED_REVENUE_AMOUNT
      , ORDERED_REVENUE_CURRENCY_CODE
      , ORDERED_UNITS
      , SHIPPED_COGS_AMOUNT
      , SHIPPED_COGS_CURRENCY_CODE
      , SHIPPED_REVENUE_AMOUNT
      , SHIPPED_REVENUE_CURRENCY_CODE
      , SHIPPED_UNITS
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , IFF(
            PSA_DELETE_IND = 'Y',
        PSA_LOAD_DTS, CONVERT_TIMEZONE('UTC',_FIVETRAN_SYNCED))  as                                           LOAD_DTS
    FROM SRC_a
)

, LOGIC_bkcc as (
    SELECT
        REC_SRC
      , BKCC                                                         as                                         BKCC_STORE
    FROM SRC_bkcc
)

, LOGIC_bkcc_mara as (
    SELECT
        REC_SRC                                                      as                                       REC_SRC_MARA
      , BKCC                                                         as                                          BKCC_ITEM
    FROM SRC_bkcc_mara
)

, LOGIC_b as (
    SELECT
        COALESCE(NULLIF(UPPER(TRIM(COALESCE(MODEL_STYLE_NUMBER, MODEL_NUMBER))), ''), '-1')  as                    ITEM_BK
      , ASIN                                                         as                                             B_ASIN
      , MODEL_NUMBER
      , MODEL_STYLE_NUMBER
    FROM SRC_b
)

, LOGIC_mara as (
    SELECT
        MATNR
    FROM SRC_mara
)
---- RENAME LAYER ----

, RENAME_b as (
    SELECT
        ITEM_BK
      , B_ASIN
      , MODEL_STYLE_NUMBER
      , MODEL_NUMBER
    FROM LOGIC_b
)

, RENAME_a as (
    SELECT
        STORE_BK
      , ASIN
      , END_DATE
      , MARKETPLACE_ID
      , START_DATE
      , CUSTOMER_RETURNS
      , ORDERED_REVENUE_AMOUNT
      , ORDERED_REVENUE_CURRENCY_CODE
      , ORDERED_UNITS
      , SHIPPED_COGS_AMOUNT
      , SHIPPED_COGS_CURRENCY_CODE
      , SHIPPED_REVENUE_AMOUNT
      , SHIPPED_REVENUE_CURRENCY_CODE
      , SHIPPED_UNITS
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
    FROM LOGIC_a
)



, RENAME_bkcc as (
    SELECT
        REC_SRC
      , BKCC_STORE
    FROM LOGIC_bkcc
)

, RENAME_bkcc_mara as (
    SELECT
        REC_SRC_MARA
      , BKCC_ITEM
    FROM LOGIC_bkcc_mara
)

, RENAME_mara as (
    SELECT
        MATNR
    FROM LOGIC_mara
)
---- FILTER LAYER ----

, FILTER_a as (
    SELECT *
    FROM RENAME_a
)

, FILTER_bkcc as (
    SELECT *
    FROM RENAME_bkcc
    WHERE rec_src = 'US.API_FT.AMAZON_SP_FT_MOEN_ANAHEIM.VENDOR_SALES_MANUFACTURING_RETAIL_ASIN_REPORT_DAILY'
)

, FILTER_bkcc_mara as (
    SELECT *
    FROM RENAME_bkcc_mara
    WHERE rec_src_mara = 'USOHNO.SAP.ECCPRD.Z_MARA'
)

, FILTER_b as (
    SELECT *
    FROM RENAME_b
)

, FILTER_mara as (
    SELECT *
    FROM RENAME_mara
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_a
    INNER JOIN FILTER_bkcc
        ON '1' = '1'
    INNER JOIN FILTER_bkcc_mara
        ON '1' = '1'
    INNER JOIN FILTER_b
        ON FILTER_a.ASIN = FILTER_b.B_ASIN
    INNER JOIN FILTER_mara
        ON FILTER_b.ITEM_BK = FILTER_mara.MATNR
)

---- FINAL LAYER ----
SELECT
          ITEM_BK
        , STORE_BK
        , ASIN
        , END_DATE
        , MARKETPLACE_ID
        , START_DATE
        , CUSTOMER_RETURNS
        , ORDERED_REVENUE_AMOUNT
        , ORDERED_REVENUE_CURRENCY_CODE
        , ORDERED_UNITS
        , SHIPPED_COGS_AMOUNT
        , SHIPPED_COGS_CURRENCY_CODE
        , SHIPPED_REVENUE_AMOUNT
        , SHIPPED_REVENUE_CURRENCY_CODE
        , SHIPPED_UNITS
        , _FIVETRAN_SYNCED
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , MODEL_STYLE_NUMBER
        , LOAD_DTS
        , REC_SRC
        , BKCC_ITEM
        , BKCC_STORE
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ITEM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(STORE_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC_ITEM as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC_STORE as VARCHAR)),''), '^^')
        ))) as CHANNEL_SOLD_ITEM_LHK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ITEM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC_ITEM as VARCHAR)),''), '^^')
        ))) as ITEM_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(STORE_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC_STORE as VARCHAR)),''), '^^')
        ))) as STORE_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              '||', IFNULL(TRIM(CUSTOMER_RETURNS::text), '^^') 
            , '||', IFNULL(TRIM(ORDERED_REVENUE_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(ORDERED_REVENUE_CURRENCY_CODE::text), '^^') 
            , '||', IFNULL(TRIM(ORDERED_UNITS::text), '^^') 
            , '||', IFNULL(TRIM(SHIPPED_COGS_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(SHIPPED_COGS_CURRENCY_CODE::text), '^^') 
            , '||', IFNULL(TRIM(SHIPPED_REVENUE_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(SHIPPED_REVENUE_CURRENCY_CODE::text), '^^') 
            , '||', IFNULL(TRIM(SHIPPED_UNITS::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
            , '||', IFNULL(TRIM(MODEL_STYLE_NUMBER::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT