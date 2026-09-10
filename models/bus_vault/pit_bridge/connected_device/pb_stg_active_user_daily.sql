{{ config(materialized='ephemeral') }}
---- SRC LAYER ----
WITH
SRC_DLY            as ( SELECT APP_SOURCE, BKCC, EVENT, EVENT_ACTION_TS, EVENT_TRACKING_ID, PLATFORM, REC_SRC FROM {{ ref('pb_app_user_engagement_event_au') }} as SRC 
                        WHERE EVENT <> 'audit'
                          AND APP_SOURCE IN ('FLO','MOEN') )

/*
SRC_DLY            as ( SELECT * FROM BUS_VAULT.PB_APP_USER_ENGAGEMENT_EVENT_AU  )
*/
---- LOGIC LAYER ----

, LOGIC_DLY as (
    SELECT
        BKCC
      , REC_SRC
      , PLATFORM
      , APP_SOURCE
      , EVENT_TRACKING_ID
      , EVENT
      , EVENT_ACTION_TS
    FROM SRC_DLY
)
---- RENAME LAYER ----

, RENAME_DLY as (
    SELECT
        BKCC
      , REC_SRC
      , PLATFORM
      , APP_SOURCE
      , EVENT_TRACKING_ID
      , EVENT
      , EVENT_ACTION_TS
    FROM LOGIC_DLY
)
---- FILTER LAYER ----

, FILTER_DLY as (
    SELECT *
    FROM RENAME_DLY
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_DLY
)

---- FINAL LAYER ----
SELECT
              row_number() over(order by 1)                            as SEQ_ID
        , CURRENT_DATE                                                 as SNAPSHOTDATE
        , CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP )                  as PB_LOAD_DTS
        , 'Daily'                                                      as PERIOD_TYPE
        , DATE_TRUNC('DAY', EVENT_ACTION_TS)::DATE                     as PERIOD_START_DATE
        , YEAR(PERIOD_START_DATE)                                      as YEAR
        , MONTH(PERIOD_START_DATE)                                     as MONTH
        , QUARTER(PERIOD_START_DATE)                                   as QUARTER
        , PLATFORM
        , APP_SOURCE
        , COUNT(DISTINCT EVENT_TRACKING_ID)                            as ACTIVE_USER_COUNT
        , MIN(BKCC)                                                    as BKCC
        , MIN(REC_SRC)                                                 as REC_SRC
FROM JOIN_RESULT
GROUP BY
    PERIOD_START_DATE,
    APP_SOURCE,
    PLATFORM,
    YEAR,
    MONTH,
    QUARTER