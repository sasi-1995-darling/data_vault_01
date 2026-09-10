---- SRC LAYER ----
WITH
SRC_D1             as ( SELECT ALERTS, BATTERY_PERCENTAGE, BCKTST_STATUS, BCKTST_TIMESTAMP, BEEPER_PIEZO_ENABLE, BEEPER_SIREN_ENABLE, BEEPER_VOLUME, CLIENTID, COMMAND, COMMAND_SRC, CONNECTED, CROCK_BACKUP, CROCK_BCK_TST, CROCK_COMMAND, CROCK_COMMAND_SRC, CROCK_DIAMETER_MM, CROCK_STATE, CROCK_STREAM, CROCK_TOF_DISTANCE, CROCK_TOF_HEIGHT, CURRENT_VERSION, DEVICE_TYPE, DEV_DEVICE, DISP_LANGUAGE, DROPLET_BACKUP_STATE, DROPLET_FLOOD_RISK, DROPLET_LEVEL, DROPLET_PRIMARY_STATE, DROPLET_TREND, FIRMWARE_VERSION, HUMID_HIGH_THRESHOLD, HUMID_LOW_THRESHOLD, LAST_CONNECT, LOGALERTACK_EVENTID, LOGALERTACK_TYPE, LOGCOMMAND_ARGS, LOGCOMMAND_COMMAND, LOGCOMMAND_DURATION, LOGCOMMAND_EVENTID, LOG_DEBUG, LOG_DEBUG_STATE, POWER_SOURCE, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, SERIAL_NUMBER, SYSTEM_STATE, TEMP_HIGH_THRESHOLD, TEMP_LOW_THRESHOLD, TEMP_SCALE, TIMESTAMP, UPGRADE_URI, WIFI_NETWORK, WIFI_NO_POLL, WIFI_RSSI FROM {{ source('databricks_integration', 'dt_cleaned_nab_shadow') }} as SRC  ),
SRC_A1             as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_D1             as ( SELECT * FROM databricks_integration.DT_CLEANED_NAB_SHADOW )
SRC_A1             as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_D1 as (
    SELECT
        CLIENTID                                                     as                                    SMART_DEVICE_BK
      , CLIENTID
      , DEVICE_TYPE
      , SERIAL_NUMBER
      , TIMESTAMP
      , FIRMWARE_VERSION
      , UPGRADE_URI
      , CONNECTED
      , LAST_CONNECT
      , WIFI_RSSI
      , WIFI_NETWORK
      , WIFI_NO_POLL
      , COMMAND
      , COMMAND_SRC
      , LOGCOMMAND_COMMAND
      , LOGCOMMAND_EVENTID
      , LOGCOMMAND_DURATION
      , LOGCOMMAND_ARGS
      , LOGALERTACK_EVENTID
      , LOGALERTACK_TYPE
      , LOG_DEBUG
      , LOG_DEBUG_STATE
      , SYSTEM_STATE
      , BEEPER_VOLUME
      , BEEPER_PIEZO_ENABLE
      , BEEPER_SIREN_ENABLE
      , DEV_DEVICE
      , DISP_LANGUAGE
      , TEMP_SCALE
      , TEMP_LOW_THRESHOLD
      , TEMP_HIGH_THRESHOLD
      , HUMID_LOW_THRESHOLD
      , HUMID_HIGH_THRESHOLD
      , POWER_SOURCE
      , BATTERY_PERCENTAGE
      , CROCK_DIAMETER_MM
      , CROCK_BACKUP
      , CROCK_COMMAND
      , CROCK_COMMAND_SRC
      , CROCK_STREAM
      , CROCK_BCK_TST
      , BCKTST_TIMESTAMP
      , BCKTST_STATUS
      , CROCK_STATE
      , CROCK_TOF_DISTANCE
      , CROCK_TOF_HEIGHT
      , DROPLET_LEVEL
      , DROPLET_TREND
      , DROPLET_FLOOD_RISK
      , DROPLET_PRIMARY_STATE
      , DROPLET_BACKUP_STATE
      , ALERTS
      , CURRENT_VERSION
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
        SMART_DEVICE_BK
      , CLIENTID
      , DEVICE_TYPE
      , SERIAL_NUMBER
      , TIMESTAMP
      , FIRMWARE_VERSION
      , UPGRADE_URI
      , CONNECTED
      , LAST_CONNECT
      , WIFI_RSSI
      , WIFI_NETWORK
      , WIFI_NO_POLL
      , COMMAND
      , COMMAND_SRC
      , LOGCOMMAND_COMMAND
      , LOGCOMMAND_EVENTID
      , LOGCOMMAND_DURATION
      , LOGCOMMAND_ARGS
      , LOGALERTACK_EVENTID
      , LOGALERTACK_TYPE
      , LOG_DEBUG
      , LOG_DEBUG_STATE
      , SYSTEM_STATE
      , BEEPER_VOLUME
      , BEEPER_PIEZO_ENABLE
      , BEEPER_SIREN_ENABLE
      , DEV_DEVICE
      , DISP_LANGUAGE
      , TEMP_SCALE
      , TEMP_LOW_THRESHOLD
      , TEMP_HIGH_THRESHOLD
      , HUMID_LOW_THRESHOLD
      , HUMID_HIGH_THRESHOLD
      , POWER_SOURCE
      , BATTERY_PERCENTAGE
      , CROCK_DIAMETER_MM
      , CROCK_BACKUP
      , CROCK_COMMAND
      , CROCK_COMMAND_SRC
      , CROCK_STREAM
      , CROCK_BCK_TST
      , BCKTST_TIMESTAMP
      , BCKTST_STATUS
      , CROCK_STATE
      , CROCK_TOF_DISTANCE
      , CROCK_TOF_HEIGHT
      , DROPLET_LEVEL
      , DROPLET_TREND
      , DROPLET_FLOOD_RISK
      , DROPLET_PRIMARY_STATE
      , DROPLET_BACKUP_STATE
      , ALERTS
      , CURRENT_VERSION
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
    WHERE rec_src = 'US.DATABRICKS_INTEGRATION.DT_CLEANED_NAB_SHADOW'
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
          SMART_DEVICE_BK
        , CONVERT_TIMEZONE('UTC', PSA_LOAD_DTS)                        as LOAD_DTS
        , CLIENTID
        , DEVICE_TYPE
        , SERIAL_NUMBER
        , TIMESTAMP
        , FIRMWARE_VERSION
        , UPGRADE_URI
        , CONNECTED
        , LAST_CONNECT
        , WIFI_RSSI
        , WIFI_NETWORK
        , WIFI_NO_POLL
        , COMMAND
        , COMMAND_SRC
        , LOGCOMMAND_COMMAND
        , LOGCOMMAND_EVENTID
        , LOGCOMMAND_DURATION
        , LOGCOMMAND_ARGS
        , LOGALERTACK_EVENTID
        , LOGALERTACK_TYPE
        , LOG_DEBUG
        , LOG_DEBUG_STATE
        , SYSTEM_STATE
        , BEEPER_VOLUME
        , BEEPER_PIEZO_ENABLE
        , BEEPER_SIREN_ENABLE
        , DEV_DEVICE
        , DISP_LANGUAGE
        , TEMP_SCALE
        , TEMP_LOW_THRESHOLD
        , TEMP_HIGH_THRESHOLD
        , HUMID_LOW_THRESHOLD
        , HUMID_HIGH_THRESHOLD
        , POWER_SOURCE
        , BATTERY_PERCENTAGE
        , CROCK_DIAMETER_MM
        , CROCK_BACKUP
        , CROCK_COMMAND
        , CROCK_COMMAND_SRC
        , CROCK_STREAM
        , CROCK_BCK_TST
        , BCKTST_TIMESTAMP
        , BCKTST_STATUS
        , CROCK_STATE
        , CROCK_TOF_DISTANCE
        , CROCK_TOF_HEIGHT
        , DROPLET_LEVEL
        , DROPLET_TREND
        , DROPLET_FLOOD_RISK
        , DROPLET_PRIMARY_STATE
        , DROPLET_BACKUP_STATE
        , ALERTS
        , CURRENT_VERSION
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(SMART_DEVICE_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as SMART_DEVICE_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(DEVICE_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(SERIAL_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(TIMESTAMP::text), '^^') 
            , '||', IFNULL(TRIM(FIRMWARE_VERSION::text), '^^') 
            , '||', IFNULL(TRIM(UPGRADE_URI::text), '^^') 
            , '||', IFNULL(TRIM(CONNECTED::text), '^^') 
            , '||', IFNULL(TRIM(LAST_CONNECT::text), '^^') 
            , '||', IFNULL(TRIM(WIFI_RSSI::text), '^^') 
            , '||', IFNULL(TRIM(WIFI_NETWORK::text), '^^') 
            , '||', IFNULL(TRIM(WIFI_NO_POLL::text), '^^') 
            , '||', IFNULL(TRIM(COMMAND::text), '^^') 
            , '||', IFNULL(TRIM(COMMAND_SRC::text), '^^') 
            , '||', IFNULL(TRIM(LOGCOMMAND_COMMAND::text), '^^') 
            , '||', IFNULL(TRIM(LOGCOMMAND_EVENTID::text), '^^') 
            , '||', IFNULL(TRIM(LOGCOMMAND_DURATION::text), '^^') 
            , '||', IFNULL(TRIM(LOGCOMMAND_ARGS::text), '^^') 
            , '||', IFNULL(TRIM(LOGALERTACK_EVENTID::text), '^^') 
            , '||', IFNULL(TRIM(LOGALERTACK_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(LOG_DEBUG::text), '^^') 
            , '||', IFNULL(TRIM(LOG_DEBUG_STATE::text), '^^') 
            , '||', IFNULL(TRIM(SYSTEM_STATE::text), '^^') 
            , '||', IFNULL(TRIM(BEEPER_VOLUME::text), '^^') 
            , '||', IFNULL(TRIM(BEEPER_PIEZO_ENABLE::text), '^^') 
            , '||', IFNULL(TRIM(BEEPER_SIREN_ENABLE::text), '^^') 
            , '||', IFNULL(TRIM(DEV_DEVICE::text), '^^') 
            , '||', IFNULL(TRIM(DISP_LANGUAGE::text), '^^') 
            , '||', IFNULL(TRIM(TEMP_SCALE::text), '^^') 
            , '||', IFNULL(TRIM(TEMP_LOW_THRESHOLD::text), '^^') 
            , '||', IFNULL(TRIM(TEMP_HIGH_THRESHOLD::text), '^^') 
            , '||', IFNULL(TRIM(HUMID_LOW_THRESHOLD::text), '^^') 
            , '||', IFNULL(TRIM(HUMID_HIGH_THRESHOLD::text), '^^') 
            , '||', IFNULL(TRIM(POWER_SOURCE::text), '^^') 
            , '||', IFNULL(TRIM(BATTERY_PERCENTAGE::text), '^^') 
            , '||', IFNULL(TRIM(CROCK_DIAMETER_MM::text), '^^') 
            , '||', IFNULL(TRIM(CROCK_BACKUP::text), '^^') 
            , '||', IFNULL(TRIM(CROCK_COMMAND::text), '^^') 
            , '||', IFNULL(TRIM(CROCK_COMMAND_SRC::text), '^^') 
            , '||', IFNULL(TRIM(CROCK_STREAM::text), '^^') 
            , '||', IFNULL(TRIM(CROCK_BCK_TST::text), '^^') 
            , '||', IFNULL(TRIM(BCKTST_TIMESTAMP::text), '^^') 
            , '||', IFNULL(TRIM(BCKTST_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(CROCK_STATE::text), '^^') 
            , '||', IFNULL(TRIM(CROCK_TOF_DISTANCE::text), '^^') 
            , '||', IFNULL(TRIM(CROCK_TOF_HEIGHT::text), '^^') 
            , '||', IFNULL(TRIM(DROPLET_LEVEL::text), '^^') 
            , '||', IFNULL(TRIM(DROPLET_TREND::text), '^^') 
            , '||', IFNULL(TRIM(DROPLET_FLOOD_RISK::text), '^^') 
            , '||', IFNULL(TRIM(DROPLET_PRIMARY_STATE::text), '^^') 
            , '||', IFNULL(TRIM(DROPLET_BACKUP_STATE::text), '^^') 
            , '||', IFNULL(TRIM(ALERTS::text), '^^') 
            , '||', IFNULL(TRIM(CURRENT_VERSION::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
