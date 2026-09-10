{{
    config(
        materialized='ephemeral'
    )
}}

with
cte_sat_item_master__tt_e21_v1 as (
    select
        item_hk
        , part_type
        , base_part_flag
        , sellable
        , part_code
        , part_desc
        , part_status
        , part_grp
        , part_subgrp
        , part_subgrp2
        , part_subgrp3
        , _fivetran_deleted
        , load_dts 
    from {{ ref('sat_item_master__tt_e21_v1') }}
)

, cte_sat_item_master__tt_e21_v1_latest as (
    {{ generate_cte_satellite_latest('cte_sat_item_master__tt_e21_v1', 'item_hk') }}
)

, cte_sat_plant__tt_e21 as (
    select
        plant_hk
        , cost_ctr
        , _fivetran_deleted
        , load_dts 
    from {{ ref('sat_plant__tt_e21') }}
)

, cte_sat_plant__tt_e21_latest as (
    {{ generate_cte_satellite_latest('cte_sat_plant__tt_e21', 'plant_hk') }}
)

, cte_lsat_plant_item__tt_e21 as (
    select
        plant_item_hk
        , part_status
        , cost_ctr
        , _fivetran_deleted
        , load_dts 
    from {{ ref('lsat_plant_item__tt_e21') }}
)

, cte_lsat_plant_item__tt_e21_latest as (
    {{ generate_cte_satellite_latest('cte_lsat_plant_item__tt_e21', 'plant_item_hk') }}
)

, cte_lsat_item_attribute__tt_e21 as (
    select
        plant_item_hk
        , item_status
        , uom
        , item_cost
        , load_dts 
    from {{ ref('lsat_item_attribute__tt_e21') }}
)

, cte_lsat_item_attribute__tt_e21_latest as (
    {{ generate_cte_satellite_latest('cte_lsat_item_attribute__tt_e21', 'plant_item_hk') }}
)

, cte_ref_item_group__tt_e21_v1 as (
    select
        part_grp_id
        , part_grp_desc
        , _fivetran_deleted
        , load_dts 
    from {{ ref('ref_item_group__tt_e21_v1') }}
)

, cte_ref_item_group__tt_e21_v1_latest as (
    {{ generate_cte_satellite_latest('cte_ref_item_group__tt_e21_v1','part_grp_id') }}
)

, cte_ref_item_subgroup__tt_e21_v1 as (
    select
        part_subgrp_id
        , part_sgrp_desc
        , _fivetran_deleted
        , load_dts 
    from {{ ref('ref_item_subgroup__tt_e21_v1') }}
)

, cte_ref_item_subgroup__tt_e21_v1_latest as (
    {{ generate_cte_satellite_latest('cte_ref_item_subgroup__tt_e21_v1','part_subgrp_id') }}
)

, cte_ref_item_subgroup_2__tt_e21_v1 as (
    select
        part_subgrp2_id
        , part_sgrp2_desc
        , _fivetran_deleted
        , load_dts 
    from {{ ref('ref_item_subgroup_2__tt_e21_v1') }}
)

, cte_ref_item_subgroup_2__tt_e21_v1_latest as (
    {{ generate_cte_satellite_latest('cte_ref_item_subgroup_2__tt_e21_v1','part_subgrp2_id') }}
)

, cte_ref_item_subgroup_3__tt_e21_v1 as (
    select
        part_subgrp3_id
        , part_sgrp3_desc
        , _fivetran_deleted
        , load_dts 
    from {{ ref('ref_item_subgroup_3__tt_e21_v1') }}
)

, cte_ref_item_subgroup_3__tt_e21_v1_latest as (
    {{ generate_cte_satellite_latest('cte_ref_item_subgroup_3__tt_e21_v1','part_subgrp3_id') }}
)

, cte_sat_item_master__tt_gp as (
    select
        item_hk
        , itemnmbr
        , itemdesc
        , itemtype
        , itmclscd
        , inactive
        , selnguom
        , uomschdl
        , itmgedsc
        , stndcost
        , currcost
        , load_dts 
    from {{ ref('sat_item_master__tt_gp') }}
)

, cte_sat_item_master__tt_gp_latest as (
    {{ generate_cte_satellite_latest('cte_sat_item_master__tt_gp', 'item_hk') }}
)

, cte_sat_plant__tt_gp as (
    select
        plant_hk
        , load_dts 
    from {{ ref('sat_plant__tt_gp') }}
)

, cte_sat_plant__tt_gp_latest as (
    {{ generate_cte_satellite_latest('cte_sat_plant__tt_gp', 'plant_hk') }}
)

, cte_lsat_plant_item__tt_gp as (
    select
        plant_item_hk
        , primvndr
        , locncode 
        , load_dts 
    from {{ ref('lsat_plant_item__tt_gp') }}
)

