---- SRC LAYER ----
WITH
SRC_PB             as ( SELECT BKCC, DEVICE_ID, MONTH_NUM, PERIOD_START_DATE_KEY, PERIOD_TYPE, QUARTER_NUM, REC_SRC, UNIQUE_EVENT_COUNT, YEAR_NUM FROM {{ ref('pb_flow_events_device_period') }} as SRC  )

/*
SRC_PB             as ( SELECT * FROM BUS_VAULT.PB_FLOW_EVENTS_DEVICE_PERIOD )
*/
---- LOGIC LAYER ----

, LOGIC_PB as (
    SELECT
        DEVICE_ID
      , PERIOD_TYPE
      , PERIOD_START_DATE_KEY
      , YEAR_NUM
      , QUARTER_NUM
      , MONTH_NUM
      , BKCC
      , REC_SRC
      , UNIQUE_EVENT_COUNT
    FROM SRC_PB
)
---- RENAME LAYER ----

, RENAME_PB as (
    SELECT
        DEVICE_ID
      , PERIOD_TYPE
      , PERIOD_START_DATE_KEY
      , YEAR_NUM
      , QUARTER_NUM
      , MONTH_NUM
      , BKCC
      , REC_SRC
      , UNIQUE_EVENT_COUNT
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
          DEVICE_ID
        , PERIOD_TYPE
        , PERIOD_START_DATE_KEY
        , YEAR_NUM
        , QUARTER_NUM
        , MONTH_NUM
        , MIN(BKCC)                                                    as BKCC
        , MIN(REC_SRC)                                                 as REC_SRC
        , SUM(UNIQUE_EVENT_COUNT)                                      as NUM_FLOW_EVENTS
FROM JOIN_RESULT
GROUP BY 
DEVICE_ID,
PERIOD_TYPE,
PERIOD_START_DATE_KEY,
YEAR_NUM,
QUARTER_NUM,
MONTH_NUM