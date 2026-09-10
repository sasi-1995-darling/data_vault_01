---- SRC LAYER ----
WITH
SRC_county         as ( SELECT * FROM {{ source('us_zip_code_crosswalk_hudusps', 'county') }} as SRC  ),
SRC_a              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_county         as ( SELECT * FROM us_zip_code_crosswalk_hudusps.county )
, SRC_a              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_county as (
    SELECT
        MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(GEOID as VARCHAR)),''), '^^')
        )))                                                          as                                          COUNTY_HK
      , GEOID                                                        as                                          COUNTY_BK
      , USPS
      , GEOID
      , ANSICODE
      , NAME
      , POP10
      , HU10
      , ALAND
      , AWATER
      , ALAND_SQMI
      , AWATER_SQMI
      , INTPTLAT
      , INTPTLONG
      , UPDATED_ON
      , to_timestamp(UPDATED_ON)                                     as                                           LOAD_DTS
    FROM SRC_county
)

, LOGIC_a as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_a
)
---- RENAME LAYER ----

, RENAME_county as (
    SELECT
        COUNTY_HK
      , COUNTY_BK
      , USPS
      , GEOID
      , ANSICODE
      , NAME
      , POP10
      , HU10
      , ALAND
      , AWATER
      , ALAND_SQMI
      , AWATER_SQMI
      , INTPTLAT
      , INTPTLONG
      , UPDATED_ON
      , LOAD_DTS
    FROM LOGIC_county
)

, RENAME_a as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_a
)
---- FILTER LAYER ----

, FILTER_county as (
    SELECT *
    FROM RENAME_county
)

, FILTER_a as (
    SELECT *
    FROM RENAME_a
    WHERE rec_src = 'USOHNO.SNFL.ZIPCODE_CROSSWALK.COUNTY'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_county
    INNER JOIN FILTER_a
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          COUNTY_HK
        , COUNTY_BK
        , USPS
        , GEOID
        , ANSICODE
        , NAME
        , POP10
        , HU10
        , ALAND
        , AWATER
        , ALAND_SQMI
        , AWATER_SQMI
        , INTPTLAT
        , INTPTLONG
        , UPDATED_ON
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(USPS::text), '^^') 
            , '||', IFNULL(TRIM(GEOID::text), '^^') 
            , '||', IFNULL(TRIM(ANSICODE::text), '^^') 
            , '||', IFNULL(TRIM(NAME::text), '^^') 
            , '||', IFNULL(TRIM(POP10::text), '^^') 
            , '||', IFNULL(TRIM(HU10::text), '^^') 
            , '||', IFNULL(TRIM(ALAND::text), '^^') 
            , '||', IFNULL(TRIM(AWATER::text), '^^') 
            , '||', IFNULL(TRIM(ALAND_SQMI::text), '^^') 
            , '||', IFNULL(TRIM(AWATER_SQMI::text), '^^') 
            , '||', IFNULL(TRIM(INTPTLAT::text), '^^') 
            , '||', IFNULL(TRIM(INTPTLONG::text), '^^') 
            , '||', IFNULL(TRIM(UPDATED_ON::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
