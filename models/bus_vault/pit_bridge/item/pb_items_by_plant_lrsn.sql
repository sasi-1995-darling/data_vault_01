{{
    config(
        materialized='ephemeral'
    )
}}

with
cte_sat_item_master__lrsn_psft as (
    select
        item_hk
        , setid
        , descr60
        , inv_item_group
        , inv_item_id   --added to call items not found in ps_prod_item
        , itm_status_current    --added to call item status for items not found in ps_prod_item
        , unit_measure_std
        , _fivetran_deleted
        , load_dts
        , hash(item_hk, setid) as pk
    from {{ ref('sat_item_master__lrsn_psft') }}
)

, cte_sat_item_master__lrsn_psft_latest as (
    {{ generate_cte_satellite_latest('cte_sat_item_master__lrsn_psft', 'pk') }}
)

, cte_sat_item_prod__lrsn_psft as (
    select
        item_hk
        , product_id
        , setid
        , eff_status
        , _fivetran_deleted
        , load_dts
    from {{ ref('sat_item_prod__lrsn_psft') }}
    where setid = 'LARSN'
)

, cte_sat_item_prod__lrsn_psft_latest as (
    {{ generate_cte_satellite_latest('cte_sat_item_prod__lrsn_psft', 'item_hk') }}
)

, cte_sat_item_prod_grp__lrsn_psft as (
    select
        item_hk
        , setid
        , l_category
        , l_company
        , l_series
        , l_model
        , l_group
        , _fivetran_deleted
        , load_dts
    from {{ ref('sat_item_prod_grp__lrsn_psft') }}
)

, cte_sat_item_prod_grp__lrsn_psft_latest as (
    {{ generate_cte_satellite_latest('cte_sat_item_prod_grp__lrsn_psft', 'item_hk') }}
)

, cte_lsat_plant_item__lrsn_psft as (
    select
        plant_item_hk
        , itm_status_current
        , business_unit
        , safety_stock
        , order_multiple
        , foq
        , current_cost
        , average_cost
        , bom_usage
        , _fivetran_deleted
        , load_dts
    from {{ ref('lsat_plant_item__lrsn_psft') }}
)

, cte_lsat_plant_item__lrsn_psft_latest as (
    {{ generate_cte_satellite_latest('cte_lsat_plant_item__lrsn_psft', 'plant_item_hk') }}
)

, cte_sat_item_inv__lrsn_psft as (
    select
        item_hk
        , harmonized_cd
        , setid
        , effdt
        , _fivetran_deleted
        , load_dts
    from {{ ref('sat_item_inv__lrsn_psft') }}
    where setid = 'LARSN'
)

, cte_sat_item_inv__lrsn_psft_latest as (
    select *
    from cte_sat_item_inv__lrsn_psft
    qualify 1 = row_number() over (partition by item_hk  order by effdt desc, load_dts desc)
)

, cte_lsat_item_attribute__lrsn_psft as (
    select
        plant_item_hk
        , pur_min_order
        , mfg_min_order
        , pur_order_multiple
        , mfg_order_multiple
        , _fivetran_deleted
        , load_dts
    from {{ ref('lsat_item_attribute__lrsn_psft') }}
)

, cte_lsat_item_attribute__lrsn_psft_latest as (
    {{ generate_cte_satellite_latest('cte_lsat_item_attribute__lrsn_psft', 'plant_item_hk') }}
)

, cte_ref_sat_trans_item__lrsn_psft as (
    select
        fieldname
        , fieldvalue
        , xlatlongname
        , _fivetran_deleted
        , load_dts
        , trans_item_bk
    from {{ ref('ref_sat_trans_item__lrsn_psft') }}
)

, cte_ref_sat_trans_item__lrsn_psft_latest as (
    {{ generate_cte_satellite_latest('cte_ref_sat_trans_item__lrsn_psft','trans_item_bk') }}
)

