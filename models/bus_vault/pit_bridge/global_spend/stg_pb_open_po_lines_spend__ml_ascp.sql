{{
    config(
        materialized='ephemeral'
    )
}}

with
hub_po_hdr as (
    select * from {{ ref('hub_po_header') }}
    where bkcc = 'Crouching_Dragon'
)

, sat_po_header__ml_ebs as (
    select * from {{ ref('sat_po_header__ml_ebs') }}
    qualify max(load_dts) over (partition by po_header_hk) = load_dts
)

, hub_po_item as (
    select * from {{ ref('hub_po_item') }}
    where bkcc = 'Crouching_Dragon'
)

, hub_item_v1 as (
    select * from {{ ref('hub_item_v1') }}
    where bkcc = 'Crouching_Dragon'
)

, sat_po_item_open_orders__ml_ascp as (
    select * from {{ ref('sat_po_item_open_orders__ml_ascp') }}
    qualify 1 = row_number() over (partition by po_item_hk, transaction_id, creation_date order by load_dts desc)
)

/*  Fetch Latest PLAN Creation Date record */
, sat_po_item_open_orders_latest_date as (
    select * from sat_po_item_open_orders__ml_ascp
    qualify max(creation_date) over (order by creation_date desc) = creation_date
)

, sat_item_base_plan__ml_ascp as (
    select * from {{ ref('sat_item_base_plan__ml_ascp') }} ---
    qualify 1 = row_number() over (partition by item_hk, organization_id order by load_dts desc)
)

, lnk_po_item as (
    select * from {{ ref('lnk_po_item') }}
    /* This filter is necessary to ensure only one record is kept per PO ITEM RECEIPT levelnk_po_item.
       However, the link's granularity is designed to track changes related to Legal Entity, Supplier etc.,*/
    qualify max(load_dts) over (partition by po_item_hk) = load_dts
)

, hub_supplier as (
    select * from {{ ref('hub_supplier_v2') }}
    where bkcc = 'Crouching_Dragon'
)

, sat_supplier__ml_ebs as (
    select * from {{ ref('sat_supplier__ml_ebs') }}
    qualify max(load_dts) over (partition by supplier_hk) = load_dts
)

, sat_po_item__ml_ebs as (
    select * from {{ ref('sat_po_item__ml_ebs') }}
    qualify max(load_dts) over (partition by po_item_hk) = load_dts
)

, ref_ctg_src_tmlc as (
    select * from {{ ref('ref_item_sourcing_category_v2') }}
    where business_unit = 'SECURITY'
)

, ref_ctg_set as (
    select * from {{ ref('ref_item_categories__ml_ebs') }}
    where category_set_name = 'Country of Origin'
)

--
select
    hub_po_item.po_header_id
    , hub_po_item.po_line_number
    , null as po_schedule_line_number
    , sopn.creation_date
    , sopn.order_number
    , sopn.transaction_id::TEXT as transaction_id
    , sopn.po_line_id
    , sopn.new_schedule_date as schedule_line_delivery_date
    , sat_po_item__ml_ebs.quantity as order_qty
    , null as received_qty
    , sat_item_base_plan__ml_ascp.standard_cost
    , sat_item_base_plan__ml_ascp.uom_code as po_item_uom
    , sopn.new_order_quantity as volume
    , sopn.new_order_quantity * sat_item_base_plan__ml_ascp.standard_cost as spend
    , year(schedule_line_delivery_date) as cal_year
    , month(schedule_line_delivery_date) as cal_month
    , coalesce(ref_ctg_src_tmlc.business_unit, 'SECURITY') as business_unit
    , coalesce(ref_ctg_src_tmlc.op_co, 'MASTER LOCK') as drvd_opco
    , concat_ws('|', coalesce(drvd_opco, ''), coalesce(hub_item_v1.item_bk, '')) as opco_item
    , sat_supplier__ml_ebs.segment1 as supplier_number_parent
    , sat_supplier__ml_ebs.vendor_name as supplier_name_parent
    , sat_supplier__ml_ebs.segment1 as supplier_number_child
    , sat_supplier__ml_ebs.vendor_name as supplier_name_child
    , sat_po_item__ml_ebs.item_description
    , ref_ctg_set.category_value1 as country_of_origin
    , sat_po_header__ml_ebs.creation_date::DATE as po_creation_date
    , coalesce(sat_po_header__ml_ebs.cancel_flag, 'N') as po_header_del_ind
    , sat_po_header__ml_ebs.description as payment_terms
    , sat_po_header__ml_ebs.type_lookup_code as document_type
    -----
    , coalesce(ref_ctg_src_tmlc.op_co, 'MASTER LOCK') as opco_category
    , coalesce(ref_ctg_src_tmlc.category_leader_name, 'REVIEW') as category_leader_name
    , coalesce(ref_ctg_src_tmlc.director_name, 'REVIEW') as director_name
    , coalesce(ref_ctg_src_tmlc.fbin_category_i, 'REVIEW') as fbin_category_i
    , coalesce(ref_ctg_src_tmlc.fbin_category_ii, 'REVIEW') as fbin_category_ii
    , coalesce(ref_ctg_src_tmlc.fbin_category_iii, 'REVIEW') as fbin_category_iii
    , hub_item_v1.item_bk
    , sat_item_base_plan__ml_ascp.organization_code as plant_bk
    , sat_po_item__ml_ebs.org_id::TEXT as legal_entity_bk
    , sopn.new_schedule_date as schedule_line_delivery_date_bk
    --HK
    , lnk_po_item.po_header_hk
    , lnk_po_item.po_item_hk
    , lnk_po_item.item_hk
    , lnk_po_item.supplier_hk
    -- , lnk_po_item.plant_hk  -- to be mapped
    , lnk_po_item.legal_entity_hk
    , lnk_po_item.purchasing_record_hk
    , lnk_po_item.purchasing_org_hk
    -- metadata
    , sopn.rec_src
    , hub_po_item.bkcc
    , 'TMLC-Forecast Open Orders' as source

from lnk_po_item
    inner join hub_po_item on lnk_po_item.po_item_hk = hub_po_item.po_item_hk
    inner join hub_po_hdr on lnk_po_item.po_header_hk = hub_po_hdr.po_header_hk
    inner join hub_item_v1 on lnk_po_item.item_hk = hub_item_v1.item_hk
    inner join
        sat_po_item_open_orders_latest_date as sopn
        on hub_po_item.po_item_hk = sopn.po_item_hk and sopn.psa_delete_ind = 'N'
    left join sat_po_header__ml_ebs on hub_po_hdr.po_header_hk = sat_po_header__ml_ebs.po_header_hk
    left join sat_po_item__ml_ebs on hub_po_item.po_item_hk = sat_po_item__ml_ebs.po_item_hk
    left join sat_item_base_plan__ml_ascp
        on lnk_po_item.item_hk = sat_item_base_plan__ml_ascp.item_hk
            and sopn.organization_id = sat_item_base_plan__ml_ascp.organization_id
    left join hub_supplier on lnk_po_item.supplier_hk = hub_supplier.supplier_hk
    left join sat_supplier__ml_ebs on hub_supplier.supplier_hk = sat_supplier__ml_ebs.supplier_hk
    left join ref_ctg_src_tmlc on hub_item_v1.item_bk = ref_ctg_src_tmlc.item
    left join ref_ctg_set on sat_item_base_plan__ml_ascp.sr_inventory_item_id = ref_ctg_set.inventory_item_id

where true
    and coalesce(sat_item_base_plan__ml_ascp.standard_cost, 0) > 0
