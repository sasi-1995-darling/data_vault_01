{{ config(materialized='ephemeral') }}
---- SRC LAYER ----
WITH
SRC_LCD            as ( SELECT DEVICE_HK, ICD_DEVICE_HK, PAIRED_DEVICE_HK, REC_SRC FROM {{ ref('lnk_icd_device') }} as SRC  ),
SRC_HP             as ( SELECT PAIRED_DEVICE_BK, PAIRED_DEVICE_HK FROM {{ ref('hub_paired_device') }} as SRC  ),
SRC_HD             as ( SELECT BKCC, DEVICE_BK, DEVICE_HK FROM {{ ref('hub_device_v2') }} as SRC  ),
SRC_SDS            as ( SELECT CREATED_TIME, DEVICE_HK, IS_CONNECTED, LAST_HEARD_FROM_TIME, MAKE, MODEL, UPDATED_TIME FROM {{ ref('sat_device_status__flo_service') }} as SRC 
                        qualify 1= row_number() over(partition by DEVICE_HK order by LOAD_DTS DESC) )

/*
SRC_LCD            as ( SELECT * FROM raw_vault.LNK_ICD_DEVICE )
SRC_HP             as ( SELECT * FROM raw_vault.HUB_PAIRED_DEVICE )
SRC_HD             as ( SELECT * FROM raw_vault.HUB_DEVICE_V2 )
SRC_SDS            as ( SELECT * FROM raw_vault.SAT_DEVICE_STATUS__FLO_SERVICE )
*/
---- LOGIC LAYER ----

, LOGIC_LCD as (
    SELECT
        ICD_DEVICE_HK
      , PAIRED_DEVICE_HK
      , DEVICE_HK
      , REC_SRC
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
    FROM SRC_HD
)

, LOGIC_SDS as (
    SELECT
        DEVICE_HK                                                    as                                      SDS_DEVICE_HK
      , MAKE
      , MODEL
      , IS_CONNECTED
      , DATEDIFF (HOUR, LAST_HEARD_FROM_TIME, CURRENT_TIMESTAMP()) <= 24 as                                          IS_ONLINE
      , LAST_HEARD_FROM_TIME                                         as                              LAST_CLOUD_CONTACT_TS
      , CREATED_TIME
      , UPDATED_TIME
    FROM SRC_SDS
)
---- RENAME LAYER ----

, RENAME_LCD as (
    SELECT
        ICD_DEVICE_HK
      , PAIRED_DEVICE_HK
      , DEVICE_HK
      , REC_SRC
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
    FROM LOGIC_HD
)

, RENAME_SDS as (
    SELECT
        SDS_DEVICE_HK
      , MAKE
      , MODEL
      , IS_CONNECTED
      , IS_ONLINE
      , LAST_CLOUD_CONTACT_TS
      , CREATED_TIME
      , UPDATED_TIME
    FROM LOGIC_SDS
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

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_LCD
    INNER JOIN FILTER_HP
        ON PAIRED_DEVICE_HK = HP_PAIRED_DEVICE_HK
    INNER JOIN FILTER_HD
        ON DEVICE_HK = HD_DEVICE_HK
    INNER JOIN FILTER_SDS
        ON DEVICE_HK = SDS_DEVICE_HK
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
        , MAKE
        , MODEL
        , IS_CONNECTED
        , IS_ONLINE
        , LAST_CLOUD_CONTACT_TS
        , CREATED_TIME
        , UPDATED_TIME
FROM JOIN_RESULT
