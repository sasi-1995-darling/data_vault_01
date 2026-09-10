---- SRC LAYER ----
WITH
SRC_dc             as ( SELECT * FROM {{ ref('v_psa_stg_dim_categories') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY customer_product_id  order by psa_load_dts DESC))=1 )

/*
SRC_dc             as ( SELECT * FROM staging.v_psa_stg_dim_categories )
*/
---- LOGIC LAYER ----

, LOGIC_dc as (
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
    FROM SRC_dc
)
---- RENAME LAYER ----

, RENAME_dc as (
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
    FROM LOGIC_dc
)
---- FILTER LAYER ----

, FILTER_dc as (
    SELECT *
    FROM RENAME_dc
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_dc
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
