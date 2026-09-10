{{ config(alias='dim_survey_project') }}
---- SRC LAYER ----
WITH
SRC_PSP            as ( SELECT * FROM {{ ref('dim_survey_project') }} as SRC  )

/*
SRC_PSP            as ( SELECT * FROM BUS_VAULT.DIM_SURVEY_PROJECT )
*/
---- LOGIC LAYER ----

, LOGIC_PSP as (
    SELECT
        PROJECT_BK
      , BKCC
      , REC_SRC
    FROM SRC_PSP
)
---- RENAME LAYER ----

, RENAME_PSP as (
    SELECT
        PROJECT_BK
      , BKCC
      , REC_SRC
    FROM LOGIC_PSP
)
---- FILTER LAYER ----

, FILTER_PSP as (
    SELECT *
    FROM RENAME_PSP
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_PSP
)

---- FINAL LAYER ----
SELECT
          PROJECT_BK
        , BKCC
        , REC_SRC
FROM JOIN_RESULT
