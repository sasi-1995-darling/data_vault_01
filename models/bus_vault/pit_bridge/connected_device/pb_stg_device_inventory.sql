{{ config(materialized='ephemeral') }}
---- SRC LAYER ----
WITH
SRC_LCD            as ( SELECT DEVICE_HK, ICD_DEVICE_HK, PAIRED_DEVICE_HK, REC_SRC FROM {{ ref('lnk_icd_device') }} as SRC  ),
SRC_HP             as ( SELECT PAIRED_DEVICE_BK, PAIRED_DEVICE_HK FROM {{ ref('hub_paired_device') }} as SRC  ),
SRC_HD             as ( SELECT BKCC, DEVICE_BK, DEVICE_HK FROM {{ ref('hub_device_v2') }} as SRC  ),
SRC_SDI            as ( SELECT CYPN, CYSN, DEVICE_HK, MANUFACTURE_DATE, MFG_NUMBER, NEW_SERIAL_NUMBER, ORIG_FW_VER, PALLET_ID, REMARK, SERIAL_NUMBER, SHEET_NUMBER, SKU, TIN, VTECH_CARTON FROM {{ ref('sat_device_inventory__flo_public') }} as SRC 
                        qualify 1= row_number() over(partition by DEVICE_HK order by LOAD_DTS DESC) )

/*
SRC_LCD            as ( SELECT * FROM raw_vault.LNK_ICD_DEVICE )
SRC_HP             as ( SELECT * FROM raw_vault.HUB_PAIRED_DEVICE )
SRC_HD             as ( SELECT * FROM raw_vault.HUB_DEVICE_V2 )
SRC_SDI            as ( SELECT * FROM raw_vault.SAT_DEVICE_INVENTORY__FLO_PUBLIC )
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

, LOGIC_SDI as (
    SELECT
        DEVICE_HK                                                    as                                      SDI_DEVICE_HK
      , TRIM(SKU)                                                   as                                      SKU
      , MFG_NUMBER
      , SERIAL_NUMBER
      , PALLET_ID
      , ORIG_FW_VER
      , SHEET_NUMBER
      , VTECH_CARTON
      , TIN
      , NEW_SERIAL_NUMBER
      , REMARK
    FROM SRC_SDI
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

, RENAME_SDI as (
    SELECT
        SDI_DEVICE_HK
      , SKU
      , MFG_NUMBER
      , SERIAL_NUMBER
      , PALLET_ID
      , ORIG_FW_VER
      , SHEET_NUMBER
      , VTECH_CARTON
      , TIN
      , NEW_SERIAL_NUMBER
      , REMARK
    FROM LOGIC_SDI
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

, FILTER_SDI as (
    SELECT *
    FROM RENAME_SDI
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_LCD
    INNER JOIN FILTER_HP
        ON PAIRED_DEVICE_HK = HP_PAIRED_DEVICE_HK
    INNER JOIN FILTER_HD
        ON DEVICE_HK = HD_DEVICE_HK
    INNER JOIN FILTER_SDI
        ON DEVICE_HK = SDI_DEVICE_HK
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
        , SKU
        , MFG_NUMBER
        , SERIAL_NUMBER
        , PALLET_ID
        , ORIG_FW_VER
        , SHEET_NUMBER
        , VTECH_CARTON
        , TIN
        , NEW_SERIAL_NUMBER
        , REMARK
FROM JOIN_RESULT
