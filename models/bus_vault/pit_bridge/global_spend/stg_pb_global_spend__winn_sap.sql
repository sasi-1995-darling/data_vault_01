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
    where rec_src <> 'USAZET.SNOWFLAKE.FBIN.DERIVED'   /* This filter is to exclude the ghost records */
    /* This filter is necessary to ensure only one record is kept per PO ITEM RECEIPT level.
     However, the link's granularity is designed to track changes related to Legal Entity, Supplier etc.,*/
    qualify MAX(load_dts) over (partition by po_item_receipt_dk) = load_dts
)

, sat_rcpt_winn as (
    select
        lnk_po_receipt_hk,
        bewtp,
        load_dts,
        ebeln,
        ebelp,
        belnr,
        buzei,
        budat,
        menge,
        shkzg,
        wrbtr,
        elikz,
        matnr,
        lsmeh,
        dmbtr,
        hswae,
        bkcc,
        werks
    from {{ ref('lsat_po_receipt__winn_sap') }}
    where bewtp in ('E', 'Q')
    qualify MAX(load_dts) over (partition by LNK_PO_RECEIPT_HK, bewtp) = load_dts
)

, hub_po_hdr as (
    select
        po_header_hk,
        bkcc
    from {{ ref('hub_po_header') }}
    where bkcc = 'Hiding_Tiger'
)

, sat_hdr_winn as (
    select
        po_header_hk,
        load_dts,
        bedat,
        loekz,
        ekgrp,
        zbd1t,
        bsart,
        bukrs,
        lifnr,
        ekorg,
        zterm,
        waers
    from {{ ref('sat_po_header__winn_sap') }}
    where bsart = 'NB'
    qualify MAX(load_dts) over (partition by po_header_hk) = load_dts
)

, hub_po_item as (
    select
        po_item_hk,
        bkcc
    from {{ ref('hub_po_item') }}
    where bkcc = 'Hiding_Tiger'
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
    qualify 1 = row_number() over(partition by po_item_hk order by load_dts desc, decode(supplier_hk, x'F4FC5C098ED311EC1BA49E8ABFE5A07A', 10, 1), decode(purchasing_org_hk, x'F4FC5C098ED311EC1BA49E8ABFE5A07A', 10, 1))
)

, hub_supplier as (
    select
        supplier_hk,
        bkcc
    from {{ ref('hub_supplier_v2') }}
    where bkcc = 'Hiding_Tiger'
)

, sat_supplier_winn as (
    select
        supplier_hk,
        load_dts,
        zzsupplierkey,
        name1,
        LTRIM(lifnr, '0') as drvd_lifnr,
        lifnr
    from {{ ref('sat_supplier__winn_sap') }}
    qualify MAX(load_dts) over (partition by supplier_hk) = load_dts
)

, sat_line_winn as (
    select
        po_item_hk,
        load_dts,
        netwr,        
        menge,
        pstyp,
        werks,
        elikz,
        matnr,
        meins
    from {{ ref('sat_po_item__winn_sap') }}
    qualify MAX(load_dts) over (partition by po_item_hk) = load_dts
)

, hub_purch_org as (
    select
        purchasing_org_hk,
        purchasing_org_bk,
        bkcc
    from {{ ref('hub_purchasing_org_v2') }}
)

, hub_purch_rec as (
    select
        purchasing_record_hk,
		purchasing_record_bk,
        bkcc
    from {{ ref('hub_purchasing_record') }}
)

, sat_purch_rec as (
    select
        purchasing_record_hk,
        load_dts,
        urzla
    from {{ ref('sat_purchasing_record__winn_sap') }}
    qualify MAX(load_dts) over (partition by purchasing_record_hk) = load_dts
)

, lnk_purch_rec_dtl as (
    select *
    from {{ ref('lnk_purchasing_record_details') }}
)

