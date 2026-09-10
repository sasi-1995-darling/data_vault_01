{{
    config(
        materialized='ephemeral'
    )
}}

with
cte_sat_item_base__fib_ocf as (
    select
        item_hk
        , inventory_item_id
        , organization_id
        , item_type
        , inventory_item_status_code
        , creation_date
        , item_catalog_group_id
        , _fivetran_deleted
        , hash(item_number, inventory_item_id, organization_id) as pk
		, unit_of_issue
		, std_lot_size
		, fixed_order_quantity
		, over_shipment_tolerance
		, under_shipment_tolerance
        , load_dts
    from {{ ref('sat_item_base__fib_ocf') }}
)

, cte_sat_item_base__fib_ocf_latest as (
    {{ generate_cte_satellite_latest('cte_sat_item_base__fib_ocf', 'pk') }}
)

, cte_sat_item_language__fib_ocf as (
    select
        item_hk
        , inventory_item_id
        , organization_id
        , language
        , description
        , creation_date
        , _fivetran_deleted
        , hash(item_hk, inventory_item_id, organization_id, language) as pk
        , load_dts
    from {{ ref('sat_item_language__fib_ocf') }}
)

, cte_sat_item_language__fib_ocf_latest as (
    {{ generate_cte_satellite_latest('cte_sat_item_language__fib_ocf', 'pk') }}
)

, cte_sat_item_attributes__fib_ocf as (
    select
        item_hk
        , inventory_item_id
        , organization_id
        , context_code
        , attribute_char_3
        , attribute_char_5
        , attribute_char_6
        , attribute_char_7
        , attribute_char_8
        , attribute_char_9
        , attribute_char_11
        , attribute_char_14
        , creation_date
        , _fivetran_deleted
        , hash(item_hk, inventory_item_id, organization_id, context_code) as pk
        , load_dts
    from {{ ref('sat_item_attributes__fib_ocf') }} where acd_type = 'PROD'
)

, cte_sat_item_attributes__fib_ocf_latest as (
    {{ generate_cte_satellite_latest('cte_sat_item_attributes__fib_ocf', 'pk') }}
)

, cte_sat_plant__fib_ocf as (
    select
        plant_hk
        , organization_code
        , organization_id
        , _fivetran_deleted
        , load_dts
    from {{ ref('sat_plant__fib_ocf') }}
)

, cte_sat_plant__fib_ocf_latest as (
    {{ generate_cte_satellite_latest('cte_sat_plant__fib_ocf', 'plant_hk') }}
)

, cte_sat_plant__fib_ocf_master_latest as (
    select * from cte_sat_plant__fib_ocf_latest where organization_code = 'MASTER'
)

, cte_ref_sat_item_class__fib_ocf as (
    select
        item_class_id
        , item_class_code
        , _fivetran_deleted
        , load_dts
    from {{ ref('ref_sat_item_class__fib_ocf') }}
)

, cte_ref_sat_item_class__fib_ocf_latest as (
    {{ generate_cte_satellite_latest('cte_ref_sat_item_class__fib_ocf', 'item_class_id') }}
)

, cte_ghost_record as (
    select
        '0' as gr_bk
        , md5_binary('0') as gr_hk
        , convert_timezone('UTC', '1900-01-01'::timestamp) as load_dts
)



