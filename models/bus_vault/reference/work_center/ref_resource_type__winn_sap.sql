---- SRC LAYER ----
WITH
SRC_b              as ( SELECT DDLANGUAGE, DDTEXT, DOMVALUE_L, LOAD_DTS, VALPOS FROM {{ ref('v_psa_stg_resource_type__winn_sap') }} as SRC  )

/*
SRC_b              as ( SELECT * FROM staging.V_PSA_STG_RESOURCE_TYPE__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_b as (
    SELECT
        DDLANGUAGE                                                   as                                       LANGUAGE_KEY
      , VALPOS                                                       as                            RESOURCE_TYPE_INDICATOR
      , DDTEXT                                                       as                                 RESOURCE_TYPE_TEXT
      , DOMVALUE_L                                                   as                                 RESOURCE_TYPE_CODE
      , LOAD_DTS
    FROM SRC_b
)
---- RENAME LAYER ----

, RENAME_b as (
    SELECT
        LANGUAGE_KEY
      , RESOURCE_TYPE_INDICATOR
      , RESOURCE_TYPE_TEXT
      , RESOURCE_TYPE_CODE
      , LOAD_DTS
    FROM LOGIC_b
)
---- FILTER LAYER ----

, FILTER_b as (
    SELECT *
    FROM RENAME_b
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_b
)

---- FINAL LAYER ----
SELECT
          LANGUAGE_KEY
        , RESOURCE_TYPE_INDICATOR
        , RESOURCE_TYPE_TEXT
        , RESOURCE_TYPE_CODE
        , LOAD_DTS
FROM JOIN_RESULT
