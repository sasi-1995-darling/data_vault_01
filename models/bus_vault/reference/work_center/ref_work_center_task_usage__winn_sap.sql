---- SRC LAYER ----
WITH
SRC_b              as ( SELECT LOAD_DTS, MANDT, PLANV, SPRAS, TXT FROM {{ ref('v_psa_stg_work_center_task_usage__winn_sap') }} as SRC  )

/*
SRC_b              as ( SELECT * FROM staging.V_PSA_STG_WORK_CENTER_TASK_USAGE__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_b as (
    SELECT
        PLANV                                                        as                             WORK_CENTER_TASK_USAGE
      , MANDT                                                        as                                             CLIENT
      , SPRAS                                                        as                                       LANGUAGE_KEY
      , TXT                                                         as                        WORK_CENTER_TASK_USAGE_TEXT
      , LOAD_DTS
    FROM SRC_b
)
---- RENAME LAYER ----

, RENAME_b as (
    SELECT
        WORK_CENTER_TASK_USAGE
      , CLIENT
      , LANGUAGE_KEY
      , WORK_CENTER_TASK_USAGE_TEXT
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
          WORK_CENTER_TASK_USAGE
        , CLIENT
        , LANGUAGE_KEY
        , WORK_CENTER_TASK_USAGE_TEXT
        , LOAD_DTS
FROM JOIN_RESULT
