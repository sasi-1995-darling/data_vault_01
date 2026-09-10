---- SRC LAYER ----
WITH
SRC_zrepcatgt      as ( SELECT GLCHANGETIME, GLDELFLAG, GLREQUEST, GLSOURCESYSTEM, LOAD_DTS, MANDT, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, REC_SRC, SPRAS, ZZREPCATG, ZZREPCATGD FROM {{ ref('v_psa_stg_item_reporting_category__winn_sap') }} as SRC 
                        QUALIFY 1 = ROW_NUMBER() OVER (PARTITION BY ZZREPCATG, SPRAS ORDER BY LOAD_DTS DESC) )

/*
SRC_zrepcatgt      as ( SELECT * FROM STAGING.v_psa_stg_item_reporting_category__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_zrepcatgt as (
    SELECT
        MANDT                                                        as                                             CLIENT
      , SPRAS                                                        as                                       LANGUAGE_KEY
      , ZZREPCATG                                                    as                              REPORTING_CATEGORY_ID
      , ZZREPCATGD                                                   as                                 REPORTING_CATEGORY
      , GLREQUEST
      , GLDELFLAG
      , GLSOURCESYSTEM
      , GLCHANGETIME
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
    FROM SRC_zrepcatgt
)
---- RENAME LAYER ----

, RENAME_zrepcatgt as (
    SELECT
        CLIENT
      , LANGUAGE_KEY
      , REPORTING_CATEGORY_ID
      , REPORTING_CATEGORY
      , GLREQUEST
      , GLDELFLAG
      , GLSOURCESYSTEM
      , GLCHANGETIME
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_zrepcatgt
)
---- FILTER LAYER ----

, FILTER_zrepcatgt as (
    SELECT *
    FROM RENAME_zrepcatgt
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_zrepcatgt
)

---- FINAL LAYER ----
SELECT
          CLIENT
        , LANGUAGE_KEY
        , REPORTING_CATEGORY_ID
        , REPORTING_CATEGORY
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
