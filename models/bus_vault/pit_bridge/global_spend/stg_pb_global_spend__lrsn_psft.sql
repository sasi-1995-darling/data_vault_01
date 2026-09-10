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
    where rec_src = 'USSDBR.ORCL.PSFTPRD.PS_RECV_LN_SHIP'   /* This filter is to exclude the ghost records */
    /* This filter is necessary to ensure only one record is kept per PO ITEM RECEIPT level.
                        However, the link's granularity is designed to track changes related to Legal Entity, Supplier etc.,*/
    qualify MAX(load_dts) over (partition by po_item_receipt_dk) = load_dts
)

, sat_rcpt_lrsn_psft as (
    select 
        po_id,
        line_nbr,
        receiver_id,
        recv_ln_nbr,
        inv_item_id,
        receipt_dttm,
        qty_sh_recvd,
        merchandise_amt,
        receive_uom,
        price_recv,
        price_po_bse,
        currency_cd_base,
        currency_cd,
        conversion_rate,
        po_type,
        recv_ship_status,
        business_unit_in,
        business_unit,
        category_id,
        itm_setid,
        bkcc,
        lnk_po_receipt_hk,
        load_dts
    from {{ ref('lsat_po_receipt__lrsn_psft') }}
    qualify MAX(load_dts) over (partition by po_id, line_nbr, receiver_id, recv_ln_nbr) = load_dts
)

-- The Ref table needs an update to include BUSINESS_UNIT field to make the join efficient
, ref_ctg_src_lrsn_psft as (
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
)

, hub_po_hdr as (
    select 
        PO_HEADER_HK,
        PO_HEADER_BK
    from {{ ref('hub_po_header') }}
    where bkcc = 'Swimming_Ocean'
)

, sat_hdr_lrsn_psft as (
    select 
        po_header_hk,
        po_id,
        buyer_id,
        po_status,
        po_dt,
        pymnt_terms_cd,
        po_type,
        rate_date,
        rate_mult,
        rate_div,
        vendor_setid,
        vndr_loc,
        bkcc,
        load_dts
    from {{ ref('sat_po_header__lrsn_psft') }}
    qualify MAX(load_dts) over (partition by po_header_hk) = load_dts
)

, hub_po_item as (
    select 
        po_item_hk 
    from {{ ref('hub_po_item') }}
    where bkcc = 'Swimming_Ocean'
)

, lnk_po_item as (
    select 
        po_item_hk,
        item_hk,
        supplier_hk,
        purchasing_record_hk,
        purchasing_org_hk,
        load_dts
    from {{ ref('lnk_po_item') }}
    /* This filter is necessary to ensure only one record is kept per PO ITEM RECEIPT level.
                                            However, the link's granularity is designed to track changes related to Legal Entity, Supplier etc.,*/
    qualify MAX(load_dts) over (partition by po_item_hk) = load_dts
)

, sat_line_lrsn_psft as (
    select 
        po_item_hk,
        unit_of_measure,
        cancel_status,
        load_dts
    from {{ ref('sat_po_item__lrsn_psft') }}
    qualify MAX(load_dts) over (partition by po_item_hk) = load_dts
)

, hub_supplier as (
    select 
        supplier_hk,
        supplier_bk
    from {{ ref('hub_supplier_v2') }}
    where bkcc = 'Swimming_Ocean'
)

, sat_supplier_lrsn_psft as (
    select 
        supplier_hk,
        vendor_id,
        name1,
        load_dts
    from {{ ref('sat_supplier__lrsn_psft') }}
    qualify MAX(load_dts) over (partition by supplier_hk) = load_dts
)
, lnk_supplier_item_loc as (
    select 
        lnk_supplier_item_hk,
        item_hk,
        supplier_hk,
        load_dts
    from {{ ref('lnk_supplier_item') }}
    qualify MAX(load_dts) over (partition by lnk_supplier_item_hk) = load_dts
)

, lmsat_vendor_loc AS (
   SELECT 
       lnk_supplier_item_hk,
       setid,
       vndr_loc,
       country_ist_origin,
       load_dts
    from {{ ref('lmsat_supplier_item_loc__lrsn_psft') }}
   qualify MAX(load_dts) over (partition by lnk_supplier_item_hk, setid, vndr_loc) = load_dts
)
, sat_po_item_schedule_lines_lrsn_psft as 
(
    select 
        po_item_hk,
        qty_po,
        price_po_bse,
        price_po,
        cancel_status,
        merchandise_amt,
        load_dts
    from {{ ref('sat_po_item_schedule_lines__lrsn_psft') }}
    qualify 1 = row_number() over (partition by po_item_hk, SCHED_NBR  order by load_dts desc)
)

