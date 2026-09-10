---- SRC LAYER ----
WITH
SRC_zarcht         as ( SELECT GLCHANGETIME, GLDELFLAG, GLREQUEST, GLSOURCESYSTEM, LOAD_DTS, MANDT, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, REC_SRC, SPRAS, TXT30, ZZARCH FROM {{ ref('v_psa_stg_item_architecture__winn_sap') }} as SRC 
                        QUALIFY 1 = ROW_NUMBER() OVER (PARTITION BY ZZARCH, SPRAS ORDER BY LOAD_DTS DESC) )

/*
SRC_zarcht         as ( SELECT * FROM STAGING.v_psa_stg_item_architecture__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_zarcht as (
    SELECT
        MANDT                                                        as                                             CLIENT
      , SPRAS                                                        as                                       LANGUAGE_KEY
      , ZZARCH                                                       as                                    ARCHITECTURE_ID
      , TXT30                                                        as                                       ARCHITECTURE
      , GLREQUEST
      , GLDELFLAG
      , GLSOURCESYSTEM
      , GLCHANGETIME
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
    FROM SRC_zarcht
)
---- RENAME LAYER ----

, RENAME_zarcht as (
    SELECT
        CLIENT
      , LANGUAGE_KEY
      , ARCHITECTURE_ID
      , ARCHITECTURE
      , GLREQUEST
      , GLDELFLAG
      , GLSOURCESYSTEM
      , GLCHANGETIME
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_zarcht
)
---- FILTER LAYER ----

, FILTER_zarcht as (
    SELECT *
    FROM RENAME_zarcht
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_zarcht
)

---- FINAL LAYER ----
SELECT
          CLIENT
        , LANGUAGE_KEY
        , ARCHITECTURE_ID
        , ARCHITECTURE
        , GLREQUEST
        , GLDELFLAG
        , GLSOURCESYSTEM
        , GLCHANGETIME
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
