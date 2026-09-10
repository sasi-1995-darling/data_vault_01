{{ config(materialized='ephemeral') }}
---- SRC LAYER ----
WITH
SRC_HDA            as ( SELECT BKCC, DEVICE_ACCOUNT_BK, DEVICE_ACCOUNT_HK, REC_SRC FROM {{ ref('hub_device_account') }} as SRC  ),
SRC_SDA            as ( SELECT  _FIVETRAN_SYNCED, ACCOUNT_NAME, ACCOUNT_TYPE, DEVICE_ACCOUNT_HK, GROUP_ID, ID, OWNER_USER_ID, TYPE_V_2, _FIVETRAN_DELETED FROM {{ ref('sat_device_account_details__flo_dynamodb') }} as SRC 
                        qualify 1= row_number() over(partition by DEVICE_ACCOUNT_HK order by LOAD_DTS DESC) )

/*
SRC_HDA            as ( SELECT * FROM RAW_VAULT.HUB_DEVICE_ACCOUNT )
SRC_SDA            as ( SELECT * FROM RAW_VAULT.SAT_DEVICE_ACCOUNT_DETAILS__FLO_DYNAMODB )
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

, LOGIC_SDA as (
    SELECT
        ID                                                           as                                         ACCOUNT_ID
      , _FIVETRAN_SYNCED                                            as                                    FIVETRAN_SYNCED
      , OWNER_USER_ID
      , _FIVETRAN_DELETED                                            as                                   FIVETRAN_DELETED
      , GROUP_ID
      , ACCOUNT_TYPE
      , TYPE_V_2                                                     as                                    ACCOUNT_TYPE_V2
      , ACCOUNT_NAME
      , DEVICE_ACCOUNT_HK                                            as                              SDA_DEVICE_ACCOUNT_HK
    FROM SRC_SDA
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

, RENAME_SDA as (
    SELECT
        ACCOUNT_ID
      , FIVETRAN_SYNCED
      , OWNER_USER_ID
      , FIVETRAN_DELETED
      , GROUP_ID
      , ACCOUNT_TYPE
      , ACCOUNT_TYPE_V2
      , ACCOUNT_NAME
      , SDA_DEVICE_ACCOUNT_HK
    FROM LOGIC_SDA
)
---- FILTER LAYER ----

, FILTER_HDA as (
    SELECT *
    FROM RENAME_HDA
)

, FILTER_SDA as (
    SELECT *
    FROM RENAME_SDA
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_HDA
    INNER JOIN FILTER_SDA
        ON DEVICE_ACCOUNT_HK = SDA_DEVICE_ACCOUNT_HK
)

---- FINAL LAYER ----
SELECT
          DEVICE_ACCOUNT_HK
        , DEVICE_ACCOUNT_BK
        , BKCC
        , REC_SRC
        , ACCOUNT_ID
        , FIVETRAN_SYNCED
        , OWNER_USER_ID
        , FIVETRAN_DELETED
        , GROUP_ID
        , ACCOUNT_TYPE
        , ACCOUNT_TYPE_V2
        , ACCOUNT_NAME
FROM JOIN_RESULT
