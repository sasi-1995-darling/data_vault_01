---- SRC LAYER ----
WITH
SRC_acitvity_details         as ( SELECT * FROM {{ ref('v_psa_stg_co_activity_type_details__winn_sap') }} as SRC 
                              qualify 1= row_number() over(partition by SPRAS, LSTAR, DATBI, KOKRS order by LOAD_DTS desc))

/*
SRC_acitvity_details as ( SELECT * FROM None.v_psa_stg_co_activity_type__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_acitvity_details as (
    SELECT
        SPRAS
      , KOKRS
      , LSTAR
      , DATBI
      , GLREQUEST
      , KTEXT
      , LTEXT
      , MCTXT
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , BKCC
    FROM SRC_acitvity_details
)
---- RENAME LAYER ----

, RENAME_acitvity_details as (
    SELECT
        SPRAS                                     as                              LANGUAGE_KEY
      , KOKRS                                     as                              CONTROLLING_AREA
      , LSTAR                                     as                              ACTIVITY_TYPE
      , DATBI                                     as                              VALID_TO_DATE__YYYYMMDD
      , GLREQUEST
      , KTEXT                                       as                            GENERAL_NAME
      , LTEXT                                       as                            DESCRIPTION
      , MCTXT                                       as                            SEARCH_TERM_FOR_MATCHCODE_USE
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , BKCC
    FROM LOGIC_acitvity_details
)
---- FILTER LAYER ----

, FILTER_acitvity_details as (
    SELECT *
    FROM RENAME_acitvity_details
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_acitvity_details
)

---- FINAL LAYER ----
SELECT
          LANGUAGE_KEY
        , CONTROLLING_AREA
        , ACTIVITY_TYPE
        , VALID_TO_DATE__YYYYMMDD
        , GLREQUEST
        , GENERAL_NAME
        , DESCRIPTION
        , SEARCH_TERM_FOR_MATCHCODE_USE
        , GLDELFLAG
        , GLCHANGETIME
        , GLSOURCESYSTEM
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , REC_SRC
        , BKCC
FROM JOIN_RESULT
