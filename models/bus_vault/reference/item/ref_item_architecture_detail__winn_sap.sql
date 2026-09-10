---- SRC LAYER ----
WITH
SRC_zarchdett      as ( SELECT GLCHANGETIME, GLDELFLAG, GLREQUEST, GLSOURCESYSTEM, LOAD_DTS, MANDT, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, REC_SRC, SPRAS, TXT30, ZZARCHDET FROM {{ ref('v_psa_stg_item_architecture_detail__winn_sap') }} as SRC 
                        QUALIFY 1 = ROW_NUMBER() OVER (PARTITION BY ZZARCHDET, SPRAS ORDER BY LOAD_DTS DESC) )

/*
SRC_zarchdett      as ( SELECT * FROM STAGING.v_psa_stg_item_architecture_detail__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_zarchdett as (
    SELECT
        MANDT                                                        as                                             CLIENT
      , SPRAS                                                        as                                       LANGUAGE_KEY
      , ZZARCHDET                                                    as                             ARCHITECTURE_DETAIL_ID
      , TXT30                                                        as                                ARCHITECTURE_DETAIL
      , GLREQUEST
      , GLSOURCESYSTEM
      , GLDELFLAG
      , GLCHANGETIME
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
    FROM SRC_zarchdett
)
---- RENAME LAYER ----

, RENAME_zarchdett as (
    SELECT
        CLIENT
      , LANGUAGE_KEY
      , ARCHITECTURE_DETAIL_ID
      , ARCHITECTURE_DETAIL
      , GLREQUEST
      , GLSOURCESYSTEM
      , GLDELFLAG
      , GLCHANGETIME
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_zarchdett
)
---- FILTER LAYER ----

, FILTER_zarchdett as (
    SELECT *
    FROM RENAME_zarchdett
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_zarchdett
)

---- FINAL LAYER ----
SELECT
          CLIENT
        , LANGUAGE_KEY
        , ARCHITECTURE_DETAIL_ID
        , ARCHITECTURE_DETAIL
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
