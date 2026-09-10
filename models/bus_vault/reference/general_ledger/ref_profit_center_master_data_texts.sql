---- SRC LAYER ----
WITH
SRC_pc_text         as ( SELECT * FROM {{ ref('v_psa_stg_profit_center_master_data_texts__winn_sap') }} as SRC 
                        qualify 1= row_number() over(partition by SPRAS, PRCTR, DATBI, KOKRS order by LOAD_DTS desc))

/*
SRC_pc_text        as ( SELECT * FROM v_psa_stg_profit_center__master_data_texts__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_pc_text as (
    SELECT
        MANDT
      , SPRAS
      , PRCTR
      , DATBI
      , KOKRS
      , GLREQUEST
      , GLSOURCESYSTEM
      , KTEXT
      , LTEXT
      , MCTXT
      , GLDELFLAG
      , GLCHANGETIME
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , BKCC
    FROM SRC_pc_text
)
---- RENAME LAYER ----

, RENAME_pc_text as (
    SELECT
        MANDT                                   as                              CLIENT
      , SPRAS                                   as                              LANGUAGE_KEY
      , PRCTR                                   as                              PROFIT_CENTER
      , DATBI                                   as                              VALID_TO_DATE__YYYYMMDD
      , KOKRS                                   as                              CONTROLLING_AREA
      , GLREQUEST
      , GLSOURCESYSTEM
      , KTEXT                                   as                              GENERAL_NAME
      , LTEXT                                   as                              LONG_TEXT
      , MCTXT                                   as                              SEARCH_TERM_FOR_MATCHCODE_SEARCH
      , GLDELFLAG
      , GLCHANGETIME
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , BKCC
    FROM LOGIC_pc_text
)
---- FILTER LAYER ----

, FILTER_pc_text as (
    SELECT *
    FROM RENAME_pc_text
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_pc_text
)

---- FINAL LAYER ----
SELECT
          CLIENT
        , LANGUAGE_KEY
        , PROFIT_CENTER
        , VALID_TO_DATE__YYYYMMDD
        , CONTROLLING_AREA
        , GLREQUEST
        , GLSOURCESYSTEM
        , GENERAL_NAME
        , LONG_TEXT
        , SEARCH_TERM_FOR_MATCHCODE_SEARCH
        , GLDELFLAG
        , GLCHANGETIME
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , REC_SRC
        , BKCC
FROM JOIN_RESULT
