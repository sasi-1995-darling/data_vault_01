---- SRC LAYER ----
WITH
SRC_ALM            as ( SELECT * FROM {{ ref('v_psa_stg_alarm') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_ALM            as ( SELECT * FROM staging.v_psa_stg_alarm )
*/
---- LOGIC LAYER ----

, LOGIC_ALM as (
    SELECT
        ALARM_HK
      , LOAD_DTS
      , NAME
      , SEVERITY
      , IS_INTERNAL
      , SEND_WHEN_VALVE_IS_CLOSED
      , ENABLED
      , MAX_DELIVERY_FREQUENCY
      , PARENT_ID
      , METADATA
      , USER_CONFIGURABLE
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , TAGS
      , USER_FEEDBACK_OPTIONS_ID
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM SRC_ALM
)
---- RENAME LAYER ----

, RENAME_ALM as (
    SELECT
        ALARM_HK
      , LOAD_DTS
      , NAME
      , SEVERITY
      , IS_INTERNAL
      , SEND_WHEN_VALVE_IS_CLOSED
      , ENABLED
      , MAX_DELIVERY_FREQUENCY
      , PARENT_ID
      , METADATA
      , USER_CONFIGURABLE
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , TAGS
      , USER_FEEDBACK_OPTIONS_ID
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM LOGIC_ALM
)
---- FILTER LAYER ----

, FILTER_ALM as (
    SELECT *
    FROM RENAME_ALM
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_ALM
)

---- FINAL LAYER ----
SELECT
          ALARM_HK
        , LOAD_DTS
        , NAME
        , SEVERITY
        , IS_INTERNAL
        , SEND_WHEN_VALVE_IS_CLOSED
        , ENABLED
        , MAX_DELIVERY_FREQUENCY
        , PARENT_ID
        , METADATA
        , USER_CONFIGURABLE
        , _FIVETRAN_DELETED
        , _FIVETRAN_SYNCED
        , TAGS
        , USER_FEEDBACK_OPTIONS_ID
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
    WHERE existing.ALARM_HK = JOIN_RESULT.ALARM_HK
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %} 
qualify 1= row_number()over(partition by ALARM_HK, HASHDIFF order by LOAD_DTS)
{% if not is_incremental() %}
union all
SELECT
MD5_BINARY(GR.VALUE) AS ALARM_HK
,CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)  AS LOAD_DTS
,null as NAME
,null as SEVERITY
,null as IS_INTERNAL
,null as SEND_WHEN_VALVE_IS_CLOSED
,null as ENABLED
,null as MAX_DELIVERY_FREQUENCY
,null as PARENT_ID
,null as METADATA
,null as USER_CONFIGURABLE
,null as _FIVETRAN_DELETED
,null as _FIVETRAN_SYNCED
,null as TAGS
,null as USER_FEEDBACK_OPTIONS_ID
,null as PSA_LOAD_DTS
,null as PSA_RECORD_SOURCE
,null as PSA_DELETE_IND
, DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS BKCC
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
, ''::BINARY as HASHDIFF
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR

{% endif %}