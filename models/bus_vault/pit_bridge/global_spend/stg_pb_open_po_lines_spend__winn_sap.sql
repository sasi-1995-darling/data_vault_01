{{
    config(
        materialized='ephemeral'
    )
}}

with
hub_po_hdr as (
    select * from {{ ref('hub_po_header') }}
    where bkcc = 'Hiding_Tiger'
)

, sat_hdr_winn as (
    select * from {{ ref('sat_po_header__winn_sap') }}
    qualify MAX(load_dts) over (partition by po_header_hk) = load_dts
)

, hub_po_item as (
    select * from {{ ref('hub_po_item') }}
    where bkcc = 'Hiding_Tiger'
)

, sat_po_itm_sch_line_winn as (
    select * from {{ ref('sat_po_item_schedule_lines__winn_sap') }}
    qualify 1 = ROW_NUMBER() over (partition by po_item_hk, etenr order by load_dts desc)
)

, lnk_po_item as (
    select * from {{ ref('lnk_po_item') }}
    /* This filter is necessary to ensure only one record is kept per PO ITEM RECEIPT levelnk_po_item.
       However, the link's granularity is designed to track changes related to Legal Entity, Supplier etc.,*/
    qualify 1 = row_number() over(partition by po_item_hk order by load_dts desc, decode(supplier_hk, x'F4FC5C098ED311EC1BA49E8ABFE5A07A', 10, 1), decode(purchasing_org_hk, x'F4FC5C098ED311EC1BA49E8ABFE5A07A', 10, 1))
)

, hub_supplier as (
    select * from {{ ref('hub_supplier_v2') }}
    where bkcc = 'Hiding_Tiger'
)

, sat_supplier_winn as (
    select
        LTRIM(lifnr, '0') as drvd_lifnr
        , *
    from {{ ref('sat_supplier__winn_sap') }}
    qualify MAX(load_dts) over (partition by supplier_hk) = load_dts
)

, sat_line_winn as (
    select * from {{ ref('sat_po_item__winn_sap') }}
    qualify MAX(load_dts) over (partition by po_item_hk) = load_dts
)

, hub_purch_rec as (
    select * from {{ ref('hub_purchasing_record') }}
)

, sat_purch_rec as (
    select * from {{ ref('sat_purchasing_record__winn_sap') }}
    qualify MAX(load_dts) over (partition by purchasing_record_hk) = load_dts
)

, lnk_purch_rec_dtl as (
    select * from {{ ref('lnk_purchasing_record_details') }}
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
    select * from {{ ref('ref_item_sourcing_category_v2') }}
    where business_unit = 'WINN'
)

, curr_conv as (
    select * from {{ ref('ref_currency_conversion_fiscal_month_avg') }}
    where fp_fiscal_month = TO_CHAR(CURRENT_DATE, 'YYYYMM')
    qualify 1 = ROW_NUMBER() over (partition by fp_fiscal_month, fcurr, fiscal_month_avg_ukurs order by fp_date_dt desc)
)

