{{ config(materialized='ephemeral') }}
---- SRC LAYER ----
WITH
SRC_B              as ( SELECT BKCC, DEVICE_ID, REC_SRC, TELEMETRY_DATE FROM {{ ref('pb_stg_device_telemetry_coverage_base') }} as SRC  )

/*
SRC_B              as ( SELECT * FROM BUS_VAULT.PB_STG_DEVICE_TELEMETRY_COVERAGE_BASE )
*/
---- LOGIC LAYER ----

, LOGIC_B as (
    SELECT
        DEVICE_ID
      , BKCC
      , REC_SRC
      , TELEMETRY_DATE
      , TO_NUMBER(TO_CHAR(DATE_TRUNC('YEAR',TELEMETRY_DATE)::DATE,'YYYYMMDD')) as                              PERIOD_START_DATE_KEY
      , DATE_TRUNC('YEAR', TELEMETRY_DATE)::DATE                     as                                  PERIOD_START_DATE
    FROM SRC_B
)
---- RENAME LAYER ----

, RENAME_B as (
    SELECT
        DEVICE_ID
      , BKCC
      , REC_SRC
      , TELEMETRY_DATE
      , PERIOD_START_DATE_KEY
      ,  PERIOD_START_DATE
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
          DEVICE_ID
        , BKCC
        , REC_SRC
        , TELEMETRY_DATE
        , 'YEARLY'                                                     as PERIOD_TYPE
        , PERIOD_START_DATE_KEY
        , EXTRACT(YEAR FROM PERIOD_START_DATE)                         as YEAR_NUM
        , EXTRACT(QUARTER FROM PERIOD_START_DATE)                      as QUARTER_NUM
        , EXTRACT(MONTH FROM PERIOD_START_DATE)                        as MONTH_NUM
FROM JOIN_RESULT
