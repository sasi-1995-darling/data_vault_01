---- SRC LAYER ----
WITH
SRC_D1             as ( SELECT ALERTS, ASSEMBLY_AIR_TEMP, BEEPER_PIEZO_ENABLE, BEEPER_SIREN_ENABLE, BEEPER_VOLUME, CHILD_LIMIT_TEMP, CHILD_MODE_ENABLED, CLIENT_ID, COMMAND, COMMAND_SRC, CONNECTED, CURRENT_VERSION, DEFAULT_FLOW_RATE, DEFAULT_TEMP, DEVICE_TYPE, DEV_DEVICE, DISPENSE_ACTIVATE_TIMEOUT, DISP_LANGUAGE, EVENT_TIMESTAMP, FIRMWARE_VERSION, FLOW_CAL_SRC, FLOW_RATE, FREEZE_ENABLE, GESTURE_COMM_ERROR, GESTURE_FW, GESTURE_MODE, HANDLE_COMM_ERROR, HANDLE_FW, HANDLE_REVERSE, HANDLE_TIMEOUT, HEALTH_PROTECT_TIMEOUT, IS_FREEZING, JANUS_OVERVIEW, LAST_CONNECT, LEARNED_MAX_TEMP, LEARNED_MIN_TEMP, LOW_FLOW_RATE, MAX_FLOW_RATE, OCCUPANCY, POWER_BATTERY_LIFE_REMAINING, POWER_BATTERY_PERCENTAGE, POWER_BATTERY_SAVING_LEVEL, POWER_ON, POWER_SOURCE, PRESET_ID, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, PURGE_TIMEOUT, REVERSE_HOT_COLD, SAFETY_LIMIT_TEMP, SAFETY_MODE_ENABLED, SENSOR_COMM_ERROR, SENSOR_CONFIG, SENSOR_DISABLE, SENSOR_LATCH_FW, SENSOR_LED_BRIGHTNESS, SENSOR_TIMEOUT, SERIAL_NUMBER, SETPOINT_COLD_TEMP, SETPOINT_HOT_TEMP, SETPOINT_WARM_TEMP, STATE, SYSTEM_STATE, TEMPERATURE, TEMPERATURE_GOAL, TEMPERATURE_LAST, TRICKLE_FLOW_RATE, UNWINTERIZE_TIMEOUT, UPGRADE_URI, USER_CALIBRATED, VD_TELEMETRY_PUBLISH_INTERVAL, VERSION, VOICE_TIMEOUT, VOLUME, WIFI_NETWORK, WIFI_NO_POLL, WIFI_RSSI, _RESCUED_DATA FROM {{ source('databricks_integration', 'dt_cleaned_vak_shadow') }} as SRC  ),
SRC_A1             as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_D1             as ( SELECT * FROM databricks_integration.DT_CLEANED_VAK_SHADOW )
SRC_A1             as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_D1 as (
    SELECT
        CLIENT_ID                                                    as                                    SMART_DEVICE_BK
      , CLIENT_ID
      , SERIAL_NUMBER
      , EVENT_TIMESTAMP
      , FIRMWARE_VERSION
      , UPGRADE_URI
      , CONNECTED
      , LAST_CONNECT
      , WIFI_RSSI
      , WIFI_NO_POLL
      , WIFI_NETWORK
      , COMMAND
      , COMMAND_SRC
      , BEEPER_VOLUME
      , BEEPER_PIEZO_ENABLE
      , BEEPER_SIREN_ENABLE
      , DEV_DEVICE
      , OCCUPANCY
      , DISP_LANGUAGE
      , HANDLE_FW
      , HANDLE_REVERSE
      , HANDLE_COMM_ERROR
      , GESTURE_FW
      , GESTURE_MODE
      , GESTURE_COMM_ERROR
      , SENSOR_LATCH_FW
      , SENSOR_LED_BRIGHTNESS
      , SENSOR_COMM_ERROR
      , SENSOR_CONFIG
      , SENSOR_DISABLE
      , POWER_SOURCE
      , POWER_BATTERY_LIFE_REMAINING
      , POWER_BATTERY_PERCENTAGE
      , POWER_BATTERY_SAVING_LEVEL
      , POWER_ON
      , STATE
      , SYSTEM_STATE
      , FLOW_CAL_SRC
      , PRESET_ID
      , VOLUME
      , FLOW_RATE
      , TEMPERATURE
      , TEMPERATURE_GOAL
      , TEMPERATURE_LAST
      , FREEZE_ENABLE
      , IS_FREEZING
      , TRICKLE_FLOW_RATE
      , LEARNED_MIN_TEMP
      , LEARNED_MAX_TEMP
      , DEFAULT_TEMP
      , DEFAULT_FLOW_RATE
      , MAX_FLOW_RATE
      , PURGE_TIMEOUT
      , HANDLE_TIMEOUT
      , SENSOR_TIMEOUT
      , VOICE_TIMEOUT
      , DISPENSE_ACTIVATE_TIMEOUT
      , VD_TELEMETRY_PUBLISH_INTERVAL
      , SAFETY_LIMIT_TEMP
      , SAFETY_MODE_ENABLED
      , CHILD_LIMIT_TEMP
      , CHILD_MODE_ENABLED
      , SETPOINT_COLD_TEMP
      , SETPOINT_WARM_TEMP
      , SETPOINT_HOT_TEMP
      , ASSEMBLY_AIR_TEMP
      , USER_CALIBRATED
      , REVERSE_HOT_COLD
      , UNWINTERIZE_TIMEOUT
      , HEALTH_PROTECT_TIMEOUT
      , LOW_FLOW_RATE
      , ALERTS
      , JANUS_OVERVIEW
      , CURRENT_VERSION
      , DEVICE_TYPE
      , VERSION
      , _RESCUED_DATA
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
      , CLIENT_ID
      , SERIAL_NUMBER
      , EVENT_TIMESTAMP
      , FIRMWARE_VERSION
      , UPGRADE_URI
      , CONNECTED
      , LAST_CONNECT
      , WIFI_RSSI
      , WIFI_NO_POLL
      , WIFI_NETWORK
      , COMMAND
      , COMMAND_SRC
      , BEEPER_VOLUME
      , BEEPER_PIEZO_ENABLE
      , BEEPER_SIREN_ENABLE
      , DEV_DEVICE
      , OCCUPANCY
      , DISP_LANGUAGE
      , HANDLE_FW
      , HANDLE_REVERSE
      , HANDLE_COMM_ERROR
      , GESTURE_FW
      , GESTURE_MODE
      , GESTURE_COMM_ERROR
      , SENSOR_LATCH_FW
      , SENSOR_LED_BRIGHTNESS
      , SENSOR_COMM_ERROR
      , SENSOR_CONFIG
      , SENSOR_DISABLE
      , POWER_SOURCE
      , POWER_BATTERY_LIFE_REMAINING
      , POWER_BATTERY_PERCENTAGE
      , POWER_BATTERY_SAVING_LEVEL
      , POWER_ON
      , STATE
      , SYSTEM_STATE
      , FLOW_CAL_SRC
      , PRESET_ID
      , VOLUME
      , FLOW_RATE
      , TEMPERATURE
      , TEMPERATURE_GOAL
      , TEMPERATURE_LAST
      , FREEZE_ENABLE
      , IS_FREEZING
      , TRICKLE_FLOW_RATE
      , LEARNED_MIN_TEMP
      , LEARNED_MAX_TEMP
      , DEFAULT_TEMP
      , DEFAULT_FLOW_RATE
      , MAX_FLOW_RATE
      , PURGE_TIMEOUT
      , HANDLE_TIMEOUT
      , SENSOR_TIMEOUT
      , VOICE_TIMEOUT
      , DISPENSE_ACTIVATE_TIMEOUT
      , VD_TELEMETRY_PUBLISH_INTERVAL
      , SAFETY_LIMIT_TEMP
      , SAFETY_MODE_ENABLED
      , CHILD_LIMIT_TEMP
      , CHILD_MODE_ENABLED
      , SETPOINT_COLD_TEMP
      , SETPOINT_WARM_TEMP
      , SETPOINT_HOT_TEMP
      , ASSEMBLY_AIR_TEMP
      , USER_CALIBRATED
      , REVERSE_HOT_COLD
      , UNWINTERIZE_TIMEOUT
      , HEALTH_PROTECT_TIMEOUT
      , LOW_FLOW_RATE
      , ALERTS
      , JANUS_OVERVIEW
      , CURRENT_VERSION
      , DEVICE_TYPE
      , VERSION
      , _RESCUED_DATA
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
    WHERE rec_src = 'US.DATABRICKS_INTEGRATION.DT_CLEANED_VAK_SHADOW'
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
        , CLIENT_ID
        , SERIAL_NUMBER
        , EVENT_TIMESTAMP
        , FIRMWARE_VERSION
        , UPGRADE_URI
        , CONNECTED
        , LAST_CONNECT
        , WIFI_RSSI
        , WIFI_NO_POLL
        , WIFI_NETWORK
        , COMMAND
        , COMMAND_SRC
        , BEEPER_VOLUME
        , BEEPER_PIEZO_ENABLE
        , BEEPER_SIREN_ENABLE
        , DEV_DEVICE
        , OCCUPANCY
        , DISP_LANGUAGE
        , HANDLE_FW
        , HANDLE_REVERSE
        , HANDLE_COMM_ERROR
        , GESTURE_FW
        , GESTURE_MODE
        , GESTURE_COMM_ERROR
        , SENSOR_LATCH_FW
        , SENSOR_LED_BRIGHTNESS
        , SENSOR_COMM_ERROR
        , SENSOR_CONFIG
        , SENSOR_DISABLE
        , POWER_SOURCE
        , POWER_BATTERY_LIFE_REMAINING
        , POWER_BATTERY_PERCENTAGE
        , POWER_BATTERY_SAVING_LEVEL
        , POWER_ON
        , STATE
        , SYSTEM_STATE
        , FLOW_CAL_SRC
        , PRESET_ID
        , VOLUME
        , FLOW_RATE
        , TEMPERATURE
        , TEMPERATURE_GOAL
        , TEMPERATURE_LAST
        , FREEZE_ENABLE
        , IS_FREEZING
        , TRICKLE_FLOW_RATE
        , LEARNED_MIN_TEMP
        , LEARNED_MAX_TEMP
        , DEFAULT_TEMP
        , DEFAULT_FLOW_RATE
        , MAX_FLOW_RATE
        , PURGE_TIMEOUT
        , HANDLE_TIMEOUT
        , SENSOR_TIMEOUT
        , VOICE_TIMEOUT
        , DISPENSE_ACTIVATE_TIMEOUT
        , VD_TELEMETRY_PUBLISH_INTERVAL
        , SAFETY_LIMIT_TEMP
        , SAFETY_MODE_ENABLED
        , CHILD_LIMIT_TEMP
        , CHILD_MODE_ENABLED
        , SETPOINT_COLD_TEMP
        , SETPOINT_WARM_TEMP
        , SETPOINT_HOT_TEMP
        , ASSEMBLY_AIR_TEMP
        , USER_CALIBRATED
        , REVERSE_HOT_COLD
        , UNWINTERIZE_TIMEOUT
        , HEALTH_PROTECT_TIMEOUT
        , LOW_FLOW_RATE
        , ALERTS
        , JANUS_OVERVIEW
        , CURRENT_VERSION
        , DEVICE_TYPE
        , VERSION
        , _RESCUED_DATA
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
              IFNULL(TRIM(SERIAL_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(EVENT_TIMESTAMP::text), '^^') 
            , '||', IFNULL(TRIM(FIRMWARE_VERSION::text), '^^') 
            , '||', IFNULL(TRIM(UPGRADE_URI::text), '^^') 
            , '||', IFNULL(TRIM(CONNECTED::text), '^^') 
            , '||', IFNULL(TRIM(LAST_CONNECT::text), '^^') 
            , '||', IFNULL(TRIM(WIFI_RSSI::text), '^^') 
            , '||', IFNULL(TRIM(WIFI_NO_POLL::text), '^^') 
            , '||', IFNULL(TRIM(WIFI_NETWORK::text), '^^') 
            , '||', IFNULL(TRIM(COMMAND::text), '^^') 
            , '||', IFNULL(TRIM(COMMAND_SRC::text), '^^') 
            , '||', IFNULL(TRIM(BEEPER_VOLUME::text), '^^') 
            , '||', IFNULL(TRIM(BEEPER_PIEZO_ENABLE::text), '^^') 
            , '||', IFNULL(TRIM(BEEPER_SIREN_ENABLE::text), '^^') 
            , '||', IFNULL(TRIM(DEV_DEVICE::text), '^^') 
            , '||', IFNULL(TRIM(OCCUPANCY::text), '^^') 
            , '||', IFNULL(TRIM(DISP_LANGUAGE::text), '^^') 
            , '||', IFNULL(TRIM(HANDLE_FW::text), '^^') 
            , '||', IFNULL(TRIM(HANDLE_REVERSE::text), '^^') 
            , '||', IFNULL(TRIM(HANDLE_COMM_ERROR::text), '^^') 
            , '||', IFNULL(TRIM(GESTURE_FW::text), '^^') 
            , '||', IFNULL(TRIM(GESTURE_MODE::text), '^^') 
            , '||', IFNULL(TRIM(GESTURE_COMM_ERROR::text), '^^') 
            , '||', IFNULL(TRIM(SENSOR_LATCH_FW::text), '^^') 
            , '||', IFNULL(TRIM(SENSOR_LED_BRIGHTNESS::text), '^^') 
            , '||', IFNULL(TRIM(SENSOR_COMM_ERROR::text), '^^') 
            , '||', IFNULL(TRIM(SENSOR_CONFIG::text), '^^') 
            , '||', IFNULL(TRIM(SENSOR_DISABLE::text), '^^') 
            , '||', IFNULL(TRIM(POWER_SOURCE::text), '^^') 
            , '||', IFNULL(TRIM(POWER_BATTERY_LIFE_REMAINING::text), '^^') 
            , '||', IFNULL(TRIM(POWER_BATTERY_PERCENTAGE::text), '^^') 
            , '||', IFNULL(TRIM(POWER_BATTERY_SAVING_LEVEL::text), '^^') 
            , '||', IFNULL(TRIM(POWER_ON::text), '^^') 
            , '||', IFNULL(TRIM(STATE::text), '^^') 
            , '||', IFNULL(TRIM(SYSTEM_STATE::text), '^^') 
            , '||', IFNULL(TRIM(FLOW_CAL_SRC::text), '^^') 
            , '||', IFNULL(TRIM(PRESET_ID::text), '^^') 
            , '||', IFNULL(TRIM(VOLUME::text), '^^') 
            , '||', IFNULL(TRIM(FLOW_RATE::text), '^^') 
            , '||', IFNULL(TRIM(TEMPERATURE::text), '^^') 
            , '||', IFNULL(TRIM(TEMPERATURE_GOAL::text), '^^') 
            , '||', IFNULL(TRIM(TEMPERATURE_LAST::text), '^^') 
            , '||', IFNULL(TRIM(FREEZE_ENABLE::text), '^^') 
            , '||', IFNULL(TRIM(IS_FREEZING::text), '^^') 
            , '||', IFNULL(TRIM(TRICKLE_FLOW_RATE::text), '^^') 
            , '||', IFNULL(TRIM(LEARNED_MIN_TEMP::text), '^^') 
            , '||', IFNULL(TRIM(LEARNED_MAX_TEMP::text), '^^') 
            , '||', IFNULL(TRIM(DEFAULT_TEMP::text), '^^') 
            , '||', IFNULL(TRIM(DEFAULT_FLOW_RATE::text), '^^') 
            , '||', IFNULL(TRIM(MAX_FLOW_RATE::text), '^^') 
            , '||', IFNULL(TRIM(PURGE_TIMEOUT::text), '^^') 
            , '||', IFNULL(TRIM(HANDLE_TIMEOUT::text), '^^') 
            , '||', IFNULL(TRIM(SENSOR_TIMEOUT::text), '^^') 
            , '||', IFNULL(TRIM(VOICE_TIMEOUT::text), '^^') 
            , '||', IFNULL(TRIM(DISPENSE_ACTIVATE_TIMEOUT::text), '^^') 
            , '||', IFNULL(TRIM(VD_TELEMETRY_PUBLISH_INTERVAL::text), '^^') 
            , '||', IFNULL(TRIM(SAFETY_LIMIT_TEMP::text), '^^') 
            , '||', IFNULL(TRIM(SAFETY_MODE_ENABLED::text), '^^') 
            , '||', IFNULL(TRIM(CHILD_LIMIT_TEMP::text), '^^') 
            , '||', IFNULL(TRIM(CHILD_MODE_ENABLED::text), '^^') 
            , '||', IFNULL(TRIM(SETPOINT_COLD_TEMP::text), '^^') 
            , '||', IFNULL(TRIM(SETPOINT_WARM_TEMP::text), '^^') 
            , '||', IFNULL(TRIM(SETPOINT_HOT_TEMP::text), '^^') 
            , '||', IFNULL(TRIM(ASSEMBLY_AIR_TEMP::text), '^^') 
            , '||', IFNULL(TRIM(USER_CALIBRATED::text), '^^') 
            , '||', IFNULL(TRIM(REVERSE_HOT_COLD::text), '^^') 
            , '||', IFNULL(TRIM(UNWINTERIZE_TIMEOUT::text), '^^') 
            , '||', IFNULL(TRIM(HEALTH_PROTECT_TIMEOUT::text), '^^') 
            , '||', IFNULL(TRIM(LOW_FLOW_RATE::text), '^^') 
            , '||', IFNULL(TRIM(ALERTS::text), '^^') 
            , '||', IFNULL(TRIM(JANUS_OVERVIEW::text), '^^') 
            , '||', IFNULL(TRIM(CURRENT_VERSION::text), '^^') 
            , '||', IFNULL(TRIM(DEVICE_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(VERSION::text), '^^') 
            , '||', IFNULL(TRIM(_RESCUED_DATA::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
