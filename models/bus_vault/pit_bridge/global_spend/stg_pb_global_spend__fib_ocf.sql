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
    where bkcc = 'Jumping_River'
    qualify max(load_dts) over (partition by supplier_site_hk) = load_dts
)

, sat_rcpt__fib as (
    select 
        lnk_po_receipt_hk,
        transaction_id,
        transaction_date,
        transaction_quantity,
        transaction_cost,
        currency_code,       
        transaction_type_id,
        inventory_item_id,      
        transaction_uom,
        load_dts,
        bkcc
    from {{ ref('lsat_po_receipt__fib_ocf') }}
    qualify max(load_dts) over (partition by lnk_po_receipt_hk) = load_dts
)

-- The Ref table needs an update to include BUSINESS_UNIT field to make the join efficient
, ref_ctg_src__fib as (
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
    where 1=1 and business_unit = 'OUTDOORS' 
    
)

, hub_po_hdr as (
    select 
        po_header_hk,
        bkcc
    from {{ ref('hub_po_header') }}
    where bkcc = 'Jumping_River'
)
    
, sat_hdr__fib as (
    select 
        po_header_hk,
        segment_1,
        creation_date,
        cancel_flag,
        term_description,
        type_lookup_code,        
        agent_id,
        currency_code,
        bkcc
    from {{ ref('sat_po_header__fib_ocf') }}
    qualify MAX(load_dts) over (partition by po_header_hk) = load_dts
)

, hub_po_item as (
    select 
        po_item_hk,
        bkcc
    from {{ ref('hub_po_item') }}
    where bkcc = 'Jumping_River'
)

, lnk_po_item as (
    select 
        po_item_hk,
        purchasing_record_hk,
        purchasing_org_hk
    from {{ ref('lnk_po_item') }}
    /* This filter is necessary to ensure only one record is kept per PO ITEM RECEIPT level.
    However, the link's granularity is designed to track changes related to Legal Entity, Supplier etc.,*/
    qualify 1 = row_number() over (partition by po_item_hk order by coalesce(metadata$row_last_commit_time, load_dts) desc)
)

, sat_line__fib as (
    select 
        po_item_hk,
        COALESCE(po_header_id::TEXT, '') as po_header_id,
        line_num,        
        quantity,
        unit_price,
        uom_code
    from {{ ref('sat_po_item__fib_ocf') }}
    qualify MAX(load_dts) over (partition by po_item_hk) = load_dts
)

, hub_supplier as (
    select 
        supplier_hk,
        bkcc
    from {{ ref('hub_supplier_v2') }}
    where bkcc = 'Jumping_River'
)

, sat_supplier__fib as (
    select 
        supplier_hk,       
        segment_1 ,      
        bkcc
    from {{ ref('sat_supplier__fib_ocf') }}
    qualify MAX(load_dts) over (partition by supplier_hk) = load_dts
)

, sat_supplier_party__fib as (
    select 
        supplier_hk,       
        party_name,      
        bkcc
    from {{ ref('sat_supplier_party__fib_ocf') }}
    qualify MAX(load_dts) over (partition by supplier_hk) = load_dts
) 

, sat_itm__fib as (
    select 
        item_hk,
        item_number
    from {{ ref('sat_item_base__fib_ocf') }}
    where organization_id = 300000034179011 -- master organization 
    qualify MAX(load_dts) over (partition by item_hk) = load_dts
)

, sat_itm_attr__fib as (
    select 
        item_hk,
        attribute_char_4, -- Country Of Origin
        load_dts
    from {{ ref('sat_item_attributes__fib_ocf') }}
    where organization_id = 300000034179011 -- master organization 
    and  context_code = 'HTC Code'   
)

, sat_itm_attr__fib_latest as (
    select 
        item_hk,
        attribute_char_4 -- Country Of Origin
    from sat_itm_attr__fib
    qualify MAX(load_dts) over (partition by item_hk) = load_dts
)

, sat_satpl__fib as (
        select 
            organization_code, 
            plant_hk 
        from {{ ref('sat_plant__fib_ocf') }}
        qualify 1 = row_number() over (partition by plant_hk order by load_dts desc)
    )

, sat_satlgl__fib as (
        select 
            legal_entity_hk, 
            legal_entity_identifier,
            name
        from {{ ref('sat_legal_entity__fib_ocf') }}
        qualify 1 = row_number() over (partition by legal_entity_hk order by load_dts desc)
    )

select 
--grain
      sat_line__fib.po_header_id::TEXT as po_header_id
    , sat_hdr__fib.segment_1::TEXT as po_number
    , sat_line__fib.line_num::TEXT as po_line_number
    , sat_rcpt__fib.transaction_id 
    , COALESCE(sat_hdr__fib.cancel_flag, 'N') as po_header_del_ind
    , sat_hdr__fib.creation_date::DATE as po_creation_date
    , sat_rcpt__fib.transaction_date::DATE as posting_date
    , YEAR(sat_rcpt__fib.transaction_date) as cal_year
    , MONTH(sat_rcpt__fib.transaction_date) as cal_month
