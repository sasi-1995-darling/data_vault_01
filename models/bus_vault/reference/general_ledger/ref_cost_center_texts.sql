---- SRC LAYER ----
WITH
SRC_S              as ( SELECT BKCC, DATBI, GLCHANGETIME, GLCHANGETIME_DTTM, GLDELFLAG, GLREQUEST, GLSOURCESYSTEM, KOKRS, KOSTL, KTEXT, LOAD_DTS, LTEXT, MCTXT, PSA_DELETE_IND, REC_SRC, SPRAS FROM {{ ref('v_psa_stg_cost_center_texts__winn_sap') }} as SRC  )

/*
SRC_S              as ( SELECT * FROM STAGING.v_psa_stg_cost_center_texts__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        SPRAS                                                        
      , KOKRS                                                        
      , KOSTL                                                        
      , DATBI                                                        
      , KTEXT                                                        
      , LTEXT                                                        
      , MCTXT                                                        
      , GLREQUEST
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , GLCHANGETIME_DTTM
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , BKCC
    FROM SRC_S
)
---- RENAME LAYER ----

, RENAME_S as (
    SELECT
      SPRAS                                                 as                             LANGUAGE_KEY
      , KOKRS                                               as                             CONTROLLING_AREA
      , KOSTL                                               as                             COST_CENTER
      , DATBI                                               as                             VALID_TO_DATE__YYYYMMDD
      , KTEXT                                               as                             GENERAL_NAME
      , LTEXT                                               as                             DESCRIPTION
      , MCTXT                                               as                             MATCHCODE_USE_SEARCH_TERM
      , GLREQUEST
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , GLCHANGETIME_DTTM
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , BKCC
    FROM LOGIC_S
)
---- FILTER LAYER ----

, FILTER_S as (
    SELECT *
    FROM RENAME_S
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_S
)

---- FINAL LAYER ----
SELECT
          LANGUAGE_KEY
        , CONTROLLING_AREA
        , COST_CENTER
        , VALID_TO_DATE__YYYYMMDD
        , GENERAL_NAME
        , DESCRIPTION
        , MATCHCODE_USE_SEARCH_TERM
        , GLREQUEST
        , GLDELFLAG
        , GLCHANGETIME
        , GLSOURCESYSTEM
        , GLCHANGETIME_DTTM
        , PSA_DELETE_IND
        , LOAD_DTS
        , REC_SRC
        , BKCC
FROM JOIN_RESULT
