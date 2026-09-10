---- SRC LAYER ----
WITH
SRC_D1             as ( SELECT COMPONENT_HEALTH, CREATED_TIME, DEVICE_ID, FW_HEALTH_TEST_ON, FW_PROPERTIES_RAW, FW_PROPERTIES_REQ, FW_VER, HW_THRESHOLDS, IS_CONNECTED, LAST_HEARD_FROM_TIME, MAKE, MOBILE_CONNECTIVITY, MODEL, MODE_LATEST, MUTE_AUDIO_UNTIL, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, UPDATED_TIME, VALVE_LATEST, VALVE_STATE_META, _FIVETRAN_DELETED, _FIVETRAN_SYNCED FROM {{ source('flo_pg_device_service', 'devices') }} as SRC  ),
SRC_A1             as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  )
/*
SRC_D1             as ( SELECT * FROM flo_pg_device_service.devices )
SRC_A1             as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_D1 as (
    SELECT
        DEVICE_ID                                                    as                                          DEVICE_BK
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
    FROM SRC_D1
)

, LOGIC_A1 as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_A1
)
---- RENAME LAYER ----

, RENAME_D1 as (
    SELECT
        DEVICE_BK
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
    FROM LOGIC_D1
)

, RENAME_A1 as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_A1
)
---- FILTER LAYER ----

, FILTER_D1 as (
    SELECT *
    FROM RENAME_D1
)

, FILTER_A1 as (
    SELECT *
    FROM RENAME_A1
    WHERE rec_src = 'US.FLO_PG_DEVICE_SERVICE.DEVICES'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_D1
    INNER JOIN FILTER_A1
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          DEVICE_BK
        , CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED)                    as LOAD_DTS
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
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(DEVICE_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as DEVICE_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(FW_VER::text), '^^') 
            , '||', IFNULL(TRIM(IS_CONNECTED::text), '^^') 
            , '||', IFNULL(TRIM(FW_PROPERTIES_RAW::text), '^^') 
            , '||', IFNULL(TRIM(CREATED_TIME::text), '^^') 
            , '||', IFNULL(TRIM(LAST_HEARD_FROM_TIME::text), '^^') 
            , '||', IFNULL(TRIM(UPDATED_TIME::text), '^^') 
            , '||', IFNULL(TRIM(MAKE::text), '^^') 
            , '||', IFNULL(TRIM(MODEL::text), '^^') 
            , '||', IFNULL(TRIM(VALVE_LATEST::text), '^^') 
            , '||', IFNULL(TRIM(MODE_LATEST::text), '^^') 
            , '||', IFNULL(TRIM(HW_THRESHOLDS::text), '^^') 
            , '||', IFNULL(TRIM(MUTE_AUDIO_UNTIL::text), '^^') 
            , '||', IFNULL(TRIM(COMPONENT_HEALTH::text), '^^') 
            , '||', IFNULL(TRIM(FW_PROPERTIES_REQ::text), '^^') 
            , '||', IFNULL(TRIM(FW_HEALTH_TEST_ON::text), '^^') 
            , '||', IFNULL(TRIM(VALVE_STATE_META::text), '^^') 
            , '||', IFNULL(TRIM(MOBILE_CONNECTIVITY::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_SYNCED::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
