{{ config(materialized='ephemeral') }}
---- SRC LAYER ----
WITH
SRC_HD             as ( SELECT DEVICE_BK, DEVICE_HK FROM {{ ref('hub_device_v2') }} as SRC  ),
SRC_SFD            as ( SELECT BKCC, CREATED_AT, DEVICE_HK, DEVICE_ROLLUP_SURROGATE_ID, PSA_DELETE_IND, REC_SRC, UNIQUE_EVENT_COUNT FROM {{ ref('msat_flow_daily_agg__flodetect') }} as SRC 
                        qualify 1= row_number() over(partition by DEVICE_ROLLUP_SURROGATE_ID order by LOAD_DTS DESC) )

/*
SRC_HD             as ( SELECT * FROM raw_vault.HUB_DEVICE_V2 )
SRC_SFD            as ( SELECT * FROM raw_vault.MSAT_FLOW_DAILY_AGG__FLODETECT )
*/
---- LOGIC LAYER ----

, LOGIC_HD as (
    SELECT
        DEVICE_HK                                                    as                                       HD_DEVICE_HK
      , DEVICE_BK                                                    as                                          DEVICE_ID
    FROM SRC_HD
)

, LOGIC_SFD as (
    SELECT
        DEVICE_HK                                                    as                                      SFD_DEVICE_HK
      , DEVICE_ROLLUP_SURROGATE_ID
      , BKCC
      , REC_SRC
      , UNIQUE_EVENT_COUNT
      , CREATED_AT
      , PSA_DELETE_IND
    FROM SRC_SFD
)
---- RENAME LAYER ----

, RENAME_HD as (
    SELECT
        HD_DEVICE_HK
      , DEVICE_ID
    FROM LOGIC_HD
)

, RENAME_SFD as (
    SELECT
        SFD_DEVICE_HK
      , DEVICE_ROLLUP_SURROGATE_ID
      , BKCC
      , REC_SRC
      , UNIQUE_EVENT_COUNT
      , CREATED_AT
      , PSA_DELETE_IND
    FROM LOGIC_SFD
)
---- FILTER LAYER ----

, FILTER_HD as (
    SELECT *
    FROM RENAME_HD
)

, FILTER_SFD as (
    SELECT *
    FROM RENAME_SFD
    WHERE 
PSA_DELETE_IND <> 'Y'
AND REC_SRC = 'US.FLO_TELEMETRY.FLODETECT_EVENTS_DEVICE_DAILY_AGG'
AND BKCC = 'Dancing_Seal'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_HD
    INNER JOIN FILTER_SFD
        ON HD_DEVICE_HK = SFD_DEVICE_HK
)

---- FINAL LAYER ----
SELECT
          DEVICE_ID
        , BKCC
        , REC_SRC
        , UNIQUE_EVENT_COUNT
        , CASE
  WHEN REGEXP_LIKE(TRIM(TO_VARCHAR(CREATED_AT)), '^[0-9]{1,2}/[0-9]{1,2}/[0-9]{4}$')
  THEN DATE_FROM_PARTS(
    TRY_TO_NUMBER(SPLIT_PART(TRIM(TO_VARCHAR(CREATED_AT)), '/', 3)),
    TRY_TO_NUMBER(SPLIT_PART(TRIM(TO_VARCHAR(CREATED_AT)), '/', 1)),
    TRY_TO_NUMBER(SPLIT_PART(TRIM(TO_VARCHAR(CREATED_AT)), '/', 2))
  )
  WHEN REGEXP_LIKE(TRIM(TO_VARCHAR(CREATED_AT)), '^[0-9]{4}-[0-9]{2}-[0-9]{2}$')
  THEN TO_DATE(TRIM(TO_VARCHAR(CREATED_AT)))
  ELSE NULL
END as FLOW_DATE
        , EXTRACT(YEAR FROM FLOW_DATE)                                 as YEAR_NUM
        , PSA_DELETE_IND
FROM JOIN_RESULT
WHERE
DEVICE_ID IS NOT NULL
AND YEAR_NUM IS NOT NULL
AND YEAR_NUM >= 2000