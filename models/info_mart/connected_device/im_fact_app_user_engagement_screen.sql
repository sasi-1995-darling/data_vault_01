{{ config(alias='fact_app_user_engagement_screen') }}
---- SRC LAYER ----
WITH
SRC_FUE            as ( SELECT APP_SOURCE, BKCC, CONSUMER_BK, CONSUMER_HK, PLATFORM, REC_SRC, SCREEN_ACTION_TS, SCREEN_NAME, SCREEN_TRACKING_ID, SCREEN_TRAIT_ID FROM {{ ref('fact_app_user_engagement_screen') }} as SRC  )

/*
SRC_FUE            as ( SELECT * FROM BUS_VAULT.FACT_APP_USER_ENGAGEMENT_SCREEN )
*/
---- LOGIC LAYER ----

, LOGIC_FUE as (
    SELECT
        CONSUMER_BK
      , BKCC
      , REC_SRC
      , CONSUMER_HK
      , SCREEN_TRAIT_ID
      , SCREEN_TRACKING_ID
      , SCREEN_NAME
      , SCREEN_ACTION_TS
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
      , SCREEN_TRAIT_ID
      , SCREEN_TRACKING_ID
      , SCREEN_NAME
      , SCREEN_ACTION_TS
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
        , SCREEN_TRAIT_ID
        , SCREEN_TRACKING_ID
        , SCREEN_NAME
        , SCREEN_ACTION_TS
        , PLATFORM
        , APP_SOURCE
FROM JOIN_RESULT
