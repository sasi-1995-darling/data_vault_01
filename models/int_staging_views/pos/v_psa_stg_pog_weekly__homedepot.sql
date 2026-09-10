---- SRC LAYER ----
WITH
SRC_hdampgw        as ( SELECT * FROM {{ source('home_depot', 'hd_askuity_master_pog_weekly') }} as SRC  ),
SRC_a              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_hdampgw        as ( SELECT * FROM home_depot.hd_askuity_master_pog_weekly )
, SRC_a              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_hdampgw as (
    SELECT
        D_STORE_NBR                                                  as                                           STORE_BK
      , D_STORE_NBR
      , MANUF_PART_NUMBER
      , SKU_NBR
      , WEEK
      , HOME_DEPOT_ACCOUNT
      , D_ASSORTMENT
      , D_ACTIVE_SKU_2
      , D_POG_2
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , CONVERT_TIMEZONE('UTC',IFF(RUN_DATE IS NULL, PSA_LOAD_DTS, RUN_DATE)) as                                           LOAD_DTS
    FROM SRC_hdampgw
)

, LOGIC_a as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_a
)
---- RENAME LAYER ----

, RENAME_hdampgw as (
    SELECT
        STORE_BK
      , D_STORE_NBR
      , MANUF_PART_NUMBER
      , SKU_NBR
      , WEEK
      , HOME_DEPOT_ACCOUNT
      , D_ASSORTMENT
      , D_ACTIVE_SKU_2
      , D_POG_2
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
    FROM LOGIC_hdampgw
)

, RENAME_a as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_a
)
---- FILTER LAYER ----

, FILTER_hdampgw as (
    SELECT *
    FROM RENAME_hdampgw
)

, FILTER_a as (
    SELECT *
    FROM RENAME_a
    WHERE rec_src = 'US.HIVE.ASKUITY.HD_ASKUITY_MASTER_POG_WEEKLY'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_hdampgw
    INNER JOIN FILTER_a
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          STORE_BK
        , D_STORE_NBR
        , MANUF_PART_NUMBER
        , SKU_NBR
        , WEEK
        , HOME_DEPOT_ACCOUNT
        , D_ASSORTMENT
        , D_ACTIVE_SKU_2
        , D_POG_2
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(STORE_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as STORE_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(D_STORE_NBR::text), '^^') 
            , '||', IFNULL(TRIM(MANUF_PART_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(SKU_NBR::text), '^^') 
            , '||', IFNULL(TRIM(WEEK::text), '^^') 
            , '||', IFNULL(TRIM(HOME_DEPOT_ACCOUNT::text), '^^') 
            , '||', IFNULL(TRIM(D_ASSORTMENT::text), '^^') 
            , '||', IFNULL(TRIM(D_ACTIVE_SKU_2::text), '^^') 
            , '||', IFNULL(TRIM(D_POG_2::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
