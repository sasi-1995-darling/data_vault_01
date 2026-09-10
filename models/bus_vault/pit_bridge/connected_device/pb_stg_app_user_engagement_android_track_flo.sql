{{ config(materialized='ephemeral') }}
---- SRC LAYER ----
WITH
SRC_HUE            as ( SELECT BKCC, CONSUMER_BK, CONSUMER_HK, REC_SRC FROM {{ ref('hub_consumer') }} as SRC  ),
SRC_STA            as ( SELECT ANONYMOUS_ID, CONSUMER_HK, CONTEXT_APP_NAME, CONTEXT_OS_NAME, CONTEXT_TRAITS_ANONYMOUS_ID, EVENT, EVENT_TEXT, TIMESTAMP FROM {{ ref('sat_user_engagement_track__android_flo') }} as SRC 
                        qualify 1= row_number() over(partition by CONSUMER_HK, EVENT order by RECEIVED_AT DESC , SENT_AT DESC, TIMESTAMP DESC, LOAD_DTS DESC) )

/*
SRC_HUE            as ( SELECT * FROM raw_vault.HUB_CONSUMER )
SRC_STA            as ( SELECT * FROM raw_vault.SAT_USER_ENGAGEMENT_TRACK__ANDROID_FLO )
*/
---- LOGIC LAYER ----

, LOGIC_HUE as (
    SELECT
        CONSUMER_HK
      , CONSUMER_BK
      , BKCC
      , REC_SRC
    FROM SRC_HUE
)

, LOGIC_STA as (
    SELECT
        CONSUMER_HK                                                  as                                    STA_CONSUMER_HK
      , CONTEXT_TRAITS_ANONYMOUS_ID                                  as                                     EVENT_TRAIT_ID
      , ANONYMOUS_ID                                                 as                                  EVENT_TRACKING_ID
      , EVENT_TEXT                                                   as                                  EVENT_DESCRIPTION
      , EVENT
      , TIMESTAMP                                                    as                                    EVENT_ACTION_TS
      , CASE
            WHEN LOWER(CONTEXT_OS_NAME) LIKE '%android%' THEN 'ANDROID'
            WHEN LOWER(CONTEXT_OS_NAME) LIKE '%ios%'
            OR LOWER(CONTEXT_OS_NAME) LIKE '%ipados%' THEN 'IOS'
            ELSE 'UNKNOWN'
        END                                                          as                                           PLATFORM
      , CASE
            WHEN LOWER(CONTEXT_APP_NAME) LIKE '%flo%'  THEN 'FLO'
            WHEN LOWER(CONTEXT_APP_NAME) LIKE '%moen%' THEN 'MOEN'
            ELSE 'UNKNOWN'
        END                                                          as                                         APP_SOURCE
      , CONTEXT_OS_NAME
      , CONTEXT_APP_NAME
    FROM SRC_STA
)
---- RENAME LAYER ----

, RENAME_HUE as (
    SELECT
        CONSUMER_HK
      , CONSUMER_BK
      , BKCC
      , REC_SRC
    FROM LOGIC_HUE
)

, RENAME_STA as (
    SELECT
        STA_CONSUMER_HK
      , EVENT_TRAIT_ID
      , EVENT_TRACKING_ID
      , EVENT_DESCRIPTION
      , EVENT
      , EVENT_ACTION_TS
      , PLATFORM
      , APP_SOURCE
      , CONTEXT_OS_NAME
      , CONTEXT_APP_NAME
    FROM LOGIC_STA
)
---- FILTER LAYER ----

, FILTER_HUE as (
    SELECT *
    FROM RENAME_HUE
)

, FILTER_STA as (
    SELECT *
    FROM RENAME_STA
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_HUE
    INNER JOIN FILTER_STA
        ON CONSUMER_HK = STA_CONSUMER_HK
)

---- FINAL LAYER ----
SELECT
          CONSUMER_HK
        , CONSUMER_BK
        , BKCC
        , REC_SRC
        , EVENT_TRAIT_ID
        , EVENT_TRACKING_ID
        , EVENT_DESCRIPTION
        , EVENT
        , EVENT_ACTION_TS
        , PLATFORM
        , APP_SOURCE
FROM JOIN_RESULT