, lsat_srt as (
    select
        *
        , IFF(loekz in ('L', 'X', 'S'), 'Y', 'N') as eine_del_ind
    from {{ ref('lsat_purchasing_record_details__winn_sap') }}
    qualify MAX(load_dts) over (partition by purchasing_record_details_hk) = load_dts
)

, lnk_lsat_purch_rec_dtl as (
    select
        lnk.purchasing_org_hk
        , lnk.purchasing_record_hk
        , lnk.plant_hk
        , lsat_srt.*
        , COUNT(*) over (partition by infnr, ekorg) as count_pr_po
        , COUNT(*) over (partition by infnr, ekorg, werks) as count_pr_po_werks
        , case
            when esokz = '2' then 1
            when esokz = '0' then 2
            else 3
        end as esokz_priority
    from lsat_srt
        inner join {{ ref('lnk_purchasing_record_details') }} as lnk
            on lsat_srt.purchasing_record_details_hk = lnk.purchasing_record_details_hk
    where eine_del_ind = 'N'
)

, final_lsat_purch_rec_dtl as (
    select *
    from lnk_lsat_purch_rec_dtl
    qualify ROW_NUMBER() over (partition by infnr, ekorg, werks order by esokz_priority, erdat) = 1
)

, final_fallback_lsat_purch_rec_dtl as (
    select *
    from lnk_lsat_purch_rec_dtl
    qualify ROW_NUMBER() over (partition by infnr, ekorg order by esokz_priority, erdat) = 1
)

, ref_ctg_src_winn as (
    select
        item,
        op_co,
        category_leader_name,
        director_name,
        fbin_category_i,
        fbin_category_ii,
        fbin_category_iii,
        business_unit
    from {{ ref('ref_item_sourcing_category_v2') }}
    where business_unit = 'WINN'
)

, curr_conv as (
    select
        fcurr,
        fp_date_dt,
        fiscal_month_avg_ukurs
    from {{ ref('ref_currency_conversion_fiscal_month_avg') }}
)

