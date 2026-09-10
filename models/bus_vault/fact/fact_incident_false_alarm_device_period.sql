---- SRC LAYER ----
WITH
SRC_PB             as ( SELECT BKCC, DEVICE_ID, INCIDENT_ID, IS_FALSE_ALARM, MONTH_NUM, PERIOD_START_DATE_KEY, PERIOD_TYPE, QUARTER_NUM, REC_SRC, YEAR_NUM FROM {{ ref('pb_incident_false_alarm_period') }} as SRC  )

/*
SRC_PB             as ( SELECT * FROM BUS_VAULT.PB_INCIDENT_FALSE_ALARM_PERIOD )
*/
---- LOGIC LAYER ----

, LOGIC_PB as (
    SELECT
        INCIDENT_ID
      , DEVICE_ID
      , IS_FALSE_ALARM
      , PERIOD_TYPE
      , PERIOD_START_DATE_KEY
      , YEAR_NUM
      , QUARTER_NUM
      , MONTH_NUM
      , BKCC
      , REC_SRC
    FROM SRC_PB
)
---- RENAME LAYER ----

, RENAME_PB as (
    SELECT
        INCIDENT_ID
      , DEVICE_ID
      , IS_FALSE_ALARM
      , PERIOD_TYPE
      , PERIOD_START_DATE_KEY
      , YEAR_NUM
      , QUARTER_NUM
      , MONTH_NUM
      , BKCC
      , REC_SRC
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
        , COUNT(DISTINCT INCIDENT_ID)                                  as TOTAL_ALERT_COUNT
        , COUNT(DISTINCT CASE WHEN IS_FALSE_ALARM = 1 THEN INCIDENT_ID END) as FALSE_ALARM_COUNT
        , MIN(BKCC)                                                    as BKCC
        , MIN(REC_SRC)                                                 as REC_SRC
FROM JOIN_RESULT
GROUP BY
DEVICE_ID, 
PERIOD_TYPE,
PERIOD_START_DATE_KEY,
YEAR_NUM,
QUARTER_NUM,
MONTH_NUM