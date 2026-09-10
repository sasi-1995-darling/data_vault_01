{{
    config(
        materialized='ephemeral'
    )
}}


with
cte_sat_item_master__moen_sap as (
    select
        item_hk
        , item_id
        , business_unit_id
        , base_material
        , item_type_code
        , room_area_id
        , item_price_type_group_id
        , item_group_id
        , item_platform_id
        , meins
        , zzfcst_base   --added for forecast base material 2025-10-17
        , zzults    --added for ultimate_supply_source 2025-10-17
        , item_architecture_id  --added for architecture 2025-10-17
        , zzarchdet --added for architecture detail 2025-10-17
        , item_finish_id  --added for finish 2025-10-17
        , item_price_category_id  --added for price band 2025-10-17
        , zzlin  --added for product line 2025-10-17
        , zzseg --added for product segment 2025-10-17
        , reporting_category_id --added for reporting category 2025-10-17
        , zzprl --added for product level code for PNS price band derivation 2025-10-17
        , spart --added for product division for PNS price band derivation 2025-10-17
        , item_line_id as zzdtp --added for product type 1-7-2026
        , zzfirstshipdate --added for launch date calculation 2026-06-02
        , zzwhennewdate   --added for launch date calculation 2026-06-02
        , zzstyle         --added for product style 2026-06-02
        , load_dts
    from {{ ref('sat_item_master__moen_sap_v1') }}
)

, cte_sat_item_master__moen_sap_latest as (
    {{ generate_cte_satellite_latest('cte_sat_item_master__moen_sap','item_hk') }}
)

, cte_sat_item_sales_data__moen_sap as (
    select
        item_hk
        , vkorg
        , vtweg
        , vmsta
        , lvorm
        , load_dts
        , hash(item_hk, vkorg, vtweg) as pk
    from {{ ref('sat_item_sales_data__moen_sap_v1') }}
)

, cte_sat_item_sales_data__moen_sap_latest as (
    {{ generate_cte_satellite_latest('cte_sat_item_sales_data__moen_sap','pk') }}
)

, cte_d_chain_code as (
    -- D-chain status per (item, sales_org) rollup (Moen Americas rule, 2026-06-08).
    -- Collapses distribution_channel (vtweg) rows to one row per item_hk + vkorg.
    -- Precedence: S3/S4/S5 > S6 > S0 > S7 > S8 > S2 > S1 > all-SN > all-SW.
    -- Active tie-breaker (rank 1): S3 wins over S4, S4 over S5.
    -- Sales orgs in scope: USFS, CANS, USIT, MXFS, AMCS.
    select
        item_hk
        , vkorg
        , case
            when min(vmsta_rank) = 1 then
                case min(active_subrank) when 1 then 'S3' when 2 then 'S4' when 3 then 'S5' end
            when min(vmsta_rank) = 2 then 'S6'
            when min(vmsta_rank) = 3 then 'S0'
            when min(vmsta_rank) = 4 then 'S7'
            when min(vmsta_rank) = 5 then 'S8'
            when min(vmsta_rank) = 6 then 'S2'
            when min(vmsta_rank) = 7 then 'S1'
            when min(vmsta_rank) = 8 and max(vmsta_rank) = 8 then 'SN'
            when min(vmsta_rank) = 9 and max(vmsta_rank) = 9 then 'SW'
            else null
        end as d_chain_code
    from (
        select
            item_hk
            , vkorg
            , case
                when vmsta in ('S3', 'S4', 'S5') then 1
                when vmsta = 'S6' then 2
                when vmsta = 'S0' then 3
                when vmsta = 'S7' then 4
                when vmsta = 'S8' then 5
                when vmsta = 'S2' then 6
                when vmsta = 'S1' then 7
                when vmsta = 'SN' then 8
                when vmsta = 'SW' then 9
                else 99
            end as vmsta_rank
            , case vmsta when 'S3' then 1 when 'S4' then 2 when 'S5' then 3 else 99 end as active_subrank
        from cte_sat_item_sales_data__moen_sap_latest
        where vkorg in ('USFS', 'CANS', 'USIT', 'MXFS', 'AMCS')
            and vmsta in ('S0', 'S1', 'S2', 'S3', 'S4', 'S5', 'S6', 'S7', 'S8', 'SN', 'SW')
    )
    group by item_hk, vkorg
)

, cte_moen_brand as (
    select
        item_id
        , item_brand
        , load_dts
    from {{ ref('ref_ausp_brand__moen_sap') }}
)

, cte_moen_brand_latest as (
    {{ generate_cte_satellite_latest('cte_moen_brand','item_id') }}
)

, cte_ref_item_room_area__moen_sap as (
    select
        room_area_id
        , room_area
        , load_dts
    from {{ ref('ref_item_room_area__moen_sap') }}
)

, cte_ref_item_room_area__moen_sap_latest as (
    {{ generate_cte_satellite_latest('cte_ref_item_room_area__moen_sap','room_area_id') }}
)

