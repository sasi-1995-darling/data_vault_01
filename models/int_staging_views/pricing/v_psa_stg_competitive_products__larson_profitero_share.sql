---- SRC LAYER ----
WITH
SRC_S              as ( SELECT DIM_RETAILER_PRODUCT_KEY, DIM_RETAILER_KEY, RPC, EAN, UPC, PRODUCT_MODEL, PRODUCT_URL, UPDATED_AT, PSA_LOAD_DTS, PSA_RECORD_SOURCE, PSA_DELETE_IND FROM {{ source('profitero_share_larson', 'dim_retailer_product') }} as SRC
                        where psa_delete_ind='N' ), -- to match the old profitero model logic
SRC_a              as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  ),
SRC_FAR            as ( SELECT DIM_RETAILER_PRODUCT_KEY, DIM_ACCOUNT_PRODUCT_KEY FROM {{ source('profitero_share_larson', 'fact_account_retailer_product') }} as SRC
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY DIM_RETAILER_PRODUCT_KEY ORDER BY DIM_ACCOUNT_PRODUCT_KEY))=1 ),
SRC_AP             as ( SELECT DIM_ACCOUNT_PRODUCT_KEY, ACCOUNT_PRODUCT_ID, EAN, UPC, PRODUCT_MODEL, UPDATED_AT, PSA_LOAD_DTS, PSA_DELETE_IND
                    /* Within the same (BK, PSA_LOAD_DTS) partition, if a non-delete row exists alongside a delete, the delete is a truncate-reload artifact.
                      True business deletes are safe, they have no companion INSERT in the same batch.
                    */
                    , CASE WHEN PSA_DELETE_IND = 'Y'
                         AND COUNT_IF(PSA_DELETE_IND = 'N') OVER (PARTITION BY DIM_ACCOUNT_PRODUCT_KEY, PSA_LOAD_DTS) > 0
                         THEN TRUE ELSE FALSE END AS TRUNCATE_RELOAD_FLAG
                FROM {{ source('profitero_share_larson', 'dim_account_product') }} as SRC
                QUALIFY NOT TRUNCATE_RELOAD_FLAG
                   AND ROW_NUMBER() OVER (PARTITION BY DIM_ACCOUNT_PRODUCT_KEY ORDER BY UPDATED_AT DESC, PSA_LOAD_DTS DESC) = 1 ),
SRC_r              as ( SELECT DIM_RETAILER_KEY, RETAILER_NAME, UPDATED_AT, PSA_LOAD_DTS, PSA_DELETE_IND
                    /* Within the same (BK, PSA_LOAD_DTS) partition, if a non-delete row exists alongside a delete, the delete is a truncate-reload artifact.
                      True business deletes are safe, they have no companion INSERT in the same batch.
                    */
                    , CASE WHEN PSA_DELETE_IND = 'Y'
                         AND COUNT_IF(PSA_DELETE_IND = 'N') OVER (PARTITION BY DIM_RETAILER_KEY, PSA_LOAD_DTS) > 0
                         THEN TRUE ELSE FALSE END AS TRUNCATE_RELOAD_FLAG
                FROM {{ source('profitero_share_larson', 'dim_retailer') }} as SRC
                QUALIFY NOT TRUNCATE_RELOAD_FLAG
                   AND ROW_NUMBER() OVER (PARTITION BY DIM_RETAILER_KEY ORDER BY UPDATED_AT DESC, PSA_LOAD_DTS DESC) = 1 ),
SRC_AMZ            as ( SELECT AMZ_PRODUCT_ID
                             , NULLIF(TRIM(EAN), '')   as EAN
                             , NULLIF(TRIM(UPC), '')   as UPC
                             , NULLIF(TRIM(MODEL), '') as MODEL
                             , UPDATED_AT, PSA_LOAD_DTS, PSA_DELETE_IND
                        , CASE WHEN PSA_DELETE_IND = 'Y'
                               AND COUNT_IF(PSA_DELETE_IND = 'N') OVER (PARTITION BY AMZ_PRODUCT_ID, PSA_LOAD_DTS) > 0
                               THEN TRUE ELSE FALSE END AS TRUNCATE_RELOAD_FLAG
                        FROM {{ source('profitero_share_larson', 'dim_amz_product') }} as SRC
                        QUALIFY NOT TRUNCATE_RELOAD_FLAG
                           AND ROW_NUMBER() OVER (PARTITION BY AMZ_PRODUCT_ID ORDER BY UPDATED_AT DESC, PSA_LOAD_DTS DESC) = 1 )

