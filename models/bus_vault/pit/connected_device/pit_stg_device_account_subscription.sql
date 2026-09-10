{{ config(materialized='ephemeral') }}
---- SRC LAYER ----
WITH
SRC_HDA            as ( SELECT BKCC, DEVICE_ACCOUNT_BK, DEVICE_ACCOUNT_HK, REC_SRC FROM {{ ref('hub_device_account') }} as SRC  ),
SRC_SDS            as ( SELECT ACCOUNT_ID, CANCELED_AT, CANCELLATION_REASON, CANCEL_AT_PERIOD_END, CREATED_AT, CURRENT_PERIOD_END, CURRENT_PERIOD_START, DEVICE_ACCOUNT_SUBSCRIPTION_HK, ENDED_AT, LOCATION_ID, PLAN_ID, SOURCE_ID, STATUS, STRIPE_CUSTOMER_ID, STRIPE_SUBSCRIPTION_ID, UPDATED_AT, _FIVETRAN_DELETED, _FIVETRAN_SYNCED FROM {{ ref('sat_device_account_subscription__flo_dynamodb') }} as SRC 
                        qualify 1= row_number() over(partition by DEVICE_ACCOUNT_SUBSCRIPTION_HK order by LOAD_DTS DESC) )

/*
SRC_HDA            as ( SELECT * FROM RAW_VAULT.HUB_DEVICE_ACCOUNT )
SRC_SDS            as ( SELECT * FROM RAW_VAULT.SAT_DEVICE_ACCOUNT_SUBSCRIPTION__FLO_DYNAMODB )
*/
---- LOGIC LAYER ----

, LOGIC_HDA as (
    SELECT
        DEVICE_ACCOUNT_HK
      , DEVICE_ACCOUNT_BK
      , BKCC
      , REC_SRC
    FROM SRC_HDA
)

, LOGIC_SDS as (
    SELECT
        ACCOUNT_ID
      , _FIVETRAN_SYNCED                                             as                                    FIVETRAN_SYNCED
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
      , CASE
            WHEN STATUS = 'active' THEN 'Active'
            WHEN STATUS = 'canceled' THEN 'Cancelled'
            WHEN STATUS = 'past_due' THEN 'Past Due'
            WHEN STATUS IS NULL THEN ''
            ELSE STATUS
        END                                                          as                                             STATUS
      , _FIVETRAN_DELETED                                            as                                   FIVETRAN_DELETED
      , CREATED_AT
      , SOURCE_ID
      , CANCELLATION_REASON
      , DEVICE_ACCOUNT_SUBSCRIPTION_HK                               as                 SDS_DEVICE_ACCOUNT_SUBSCRIPTION_HK
      , STATUS                                                       as                                         RAW_STATUS
    FROM SRC_SDS
)
---- RENAME LAYER ----

, RENAME_HDA as (
    SELECT
        DEVICE_ACCOUNT_HK
      , DEVICE_ACCOUNT_BK
      , BKCC
      , REC_SRC
    FROM LOGIC_HDA
)

, RENAME_SDS as (
    SELECT
        ACCOUNT_ID
      , FIVETRAN_SYNCED
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
      , FIVETRAN_DELETED
      , CREATED_AT
      , SOURCE_ID
      , CANCELLATION_REASON
      , SDS_DEVICE_ACCOUNT_SUBSCRIPTION_HK
      , RAW_STATUS
    FROM LOGIC_SDS
)
---- FILTER LAYER ----

, FILTER_HDA as (
    SELECT *
    FROM RENAME_HDA
)

, FILTER_SDS as (
    SELECT *
    FROM RENAME_SDS
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_HDA
    INNER JOIN FILTER_SDS
        ON DEVICE_ACCOUNT_HK = SDS_DEVICE_ACCOUNT_SUBSCRIPTION_HK
)

---- FINAL LAYER ----
SELECT
          DEVICE_ACCOUNT_HK
        , DEVICE_ACCOUNT_BK
        , BKCC
        , REC_SRC
        , ACCOUNT_ID
        , FIVETRAN_SYNCED
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
        , FIVETRAN_DELETED
        , CREATED_AT
        , SOURCE_ID
        , CANCELLATION_REASON
FROM JOIN_RESULT
