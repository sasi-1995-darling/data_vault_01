---- SRC LAYER ----
WITH
SRC_INC            as ( SELECT * FROM {{ ref('v_psa_stg_incident') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_INC            as ( SELECT * FROM staging.v_psa_stg_incident )
*/
---- LOGIC LAYER ----

, LOGIC_INC as (
    SELECT
        INCIDENT_HK
      , LOAD_DTS
      , ACCOUNT_ID
      , ALARM_ID
      , CREATE_AT
      , DATA_VALUES
      , GROUP_ID
      , HEALTH_TEST_ROUND_ID
      , ICD_ID
      , LOCATION_ID
      , NEW_INCIDENT_REF
      , OLD_INCIDENT_REF
      , REASON
      , SNOOZE_TO
      , STATUS
      , SYSTEM_MODE
      , UPDATE_AT
      , TS_MS
      , EVENT_NAME
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM SRC_INC
)
---- RENAME LAYER ----

, RENAME_INC as (
    SELECT
        INCIDENT_HK
      , LOAD_DTS
      , ACCOUNT_ID
      , ALARM_ID
      , CREATE_AT
      , DATA_VALUES
      , GROUP_ID
      , HEALTH_TEST_ROUND_ID
      , ICD_ID
      , LOCATION_ID
      , NEW_INCIDENT_REF
      , OLD_INCIDENT_REF
      , REASON
      , SNOOZE_TO
      , STATUS
      , SYSTEM_MODE
      , UPDATE_AT
      , TS_MS
      , EVENT_NAME
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM LOGIC_INC
)
---- FILTER LAYER ----

, FILTER_INC as (
    SELECT *
    FROM RENAME_INC
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_INC
)

---- FINAL LAYER ----
SELECT
          INCIDENT_HK
        , LOAD_DTS
        , ACCOUNT_ID
        , ALARM_ID
        , CREATE_AT
        , DATA_VALUES
        , GROUP_ID
        , HEALTH_TEST_ROUND_ID
        , ICD_ID
        , LOCATION_ID
        , NEW_INCIDENT_REF
        , OLD_INCIDENT_REF
        , REASON
        , SNOOZE_TO
        , STATUS
        , SYSTEM_MODE
        , UPDATE_AT
        , TS_MS
        , EVENT_NAME
        , REC_SRC
        , BKCC
        , HASHDIFF
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.INCIDENT_HK = JOIN_RESULT.INCIDENT_HK
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %} 
qualify 1= row_number()over(partition by INCIDENT_HK, HASHDIFF order by LOAD_DTS)
{% if not is_incremental() %}
union all
SELECT
MD5_BINARY(GR.VALUE) AS INCIDENT_HK
,CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)  AS LOAD_DTS
,null as ACCOUNT_ID
,null as ALARM_ID
,null as CREATE_AT
,null as DATA_VALUES
,null as GROUP_ID
,null as HEALTH_TEST_ROUND_ID
,null as ICD_ID
,null as LOCATION_ID
,null as NEW_INCIDENT_REF
,null as OLD_INCIDENT_REF
,null as REASON
,null as SNOOZE_TO
,null as STATUS
,null as SYSTEM_MODE
,null as UPDATE_AT
,null as TS_MS
,null as EVENT_NAME
, DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS BKCC
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
, ''::BINARY as HASHDIFF
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR

{% endif %}