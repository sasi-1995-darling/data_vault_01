---- SRC LAYER ----
WITH
SRC_AF             as ( SELECT ALARM_HK, ALERT_FEEDBACK_HK, FLO_USER_HK, INCIDENT_HK, LOAD_DTS, PAIRED_DEVICE_HK, REC_SRC FROM {{ ref('v_psa_stg_alert_feedback') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY ALERT_FEEDBACK_HK ORDER BY LOAD_DTS))=1 )

/*
SRC_AF             as ( SELECT * FROM STAGING.v_psa_stg_alert_feedback )
*/
---- LOGIC LAYER ----

, LOGIC_AF as (
    SELECT
        ALERT_FEEDBACK_HK
      , INCIDENT_HK
      , ALARM_HK
      , PAIRED_DEVICE_HK
      , FLO_USER_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_AF
)
---- RENAME LAYER ----

, RENAME_AF as (
    SELECT
        ALERT_FEEDBACK_HK
      , INCIDENT_HK
      , ALARM_HK
      , PAIRED_DEVICE_HK
      , FLO_USER_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_AF
)
---- FILTER LAYER ----

, FILTER_AF as (
    SELECT *
    FROM RENAME_AF
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_AF
)

---- FINAL LAYER ----
SELECT
          ALERT_FEEDBACK_HK
        , INCIDENT_HK
        , ALARM_HK
        , PAIRED_DEVICE_HK
        , FLO_USER_HK
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.ALERT_FEEDBACK_HK = JOIN_RESULT.ALERT_FEEDBACK_HK
)
{% endif %}
--this is to consolidate records coming from 2 diff tables with the same bkcc
QUALIFY (ROW_NUMBER() OVER(PARTITION BY ALERT_FEEDBACK_HK ORDER BY LOAD_DTS))=1
{% if not is_incremental() %}

union all
SELECT 
 MD5_BINARY(GR.VALUE) AS ALERT_FEEDBACK_HK
, MD5_BINARY(GR.VALUE) AS INCIDENT_HK
, MD5_BINARY(GR.VALUE) AS ALARM_HK
, MD5_BINARY(GR.VALUE) AS PAIRED_DEVICE_HK
, MD5_BINARY(GR.VALUE) AS FLO_USER_HK
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)  AS LOAD_DTS
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}