--
select
    hub_po_item.po_header_id
    , hub_po_item.po_line_number
    , sat_po_itm_sch_line_winn.etenr as po_schedule_line_number
    , TRY_TO_DATE(sat_po_itm_sch_line_winn.eindt, 'YYYYMMDD') as schedule_line_delivery_date
    , sat_line_winn.menge as order_qty
    , sat_po_itm_sch_line_winn.wemng as received_qty
    , sat_line_winn.netpr
    , sat_line_winn.meins as po_item_uom
    , sat_line_winn.menge - sat_po_itm_sch_line_winn.wemng as volume
    , (((sat_line_winn.netpr / sat_line_winn.peinh) * volume) * COALESCE(curr_conv.fiscal_month_avg_ukurs, 1)) as spend
    , YEAR(schedule_line_delivery_date) as cal_year
    , MONTH(schedule_line_delivery_date) as cal_month
    , 'WINN' as business_unit
    , case when
            sat_hdr_winn.ekorg in ('MPFS', 'MXFS', 'NAFS', 'MPAC', 'AMCP', 'MINP', 'MCFG', 'MINT')
            then 'MOEN-NOAM'
        when sat_hdr_winn.ekorg in ('RIOP') then 'HOUSE OF ROHL'
        when sat_hdr_winn.ekorg in ('MGFP', 'MCHP', 'MHKP') then 'MOEN-CHINA'
        when sat_hdr_winn.ekorg in ('MPEX') then 'ALL OPCO - INDIRECT'
    end as drvd_opco

    , CONCAT_WS('|', COALESCE(drvd_opco, ''), COALESCE(sat_line_winn.matnr, '')) as opco_item

    , suplr_p.zzsupplierkey as supplier_number_parent
    , suplr_p.name1 as supplier_name_parent
    , suplr_c.lifnr as supplier_number_child
    , suplr_c.name1 as supplier_name_child

    , sat_line_winn.txz01 as item_description
    , sat_purch_rec.urzla as country_of_origin

    , TRY_TO_DATE(sat_hdr_winn.bedat, 'YYYYMMDD') as po_creation_date
    , case when sat_hdr_winn.loekz = 'L' then 'Y' when sat_hdr_winn.loekz = '' then 'N' end as po_header_del_ind
    , CAST(sat_hdr_winn.zbd1t as VARCHAR) as payment_terms
    , sat_hdr_winn.bsart as document_type

    , COALESCE(ref_ctg_src_winn.op_co, 'WINN') as opco_category
    , COALESCE(ref_ctg_src_winn.category_leader_name, 'REVIEW') as category_leader_name
    , COALESCE(ref_ctg_src_winn.director_name, 'REVIEW') as director_name
    , COALESCE(ref_ctg_src_winn.fbin_category_i, 'REVIEW') as fbin_category_i
    , COALESCE(ref_ctg_src_winn.fbin_category_ii, 'REVIEW') as fbin_category_ii
    , COALESCE(ref_ctg_src_winn.fbin_category_iii, 'REVIEW') as fbin_category_iii
    , sat_line_winn.matnr as item_bk
    , sat_line_winn.werks as plant_bk
    , sat_line_winn.bukrs as legal_entity_bk
    , sat_po_itm_sch_line_winn.eindt as schedule_line_delivery_date_bk
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
    , 'WINN-Forecast Open Orders' as source

from lnk_po_item
    inner join hub_po_item on lnk_po_item.po_item_hk = hub_po_item.po_item_hk
    inner join hub_po_hdr on lnk_po_item.po_header_hk = hub_po_hdr.po_header_hk
    inner join sat_hdr_winn on hub_po_hdr.po_header_hk = sat_hdr_winn.po_header_hk
    inner join sat_line_winn on hub_po_item.po_item_hk = sat_line_winn.po_item_hk
    inner join sat_po_itm_sch_line_winn on hub_po_item.po_item_hk = sat_po_itm_sch_line_winn.po_item_hk
    left join hub_purch_rec on lnk_po_item.purchasing_record_hk = hub_purch_rec.purchasing_record_hk
    left join sat_purch_rec on hub_purch_rec.purchasing_record_hk = sat_purch_rec.purchasing_record_hk
    left join
        ref_ctg_src_winn
        on sat_line_winn.matnr = ref_ctg_src_winn.item and drvd_opco = ref_ctg_src_winn.op_co
    left join final_lsat_purch_rec_dtl
        on lnk_po_item.purchasing_record_hk = final_lsat_purch_rec_dtl.purchasing_record_hk
            and lnk_po_item.purchasing_org_hk = final_lsat_purch_rec_dtl.purchasing_org_hk
            -- this join is at the level of infnr, ekorg, and werks and this is the First attempt with WERKS
            and sat_line_winn.werks = final_lsat_purch_rec_dtl.werks -- this will be changed to plant_hk when its mapped

    left join final_fallback_lsat_purch_rec_dtl
        on lnk_po_item.purchasing_record_hk = final_fallback_lsat_purch_rec_dtl.purchasing_record_hk
            and lnk_po_item.purchasing_org_hk = final_fallback_lsat_purch_rec_dtl.purchasing_org_hk
            and final_lsat_purch_rec_dtl.infnr is null -- Only use fallback if no match in first join
    left join hub_supplier on lnk_po_item.supplier_hk = hub_supplier.supplier_hk
    left join sat_supplier_winn as suplr_c on hub_supplier.supplier_hk = suplr_c.supplier_hk
    left join sat_supplier_winn as suplr_p on suplr_c.zzsupplierkey = suplr_p.drvd_lifnr
    left join curr_conv on curr_conv.fcurr = COALESCE(sat_hdr_winn.waers, '')
where COALESCE(sat_line_winn.elikz, '') <> 'X'
    and sat_line_winn.netpr > 0
    and not COALESCE(sat_line_winn.loekz, '') in ('L', 'X', 'S')
    and sat_hdr_winn.bsart = 'NB'
