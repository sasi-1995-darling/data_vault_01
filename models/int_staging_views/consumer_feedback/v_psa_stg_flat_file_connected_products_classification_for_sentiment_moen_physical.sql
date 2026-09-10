---- SRC LAYER ----
WITH
SRC_src            as ( SELECT * FROM {{ source('reference_psa', 'flat_file_connected_products_classification_for_sentiment_moen_physical') }} as SRC  ),
SRC_cp             as ( SELECT * FROM {{ source('profitero_winn_psa', 'customer_products') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY ID ORDER BY UPDATED_AT desc, psa_load_dts desc ))=1 )

/*
SRC_src            as ( SELECT * FROM reference_psa.flat_file_connected_products_classification_for_sentiment_moen_physical )
, SRC_cp             as ( SELECT * FROM profitero_winn_psa.customer_products )
*/
---- LOGIC LAYER ----

, LOGIC_src as (
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
      , case when connected_products_class is not null then 'Y' else 'N' end as                                     CONNECTED_FLAG
    FROM SRC_src
)

, LOGIC_cp as (
    SELECT
        ID
      , regexp_replace(MODEL,'[^[:ascii:]]')                         as                                           CP_MODEL
      , to_varchar(id)                                               as                                             SRC_ID
    FROM SRC_cp
)
---- RENAME LAYER ----

, RENAME_src as (
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
    FROM LOGIC_src
)

, RENAME_cp as (
    SELECT
        ID
      , CP_MODEL
      , SRC_ID
    FROM LOGIC_cp
)
---- FILTER LAYER ----

, FILTER_src as (
    SELECT *
    FROM RENAME_src
)

, FILTER_cp as (
    SELECT *
    FROM RENAME_cp
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_src
    INNER JOIN FILTER_cp
        ON BASE_MATERIAL_NUMBER = CP_MODEL
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