, cte_ref_item_sub_category_moen as (
    select
        item_price_type_group_id
        , price_type_group
        , load_dts
    from {{ ref('ref_item_price_group__moen_sap') }}
    where language = 'E'
)

, cte_ref_item_sub_category_moen_latest as (
    {{ generate_cte_satellite_latest('cte_ref_item_sub_category_moen','item_price_type_group_id') }}
)

, cte_ref_item_class_moen as (
    select
        item_group_id
        , item_group
        , load_dts
    from {{ ref('ref_item_group__moen_sap') }}
    where language = 'E'
)

, cte_ref_item_class_moen_latest as (
    {{ generate_cte_satellite_latest('cte_ref_item_class_moen','item_group_id') }}
)

, cte_ref_item_sub_class_moen as (
    select
        item_platform_id
        , item_platform
        , load_dts
    from {{ ref('ref_item_platform__moen_sap') }}
    where language = 'E'
)

, cte_ref_item_sub_class_moen_latest as (
    {{ generate_cte_satellite_latest('cte_ref_item_sub_class_moen','item_platform_id') }}
)

, cte_ref_special_procurement_type_moen as (
    select
        client
        , language_key
        , plant
        , special_procurement_type_id
        , special_procurement_type_text
        , load_dts
    from {{ ref('ref_special_procurement_type__winn_sap') }}
    where language_key = 'E'
)

, cte_ref_special_procurement_type_moen_latest as (
    {{ generate_cte_satellite_latest('cte_ref_special_procurement_type_moen','client, language_key, plant, special_procurement_type_id ') }}        
)

, cte_ref_special_procurement_plant_moen as (
    select
        client
        , plant
        , special_procurement_type_id
        , procurement_type
        , special_procurement_plant
        , load_dts
    from {{ ref('ref_special_procurement_plant__winn_sap') }}
)

, cte_ref_special_procurement_plant_moen_latest as (
    {{ generate_cte_satellite_latest('cte_ref_special_procurement_plant_moen','client, plant, special_procurement_type_id ') }}        
)

, cte_lsat_plant_item__moen_sap_v1 as (
    select
        plant_item_hk
        , material_status
        , beskz
        , stawn
        , sobsl
        , ekgrp --added for purchasing group 2025-10-17
        , webaz --added for GR processing time 2025-10-17
        , plifz --added for planned delivery time 2025-10-17
        , maabc --added for abc_category 2025-10-17
        , kzkri --added for critical part 2025-10-17
        , dispr --added for MRP profile 2025-10-17
        , dismm --added for mrp type 2025-10-17
        , dispo --added for mrp controller 2025-10-17
        , disgr --added for mrp group 2025-10-17
        , altsl --added for method for alt bom 2025-10-17
        , kzaus --added for discontinuation flag 2025-10-17
        , fevor --added for production supervisor 2025-10-17
        , dzeit --added for in house production time 2025-10-17
        , lgrad --added for target service level 2025-10-17
        , takzt --added for takt time 2025-10-17
        , werks
        , eisbe
        , mabst
        , shflg
        , shzet
        , eprio
        , rwpro
        , bstmi
        , bstma
        , bstrf
        , shpro
        , lvorm
        , ausme
        , disls
        , bstfe
        , losfx
        , fhori
        , ueeto
        , uneto
        , vzusl
        , mpdau
        , kordb
        , zzdeldate
        , zzplanning_time
        , stlan
        , load_dts
    from {{ ref('lsat_plant_item__moen_sap_v1') }}
)

, cte_lsat_plant_item__moen_sap_v1_latest as (
    {{ generate_cte_satellite_latest('cte_lsat_plant_item__moen_sap_v1','plant_item_hk') }}
)

, cte_ref_item_architecture__winn_sap as (   
    select
        architecture_id
        , architecture
        , load_dts
    from {{ ref('ref_item_architecture__winn_sap') }} 
    where language_key = 'E'
)

, cte_ref_item_architecture__winn_sap_latest as (  
    {{ generate_cte_satellite_latest('cte_ref_item_architecture__winn_sap','architecture_id') }} 
)

, cte_ref_coverage_profile_description__winn_sap as (   
    select
          PLANT
        , COVERAGE_PROFILE_CODE
        , COVERAGE_PROFILE_TEXT
        , load_dts
    from {{ ref('ref_coverage_profile_description') }} 
)

, cte_ref_coverage_profile_description__winn_sap_latest as (  
    {{ generate_cte_satellite_latest('cte_ref_coverage_profile_description__winn_sap','plant,coverage_profile_code') }} 
)

, cte_ref_item_architecture_detail__winn_sap as (   
    select
        architecture_detail_id
        , architecture_detail
        , load_dts
    from {{ ref('ref_item_architecture_detail__winn_sap') }}
    where language_key = 'E'
)

