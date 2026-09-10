---- SRC LAYER ----
WITH
SRC_sap            as ( SELECT DIMEN, FLDFA, FLDPL, LOAD_DTS, PARID, TXT, TXTLG, SPRAS, UNIT, VALUE_DEF, VGFLD, VKALK, VKAPA, VKAPF, VRWRT, VTERM FROM {{ ref('v_psa_stg_work_center_formula_pattern__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PARID,SPRAS ORDER BY LOAD_DTS desc))=1 )

/*
SRC_sap            as ( SELECT * FROM STAGING.V_PSA_STG_WORK_CENTER_FORMULA_PATTERN__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_sap as (
    SELECT
        PARID                                                        as                                       PARAMETER_ID
      , TXT                                                          as                                  SHORT_DESCRIPTION
      , TXTLG                                                        as                                   LONG_DESCRIPTION
      , SPRAS                                                        as                                   LANGUAGE_KEY
      , VRWRT                                                        as                                      DEFAULT_VALUE
      , FLDPL                                                        as                                     DECIMAL_PLACES
      , FLDFA                                                        as                                       FIELD_FACTOR
      , DIMEN                                                        as                                      DIMENSION_KEY
      , UNIT                                                         as                                    UNIT_OF_MEASURE
      , VALUE_DEF                                                    as                                     STANDARD_VALUE
      , VGFLD                                                        as                                         FIELD_NAME
      , VKALK                                                        as                                  COSTING_RELEVANCE
      , VKAPA                                                        as                                 CAPACITY_RELEVANCE
      , VKAPF                                                        as                                   CAPACITY_FORMULA
      , VTERM                                                        as                               SCHEDULING_RELEVANCE
      , LOAD_DTS
    FROM SRC_sap
)
---- RENAME LAYER ----

, RENAME_sap as (
    SELECT
        PARAMETER_ID
      , SHORT_DESCRIPTION
      , LONG_DESCRIPTION
      , LANGUAGE_KEY
      , DEFAULT_VALUE
      , DECIMAL_PLACES
      , FIELD_FACTOR
      , DIMENSION_KEY
      , UNIT_OF_MEASURE
      , STANDARD_VALUE
      , FIELD_NAME
      , COSTING_RELEVANCE
      , CAPACITY_RELEVANCE
      , CAPACITY_FORMULA
      , SCHEDULING_RELEVANCE
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
          PARAMETER_ID
        , SHORT_DESCRIPTION
        , LONG_DESCRIPTION
        , LANGUAGE_KEY
        , DEFAULT_VALUE
        , DECIMAL_PLACES
        , FIELD_FACTOR
        , DIMENSION_KEY
        , UNIT_OF_MEASURE
        , STANDARD_VALUE
        , FIELD_NAME
        , COSTING_RELEVANCE
        , CAPACITY_RELEVANCE
        , CAPACITY_FORMULA
        , SCHEDULING_RELEVANCE
        , LOAD_DTS
FROM JOIN_RESULT