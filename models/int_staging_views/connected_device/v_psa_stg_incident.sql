---- SRC LAYER ----
WITH
SRC_D1             as ( SELECT ACCOUNT_ID, ALARM_ID, CREATE_AT, DATA_VALUES, EVENT_NAME, GROUP_ID, HEALTH_TEST_ROUND_ID, ICD_ID, ID, LOCATION_ID, NEW_INCIDENT_REF, OLD_INCIDENT_REF, REASON, SNOOZE_TO, STATUS, SYSTEM_MODE, TS_MS, UPDATE_AT FROM {{ source('notification_api', 'cleaned_flo_prod_notification_api_incident') }} as SRC  ),
SRC_A1             as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_D1             as ( SELECT * FROM NOTIFICATION_API.CLEANED_FLO_PROD_NOTIFICATION_API_INCIDENT )
SRC_A1             as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_D1 as (
    SELECT
        ID                                                           as                                        INCIDENT_BK
      , TO_TIMESTAMP_TZ(DATEADD('millisecond', TS_MS, '1970-01-01'::TIMESTAMP_NTZ)) as                                           LOAD_DTS
      , ID
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
        INCIDENT_BK
      , LOAD_DTS
      , ID
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
    WHERE rec_src = 'US.NOTIFICATION_API.CLEANED_FLO_PROD_NOTIFICATION_API_INCIDENT'
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
          INCIDENT_BK
        , LOAD_DTS
        , ID
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
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(INCIDENT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as INCIDENT_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ALARM_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ALARM_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ICD_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PAIRED_DEVICE_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ALARM_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(ICD_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(INCIDENT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as INCIDENT_ALARM_DEVICE_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(ACCOUNT_ID::text), '^^') 
            , '||', IFNULL(TRIM(ALARM_ID::text), '^^') 
            , '||', IFNULL(TRIM(CREATE_AT::text), '^^') 
            , '||', IFNULL(TRIM(DATA_VALUES::text), '^^') 
            , '||', IFNULL(TRIM(GROUP_ID::text), '^^') 
            , '||', IFNULL(TRIM(HEALTH_TEST_ROUND_ID::text), '^^') 
            , '||', IFNULL(TRIM(ICD_ID::text), '^^') 
            , '||', IFNULL(TRIM(LOCATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(NEW_INCIDENT_REF::text), '^^') 
            , '||', IFNULL(TRIM(OLD_INCIDENT_REF::text), '^^') 
            , '||', IFNULL(TRIM(REASON::text), '^^') 
            , '||', IFNULL(TRIM(SNOOZE_TO::text), '^^') 
            , '||', IFNULL(TRIM(STATUS::text), '^^') 
            , '||', IFNULL(TRIM(SYSTEM_MODE::text), '^^') 
            , '||', IFNULL(TRIM(UPDATE_AT::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
