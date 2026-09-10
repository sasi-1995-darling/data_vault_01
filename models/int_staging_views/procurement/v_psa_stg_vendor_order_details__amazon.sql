---- SRC LAYER ----
WITH
SRC_a              as ( SELECT ITEM_SEQUENCE_NUMBER, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, PURCHASE_ORDER_NUMBER, VENDOR_PRODUCT_IDENTIFIER, _FIVETRAN_SYNCED FROM {{ source('amazon_sp_ft_moen_inc', 'vendor_retail_procurement_order_item') }}  ),
SRC_bkcc_mara      as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  ),
SRC_b              as ( SELECT BSTNK, VBELN FROM {{ source('sap_ecc_prd', 'z_vbak') }} as SRC  ),
SRC_c              as ( SELECT EAN11, MATNR, POSNR, VBELN FROM {{ source('sap_ecc_prd', 'z_vbap') }} as SRC  )

/*
SRC_a              as ( SELECT * FROM amazon_sp_ft_moen_inc.v_psa_stg_lnk_sales_order_vendor_details__amazon )
SRC_bkcc           as ( SELECT * FROM raw_vault.ref_business_key_collision )
SRC_b              as ( SELECT * FROM sap_ecc_prd.z_vbak )
SRC_c              as ( SELECT * FROM sap_ecc_prd.z_vbap )
*/
---- LOGIC LAYER ----

, LOGIC_a as (
    SELECT
        PURCHASE_ORDER_NUMBER
      , VENDOR_PRODUCT_IDENTIFIER
      , ITEM_SEQUENCE_NUMBER
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , IFF(
            PSA_DELETE_IND = 'Y',
            PSA_LOAD_DTS, CONVERT_TIMEZONE('UTC',_FIVETRAN_SYNCED)) as LOAD_DTS
      , COALESCE(NULLIF(UPPER(TRIM(PURCHASE_ORDER_NUMBER)), ''), '-1') as VENDOR_ORDER_BK
      , COALESCE(NULLIF(UPPER(TRIM(ITEM_SEQUENCE_NUMBER)), ''), '-1') as VENDOR_ORDER_LINE_BK
    FROM SRC_a
)

, LOGIC_bkcc_mara as (                                               
    SELECT REC_SRC, BKCC FROM SRC_bkcc_mara
)

, LOGIC_b as (
    SELECT
        BSTNK
      , VBELN
    FROM SRC_b
    -- Keep ONLY ONE VBELN per BSTNK
    QUALIFY ROW_NUMBER() OVER (PARTITION BY BSTNK ORDER BY VBELN) = 1
)

, LOGIC_c as (
    SELECT
        LPAD(EAN11, 12, '0') as EAN11
      , VBELN
      , MATNR
      , POSNR
      , CONCAT_WS('||', COALESCE(VBELN, '-1'), COALESCE(POSNR, '-1')) as ORDER_LINE_BK
      , COALESCE(MATNR, '-1') as ITEM_BK
    FROM SRC_c
    -- Deduplicate VBAP: keep only one record per VBELN+EAN11
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY VBELN, LPAD(EAN11, 12, '0') 
        ORDER BY POSNR
    ) = 1
)
---- RENAME LAYER ----

, RENAME_a as (
    SELECT
        VENDOR_ORDER_BK
      , PURCHASE_ORDER_NUMBER
      , VENDOR_PRODUCT_IDENTIFIER
      , ITEM_SEQUENCE_NUMBER
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , VENDOR_ORDER_LINE_BK
    FROM LOGIC_a
)

, RENAME_b as (
    SELECT
        BSTNK
      , VBELN
    FROM LOGIC_b
)

, RENAME_c as (
    SELECT
        EAN11
      , VBELN
      , MATNR
      , POSNR
      , ORDER_LINE_BK
      , ITEM_BK
    FROM LOGIC_c
)

, RENAME_bkcc_mara as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_bkcc_mara
)
---- FILTER LAYER ----

, FILTER_a as (
    SELECT *
    FROM RENAME_a
)

, FILTER_bkcc_mara as (                                              
    SELECT * FROM RENAME_bkcc_mara
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_MARA'
)

, FILTER_b as (
    SELECT *
    FROM RENAME_b
)

, FILTER_c as (
    SELECT *
    FROM RENAME_c
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT 
        FILTER_a.*
      , FILTER_bkcc_mara.REC_SRC
      , FILTER_bkcc_mara.BKCC
      , FILTER_b.BSTNK
      , FILTER_c.EAN11
      , FILTER_c.VBELN
      , FILTER_c.MATNR
      , FILTER_c.POSNR
      , FILTER_c.ORDER_LINE_BK
      , FILTER_c.ITEM_BK
    FROM FILTER_a
    INNER JOIN FILTER_bkcc_mara ON '1' = '1'    -- ADD
    INNER JOIN FILTER_b ON FILTER_a.PURCHASE_ORDER_NUMBER = FILTER_b.BSTNK
    INNER JOIN FILTER_c ON FILTER_b.VBELN = FILTER_c.VBELN
           AND FILTER_a.VENDOR_PRODUCT_IDENTIFIER = FILTER_c.EAN11
)

---- FINAL LAYER ----
SELECT
          VENDOR_ORDER_BK
        , PURCHASE_ORDER_NUMBER
        , BSTNK
        , VENDOR_PRODUCT_IDENTIFIER
        , EAN11
        , VBELN
        , MATNR
        , POSNR
        , ORDER_LINE_BK
        , ITEM_BK
        , ITEM_SEQUENCE_NUMBER
        , _FIVETRAN_SYNCED
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , VENDOR_ORDER_LINE_BK
        -- Hub hash keys calculated after join
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(VENDOR_ORDER_BK), ''), '^^'),
          COALESCE(NULLIF(TRIM(VENDOR_ORDER_LINE_BK), ''), '^^'),
          COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as VENDOR_ORDER_ITEM_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(VENDOR_ORDER_BK as VARCHAR)),''), '^^'),
          COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as VENDOR_ORDER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ORDER_LINE_BK as VARCHAR)),''), '^^'),
          COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ORDER_LINE_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ITEM_BK as VARCHAR)),''), '^^'),
          COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ITEM_HK
        -- Link composite hash key
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(VENDOR_ORDER_BK as VARCHAR)),''), '^^'),
          COALESCE(NULLIF(TRIM(CAST(VENDOR_ORDER_LINE_BK as VARCHAR)),''), '^^'),
          COALESCE(NULLIF(TRIM(CAST(ITEM_BK as VARCHAR)),''), '^^'),
          COALESCE(NULLIF(TRIM(CAST(ORDER_LINE_BK as VARCHAR)),''), '^^'),
          COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as LNK_SALES_ORDER_VENDOR_DETAILS_HK
        -- HASHDIFF
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(EAN11::text), '^^')
            , '||', IFNULL(TRIM(VENDOR_PRODUCT_IDENTIFIER::text), '^^')
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
