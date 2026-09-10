---- SRC LAYER ----
WITH
SRC_fcpc           as ( SELECT * FROM {{ ref('v_psa_stg_flat_file_connected_products_classification_for_sentiment_moen_physical') }} as SRC 
                        WHERE  PSA_DELETE_IND = 'N'
                        QUALIFY 1 = ROW_NUMBER() OVER(PARTITION BY BASE_MATERIAL_NUMBER ORDER BY _LINE, PSA_LOAD_DTS DESC) )

/*
SRC_fcpc           as ( SELECT * FROM staging.v_psa_stg_flat_file_connected_products_classification_for_sentiment_moen_physical )
*/
---- LOGIC LAYER ----

, LOGIC_fcpc as (
    SELECT
        _LINE
      , _FIVETRAN_SYNCED
      , PRODUCT_GROUP
      , BASE_MATERIAL_NUMBER
      , PLATFORM
      , PRODUCT_TYPE
      , "IN"
      , ROOM_AREA
      , LB
      , ITEM_DESCRIPTION
      , PRICE_TYPE_GROUP
      , REPORTING_CATEGORY
      , CONNECTED_PRODUCTS_CLASS
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
      , PRODUCT_GROUP
      , BASE_MATERIAL_NUMBER
      , PLATFORM
      , PRODUCT_TYPE
      , "IN"
      , ROOM_AREA
      , LB
      , ITEM_DESCRIPTION
      , PRICE_TYPE_GROUP
      , REPORTING_CATEGORY
      , CONNECTED_PRODUCTS_CLASS
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
        , PRODUCT_GROUP
        , BASE_MATERIAL_NUMBER
        , PLATFORM
        , PRODUCT_TYPE
        , "IN"
        , ROOM_AREA
        , LB
        , ITEM_DESCRIPTION
        , PRICE_TYPE_GROUP
        , REPORTING_CATEGORY
        , CONNECTED_PRODUCTS_CLASS
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , CONNECTED_FLAG
        , SRC_ID
FROM JOIN_RESULT