, cte_ref_item_architecture_detail__winn_sap_latest as (  
     {{ generate_cte_satellite_latest('cte_ref_item_architecture_detail__winn_sap','architecture_detail_id') }}  
)

, cte_ref_item_finish__winn_sap as (    
    select
        finish_id
        , finish
        , load_dts
    from {{ ref('ref_item_finish__winn_sap') }}
    where language_key = 'E'
)

, cte_ref_item_finish__winn_sap_latest as ( 
     {{ generate_cte_satellite_latest('cte_ref_item_finish__winn_sap','finish_id') }} 
)

, cte_ref_item_price_band__winn_sap as (    
    select
        price_band_id
        , price_band
        , load_dts
    from {{ ref('ref_item_price_band__winn_sap') }}
    where language_key = 'E'
)

, cte_ref_item_price_band__winn_sap_latest as ( 
    {{ generate_cte_satellite_latest('cte_ref_item_price_band__winn_sap','price_band_id') }} 
)

, cte_ref_item_product_line__winn_sap as (  
    select
        product_line_id
        ,product_line
        ,load_dts
    from {{ ref('ref_item_product_line__winn_sap') }} 
    where language_key = 'E'
)

, cte_ref_item_product_line__winn_sap_latest as ( 
     {{ generate_cte_satellite_latest('cte_ref_item_product_line__winn_sap','product_line_id') }}   
)

, cte_ref_item_product_segment__winn_sap as (   
    select
        product_segment_id
        , product_segment
        , load_dts
    from {{ ref('ref_item_product_segment__winn_sap') }} 
    where language_key = 'E'
)

, cte_ref_item_product_segment__winn_sap_latest as (    
    {{ generate_cte_satellite_latest('cte_ref_item_product_segment__winn_sap','product_segment_id') }}
)

, cte_ref_item_reporting_category__winn_sap as (    
    select
        reporting_category_id
        , reporting_category
        , load_dts
    from {{ ref('ref_item_reporting_category__winn_sap') }} 
    where language_key = 'E'
)

, cte_ref_item_reporting_category__winn_sap_latest as ( 
    {{ generate_cte_satellite_latest('cte_ref_item_reporting_category__winn_sap','reporting_category_id') }}
)

, cte_ref_item_room_area_detail__winn_sap as (  
    select
        room_area_id
        , room_area_detail
        , load_dts
    from {{ ref('ref_item_room_area_detail__winn_sap') }} 
    where language_key = 'E'
)

, cte_ref_item_room_area_detail__winn_sap_latest as (
    {{ generate_cte_satellite_latest('cte_ref_item_room_area_detail__winn_sap','room_area_id') }}
)

, cte_ref_item_product_type__winn_sap as (  --added to bring in product type description 2026-01-07
    select
        product_type_id
        , product_type
        , load_dts
    from {{ ref('ref_item_product_type__winn_sap') }} 
    where language_key = 'E'
)

, cte_ref_item_product_type__winn_sap_latest as (  --added to bring in product type description 2026-01-07
   {{ generate_cte_satellite_latest('cte_ref_item_product_type__winn_sap','product_type_id') }}
)

, cte_ref_informatica_mdm_item_category_sat as (    --added to bring in MDM Informatica item data 2026-01-07
    select
        item_bk
        , category
        , subcategory
        , class
        , subclass
        , item_description
        , material_type
        , load_dts
    from {{ref('ref_informatica_mdm_item_category_sat')}}
    where brand = 'MOEN'
)

, cte_ref_informatica_mdm_item_category_sat_latest as ( --added to bring in MDM Informatica item data 2026-01-07
    {{ generate_cte_satellite_latest('cte_ref_informatica_mdm_item_category_sat','item_bk') }}
)

