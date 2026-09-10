{{ config(materialized='ephemeral') }}
---- SRC LAYER ----
WITH
SRC_HD             as ( SELECT BKCC, PAIRED_DEVICE_BK, PAIRED_DEVICE_HK, REC_SRC FROM {{ ref('hub_paired_device') }} as SRC  ),
SRC_SD             as ( SELECT DEVICE_ID, DEVICE_MODEL, DEVICE_TYPE, ID, INSTALLATION_POINT, IRRIGATION_TYPE, IS_PAIRED, IS_TEST_DEVICE, LOCATION_ID, NICKNAME, PAIRED_DEVICE_HK, PRV_INSTALLATION, PUCK_CONFIGURED_AT, PURCHASE_LOCATION, REVERT_MINUTES, REVERT_MODE, REVERT_SCHEDULED_AT, SHOULD_INHERIT_SYSTEM_MODE, TARGET_SYSTEM_MODE, TARGET_VALVE_STATE, _FIVETRAN_DELETED, _FIVETRAN_SYNCED FROM {{ ref('sat_paired_device__flo_dynamodb') }} as SRC 
                        qualify 1= row_number() over(partition by PAIRED_DEVICE_HK order by LOAD_DTS DESC) )

/*
SRC_HD             as ( SELECT * FROM RAW_VAULT.HUB_PAIRED_DEVICE )
SRC_SD             as ( SELECT * FROM RAW_VAULT.SAT_PAIRED_DEVICE__FLO_DYNAMODB )
*/
---- LOGIC LAYER ----

, LOGIC_HD as (
    SELECT
        PAIRED_DEVICE_HK
      , PAIRED_DEVICE_BK
      , BKCC
      , REC_SRC
    FROM SRC_HD
)

, LOGIC_SD as (
    SELECT
        ID
      , _FIVETRAN_DELETED
      , IS_PAIRED
      , DEVICE_ID
      , LOCATION_ID
      , _FIVETRAN_SYNCED
      , COALESCE(IS_TEST_DEVICE, FALSE)                              as                                     IS_TEST_DEVICE
      , COALESCE(DEVICE_MODEL,'')                                    as                                       DEVICE_MODEL
      , COALESCE(SHOULD_INHERIT_SYSTEM_MODE, FALSE)                  as                         SHOULD_INHERIT_SYSTEM_MODE
      , COALESCE(NICKNAME,'')                                        as                                           NICKNAME
      , COALESCE(DEVICE_TYPE,'')                                     as                                        DEVICE_TYPE
      , COALESCE(TARGET_VALVE_STATE,'')                              as                                 TARGET_VALVE_STATE
      , COALESCE(REVERT_MINUTES,0)                                   as                                     REVERT_MINUTES
      , REVERT_SCHEDULED_AT
      , COALESCE(REVERT_MODE,'')                                     as                                        REVERT_MODE
      , COALESCE(TARGET_SYSTEM_MODE,'')                              as                                 TARGET_SYSTEM_MODE
      , COALESCE(PRV_INSTALLATION,'')                                as                                   PRV_INSTALLATION
      , COALESCE(IRRIGATION_TYPE,'')                                 as                                    IRRIGATION_TYPE
      , PUCK_CONFIGURED_AT
      , COALESCE(INSTALLATION_POINT,'')                              as                                 INSTALLATION_POINT
      , COALESCE(PURCHASE_LOCATION,'')                               as                                  PURCHASE_LOCATION
      , PAIRED_DEVICE_HK                                             as                                SD_PAIRED_DEVICE_HK
      , IS_TEST_DEVICE                                               as                                 RAW_IS_TEST_DEVICE
      , DEVICE_MODEL                                                 as                                   RAW_DEVICE_MODEL
      , SHOULD_INHERIT_SYSTEM_MODE                                   as                     RAW_SHOULD_INHERIT_SYSTEM_MODE
      , NICKNAME                                                     as                                       RAW_NICKNAME
      , DEVICE_TYPE                                                  as                                    RAW_DEVICE_TYPE
      , TARGET_VALVE_STATE                                           as                             RAW_TARGET_VALVE_STATE
      , REVERT_MINUTES                                               as                                 RAW_REVERT_MINUTES
      , REVERT_MODE                                                  as                                    RAW_REVERT_MODE
      , TARGET_SYSTEM_MODE                                           as                             RAW_TARGET_SYSTEM_MODE
      , PRV_INSTALLATION                                             as                               RAW_PRV_INSTALLATION
      , IRRIGATION_TYPE                                              as                                RAW_IRRIGATION_TYPE
      , INSTALLATION_POINT                                           as                             RAW_INSTALLATION_POINT
      , PURCHASE_LOCATION                                            as                              RAW_PURCHASE_LOCATION
    FROM SRC_SD
)
---- RENAME LAYER ----

, RENAME_HD as (
    SELECT
        PAIRED_DEVICE_HK
      , PAIRED_DEVICE_BK
      , BKCC
      , REC_SRC
    FROM LOGIC_HD
)

, RENAME_SD as (
    SELECT
        ID
      , _FIVETRAN_DELETED
      , IS_PAIRED
      , DEVICE_ID
      , LOCATION_ID
      , _FIVETRAN_SYNCED
      , IS_TEST_DEVICE
      , DEVICE_MODEL
      , SHOULD_INHERIT_SYSTEM_MODE
      , NICKNAME
      , DEVICE_TYPE
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
      , SD_PAIRED_DEVICE_HK
      , RAW_IS_TEST_DEVICE
      , RAW_DEVICE_MODEL
      , RAW_SHOULD_INHERIT_SYSTEM_MODE
      , RAW_NICKNAME
      , RAW_DEVICE_TYPE
      , RAW_TARGET_VALVE_STATE
      , RAW_REVERT_MINUTES
      , RAW_REVERT_MODE
      , RAW_TARGET_SYSTEM_MODE
      , RAW_PRV_INSTALLATION
      , RAW_IRRIGATION_TYPE
      , RAW_INSTALLATION_POINT
      , RAW_PURCHASE_LOCATION
    FROM LOGIC_SD
)
---- FILTER LAYER ----

, FILTER_HD as (
    SELECT *
    FROM RENAME_HD
)

, FILTER_SD as (
    SELECT *
    FROM RENAME_SD
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_HD
    INNER JOIN FILTER_SD
        ON PAIRED_DEVICE_HK = SD_PAIRED_DEVICE_HK
)

---- FINAL LAYER ----
SELECT
          PAIRED_DEVICE_HK
        , PAIRED_DEVICE_BK
        , BKCC
        , REC_SRC
        , ID
        , _FIVETRAN_DELETED
        , IS_PAIRED
        , DEVICE_ID
        , LOCATION_ID
        , _FIVETRAN_SYNCED
        , IS_TEST_DEVICE
        , DEVICE_MODEL
        , SHOULD_INHERIT_SYSTEM_MODE
        , NICKNAME
        , DEVICE_TYPE
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
FROM JOIN_RESULT
