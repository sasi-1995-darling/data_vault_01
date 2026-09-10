---- SRC LAYER ----
WITH
SRC_FD             as ( SELECT * FROM {{ ref('v_psa_stg_flo_devices') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_FD             as ( SELECT * FROM staging.v_psa_stg_flo_devices )
*/
---- LOGIC LAYER ----

, LOGIC_FD as (
    SELECT
        DEVICE_HK
      , LOAD_DTS
      , FW_VER
      , IS_CONNECTED
      , FW_PROPERTIES_RAW
      , CREATED_TIME
      , LAST_HEARD_FROM_TIME
      , UPDATED_TIME
      , MAKE
      , MODEL
      , VALVE_LATEST
      , MODE_LATEST
      , HW_THRESHOLDS
      , MUTE_AUDIO_UNTIL
      , COMPONENT_HEALTH
      , FW_PROPERTIES_REQ
      , FW_HEALTH_TEST_ON
      , VALVE_STATE_META
      , MOBILE_CONNECTIVITY
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM SRC_FD
)
---- RENAME LAYER ----

, RENAME_FD as (
    SELECT
        DEVICE_HK
      , LOAD_DTS
      , FW_VER
      , IS_CONNECTED
      , FW_PROPERTIES_RAW
      , CREATED_TIME
      , LAST_HEARD_FROM_TIME
      , UPDATED_TIME
      , MAKE
      , MODEL
      , VALVE_LATEST
      , MODE_LATEST
      , HW_THRESHOLDS
      , MUTE_AUDIO_UNTIL
      , COMPONENT_HEALTH
      , FW_PROPERTIES_REQ
      , FW_HEALTH_TEST_ON
      , VALVE_STATE_META
      , MOBILE_CONNECTIVITY
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM LOGIC_FD
)
---- FILTER LAYER ----

, FILTER_FD as (
    SELECT *
    FROM RENAME_FD
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_FD
)

---- FINAL LAYER ----
SELECT
          DEVICE_HK
        , LOAD_DTS
        , FW_VER
        , IS_CONNECTED
        , FW_PROPERTIES_RAW
        , CREATED_TIME
        , LAST_HEARD_FROM_TIME
        , UPDATED_TIME
        , MAKE
        , MODEL
        , VALVE_LATEST
        , MODE_LATEST
        , HW_THRESHOLDS
        , MUTE_AUDIO_UNTIL
        , COMPONENT_HEALTH
        , FW_PROPERTIES_REQ
        , FW_HEALTH_TEST_ON
        , VALVE_STATE_META
        , MOBILE_CONNECTIVITY
        , _FIVETRAN_DELETED
        , _FIVETRAN_SYNCED
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
    WHERE existing.DEVICE_HK = JOIN_RESULT.DEVICE_HK
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %} 

{% if not is_incremental() %}
qualify 1= row_number()over(partition by DEVICE_HK, HASHDIFF order by LOAD_DTS) 
union all
SELECT
MD5_BINARY(GR.VALUE) AS DEVICE_HK
,CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)  AS LOAD_DTS
,null as FW_VER
,null as IS_CONNECTED	
,null as FW_PROPERTIES_RAW		
,null as CREATED_TIME	
,null as LAST_HEARD_FROM_TIME	
,null as UPDATED_TIME		
,null as MAKE	
,null as MODEL	
,null as VALVE_LATEST	
,null as MODE_LATEST	
,null as HW_THRESHOLDS	
,null as MUTE_AUDIO_UNTIL	
,null as COMPONENT_HEALTH	
,null as FW_PROPERTIES_REQ	
,null as FW_HEALTH_TEST_ON	
,null as VALVE_STATE_META	
,null as MOBILE_CONNECTIVITY	
,null as _FIVETRAN_DELETED	
,null as _FIVETRAN_SYNCED
,null as PSA_LOAD_DTS
,null as PSA_RECORD_SOURCE
,null as PSA_DELETE_IND		
, DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS BKCC
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
, ''::BINARY as HASHDIFF
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR

{% endif %}