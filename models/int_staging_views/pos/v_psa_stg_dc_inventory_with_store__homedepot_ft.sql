---- SRC LAYER ----
WITH
SRC_DC             as ( SELECT DAY_1, D_DC_NAME, D_DH_DC_NBR, HOME_DEPOT_ACCOUNT, MANUF_PART_NUMBER, M_DC_OH_AMT, M_DC_OH_UNITS, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, SKU_NBR, _FIVETRAN_SYNCED FROM {{ source('home_depot_ft_psa', 'vendor_drill_dc_inv_data_with_store_us') }} as SRC  ),
SRC_BKCC           as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_DC             as ( SELECT * FROM home_depot_ft_psa.vendor_drill_dc_inv_data_with_store_us )
SRC_BKCC           as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_DC as (
    SELECT
        HOME_DEPOT_ACCOUNT
      , DAY_1
      , MANUF_PART_NUMBER
      , SKU_NBR
      , CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED)                    as                                           LOAD_DTS
      , D_DH_DC_NBR
      , D_DH_DC_NBR::TEXT                                            as                                           STORE_BK
      , D_DC_NAME
      , M_DC_OH_UNITS
      , M_DC_OH_AMT
      , PSA_LOAD_DTS
      , _FIVETRAN_SYNCED
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
    FROM SRC_DC
)

, LOGIC_BKCC as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_BKCC
)
---- RENAME LAYER ----

, RENAME_DC as (
    SELECT
        HOME_DEPOT_ACCOUNT
      , DAY_1
      , MANUF_PART_NUMBER
      , SKU_NBR
      , LOAD_DTS
      , D_DH_DC_NBR
      , STORE_BK
      , D_DC_NAME
      , M_DC_OH_UNITS
      , M_DC_OH_AMT
      , PSA_LOAD_DTS
      , _FIVETRAN_SYNCED
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
    FROM LOGIC_DC
)

, RENAME_BKCC as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_BKCC
)
---- FILTER LAYER ----

, FILTER_DC as (
    SELECT *
    FROM RENAME_DC
    WHERE PSA_DELETE_IND='N'
)

, FILTER_BKCC as (
    SELECT *
    FROM RENAME_BKCC
    WHERE REC_SRC = 'US.HIVE.ASKUITY_FT.VENDOR_DRILL_DC_INV_DATA_WITH_STORE_US'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_DC
    INNER JOIN FILTER_BKCC
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          HOME_DEPOT_ACCOUNT
        , DAY_1
        , MANUF_PART_NUMBER
        , SKU_NBR::TEXT                                                as SKU_NBR
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(STORE_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as STORE_HK
        , LOAD_DTS
        , STORE_BK
        , D_DH_DC_NBR::TEXT                                            as D_DH_DC_NBR
        , D_DC_NAME
        , M_DC_OH_UNITS
        , M_DC_OH_AMT
        , PSA_LOAD_DTS
        , _FIVETRAN_SYNCED
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(D_DH_DC_NBR::text), '^^') 
            , '||', IFNULL(TRIM(D_DC_NAME::text), '^^') 
            , '||', IFNULL(TRIM(M_DC_OH_UNITS::text), '^^') 
            , '||', IFNULL(TRIM(M_DC_OH_AMT::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
