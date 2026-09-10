{{ config(materialized='ephemeral') }}
---- SRC LAYER ----
WITH
SRC_D              as ( SELECT BKCC, DEVICE_ID, MONTH_NUM, NUM_FLOW_EVENTS, PERIOD_START_DATE_KEY, PERIOD_TYPE, QUARTER_NUM, REC_SRC, YEAR_NUM FROM {{ ref('fact_flow_events_device_period') }} as SRC  ),
SRC_C              as ( SELECT BKCC, DEVICE_ID, IS_TELEMETRY_QUALIFIED, PERIOD_START_DATE_KEY, PERIOD_TYPE, REC_SRC, TELEMETRY_DAYS FROM {{ ref('fact_device_telemetry_coverage_period') }} as SRC  ),
SRC_N              as ( SELECT BKCC, DEVICE_ID, FALSE_ALARM_COUNT, PERIOD_START_DATE_KEY, PERIOD_TYPE, REC_SRC, TOTAL_ALERT_COUNT FROM {{ ref('fact_incident_false_alarm_device_period') }} as SRC  )

/*
SRC_D              as ( SELECT * FROM BUS_VAULT.FACT_FLOW_EVENTS_DEVICE_PERIOD )
SRC_C              as ( SELECT * FROM BUS_VAULT.FACT_DEVICE_TELEMETRY_COVERAGE_PERIOD )
SRC_N              as ( SELECT * FROM BUS_VAULT.FACT_INCIDENT_FALSE_ALARM_DEVICE_PERIOD )
*/
---- LOGIC LAYER ----

, LOGIC_D as (
    SELECT
        DEVICE_ID
      , PERIOD_TYPE
      , PERIOD_START_DATE_KEY
      , YEAR_NUM
      , QUARTER_NUM
      , MONTH_NUM
      , NUM_FLOW_EVENTS
      , BKCC                                                         as                                           BKCC_DEN
      , REC_SRC                                                      as                                        REC_SRC_DEN
    FROM SRC_D
)

, LOGIC_C as (
    SELECT
        DEVICE_ID                                                    as                                        C_DEVICE_ID
      , PERIOD_TYPE                                                  as                                      C_PERIOD_TYPE
      , PERIOD_START_DATE_KEY                                        as                            C_PERIOD_START_DATE_KEY
      , IS_TELEMETRY_QUALIFIED
      , BKCC                                                         as                                           BKCC_COV
      , REC_SRC                                                      as                                        REC_SRC_COV
      , TELEMETRY_DAYS
    FROM SRC_C
)

, LOGIC_N as (
    SELECT
        DEVICE_ID                                                    as                                        N_DEVICE_ID
      , PERIOD_TYPE                                                  as                                      N_PERIOD_TYPE
      , PERIOD_START_DATE_KEY                                        as                            N_PERIOD_START_DATE_KEY
      , TOTAL_ALERT_COUNT
      , FALSE_ALARM_COUNT
      , BKCC                                                         as                                           BKCC_NUM
      , REC_SRC                                                      as                                        REC_SRC_NUM
    FROM SRC_N
)
---- RENAME LAYER ----

, RENAME_D as (
    SELECT
        DEVICE_ID
      , PERIOD_TYPE
      , PERIOD_START_DATE_KEY
      , YEAR_NUM
      , QUARTER_NUM
      , MONTH_NUM
      , NUM_FLOW_EVENTS
      , BKCC_DEN
      , REC_SRC_DEN
    FROM LOGIC_D
)

, RENAME_C as (
    SELECT
        C_DEVICE_ID
      , C_PERIOD_TYPE
      , C_PERIOD_START_DATE_KEY
      , IS_TELEMETRY_QUALIFIED
      , BKCC_COV
      , REC_SRC_COV
      , TELEMETRY_DAYS
    FROM LOGIC_C
)

, RENAME_N as (
    SELECT
        N_DEVICE_ID
      , N_PERIOD_TYPE
      , N_PERIOD_START_DATE_KEY
      , TOTAL_ALERT_COUNT
      , FALSE_ALARM_COUNT
      , BKCC_NUM
      , REC_SRC_NUM
    FROM LOGIC_N
)
---- FILTER LAYER ----

, FILTER_D as (
    SELECT *
    FROM RENAME_D
)

, FILTER_C as (
    SELECT *
    FROM RENAME_C
)

, FILTER_N as (
    SELECT *
    FROM RENAME_N
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_D
    left join FILTER_C
    on FILTER_D.DEVICE_ID = FILTER_C.C_DEVICE_ID
    and FILTER_D.PERIOD_TYPE =  FILTER_C.C_PERIOD_TYPE
    and FILTER_D.PERIOD_START_DATE_KEY =  FILTER_C.C_PERIOD_START_DATE_KEY
    left join FILTER_N
    on FILTER_D.DEVICE_ID = FILTER_N.N_DEVICE_ID
    and FILTER_D.PERIOD_TYPE = FILTER_N.N_PERIOD_TYPE
    and FILTER_D.PERIOD_START_DATE_KEY = FILTER_N.N_PERIOD_START_DATE_KEY
)

---- FINAL LAYER ----
SELECT
          DEVICE_ID
        , PERIOD_TYPE
        , PERIOD_START_DATE_KEY
        , YEAR_NUM
        , QUARTER_NUM
        , MONTH_NUM
        , BKCC_DEN
        , REC_SRC_DEN
        , COALESCE(NUM_FLOW_EVENTS, 0)                                 as NUM_FLOW_EVENTS
        , IS_TELEMETRY_QUALIFIED
        , BKCC_COV
        , REC_SRC_COV
        , TELEMETRY_DAYS
        , BKCC_NUM
        , REC_SRC_NUM
        , COALESCE(FALSE_ALARM_COUNT, 0)                               as FALSE_ALARM_COUNT
        , COALESCE(TOTAL_ALERT_COUNT, 0)                               as TOTAL_ALERT_COUNT
        , CASE
  WHEN IS_TELEMETRY_QUALIFIED = 1
   AND NULLIF(TELEMETRY_DAYS, 0) IS NOT NULL
  THEN (COALESCE(FALSE_ALARM_COUNT, 0) / NULLIF(TELEMETRY_DAYS, 0)) * 30.437
END as DEVICE_FALSE_ALARMS_PER_MONTH
FROM JOIN_RESULT
