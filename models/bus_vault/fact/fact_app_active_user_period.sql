---- SRC LAYER ----
WITH
SRC_PB             as ( SELECT ACTIVE_USER_COUNT, APP_SOURCE, BKCC, MONTH, PERIOD_START_DATE, PERIOD_TYPE, PLATFORM, QUARTER, REC_SRC, YEAR FROM {{ ref('pb_app_active_user_period') }} as SRC  )

/*
SRC_PB             as ( SELECT * FROM BUS_VAULT.PB_APP_ACTIVE_USER_PERIOD )
*/
---- LOGIC LAYER ----

, LOGIC_PB as (
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
    FROM SRC_PB
)
---- RENAME LAYER ----

, RENAME_PB as (
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
    FROM LOGIC_PB
)
---- FILTER LAYER ----

, FILTER_PB as (
    SELECT *
    FROM RENAME_PB
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_PB
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
