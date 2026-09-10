{{
    config(
        materialized='ephemeral'
    )
}}


with
l as (
    select 
        po_item_receipt_dk,
        lnk_po_receipt_hk,
        po_header_hk,
        po_item_hk,
        item_hk,
        supplier_hk,
        plant_hk,
        legal_entity_hk,
        rec_src,
        load_dts
    from {{ ref('lnk_po_receipt') }}
    where rec_src = 'USOHMA.ORCL.E21PRD.POITEM'   /* This filter is to exclude the ghost records */
    /* This filter is necessary to ensure only one record is kept per PO ITEM RECEIPT level.
                        However, the link's granularity is designed to track changes related to Legal Entity, Supplier etc.,*/
    qualify MAX(load_dts) over (partition by po_item_receipt_dk) = load_dts
)

, sat_rcpt_tt_e21_ltst as (
    select 
        po_number,
		rel_numb, 
		item_no,
		part_code,
		vend_code,
		part_type,
		date_rcv,
		qty_ord, 
		qty_recvd, 
		uom, 
		rcv_uom,
		uom_conv,
		rcv_conv,
        xcur_uom,
		xcur_conv,
		unit_price, 
		item_status,
		cost_ctr,
        SO_NUMBER,
        INV_EXT_COST,
        bkcc,
        lnk_po_receipt_hk,
        load_dts
    from {{ ref('lsat_po_receipt__tt_e21') }}
    qualify max(load_dts) over (partition by lnk_po_receipt_hk) = load_dts
)

, sat_rcpt_tt_e21 as (
    select *
    from sat_rcpt_tt_e21_ltst
	where part_type not in ('N','P')	 -- Filter Non-Stock and Capital Item and Keep only Stock Item 
	 and date_rcv is not null and qty_recvd>0  -- filter only receipts 
)

-- The Ref table needs an update to include BUSINESS_UNIT field to make the join efficient
, ref_ctg_src_tt_e21 as (
    select item,
        business_unit,
        op_co,
        director_name,
        category_leader_name,
        fbin_category_i,
        fbin_category_ii,
        fbin_category_iii
    from {{ ref('ref_item_sourcing_category_v2') }}
    where business_unit = 'OUTDOORS' 
	and OP_CO = 'THERMA-TRU'
)

, hub_po_hdr as (
    select 
        PO_HEADER_HK
    from {{ ref('hub_po_header') }}
    where bkcc = 'Kicking_Panda'
)

, sat_hdr_tt_e21 as (
    select 
        po_header_hk,
		po_number ,
		rel_numb  ,
		terms_code,
		po_type   ,
		vend_code ,
		buyer_id ,
		billto_code,
		date_entered,	
        PO_STATUS,
        bkcc      ,
        load_dts
    from {{ ref('msat_po_header__tt_e21') }}
    qualify MAX(load_dts) over (partition by po_header_hk,rel_numb) = load_dts
)

, hub_supplier as (
    select 
        supplier_hk,
        supplier_bk
    from {{ ref('hub_supplier_v2') }}
    where bkcc = 'Kicking_Panda'
)

, sat_supplier_tt_e21 as (
    select 
        supplier_hk,
        vend_code,
        vend_name,
        load_dts
    from {{ ref('sat_supplier__tt_e21')}}
    qualify MAX(load_dts) over (partition by supplier_hk) = load_dts
)


, lnk_supplier_item as (
    select 
        lnk_supplier_item_hk,
        item_hk,
        supplier_hk,
        load_dts
    from {{ ref('lnk_supplier_item') }}
    qualify MAX(load_dts) over (partition by lnk_supplier_item_hk) = load_dts
)

, lsat_supplier_item AS (
   SELECT 
       lnk_supplier_item_hk,
       origin_country,
       load_dts
   FROM {{ ref('lsat_supplier_item__tt_e21')}}
   qualify MAX(load_dts) over (partition by lnk_supplier_item_hk) = load_dts
)
, lnk_supplier_item_plant as (
    select 
        lnk_supplier_item_plant_hk,
        item_hk,
        supplier_hk,
		plant_hk,
        load_dts
    from {{ ref('lnk_supplier_item_plant') }}
    qualify MAX(load_dts) over (partition by lnk_supplier_item_plant_hk) = load_dts
)

