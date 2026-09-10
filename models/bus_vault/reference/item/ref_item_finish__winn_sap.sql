---- SRC LAYER ----
WITH
SRC_zpfint         as ( SELECT GLCHANGETIME, GLDELFLAG, GLREQUEST, GLSOURCESYSTEM, LOAD_DTS, MANDT, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, REC_SRC, SPRAS, TXT30, ZZFIN FROM {{ ref('v_psa_stg_item_finish__winn_sap') }} as SRC 
                        QUALIFY 1 = ROW_NUMBER() OVER (PARTITION BY ZZFIN, SPRAS ORDER BY LOAD_DTS DESC) )

/*
SRC_zpfint         as ( SELECT * FROM STAGING.v_psa_stg_item_finish__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_zpfint as (
    SELECT
        MANDT                                                        as                                             CLIENT
      , SPRAS                                                        as                                       LANGUAGE_KEY
      , ZZFIN                                                        as                                          FINISH_ID
      , TXT30                                                        as                                             FINISH
      , GLREQUEST
      , GLSOURCESYSTEM
      , GLDELFLAG
      , GLCHANGETIME
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
    FROM SRC_zpfint
)
---- RENAME LAYER ----

, RENAME_zpfint as (
    SELECT
        CLIENT
      , LANGUAGE_KEY
      , FINISH_ID
      , FINISH
      , GLREQUEST
      , GLSOURCESYSTEM
      , GLDELFLAG
      , GLCHANGETIME
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_zpfint
)
---- FILTER LAYER ----

, FILTER_zpfint as (
    SELECT *
    FROM RENAME_zpfint
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_zpfint
)

---- FINAL LAYER ----
SELECT
          CLIENT
        , LANGUAGE_KEY
        , FINISH_ID
        , FINISH
        , GLREQUEST
        , GLSOURCESYSTEM
        , GLDELFLAG
        , GLCHANGETIME
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
