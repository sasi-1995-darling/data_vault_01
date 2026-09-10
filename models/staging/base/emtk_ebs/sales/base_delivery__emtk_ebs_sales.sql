/*
    HUB: Delivery
*/

with cte_wsh_delivery_details as (
    select 
    delivery_detail_id::varchar as delivery_detail_id -- BK
    ,source_line_id
    ,move_order_line_id
    ,transaction_id
    ,ato_line_id
    ,earliest_pickup_date
    ,latest_pickup_date
    ,creation_date
    ,batch_id
    ,source_header_id
    ,source_header_number
    ,date_requested
    ,tracking_number
    ,cust_po_number
    ,ship_to_location_id
    ,ship_to_site_use_id
    ,deliver_to_location_id
    ,last_update_date
    ,item_description
    ,inventory_item_id
    ,last_update_login
    ,customer_item_id
    ,split_from_delivery_detail_id
    ,source_line_set_id
    ,customer_id
    ,net_weight
    ,gross_weight
    ,date_scheduled
    ,unit_price
    ,source_line_number
    ,request_id
    ,program_update_date
    ,requested_quantity
    ,shipped_quantity
    ,src_requested_quantity
    ,picked_quantity
    ,ship_to_contact_id
    ,sold_to_contact_id
    ,cancelled_quantity
    ,created_by
    ,last_updated_by
    ,unit_weight
    ,ship_set_id
    ,shipping_instructions
    ,source_header_type_id
    ,source_header_type_name
    ,ship_method_code
    ,deliver_to_site_use_id
    ,freight_terms_code
    ,arrival_set_id
    ,service_level
    ,packing_instructions
    ,released_status
    ,carrier_id
    ,fob_code
    ,inv_interfaced_flag
    ,src_requested_quantity_uom
    ,requested_quantity2
    ,requested_quantity_uom
    ,subinventory
    ,oe_interfaced_flag
    ,mode_of_transport
    ,weight_uom_code
    ,pickable_flag
    ,shipment_priority_code
    ,source_document_type_id
    ,org_id
    ,organization_id
    ,ship_from_location_id
    ,wv_frozen_flag
    ,source_code
    ,cycle_count_quantity
    ,program_application_id
    ,program_id
    ,cycle_count_quantity2
    ,ship_tolerance_below
    ,ship_tolerance_above
    ,ship_model_complete_flag
    ,delivered_quantity2
    ,shipped_quantity2
    ,currency_code
    ,inspection_flag
    ,ignore_for_planning
    ,quality_control_quantity2
    ,top_model_line_id
    ,line_direction
    ,cancelled_quantity2
    ,tms_interface_flag
    ,dep_plan_required_flag
    ,mvt_stat_status
    ,container_flag
    ,quality_control_quantity
    ,delivered_quantity
        ,_fivetran_synced
    from {{ source('emtk_ebs_sales__wsh', 'wsh_delivery_details') }}
    where _fivetran_deleted = false
)

, cte_union_default as (
    /* because links to delivery may not exist */
    select
    '-1' as delivery_detail_id -- BK
    ,null as source_line_id
    ,null as move_order_line_id
    ,null as transaction_id
    ,null as ato_line_id
    ,null as earliest_pickup_date
    ,null as latest_pickup_date
    ,null as creation_date
    ,null as batch_id
    ,null as source_header_id
    ,null as source_header_number
    ,null as date_requested
    ,null as tracking_number
    ,null as cust_po_number
    ,null as ship_to_location_id
    ,null as ship_to_site_use_id
    ,null as deliver_to_location_id
    ,null as last_update_date
    ,null as item_description
    ,null as inventory_item_id
    ,null as last_update_login
    ,null as customer_item_id
    ,null as split_from_delivery_detail_id
    ,null as source_line_set_id
    ,null as customer_id
    ,null as net_weight
    ,null as gross_weight
    ,null as date_scheduled
    ,null as unit_price
    ,null as source_line_number
    ,null as request_id
    ,null as program_update_date
    ,null as requested_quantity
    ,null as shipped_quantity
    ,null as src_requested_quantity
    ,null as picked_quantity
    ,null as ship_to_contact_id
    ,null as sold_to_contact_id
    ,null as cancelled_quantity
    ,null as created_by
    ,null as last_updated_by
    ,null as unit_weight
    ,null as ship_set_id
    ,null as shipping_instructions
    ,null as source_header_type_id
    ,null as source_header_type_name
    ,null as ship_method_code
    ,null as deliver_to_site_use_id
    ,null as freight_terms_code
    ,null as arrival_set_id
    ,null as service_level
    ,null as packing_instructions
    ,null as released_status
    ,null as carrier_id
    ,null as fob_code
    ,null as inv_interfaced_flag
    ,null as src_requested_quantity_uom
    ,null as requested_quantity2
    ,null as requested_quantity_uom
    ,null as subinventory
    ,null as oe_interfaced_flag
    ,null as mode_of_transport
    ,null as weight_uom_code
    ,null as pickable_flag
    ,null as shipment_priority_code
    ,null as source_document_type_id
    ,null as org_id
    ,null as organization_id
    ,null as ship_from_location_id
    ,null as wv_frozen_flag
    ,null as source_code
    ,null as cycle_count_quantity
    ,null as program_application_id
    ,null as program_id
    ,null as cycle_count_quantity2
    ,null as ship_tolerance_below
    ,null as ship_tolerance_above
    ,null as ship_model_complete_flag
    ,null as delivered_quantity2
    ,null as shipped_quantity2
    ,null as currency_code
    ,null as inspection_flag
    ,null as ignore_for_planning
    ,null as quality_control_quantity2
    ,null as top_model_line_id
    ,null as line_direction
    ,null as cancelled_quantity2
    ,null as tms_interface_flag
    ,null as dep_plan_required_flag
    ,null as mvt_stat_status
    ,null as container_flag
    ,null as quality_control_quantity
    ,null as delivered_quantity
    ,'1900-01-01' as _fivetran_synced
)

, cte_final as (
    select *
    from cte_wsh_delivery_details

    union all

    select * 
    from cte_union_default
)

select * from cte_final
