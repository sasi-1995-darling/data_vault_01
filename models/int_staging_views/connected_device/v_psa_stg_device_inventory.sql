---- SRC LAYER ----
WITH
SRC_D1             as ( SELECT CYPN, CYSN, DEVICE_ID, ID, MANUFACTURE_DATE, MFG_NUMBER, NEW_SERIAL_NUMBER, ORIG_FW_VER, PALLET_ID, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, REMARK, SERIAL_NUMBER, SHEET_NUMBER, SKU, TIN__, VTECH_CARTON__, _FIVETRAN_DELETED, _FIVETRAN_SYNCED FROM {{ source('data_prod_device_inventory_public', 'device_info') }} as SRC  ),
SRC_A1             as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_D1             as ( SELECT * FROM data_prod_device_inventory_public.device_info )
SRC_A1             as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_D1 as (
    SELECT
        ID
      , SKU
      , MFG_NUMBER
      , SERIAL_NUMBER
      , PALLET_ID
      , CYSN
      , CYPN
      , ORIG_FW_VER
      , SHEET_NUMBER
      , MANUFACTURE_DATE
      , VTECH_CARTON__                                               as                                       VTECH_CARTON
      , TIN__                                                        as                                                TIN
      , NEW_SERIAL_NUMBER
      , REMARK
      , _FIVETRAN_DELETED                                            as                                   FIVETRAN_DELETED
      , _FIVETRAN_SYNCED                                             as                                    FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , DEVICE_ID                                                    as                                      RAW_DEVICE_ID
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
        ID
      , SKU
      , MFG_NUMBER
      , SERIAL_NUMBER
      , PALLET_ID
      , CYSN
      , CYPN
      , ORIG_FW_VER
      , SHEET_NUMBER
      , MANUFACTURE_DATE
      , VTECH_CARTON
      , TIN
      , NEW_SERIAL_NUMBER
      , REMARK
      , FIVETRAN_DELETED
      , FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , RAW_DEVICE_ID
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
    WHERE rec_src = 'US.DATA_PROD_DEVICE_INVENTORY_PUBLIC.DEVICE_INFO'
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
          COALESCE(RAW_DEVICE_ID, '-1')                                as DEVICE_BK
        , CONVERT_TIMEZONE('UTC', PSA_LOAD_DTS)                        as LOAD_DTS
        , ID
        , SKU
        , MFG_NUMBER
        , SERIAL_NUMBER
        , PALLET_ID
        , CYSN
        , CYPN
        , ORIG_FW_VER
        , SHEET_NUMBER
        , MANUFACTURE_DATE
        , VTECH_CARTON
        , TIN
        , NEW_SERIAL_NUMBER
        , REMARK
        , FIVETRAN_DELETED
        , FIVETRAN_SYNCED
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(DEVICE_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as DEVICE_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(ID::text), '^^') 
            , '||', IFNULL(TRIM(SKU::text), '^^') 
            , '||', IFNULL(TRIM(MFG_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(SERIAL_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(PALLET_ID::text), '^^') 
            , '||', IFNULL(TRIM(CYSN::text), '^^') 
            , '||', IFNULL(TRIM(CYPN::text), '^^') 
            , '||', IFNULL(TRIM(ORIG_FW_VER::text), '^^') 
            , '||', IFNULL(TRIM(SHEET_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(MANUFACTURE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(VTECH_CARTON::text), '^^') 
            , '||', IFNULL(TRIM(TIN::text), '^^') 
            , '||', IFNULL(TRIM(NEW_SERIAL_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(REMARK::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
