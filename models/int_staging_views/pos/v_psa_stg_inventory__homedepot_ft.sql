---- SRC LAYER ----
WITH
SRC_S              as ( SELECT DAY_1, D_STORE_NBR, HOME_DEPOT_ACCOUNT, MANUF_PART_NUMBER, MERCH_VENDOR, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, SKU_NBR, SKU_STATUS, STR_OH, STR_OH_UNITS_DLY, STR_OO_DLY, STR_OO_UNITS_DLY, _FIVETRAN_SYNCED FROM {{ source('home_depot_ft_psa', 'vendor_drill_inv_data_us') }} as SRC  ),
SRC_A              as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S              as ( SELECT * FROM home_depot_ft_psa.vendor_drill_inv_data_us )
SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        D_STORE_NBR                                                  as                                           STORE_BK
      , D_STORE_NBR
      , MANUF_PART_NUMBER
      , DAY_1
      , DAY_1::DATE                                                  as                                                DAY
      , _FIVETRAN_SYNCED
      , CONVERT_TIMEZONE('UTC',_FIVETRAN_SYNCED)                     as                                           LOAD_DTS
      , MERCH_VENDOR
      , SKU_NBR                                                      as                                         IN_SKU_NBR
      , SKU_STATUS
      , HOME_DEPOT_ACCOUNT
      , STR_OO_UNITS_DLY
      , STR_OO_DLY
      , STR_OH
      , STR_OH_UNITS_DLY
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
    FROM SRC_S
)

, LOGIC_A as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_A
)
---- RENAME LAYER ----

, RENAME_S as (
    SELECT
        STORE_BK
      , D_STORE_NBR
      , MANUF_PART_NUMBER
      , DAY_1
      , DAY
      , _FIVETRAN_SYNCED
      , LOAD_DTS
      , MERCH_VENDOR
      , IN_SKU_NBR
      , SKU_STATUS
      , HOME_DEPOT_ACCOUNT
      , STR_OO_UNITS_DLY
      , STR_OO_DLY
      , STR_OH
      , STR_OH_UNITS_DLY
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
    FROM LOGIC_S
)

, RENAME_A as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_A
)
---- FILTER LAYER ----

, FILTER_S as (
    SELECT *
    FROM RENAME_S
    WHERE PSA_DELETE_IND='N'
)

, FILTER_A as (
    SELECT *
    FROM RENAME_A
    WHERE rec_src = 'US.HIVE.ASKUITY_FT.VENDOR_DRILL_INV_DATA_US'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_S
    INNER JOIN FILTER_A
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          STORE_BK
        , D_STORE_NBR
        , MANUF_PART_NUMBER
        , DAY
        , LOAD_DTS
        , MERCH_VENDOR
        , IN_SKU_NBR::TEXT                                             as SKU_NBR
        , SKU_STATUS
        , HOME_DEPOT_ACCOUNT
        , STR_OO_UNITS_DLY
        , STR_OO_DLY
        , STR_OH
        , STR_OH_UNITS_DLY
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(D_STORE_NBR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as STORE_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(STR_OO_UNITS_DLY::text), '^^') 
            , '||', IFNULL(TRIM(STR_OO_DLY::text), '^^') 
            , '||', IFNULL(TRIM(STR_OH::text), '^^') 
            , '||', IFNULL(TRIM(STR_OH_UNITS_DLY::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
