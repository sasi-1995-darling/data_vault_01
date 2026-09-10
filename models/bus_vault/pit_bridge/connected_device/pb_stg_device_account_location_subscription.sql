{{ config(materialized='ephemeral') }}
---- SRC LAYER ----
WITH
SRC_LDL            as ( SELECT DEVICE_ACCOUNT_HK, DEVICE_ACCOUNT_LOCATION_HK, DEVICE_LOCATION_HK, REC_SRC FROM {{ ref('lnk_device_account_location') }} as SRC  ),
SRC_HD             as ( SELECT BKCC, DEVICE_ACCOUNT_BK, DEVICE_ACCOUNT_HK FROM {{ ref('hub_device_account') }} as SRC  ),
SRC_HL             as ( SELECT DEVICE_LOCATION_BK, DEVICE_LOCATION_HK FROM {{ ref('hub_device_location') }} as SRC  ),
SRC_SDS            as ( SELECT CANCELLATION_REASON, DEVICE_LOCATION_SUBSCRIPTION_HK, ID, IS_ACTIVE, PLAN_ID, PROVIDER_CUSTOMER_ID, PROVIDER_SUBSCRIPTION_ID, RELATED_ENTITY, RELATED_ENTITY_ID, SOURCE_ID, STRIPE_PROVIDER_DATA, SUBSCRIPTION_PROVIDER, _FIVETRAN_DELETED, _FIVETRAN_SYNCED FROM {{ ref('sat_device_location_subscription__flo_dynamodb') }} as SRC 
                        qualify 1= row_number() over(partition by DEVICE_LOCATION_SUBSCRIPTION_HK order by LOAD_DTS DESC) )

/*
SRC_LDL            as ( SELECT * FROM raw_vault.LNK_DEVICE_ACCOUNT_LOCATION )
SRC_HD             as ( SELECT * FROM raw_vault.HUB_DEVICE_ACCOUNT )
SRC_HL             as ( SELECT * FROM raw_vault.HUB_DEVICE_LOCATION )
SRC_SDS            as ( SELECT * FROM raw_vault.SAT_DEVICE_LOCATION_SUBSCRIPTION__FLO_DYNAMODB )
*/
---- LOGIC LAYER ----

, LOGIC_LDL as (
    SELECT
        DEVICE_ACCOUNT_LOCATION_HK
      , DEVICE_ACCOUNT_HK
      , DEVICE_LOCATION_HK
      , REC_SRC
    FROM SRC_LDL
)

, LOGIC_HD as (
    SELECT
        DEVICE_ACCOUNT_HK                                            as                               HD_DEVICE_ACCOUNT_HK
      , DEVICE_ACCOUNT_BK
      , BKCC
    FROM SRC_HD
)

, LOGIC_HL as (
    SELECT
        DEVICE_LOCATION_HK                                           as                              HL_DEVICE_LOCATION_HK
      , DEVICE_LOCATION_BK
    FROM SRC_HL
)

, LOGIC_SDS as (
    SELECT
        DEVICE_LOCATION_SUBSCRIPTION_HK                              as                SDS_DEVICE_LOCATION_SUBSCRIPTION_HK
      , ID                                                           as                                         ACCOUNT_ID
      , _FIVETRAN_SYNCED                                             as                                    FIVETRAN_SYNCED
      , RELATED_ENTITY_ID
      , IS_ACTIVE
      , PROVIDER_CUSTOMER_ID
      , SOURCE_ID
      , SUBSCRIPTION_PROVIDER
      , PROVIDER_SUBSCRIPTION_ID
      , TO_VARCHAR(STRIPE_PROVIDER_DATA)                             as                               STRIPE_PROVIDER_DATA
      , PLAN_ID
      , RELATED_ENTITY
      , _FIVETRAN_DELETED                                            as                                   FIVETRAN_DELETED
      , CANCELLATION_REASON
      , STRIPE_PROVIDER_DATA                                         as                           RAW_STRIPE_PROVIDER_DATA
    FROM SRC_SDS
)
---- RENAME LAYER ----

, RENAME_LDL as (
    SELECT
        DEVICE_ACCOUNT_LOCATION_HK
      , DEVICE_ACCOUNT_HK
      , DEVICE_LOCATION_HK
      , REC_SRC
    FROM LOGIC_LDL
)

, RENAME_HD as (
    SELECT
        HD_DEVICE_ACCOUNT_HK
      , DEVICE_ACCOUNT_BK
      , BKCC
    FROM LOGIC_HD
)

, RENAME_HL as (
    SELECT
        HL_DEVICE_LOCATION_HK
      , DEVICE_LOCATION_BK
    FROM LOGIC_HL
)

, RENAME_SDS as (
    SELECT
        SDS_DEVICE_LOCATION_SUBSCRIPTION_HK
      , ACCOUNT_ID
      , FIVETRAN_SYNCED
      , RELATED_ENTITY_ID
      , IS_ACTIVE
      , PROVIDER_CUSTOMER_ID
      , SOURCE_ID
      , SUBSCRIPTION_PROVIDER
      , PROVIDER_SUBSCRIPTION_ID
      , STRIPE_PROVIDER_DATA
      , PLAN_ID
      , RELATED_ENTITY
      , FIVETRAN_DELETED
      , CANCELLATION_REASON
      , RAW_STRIPE_PROVIDER_DATA
    FROM LOGIC_SDS
)
---- FILTER LAYER ----

, FILTER_LDL as (
    SELECT *
    FROM RENAME_LDL
)

, FILTER_HD as (
    SELECT *
    FROM RENAME_HD
)

, FILTER_HL as (
    SELECT *
    FROM RENAME_HL
)

, FILTER_SDS as (
    SELECT *
    FROM RENAME_SDS
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_LDL
    INNER JOIN FILTER_HD
        ON DEVICE_ACCOUNT_HK = HD_DEVICE_ACCOUNT_HK
    INNER JOIN FILTER_HL
        ON DEVICE_LOCATION_HK = HL_DEVICE_LOCATION_HK
    INNER JOIN FILTER_SDS
        ON DEVICE_LOCATION_HK = SDS_DEVICE_LOCATION_SUBSCRIPTION_HK
)

---- FINAL LAYER ----
SELECT
          DEVICE_ACCOUNT_LOCATION_HK
        , DEVICE_ACCOUNT_HK
        , DEVICE_LOCATION_HK
        , DEVICE_ACCOUNT_BK
        , DEVICE_LOCATION_BK
        , BKCC
        , REC_SRC
        , ACCOUNT_ID
        , FIVETRAN_SYNCED
        , RELATED_ENTITY_ID
        , IS_ACTIVE
        , PROVIDER_CUSTOMER_ID
        , SOURCE_ID
        , SUBSCRIPTION_PROVIDER
        , PROVIDER_SUBSCRIPTION_ID
        , STRIPE_PROVIDER_DATA
        , PLAN_ID
        , RELATED_ENTITY
        , FIVETRAN_DELETED
        , CANCELLATION_REASON
FROM JOIN_RESULT
