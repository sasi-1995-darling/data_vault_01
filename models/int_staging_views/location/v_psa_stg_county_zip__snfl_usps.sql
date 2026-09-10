---- SRC LAYER ----
WITH
SRC_county_zip     as ( SELECT * FROM {{ source('us_zip_code_crosswalk_hudusps', 'county_zip') }} as SRC  ),
SRC_a              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_county_zip     as ( SELECT * FROM us_zip_code_crosswalk_hudusps.county_zip )
, SRC_a              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_county_zip as (
    SELECT
        MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(COUNTY as VARCHAR)),''), '^^')
        )))                                                          as                                          COUNTY_HK
      , COUNTY                                                       as                                          COUNTY_BK
      , COUNTY
      , ZIP
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
            , COALESCE(NULLIF(TRIM(CAST(COUNTY as VARCHAR)),''), '^^')
        )))                                                          as                                  LNK_ZIP_COUNTY_HK
      , MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(ZIP as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(COUNTY as VARCHAR)),''), '^^')
        )))                                                          as                                             ZIP_HK
    FROM SRC_county_zip
)

, LOGIC_a as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_a
)
---- RENAME LAYER ----

, RENAME_county_zip as (
    SELECT
        COUNTY_HK
      , COUNTY_BK
      , COUNTY
      , ZIP
      , USPS_ZIP_PREF_CITY
      , USPS_ZIP_PREF_STATE
      , RES_RATIO
      , BUS_RATIO
      , OTH_RATIO
      , TOT_RATIO
      , UPDATED_ON
      , LOAD_DTS
      , LNK_ZIP_COUNTY_HK
      , ZIP_HK
    FROM LOGIC_county_zip
)

, RENAME_a as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_a
)
---- FILTER LAYER ----

, FILTER_county_zip as (
    SELECT *
    FROM RENAME_county_zip
)

, FILTER_a as (
    SELECT *
    FROM RENAME_a
    WHERE rec_src = 'USOHNO.SNFL.ZIPCODE_CROSSWALK.COUNTY_ZIP'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_county_zip
    INNER JOIN FILTER_a
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          COUNTY_HK
        , COUNTY_BK
        , COUNTY
        , ZIP
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
        , LNK_ZIP_COUNTY_HK
        , ZIP_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(COUNTY::text), '^^') 
            , '||', IFNULL(TRIM(ZIP::text), '^^') 
            , '||', IFNULL(TRIM(USPS_ZIP_PREF_CITY::text), '^^') 
            , '||', IFNULL(TRIM(USPS_ZIP_PREF_STATE::text), '^^') 
            , '||', IFNULL(TRIM(RES_RATIO::text), '^^') 
            , '||', IFNULL(TRIM(BUS_RATIO::text), '^^') 
            , '||', IFNULL(TRIM(OTH_RATIO::text), '^^') 
            , '||', IFNULL(TRIM(TOT_RATIO::text), '^^') 
            , '||', IFNULL(TRIM(UPDATED_ON::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
