---- SRC LAYER ----
WITH
SRC_S1             as ( SELECT * FROM {{ source('profitero_winn_psa', 'product_ratings') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY date, CUSTOMER_PRODUCT_ID, RETAILER_ID,product_id ORDER BY UPDATED_AT DESC, PSA_LOAD_DTS DESC ))=1 ),
SRC_a              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  ),
SRC_S3             as ( SELECT * FROM {{ source('profitero_winn_psa', 'retailers') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY ID ORDER BY UPDATED_AT DESC, PSA_LOAD_DTS DESC  ))=1 )

/*
SRC_S1             as ( SELECT * FROM profitero_winn_psa.product_ratings )
SRC_a              as ( SELECT * FROM raw_vault.ref_business_key_collision )
SRC_S3             as ( SELECT * FROM profitero_winn_psa.retailers )
*/
---- LOGIC LAYER ----

, LOGIC_S1 as (
    SELECT
        coalesce(nullif(trim(CUSTOMER_PRODUCT_ID), ''), '-1')        as                                         PRODUCT_BK
      , Coalesce(CONVERT_TIMEZONE('UTC', UPDATED_AT),CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)) as                                           LOAD_DTS
      , DATE
      , CUSTOMER_PRODUCT_ID
      , PRODUCT_ID
      , CUMULATIVE_STAR_RATING
      , CUMULATIVE_REVIEWS
      , CUMULATIVE_5_STAR_REVIEWS
      , CUMULATIVE_4_STAR_REVIEWS
      , CUMULATIVE_3_STAR_REVIEWS
      , CUMULATIVE_2_STAR_REVIEWS
      , CUMULATIVE_1_STAR_REVIEWS
      , RETAILER_ID
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
      , CUMULATIVE_STAR_RATING
      , CUMULATIVE_REVIEWS
      , CUMULATIVE_5_STAR_REVIEWS
      , CUMULATIVE_4_STAR_REVIEWS
      , CUMULATIVE_3_STAR_REVIEWS
      , CUMULATIVE_2_STAR_REVIEWS
      , CUMULATIVE_1_STAR_REVIEWS
      , RETAILER_ID
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
    WHERE rec_src = 'US.PROFITERO_WINN.PRODUCT_RATINGS'
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
        , CUMULATIVE_STAR_RATING
        , CUMULATIVE_REVIEWS
        , CUMULATIVE_5_STAR_REVIEWS
        , CUMULATIVE_4_STAR_REVIEWS
        , CUMULATIVE_3_STAR_REVIEWS
        , CUMULATIVE_2_STAR_REVIEWS
        , CUMULATIVE_1_STAR_REVIEWS
        , RETAILER_ID
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
            , '||', IFNULL(TRIM(CUMULATIVE_STAR_RATING::text), '^^') 
            , '||', IFNULL(TRIM(CUMULATIVE_REVIEWS::text), '^^') 
            , '||', IFNULL(TRIM(CUMULATIVE_5_STAR_REVIEWS::text), '^^') 
            , '||', IFNULL(TRIM(CUMULATIVE_4_STAR_REVIEWS::text), '^^') 
            , '||', IFNULL(TRIM(CUMULATIVE_3_STAR_REVIEWS::text), '^^') 
            , '||', IFNULL(TRIM(CUMULATIVE_2_STAR_REVIEWS::text), '^^') 
            , '||', IFNULL(TRIM(CUMULATIVE_1_STAR_REVIEWS::text), '^^') 
            , '||', IFNULL(TRIM(RETAILER_ID::text), '^^') 
            , '||', IFNULL(TRIM(UPDATED_AT::text), '^^') 
            , '||', IFNULL(TRIM(IS_DELETED::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
