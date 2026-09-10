{{
    config(
        materialized='ephemeral'
    )
}}

with
hub_po_hdr as (
    select * from {{ ref('hub_po_header') }}
    where bkcc = 'Swimming_Ocean'
)

, sat_hdr_lrsn as (
    select * from {{ ref('sat_po_header__lrsn_psft') }}
    qualify MAX(load_dts) over (partition by po_header_hk) = load_dts
)

, hub_po_item as (
    select * from {{ ref('hub_po_item') }}
    where bkcc = 'Swimming_Ocean'
)

, sat_po_itm_sch_line_lrsn as (
    select 
        *
    from {{ ref('sat_po_item_schedule_lines__lrsn_psft') }}
    qualify 1 = row_number() over (partition by po_item_hk, sched_nbr order by load_dts desc)
)

, lnk_po_item as 
(
/** Driving Key as po_item_hk , to pick the latest record**/
    select * 
    from {{ ref('lnk_po_item') }}
    where rec_src = 'USSDBR.ORCL.PSFTPRD.PS_PO_LINE'
    QUALIFY 1= ROW_NUMBER() OVER(PARTITION BY po_item_hk ORDER BY load_dts DESC) 
)
, sat_po_receipt_lrsn as (
    select * 
    from {{ ref('lsat_po_receipt__lrsn_psft') }}
    qualify 1 = ROW_NUMBER() over (partition by LNK_PO_RECEIPT_HK order by load_dts desc)
)

, sat_po_receipt_lrsn_aggr as (
       select po_id, 
              line_nbr,
              sched_nbr,
              BUSINESS_UNIT,
              SUM(QTY_SH_RECVD) sum_QTY_SH_RECVD   ,
              MAX(CASE WHEN SHIP_QTY_STATUS = '2' THEN 1 ELSE 0 END) AS has_over_shipment
    from sat_po_receipt_lrsn
    GROUP BY ALL 
)

, hub_supplier as (
    select * from {{ ref('hub_supplier_v2') }}
    where bkcc = 'Swimming_Ocean'
)

, sat_supplier_lrsn as (
    select * from {{ ref('sat_supplier__lrsn_psft') }}
    qualify MAX(load_dts) over (partition by supplier_hk) = load_dts
)

, sat_line_lrsn as (
    select * from {{ ref('sat_po_item__lrsn_psft') }}
    qualify MAX(load_dts) over (partition by po_item_hk) = load_dts
)

, ref_ctg_src_lrsn as (
    select * from {{ ref('ref_item_sourcing_category_v2') }}
    where  business_unit = 'OUTDOORS'
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
   FROM {{ ref('lmsat_supplier_item_loc__lrsn_psft') }}
   qualify MAX(load_dts) over (partition by lnk_supplier_item_hk) = load_dts
)


