{{ config(materialized='table') }}
---- SRC LAYER ----
WITH
SRC_SIDD           as ( SELECT BKCC, REC_SRC,BRAND, COMPETITIVE_PRODUCT_HK, ITEM_ID, ITEM_NAME, LOAD_DTS, STORE_ITEM_ID,PSA_DELETE_IND FROM {{ ref('sat_item_details__datavations') }} as SRC 
                        qualify row_number() over(partition by competitive_product_hk ORDER BY load_dts DESC)=1 )

/*
SRC_SIDD           as ( SELECT * FROM raw_vault.sat_item_details__datavations )
*/
---- LOGIC LAYER ----

, LOGIC_SIDD as (
    SELECT
        COMPETITIVE_PRODUCT_HK
      , ITEM_NAME
      , ITEM_ID
      , BRAND
      , LOAD_DTS
      , BKCC
      , REC_SRC
      , STORE_ITEM_ID
      , PSA_DELETE_IND
    FROM SRC_SIDD
)
---- RENAME LAYER ----

, RENAME_SIDD as (
    SELECT
        COMPETITIVE_PRODUCT_HK
      , ITEM_NAME
      , ITEM_ID
      , BRAND
      , LOAD_DTS
      , BKCC
      , REC_SRC
      , STORE_ITEM_ID
      , PSA_DELETE_IND  AS ITEM_PSA_DELETE_IND
    FROM LOGIC_SIDD
)
---- FILTER LAYER ----

, FILTER_SIDD as (
    SELECT *
    FROM RENAME_SIDD
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_SIDD
)

---- FINAL LAYER ----
SELECT
          COMPETITIVE_PRODUCT_HK
        , ITEM_NAME
        , ITEM_ID
        , BRAND
        , LOAD_DTS
        , BKCC
        , REC_SRC
        , STORE_ITEM_ID
        , ITEM_PSA_DELETE_IND
FROM JOIN_RESULT