, base as (
    select
        sorg.organization_code as bus_unit_id
        , upper(trim(coalesce(sitl_m.description, sitl.description))) as system_base_material
        , sib.inventory_item_id::text as item_id
        , i.item_bk as item_number
        , sitl.description as system_item_title
        , coalesce(sitl_m.description, sitl.description) as item_title
        , sib.item_type as system_item_type_cd
        , null as item_type_description --added for moen item enhancement 2026-01-07
        , null as sales_org
        , null as distribution_channel
        , null as mstat_dc_salesorg
        , null as deactivated_ind
        , sib.inventory_item_status_code as material_sts
        , null as plant_material_sts
        , p.plant_bk
        , i.bkcc
        , i.rec_src
        , null as room_area_id
        , null as item_price_type_group_id
        , null as item_group_id
        , null as item_platform_id
        , iff(
            coalesce(sib_m.inventory_item_status_code, sib.inventory_item_status_code)
            in ('Active', 'PhaseOut'), 'Y', 'N'
        ) as active_item_plant_ind
        , md5_binary(nullif(concat_ws(
            '||'
            , coalesce(nullif(upper(trim(system_base_material::varchar)), ''), '^^')
            , coalesce(nullif(upper(trim((i.bkcc)::varchar)), ''), '^^')
        ), '^^||^^')) as base_material_key
        , row_number() over (partition by base_material_key order by i.rec_src) as base_material_rn
        , active_item_plant_ind as active_item_ind
        , iff(active_item_ind = 'Y', 1, 0) as active_item_value
        , max(active_item_plant_ind) over (partition by base_material_key) as active_item_ind_base_material
        , iff(active_item_ind_base_material = 'Y', 1, 0) as active_item_value_base_material
        , iff(material_sts in ('Active', 'PhaseOut'), 'Y', 'N') as active_base_item_ind
        , iff(active_base_item_ind = 'Y', 1, 0) as active_base_item_value
        , i.item_hk
        , p.plant_hk
        , l.plant_item_hk
        , null::binary(16) as sat_plant_item_hk
        , null as sat_plant_item_load_dts
        , coalesce(sorg.plant_hk, gr.gr_hk) as sat_plant_hk
        , coalesce(sorg.load_dts, gr.load_dts) as sat_plant_load_dts
        , coalesce(sib.item_hk, gr.gr_hk) as sat_item_base_hk
        , coalesce(sib.load_dts, gr.load_dts) as sat_item_base_load_dts
        , coalesce(sitl.item_hk, gr.gr_hk) as sat_item_language_hk
        , coalesce(sitl.load_dts, gr.load_dts) as sat_item_language_load_dts
        , null as item_procurement_type
        , null as item_special_procurement_type
        , null as special_procurement_plant
        , null as item_country_of_origin
        , null as item_hts_code
        , null as item_base_uom
        , null as forecast_base_material  
        , null as ultimate_item_supply_source   
        , null as item_architecture
        , null as item_architecture_detail
        , null as item_finish
        , null as item_price_band   
        , null as pns_price_band   
        , null as item_product_line   
        , null as item_product_segment 
        , null as item_reporting_category   
        , null as item_room_area_detail  
        , null as item_purchasing_group   
        , null as item_processing_time
        , null as item_planned_delivery_time
        , null as item_abc_category   
        , null as critical_part   
        , null as item_mrp_profile
        , null as item_mrp_type   
        , null as item_mrp_controller 
        , null as item_mrp_group  
        , null as item_alt_bom_method 
        , null as item_discontinuation_flag   
        , null as item_production_supervisor  
        , null as item_in_house_production_time   
        , null as item_target_service_level   
        , null as item_takt_time
        , null as item_product_type --added for moen item enhancement 2026-01-07
        , siatr.attribute_char_3 as system_registered_brand
        , siatr_m.attribute_char_3 as registered_brand
        , decode(active_item_ind, 'Y', 1, 'N', 2, 9) as item_type_cd_pref
        , concat(
            decode(active_item_ind, 'Y', '1-', 'N', '2-', '9-')
            , coalesce(sib_m.item_type, sib.item_type)
        ) as item_type_cd_pref_v1
        , coalesce(sib_m.item_type, sib.item_type) as item_type_code
        , split(
            min(item_type_cd_pref_v1)
                over (partition by base_material_key order by item_type_cd_pref_v1 asc, sib_m.creation_date desc)
            , '-'
        )[1]::string as item_type_cd_base_material
        , null as registered_brand_pref
        , first_value(registered_brand)
            over (partition by base_material_key order by registered_brand nulls last)
            as registered_brand_pref_base_material
        , null as base_material_pref
        , system_base_material as base_material
        , null as moen_base_material_flag
        , registered_brand as brand
        , siatr_m.attribute_char_6 as material_type
        , coalesce(ricl.item_class_code, ricl_m.item_class_code) as item_class_code_derv
        , case
            when item_class_code_derv = 'Raw_Materials' then siatr_m.attribute_char_5
        end as whereused_product_category
        , case
            when item_class_code_derv = 'Fasteners' then siatr_m.attribute_char_7
        end as screw_material
        , siatr_m.attribute_char_11 as side_edge_type
        , case
            when item_class_code_derv in (
                    'PVCRailing'
                    , 'ALRailing'
                ) then siatr_m.attribute_char_9
        end as specific_part_type_railing
        , siatr_m.attribute_char_14 as product_line
        , case
            when item_class_code_derv = 'Fasteners' then siatr_m.attribute_char_14
        end as fastner_type
        , case
            when item_class_code_derv = 'Raw_Materials' then siatr_m.attribute_char_8
        end as item_sub_group
        , case
            when item_class_code_derv in (
                    'Decking'
                    , 'PVCRailing'
                    , 'ALRailing'
                    , 'Cladding'
                ) then 'Decking'
            else 'Other Outdoors'
        end as item_category
        , case
            when item_class_code_derv in (
                    'Decking'
                    , 'Cladding'
                ) then 'Deck Boards'
            when item_class_code_derv in (
                    'PVCRailing'
                    , 'ALRailing'
                ) then 'Rails'
            else item_class_code_derv
        end as item_sub_category
        , case
            when item_class_code_derv in (
                    'Decking'
                    , 'PVCRailing'
                    , 'ALRailing'
                    , 'Cladding'
                    , 'Furniture'
                ) then material_type
            when item_class_code_derv = 'Raw_Materials' then whereused_product_category
            when item_class_code_derv = 'Fasteners' then screw_material
        end as item_class
        , case
            when item_class_code_derv in (
                    'Decking'
                    , 'PVCRailing'
                    , 'ALRailing'
                    , 'Cladding'
                    , 'Furniture'
                ) then coalesce(side_edge_type, specific_part_type_railing, product_line)
            when item_class_code_derv = 'Fasteners' then fastner_type
            when item_class_code_derv = 'Raw_Materials' then item_sub_group
        end as item_sub_class
        , first_value(item_category)
            over (partition by base_material_key order by item_category asc nulls last, siatr_m.creation_date desc)
            as item_category_base_material
        , first_value(item_sub_category)
            over (partition by base_material_key order by item_sub_category asc nulls last, siatr_m.creation_date desc)
            as item_sub_category_base_material
        , first_value(item_class)
            over (partition by base_material_key order by item_class asc nulls last, siatr_m.creation_date desc)
            as item_class_base_material
        , first_value(item_sub_class)
            over (partition by base_material_key order by item_sub_class asc nulls last, siatr_m.creation_date desc)
            as item_sub_class_base_material
        , sib.inventory_item_status_code as inventory_item_status_code
		, sib.unit_of_issue as unit_of_issue
		, sib.std_lot_size::TEXT as std_lot_size
		, sib.fixed_order_quantity as fixed_order_quantity
		, sib.over_shipment_tolerance as over_shipment_tolerance
		, sib.under_shipment_tolerance as under_shipment_tolerance
    from {{ ref('link_plant_item_v1') }} as l
        inner join cte_ghost_record as gr on 1 = 1
        inner join {{ ref('hub_plant_v1') }} as p on l.plant_hk = p.plant_hk
        inner join {{ ref('hub_item_v1') }} as i on l.item_hk = i.item_hk and i.bkcc = 'Jumping_River'
        left join cte_sat_plant__fib_ocf_master_latest as sorg_m
            on 1 = 1 and sorg_m._fivetran_deleted = 'false'
        left join cte_sat_plant__fib_ocf_latest as sorg
            on p.plant_hk = sorg.plant_hk and sorg._fivetran_deleted = 'false'
        left join cte_sat_item_base__fib_ocf_latest as sib
            on i.item_hk = sib.item_hk
                and sorg.organization_id = sib.organization_id
                and sib._fivetran_deleted = 'false'
        left join cte_sat_item_base__fib_ocf_latest as sib_m
            on i.item_hk = sib_m.item_hk
                and sorg_m.organization_id = sib_m.organization_id
                and sib_m._fivetran_deleted = 'false'
        left join cte_sat_item_language__fib_ocf_latest as sitl
            on i.item_hk = sitl.item_hk and sorg.organization_id = sitl.organization_id and sitl.language = 'US'
                and sitl._fivetran_deleted = 'false'
        left join cte_sat_item_language__fib_ocf_latest as sitl_m
            on i.item_hk = sitl_m.item_hk and sorg_m.organization_id = sitl_m.organization_id and sitl_m.language = 'US'
                and sitl_m._fivetran_deleted = 'false'
        left join cte_ref_sat_item_class__fib_ocf_latest as ricl
            on sib.item_catalog_group_id = ricl.item_class_id and ricl._fivetran_deleted = 'false'
        left join cte_sat_item_attributes__fib_ocf_latest as siatr
            on i.item_hk = siatr.item_hk
                and sorg.organization_id = siatr.organization_id
                and ricl.item_class_code = siatr.context_code
                and siatr._fivetran_deleted = 'false'
        left join cte_ref_sat_item_class__fib_ocf_latest as ricl_m
            on sib_m.item_catalog_group_id = ricl_m.item_class_id and ricl_m._fivetran_deleted = 'false'
        left join cte_sat_item_attributes__fib_ocf_latest as siatr_m
            on i.item_hk = siatr_m.item_hk
                and sorg_m.organization_id = siatr_m.organization_id
                and ricl_m.item_class_code = siatr_m.context_code
                and siatr_m._fivetran_deleted = 'false'
)

