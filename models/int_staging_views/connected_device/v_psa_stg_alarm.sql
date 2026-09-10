---- SRC LAYER ----
WITH
SRC_D1             as ( SELECT ENABLED, ID, IS_INTERNAL, MAX_DELIVERY_FREQUENCY, METADATA, NAME, PARENT_ID, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, SEND_WHEN_VALVE_IS_CLOSED, SEVERITY, TAGS, USER_CONFIGURABLE, USER_FEEDBACK_OPTIONS_ID, _FIVETRAN_DELETED, _FIVETRAN_SYNCED FROM {{ source('reference', 'alarm') }} as SRC  ),
SRC_A1             as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_D1             as ( SELECT * FROM REFERENCE.ALARM )
SRC_A1             as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_D1 as (
    SELECT
        SPLIT_PART(TO_VARCHAR(ID), '.', 1)                                                           as                                           ALARM_BK
      , CONVERT_TIMEZONE('UTC', PSA_LOAD_DTS)                        as                                           LOAD_DTS
      , ID
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
        ALARM_BK
      , LOAD_DTS
      , ID
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
    WHERE rec_src = 'US.REFERENCE.ALARM'
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
          ALARM_BK
        , LOAD_DTS
        , ID
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
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ALARM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ALARM_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(NAME::text), '^^') 
            , '||', IFNULL(TRIM(SEVERITY::text), '^^') 
            , '||', IFNULL(TRIM(IS_INTERNAL::text), '^^') 
            , '||', IFNULL(TRIM(SEND_WHEN_VALVE_IS_CLOSED::text), '^^') 
            , '||', IFNULL(TRIM(ENABLED::text), '^^') 
            , '||', IFNULL(TRIM(MAX_DELIVERY_FREQUENCY::text), '^^') 
            , '||', IFNULL(TRIM(PARENT_ID::text), '^^') 
            , '||', IFNULL(TRIM(METADATA::text), '^^') 
            , '||', IFNULL(TRIM(USER_CONFIGURABLE::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_SYNCED::text), '^^') 
            , '||', IFNULL(TRIM(TAGS::text), '^^') 
            , '||', IFNULL(TRIM(USER_FEEDBACK_OPTIONS_ID::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
