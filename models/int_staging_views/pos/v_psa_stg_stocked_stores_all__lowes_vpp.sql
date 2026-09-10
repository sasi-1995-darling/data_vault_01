---- SRC LAYER ----
WITH
SRC_lssavpp        as ( SELECT * FROM {{ source('lowes_vpp', 'lowes_stocked_stores_all') }} as SRC  ),
SRC_a              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_lssavpp        as ( SELECT * FROM lowes_vpp.lowes_stocked_stores_all )
, SRC_a              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_lssavpp as (
    SELECT
        ITEM_NUMBER                                                   as                                       LOWES_SKU_BK
      , WEEK_ID
      , ITEM_NUMBER
      , ITEM_DESC
      , ASSORTMENT_NUMBER
      , ASSORTMENT_NAME
      , STOCKED_STORES
      , HOVBU_DESC
      , HOVBU_ID
      , PRODUCT_GROUP_NUMBER
      , PRODUCT_GROUP_NAME
      , MERCH_DIVISION
      , MERCH_SUB_DIVISION
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , CONVERT_TIMEZONE('UTC', PSA_LOAD_DTS)                        as                                           LOAD_DTS
    FROM SRC_lssavpp
)

, LOGIC_a as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_a
)
---- RENAME LAYER ----

, RENAME_lssavpp as (
    SELECT
        LOWES_SKU_BK
      , WEEK_ID
      , ITEM_NUMBER
      , ITEM_DESC
      , ASSORTMENT_NUMBER
      , ASSORTMENT_NAME
      , STOCKED_STORES
      , HOVBU_DESC
      , HOVBU_ID
      , PRODUCT_GROUP_NUMBER
      , PRODUCT_GROUP_NAME
      , MERCH_DIVISION
      , MERCH_SUB_DIVISION
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
    FROM LOGIC_lssavpp
)

, RENAME_a as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_a
)
---- FILTER LAYER ----

, FILTER_lssavpp as (
    SELECT *
    FROM RENAME_lssavpp
)

, FILTER_a as (
    SELECT *
    FROM RENAME_a
    WHERE rec_src = 'US.EXCEL.LOWES_VPP.LOWES_STOCKED_STORES_ALL'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_lssavpp
    INNER JOIN FILTER_a
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          LOWES_SKU_BK
        , WEEK_ID
        , ITEM_NUMBER
        , ITEM_DESC
        , ASSORTMENT_NUMBER
        , ASSORTMENT_NAME
        , STOCKED_STORES
        , HOVBU_DESC
        , HOVBU_ID
        , PRODUCT_GROUP_NUMBER
        , PRODUCT_GROUP_NAME
        , MERCH_DIVISION
        , MERCH_SUB_DIVISION
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(WEEK_ID::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_DESC::text), '^^') 
            , '||', IFNULL(TRIM(ASSORTMENT_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(ASSORTMENT_NAME::text), '^^') 
            , '||', IFNULL(TRIM(STOCKED_STORES::text), '^^') 
            , '||', IFNULL(TRIM(HOVBU_DESC::text), '^^') 
            , '||', IFNULL(TRIM(HOVBU_ID::text), '^^') 
            , '||', IFNULL(TRIM(PRODUCT_GROUP_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(PRODUCT_GROUP_NAME::text), '^^') 
            , '||', IFNULL(TRIM(MERCH_DIVISION::text), '^^') 
            , '||', IFNULL(TRIM(MERCH_SUB_DIVISION::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
