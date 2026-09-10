{{
    config(
        materialized='ephemeral'
    )
}}

with
l as (
    select 
        po_header_hk,
        lnk_po_receipt_hk,
        po_item_hk,
        po_item_receipt_dk,
        item_hk,
        supplier_hk,
        plant_hk,
        legal_entity_hk,
        rec_src,
        max(load_dts) over (partition by po_item_receipt_dk) as load_dts
    from {{ ref('lnk_po_receipt') }}
    where rec_src <> 'USAZET.SNOWFLAKE.FBIN.DERIVED'   /* This filter is to exclude the ghost records */
    qualify max(load_dts) over (partition by po_item_receipt_dk) = load_dts
)

, lpoh as (
    select 
        LNK_PO_HEADER_SUPPLIER_SITE_HK,
        po_header_hk,
        supplier_site_hk
    from {{ ref('lnk_po_header_supplier_site') }}
    where rec_src <> 'USAZET.SNOWFLAKE.FBIN.DERIVED'   /* This filter is to exclude the ghost records */
    qualify max(load_dts) over (partition by po_header_hk) = load_dts
)

, hub_supplier_site as (
    select 
        supplier_site_hk,
        supplier_site_bk,        
        load_dts
    from {{ ref('hub_supplier_site_v2') }}
    where bkcc = 'Crouching_Dragon'
    qualify max(load_dts) over (partition by supplier_site_hk) = load_dts
)

, sat_rcpt_tmlc as (
    select 
        lnk_po_receipt_hk,
        po_header_id,
        line_num,
        transaction_id,
        transaction_date,
        transaction_quantity,
        transaction_cost,
        transaction_uom,
        currency_code,
        currency_conversion_rate,
        currency_conversion_date,
        currency_conversion_type,
        intercompany_currency_code,
        transaction_type_id,
        organization_id,
        inventory_item_id,
        bkcc,
        load_dts
    from {{ ref('lsat_po_receipt__ml_ebs') }}
    qualify max(load_dts) over (partition by lnk_po_receipt_hk, transaction_type_id) = load_dts
)

-- The Ref table needs an update to include BUSINESS_UNIT field to make the join efficient
, ref_ctg_src_tmlc as (
    select 
        item,
        business_unit,
        op_co,
        director_name,
        category_leader_name,
        fbin_category_i,
        fbin_category_ii,
        fbin_category_iii
    from {{ ref('ref_item_sourcing_category_v2') }}
    where business_unit = 'SECURITY'
)

, hub_po_hdr as (
    select 
        po_header_hk,
        bkcc
    from {{ ref('hub_po_header') }}
    where bkcc = 'Crouching_Dragon'
)

, sat_hdr_tmlc as (
    select 
        po_header_hk,
        segment1,
        cancel_flag,
        creation_date,
        description,
        type_lookup_code,
        agent_id,
        currency_code,
        load_dts
    from {{ ref('sat_po_header__ml_ebs') }}
    qualify max(load_dts) over (partition by po_header_hk) = load_dts
)
, hub_po_item as (
    select 
        po_item_hk,
        bkcc
    from {{ ref('hub_po_item') }}
    where bkcc = 'Crouching_Dragon'
)

, lnk_po_item as (
    select 
        po_item_hk,
        purchasing_record_hk,
        purchasing_org_hk,
        load_dts
    from {{ ref('lnk_po_item') }}
    qualify max(load_dts) over (partition by po_item_hk) = load_dts
)

, sat_line_tmlc as (
    select 
        po_item_hk,
        po_header_id,
        org_id,
        line_num,
        quantity,
        unit_meas_lookup_code,
        unit_price,
        load_dts
    from {{ ref('sat_po_item__ml_ebs') }}
    qualify max(load_dts) over (partition by po_item_hk) = load_dts
)

, hub_supplier as (
    select 
        supplier_hk,
        bkcc
    from {{ ref('hub_supplier_v2') }}
    where bkcc = 'Crouching_Dragon'
)

, sat_supplier_tmlc as (
    select 
        supplier_hk,
        segment1,
        segment1 as sup_segment1,
        vendor_name,
        load_dts
    from {{ ref('sat_supplier__ml_ebs') }}
    qualify max(load_dts) over (partition by supplier_hk) = load_dts
)

