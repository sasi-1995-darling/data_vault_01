---- SRC LAYER ----
WITH
SRC_b              as ( SELECT LOAD_DTS, PLANR, SPRAS, TXT FROM {{ ref('v_psa_stg_capacity_planner_group__winn_sap') }} as SRC 
                              qualify 1= row_number()over(partition by PLANR, SPRAS order by LOAD_DTS desc) )

/*
SRC_b              as ( SELECT * FROM staging.V_PSA_STG_CAPACITY_PLANNER_GROUP__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_b as (
    SELECT
        SPRAS                                                        as                                       LANGUAGE_KEY
      , PLANR                                                        as                             CAPACITY_PLANNER_GROUP
      , TXT                                                          as                        CAPACITY_PLANNER_GROUP_TEXT
      , LOAD_DTS
    FROM SRC_b
)
---- RENAME LAYER ----

, RENAME_b as (
    SELECT
        LANGUAGE_KEY
      , CAPACITY_PLANNER_GROUP
      , CAPACITY_PLANNER_GROUP_TEXT
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
        , CAPACITY_PLANNER_GROUP
        , CAPACITY_PLANNER_GROUP_TEXT
        , LOAD_DTS
FROM JOIN_RESULT
