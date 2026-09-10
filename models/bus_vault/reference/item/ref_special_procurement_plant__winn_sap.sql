---- SRC LAYER ----
WITH
SRC_prcplnt        as ( SELECT * FROM {{ ref('v_psa_stg_item_special_procurement_plant__winn_sap') }} as SRC  )

/*
SRC_prcplnt        as ( SELECT * FROM staging.v_psa_stg_item_special_procurement_plant__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_prcplnt as (
    SELECT
        MANDT                                                        as                                             CLIENT
      , WERKS                                                        as                                              PLANT
      , SOBSL                                                        as                        SPECIAL_PROCUREMENT_TYPE_ID
      , GLREQUEST
      , BESKZ                                                        as                                   PROCUREMENT_TYPE
      , SOBES                                                        as               SPECIAL_PROCUREMENT_EXTERNAL_DISPLAY
      , WRK02                                                        as                          SPECIAL_PROCUREMENT_PLANT
      , CLCOR                                                        as                              DIRECT_PRODUCTION_IND
      , DUMPS                                                        as                                   PHANTOM_ITEM_IND
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
    FROM SRC_prcplnt
)
---- RENAME LAYER ----

, RENAME_prcplnt as (
    SELECT
        CLIENT
      , PLANT
      , SPECIAL_PROCUREMENT_TYPE_ID
      , GLREQUEST
      , PROCUREMENT_TYPE
      , SPECIAL_PROCUREMENT_EXTERNAL_DISPLAY
      , SPECIAL_PROCUREMENT_PLANT
      , DIRECT_PRODUCTION_IND
      , PHANTOM_ITEM_IND
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
    FROM LOGIC_prcplnt
)
---- FILTER LAYER ----

, FILTER_prcplnt as (
    SELECT *
    FROM RENAME_prcplnt
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_prcplnt
)

---- FINAL LAYER ----
SELECT
          CLIENT
        , PLANT
        , SPECIAL_PROCUREMENT_TYPE_ID
        , GLREQUEST
        , PROCUREMENT_TYPE
        , SPECIAL_PROCUREMENT_EXTERNAL_DISPLAY
        , SPECIAL_PROCUREMENT_PLANT
        , DIRECT_PRODUCTION_IND
        , PHANTOM_ITEM_IND
        , GLDELFLAG
        , GLCHANGETIME
        , GLSOURCESYSTEM
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
FROM JOIN_RESULT