, cte_lsat_plant_item__tt_gp_latest as (
    {{ generate_cte_satellite_latest('cte_lsat_plant_item__tt_gp', 'plant_item_hk') }}
)

, cte_ref_sat_item_class__tt_gp as (
    select
        item_class_bk
        , item_class_desc
        , load_dts 
    from {{ ref('ref_sat_item_class__tt_gp') }}
)

, cte_ref_sat_item_class__tt_gp_latest as (
    {{ generate_cte_satellite_latest('cte_ref_sat_item_class__tt_gp', 'item_class_bk') }}
)

, cte_base_part_join_tt_e21 as (--derive base part: step 1 extract characters before the first hyphen/dash
    select
        part_type
        , base_part_flag
        , sellable
        , part_code
        --added the item hash key to resolve nulls from joining on item_bk/part_code due to leading/lagging spaces
        , item_hk
        , case
            when part_code is null
                then ''
            else substring(part_code, 1, position('-' in part_code) - 1)
        end as base_part_join
    from cte_sat_item_master__tt_e21_v1_latest
    where _fivetran_deleted = false
)

, cte_base_part_filter_tt_e21 as (-- step 2 isolate only sellable base parts
    select part_code
    from cte_sat_item_master__tt_e21_v1_latest
    where _fivetran_deleted = false
        and sellable = '0'
        and base_part_flag = '1'
)

-- step 3 give me only parts from step 1 that contains hypen after position 2 that are sellable base parts (step 2) 
, cte_base_part_1_tt_e21 as (
    select
        bpj.*
        , case
            when bpj.part_code is null
                then ''
            when position('-' in bpj.part_code) > 2
                then bpf.part_code
        end as base_part_1
    from cte_base_part_join_tt_e21 as bpj
        left join cte_base_part_filter_tt_e21 as bpf
            on bpj.base_part_join = bpf.part_code
)

, cte_ghost_record as (
    select
        '0' as gr_bk
        , md5_binary('0') as gr_hk
        , convert_timezone('UTC', '1900-01-01'::timestamp) as load_dts
)

