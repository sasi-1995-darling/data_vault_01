---- SRC LAYER ----
WITH
SRC_b              as ( SELECT LOAD_DTS, SPRAS, TXT, VERWE FROM {{ ref('v_psa_stg_task_list_usage__winn_sap') }} as SRC  )

/*
SRC_b              as ( SELECT * FROM staging.V_PSA_STG_TASK_LIST_USAGE__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_b as (
    SELECT
        VERWE                                                        as                                    TASK_LIST_USAGE
      , SPRAS                                                        as                                       LANGUAGE_KEY
      , TXT                                                         as                               TASK_LIST_USAGE_TEXT
      , LOAD_DTS
    FROM SRC_b
)
---- RENAME LAYER ----

, RENAME_b as (
    SELECT
        TASK_LIST_USAGE
      , LANGUAGE_KEY
      , TASK_LIST_USAGE_TEXT
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
          TASK_LIST_USAGE
        , LANGUAGE_KEY
        , TASK_LIST_USAGE_TEXT
        , LOAD_DTS
FROM JOIN_RESULT
