{{ config(materialized='ephemeral') }}
---- SRC LAYER ----
WITH
SRC_HP             as ( SELECT * FROM {{ ref('hub_project') }} as SRC  )

/*
SRC_HP             as ( SELECT * FROM RAW_VAULT.HUB_PROJECT )
*/
---- LOGIC LAYER ----

, LOGIC_HP as (
    SELECT
        PROJECT_HK
      , PROJECT_BK
      , BKCC
      , REC_SRC
    FROM SRC_HP
)
---- RENAME LAYER ----

, RENAME_HP as (
    SELECT
        PROJECT_HK
      , PROJECT_BK
      , BKCC
      , REC_SRC
    FROM LOGIC_HP
)
---- FILTER LAYER ----

, FILTER_HP as (
    SELECT *
    FROM RENAME_HP
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_HP
)

---- FINAL LAYER ----
SELECT
          PROJECT_HK
        , PROJECT_BK
        , BKCC
        , REC_SRC
FROM JOIN_RESULT
