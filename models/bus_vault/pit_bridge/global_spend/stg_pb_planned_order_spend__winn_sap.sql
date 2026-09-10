{{
    config(
        materialized='ephemeral'
    )
}}

with
l as (
    select
        planned_order_hk,
        supplier_hk,
        item_hk,
        plant_hk,
        purchasing_org_hk,
        purchasing_record_hk,
        rec_src,
        load_dts
    from {{ ref('lnk_planned_order') }}
    where rec_src <> 'USAZET.SNOWFLAKE.FBIN.DERIVED'   /* This filter is to exclude the ghost records */
    /* This filter is necessary to ensure only one record is kept per Planned Order level.
     However, the link's granularity is designed to track changes related to Item, Plant,Supplier etc.,*/
    qualify MAX(load_dts) over (partition by planned_order_hk) = load_dts
)

, hub_pln_ordr as (
    select
        planned_order_hk,
        planned_order_bk,
        bkcc
    from {{ ref('hub_planned_order') }}
)

, sat_pln_ordr as (
    select
        planned_order_hk,
        pedtr,
        gsmng,
        ekorg,
        matnr,
        paart,
        obart,
        psa_delete_ind,
        flief,
        plwrk,
        load_dts
    from {{ ref('sat_planned_order__winn_sap') }}
    qualify MAX(load_dts) over (partition by planned_order_hk) = load_dts
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
        meins,
        umrez,
        umren,
        lmein,
        urzla,
        load_dts
    from {{ ref('sat_purchasing_record__winn_sap') }}
    qualify MAX(load_dts) over (partition by purchasing_record_hk) = load_dts
)

, lsat_srt as (
    select
        purchasing_record_details_hk,
        loekz,
        netpr,
        peinh,
        waers,
        erdat,
        esokz,
        load_dts,
        IFF(loekz in ('L', 'X', 'S'), 'Y', 'N') as eine_del_ind,
        infnr,
        ekorg,
        werks
    from {{ ref('lsat_purchasing_record_details__winn_sap') }}
    where netpr > 0
    qualify MAX(load_dts) over (partition by purchasing_record_details_hk) = load_dts
)

