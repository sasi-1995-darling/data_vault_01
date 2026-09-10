---- SRC LAYER ----
WITH
SRC_D1             as ( SELECT AGGREGATE_DATE, AVG_NIGHT_TEMPERATURE, AVG_PRESSURE, AVG_TEMPERATURE, CREATED_AT, DEVICE_ID, FLOW_RECORDS, GALLONS, ID, MAX_GPM, MAX_PRESSURE, MAX_TEMPERATURE, MEDIAN_GPS, MIN_PRESSURE, MIN_TEMPERATURE, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, P_STATIC, RECORDS, UPDATED_AT FROM {{ source('flo_telemetry', 'flo_device_daily') }} as SRC  ),
SRC_A1             as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_D1             as ( SELECT * FROM flo_telemetry.flo_device_daily )
SRC_A1             as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_D1 as (
    SELECT
        DEVICE_ID                                                    as                                          DEVICE_BK
      , ID
      , AGGREGATE_DATE
      , GALLONS
      , MAX_GPM
      , MIN_PRESSURE
      , MAX_PRESSURE
      , AVG_PRESSURE
      , MIN_TEMPERATURE
      , MAX_TEMPERATURE
      , AVG_TEMPERATURE
      , RECORDS
      , FLOW_RECORDS
      , AVG_NIGHT_TEMPERATURE
      , CREATED_AT
      , UPDATED_AT
      , MEDIAN_GPS
      , P_STATIC
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
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
      , ID
      , AGGREGATE_DATE
      , GALLONS
      , MAX_GPM
      , MIN_PRESSURE
      , MAX_PRESSURE
      , AVG_PRESSURE
      , MIN_TEMPERATURE
      , MAX_TEMPERATURE
      , AVG_TEMPERATURE
      , RECORDS
      , FLOW_RECORDS
      , AVG_NIGHT_TEMPERATURE
      , CREATED_AT
      , UPDATED_AT
      , MEDIAN_GPS
      , P_STATIC
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
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
    WHERE rec_src = 'US.FLO_TELEMETRY.FLO_DEVICE_DAILY'
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
        , CONVERT_TIMEZONE('UTC', PSA_LOAD_DTS)                        as LOAD_DTS
        , ID
        , AGGREGATE_DATE
        , GALLONS
        , MAX_GPM
        , MIN_PRESSURE
        , MAX_PRESSURE
        , AVG_PRESSURE
        , MIN_TEMPERATURE
        , MAX_TEMPERATURE
        , AVG_TEMPERATURE
        , RECORDS
        , FLOW_RECORDS
        , AVG_NIGHT_TEMPERATURE
        , CREATED_AT
        , UPDATED_AT
        , MEDIAN_GPS
        , P_STATIC
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(DEVICE_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as DEVICE_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(AGGREGATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(GALLONS::text), '^^') 
            , '||', IFNULL(TRIM(MAX_GPM::text), '^^') 
            , '||', IFNULL(TRIM(MIN_PRESSURE::text), '^^') 
            , '||', IFNULL(TRIM(MAX_PRESSURE::text), '^^') 
            , '||', IFNULL(TRIM(AVG_PRESSURE::text), '^^') 
            , '||', IFNULL(TRIM(MIN_TEMPERATURE::text), '^^') 
            , '||', IFNULL(TRIM(MAX_TEMPERATURE::text), '^^') 
            , '||', IFNULL(TRIM(AVG_TEMPERATURE::text), '^^') 
            , '||', IFNULL(TRIM(RECORDS::text), '^^') 
            , '||', IFNULL(TRIM(FLOW_RECORDS::text), '^^') 
            , '||', IFNULL(TRIM(AVG_NIGHT_TEMPERATURE::text), '^^') 
            , '||', IFNULL(TRIM(CREATED_AT::text), '^^') 
            , '||', IFNULL(TRIM(UPDATED_AT::text), '^^') 
            , '||', IFNULL(TRIM(MEDIAN_GPS::text), '^^') 
            , '||', IFNULL(TRIM(P_STATIC::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
