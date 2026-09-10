{{ config(materialized='ephemeral') }}
---- SRC LAYER ----
WITH
SRC_B              as ( SELECT BKCC, DEVICE_ID, FLOW_DATE, REC_SRC, UNIQUE_EVENT_COUNT FROM {{ ref('pb_stg_flow_events_base') }} as SRC  )

/*
SRC_B              as ( SELECT * FROM BUS_VAULT.PB_STG_FLOW_EVENTS_BASE )
*/
---- LOGIC LAYER ----

, LOGIC_B as (
    SELECT
        DEVICE_ID
      , BKCC
      , REC_SRC
      , FLOW_DATE
      , UNIQUE_EVENT_COUNT
      , TO_NUMBER(TO_CHAR(DATE_TRUNC('MONTH', FLOW_DATE)::DATE,'YYYYMMDD')) as                              PERIOD_START_DATE_KEY
      , EXTRACT(YEAR FROM DATE_TRUNC('MONTH', FLOW_DATE)::DATE)      as                                           YEAR_NUM
      , EXTRACT(QUARTER FROM DATE_TRUNC('MONTH', FLOW_DATE)::DATE)   as                                        QUARTER_NUM
      , EXTRACT(MONTH FROM DATE_TRUNC('MONTH', FLOW_DATE)::DATE)     as                                          MONTH_NUM
    FROM SRC_B
)
---- RENAME LAYER ----

, RENAME_B as (
    SELECT
        DEVICE_ID
      , BKCC
      , REC_SRC
      , FLOW_DATE
      , UNIQUE_EVENT_COUNT
      , PERIOD_START_DATE_KEY
      , YEAR_NUM
      , QUARTER_NUM
      , MONTH_NUM
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
        , FLOW_DATE
        , UNIQUE_EVENT_COUNT
        , 'MONTHLY'                                                    as PERIOD_TYPE
        , PERIOD_START_DATE_KEY
        , YEAR_NUM
        , QUARTER_NUM
        , MONTH_NUM
FROM JOIN_RESULT
