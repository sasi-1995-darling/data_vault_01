{{
    config(
        materialized='ephemeral'
    )
}}

with cte_sat_item_base__ml_ebs as (
    select
        item_hk
        , inventory_item_id
        , organization_id
        , hash(item_hk, inventory_item_id, organization_id) as pk
        , load_dts
        , case /*identified source system data quality issues causing duplicate base material; expected to be fixed in future; added as a patch to solve until*/
            when inventory_item_id in ('591195', '591197', '593072', '6909710') then description
            when inventory_item_id = '9551275' then 'X041EML'
            else attribute1
        end as attribute1
        , description
        , item_type
        , inventory_item_status_code
        , planning_make_buy_code
        , primary_uom_code
        , _fivetran_deleted
		, unit_of_issue
		, std_lot_size
		, fixed_order_quantity
		, over_shipment_tolerance
		, under_shipment_tolerance
    from {{ ref('sat_item_base__ml_ebs_v2') }}
)

, cte_sat_item_base__ml_ebs_latest as (
    {{ generate_cte_satellite_latest('cte_sat_item_base__ml_ebs','pk') }}
)

, cte_sat_plant__ml_ebs as (
    select
        plant_hk
        , organization_id
        , organization_code
        , load_dts
    from {{ ref('sat_plant__ml_ebs_v1') }}
)

, cte_sat_plant__ml_ebs_latest as (
    {{ generate_cte_satellite_latest('cte_sat_plant__ml_ebs','plant_hk') }}
)

, cte_ref_item_categories__ml_ebs as (
    select
        inventory_item_id
        , category_set_name
        , category_value1
        , load_dts
    from {{ ref('ref_item_categories__ml_ebs') }}
)

, cte_ref_item_category_map as (
    select distinct
        trim(base_material) as base_material
        , category
        , sub_category
        , class
        , sub_class
        , load_dts
    from {{ ref('ref_item_category_map') }}
)

, cte_sat_item_base__ml_ebs_latest_master as (
    select
        item_hk
        , description
        , _fivetran_deleted
    from cte_sat_item_base__ml_ebs_latest
    where organization_id = 1
)

, item_base as (
    select
        org.organization_code as bus_unit_id
        , upper(trim(ml.attribute1)) as system_base_material
        , ml.inventory_item_id::TEXT as item_id
        , i.item_bk as item_number
        , mlm.description as item_title
        , ml.item_type as system_item_type_cd
        , null as item_type_description --added for moen item enhancement 2026-01-07
        , null as sales_org
        , null as distribution_channel
        , null as mstat_dc_salesorg
        , null as deactivated_ind
        , ml.inventory_item_status_code as material_sts
        , p.plant_bk
        , i.bkcc
        , i.rec_src
        , null as room_area_id
        , null as item_price_type_group_id
        , null as item_group_id
        , null as item_platform_id
        , case
            when ml.item_type in ('FG', 'ATO')
                and ml.inventory_item_status_code in ('Active', 'Draw Down', 'Phase-out')
                then 'Y'
            else 'N'
        end as active_item_plant_ind
        , md5_binary(nullif(concat_ws(
            '||'
            , coalesce(nullif(upper(trim(system_base_material::VARCHAR)), ''), '^^')
            , coalesce(nullif(upper(trim((i.bkcc)::VARCHAR)), ''), '^^')
        ), '^^||^^')) as base_material_key
        , row_number() over (partition by base_material_key order by i.rec_src) as base_material_rn
        , max(active_item_plant_ind) over (partition by i.item_bk) as active_item_ind
        , iff(active_item_ind = 'Y', 1, 0) as active_item_value
        , max(active_item_plant_ind) over (partition by base_material_key) as active_item_ind_base_material
        , iff(active_item_ind_base_material = 'Y', 1, 0) as active_item_value_base_material
        , case
            when ml.item_type in ('FG', 'I')
                and ml.inventory_item_status_code in ('Active', 'Draw Down', 'Phase-out')
                then 'Y'
            else 'N'
        end as active_base_item_ind
        , iff(active_base_item_ind = 'Y', 1, 0) as active_base_item_value
        , i.item_hk
        , p.plant_hk
        , l.plant_item_hk
        , null::BINARY(16) as sat_plant_item_hk
        , null as sat_plant_item_load_dts
        , iff(ml.planning_make_buy_code = '2', 'EXTERNAL PROCUREMENT', 'IN-HOUSE PRODUCTION') as item_procurement_type
        , null as item_special_procurement_type
        , null as special_procurement_plant
        , ml_coo.category_value1 as item_country_of_origin
        , ml_hts.category_value1 as item_hts_code
        , ml.primary_uom_code as item_base_uom 
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
        , upper(ml_rb.category_value1) as registered_brand
        , case when system_item_type_cd = 'FG' then 1
            when system_item_type_cd = 'COMP' then 2
            when system_item_type_cd = 'EXP' then 3
            else 9
        end as item_type_cd_pref
        , case when system_item_type_cd = 'FG' then '1-' || system_item_type_cd
            when system_item_type_cd = 'COMP' then '2-' || system_item_type_cd
            when system_item_type_cd = 'EXP' then '3-' || system_item_type_cd
            else '9-' || system_item_type_cd
        end as item_type_cd_pref_v1
        , split(min(item_type_cd_pref_v1) over (partition by i.item_hk order by item_type_cd_pref_v1), '-')[
            1
        ]::STRING as item_type_code
        , split(min(item_type_cd_pref_v1) over (partition by base_material_key order by item_type_cd_pref_v1), '-')[
            1
        ]::STRING as item_type_cd_base_material
        , first_value(registered_brand)
            over (partition by i.item_hk order by registered_brand nulls last)
            as registered_brand_pref
        , first_value(registered_brand)
            over (partition by base_material_key order by registered_brand nulls last)
            as registered_brand_pref_base_material
        , len(system_base_material) || '-' || system_base_material as base_material_pref
        , split(
            first_value(base_material_pref)
                over (partition by i.item_hk order by split(base_material_pref, '-')[1]::STRING)
            , '-'
        )[1]::STRING as base_material
        , null as moen_base_material_flag
        , registered_brand as brand
        , ml.inventory_item_status_code as inventory_item_status_code
		, ml.unit_of_issue as unit_of_issue
		, ml.std_lot_size::TEXT as std_lot_size
		, ml.fixed_order_quantity as fixed_order_quantity
		, ml.over_shipment_tolerance as over_shipment_tolerance
		, ml.under_shipment_tolerance as under_shipment_tolerance
        , ml.attribute1
    from {{ ref('link_plant_item_v1') }} as l
        inner join {{ ref('hub_plant_v1') }} as p on l.plant_hk = p.plant_hk
        inner join {{ ref('hub_item_v1') }} as i on l.item_hk = i.item_hk and i.bkcc = 'Crouching_Dragon'
        left join cte_sat_plant__ml_ebs_latest as org on p.plant_hk = org.plant_hk
        left join cte_sat_item_base__ml_ebs_latest as ml
            on i.item_hk = ml.item_hk and org.organization_id = ml.organization_id
                and ml._fivetran_deleted = false
        left join cte_sat_item_base__ml_ebs_latest_master as mlm
            on i.item_hk = mlm.item_hk and mlm._fivetran_deleted = false
        left join
            cte_ref_item_categories__ml_ebs as ml_rb
            on ml.inventory_item_id = ml_rb.inventory_item_id and ml_rb.category_set_name = 'Registered Brand'
        left join
            cte_ref_item_categories__ml_ebs as ml_coo
            on ml.inventory_item_id = ml_coo.inventory_item_id and ml_coo.category_set_name = 'Country of Origin'
        left join
            cte_ref_item_categories__ml_ebs as ml_hts
            on ml.inventory_item_id = ml_hts.inventory_item_id and ml_hts.category_set_name = 'Harmonization Code - USA'            
)

