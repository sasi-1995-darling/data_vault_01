{{
    config(
        materialized='incremental',
        transient=false,
        unique_key='plsd_hk'
    )
}}


with cte_part_buffer_tracking as (
    select * from {{ ref('stg_planning_buffer_tracking__moen_o8') }} as SRC
                              {% if is_incremental() %}
                        where SRC.load_dts > (SELECT DATEADD('MINUTE', '-1', MAX(planning_load_date)) FROM {{this}})
                          {% endif %}  

)

, cte_parts as (
    select * from {{ ref('stg_planning_part__moen_o8') }} as SRC
                                  {% if is_incremental() %}
                        where SRC.load_dts > (SELECT DATEADD('MINUTE', '-1', MAX(part_load_date)) FROM {{this}})
                          {% endif %}  
)

, planning_all as ( 
    select plsd_hk,
           pls_hk, 
           base_part_number,
           location,
           supplier,
           date        as buffer_date,
           rule,
           stock,
           orders,
           strat_buffer,
           yellow_zone,
           red_zone,
           green_zone,
           load_dts,
           date(sys_date,'dd-mm-yyyy') as planning_date,
           ROW_NUMBER() OVER (PARTITION BY base_part_number, location,supplier,date order by date(sys_date,'dd-mm-yyyy') DESC) rn
     from  cte_part_buffer_tracking
    where  true
      and base_part_number <> 'FLOW'
)

, latest_planning as (
    select pl.*,
      from planning_all pl
     where rn = 1
)

, latest_planning_with_item_date as (
    select pl.*,
    max(pm.planning_date)   as part_planning_date
   from latest_planning pl
   join cte_parts pm
     on pl.pls_hk = pm.pls_hk
    and pl.planning_date >= pm.planning_date
 group by all
)
    
    select plsd_hk,
           a.base_part_number                                               as part_number,
           a.location                                                       as location,
           a.supplier                                                       as supplier_code,
           a.buffer_date                                                    as buffer_date,
           a.rule                                                           as rule,
           a.strat_buffer                                                   as strategic_buffer,
           a.yellow_zone                                                    as yellow_zone,
           a.red_zone                                                       as red_zone,
           a.green_zone                                                     as green_zone,
           a.strat_buffer + a.yellow_zone + a.red_zone + a.green_zone       as total_buffer,
           a.orders                                                         as total_orders,
           a.stock                                                          as total_stock,
           a.strat_buffer * b.material_cost                                 as strategic_dollars,
           a.yellow_zone * b.material_cost                                  as yellow_dollars,
           a.red_zone * b.material_cost                                     as red_dollars,
           a.green_zone * b.material_cost                                   as green_dollars,
           (a.strat_buffer + a.yellow_zone + a.red_zone + a.green_zone)  * b.material_cost       as total_buffer_dollars,
           a.orders * b.material_cost                                       as order_dollars,
           (strategic_dollars + red_dollars + yellow_dollars + green_dollars)/2                  as onhand_dollars,
           (a.strat_buffer + a.red_zone + 0.5 *(a.green_zone)) * b.material_cost                 as DDI_target_dollars,           
           b.part_description                                               as part_description,  
           b.supplier_name                                                  as supplier_name, 
           b.manufactured_purchased, 
           b.replenishment_leadtime, 
           b.maximum_order_qty, 
           b.minimum_order_qty, 
           b.multiple_order_qty, 
           b.phase_in_date, 
           b.phase_out_date, 
           b.part_type_code, 
           b.material_cost, 
           b.product_family, 
           b.planner_code, 
           b.days_strat_buffer, 
           b.container_qty, 
           b.part_status, 
           b.leadtime_offset, 
           b.report_field_1                                                 as part_attribute_1, 
           b.report_field_2                                                 as part_attribute_2, 
           b.report_field_3                                                 as part_attribute_3, 
           b.report_field_4                                                 as part_attribute_4, 
           b.report_field_5                                                 as part_attribute_5, 
           b.manufacturing_leadtime, 
           b.uom_conversion, 
           b.unit_of_measure, 
           b.apply_uom, 
           b.report_field_6                                                 as part_attribute_6, 
           b.report_field_7                                                 as part_attribute_7, 
           b.report_field_8                                                 as part_attribute_8, 
           b.report_field_9                                                 as part_attribute_9, 
           b.report_field_10                                                as part_attribute_10, 
           b.customer_part_number, 
           b.orig_customer_code, 
           b.material_type, 
           b.asrleadtime, 
           b.stackable, 
           b.hazardous, 
           b.report_field_11                                                as part_attribute_11, 
           b.report_field_12                                                as part_attribute_12, 
           b.report_field_13                                                as part_attribute_13, 
           b.report_field_14                                                as part_attribute_14, 
           b.active,
           b.planning_date                                                  as part_o8_reported_date,
           a.planning_date                                                  as planning_o8_reported_date,
           a.load_dts                                                       as planning_load_date,
           b.load_dts                                                       as part_load_date
      FROM latest_planning_with_item_date a
 LEFT JOIN cte_parts b
     WHERE 1 = 1
       and a.pls_hk = b.pls_hk
       and a.part_planning_date = b.planning_date