, sat_po_item_schedule_lines_lrsn_psft_aggr as
(
	select po_item_hk 
	,SUM(qty_po) as sum_order_qty
    ,SUM(merchandise_amt) as sum_merchandise_amt
    , max(price_po_bse) as price_po_bse
    , max(price_po) as price_po
	 from sat_po_item_schedule_lines_lrsn_psft  
     where sat_po_item_schedule_lines_lrsn_psft.cancel_status <> 'X'
     group by all
)

, ref_cat_cd_lrsn as
(
    select 
        category_id,
        setid,
        category_cd,
        descr60,
        effdt
    from {{ ref('ref_sat_item_cat__lrsn_psft') }}
    where rec_src <> 'USAZET.SNOWFLAKE.FBIN.DERIVED' 
    qualify 1 = row_number() over (partition by category_id, setid order by effdt desc) 
)

--  Larson_SPEND_CALC 
select
--grain
    hub_po_hdr.po_header_bk as po_header_id 
    , sat_rcpt_lrsn_psft.line_nbr::TEXT as po_line_number 
    , sat_rcpt_lrsn_psft.PO_ID::TEXT as po_number
    , sat_rcpt_lrsn_psft.receiver_id::TEXT as material_document_number
    , sat_rcpt_lrsn_psft.recv_ln_nbr::TEXT as material_document_item
    , sat_rcpt_lrsn_psft.INV_ITEM_ID as inventory_item_id
    , CASE 
        WHEN sat_hdr_lrsn_psft.po_status = 'X' THEN 'Y'
        WHEN sat_hdr_lrsn_psft.po_status = 'PX' THEN 'Y'
        ELSE 'N'
    END as po_header_del_ind
    , sat_hdr_lrsn_psft.PO_DT::DATE as po_creation_date
    , sat_rcpt_lrsn_psft.RECEIPT_DTTM::DATE as posting_date
    , YEAR(sat_rcpt_lrsn_psft.RECEIPT_DTTM) as cal_year
    , MONTH(sat_rcpt_lrsn_psft.RECEIPT_DTTM) as cal_month
    , suplr_c.VENDOR_ID as supplier_number_parent
    , suplr_c.NAME1 as supplier_name_parent
    , suplr_c.VENDOR_ID as supplier_number_child
    , suplr_c.NAME1 as supplier_name_child 
    , sat_hdr_lrsn_psft.pymnt_terms_cd as payment_terms
    , sat_hdr_lrsn_psft.po_type as document_type
    , hub_supplier.supplier_bk as supplier_bk
    , sat_rcpt_lrsn_psft.inv_item_id as item_bk
    , sat_rcpt_lrsn_psft.business_unit_in as plant_bk
    , sat_rcpt_lrsn_psft.business_unit as legal_entity_bk
    , UPPER(lmsat_vendor_loc.country_ist_origin) as country_of_origin
    , ref_cat_cd_lrsn.category_cd as category_cd
    , ref_cat_cd_lrsn.descr60 as category_desc
    , sat_hdr_lrsn_psft.buyer_id as HDR_BUYER_CODE
    , 'LARSON' as drvd_opco
    , COALESCE(sat_po_item_schedule_lines_lrsn_psft_aggr.sum_order_qty, 0) as order_qty
    , sat_po_item_schedule_lines_lrsn_psft_aggr.price_po  as order_unit_price
    , ROUND(sat_po_item_schedule_lines_lrsn_psft_aggr.price_po*(sat_hdr_lrsn_psft.rate_mult/sat_hdr_lrsn_psft.rate_div ), 5)   as order_unit_price_usd
