---- SRC LAYER ----
WITH
SRC_S              as ( SELECT * FROM {{ source('incoming_pos', 'item') }} as SRC 
                        
                        qualify row_number() over(partition by item_id order by modified_at desc)=1 ),
SRC_a              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S              as ( SELECT * FROM datavations_incoming.item )
, SRC_a              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        coalesce(nullif(trim(ITEM_ID), ''), '-1')                    as                             COMPETITIVE_PRODUCT_BK
      , CONVERT_TIMEZONE('UTC', MODIFIED_AT)                         as                                           LOAD_DTS
      , BRAND
      , CATEGORY
      , CREATED_AT
      , DEPARTMENT
      , INTERNET_IDS
      , ITEM_ID
      , ITEM_NAME
      , MODIFIED_AT
      , PARENT_CATEGORY
      , RETAILER
      , RETAILER_CATEGORY
      , SECTOR
      , STORE_ITEM_ID
      , PSA_LOAD_DTS
      , PSA_DELETE_IND
    FROM SRC_S
)

, LOGIC_a as (
    SELECT
        BKCC
      , REC_SRC
    FROM SRC_a
)
---- RENAME LAYER ----

, RENAME_S as (
    SELECT
        COMPETITIVE_PRODUCT_BK
      , LOAD_DTS
      , BRAND
      , CATEGORY
      , CREATED_AT
      , DEPARTMENT
      , INTERNET_IDS
      , ITEM_ID
      , ITEM_NAME
      , MODIFIED_AT
      , PARENT_CATEGORY
      , RETAILER
      , RETAILER_CATEGORY
      , SECTOR
      , STORE_ITEM_ID
      , PSA_LOAD_DTS
      , PSA_DELETE_IND
    FROM LOGIC_S
)

, RENAME_a as (
    SELECT
        BKCC
      , REC_SRC
    FROM LOGIC_a
)
---- FILTER LAYER ----

, FILTER_S as (
    SELECT *
    FROM RENAME_S
)

, FILTER_a as (
    SELECT *
    FROM RENAME_a
    WHERE rec_src = 'US.DATAVATIONS.ITEMS'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_S
    INNER JOIN FILTER_a
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          COMPETITIVE_PRODUCT_BK
        , LOAD_DTS
        , BRAND
        , CATEGORY
        , CREATED_AT
        , DEPARTMENT
        , INTERNET_IDS
        , ITEM_ID
        , ITEM_NAME
        , MODIFIED_AT
        , PARENT_CATEGORY
        , RETAILER
        , RETAILER_CATEGORY
        , SECTOR
        , STORE_ITEM_ID
        , PSA_LOAD_DTS
        , PSA_DELETE_IND
        , BKCC
        , REC_SRC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(COMPETITIVE_PRODUCT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as COMPETITIVE_PRODUCT_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(BRAND::text), '^^') 
            , '||', IFNULL(TRIM(CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(CREATED_AT::text), '^^') 
            , '||', IFNULL(TRIM(DEPARTMENT::text), '^^') 
            , '||', IFNULL(TRIM(INTERNET_IDS::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_ID::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_NAME::text), '^^') 
            , '||', IFNULL(TRIM(MODIFIED_AT::text), '^^') 
            , '||', IFNULL(TRIM(PARENT_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
            , '||', IFNULL(TRIM(RETAILER::text), '^^') 
            , '||', IFNULL(TRIM(RETAILER_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(SECTOR::text), '^^') 
            , '||', IFNULL(TRIM(STORE_ITEM_ID::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
