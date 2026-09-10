---- SRC LAYER ----
WITH
SRC_S1             as ( SELECT ACCOUNT_PRODUCT_ID, ACCOUNT_PRODUCT_NAME, CREATED_AT, DIM_ACCOUNT_PRODUCT_KEY, DIM_BRAND_KEY, EAN, MAP_PRICE, PRODUCT_DUPLICATE_GROUP_ID, PRODUCT_MODEL, PRODUCT_URL, PROVIDED_RPC, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, SCRAPED_RPC, UPC, UPDATED_AT
                              /* Within the same (BK, PSA_LOAD_DTS) partition, if a non-delete row exists alongside a delete, the delete is a truncate-reload artifact.
                                 True business deletes are safe, they have no companion INSERT in the same batch.
                              */
                              , CASE WHEN PSA_DELETE_IND = 'Y'
                                     AND COUNT_IF(PSA_DELETE_IND = 'N') OVER (PARTITION BY DIM_ACCOUNT_PRODUCT_KEY, PSA_LOAD_DTS) > 0
                                     THEN TRUE ELSE FALSE END AS TRUNCATE_RELOAD_FLAG
                        FROM {{ source('profitero_share_thermatru', 'dim_account_product') }} as SRC
                        QUALIFY NOT TRUNCATE_RELOAD_FLAG ),
SRC_A1             as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S1             as ( SELECT * FROM profitero_share_thermatru.dim_account_product )
SRC_A1             as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S1 as (
    SELECT
        to_varchar(ACCOUNT_PRODUCT_ID)                               as                                         PRODUCT_BK
      /* PSA_LOAD_DTS for deletes (clears watermark), UPDATED_AT for active records (preserves business chronology) */
      , CONVERT_TIMEZONE('UTC', IFF(PSA_DELETE_IND = 'Y', PSA_LOAD_DTS, UPDATED_AT)) as                                           LOAD_DTS
      , ACCOUNT_PRODUCT_ID
      , ACCOUNT_PRODUCT_NAME
      , DIM_BRAND_KEY
      , PROVIDED_RPC
      , EAN
      , UPC
      , PRODUCT_MODEL
      , MAP_PRICE
      , PRODUCT_URL
      , CREATED_AT
      , UPDATED_AT
      , SCRAPED_RPC
      , PRODUCT_DUPLICATE_GROUP_ID
      , NULL                                                         as                                         IS_DELETED /* just to match cols from the old Profitero. This col is not being used in business_vault or infomart */
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , DIM_ACCOUNT_PRODUCT_KEY
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
      , ACCOUNT_PRODUCT_ID
      , ACCOUNT_PRODUCT_NAME
      , DIM_BRAND_KEY
      , PROVIDED_RPC
      , EAN
      , UPC
      , PRODUCT_MODEL
      , MAP_PRICE
      , PRODUCT_URL
      , CREATED_AT
      , UPDATED_AT
      , SCRAPED_RPC
      , PRODUCT_DUPLICATE_GROUP_ID
      , IS_DELETED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , DIM_ACCOUNT_PRODUCT_KEY
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
    WHERE rec_src = 'US.PROFITERO_THERMATRU.CUSTOMER_PRODUCTS'
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
        , ACCOUNT_PRODUCT_ID
        , ACCOUNT_PRODUCT_NAME
        , DIM_BRAND_KEY
        , PROVIDED_RPC
        , EAN
        , UPC
        , PRODUCT_MODEL
        , MAP_PRICE
        , PRODUCT_URL
        , CREATED_AT
        , UPDATED_AT
        , SCRAPED_RPC
        , PRODUCT_DUPLICATE_GROUP_ID
        , IS_DELETED
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , REC_SRC
        , BKCC
        , DIM_ACCOUNT_PRODUCT_KEY
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PRODUCT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PRODUCT_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(ACCOUNT_PRODUCT_NAME::text), '^^') 
            , '||', IFNULL(TRIM(DIM_BRAND_KEY::text), '^^') 
            , '||', IFNULL(TRIM(PROVIDED_RPC::text), '^^') 
            , '||', IFNULL(TRIM(EAN::text), '^^') 
            , '||', IFNULL(TRIM(UPC::text), '^^') 
            , '||', IFNULL(TRIM(PRODUCT_MODEL::text), '^^') 
            , '||', IFNULL(TRIM(MAP_PRICE::text), '^^') 
            , '||', IFNULL(TRIM(IS_DELETED::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT