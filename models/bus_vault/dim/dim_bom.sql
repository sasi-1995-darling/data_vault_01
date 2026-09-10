select
    root_item_key
    , root_item_number
    , root_bom_key
    , root_bom_number
    , root_plant_key
    , root_plant
    , root_bom_category
    , root_bom_usage
    , root_alt_bom
    , assembly_item_key
    , assembly_item_number
    , assembly_bom_key
    , assembly_bom_number
    , assembly_plant_key
    , assembly_plant
    , assembly_bom_category
    , assembly_bom_usage
    , assembly_alt_bom
    , bom_is_preferred
    , bom_implementation_date__yyyymmdd
    , bom_change_notice
    , component_item_key
    , component_item_number
    , component_quantity
    , component_uom
    , component_item_num
    , component_operation_sequence_num
    , component_sequence_id
    , component_item_node_num
    , component_bom_item_type
    , component_supply_subinventory
    , component_wip_supply_type
    , component_mutually_exclusive_options
    , component_optional
    , include_component_in_cost_rollup
    , component_change_notice
    , component_effective_from_date__yyyymmdd
    , component_effective_to_date__yyyymmdd
    , level
    , REPLACE(LTRIM(bom_path, ','), ',', ' -> ') AS bom_path
    , bkcc
    , rec_src
from {{ ref('pb_bom_explosion') }}