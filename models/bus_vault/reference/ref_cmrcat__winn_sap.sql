---- SRC LAYER ----
WITH
SRC_cmr            as ( SELECT * FROM {{ ref('v_psa_stg_cmrcat__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY VKORG, SPART, BUKRS order by psa_load_dts DESC))=1 )

/*
SRC_cmr            as ( SELECT * FROM staging.v_psa_stg_cmrcat__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_cmr as (
    SELECT
        MANDT
      , BUKRS
      , VKORG
      , SPART
      , GLREQUEST
      , ZCMRCAT
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
    FROM SRC_cmr
)
---- RENAME LAYER ----

, RENAME_cmr as (
    SELECT
        MANDT
      , BUKRS
      , VKORG
      , SPART
      , GLREQUEST
      , ZCMRCAT
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
    FROM LOGIC_cmr
)
---- FILTER LAYER ----

, FILTER_cmr as (
    SELECT *
    FROM RENAME_cmr
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_cmr
)

---- FINAL LAYER ----
SELECT
          MANDT
        , BUKRS
        , VKORG
        , SPART
        , GLREQUEST
        , ZCMRCAT
        , GLDELFLAG
        , GLCHANGETIME
        , GLSOURCESYSTEM
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
FROM JOIN_RESULT
