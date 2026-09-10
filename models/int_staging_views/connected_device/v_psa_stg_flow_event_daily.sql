---- SRC LAYER ----
WITH
SRC_D1             as ( SELECT AVG_FLOW_RATE, AVG_PRESSURE, CREATED_AT, DEVICE_ROLLUP_SURROGATE_ID, DEVICE_ID, END_TIMESTAMP, EVENT_COUNT, FIRST_EVENT_TIMESTAMP, LAST_EVENT_TIMESTAMP, LOAD_TIMESTAMP, MAX_FLOW_RATE, MAX_PRESSURE, MIN_PRESSURE, MONTH_CREATED, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, PSA_UPDATED_AT_DTS, START_TIMESTAMP, TOTAL_DURATION, TOTAL_GALLONS, TOTAL_RECORDS, UNIQUE_EVENT_COUNT, YEAR_CREATED FROM {{ source('flo_telemetry', 'flodetect_events_device_daily_agg_v') }} as SRC  ),
SRC_A1             as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_D1             as ( SELECT * FROM FLO_TELEMETRY.FLODETECT_EVENTS_DEVICE_DAILY_AGG_V )
SRC_A1             as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_D1 as (
    SELECT
        DEVICE_ID                                                    as                                          DEVICE_BK
      , CONVERT_TIMEZONE('UTC', LAST_EVENT_TIMESTAMP)                        as                                           LOAD_DTS
      , DEVICE_ROLLUP_SURROGATE_ID
      , CREATED_AT
      , MONTH_CREATED
      , YEAR_CREATED
      , START_TIMESTAMP
      , END_TIMESTAMP
      , EVENT_COUNT
      , TOTAL_RECORDS
      , TOTAL_DURATION
      , MAX_FLOW_RATE
      , AVG_FLOW_RATE
      , TOTAL_GALLONS
      , MIN_PRESSURE
      , AVG_PRESSURE
      , MAX_PRESSURE
      , FIRST_EVENT_TIMESTAMP
      , LAST_EVENT_TIMESTAMP
      , UNIQUE_EVENT_COUNT
      , LOAD_TIMESTAMP
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , PSA_UPDATED_AT_DTS
    FROM SRC_D1
)

, LOGIC_A1 as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_A1
)
---- RENAME LAYER ----

, RENAME_D1 as (
    SELECT
        DEVICE_BK
      , LOAD_DTS
      , DEVICE_ROLLUP_SURROGATE_ID
      , CREATED_AT
      , MONTH_CREATED
      , YEAR_CREATED
      , START_TIMESTAMP
      , END_TIMESTAMP
      , EVENT_COUNT
      , TOTAL_RECORDS
      , TOTAL_DURATION
      , MAX_FLOW_RATE
      , AVG_FLOW_RATE
      , TOTAL_GALLONS
      , MIN_PRESSURE
      , AVG_PRESSURE
      , MAX_PRESSURE
      , FIRST_EVENT_TIMESTAMP
      , LAST_EVENT_TIMESTAMP
      , UNIQUE_EVENT_COUNT
      , LOAD_TIMESTAMP
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , PSA_UPDATED_AT_DTS
    FROM LOGIC_D1
)

, RENAME_A1 as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_A1
)
---- FILTER LAYER ----

, FILTER_D1 as (
    SELECT *
    FROM RENAME_D1
)

, FILTER_A1 as (
    SELECT *
    FROM RENAME_A1
    WHERE rec_src = 'US.FLO_TELEMETRY.FLODETECT_EVENTS_DEVICE_DAILY_AGG'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_D1
    INNER JOIN FILTER_A1
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          DEVICE_BK
        , LOAD_DTS
        , DEVICE_ROLLUP_SURROGATE_ID
        , CREATED_AT
        , MONTH_CREATED
        , YEAR_CREATED
        , START_TIMESTAMP
        , END_TIMESTAMP
        , EVENT_COUNT
        , TOTAL_RECORDS
        , TOTAL_DURATION
        , MAX_FLOW_RATE
        , AVG_FLOW_RATE
        , TOTAL_GALLONS
        , MIN_PRESSURE
        , AVG_PRESSURE
        , MAX_PRESSURE
        , FIRST_EVENT_TIMESTAMP
        , LAST_EVENT_TIMESTAMP
        , UNIQUE_EVENT_COUNT
        , LOAD_TIMESTAMP
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , PSA_UPDATED_AT_DTS
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(DEVICE_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as DEVICE_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(DEVICE_ROLLUP_SURROGATE_ID::text), '^^') 
            , '||', IFNULL(TRIM(CREATED_AT::text), '^^') 
            , '||', IFNULL(TRIM(MONTH_CREATED::text), '^^') 
            , '||', IFNULL(TRIM(YEAR_CREATED::text), '^^') 
            , '||', IFNULL(TRIM(EVENT_COUNT::text), '^^') 
            , '||', IFNULL(TRIM(TOTAL_RECORDS::text), '^^') 
            , '||', IFNULL(TRIM(TOTAL_DURATION::text), '^^') 
            , '||', IFNULL(TRIM(MAX_FLOW_RATE::text), '^^') 
            , '||', IFNULL(TRIM(AVG_FLOW_RATE::text), '^^') 
            , '||', IFNULL(TRIM(TOTAL_GALLONS::text), '^^') 
            , '||', IFNULL(TRIM(MIN_PRESSURE::text), '^^') 
            , '||', IFNULL(TRIM(AVG_PRESSURE::text), '^^') 
            , '||', IFNULL(TRIM(MAX_PRESSURE::text), '^^') 
            , '||', IFNULL(TRIM(UNIQUE_EVENT_COUNT::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
