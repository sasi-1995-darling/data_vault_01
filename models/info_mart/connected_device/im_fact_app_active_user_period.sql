{{ config(alias='fact_app_active_user_period') }}
---- SRC LAYER ----
WITH
SRC_AU             as ( SELECT ACTIVE_USER_COUNT, APP_SOURCE, BKCC, MONTH, PERIOD_START_DATE, PERIOD_TYPE, PLATFORM, QUARTER, REC_SRC, YEAR FROM {{ ref('fact_app_active_user_period') }} as SRC  )

/*
SRC_AU             as ( SELECT * FROM BUS_VAULT.FACT_APP_ACTIVE_USER_PERIOD )
*/
---- LOGIC LAYER ----

, LOGIC_AU as (
    SELECT
        BKCC
      , REC_SRC
      , PERIOD_TYPE
      , PERIOD_START_DATE
      , YEAR
      , MONTH
      , QUARTER
      , PLATFORM
      , APP_SOURCE
      , ACTIVE_USER_COUNT
    FROM SRC_AU
)
---- RENAME LAYER ----

, RENAME_AU as (
    SELECT
        BKCC
      , REC_SRC
      , PERIOD_TYPE
      , PERIOD_START_DATE
      , YEAR
      , MONTH
      , QUARTER
      , PLATFORM
      , APP_SOURCE
      , ACTIVE_USER_COUNT
    FROM LOGIC_AU
)
---- FILTER LAYER ----

, FILTER_AU as (
    SELECT *
    FROM RENAME_AU
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_AU
)

---- FINAL LAYER ----
SELECT
          BKCC
        , REC_SRC
        , PERIOD_TYPE
        , PERIOD_START_DATE
        , YEAR
        , MONTH
        , QUARTER
        , PLATFORM
        , APP_SOURCE
        , ACTIVE_USER_COUNT
FROM JOIN_RESULT
