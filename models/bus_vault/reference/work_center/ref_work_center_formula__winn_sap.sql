---- SRC LAYER ----
WITH
SRC_b              as ( SELECT FTEXT, FTEXT2, FTEXT3, GENER, IDENT, LOAD_DTS, MANDT, SPRAS, TXT, VKALK, VKAPA, VKAPF, VTERM FROM {{ ref('v_psa_stg_work_center_formula__winn_sap') }} as SRC  )

/*
SRC_b              as ( SELECT * FROM staging.V_PSA_STG_WORK_CENTER_FORMULA__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_b as (
    SELECT
        MANDT                                                        as                                             CLIENT
      , IDENT                                                        as                                WORK_CENTER_FORMULA
      , FTEXT                                                        as                          WORK_CENTER_FORMULA_TEXT1
      , FTEXT2                                                       as                          WORK_CENTER_FORMULA_TEXT2
      , FTEXT3                                                       as                          WORK_CENTER_FORMULA_TEXT3
      , GENER                                                        as                INTERNAL_INDICATOR_CODING_GENERATED
      , VKALK                                                        as                          INDICATOR_ALLOWED_COSTING
      , VKAPA                                                        as            INDICATOR_ALLOWED_CAPACITY_REQUIREMENTS
      , VKAPF                                                        as                 INDICATOR_PRT_ALLOWED_REQUIREMENTS
      , VTERM                                                        as                       INDICATOR_ALLOWED_SCHEDULING
      , SPRAS                                                        as                                       LANGUAGE_KEY
      , TXT                                                          as                     WORK_CENTER_SHORT_FORMULA_TEXT
      , LOAD_DTS
    FROM SRC_b
)
---- RENAME LAYER ----

, RENAME_b as (
    SELECT
        CLIENT
      , WORK_CENTER_FORMULA
      , WORK_CENTER_FORMULA_TEXT1
      , WORK_CENTER_FORMULA_TEXT2
      , WORK_CENTER_FORMULA_TEXT3
      , INTERNAL_INDICATOR_CODING_GENERATED
      , INDICATOR_ALLOWED_COSTING
      , INDICATOR_ALLOWED_CAPACITY_REQUIREMENTS
      , INDICATOR_PRT_ALLOWED_REQUIREMENTS
      , INDICATOR_ALLOWED_SCHEDULING
      , LANGUAGE_KEY
      , WORK_CENTER_SHORT_FORMULA_TEXT
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
          CLIENT
        , WORK_CENTER_FORMULA
        , WORK_CENTER_FORMULA_TEXT1
        , WORK_CENTER_FORMULA_TEXT2
        , WORK_CENTER_FORMULA_TEXT3
        , INTERNAL_INDICATOR_CODING_GENERATED
        , INDICATOR_ALLOWED_COSTING
        , INDICATOR_ALLOWED_CAPACITY_REQUIREMENTS
        , INDICATOR_PRT_ALLOWED_REQUIREMENTS
        , INDICATOR_ALLOWED_SCHEDULING
        , LANGUAGE_KEY
        , WORK_CENTER_SHORT_FORMULA_TEXT
        , LOAD_DTS
FROM JOIN_RESULT
