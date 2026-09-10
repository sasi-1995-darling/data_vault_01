---- SRC LAYER ----
WITH
SRC_S              as ( SELECT D_ALL_THD, D_BUYING_OFFICE, D_BYO_NAME, D_BYO_NBR, D_CITY, D_COUNTRY, D_DISTRICT, D_DISTRICT_NAME, D_DISTRICT_NBR, D_DIVISION_NAME, D_LATITUDE, D_LOB, D_LONGITUDE, D_MARKET, D_MARKET_NAME,D_POSTAL_CODE, D_MARKET_NBR, D_REGION, D_REGION_NAME, D_REGION_NBR, D_STORE, D_STORE_ADDRESS, D_STORE_NAME, D_STORE_NBR, D_TIME_ZONE, HOME_DEPOT_ACCOUNT, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, STATE_TERRITORY_CODE, _FIVETRAN_DELETED, _FIVETRAN_SYNCED FROM {{ source('home_depot_ft_psa', 'vendor_drill_store_attr_data_us') }} as SRC  ),
SRC_A              as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S              as ( SELECT * FROM home_depot_ft_psa.vendor_drill_store_attr_data_us )
SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        D_STORE_NBR                                                  as                                           STORE_BK
      , D_STORE_NBR
      , HOME_DEPOT_ACCOUNT
      , _FIVETRAN_SYNCED
      , CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED)                    as                                           LOAD_DTS
      , D_REGION
      , D_MARKET
      , D_ALL_THD
      , D_DISTRICT
      , D_MARKET_NAME
      , _FIVETRAN_DELETED
      , D_TIME_ZONE
      , D_LOB
      , D_REGION_NBR
      , D_STORE
      , D_DISTRICT_NAME
      , STATE_TERRITORY_CODE
      , D_LONGITUDE
      , D_STORE_NAME
      , D_STORE_ADDRESS
      , D_BUYING_OFFICE
      , D_COUNTRY
      , D_REGION_NAME
      , D_BYO_NAME
      , D_LATITUDE
      , D_MARKET_NBR
      , D_DIVISION_NAME
      , D_CITY
      , D_BYO_NBR
      , D_DISTRICT_NBR
      , D_POSTAL_CODE
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
      , HOME_DEPOT_ACCOUNT
      , _FIVETRAN_SYNCED
      , LOAD_DTS
      , D_REGION
      , D_MARKET
      , D_ALL_THD
      , D_DISTRICT
      , D_MARKET_NAME
      , _FIVETRAN_DELETED
      , D_TIME_ZONE
      , D_LOB
      , D_REGION_NBR
      , D_STORE
      , D_DISTRICT_NAME
      , STATE_TERRITORY_CODE
      , D_LONGITUDE
      , D_STORE_NAME
      , D_STORE_ADDRESS
      , D_BUYING_OFFICE
      , D_COUNTRY
      , D_REGION_NAME
      , D_BYO_NAME
      , D_LATITUDE
      , D_MARKET_NBR
      , D_DIVISION_NAME
      , D_CITY
      , D_BYO_NBR
      , D_DISTRICT_NBR
      , D_POSTAL_CODE
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
    WHERE rec_src = 'US.HIVE.ASKUITY_FT.VENDOR_DRILL_STORE_ATTR_DATA_US'
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
        , HOME_DEPOT_ACCOUNT
        , LOAD_DTS
        , D_REGION
        , D_MARKET
        , D_ALL_THD
        , D_DISTRICT
        , D_MARKET_NAME
        , _FIVETRAN_DELETED
        , D_TIME_ZONE
        , D_LOB
        , D_REGION_NBR
        , D_STORE
        , D_DISTRICT_NAME
        , STATE_TERRITORY_CODE
        , D_LONGITUDE
        , D_STORE_NAME
        , D_STORE_ADDRESS
        , D_BUYING_OFFICE
        , D_COUNTRY
        , D_REGION_NAME
        , D_BYO_NAME
        , D_LATITUDE
        , D_MARKET_NBR
        , D_DIVISION_NAME
        , D_CITY
        , D_BYO_NBR
        , D_DISTRICT_NBR
        , D_POSTAL_CODE
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
              IFNULL(TRIM(D_REGION::text), '^^') 
            , '||', IFNULL(TRIM(D_MARKET::text), '^^') 
            , '||', IFNULL(TRIM(D_ALL_THD::text), '^^') 
            , '||', IFNULL(TRIM(D_DISTRICT::text), '^^') 
            , '||', IFNULL(TRIM(D_MARKET_NAME::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
            , '||', IFNULL(TRIM(D_TIME_ZONE::text), '^^') 
            , '||', IFNULL(TRIM(D_LOB::text), '^^') 
            , '||', IFNULL(TRIM(D_REGION_NBR::text), '^^') 
            , '||', IFNULL(TRIM(D_STORE::text), '^^') 
            , '||', IFNULL(TRIM(D_DISTRICT_NAME::text), '^^') 
            , '||', IFNULL(TRIM(STATE_TERRITORY_CODE::text), '^^') 
            , '||', IFNULL(TRIM(D_LONGITUDE::text), '^^') 
            , '||', IFNULL(TRIM(D_STORE_NAME::text), '^^') 
            , '||', IFNULL(TRIM(D_STORE_ADDRESS::text), '^^') 
            , '||', IFNULL(TRIM(D_BUYING_OFFICE::text), '^^') 
            , '||', IFNULL(TRIM(D_COUNTRY::text), '^^') 
            , '||', IFNULL(TRIM(D_REGION_NAME::text), '^^') 
            , '||', IFNULL(TRIM(D_BYO_NAME::text), '^^') 
            , '||', IFNULL(TRIM(D_LATITUDE::text), '^^') 
            , '||', IFNULL(TRIM(D_MARKET_NBR::text), '^^') 
            , '||', IFNULL(TRIM(D_DIVISION_NAME::text), '^^') 
            , '||', IFNULL(TRIM(D_CITY::text), '^^') 
            , '||', IFNULL(TRIM(D_BYO_NBR::text), '^^') 
            , '||', IFNULL(TRIM(D_DISTRICT_NBR::text), '^^')
            , '||', IFNULL(TRIM(D_POSTAL_CODE::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