--******** Total receipt spend & qty calc
    , COALESCE(
        SUM(sat_rcpt_lrsn_psft.QTY_SH_RECVD)
            over (partition by po_header_id, sat_rcpt_lrsn_psft.line_nbr order by po_creation_date)
        , 0
    ) as total_rcpt_qty 
    , COALESCE(
        SUM(sat_rcpt_lrsn_psft.QTY_SH_RECVD * sat_rcpt_lrsn_psft.price_recv)
            over (partition by po_header_id, sat_rcpt_lrsn_psft.line_nbr order by po_creation_date)
        , 0
    ) as total_rcpt_spend 
    , sat_rcpt_lrsn_psft.QTY_SH_RECVD as receipt_qty
    ,COALESCE((sat_rcpt_lrsn_psft.QTY_SH_RECVD * sat_rcpt_lrsn_psft.price_recv), 0) as receipt_spend 
    , sat_rcpt_lrsn_psft.QTY_SH_RECVD as  spend_volume
    , sat_line_lrsn_psft.UNIT_OF_MEASURE as po_item_uom
    , sat_rcpt_lrsn_psft.RECEIVE_UOM as po_receipt_uom
    , sat_rcpt_lrsn_psft.PRICE_RECV as po_receipt_price
    , ROUND(sat_rcpt_lrsn_psft.price_recv*(sat_hdr_lrsn_psft.rate_mult/sat_hdr_lrsn_psft.rate_div ), 5) as usd_po_item_price 
	, COALESCE(ROUND((sat_rcpt_lrsn_psft.QTY_SH_RECVD * sat_rcpt_lrsn_psft.price_recv), 5), 0)  as SPEND_AMOUNT_LOCAL_CURRENCY
    /* For Larson PeopleSoft, the merchandise_amt and price_recv fields are recorded in the PO currency. 
       Therefore, the conversion for SPEND_USD is performed using the PO currency rather than the local currency. */
    , IFF(
        sat_rcpt_lrsn_psft.CURRENCY_CD = 'USD', SPEND_AMOUNT_LOCAL_CURRENCY, COALESCE(ROUND((sat_rcpt_lrsn_psft.QTY_SH_RECVD * sat_rcpt_lrsn_psft.price_recv)*(sat_hdr_lrsn_psft.rate_mult/sat_hdr_lrsn_psft.rate_div ), 5), 0)
    )  as spend_usd
	, sat_rcpt_lrsn_psft.CURRENCY_CD_BASE AS local_currency
    , sat_rcpt_lrsn_psft.CURRENCY_CD as PO_CURRENCY
    , sat_rcpt_lrsn_psft.CONVERSION_RATE
    , sat_hdr_lrsn_psft.RATE_DATE
    , sat_hdr_lrsn_psft.RATE_MULT
    , sat_hdr_lrsn_psft.RATE_DIV
    , COALESCE(ref.business_unit, 'OUTDOORS') as business_unit
    , COALESCE(ref.op_co, 'LARSON') as op_co_
    , CONCAT_WS('|', COALESCE(op_co_, ''), COALESCE(sat_rcpt_lrsn_psft.inv_item_id, '')) as opco_item
    , sat_rcpt_lrsn_psft.po_type as po_receipt_type
    , l.po_header_hk
    , l.po_item_hk
    , l.po_item_receipt_dk
    , l.item_hk
    , l.supplier_hk
    , l.plant_hk
    , l.legal_entity_hk
    , sat_rcpt_lrsn_psft.bkcc
    , COALESCE(ref.op_co, 'LARSON') as opco_category
    , COALESCE(ref.director_name, 'REVIEW') as director_name
    , COALESCE(ref.category_leader_name, 'REVIEW') as category_leader_name
    , COALESCE(ref.fbin_category_i, 'REVIEW') as fbin_category_i
    , COALESCE(ref.fbin_category_ii, 'REVIEW') as fbin_category_ii
    , COALESCE(ref.fbin_category_iii, 'REVIEW') as fbin_category_iii
    , sat_rcpt_lrsn_psft.recv_ship_status
    , sat_line_lrsn_psft.cancel_status as po_item_cancel_status
	, lnk_po_item.PURCHASING_RECORD_HK
	, lnk_po_item.PURCHASING_ORG_HK
	, l.rec_src
from l
    inner join sat_rcpt_lrsn_psft on l.LNK_PO_RECEIPT_HK = sat_rcpt_lrsn_psft.LNK_PO_RECEIPT_HK
    inner join hub_po_item on l.po_item_hk = hub_po_item.po_item_hk
    inner join lnk_po_item on hub_po_item.po_item_hk = lnk_po_item.po_item_hk
    inner join hub_po_hdr on l.po_header_hk = hub_po_hdr.po_header_hk
    left join sat_hdr_lrsn_psft on l.po_header_hk = sat_hdr_lrsn_psft.po_header_hk
    left join sat_line_lrsn_psft on hub_po_item.po_item_hk = sat_line_lrsn_psft.po_item_hk
    left join ref_ctg_src_lrsn_psft as ref on sat_rcpt_lrsn_psft.inv_item_id = ref.item and ref.op_co = 'LARSON'
    inner join hub_supplier on l.supplier_hk = hub_supplier.supplier_hk
    left join sat_supplier_lrsn_psft as suplr_c on hub_supplier.supplier_hk = suplr_c.supplier_hk
	left join sat_po_item_schedule_lines_lrsn_psft_aggr on l.po_item_hk = sat_po_item_schedule_lines_lrsn_psft_aggr.po_item_hk
	left join lnk_supplier_item_loc on lnk_po_item.item_hk = lnk_supplier_item_loc.item_hk and lnk_po_item.SUPPLIER_HK = lnk_supplier_item_loc.SUPPLIER_HK 
    left join lmsat_vendor_loc on lmsat_vendor_loc.lnk_supplier_item_hk = lnk_supplier_item_loc.lnk_supplier_item_hk
        and lmsat_vendor_loc.setid = sat_hdr_lrsn_psft.vendor_setid
        and lmsat_vendor_loc.vndr_loc = sat_hdr_lrsn_psft.vndr_loc
    left join ref_cat_cd_lrsn on ref_cat_cd_lrsn.category_id = sat_rcpt_lrsn_psft.category_id and ref_cat_cd_lrsn.setid = sat_rcpt_lrsn_psft.itm_setid
where sat_rcpt_lrsn_psft.RECV_SHIP_STATUS <> 'X'
