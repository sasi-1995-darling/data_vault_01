---- SRC LAYER ----
WITH
SRC_PBDI           as ( SELECT BKCC, DEVICE_BK, DEVICE_HK, ICD_DEVICE_HK, MFG_NUMBER, NEW_SERIAL_NUMBER, ORIG_FW_VER, PAIRED_DEVICE_BK, PAIRED_DEVICE_HK, PALLET_ID, REC_SRC, REMARK, SERIAL_NUMBER, SHEET_NUMBER, SKU, TIN, VTECH_CARTON FROM {{ ref('pb_stg_device_inventory') }} as SRC  )

/*
SRC_PBDI           as ( SELECT * FROM BUS_VAULT.PB_STG_DEVICE_INVENTORY )
*/
---- LOGIC LAYER ----

, LOGIC_PBDI as (
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
    FROM SRC_PBDI
)
---- RENAME LAYER ----

, RENAME_PBDI as (
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
    FROM LOGIC_PBDI
)
---- FILTER LAYER ----

, FILTER_PBDI as (
    SELECT *
    FROM RENAME_PBDI
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_PBDI
)

---- FINAL LAYER ----
SELECT
              row_number() over(order by 1)                            as SEQ_ID
        , CURRENT_DATE                                                 as SNAPSHOTDATE
        , CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP )                  as PB_LOAD_DTS
        , ICD_DEVICE_HK
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
