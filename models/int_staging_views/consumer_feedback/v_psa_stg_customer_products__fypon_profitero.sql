---- SRC LAYER ----
WITH
SRC_S1             as ( SELECT * FROM {{ source('profitero_fypon_psa', 'customer_products') }} as SRC  ),
SRC_A1             as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S1             as ( SELECT * FROM profitero_fypon_psa.customer_products )
, SRC_A1             as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S1 as (
    SELECT
        to_varchar(ID)                                               as                                         PRODUCT_BK
      , Coalesce(CONVERT_TIMEZONE('UTC', UPDATED_AT),CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)) as                                           LOAD_DTS
      , MODEL
      , NAME
      , BRAND_ID
      , RPC
      , EAN
      , UPC
      , MAP_PRICE
      , UPDATED_AT
      , IS_DELETED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
    FROM SRC_S1
)

, LOGIC_A1 as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_A1
)
---- RENAME LAYER ----

, RENAME_S1 as (
    SELECT
        PRODUCT_BK
      , LOAD_DTS
      , MODEL
      , NAME
      , BRAND_ID
      , RPC
      , EAN
      , UPC
      , MAP_PRICE
      , UPDATED_AT
      , IS_DELETED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
    FROM LOGIC_S1
)

, RENAME_A1 as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_A1
)
---- FILTER LAYER ----

, FILTER_S1 as (
    SELECT *
    FROM RENAME_S1
)

, FILTER_A1 as (
    SELECT *
    FROM RENAME_A1
    WHERE rec_src = 'US.PROFITERO_FYPON.CUSTOMER_PRODUCTS'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_S1
    INNER JOIN FILTER_A1
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          PRODUCT_BK
        , LOAD_DTS
        , MODEL
        , NAME
        , BRAND_ID
        , RPC
        , EAN
        , UPC
        , MAP_PRICE
        , UPDATED_AT
        , IS_DELETED
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PRODUCT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PRODUCT_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(MODEL::text), '^^') 
            , '||', IFNULL(TRIM(NAME::text), '^^') 
            , '||', IFNULL(TRIM(BRAND_ID::text), '^^') 
            , '||', IFNULL(TRIM(RPC::text), '^^') 
            , '||', IFNULL(TRIM(EAN::text), '^^') 
            , '||', IFNULL(TRIM(UPC::text), '^^') 
            , '||', IFNULL(TRIM(MAP_PRICE::text), '^^') 
            , '||', IFNULL(TRIM(IS_DELETED::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_BK ORDER BY LOAD_DTS desc, psa_load_dts desc ))=1