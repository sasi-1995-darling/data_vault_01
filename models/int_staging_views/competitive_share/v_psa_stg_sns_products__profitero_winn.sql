---- SRC LAYER ----
WITH
SRC_S              as ( SELECT * FROM {{ source('profitero', 'sns_products') }} as SRC 
                        where psa_delete_ind='N'
                        qualify row_number() over(partition by asin order by psa_load_dts desc)=1 ),
SRC_a              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S              as ( SELECT * FROM profitero.sns_products )
, SRC_a              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        coalesce(nullif(trim(ASIN::varchar), ''), '-1')              as                                            ASIN_BK
      , CONVERT_TIMEZONE('UTC', IFF(PSA_DELETE_IND = 'Y', PSA_LOAD_DTS, coalesce(updated_at,psa_load_dts))) as                                           LOAD_DTS
      , ASIN
      , CUSTOMER_PRODUCT_ID::VARCHAR                                 as                                CUSTOMER_PRODUCT_ID
      , CUSTOMER_PRODUCT_ID::VARCHAR                                 as                                         PRODUCT_BK
      , BRAND_ID
      , NAME
      , UPC
      , EAN
      , MODEL
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
---- RENAME LAYER ----

, RENAME_S as (
    SELECT
        ASIN_BK
      , LOAD_DTS
      , ASIN
      , CUSTOMER_PRODUCT_ID
      , PRODUCT_BK
      , BRAND_ID
      , NAME
      , UPC
      , EAN
      , MODEL
      , UPDATED_AT
      , IS_DELETED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
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
    WHERE rec_src = 'US.PROFITERO_WINN.SNS_PRODUCTS'
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
          ASIN_BK
        , LOAD_DTS
        , ASIN
        , CUSTOMER_PRODUCT_ID
        , PRODUCT_BK
        , BRAND_ID
        , NAME
        , UPC
        , EAN
        , MODEL
        , UPDATED_AT
        , IS_DELETED
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , BKCC
        , REC_SRC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PRODUCT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(ASIN_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as LNK_PRODUCT_ASIN_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ASIN_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ASIN_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PRODUCT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PRODUCT_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(CUSTOMER_PRODUCT_ID::text), '^^') 
            , '||', IFNULL(TRIM(PRODUCT_BK::text), '^^') 
            , '||', IFNULL(TRIM(BRAND_ID::text), '^^') 
            , '||', IFNULL(TRIM(NAME::text), '^^') 
            , '||', IFNULL(TRIM(UPC::text), '^^') 
            , '||', IFNULL(TRIM(EAN::text), '^^') 
            , '||', IFNULL(TRIM(MODEL::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
