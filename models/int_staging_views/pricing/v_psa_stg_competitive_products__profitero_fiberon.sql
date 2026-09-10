---- SRC LAYER ----
WITH
SRC_S              as ( SELECT * FROM {{ source('profitero_fiberon', 'products') }} as SRC 
                        where psa_delete_ind='N'
                        qualify row_number() over(partition by id order by psa_load_dts desc)=1 ),
SRC_a              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  ),
SRC_p              as ( SELECT * FROM {{ source('profitero_fiberon', 'price_availability_history') }} as SRC 
                        where psa_delete_ind='N'
                        qualify row_number() over(partition by product_id, retailer_id order by psa_load_dts desc)=1 ),
SRC_r              as ( SELECT * FROM {{ source('profitero_fiberon', 'retailers') }} as SRC 
                        where psa_delete_ind='N'
                        qualify row_number() over(partition by id order by psa_load_dts desc)=1 )

/*
SRC_S              as ( SELECT * FROM profitero_fiberon.products )
, SRC_a              as ( SELECT * FROM raw_vault.ref_business_key_collision )
, SRC_p              as ( SELECT * FROM profitero_fiberon.price_availability_history )
, SRC_r              as ( SELECT * FROM profitero_fiberon.retailers )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        coalesce(nullif(trim(ID), ''), '-1')                         as                             COMPETITIVE_PRODUCT_BK
      , CONVERT_TIMEZONE('UTC', IFF(PSA_DELETE_IND = 'Y', PSA_LOAD_DTS, updated_at)) as                                           LOAD_DTS
      , ID                                                           as                             COMPETITIVE_PRODUCT_ID
      , RANKING_PRODUCT_ID
      , RPC
      , EAN
      , UPC
      , MODEL
      , URL
      , RETAILER_ID
      , UPDATED_AT
      , IS_DELETED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
    FROM SRC_S
)

, LOGIC_a as (
    SELECT
        BKCC
      , REC_SRC
    FROM SRC_a
)

, LOGIC_p as (
    SELECT
        PRODUCT_ID                                                   as                                    COMP_PRODUCT_ID
      , CUSTOMER_PRODUCT_ID                                          as                                         PRODUCT_ID
      , coalesce(nullif(trim(CUSTOMER_PRODUCT_ID), ''), '-1')        as                                         PRODUCT_BK
    FROM SRC_p
)

, LOGIC_r as (
    SELECT
        coalesce(nullif(trim(NAME), ''), '-1')                       as                                        RETAILER_BK
      , ID                                                           as                                   RETAILER_MAIN_ID
    FROM SRC_r
)
---- RENAME LAYER ----

, RENAME_S as (
    SELECT
        COMPETITIVE_PRODUCT_BK
      , LOAD_DTS
      , COMPETITIVE_PRODUCT_ID
      , RANKING_PRODUCT_ID
      , RPC
      , EAN
      , UPC
      , MODEL
      , URL
      , RETAILER_ID
      , UPDATED_AT
      , IS_DELETED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
    FROM LOGIC_S
)

, RENAME_r as (
    SELECT
        RETAILER_BK
      , RETAILER_MAIN_ID
    FROM LOGIC_r
)

, RENAME_p as (
    SELECT
        COMP_PRODUCT_ID
      , PRODUCT_ID
      , PRODUCT_BK
    FROM LOGIC_p
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
    WHERE rec_src = 'US.PROFITERO_FIBERON.PRODUCTS'
)

, FILTER_p as (
    SELECT *
    FROM RENAME_p
)

, FILTER_r as (
    SELECT *
    FROM RENAME_r
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_S
    INNER JOIN FILTER_a
        ON '1' = '1'
    LEFT JOIN FILTER_p
        ON competitive_product_id = comp_product_id
    LEFT JOIN FILTER_r
        ON retailer_id = retailer_main_id
)

---- FINAL LAYER ----
SELECT
          COMPETITIVE_PRODUCT_BK
        , RETAILER_BK
        , LOAD_DTS
        , COMPETITIVE_PRODUCT_ID
        , RANKING_PRODUCT_ID
        , RPC
        , EAN
        , UPC
        , MODEL
        , URL
        , RETAILER_ID
        , UPDATED_AT
        , IS_DELETED
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , COMP_PRODUCT_ID
        , RETAILER_MAIN_ID
        , PRODUCT_ID
        , PRODUCT_BK
        , BKCC
        , REC_SRC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(RETAILER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as RETAILER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PRODUCT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PRODUCT_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(COMPETITIVE_PRODUCT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as COMPETITIVE_PRODUCT_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(COMPETITIVE_PRODUCT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(RETAILER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as COMPETITIVE_PRODUCT_RETAILER_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(COMPETITIVE_PRODUCT_ID::text), '^^') 
            , '||', IFNULL(TRIM(RANKING_PRODUCT_ID::text), '^^') 
            , '||', IFNULL(TRIM(RPC::text), '^^') 
            , '||', IFNULL(TRIM(EAN::text), '^^') 
            , '||', IFNULL(TRIM(UPC::text), '^^') 
            , '||', IFNULL(TRIM(MODEL::text), '^^') 
            , '||', IFNULL(TRIM(URL::text), '^^') 
            , '||', IFNULL(TRIM(RETAILER_ID::text), '^^') 
            , '||', IFNULL(TRIM(UPDATED_AT::text), '^^') 
            , '||', IFNULL(TRIM(IS_DELETED::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
