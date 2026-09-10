---- SRC LAYER ----
WITH
SRC_S1             as ( SELECT AUTHOR, DB_CREATED_AT, DIM_RETAILER_KEY, DIM_REVIEW_KEY, DUPLICATE_GROUP, HAS_IMAGE, MANUFACTURER_COMMENT, MANUFACTURER_COMMENT_DATE, MANUFACTURER_COMMENT_TEXT, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, REVIEW_URL, STAR_RATING, SUMMARY, TEXT, UKEY, UPDATED_AT
                              /* Within the same (BK, PSA_LOAD_DTS) partition, if a non-delete row exists alongside a delete, the delete is a truncate-reload artifact.
                                 True business deletes are safe, they have no companion INSERT in the same batch.
                              */
                              , CASE WHEN PSA_DELETE_IND = 'Y'
                                     AND COUNT_IF(PSA_DELETE_IND = 'N') OVER (PARTITION BY DIM_REVIEW_KEY, DIM_RETAILER_KEY, UKEY, DUPLICATE_GROUP, PSA_LOAD_DTS) > 0
                                     THEN TRUE ELSE FALSE END AS TRUNCATE_RELOAD_FLAG
                        FROM {{ source('profitero_share_fiberon', 'dim_review') }} as SRC
                        QUALIFY NOT TRUNCATE_RELOAD_FLAG ),
SRC_a              as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  ),
SRC_S2             as ( SELECT DIM_ACCOUNT_PRODUCT_KEY, DIM_REVIEW_KEY, PSA_DELETE_IND, PSA_LOAD_DTS, UPDATED_AT, VARIATION
                              /* Within the same (BK, PSA_LOAD_DTS) partition, if a non-delete row exists alongside a delete, the delete is a truncate-reload artifact.
                                 True business deletes are safe, they have no companion INSERT in the same batch.
                              */
                              , CASE WHEN PSA_DELETE_IND = 'Y'
                                     AND COUNT_IF(PSA_DELETE_IND = 'N') OVER (PARTITION BY DIM_PRODUCT_REVIEW_KEY, DIM_ACCOUNT_PRODUCT_KEY, DIM_REVIEW_KEY, DIM_RETAILER_KEY, PSA_LOAD_DTS) > 0
                                     THEN TRUE ELSE FALSE END AS TRUNCATE_RELOAD_FLAG
                        FROM {{ source('profitero_share_fiberon', 'dim_product_review') }} as SRC
                        QUALIFY NOT TRUNCATE_RELOAD_FLAG
                            AND ROW_NUMBER() OVER (PARTITION BY DIM_PRODUCT_REVIEW_KEY, DIM_ACCOUNT_PRODUCT_KEY, DIM_REVIEW_KEY, DIM_RETAILER_KEY ORDER BY UPDATED_AT DESC, PSA_LOAD_DTS DESC) = 1 ),
SRC_S3             as ( SELECT DIM_RETAILER_KEY, PSA_DELETE_IND, PSA_LOAD_DTS, RETAILER_NAME, UPDATED_AT
                              /* Within the same (BK, PSA_LOAD_DTS) partition, if a non-delete row exists alongside a delete, the delete is a truncate-reload artifact.
                                 True business deletes are safe, they have no companion INSERT in the same batch.
                              */
                              , CASE WHEN PSA_DELETE_IND = 'Y'
                                     AND COUNT_IF(PSA_DELETE_IND = 'N') OVER (PARTITION BY DIM_RETAILER_KEY, PSA_LOAD_DTS) > 0
                                     THEN TRUE ELSE FALSE END AS TRUNCATE_RELOAD_FLAG
                        FROM {{ source('profitero_share_fiberon', 'dim_retailer') }} as SRC
                        QUALIFY NOT TRUNCATE_RELOAD_FLAG
                            AND ROW_NUMBER() OVER (PARTITION BY DIM_RETAILER_KEY ORDER BY UPDATED_AT DESC, PSA_LOAD_DTS DESC) = 1 ),
SRC_S4             as ( SELECT ACCOUNT_PRODUCT_ID, DIM_ACCOUNT_PRODUCT_KEY, DIM_RETAILER_KEY, PSA_DELETE_IND, PSA_LOAD_DTS, UPDATED_AT
                              /* Within the same (BK, PSA_LOAD_DTS) partition, if a non-delete row exists alongside a delete, the delete is a truncate-reload artifact.
                                 True business deletes are safe, they have no companion INSERT in the same batch.
                              */
                              , CASE WHEN PSA_DELETE_IND = 'Y'
                                     AND COUNT_IF(PSA_DELETE_IND = 'N') OVER (PARTITION BY ACCOUNT_PRODUCT_ID, DIM_RETAILER_KEY, PSA_LOAD_DTS) > 0
                                     THEN TRUE ELSE FALSE END AS TRUNCATE_RELOAD_FLAG
                        FROM {{ source('profitero_share_fiberon', 'dim_account_product') }} as SRC
                        QUALIFY NOT TRUNCATE_RELOAD_FLAG
                            AND ROW_NUMBER() OVER (PARTITION BY ACCOUNT_PRODUCT_ID, DIM_RETAILER_KEY ORDER BY UPDATED_AT DESC, PSA_LOAD_DTS DESC) = 1 )