--
, final as (
select
      sat_po_itm_sch_line_lrsn.po_id::TEXT as po_id
    , hub_po_hdr.po_header_bk as po_header_bk
    , sat_po_itm_sch_line_lrsn.line_nbr::TEXT as line_nbr
    , ROUND(sat_po_itm_sch_line_lrsn.SCHED_NBR, 0)::TEXT as po_schedule_line_number
    , sat_po_itm_sch_line_lrsn.due_dt as schedule_line_delivery_date
    , sat_po_itm_sch_line_lrsn.qty_po as order_qty
    , COALESCE(sat_po_receipt_lrsn_aggr.sum_qty_sh_recvd,0) as received_qty 
    , round(sat_po_itm_sch_line_lrsn.PRICE_PO *(sat_hdr_lrsn.rate_mult/sat_hdr_lrsn.rate_div ), 2) as NET_PRICE
    , sat_line_lrsn.UNIT_OF_MEASURE as po_item_uom
    , sat_po_itm_sch_line_lrsn.qty_po - received_qty as volume
    , NET_PRICE *(sat_po_itm_sch_line_lrsn.qty_po -received_qty ) as spend
    , YEAR(sat_po_itm_sch_line_lrsn.due_dt) as cal_year
    , MONTH(sat_po_itm_sch_line_lrsn.due_dt) as cal_month
    , 'OUTDOORS' as business_unit  
    , 'LARSON' as drvd_opco
    , CONCAT_WS('|', COALESCE(drvd_opco, ''), COALESCE(sat_line_lrsn.inv_item_id, '')) as opco_item
    , sat_supplier_lrsn.VENDOR_ID as supplier_number_parent
    , sat_supplier_lrsn.NAME1 as supplier_name_parent
    , sat_supplier_lrsn.VENDOR_ID as supplier_number_child
    , sat_supplier_lrsn.NAME1 as supplier_name_child
    , sat_line_lrsn.descr254_mixed as item_description
    , UPPER(lmsat_vendor_loc.country_ist_origin) as country_of_origin
    , sat_hdr_lrsn.PO_DT::DATE  as po_creation_date
    , CASE 
        WHEN sat_hdr_lrsn.po_status = 'X' THEN 'Y'
        WHEN sat_hdr_lrsn.po_status = 'PX' THEN 'Y'
        ELSE 'N'
        END as po_header_del_ind
    , sat_hdr_lrsn.pymnt_terms_cd as payment_terms
    , sat_hdr_lrsn.po_type as document_type
    , COALESCE(ref_ctg_src_lrsn.op_co, 'LARSON') as opco_category
    , COALESCE(ref_ctg_src_lrsn.director_name, 'REVIEW') as director_name
    , COALESCE(ref_ctg_src_lrsn.category_leader_name, 'REVIEW') as category_leader_name
    , COALESCE(ref_ctg_src_lrsn.fbin_category_i, 'REVIEW') as fbin_category_i
    , COALESCE(ref_ctg_src_lrsn.fbin_category_ii, 'REVIEW') as fbin_category_ii
    , COALESCE(ref_ctg_src_lrsn.fbin_category_iii, 'REVIEW') as fbin_category_iii
    , sat_line_lrsn.inv_item_id as item_bk
    , sat_po_itm_sch_line_lrsn.business_unit_in as plant_bk
    , sat_po_itm_sch_line_lrsn.business_unit as legal_entity_bk
    , sat_po_itm_sch_line_lrsn.due_dt as schedule_line_delivery_date_bk
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
    , lnk_po_item.rec_src
    , hub_po_item.bkcc
    , 'Larson-Forecast Open Orders' as source

from lnk_po_item
    inner join hub_po_item on lnk_po_item.po_item_hk = hub_po_item.po_item_hk
    inner join hub_po_hdr on lnk_po_item.po_header_hk = hub_po_hdr.po_header_hk
    left join sat_hdr_lrsn on hub_po_hdr.po_header_hk = sat_hdr_lrsn.po_header_hk
    left join sat_line_lrsn on hub_po_item.po_item_hk = sat_line_lrsn.po_item_hk
    left join sat_po_itm_sch_line_lrsn on hub_po_item.po_item_hk = sat_po_itm_sch_line_lrsn.po_item_hk
    left join sat_po_receipt_lrsn_aggr on sat_po_itm_sch_line_lrsn.po_id = sat_po_receipt_lrsn_aggr.po_id and 
     sat_po_itm_sch_line_lrsn.line_nbr = sat_po_receipt_lrsn_aggr.line_nbr and 
     sat_po_itm_sch_line_lrsn.sched_nbr = sat_po_receipt_lrsn_aggr.sched_nbr   and 
     sat_po_itm_sch_line_lrsn.BUSINESS_UNIT = sat_po_receipt_lrsn_aggr.BUSINESS_UNIT
    left join
        ref_ctg_src_lrsn
        on sat_line_lrsn.inv_item_id = ref_ctg_src_lrsn.item and drvd_opco = ref_ctg_src_lrsn.op_co
    left join hub_supplier on lnk_po_item.supplier_hk = hub_supplier.supplier_hk
    left join sat_supplier_lrsn  on hub_supplier.supplier_hk = sat_supplier_lrsn.supplier_hk   

    left join lnk_supplier_item_loc on lnk_po_item.item_hk = lnk_supplier_item_loc.item_hk and lnk_po_item.SUPPLIER_HK = lnk_supplier_item_loc.SUPPLIER_HK 
    left join lmsat_vendor_loc on lmsat_vendor_loc.lnk_supplier_item_hk = lnk_supplier_item_loc.lnk_supplier_item_hk
        and lmsat_vendor_loc.setid = sat_hdr_lrsn.vendor_setid
        and lmsat_vendor_loc.vndr_loc = sat_hdr_lrsn.vndr_loc
where  sat_po_itm_sch_line_lrsn.cancel_status NOT IN ('X' ,'C') -- Filter Cancel and Closed Status
and   (order_qty - COALESCE(received_qty,0)) > 0

)

select 
po_header_bk as PO_HEADER_ID
,line_nbr as PO_LINE_NUMBER
,PO_ID
,PO_SCHEDULE_LINE_NUMBER
,null as PLAN_CREATION_DATE
,null as ORDER_NUMBER
,null as  TRANSACTION_ID
,PO_CREATION_DATE
,SCHEDULE_LINE_DELIVERY_DATE 
,PO_ITEM_UOM
,ORDER_QTY
,RECEIVED_QTY
,NET_PRICE
,VOLUME
,SPEND
,CAL_YEAR
,CAL_MONTH
,BUSINESS_UNIT
,DRVD_OPCO
,OPCO_ITEM
,SUPPLIER_NUMBER_PARENT
,SUPPLIER_NAME_PARENT
,SUPPLIER_NUMBER_CHILD
,SUPPLIER_NAME_CHILD
,ITEM_DESCRIPTION
,COUNTRY_OF_ORIGIN
,PO_HEADER_DEL_IND
,PAYMENT_TERMS
,DOCUMENT_TYPE
,OPCO_CATEGORY
,CATEGORY_LEADER_NAME
,DIRECTOR_NAME
,FBIN_CATEGORY_I
,FBIN_CATEGORY_II
,FBIN_CATEGORY_III
,ITEM_BK
,PLANT_BK
,LEGAL_ENTITY_BK
,SCHEDULE_LINE_DELIVERY_DATE_BK 
,PO_HEADER_HK
,PO_ITEM_HK
,ITEM_HK
,SUPPLIER_HK
,LEGAL_ENTITY_HK
,PURCHASING_RECORD_HK
,PURCHASING_ORG_HK
,SOURCE
,REC_SRC
,BKCC
from final