, base as (
    select
        coalesce(spi.cost_ctr, lspig.locncode) as bus_unit_id
        , upper(coalesce(trim(bp.base_part_1), trim(bp.part_code), nullif((case when mgp.itmclscd in ('P-SLAB', 'P-SLABF') then left(mgp.itemnmbr, charindex('-', mgp.itemnmbr) - 1) end),''), trim(i.item_bk))) as system_base_material --added item_bk from hub_item to resolve nulls for item ids that exist in the plant-item link but not in item mstr
        , coalesce(m.part_code, mgp.itemnmbr, i.item_bk) as item_id --added item_bk from hub_item to resolve nulls for item ids that exist in the plant-item link but not in item mstr
        , i.item_bk as item_number
        , coalesce(m.part_desc, mgp.itemdesc) as item_title
        , coalesce(
            m.part_type
            , decode(
                mgp.itemtype
                , 1
                , 'SALES INVENTORY'
                , 2
                , 'DISCONTINUED'
                , 3
                , 'KIT'
                , 4
                , 'MISC CHARGES'
                , 5
                , 'SERVICES'
                , 6
                , 'FLAT FEE'
            )
        ) as system_item_type_cd
        , null as item_type_description --added for moen item enhancement 2026-01-07
        , null as sales_org
        , null as distribution_channel
        , null as mstat_dc_salesorg
        , null as deactivated_ind
        , coalesce(m.part_status, decode(coalesce(mgp.itmclscd, ''), 'Z-DISC', 'I', '', 'I', 'A')) as material_sts
        , p.plant_bk
        , i.bkcc
        , i.rec_src
        , null as room_area_id
        , null as item_price_type_group_id
        , null as item_group_id
        , null as item_platform_id
        , case
            when spi.part_status = 'A' then 'Y'
            when spi.part_status is null
                and coalesce(mgp.itmclscd, '') not in ('Z-DISC', '')
                and lspig.locncode = 'FTWAYNE'
                then 'Y'
            else 'N'
        end as active_item_plant_ind
        , md5_binary(nullif(concat_ws(
            '||'
            , coalesce(nullif(upper(trim(system_base_material::varchar)), ''), '^^')
            , coalesce(nullif(upper(trim((i.bkcc)::varchar)), ''), '^^')
        ), '^^||^^')) as base_material_key
        , row_number() over (partition by base_material_key order by i.rec_src) as base_material_rn
        , case
            when coalesce(m.part_status, decode(coalesce(mgp.itmclscd, ''), 'Z-DISC', 'I', '', 'I', 'A')) = 'A' then 'Y'
            else 'N'
        end as active_item_ind
        , iff(active_item_ind = 'Y', 1, 0) as active_item_value
        , max(active_item_plant_ind) over (partition by base_material_key) as active_item_ind_base_material
        , iff(active_item_ind_base_material = 'Y', 1, 0) as active_item_value_base_material
        , iff(material_sts = 'A', 'Y', 'N') as active_base_item_ind
        , iff(active_base_item_ind = 'Y', 1, 0) as active_base_item_value
        , i.item_hk
        , p.plant_hk
        , l.plant_item_hk
        , coalesce(spi.plant_item_hk, lspig.plant_item_hk, gr.gr_hk) as sat_plant_item_hk
        , coalesce(spi.load_dts, lspig.load_dts, gr.load_dts) as sat_plant_item_load_dts
        , coalesce(sp.plant_hk, spg.plant_hk, gr.gr_hk) as sat_plant_hk
        , coalesce(sp.load_dts, spg.load_dts, gr.load_dts) as sat_plant_load_dts
        , coalesce(m.item_hk, mgp.item_hk, gr.gr_hk) as sat_item_base_hk
        , coalesce(m.load_dts, mgp.load_dts, gr.load_dts) as sat_item_base_load_dts
        , null as sat_item_language_hk
        , null as sat_item_language_load_dts
        , null as item_procurement_type
        , null as item_special_procurement_type
        , null as special_procurement_plant
        , null as item_country_of_origin
        , mgp.itmclscd as item_hts_code
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
        , case --this assigns first priority to fypon as the registered brand based on cost_ctrs, consolidates logic from multiple ctes in prior version
            when sp.cost_ctr ilike any ('30%', '31%', '32%', '33%') then 'FYPON'
            -- second priority
            when spi.cost_ctr ilike any ('02%', '15%') then 'THERMA-TRU'
            -- Third priority
            when rg.part_grp_desc in ('POLYVINYL CHLORIDE', 'POLYURETHANE') then 'FYPON'
            else 'THERMA-TRU'
        end as drvd_registered_brand

        , case when sp.cost_ctr ilike any ('30%', '31%', '32%', '33%') then '1'
            when spi.cost_ctr ilike any ('02%', '15%') then '2'
            when rg.part_grp_desc in ('POLYVINYL CHLORIDE', 'POLYURETHANE') then '3'
            else '4'
        end as priority_rank
        , case
            when active_item_ind = 'Y'
                then 1
            when active_item_ind = 'N'
                then 2
            else 9
        end as item_type_cd_pref
        , case
            when active_item_ind = 'Y'
                then '1-'
                    || system_item_type_cd
            when active_item_ind = 'N'
                then '2-'
                    || system_item_type_cd
            else '9-'
                || system_item_type_cd
        end as item_type_cd_pref_v1
        , system_item_type_cd as item_type_code
        , first_value(item_type_code)
            over (partition by base_material_key order by length(item_number) nulls last)
            as item_type_cd_base_material
        , null as registered_brand_pref
        , null as base_material_pref
        , system_base_material as base_material
        , null as moen_base_material_flag
        , coalesce(rg.part_grp_desc, rsic.item_class_desc) as item_category
        , rsg.part_sgrp_desc as item_sub_category
        , rsg2.part_sgrp2_desc as item_class
        , rsg3.part_sgrp3_desc as item_sub_class
        , first_value(item_category)
            over (partition by base_material_key order by length(item_number) - length(system_base_material) nulls last)
            as item_category_base_material
        , first_value(item_sub_category)
            over (partition by base_material_key order by length(item_number) - length(system_base_material) nulls last)
            as item_sub_category_base_material
        , first_value(item_class)
            over (partition by base_material_key order by length(item_number) - length(system_base_material) nulls last)
            as item_class_base_material
        , first_value(item_sub_class)
            over (partition by base_material_key order by length(item_number) - length(system_base_material) nulls last)
            as item_sub_class_base_material
        , coalesce(lia.item_status, cast(mgp.inactive as varchar)) as DELETION_STATUS_FLAG
        , coalesce(lia.uom, mgp.selnguom)   as UNIT_OF_ISSUE
        , mgp.uomschdl  as LOT_SIZE_CODE
        , mgp.itmgedsc  as COMMODITY_DESCRIPTION
        , coalesce(lia.item_cost, mgp.stndcost) as STANDARD_PRICE
        , mgp.currcost  as MOVING_AVG_PRICE

    from {{ ref('link_plant_item_v1') }} as l
        inner join cte_ghost_record as gr on 1 = 1
        inner join {{ ref('hub_plant_v1') }} as p on l.plant_hk = p.plant_hk
        inner join {{ ref('hub_item_v1') }} as i on l.item_hk = i.item_hk and i.bkcc = 'Kicking_Panda'
        left join
            cte_sat_item_master__tt_e21_v1_latest as m
            on l.item_hk = m.item_hk
                and m._fivetran_deleted = false
        left join
            cte_sat_plant__tt_e21_latest as sp
            on l.plant_hk = sp.plant_hk
                and sp._fivetran_deleted = false
        left join
            cte_lsat_plant_item__tt_e21_latest as spi
            on l.plant_item_hk = spi.plant_item_hk
                and spi._fivetran_deleted = false
        left join
            cte_ref_item_group__tt_e21_v1_latest as rg
            on (m.part_grp) = rg.part_grp_id
                and rg._fivetran_deleted = false
        left join
            cte_ref_item_subgroup__tt_e21_v1_latest as rsg
            on m.part_subgrp = rsg.part_subgrp_id
                and rsg._fivetran_deleted = false
        left join
            cte_ref_item_subgroup_2__tt_e21_v1_latest as rsg2
            on m.part_subgrp2 = rsg2.part_subgrp2_id
                and rsg2._fivetran_deleted = false
        left join
            cte_ref_item_subgroup_3__tt_e21_v1_latest as rsg3
            on m.part_subgrp3 = rsg3.part_subgrp3_id
                and rsg3._fivetran_deleted = false
        left join 
            cte_lsat_item_attribute__tt_e21_latest as lia
            on l.plant_item_hk = lia.plant_item_hk
        left join
            cte_sat_item_master__tt_gp_latest as mgp
            on l.item_hk = mgp.item_hk
        left join
            cte_sat_plant__tt_gp_latest as spg
            on l.plant_hk = spg.plant_hk
        left join
            cte_lsat_plant_item__tt_gp_latest as lspig
            on l.plant_item_hk = lspig.plant_item_hk
                and coalesce(lspig.primvndr, '') in ('T200', '')
        left join {{ ref('ref_hub_item_class') }} as rhic
            on mgp.itmclscd = rhic.item_class_bk
                and rhic.rec_src = 'USOHMA.MSSQL.GPPRD.DBO_IV40400'
        left join
            cte_ref_sat_item_class__tt_gp_latest as rsic
            on rhic.item_class_bk = rsic.item_class_bk
        left join
            cte_base_part_1_tt_e21 as bp
            on i.item_bk = bp.part_code
)

