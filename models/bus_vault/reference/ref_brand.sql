---- SRC LAYER ----
WITH
SRC_dc             as ( SELECT * FROM {{ ref('v_psa_stg_ref_brand') }} as SRC  )

/*
SRC_dc             as ( SELECT * FROM staging.v_psa_stg_ref_brand )
*/
---- LOGIC LAYER ----

, LOGIC_dc as (
    SELECT
        BUSINESS_UNIT
      , BRAND
      , SUB_BRAND
      , SYSTEM_BRAND
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , COMPETITOR
      , PSA_DELETE_IND
    FROM SRC_dc
)
---- RENAME LAYER ----

, RENAME_dc as (
    SELECT
        BUSINESS_UNIT
      , BRAND
      , SUB_BRAND
      , SYSTEM_BRAND
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , COMPETITOR
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
          BUSINESS_UNIT
        , BRAND
        , SUB_BRAND
        , SYSTEM_BRAND
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , COMPETITOR
        , PSA_DELETE_IND
FROM JOIN_RESULT
