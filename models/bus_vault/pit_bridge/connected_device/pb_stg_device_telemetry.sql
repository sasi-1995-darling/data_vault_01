{{ config(materialized='ephemeral') }}
---- SRC LAYER ----
WITH
SRC_LCD            as ( SELECT DEVICE_HK, ICD_DEVICE_HK, PAIRED_DEVICE_HK, REC_SRC FROM {{ ref('lnk_icd_device') }} as SRC  ),
SRC_HP             as ( SELECT PAIRED_DEVICE_BK, PAIRED_DEVICE_HK FROM {{ ref('hub_paired_device') }} as SRC  ),
SRC_HD             as ( SELECT BKCC, DEVICE_BK, DEVICE_HK FROM {{ ref('hub_device_v2') }} as SRC  ),
SRC_SDT            as ( SELECT AGGREGATE_DATE, AVG_NIGHT_TEMPERATURE, AVG_PRESSURE, AVG_TEMPERATURE, CREATED_AT, DEVICE_HK, FLOW_RECORDS, GALLONS, MAX_GPM, MAX_PRESSURE, MAX_TEMPERATURE, MEDIAN_GPS, MIN_PRESSURE, MIN_TEMPERATURE, P_STATIC, RECORDS, UPDATED_AT FROM {{ ref('sat_device_telemetry__flo_daily') }} as SRC 
                        qualify 1= row_number() over(partition by DEVICE_HK, ID order by LOAD_DTS DESC) )

/*
SRC_LCD            as ( SELECT * FROM raw_vault.LNK_ICD_DEVICE )
SRC_HP             as ( SELECT * FROM raw_vault.HUB_PAIRED_DEVICE )
SRC_HD             as ( SELECT * FROM raw_vault.HUB_DEVICE_V2 )
SRC_SDT            as ( SELECT * FROM raw_vault.SAT_DEVICE_TELEMETRY__FLO_DAILY )
*/
---- LOGIC LAYER ----

, LOGIC_LCD as (
    SELECT
        ICD_DEVICE_HK
      , PAIRED_DEVICE_HK
      , DEVICE_HK
      , REC_SRC
    FROM SRC_LCD
)

, LOGIC_HP as (
    SELECT
        PAIRED_DEVICE_HK                                             as                                HP_PAIRED_DEVICE_HK
      , PAIRED_DEVICE_BK
    FROM SRC_HP
)

, LOGIC_HD as (
    SELECT
        DEVICE_HK                                                    as                                       HD_DEVICE_HK
      , DEVICE_BK
      , BKCC
    FROM SRC_HD
)

, LOGIC_SDT as (
    SELECT
        DEVICE_HK                                                    as                                      SDT_DEVICE_HK
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
    FROM SRC_SDT
)
---- RENAME LAYER ----

, RENAME_LCD as (
    SELECT
        ICD_DEVICE_HK
      , PAIRED_DEVICE_HK
      , DEVICE_HK
      , REC_SRC
    FROM LOGIC_LCD
)

, RENAME_HP as (
    SELECT
        HP_PAIRED_DEVICE_HK
      , PAIRED_DEVICE_BK
    FROM LOGIC_HP
)

, RENAME_HD as (
    SELECT
        HD_DEVICE_HK
      , DEVICE_BK
      , BKCC
    FROM LOGIC_HD
)

, RENAME_SDT as (
    SELECT
        SDT_DEVICE_HK
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
    FROM LOGIC_SDT
)
---- FILTER LAYER ----

, FILTER_LCD as (
    SELECT *
    FROM RENAME_LCD
)

, FILTER_HP as (
    SELECT *
    FROM RENAME_HP
)

, FILTER_HD as (
    SELECT *
    FROM RENAME_HD
)

, FILTER_SDT as (
    SELECT *
    FROM RENAME_SDT
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_LCD
    INNER JOIN FILTER_HP
        ON PAIRED_DEVICE_HK = HP_PAIRED_DEVICE_HK
    INNER JOIN FILTER_HD
        ON DEVICE_HK = HD_DEVICE_HK
    INNER JOIN FILTER_SDT
        ON DEVICE_HK = SDT_DEVICE_HK
)

---- FINAL LAYER ----
SELECT
          ICD_DEVICE_HK
        , PAIRED_DEVICE_HK
        , DEVICE_HK
        , PAIRED_DEVICE_BK
        , DEVICE_BK
        , BKCC
        , REC_SRC
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
FROM JOIN_RESULT
