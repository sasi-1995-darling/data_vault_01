---- SRC LAYER ----
WITH
SRC_fcpc           as ( SELECT * FROM {{ ref('v_psa_stg_flat_file_connected_products_classification_for_sentiment_yale_combined') }} as SRC 
                        WHERE  PSA_DELETE_IND = 'N'
                        QUALIFY 1 = ROW_NUMBER() OVER(PARTITION BY MODEL ORDER BY _LINE, PSA_LOAD_DTS DESC) )

/*
SRC_fcpc           as ( SELECT * FROM staging.v_psa_stg_flat_file_connected_products_classification_for_sentiment_yale_combined )
*/
---- LOGIC LAYER ----

, LOGIC_fcpc as (
    SELECT
        _LINE
      , _FIVETRAN_SYNCED
      , CONNECTED
      , PRIMARY_KEYWORD_FILTER
      , PRODUCT_CATEGORY
      , MODEL
      , PRODUCT
      , PRODUCT_AREA
      , PRODUCT_FAMILY
      , SOURCE
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , CONNECTED_FLAG
      , SRC_ID
    FROM SRC_fcpc
)
---- RENAME LAYER ----

, RENAME_fcpc as (
    SELECT
        _LINE
      , _FIVETRAN_SYNCED
      , CONNECTED
      , PRIMARY_KEYWORD_FILTER
      , PRODUCT_CATEGORY
      , MODEL
      , PRODUCT
      , PRODUCT_AREA
      , PRODUCT_FAMILY
      , SOURCE
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , CONNECTED_FLAG
      , SRC_ID
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
        , CONNECTED
        , PRIMARY_KEYWORD_FILTER
        , PRODUCT_CATEGORY
        , MODEL
        , PRODUCT
        , PRODUCT_AREA
        , PRODUCT_FAMILY
        , SOURCE
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , CONNECTED_FLAG
        , SRC_ID
FROM JOIN_RESULT
