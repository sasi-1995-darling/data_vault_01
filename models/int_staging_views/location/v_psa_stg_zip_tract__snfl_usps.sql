---- SRC LAYER ----
WITH
SRC_zip_tract      as ( SELECT * FROM {{ source('us_zip_code_crosswalk_hudusps', 'zip_tract') }} as SRC  ),
SRC_a              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_zip_tract      as ( SELECT * FROM us_zip_code_crosswalk_hudusps.zip_tract )
, SRC_a              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_zip_tract as (
    SELECT
        MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(ZIP as VARCHAR)),''), '^^')
        )))                                                          as                                             ZIP_HK
      , ZIP                                                          as                                             ZIP_BK
      , ZIP
      , TRACT
      , USPS_ZIP_PREF_CITY
      , USPS_ZIP_PREF_STATE
      , RES_RATIO
      , BUS_RATIO
      , OTH_RATIO
      , TOT_RATIO
      , UPDATED_ON
      , to_timestamp(UPDATED_ON)                                     as                                           LOAD_DTS
      , MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(ZIP as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(TRACT as VARCHAR)),''), '^^')
        )))                                                          as                                   LNK_ZIP_TRACT_HK
      , MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(TRACT as VARCHAR)),''), '^^')
        )))                                                          as                                           TRACT_HK
    FROM SRC_zip_tract
)

, LOGIC_a as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_a
)
---- RENAME LAYER ----

, RENAME_zip_tract as (
    SELECT
        ZIP_HK
      , ZIP_BK
      , ZIP
      , TRACT
      , USPS_ZIP_PREF_CITY
      , USPS_ZIP_PREF_STATE
      , RES_RATIO
      , BUS_RATIO
      , OTH_RATIO
      , TOT_RATIO
      , UPDATED_ON
      , LOAD_DTS
      , LNK_ZIP_TRACT_HK
      , TRACT_HK
    FROM LOGIC_zip_tract
)

, RENAME_a as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_a
)
---- FILTER LAYER ----

, FILTER_zip_tract as (
    SELECT *
    FROM RENAME_zip_tract
)

, FILTER_a as (
    SELECT *
    FROM RENAME_a
    WHERE rec_src = 'USOHNO.SNFL.ZIPCODE_CROSSWALK.ZIP_TRACT'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_zip_tract
    INNER JOIN FILTER_a
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          ZIP_HK
        , ZIP_BK
        , ZIP
        , TRACT
        , USPS_ZIP_PREF_CITY
        , USPS_ZIP_PREF_STATE
        , RES_RATIO
        , BUS_RATIO
        , OTH_RATIO
        , TOT_RATIO
        , UPDATED_ON
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , LNK_ZIP_TRACT_HK
        , TRACT_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(ZIP::text), '^^') 
            , '||', IFNULL(TRIM(TRACT::text), '^^') 
            , '||', IFNULL(TRIM(USPS_ZIP_PREF_CITY::text), '^^') 
            , '||', IFNULL(TRIM(USPS_ZIP_PREF_STATE::text), '^^') 
            , '||', IFNULL(TRIM(RES_RATIO::text), '^^') 
            , '||', IFNULL(TRIM(BUS_RATIO::text), '^^') 
            , '||', IFNULL(TRIM(OTH_RATIO::text), '^^') 
            , '||', IFNULL(TRIM(TOT_RATIO::text), '^^') 
            , '||', IFNULL(TRIM(UPDATED_ON::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
