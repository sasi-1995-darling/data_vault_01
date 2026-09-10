{{
    config(
        materialized='ephemeral'
    )
}}

with lnk_plnd_ordr as (
    select
        planned_order_hk,
        supplier_hk,
        item_hk,
        plant_hk,
        purchasing_org_hk,
        purchasing_record_hk,
        load_dts
    from {{ ref('lnk_planned_order') }}
    where rec_src = 'USWIOC.ORCL.ASCPPRD.MSC_SUPPLIES'
    /* This filter is necessary to ensure only one record is kept per Planned Order level.
     However, the link's granularity is designed to track changes related to Item, Plant, Supplier etc., */
    qualify MAX(load_dts) over (partition by planned_order_hk) = load_dts
)

, hub_pln_ordr as (
    select
        planned_order_hk,
        planned_order_bk,
        rec_src,
        bkcc
    from {{ ref('hub_planned_order') }}
    where bkcc = 'Crouching_Dragon'
)

, sat_pln_ordr as (
    select
        planned_order_hk,
        plan_id,
        inventory_item_id,
        description,
        order_number,
        new_schedule_date,
        new_order_quantity,
        load_dts,
        organization_id,
        order_type,
        creation_date
    from {{ ref('sat_planned_order__ml_ascp') }}
    where plan_id = 1
    qualify MAX(load_dts) over (partition by planned_order_hk) = load_dts
)

/*  Fetch Latest PLAN Creation Date record */
, sat_pln_ordr_latest_date as (
    select * from sat_pln_ordr
    qualify max(creation_date) over (order by creation_date desc) = creation_date
)

, hub_supplier as (
    select
        supplier_hk,
        supplier_bk
    from {{ ref('hub_supplier_v2') }}
    where bkcc = 'Crouching_Dragon'
)

, sat_supplier_tmlc as (
    select
        supplier_hk,
        segment1,
        vendor_name,
        load_dts
    from {{ ref('sat_supplier__ml_ebs') }}
    qualify MAX(load_dts) over (partition by supplier_hk) = load_dts
)

, hub_item as (
    select
        item_hk
    from {{ ref('hub_item_v1') }}
    where bkcc = 'Crouching_Dragon'
)

, sat_item_tmlc as (
    select
        item_hk,
        sr_inventory_item_id,
        sr_inventory_item_id::TEXT as drvd_sr_inv_item_id,
        organization_code,
        organization_id,
        item_name,
        uom_code,
        standard_cost
    from {{ ref('sat_item_base_plan__ml_ascp') }}
    qualify MAX(load_dts) over (partition by ITEM_HK, organization_id) = load_dts
)

, ref_ctg_src_tmlc as (
    select
        item,
        op_co,
        director_name,
        category_leader_name,
        fbin_category_i,
        fbin_category_ii,
        fbin_category_iii
    from {{ ref('ref_item_sourcing_category_v2') }}
    where business_unit = 'SECURITY'
)

, ref_ctg_set as (
    select
        inventory_item_id,
        category_set_name,
        category_value1
    from {{ ref('ref_item_categories__ml_ebs') }}
    where category_set_name = 'Country of Origin'
)

