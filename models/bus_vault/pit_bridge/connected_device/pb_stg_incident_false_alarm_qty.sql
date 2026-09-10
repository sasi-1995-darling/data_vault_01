{{ config(materialized='ephemeral') }}
---- SRC LAYER ----
WITH
SRC_B              as ( SELECT BKCC, DEVICE_ID, INCIDENT_CREATED_AT, INCIDENT_ID, IS_FALSE_ALARM, REC_SRC FROM {{ ref('pb_stg_incident_false_alarm_base') }} as SRC  )

/*
SRC_B              as ( SELECT * FROM BUS_VAULT.PB_STG_INCIDENT_FALSE_ALARM_BASE )
*/
---- LOGIC LAYER ----

, LOGIC_B as (
    SELECT
        INCIDENT_ID
      , DEVICE_ID
      , INCIDENT_CREATED_AT
      , IS_FALSE_ALARM
      , COALESCE(TO_NUMBER(TO_CHAR(DATE_TRUNC('QUARTER', INCIDENT_CREATED_AT)::DATE,'YYYYMMDD')),19000101) as                              PERIOD_START_DATE_KEY
      , BKCC
      , REC_SRC
    FROM SRC_B
)
---- RENAME LAYER ----

, RENAME_B as (
    SELECT
        INCIDENT_ID
      , DEVICE_ID
      , INCIDENT_CREATED_AT
      , IS_FALSE_ALARM
      , PERIOD_START_DATE_KEY
      , BKCC
      , REC_SRC
    FROM LOGIC_B
)
---- FILTER LAYER ----

, FILTER_B as (
    SELECT *
    FROM RENAME_B
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_B
)

---- FINAL LAYER ----
SELECT
          INCIDENT_ID
        , DEVICE_ID
        , INCIDENT_CREATED_AT
        , IS_FALSE_ALARM
        , 'QUARTERLY'                                                  as PERIOD_TYPE
        , PERIOD_START_DATE_KEY
        , YEAR(TO_DATE(PERIOD_START_DATE_KEY::STRING, 'YYYYMMDD'))     as YEAR_NUM
        , QUARTER(TO_DATE(PERIOD_START_DATE_KEY::STRING, 'YYYYMMDD'))  as QUARTER_NUM
        , MONTH(TO_DATE(PERIOD_START_DATE_KEY::STRING, 'YYYYMMDD'))    as MONTH_NUM
        , BKCC
        , REC_SRC
FROM JOIN_RESULT
