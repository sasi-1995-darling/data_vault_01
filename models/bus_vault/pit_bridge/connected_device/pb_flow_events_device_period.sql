---- SRC LAYER ----
WITH
SRC_MTH            as ( SELECT BKCC, DEVICE_ID, MONTH_NUM, PERIOD_START_DATE_KEY, PERIOD_TYPE, QUARTER_NUM, REC_SRC, UNIQUE_EVENT_COUNT, YEAR_NUM FROM {{ ref('pb_stg_flow_events_mth') }} as SRC  ),
SRC_QTY            as ( SELECT BKCC, DEVICE_ID, MONTH_NUM, PERIOD_START_DATE_KEY, PERIOD_TYPE, QUARTER_NUM, REC_SRC, UNIQUE_EVENT_COUNT, YEAR_NUM FROM {{ ref('pb_stg_flow_events_qty') }} as SRC  ),
SRC_YLY            as ( SELECT BKCC, DEVICE_ID, MONTH_NUM, PERIOD_START_DATE_KEY, PERIOD_TYPE, QUARTER_NUM, REC_SRC, UNIQUE_EVENT_COUNT, YEAR_NUM FROM {{ ref('pb_stg_flow_events_yly') }} as SRC  )

/*
SRC_MTH            as ( SELECT * FROM BUS_VAULT.PB_STG_FLOW_EVENTS_MTH )
SRC_QTY            as ( SELECT * FROM BUS_VAULT.PB_STG_FLOW_EVENTS_QTY )
SRC_YLY            as ( SELECT * FROM BUS_VAULT.PB_STG_FLOW_EVENTS_YLY )
*/
---- LOGIC LAYER ----

, LOGIC_MTH as (
    SELECT
        DEVICE_ID
      , BKCC
      , REC_SRC
      , UNIQUE_EVENT_COUNT
      , PERIOD_TYPE
      , PERIOD_START_DATE_KEY
      , YEAR_NUM
      , QUARTER_NUM
      , MONTH_NUM
    FROM SRC_MTH
)

, LOGIC_QTY as (
    SELECT
        DEVICE_ID
      , BKCC
      , REC_SRC
      , UNIQUE_EVENT_COUNT
      , PERIOD_TYPE
      , PERIOD_START_DATE_KEY
      , YEAR_NUM
      , QUARTER_NUM
      , MONTH_NUM
    FROM SRC_QTY
)

, LOGIC_YLY as (
    SELECT
        DEVICE_ID
      , BKCC
      , REC_SRC
      , UNIQUE_EVENT_COUNT
      , PERIOD_TYPE
      , PERIOD_START_DATE_KEY
      , YEAR_NUM
      , QUARTER_NUM
      , MONTH_NUM
    FROM SRC_YLY
)
---- RENAME LAYER ----

, RENAME_MTH as (
    SELECT
        DEVICE_ID
      , BKCC
      , REC_SRC
      , UNIQUE_EVENT_COUNT
      , PERIOD_TYPE
      , PERIOD_START_DATE_KEY
      , YEAR_NUM
      , QUARTER_NUM
      , MONTH_NUM
    FROM LOGIC_MTH
)

, RENAME_QTY as (
    SELECT
        DEVICE_ID
      , BKCC
      , REC_SRC
      , UNIQUE_EVENT_COUNT
      , PERIOD_TYPE
      , PERIOD_START_DATE_KEY
      , YEAR_NUM
      , QUARTER_NUM
      , MONTH_NUM
    FROM LOGIC_QTY
)

, RENAME_YLY as (
    SELECT
        DEVICE_ID
      , BKCC
      , REC_SRC
      , UNIQUE_EVENT_COUNT
      , PERIOD_TYPE
      , PERIOD_START_DATE_KEY
      , YEAR_NUM
      , QUARTER_NUM
      , MONTH_NUM
    FROM LOGIC_YLY
)
---- FILTER LAYER ----

, FILTER_MTH as (
    SELECT *
    FROM RENAME_MTH
)

, FILTER_QTY as (
    SELECT *
    FROM RENAME_QTY
)

, FILTER_YLY as (
    SELECT *
    FROM RENAME_YLY
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_MTH
    UNION ALL
    SELECT * FROM FILTER_QTY
    UNION ALL
    SELECT * FROM FILTER_YLY
)

---- FINAL LAYER ----
SELECT
              row_number() over(order by 1)                            as SEQ_ID
        , CURRENT_DATE                                                 as SNAPSHOTDATE
        , CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP )                  as PB_LOAD_DTS
        , DEVICE_ID
        , BKCC
        , REC_SRC
        , UNIQUE_EVENT_COUNT
        , PERIOD_TYPE
        , PERIOD_START_DATE_KEY
        , YEAR_NUM
        , QUARTER_NUM
        , MONTH_NUM
FROM JOIN_RESULT
