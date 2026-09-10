---- SRC LAYER ----
WITH
SRC_b              as ( SELECT KTEXT, LOAD_DTS, MANDT, SPRAS, VERWE FROM {{ ref('v_psa_stg_work_center_category__winn_sap') }} as SRC  )

/*
SRC_b              as ( SELECT * FROM staging.V_PSA_STG_WORK_CENTER_CATEGORY__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_b as (
    SELECT
        VERWE                                                        as                               WORK_CENTER_CATEGORY
      , MANDT                                                        as                                             CLIENT
      , SPRAS                                                        as                                       LANGUAGE_KEY
      , KTEXT                                                        as                          WORK_CENTER_CATEGORY_TEXT
      , LOAD_DTS
    FROM SRC_b
)
---- RENAME LAYER ----

, RENAME_b as (
    SELECT
        WORK_CENTER_CATEGORY
      , CLIENT
      , LANGUAGE_KEY
      , WORK_CENTER_CATEGORY_TEXT
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
          WORK_CENTER_CATEGORY
        , CLIENT
        , LANGUAGE_KEY
        , WORK_CENTER_CATEGORY_TEXT
        , LOAD_DTS
FROM JOIN_RESULT
