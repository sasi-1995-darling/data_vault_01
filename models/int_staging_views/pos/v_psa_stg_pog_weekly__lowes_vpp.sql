---- SRC LAYER ----
WITH
SRC_s              as ( SELECT ASSORTMENT_NAME, ASSORTMENT_NUMBER, HOVBU_DESC, HOVBU_ID, ITEM_DESC, ITEM_NUMBER, LOCATION_DESC, LOCATION_ID, MERCHANDISING_DIVISION, MERCHANDISING_SUBDIVISION, PRODUCT_GROUP_NAME, PRODUCT_GROUP_NUMBER, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, STOCKED_STORES, WEEK_ID, _FIVETRAN_DELETED, _FIVETRAN_SYNCED FROM {{ source('custom_fivetran_lowes_vpp_stocked_stores', 'stocked_stores_all') }} as SRC  ),
SRC_a              as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_s              as ( SELECT * FROM custom_fivetran_lowes_vpp_stocked_stores.stocked_stores_all )
SRC_a              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_s as (
    SELECT
        COALESCE(LOCATION_ID, '0')::varchar                          as                                           STORE_BK
      , HOVBU_ID
      , ITEM_NUMBER
      , LOCATION_ID
      , WEEK_ID
      , HOVBU_DESC
      , ITEM_DESC
      , ASSORTMENT_NUMBER
      , ASSORTMENT_NAME
      , PRODUCT_GROUP_NUMBER
      , PRODUCT_GROUP_NAME
      , MERCHANDISING_SUBDIVISION
      , MERCHANDISING_DIVISION
      , LOCATION_DESC
      , STOCKED_STORES
      , _FIVETRAN_SYNCED
      , _FIVETRAN_DELETED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED)                    as                                           LOAD_DTS
    FROM SRC_s
)

, LOGIC_a as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_a
)
---- RENAME LAYER ----

, RENAME_s as (
    SELECT
        STORE_BK
      , HOVBU_ID
      , ITEM_NUMBER
      , LOCATION_ID
      , WEEK_ID
      , HOVBU_DESC
      , ITEM_DESC
      , ASSORTMENT_NUMBER
      , ASSORTMENT_NAME
      , PRODUCT_GROUP_NUMBER
      , PRODUCT_GROUP_NAME
      , MERCHANDISING_SUBDIVISION
      , MERCHANDISING_DIVISION
      , LOCATION_DESC
      , STOCKED_STORES
      , _FIVETRAN_SYNCED
      , _FIVETRAN_DELETED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
    FROM LOGIC_s
)

, RENAME_a as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_a
)
---- FILTER LAYER ----

, FILTER_s as (
    SELECT *
    FROM RENAME_s
)

, FILTER_a as (
    SELECT *
    FROM RENAME_a
    WHERE rec_src = 'US.API.LOWES_VPP.STOCKED_STORES_ALL'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_s
    INNER JOIN FILTER_a
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          STORE_BK
        , HOVBU_ID
        , ITEM_NUMBER
        , LOCATION_ID
        , WEEK_ID
        , HOVBU_DESC
        , ITEM_DESC
        , ASSORTMENT_NUMBER
        , ASSORTMENT_NAME
        , PRODUCT_GROUP_NUMBER
        , PRODUCT_GROUP_NAME
        , MERCHANDISING_SUBDIVISION
        , MERCHANDISING_DIVISION
        , LOCATION_DESC
        , STOCKED_STORES
        , _FIVETRAN_SYNCED
        , _FIVETRAN_DELETED
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(STORE_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as STORE_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(HOVBU_ID::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(LOCATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(WEEK_ID::text), '^^') 
            , '||', IFNULL(TRIM(HOVBU_DESC::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_DESC::text), '^^') 
            , '||', IFNULL(TRIM(ASSORTMENT_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(ASSORTMENT_NAME::text), '^^') 
            , '||', IFNULL(TRIM(PRODUCT_GROUP_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(PRODUCT_GROUP_NAME::text), '^^') 
            , '||', IFNULL(TRIM(MERCHANDISING_SUBDIVISION::text), '^^') 
            , '||', IFNULL(TRIM(MERCHANDISING_DIVISION::text), '^^') 
            , '||', IFNULL(TRIM(LOCATION_DESC::text), '^^') 
            , '||', IFNULL(TRIM(STOCKED_STORES::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
