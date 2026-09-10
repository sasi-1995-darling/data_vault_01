---- SRC LAYER ----
WITH
SRC_D1             as ( SELECT DEVICE_ID, DEVICE_MODEL, DEVICE_TYPE, ID, INSTALLATION_POINT, IRRIGATION_TYPE, IS_PAIRED, IS_TEST_DEVICE, LOCATION_ID, NICKNAME, PRV_INSTALLATION, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, PUCK_CONFIGURED_AT, PURCHASE_LOCATION, REVERT_MINUTES, REVERT_MODE, REVERT_SCHEDULED_AT, SHOULD_INHERIT_SYSTEM_MODE, TARGET_SYSTEM_MODE, TARGET_VALVE_STATE, _FIVETRAN_DELETED, _FIVETRAN_SYNCED FROM {{ source('flo_dynamodb', 'prod_icd') }} as SRC  ),
SRC_A1             as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_D1             as ( SELECT * FROM flo_dynamodb.prod_icd )
SRC_A1             as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_D1 as (
    SELECT
        ID                                                           as                                   PAIRED_DEVICE_BK
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
      , LOCATION_ID                                                  as                                 DEVICE_LOCATION_BK
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
        PAIRED_DEVICE_BK
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
      , DEVICE_LOCATION_BK
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
    WHERE rec_src = 'US.FLO_DYNAMODB.PROD_ICD'
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
          PAIRED_DEVICE_BK
        , CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED)                    as LOAD_DTS
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
        , DEVICE_LOCATION_BK
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , COALESCE(DEVICE_ID, '-1')                                    as DEVICE_BK
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PAIRED_DEVICE_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PAIRED_DEVICE_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(DEVICE_LOCATION_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as DEVICE_LOCATION_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PAIRED_DEVICE_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(DEVICE_LOCATION_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PAIRED_DEVICE_LOCATION_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(DEVICE_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as DEVICE_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(DEVICE_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(PAIRED_DEVICE_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ICD_DEVICE_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(ID::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
            , '||', IFNULL(TRIM(IS_PAIRED::text), '^^') 
            , '||', IFNULL(TRIM(DEVICE_ID::text), '^^') 
            , '||', IFNULL(TRIM(LOCATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_SYNCED::text), '^^') 
            , '||', IFNULL(TRIM(IS_TEST_DEVICE::text), '^^') 
            , '||', IFNULL(TRIM(DEVICE_MODEL::text), '^^') 
            , '||', IFNULL(TRIM(NICKNAME::text), '^^') 
            , '||', IFNULL(TRIM(DEVICE_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(SHOULD_INHERIT_SYSTEM_MODE::text), '^^') 
            , '||', IFNULL(TRIM(TARGET_VALVE_STATE::text), '^^') 
            , '||', IFNULL(TRIM(REVERT_MINUTES::text), '^^') 
            , '||', IFNULL(TRIM(REVERT_SCHEDULED_AT::text), '^^') 
            , '||', IFNULL(TRIM(REVERT_MODE::text), '^^') 
            , '||', IFNULL(TRIM(TARGET_SYSTEM_MODE::text), '^^') 
            , '||', IFNULL(TRIM(PRV_INSTALLATION::text), '^^') 
            , '||', IFNULL(TRIM(IRRIGATION_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(PUCK_CONFIGURED_AT::text), '^^') 
            , '||', IFNULL(TRIM(INSTALLATION_POINT::text), '^^') 
            , '||', IFNULL(TRIM(PURCHASE_LOCATION::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
