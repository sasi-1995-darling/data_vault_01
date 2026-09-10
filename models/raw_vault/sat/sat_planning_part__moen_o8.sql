---- SRC LAYER ----
WITH
SRC_SPM            as ( SELECT * FROM {{ ref('stg_planning_part__moen_o8') }} as SRC 
                        {% if is_incremental() %}
                        WHERE src.load_dts > (SELECT DATEADD('MINUTE','-1',MAX(LOAD_DTS)) FROM {{ this }})
                        {% endif %}   )

/*
SRC_SPM            as ( SELECT * FROM staging.stg_planning_part__moen_o8 )
*/
---- LOGIC LAYER ----

, LOGIC_SPM as (
    SELECT
        pls_bk                                                      
      , pls_hk                                                      
      , hashdiff                                                    
      , base_part_number                                            
      , location                                                    
      , supplier_code                                               
      , _modified                                                   
      , part_description                                            
      , supplier_name                                               
      , manufactured_purchased                                      
      , replenishment_leadtime                                      
      , maximum_order_qty                                           
      , minimum_order_qty                                           
      , multiple_order_qty                                          
      , phase_in_date                                               
      , phase_out_date                                              
      , part_type_code                                              
      , material_cost                                               
      , product_family                                              
      , planner_code                                                
      , days_strat_buffer                                           
      , container_qty                                               
      , part_status                                                 
      , leadtime_offset                                             
      , report_field_1                                              
      , report_field_2                                              
      , report_field_3                                              
      , report_field_4                                              
      , report_field_5                                              
      , manufacturing_leadtime                                      
      , uom_conversion                                              
      , unit_of_measure                                             
      , apply_uom                                                   
      , report_field_6                                              
      , report_field_7                                              
      , report_field_8                                              
      , report_field_9                                              
      , report_field_10                                             
      , customer_part_number                                        
      , orig_customer_code                                          
      , material_type                                               
      , asrleadtime                                                 
      , stackable                                                   
      , hazardous                                                   
      , report_field_11                                             
      , report_field_12                                             
      , report_field_13                                             
      , report_field_14                                             
      , active                                                      
      , load_dts                                                    
      , planning_date                                               
      , brand                                                       
      , rec_src                                                     
    FROM SRC_SPM
)
---- RENAME LAYER ----

, RENAME_SPM as (
    SELECT
        pls_bk
      , pls_hk
      , hashdiff
      , base_part_number
      , location
      , supplier_code
      , _modified
      , part_description
      , supplier_name
      , manufactured_purchased
      , replenishment_leadtime
      , maximum_order_qty
      , minimum_order_qty
      , multiple_order_qty
      , phase_in_date
      , phase_out_date
      , part_type_code
      , material_cost
      , product_family
      , planner_code
      , days_strat_buffer
      , container_qty
      , part_status
      , leadtime_offset
      , report_field_1
      , report_field_2
      , report_field_3
      , report_field_4
      , report_field_5
      , manufacturing_leadtime
      , uom_conversion
      , unit_of_measure
      , apply_uom
      , report_field_6
      , report_field_7
      , report_field_8
      , report_field_9
      , report_field_10
      , customer_part_number
      , orig_customer_code
      , material_type
      , asrleadtime
      , stackable
      , hazardous
      , report_field_11
      , report_field_12
      , report_field_13
      , report_field_14
      , active
      , load_dts
      , planning_date
      , brand
      , rec_src
    FROM LOGIC_SPM
)
---- FILTER LAYER ----

, FILTER_SPM as (
    SELECT *
    FROM RENAME_SPM
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_SPM
)

---- FINAL LAYER ----
SELECT
          PLS_BK
        , PLS_HK
        , BASE_PART_NUMBER
        , LOCATION
        , SUPPLIER_CODE
        , _MODIFIED
        , PART_DESCRIPTION
        , SUPPLIER_NAME
        , MANUFACTURED_PURCHASED
        , REPLENISHMENT_LEADTIME
        , MAXIMUM_ORDER_QTY
        , MINIMUM_ORDER_QTY
        , MULTIPLE_ORDER_QTY
        , PHASE_IN_DATE
        , PHASE_OUT_DATE
        , PART_TYPE_CODE
        , MATERIAL_COST
        , PRODUCT_FAMILY
        , PLANNER_CODE
        , DAYS_STRAT_BUFFER
        , CONTAINER_QTY
        , PART_STATUS
        , LEADTIME_OFFSET
        , REPORT_FIELD_1
        , REPORT_FIELD_2
        , REPORT_FIELD_3
        , REPORT_FIELD_4
        , REPORT_FIELD_5
        , MANUFACTURING_LEADTIME
        , UOM_CONVERSION
        , UNIT_OF_MEASURE
        , APPLY_UOM
        , REPORT_FIELD_6
        , REPORT_FIELD_7
        , REPORT_FIELD_8
        , REPORT_FIELD_9
        , REPORT_FIELD_10
        , CUSTOMER_PART_NUMBER
        , ORIG_CUSTOMER_CODE
        , MATERIAL_TYPE
        , ASRLEADTIME
        , STACKABLE
        , HAZARDOUS
        , REPORT_FIELD_11
        , REPORT_FIELD_12
        , REPORT_FIELD_13
        , REPORT_FIELD_14
        , ACTIVE
        , LOAD_DTS
        , PLANNING_DATE
        , BRAND
        , REC_SRC
        , HASHDIFF
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.pls_HK = join_result.pls_HK AND existing.LOAD_DTS = join_result.load_dts
)
{% endif %}