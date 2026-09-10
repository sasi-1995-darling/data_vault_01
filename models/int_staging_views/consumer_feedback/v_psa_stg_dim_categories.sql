---- SRC LAYER ----
WITH
SRC_src            as ( SELECT * FROM {{ source('reference_psa', 'dim_categories') }} as SRC  )

/*
SRC_src            as ( SELECT * FROM reference_psa.dim_categories )
*/
---- LOGIC LAYER ----

, LOGIC_src as (
    SELECT
        PRODUCT_ID
      , CUSTOMER_PRODUCT_ID
      , RETAILER_ID
      , RPC
      , MODEL
      , NAME
      , BRAND
      , SUBBRAND
      , SUBSUBBRAND
      , FIRE_RESISTANT_ATTR
      , SMART_ATTR
      , LEVEL_1
      , LEVEL_2
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
    FROM SRC_src
)
---- RENAME LAYER ----

, RENAME_src as (
    SELECT
        PRODUCT_ID
      , CUSTOMER_PRODUCT_ID
      , RETAILER_ID
      , RPC
      , MODEL
      , NAME
      , BRAND
      , SUBBRAND
      , SUBSUBBRAND
      , FIRE_RESISTANT_ATTR
      , SMART_ATTR
      , LEVEL_1
      , LEVEL_2
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
          PRODUCT_ID
        , CUSTOMER_PRODUCT_ID
        , RETAILER_ID
        , RPC
        , MODEL
        , NAME
        , BRAND
        , SUBBRAND
        , SUBSUBBRAND
        , FIRE_RESISTANT_ATTR
        , SMART_ATTR
        , LEVEL_1
        , LEVEL_2
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
FROM JOIN_RESULT
