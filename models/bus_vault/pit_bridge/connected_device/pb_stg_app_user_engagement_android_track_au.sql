{{ config(materialized='ephemeral') }}
---- SRC LAYER ----
WITH
SRC_HUE            as ( SELECT CONSUMER_BK, CONSUMER_HK FROM {{ ref('hub_consumer') }} as SRC  ),
SRC_STA            as ( SELECT ANONYMOUS_ID, CONSUMER_HK, CONTEXT_APP_NAME, CONTEXT_OS_NAME, CONTEXT_TRAITS_ANONYMOUS_ID, EVENT, EVENT_TEXT, REC_SRC, TIMESTAMP FROM {{ ref('sat_user_engagement_track__android_moen') }} as SRC 
                        WHERE REC_SRC = 'US.ANDROID_MOEN.TRACKS'
                        AND TIMESTAMP IS NOT NULL
                        AND TIMESTAMP <= DATEADD('day', 1, CURRENT_TIMESTAMP()::TIMESTAMP_NTZ)
                        qualify 1= row_number() over(partition by CONSUMER_HK, ANONYMOUS_ID, CONTEXT_TRAITS_ANONYMOUS_ID, EVENT, TIMESTAMP order by RECEIVED_AT DESC , SENT_AT DESC, LOAD_DTS DESC) ),
SRC_BK             as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC 
                        WHERE REC_SRC = 'US.ANDROID_MOEN.TRACKS' )

/*
SRC_HUE            as ( SELECT * FROM raw_vault.HUB_CONSUMER )
SRC_STA            as ( SELECT * FROM raw_vault.SAT_USER_ENGAGEMENT_TRACK__ANDROID_MOEN )
SRC_BK             as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_HUE as (
    SELECT
        CONSUMER_HK
      , CONSUMER_BK
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
      , REC_SRC
    FROM SRC_STA
)

, LOGIC_BK as (
    SELECT
        BKCC
      , REC_SRC                                                      as                                          B_REC_SRC
    FROM SRC_BK
)
---- RENAME LAYER ----

, RENAME_HUE as (
    SELECT
        CONSUMER_HK
      , CONSUMER_BK
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
      , REC_SRC
    FROM LOGIC_STA
)

, RENAME_BK as (
    SELECT
        BKCC
      , B_REC_SRC
    FROM LOGIC_BK
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

, FILTER_BK as (
    SELECT *
    FROM RENAME_BK
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_HUE
    INNER JOIN FILTER_STA
        ON CONSUMER_HK = STA_CONSUMER_HK
    INNER JOIN FILTER_BK
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          CONSUMER_HK
        , CONSUMER_BK
        , EVENT_TRAIT_ID
        , EVENT_TRACKING_ID
        , EVENT_DESCRIPTION
        , EVENT
        , EVENT_ACTION_TS
        , PLATFORM
        , APP_SOURCE
        , REC_SRC
        , BKCC
FROM JOIN_RESULT
