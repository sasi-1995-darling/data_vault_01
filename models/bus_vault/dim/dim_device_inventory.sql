---- SRC LAYER ----
WITH
SRC_PB             as ( SELECT BKCC, DEVICE_BK, MFG_NUMBER, NEW_SERIAL_NUMBER, ORIG_FW_VER, PAIRED_DEVICE_BK, PALLET_ID, REC_SRC, REMARK, SERIAL_NUMBER, SHEET_NUMBER, SKU, TIN, VTECH_CARTON FROM {{ ref('pb_device_inventory') }} as SRC  )

/*
SRC_PB             as ( SELECT * FROM BUS_VAULT.PB_DEVICE_INVENTORY )
*/
---- LOGIC LAYER ----

, LOGIC_PB as (
    SELECT
        PAIRED_DEVICE_BK
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
    FROM SRC_PB
)
---- RENAME LAYER ----

, RENAME_PB as (
    SELECT
        PAIRED_DEVICE_BK
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
    FROM LOGIC_PB
)
---- FILTER LAYER ----

, FILTER_PB as (
    SELECT *
    FROM RENAME_PB
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_PB
)

---- FINAL LAYER ----
SELECT
          PAIRED_DEVICE_BK
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
