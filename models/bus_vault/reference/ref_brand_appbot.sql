---- SRC LAYER ----
WITH
SRC_dc             as ( SELECT * FROM {{ ref('v_psa_stg_ref_brand_appbot') }} as SRC  )

/*
SRC_dc             as ( SELECT * FROM staging.v_psa_stg_ref_brand_appbot )
*/
---- LOGIC LAYER ----

, LOGIC_dc as (
    SELECT
        APPBOT_PRODUCT
      , BRAND
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
    FROM SRC_dc
)
---- RENAME LAYER ----

, RENAME_dc as (
    SELECT
        APPBOT_PRODUCT
      , BRAND
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
          APPBOT_PRODUCT
        , BRAND
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
FROM JOIN_RESULT