--
, join_layer as (
    select
        sat_rcpt_winn.ebeln as po_header_id
        , sat_rcpt_winn.ebelp as po_line_number
        , sat_rcpt_winn.belnr as material_document_number
        , sat_rcpt_winn.buzei as material_document_item
        , TRY_TO_DATE(sat_hdr_winn.bedat, 'YYYYMMDD') as po_creation_date
        , case when sat_hdr_winn.loekz = 'L' then 'Y' when sat_hdr_winn.loekz = '' then 'N' end as po_header_del_ind
        , sat_hdr_winn.ekgrp as hdr_buyer_code
        , sat_rcpt_winn.bewtp
        , TRY_TO_DATE(sat_rcpt_winn.budat, 'YYYYMMDD') as budat
        , sat_line_winn.menge as order_qty
        , sat_line_winn.netwr as net_order_value
        , case when sat_line_winn.menge = 0 then 0 
               else sat_line_winn.netwr/sat_line_winn.menge 
              end  as order_unit_price
        , case
            when sat_line_winn.pstyp = '2' then 'Y'
            when sat_line_winn.werks = 'S100' then 'Y'
            else 'N'
        end as consignment_ind
        , case when sat_rcpt_winn.bewtp = 'E' and sat_rcpt_winn.shkzg = 'H' then 0 - sat_rcpt_winn.menge
            when sat_rcpt_winn.bewtp = 'E' and sat_rcpt_winn.shkzg <> 'H' then sat_rcpt_winn.menge else 0
        end as receipt_qty
        , case when sat_rcpt_winn.bewtp = 'E' and sat_rcpt_winn.shkzg = 'H' then 0 - sat_rcpt_winn.wrbtr
            when sat_rcpt_winn.bewtp = 'E' and sat_rcpt_winn.shkzg <> 'H' then sat_rcpt_winn.wrbtr else 0
        end as receipt_spend
        , case when sat_rcpt_winn.bewtp = 'E' and sat_rcpt_winn.shkzg = 'H' then 0 - sat_rcpt_winn.dmbtr
            when sat_rcpt_winn.bewtp = 'E' and sat_rcpt_winn.shkzg <> 'H' then sat_rcpt_winn.dmbtr else 0
        end as pre_spend_amount_local_currency 
        , case when sat_rcpt_winn.bewtp = 'Q' and sat_rcpt_winn.shkzg = 'H' then 0 - sat_rcpt_winn.menge
            when sat_rcpt_winn.bewtp = 'Q' and sat_rcpt_winn.shkzg <> 'H' then sat_rcpt_winn.menge else 0
        end as invoice_qty
        , case when sat_rcpt_winn.bewtp = 'Q' and sat_rcpt_winn.shkzg = 'H' then 0 - sat_rcpt_winn.wrbtr
            when sat_rcpt_winn.bewtp = 'Q' and sat_rcpt_winn.shkzg <> 'H' then sat_rcpt_winn.wrbtr else 0
        end as invoice_spend

        , sat_line_winn.elikz as po_line_elikz
        , sat_rcpt_winn.elikz
        , sat_line_winn.matnr
        , sat_hdr_winn.zterm as payment_terms
        , sat_hdr_winn.bsart as document_type
        , case when
                sat_hdr_winn.ekorg in ('MPFS', 'MXFS', 'NAFS', 'MPAC', 'AMCP', 'MINP', 'MCFG', 'MINT')
                then 'MOEN-NOAM'
            when sat_hdr_winn.ekorg in ('RIOP') then 'HOUSE OF ROHL'
            when sat_hdr_winn.ekorg in ('MGFP', 'MCHP', 'MHKP') then 'MOEN-CHINA'
            when sat_hdr_winn.ekorg in ('MPEX') then 'ALL OPCO - INDIRECT'
        end as op_co_moen_drvd
        , sat_purch_rec.urzla as country_of_origin
        , COALESCE(ref_ctg_src_winn.op_co, 'WINN') as opco_category
        , COALESCE(ref_ctg_src_winn.category_leader_name, 'REVIEW') as category_leader_name
        , COALESCE(ref_ctg_src_winn.director_name, 'REVIEW') as director_name
        , COALESCE(ref_ctg_src_winn.fbin_category_i, 'REVIEW') as fbin_category_i
        , COALESCE(ref_ctg_src_winn.fbin_category_ii, 'REVIEW') as fbin_category_ii
        , COALESCE(ref_ctg_src_winn.fbin_category_iii, 'REVIEW') as fbin_category_iii
        , sat_line_winn.meins as po_item_uom
        , sat_rcpt_winn.lsmeh as po_receipt_uom
        , sat_rcpt_winn.dmbtr as receipt_value_local
        , sat_rcpt_winn.hswae as local_currency
        , COALESCE(final_lsat_purch_rec_dtl.infnr, final_fallback_lsat_purch_rec_dtl.infnr) as infnr
        , COALESCE(final_lsat_purch_rec_dtl.ekorg, final_fallback_lsat_purch_rec_dtl.ekorg) as ekorg
        , COALESCE(final_lsat_purch_rec_dtl.werks, final_fallback_lsat_purch_rec_dtl.werks) as werks
        , COALESCE(final_lsat_purch_rec_dtl.esokz, final_fallback_lsat_purch_rec_dtl.esokz) as esokz
        , COALESCE(final_lsat_purch_rec_dtl.netpr, final_fallback_lsat_purch_rec_dtl.netpr) as net_price
        , COALESCE(final_lsat_purch_rec_dtl.peinh, final_fallback_lsat_purch_rec_dtl.peinh) as price_per_unit
        , COALESCE(final_lsat_purch_rec_dtl.bprme, final_fallback_lsat_purch_rec_dtl.bprme) as order_price_unit
        , COALESCE(final_lsat_purch_rec_dtl.bpumz, final_fallback_lsat_purch_rec_dtl.bpumz)
            as conversion_price_uom_to_order_uom_n
        , COALESCE(final_lsat_purch_rec_dtl.bpumn, final_fallback_lsat_purch_rec_dtl.bpumn)
            as conversion_price_uom_to_order_uom_d
        , case when sat_rcpt_winn.hswae <> 'USD' then curr_conv.fiscal_month_avg_ukurs end as usd_conversion_rate

        , suplr_p.zzsupplierkey as supplier_number_parent
        , suplr_p.name1 as supplier_name_parent
        , suplr_c.lifnr as supplier_number_child
        , suplr_c.name1 as supplier_name_child
        -- BK
        , hub_purch_org.purchasing_org_bk as purchasing_org_bk
		, hub_purch_rec.purchasing_record_bk
        , sat_hdr_winn.lifnr as supplier_bk
        , sat_rcpt_winn.matnr as item_bk
        , sat_rcpt_winn.werks as plant_bk
        , sat_hdr_winn.bukrs as legal_entity_bk
        --HK
        , l.po_header_hk
        , l.po_item_hk
        , l.item_hk
        , l.supplier_hk
        , l.plant_hk
        , l.legal_entity_hk
        , lnk_po_item.purchasing_record_hk
        , lnk_po_item.purchasing_org_hk
        , l.rec_src
        , sat_rcpt_winn.bkcc
        , sat_hdr_winn.waers AS po_currency
        , case when sat_hdr_winn.waers <> 'USD' then po_item_curr_conv.fiscal_month_avg_ukurs end as po_item_usd_conversion_rate
       
    from l
        inner join sat_rcpt_winn on l.lnk_po_receipt_hk = sat_rcpt_winn.lnk_po_receipt_hk
        inner join hub_po_item using (po_item_hk)
        inner join lnk_po_item on hub_po_item.po_item_hk = lnk_po_item.po_item_hk
        inner join hub_po_hdr on l.po_header_hk = hub_po_hdr.po_header_hk
        inner join sat_hdr_winn on hub_po_hdr.po_header_hk = sat_hdr_winn.po_header_hk
        left join sat_line_winn on hub_po_item.po_item_hk = sat_line_winn.po_item_hk
        left join hub_purch_org on lnk_po_item.purchasing_org_hk = hub_purch_org.purchasing_org_hk
        left join hub_purch_rec on lnk_po_item.purchasing_record_hk = hub_purch_rec.purchasing_record_hk
        left join sat_purch_rec on hub_purch_rec.purchasing_record_hk = sat_purch_rec.purchasing_record_hk
        left join
            ref_ctg_src_winn
            on sat_line_winn.matnr = ref_ctg_src_winn.item and op_co_moen_drvd = ref_ctg_src_winn.op_co
        left join
             curr_conv
             on TRY_TO_DATE(sat_rcpt_winn.budat, 'YYYYMMDD') = curr_conv.fp_date_dt
                 and sat_rcpt_winn.hswae = curr_conv.fcurr
        left join
            curr_conv po_item_curr_conv
            on TRY_TO_DATE(sat_rcpt_winn.budat, 'YYYYMMDD') = po_item_curr_conv.fp_date_dt
                and sat_hdr_winn.waers = po_item_curr_conv.fcurr
        left join final_lsat_purch_rec_dtl
            on lnk_po_item.purchasing_record_hk = final_lsat_purch_rec_dtl.purchasing_record_hk
                and lnk_po_item.purchasing_org_hk = final_lsat_purch_rec_dtl.purchasing_org_hk
                -- this join is at the level of infnr, ekorg, and werks and this is the First attempt with WERKS
                and l.plant_hk = final_lsat_purch_rec_dtl.plant_hk

        left join final_fallback_lsat_purch_rec_dtl
            on lnk_po_item.purchasing_record_hk = final_fallback_lsat_purch_rec_dtl.purchasing_record_hk
                and lnk_po_item.purchasing_org_hk = final_fallback_lsat_purch_rec_dtl.purchasing_org_hk
                and final_lsat_purch_rec_dtl.infnr is null -- Only use fallback if no match in first join
        left join hub_supplier on l.supplier_hk = hub_supplier.supplier_hk
        left join sat_supplier_winn as suplr_c on hub_supplier.supplier_hk = suplr_c.supplier_hk
        left join sat_supplier_winn as suplr_p on suplr_c.zzsupplierkey = suplr_p.drvd_lifnr
    where bewtp in ('E', 'Q')
)

