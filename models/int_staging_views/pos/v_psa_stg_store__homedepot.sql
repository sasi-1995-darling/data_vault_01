---- SRC LAYER ----
WITH
SRC_S              as ( SELECT * FROM {{ source('home_depot_psa', 'hd_askuity_master_storeattributes') }} as SRC  ),
SRC_A              as ( SELECT * FROM {{ ref( 'ref_business_key_collision') }} as SRC  )

/*
SRC_S              as ( SELECT * FROM home_depot_psa.hd_askuity_master_storeattributes )
SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        D_STORE_NBR                                                  as                                           STORE_BK
      , D_STORE_NBR                                                 
      , CONVERT_TIMEZONE('UTC', RUN_DATE)                            as                                           LOAD_DTS
      , STATE_TERRITORY_CODE                                        
      , D_ALL_THD                                                   
      , D_BUYING_OFFICE                                             
      , D_CITY                                                      
      , D_COUNTRY                                                   
      , D_DISTRICT                                                  
      , D_DIVISION                                                  
      , D_LOB                                                       
      , D_LATITUDE                                                  
      , D_LONGITUDE                                                 
      , D_MARKET                                                    
      , D_POSTAL_CODE                                               
      , D_REGION                                                    
      , D_STORE                                                     
      , D_STORE_ADDRESS                                             
      , D_STORE_NAME                                                
      , D_TIME_ZONE                                                 
      , HOME_DEPOT_ACCOUNT                                          
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
      , LOAD_DTS
      , STATE_TERRITORY_CODE
      , D_ALL_THD
      , D_BUYING_OFFICE
      , D_CITY
      , D_COUNTRY
      , D_DISTRICT
      , D_DIVISION
      , D_LOB
      , D_LATITUDE
      , D_LONGITUDE
      , D_MARKET
      , D_POSTAL_CODE
      , D_REGION
      , D_STORE
      , D_STORE_ADDRESS
      , D_STORE_NAME
      , D_TIME_ZONE
      , HOME_DEPOT_ACCOUNT
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
    WHERE rec_src = 'US.HIVE.ASKUITY.HD_ASKUITY_MASTER_STOREATTRIBUTES'
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
        , LOAD_DTS
        , STATE_TERRITORY_CODE
        , D_ALL_THD
        , D_BUYING_OFFICE
        , D_CITY
        , D_COUNTRY
        , D_DISTRICT
        , D_DIVISION
        , D_LOB
        , D_LATITUDE
        , D_LONGITUDE
        , D_MARKET
        , D_POSTAL_CODE
        , D_REGION
        , D_STORE
        , D_STORE_ADDRESS
        , D_STORE_NAME
        , D_TIME_ZONE
        , HOME_DEPOT_ACCOUNT
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(D_STORE_NBR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as STORE_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(D_ALL_THD::text), '^^') 
            , '||', IFNULL(TRIM(D_BUYING_OFFICE::text), '^^') 
            , '||', IFNULL(TRIM(D_CITY::text), '^^') 
            , '||', IFNULL(TRIM(D_COUNTRY::text), '^^') 
            , '||', IFNULL(TRIM(D_DISTRICT::text), '^^') 
            , '||', IFNULL(TRIM(D_DIVISION::text), '^^') 
            , '||', IFNULL(TRIM(D_LOB::text), '^^') 
            , '||', IFNULL(TRIM(D_LATITUDE::text), '^^') 
            , '||', IFNULL(TRIM(D_LONGITUDE::text), '^^') 
            , '||', IFNULL(TRIM(D_MARKET::text), '^^') 
            , '||', IFNULL(TRIM(D_POSTAL_CODE::text), '^^') 
            , '||', IFNULL(TRIM(D_REGION::text), '^^') 
            , '||', IFNULL(TRIM(D_STORE::text), '^^') 
            , '||', IFNULL(TRIM(D_STORE_ADDRESS::text), '^^') 
            , '||', IFNULL(TRIM(D_STORE_NAME::text), '^^') 
            , '||', IFNULL(TRIM(D_TIME_ZONE::text), '^^') 
            , '||', IFNULL(TRIM(HOME_DEPOT_ACCOUNT::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
