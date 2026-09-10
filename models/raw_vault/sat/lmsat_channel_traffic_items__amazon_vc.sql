---- SRC LAYER ----
WITH
SRC_s              as ( SELECT ASIN, GLANCE_VIEWS, HASHDIFF, LOAD_DTS, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, REC_SRC, REPORT_END_DATE, REPORT_START_DATE, RUN_DATE, VENDORCENTRAL_ACCOUNT, CHANNEL_TRAFFIC_ITEM_LHK FROM {{ ref('v_psa_stg_channel_traffic_items__amazon_vc') }} as SRC 
                        {% if is_incremental() %}
                        WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}}){% endif %} )

/*
SRC_s              as ( SELECT * FROM STAGING.v_psa_stg_channel_traffic_items__amazon_vc )
*/
---- LOGIC LAYER ----

, LOGIC_s as (
    SELECT
        REPORT_START_DATE
      , REPORT_END_DATE
      , ASIN
      , GLANCE_VIEWS
      , RUN_DATE
      , VENDORCENTRAL_ACCOUNT
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , CHANNEL_TRAFFIC_ITEM_LHK
      , HASHDIFF
    FROM SRC_s
)
---- RENAME LAYER ----

, RENAME_s as (
    SELECT
        REPORT_START_DATE
      , REPORT_END_DATE
      , ASIN
      , GLANCE_VIEWS
      , RUN_DATE
      , VENDORCENTRAL_ACCOUNT
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , CHANNEL_TRAFFIC_ITEM_LHK
      , HASHDIFF
    FROM LOGIC_s
)
---- FILTER LAYER ----

, FILTER_s as (
    SELECT *
    FROM RENAME_s
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_s
)

---- FINAL LAYER ----
SELECT
          REPORT_START_DATE
        , REPORT_END_DATE
        , ASIN
        , GLANCE_VIEWS
        , RUN_DATE
        , VENDORCENTRAL_ACCOUNT
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , REC_SRC
        , CHANNEL_TRAFFIC_ITEM_LHK
        , HASHDIFF
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
SELECT 1 
FROM {{ this }} existing
WHERE existing.CHANNEL_TRAFFIC_ITEM_LHK = JOIN_RESULT.CHANNEL_TRAFFIC_ITEM_LHK AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %}
{% if not is_incremental() %}

/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per HK and hashdiff. */
qualify 1 = row_number() over (partition by CHANNEL_TRAFFIC_ITEM_LHK, HASHDIFF order by PSA_LOAD_DTS)

union all
SELECT 
NULL AS REPORT_START_DATE,
GR.VALUE::DATE AS REPORT_END_DATE,
GR.VALUE::text AS ASIN,
NULL AS GLANCE_VIEWS,
NULL AS RUN_DATE,
GR.VALUE::text AS VENDORCENTRAL_ACCOUNT,
NULL AS PSA_LOAD_DTS,
NULL AS PSA_RECORD_SOURCE,
NULL AS PSA_DELETE_IND,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC,
MD5_BINARY(GR.VALUE) AS CHANNEL_TRAFFIC_ITEM_LHK,
''::BINARY AS HASHDIFF
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}