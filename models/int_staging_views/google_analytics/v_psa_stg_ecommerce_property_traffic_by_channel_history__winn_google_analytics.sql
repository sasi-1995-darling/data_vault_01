---- SRC LAYER ----
WITH
SRC_s              as ( SELECT DATE, ENGAGED_SESSIONS, ENGAGEMENT_RATE, EVENTS_PER_SESSION, EVENT_COUNT, KEY_EVENTS, PROPERTY, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, 
                        SESSIONS, SESSION_DEFAULT_CHANNEL_GROUPING, TOTAL_REVENUE, TOTAL_USERS, USER_ENGAGEMENT_DURATION, _FIVETRAN_ID, _FIVETRAN_SYNCED 
                        FROM {{ source('google_analytics_4_moen_dtc_historical', 'traffic_acquisition_session_default_channel_grouping_report') }} as SRC 
                        /*Filter to isolate applicable time period of historic Google Analytics data*/
                        WHERE DATE <= '2024-04-24' ),
SRC_a              as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  ),
SRC_p              as ( SELECT DISPLAY_NAME, NAME FROM {{ source('google_analytics_4_moen_dtc_historical', 'properties') }} as SRC
                        /* The following qualify clause is required to pull the first row pushed to PSA based on these PK columns*/
                        qualify 1 = row_number() over(partition by  display_name order by psa_load_dts )  )

/*
SRC_s              as ( SELECT * FROM google_analytics_4_moen_dtc_historical.traffic_acquisition_session_default_channel_grouping_report )
SRC_a              as ( SELECT * FROM raw_vault.ref_business_key_collision )
SRC_p              as ( SELECT * FROM google_analytics_4_moen_dtc_historical.properties )
*/
---- LOGIC LAYER ----

, LOGIC_s as (
    SELECT
        DATE
      , PROPERTY
      , _FIVETRAN_ID
      , SESSION_DEFAULT_CHANNEL_GROUPING
      , EVENTS_PER_SESSION
      , USER_ENGAGEMENT_DURATION
      , ENGAGEMENT_RATE
      , SESSIONS
      , KEY_EVENTS
      , TOTAL_USERS
      , ENGAGED_SESSIONS
      , EVENT_COUNT
      , _FIVETRAN_SYNCED
      , TOTAL_REVENUE
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
    FROM SRC_s
)

, LOGIC_a as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_a
)

, LOGIC_p as (
    SELECT
        DISPLAY_NAME
      , NAME                                                         as                                             P_NAME
    FROM SRC_p
)
---- RENAME LAYER ----

, RENAME_s as (
    SELECT
        DATE
      , PROPERTY
      , _FIVETRAN_ID
      , SESSION_DEFAULT_CHANNEL_GROUPING
      , EVENTS_PER_SESSION
      , USER_ENGAGEMENT_DURATION
      , ENGAGEMENT_RATE
      , SESSIONS
      , KEY_EVENTS
      , TOTAL_USERS
      , ENGAGED_SESSIONS
      , EVENT_COUNT
      , _FIVETRAN_SYNCED
      , TOTAL_REVENUE
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
    FROM LOGIC_s
)

, RENAME_p as (
    SELECT
        DISPLAY_NAME
      , P_NAME
    FROM LOGIC_p
)

, RENAME_a as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_a
)
---- FILTER LAYER ----

, FILTER_s as (
    SELECT *
    FROM RENAME_s
)

, FILTER_a as (
    SELECT *
    FROM RENAME_a
    WHERE rec_src = 'US.API.GOOGLE_ANALYTICS_WINN_DTC_HISTORICAL.TRAFFIC_ACQUISITION_SESSION_DEFAULT_CHANNEL_GROUPING_REPORT'
)

, FILTER_p as (
    SELECT *
    FROM RENAME_p
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_s
    INNER JOIN FILTER_a
        ON '1' = '1'
    LEFT JOIN FILTER_p
        ON FILTER_S.PROPERTY = P_NAME
)

---- FINAL LAYER ----
SELECT
          UPPER(TRIM(DISPLAY_NAME))                                    as ECOMMERCE_PROPERTY_BK
        , DATE
        , PROPERTY
        , DISPLAY_NAME
        , _FIVETRAN_ID
        , SESSION_DEFAULT_CHANNEL_GROUPING
        , EVENTS_PER_SESSION
        , USER_ENGAGEMENT_DURATION
        , ENGAGEMENT_RATE
        , SESSIONS
        , KEY_EVENTS
        , TOTAL_USERS
        , ENGAGED_SESSIONS
        , EVENT_COUNT
        , _FIVETRAN_SYNCED
        , TOTAL_REVENUE
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , CONVERT_TIMEZONE('UTC',_FIVETRAN_SYNCED)                     as LOAD_DTS
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ECOMMERCE_PROPERTY_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ECOMMERCE_PROPERTY_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(PROPERTY::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_ID::text), '^^') 
            , '||', IFNULL(TRIM(SESSION_DEFAULT_CHANNEL_GROUPING::text), '^^') 
            , '||', IFNULL(TRIM(EVENTS_PER_SESSION::text), '^^') 
            , '||', IFNULL(TRIM(USER_ENGAGEMENT_DURATION::text), '^^') 
            , '||', IFNULL(TRIM(ENGAGEMENT_RATE::text), '^^') 
            , '||', IFNULL(TRIM(SESSIONS::text), '^^') 
            , '||', IFNULL(TRIM(KEY_EVENTS::text), '^^') 
            , '||', IFNULL(TRIM(TOTAL_USERS::text), '^^') 
            , '||', IFNULL(TRIM(ENGAGED_SESSIONS::text), '^^') 
            , '||', IFNULL(TRIM(EVENT_COUNT::text), '^^') 
            , '||', IFNULL(TRIM(TOTAL_REVENUE::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
