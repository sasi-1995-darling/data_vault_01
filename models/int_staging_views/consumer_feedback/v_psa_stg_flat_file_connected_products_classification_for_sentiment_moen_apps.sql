---- SRC LAYER ----
WITH
SRC_src            as ( SELECT * FROM {{ source('reference_psa', 'flat_file_connected_products_classification_for_sentiment_moen_apps') }} as SRC  )

/*
SRC_src            as ( SELECT * FROM reference_psa.flat_file_connected_products_classification_for_sentiment_moen_apps )
*/
---- LOGIC LAYER ----

, LOGIC_src as (
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
    FROM SRC_src
)
---- RENAME LAYER ----

, RENAME_src as (
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
    FROM LOGIC_src
)
---- FILTER LAYER ----

, FILTER_src as (
    SELECT *
    FROM RENAME_src
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_src
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
