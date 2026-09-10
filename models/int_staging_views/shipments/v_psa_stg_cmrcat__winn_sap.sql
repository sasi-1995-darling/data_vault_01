---- SRC LAYER ----
WITH
SRC_src            as ( SELECT * FROM {{ source('sap_ecc_prd', 'z_zbw_cmrcat') }} as SRC  )

/*
SRC_src            as ( SELECT * FROM sap_ecc_prd.z_zbw_cmrcat )
*/
---- LOGIC LAYER ----

, LOGIC_src as (
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
    FROM SRC_src
)
---- RENAME LAYER ----

, RENAME_src as (
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
    FROM LOGIC_src
)
---- FILTER LAYER ----

, FILTER_src as (
    SELECT *
    FROM RENAME_src
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_src
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
