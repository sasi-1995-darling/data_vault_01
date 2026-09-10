---- SRC LAYER ----
WITH
SRC_src            as ( SELECT * FROM {{ source('reference_psa', 'ref_brand') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY system_brand  order by psa_load_dts))=1 )

/*
SRC_src            as ( SELECT * FROM reference_psa.ref_brand )
*/
---- LOGIC LAYER ----

, LOGIC_src as (
    SELECT
        BUSINESS_UNIT
      , BRAND
      , SUB_BRAND
      , SYSTEM_BRAND
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , COMPETITOR
      , PSA_DELETE_IND
    FROM SRC_src
)
---- RENAME LAYER ----

, RENAME_src as (
    SELECT
        BUSINESS_UNIT
      , BRAND
      , SUB_BRAND
      , SYSTEM_BRAND
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , COMPETITOR
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
          BUSINESS_UNIT
        , BRAND
        , SUB_BRAND
        , SYSTEM_BRAND
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , COMPETITOR
        , PSA_DELETE_IND
FROM JOIN_RESULT