--
    , suplr_c.segment_1 as supplier_number_parent
    , suplr_prty_c.party_name as supplier_name_parent
    , suplr_c.segment_1 as supplier_number_child
    , suplr_prty_c.party_name as supplier_name_child
 --   
    , TRIM(sat_hdr__fib.term_description, '\r\n ') as payment_terms
    , sat_hdr__fib.type_lookup_code as document_type
 --   
    , suplr_c.segment_1::TEXT as supplier_bk
    , sat_itm__fib.item_number::TEXT as item_bk
    , sat_satpl__fib.organization_code as plant_bk
    , sat_satlgl__fib.legal_entity_identifier as legal_entity_bk
    , sat_itm_attr__fib_latest.attribute_char_4 as country_of_origin
    , 'FIBERON' as drvd_opco
    , sat_hdr__fib.agent_id::TEXT as hdr_buyer_code
    , sat_line__fib.quantity as order_qty
    , sat_line__fib.unit_price as order_unit_price    
    , sat_line__fib.unit_price as order_unit_price_usd
    , COALESCE(
        SUM(sat_rcpt__fib.transaction_quantity)
            over (partition by sat_line__fib.po_header_id, sat_line__fib.line_num order by po_creation_date)
        , 0
    ) as total_rcpt_qty
    , COALESCE(
        SUM((sat_rcpt__fib.transaction_quantity * sat_line__fib.unit_price))
            over (partition by sat_line__fib.po_header_id, sat_line__fib.line_num order by po_creation_date)
        , 0
    ) as total_rcpt_spend

    , sat_rcpt__fib.transaction_quantity as receipt_qty
    -- transaction_cost from Receipt (INV_MATERIAL_TXNS) is always NULL
    , (sat_rcpt__fib.transaction_quantity * sat_line__fib.unit_price) as receipt_spend
    , receipt_qty as spend_volume
    , sat_line__fib.uom_code as po_item_uom -- base_uom
    , sat_rcpt__fib.transaction_uom as po_receipt_uom 
    , COALESCE(ref_ctg_src__fib.business_unit, 'OUTDOORS') as business_unit
    , COALESCE(ref_ctg_src__fib.op_co, 'FIBERON') as op_co_
    , CONCAT_WS('|', COALESCE(op_co, 'FIBERON'), COALESCE(sat_itm__fib.item_number::TEXT, '')) as opco_item
    , sat_line__fib.unit_price as po_receipt_price
    , sat_hdr__fib.currency_code as local_currency
	, receipt_spend as SPEND_AMOUNT_LOCAL_CURRENCY
	, receipt_spend as SPEND_USD  
    , sat_rcpt__fib.transaction_type_id::TEXT as po_receipt_type
    , l.po_header_hk
    , l.po_item_hk
    , l.po_item_receipt_dk
    , l.item_hk
    , l.supplier_hk
    , l.plant_hk
    , l.legal_entity_hk
    , sat_rcpt__fib.bkcc
    , l.rec_src
	, lnk_po_item.PURCHASING_RECORD_HK
	, lnk_po_item.PURCHASING_ORG_HK
    , hub_supplier_site.supplier_site_hk
    , hub_supplier_site.supplier_site_bk
    , sat_rcpt__fib.inventory_item_id::TEXT as inventory_item_id
    , COALESCE(ref_ctg_src__fib.op_co, 'FIBERON') as opco_category
    , COALESCE(ref_ctg_src__fib.director_name, 'REVIEW') as director_name
    , COALESCE(ref_ctg_src__fib.category_leader_name, 'REVIEW') as category_leader_name
    , COALESCE(ref_ctg_src__fib.fbin_category_i, 'REVIEW') as fbin_category_i
    , COALESCE(ref_ctg_src__fib.fbin_category_ii, 'REVIEW') as fbin_category_ii
    , COALESCE(ref_ctg_src__fib.fbin_category_iii, 'REVIEW') as fbin_category_iii
from l
    inner join sat_rcpt__fib on l.lnk_po_receipt_hk = sat_rcpt__fib.lnk_po_receipt_hk
    inner join hub_po_item on l.po_item_hk = hub_po_item.po_item_hk
    inner join lnk_po_item on hub_po_item.po_item_hk = lnk_po_item.po_item_hk
    inner join hub_po_hdr on l.po_header_hk = hub_po_hdr.po_header_hk
    left join lpoh on l.po_header_hk = lpoh.po_header_hk
    left join hub_supplier_site on lpoh.supplier_site_hk = hub_supplier_site.supplier_site_hk
    left join sat_hdr__fib on l.po_header_hk = sat_hdr__fib.po_header_hk
    left join sat_line__fib on hub_po_item.po_item_hk = sat_line__fib.po_item_hk
    left join sat_itm__fib on l.item_hk = sat_itm__fib.item_hk
    left join sat_itm_attr__fib_latest on l.item_hk = sat_itm_attr__fib_latest.item_hk
    left join ref_ctg_src__fib on sat_itm__fib.item_number = ref_ctg_src__fib.item and ref_ctg_src__fib.op_co = 'FIBERON'
    left join hub_supplier on l.supplier_hk = hub_supplier.supplier_hk
    left join sat_supplier__fib as suplr_c on hub_supplier.supplier_hk = suplr_c.supplier_hk
    left join sat_supplier_party__fib as suplr_prty_c on hub_supplier.supplier_hk = suplr_prty_c.supplier_hk
    left join sat_satpl__fib on l.plant_hk = sat_satpl__fib.plant_hk
    left join sat_satlgl__fib on l.legal_entity_hk = sat_satlgl__fib.legal_entity_hk
  -- left join ref_ctg_set as ref on sat_rcpt__fib.inventory_item_id = ref.inventory_item_id
where sat_rcpt__fib.transaction_type_id in (71,18,36) 
