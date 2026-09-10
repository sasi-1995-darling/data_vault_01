{{
  config(
    materialized='incremental', 
    incremental_strategy='append',
    incremental_predicates = [
      "DBT_INTERNAL_DEST.LOAD_DTS >= dateadd(day, -7, current_date)"
    ]
  )
}}
---- SRC LAYER ----
WITH
SRC_PM             as ( SELECT * FROM {{ source('o8__winn', 'part_master') }} as SRC 
                        where base_part_number<> 'FLOW'
                        {% if is_incremental() %}
                        and src._fivetran_synced > (select dateadd('minute','-1',max(load_dts)) from {{ this }})
                        {% endif %} )

/*
SRC_PM             as ( SELECT * FROM o8__winn.part_master )
*/
---- LOGIC LAYER ----

, LOGIC_PM as (
    SELECT
        _file                                                       
      , _line                                                       
      , _modified                                                   
      , part_number                                                 
      , part_description                                            
      , supplier_code                                               
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
      , location                                                    
      , asrleadtime                                                 
      , stackable                                                   
      , hazardous                                                   
      , report_field_11                                             
      , report_field_12                                             
      , report_field_13                                             
      , report_field_14                                             
      , active                                                      
      , _fivetran_synced                                             as                                           load_dts
      , base_part_number                                            
      , date(sys_date,'dd-mm-yyyy')                                  as                                     planning_date 
      , '!MOEN'                                                      as                                              brand
      , '!O8'                                                        as                                            rec_src
      , CONCAT_WS('||',
            COALESCE(base_part_number::TEXT, ''),
            COALESCE(location::TEXT, ''),
            COALESCE(supplier_code::TEXT, '')
        )                                                            as                                             pls_bk
      , CAST(MD5_BINARY(NULLIF(CONCAT(IFNULL(NULLIF(UPPER(TRIM(CAST(pls_bk AS VARCHAR))), ''), '^^'), '||',IFNULL(NULLIF(UPPER(TRIM(CAST(brand AS VARCHAR))), ''), '^^')), '^^||^^')) AS BINARY(16)) as                                             pls_hk
    FROM SRC_PM
)
---- RENAME LAYER ----

, RENAME_PM as (
    SELECT
        _file
      , _line
      , _modified
      , part_number 
      , part_description 
      , supplier_code 
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
      , location 
      , asrleadtime 
      , stackable 
      , hazardous 
      , report_field_11 
      , report_field_12 
      , report_field_13 
      , report_field_14 
      , active 
      , load_dts
      , base_part_number
      , planning_date 
      , brand
      , rec_src
      , pls_bk
      , pls_hk
    FROM LOGIC_PM
)
---- FILTER LAYER ----

, FILTER_PM as (
    SELECT *
    FROM RENAME_PM
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_PM
)

