{{ config(materialized='ephemeral') }}
---- SRC LAYER ----
WITH
SRC_LCD            as ( SELECT DEVICE_HK, ICD_DEVICE_HK, PAIRED_DEVICE_HK FROM {{ ref('lnk_icd_device') }} as SRC  ),
SRC_HP             as ( SELECT PAIRED_DEVICE_BK, PAIRED_DEVICE_HK FROM {{ ref('hub_paired_device') }} as SRC  ),
SRC_HD             as ( SELECT BKCC, DEVICE_BK, DEVICE_HK, REC_SRC FROM {{ ref('hub_device_v2') }} as SRC  ),
SRC_SDS            as ( SELECT DEVICE_HK, MAKE, MODEL FROM {{ ref('sat_device_status__flo_service') }} as SRC 
                        qualify 1= row_number() over(partition by DEVICE_HK order by LOAD_DTS DESC) ),
SRC_SDE            as ( SELECT PAIRED_DEVICE_EVENT_HK FROM {{ ref('sat_paired_device_event__flo_dynamodb') }} as SRC 
                        qualify 1= row_number() over(partition by PAIRED_DEVICE_EVENT_HK order by LOAD_DTS DESC) ),
SRC_SPD            as ( SELECT DEVICE_ID, ID, PAIRED_DEVICE_HK, _FIVETRAN_DELETED FROM {{ ref('sat_paired_device__flo_dynamodb') }} as SRC 
                        
                        qualify 1= row_number() over(partition by PAIRED_DEVICE_HK order by LOAD_DTS DESC) ),
SRC_LDL            as ( SELECT DEVICE_LOCATION_HK, PAIRED_DEVICE_HK, PAIRED_DEVICE_LOCATION_HK FROM {{ ref('lnk_paired_device_location') }} as SRC  ),
SRC_HL             as ( SELECT DEVICE_LOCATION_BK, DEVICE_LOCATION_HK FROM {{ ref('hub_device_location') }} as SRC  ),
SRC_SDLS           as ( SELECT DEVICE_LOCATION_SUBSCRIPTION_HK, LOAD_DTS, STRIPE_PROVIDER_DATA FROM {{ ref('sat_device_location_subscription__flo_dynamodb') }} as SRC 
                        qualify 1= row_number() over(partition by DEVICE_LOCATION_SUBSCRIPTION_HK order by LOAD_DTS DESC) )

/*
SRC_LCD            as ( SELECT * FROM raw_vault.LNK_ICD_DEVICE )
SRC_HP             as ( SELECT * FROM raw_vault.HUB_PAIRED_DEVICE )
SRC_HD             as ( SELECT * FROM raw_vault.HUB_DEVICE_V2 )
SRC_SDS            as ( SELECT * FROM raw_vault.SAT_DEVICE_STATUS__FLO_SERVICE )
SRC_SDE            as ( SELECT * FROM raw_vault.SAT_PAIRED_DEVICE_EVENT__FLO_DYNAMODB )
SRC_SPD            as ( SELECT * FROM raw_vault.SAT_PAIRED_DEVICE__FLO_DYNAMODB )
SRC_LDL            as ( SELECT * FROM raw_vault.LNK_PAIRED_DEVICE_LOCATION )
SRC_HL             as ( SELECT * FROM raw_vault.HUB_DEVICE_LOCATION )
SRC_SDLS           as ( SELECT * FROM raw_vault.SAT_DEVICE_LOCATION_SUBSCRIPTION__FLO_DYNAMODB )
*/
---- LOGIC LAYER ----

, LOGIC_LCD as (
    SELECT
        ICD_DEVICE_HK
      , PAIRED_DEVICE_HK
      , DEVICE_HK
    FROM SRC_LCD
)

, LOGIC_HP as (
    SELECT
        PAIRED_DEVICE_HK                                             as                                HP_PAIRED_DEVICE_HK
      , PAIRED_DEVICE_BK
    FROM SRC_HP
)

, LOGIC_HD as (
    SELECT
        DEVICE_HK                                                    as                                       HD_DEVICE_HK
      , DEVICE_BK
      , BKCC
      , REC_SRC
    FROM SRC_HD
)

, LOGIC_SDS as (
    SELECT
        DEVICE_HK                                                    as                                      SDS_DEVICE_HK
      , MAKE                                                         as                                        DEVICE_MAKE
      , MODEL
      , CASE WHEN DEVICE_MAKE = 'flo_device_v2' THEN 1 ELSE 0 END    as                                      IS_SWS_DEVICE
      , CASE WHEN DEVICE_MAKE = 'puck_oem' THEN 1 ELSE 0 END         as                                      IS_SWD_DEVICE
    FROM SRC_SDS
)

, LOGIC_SDE as (
    SELECT
        PAIRED_DEVICE_EVENT_HK                                       as                         SDE_PAIRED_DEVICE_EVENT_HK
    FROM SRC_SDE
)

, LOGIC_SPD as (
    SELECT
        PAIRED_DEVICE_HK                                             as                               SPD_PAIRED_DEVICE_HK
      , ID                                                           as                                             ICD_ID
      , DEVICE_ID
      , _FIVETRAN_DELETED                                            as                                   FIVETRAN_DELETED
    FROM SRC_SPD
)

, LOGIC_LDL as (
    SELECT
        PAIRED_DEVICE_LOCATION_HK
      , PAIRED_DEVICE_HK                                             as                               LDL_PAIRED_DEVICE_HK
      , DEVICE_LOCATION_HK
    FROM SRC_LDL
)

