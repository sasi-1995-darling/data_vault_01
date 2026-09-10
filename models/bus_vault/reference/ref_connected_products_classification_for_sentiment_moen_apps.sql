---- SRC LAYER ----
WITH
SRC_fcpc           as ( SELECT * FROM {{ ref('v_psa_stg_flat_file_connected_products_classification_for_sentiment_moen_apps') }} as SRC 
                        WHERE  PSA_DELETE_IND = 'N'
                        QUALIFY 1 = ROW_NUMBER() OVER(PARTITION BY APP_NAME ORDER BY _LINE, PSA_LOAD_DTS DESC) )

/*
SRC_fcpc           as ( SELECT * FROM staging.v_psa_stg_flat_file_connected_products_classification_for_sentiment_moen_apps )
*/
---- LOGIC LAYER ----

, LOGIC_fcpc as (
    SELECT
        _LINE
      , _FIVETRAN_SYNCED
      , BRAND_ID
      , APP_NAME
      , COMMENTS
      , AREA_LEVEL_1
      , PRODUCT_ID_LEVEL_2
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
    FROM SRC_fcpc
)
---- RENAME LAYER ----

, RENAME_fcpc as (
    SELECT
        _LINE
      , _FIVETRAN_SYNCED
      , BRAND_ID
      , APP_NAME
      , COMMENTS
      , AREA_LEVEL_1
      , PRODUCT_ID_LEVEL_2
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
    FROM LOGIC_fcpc
)
---- FILTER LAYER ----

, FILTER_fcpc as (
    SELECT *
    FROM RENAME_fcpc
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_fcpc
)

---- FINAL LAYER ----
SELECT
          _LINE
        , _FIVETRAN_SYNCED
        , BRAND_ID
        , APP_NAME
        , COMMENTS
        , AREA_LEVEL_1
        , PRODUCT_ID_LEVEL_2
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
FROM JOIN_RESULT