---- FINAL LAYER ----
SELECT
          _FILE
        , _LINE
        , _MODIFIED
        , PART_NUMBER 
        , PART_DESCRIPTION 
        , SUPPLIER_CODE 
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
        , LOCATION 
        , ASRLEADTIME 
        , STACKABLE 
        , HAZARDOUS 
        , REPORT_FIELD_11 
        , REPORT_FIELD_12 
        , REPORT_FIELD_13 
        , REPORT_FIELD_14 
        , ACTIVE 
        , LOAD_DTS
        , BASE_PART_NUMBER
        , PLANNING_DATE 
        , BRAND
        , REC_SRC
        , PLS_BK
        , PLS_HK
        , CAST(MD5_BINARY(NULLIF(CONCAT(
              
            IFNULL(NULLIF(UPPER(TRIM(_MODIFIED::text)), ''), '^^')  , '||', IFNULL(NULLIF(UPPER(TRIM(PART_NUMBER ::text)), ''), '^^')  , '||', IFNULL(NULLIF(UPPER(TRIM(PART_DESCRIPTION ::text)), ''), '^^')  , '||', IFNULL(NULLIF(UPPER(TRIM(SUPPLIER_CODE ::text)), ''), '^^')  , '||', IFNULL(NULLIF(UPPER(TRIM(SUPPLIER_NAME ::text)), ''), '^^')  , '||', IFNULL(NULLIF(UPPER(TRIM(MANUFACTURED_PURCHASED::text)), ''), '^^')  , '||', IFNULL(NULLIF(UPPER(TRIM(REPLENISHMENT_LEADTIME::text)), ''), '^^')  , '||', IFNULL(NULLIF(UPPER(TRIM(MAXIMUM_ORDER_QTY ::text)), ''), '^^')  , '||', IFNULL(NULLIF(UPPER(TRIM(MINIMUM_ORDER_QTY ::text)), ''), '^^')  , '||', IFNULL(NULLIF(UPPER(TRIM(MULTIPLE_ORDER_QTY::text)), ''), '^^')  , '||', IFNULL(NULLIF(UPPER(TRIM(PHASE_IN_DATE ::text)), ''), '^^')  , '||', IFNULL(NULLIF(UPPER(TRIM(PHASE_OUT_DATE ::text)), ''), '^^')  , '||', IFNULL(NULLIF(UPPER(TRIM(PART_TYPE_CODE ::text)), ''), '^^')  , '||', IFNULL(NULLIF(UPPER(TRIM(MATERIAL_COST ::text)), ''), '^^')  , '||', IFNULL(NULLIF(UPPER(TRIM(PRODUCT_FAMILY::text)), ''), '^^')  , '||', IFNULL(NULLIF(UPPER(TRIM(PLANNER_CODE ::text)), ''), '^^')  , '||', IFNULL(NULLIF(UPPER(TRIM(DAYS_STRAT_BUFFER ::text)), ''), '^^')  , '||', IFNULL(NULLIF(UPPER(TRIM(CONTAINER_QTY ::text)), ''), '^^')  , '||', IFNULL(NULLIF(UPPER(TRIM(PART_STATUS::text)), ''), '^^')  , '||', IFNULL(NULLIF(UPPER(TRIM(LEADTIME_OFFSET ::text)), ''), '^^')  , '||', IFNULL(NULLIF(UPPER(TRIM(REPORT_FIELD_1 ::text)), ''), '^^')  , '||', IFNULL(NULLIF(UPPER(TRIM(REPORT_FIELD_2 ::text)), ''), '^^')  , '||', IFNULL(NULLIF(UPPER(TRIM(REPORT_FIELD_3 ::text)), ''), '^^')  , '||', IFNULL(NULLIF(UPPER(TRIM(REPORT_FIELD_4 ::text)), ''), '^^')  , '||', IFNULL(NULLIF(UPPER(TRIM(REPORT_FIELD_5 ::text)), ''), '^^')  , '||', IFNULL(NULLIF(UPPER(TRIM(MANUFACTURING_LEADTIME ::text)), ''), '^^')  , '||', IFNULL(NULLIF(UPPER(TRIM(UOM_CONVERSION ::text)), ''), '^^')  , '||', IFNULL(NULLIF(UPPER(TRIM(UNIT_OF_MEASURE ::text)), ''), '^^')  , '||', IFNULL(NULLIF(UPPER(TRIM(APPLY_UOM ::text)), ''), '^^')  , '||', IFNULL(NULLIF(UPPER(TRIM(REPORT_FIELD_6 ::text)), ''), '^^')  , '||', IFNULL(NULLIF(UPPER(TRIM(REPORT_FIELD_7 ::text)), ''), '^^')  , '||', IFNULL(NULLIF(UPPER(TRIM(REPORT_FIELD_8 ::text)), ''), '^^')  , '||', IFNULL(NULLIF(UPPER(TRIM(REPORT_FIELD_9 ::text)), ''), '^^')  , '||', IFNULL(NULLIF(UPPER(TRIM(REPORT_FIELD_10 ::text)), ''), '^^')  , '||', IFNULL(NULLIF(UPPER(TRIM(CUSTOMER_PART_NUMBER ::text)), ''), '^^')  , '||', IFNULL(NULLIF(UPPER(TRIM(ORIG_CUSTOMER_CODE ::text)), ''), '^^')  , '||', IFNULL(NULLIF(UPPER(TRIM(MATERIAL_TYPE ::text)), ''), '^^')  , '||', IFNULL(NULLIF(UPPER(TRIM(LOCATION ::text)), ''), '^^')  , '||', IFNULL(NULLIF(UPPER(TRIM(ASRLEADTIME ::text)), ''), '^^')  , '||', IFNULL(NULLIF(UPPER(TRIM(STACKABLE ::text)), ''), '^^')  , '||', IFNULL(NULLIF(UPPER(TRIM(HAZARDOUS ::text)), ''), '^^')  , '||', IFNULL(NULLIF(UPPER(TRIM(REPORT_FIELD_11 ::text)), ''), '^^')  , '||', IFNULL(NULLIF(UPPER(TRIM(REPORT_FIELD_12 ::text)), ''), '^^')  , '||', IFNULL(NULLIF(UPPER(TRIM(REPORT_FIELD_13 ::text)), ''), '^^')  , '||', IFNULL(NULLIF(UPPER(TRIM(REPORT_FIELD_14 ::text)), ''), '^^')  , '||', IFNULL(NULLIF(UPPER(TRIM(ACTIVE ::text)), ''), '^^')  , '||', IFNULL(NULLIF(UPPER(TRIM(BASE_PART_NUMBER::text)), ''), '^^')  , '||', IFNULL(NULLIF(UPPER(TRIM(BRAND::text)), ''), '^^')  , '||', IFNULL(NULLIF(UPPER(TRIM(REC_SRC::text)), ''), '^^') 
          ), '^^||^^')) AS BINARY(16)) as HASHDIFF
FROM JOIN_RESULT
{% if is_incremental() %}
where not exists (
select 1 
   from {{ this }} existing
  where existing._file = join_result._file and existing.pls_bk = join_result.pls_bk and existing.load_dts = join_result.load_dts
    )
    {% endif %}