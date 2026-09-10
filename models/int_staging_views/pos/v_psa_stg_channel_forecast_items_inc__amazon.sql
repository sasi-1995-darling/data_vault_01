---- SRC LAYER ----
WITH
SRC_a              as ( SELECT ASIN, END_DATE, FORECAST_GENERATION_DATE, MARKETPLACE_ID, MEAN_FORECAST_UNITS, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, P_70_FORECAST_UNITS, P_80_FORECAST_UNITS, P_90_FORECAST_UNITS, START_DATE, _FIVETRAN_SYNCED FROM {{ source('amazon_sp_ft_moen_inc', 'vendor_forecasting_retail_report') }} as SRC  ),
                       -- Expected behavior is the catalog filters the data (items, forecasting) for the records via an inner join found within this file
SRC_b              as ( SELECT ASIN, MODEL_STYLE_NUMBER, MODEL_NUMBER  FROM {{ source('amazon_xref_prd', 'amazon_moen_catalog_hist') }} as SRC  
                        qualify 1 = row_number() over (partition by ASIN order by psa_load_dts desc) ),
SRC_mara           as ( SELECT matnr FROM {{ source('sap_ecc_prd', 'z_mara') }} as SRC 
                        qualify 1 = row_number() over (partition by matnr order by psa_load_dts desc) ),
SRC_bkcc           as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  ),
SRC_bkcc_mara      as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  )
/*
SRC_a              as ( SELECT * FROM AMAZON_SP_FT_MOEN_INC.VENDOR_FORECASTING_RETAIL_REPORT )
SRC_b              as ( SELECT * FROM amazon_xref_prd.amazon_moen_catalog_hist )
SRC_mara           as ( SELECT * FROM sap_ecc_prd.z_mara )
SRC_bkcc           as ( SELECT * FROM raw_vault.ref_business_key_collision )
SRC_bkcc_mara      as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_a as (
    SELECT
        ASIN
      , END_DATE
      , FORECAST_GENERATION_DATE
      , MARKETPLACE_ID
      , START_DATE
      , MEAN_FORECAST_UNITS
      , P_70_FORECAST_UNITS
      , P_80_FORECAST_UNITS
      , P_90_FORECAST_UNITS
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , IFF(
            PSA_DELETE_IND = 'Y',
        PSA_LOAD_DTS, CONVERT_TIMEZONE('UTC',_FIVETRAN_SYNCED))              as                                           LOAD_DTS
      , 'AMAZON'                                                      as                                           STORE_BK
    FROM SRC_a
)

, LOGIC_b as (
    SELECT
        MODEL_STYLE_NUMBER
      , MODEL_NUMBER
      , ASIN                                                         as                                          ASIN_XREF
      , COALESCE(NULLIF(UPPER(TRIM(COALESCE(MODEL_STYLE_NUMBER, MODEL_NUMBER))), ''), '-1')  as                                            ITEM_BK
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
      , BKCC as BKCC_STORE 
    FROM SRC_bkcc
)

, LOGIC_bkcc_mara as (
    SELECT
        REC_SRC                                                      as                                       REC_SRC_MARA
      , BKCC                                                         as                                          BKCC_ITEM 
    FROM SRC_bkcc_mara
)
---- RENAME LAYER ----

, RENAME_a as (
    SELECT
        ASIN
      , END_DATE
      , FORECAST_GENERATION_DATE
      , MARKETPLACE_ID
      , START_DATE
      , MEAN_FORECAST_UNITS
      , P_70_FORECAST_UNITS
      , P_80_FORECAST_UNITS
      , P_90_FORECAST_UNITS
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , STORE_BK
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

, RENAME_b as (
    SELECT
        MODEL_STYLE_NUMBER
      , MODEL_NUMBER
      , ASIN_XREF
      , ITEM_BK
    FROM LOGIC_b
)

, RENAME_mara as (
    SELECT
        matnr
    FROM LOGIC_mara
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
    WHERE rec_src = 'US.API_FT.AMAZON_SP_FT_MOEN_INC.VENDOR_FORECASTING_RETAIL_REPORT'
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
          ASIN
        , END_DATE
        , FORECAST_GENERATION_DATE
        , MARKETPLACE_ID
        , START_DATE
        , MEAN_FORECAST_UNITS
        , P_70_FORECAST_UNITS
        , P_80_FORECAST_UNITS
        , P_90_FORECAST_UNITS
        , _FIVETRAN_SYNCED
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , REC_SRC
        , BKCC_ITEM
        , STORE_BK
        , ITEM_BK
        , BKCC_STORE
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ITEM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(STORE_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC_ITEM as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC_STORE as VARCHAR)),''), '^^')
        ))) as CHANNEL_FORECAST_ITEMS_LHK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ITEM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC_ITEM as VARCHAR)),''), '^^')
        ))) as ITEM_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(STORE_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC_STORE as VARCHAR)),''), '^^')
        ))) as STORE_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(END_DATE::text), '^^')
            , '||', IFNULL(TRIM(MEAN_FORECAST_UNITS::text), '^^') 
            , '||', IFNULL(TRIM(P_70_FORECAST_UNITS::text), '^^') 
            , '||', IFNULL(TRIM(P_80_FORECAST_UNITS::text), '^^') 
            , '||', IFNULL(TRIM(P_90_FORECAST_UNITS::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT