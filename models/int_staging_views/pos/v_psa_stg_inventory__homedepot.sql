---- SRC LAYER ----
WITH
SRC_S              as ( SELECT DAY, D_STORE_NBR, HOME_DEPOT_ACCOUNT, MANUF_PART_NUMBER, MERCH_VENDOR, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, RUN_DATE, 
                        SKU_NBR, SKU_STATUS, STR_OH, STR_OH_UNITS_DLY FROM {{ source('home_depot', 'hd_askuity_inventory') }} as SRC 
                        /* The following qualify clause is required to pull the latest row pushed to PSA based on these PK columns, only the most recent record needed*/
                        qualify 1 = row_number() over(partition by  day,manuf_part_number, sku_nbr, d_store_nbr, merch_vendor, sku_status, home_depot_account order by psa_load_dts desc) ),
SRC_A              as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S              as ( SELECT * FROM home_depot.hd_askuity_inventory )
SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        D_STORE_NBR                                                  as                                           STORE_BK
      , DAY
      , MANUF_PART_NUMBER
      , SKU_NBR
      , D_STORE_NBR
      , MERCH_VENDOR
      , SKU_STATUS
      , HOME_DEPOT_ACCOUNT
      , RUN_DATE
      , CONVERT_TIMEZONE('UTC', RUN_DATE)                            as                                           LOAD_DTS
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
      , DAY
      , MANUF_PART_NUMBER
      , SKU_NBR
      , D_STORE_NBR
      , MERCH_VENDOR
      , SKU_STATUS
      , HOME_DEPOT_ACCOUNT
      , RUN_DATE
      , LOAD_DTS
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
)

, FILTER_A as (
    SELECT *
    FROM RENAME_A
    WHERE rec_src = 'US.HIVE.ASKUITY.HD_ASKUITY_INVENTORY'
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
        , DAY
        , MANUF_PART_NUMBER
        , SKU_NBR
        , D_STORE_NBR
        , MERCH_VENDOR
        , SKU_STATUS
        , HOME_DEPOT_ACCOUNT
        , LOAD_DTS
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
              IFNULL(TRIM(STR_OH::text), '^^') 
            , '||', IFNULL(TRIM(STR_OH_UNITS_DLY::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
