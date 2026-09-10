---- SRC LAYER ----
WITH
SRC_S1             as ( SELECT * FROM {{ source('profitero_larson_psa', 'reviews') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY CUSTOMER_PRODUCT_ID, RETAILER_Id, product_id, UKEY, DUPLICATE_GROUP, IS_DELETED ORDER BY UPDATED_AT DESC, PSA_LOAD_DTS DESC ))=1 ),
SRC_a              as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  ),
SRC_S3             as ( SELECT ID, NAME FROM {{ source('profitero_larson_psa', 'retailers') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY ID ORDER BY UPDATED_AT DESC ))=1 )

/*
SRC_S1             as ( SELECT * FROM profitero_larson_psa.reviews )
SRC_a              as ( SELECT * FROM raw_vault.ref_business_key_collision )
SRC_S3             as ( SELECT * FROM profitero_larson_psa.retailers )
*/
---- LOGIC LAYER ----

, LOGIC_S1 as (
    SELECT
        coalesce(nullif(trim(CUSTOMER_PRODUCT_ID), ''), '-1')        as                                         PRODUCT_BK
      , Coalesce(CONVERT_TIMEZONE('UTC', UPDATED_AT),CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)) as                                           LOAD_DTS
      , DATE
      , CUSTOMER_PRODUCT_ID
      , PRODUCT_ID
      , SUMMARY
      , TEXT
      , STAR_RATING
      , "UNIQUE"
      , DUPLICATE_GROUP
      , REVIEW_URL
      , MANUFACTURER_COMMENT
      , MANUFACTURER_COMMENT_TEXT
      , MANUFACTURER_COMMENT_DATE
      , HAS_IMAGE
      , RETAILER_ID
      , UKEY
      , AUTHOR
      , DB_CREATED_AT
      , UPDATED_AT
      , IS_DELETED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
    FROM SRC_S1
)

, LOGIC_a as (
    SELECT
        BKCC
      , REC_SRC
    FROM SRC_a
)

, LOGIC_S3 as (
    SELECT
        NAME                                                         as                                        RETAILER_BK
      , ID                                                           as                                     S3_retailer_id
    FROM SRC_S3
)
---- RENAME LAYER ----

, RENAME_S3 as (
    SELECT
        RETAILER_BK
      , S3_retailer_id
    FROM LOGIC_S3
)

, RENAME_S1 as (
    SELECT
        PRODUCT_BK
      , LOAD_DTS
      , DATE
      , CUSTOMER_PRODUCT_ID
      , PRODUCT_ID
      , SUMMARY
      , TEXT
      , STAR_RATING
      , "UNIQUE"
      , DUPLICATE_GROUP
      , REVIEW_URL
      , MANUFACTURER_COMMENT
      , MANUFACTURER_COMMENT_TEXT
      , MANUFACTURER_COMMENT_DATE
      , HAS_IMAGE
      , RETAILER_ID
      , UKEY
      , AUTHOR
      , DB_CREATED_AT
      , UPDATED_AT
      , IS_DELETED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
    FROM LOGIC_S1
)

, RENAME_a as (
    SELECT
        BKCC
      , REC_SRC
    FROM LOGIC_a
)
---- FILTER LAYER ----

, FILTER_S1 as (
    SELECT *
    FROM RENAME_S1
)

, FILTER_a as (
    SELECT *
    FROM RENAME_a
    WHERE rec_src = 'US.PROFITERO_LARSON.REVIEWS'
)

, FILTER_S3 as (
    SELECT *
    FROM RENAME_S3
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_S1
    INNER JOIN FILTER_a
        ON '1' = '1'
    INNER JOIN FILTER_S3
        ON retailer_id = S3_retailer_id
)

---- FINAL LAYER ----
SELECT
          RETAILER_BK
        , PRODUCT_BK
        , LOAD_DTS
        , DATE
        , CUSTOMER_PRODUCT_ID
        , PRODUCT_ID
        , SUMMARY
        , TEXT
        , STAR_RATING
        , "UNIQUE"
        , DUPLICATE_GROUP
        , REVIEW_URL
        , MANUFACTURER_COMMENT
        , MANUFACTURER_COMMENT_TEXT
        , MANUFACTURER_COMMENT_DATE
        , HAS_IMAGE
        , RETAILER_ID
        , UKEY
        , AUTHOR
        , DB_CREATED_AT
        , UPDATED_AT
        , IS_DELETED
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , BKCC
        , REC_SRC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PRODUCT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(RETAILER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PRODUCT_RETAILER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PRODUCT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PRODUCT_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(RETAILER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as RETAILER_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(RETAILER_BK::text), '^^') 
            , '||', IFNULL(TRIM(PRODUCT_BK::text), '^^') 
            , '||', IFNULL(TRIM(DATE::text), '^^') 
            , '||', IFNULL(TRIM(CUSTOMER_PRODUCT_ID::text), '^^') 
            , '||', IFNULL(TRIM(PRODUCT_ID::text), '^^') 
            , '||', IFNULL(TRIM(SUMMARY::text), '^^') 
            , '||', IFNULL(TRIM(TEXT::text), '^^') 
            , '||', IFNULL(TRIM(STAR_RATING::text), '^^') 
            , '||', IFNULL(TRIM("UNIQUE"::text), '^^') 
            , '||', IFNULL(TRIM(DUPLICATE_GROUP::text), '^^') 
            , '||', IFNULL(TRIM(REVIEW_URL::text), '^^') 
            , '||', IFNULL(TRIM(MANUFACTURER_COMMENT::text), '^^') 
            , '||', IFNULL(TRIM(MANUFACTURER_COMMENT_TEXT::text), '^^') 
            , '||', IFNULL(TRIM(MANUFACTURER_COMMENT_DATE::text), '^^') 
            , '||', IFNULL(TRIM(HAS_IMAGE::text), '^^') 
            , '||', IFNULL(TRIM(RETAILER_ID::text), '^^') 
            , '||', IFNULL(TRIM(UKEY::text), '^^') 
            , '||', IFNULL(TRIM(AUTHOR::text), '^^') 
            , '||', IFNULL(TRIM(DB_CREATED_AT::text), '^^') 
            , '||', IFNULL(TRIM(UPDATED_AT::text), '^^') 
            , '||', IFNULL(TRIM(IS_DELETED::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
