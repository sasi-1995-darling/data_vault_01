---- SRC LAYER ----
WITH
SRC_S1             as ( SELECT CREATED_AT, CUMULATIVE_1_STAR_REVIEWS, CUMULATIVE_2_STAR_REVIEWS, CUMULATIVE_3_STAR_REVIEWS, CUMULATIVE_4_STAR_REVIEWS, CUMULATIVE_5_STAR_REVIEWS, CUMULATIVE_RATINGS, CUMULATIVE_REVIEWS, CUMULATIVE_STAR_RATING, DIM_ACCOUNT_PRODUCT_KEY, DIM_DATE_KEY, DIM_PRODUCT_RATING_KEY, DIM_RETAILER_KEY, DIM_RETAILER_LOCATION_KEY, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, SOURCE_UPDATED_AT, UPDATED_AT
                              /* Within the same (BK, PSA_LOAD_DTS) partition, if a non-delete row exists alongside a delete, the delete is a truncate-reload artifact.
                                 True business deletes are safe, they have no companion INSERT in the same batch.
                              */
                              , CASE WHEN PSA_DELETE_IND = 'Y'
                                     AND COUNT_IF(PSA_DELETE_IND = 'N') OVER (PARTITION BY DIM_DATE_KEY, DIM_ACCOUNT_PRODUCT_KEY, DIM_RETAILER_LOCATION_KEY, PSA_LOAD_DTS) > 0
                                     THEN TRUE ELSE FALSE END AS TRUNCATE_RELOAD_FLAG
                        FROM {{ source('profitero_share_moen', 'dim_product_rating') }} as SRC
                        QUALIFY NOT TRUNCATE_RELOAD_FLAG ),
SRC_a              as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  ),
SRC_S3             as ( SELECT DIM_RETAILER_LOCATION_KEY, PSA_DELETE_IND, PSA_LOAD_DTS, RETAILER_LOCATION_NAME, UPDATED_AT
                              /* Within the same (BK, PSA_LOAD_DTS) partition, if a non-delete row exists alongside a delete, the delete is a truncate-reload artifact.
                                 True business deletes are safe, they have no companion INSERT in the same batch.
                              */
                              , CASE WHEN PSA_DELETE_IND = 'Y'
                                     AND COUNT_IF(PSA_DELETE_IND = 'N') OVER (PARTITION BY DIM_RETAILER_LOCATION_KEY, PSA_LOAD_DTS) > 0
                                     THEN TRUE ELSE FALSE END AS TRUNCATE_RELOAD_FLAG
                        FROM {{ source('profitero_share_moen', 'dim_retailer_location') }} as SRC
                        QUALIFY NOT TRUNCATE_RELOAD_FLAG
                            AND ROW_NUMBER() OVER (PARTITION BY DIM_RETAILER_LOCATION_KEY ORDER BY UPDATED_AT DESC, PSA_LOAD_DTS DESC) = 1 ),
SRC_S4             as ( SELECT ACCOUNT_PRODUCT_ID, DIM_ACCOUNT_PRODUCT_KEY, PSA_DELETE_IND, PSA_LOAD_DTS, UPDATED_AT
                              /* Within the same (BK, PSA_LOAD_DTS) partition, if a non-delete row exists alongside a delete, the delete is a truncate-reload artifact.
                                 True business deletes are safe, they have no companion INSERT in the same batch.
                              */
                              , CASE WHEN PSA_DELETE_IND = 'Y'
                                     AND COUNT_IF(PSA_DELETE_IND = 'N') OVER (PARTITION BY DIM_ACCOUNT_PRODUCT_KEY, PSA_LOAD_DTS) > 0
                                     THEN TRUE ELSE FALSE END AS TRUNCATE_RELOAD_FLAG
                        FROM {{ source('profitero_share_moen', 'dim_account_product') }} as SRC
                        QUALIFY NOT TRUNCATE_RELOAD_FLAG
                            AND ROW_NUMBER() OVER (PARTITION BY DIM_ACCOUNT_PRODUCT_KEY ORDER BY UPDATED_AT DESC, PSA_LOAD_DTS DESC) = 1 )

/*
SRC_S1             as ( SELECT * FROM profitero_share_moen.dim_product_rating )
SRC_a              as ( SELECT * FROM raw_vault.ref_business_key_collision )
SRC_S3             as ( SELECT * FROM profitero_share_moen.dim_retailer_location )
SRC_S4             as ( SELECT * FROM profitero_share_moen.dim_account_product )
*/
---- LOGIC LAYER ----

