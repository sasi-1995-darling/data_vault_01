---- SRC LAYER ----
WITH
SRC_src            as ( SELECT * FROM {{ source('pos_ref', 'retail_sellthrough_phases') }} as SRC  )

/*
SRC_src            as ( SELECT * FROM PSA_PROD.POS.RETAIL_SELLTHROUGH_PHASES )
*/
---- LOGIC LAYER ----

, LOGIC_src as (
    SELECT
        PHASE
      , CATEGORY
      , PRODUCT_LINE
      , BASE_MATERIAL
      , PRODUCT_DESCRIPTION
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
    FROM SRC_src
)
---- RENAME LAYER ----

, RENAME_src as (
    SELECT
        PHASE
      , CATEGORY
      , PRODUCT_LINE
      , BASE_MATERIAL
      , PRODUCT_DESCRIPTION
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
          PHASE
        , CATEGORY
        , PRODUCT_LINE
        , BASE_MATERIAL
        , PRODUCT_DESCRIPTION
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
FROM JOIN_RESULT