--assigns the brand at the item_id level based on the lowest priority rank across multiple records for a unique item id
, brand_priority as (
    select
        *
        , first_value(drvd_registered_brand) over (partition by item_id order by priority_rank) as registered_brand
    from base
)

--this assigns ultimate priority to the registered brand associated with the base part code to all variant part codes
, base_material_brand_priority as (
    select distinct
        system_base_material
        , first_value(registered_brand)
            over (partition by base_material_key order by length(item_number) nulls last)
            as registered_brand
    from brand_priority
)

, consolidated_brand as (    --this consolidates the individual part brand and base part brand
    select
        b.* exclude (registered_brand)
        , bm.registered_brand
    from brand_priority as b
        left join base_material_brand_priority as bm
            on b.system_base_material = bm.system_base_material
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
    , registered_brand as registered_brand_pref_base_material
    , base_material_pref
    , base_material
    , base_material_rn
    , moen_base_material_flag
    , registered_brand as brand
    , item_category
    , item_sub_category
    , item_class
    , item_sub_class
    , item_category_base_material
    , item_sub_category_base_material
    , item_class_base_material
    , item_sub_class_base_material
    /*START of fields added for moen item enhancements 2026-06-01, putting null here so it will be comptable in union*/
    , DELETION_STATUS_FLAG as 	DELETION_FLAG
    , UNIT_OF_ISSUE
    , LOT_SIZE_CODE
    , NULL as 	FIXED_LOT_SIZE_QTY
    , NULL as 	LOT_SIZE_SCRAP_QTY
    , NULL as 	SCHEDULING_MARGIN_KEY
    , NULL as 	OVERDELIVERY_TOLERANCE_PCT
    , NULL as 	UNDERDELIVERY_TOLERANCE_PCT
    , NULL as 	QUOTA_ARRANGEMENT_USAGE
    , NULL as 	MRP_PLANNING_CALENDAR
    , NULL as 	SOURCE_LIST_REQUIREMENT_IND
    , NULL as	DELIVERY_DATE_KEY
    , NULL as	PLANNING_TIME
    , NULL as	BOM_USAGE
    /*End*/
    /*START of fields added for Thermatru item enhancements 2026-06-17*/
    , COMMODITY_DESCRIPTION
    , STANDARD_PRICE
    , MOVING_AVG_PRICE
    /*End*/
from consolidated_brand