---- SRC LAYER ----
WITH
SRC_src            as ( SELECT * FROM {{ source('reference_psa', 'ref_brand_appbot') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY appbot_product  order by psa_load_dts))=1 )

/*
SRC_src            as ( SELECT * FROM reference_psa.ref_brand_appbot )
*/
---- LOGIC LAYER ----

, LOGIC_src as (
    SELECT
        APPBOT_PRODUCT
      , BRAND
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
    FROM SRC_src
)
---- RENAME LAYER ----

, RENAME_src as (
    SELECT
        APPBOT_PRODUCT
      , BRAND
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
          APPBOT_PRODUCT
        , BRAND
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
FROM JOIN_RESULT