/*
SRC_S1             as ( SELECT * FROM profitero_share_fiberon.dim_review )
SRC_a              as ( SELECT * FROM raw_vault.ref_business_key_collision )
SRC_S2             as ( SELECT * FROM profitero_share_fiberon.dim_product_review )
SRC_S3             as ( SELECT * FROM profitero_share_fiberon.dim_retailer )
SRC_S4             as ( SELECT * FROM profitero_share_fiberon.dim_account_product )
*/
---- LOGIC LAYER ----

, LOGIC_S1 as (
    SELECT
        /* PSA_LOAD_DTS for deletes (clears watermark), UPDATED_AT for active records (preserves business chronology) */
        CONVERT_TIMEZONE('UTC', IFF(PSA_DELETE_IND = 'Y', PSA_LOAD_DTS, UPDATED_AT)) as                                           LOAD_DTS
      , DB_CREATED_AT::DATE                                          as                                               DATE
      , SUMMARY
      , TEXT
      , STAR_RATING
      , ''                                                           as                                           "UNIQUE"
      , DUPLICATE_GROUP
      , REVIEW_URL
      , MANUFACTURER_COMMENT
      , MANUFACTURER_COMMENT_TEXT
      , MANUFACTURER_COMMENT_DATE
      , HAS_IMAGE
      , DIM_RETAILER_KEY                                             as                                        RETAILER_ID
      , UKEY
      , AUTHOR
      , DB_CREATED_AT
      , UPDATED_AT
      , NULL                                                         as                                         IS_DELETED /* just to match cols from the old Profitero. This col is not being used in business_vault or infomart */
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , DIM_REVIEW_KEY
      , DIM_RETAILER_KEY
    FROM SRC_S1
)

, LOGIC_a as (
    SELECT
        BKCC
      , REC_SRC
    FROM SRC_a
)

, LOGIC_S2 as (
    SELECT
        VARIATION
      , DIM_ACCOUNT_PRODUCT_KEY                                      as                         S2_DIM_ACCOUNT_PRODUCT_KEY
      , DIM_REVIEW_KEY                                               as                                  S2_DIM_REVIEW_KEY
      /* PSA_LOAD_DTS for deletes (clears watermark), UPDATED_AT for active records (preserves business chronology) */
      , PSA_LOAD_DTS as S2_PSA_LOAD_DTS
    FROM SRC_S2
)

, LOGIC_S3 as (
    SELECT
        RETAILER_NAME                                                as                                        RETAILER_BK
      , DIM_RETAILER_KEY                                             as                                S3_DIM_RETAILER_KEY
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
      , DIM_RETAILER_KEY                                             as                                S4_DIM_RETAILER_KEY
      /* PSA_LOAD_DTS for deletes (clears watermark), UPDATED_AT for active records (preserves business chronology) */
      , PSA_LOAD_DTS as S4_PSA_LOAD_DTS
    FROM SRC_S4
)
---- RENAME LAYER ----

, RENAME_S3 as (
    SELECT
        RETAILER_BK
      , S3_DIM_RETAILER_KEY
      , S3_PSA_LOAD_DTS
    FROM LOGIC_S3
)

, RENAME_S4 as (
    SELECT
        PRODUCT_BK
      , CUSTOMER_PRODUCT_ID
      , PRODUCT_ID
      , S4_DIM_ACCOUNT_PRODUCT_KEY
      , S4_DIM_RETAILER_KEY
      , S4_PSA_LOAD_DTS
    FROM LOGIC_S4
)

, RENAME_S1 as (
    SELECT
        LOAD_DTS
      , DATE
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
      , DIM_REVIEW_KEY
      , DIM_RETAILER_KEY
    FROM LOGIC_S1
)

, RENAME_S2 as (
    SELECT
        VARIATION
      , S2_DIM_ACCOUNT_PRODUCT_KEY
      , S2_DIM_REVIEW_KEY
      , S2_PSA_LOAD_DTS
    FROM LOGIC_S2
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
    WHERE rec_src = 'US.PROFITERO_FIBERON.REVIEWS'
)

, FILTER_S2 as (
    SELECT *
    FROM RENAME_S2
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
    INNER JOIN FILTER_S2
        ON dim_review_key = S2_dim_review_key
    INNER JOIN FILTER_S3
        ON dim_retailer_key = S3_dim_retailer_key
    INNER JOIN FILTER_S4
        ON S2_dim_account_product_key = S4_dim_account_product_key and dim_retailer_key = S4_dim_retailer_key
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
        , {{ greatest_date(['PSA_LOAD_DTS', 'S2_PSA_LOAD_DTS', 'S3_PSA_LOAD_DTS', 'S4_PSA_LOAD_DTS']) }} as PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , BKCC
        , REC_SRC
        , DIM_REVIEW_KEY
        , DIM_RETAILER_KEY
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
            , '||', IFNULL(TRIM(IS_DELETED::text), '^^') 
            , '||', IFNULL(TRIM(DIM_REVIEW_KEY::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
-- QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_RETAILER_HK, UKEY, PRODUCT_ID, DUPLICATE_GROUP ORDER BY LOAD_DTS DESC, PSA_LOAD_DTS DESC ))=1 


