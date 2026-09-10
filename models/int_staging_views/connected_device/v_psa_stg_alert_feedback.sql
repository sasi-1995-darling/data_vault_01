---- SRC LAYER ----
WITH
SRC_D1             as ( SELECT ACTION_TAKEN, ALARM_ID, CAUSE, CAUSE_OTHER, CREATED_AT, DISMISS, ICD_ID, INCIDENT_ID, PLUMBING_FAILURE, PLUMBING_FAILURE_OTHER, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, SHOULD_ACCEPT_AS_NORMAL, SYSTEM_MODE, TEST_FEEDBACK_FOR_INCIDENT, UPDATED_AT, USER_ID, _FIVETRAN_DELETED, _FIVETRAN_SYNCED FROM {{ source('flo_dynamodb', 'prod_alert_feedback') }} as SRC  ),
SRC_A1             as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_D1             as ( SELECT * FROM FLO_DYNAMODB.PROD_ALERT_FEEDBACK )
SRC_A1             as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_D1 as (
    SELECT
        INCIDENT_ID                                                  as                                        INCIDENT_BK
      , CONVERT_TIMEZONE('UTC', PSA_LOAD_DTS)                        as                                           LOAD_DTS
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
    WHERE rec_src = 'US.FLO_DYNAMODB.PROD_ALERT_FEEDBACK'
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
        , COALESCE(USER_ID, '-1')                                      as FLO_USER_BK
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
          COALESCE(NULLIF(TRIM(CAST(FLO_USER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as FLO_USER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ALARM_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(ICD_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(FLO_USER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(INCIDENT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ALERT_FEEDBACK_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(ICD_ID::text), '^^') 
            , '||', IFNULL(TRIM(INCIDENT_ID::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_SYNCED::text), '^^') 
            , '||', IFNULL(TRIM(SHOULD_ACCEPT_AS_NORMAL::text), '^^') 
            , '||', IFNULL(TRIM(USER_ID::text), '^^') 
            , '||', IFNULL(TRIM(CREATED_AT::text), '^^') 
            , '||', IFNULL(TRIM(ACTION_TAKEN::text), '^^') 
            , '||', IFNULL(TRIM(ALARM_ID::text), '^^') 
            , '||', IFNULL(TRIM(SYSTEM_MODE::text), '^^') 
            , '||', IFNULL(TRIM(CAUSE::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
            , '||', IFNULL(TRIM(CAUSE_OTHER::text), '^^') 
            , '||', IFNULL(TRIM(UPDATED_AT::text), '^^') 
            , '||', IFNULL(TRIM(PLUMBING_FAILURE::text), '^^') 
            , '||', IFNULL(TRIM(PLUMBING_FAILURE_OTHER::text), '^^') 
            , '||', IFNULL(TRIM(TEST_FEEDBACK_FOR_INCIDENT::text), '^^') 
            , '||', IFNULL(TRIM(DISMISS::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