, sat_itm_tmlc as (
    select 
        item_hk,
        segment1,
        segment1 as itm_segment1,
        load_dts
    from {{ ref('sat_item_base__ml_ebs_v2') }}
    where organization_id = 1 
    qualify max(load_dts) over (partition by item_hk) = load_dts
)

, ref_ctg_set as (
    select 
        category_set_name,
        category_value1,
        inventory_item_id
    from {{ ref('ref_item_categories__ml_ebs') }}
    where category_set_name = 'Country of Origin'
)

, cte_ref_sat_currency_rates__ml_ebs as (
    select 
        curr_rates_bk,
        from_currency,
        to_currency,
        conversion_type,
        conversion_rate,
        conversion_date,
        load_dts
    from {{ ref('ref_sat_currency_rates__ml_ebs') }}
)

, cte_ref_sat_currency_rates__ml_ebs__latest as (
    select
        *
        , ROW_NUMBER() over (
            partition by curr_rates_bk,conversion_type
            order by load_dts desc
        ) as row_num
    from cte_ref_sat_currency_rates__ml_ebs
    qualify row_num = 1
)

--  TMLC_SPEND_CALC 
select
--grain
    sat_line_tmlc.po_header_id::TEXT as po_header_id
    , sat_hdr_tmlc.segment1::TEXT as po_number
    , sat_line_tmlc.line_num::TEXT as po_line_number
    , sat_rcpt_tmlc.transaction_id
    , COALESCE(sat_hdr_tmlc.cancel_flag, 'N') as po_header_del_ind
    , sat_hdr_tmlc.creation_date::DATE as po_creation_date
    , sat_rcpt_tmlc.transaction_date::DATE as posting_date
    , YEAR(sat_rcpt_tmlc.transaction_date) as cal_year
    , MONTH(sat_rcpt_tmlc.transaction_date) as cal_month

    , suplr_c.segment1 as supplier_number_parent
    , suplr_c.vendor_name as supplier_name_parent
    , suplr_c.segment1 as supplier_number_child
    , suplr_c.vendor_name as supplier_name_child

    , sat_hdr_tmlc.description as payment_terms
    , sat_hdr_tmlc.type_lookup_code as document_type
    , suplr_c.sup_segment1::TEXT as supplier_bk
    , sat_itm_tmlc.itm_segment1::TEXT as item_bk
    , sat_rcpt_tmlc.organization_id::TEXT as plant_bk
    , sat_line_tmlc.org_id::TEXT as legal_entity_bk
    , ref.category_value1 as country_of_origin
    , 'MASTER LOCK' as drvd_opco
    , sat_hdr_tmlc.agent_id::TEXT as hdr_buyer_code
    , sat_line_tmlc.quantity as order_qty
    , sat_line_tmlc.unit_price as order_unit_price    
    , CAST(IFF(
        sat_hdr_tmlc.currency_code = 'USD', order_unit_price, ref_currency_po_ord.conversion_rate * order_unit_price
    ) as NUMBER(32, 4))  as order_unit_price_usd
    , COALESCE(
        SUM(sat_rcpt_tmlc.transaction_quantity)
            over (partition by sat_line_tmlc.po_header_id, sat_line_tmlc.line_num order by po_creation_date)
        , 0
    ) as total_rcpt_qty
    , COALESCE(
        SUM((sat_rcpt_tmlc.transaction_quantity * sat_rcpt_tmlc.transaction_cost))
            over (partition by sat_line_tmlc.po_header_id, sat_line_tmlc.line_num order by po_creation_date)
        , 0
    ) as total_rcpt_spend

    , sat_rcpt_tmlc.transaction_quantity as receipt_qty
    , (sat_rcpt_tmlc.transaction_quantity * sat_rcpt_tmlc.transaction_cost) as receipt_spend
    , receipt_qty as spend_volume
    , sat_line_tmlc.unit_meas_lookup_code as po_item_uom
    , sat_rcpt_tmlc.transaction_uom as po_receipt_uom
    , COALESCE(ref_ctg_src_tmlc.business_unit, 'SECURITY') as business_unit
    , COALESCE(ref_ctg_src_tmlc.op_co, 'MASTER LOCK') as op_co_
    , CONCAT_WS('|', COALESCE(op_co_, ''), COALESCE(sat_itm_tmlc.itm_segment1::TEXT, '')) as opco_item

    , sat_rcpt_tmlc.transaction_cost as po_receipt_price
     , sat_rcpt_tmlc.currency_code as local_currency
    , (sat_rcpt_tmlc.transaction_quantity * sat_rcpt_tmlc.transaction_cost) as spend_amount_local_currency
    , CAST(IFF(
        local_currency = 'USD', spend_amount_local_currency, ref_currency.conversion_rate * spend_amount_local_currency
    ) as NUMBER(32, 4)) as spend_usd
    , round(ref_currency.conversion_rate, 2) as usd_conversion_rate
    , sat_rcpt_tmlc.currency_conversion_rate
    , sat_rcpt_tmlc.currency_conversion_date
    , sat_rcpt_tmlc.currency_conversion_type
    , sat_rcpt_tmlc.intercompany_currency_code
    , sat_rcpt_tmlc.transaction_type_id::TEXT as po_receipt_type

    , l.po_header_hk
    , l.po_item_hk
    , l.po_item_receipt_dk
    , l.item_hk
    , l.supplier_hk
    , l.plant_hk
    , l.legal_entity_hk
    , sat_rcpt_tmlc.bkcc
    , l.rec_src
	, lnk_po_item.PURCHASING_RECORD_HK
	, lnk_po_item.PURCHASING_ORG_HK
    , hub_supplier_site.supplier_site_hk
    , hub_supplier_site.supplier_site_bk
    , sat_rcpt_tmlc.inventory_item_id::TEXT as inventory_item_id
    , COALESCE(ref_ctg_src_tmlc.op_co, 'MASTER LOCK') as opco_category
    , COALESCE(ref_ctg_src_tmlc.director_name, 'REVIEW') as director_name
    , COALESCE(ref_ctg_src_tmlc.category_leader_name, 'REVIEW') as category_leader_name
    , COALESCE(ref_ctg_src_tmlc.fbin_category_i, 'REVIEW') as fbin_category_i
    , COALESCE(ref_ctg_src_tmlc.fbin_category_ii, 'REVIEW') as fbin_category_ii
    , COALESCE(ref_ctg_src_tmlc.fbin_category_iii, 'REVIEW') as fbin_category_iii
