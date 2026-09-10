---- SRC LAYER ----
WITH
SRC_a              as ( SELECT LAST_UPDATED_DATE, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, PURCHASE_ORDER_DATE, PURCHASE_ORDER_NUMBER, PURCHASE_ORDER_STATUS, _FIVETRAN_SYNCED FROM {{ source('amazon_sp_ft_moen_inc', 'vendor_retail_procurement_order_status') }} as SRC  ),
SRC_bkcc           as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_a              as ( SELECT * FROM amazon_sp_ft_moen_inc.vendor_retail_procurement_order_status )
SRC_bkcc           as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_a as (
    SELECT
        PURCHASE_ORDER_NUMBER                                        as                                    VENDOR_ORDER_BK
      , PURCHASE_ORDER_STATUS
      , PURCHASE_ORDER_DATE
      , LAST_UPDATED_DATE
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , PURCHASE_ORDER_NUMBER
      , IFF(
            PSA_DELETE_IND = 'Y',
            PSA_LOAD_DTS, CONVERT_TIMEZONE('UTC',_FIVETRAN_SYNCED)) as LOAD_DTS
    FROM SRC_a
)

, LOGIC_bkcc as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_bkcc
)
---- RENAME LAYER ----

, RENAME_a as (
    SELECT
        VENDOR_ORDER_BK
      , PURCHASE_ORDER_STATUS
      , PURCHASE_ORDER_DATE
      , LAST_UPDATED_DATE
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , PURCHASE_ORDER_NUMBER
      , LOAD_DTS
    FROM LOGIC_a
)

, RENAME_bkcc as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_bkcc
)
---- FILTER LAYER ----

, FILTER_a as (
    SELECT *
    FROM RENAME_a
)

, FILTER_bkcc as (
    SELECT *
    FROM RENAME_bkcc
    WHERE rec_src = 'US.API_FT.AMAZON_VC.VENDOR_RETAIL_PROCUREMENT_ORDER_STATUS'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_a
    INNER JOIN FILTER_bkcc
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          VENDOR_ORDER_BK
        , PURCHASE_ORDER_STATUS
        , PURCHASE_ORDER_DATE
        , LAST_UPDATED_DATE
        , _FIVETRAN_SYNCED
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , PURCHASE_ORDER_NUMBER
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(VENDOR_ORDER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as VENDOR_ORDER_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(PURCHASE_ORDER_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(PURCHASE_ORDER_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(PURCHASE_ORDER_DATE::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATED_DATE::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