, join_layer as (
select
    hub_pln_ordr.planned_order_bk
    , sat_pln_ordr_latest_date.new_schedule_date as planned_order_finish_date
    , YEAR(sat_pln_ordr_latest_date.new_schedule_date) as cal_year
    , MONTH(sat_pln_ordr_latest_date.new_schedule_date) as cal_month
    , sat_item_tmlc.drvd_sr_inv_item_id
    , sat_item_tmlc.item_name as item_bk
    , sat_pln_ordr_latest_date.inventory_item_id
    , sat_pln_ordr_latest_date.description
    , sat_pln_ordr_latest_date.order_number
    , CONCAT_WS('|', COALESCE(ref_ctg_src_tmlc.op_co, 'MASTER LOCK'), sat_item_tmlc.item_name) as opco_item
    , SPLIT_PART(sat_item_tmlc.organization_code, ':', 2) as plant_bk
    , sat_supplier_tmlc.segment1 as supplier_number_parent
    , sat_supplier_tmlc.vendor_name as supplier_name_parent
    , sat_supplier_tmlc.segment1 as supplier_number_child
    , sat_supplier_tmlc.vendor_name as supplier_name_child
    , sat_item_tmlc.standard_cost as item_standard_cost
    , sat_pln_ordr_latest_date.new_order_quantity as volume
    , volume * sat_item_tmlc.standard_cost as spend
    , sat_item_tmlc.uom_code as uom
    , '' as payment_terms
    , ref.category_value1 as country_of_origin
    , COALESCE(ref_ctg_src_tmlc.op_co, 'MASTER LOCK') as opco_category
    , COALESCE(ref_ctg_src_tmlc.director_name, 'REVIEW') as director_name
    , COALESCE(ref_ctg_src_tmlc.category_leader_name, 'REVIEW') as category_leader_name
    , COALESCE(ref_ctg_src_tmlc.fbin_category_i, 'REVIEW') as fbin_category_i
    , COALESCE(ref_ctg_src_tmlc.fbin_category_ii, 'REVIEW') as fbin_category_ii
    , COALESCE(ref_ctg_src_tmlc.fbin_category_iii, 'REVIEW') as fbin_category_iii
    , TO_CHAR(planned_order_finish_date, 'YYYYMMDD') as planned_order_finish_date_bk
    , lnk_plnd_ordr.planned_order_hk
    , lnk_plnd_ordr.supplier_hk
    , lnk_plnd_ordr.item_hk
    , lnk_plnd_ordr.plant_hk
    , lnk_plnd_ordr.purchasing_org_hk
    , lnk_plnd_ordr.purchasing_record_hk
    , hub_pln_ordr.rec_src
    , hub_pln_ordr.bkcc
    , 'TMLC-Forecast Planned Orders' as source
    , 'SECURITY' as business_unit
from lnk_plnd_ordr
    inner join hub_pln_ordr on lnk_plnd_ordr.planned_order_hk = hub_pln_ordr.planned_order_hk
    inner join sat_pln_ordr_latest_date on hub_pln_ordr.planned_order_hk = sat_pln_ordr_latest_date.planned_order_hk
    left join hub_supplier on lnk_plnd_ordr.supplier_hk = hub_supplier.supplier_hk
    left join sat_supplier_tmlc on hub_supplier.supplier_hk = sat_supplier_tmlc.supplier_hk
    left join hub_item on lnk_plnd_ordr.item_hk = hub_item.item_hk
    left join
        sat_item_tmlc
        on hub_item.item_hk = sat_item_tmlc.item_hk and sat_pln_ordr_latest_date.organization_id = sat_item_tmlc.organization_id
    left join ref_ctg_set as ref on sat_item_tmlc.sr_inventory_item_id = ref.inventory_item_id
    left join ref_ctg_src_tmlc on sat_item_tmlc.item_name = ref_ctg_src_tmlc.item
where sat_pln_ordr_latest_date.order_type = '5'
    and hub_supplier.supplier_bk <> '-2' 
    and sat_item_tmlc.organization_code in ('FOS:NG2', 'FOS:KY', 'FOS:ARZ', 'FOS:HO', 'FOS:NG')
)

--Final Layer
select
	 planned_order_bk
	 ,planned_order_finish_date
	 ,cal_year
	 ,cal_month
	 ,drvd_sr_inv_item_id
	 ,item_bk
	 ,inventory_item_id
	 ,description
	 ,order_number
	 ,opco_item
	 ,plant_bk
	 ,supplier_number_parent
	 ,supplier_name_parent
	 ,supplier_number_child
	 ,supplier_name_child
	 ,item_standard_cost
	 ,volume
	 ,spend
	 ,uom
	 ,payment_terms
	 ,country_of_origin
	 ,opco_category
	 ,director_name
	 ,category_leader_name
	 ,fbin_category_i
	 ,fbin_category_ii
	 ,fbin_category_iii
	 ,planned_order_finish_date_bk
	 ,planned_order_hk
	 ,supplier_hk
	 ,item_hk
	 ,plant_hk
	 ,purchasing_org_hk
	 ,purchasing_record_hk
	 ,rec_src
	 ,bkcc
	 ,source
	 ,business_unit
from join_layer