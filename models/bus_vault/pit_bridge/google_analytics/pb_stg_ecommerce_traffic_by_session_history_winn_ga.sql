{{ config(materialized='ephemeral') }}
---- SRC LAYER ----
WITH
SRC_leap           as ( SELECT ECOMMERCE_ACCOUNT_HK, ECOMMERCE_PROPERTY_HK, LNK_ECOMMERCE_ACCOUNT_PROPERTY_HK FROM {{ ref('lnk_ecommerce_account_property') }} as SRC  ),
SRC_hea            as ( SELECT BKCC, ECOMMERCE_ACCOUNT_BK, ECOMMERCE_ACCOUNT_HK FROM {{ ref('hub_ecommerce_account') }} as SRC  ),
SRC_hep            as ( SELECT ECOMMERCE_PROPERTY_BK, ECOMMERCE_PROPERTY_HK FROM {{ ref('hub_ecommerce_property') }} as SRC  ),
SRC_lseah          as ( SELECT CURRENCY_CODE, LNK_ECOMMERCE_ACCOUNT_PROPERTY_HK, NAME, PROPERTY_TYPE, REC_SRC, SERVICE_LEVEL, TIME_ZONE 
                        FROM {{ ref('lsat_ecommerce_account_property_history__winn_google_analytics') }} as SRC  ),
SRC_sea            as ( SELECT ECOMMERCE_ACCOUNT_HK, REGION_CODE FROM {{ ref('sat_ecommerce_account__winn_google_analytics') }} as SRC  ),
SRC_septch         as ( SELECT DATE, ECOMMERCE_PROPERTY_HK, ENGAGED_SESSIONS, ENGAGEMENT_RATE, EVENT_COUNT, KEY_EVENTS, SESSIONS, SESSION_DEFAULT_CHANNEL_GROUPING, 
                        TOTAL_REVENUE, TOTAL_USERS FROM {{ ref('sat_ecommerce_property_traffic_by_channel_history__winn_google_analytics') }} as SRC  ),
SRC_pdtf           as ( SELECT DATE, DATE_BK, FISCAL_445_CAL_WEEK_YYYYWW FROM {{ ref('pit_date_fiscal_445') }} as SRC  )

/*
SRC_leap           as ( SELECT * FROM raw_vault.lnk_ecommerce_account_property )
SRC_hea            as ( SELECT * FROM raw_vault.hub_ecommerce_account )
SRC_hep            as ( SELECT * FROM raw_vault.hub_ecommerce_property )
SRC_lseah          as ( SELECT * FROM raw_vault.lsat_ecommerce_account_property_history__winn_google_analytics )
SRC_sea            as ( SELECT * FROM raw_vault.sat_ecommerce_account__winn_google_analytics )
SRC_septch         as ( SELECT * FROM raw_vault.sat_ecommerce_property_traffic_by_channel_history__winn_google_analytics )
SRC_pdtf           as ( SELECT * FROM bus_vault.pit_date_fiscal_445 )
*/
---- LOGIC LAYER ----

, LOGIC_leap as (
    SELECT
        LNK_ECOMMERCE_ACCOUNT_PROPERTY_HK
      , ECOMMERCE_ACCOUNT_HK
      , ECOMMERCE_PROPERTY_HK
    FROM SRC_leap
)

, LOGIC_hea as (
    SELECT
        ECOMMERCE_ACCOUNT_BK
      , BKCC
      , ECOMMERCE_ACCOUNT_HK                                         as                           HEA_ECOMMERCE_ACCOUNT_HK
    FROM SRC_hea
)

, LOGIC_hep as (
    SELECT
        ECOMMERCE_PROPERTY_BK
      , ECOMMERCE_PROPERTY_HK                                        as                          HEP_ECOMMERCE_PROPERTY_HK
    FROM SRC_hep
)