, cte_ref_sat_prod_grp_lu__lrsn_psft as (
    select
        l_grp_type
        , l_grp_code
        , descr
        , l_descr
        , _fivetran_deleted
        , load_dts
        , prod_grp_bk
    from {{ ref('ref_sat_prod_grp_lu__lrsn_psft') }}
)

, cte_ref_sat_prod_grp_lu__lrsn_psft_latest as (
    {{ generate_cte_satellite_latest('cte_ref_sat_prod_grp_lu__lrsn_psft','prod_grp_bk') }}
)

, cte_ghost_record as (
    select
        '0' as gr_bk
        , md5_binary('0') as gr_hk
        , convert_timezone('UTC', '1900-01-01'::timestamp) as load_dts
)

, base as (
    select
        spl_lr.business_unit as bus_unit_id
        , upper(trim(COALESCE(spi.product_id, smi.inv_item_id))) as system_base_material --added coalesce to call status for items not found in ps_prod_item
        , COALESCE(spi.product_id, smi.inv_item_id) as item_id  --added coalesce to call status for items not found in ps_prod_item
        , i.item_bk as item_number
        , smi.descr60 as item_title
        , smi.inv_item_group as system_item_type_cd
        , null as item_type_description --added for moen item enhancement 2026-01-07
        , null as sales_org
        , null as distribution_channel
        , null as mstat_dc_salesorg
        , null as deactivated_ind
        , UPPER(COALESCE(ref_xlat.xlatlongname, ref_xlat_smi.xlatlongname)) as material_sts    --added coalesce to call status for items not found in ps_prod_item
        , ref_xlat_plsts.xlatlongname as plant_material_sts
        , p.plant_bk
        , i.bkcc
        , i.rec_src
        , null as room_area_id
        , null as item_price_type_group_id
        , null as item_group_id
        , null as item_platform_id
        , case
            when ref_xlat_plsts.xlatlongname = 'ACTIVE'
                then 'Y'
            else 'N'
        end as active_item_plant_ind
        , (md5_binary(nullif(concat_ws(
            '||'
            , coalesce(nullif(upper(trim(system_base_material::varchar)), ''), '^^')
            , coalesce(nullif(upper(trim((i.bkcc)::varchar)), ''), '^^')
        ), '^^||^^'))) as base_material_key
        , iff(UPPER(COALESCE(ref_xlat.xlatlongname, ref_xlat_smi.xlatlongname)) = 'ACTIVE', 'Y', 'N') as active_item_ind    --updated to include status for missing items
        , iff(active_item_ind = 'Y', 1, 0) as active_item_value
        , iff(UPPER(COALESCE(ref_xlat.xlatlongname, ref_xlat_smi.xlatlongname)) = 'ACTIVE', 'Y', 'N') as active_item_ind_base_material  --updated to include status for missing items
        , iff(active_item_ind_base_material = 'Y', 1, 0) as active_item_value_base_material
        , null as active_base_item_ind
        , null as active_base_item_value
        , i.item_hk
        , p.plant_hk
        , l.plant_item_hk
        , coalesce(spl_lr.plant_item_hk, gr.gr_hk) as sat_plant_item_hk
        , coalesce(spl_lr.load_dts, gr.load_dts) as sat_plant_item_load_dts
        , coalesce(spi.item_hk, gr.gr_hk) as sat_item_prod_hk
        , coalesce(spi.load_dts, gr.load_dts) as sat_item_prod_load_dts
        , coalesce(spg.item_hk, gr.gr_hk) as sat_item_prod_grp_hk
        , coalesce(spg.load_dts, gr.load_dts) as sat_item_prod_grp_load_dts
        , coalesce(smi.item_hk, gr.gr_hk) as sat_item_master_hk
        , coalesce(smi.load_dts, gr.load_dts) as sat_item_master_load_dts
        , null as item_procurement_type
        , null as item_special_procurement_type
        , null as special_procurement_plant
        , null as item_country_of_origin
        , sii.harmonized_cd as item_hts_code
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
        , ref_pg_com.descr as registered_brand
        , null as item_type_cd_pref
        , null as item_type_cd_pref_v1
        , case
            when spg.l_category = 'PRODUCT KIT'
                then coalesce(smi.inv_item_group, 'FIN')
            else smi.inv_item_group
        end as item_type_code
        , case
            when spg.l_category = 'PRODUCT KIT'
                then coalesce(smi.inv_item_group, 'FIN')
            else smi.inv_item_group
        end as item_type_cd_base_material
        , null as registered_brand_pref
        , registered_brand as registered_brand_pref_base_material
        , null as base_material_pref
        , system_base_material as base_material
        , null as moen_base_material_flag
        , registered_brand as brand
        , coalesce(decode(ref_pg_grp.l_descr, ' ', ref_pg_grp.descr, ref_pg_grp.l_descr), 'Replacement Parts')
            as item_category
        , coalesce(ref_pg_cat.descr, 'Replacement Parts') as item_sub_category
        , decode(ref_pg_ser.l_descr, ' ', ref_pg_ser.descr, ref_pg_ser.l_descr)
            as item_class
        , decode(ref_pg_mod.l_descr, ' ', ref_pg_mod.descr, ref_pg_mod.l_descr)
            as item_sub_class
        , item_category as item_category_base_material
        , item_sub_category as item_sub_category_base_material
        , item_class as item_class_base_material
        , item_sub_class as item_sub_class_base_material
        , COALESCE(sia.PUR_MIN_ORDER, sia.MFG_MIN_ORDER) as min_lot_size
        , COALESCE(sia.PUR_ORDER_MULTIPLE, sia.MFG_ORDER_MULTIPLE, spl_lr.ORDER_MULTIPLE) as rounding_profile
        , spl_lr.safety_stock as safety_stock
        , spl_lr.itm_status_current as DELETION_FLAG
        , smi.unit_measure_std as UNIT_OF_ISSUE
        , spl_lr.foq as FIXED_LOT_SIZE_QTY
        , spl_lr.current_cost as STANDARD_PRICE
        , spl_lr.average_cost as MOVING_AVG_PRICE
        , spl_lr.bom_usage as BOM_USAGE
    from {{ ref('link_plant_item_v1') }} as l
        inner join cte_ghost_record as gr on 1 = 1
        inner join {{ ref('hub_plant_v1') }} as p on l.plant_hk = p.plant_hk and p.bkcc = 'Swimming_Ocean'    --added to filter to Larson only
        inner join {{ ref('hub_item_v1') }} as i on l.item_hk = i.item_hk
        left join cte_lsat_plant_item__lrsn_psft_latest as spl_lr
            on l.plant_item_hk = spl_lr.plant_item_hk and spl_lr._fivetran_deleted = 'false'
        left join cte_sat_item_prod__lrsn_psft_latest as spi
            on (i.item_hk = spi.item_hk and spi.setid = 'LARSN' and spi._fivetran_deleted = 'false')
        left join cte_sat_item_prod_grp__lrsn_psft_latest as spg
            on (i.item_hk = spg.item_hk and spi.setid = spg.setid and spg._fivetran_deleted = 'false')
        left join cte_sat_item_master__lrsn_psft_latest as smi
            on (i.item_hk = smi.item_hk and smi.setid = 'LARSN' and smi._fivetran_deleted = 'false')    --updated join criteria to bring forward missing item data
        left join cte_sat_item_inv__lrsn_psft_latest as sii
            on (i.item_hk = sii.item_hk and sii._fivetran_deleted = 'false')
        left join cte_lsat_item_attribute__lrsn_psft_latest as sia 
            on l.plant_item_hk = sia.plant_item_hk and sia._fivetran_deleted = 'false'
        left join cte_ref_sat_trans_item__lrsn_psft_latest as ref_xlat
            on ref_xlat.fieldname = 'EFF_STATUS'
                and spi.eff_status = ref_xlat.fieldvalue
                and ref_xlat._fivetran_deleted = 'false'
        left join cte_ref_sat_trans_item__lrsn_psft_latest as ref_xlat_smi      --added to call item status for items not found in ps_prod_item
            on ref_xlat_smi.fieldname = 'ITM_STATUS_CURRENT'
                and smi.itm_status_current = ref_xlat_smi.fieldvalue 
                and ref_xlat_smi._fivetran_deleted = 'false'
        left join cte_ref_sat_trans_item__lrsn_psft_latest as ref_xlat_plsts
            on ref_xlat_plsts.fieldname = 'ITM_STATUS_CURRENT'
                and spl_lr.itm_status_current = ref_xlat_plsts.fieldvalue
                and ref_xlat_plsts._fivetran_deleted = 'false'
        left join cte_ref_sat_prod_grp_lu__lrsn_psft_latest as ref_pg_com
            on (
                ref_pg_com.l_grp_type = 'CO'
                and spg.l_company = ref_pg_com.l_grp_code
                and ref_pg_com._fivetran_deleted = 'false'
            )
        left join cte_ref_sat_prod_grp_lu__lrsn_psft_latest as ref_pg_ser
            on (
                ref_pg_ser.l_grp_type = 'SER'
                and spg.l_series = ref_pg_ser.l_grp_code
                and ref_pg_ser._fivetran_deleted = 'false'
            )
        left join cte_ref_sat_prod_grp_lu__lrsn_psft_latest as ref_pg_mod
            on (
                ref_pg_mod.l_grp_type = 'MOD'
                and spg.l_model = ref_pg_mod.l_grp_code
                and ref_pg_mod._fivetran_deleted = 'false'
            )
        left join cte_ref_sat_prod_grp_lu__lrsn_psft_latest as ref_pg_grp
            on (
                ref_pg_grp.l_grp_type = 'GRP'
                and spg.l_group = ref_pg_grp.l_grp_code
                and ref_pg_grp._fivetran_deleted = 'false'
            )
        left join cte_ref_sat_prod_grp_lu__lrsn_psft_latest as ref_pg_cat
            on (
                ref_pg_cat.l_grp_type = 'CAT'
                and spg.l_category = ref_pg_cat.l_grp_code
                and ref_pg_cat._fivetran_deleted = 'false'
            )
        where nullif(trim(coalesce(spi.product_id, smi.inv_item_id)), '') is not null  --added filter to address data quality issue in ps_master_item_tbl 2026-01-07
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
    , safety_stock
    , CAST(NULL AS NUMBER)  as max_stock
    , CAST(NULL AS VARCHAR) as safety_time_indicator
    , CAST(NULL AS NUMBER)  as safety_time_in_days
    , CAST(NULL AS VARCHAR) as stock_determination_group
    , CAST(NULL AS VARCHAR) as coverage_profile
    , min_lot_size
    , CAST(NULL AS NUMBER)  as max_lot_size
    , rounding_profile
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
    , 1 as base_material_rn
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
    , DELETION_FLAG
    , UNIT_OF_ISSUE
    , 'FOQ' as 	LOT_SIZE_CODE
    , FIXED_LOT_SIZE_QTY
    , NULL as 	LOT_SIZE_SCRAP_QTY
    , NULL as 	SCHEDULING_MARGIN_KEY
    , NULL as 	OVERDELIVERY_TOLERANCE_PCT
    , NULL as 	UNDERDELIVERY_TOLERANCE_PCT
    , NULL as 	QUOTA_ARRANGEMENT_USAGE
    , NULL as 	MRP_PLANNING_CALENDAR
    , NULL as 	SOURCE_LIST_REQUIREMENT_IND
    , NULL as	DELIVERY_DATE_KEY
    , NULL as	PLANNING_TIME
    , BOM_USAGE
    /*End*/
    /*START of fields added for Thermatru item enhancements 2026-06-17, putting null here so it will be compatible in union*/
    , null as COMMODITY_DESCRIPTION
    , STANDARD_PRICE
    , MOVING_AVG_PRICE
    /*End*/
from base
