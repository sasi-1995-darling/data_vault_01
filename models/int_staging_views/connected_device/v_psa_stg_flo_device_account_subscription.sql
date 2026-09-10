---- SRC LAYER ----
WITH
SRC_D1             as ( SELECT ACCOUNT_ID, CANCELED_AT, CANCELLATION_REASON, CANCEL_AT_PERIOD_END, CREATED_AT, CURRENT_PERIOD_END, CURRENT_PERIOD_START, ENDED_AT, LOCATION_ID, PLAN_ID, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, SOURCE_ID, STATUS, STRIPE_CUSTOMER_ID, STRIPE_SUBSCRIPTION_ID, UPDATED_AT, _FIVETRAN_DELETED, _FIVETRAN_SYNCED FROM {{ source('flo_dynamodb', 'prod_account_subscription') }} as SRC  ),
SRC_A1             as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_D1             as ( SELECT * FROM flo_dynamodb.prod_account_subscription )
SRC_A1             as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_D1 as (
    SELECT
        ACCOUNT_ID                                                   as                     DEVICE_ACCOUNT_SUBSCRIPTION_BK
      , CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED)                    as                                           LOAD_DTS
      , ACCOUNT_ID
      , _FIVETRAN_SYNCED
      , STRIPE_CUSTOMER_ID
      , UPDATED_AT
      , CANCEL_AT_PERIOD_END
      , CANCELED_AT
      , STRIPE_SUBSCRIPTION_ID
      , CURRENT_PERIOD_END
      , PLAN_ID
      , ENDED_AT
      , CURRENT_PERIOD_START
      , LOCATION_ID
      , STATUS
      , _FIVETRAN_DELETED
      , CREATED_AT
      , SOURCE_ID
      , CANCELLATION_REASON
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , ACCOUNT_ID                                                   as                                  DEVICE_ACCOUNT_BK
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
        DEVICE_ACCOUNT_SUBSCRIPTION_BK
      , LOAD_DTS
      , ACCOUNT_ID
      , _FIVETRAN_SYNCED
      , STRIPE_CUSTOMER_ID
      , UPDATED_AT
      , CANCEL_AT_PERIOD_END
      , CANCELED_AT
      , STRIPE_SUBSCRIPTION_ID
      , CURRENT_PERIOD_END
      , PLAN_ID
      , ENDED_AT
      , CURRENT_PERIOD_START
      , LOCATION_ID
      , STATUS
      , _FIVETRAN_DELETED
      , CREATED_AT
      , SOURCE_ID
      , CANCELLATION_REASON
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , DEVICE_ACCOUNT_BK
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
    WHERE rec_src = 'US.FLO_DYNAMODB.PROD_ACCOUNT_SUBSCRIPTION'
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
          DEVICE_ACCOUNT_SUBSCRIPTION_BK
        , LOAD_DTS
        , ACCOUNT_ID
        , _FIVETRAN_SYNCED
        , STRIPE_CUSTOMER_ID
        , UPDATED_AT
        , CANCEL_AT_PERIOD_END
        , CANCELED_AT
        , STRIPE_SUBSCRIPTION_ID
        , CURRENT_PERIOD_END
        , PLAN_ID
        , ENDED_AT
        , CURRENT_PERIOD_START
        , LOCATION_ID
        , STATUS
        , _FIVETRAN_DELETED
        , CREATED_AT
        , SOURCE_ID
        , CANCELLATION_REASON
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , COALESCE(LOCATION_ID, '-1')                                  as DEVICE_LOCATION_BK
        , DEVICE_ACCOUNT_BK
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(DEVICE_ACCOUNT_SUBSCRIPTION_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as DEVICE_ACCOUNT_SUBSCRIPTION_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(DEVICE_LOCATION_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as DEVICE_LOCATION_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(DEVICE_ACCOUNT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as DEVICE_ACCOUNT_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(DEVICE_LOCATION_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(DEVICE_ACCOUNT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as DEVICE_ACCOUNT_LOCATION_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(ACCOUNT_ID::text), '^^') 
            , '||', IFNULL(TRIM(STRIPE_CUSTOMER_ID::text), '^^') 
            , '||', IFNULL(TRIM(UPDATED_AT::text), '^^') 
            , '||', IFNULL(TRIM(CANCEL_AT_PERIOD_END::text), '^^') 
            , '||', IFNULL(TRIM(CANCELED_AT::text), '^^') 
            , '||', IFNULL(TRIM(STRIPE_SUBSCRIPTION_ID::text), '^^') 
            , '||', IFNULL(TRIM(CURRENT_PERIOD_END::text), '^^') 
            , '||', IFNULL(TRIM(PLAN_ID::text), '^^') 
            , '||', IFNULL(TRIM(ENDED_AT::text), '^^') 
            , '||', IFNULL(TRIM(CURRENT_PERIOD_START::text), '^^') 
            , '||', IFNULL(TRIM(LOCATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(STATUS::text), '^^') 
            , '||', IFNULL(TRIM(CREATED_AT::text), '^^') 
            , '||', IFNULL(TRIM(SOURCE_ID::text), '^^') 
            , '||', IFNULL(TRIM(CANCELLATION_REASON::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
