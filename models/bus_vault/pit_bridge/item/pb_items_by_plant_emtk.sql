{{
    config(
        materialized='ephemeral'
    )
}}

with cte_sat_item_base__emtk_ebs as (
    select
        item_hk
        , inventory_item_id
        , organization_id
        , load_dts
        , attribute1
        , description
        , item_type
        , inventory_item_status_code
        , planning_make_buy_code
        , primary_uom_code
        , creation_date
        , _fivetran_deleted
		, unit_of_issue
		, std_lot_size
        , fixed_order_quantity
        , over_shipment_tolerance
		, under_shipment_tolerance
    from {{ ref('sat_item_base__emtk_ebs_v1') }}
    QUALIFY 1= ROW_NUMBER() OVER(PARTITION BY hash(item_hk, inventory_item_id, organization_id) ORDER BY load_dts DESC)
)

, cte_sat_item_base__emtk_ebs_latest as (
    select
        *
        /*This is to resolve the duplicate issue where two inv items tied with a same Item_hk with different status. 
        We are using inventory_item_status_code status-priority QUALIFY and ranking it*/
        , ROW_NUMBER() over (
            partition by item_hk, organization_id
            order by DECODE(inventory_item_status_code, 'Active', 1, 'PH EMTEK', 2, 'Pilot', 3, 'Expired', 4, 'Inactive', 5, 99) asc, 
                        creation_date desc, inventory_item_id desc
        ) as row_num
    from cte_sat_item_base__emtk_ebs
    qualify row_num = 1
)

, cte_sat_plant__emtk_ebs as (
    select
        plant_hk
        , organization_id
        , organization_code
        , load_dts
    from {{ ref('sat_plant__emtk_ebs') }}
)

, cte_sat_plant__emtk_ebs_latest as (
    select
        *
        , ROW_NUMBER() over (
            partition by plant_hk
            order by load_dts desc
        ) as row_num
    from cte_sat_plant__emtk_ebs
    qualify row_num = 1
)

, cte_sat_item_base__emtk_ebs_latest_master as (
    select
        item_hk
        , description
        , inventory_item_status_code
        , item_type
        , creation_date
        , _fivetran_deleted
    from cte_sat_item_base__emtk_ebs_latest
    where organization_id = 101 -- master organization 
)
, lnk_plant_item__emtk_ebs as (
    select
        plant_item_hk,
        item_hk,
        plant_hk
    from {{ ref('link_plant_item_v1') }}
)

, hub_plant__emtk_ebs as (
    select
        plant_hk,
        plant_bk,
        bkcc,
        rec_src
    from {{ ref('hub_plant_v1') }}
)

, hub_item__emtk_ebs as (
    select
        item_hk,
        item_bk,
        bkcc,
        rec_src
    from {{ ref('hub_item_v1') }}
    where bkcc = 'Diving_Sea'
)

, item_base as (
    select
        org.organization_code as bus_unit_id
        , sitm.attribute1 as system_base_material
        , sitm.inventory_item_id::TEXT as item_id
        , i.item_bk as item_number
        , coalesce(sitm_m.description,sitm.description) as system_item_title        
        , first_value(coalesce(sitm_m.description,sitm.description)) over ( partition by i.item_hk order by 
                decode (sitm_m.inventory_item_status_code, 'Active', 1, 'PH  Emtek', 2, 'Pilot', 3, 'Expired', 4, 'Inactive', 5, 6)
                , sitm_m.creation_date desc ) as item_title
        , sitm.item_type as system_item_type_cd
        , null as item_type_description --added for moen item enhancement 2026-01-07
        , null as sales_org
        , null as distribution_channel
        , null as mstat_dc_salesorg
        , null as deactivated_ind
        , coalesce(sitm_m.inventory_item_status_code,sitm.inventory_item_status_code ) as material_sts
        , p.plant_bk
        , i.bkcc
        , i.rec_src
        , null as room_area_id
        , null as item_price_type_group_id
        , null as item_group_id
        , null as item_platform_id
        , null as active_item_plant_ind
        , null as base_material_key
        , null as base_material_rn
        , null as active_item_ind
        , null as active_item_value
        , null as active_item_ind_base_material
        , null as active_item_value_base_material
        , null as active_base_item_ind
        , null as active_base_item_value
        , i.item_hk
        , p.plant_hk
        , l.plant_item_hk
        , null::BINARY(16) as sat_plant_item_hk
        , null as sat_plant_item_load_dts
        , null as item_procurement_type
        , null as item_special_procurement_type
        , null as special_procurement_plant
        , null as item_country_of_origin
        , null as item_hts_code
        , sitm.primary_uom_code as item_base_uom 
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
        , null as registered_brand
        , null as item_type_cd_pref
        , null as item_type_cd_pref_v1
        , coalesce(sitm_m.item_type, sitm.item_type) as item_type_code
        , null as item_type_cd_base_material
        , null as registered_brand_pref
        , null as registered_brand_pref_base_material
        , null as base_material_pref
        , null as base_material
        , null as moen_base_material_flag
        , null as brand
        , sitm.attribute1
        , null as item_category
        , null as item_sub_category
        , null as item_class
        , null as item_sub_class
        , sitm.inventory_item_status_code as inventory_item_status_code
		, sitm.unit_of_issue as unit_of_issue
		, sitm.std_lot_size::TEXT as std_lot_size
        , sitm.fixed_order_quantity as fixed_order_quantity
        , sitm.over_shipment_tolerance as over_shipment_tolerance
		, sitm.under_shipment_tolerance as under_shipment_tolerance
    from lnk_plant_item__emtk_ebs as l
        inner join hub_plant__emtk_ebs as p on l.plant_hk = p.plant_hk
        inner join hub_item__emtk_ebs as i on l.item_hk = i.item_hk
        left join cte_sat_plant__emtk_ebs_latest as org on p.plant_hk = org.plant_hk
        left join cte_sat_item_base__emtk_ebs_latest as sitm
            on i.item_hk = sitm.item_hk and org.organization_id = sitm.organization_id
                and sitm._fivetran_deleted = false
        left join cte_sat_item_base__emtk_ebs_latest_master as sitm_m
            on i.item_hk = sitm_m.item_hk and sitm_m._fivetran_deleted = false
            
)

/* Final Layer */
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
    , item_category as item_category_base_material
    , item_sub_category as item_sub_category_base_material
    , item_class as item_class_base_material
    , item_sub_class as item_sub_class_base_material
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
from item_base