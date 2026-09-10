{{
    config(
        materialized='ephemeral'
    )
}}

with
l as (
    select * from {{ ref('lnk_purchase_requisition') }}
    where rec_src <> 'USAZET.SNOWFLAKE.FBIN.DERIVED'   /* This filter is to exclude the ghost records */
    /* This filter is necessary to ensure only one record is kept perpurchase_requisition level.
     However, the link's granularity is designed to track changes related to Item, Plant,Supplier etc.,*/
    qualify MAX(load_dts) over (partition by purchase_requisition_hk) = load_dts
)

, hub_purchase_requisition as (
    select * from {{ ref('hub_purchase_requisition') }}
)

, sat_purchase_requisition as (
    select * from {{ ref('sat_purchase_requisition__winn_sap') }}
    qualify MAX(load_dts) over (partition by purchase_requisition_hk) = load_dts
)

, hub_purch_rec as (
    select * from {{ ref('hub_purchasing_record') }}
)

, sat_purch_rec as (
    select * from {{ ref('sat_purchasing_record__winn_sap') }}
    qualify MAX(load_dts) over (partition by purchasing_record_hk) = load_dts
)

, hub_supplier as (
    select * from {{ ref('hub_supplier_v2') }}
)

, sat_supplier_winn as (
    select
        LTRIM(lifnr, '0') as drvd_lifnr
        , *
    from {{ ref('sat_supplier__winn_sap') }}
    qualify MAX(load_dts) over (partition by supplier_hk) = load_dts
)

, ref_ctg_src_winn as (
    select * from {{ ref('ref_item_sourcing_category_v2') }}
    where business_unit = 'WINN'
)

, curr_conv as (
    select * from {{ ref('ref_currency_conversion_fiscal_month_avg') }}
    where fp_fiscal_month = TO_CHAR(CURRENT_DATE, 'YYYYMM')
    qualify 1 = ROW_NUMBER() over (partition by fp_fiscal_month, fcurr, fiscal_month_avg_ukurs order by fp_date_dt desc)
)


