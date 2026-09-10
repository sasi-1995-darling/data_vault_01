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
    where rec_src = 'USOHMA.MSSQL.GPPRD.DBO_POP10500'   /* This filter is to exclude the ghost records */
    /* This filter is necessary to ensure only one record is kept per PO ITEM RECEIPT level.
                        However, the link's granularity is designed to track changes related to Legal Entity, Supplier etc.,*/
    qualify MAX(load_dts) over (partition by po_item_receipt_dk) = load_dts
)

, sat_rcpt_tt_gp as (
    select 
        ponumber,
		polnenum, 
		poprctnm,
		rcptlnnm,
		ITEMNMBR,
		status,
		daterecd,
		uofm,
		qtyshppd,
		umqtyinb,
		pchrptct,   
        CURNCYID,
        bkcc,
        lnk_po_receipt_hk,
        load_dts
    from {{ ref('lsat_po_receipt__tt_gp') }}
	where status = 1	 -- Only Posted Status
	 and  qtyshppd>0  -- filter only receipts 
    qualify max(load_dts) over (partition by lnk_po_receipt_hk) = load_dts
)

-- The Ref table needs an update to include BUSINESS_UNIT field to make the join efficient
, REF_CTG_SRC_TT_GP as (
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

, sat_hdr_tt_gp as (
    select 
        po_header_hk,
		PONUMBER   ,
		POSTATUS   ,
		POTYPE    ,
		DOCDATE    ,
		VENDORID   ,
		CMPANYID   ,
		CMPNYNAM   ,
		PYMTRMID   ,
		BUYERID	   ,
		PURCHCOUNTRY,
        bkcc      ,
        load_dts
    from {{ ref('sat_po_header__tt_gp') }}
    qualify MAX(load_dts) over (partition by po_header_hk) = load_dts
)

, hub_po_item as (
    select
        po_item_hk,
        bkcc
    from {{ ref('hub_po_item') }}
    where bkcc = 'Kicking_Panda'
)

, lnk_po_item as (
    select
        po_item_hk,
        purchasing_record_hk,
        purchasing_org_hk,
        load_dts
    from {{ ref('lnk_po_item') }}
    /* This filter is necessary to ensure only one record is kept per PO ITEM RECEIPT level.
       However, the link's granularity is designed to track changes related to Legal Entity, Supplier etc.,*/
    qualify MAX(load_dts) over (partition by po_item_hk) = load_dts
)

, sat_line_tt_gp as (
    select
        po_item_hk,
        load_dts,
        ITEMNMBR   ,
		ITEMDESC   ,
		POTYPE     ,
		POLNESTA   ,
		VNDITDSC   ,
		QTYORDER   ,
		UNITCOST   ,
		LOCNCODE   ,
        UOFM
    from {{ ref('sat_po_item__tt_gp') }}
    qualify MAX(load_dts) over (partition by po_item_hk) = load_dts
)

, hub_supplier as (
    select 
        supplier_hk,
        supplier_bk
    from {{ ref('hub_supplier_v2') }}
    where bkcc = 'Kicking_Panda'
)

, sat_supplier_tt_gp as (
    select 
        supplier_hk,
        VENDORID,
        VENDNAME,
        VNDCLSID,
        load_dts
    from {{ ref('sat_supplier__tt_gp') }}
    qualify MAX(load_dts) over (partition by supplier_hk) = load_dts
)


--  TTGP Spend Calc 
select
--grain
      sat_rcpt_tt_gp.PONUMBER as po_header_id 
    , sat_rcpt_tt_gp.POLNENUM::TEXT as po_line_number 
    , sat_rcpt_tt_gp.POPRCTNM::TEXT as material_document_number
    , sat_rcpt_tt_gp.RCPTLNNM::TEXT as material_document_item
    , sat_rcpt_tt_gp.ITEMNMBR as inventory_item_id
    , CASE 
        WHEN sat_hdr_tt_gp.POSTATUS = '6' THEN 'Y' -- 6 : Cancelled Code
        ELSE 'N'
    END as po_header_del_ind
    , sat_hdr_tt_gp.DOCDATE::date as po_creation_date
    , sat_rcpt_tt_gp.DATERECD::date as posting_date
    , YEAR(posting_date) as cal_year
    , MONTH(posting_date) as cal_month
    , suplr_c.VENDORID as supplier_number_parent
    , suplr_c.VENDNAME as supplier_name_parent
    , suplr_c.VENDORID as supplier_number_child
    , suplr_c.VENDNAME as supplier_name_child 
    , sat_hdr_tt_gp.PYMTRMID as payment_terms
    , sat_hdr_tt_gp.POTYPE::TEXT as document_type
    , hub_supplier.supplier_bk as supplier_bk
    , sat_rcpt_tt_gp.ITEMNMBR as item_bk
    , sat_line_tt_gp.LOCNCODE  as plant_bk
    , sat_hdr_tt_gp.CMPANYID::TEXT as legal_entity_bk
    , sat_hdr_tt_gp.PURCHCOUNTRY  as country_of_origin
    , sat_hdr_tt_gp.buyerid as HDR_BUYER_CODE
    , COALESCE(ref.op_co, 'THERMA-TRU') as drvd_opco	
    , sat_line_tt_gp.QTYORDER as order_qty	
    , sat_rcpt_tt_gp.QTYSHPPD as receipt_qty
	, sat_line_tt_gp.UNITCOST as order_unit_price
    , sat_line_tt_gp.UNITCOST as order_unit_price_usd
	, sat_rcpt_tt_gp.UMQTYINB*sat_rcpt_tt_gp.PCHRPTCT as po_receipt_price
	, COALESCE((receipt_qty * po_receipt_price), 0) as receipt_spend
--******** Total receipt spend & qty calc
    , COALESCE(
        SUM(receipt_qty)
            over (partition by sat_rcpt_tt_gp.PONUMBER, sat_rcpt_tt_gp.POLNENUM order by po_creation_date)
        , 0
    ) as total_rcpt_qty
    , COALESCE(
        SUM(receipt_spend)
            over (partition by sat_rcpt_tt_gp.PONUMBER, sat_rcpt_tt_gp.POLNENUM order  by po_creation_date)
        , 0
    ) as total_rcpt_spend
    , receipt_qty as  spend_volume
    , sat_line_tt_gp.UOFM  as po_item_uom
    , sat_rcpt_tt_gp.UOFM  as po_receipt_uom   
    , null as usd_po_item_price
	, COALESCE(receipt_spend, 0) as SPEND_AMOUNT_LOCAL_CURRENCY
	, COALESCE(receipt_spend, 0) as SPEND_USD	
    , sat_rcpt_tt_gp.curncyid as LOCAL_CURRENCY  
    , COALESCE(ref.business_unit, 'OUTDOORS') as business_unit
    , COALESCE(ref.op_co, 'THERMA-TRU') as op_co_
    , CONCAT_WS('|', COALESCE(op_co_, ''), COALESCE(sat_rcpt_tt_gp.ITEMNMBR, '')) as opco_item
    , l.po_header_hk
    , l.po_item_hk
    , l.po_item_receipt_dk
    , l.item_hk
    , l.supplier_hk
    , l.plant_hk
    , l.legal_entity_hk
    , sat_rcpt_tt_gp.bkcc
    , COALESCE(ref.op_co, 'THERMA-TRU') as opco_category
    , COALESCE(ref.director_name, 'REVIEW') as director_name
    , COALESCE(ref.category_leader_name, 'REVIEW') as category_leader_name
    , COALESCE(ref.fbin_category_i, 'REVIEW') as fbin_category_i
    , COALESCE(ref.fbin_category_ii, 'REVIEW') as fbin_category_ii
    , COALESCE(ref.fbin_category_iii, 'REVIEW') as fbin_category_iii
	, lnk_po_item.PURCHASING_RECORD_HK
	, lnk_po_item.PURCHASING_ORG_HK
	, l.rec_src
from l
    inner join sat_rcpt_tt_gp on l.LNK_PO_RECEIPT_HK = sat_rcpt_tt_gp.LNK_PO_RECEIPT_HK
    inner join hub_po_hdr on l.po_header_hk = hub_po_hdr.po_header_hk
	inner join hub_po_item  on l.po_item_hk = hub_po_item.po_item_hk 
    left join lnk_po_item on hub_po_item.po_item_hk = lnk_po_item.po_item_hk
    left join sat_hdr_tt_gp on l.po_header_hk = sat_hdr_tt_gp.po_header_hk
	left join sat_line_tt_gp on hub_po_item.po_item_hk = sat_line_tt_gp.po_item_hk
    left join ref_ctg_src_tt_gp as ref on sat_rcpt_tt_gp.ITEMNMBR = ref.item and ref.op_co = 'THERMA-TRU'
    left join hub_supplier on l.supplier_hk = hub_supplier.supplier_hk
    left join sat_supplier_tt_gp as suplr_c on hub_supplier.supplier_hk = suplr_c.supplier_hk	   
   WHERE true 
  and suplr_c.VNDCLSID <> 'INV-IC' -- Filter Intra Company transfer