, LOGIC_S1 as (
    SELECT
        /* PSA_LOAD_DTS for deletes (clears watermark), UPDATED_AT for active records (preserves business chronology) */
        CONVERT_TIMEZONE('UTC', IFF(PSA_DELETE_IND = 'Y', PSA_LOAD_DTS, UPDATED_AT)) as                                           LOAD_DTS
      , TO_DATE(TO_CHAR(DIM_DATE_KEY), 'YYYYMMDD')                   as                                               DATE
      , CUMULATIVE_STAR_RATING
      , CUMULATIVE_REVIEWS
      , CUMULATIVE_5_STAR_REVIEWS
      , CUMULATIVE_4_STAR_REVIEWS
      , CUMULATIVE_3_STAR_REVIEWS
      , CUMULATIVE_2_STAR_REVIEWS
      , CUMULATIVE_1_STAR_REVIEWS
      , DIM_RETAILER_KEY                                             as                                        RETAILER_ID
      , SOURCE_UPDATED_AT
      , CREATED_AT
      , UPDATED_AT
      , CUMULATIVE_RATINGS
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , DIM_DATE_KEY
      , DIM_PRODUCT_RATING_KEY
      , DIM_ACCOUNT_PRODUCT_KEY
      , DIM_RETAILER_LOCATION_KEY
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
        RETAILER_LOCATION_NAME                                       as                                        RETAILER_BK
      , DIM_RETAILER_LOCATION_KEY                                    as                       S3_DIM_RETAILER_LOCATION_KEY
      /* PSA_LOAD_DTS for deletes (clears watermark), UPDATED_AT for active records (preserves business chronology) */
      , PSA_LOAD_DTS as S3_PSA_LOAD_DTS
    FROM SRC_S3
)

, LOGIC_S4 as (
    SELECT
        coalesce(nullif(trim(ACCOUNT_PRODUCT_ID), ''), '-1')         as                                         PRODUCT_BK
      , ACCOUNT_PRODUCT_ID                                           as                                CUSTOMER_PRODUCT_ID
      , ACCOUNT_PRODUCT_ID                                           as                                         PRODUCT_ID
      , DIM_ACCOUNT_PRODUCT_KEY                                      as                         S4_DIM_ACCOUNT_PRODUCT_KEY
      /* PSA_LOAD_DTS for deletes (clears watermark), UPDATED_AT for active records (preserves business chronology) */
      , PSA_LOAD_DTS as S4_PSA_LOAD_DTS
    FROM SRC_S4
)
---- RENAME LAYER ----

, RENAME_S3 as (
    SELECT
        RETAILER_BK
      , S3_DIM_RETAILER_LOCATION_KEY
      , S3_PSA_LOAD_DTS
    FROM LOGIC_S3
)

, RENAME_S4 as (
    SELECT
        PRODUCT_BK
      , CUSTOMER_PRODUCT_ID
      , PRODUCT_ID
      , S4_DIM_ACCOUNT_PRODUCT_KEY
      , S4_PSA_LOAD_DTS
    FROM LOGIC_S4
)

, RENAME_S1 as (
    SELECT
        LOAD_DTS
      , DATE
      , CUMULATIVE_STAR_RATING
      , CUMULATIVE_REVIEWS
      , CUMULATIVE_5_STAR_REVIEWS
      , CUMULATIVE_4_STAR_REVIEWS
      , CUMULATIVE_3_STAR_REVIEWS
      , CUMULATIVE_2_STAR_REVIEWS
      , CUMULATIVE_1_STAR_REVIEWS
      , RETAILER_ID
      , SOURCE_UPDATED_AT
      , CREATED_AT
      , UPDATED_AT
      , CUMULATIVE_RATINGS
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , DIM_DATE_KEY
      , DIM_PRODUCT_RATING_KEY
      , DIM_ACCOUNT_PRODUCT_KEY
      , DIM_RETAILER_LOCATION_KEY
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

, FILTER_S4 as (
    SELECT *
    FROM RENAME_S4
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_S1
    INNER JOIN FILTER_a
        ON '1' = '1'
    INNER JOIN FILTER_S4
        ON dim_account_product_key = S4_dim_account_product_key
    INNER JOIN FILTER_S3
        ON dim_retailer_location_key = S3_dim_retailer_location_key
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
        , SOURCE_UPDATED_AT
        , CREATED_AT
        , UPDATED_AT
        , CUMULATIVE_RATINGS
        , {{ greatest_date(['PSA_LOAD_DTS', 'S3_PSA_LOAD_DTS', 'S4_PSA_LOAD_DTS']) }} as PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , BKCC
        , REC_SRC
        , DIM_DATE_KEY
        , DIM_PRODUCT_RATING_KEY
        , DIM_ACCOUNT_PRODUCT_KEY
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
            , '||', IFNULL(TRIM(SOURCE_UPDATED_AT::text), '^^') 
            , '||', IFNULL(TRIM(CREATED_AT::text), '^^') 
            , '||', IFNULL(TRIM(CUMULATIVE_RATINGS::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
            , '||', IFNULL(TRIM(DIM_DATE_KEY::text), '^^') 
            , '||', IFNULL(TRIM(DIM_PRODUCT_RATING_KEY::text), '^^') 
            , '||', IFNULL(TRIM(DIM_ACCOUNT_PRODUCT_KEY::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT



