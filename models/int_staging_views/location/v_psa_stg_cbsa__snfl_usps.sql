---- SRC LAYER ----
WITH
SRC_cbsa           as ( SELECT * FROM {{ source('us_zip_code_crosswalk_hudusps', 'cbsa') }} as SRC  ),
SRC_a              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_cbsa           as ( SELECT * FROM us_zip_code_crosswalk_hudusps.cbsa )
, SRC_a              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_cbsa as (
    SELECT
        MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(CBSA_CODE as VARCHAR)),''), '^^')
        )))                                                          as                                            CBSA_HK
      , CBSA_CODE                                                    as                                            CBSA_BK
      , CBSA_CODE
      , METRO_DIVISION_CODE
      , CSA_CODE
      , CBSA_TITLE
      , METROPOLITAN_MICROPOLITAN_STATISTICAL_AREA
      , METROPOLITAN_DIVISION_TITLE
      , COUNTY_COUNTY_EQUIVALENT
      , STATE_NAME
      , FIPS_STATE_CODE
      , FIPS_COUNTY_CODE
      , CENTRAL_OUTLYING_COUNTY
      , UPDATED_ON
      , to_timestamp(UPDATED_ON)                                     as                                           LOAD_DTS
    FROM SRC_cbsa
)

, LOGIC_a as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_a
)
---- RENAME LAYER ----

, RENAME_cbsa as (
    SELECT
        CBSA_HK
      , CBSA_BK
      , CBSA_CODE
      , METRO_DIVISION_CODE
      , CSA_CODE
      , CBSA_TITLE
      , METROPOLITAN_MICROPOLITAN_STATISTICAL_AREA
      , METROPOLITAN_DIVISION_TITLE
      , COUNTY_COUNTY_EQUIVALENT
      , STATE_NAME
      , FIPS_STATE_CODE
      , FIPS_COUNTY_CODE
      , CENTRAL_OUTLYING_COUNTY
      , UPDATED_ON
      , LOAD_DTS
    FROM LOGIC_cbsa
)

, RENAME_a as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_a
)
---- FILTER LAYER ----

, FILTER_cbsa as (
    SELECT *
    FROM RENAME_cbsa
)

, FILTER_a as (
    SELECT *
    FROM RENAME_a
    WHERE rec_src = 'USOHNO.SNFL.ZIPCODE_CROSSWALK.CBSA'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_cbsa
    INNER JOIN FILTER_a
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          CBSA_HK
        , CBSA_BK
        , CBSA_CODE
        , METRO_DIVISION_CODE
        , CSA_CODE
        , CBSA_TITLE
        , METROPOLITAN_MICROPOLITAN_STATISTICAL_AREA
        , METROPOLITAN_DIVISION_TITLE
        , COUNTY_COUNTY_EQUIVALENT
        , STATE_NAME
        , FIPS_STATE_CODE
        , FIPS_COUNTY_CODE
        , CENTRAL_OUTLYING_COUNTY
        , UPDATED_ON
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(METRO_DIVISION_CODE::text), '^^') 
            , '||', IFNULL(TRIM(CSA_CODE::text), '^^') 
            , '||', IFNULL(TRIM(CBSA_TITLE::text), '^^') 
            , '||', IFNULL(TRIM(METROPOLITAN_MICROPOLITAN_STATISTICAL_AREA::text), '^^') 
            , '||', IFNULL(TRIM(METROPOLITAN_DIVISION_TITLE::text), '^^') 
            , '||', IFNULL(TRIM(COUNTY_COUNTY_EQUIVALENT::text), '^^') 
            , '||', IFNULL(TRIM(STATE_NAME::text), '^^') 
            , '||', IFNULL(TRIM(FIPS_STATE_CODE::text), '^^') 
            , '||', IFNULL(TRIM(FIPS_COUNTY_CODE::text), '^^') 
            , '||', IFNULL(TRIM(CENTRAL_OUTLYING_COUNTY::text), '^^') 
            , '||', IFNULL(TRIM(UPDATED_ON::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
