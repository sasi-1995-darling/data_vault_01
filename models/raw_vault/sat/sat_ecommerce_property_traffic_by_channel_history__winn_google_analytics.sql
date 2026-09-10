---- SRC LAYER ----
WITH
SRC_GAPTC          as ( SELECT * FROM {{ ref('v_psa_stg_ecommerce_property_traffic_by_channel_history__winn_google_analytics') }} as SRC 
                        {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %} )

/*
SRC_GAPTC          as ( SELECT * FROM STAGING.v_psa_stg_ecommerce_property_traffic_by_channel_history__winn_google_analytics )
*/
---- LOGIC LAYER ----

, LOGIC_GAPTC as (
    SELECT
        ECOMMERCE_PROPERTY_HK
      , DATE
      , PROPERTY
      , DISPLAY_NAME
      , _FIVETRAN_ID
      , SESSION_DEFAULT_CHANNEL_GROUPING
      , USER_ENGAGEMENT_DURATION
      , ENGAGEMENT_RATE
      , SESSIONS
      , KEY_EVENTS
      , TOTAL_USERS
      , ENGAGED_SESSIONS
      , EVENT_COUNT
      , EVENTS_PER_SESSION
      , _FIVETRAN_SYNCED
      , TOTAL_REVENUE
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , HASHDIFF
    FROM SRC_GAPTC
)
---- RENAME LAYER ----

, RENAME_GAPTC as (
    SELECT
        ECOMMERCE_PROPERTY_HK
      , DATE
      , PROPERTY
      , DISPLAY_NAME
      , _FIVETRAN_ID
      , SESSION_DEFAULT_CHANNEL_GROUPING
      , USER_ENGAGEMENT_DURATION
      , ENGAGEMENT_RATE
      , SESSIONS
      , KEY_EVENTS
      , TOTAL_USERS
      , ENGAGED_SESSIONS
      , EVENT_COUNT
      , EVENTS_PER_SESSION
      , _FIVETRAN_SYNCED
      , TOTAL_REVENUE
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , HASHDIFF
    FROM LOGIC_GAPTC
)
---- FILTER LAYER ----

, FILTER_GAPTC as (
    SELECT *
    FROM RENAME_GAPTC
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_GAPTC
)

---- FINAL LAYER ----
SELECT
          ECOMMERCE_PROPERTY_HK
        , DATE
        , PROPERTY
        , DISPLAY_NAME
        , _FIVETRAN_ID
        , SESSION_DEFAULT_CHANNEL_GROUPING
        , USER_ENGAGEMENT_DURATION
        , ENGAGEMENT_RATE
        , SESSIONS
        , KEY_EVENTS
        , TOTAL_USERS
        , ENGAGED_SESSIONS
        , EVENT_COUNT
        , EVENTS_PER_SESSION
        , _FIVETRAN_SYNCED
        , TOTAL_REVENUE
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , REC_SRC
        , HASHDIFF
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.ECOMMERCE_PROPERTY_HK = JOIN_RESULT.ECOMMERCE_PROPERTY_HK
    AND existing.SESSION_DEFAULT_CHANNEL_GROUPING = JOIN_RESULT.SESSION_DEFAULT_CHANNEL_GROUPING
    AND existing.DATE = JOIN_RESULT.DATE
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF	
)
{% endif %}
{% if not is_incremental() %}

/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per HK and hashdiff. */
qualify 1 = row_number() over (partition by PROPERTY, SESSION_DEFAULT_CHANNEL_GROUPING, DATE, HASHDIFF order by PSA_LOAD_DTS)

union all
SELECT 
MD5_BINARY(GR.VALUE) AS ECOMMERCE_PROPERTY_HK,
'1900-01-01' AS DATE,
GR.VALUE::text AS PROPERTY,
GR.VALUE::text AS DISPLAY_NAME,
NULL AS _FIVETRAN_ID,
GR.VALUE::text AS SESSION_DEFAULT_CHANNEL_GROUPING,
NULL AS USER_ENGAGEMENT_DURATION,
NULL AS ENGAGEMENT_RATE,
NULL AS SESSIONS,
NULL AS KEY_EVENTS,
NULL AS TOTAL_USERS,
NULL AS ENGAGED_SESSIONS,
NULL AS EVENT_COUNT,
NULL AS EVENTS_PER_SESSION,
NULL AS _FIVETRAN_SYNCED,
NULL AS TOTAL_REVENUE,
'1900-01-01'::TIMESTAMP AS PSA_LOAD_DTS,
NULL AS PSA_RECORD_SOURCE,
'N' AS PSA_DELETE_IND,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC,
''::BINARY AS HASHDIFF
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}