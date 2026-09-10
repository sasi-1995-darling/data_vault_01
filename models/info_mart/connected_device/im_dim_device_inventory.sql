{{ config(alias='dim_device_inventory') }}
---- SRC LAYER ----
WITH
SRC_DI             as ( SELECT BKCC, DEVICE_BK, MFG_NUMBER, NEW_SERIAL_NUMBER, ORIG_FW_VER, PAIRED_DEVICE_BK, PALLET_ID, REC_SRC, REMARK, SERIAL_NUMBER, SHEET_NUMBER, SKU, TIN, VTECH_CARTON FROM {{ ref('dim_device_inventory') }} as SRC  )

/*
SRC_DI             as ( SELECT * FROM BUS_VAULT.DIM_DEVICE_INVENTORY )
*/
---- LOGIC LAYER ----

, LOGIC_DI as (
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
    FROM SRC_DI
)
---- RENAME LAYER ----

, RENAME_DI as (
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
    FROM LOGIC_DI
)
---- FILTER LAYER ----

, FILTER_DI as (
    SELECT *
    FROM RENAME_DI
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_DI
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
