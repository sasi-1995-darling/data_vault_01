---- SRC LAYER ----
WITH
SRC_S              as ( SELECT * FROM {{ source('lowes_vpp_psa', 'sales_inventory') }} as SRC  ),
SRC_A              as ( SELECT * FROM {{ ref( 'ref_business_key_collision') }} as SRC  )

/*
SRC_S              as ( SELECT * FROM lowes_vpp_psa.sales_inventory )
SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        LOCATION_ID                                                  as                                           STORE_BK
      , LOCATION_ID                                                 
      , ITEM_NUMBER                                                 
      , END_DATE                                                    
      , CONVERT_TIMEZONE('UTC',PM_SNAPSHOT_DATE)                     as                                           LOAD_DTS
      , ITEM_NAME                                                   
      , ASSORTMENT_NUMBER                                           
      , ASSORTMENT_NAME                                             
      , BRAND_NUMBER                                                
      , BRAND_NAME                                                  
      , PRODUCT_GROUP_NUMBER                                        
      , PRODUCT_GROUP_NAME                                          
      , MER_SBO_DVS_NBR                                             
      , MERCHANDISING_SUBDIVISION                                   
      , MER_DVS_NBR                                                 
      , MERCHANDISING_DIVISION                                      
      , BUS_ARA_NBR                                                 
      , BUSINESS_AREA                                               
      , ADVERTISING_PATCH_AREA_ID                                   
      , DISTRICT_ID                                                 
      , DIVISION_DESC                                               
      , GEO_ZONE_ID                                                 
      , LOCATION_DESC                                               
      , LOCATION_TYPE_DESC                                          
      , REGION_DESC                                                 
      , SERVICING_DZ_ID                                             
      , STATE_ID                                                    
      , SUPPORTING_FDC_ID                                           
      , SUPPORTING_FDC_DESC                                         
      , SUPPORTING_REGIONAL_DISTRIBUTION_CENTER_ID                  
      , WEEK_ID                                                     
      , FULFILLED_INTERNET_SALES_TY                                 
      , FULFILLED_INTERNET_SALES_LY                                 
      , FULFILLED_INTERNET_SALES_TY_VS_LY                           
      , FULFILLED_INTERNET_UNITS_TY                                 
      , FULFILLED_INTERNET_UNITS_LY                                 
      , FULFILLED_INTERNET_UNITS_TY_VS_LY                           
      , SALES_TY                                                    
      , SALES_LY                                                    
      , SALES_TY_VS_LY                                              
      , UNITS_TY                                                    
      , UNITS_LY                                                    
      , UNITS_TY_VS_LY                                              
      , AVG_INVENTORY_ON_HAND_TY                                    
      , AVG_INVENTORY_ON_HAND_LY                                    
      , AVG_INVENTORY_ON_HAND_TY_VS_LY                              
      , AVG_INVENTORY_ON_HAND_UNITS_TY                              
      , AVG_INVENTORY_ON_HAND_UNITS_LY                              
      , AVG_INVENTORY_ON_HAND_UNITS_TY_VS_LY                        
      , AVG_INVENTORY_ON_REQUISITION_TY                             
      , AVG_INVENTORY_ON_REQUISITION_LY                             
      , AVG_INVENTORY_ON_REQUISITION_TY_VS_LY                       
      , AVG_INVENTORY_ON_REQUISITION_UNITS_TY                       
      , AVG_INVENTORY_ON_REQUISITION_UNITS_LY                       
      , AVG_INVENTORY_ON_REQUISITION_UNITS_TY_VS_LY                 
      , AVG_INVENTORY_ON_DIRECT_ORDER_TY                            
      , AVG_INVENTORY_ON_DIRECT_ORDER_LY                            
      , AVG_INVENTORY_ON_DIRECT_ORDER_TY_VS_LY                      
      , AVG_INVENTORY_ON_DIRECT_ORDER_UNITS_TY                      
      , AVG_INVENTORY_ON_DIRECT_ORDER_UNITS_LY                      
      , AVG_INVENTORY_ON_DIRECT_ORDER_UNITS_TY_VS_LY                
      , TOT_ITM_OUT_STK_CNT                                         
      , TOT_ITM_STK_CNT                                             
      , INSTOCK_                                                    
      , AVAILABLE_INVENTORY_TY                                      
      , AVAILABLE_INVENTORY_LY                                      
      , INVENTORY_TY_VS_LY                                          
      , AVAILABLE_INVENTORY_UNITS_TY                                
      , AVAILABLE_INVENTORY_UNITS_LY                                
      , INVENTORY_UNITS_TY_VS_LY                                    
      , INVENTORY_ON_DIRECT_ORDER_TY                                
      , INVENTORY_ON_DIRECT_ORDER_LY                                
      , INVENTORY_ON_DIRECT_ORDER_TY_VS_LY                          
      , INVENTORY_ON_DIRECT_ORDER_UNITS_TY                          
      , INVENTORY_ON_DIRECT_ORDER_UNITS_LY                          
      , INVENTORY_ON_DIRECT_ORDER_UNITS__TY_VS_LY                   
      , INVENTORY_UNITS_ON_BILL_TY                                  
      , INVENTORY_UNITS_ON_BILL_LY                                  
      , INVENTORY_UNITS_ON_BILL_TY_VS_LY                            
      , INVENTORY_UNITS_IN_REQ_TY                                   
      , INVENTORY_UNITS_IN_REQ_LY                                   
      , INVENTORY_UNITS_IN_REQ_TY_VS_LY                             
      , TURN_RATES                                                  
      , YTD_SALES_UNITS_THRU_PW_TY                                  
      , YTD_SALES_UNITS_THRU_PW_LY                                  
      , YTD_SALES_UNITS_TY_VS_LY                                    
      , AVG_YTD_SALES_UNITS                                         
      , AVAILABLE_DC_INVENTORY_UNITS                                
      , AVAILABLE_RETAIL_INVENTORY_UNITS                            
      , WEEKS_OF_SUPPLY_ON_HAND                                     
      , WEEKS_OF_SUPPLY_ON_ORDER                                    
      , JDA_LOST_SALES_TY                                           
      , JDA_SERVICE_LEVEL_TY                                        
      , GROSS_SALES                                                 
      , FILE_NAME                                                   
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
      , ITEM_NUMBER
      , END_DATE
      , LOAD_DTS
      , ITEM_NAME
      , ASSORTMENT_NUMBER
      , ASSORTMENT_NAME
      , BRAND_NUMBER
      , BRAND_NAME
      , PRODUCT_GROUP_NUMBER
      , PRODUCT_GROUP_NAME
      , MER_SBO_DVS_NBR
      , MERCHANDISING_SUBDIVISION
      , MER_DVS_NBR
      , MERCHANDISING_DIVISION
      , BUS_ARA_NBR
      , BUSINESS_AREA
      , ADVERTISING_PATCH_AREA_ID
      , DISTRICT_ID
      , DIVISION_DESC
      , GEO_ZONE_ID
      , LOCATION_DESC
      , LOCATION_TYPE_DESC
      , REGION_DESC
      , SERVICING_DZ_ID
      , STATE_ID
      , SUPPORTING_FDC_ID
      , SUPPORTING_FDC_DESC
      , SUPPORTING_REGIONAL_DISTRIBUTION_CENTER_ID
      , WEEK_ID
      , FULFILLED_INTERNET_SALES_TY
      , FULFILLED_INTERNET_SALES_LY
      , FULFILLED_INTERNET_SALES_TY_VS_LY
      , FULFILLED_INTERNET_UNITS_TY
      , FULFILLED_INTERNET_UNITS_LY
      , FULFILLED_INTERNET_UNITS_TY_VS_LY
      , SALES_TY
      , SALES_LY
      , SALES_TY_VS_LY
      , UNITS_TY
      , UNITS_LY
      , UNITS_TY_VS_LY
      , AVG_INVENTORY_ON_HAND_TY
      , AVG_INVENTORY_ON_HAND_LY
      , AVG_INVENTORY_ON_HAND_TY_VS_LY
      , AVG_INVENTORY_ON_HAND_UNITS_TY
      , AVG_INVENTORY_ON_HAND_UNITS_LY
      , AVG_INVENTORY_ON_HAND_UNITS_TY_VS_LY
      , AVG_INVENTORY_ON_REQUISITION_TY
      , AVG_INVENTORY_ON_REQUISITION_LY
      , AVG_INVENTORY_ON_REQUISITION_TY_VS_LY
      , AVG_INVENTORY_ON_REQUISITION_UNITS_TY
      , AVG_INVENTORY_ON_REQUISITION_UNITS_LY
      , AVG_INVENTORY_ON_REQUISITION_UNITS_TY_VS_LY
      , AVG_INVENTORY_ON_DIRECT_ORDER_TY
      , AVG_INVENTORY_ON_DIRECT_ORDER_LY
      , AVG_INVENTORY_ON_DIRECT_ORDER_TY_VS_LY
      , AVG_INVENTORY_ON_DIRECT_ORDER_UNITS_TY
      , AVG_INVENTORY_ON_DIRECT_ORDER_UNITS_LY
      , AVG_INVENTORY_ON_DIRECT_ORDER_UNITS_TY_VS_LY
      , TOT_ITM_OUT_STK_CNT
      , TOT_ITM_STK_CNT
      , INSTOCK_
      , AVAILABLE_INVENTORY_TY
      , AVAILABLE_INVENTORY_LY
      , INVENTORY_TY_VS_LY
      , AVAILABLE_INVENTORY_UNITS_TY
      , AVAILABLE_INVENTORY_UNITS_LY
      , INVENTORY_UNITS_TY_VS_LY
      , INVENTORY_ON_DIRECT_ORDER_TY
      , INVENTORY_ON_DIRECT_ORDER_LY
      , INVENTORY_ON_DIRECT_ORDER_TY_VS_LY
      , INVENTORY_ON_DIRECT_ORDER_UNITS_TY
      , INVENTORY_ON_DIRECT_ORDER_UNITS_LY
      , INVENTORY_ON_DIRECT_ORDER_UNITS__TY_VS_LY
      , INVENTORY_UNITS_ON_BILL_TY
      , INVENTORY_UNITS_ON_BILL_LY
      , INVENTORY_UNITS_ON_BILL_TY_VS_LY
      , INVENTORY_UNITS_IN_REQ_TY
      , INVENTORY_UNITS_IN_REQ_LY
      , INVENTORY_UNITS_IN_REQ_TY_VS_LY
      , TURN_RATES
      , YTD_SALES_UNITS_THRU_PW_TY
      , YTD_SALES_UNITS_THRU_PW_LY
      , YTD_SALES_UNITS_TY_VS_LY
      , AVG_YTD_SALES_UNITS
      , AVAILABLE_DC_INVENTORY_UNITS
      , AVAILABLE_RETAIL_INVENTORY_UNITS
      , WEEKS_OF_SUPPLY_ON_HAND
      , WEEKS_OF_SUPPLY_ON_ORDER
      , JDA_LOST_SALES_TY
      , JDA_SERVICE_LEVEL_TY
      , GROSS_SALES
      , FILE_NAME
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
    WHERE not(location_id='0' and item_number='0' and end_date='-')
)

, FILTER_A as (
    SELECT *
    FROM RENAME_A
    WHERE rec_src = 'US.API.LOWES_VPP.SALES_INVENTORY'
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
        , ITEM_NUMBER
        , END_DATE
        , LOAD_DTS
        , ITEM_NAME
        , ASSORTMENT_NUMBER
        , ASSORTMENT_NAME
        , BRAND_NUMBER
        , BRAND_NAME
        , PRODUCT_GROUP_NUMBER
        , PRODUCT_GROUP_NAME
        , MER_SBO_DVS_NBR
        , MERCHANDISING_SUBDIVISION
        , MER_DVS_NBR
        , MERCHANDISING_DIVISION
        , BUS_ARA_NBR
        , BUSINESS_AREA
        , ADVERTISING_PATCH_AREA_ID
        , DISTRICT_ID
        , DIVISION_DESC
        , GEO_ZONE_ID
        , LOCATION_DESC
        , LOCATION_TYPE_DESC
        , REGION_DESC
        , SERVICING_DZ_ID
        , STATE_ID
        , SUPPORTING_FDC_ID
        , SUPPORTING_FDC_DESC
        , SUPPORTING_REGIONAL_DISTRIBUTION_CENTER_ID
        , WEEK_ID
        , FULFILLED_INTERNET_SALES_TY
        , FULFILLED_INTERNET_SALES_LY
        , FULFILLED_INTERNET_SALES_TY_VS_LY
        , FULFILLED_INTERNET_UNITS_TY
        , FULFILLED_INTERNET_UNITS_LY
        , FULFILLED_INTERNET_UNITS_TY_VS_LY
        , SALES_TY
        , SALES_LY
        , SALES_TY_VS_LY
        , UNITS_TY
        , UNITS_LY
        , UNITS_TY_VS_LY
        , AVG_INVENTORY_ON_HAND_TY
        , AVG_INVENTORY_ON_HAND_LY
        , AVG_INVENTORY_ON_HAND_TY_VS_LY
        , AVG_INVENTORY_ON_HAND_UNITS_TY
        , AVG_INVENTORY_ON_HAND_UNITS_LY
        , AVG_INVENTORY_ON_HAND_UNITS_TY_VS_LY
        , AVG_INVENTORY_ON_REQUISITION_TY
        , AVG_INVENTORY_ON_REQUISITION_LY
        , AVG_INVENTORY_ON_REQUISITION_TY_VS_LY
        , AVG_INVENTORY_ON_REQUISITION_UNITS_TY
        , AVG_INVENTORY_ON_REQUISITION_UNITS_LY
        , AVG_INVENTORY_ON_REQUISITION_UNITS_TY_VS_LY
        , AVG_INVENTORY_ON_DIRECT_ORDER_TY
        , AVG_INVENTORY_ON_DIRECT_ORDER_LY
        , AVG_INVENTORY_ON_DIRECT_ORDER_TY_VS_LY
        , AVG_INVENTORY_ON_DIRECT_ORDER_UNITS_TY
        , AVG_INVENTORY_ON_DIRECT_ORDER_UNITS_LY
        , AVG_INVENTORY_ON_DIRECT_ORDER_UNITS_TY_VS_LY
        , TOT_ITM_OUT_STK_CNT
        , TOT_ITM_STK_CNT
        , INSTOCK_
        , AVAILABLE_INVENTORY_TY
        , AVAILABLE_INVENTORY_LY
        , INVENTORY_TY_VS_LY
        , AVAILABLE_INVENTORY_UNITS_TY
        , AVAILABLE_INVENTORY_UNITS_LY
        , INVENTORY_UNITS_TY_VS_LY
        , INVENTORY_ON_DIRECT_ORDER_TY
        , INVENTORY_ON_DIRECT_ORDER_LY
        , INVENTORY_ON_DIRECT_ORDER_TY_VS_LY
        , INVENTORY_ON_DIRECT_ORDER_UNITS_TY
        , INVENTORY_ON_DIRECT_ORDER_UNITS_LY
        , INVENTORY_ON_DIRECT_ORDER_UNITS__TY_VS_LY
        , INVENTORY_UNITS_ON_BILL_TY
        , INVENTORY_UNITS_ON_BILL_LY
        , INVENTORY_UNITS_ON_BILL_TY_VS_LY
        , INVENTORY_UNITS_IN_REQ_TY
        , INVENTORY_UNITS_IN_REQ_LY
        , INVENTORY_UNITS_IN_REQ_TY_VS_LY
        , TURN_RATES
        , YTD_SALES_UNITS_THRU_PW_TY
        , YTD_SALES_UNITS_THRU_PW_LY
        , YTD_SALES_UNITS_TY_VS_LY
        , AVG_YTD_SALES_UNITS
        , AVAILABLE_DC_INVENTORY_UNITS
        , AVAILABLE_RETAIL_INVENTORY_UNITS
        , WEEKS_OF_SUPPLY_ON_HAND
        , WEEKS_OF_SUPPLY_ON_ORDER
        , JDA_LOST_SALES_TY
        , JDA_SERVICE_LEVEL_TY
        , GROSS_SALES
        , FILE_NAME
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
            , '||', IFNULL(TRIM(ASSORTMENT_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(ASSORTMENT_NAME::text), '^^') 
            , '||', IFNULL(TRIM(BRAND_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(BRAND_NAME::text), '^^') 
            , '||', IFNULL(TRIM(PRODUCT_GROUP_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(PRODUCT_GROUP_NAME::text), '^^') 
            , '||', IFNULL(TRIM(MER_SBO_DVS_NBR::text), '^^') 
            , '||', IFNULL(TRIM(MERCHANDISING_SUBDIVISION::text), '^^') 
            , '||', IFNULL(TRIM(MER_DVS_NBR::text), '^^') 
            , '||', IFNULL(TRIM(MERCHANDISING_DIVISION::text), '^^') 
            , '||', IFNULL(TRIM(BUS_ARA_NBR::text), '^^') 
            , '||', IFNULL(TRIM(BUSINESS_AREA::text), '^^') 
            , '||', IFNULL(TRIM(ADVERTISING_PATCH_AREA_ID::text), '^^') 
            , '||', IFNULL(TRIM(DISTRICT_ID::text), '^^') 
            , '||', IFNULL(TRIM(DIVISION_DESC::text), '^^') 
            , '||', IFNULL(TRIM(GEO_ZONE_ID::text), '^^') 
            , '||', IFNULL(TRIM(LOCATION_DESC::text), '^^') 
            , '||', IFNULL(TRIM(LOCATION_TYPE_DESC::text), '^^') 
            , '||', IFNULL(TRIM(REGION_DESC::text), '^^') 
            , '||', IFNULL(TRIM(SERVICING_DZ_ID::text), '^^') 
            , '||', IFNULL(TRIM(STATE_ID::text), '^^') 
            , '||', IFNULL(TRIM(SUPPORTING_FDC_ID::text), '^^') 
            , '||', IFNULL(TRIM(SUPPORTING_FDC_DESC::text), '^^') 
            , '||', IFNULL(TRIM(SUPPORTING_REGIONAL_DISTRIBUTION_CENTER_ID::text), '^^') 
            , '||', IFNULL(TRIM(WEEK_ID::text), '^^') 
            , '||', IFNULL(TRIM(FULFILLED_INTERNET_SALES_TY::text), '^^') 
            , '||', IFNULL(TRIM(FULFILLED_INTERNET_SALES_LY::text), '^^') 
            , '||', IFNULL(TRIM(FULFILLED_INTERNET_SALES_TY_VS_LY::text), '^^') 
            , '||', IFNULL(TRIM(FULFILLED_INTERNET_UNITS_TY::text), '^^') 
            , '||', IFNULL(TRIM(FULFILLED_INTERNET_UNITS_LY::text), '^^') 
            , '||', IFNULL(TRIM(FULFILLED_INTERNET_UNITS_TY_VS_LY::text), '^^') 
            , '||', IFNULL(TRIM(SALES_TY::text), '^^') 
            , '||', IFNULL(TRIM(SALES_LY::text), '^^') 
            , '||', IFNULL(TRIM(SALES_TY_VS_LY::text), '^^') 
            , '||', IFNULL(TRIM(UNITS_TY::text), '^^') 
            , '||', IFNULL(TRIM(UNITS_LY::text), '^^') 
            , '||', IFNULL(TRIM(UNITS_TY_VS_LY::text), '^^') 
            , '||', IFNULL(TRIM(AVG_INVENTORY_ON_HAND_TY::text), '^^') 
            , '||', IFNULL(TRIM(AVG_INVENTORY_ON_HAND_LY::text), '^^') 
            , '||', IFNULL(TRIM(AVG_INVENTORY_ON_HAND_TY_VS_LY::text), '^^') 
            , '||', IFNULL(TRIM(AVG_INVENTORY_ON_HAND_UNITS_TY::text), '^^') 
            , '||', IFNULL(TRIM(AVG_INVENTORY_ON_HAND_UNITS_LY::text), '^^') 
            , '||', IFNULL(TRIM(AVG_INVENTORY_ON_HAND_UNITS_TY_VS_LY::text), '^^') 
            , '||', IFNULL(TRIM(AVG_INVENTORY_ON_REQUISITION_TY::text), '^^') 
            , '||', IFNULL(TRIM(AVG_INVENTORY_ON_REQUISITION_LY::text), '^^') 
            , '||', IFNULL(TRIM(AVG_INVENTORY_ON_REQUISITION_TY_VS_LY::text), '^^') 
            , '||', IFNULL(TRIM(AVG_INVENTORY_ON_REQUISITION_UNITS_TY::text), '^^') 
            , '||', IFNULL(TRIM(AVG_INVENTORY_ON_REQUISITION_UNITS_LY::text), '^^') 
            , '||', IFNULL(TRIM(AVG_INVENTORY_ON_REQUISITION_UNITS_TY_VS_LY::text), '^^') 
            , '||', IFNULL(TRIM(AVG_INVENTORY_ON_DIRECT_ORDER_TY::text), '^^') 
            , '||', IFNULL(TRIM(AVG_INVENTORY_ON_DIRECT_ORDER_LY::text), '^^') 
            , '||', IFNULL(TRIM(AVG_INVENTORY_ON_DIRECT_ORDER_TY_VS_LY::text), '^^') 
            , '||', IFNULL(TRIM(AVG_INVENTORY_ON_DIRECT_ORDER_UNITS_TY::text), '^^') 
            , '||', IFNULL(TRIM(AVG_INVENTORY_ON_DIRECT_ORDER_UNITS_LY::text), '^^') 
            , '||', IFNULL(TRIM(AVG_INVENTORY_ON_DIRECT_ORDER_UNITS_TY_VS_LY::text), '^^') 
            , '||', IFNULL(TRIM(TOT_ITM_OUT_STK_CNT::text), '^^') 
            , '||', IFNULL(TRIM(TOT_ITM_STK_CNT::text), '^^') 
            , '||', IFNULL(TRIM(INSTOCK_::text), '^^') 
            , '||', IFNULL(TRIM(AVAILABLE_INVENTORY_TY::text), '^^') 
            , '||', IFNULL(TRIM(AVAILABLE_INVENTORY_LY::text), '^^') 
            , '||', IFNULL(TRIM(INVENTORY_TY_VS_LY::text), '^^') 
            , '||', IFNULL(TRIM(AVAILABLE_INVENTORY_UNITS_TY::text), '^^') 
            , '||', IFNULL(TRIM(AVAILABLE_INVENTORY_UNITS_LY::text), '^^') 
            , '||', IFNULL(TRIM(INVENTORY_UNITS_TY_VS_LY::text), '^^') 
            , '||', IFNULL(TRIM(INVENTORY_ON_DIRECT_ORDER_TY::text), '^^') 
            , '||', IFNULL(TRIM(INVENTORY_ON_DIRECT_ORDER_LY::text), '^^') 
            , '||', IFNULL(TRIM(INVENTORY_ON_DIRECT_ORDER_TY_VS_LY::text), '^^') 
            , '||', IFNULL(TRIM(INVENTORY_ON_DIRECT_ORDER_UNITS_TY::text), '^^') 
            , '||', IFNULL(TRIM(INVENTORY_ON_DIRECT_ORDER_UNITS_LY::text), '^^') 
            , '||', IFNULL(TRIM(INVENTORY_ON_DIRECT_ORDER_UNITS__TY_VS_LY::text), '^^') 
            , '||', IFNULL(TRIM(INVENTORY_UNITS_ON_BILL_TY::text), '^^') 
            , '||', IFNULL(TRIM(INVENTORY_UNITS_ON_BILL_LY::text), '^^') 
            , '||', IFNULL(TRIM(INVENTORY_UNITS_ON_BILL_TY_VS_LY::text), '^^') 
            , '||', IFNULL(TRIM(INVENTORY_UNITS_IN_REQ_TY::text), '^^') 
            , '||', IFNULL(TRIM(INVENTORY_UNITS_IN_REQ_LY::text), '^^') 
            , '||', IFNULL(TRIM(INVENTORY_UNITS_IN_REQ_TY_VS_LY::text), '^^') 
            , '||', IFNULL(TRIM(TURN_RATES::text), '^^') 
            , '||', IFNULL(TRIM(YTD_SALES_UNITS_THRU_PW_TY::text), '^^') 
            , '||', IFNULL(TRIM(YTD_SALES_UNITS_THRU_PW_LY::text), '^^') 
            , '||', IFNULL(TRIM(YTD_SALES_UNITS_TY_VS_LY::text), '^^') 
            , '||', IFNULL(TRIM(AVG_YTD_SALES_UNITS::text), '^^') 
            , '||', IFNULL(TRIM(AVAILABLE_DC_INVENTORY_UNITS::text), '^^') 
            , '||', IFNULL(TRIM(AVAILABLE_RETAIL_INVENTORY_UNITS::text), '^^') 
            , '||', IFNULL(TRIM(WEEKS_OF_SUPPLY_ON_HAND::text), '^^') 
            , '||', IFNULL(TRIM(WEEKS_OF_SUPPLY_ON_ORDER::text), '^^') 
            , '||', IFNULL(TRIM(JDA_LOST_SALES_TY::text), '^^') 
            , '||', IFNULL(TRIM(JDA_SERVICE_LEVEL_TY::text), '^^') 
            , '||', IFNULL(TRIM(GROSS_SALES::text), '^^') 
            , '||', IFNULL(TRIM(FILE_NAME::text), '^^') 
            , '||', IFNULL(TRIM(START_DATE::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