, base_query as (
    select
        m.business_unit_id as bus_unit_id
        , upper(trim(m.base_material)) as system_base_material
        , m.item_id
        , i.item_bk as item_number
        , coalesce(rimics.item_description, rid.material_desc) as item_title    --updated to prioritize MDM informatica item description 2026-01-07
        , m.item_type_code as system_item_type_cd
        , rimics.material_type as item_type_description --added for MDM Informatica item type description 2026-01-07
        , so.vkorg as sales_org
        , so.vtweg as distribution_channel
        , so.vmsta as mstat_dc_salesorg
        , so.lvorm as deactivated_ind
        , sts.material_status as material_sts
        , p.plant_bk
        , i.bkcc
        , i.rec_src
        , m.room_area_id
        , m.item_price_type_group_id
        , m.item_group_id
        , m.item_platform_id
        , case
            when m.business_unit_id in ('WBU', 'AMC', 'CAN', 'USIT', 'MMEX', 'RBU', 'USEC')
                and m.item_type_code = 'FERT'
                and so.vmsta in ('S0', 'S1', 'S2', 'S3', 'S4', 'S5', 'S6')
                and sts.material_status in ('Z1', 'Z2', 'Z3', 'Z4', 'Z5', 'Z6', 'Z7')
                and sales_org in ('USFS', 'CANS', 'USIT', 'MXFS', 'AMCS')
                then 'Y'
            else 'N'
        end as active_item_plant_dc_salesorg_ind
        , max(active_item_plant_dc_salesorg_ind) over (partition by i.item_bk, p.plant_bk) as active_item_plant_ind
        , md5_binary(nullif(concat_ws(
            '||'
            , coalesce(nullif(upper(trim(system_base_material::varchar)), ''), '^^')
            , coalesce(nullif(upper(trim((i.bkcc)::varchar)), ''), '^^')
        ), '^^||^^')) as base_material_key
        , max(active_item_plant_dc_salesorg_ind) over (partition by i.item_bk) as active_item_ind
        , iff(active_item_ind = 'Y', 1, 0) as active_item_value
        , max(active_item_plant_dc_salesorg_ind) over (partition by base_material_key) as active_item_ind_base_material
        , iff(active_item_ind_base_material = 'Y', 1, 0) as active_item_value_base_material
        , case
            when m.business_unit_id in ('WBU', 'AMC', 'CAN', 'USIT', 'MMEX', 'RBU', 'USEC')
                and m.item_type_code = 'FERT'
                and so.vmsta in ('S0', 'S1', 'S2', 'S3', 'S4', 'S5', 'S6')
                and sts.material_status in ('Z1', 'Z2', 'Z3', 'Z4', 'Z5', 'Z6', 'Z7')
                and sales_org in ('USFS', 'CANS', 'USIT', 'MXFS', 'AMCS')
                then 'Y'
            else 'N'
        end as active_base_item_ind
        , iff(active_base_item_ind = 'Y', 1, 0) as active_base_item_value
        , i.item_hk
        , p.plant_hk
        , l.plant_item_hk
        , sts.plant_item_hk as sat_plant_item_hk
        , sts.load_dts as sat_plant_item_load_dts
        , case when sts.beskz = 'E' then 'IN-HOUSE PRODUCTION'
            when sts.beskz = 'F' then 'EXTERNAL PROCUREMENT'
            when sts.beskz = 'X' then 'BOTH PROCUREMENT TYPE'
            when coalesce(sts.beskz, '') = '' then 'NO PROCUREMENT'
        end as item_procurement_type
        , spt.special_procurement_type_text as item_special_procurement_type
        , sptp.special_procurement_plant
        , null as item_country_of_origin
        , sts.stawn as item_hts_code
        , m.meins as item_base_uom
        , m.zzfcst_base as forecast_base_material  /*START of code/logic added for item enhancements 2025-10-17*/
        , m.zzults as ultimate_item_supply_source   
        , ria.architecture as item_architecture
        , riad.architecture_detail as item_architecture_detail
        , rif.finish as item_finish
        , ripb.price_band as item_price_band   
        , case      --PNS Price band logic from WINN BI Team
            when m.zzlin = '816' 
            then 'FLO'
            when m.zzlin <> '816'   
                and m.zzseg not in ('041', '042', '043', '044')
                and m.item_price_category_id not in ( '003', '013', '014', '015', '016', '018', '019', '020', '022', '023', '024')
                and m.spart not in ('AC', 'CF')
                and m.zzprl not in ('002', '004')
            then 'CORE, SPEC, 1ST UPGRADE'
            when m.zzlin <> '816' 
                and m.zzseg not in ('041', '042', '043', '044')
                and m.item_price_category_id not in ('', '001', '002', '004', '005', '006', '007', '008', '009', '010', '011', '012', '013', '014', '015', '016', '017', '018', '019', '020', '021', '022', '023', '024', '025', '026', '027', '028', '029', '030', '031', '032', '033', '034', '035', '036', '037', '038')
                and m.spart not in ('AC', 'CF')
                and m.zzprl not in ('002', '004')
            then '2ND UPGRADE'
            when m.zzlin <> '816' 
                and m.zzseg not in ('041', '042', '043', '044')
                and m.item_price_category_id not in ('013', '014', '015', '016', '018', '019', '020', '022', '023', '024')
                and m.spart not in ('AC', 'CF')
                and m.zzprl not in ('', '001', '003', '005', '006', '007', '008', '009', '010', '071', '092')
            then 'PREMIUM'
            when m.zzlin <> '816' 
                and m.zzseg not in ('041', '042', '043', '044')
                and m.item_price_category_id not in ('013', '014', '015', '016')
                and m.spart not in ('AC', 'FS')
            then 'CFG'
            when m.zzlin <> '816' 
                and m.item_price_category_id not in ('013', '014', '015', '016', '018', '019', '020', '022', '023', '024')
                and m.zzseg = '041'
            then 'COMMERCIAL'
            when m.zzlin <> '816' 
                and m.zzseg not in ('041', '042', '043', '044')
                and m.item_price_category_id not in ('013', '014', '015', '016', '018', '019', '020', '022', '023', '024')
                and m.spart not in ('FS', 'CF')
            then 'ACCESSORIES'
            when m.zzlin <> '816'  
                and m.item_price_category_id not in ('013', '014', '015', '016', '018', '019', '020', '022', '023', '024')
                and m.zzseg IN ('042', '043', '044')
            then 'DISPOSALS'
        end as pns_price_band
        , ripl.product_line as item_product_line   
        , rips.product_segment as item_product_segment 
        , rirc.reporting_category as item_reporting_category   
        , rirad.room_area_detail as item_room_area_detail  
        , sts.ekgrp as item_purchasing_group   
        , sts.webaz as item_processing_time
        , sts.plifz as item_planned_delivery_time
        , sts.maabc as item_abc_category   
        , sts.kzkri as critical_part   
        , sts.dispr as item_mrp_profile
        , sts.dismm as item_mrp_type   
        , sts.dispo as item_mrp_controller 
        , sts.disgr as item_mrp_group  
        , sts.altsl as item_alt_bom_method 
        , sts.kzaus as item_discontinuation_flag   
        , sts.fevor as item_production_supervisor  
        , sts.dzeit as item_in_house_production_time   
        , sts.lgrad as item_target_service_level   
        , sts.takzt as item_takt_time   /*END of code/logic added for item enhancements 2025-10-17*/
        , ript.product_type as item_product_type    --added for moen item enhancement 2026-01-07
        , sts.plifz as lead_time_in_days
        , sts.eisbe as safety_stock
        , sts.mabst as max_stock
        , sts.shflg as safety_time_indicator
        , sts.shzet as safety_time_in_days
        , sts.eprio as stock_determination_group
        , sts.rwpro as coverage_profile
        , sts.bstmi as min_lot_size
        , sts.bstma as max_lot_size
        , sts.bstrf as rounding_profile
        , sts.dismm as mrp_type
        , sts.maabc as abc_category
        , ref_cov.COVERAGE_PROFILE_TEXT as COVERAGE_PROFILE_DESCRIPTION
        , upper(mb.item_brand) as registered_brand
        , registered_brand as brand
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
        ]::string as item_type_code
        , split(min(item_type_cd_pref_v1) over (partition by base_material_key order by item_type_cd_pref_v1), '-')[
            1
        ]::string as item_type_cd_base_material
        , first_value(registered_brand)
            over (partition by i.item_hk order by registered_brand nulls last)
            as registered_brand_pref
        , first_value(registered_brand)
            over (partition by base_material_key order by registered_brand nulls last)
            as registered_brand_pref_base_material
        , null as base_material_pref
        , m.base_material
        , iff(base_material = i.item_bk, 'Y', 'N') as moen_base_material_flag
        , UPPER(TRIM(COALESCE(rimics.category, rirad.room_area_detail, ctg.room_area)))  as item_category  --updated to MDM informatica item category 2026-01-07
        , UPPER(TRIM(COALESCE(rimics.subcategory, scm.price_type_group))) as item_sub_category  --updated to add MDM informatica item sub category 2026-01-07
        , UPPER(TRIM(COALESCE(rimics.class, icm.item_group))) as item_class --updated to add MDM informatica item class 2026-01-07
        , UPPER(TRIM(COALESCE(rimics.subclass, iscm.item_platform))) as item_sub_class --updated to add MDM informatica item sub class 2026-01-07
        , m.zzstyle as item_style --added for product style 2026-06-02
        , try_to_date(nullif(trim(m.zzfirstshipdate), ''), 'YYYYMMDD') as first_ship_date --added 2026-06-04
        , try_to_date(nullif(trim(m.zzwhennewdate), ''), 'YYYYMMDD')   as when_new_date   --added 2026-06-04
        , dc.d_chain_code   --added 2026-06-08 (per-sales-org D-chain status)
        , sts.lvorm as deletion_flag
        , sts.ausme as unit_of_issue
        , sts.disls::TEXT as lot_size_code
        , sts.bstfe as fixed_lot_size_qty
        , sts.losfx as lot_size_scrap_qty
        , sts.fhori as scheduling_margin_key
        , sts.ueeto as overdelivery_tolerance_pct
        , sts.uneto as underdelivery_tolerance_pct
        , sts.vzusl as quota_arrangement_usage
        , sts.mpdau as mrp_planning_calendar
        , sts.kordb as source_list_requirement_ind
        , sts.zzdeldate::INTEGER as delivery_date_key
        , sts.zzplanning_time as planning_time
        , sts.stlan as bom_usage
    from {{ ref('link_plant_item_v1') }} as l
        inner join {{ ref('hub_plant_v1') }} as p on l.plant_hk = p.plant_hk
        inner join {{ ref('hub_item_v1') }} as i on l.item_hk = i.item_hk and i.bkcc = 'Hiding_Tiger'
        left join cte_sat_item_master__moen_sap_latest as m on l.item_hk = m.item_hk
        left join cte_sat_item_sales_data__moen_sap_latest as so on i.item_hk = so.item_hk
        left join cte_d_chain_code as dc on i.item_hk = dc.item_hk and so.vkorg = dc.vkorg
        left join cte_lsat_plant_item__moen_sap_v1_latest as sts on l.plant_item_hk = sts.plant_item_hk
        left join cte_ref_coverage_profile_description__winn_sap_latest as ref_cov on sts.WERKS = ref_cov.plant and sts.rwpro = ref_cov.coverage_profile_code
        left join cte_moen_brand_latest as mb on i.item_bk = mb.item_id
        left join cte_ref_item_room_area__moen_sap_latest as ctg using (room_area_id)
        left join cte_ref_item_sub_category_moen_latest as scm using (item_price_type_group_id)
        left join cte_ref_item_class_moen_latest as icm using (item_group_id)
        left join cte_ref_item_sub_class_moen_latest as iscm using (item_platform_id)
        left join {{ ref('ref_item_description__moen_sap_v1') }} as rid
            on l.item_hk = rid.item_hk and rid.language = 'E'
        left join cte_ref_special_procurement_type_moen_latest as spt
            on sts.sobsl = spt.special_procurement_type_id and p.plant_bk = spt.plant
        left join cte_ref_special_procurement_plant_moen_latest as sptp
            on sts.sobsl = sptp.special_procurement_type_id
                and sts.beskz = sptp.procurement_type
                and p.plant_bk = sptp.plant
        left join cte_ref_item_architecture__winn_sap_latest as ria
            on m.item_architecture_id = ria.architecture_id
        left join cte_ref_item_architecture_detail__winn_sap_latest as riad
            on m.zzarchdet = riad.architecture_detail_id 
        left join cte_ref_item_finish__winn_sap_latest as rif        
            on m.item_finish_id = rif.finish_id
        left join cte_ref_item_price_band__winn_sap_latest as ripb
            on m.item_price_category_id = ripb.price_band_id
        left join cte_ref_item_product_line__winn_sap_latest as ripl   
            on m.zzlin = ripl.product_line_id  
        left join cte_ref_item_product_segment__winn_sap_latest as rips
            on m.zzseg = rips.product_segment_id
        left join cte_ref_item_reporting_category__winn_sap_latest as rirc 
            on m.reporting_category_id = rirc.reporting_category_id
        left join cte_ref_item_room_area_detail__winn_sap_latest as rirad  
            on m.room_area_id = rirad.room_area_id
        left join cte_ref_item_product_type__winn_sap_latest as ript    --added to include moen product type description 2026-01-07
            on m.zzdtp = ript.product_type_id
        left join cte_ref_informatica_mdm_item_category_sat_latest as rimics    --added to include Informatica MDM item hierarchy fields 2026-01-07
            on i.item_bk = rimics.item_bk
)

