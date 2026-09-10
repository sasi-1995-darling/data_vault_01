---- SRC LAYER ----
WITH
SRC_S              as ( SELECT * FROM {{ source('lowes_us_psa', 'location') }} as SRC  ),
SRC_A              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S              as ( SELECT * FROM lowes_us_psa.location )
SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        LOCATION_ID                                                  as                                           STORE_BK
      , LOCATION_ID                                                 
      , CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED)                    as                                           LOAD_DTS
      , LOCATION_DESC                                               
      , DELIVERY_ADDRESS                                            
      , DELIVERY_CITY                                               
      , DELIVERY_STATE                                              
      , DELIVERY_CODE                                               
      , SALESFLOOR_FOOTAGE                                          
      , DISTRICT_DISTRICT                                           
      , REGION_ID                                                   
      , REGION_DESC                                                 
      , DIVISION_DIVISION                                           
      , ADVERTISING_AREA                                            
      , GEO_ID                                                      
      , GEO_DESC                                                    
      , FORECAST_ZONE                                               
      , SUPPORTING_CENTER                                           
      , SUPPORTING_FDC                                              
      , SUPPORTING_TRANSLOAD                                        
      , FILE_NAME                                                   
      , OPEN_DATE                                                   
      , _FILE                                                       
      , PM_SNAPSHOT_DATE                                            
      , _MODIFIED                                                   
      , REAL_DATE                                                   
      , _LINE                                                       
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
      , LOCATION_ID
      , LOAD_DTS
      , LOCATION_DESC
      , DELIVERY_ADDRESS
      , DELIVERY_CITY
      , DELIVERY_STATE
      , DELIVERY_CODE
      , SALESFLOOR_FOOTAGE
      , DISTRICT_DISTRICT
      , REGION_ID
      , REGION_DESC
      , DIVISION_DIVISION
      , ADVERTISING_AREA
      , GEO_ID
      , GEO_DESC
      , FORECAST_ZONE
      , SUPPORTING_CENTER
      , SUPPORTING_FDC
      , SUPPORTING_TRANSLOAD
      , FILE_NAME
      , OPEN_DATE
      , _FILE
      , PM_SNAPSHOT_DATE
      , _MODIFIED
      , REAL_DATE
      , _LINE
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
    WHERE rec_src = 'US.EXCEL.LOWES_US.LOCATION'
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
        , LOCATION_ID
        , LOAD_DTS
        , LOCATION_DESC
        , DELIVERY_ADDRESS
        , DELIVERY_CITY
        , DELIVERY_STATE
        , DELIVERY_CODE
        , SALESFLOOR_FOOTAGE
        , DISTRICT_DISTRICT
        , REGION_ID
        , REGION_DESC
        , DIVISION_DIVISION
        , ADVERTISING_AREA
        , GEO_ID
        , GEO_DESC
        , FORECAST_ZONE
        , SUPPORTING_CENTER
        , SUPPORTING_FDC
        , SUPPORTING_TRANSLOAD
        , FILE_NAME
        , OPEN_DATE
        , _FILE
        , PM_SNAPSHOT_DATE
        , _MODIFIED
        , REAL_DATE
        , _LINE
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(LOCATION_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as STORE_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(LOCATION_DESC::text), '^^') 
            , '||', IFNULL(TRIM(DELIVERY_ADDRESS::text), '^^') 
            , '||', IFNULL(TRIM(DELIVERY_CITY::text), '^^') 
            , '||', IFNULL(TRIM(DELIVERY_STATE::text), '^^') 
            , '||', IFNULL(TRIM(DELIVERY_CODE::text), '^^') 
            , '||', IFNULL(TRIM(SALESFLOOR_FOOTAGE::text), '^^') 
            , '||', IFNULL(TRIM(DISTRICT_DISTRICT::text), '^^') 
            , '||', IFNULL(TRIM(REGION_ID::text), '^^') 
            , '||', IFNULL(TRIM(REGION_DESC::text), '^^') 
            , '||', IFNULL(TRIM(DIVISION_DIVISION::text), '^^') 
            , '||', IFNULL(TRIM(ADVERTISING_AREA::text), '^^') 
            , '||', IFNULL(TRIM(GEO_ID::text), '^^') 
            , '||', IFNULL(TRIM(GEO_DESC::text), '^^') 
            , '||', IFNULL(TRIM(FORECAST_ZONE::text), '^^') 
            , '||', IFNULL(TRIM(SUPPORTING_CENTER::text), '^^') 
            , '||', IFNULL(TRIM(SUPPORTING_FDC::text), '^^') 
            , '||', IFNULL(TRIM(SUPPORTING_TRANSLOAD::text), '^^') 
            , '||', IFNULL(TRIM(FILE_NAME::text), '^^') 
            , '||', IFNULL(TRIM(OPEN_DATE::text), '^^') 
            , '||', IFNULL(TRIM(_FILE::text), '^^') 
            , '||', IFNULL(TRIM(PM_SNAPSHOT_DATE::text), '^^') 
            , '||', IFNULL(TRIM(_MODIFIED::text), '^^') 
            , '||', IFNULL(TRIM(REAL_DATE::text), '^^') 
            , '||', IFNULL(TRIM(_LINE::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
