---- SRC LAYER ----
WITH
SRC_prctyp         as ( SELECT * FROM {{ ref('v_psa_stg_item_special_procurement_type__winn_sap') }} as SRC  )

/*
SRC_prctyp         as ( SELECT * FROM staging.v_psa_stg_item_special_procurement_type__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_prctyp as (
    SELECT
        MANDT                                                        as                                             CLIENT
      , SPRAS                                                        as                                       LANGUAGE_KEY
      , WERKS                                                        as                                              PLANT
      , SOBSL                                                        as                        SPECIAL_PROCUREMENT_TYPE_ID
      , GLREQUEST
      , GLSOURCESYSTEM
      , LTEXT                                                        as                      SPECIAL_PROCUREMENT_TYPE_TEXT
      , GLDELFLAG
      , GLCHANGETIME
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
    FROM SRC_prctyp
)
---- RENAME LAYER ----

, RENAME_prctyp as (
    SELECT
        CLIENT
      , LANGUAGE_KEY
      , PLANT
      , SPECIAL_PROCUREMENT_TYPE_ID
      , GLREQUEST
      , GLSOURCESYSTEM
      , SPECIAL_PROCUREMENT_TYPE_TEXT
      , GLDELFLAG
      , GLCHANGETIME
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
    FROM LOGIC_prctyp
)
---- FILTER LAYER ----

, FILTER_prctyp as (
    SELECT *
    FROM RENAME_prctyp
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_prctyp
)

---- FINAL LAYER ----
SELECT
          CLIENT
        , LANGUAGE_KEY
        , PLANT
        , SPECIAL_PROCUREMENT_TYPE_ID
        , GLREQUEST
        , GLSOURCESYSTEM
        , SPECIAL_PROCUREMENT_TYPE_TEXT
        , GLDELFLAG
        , GLCHANGETIME
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
FROM JOIN_RESULT
