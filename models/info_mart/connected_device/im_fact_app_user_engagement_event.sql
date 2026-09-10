{{ config(alias='fact_app_user_engagement_event') }}
---- SRC LAYER ----
WITH
SRC_FUE            as ( SELECT APP_SOURCE, BKCC, CONSUMER_BK, CONSUMER_HK, EVENT, EVENT_ACTION_TS, EVENT_DESCRIPTION, EVENT_TRACKING_ID, EVENT_TRAIT_ID, PLATFORM, REC_SRC FROM {{ ref('fact_app_user_engagement_event') }} as SRC  )

/*
SRC_FUE            as ( SELECT * FROM BUS_VAULT.FACT_APP_USER_ENGAGEMENT_EVENT )
*/
---- LOGIC LAYER ----

, LOGIC_FUE as (
    SELECT
        CONSUMER_BK
      , BKCC
      , REC_SRC
      , CONSUMER_HK
      , EVENT_TRAIT_ID
      , EVENT_TRACKING_ID
      , EVENT_DESCRIPTION
      , EVENT
      , EVENT_ACTION_TS
      , PLATFORM
      , APP_SOURCE
    FROM SRC_FUE
)
---- RENAME LAYER ----

, RENAME_FUE as (
    SELECT
        CONSUMER_BK
      , BKCC
      , REC_SRC
      , CONSUMER_HK
      , EVENT_TRAIT_ID
      , EVENT_TRACKING_ID
      , EVENT_DESCRIPTION
      , EVENT
      , EVENT_ACTION_TS
      , PLATFORM
      , APP_SOURCE
    FROM LOGIC_FUE
)
---- FILTER LAYER ----

, FILTER_FUE as (
    SELECT *
    FROM RENAME_FUE
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_FUE
)

---- FINAL LAYER ----
SELECT
          CONSUMER_BK
        , BKCC
        , REC_SRC
        , CONSUMER_HK
        , EVENT_TRAIT_ID
        , EVENT_TRACKING_ID
        , EVENT_DESCRIPTION
        , EVENT
        , EVENT_ACTION_TS
        , PLATFORM
        , APP_SOURCE
FROM JOIN_RESULT