select 
    bus_unit_id
    , system_base_material
    , item_id
    , item_number
    , item_title
    , system_item_type_cd
    , item_type_description --added for moen item enhancement 2026-01-07
    , sales_org
    , distribution_channel
    , mstat_dc_salesorg
    , deactivated_ind
    , material_sts
    , plant_bk
    , bkcc
    , rec_src
    , room_area_id
    , item_price_type_group_id
    , item_group_id
    , item_platform_id
    , active_item_plant_ind
    , base_material_key
    , active_item_ind
    , active_item_value
    , active_item_ind_base_material
    , active_item_value_base_material
    , active_base_item_ind
    , active_base_item_value
    , item_hk
    , plant_hk
    , plant_item_hk
    , sat_plant_item_hk
    , sat_plant_item_load_dts
    , item_procurement_type
    , item_special_procurement_type
    , special_procurement_plant
    , item_country_of_origin
    , item_hts_code
    , item_base_uom
    , forecast_base_material   /*START of fields added for moen item enhancements 2025-10-17*/
    , ultimate_item_supply_source   
    , item_architecture
    , item_architecture_detail
    , item_finish
    , item_price_band   
    , pns_price_band 
    , item_product_line   
    , item_product_segment 
    , item_reporting_category   
    , item_room_area_detail  
    , item_purchasing_group   
    , item_processing_time
    , item_planned_delivery_time
    , item_abc_category   
    , critical_part   
    , item_mrp_profile
    , item_mrp_type   
    , item_mrp_controller 
    , item_mrp_group  
    , item_alt_bom_method 
    , item_discontinuation_flag   
    , item_production_supervisor  
    , item_in_house_production_time   
    , item_target_service_level   
    , item_takt_time  /*END of fields added for moen item enhancements 2025-10-17*/
    --Those column new addition in pb_items_by_plant_moen so that putting null here so it will be comptable in union"
    , CAST(NULL AS VARCHAR) as lead_time_in_days
    , CAST(NULL AS NUMBER)  as safety_stock
    , CAST(NULL AS NUMBER)  as max_stock
    , CAST(NULL AS VARCHAR) as safety_time_indicator
    , CAST(NULL AS NUMBER)  as safety_time_in_days
    , CAST(NULL AS VARCHAR) as stock_determination_group
    , CAST(NULL AS VARCHAR) as coverage_profile
    , CAST(NULL AS NUMBER)  as min_lot_size
    , CAST(NULL AS NUMBER)  as max_lot_size
    , CAST(NULL AS VARCHAR) as rounding_profile
    , CAST(NULL AS VARCHAR) as mrp_type
    , CAST(NULL AS VARCHAR) as abc_category
    , CAST(NULL AS VARCHAR) as COVERAGE_PROFILE_DESCRIPTION
    -- End
    , item_product_type --added for moen item enhancement 2026-01-07
    , registered_brand
    , item_type_cd_pref
    , item_type_cd_pref_v1
    , item_type_code
    , item_type_cd_base_material
    , registered_brand_pref
    , registered_brand_pref_base_material
    , base_material_pref
    , base_material
    , base_material_rn
    , moen_base_material_flag
    , brand
    , item_category
    , item_sub_category
    , item_class
    , item_sub_class
    , item_category_base_material
    , item_sub_category_base_material
    , item_class_base_material
    , item_sub_class_base_material
    /*START of fields added for moen item enhancements 2026-06-01, putting null here so it will be comptable in union*/
    , inventory_item_status_code as 	DELETION_FLAG
    , unit_of_issue as 	UNIT_OF_ISSUE
    , std_lot_size as 	LOT_SIZE_CODE
    , fixed_order_quantity as 	FIXED_LOT_SIZE_QTY
    , NULL as 	LOT_SIZE_SCRAP_QTY
    , NULL as 	SCHEDULING_MARGIN_KEY
    , over_shipment_tolerance as 	OVERDELIVERY_TOLERANCE_PCT
    , under_shipment_tolerance as 	UNDERDELIVERY_TOLERANCE_PCT
    , NULL as 	QUOTA_ARRANGEMENT_USAGE
    , NULL as 	MRP_PLANNING_CALENDAR
    , NULL as 	SOURCE_LIST_REQUIREMENT_IND
    , NULL as	DELIVERY_DATE_KEY
    , NULL as	PLANNING_TIME
    , NULL as	BOM_USAGE
    /*End*/
    /*START of fields added for Thermatru item enhancements 2026-06-17, putting null here so it will be compatible in union*/
    , null as COMMODITY_DESCRIPTION
    , null as STANDARD_PRICE
    , null as MOVING_AVG_PRICE
    /*End*/
from base
