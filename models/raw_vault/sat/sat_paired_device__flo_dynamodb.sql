---- SRC LAYER ----
WITH
SRC_FD             as ( SELECT * FROM {{ ref('v_psa_stg_flo_device_icd') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_FD             as ( SELECT * FROM staging.v_psa_stg_flo_device_icd )
*/
---- LOGIC LAYER ----

, LOGIC_FD as (
    SELECT
        PAIRED_DEVICE_HK
      , LOAD_DTS
      , ID
      , _FIVETRAN_DELETED
      , IS_PAIRED
      , DEVICE_ID
      , LOCATION_ID
      , _FIVETRAN_SYNCED
      , IS_TEST_DEVICE
      , DEVICE_MODEL
      , NICKNAME
      , DEVICE_TYPE
      , SHOULD_INHERIT_SYSTEM_MODE
      , TARGET_VALVE_STATE
      , REVERT_MINUTES
      , REVERT_SCHEDULED_AT
      , REVERT_MODE
      , TARGET_SYSTEM_MODE
      , PRV_INSTALLATION
      , IRRIGATION_TYPE
      , PUCK_CONFIGURED_AT
      , INSTALLATION_POINT
      , PURCHASE_LOCATION
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
        PAIRED_DEVICE_HK
      , LOAD_DTS
      , ID
      , _FIVETRAN_DELETED
      , IS_PAIRED
      , DEVICE_ID
      , LOCATION_ID
      , _FIVETRAN_SYNCED
      , IS_TEST_DEVICE
      , DEVICE_MODEL
      , NICKNAME
      , DEVICE_TYPE
      , SHOULD_INHERIT_SYSTEM_MODE
      , TARGET_VALVE_STATE
      , REVERT_MINUTES
      , REVERT_SCHEDULED_AT
      , REVERT_MODE
      , TARGET_SYSTEM_MODE
      , PRV_INSTALLATION
      , IRRIGATION_TYPE
      , PUCK_CONFIGURED_AT
      , INSTALLATION_POINT
      , PURCHASE_LOCATION
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
          PAIRED_DEVICE_HK
        , LOAD_DTS
        , ID
        , _FIVETRAN_DELETED
        , IS_PAIRED
        , DEVICE_ID
        , LOCATION_ID
        , _FIVETRAN_SYNCED
        , IS_TEST_DEVICE
        , DEVICE_MODEL
        , NICKNAME
        , DEVICE_TYPE
        , SHOULD_INHERIT_SYSTEM_MODE
        , TARGET_VALVE_STATE
        , REVERT_MINUTES
        , REVERT_SCHEDULED_AT
        , REVERT_MODE
        , TARGET_SYSTEM_MODE
        , PRV_INSTALLATION
        , IRRIGATION_TYPE
        , PUCK_CONFIGURED_AT
        , INSTALLATION_POINT
        , PURCHASE_LOCATION
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
    WHERE existing.PAIRED_DEVICE_HK = JOIN_RESULT.PAIRED_DEVICE_HK 
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %} 

{% if not is_incremental() %}
qualify 1= row_number()over(partition by PAIRED_DEVICE_HK, HASHDIFF order by LOAD_DTS) 
union all
SELECT
MD5_BINARY(GR.VALUE) AS PAIRED_DEVICE_HK
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)  AS LOAD_DTS
, GR.VALUE::TEXT  as ID
, null  as _FIVETRAN_DELETED
, null  as IS_PAIRED
, null  as DEVICE_ID
, null  as LOCATION_ID
, null  as _FIVETRAN_SYNCED
, null  as IS_TEST_DEVICE
, null  as DEVICE_MODEL
, null  as NICKNAME
, null  as DEVICE_TYPE
, null  as SHOULD_INHERIT_SYSTEM_MODE
, null  as TARGET_VALVE_STATE
, null  as REVERT_MINUTES
, null  as REVERT_SCHEDULED_AT
, null  as REVERT_MODE
, null  as TARGET_SYSTEM_MODE
, null  as PRV_INSTALLATION
, null  as IRRIGATION_TYPE
, null  as PUCK_CONFIGURED_AT
, null  as INSTALLATION_POINT
, null  as PURCHASE_LOCATION
, null as PSA_LOAD_DTS
, null as PSA_RECORD_SOURCE
, null as PSA_DELETE_IND
, DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS BKCC
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
, ''::BINARY as HASH_DIFF
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR

{% endif %}