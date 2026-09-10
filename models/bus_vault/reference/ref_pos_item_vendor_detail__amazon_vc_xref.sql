---- SRC LAYER ----
WITH
SRC_IVD            as ( SELECT * FROM {{ ref('v_psa_stg_item_vendor_detail__amazon_vc') }} as SRC 
                        qualify row_number() over(partition by asin, marketplace_id order by load_dts desc)=1 )

/*
SRC_IVD            as ( SELECT * FROM staging.v_psa_stg_item_vendor_detail__amazon_vc )
*/
---- LOGIC LAYER ----

, LOGIC_IVD as (
    SELECT
        AMAZON_ASIN_HK
      , ASIN
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
      , HASHDIFF
    FROM SRC_IVD
)
---- RENAME LAYER ----

, RENAME_IVD as (
    SELECT
        AMAZON_ASIN_HK
      , ASIN
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
      , HASHDIFF
    FROM LOGIC_IVD
)
---- FILTER LAYER ----

, FILTER_IVD as (
    SELECT *
    FROM RENAME_IVD
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_IVD
)

---- FINAL LAYER ----
SELECT
          AMAZON_ASIN_HK
        , ASIN
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
        , HASHDIFF
FROM JOIN_RESULT