, lsat_supplier_item_plant AS (
   SELECT 
       lnk_supplier_item_plant_hk,
       origin_country,
       load_dts
   FROM {{ ref('lsat_supplier_item_plant__tt_e21') }}
   qualify MAX(load_dts) over (partition by lnk_supplier_item_plant_hk) = load_dts
)

--  TTE21 Spend Calc 
select
--grain
      sat_rcpt_tt_e21.po_number as po_header_id 
    , sat_rcpt_tt_e21.item_no::TEXT as po_line_number 
    , NULL as material_document_number
    , NULL as material_document_item
	, sat_rcpt_tt_e21.REL_NUMB as release_number 
    , sat_rcpt_tt_e21.part_code as inventory_item_id
    , CASE 
        WHEN sat_hdr_tt_e21.PO_STATUS = '20' THEN 'Y' -- 20 : Cancelled Code
        ELSE 'N'
    END as po_header_del_ind
    , sat_hdr_tt_e21.date_entered as po_creation_date
    , sat_rcpt_tt_e21.date_rcv as posting_date
    , YEAR(sat_rcpt_tt_e21.date_rcv) as cal_year
    , MONTH(sat_rcpt_tt_e21.date_rcv) as cal_month
    , suplr_c.vend_code as supplier_number_parent
    , suplr_c.vend_name as supplier_name_parent
    , suplr_c.vend_code as supplier_number_child
    , suplr_c.vend_name as supplier_name_child 
    , sat_hdr_tt_e21.TERMS_CODE as payment_terms
    , sat_hdr_tt_e21.PO_TYPE as document_type
    , COALESCE(hub_supplier.supplier_bk, '-2') as supplier_bk  -- '-2' : GHOST RECORD-nullkey-optional
    , sat_rcpt_tt_e21.part_code as item_bk
    , sat_rcpt_tt_e21.cost_ctr as plant_bk
    , sat_hdr_tt_e21.billto_code as legal_entity_bk
    , COALESCE(lsat_supplier_item_plant.ORIGIN_COUNTRY,lsat_supplier_item.ORIGIN_COUNTRY )  as country_of_origin
    , sat_hdr_tt_e21.buyer_id as HDR_BUYER_CODE
    , COALESCE(ref.op_co, 'THERMA-TRU') as drvd_opco
	, sat_rcpt_tt_e21.qty_ord as sys_order_qty
	, sat_rcpt_tt_e21.uom_conv as sys_uom_conv
    , sat_rcpt_tt_e21.qty_ord/sat_rcpt_tt_e21.uom_conv as order_qty
    , CASE WHEN sat_rcpt_tt_e21.UOM_CONV=0 
            THEN COALESCE(sat_rcpt_tt_e21.UNIT_PRICE,0) 
            ELSE COALESCE(sat_rcpt_tt_e21.UNIT_PRICE,0)*sat_rcpt_tt_e21.UOM_CONV
            END                                                              as order_unit_price   
    , order_unit_price as order_unit_price_usd
	, sat_rcpt_tt_e21.qty_recvd as sys_receipt_qty
	, sat_rcpt_tt_e21.rcv_conv  as sys_rcv_conv
    , sat_rcpt_tt_e21.qty_recvd/sat_rcpt_tt_e21.rcv_conv as receipt_qty
	, sat_rcpt_tt_e21.unit_price as sys_unit_price
	, COALESCE((sat_rcpt_tt_e21.unit_price*sat_rcpt_tt_e21.rcv_conv), 0) as po_receipt_price
    /** if order is a drop ship order , use INV_EXT_COST as spend amount */
	, case 
        when  sat_rcpt_tt_e21.SO_NUMBER IS NOT NULL THEN COALESCE(sat_rcpt_tt_e21.INV_EXT_COST ,0)
        else COALESCE((sat_rcpt_tt_e21.qty_recvd*sat_rcpt_tt_e21.unit_price), 0) 
      end as  receipt_spend    