, null_cat_parent_items as (
    select
        item_hk
        , item_id
        , iff(item_id = split_part(item_id, '-', 0), null, split_part(item_id, '-', 0)) as priority_one_parent_item_id
        , iff(
            item_id = regexp_replace(split_part(item_id, '-', 0), '^T|^WS', '')
            , null
            , regexp_replace(split_part(item_id, '-', 0), '^T|^WS', '')
        )
            as priority_two_parent_item_id
        , nullif(regexp_replace(item_id, '(-[^-]*$|[A-Za-z])', ''), item_id) as priority_three_parent_item_id
        , nullif(split_part(item_title, '-', 0), item_id) as priority_four_parent_item_id
    from base_query
    where (brand is null or brand = 'MOEN' or len(brand) = 0)
        or item_category is null
)

, priority_one_parent_cat as (
    -- 1 row per ncpi.item_id (perf: prevents Cartesian fan-out into t_w_resolved_cat, 2026-06-08)
    select
        ncpi.item_hk
        , ncpi.item_id
        , b.item_category
        , b.item_sub_category
        , b.item_class
        , b.item_sub_class
        , b.brand
    from null_cat_parent_items as ncpi
        inner join base_query as b on ncpi.priority_one_parent_item_id = b.item_id
    qualify row_number() over (partition by ncpi.item_id order by 1) = 1
)