from l
    inner join sat_rcpt_tmlc on l.lnk_po_receipt_hk = sat_rcpt_tmlc.lnk_po_receipt_hk
    inner join hub_po_item on l.po_item_hk = hub_po_item.po_item_hk
    inner join lnk_po_item on hub_po_item.po_item_hk = lnk_po_item.po_item_hk
    inner join hub_po_hdr on l.po_header_hk = hub_po_hdr.po_header_hk
    left join lpoh on l.po_header_hk = lpoh.po_header_hk
    left join hub_supplier_site on lpoh.supplier_site_hk = hub_supplier_site.supplier_site_hk
    left join sat_hdr_tmlc on l.po_header_hk = sat_hdr_tmlc.po_header_hk
    left join sat_line_tmlc on hub_po_item.po_item_hk = sat_line_tmlc.po_item_hk
    left join sat_itm_tmlc on l.item_hk = sat_itm_tmlc.item_hk
    left join ref_ctg_src_tmlc on sat_itm_tmlc.itm_segment1 = ref_ctg_src_tmlc.item
    left join hub_supplier on l.supplier_hk = hub_supplier.supplier_hk
    left join sat_supplier_tmlc as suplr_c on hub_supplier.supplier_hk = suplr_c.supplier_hk   
    left join ref_ctg_set as ref on sat_rcpt_tmlc.inventory_item_id = ref.inventory_item_id
    left join cte_ref_sat_currency_rates__ml_ebs__latest as ref_currency on sat_rcpt_tmlc.currency_code = ref_currency.from_currency
                and ref_currency.to_currency = 'USD'
                and ref_currency.conversion_type = 'Spot'
                and sat_rcpt_tmlc.transaction_date::DATE = ref_currency.conversion_date 
    left join cte_ref_sat_currency_rates__ml_ebs__latest as ref_currency_po_ord on sat_hdr_tmlc.currency_code = ref_currency_po_ord.from_currency
                and ref_currency_po_ord.to_currency = 'USD'
                and ref_currency_po_ord.conversion_type = 'Spot'
                and sat_hdr_tmlc.creation_date::DATE = ref_currency_po_ord.conversion_date 
where sat_rcpt_tmlc.transaction_type_id in ('18', '71')
