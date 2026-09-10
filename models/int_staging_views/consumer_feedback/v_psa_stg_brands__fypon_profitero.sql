---- SRC LAYER ----
WITH
SRC_S1             as ( SELECT * FROM {{ source('profitero_fypon_psa', 'brands') }} as SRC 
                        where psa_delete_ind = 'N'
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY ID ORDER BY UPDATED_AT DESC, PSA_LOAD_DTS DESC ))=1 ),
SRC_C1             as ( SELECT * FROM {{ source('profitero_fypon_psa', 'customer_products') }} as SRC 
                        where psa_delete_ind = 'N'
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY ID ORDER BY UPDATED_AT DESC, PSA_LOAD_DTS DESC ))=1 ),
SRC_A1             as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S1             as ( SELECT * FROM profitero_fypon_psa.brands )
, SRC_C1             as ( SELECT * FROM profitero_fypon_psa.customer_products )
, SRC_A1             as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S1 as (
    SELECT
        NAME                                                         as                                           BRAND_BK
      , CONVERT_TIMEZONE('UTC', UPDATED_AT)                          as                                           LOAD_DTS
      , NAME
      , ID
      , FULL_NAME
      , OWNER
      , BRAND
      , SUBBRAND
      , SUBSUBBRAND
      , UPDATED_AT
      , IS_DELETED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
    FROM SRC_S1
)

, LOGIC_C1 as (
    SELECT
        coalesce(nullif(trim(ID), ''), '-1')                         as                                         PRODUCT_BK
      , ID                                                           as                                CUSTOMER_PRODUCT_ID
      , BRAND_ID
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
      , NAME
      , ID
      , FULL_NAME
      , OWNER
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
      , CUSTOMER_PRODUCT_ID
      , BRAND_ID
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
    WHERE rec_src = 'US.PROFITERO_FYPON.BRANDS'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_S1
    LEFT JOIN FILTER_C1
        ON id = brand_id
    INNER JOIN FILTER_A1
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          BRAND_BK
        , PRODUCT_BK
        , LOAD_DTS
        , CUSTOMER_PRODUCT_ID
        , NAME
        , ID
        , FULL_NAME
        , OWNER
        , BRAND
        , SUBBRAND
        , SUBSUBBRAND
        , UPDATED_AT
        , IS_DELETED
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , REC_SRC
        , BKCC
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
              IFNULL(TRIM(ID::text), '^^') 
            , '||', IFNULL(TRIM(FULL_NAME::text), '^^') 
            , '||', IFNULL(TRIM(OWNER::text), '^^') 
            , '||', IFNULL(TRIM(BRAND::text), '^^') 
            , '||', IFNULL(TRIM(SUBBRAND::text), '^^') 
            , '||', IFNULL(TRIM(SUBSUBBRAND::text), '^^') 
            , '||', IFNULL(TRIM(UPDATED_AT::text), '^^') 
            , '||', IFNULL(TRIM(IS_DELETED::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_BRAND_HK, hashdiff ORDER BY PSA_LOAD_DTS DESC))=1