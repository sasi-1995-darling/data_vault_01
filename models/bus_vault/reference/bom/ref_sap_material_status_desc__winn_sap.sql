---- SRC LAYER ----
WITH
SRC_sap            as ( SELECT * FROM {{ ref('v_psa_stg_material_status_desc__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY MMSTA ORDER BY LOAD_DTS desc))=1 )

/*
SRC_sap            as ( SELECT * FROM STAGING.V_PSA_STG_MATERIAL_STATUS_DESC__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_sap as (
    SELECT
        MMSTA                                                        as                               MATERIAL_STATUS_CODE
      , SPRAS                                                        as                                       LANGUAGE_KEY
      , MTSTB                                                        as                               MATERIAL_STATUS_TEXT
      , LOAD_DTS
    FROM SRC_sap
)
---- RENAME LAYER ----

, RENAME_sap as (
    SELECT
        MATERIAL_STATUS_CODE
      , LANGUAGE_KEY
      , MATERIAL_STATUS_TEXT
      , LOAD_DTS
    FROM LOGIC_sap
)
---- FILTER LAYER ----

, FILTER_sap as (
    SELECT *
    FROM RENAME_sap
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_sap
)

---- FINAL LAYER ----
SELECT
          MATERIAL_STATUS_CODE
        , LANGUAGE_KEY
        , MATERIAL_STATUS_TEXT
        , LOAD_DTS
FROM JOIN_RESULT