/*
SRC_S              as ( SELECT * FROM profitero_share_larson.dim_retailer_product )
, SRC_a              as ( SELECT * FROM raw_vault.ref_business_key_collision )
, SRC_FAR            as ( SELECT * FROM profitero_share_larson.fact_account_retailer_product )
, SRC_AP             as ( SELECT * FROM profitero_share_larson.dim_account_product )
, SRC_r              as ( SELECT * FROM profitero_share_larson.dim_retailer )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        coalesce(nullif(DIM_RETAILER_PRODUCT_KEY::VARCHAR, ''), '-1') as                             COMPETITIVE_PRODUCT_BK
      , CONVERT_TIMEZONE('UTC', PSA_LOAD_DTS)                              as                                           LOAD_DTS
      , DIM_RETAILER_PRODUCT_KEY::VARCHAR                                  as                             COMPETITIVE_PRODUCT_ID
      , NULL::VARCHAR                                                       as                              RANKING_PRODUCT_ID
      , RPC
      , EAN
      , UPC
      , PRODUCT_MODEL                                                       as                                            MODEL
      , PRODUCT_URL                                                         as                                              URL
      , DIM_RETAILER_KEY::VARCHAR                                           as                                        RETAILER_ID
      , UPDATED_AT
      , FALSE                                                               as                                         IS_DELETED
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
        far.DIM_RETAILER_PRODUCT_KEY::VARCHAR                              as                                   COMP_PRODUCT_ID
      , ap.ACCOUNT_PRODUCT_ID::VARCHAR                                     as                                         PRODUCT_ID
      , coalesce(nullif(trim(ap.ACCOUNT_PRODUCT_ID::VARCHAR), ''), '-1')   as                                         PRODUCT_BK
      , ap.PSA_LOAD_DTS                                                    as                                     P_PSA_LOAD_DTS
      , ap.EAN                                                             as                                         AP_EAN
      , ap.UPC                                                             as                                         AP_UPC
      , ap.PRODUCT_MODEL                                                   as                                        AP_MODEL
    FROM SRC_FAR far
    LEFT JOIN SRC_AP ap
        ON far.DIM_ACCOUNT_PRODUCT_KEY = ap.DIM_ACCOUNT_PRODUCT_KEY
)

, LOGIC_r as (
    SELECT
        coalesce(nullif(trim(RETAILER_NAME), ''), '-1')                    as                                        RETAILER_BK
      , RETAILER_NAME
      , DIM_RETAILER_KEY::VARCHAR                                          as                                   RETAILER_MAIN_ID
      , PSA_LOAD_DTS                                                       as                                     R_PSA_LOAD_DTS
    FROM SRC_r
)

, LOGIC_amz as (
    SELECT
        AMZ_PRODUCT_ID                                                     as                                  AMZ_PRODUCT_ID
      , EAN                                                                as                                         AMZ_EAN
      , UPC                                                                as                                         AMZ_UPC
      , MODEL                                                              as                                        AMZ_MODEL
      , PSA_LOAD_DTS                                                       as                                  AMZ_PSA_LOAD_DTS
    FROM SRC_AMZ
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
      , RETAILER_NAME
      , RETAILER_MAIN_ID
      , R_PSA_LOAD_DTS
    FROM LOGIC_r
)

, RENAME_p as (
    SELECT
        COMP_PRODUCT_ID
      , PRODUCT_ID
      , PRODUCT_BK
      , P_PSA_LOAD_DTS
      , AP_EAN
      , AP_UPC
      , AP_MODEL
    FROM LOGIC_p
)

, RENAME_a as (
    SELECT
        BKCC
      , REC_SRC
    FROM LOGIC_a
)

, RENAME_amz as (
    SELECT
        AMZ_PRODUCT_ID
      , AMZ_EAN
      , AMZ_UPC
      , AMZ_MODEL
      , AMZ_PSA_LOAD_DTS
    FROM LOGIC_amz
)
---- FILTER LAYER ----

, FILTER_S as (
    SELECT *
    FROM RENAME_S
)

, FILTER_a as (
    SELECT *
    FROM RENAME_a
    WHERE rec_src = 'US.PROFITERO_LARSON.PRODUCTS'
)

, FILTER_p as (
    SELECT *
    FROM RENAME_p
)

, FILTER_r as (
    SELECT *
    FROM RENAME_r
)

, FILTER_amz as (
    SELECT *
    FROM RENAME_amz
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
    LEFT JOIN FILTER_amz
        ON RPC = AMZ_PRODUCT_ID
)

---- FINAL LAYER ----
SELECT
          COMPETITIVE_PRODUCT_BK
        , RETAILER_BK
        , RETAILER_NAME
        , LOAD_DTS
        , COMPETITIVE_PRODUCT_ID
        , RANKING_PRODUCT_ID
        , RPC
        , COALESCE(EAN, AP_EAN, AMZ_EAN)                                  as EAN
        , COALESCE(UPC, AP_UPC, AMZ_UPC)                                  as UPC
        , COALESCE(MODEL, AP_MODEL, AMZ_MODEL)                            as MODEL
        , URL
        , RETAILER_ID
        , UPDATED_AT
        , IS_DELETED
        , {{ greatest_date(['PSA_LOAD_DTS', 'P_PSA_LOAD_DTS', 'R_PSA_LOAD_DTS', 'AMZ_PSA_LOAD_DTS']) }} as PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , COMP_PRODUCT_ID
        , RETAILER_MAIN_ID
        , PRODUCT_ID
        , PRODUCT_BK
        , BKCC
        , REC_SRC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(RETAILER_NAME as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as RETAILER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PRODUCT_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PRODUCT_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(COMPETITIVE_PRODUCT_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as COMPETITIVE_PRODUCT_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(COMPETITIVE_PRODUCT_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(RETAILER_NAME as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as COMPETITIVE_PRODUCT_RETAILER_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(RPC::text), '^^')
            , '||', IFNULL(TRIM(COALESCE(EAN, AP_EAN, AMZ_EAN)::text), '^^')
            , '||', IFNULL(TRIM(COALESCE(UPC, AP_UPC, AMZ_UPC)::text), '^^')
            , '||', IFNULL(TRIM(COALESCE(MODEL, AP_MODEL, AMZ_MODEL)::text), '^^')
            , '||', IFNULL(TRIM(URL::text), '^^')
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^')
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