, LOGIC_HL as (
    SELECT
        DEVICE_LOCATION_HK                                           as                              HL_DEVICE_LOCATION_HK
      , DEVICE_LOCATION_BK                                           as                                        LOCATION_ID
    FROM SRC_HL
)

, LOGIC_SDLS as (
    SELECT
        DEVICE_LOCATION_SUBSCRIPTION_HK                              as               SDLS_DEVICE_LOCATION_SUBSCRIPTION_HK
      , STRIPE_PROVIDER_DATA
      , (REPLACE(STRIPE_PROVIDER_DATA:"status",'"',''))              as                                SUBSCRIPTION_STATUS
      , CASE WHEN SUBSCRIPTION_STATUS = 'active' THEN 1 ELSE 0 END   as                              IS_ACTIVE_FLO_PROTECT
      , LOAD_DTS
    FROM SRC_SDLS
)
---- RENAME LAYER ----

, RENAME_LCD as (
    SELECT
        ICD_DEVICE_HK
      , PAIRED_DEVICE_HK
      , DEVICE_HK
    FROM LOGIC_LCD
)

, RENAME_HP as (
    SELECT
        HP_PAIRED_DEVICE_HK
      , PAIRED_DEVICE_BK
    FROM LOGIC_HP
)

, RENAME_HD as (
    SELECT
        HD_DEVICE_HK
      , DEVICE_BK
      , BKCC
      , REC_SRC
    FROM LOGIC_HD
)

, RENAME_SDS as (
    SELECT
        SDS_DEVICE_HK
      , DEVICE_MAKE
      , MODEL
      , IS_SWS_DEVICE
      , IS_SWD_DEVICE
    FROM LOGIC_SDS
)

, RENAME_SPD as (
    SELECT
        SPD_PAIRED_DEVICE_HK
      , ICD_ID
      , DEVICE_ID
      , FIVETRAN_DELETED
    FROM LOGIC_SPD
)

, RENAME_SDE as (
    SELECT
        SDE_PAIRED_DEVICE_EVENT_HK
    FROM LOGIC_SDE
)

, RENAME_LDL as (
    SELECT
        PAIRED_DEVICE_LOCATION_HK
      , LDL_PAIRED_DEVICE_HK
      , DEVICE_LOCATION_HK
    FROM LOGIC_LDL
)

, RENAME_HL as (
    SELECT
        HL_DEVICE_LOCATION_HK
      , LOCATION_ID
    FROM LOGIC_HL
)

, RENAME_SDLS as (
    SELECT
        SDLS_DEVICE_LOCATION_SUBSCRIPTION_HK
      , STRIPE_PROVIDER_DATA
      , SUBSCRIPTION_STATUS
      , IS_ACTIVE_FLO_PROTECT
      , LOAD_DTS
    FROM LOGIC_SDLS
)
---- FILTER LAYER ----

, FILTER_LCD as (
    SELECT *
    FROM RENAME_LCD
)

, FILTER_HP as (
    SELECT *
    FROM RENAME_HP
)

, FILTER_HD as (
    SELECT *
    FROM RENAME_HD
)

, FILTER_SDS as (
    SELECT *
    FROM RENAME_SDS
)

, FILTER_SDE as (
    SELECT *
    FROM RENAME_SDE
)

, FILTER_SPD as (
    SELECT *
    FROM RENAME_SPD
)

, FILTER_LDL as (
    SELECT *
    FROM RENAME_LDL
)

, FILTER_HL as (
    SELECT *
    FROM RENAME_HL
)

, FILTER_SDLS as (
    SELECT *
    FROM RENAME_SDLS
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_LCD
    INNER JOIN FILTER_HP
        ON PAIRED_DEVICE_HK = HP_PAIRED_DEVICE_HK
    INNER JOIN FILTER_HD
        ON DEVICE_HK = HD_DEVICE_HK
    LEFT JOIN FILTER_SDS
        ON DEVICE_HK = SDS_DEVICE_HK
    LEFT JOIN FILTER_SDE
        ON PAIRED_DEVICE_HK = SDE_PAIRED_DEVICE_EVENT_HK
    LEFT JOIN FILTER_SPD
        ON PAIRED_DEVICE_HK = SPD_PAIRED_DEVICE_HK
    LEFT JOIN FILTER_LDL
        ON PAIRED_DEVICE_HK = LDL_PAIRED_DEVICE_HK
    LEFT JOIN FILTER_HL
        ON DEVICE_LOCATION_HK = HL_DEVICE_LOCATION_HK
    LEFT JOIN FILTER_SDLS
        ON DEVICE_LOCATION_HK = SDLS_DEVICE_LOCATION_SUBSCRIPTION_HK
)

---- FINAL LAYER ----
SELECT
          ICD_DEVICE_HK
        , PAIRED_DEVICE_HK
        , DEVICE_HK
        , PAIRED_DEVICE_BK
        , DEVICE_BK
        , BKCC
        , REC_SRC
        , DEVICE_MAKE
        , MODEL
        , IS_SWS_DEVICE
        , IS_SWD_DEVICE
        , ICD_ID
        , DEVICE_ID
        , FIVETRAN_DELETED
        , PAIRED_DEVICE_LOCATION_HK
        , LDL_PAIRED_DEVICE_HK
        , DEVICE_LOCATION_HK
        , LOCATION_ID
        , STRIPE_PROVIDER_DATA
        , SUBSCRIPTION_STATUS
        , IS_ACTIVE_FLO_PROTECT
        , LOAD_DTS
FROM JOIN_RESULT