, priority_two_parent_cat as (
    -- 1 row per ncpi.item_id (perf: prevents Cartesian fan-out into t_w_resolved_cat, 2026-06-08)
    select
        ncpi.item_hk
        , ncpi.item_id
        , b.item_category
        , b.item_sub_category
        , b.item_class
        , b.item_sub_class
        , b.brand
    from null_cat_parent_items as ncpi
        inner join base_query as b on ncpi.priority_two_parent_item_id = b.item_id
    qualify row_number() over (partition by ncpi.item_id order by 1) = 1
)

, priority_three_parent_cat as (
    -- 1 row per ncpi.item_id (perf: prevents Cartesian fan-out into t_w_resolved_cat, 2026-06-08)
    select
        ncpi.item_hk
        , ncpi.item_id
        , b.item_category
        , b.item_sub_category
        , b.item_class
        , b.item_sub_class
        , b.brand
    from null_cat_parent_items as ncpi
        inner join base_query as b on ncpi.priority_three_parent_item_id = b.item_id
    qualify row_number() over (partition by ncpi.item_id order by 1) = 1
)

, priority_four_parent_cat as (
    -- 1 row per ncpi.item_id (perf: prevents Cartesian fan-out into t_w_resolved_cat, 2026-06-08)
    select
        ncpi.item_hk
        , ncpi.item_id
        , b.item_category
        , b.item_sub_category
        , b.item_class
        , b.item_sub_class
        , 'MOEN' as brand
    from null_cat_parent_items as ncpi
        inner join base_query as b on ncpi.priority_four_parent_item_id = b.item_id
    qualify row_number() over (partition by ncpi.item_id order by 1) = 1
)

