---- SRC LAYER ----
WITH
SRC_D1             as ( SELECT CREATED_AT, EVENT, ICD_ID, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, _FIVETRAN_DELETED, _FIVETRAN_SYNCED FROM {{ source('flo_dynamodb', 'prod_onboarding_log') }} as SRC  ),
SRC_A1             as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_D1             as ( SELECT * FROM flo_dynamodb.prod_onboarding_log )
SRC_A1             as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_D1 as (
    SELECT
        ICD_ID                                                       as                             PAIRED_DEVICE_EVENT_BK
      , CREATED_AT
      , ICD_ID
      , _FIVETRAN_DELETED
      , EVENT
      , _FIVETRAN_SYNCED
      , NULL                                                         as                                              DUMMY
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
        PAIRED_DEVICE_EVENT_BK
      , CREATED_AT
      , ICD_ID
      , _FIVETRAN_DELETED
      , EVENT
      , _FIVETRAN_SYNCED
      , DUMMY
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
    WHERE rec_src = 'US.FLO_DYNAMODB.PROD_ONBOARDING_LOG'
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
          PAIRED_DEVICE_EVENT_BK
        , CONVERT_TIMEZONE('UTC', CREATED_AT)                          as LOAD_DTS
        , CREATED_AT
        , ICD_ID
        , _FIVETRAN_DELETED
        , EVENT
        , _FIVETRAN_SYNCED
        , DUMMY
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PAIRED_DEVICE_EVENT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PAIRED_DEVICE_EVENT_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(ICD_ID::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
            , '||', IFNULL(TRIM(EVENT::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_SYNCED::text), '^^') 
            , '||', IFNULL(TRIM(DUMMY::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
