---- SRC LAYER ----
WITH
SRC_D1             as ( SELECT CANCELLATION_REASON, ID, IS_ACTIVE, PLAN_ID, PROVIDER_CUSTOMER_ID, PROVIDER_SUBSCRIPTION_ID, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, RELATED_ENTITY, RELATED_ENTITY_ID, SOURCE_ID, STRIPE_PROVIDER_DATA, SUBSCRIPTION_PROVIDER, _FIVETRAN_DELETED, _FIVETRAN_SYNCED FROM {{ source('flo_dynamodb', 'prod_subscription') }} as SRC  ),
SRC_A1             as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_D1             as ( SELECT * FROM flo_dynamodb.prod_subscription )
SRC_A1             as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_D1 as (
    SELECT
        COALESCE(RELATED_ENTITY_ID, '-1')                            as                    DEVICE_LOCATION_SUBSCRIPTION_BK
      , CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED)                    as                                           LOAD_DTS
      , ID
      , _FIVETRAN_SYNCED
      , RELATED_ENTITY_ID
      , IS_ACTIVE
      , PROVIDER_CUSTOMER_ID
      , SOURCE_ID
      , SUBSCRIPTION_PROVIDER
      , PROVIDER_SUBSCRIPTION_ID
      , STRIPE_PROVIDER_DATA
      , PLAN_ID
      , RELATED_ENTITY
      , _FIVETRAN_DELETED
      , CANCELLATION_REASON
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
        DEVICE_LOCATION_SUBSCRIPTION_BK
      , LOAD_DTS
      , ID
      , _FIVETRAN_SYNCED
      , RELATED_ENTITY_ID
      , IS_ACTIVE
      , PROVIDER_CUSTOMER_ID
      , SOURCE_ID
      , SUBSCRIPTION_PROVIDER
      , PROVIDER_SUBSCRIPTION_ID
      , STRIPE_PROVIDER_DATA
      , PLAN_ID
      , RELATED_ENTITY
      , _FIVETRAN_DELETED
      , CANCELLATION_REASON
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
    WHERE rec_src = 'US.FLO_DYNAMODB.PROD_SUBSCRIPTION'
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
          DEVICE_LOCATION_SUBSCRIPTION_BK
        , LOAD_DTS
        , ID
        , _FIVETRAN_SYNCED
        , RELATED_ENTITY_ID
        , IS_ACTIVE
        , PROVIDER_CUSTOMER_ID
        , SOURCE_ID
        , SUBSCRIPTION_PROVIDER
        , PROVIDER_SUBSCRIPTION_ID
        , STRIPE_PROVIDER_DATA
        , PLAN_ID
        , RELATED_ENTITY
        , _FIVETRAN_DELETED
        , CANCELLATION_REASON
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(DEVICE_LOCATION_SUBSCRIPTION_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as DEVICE_LOCATION_SUBSCRIPTION_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(ID::text), '^^') 
            , '||', IFNULL(TRIM(RELATED_ENTITY_ID::text), '^^') 
            , '||', IFNULL(TRIM(IS_ACTIVE::text), '^^') 
            , '||', IFNULL(TRIM(PROVIDER_CUSTOMER_ID::text), '^^') 
            , '||', IFNULL(TRIM(SOURCE_ID::text), '^^') 
            , '||', IFNULL(TRIM(SUBSCRIPTION_PROVIDER::text), '^^') 
            , '||', IFNULL(TRIM(PROVIDER_SUBSCRIPTION_ID::text), '^^') 
            , '||', IFNULL(TRIM(STRIPE_PROVIDER_DATA::text), '^^') 
            , '||', IFNULL(TRIM(PLAN_ID::text), '^^') 
            , '||', IFNULL(TRIM(RELATED_ENTITY::text), '^^') 
            , '||', IFNULL(TRIM(CANCELLATION_REASON::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
