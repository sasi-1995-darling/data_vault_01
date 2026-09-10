---- SRC LAYER ----
WITH
SRC_S              as ( SELECT * FROM {{ source('amazon_sp_ft_psa', 'item_vendor_detail') }} as SRC  ),
SRC_A              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S              as ( SELECT * FROM amazon_sp_ft_psa.item_vendor_detail )
, SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        ASIN
      , MARKETPLACE_ID
      , CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED)                    as                                           LOAD_DTS
      , MANUFACTURER_CODE
      , MANUFACTURER_CODE_PARENT
      , PRODUCT_CATEGORYDISPLAY_NAME
      , PRODUCT_CATEGORYVALUE
      , PRODUCT_GROUP
      , PRODUCT_SUBCATEGORYDISPLAY_NAME
      , PRODUCT_SUBCATEGORYVALUE
      , REPLENISHMENT_CATEGORY
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
        ASIN
      , MARKETPLACE_ID
      , LOAD_DTS
      , MANUFACTURER_CODE
      , MANUFACTURER_CODE_PARENT
      , PRODUCT_CATEGORYDISPLAY_NAME
      , PRODUCT_CATEGORYVALUE
      , PRODUCT_GROUP
      , PRODUCT_SUBCATEGORYDISPLAY_NAME
      , PRODUCT_SUBCATEGORYVALUE
      , REPLENISHMENT_CATEGORY
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
    WHERE rec_src = 'US.API.AMAZON_VC.ITEM_VENDOR_DETAIL'
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
          ASIN
        , MARKETPLACE_ID
        , LOAD_DTS
        , MANUFACTURER_CODE
        , MANUFACTURER_CODE_PARENT
        , PRODUCT_CATEGORYDISPLAY_NAME
        , PRODUCT_CATEGORYVALUE
        , PRODUCT_GROUP
        , PRODUCT_SUBCATEGORYDISPLAY_NAME
        , PRODUCT_SUBCATEGORYVALUE
        , REPLENISHMENT_CATEGORY
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(ASIN as VARCHAR)),''), '^^')
        ))) as AMAZON_ASIN_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(MANUFACTURER_CODE::text), '^^') 
            , '||', IFNULL(TRIM(MANUFACTURER_CODE_PARENT::text), '^^') 
            , '||', IFNULL(TRIM(PRODUCT_CATEGORYDISPLAY_NAME::text), '^^') 
            , '||', IFNULL(TRIM(PRODUCT_CATEGORYVALUE::text), '^^') 
            , '||', IFNULL(TRIM(PRODUCT_GROUP::text), '^^') 
            , '||', IFNULL(TRIM(PRODUCT_SUBCATEGORYDISPLAY_NAME::text), '^^') 
            , '||', IFNULL(TRIM(PRODUCT_SUBCATEGORYVALUE::text), '^^') 
            , '||', IFNULL(TRIM(REPLENISHMENT_CATEGORY::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
