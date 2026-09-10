---- SRC LAYER ----
WITH
SRC_a              as ( SELECT * FROM {{ ref('v_psa_stg_bom_usage__winn_sap') }} as SRC 
                   QUALIFY 1 = ROW_NUMBER() OVER(PARTITION BY MANDT, SPRAS, STLAN, SPTXT order by GLCHANGETIME DESC) )
                   
/*
SRC_a              as ( SELECT * FROM staging.V_PSA_STG_BOM_USAGE__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_a as (
    SELECT
        MANDT
      , SPTXT
      , SPRAS
      , STLAN
      , GLREQUEST
      , GLSOURCESYSTEM
      , ANTXT
      , GLDELFLAG
      , GLCHANGETIME
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
    FROM SRC_a
)
---- RENAME LAYER ----

, RENAME_a as (
    SELECT
        MANDT
      , SPTXT
      , SPRAS
      , STLAN
      , GLREQUEST
      , GLSOURCESYSTEM
      , ANTXT
      , GLDELFLAG
      , GLCHANGETIME
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
    FROM LOGIC_a
)
---- FILTER LAYER ----

, FILTER_a as (
    SELECT *
    FROM RENAME_a
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_a
)

---- FINAL LAYER ----
SELECT
          MANDT     as    CLIENT
        , SPTXT     as    LANGUAGE_NAME
        , SPRAS     as    LANGUAGE_KEY
        , STLAN     as    BOM_USAGE
        , GLREQUEST
        , GLSOURCESYSTEM
        , ANTXT     as    BOM_USAGE_TEXT
        , GLDELFLAG
        , GLCHANGETIME
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
FROM JOIN_RESULT
