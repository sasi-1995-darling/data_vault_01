---- SRC LAYER ----
WITH
SRC_DLY            as ( SELECT ACTIVE_USER_COUNT, APP_SOURCE, BKCC, MONTH, PERIOD_START_DATE, PERIOD_TYPE, PLATFORM, QUARTER, REC_SRC, YEAR FROM {{ ref('pb_stg_active_user_daily') }} as SRC  ),
SRC_WKY            as ( SELECT ACTIVE_USER_COUNT, APP_SOURCE, BKCC, MONTH, PERIOD_START_DATE, PERIOD_TYPE, PLATFORM, QUARTER, REC_SRC, YEAR FROM {{ ref('pb_stg_active_user_weekly') }} as SRC  ),
SRC_MTY            as ( SELECT ACTIVE_USER_COUNT, APP_SOURCE, BKCC, MONTH, PERIOD_START_DATE, PERIOD_TYPE, PLATFORM, QUARTER, REC_SRC, YEAR FROM {{ ref('pb_stg_active_user_monthly') }} as SRC  ),
SRC_QTY            as ( SELECT ACTIVE_USER_COUNT, APP_SOURCE, BKCC, MONTH, PERIOD_START_DATE, PERIOD_TYPE, PLATFORM, QUARTER, REC_SRC, YEAR FROM {{ ref('pb_stg_active_user_quarterly') }} as SRC  )

/*
SRC_DLY            as ( SELECT * FROM BUS_VAULT.PB_STG_ACTIVE_USER_DAILY )
SRC_WKY            as ( SELECT * FROM BUS_VAULT.PB_STG_ACTIVE_USER_WEEKLY )
SRC_MTY            as ( SELECT * FROM BUS_VAULT.PB_STG_ACTIVE_USER_MONTHLY )
SRC_QTY            as ( SELECT * FROM BUS_VAULT.PB_STG_ACTIVE_USER_QUARTERLY )
*/
---- LOGIC LAYER ----

, LOGIC_DLY as (
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
    FROM SRC_DLY
)

, LOGIC_WKY as (
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
    FROM SRC_WKY
)

, LOGIC_MTY as (
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
    FROM SRC_MTY
)

, LOGIC_QTY as (
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
    FROM SRC_QTY
)
---- RENAME LAYER ----

, RENAME_DLY as (
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
    FROM LOGIC_DLY
)

, RENAME_WKY as (
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
    FROM LOGIC_WKY
)

, RENAME_MTY as (
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
    FROM LOGIC_MTY
)

, RENAME_QTY as (
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
    FROM LOGIC_QTY
)
---- FILTER LAYER ----

, FILTER_DLY as (
    SELECT *
    FROM RENAME_DLY
)

, FILTER_WKY as (
    SELECT *
    FROM RENAME_WKY
)

, FILTER_MTY as (
    SELECT *
    FROM RENAME_MTY
)

, FILTER_QTY as (
    SELECT *
    FROM RENAME_QTY
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_DLY
    UNION ALL
    SELECT * FROM FILTER_WKY
    UNION ALL
    SELECT * FROM FILTER_MTY
    UNION ALL
    SELECT * FROM FILTER_QTY
)

---- FINAL LAYER ----
SELECT
              row_number() over(order by 1)                            as SEQ_ID
        , CURRENT_DATE                                                 as SNAPSHOTDATE
        , CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP )                  as PB_LOAD_DTS
        , BKCC
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
