{{
    config(
        materialized='incremental',
        unique_key='row_id'
    )
}}

with cte_lsat_copa_sales__winn_sap as (
    select
        lnk_copa_sales_hk
        , budat_dt
        , vtweg
        , budat
        , wwstp
        , vvgrs
        , wwrsn
        , vvfrm
        , vvfrc
        , vvfra
        , vvvpp
        , vvrst
        , vvhdl
        , vvmin
        , vvces
        , vvacq
        , vvqty
        , vkorg
        , wwknu
        , kaufn
        , vrgar
        , rbeln
        , zzorc
        , perio
        , artnr 
        , skost
        , kstar
        , bukrs 
        , vvcst
        , vvgbp
        , augru
        , gjahr
        , pstyv
        , auart
        , load_dts
    from {{ ref('lsat_copa_sales__winn_sap') }}

    {% if is_incremental() %}
    -- Only get new/updated records
    where load_dts >= (select max(load_date) from {{ this }})
    {% endif %}

    qualify 1 = row_number() over (
        partition by lnk_copa_sales_hk
        order by load_dts desc
    )
)

, cte_pb_customer_sales_attributes as (
    select
        customer_sales_attributes_key
        , customer_hk
        , customer_bk
        , sales_organization_hk
        , distribution_channel_hk
        , division_hk
        , customer
        , account_number
        , account_name
    from {{ ref('pb_customer_sales_attributes') }}
    where bkcc = 'Hiding_Tiger'
)

, cte_pit_order_header as (
    select
        sales_order_header_hk
        , customer_purchase_order_type
    from {{ ref('pit_order_header') }}
    where bkcc = 'Hiding_Tiger'
        and sales_order_number is not null
)

, cte_sat_item_master__moen_sap_v1 as (
    select
        item_hk
        , base_material
        , load_dts
    from {{ ref('sat_item_master__moen_sap_v1') }}
    qualify 1 = row_number() over (partition by item_hk order by load_dts desc)
)


, cte_join_base as (
    select
        lnkcopa.lnk_copa_sales_hk
        , hbcopa.copa_hk
        , hbcust.customer_hk
        , hbitm.item_hk
        , satitm.base_material
        , hbitm.bkcc as hbitm_bkcc
        , hbitm.item_bk
        , pbcsat.customer
        , hbcust.customer_bk
        , pbcsat.account_number
        , pbcsat.account_name
        , hbslo.sales_organization_bk
        , hbdst.distribution_channel_bk
        , ptodh.customer_purchase_order_type
        , hbordh.order_header_hk
        , hbordh.order_header_bk
        , hbordl.order_line_hk
        , hbordl.order_line_bk
        , hbslo.sales_organization_hk
        , hbdst.distribution_channel_hk
        , hbdiv.division_hk
        , hbdiv.division_bk
        , hbplt.plant_hk
        , hbplt.plant_bk
        , hbconta.controlling_area_hk
        , hbconta.controlling_area_bk
        , hbcstc.cost_center_hk
        , hbcstc.cost_center_bk
        , hbcste.cost_element_hk
        , hbcste.cost_element_bk
        , hbcrrt.currency_type_hk
        , hbcrrt.currency_type_bk
        , pbcsat.customer_sales_attributes_key
        , lnkcopa.rec_src
        , hbcopa.bkcc

    from {{ ref('lnk_copa_sales') }} as lnkcopa
        inner join {{ ref('hub_copa') }} as hbcopa
            on lnkcopa.copa_hk = hbcopa.copa_hk
        inner join {{ ref('hub_controlling_area') }} as hbconta
            on lnkcopa.controlling_area_hk = hbconta.controlling_area_hk
        inner join {{ ref('hub_cost_center') }} as hbcstc
            on lnkcopa.cost_center_hk = hbcstc.cost_center_hk
        inner join {{ ref('hub_cost_element') }} as hbcste
            on lnkcopa.cost_element_hk = hbcste.cost_element_hk
        inner join {{ ref('hub_currency_type') }} as hbcrrt
            on lnkcopa.currency_type_hk = hbcrrt.currency_type_hk
        inner join {{ ref('hub_order_header') }} as hbordh
            on lnkcopa.order_header_hk = hbordh.order_header_hk
        inner join {{ ref('hub_order_line') }} as hbordl
            on lnkcopa.order_line_hk = hbordl.order_line_hk
        inner join {{ ref('hub_customer_v1') }} as hbcust
            on lnkcopa.customer_hk = hbcust.customer_hk
        inner join {{ ref('hub_sales_organization') }} as hbslo
            on lnkcopa.sales_organization_hk = hbslo.sales_organization_hk
        inner join {{ ref('hub_distribution_channel') }} as hbdst
            on lnkcopa.distribution_channel_hk = hbdst.distribution_channel_hk
        inner join {{ ref('hub_division') }} as hbdiv
            on lnkcopa.division_hk = hbdiv.division_hk
        inner join {{ ref('hub_item_v1') }} as hbitm
            on lnkcopa.item_hk = hbitm.item_hk
        inner join {{ ref('hub_plant_v1') }} as hbplt
            on lnkcopa.plant_hk = hbplt.plant_hk
        left join cte_sat_item_master__moen_sap_v1 as satitm
            on hbitm.item_hk = satitm.item_hk
        left join cte_pb_customer_sales_attributes as pbcsat
            on hbcust.customer_hk = pbcsat.customer_hk
                and hbslo.sales_organization_hk = pbcsat.sales_organization_hk
                and hbdst.distribution_channel_hk = pbcsat.distribution_channel_hk
                and hbdiv.division_hk = pbcsat.division_hk
        left join cte_pit_order_header as ptodh
            on hbordh.order_header_hk = ptodh.sales_order_header_hk
)