, LOGIC_lseah as (
    SELECT
        SERVICE_LEVEL                                                as                        ECOMMERCE_ANALYTICS_SERVICE
      , NAME                                                         as                              ECOMMERCE_PROPERTY_ID
      , PROPERTY_TYPE                                                as                            ECOMMERCE_PROPERTY_TYPE
      , TIME_ZONE                                                    as                        ECOMMERCE_PROPERTY_TIMEZONE
      , CURRENCY_CODE                                                as                   ECOMMERCE_PROPERTY_CURRENCY_CODE
      , REC_SRC
      , LNK_ECOMMERCE_ACCOUNT_PROPERTY_HK                            as            LSEAH_LNK_ECOMMERCE_ACCOUNT_PROPERTY_HK
    FROM SRC_lseah
)

, LOGIC_sea as (
    SELECT
        REGION_CODE                                                  as                          ECOMMERCE_ACCOUNT_COUNTRY
      , ECOMMERCE_ACCOUNT_HK                                         as                           SEA_ECOMMERCE_ACCOUNT_HK
    FROM SRC_sea
)

, LOGIC_septch as (
    SELECT
        SESSION_DEFAULT_CHANNEL_GROUPING                             as                              SESSION_CHANNEL_GROUP
      , SESSIONS
      , ENGAGEMENT_RATE
      , KEY_EVENTS
      , TOTAL_USERS
      , ENGAGED_SESSIONS
      , EVENT_COUNT
      , TOTAL_REVENUE
      , ECOMMERCE_PROPERTY_HK                                        as                       SEPTCH_ECOMMERCE_PROPERTY_HK
      , DATE                                                         as                                        SEPTCH_DATE
    FROM SRC_septch
)

, LOGIC_pdtf as (
    SELECT
        DATE_BK                                                      as                             SESSION_DATE__YYYYMMDD
      , DATE                                                         as                                          PDTF_DATE
      , FISCAL_445_CAL_WEEK_YYYYWW
      , MAX(PDTF_DATE) OVER (PARTITION BY FISCAL_445_CAL_WEEK_YYYYWW ORDER BY PDTF_DATE DESC) as                                   WEEK_ENDING_DATE
    FROM SRC_pdtf
)
---- RENAME LAYER ----

, RENAME_leap as (
    SELECT
        LNK_ECOMMERCE_ACCOUNT_PROPERTY_HK
      , ECOMMERCE_ACCOUNT_HK
      , ECOMMERCE_PROPERTY_HK
    FROM LOGIC_leap
)

, RENAME_hea as (
    SELECT
        ECOMMERCE_ACCOUNT_BK
      , BKCC
      , HEA_ECOMMERCE_ACCOUNT_HK
    FROM LOGIC_hea
)

, RENAME_hep as (
    SELECT
        ECOMMERCE_PROPERTY_BK
      , HEP_ECOMMERCE_PROPERTY_HK
    FROM LOGIC_hep
)

, RENAME_sea as (
    SELECT
        ECOMMERCE_ACCOUNT_COUNTRY
      , SEA_ECOMMERCE_ACCOUNT_HK
    FROM LOGIC_sea
)

, RENAME_lseah as (
    SELECT
        ECOMMERCE_ANALYTICS_SERVICE
      , ECOMMERCE_PROPERTY_ID
      , ECOMMERCE_PROPERTY_TYPE
      , ECOMMERCE_PROPERTY_TIMEZONE
      , ECOMMERCE_PROPERTY_CURRENCY_CODE
      , REC_SRC
      , LSEAH_LNK_ECOMMERCE_ACCOUNT_PROPERTY_HK
    FROM LOGIC_lseah
)

, RENAME_pdtf as (
    SELECT
        SESSION_DATE__YYYYMMDD
      , PDTF_DATE
      , FISCAL_445_CAL_WEEK_YYYYWW
      , WEEK_ENDING_DATE
    FROM LOGIC_pdtf
)