--
, join_layer as (
    select
          s_pr.banfn as purchase_requisition_number
        , s_pr.bnfpo as purchase_requisition_item_number
        , s_pr.lfdat as item_delivery_date
        , sat_purch_rec.lmein as base_uom
        , sat_purch_rec.meins as uom -- PO Unit of Measure     
        , sat_purch_rec.umrez as uom_n
        , sat_purch_rec.umren as uom_d
        , s_pr.menge as quantity_base_unit
/* If no match in EINA (sat_purch_rec) derive quantity from EBAN as units in EBAN is mostly same as PO units */
        , (s_pr.menge) * (COALESCE(sat_purch_rec.umren,1)/ COALESCE(sat_purch_rec.umrez,1)) as quantity_po_unit
        , s_pr.waers
        , s_pr.preis as net_price
        , s_pr.peinh as price_unit
        , (s_pr.preis / s_pr.peinh) * (sat_purch_rec.umrez / sat_purch_rec.umren) as price_per_po_unit 
        , price_per_po_unit * quantity_po_unit * COALESCE(curr_conv.fiscal_month_avg_ukurs, 1) as spend
        , case when
                s_pr.ekorg in ('MPFS', 'MXFS', 'NAFS', 'MPAC', 'AMCP', 'MINP', 'MCFG', 'MINT')
                then 'MOEN-NOAM'
            when s_pr.ekorg in ('RIOP') then 'HOUSE OF ROHL'
            when s_pr.ekorg in ('MGFP', 'MCHP', 'MHKP') then 'MOEN-CHINA'
            when s_pr.ekorg in ('MPEX') then 'ALL OPCO - INDIRECT'
        end as op_co_moen_drvd
        , CONCAT_WS('|', COALESCE(op_co_moen_drvd, ''), COALESCE(s_pr.matnr, '')) as opco_item
        , suplr_p.zzsupplierkey as supplier_number_parent
        , suplr_p.name1 as supplier_name_parent
        , suplr_c.lifnr as supplier_number_child
        , suplr_c.name1 as supplier_name_child
        , sat_purch_rec.urzla as country_of_origin
        , COALESCE(ref_ctg_src_winn.op_co, 'WINN') as opco_category
        , COALESCE(ref_ctg_src_winn.category_leader_name, 'REVIEW') as category_leader_name
        , COALESCE(ref_ctg_src_winn.director_name, 'REVIEW') as director_name
        , COALESCE(ref_ctg_src_winn.fbin_category_i, 'REVIEW') as fbin_category_i
        , COALESCE(ref_ctg_src_winn.fbin_category_ii, 'REVIEW') as fbin_category_ii
        , COALESCE(ref_ctg_src_winn.fbin_category_iii, 'REVIEW') as fbin_category_iii
        , COALESCE(ref_ctg_src_winn.business_unit, 'WINN') as business_unit
        -- Payment Terms TBD
        , s_pr.bsart as document_type
        -- BK        
        , s_pr.matnr as item_bk
        , s_pr.werks as plant_bk 
        , s_pr.lfdat as item_delivery_date_bk
        --HK
        , l.purchase_requisition_hk
        , l.supplier_hk
        , l.item_hk
        , l.plant_hk
        , l.purchasing_org_hk 
        , l.purchasing_record_hk 
        --System fields
        , l.rec_src
        , h.bkcc
        , s_pr.psa_delete_ind
    from l
        inner join hub_purchase_requisition h on h.purchase_requisition_hk = l.purchase_requisition_hk
        inner join sat_purchase_requisition s_pr on h.purchase_requisition_hk = s_pr.purchase_requisition_hk                                     
        left join hub_purch_rec on l.purchasing_record_hk = hub_purch_rec.purchasing_record_hk
        left join sat_purch_rec on hub_purch_rec.purchasing_record_hk = sat_purch_rec.purchasing_record_hk
        left join
            ref_ctg_src_winn
            on s_pr.matnr = ref_ctg_src_winn.item and op_co_moen_drvd = ref_ctg_src_winn.op_co       
        left join curr_conv
            on curr_conv.fcurr = s_pr.waers
        left join hub_supplier on l.supplier_hk = hub_supplier.supplier_hk
        left join sat_supplier_winn as suplr_c on hub_supplier.supplier_hk = suplr_c.supplier_hk
        left join sat_supplier_winn as suplr_p on suplr_c.zzsupplierkey = suplr_p.drvd_lifnr
    where
            s_pr.bsart = 'NB' /* Filter - standard purchase order  */
        and s_pr.statu <> 'B' /* Filter out PO created */
        and s_pr.loekz not in ('X', 'L') /* Filter Deleted Item */
        and s_pr.pstyp <> '7'
        and s_pr.matnr != ''
        and COALESCE(s_pr.preis, 0) > 0
        and s_pr.psa_delete_ind = 'N'
        and LEFT(s_pr.lfdat, 6) between TO_CHAR(CURRENT_DATE, 'YYYYMM') and TO_CHAR(
            DATEADD(month, 18, CURRENT_DATE()), 'YYYYMM'
        )
)


--FINAL LAYER 

select
      purchase_requisition_hk
    , purchase_requisition_number
    , purchase_requisition_item_number
    , item_delivery_date   
    , base_uom
    , uom
    , uom_n
    , uom_d
    , quantity_base_unit
    , quantity_po_unit
    , waers
    , net_price
    , price_unit
    , price_per_po_unit
    , spend
    , op_co_moen_drvd as opco
    , opco_item
    , supplier_number_parent
    , supplier_name_parent
    , supplier_number_child
    , supplier_name_child
    , country_of_origin
    , opco_category
    , category_leader_name
    , director_name
    , fbin_category_i
    , fbin_category_ii
    , fbin_category_iii
    , business_unit
    , document_type
    , item_bk
    , plant_bk  
    , item_delivery_date_bk
    , supplier_hk
    , item_hk
    , plant_hk
    , purchasing_org_hk
    , purchasing_record_hk
    , rec_src
    , BKCC
    , 'WINN-Forecast Purchase Requisition' as source   
from join_layer