, base as (
    select
        cte_join_base.*
        , lsatcopa.budat_dt
        , lsatcopa.wwstp
        , lsatcopa.vvgrs
        , lsatcopa.wwrsn
        , lsatcopa.vvfrm
        , lsatcopa.vvfrc
        , lsatcopa.vvfra
        , lsatcopa.vvvpp
        , lsatcopa.vvrst
        , lsatcopa.vvhdl
        , lsatcopa.vvmin
        , lsatcopa.vvces
        , lsatcopa.vvacq
        , lsatcopa.vvqty
        , lsatcopa.rbeln
        , lsatcopa.kaufn
        , lsatcopa.wwknu
        , lsatcopa.zzorc
        , lsatcopa.vrgar
        , lsatcopa.perio
        , lsatcopa.artnr 
        , lsatcopa.skost
        , lsatcopa.kstar
        , lsatcopa.bukrs
        , lsatcopa.vvcst
        , lsatcopa.vvgbp
        , lsatcopa.augru
        , lsatcopa.gjahr
        , lsatcopa.pstyv
        , lsatcopa.auart
    from cte_join_base
        inner join cte_lsat_copa_sales__winn_sap as lsatcopa
            on cte_join_base.lnk_copa_sales_hk = lsatcopa.lnk_copa_sales_hk
    --cut off data for transition of ROHS shipments data to WINN SAP ERP reporting
    where (lsatcopa.vkorg = 'ROHS' and lsatcopa.budat_dt >= '2023-07-02')
        or lsatcopa.vkorg <> 'ROHS'
)

