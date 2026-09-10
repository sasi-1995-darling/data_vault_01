{{
    config(
        materialized='ephemeral'
    )
}}

with cte_sat_invoice_header__tt_e21 as (
    select * from {{ ref('sat_invoice_header__tt_e21') }}
)
, cte_sat_invoice_header__tt_e21__latest as (
    {{ generate_cte_satellite_latest(
        cte_name='cte_sat_invoice_header__tt_e21'
        ,hk_field='invoice_hk') }}
)
, cte_lsat_invoice_line__tt_e21 as (
    select * from {{ ref('lsat_invoice_line__tt_e21') }}
)
, cte_lsat_invoice_line__tt_e21__latest as (
    {{ generate_cte_satellite_latest(
        cte_name='cte_lsat_invoice_line__tt_e21'
        ,hk_field='invoice_line_hk') }}
)

select
    ih.invoice_hk as shipment_hk
    , to_varchar(il.base_part_code) as item_id
    , ih.billname as customer
    , null as customer_id
    , null as key_account_number
    , null as customer_account_name
    , null as sales_org
    , null as channel
    , il.qty as invoiced_qty
    , null as return_qty
    , ih.post_date as date_posted
    , ih.billzip as location
    , ih.billadd1 as address_1
    , ih.billadd2 as address_2
    , ih.billadd3 as address_3
    , ih.billadd3 as address_4
    , null as province
    , ih.billcountry as country
    , ih.billcity as city
    , ih.billst as state
    , ih.billzip as zip_code
    , il.qty * il.item_price as revenue_dollars
    , null as shipment_consumer_dollars
    , null as actual_return_dollars
    , null as shipment_type
    , 'THERMATRU' as source
from cte_sat_invoice_header__tt_e21__latest as ih
    inner join cte_lsat_invoice_line__tt_e21__latest as il
        on ih.invoice_numb = il.invoice_numb
            and ih.cost_ctr = il.cost_ctr
