{{ config(materialized='ephemeral') }}
---- SRC LAYER ----
WITH
SRC_HD             as ( SELECT DEVICE_BK, DEVICE_HK FROM {{ ref('hub_device_v2') }} as SRC  ),
SRC_SDT            as ( SELECT AGGREGATE_DATE, BKCC, DEVICE_HK, PSA_DELETE_IND, REC_SRC FROM {{ ref('sat_device_telemetry__flo_daily') }} as SRC 
                        qualify 1= row_number() over(partition by ID order by LOAD_DTS DESC) )

/*
SRC_HD             as ( SELECT * FROM raw_vault.HUB_DEVICE_V2 )
SRC_SDT            as ( SELECT * FROM raw_vault.SAT_DEVICE_TELEMETRY__FLO_DAILY )
*/
---- LOGIC LAYER ----

, LOGIC_HD as (
    SELECT
        DEVICE_HK                                                    as                                       HD_DEVICE_HK
      , DEVICE_BK                                                    as                                          DEVICE_ID
    FROM SRC_HD
)

, LOGIC_SDT as (
    SELECT
        DEVICE_HK                                                    as                                      SDT_DEVICE_HK
      , BKCC
      , REC_SRC
      , CASE
            WHEN REGEXP_LIKE(TRIM(AGGREGATE_DATE), '^[0-9]{1,2}/[0-9]{1,2}/[0-9]{4}$')
            THEN DATE_FROM_PARTS(
            TRY_TO_NUMBER(SPLIT_PART(TRIM(AGGREGATE_DATE), '/', 3)), -- YYYY
            TRY_TO_NUMBER(SPLIT_PART(TRIM(AGGREGATE_DATE), '/', 1)), -- MM
            TRY_TO_NUMBER(SPLIT_PART(TRIM(AGGREGATE_DATE), '/', 2))  -- DD
            )
            WHEN REGEXP_LIKE(TRIM(AGGREGATE_DATE), '^[0-9]{4}-[0-9]{2}-[0-9]{2}$')
            THEN TO_DATE(TRIM(AGGREGATE_DATE))
            ELSE NULL
        END                                                          as                                     TELEMETRY_DATE
      , AGGREGATE_DATE
      , PSA_DELETE_IND
    FROM SRC_SDT
)
---- RENAME LAYER ----

, RENAME_HD as (
    SELECT
        HD_DEVICE_HK
      , DEVICE_ID
    FROM LOGIC_HD
)

, RENAME_SDT as (
    SELECT
        SDT_DEVICE_HK
      , BKCC
      , REC_SRC
      , TELEMETRY_DATE
      , AGGREGATE_DATE
      , PSA_DELETE_IND
    FROM LOGIC_SDT
)
---- FILTER LAYER ----

, FILTER_HD as (
    SELECT *
    FROM RENAME_HD
)

, FILTER_SDT as (
    SELECT *
    FROM RENAME_SDT
    WHERE 
PSA_DELETE_IND <> 'Y'
AND REC_SRC = 'US.FLO_TELEMETRY.FLO_DEVICE_DAILY'
AND BKCC = 'Leaking_Water'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_HD
    INNER JOIN FILTER_SDT
        ON HD_DEVICE_HK = SDT_DEVICE_HK
)

---- FINAL LAYER ----
SELECT
          DEVICE_ID
        , BKCC
        , REC_SRC
        , TELEMETRY_DATE
        , PSA_DELETE_IND
FROM JOIN_RESULT
WHERE
DEVICE_ID IS NOT NULL
AND TELEMETRY_DATE IS NOT NULL
AND EXTRACT(YEAR FROM TELEMETRY_DATE) >= 2000