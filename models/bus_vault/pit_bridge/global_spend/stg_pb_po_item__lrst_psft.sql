{{
    config(
        materialized='ephemeral'
    )
}}

with 
 cte_lnk_po_item as 
(
/** Driving Key as po_item_hk , to pick the latest record**/
    select * from {{ ref('lnk_po_item') }} 
    where rec_src = 'USSDBR.ORCL.PSFTPRD.PS_PO_LINE'
    QUALIFY 1= ROW_NUMBER() OVER(PARTITION BY po_item_hk ORDER BY load_dts DESC) 
)


,cte_sat_po_item__lrsn_psft as 
(
    select * from {{ ref('sat_po_item__lrsn_psft') }}
    QUALIFY 1= ROW_NUMBER() OVER(PARTITION BY po_item_hk ORDER BY LOAD_DTS DESC) 
)

,cte_sat_po_item_schedule_lines__lrsn_psft as 
(
    select * from {{ ref('sat_po_item_schedule_lines__lrsn_psft') }} 
    QUALIFY 1= ROW_NUMBER() OVER(PARTITION BY po_item_hk , SCHED_NBR ORDER BY load_dts DESC)
)


,cte_sat_po_item_schedule_lines__lrsn_psft_aggr as 
(
    select po_item_hk, 
       SUM(qty_po) sum_qty_po,
       SUM(merch_amt_bse) AS sum_merch_amt_bse,
       SUM(merchandise_amt) as sum_merchandise_amt,
       MAX(price_po) as price_po ,
       max(price_po_bse) as price_po_bse,
       MAX(currency_cd) AS currency_cd ,
       MAX(DUE_DT) AS DUE_DT_LATEST,
       MIN(DUE_DT) AS DUE_DT_EARLIEST,
       MAX(SHIP_DATE) AS SHIP_DATE_LATEST,
       MIN(SHIP_DATE) AS SHIP_DATE_EARLIEST
    from cte_sat_po_item_schedule_lines__lrsn_psft
    GROUP BY ALL 
)

,cte_sat_po_header__lrsn_psft as 
(
    select * from {{ ref('sat_po_header__lrsn_psft') }} 
    QUALIFY 1= ROW_NUMBER() OVER(PARTITION BY po_header_hk ORDER BY load_dts DESC) 
)

,cte_hub_po_item as
(
    select * from {{ ref('hub_po_item') }}
    where bkcc  in ('Swimming_Ocean')
)

,cte_hub_supplier_v2 as
(
    select * from {{ ref('hub_supplier_v2') }}
    where bkcc  in ('Swimming_Ocean')
)


select  
    -- hks ----------
    lnk.po_item_hk,
    lnk.po_header_hk,
    lnk.supplier_hk,
    lnk.item_hk,
    lnk.legal_entity_hk,    
    -- Bks ----------
    CONCAT_WS('||', spl.business_unit,spl.po_id) as po_header_bk,
    spl.po_id, 
    spl.line_nbr,
    hs.supplier_bk,
    spl.inv_item_id,
    spl.business_unit,
    -----------------
    sph.po_dt ,  
    sph.RATE_MULT,
    sph.RATE_DIV,
    sph.RATE_DATE,
    spsch.sum_qty_po,
    spl.unit_of_measure,
    spsch.sum_merchandise_amt,
    TO_CHAR(spsch.DUE_DT_LATEST, 'YYYYMMDD')::INTEGER AS DUE_DT_LATEST,
    TO_CHAR(spsch.DUE_DT_EARLIEST, 'YYYYMMDD')::INTEGER AS DUE_DT_EARLIEST,
    TO_CHAR(spsch.SHIP_DATE_LATEST, 'YYYYMMDD')::INTEGER AS SHIP_DATE_LATEST,
    TO_CHAR(spsch.SHIP_DATE_EARLIEST, 'YYYYMMDD')::INTEGER AS SHIP_DATE_EARLIEST,
    spsch.price_po,
    IFF(sph.rate_div = 0, spsch.price_po, ROUND(spsch.price_po*(sph.rate_mult/sph.rate_div ), 5)) as price_po_usd,
    spl.cancel_status,
    spl._fivetran_deleted,
    spsch.currency_cd,
	spl.load_dts
from cte_lnk_po_item lnk
inner join cte_hub_po_item hp on (lnk.po_item_hk = hp.po_item_hk) 
left join cte_hub_supplier_v2 hs on (lnk.supplier_hk = hs.supplier_hk)
left join cte_sat_po_header__lrsn_psft sph on (lnk.po_header_hk = sph.po_header_hk )
left join cte_sat_po_item__lrsn_psft spl on (lnk.po_item_hk = spl.PO_ITEM_HK   )
left join cte_sat_po_item_schedule_lines__lrsn_psft_aggr  spsch on (lnk.po_item_hk = spsch.PO_ITEM_HK)