, cte_logic_base as (
    select
        lnk_copa_sales_hk as shipment_hk
        , customer_hk
        , item_hk as item_id
        , md5_binary(nullif(concat_ws(
            '||'
            , coalesce(nullif(upper(trim(base_material::varchar)), ''), '^^')
            , coalesce(nullif(upper(trim((hbitm_bkcc)::varchar)), ''), '^^')
        ), '^^||^^')) as base_material_id
        , item_bk as item_number
        , base_material
        , customer
        , to_char(customer_bk) as customer_id
        , account_number as key_account_number
        , account_name as customer_account_name
        , sales_organization_bk as sales_org
        , distribution_channel_bk as channel
        , budat_dt as date_posted
        , null as location_id
        , case when item_bk in ('CQCLAIM', 'CSCLAIM', 'FSDAMAGE', 'FSLABOR')
                then 0
            when wwstp in ('SAL', 'NCH', 'PRM', 'I/C', 'ACT', 'CCA')
                then vvgrs
            when wwstp in ('CDM')
                and (
                    try_to_number(wwrsn) not between 300 and 499
                    and try_to_number(wwrsn) not between 501 and 599
                )
                then vvgrs
            else 0
        end as derv_gross_sales_before_freight_and_handling --'vvgrs'

        , case when item_bk in ('CQCLAIM', 'CSCLAIM', 'FSDAMAGE', 'FSLABOR')
                then 0
            when wwstp in ('SAL', 'RTN', 'ALW', 'CDM', 'NCH', 'PRM', 'I/C', 'ACT', 'CCA')
                then vvfrm + vvfrc
            else 0
        end as derv_revenue_from_freight --'vvfrm'

        , case when item_bk in ('CQCLAIM', 'CSCLAIM', 'FSDAMAGE', 'FSLABOR')
                then 0
            when wwstp in ('SAL', 'RTN', 'ALW', 'CDM', 'NCH', 'PRM', 'I/C', 'ACT', 'CCA')
                then vvfra
            else 0
        end as derv_freight_allowance --'vvfra'

        , case when item_bk in ('CQCLAIM', 'CSCLAIM', 'FSDAMAGE', 'FSLABOR')
                then 0
            when wwstp in ('SAL', 'RTN', 'ALW', 'CDM', 'NCH', 'PRM', 'I/C', 'ACT', 'CCA')
                then vvvpp + vvrst + vvhdl + vvmin
            else 0
        end as derv_revenue_from_handling --'zhdlrev' derived inside zcpsls1

        , case when item_bk in ('CQCLAIM', 'CSCLAIM', 'FSDAMAGE', 'FSLABOR')
                then 0
            when wwstp in ('SAL', 'RTN', 'ALW', 'CDM', 'NCH', 'PRM', 'I/C', 'ACT', 'CCA')
                then vvces
            else 0
        end as derv_currency_exchange_surcharge --'vvces'

        , case when item_bk in ('CQCLAIM', 'CSCLAIM', 'FSDAMAGE', 'FSLABOR')
                then 0
            when wwstp in ('SAL', 'RTN', 'ALW', 'NCH', 'PRM', 'I/C', 'ACT', 'CCA')
                then vvacq
            else 0
        end as derv_acquisition --'vvacq'

        , case when item_bk in ('CQCLAIM', 'CSCLAIM', 'FSDAMAGE', 'FSLABOR')
                then 0
            when wwstp in ('SAL')
                then vvqty
            else 0
        end as bill_qty --derived inside zcpsls1

        , case when item_bk in ('CQCLAIM', 'CSCLAIM', 'FSDAMAGE', 'FSLABOR')
                then 0
            when item_bk not in ('ACMISC', 'SPMISC', 'CFMISC') and wwstp = 'NCH'
                then vvqty
            else 0
        end as no_charge_qty --'znchgqty' derived inside zcpsls1

        , case when item_bk in ('CQCLAIM', 'CSCLAIM', 'FSDAMAGE', 'FSLABOR')
                then 0
            when item_bk not in ('ACMISC', 'SPMISC', 'CFMISC') and wwstp = 'RTN'
                then vvqty
            else 0
        end as return_qty --'zretrnqty' derived inside zcpsls1

        , case when item_bk in ('CQCLAIM', 'CSCLAIM', 'FSDAMAGE', 'FSLABOR')
                then 0
            when wwstp in ('RTN', 'ALW') and try_to_number(wwrsn) between 100 and 299
                then vvgrs
            else 0
        end as actual_returns_dollars --'zactret' derived inside zcpsls1

        , derv_gross_sales_before_freight_and_handling + derv_revenue_from_freight + derv_freight_allowance
        + derv_revenue_from_handling + derv_currency_exchange_surcharge + derv_acquisition as revenue_dollars
        , bill_qty + no_charge_qty as invoiced_qty
        , wwstp as shipment_type
        , 'MOEN' as source
        , null::binary as invoice_hk
        , case
            when vrgar = 'F' then rbeln   --record type F is associated with billing data and the rbeln/reference document number corresponds to invoice headers
        end as invoice_bk
        , null as payment_schedule_bk
        , null as adjustment_id
        , kaufn as sales_document
        , wwknu as sales_deal
        , customer_purchase_order_type
        , zzorc as order_category
        , vrgar as copa_record_type     --added to make joins to sales orders downstream cleaner ac
        , cast(
            case
                when length(trim(perio)) = 6
                    then substr(trim(perio), 1, 4) || substr(trim(perio), 5, 2)
                when length(trim(perio)) = 4
                    then perio || '01'
                when length(trim(perio)) = 2 and gjahr is not null
                    then gjahr || lpad(trim(perio), 2, '0')
                when length(trim(perio)) = 8
                    then substr(trim(perio), 1, 4) || substr(trim(perio), 5, 2)
                when length(trim(perio)) = 7
                    and left(trim(perio), 4) = gjahr
                    and substr(trim(perio), 5, 1) = '0'
                    then left(trim(perio), 4) || substr(trim(perio), 6, 2)
                when length(gjahr) = 4
                    and length(trim(perio)) > 2
                    and length(trim(perio)) < 6
                    then gjahr || lpad(left(trim(perio), 2), 2, '0')
            end as integer
        ) as fiscal_month__yyyymm
        , artnr as product_number
        , skost as sender_cost_center
        , kstar as cost_element 
        , bukrs as company_code
        , vvqty as sales_quantity
        , vvcst as standard_cost
        , vvgbp as gross_billing_price
        , augru as order_reason
        , cast(gjahr as integer) as fiscal_year__yyyy
        , pstyv as item_category
        , auart as sales_document_type
        , order_header_hk
        , order_header_bk
        , order_line_hk
        , order_line_bk
        , sales_organization_hk
        , sales_organization_bk
        , distribution_channel_hk
        , distribution_channel_bk
        , division_hk
        , division_bk
        , plant_hk
        , plant_bk
        , controlling_area_hk
        , controlling_area_bk
        , cost_center_hk
        , cost_center_bk
        , cost_element_hk
        , cost_element_bk
        , currency_type_hk
        , currency_type_bk
        , customer_sales_attributes_key
        , rec_src
        , bkcc
    from base
)