, lnk_lsat_purch_rec_dtl as (
    select
        lnk.purchasing_org_hk,
        lnk.purchasing_record_hk,
        lnk.plant_hk,
        case
            when lsat_srt.esokz = '2' then 1
            when lsat_srt.esokz = '0' then 2
            else 3
        end as esokz_priority,
        lsat_srt.*
    from {{ ref('lnk_purchasing_record_details') }} as lnk
        inner join lsat_srt
            on lnk.purchasing_record_details_hk = lsat_srt.purchasing_record_details_hk
    where lsat_srt.eine_del_ind = 'N'
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

, hub_supplier as (
    select
        supplier_hk
    from {{ ref('hub_supplier_v2') }}
    where bkcc = 'Hiding_Tiger'
)
, sat_supplier_winn as (
    select
        supplier_hk,
        zzsupplierkey,
        name1,
        load_dts,
        LTRIM(lifnr, '0') as drvd_lifnr,
        lifnr
    from {{ ref('sat_supplier__winn_sap') }}
    qualify MAX(load_dts) over (partition by supplier_hk) = load_dts
)

, ref_ctg_src_winn as (
    select
        item,
        op_co,
        category_leader_name,
        director_name,
        fbin_category_i,
        fbin_category_ii,
        fbin_category_iii
    from {{ ref('ref_item_sourcing_category_v2') }}
    where business_unit = 'WINN'
)

, curr_conv as (
    select
        fcurr,
        fiscal_month_avg_ukurs,
        fp_date_dt,
        fp_fiscal_month
    from {{ ref('ref_currency_conversion_fiscal_month_avg') }}
    where fp_fiscal_month = TO_CHAR(CURRENT_DATE, 'YYYYMM')
    qualify 1 = ROW_NUMBER() over (partition by fp_fiscal_month, fcurr, fiscal_month_avg_ukurs order by fp_date_dt desc)
)


--
, join_layer as (
    select
        hub_pln_ordr.planned_order_bk
        , TRY_TO_DATE(sat_pln_ordr.pedtr, 'YYYYMMDD') as planned_order_finish_date
        , sat_pln_ordr.gsmng as volume
        , sat_purch_rec.meins as uom
        , sat_purch_rec.umrez as uom_n
        , sat_purch_rec.umren as uom_d
        , sat_purch_rec.lmein as base_uom
        , COALESCE(final_lsat_purch_rec_dtl.netpr, final_fallback_lsat_purch_rec_dtl.netpr) as net_price
        , COALESCE(final_lsat_purch_rec_dtl.peinh, final_fallback_lsat_purch_rec_dtl.peinh) as price_per_unit
        , (
            (net_price / price_per_unit)
            * (sat_purch_rec.umren * (sat_pln_ordr.gsmng / sat_purch_rec.umrez))
            * COALESCE(curr_conv.fiscal_month_avg_ukurs, 1)
        ) as spend
        , case when
                sat_pln_ordr.ekorg in ('MPFS', 'MXFS', 'NAFS', 'MPAC', 'AMCP', 'MINP', 'MCFG', 'MINT')
                then 'MOEN-NOAM'
            when sat_pln_ordr.ekorg in ('RIOP') then 'HOUSE OF ROHL'
            when sat_pln_ordr.ekorg in ('MGFP', 'MCHP', 'MHKP') then 'MOEN-CHINA'
            when sat_pln_ordr.ekorg in ('MPEX') then 'ALL OPCO - INDIRECT'
        end as op_co_moen_drvd
        , CONCAT_WS('|', COALESCE(op_co_moen_drvd, ''), COALESCE(sat_pln_ordr.matnr, '')) as opco_item
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
        -- Payment Terms TBD
        , sat_pln_ordr.paart as document_type

        -- BK
        , sat_pln_ordr.flief as supplier_bk
        , sat_pln_ordr.matnr as item_bk
        , sat_pln_ordr.plwrk as plant_bk
        , sat_pln_ordr.pedtr as planned_order_finish_date_bk
        --HK
        , l.planned_order_hk
        , l.supplier_hk
        , l.item_hk
        , l.plant_hk
        , l.purchasing_org_hk
        , l.purchasing_record_hk
        , l.rec_src
        , hub_pln_ordr.bkcc
    from l
        inner join hub_pln_ordr on l.planned_order_hk = hub_pln_ordr.planned_order_hk
        inner join sat_pln_ordr on hub_pln_ordr.planned_order_hk = sat_pln_ordr.planned_order_hk
        left join hub_purch_rec on l.purchasing_record_hk = hub_purch_rec.purchasing_record_hk
        left join sat_purch_rec on hub_purch_rec.purchasing_record_hk = sat_purch_rec.purchasing_record_hk
        left join
            ref_ctg_src_winn
            on sat_pln_ordr.matnr = ref_ctg_src_winn.item and op_co_moen_drvd = ref_ctg_src_winn.op_co

        left join final_lsat_purch_rec_dtl
            on l.purchasing_record_hk = final_lsat_purch_rec_dtl.purchasing_record_hk
                and l.purchasing_org_hk = final_lsat_purch_rec_dtl.purchasing_org_hk
                /* this join is at the level of infnr, ekorg, and werks and this is the First attempt with WERKS */
                and l.plant_hk = final_lsat_purch_rec_dtl.plant_hk

        left join final_fallback_lsat_purch_rec_dtl
            on l.purchasing_record_hk = final_fallback_lsat_purch_rec_dtl.purchasing_record_hk
                and l.purchasing_org_hk = final_fallback_lsat_purch_rec_dtl.purchasing_org_hk
                and final_lsat_purch_rec_dtl.infnr is null /*  Only use fallback if no match in first join */
        left join
            curr_conv
            on curr_conv.fcurr = COALESCE(final_lsat_purch_rec_dtl.waers, final_fallback_lsat_purch_rec_dtl.waers)
        left join hub_supplier on l.supplier_hk = hub_supplier.supplier_hk
        left join sat_supplier_winn as suplr_c on hub_supplier.supplier_hk = suplr_c.supplier_hk
        left join sat_supplier_winn as suplr_p on suplr_c.zzsupplierkey = suplr_p.drvd_lifnr

    where
        sat_pln_ordr.paart = 'NB' /* Filter - purchasing Planned Orders */
        and sat_pln_ordr.obart = 1 /* 1= planned orders */
        and sat_pln_ordr.psa_delete_ind = 'N'
        and LEFT(sat_pln_ordr.pedtr, 6) between TO_CHAR(CURRENT_DATE, 'YYYYMM') and TO_CHAR(
            DATEADD(month, 18, CURRENT_DATE()), 'YYYYMM'
        )  /* order finished date  */
)

--FINAL LAYER 

select
    planned_order_bk
    , planned_order_finish_date
    , YEAR(planned_order_finish_date) as cal_year
    , MONTH(planned_order_finish_date) as cal_month
    , volume
    , uom
    , uom_n
    , uom_d
    , base_uom
    , net_price
    , price_per_unit
    , spend
    , op_co_moen_drvd as drvd_opco
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
    , document_type
    , supplier_bk
    , planned_order_hk
    , item_bk
    , plant_bk
    , planned_order_finish_date_bk
    , supplier_hk
    , item_hk
    , plant_hk
    , purchasing_org_hk
    , purchasing_record_hk
    , rec_src
    , bkcc
    , 'WINN-Forecast Planned Orders' as source
    , 'WINN' as business_unit
from join_layer
