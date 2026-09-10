---- SRC LAYER ----
WITH
SRC_pos            as ( SELECT * FROM {{ ref('v_psa_pos_sellthrough_stages__win') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PHASE, CATEGORY, PRODUCT_LINE, BASE_MATERIAL order by psa_load_dts DESC))=1 )

/*
SRC_pos            as ( SELECT * FROM staging.v_psa_pos_sellthrough_stages__win )
*/
---- LOGIC LAYER ----

, LOGIC_pos as (
    SELECT
        PHASE
      , CATEGORY
      , PRODUCT_LINE
      , BASE_MATERIAL
      , PRODUCT_DESCRIPTION
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
    FROM SRC_pos
)
---- RENAME LAYER ----

, RENAME_pos as (
    SELECT
        PHASE
      , CATEGORY
      , PRODUCT_LINE
      , BASE_MATERIAL
      , PRODUCT_DESCRIPTION
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
    FROM LOGIC_pos
)
---- FILTER LAYER ----

, FILTER_pos as (
    SELECT *
    FROM RENAME_pos
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_pos
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