, RENAME_septch as (
    SELECT
        SESSION_CHANNEL_GROUP
      , SESSIONS
      , ENGAGEMENT_RATE
      , KEY_EVENTS
      , TOTAL_USERS
      , ENGAGED_SESSIONS
      , EVENT_COUNT
      , TOTAL_REVENUE
      , SEPTCH_ECOMMERCE_PROPERTY_HK
      , SEPTCH_DATE
    FROM LOGIC_septch
)
---- FILTER LAYER ----

, FILTER_leap as (
    SELECT *
    FROM RENAME_leap
)

, FILTER_hea as (
    SELECT *
    FROM RENAME_hea
)

, FILTER_hep as (
    SELECT *
    FROM RENAME_hep
)

, FILTER_lseah as (
    SELECT *
    FROM RENAME_lseah
    WHERE  REC_SRC <> 'USAZET.SNOWFLAKE.FBIN.DERIVED' /* This filter is to exclude the ghost records */
)

, FILTER_sea as (
    SELECT *
    FROM RENAME_sea
)

, FILTER_septch as (
    SELECT *
    FROM RENAME_septch
)

, FILTER_pdtf as (
    SELECT *
    FROM RENAME_pdtf
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_leap
    INNER JOIN FILTER_hea
        ON FILTER_leap.ECOMMERCE_ACCOUNT_HK = HEA_ECOMMERCE_ACCOUNT_HK
    INNER JOIN FILTER_hep
        ON FILTER_leap.ECOMMERCE_PROPERTY_HK = HEP_ECOMMERCE_PROPERTY_HK
    INNER JOIN FILTER_lseah
        ON FILTER_leap.LNK_ECOMMERCE_ACCOUNT_PROPERTY_HK = LSEAH_LNK_ECOMMERCE_ACCOUNT_PROPERTY_HK
    INNER JOIN FILTER_sea
        ON FILTER_leap.ECOMMERCE_ACCOUNT_HK = SEA_ECOMMERCE_ACCOUNT_HK
    INNER JOIN FILTER_septch
        ON FILTER_leap.ECOMMERCE_PROPERTY_HK = SEPTCH_ECOMMERCE_PROPERTY_HK
    LEFT JOIN FILTER_pdtf
        ON SEPTCH_DATE = PDTF_DATE
)

---- FINAL LAYER ----
SELECT
          LNK_ECOMMERCE_ACCOUNT_PROPERTY_HK
        , ECOMMERCE_ACCOUNT_HK
        , ECOMMERCE_ACCOUNT_BK
        , ECOMMERCE_PROPERTY_HK
        , ECOMMERCE_PROPERTY_BK
        , ECOMMERCE_ACCOUNT_COUNTRY
        , ECOMMERCE_ANALYTICS_SERVICE
        , ECOMMERCE_PROPERTY_ID
        , ECOMMERCE_PROPERTY_TYPE
        , ECOMMERCE_PROPERTY_TIMEZONE
        , SESSION_DATE__YYYYMMDD
        , to_char(WEEK_ENDING_DATE, 'YYYYMMDD')                        as WEEK_ENDING_DATEKEY
        , SESSION_CHANNEL_GROUP
        , SESSIONS
        , ENGAGEMENT_RATE
        , KEY_EVENTS
        , TOTAL_USERS
        , ENGAGED_SESSIONS
        , EVENT_COUNT
        , DIV0(EVENT_COUNT, SESSIONS)::DECIMAL(28,2)                   as EVENTS_PER_SESSION
        , DIV0(EVENT_COUNT, ENGAGED_SESSIONS)::DECIMAL(28,2)           as EVENTS_PER_ENGAGED_SESSION
        , DIV0(SESSIONS, TOTAL_USERS)::DECIMAL(28,2)                   as SESSIONS_PER_USER
        , TOTAL_REVENUE
        , ECOMMERCE_PROPERTY_CURRENCY_CODE
        , REC_SRC
        , BKCC
FROM JOIN_RESULT
