{{
    config(
        materialized='ephemeral'
    )
}}

with
l as (
    select 
        po_header_hk,
        po_item_hk,
        po_item_receipt_dk,
        item_hk,
        supplier_hk,
        plant_hk,
        legal_entity_hk,
        rec_src,
        lnk_po_receipt_hk
    from {{ ref('lnk_po_receipt') }}
    where rec_src <> 'USAZET.SNOWFLAKE.FBIN.DERIVED'   /* This filter is to exclude the ghost records */
    /* This filter is necessary to ensure only one record is kept per PO ITEM RECEIPT level.
                        However, the link's granularity is designed to track changes related to Legal Entity, Supplier etc.,*/
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
    where bkcc = 'Diving_Sea'
    qualify max(load_dts) over (partition by supplier_site_hk) = load_dts
)

, sat_rcpt_emtk as (
    select 
        po_header_id,
        line_num,
        transaction_id,
        transaction_date,
        transaction_quantity,
        transaction_cost,
        currency_code,
        currency_conversion_rate,
        currency_conversion_date,
        currency_conversion_type,
        intercompany_currency_code,
        transaction_type_id,
        inventory_item_id,
        bkcc,
        lnk_po_receipt_hk,
        transaction_uom,
        load_dts
    from {{ ref('lsat_po_receipt__emtk_ebs') }}
    qualify max(load_dts) over (partition by lnk_po_receipt_hk) = load_dts
)

-- The Ref table needs an update to include BUSINESS_UNIT field to make the join efficient
, ref_ctg_src_emtk as (
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
    where 1=1 and business_unit = 'WINN' 
    AND op_co = 'EMTEK & SCHAUB'
)

, hub_po_hdr as (
    select 
        po_header_hk,
        bkcc
    from {{ ref('hub_po_header') }}
    where bkcc = 'Diving_Sea'
)

, sat_hdr_emtk as (
    select 
        po_header_hk,
        segment1,
        creation_date,
        cancel_flag,
        term_description,
        type_lookup_code,
        agent_id,
        bkcc
    from {{ ref('sat_po_header__emtk_ebs') }}
    qualify MAX(load_dts) over (partition by po_header_hk) = load_dts
)

, hub_po_item as (
    select 
        po_item_hk,
        bkcc
    from {{ ref('hub_po_item') }}
    where bkcc = 'Diving_Sea'
)

, lnk_po_item as (
    select 
        po_item_hk,
        purchasing_record_hk,
        purchasing_org_hk
    from {{ ref('lnk_po_item') }}
    /* This filter is necessary to ensure only one record is kept per PO ITEM RECEIPT level.
                                            However, the link's granularity is designed to track changes related to Legal Entity, Supplier etc.,*/
    qualify MAX(load_dts) over (partition by po_item_hk) = load_dts
)

, sat_line_emtk as (
    select 
        po_item_hk,
        COALESCE(po_header_id::TEXT, '') as po_header_id,
        line_num,
        quantity,
        unit_meas_lookup_code,
        unit_price
    from {{ ref('sat_po_item__emtk_ebs') }}
    qualify MAX(load_dts) over (partition by po_item_hk) = load_dts
)

, hub_supplier as (
    select 
        supplier_hk,
        bkcc
    from {{ ref('hub_supplier_v2') }}
    where bkcc = 'Diving_Sea'
)

, sat_supplier_emtk as (
    select 
        supplier_hk,
        segment1,
        segment1 as sup_segment1,
        vendor_name,
        bkcc
    from {{ ref('sat_supplier__emtk_ebs') }}
    qualify MAX(load_dts) over (partition by supplier_hk) = load_dts
)

, sat_itm_emtk as (
    select 
        item_hk,
        segment1 as itm_segment1,
    from {{ ref('sat_item_base__emtk_ebs_v1') }}
    where organization_id = 101 -- master organization 
    qualify MAX(load_dts) over (partition by item_hk) = load_dts
)

, sat_satpl_emtk as (
        select 
            organization_code, 
            plant_hk 
        from {{ ref('sat_plant__emtk_ebs') }} as src
        qualify 1 = row_number() over (partition by plant_hk order by load_dts desc)
    )

, sat_satlgl_emtk as (
        select 
            legal_entity_hk, 
            name
        from {{ ref('sat_legal_entity__emtk_ebs') }} as src
        qualify 1 = row_number() over (partition by legal_entity_hk order by load_dts desc)
    )

/*** Country of Origin is not avaiolable in emtk category table  */
-- , ref_ctg_set as (
--     select * from datavault_dev.raw_vault.ref_item_categories__emtk_ebs
--     where category_set_name = 'Country of Origin'
-- )

--  EMTK_SPEND_CALC 

select 
--grain
      sat_line_emtk.po_header_id::TEXT as po_header_id
    , sat_hdr_emtk.segment1::TEXT as po_number
    , sat_line_emtk.line_num::TEXT as po_line_number
    , sat_rcpt_emtk.transaction_id 
    , COALESCE(sat_hdr_emtk.cancel_flag, 'N') as po_header_del_ind
    , sat_hdr_emtk.creation_date::DATE as po_creation_date
    , sat_rcpt_emtk.transaction_date::DATE as posting_date
    , YEAR(sat_rcpt_emtk.transaction_date) as cal_year
    , MONTH(sat_rcpt_emtk.transaction_date) as cal_month