--FINAL LAYER

select
    po_header_id
    , po_line_number
    , material_document_number
    , material_document_item
    , po_header_del_ind
    , po_creation_date
    , budat as posting_date
    , YEAR(budat) as cal_year
    , MONTH(budat) as cal_month
    , supplier_number_parent
    , supplier_name_parent
    , supplier_number_child
    , supplier_name_child
    , payment_terms
    , document_type
    , supplier_bk
    , item_bk
    , plant_bk
    , legal_entity_bk
    , country_of_origin
    , op_co_moen_drvd as drvd_opco
    , hdr_buyer_code
    , order_qty
    , COALESCE(SUM(receipt_qty) over (partition by po_header_id, po_line_number order by po_creation_date), 0)
        as total_rcpt_qty
    , COALESCE(SUM(receipt_spend) over (partition by po_header_id, po_line_number order by po_creation_date), 0)
        as total_rcpt_spend
    , COALESCE(SUM(invoice_qty) over (partition by po_header_id, po_line_number order by po_creation_date), 0)
        as total_inv_qty
    , COALESCE(SUM(invoice_spend) over (partition by po_header_id, po_line_number order by po_creation_date), 0)
        as total_inv_spend
    , receipt_qty
    , receipt_spend
    /* Added the below if condition to populate avg_inv_price if it has an actual invoice tied to it */
    , IFF(po_line_elikz = 'X' , CAST(total_inv_spend / NULLIF(total_inv_qty, 0) as NUMBER(10, 2)), 0) as avg_inv_price
    , receipt_qty as spend_volume
    , po_item_uom
    , order_unit_price
    , CAST(IFF(
       po_currency  = 'USD', order_unit_price, po_item_usd_conversion_rate * order_unit_price
    ) as NUMBER(32, 2)) as ORDER_UNIT_PRICE_USD
    , po_receipt_uom
    , CAST((case when consignment_ind <> 'Y' and po_line_elikz <> 'X' then pre_spend_amount_local_currency
        when consignment_ind <> 'Y' and po_line_elikz = 'X' and total_inv_qty > 0 then (receipt_qty * avg_inv_price)
        when consignment_ind <> 'Y' and po_line_elikz = 'X' and total_inv_qty = 0 then pre_spend_amount_local_currency
        when
            consignment_ind = 'Y'
            then (net_price / NULLIF(price_per_unit, 0))
                * (conversion_price_uom_to_order_uom_n / NULLIF(conversion_price_uom_to_order_uom_d, 0))
                * receipt_qty
    end) as NUMBER(32, 2)) as spend_amount_local_currency
    , po_line_elikz
    , local_currency
    , po_currency
    , CAST(IFF(
        local_currency = 'USD', spend_amount_local_currency, usd_conversion_rate * spend_amount_local_currency
    ) as NUMBER(32, 2)) as spend_usd
    , opco_category
    , director_name
    , category_leader_name
    , fbin_category_i
    , fbin_category_ii
    , fbin_category_iii
    , consignment_ind
    , purchasing_org_bk
	, purchasing_record_bk
    , po_header_hk
    , po_item_hk
    , item_hk
    , supplier_hk
    , plant_hk
    , legal_entity_hk
    , purchasing_record_hk
    , purchasing_org_hk
    , rec_src
    , bkcc
    , 'WINN' as business_unit
from join_layer
-- The Below qualify clause is to act as summary filter
qualify bewtp = 'E'
