{{
    config(
        materialized='ephemeral'
    )
}}

with cte_sat_shipment__moen_sap as (select * from {{ ref('sat_shipment__moen_sap') }})

, cte_sat_shipment__moen_sap_latest as (
    {{ generate_cte_satellite_latest('cte_sat_shipment__moen_sap','copa_sales_hk') }}
)

, base as (
    select
        hshp.copa_sales_hk as shipment_hk
        , case when sshp.type_of_sale in ('SAL', 'NCH', 'PRM', 'I/C', 'ACT', 'CCA')
                then sshp.gross_sales_before_freight_and_handling
            when sshp.type_of_sale in ('CDM')
                and (
                    try_to_number(sshp.combined_reason_code) not between 300 and 499
                    and try_to_number(sshp.combined_reason_code) not between 501 and 599
                )
                then sshp.gross_sales_before_freight_and_handling
            else 0
        end as derv_gross_sales_before_freight_and_handling

        , case when sshp.type_of_sale in ('SAL', 'RTN', 'ALW', 'CDM', 'NCH', 'PRM', 'I/C', 'ACT', 'CCA')
                then sshp.freight + sshp.freight_on_cash_sale
            else 0
        end as derv_revenue_from_freight

        , case when sshp.type_of_sale in ('SAL', 'RTN', 'ALW', 'CDM', 'NCH', 'PRM', 'I/C', 'ACT', 'CCA')
                then sshp.freight_allowance
            else 0
        end as derv_freight_allowance

        , case when sshp.type_of_sale in ('SAL', 'RTN', 'ALW', 'CDM', 'NCH', 'PRM', 'I/C', 'ACT', 'CCA')
                then sshp.restocking_charge
                    + sshp.customer_chargebacks
                    + sshp.handling_charge
                    + sshp.volume_purchase_penalty
            else 0
        end as derv_revenue_from_handling

        , case when sshp.type_of_sale in ('SAL', 'RTN', 'ALW', 'CDM', 'NCH', 'PRM', 'I/C', 'ACT', 'CCA')
                then sshp.currency_exchange_surcharge
            else 0
        end as derv_currency_exchange_surcharge

        , case when sshp.type_of_sale in ('SAL', 'RTN', 'ALW', 'NCH', 'PRM', 'I/C', 'ACT', 'CCA')
                then sshp.acquisition_oid
            else 0
        end as derv_acquisition

        , case when sshp.type_of_sale in ('SAL')
                then sshp.invoice_qty
            else 0
        end as bill_qty

        , case when hi.item_bk not in ('ACMISC', 'SPMISC', 'CFMISC') and sshp.type_of_sale in ('NCH')
                then sshp.invoice_qty
            else 0
        end as no_charge_qty

        , case when hi.item_bk not in ('ACMISC', 'SPMISC', 'CFMISC') and sshp.type_of_sale in ('RTN')
                then sshp.invoice_qty
            else 0
        end as return_qty

        , case when sshp.type_of_sale in ('ALW')
                then sshp.invoice_qty
            else 0
        end as allowance_qty

        , case when sshp.type_of_sale in ('RTN', 'ALW')
                and try_to_number(sshp.combined_reason_code) between 100 and 299
                then sshp.gross_sales_before_freight_and_handling
            else 0
        end as actual_returns

        , derv_gross_sales_before_freight_and_handling + derv_revenue_from_freight + derv_freight_allowance
        + derv_revenue_from_handling
        + derv_currency_exchange_surcharge
        + derv_acquisition as derv_gross_sales_before_incentives
        , bill_qty + no_charge_qty as shipped_qty
    from {{ ref('hub_shipment_sap') }} as hshp
        inner join cte_sat_shipment__moen_sap_latest as sshp
            on hshp.copa_sales_hk = sshp.copa_sales_hk
        left join {{ ref('link_item_cust_shipment') }} as lics
            on hshp.copa_sales_hk = lics.copa_sales_hk
        left join {{ ref('hub_item') }} as hi
            on lics.item_hk = hi.item_hk
    where hi.item_bk not in ('CQCLAIM', 'CSCLAIM', 'FSDAMAGE', 'FSLABOR')
)

select
    shipment_hk
    , derv_gross_sales_before_freight_and_handling as gross_sales_before_freight_and_handling --'vvgrs'
    , derv_revenue_from_freight as freight --'vvfrm'
    , derv_freight_allowance as freight_allowance --'vvfra'
    , derv_revenue_from_handling as revenue_from_handling--'zhdlrev' derived inside zcpsls1
    , derv_currency_exchange_surcharge as currency_exchange_surcharge --'vvces'
    , derv_acquisition as acquisition_oid --'vvacq'
    , bill_qty --derived inside zcpsls1
    , no_charge_qty --'znchgqty' derived inside zcpsls1
    , return_qty --'zretrnqty' derived inside zcpsls1
    , allowance_qty --'zalwqty' derived inside zcpsls1
    , actual_returns --'zactret' derived inside zcpsls1
    , derv_gross_sales_before_incentives as gross_sales_before_incentives --'vvgbp'
    , shipped_qty --'zshipqty' derived inside zcpsls1
from base
