{%- set yaml_metadata -%}
source_model: 'base_delivery__emtk_ebs_sales'
derived_columns:
  rec_src: '!EMTEK_EBS'
  load_dts: '_fivetran_synced'
  brand: '!EMTEK'
  delivery_bk: delivery_detail_id
hashed_columns:
  delivery_hk: 
    columns:
    - 'delivery_bk'
    - 'brand'
  delivery_hdiff:
    is_hashdiff: true
    columns:
    - 'delivery_detail_id'
    - 'source_line_id'
    - 'move_order_line_id'
    - 'transaction_id'
    - 'ato_line_id'
    - 'earliest_pickup_date'
    - 'latest_pickup_date'
    - 'creation_date'
    - 'batch_id'
    - 'source_header_id'
    - 'source_header_number'
    - 'date_requested'
    - 'tracking_number'
    - 'cust_po_number'
    - 'ship_to_location_id'
    - 'ship_to_site_use_id'
    - 'deliver_to_location_id'
    - 'last_update_date'
    - 'item_description'
    - 'inventory_item_id'
    - 'last_update_login'
    - 'customer_item_id'
    - 'split_from_delivery_detail_id'
    - 'source_line_set_id'
    - 'customer_id'
    - 'net_weight'
    - 'gross_weight'
    - 'date_scheduled'
    - 'unit_price'
    - 'source_line_number'
    - 'request_id'
    - 'program_update_date'
    - 'requested_quantity'
    - 'shipped_quantity'
    - 'src_requested_quantity'
    - 'picked_quantity'
    - 'ship_to_contact_id'
    - 'sold_to_contact_id'
    - 'cancelled_quantity'
    - 'created_by'
    - 'last_updated_by'
    - 'unit_weight'
    - 'ship_set_id'
    - 'shipping_instructions'
    - 'source_header_type_id'
    - 'source_header_type_name'
    - 'ship_method_code'
    - 'deliver_to_site_use_id'
    - 'freight_terms_code'
    - 'arrival_set_id'
    - 'service_level'
    - 'packing_instructions'
    - 'released_status'
    - 'carrier_id'
    - 'fob_code'
    - 'inv_interfaced_flag'
    - 'src_requested_quantity_uom'
    - 'requested_quantity2'
    - 'requested_quantity_uom'
    - 'subinventory'
    - 'oe_interfaced_flag'
    - 'mode_of_transport'
    - 'weight_uom_code'
    - 'pickable_flag'
    - 'shipment_priority_code'
    - 'source_document_type_id'
    - 'org_id'
    - 'organization_id'
    - 'ship_from_location_id'
    - 'wv_frozen_flag'
    - 'source_code'
    - 'cycle_count_quantity'
    - 'program_application_id'
    - 'program_id'
    - 'cycle_count_quantity2'
    - 'ship_tolerance_below'
    - 'ship_tolerance_above'
    - 'ship_model_complete_flag'
    - 'delivered_quantity2'
    - 'shipped_quantity2'
    - 'currency_code'
    - 'inspection_flag'
    - 'ignore_for_planning'
    - 'quality_control_quantity2'
    - 'top_model_line_id'
    - 'line_direction'
    - 'cancelled_quantity2'
    - 'tms_interface_flag'
    - 'dep_plan_required_flag'
    - 'mvt_stat_status'
    - 'container_flag'
    - 'quality_control_quantity'
    - 'delivered_quantity'

{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}

{% set source_model = metadata_dict['source_model'] %}
{% set derived_columns = metadata_dict['derived_columns'] %}
{% set hashed_columns = metadata_dict['hashed_columns'] %}

{{ automate_dv.stage(include_source_columns=true,
                     source_model=source_model,
                     derived_columns=derived_columns,
                     null_columns=none,
                     hashed_columns=hashed_columns,
                     ranked_columns=none) }}