, t_w_resolved_cat as (
    -- 1 row per item_hk; downstream joins on item_hk. (QUALIFY replaces former SELECT DISTINCT, 2026-06-08)
    select
        b.item_hk
        , b.item_id
        , coalesce(p1pc.item_category, p2pc.item_category, p3pc.item_category, p4pc.item_category, b.item_category)
            as item_category
        , coalesce(
            p1pc.item_sub_category
            , p2pc.item_sub_category
            , p3pc.item_sub_category
            , p4pc.item_sub_category
            , b.item_sub_category
        ) as item_sub_category
        , coalesce(p1pc.item_class, p2pc.item_class, p3pc.item_class, p4pc.item_class, b.item_class) as item_class
        , coalesce(
            p1pc.item_sub_class, p2pc.item_sub_class, p3pc.item_sub_class, p4pc.item_sub_class, b.item_sub_class
        ) as item_sub_class
        , coalesce(p1pc.brand, p2pc.brand, b.brand, p3pc.brand, p4pc.brand) as brand
    from base_query as b
        left join priority_one_parent_cat as p1pc on b.item_id = p1pc.item_id
        left join priority_two_parent_cat as p2pc on b.item_id = p2pc.item_id
        left join priority_three_parent_cat as p3pc on b.item_id = p3pc.item_id
        left join priority_four_parent_cat as p4pc on b.item_id = p4pc.item_id
    qualify row_number() over (
        partition by b.item_hk
        order by
            coalesce(p1pc.item_category, p2pc.item_category, p3pc.item_category, p4pc.item_category, b.item_category) nulls last
            , coalesce(p1pc.item_sub_category, p2pc.item_sub_category, p3pc.item_sub_category, p4pc.item_sub_category, b.item_sub_category) nulls last
            , coalesce(p1pc.item_class, p2pc.item_class, p3pc.item_class, p4pc.item_class, b.item_class) nulls last
            , coalesce(p1pc.item_sub_class, p2pc.item_sub_class, p3pc.item_sub_class, p4pc.item_sub_class, b.item_sub_class) nulls last
    ) = 1
)

, bundle_item_categories as (
    -- 1 row per item_bundle_id; downstream joins on item_bundle_id. (QUALIFY replaces former SELECT DISTINCT, 2026-06-08)
    select
        rib.item_bundle_id
        , twrc.item_category
    from {{ ref('ref_item_bundle__moen_sap') }} as rib
        left join t_w_resolved_cat as twrc on rib.item_id = twrc.item_id
    qualify row_number() over (
        partition by rib.item_bundle_id
        order by twrc.item_category nulls last
    ) = 1
)

, bundle_items as (
    select
        twrc.* exclude (brand, item_category, item_sub_category, item_class, item_sub_class)
        , bic.item_category
        , 'MOEN' as brand
        , 'KIT' as item_sub_category
        , 'KIT' as item_class
        , 'KIT' as item_sub_class
    from t_w_resolved_cat as twrc
        left join bundle_item_categories as bic on twrc.item_id = bic.item_bundle_id
    where exists (select 1 from {{ ref('ref_item_bundle__moen_sap') }} where item_bundle_id = twrc.item_id)
)