, base_mat as ( --cte added to resolve duplicate categories via multiple attribute1; join on pref base_material instead
    select
        ib.*
        , ml_ctg.category as item_category
        , ml_ctg.sub_category as item_sub_category
        , ml_ctg.class as item_class
        , ml_ctg.sub_class as item_sub_class
    from item_base as ib
        left join cte_ref_item_category_map as ml_ctg on ib.base_material = ml_ctg.base_material
) 

, base_attr1 as ( --cte added to further resolve via attribute1, items that did not match on pref base_material join 
    select
        bm.* exclude (item_category, item_sub_category, item_class, item_sub_class)
        , ml_ctg.category as item_category
        , ml_ctg.sub_category as item_sub_category
        , ml_ctg.class as item_class
        , ml_ctg.sub_class as item_sub_class
    from base_mat as bm
        left join cte_ref_item_category_map as ml_ctg on bm.attribute1 = ml_ctg.base_material
    where bm.item_category is null
) 

, base as ( --new base combining categories resolved from pref base material join and attribute1 join
    select * exclude (attribute1) from base_mat where item_category is not null
    union all
    select * exclude (attribute1) from base_attr1
)

, null_cat_items as ( 
    select
        b.* exclude (item_category, item_sub_category, item_class, item_sub_class)
        , non_null_cat.item_category
        , non_null_cat.item_sub_category
        , non_null_cat.item_class
        , non_null_cat.item_sub_class
    from base as b
        left join (
            select distinct
                item_id
                , item_category
                , item_sub_category
                , item_class
                , item_sub_class
            from base where item_category is not null
        ) as non_null_cat
            on b.item_id = non_null_cat.item_id
    where b.item_category is null
)

, resolved_null_cat_items as (
    select distinct
        system_base_material
        , item_category
        , item_sub_category
        , item_class
        , item_sub_class
    from base where item_category is not null
    union
    select distinct
        system_base_material
        , item_category
        , item_sub_category
        , item_class
        , item_sub_class
    from null_cat_items where item_category is not null
)

, null_cat_base_materials as (
    select
        b.* exclude (item_category, item_sub_category, item_class, item_sub_class)
        , non_null_cat.item_category
        , non_null_cat.item_sub_category
        , non_null_cat.item_class
        , non_null_cat.item_sub_class
    from null_cat_items as b
        left join (
            select distinct
                system_base_material
                , item_category
                , item_sub_category
                , item_class
                , item_sub_class
            from resolved_null_cat_items where item_category is not null
        ) as non_null_cat
            on b.system_base_material = non_null_cat.system_base_material
    where b.item_category is null
)

, cat_items_all as (
    select * from null_cat_items where item_category is not null
    union all
    select * from null_cat_base_materials
    union all
    select * from base where item_category is not null
)

select
    bus_unit_id
    , system_base_material
    , item_id
    , item_number
    , item_title
    , system_item_type_cd
    , item_type_description --added for moen item enhancement 01-07-2026
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
from cat_items_all
