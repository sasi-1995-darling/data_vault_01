---- SRC LAYER ----
WITH
SRC_S1             as ( SELECT BRAND, BRAND_NAME, BRAND_OWNER, DIM_BRAND_KEY, FULL_NAME, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, SUBBRAND, SUBSUBBRAND, UPDATED_AT
                              /* Within the same (BK, PSA_LOAD_DTS) partition, if a non-delete row exists alongside a delete, the delete is a truncate-reload artifact.
                                 True business deletes are safe, they have no companion INSERT in the same batch.
                              */
                              , CASE WHEN PSA_DELETE_IND = 'Y'
                                     AND COUNT_IF(PSA_DELETE_IND = 'N') OVER (PARTITION BY DIM_BRAND_KEY, PSA_LOAD_DTS) > 0
                                     THEN TRUE ELSE FALSE END AS TRUNCATE_RELOAD_FLAG
                        FROM {{ source('profitero_share_moen', 'dim_brand') }} as SRC
                        QUALIFY NOT TRUNCATE_RELOAD_FLAG ),
SRC_C1             as ( SELECT ACCOUNT_PRODUCT_ID, DIM_ACCOUNT_PRODUCT_KEY, DIM_BRAND_KEY, PSA_DELETE_IND, PSA_LOAD_DTS, UPDATED_AT
                              /* Within the same (BK, PSA_LOAD_DTS) partition, if a non-delete row exists alongside a delete, the delete is a truncate-reload artifact.
                                 True business deletes are safe, they have no companion INSERT in the same batch.
                              */
                              , CASE WHEN PSA_DELETE_IND = 'Y'
                                     AND COUNT_IF(PSA_DELETE_IND = 'N') OVER (PARTITION BY DIM_ACCOUNT_PRODUCT_KEY, PSA_LOAD_DTS) > 0
                                     THEN TRUE ELSE FALSE END AS TRUNCATE_RELOAD_FLAG
                        FROM {{ source('profitero_share_moen', 'dim_account_product') }} as SRC
                        QUALIFY NOT TRUNCATE_RELOAD_FLAG
                            AND ROW_NUMBER() OVER (PARTITION BY DIM_ACCOUNT_PRODUCT_KEY ORDER BY UPDATED_AT DESC, PSA_LOAD_DTS DESC) = 1 ),
SRC_A1             as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S1             as ( SELECT * FROM profitero_share_moen.dim_brand )
SRC_C1             as ( SELECT * FROM profitero_share_moen.dim_account_product )
SRC_A1             as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S1 as (
    SELECT
        BRAND_NAME                                                   as                                           BRAND_BK
      /* PSA_LOAD_DTS for deletes (clears watermark), UPDATED_AT for active records (preserves business chronology) */
      , CONVERT_TIMEZONE('UTC', IFF(PSA_DELETE_IND = 'Y', PSA_LOAD_DTS, UPDATED_AT)) as                                           LOAD_DTS
      , BRAND_NAME
      , DIM_BRAND_KEY
      , FULL_NAME
      , BRAND_OWNER
      , BRAND
      , SUBBRAND
      , SUBSUBBRAND
      , UPDATED_AT
      , NULL                                                         as                                         IS_DELETED /* just to match cols from the old Profitero. This col is not being used in business_vault or infomart */
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
    FROM SRC_S1
)

, LOGIC_C1 as (
    SELECT
        coalesce(nullif(trim(ACCOUNT_PRODUCT_ID), ''), '-1')         as                                         PRODUCT_BK
      , DIM_ACCOUNT_PRODUCT_KEY
      , DIM_BRAND_KEY                                                as                                   C1_DIM_BRAND_KEY
      , ACCOUNT_PRODUCT_ID
      /* PSA_LOAD_DTS for deletes (clears watermark), UPDATED_AT for active records (preserves business chronology) */
      , PSA_LOAD_DTS                                                as                                        C1_PSA_LOAD_DTS
    FROM SRC_C1
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
        BRAND_BK
      , LOAD_DTS
      , BRAND_NAME
      , DIM_BRAND_KEY
      , FULL_NAME
      , BRAND_OWNER
      , BRAND
      , SUBBRAND
      , SUBSUBBRAND
      , UPDATED_AT
      , IS_DELETED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
    FROM LOGIC_S1
)

, RENAME_C1 as (
    SELECT
        PRODUCT_BK
      , DIM_ACCOUNT_PRODUCT_KEY
      , C1_DIM_BRAND_KEY
      , ACCOUNT_PRODUCT_ID
      , C1_PSA_LOAD_DTS
    FROM LOGIC_C1
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

, FILTER_C1 as (
    SELECT *
    FROM RENAME_C1
)

, FILTER_A1 as (
    SELECT *
    FROM RENAME_A1
    WHERE rec_src = 'US.PROFITERO_WINN.BRANDS'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_S1
    LEFT JOIN FILTER_C1
        ON DIM_BRAND_KEY = C1_DIM_BRAND_KEY
    INNER JOIN FILTER_A1
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          BRAND_BK
        , PRODUCT_BK
        , LOAD_DTS
        , DIM_ACCOUNT_PRODUCT_KEY
        , BRAND_NAME
        , DIM_BRAND_KEY
        , FULL_NAME
        , BRAND_OWNER
        , BRAND
        , SUBBRAND
        , SUBSUBBRAND
        , UPDATED_AT
        , IS_DELETED
        , {{ greatest_date(['PSA_LOAD_DTS', 'C1_PSA_LOAD_DTS']) }} as PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , REC_SRC
        , BKCC
        , ACCOUNT_PRODUCT_ID
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(BRAND_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as BRAND_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PRODUCT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PRODUCT_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PRODUCT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BRAND_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PRODUCT_BRAND_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(DIM_BRAND_KEY::text), '^^') 
            , '||', IFNULL(TRIM(FULL_NAME::text), '^^') 
            , '||', IFNULL(TRIM(BRAND_OWNER::text), '^^') 
            , '||', IFNULL(TRIM(BRAND::text), '^^') 
            , '||', IFNULL(TRIM(SUBBRAND::text), '^^') 
            , '||', IFNULL(TRIM(SUBSUBBRAND::text), '^^') 
            , '||', IFNULL(TRIM(IS_DELETED::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_BRAND_HK, hashdiff ORDER BY PSA_LOAD_DTS DESC))=1