-- Natural grain: (item_hk, plant_hk, sales_org, distribution_channel) inherited from base_query.
-- After dedup of t_w_resolved_cat and bundle_item_categories above, no fan-out from twrc / bi joins.
-- (Former SELECT DISTINCT removed 2026-06-08 — was defensive only, replaced by upstream QUALIFY.)
select
    b.bus_unit_id
    , b.system_base_material
    , b.item_id
    , b.item_number
    , b.item_title
    , b.system_item_type_cd
    , b.item_type_description   --added for MDM Informatica item type description 2026-01-07
    , b.sales_org
    , b.distribution_channel
    , b.mstat_dc_salesorg
    , b.deactivated_ind
    , b.material_sts
    , b.plant_bk
    , b.bkcc
    , b.rec_src
    , b.room_area_id
    , b.item_price_type_group_id
    , b.item_group_id
    , b.item_platform_id
    , b.active_item_plant_ind
    , b.base_material_key
    , b.active_item_ind
    , b.active_item_value
    , b.active_item_ind_base_material
    , b.active_item_value_base_material
    , b.active_base_item_ind
    , b.active_base_item_value
    , b.item_hk
    , b.plant_hk
    , b.plant_item_hk
    , b.sat_plant_item_hk
    , b.sat_plant_item_load_dts
    , b.item_procurement_type
    , b.item_special_procurement_type
    , b.special_procurement_plant
    , b.item_country_of_origin
    , b.item_hts_code
    , b.item_base_uom
    , b.forecast_base_material   /*START of fields added for item enhancements 2025-10-17*/
    , b.ultimate_item_supply_source   
    , b.item_architecture
    , b.item_architecture_detail
    , b.item_finish
    , b.item_price_band   
    , b.pns_price_band 
    , b.item_product_line   
    , b.item_product_segment 
    , b.item_reporting_category   
    , b.item_room_area_detail  
    , b.item_purchasing_group   
    , b.item_processing_time
    , b.item_planned_delivery_time
    , b.item_abc_category   
    , b.critical_part   
    , b.item_mrp_profile
    , b.item_mrp_type   
    , b.item_mrp_controller 
    , b.item_mrp_group  
    , b.item_alt_bom_method 
    , b.item_discontinuation_flag   
    , b.item_production_supervisor  
    , b.item_in_house_production_time   
    , b.item_target_service_level   
    , b.item_takt_time  /*END of fields added for item enhancements 2025-10-17*/
    , b.lead_time_in_days
    , b.safety_stock
    , b.max_stock
    , b.safety_time_indicator
    , b.safety_time_in_days
    , b.stock_determination_group
    , b.coverage_profile
    , b.min_lot_size
    , b.max_lot_size
    , b.rounding_profile
    , b.mrp_type
    , b.abc_category
    , b.COVERAGE_PROFILE_DESCRIPTION
    , b.item_product_type   --added moen product type description 2026-01-07
    , b.registered_brand
    , b.item_type_cd_pref
    , b.item_type_cd_pref_v1
    , b.item_type_code
    , b.item_type_cd_base_material
    , b.registered_brand_pref
    , b.registered_brand_pref_base_material
    , b.base_material_pref
    , b.base_material
    , 1 as base_material_rn
    , b.moen_base_material_flag
    , coalesce(bi.brand, twrc.brand, b.brand) as brand
    , coalesce(b.item_category, bi.item_category, twrc.item_category) as item_category      --updated order to prioritize informatica MDM item fields 2026-01-07
    , coalesce(b.item_sub_category, bi.item_sub_category, twrc.item_sub_category) as item_sub_category  --updated order to prioritize informatica MDM item fields 2026-01-07
    , coalesce(b.item_class, bi.item_class, twrc.item_class) as item_class  --updated order to prioritize informatica MDM item fields 2026-01-07
    , coalesce(b.item_sub_class, bi.item_sub_class, twrc.item_sub_class) as item_sub_class --updated order to prioritize informatica MDM item fields 2026-01-07
    , coalesce(b.item_category, bi.item_category, twrc.item_category) as item_category_base_material --updated order to prioritize informatica MDM item fields 2026-01-07
    , coalesce(b.item_sub_category, bi.item_sub_category, twrc.item_sub_category) as item_sub_category_base_material --updated order to prioritize informatica MDM item fields 2026-01-07
    , coalesce(b.item_class, bi.item_class, twrc.item_class) as item_class_base_material --updated order to prioritize informatica MDM item fields 2026-01-07
    , coalesce(b.item_sub_class, bi.item_sub_class, twrc.item_sub_class) as item_sub_class_base_material --updated order to prioritize informatica MDM item fields 2026-01-07
    , b.item_style  --added for product style 2026-06-02
    , b.first_ship_date --added 2026-06-04
    , b.when_new_date   --added 2026-06-04
    , b.d_chain_code   --added 2026-06-08 (per-sales-org D-chain status)
    , b.deletion_flag
    , b.unit_of_issue
    , b.lot_size_code
    , b.fixed_lot_size_qty
    , b.lot_size_scrap_qty
    , b.scheduling_margin_key
    , b.overdelivery_tolerance_pct
    , b.underdelivery_tolerance_pct
    , b.quota_arrangement_usage
    , b.mrp_planning_calendar
    , b.source_list_requirement_ind
    , b.delivery_date_key
    , b.planning_time
    , b.bom_usage
    /*START of fields added for Thermatru item enhancements 2026-06-17, putting null here so it will be compatible in union*/
    , null as COMMODITY_DESCRIPTION
    , null as STANDARD_PRICE
    , null as MOVING_AVG_PRICE
    /*End*/
from base_query as b
    left join t_w_resolved_cat as twrc on b.item_hk = twrc.item_hk
    left join bundle_items as bi on b.item_hk = bi.item_hk
