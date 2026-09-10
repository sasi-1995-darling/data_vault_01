---- SRC LAYER ----
WITH
SRC_S              as ( SELECT * FROM {{ source('lowes_vpp_psa', 'sales_inventory_moen') }} as SRC  ),
SRC_A              as ( SELECT * FROM {{ ref( 'ref_business_key_collision') }} as SRC  )

/*
SRC_S              as ( SELECT * FROM lowes_vpp_psa.sales_inventory_moen )
SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        LOCATION_ID                                                  as                                           STORE_BK
      , LOCATION_ID                                                 
      , ITEM_ID                                                     
      , END_DATE                                                    
      , CONVERT_TIMEZONE('UTC',PM_SNAPSHOT_DATE)                     as                                           LOAD_DTS
      , ITEM_NAME                                                   
      , LOCATION_NAME                                               
      , TY_AVAILABLE_INVENTORY_UNITS                                
      , LY_AVAILABLE_INVENTORY_UNITS                                
      , TY_VS_LY_AVAILABLE_INVENTORY_UNITS                          
      , TY_AVAILABLE_INVENTORY_SALES                                
      , LY_AVAILABLE_INVENTORY_SALES                                
      , TY_VS_LY_AVAILABLE_INVENTORY_SALES                          
      , AVAILABLE_DC_INVENTORY_UNITS                                
      , AVAILABLE_RETAIL_INVENTORY_UNITS                            
      , TY_INVENTORY_ON_DIRECT_ORDER_UNITS                          
      , LY_INVENTORY_ON_DIRECT_ORDER_UNITS                          
      , TY_VS_LY_INVENTORY_ON_DIRECT_ORDER_UNITS                    
      , TY_INVENTORY_ON_DIRECT_ORDER_SALES                          
      , LY_INVENTORY_ON_DIRECT_ORDER_SALES                          
      , TY_VS_LY_INVENTORY_ON_DIRECT_ORDER_SALES                    
      , TY_INVENTORY_UNITS_IN_REQ                                   
      , LY_INVENTORY_UNITS_IN_REQ                                   
      , TY_VS_LY_INVENTORY_UNITS_IN_REQ                             
      , TY_INVENTORY_UNITS_ON_BILL                                  
      , LY_INVENTORY_UNITS_ON_BILL                                  
      , TY_VS_LY_INVENTORY_UNITS_ON_BILL                            
      , TY_SALES_UNITS                                              
      , LY_SALES_UNITS                                              
      , TY_VS_LY_SALES_UNITS                                        
      , TY_SALES                                                    
      , LY_SALES                                                    
      , TY_VS_LY_SALES                                              
      , GROSS_SALES                                                 
      , TY_FULFILLED_INTERNET_UNITS                                 
      , LY_FULFILLED_INTERNET_UNITS                                 
      , TY_VS_LY_FULFILLED_INTERNET_UNITS                           
      , TY_FULFILLED_INTERNET_SALES                                 
      , LY_FULFILLED_INTERNET_SALES                                 
      , TY_VS_LY_FULFILLED_INTERNET_SALES                           
      , TY_AVG_INVENTORY_ON_HAND_UNITS                              
      , LY_AVG_INVENTORY_ON_HAND_UNITS                              
      , TY_VS_LY_AVG_INVENTORY_ON_HAND_UNITS                        
      , TY_AVG_INVENTORY_ON_HAND_SALES                              
      , LY_AVG_INVENTORY_ON_HAND_SALES                              
      , TY_VS_LY_AVG_INVENTORY_ON_HAND_SALES                        
      , TY_AVERAGE_INVENTORY_ON_DIRECT_ORDER_UNITS                  
      , LY_AVERAGE_INVENTORY_ON_DIRECT_ORDER_UNITS                  
      , TY_VS_LY_AVERAGE_INVENTORY_ON_DIRECT_ORDER_UNITS            
      , TY_AVERAGE_INVENTORY_ON_DIRECT_ORDER_SALES                  
      , LY_AVERAGE_INVENTORY_ON_DIRECT_ORDER_SALES                  
      , TY_VS_LY_AVERAGE_INVENTORY_ON_DIRECT_ORDER_SALES            
      , TY_AVERAGE_INVENTORY_ON_REQUISITION_UNITS                   
      , LY_AVERAGE_INVENTORY_ON_REQUISITION_UNITS                   
      , TY_VS_LY_AVERAGE_INVENTORY_ON_REQUISITION_UNITS             
      , TY_AVERAGE_INVENTORY_ON_REQUISITION_SALES                   
      , LY_AVERAGE_INVENTORY_ON_REQUISITION_SALES                   
      , TY_VS_LY_AVERAGE_INVENTORY_ON_REQUISITION_SALES             
      , IN_STOCK_PERCENTAGE                                         
      , AVERAGE_YEAR_TO_DATE_SALES                                  
      , TY_YEAR_TO_DATE_SALES_UNITS                                 
      , LY_YEAR_TO_DATE_SALES_UNITS                                 
      , TY_VS_LY_YEAR_TO_DATE_SALES_UNITS                           
      , WEEKS_OF_SUPPLY_ON_HAND                                     
      , WEEKS_OF_SUPPLY_ON_ORDER                                    
      , TY_JDA_LOST_SALES                                           
      , TY_JDA_SERVICE_LEVEL                                        
      , LY_TURN_RATE                                                
      , TY_TURN_RATE                                                
      , START_DATE                                                  
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
      , ITEM_ID
      , END_DATE
      , LOAD_DTS
      , ITEM_NAME
      , LOCATION_NAME
      , TY_AVAILABLE_INVENTORY_UNITS
      , LY_AVAILABLE_INVENTORY_UNITS
      , TY_VS_LY_AVAILABLE_INVENTORY_UNITS
      , TY_AVAILABLE_INVENTORY_SALES
      , LY_AVAILABLE_INVENTORY_SALES
      , TY_VS_LY_AVAILABLE_INVENTORY_SALES
      , AVAILABLE_DC_INVENTORY_UNITS
      , AVAILABLE_RETAIL_INVENTORY_UNITS
      , TY_INVENTORY_ON_DIRECT_ORDER_UNITS
      , LY_INVENTORY_ON_DIRECT_ORDER_UNITS
      , TY_VS_LY_INVENTORY_ON_DIRECT_ORDER_UNITS
      , TY_INVENTORY_ON_DIRECT_ORDER_SALES
      , LY_INVENTORY_ON_DIRECT_ORDER_SALES
      , TY_VS_LY_INVENTORY_ON_DIRECT_ORDER_SALES
      , TY_INVENTORY_UNITS_IN_REQ
      , LY_INVENTORY_UNITS_IN_REQ
      , TY_VS_LY_INVENTORY_UNITS_IN_REQ
      , TY_INVENTORY_UNITS_ON_BILL
      , LY_INVENTORY_UNITS_ON_BILL
      , TY_VS_LY_INVENTORY_UNITS_ON_BILL
      , TY_SALES_UNITS
      , LY_SALES_UNITS
      , TY_VS_LY_SALES_UNITS
      , TY_SALES
      , LY_SALES
      , TY_VS_LY_SALES
      , GROSS_SALES
      , TY_FULFILLED_INTERNET_UNITS
      , LY_FULFILLED_INTERNET_UNITS
      , TY_VS_LY_FULFILLED_INTERNET_UNITS
      , TY_FULFILLED_INTERNET_SALES
      , LY_FULFILLED_INTERNET_SALES
      , TY_VS_LY_FULFILLED_INTERNET_SALES
      , TY_AVG_INVENTORY_ON_HAND_UNITS
      , LY_AVG_INVENTORY_ON_HAND_UNITS
      , TY_VS_LY_AVG_INVENTORY_ON_HAND_UNITS
      , TY_AVG_INVENTORY_ON_HAND_SALES
      , LY_AVG_INVENTORY_ON_HAND_SALES
      , TY_VS_LY_AVG_INVENTORY_ON_HAND_SALES
      , TY_AVERAGE_INVENTORY_ON_DIRECT_ORDER_UNITS
      , LY_AVERAGE_INVENTORY_ON_DIRECT_ORDER_UNITS
      , TY_VS_LY_AVERAGE_INVENTORY_ON_DIRECT_ORDER_UNITS
      , TY_AVERAGE_INVENTORY_ON_DIRECT_ORDER_SALES
      , LY_AVERAGE_INVENTORY_ON_DIRECT_ORDER_SALES
      , TY_VS_LY_AVERAGE_INVENTORY_ON_DIRECT_ORDER_SALES
      , TY_AVERAGE_INVENTORY_ON_REQUISITION_UNITS
      , LY_AVERAGE_INVENTORY_ON_REQUISITION_UNITS
      , TY_VS_LY_AVERAGE_INVENTORY_ON_REQUISITION_UNITS
      , TY_AVERAGE_INVENTORY_ON_REQUISITION_SALES
      , LY_AVERAGE_INVENTORY_ON_REQUISITION_SALES
      , TY_VS_LY_AVERAGE_INVENTORY_ON_REQUISITION_SALES
      , IN_STOCK_PERCENTAGE
      , AVERAGE_YEAR_TO_DATE_SALES
      , TY_YEAR_TO_DATE_SALES_UNITS
      , LY_YEAR_TO_DATE_SALES_UNITS
      , TY_VS_LY_YEAR_TO_DATE_SALES_UNITS
      , WEEKS_OF_SUPPLY_ON_HAND
      , WEEKS_OF_SUPPLY_ON_ORDER
      , TY_JDA_LOST_SALES
      , TY_JDA_SERVICE_LEVEL
      , LY_TURN_RATE
      , TY_TURN_RATE
      , START_DATE
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
    WHERE rec_src = 'US.API.LOWES_VPP.SALES_INVENTORY_MOEN'
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
        , ITEM_ID
        , END_DATE
        , LOAD_DTS
        , ITEM_NAME
        , LOCATION_NAME
        , TY_AVAILABLE_INVENTORY_UNITS
        , LY_AVAILABLE_INVENTORY_UNITS
        , TY_VS_LY_AVAILABLE_INVENTORY_UNITS
        , TY_AVAILABLE_INVENTORY_SALES
        , LY_AVAILABLE_INVENTORY_SALES
        , TY_VS_LY_AVAILABLE_INVENTORY_SALES
        , AVAILABLE_DC_INVENTORY_UNITS
        , AVAILABLE_RETAIL_INVENTORY_UNITS
        , TY_INVENTORY_ON_DIRECT_ORDER_UNITS
        , LY_INVENTORY_ON_DIRECT_ORDER_UNITS
        , TY_VS_LY_INVENTORY_ON_DIRECT_ORDER_UNITS
        , TY_INVENTORY_ON_DIRECT_ORDER_SALES
        , LY_INVENTORY_ON_DIRECT_ORDER_SALES
        , TY_VS_LY_INVENTORY_ON_DIRECT_ORDER_SALES
        , TY_INVENTORY_UNITS_IN_REQ
        , LY_INVENTORY_UNITS_IN_REQ
        , TY_VS_LY_INVENTORY_UNITS_IN_REQ
        , TY_INVENTORY_UNITS_ON_BILL
        , LY_INVENTORY_UNITS_ON_BILL
        , TY_VS_LY_INVENTORY_UNITS_ON_BILL
        , TY_SALES_UNITS
        , LY_SALES_UNITS
        , TY_VS_LY_SALES_UNITS
        , TY_SALES
        , LY_SALES
        , TY_VS_LY_SALES
        , GROSS_SALES
        , TY_FULFILLED_INTERNET_UNITS
        , LY_FULFILLED_INTERNET_UNITS
        , TY_VS_LY_FULFILLED_INTERNET_UNITS
        , TY_FULFILLED_INTERNET_SALES
        , LY_FULFILLED_INTERNET_SALES
        , TY_VS_LY_FULFILLED_INTERNET_SALES
        , TY_AVG_INVENTORY_ON_HAND_UNITS
        , LY_AVG_INVENTORY_ON_HAND_UNITS
        , TY_VS_LY_AVG_INVENTORY_ON_HAND_UNITS
        , TY_AVG_INVENTORY_ON_HAND_SALES
        , LY_AVG_INVENTORY_ON_HAND_SALES
        , TY_VS_LY_AVG_INVENTORY_ON_HAND_SALES
        , TY_AVERAGE_INVENTORY_ON_DIRECT_ORDER_UNITS
        , LY_AVERAGE_INVENTORY_ON_DIRECT_ORDER_UNITS
        , TY_VS_LY_AVERAGE_INVENTORY_ON_DIRECT_ORDER_UNITS
        , TY_AVERAGE_INVENTORY_ON_DIRECT_ORDER_SALES
        , LY_AVERAGE_INVENTORY_ON_DIRECT_ORDER_SALES
        , TY_VS_LY_AVERAGE_INVENTORY_ON_DIRECT_ORDER_SALES
        , TY_AVERAGE_INVENTORY_ON_REQUISITION_UNITS
        , LY_AVERAGE_INVENTORY_ON_REQUISITION_UNITS
        , TY_VS_LY_AVERAGE_INVENTORY_ON_REQUISITION_UNITS
        , TY_AVERAGE_INVENTORY_ON_REQUISITION_SALES
        , LY_AVERAGE_INVENTORY_ON_REQUISITION_SALES
        , TY_VS_LY_AVERAGE_INVENTORY_ON_REQUISITION_SALES
        , IN_STOCK_PERCENTAGE
        , AVERAGE_YEAR_TO_DATE_SALES
        , TY_YEAR_TO_DATE_SALES_UNITS
        , LY_YEAR_TO_DATE_SALES_UNITS
        , TY_VS_LY_YEAR_TO_DATE_SALES_UNITS
        , WEEKS_OF_SUPPLY_ON_HAND
        , WEEKS_OF_SUPPLY_ON_ORDER
        , TY_JDA_LOST_SALES
        , TY_JDA_SERVICE_LEVEL
        , LY_TURN_RATE
        , TY_TURN_RATE
        , START_DATE
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(LOCATION_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as STORE_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(ITEM_NAME::text), '^^') 
            , '||', IFNULL(TRIM(LOCATION_NAME::text), '^^') 
            , '||', IFNULL(TRIM(TY_AVAILABLE_INVENTORY_UNITS::text), '^^') 
            , '||', IFNULL(TRIM(LY_AVAILABLE_INVENTORY_UNITS::text), '^^') 
            , '||', IFNULL(TRIM(TY_VS_LY_AVAILABLE_INVENTORY_UNITS::text), '^^') 
            , '||', IFNULL(TRIM(TY_AVAILABLE_INVENTORY_SALES::text), '^^') 
            , '||', IFNULL(TRIM(LY_AVAILABLE_INVENTORY_SALES::text), '^^') 
            , '||', IFNULL(TRIM(TY_VS_LY_AVAILABLE_INVENTORY_SALES::text), '^^') 
            , '||', IFNULL(TRIM(AVAILABLE_DC_INVENTORY_UNITS::text), '^^') 
            , '||', IFNULL(TRIM(AVAILABLE_RETAIL_INVENTORY_UNITS::text), '^^') 
            , '||', IFNULL(TRIM(TY_INVENTORY_ON_DIRECT_ORDER_UNITS::text), '^^') 
            , '||', IFNULL(TRIM(LY_INVENTORY_ON_DIRECT_ORDER_UNITS::text), '^^') 
            , '||', IFNULL(TRIM(TY_VS_LY_INVENTORY_ON_DIRECT_ORDER_UNITS::text), '^^') 
            , '||', IFNULL(TRIM(TY_INVENTORY_ON_DIRECT_ORDER_SALES::text), '^^') 
            , '||', IFNULL(TRIM(LY_INVENTORY_ON_DIRECT_ORDER_SALES::text), '^^') 
            , '||', IFNULL(TRIM(TY_VS_LY_INVENTORY_ON_DIRECT_ORDER_SALES::text), '^^') 
            , '||', IFNULL(TRIM(TY_INVENTORY_UNITS_IN_REQ::text), '^^') 
            , '||', IFNULL(TRIM(LY_INVENTORY_UNITS_IN_REQ::text), '^^') 
            , '||', IFNULL(TRIM(TY_VS_LY_INVENTORY_UNITS_IN_REQ::text), '^^') 
            , '||', IFNULL(TRIM(TY_INVENTORY_UNITS_ON_BILL::text), '^^') 
            , '||', IFNULL(TRIM(LY_INVENTORY_UNITS_ON_BILL::text), '^^') 
            , '||', IFNULL(TRIM(TY_VS_LY_INVENTORY_UNITS_ON_BILL::text), '^^') 
            , '||', IFNULL(TRIM(TY_SALES_UNITS::text), '^^') 
            , '||', IFNULL(TRIM(LY_SALES_UNITS::text), '^^') 
            , '||', IFNULL(TRIM(TY_VS_LY_SALES_UNITS::text), '^^') 
            , '||', IFNULL(TRIM(TY_SALES::text), '^^') 
            , '||', IFNULL(TRIM(LY_SALES::text), '^^') 
            , '||', IFNULL(TRIM(TY_VS_LY_SALES::text), '^^') 
            , '||', IFNULL(TRIM(GROSS_SALES::text), '^^') 
            , '||', IFNULL(TRIM(TY_FULFILLED_INTERNET_UNITS::text), '^^') 
            , '||', IFNULL(TRIM(LY_FULFILLED_INTERNET_UNITS::text), '^^') 
            , '||', IFNULL(TRIM(TY_VS_LY_FULFILLED_INTERNET_UNITS::text), '^^') 
            , '||', IFNULL(TRIM(TY_FULFILLED_INTERNET_SALES::text), '^^') 
            , '||', IFNULL(TRIM(LY_FULFILLED_INTERNET_SALES::text), '^^') 
            , '||', IFNULL(TRIM(TY_VS_LY_FULFILLED_INTERNET_SALES::text), '^^') 
            , '||', IFNULL(TRIM(TY_AVG_INVENTORY_ON_HAND_UNITS::text), '^^') 
            , '||', IFNULL(TRIM(LY_AVG_INVENTORY_ON_HAND_UNITS::text), '^^') 
            , '||', IFNULL(TRIM(TY_VS_LY_AVG_INVENTORY_ON_HAND_UNITS::text), '^^') 
            , '||', IFNULL(TRIM(TY_AVG_INVENTORY_ON_HAND_SALES::text), '^^') 
            , '||', IFNULL(TRIM(LY_AVG_INVENTORY_ON_HAND_SALES::text), '^^') 
            , '||', IFNULL(TRIM(TY_VS_LY_AVG_INVENTORY_ON_HAND_SALES::text), '^^') 
            , '||', IFNULL(TRIM(TY_AVERAGE_INVENTORY_ON_DIRECT_ORDER_UNITS::text), '^^') 
            , '||', IFNULL(TRIM(LY_AVERAGE_INVENTORY_ON_DIRECT_ORDER_UNITS::text), '^^') 
            , '||', IFNULL(TRIM(TY_VS_LY_AVERAGE_INVENTORY_ON_DIRECT_ORDER_UNITS::text), '^^') 
            , '||', IFNULL(TRIM(TY_AVERAGE_INVENTORY_ON_DIRECT_ORDER_SALES::text), '^^') 
            , '||', IFNULL(TRIM(LY_AVERAGE_INVENTORY_ON_DIRECT_ORDER_SALES::text), '^^') 
            , '||', IFNULL(TRIM(TY_VS_LY_AVERAGE_INVENTORY_ON_DIRECT_ORDER_SALES::text), '^^') 
            , '||', IFNULL(TRIM(TY_AVERAGE_INVENTORY_ON_REQUISITION_UNITS::text), '^^') 
            , '||', IFNULL(TRIM(LY_AVERAGE_INVENTORY_ON_REQUISITION_UNITS::text), '^^') 
            , '||', IFNULL(TRIM(TY_VS_LY_AVERAGE_INVENTORY_ON_REQUISITION_UNITS::text), '^^') 
            , '||', IFNULL(TRIM(TY_AVERAGE_INVENTORY_ON_REQUISITION_SALES::text), '^^') 
            , '||', IFNULL(TRIM(LY_AVERAGE_INVENTORY_ON_REQUISITION_SALES::text), '^^') 
            , '||', IFNULL(TRIM(TY_VS_LY_AVERAGE_INVENTORY_ON_REQUISITION_SALES::text), '^^') 
            , '||', IFNULL(TRIM(IN_STOCK_PERCENTAGE::text), '^^') 
            , '||', IFNULL(TRIM(AVERAGE_YEAR_TO_DATE_SALES::text), '^^') 
            , '||', IFNULL(TRIM(TY_YEAR_TO_DATE_SALES_UNITS::text), '^^') 
            , '||', IFNULL(TRIM(LY_YEAR_TO_DATE_SALES_UNITS::text), '^^') 
            , '||', IFNULL(TRIM(TY_VS_LY_YEAR_TO_DATE_SALES_UNITS::text), '^^') 
            , '||', IFNULL(TRIM(WEEKS_OF_SUPPLY_ON_HAND::text), '^^') 
            , '||', IFNULL(TRIM(WEEKS_OF_SUPPLY_ON_ORDER::text), '^^') 
            , '||', IFNULL(TRIM(TY_JDA_LOST_SALES::text), '^^') 
            , '||', IFNULL(TRIM(TY_JDA_SERVICE_LEVEL::text), '^^') 
            , '||', IFNULL(TRIM(LY_TURN_RATE::text), '^^') 
            , '||', IFNULL(TRIM(TY_TURN_RATE::text), '^^') 
            , '||', IFNULL(TRIM(START_DATE::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
