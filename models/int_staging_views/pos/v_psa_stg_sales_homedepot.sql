---- SRC LAYER ----
WITH
SRC_S              as ( SELECT * FROM {{ source('home_depot_psa', 'hd_askuity_pos') }} as SRC 
                        /* The following qualify clause is required to pull the first row pushed to PSA based on these PK columns*/
                        qualify 1 = row_number() over(partition by  day,sku_nbr,d_store_nbr,merch_vendor,manuf_part_number,fulfillment_channel,home_depot_account,sku_status,run_date order by psa_load_dts )  ),
SRC_A              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S              as ( SELECT * FROM home_depot_psa.hd_askuity_pos )
, SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        D_STORE_NBR                                                  as                                           STORE_BK
      , D_STORE_NBR
      , MANUF_PART_NUMBER
      , DAY
      , CONVERT_TIMEZONE('UTC',RUN_DATE)                             as                                           LOAD_DTS
      , FULFILLMENT_CHANNEL
      , MERCH_VENDOR
      , SKU_NBR
      , SKU_STATUS
      , HOME_DEPOT_ACCOUNT
      , SALES_UNITS
      , M_TY_RETURNS_SUM
      , M_TY_RETURN_UNITS_SUM
      , SALES
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
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
      , DAY
      , LOAD_DTS
      , FULFILLMENT_CHANNEL
      , MERCH_VENDOR
      , SKU_NBR
      , SKU_STATUS
      , HOME_DEPOT_ACCOUNT
      , SALES_UNITS
      , M_TY_RETURNS_SUM
      , M_TY_RETURN_UNITS_SUM
      , SALES
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
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
    WHERE rec_src = 'US.HIVE.ASKUITY.HD_ASKUITY_POS'
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
        , FULFILLMENT_CHANNEL
        , MERCH_VENDOR
        , SKU_NBR
        , SKU_STATUS
        , HOME_DEPOT_ACCOUNT
        , SALES_UNITS
        , M_TY_RETURNS_SUM
        , M_TY_RETURN_UNITS_SUM
        , SALES
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(D_STORE_NBR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as STORE_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(SALES_UNITS::text), '^^') 
            , '||', IFNULL(TRIM(M_TY_RETURNS_SUM::text), '^^') 
            , '||', IFNULL(TRIM(M_TY_RETURN_UNITS_SUM::text), '^^') 
            , '||', IFNULL(TRIM(SALES::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
