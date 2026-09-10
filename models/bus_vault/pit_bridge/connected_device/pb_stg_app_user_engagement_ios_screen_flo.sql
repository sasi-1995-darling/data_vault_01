{{ config(materialized='ephemeral') }}
---- SRC LAYER ----
WITH
SRC_HUE            as ( SELECT BKCC, CONSUMER_BK, CONSUMER_HK, REC_SRC FROM {{ ref('hub_consumer') }} as SRC  ),
SRC_SSI            as ( SELECT ANONYMOUS_ID, CONSUMER_HK, CONTEXT_APP_NAME, CONTEXT_OS_NAME, CONTEXT_TRAITS_ANONYMOUS_ID, NAME, TIMESTAMP FROM {{ ref('sat_user_engagement_screen__ios_flo') }} as SRC 
                        qualify 1= row_number() over(partition by CONSUMER_HK, NAME order by RECEIVED_AT DESC , SENT_AT DESC,  TIMESTAMP DESC, LOAD_DTS DESC) )

/*
SRC_HUE            as ( SELECT * FROM raw_vault.HUB_CONSUMER )
SRC_SSI            as ( SELECT * FROM raw_vault.SAT_USER_ENGAGEMENT_SCREEN__IOS_FLO )
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

, LOGIC_SSI as (
    SELECT
        CONSUMER_HK                                                  as                                    SSI_CONSUMER_HK
      , CONTEXT_TRAITS_ANONYMOUS_ID                                  as                                    SCREEN_TRAIT_ID
      , ANONYMOUS_ID                                                 as                                 SCREEN_TRACKING_ID
      , NAME                                                         as                                        SCREEN_NAME
      , TIMESTAMP                                                    as                                   SCREEN_ACTION_TS
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
    FROM SRC_SSI
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

, RENAME_SSI as (
    SELECT
        SSI_CONSUMER_HK
      , SCREEN_TRAIT_ID
      , SCREEN_TRACKING_ID
      , SCREEN_NAME
      , SCREEN_ACTION_TS
      , PLATFORM
      , APP_SOURCE
      , CONTEXT_OS_NAME
      , CONTEXT_APP_NAME
    FROM LOGIC_SSI
)
---- FILTER LAYER ----

, FILTER_HUE as (
    SELECT *
    FROM RENAME_HUE
)

, FILTER_SSI as (
    SELECT *
    FROM RENAME_SSI
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_HUE
    INNER JOIN FILTER_SSI
        ON CONSUMER_HK = SSI_CONSUMER_HK
)

---- FINAL LAYER ----
SELECT
          CONSUMER_HK
        , CONSUMER_BK
        , BKCC
        , REC_SRC
        , SCREEN_TRAIT_ID
        , SCREEN_TRACKING_ID
        , SCREEN_NAME
        , SCREEN_ACTION_TS
        , PLATFORM
        , APP_SOURCE
FROM JOIN_RESULT