--
    , suplr_c.segment1 as supplier_number_parent
    , suplr_c.vendor_name as supplier_name_parent
    , suplr_c.segment1 as supplier_number_child
    , suplr_c.vendor_name as supplier_name_child
 --   
    , sat_hdr_emtk.term_description as payment_terms
    , sat_hdr_emtk.type_lookup_code as document_type
 --   
    , suplr_c.sup_segment1::TEXT as supplier_bk
    , sat_itm_emtk.itm_segment1::TEXT as item_bk
    , sat_satpl_emtk.organization_code as plant_bk
    , sat_satlgl_emtk.name as legal_entity_bk
    , NULL as country_of_origin
    , 'EMTEK & SCHAUB' as drvd_opco
    , sat_hdr_emtk.agent_id::TEXT as hdr_buyer_code
    , sat_line_emtk.quantity as order_qty
    , sat_line_emtk.unit_price as order_unit_price    
    , sat_line_emtk.unit_price as order_unit_price_usd
    , COALESCE(
        SUM(sat_rcpt_emtk.transaction_quantity)
            over (partition by sat_line_emtk.po_header_id, sat_line_emtk.line_num order by po_creation_date)
        , 0
    ) as total_rcpt_qty
    , COALESCE(
        SUM((sat_rcpt_emtk.transaction_quantity * sat_rcpt_emtk.transaction_cost))
            over (partition by sat_line_emtk.po_header_id, sat_line_emtk.line_num order by po_creation_date)
        , 0
    ) as total_rcpt_spend

    , sat_rcpt_emtk.transaction_quantity as receipt_qty
    , (sat_rcpt_emtk.transaction_quantity * sat_rcpt_emtk.transaction_cost) as receipt_spend
    , receipt_qty as spend_volume
    , sat_line_emtk.unit_meas_lookup_code as po_item_uom
    , sat_rcpt_emtk.transaction_uom as po_receipt_uom
    , COALESCE(ref_ctg_src_emtk.business_unit, 'WINN') as business_unit
    , COALESCE(ref_ctg_src_emtk.op_co, 'EMTEK & SCHAUB') as op_co_
    , CONCAT_WS('|', COALESCE(op_co, 'EMTEK & SCHAUB'), COALESCE(sat_itm_emtk.itm_segment1::TEXT, '')) as opco_item
    , sat_rcpt_emtk.transaction_cost as po_receipt_price
    , sat_rcpt_emtk.currency_code as local_currency
	, CASE WHEN local_currency = 'USD' THEN receipt_spend
            ELSE NULL 
      END as SPEND_AMOUNT_LOCAL_CURRENCY
	, CASE WHEN local_currency = 'USD' THEN SPEND_AMOUNT_LOCAL_CURRENCY
            ELSE NULL 
      END as SPEND_USD
    , sat_rcpt_emtk.currency_conversion_rate
    , sat_rcpt_emtk.currency_conversion_date
    , sat_rcpt_emtk.currency_conversion_type
    , sat_rcpt_emtk.intercompany_currency_code
    , sat_rcpt_emtk.transaction_type_id::TEXT as po_receipt_type
    , l.po_header_hk
    , l.po_item_hk
    , l.po_item_receipt_dk
    , l.item_hk
    , l.supplier_hk
    , l.plant_hk
    , l.legal_entity_hk
    , sat_rcpt_emtk.bkcc
    , l.rec_src
	, lnk_po_item.PURCHASING_RECORD_HK
	, lnk_po_item.PURCHASING_ORG_HK
    , hub_supplier_site.supplier_site_hk
    , hub_supplier_site.supplier_site_bk
    , sat_rcpt_emtk.inventory_item_id::TEXT as inventory_item_id
    , COALESCE(ref_ctg_src_emtk.op_co, 'EMTEK & SCHAUB') as opco_category
    , COALESCE(ref_ctg_src_emtk.director_name, 'REVIEW') as director_name
    , COALESCE(ref_ctg_src_emtk.category_leader_name, 'REVIEW') as category_leader_name
    , COALESCE(ref_ctg_src_emtk.fbin_category_i, 'REVIEW') as fbin_category_i
    , COALESCE(ref_ctg_src_emtk.fbin_category_ii, 'REVIEW') as fbin_category_ii
    , COALESCE(ref_ctg_src_emtk.fbin_category_iii, 'REVIEW') as fbin_category_iii
from l
    inner join sat_rcpt_emtk on l.lnk_po_receipt_hk = sat_rcpt_emtk.lnk_po_receipt_hk
    inner join hub_po_item on l.po_item_hk = hub_po_item.po_item_hk
    inner join lnk_po_item on hub_po_item.po_item_hk = lnk_po_item.po_item_hk
    inner join hub_po_hdr on l.po_header_hk = hub_po_hdr.po_header_hk
    left join lpoh on l.po_header_hk = lpoh.po_header_hk
    left join hub_supplier_site on lpoh.supplier_site_hk = hub_supplier_site.supplier_site_hk
    left join sat_hdr_emtk on l.po_header_hk = sat_hdr_emtk.po_header_hk
    left join sat_line_emtk on hub_po_item.po_item_hk = sat_line_emtk.po_item_hk
    left join sat_itm_emtk on l.item_hk = sat_itm_emtk.item_hk
    left join ref_ctg_src_emtk on sat_itm_emtk.itm_segment1 = ref_ctg_src_emtk.item
    left join hub_supplier on l.supplier_hk = hub_supplier.supplier_hk
    left join sat_supplier_emtk as suplr_c on hub_supplier.supplier_hk = suplr_c.supplier_hk
    left join sat_satpl_emtk on l.plant_hk = sat_satpl_emtk.plant_hk
    left join sat_satlgl_emtk on l.legal_entity_hk = sat_satlgl_emtk.legal_entity_hk
  -- left join ref_ctg_set as ref on sat_rcpt_emtk.inventory_item_id = ref.inventory_item_id
where sat_rcpt_emtk.transaction_type_id in ('18', '71')
