---- SRC LAYER ----
WITH
SRC_AF             as ( SELECT * FROM {{ ref('v_psa_stg_alert_feedback') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_AF             as ( SELECT * FROM staging.v_psa_stg_alert_feedback )
*/
---- LOGIC LAYER ----

, LOGIC_AF as (
    SELECT
        ALERT_FEEDBACK_HK
      , LOAD_DTS
      , ICD_ID
      , INCIDENT_ID
      , _FIVETRAN_SYNCED
      , SHOULD_ACCEPT_AS_NORMAL
      , USER_ID
      , CREATED_AT
      , ACTION_TAKEN
      , ALARM_ID
      , SYSTEM_MODE
      , CAUSE
      , _FIVETRAN_DELETED
      , CAUSE_OTHER
      , UPDATED_AT
      , PLUMBING_FAILURE
      , PLUMBING_FAILURE_OTHER
      , TEST_FEEDBACK_FOR_INCIDENT
      , DISMISS
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM SRC_AF
)
---- RENAME LAYER ----

, RENAME_AF as (
    SELECT
        ALERT_FEEDBACK_HK
      , LOAD_DTS
      , ICD_ID
      , INCIDENT_ID
      , _FIVETRAN_SYNCED
      , SHOULD_ACCEPT_AS_NORMAL
      , USER_ID
      , CREATED_AT
      , ACTION_TAKEN
      , ALARM_ID
      , SYSTEM_MODE
      , CAUSE
      , _FIVETRAN_DELETED
      , CAUSE_OTHER
      , UPDATED_AT
      , PLUMBING_FAILURE
      , PLUMBING_FAILURE_OTHER
      , TEST_FEEDBACK_FOR_INCIDENT
      , DISMISS
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
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
        , LOAD_DTS
        , ICD_ID
        , INCIDENT_ID
        , _FIVETRAN_SYNCED
        , SHOULD_ACCEPT_AS_NORMAL
        , USER_ID
        , CREATED_AT
        , ACTION_TAKEN
        , ALARM_ID
        , SYSTEM_MODE
        , CAUSE
        , _FIVETRAN_DELETED
        , CAUSE_OTHER
        , UPDATED_AT
        , PLUMBING_FAILURE
        , PLUMBING_FAILURE_OTHER
        , TEST_FEEDBACK_FOR_INCIDENT
        , DISMISS
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , REC_SRC
        , BKCC
        , HASHDIFF
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.ALERT_FEEDBACK_HK = JOIN_RESULT.ALERT_FEEDBACK_HK
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %} 
qualify 1= row_number()over(partition by ALERT_FEEDBACK_HK, HASHDIFF order by LOAD_DTS)
{% if not is_incremental() %}
union all
SELECT
MD5_BINARY(GR.VALUE) AS ALERT_FEEDBACK_HK
,CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)  AS LOAD_DTS
,null as ICD_ID
,null as INCIDENT_ID
,null as _FIVETRAN_SYNCED
,null as SHOULD_ACCEPT_AS_NORMAL
,null as USER_ID
,null as CREATED_AT
,null as ACTION_TAKEN
,null as ALARM_ID
,null as SYSTEM_MODE
,null as CAUSE
,null as _FIVETRAN_DELETED
,null as CAUSE_OTHER
,null as UPDATED_AT
,null as PLUMBING_FAILURE
,null as PLUMBING_FAILURE_OTHER
,null as TEST_FEEDBACK_FOR_INCIDENT
,null as DISMISS
,null as PSA_LOAD_DTS
,null as PSA_RECORD_SOURCE
,null as PSA_DELETE_IND
, DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS BKCC
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
, ''::BINARY as HASHDIFF
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR

{% endif %}