select
    hash(
        shipment_hk
        , invoice_bk
        , payment_schedule_bk
        , order_header_bk
        , order_line_bk
        , sales_organization_bk
        , distribution_channel_bk
        , division_bk
        , plant_bk
    ) as row_id
    , shipment_hk as shipment_id
    , item_id
    , base_material_id
    , customer_id
    , null::varchar as location_id
    , to_char(date_posted, 'YYYYMMDD') as posted_datekey
    , item_number
    , base_material
    , customer
    , key_account_number
    , customer_account_name
    , sales_org
    , channel
    , return_qty
    , actual_returns_dollars
    , revenue_dollars
    , invoiced_qty
    , shipment_type
    , source
    , customer_hk
    , invoice_hk
    , invoice_bk
    , payment_schedule_bk
    , adjustment_id
    , sales_document
    , sales_deal
    , customer_purchase_order_type
    , order_category
    , copa_record_type
    , fiscal_month__yyyymm
    , product_number
    , sender_cost_center
    , cost_element 
    , company_code
    , sales_quantity
    , standard_cost
    , gross_billing_price
    , order_reason
    , fiscal_year__yyyy
    , item_category
    , sales_document_type
    , order_header_hk
    , order_header_bk
    , order_line_hk
    , order_line_bk
    , sales_organization_hk
    , sales_organization_bk
    , distribution_channel_hk
    , distribution_channel_bk
    , division_hk
    , division_bk
    , plant_hk
    , plant_bk
    , customer_sales_attributes_key
    , rec_src
    , bkcc
    , current_date as load_date
from cte_logic_base