--******** Total receipt spend & qty calc
    , COALESCE(
        SUM(receipt_qty)
            over (partition by sat_rcpt_tt_e21.po_number, sat_rcpt_tt_e21.item_no order by po_creation_date)
        , 0
    ) as total_rcpt_qty
    , COALESCE(
        SUM(receipt_spend)
            over (partition by sat_rcpt_tt_e21.po_number, sat_rcpt_tt_e21.item_no  order by po_creation_date)
        , 0
    ) as total_rcpt_spend
    , receipt_qty as  spend_volume
    , sat_rcpt_tt_e21.uom as po_item_uom
    , sat_rcpt_tt_e21.rcv_uom as po_receipt_uom   
    , null as usd_po_item_price
	, COALESCE(receipt_spend, 0) as SPEND_AMOUNT_LOCAL_CURRENCY
	, COALESCE(receipt_spend, 0) as SPEND_USD
	, sat_rcpt_tt_e21.xcur_uom
    , sat_rcpt_tt_e21.xcur_uom as LOCAL_CURRENCY
    , sat_rcpt_tt_e21.xcur_conv
    , COALESCE(ref.business_unit, 'OUTDOORS') as business_unit
    , COALESCE(ref.op_co, 'THERMA-TRU') as op_co_
    , CONCAT_WS('|', COALESCE(op_co_, ''), COALESCE(sat_rcpt_tt_e21.part_code, '')) as opco_item
    , l.po_header_hk
    , l.po_item_hk
    , l.po_item_receipt_dk
    , l.item_hk
    , l.supplier_hk
    , l.plant_hk
    , l.legal_entity_hk   
    , sat_rcpt_tt_e21.bkcc
    , COALESCE(ref.op_co, 'THERMA-TRU') as opco_category
    , COALESCE(ref.director_name, 'REVIEW') as director_name
    , COALESCE(ref.category_leader_name, 'REVIEW') as category_leader_name
    , COALESCE(ref.fbin_category_i, 'REVIEW') as fbin_category_i
    , COALESCE(ref.fbin_category_ii, 'REVIEW') as fbin_category_ii
    , COALESCE(ref.fbin_category_iii, 'REVIEW') as fbin_category_iii
	, MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST('-2' as VARCHAR)),''), '^^')
        )))                                                          as                               PURCHASING_RECORD_HK
      , MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST('-2' as VARCHAR)),''), '^^')
        )))                                                          as                                  PURCHASING_ORG_HK
	, l.rec_src
from l
    inner join sat_rcpt_tt_e21 on l.LNK_PO_RECEIPT_HK = sat_rcpt_tt_e21.LNK_PO_RECEIPT_HK
    inner join hub_po_hdr on l.po_header_hk = hub_po_hdr.po_header_hk
    left join sat_hdr_tt_e21 on l.po_header_hk = sat_hdr_tt_e21.po_header_hk and sat_hdr_tt_e21.REL_NUMB = sat_rcpt_tt_e21.REL_NUMB
    left join ref_ctg_src_tt_e21 as ref on sat_rcpt_tt_e21.part_code = ref.item and ref.op_co = 'THERMA-TRU'
    left join hub_supplier on l.supplier_hk = hub_supplier.supplier_hk
    left join sat_supplier_tt_e21 as suplr_c on hub_supplier.supplier_hk = suplr_c.supplier_hk
	left join lnk_supplier_item on l.item_hk = lnk_supplier_item.item_hk and l.supplier_hk = lnk_supplier_item.SUPPLIER_HK 
    left join lsat_supplier_item on lsat_supplier_item.lnk_supplier_item_hk = lnk_supplier_item.lnk_supplier_item_hk
	left join lnk_supplier_item_plant on lnk_supplier_item_plant.item_hk = l.item_hk 
										and lnk_supplier_item_plant.supplier_hk = l.supplier_hk 
										and lnk_supplier_item_plant.plant_hk = l.plant_hk 
    left join lsat_supplier_item_plant on lnk_supplier_item_plant.lnk_supplier_item_plant_hk = lsat_supplier_item_plant.lnk_supplier_item_plant_hk       
   where true 
   and sat_hdr_tt_e21.po_type <> 'I' -- Filter Intra company transfers 
   