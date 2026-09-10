-- {{ ref('hub_party') }}
-- {{ ref('hub_party_site') }}
-- {{ ref('hub_invoice_line') }}
-- {{ ref('hub_customer_account') }}
-- {{ ref('hub_cust_acct_site') }}
-- {{ ref('hub_cust_site_use') }}
-- {{ ref('link_invoice_line') }}

{{
    config(
        materialized='table'
    )
}}

with cte_sat_invoice_header__ml_ebs as (
    select * from {{ ref('sat_invoice_header__ml_ebs') }}
)
, cte_sat_invoice_header__ml_ebs__latest as (
    {{ generate_cte_satellite_latest(
        cte_name='cte_sat_invoice_header__ml_ebs'
        ,hk_field='invoice_hk') }}
)
, cte_lsat_invoice_line__ml_ebs as (
    select * from {{ ref('lsat_invoice_line__ml_ebs') }}
)
, cte_lsat_invoice_line__ml_ebs__latest as (
    {{ generate_cte_satellite_latest(
        cte_name='cte_lsat_invoice_line__ml_ebs'
        ,hk_field='invoice_line_hk') }}
)
, cte_sat_customer_account__ml_ebs as (
    select * from {{ ref('sat_customer_account__ml_ebs') }}
)
, cte_sat_customer_account__ml_ebs__latest as (
    {{ generate_cte_satellite_latest(
        cte_name='cte_sat_customer_account__ml_ebs'
        ,hk_field='account_hk') }}
)
, cte_sat_party__ml_ebs as (
    select * from {{ ref('sat_party__ml_ebs') }}
)
, cte_sat_party__ml_ebs__latest as (
    {{ generate_cte_satellite_latest(
        cte_name='cte_sat_party__ml_ebs'
        ,hk_field='party_hk') }}
)
, cte_lsat_invoice_line_gl_dist__ml_ebs as (
    select * from {{ ref('lsat_invoice_line_gl_dist__ml_ebs') }}
)
, cte_lsat_invoice_line_gl_dist__ml_ebs__latest as (
    {{ generate_cte_satellite_latest(
        cte_name='cte_lsat_invoice_line_gl_dist__ml_ebs'
        ,hk_field='invoice_line_hk') }}
)
, cte_sat_cust_site_use__ml_ebs as (
    select * from {{ ref('sat_cust_site_use__ml_ebs') }}
)
, cte_sat_cust_site_use__ml_ebs__latest as (
    {{ generate_cte_satellite_latest(
        cte_name='cte_sat_cust_site_use__ml_ebs'
        ,hk_field='site_use_hk') }}
)
, cte_sat_cust_acct_site__ml_ebs as (
    select * from {{ ref('sat_cust_acct_site__ml_ebs') }}
)
, cte_sat_cust_acct_site__ml_ebs__latest as (
    {{ generate_cte_satellite_latest(
        cte_name='cte_sat_cust_acct_site__ml_ebs'
        ,hk_field='cust_acct_site_hk') }}
)
, cte_sat_party_site__ml_ebs as (
    select * from {{ ref('sat_party_site__ml_ebs') }}
)
, cte_sat_party_site__ml_ebs__latest as (
    {{ generate_cte_satellite_latest(
        cte_name='cte_sat_party_site__ml_ebs'
        ,hk_field='party_site_hk') }}
)
, cte_sat_location__ml_ebs as (
    select * from {{ ref('sat_location__ml_ebs') }}
)
, cte_sat_location__ml_ebs__latest as (
    {{ generate_cte_satellite_latest(
        cte_name='cte_sat_location__ml_ebs'
        ,hk_field='location_hk') }}
)
, cte_sat_order_lines_all__ml_ebs as (
    select * from {{ ref('sat_order_lines_all__ml_ebs') }}
)
, cte_sat_order_lines_all__ml_ebs__latest as (
    {{ generate_cte_satellite_latest(
        cte_name='cte_sat_order_lines_all__ml_ebs'
        ,hk_field='order_line_hk') }}
)
, cte_sat_payment_schedule_all__ml_ebs as (
    select * from {{ ref('sat_payment_schedule_all__ml_ebs') }}
)
, cte_sat_payment_schedule_all__ml_ebs__latest as (
    {{ generate_cte_satellite_latest(
        cte_name='cte_sat_payment_schedule_all__ml_ebs'
        ,hk_field='payment_schedule_hk') }}
)

, null_memo_null_inventory_id as 
(
    select
        rctl.invoice_line_hk as shipment_hk
        , to_varchar(rctl.inventory_item_id) as item_id
        , hp.party_name as customer
        , to_char(hp.party_id) as customer_id
        , hca.key_account_number
        , null as customer_account_name
        , null as sales_org
        , null as channel
        , rctl.quantity_invoiced as invoiced_qty
        , null as return_qty
        , psa.gl_date as date_posted
        , hcs.location
        , hl.address1 as address_1
        , hl.address2 as address_2
        , hl.address3 as address_3
        , hl.address4 as address_4
        , hl.province
        , hl.country
        , hl.city
        , hl.state
        , hl.zipcode as zip_code
        , rctl.quantity_invoiced * rctl.unit_selling_price as revenue_dollars
        , rctl.quantity_invoiced * xref_cp.consumer_price as shipment_consumer_dollars
        , null as actual_return_dollars
        , null as shipment_type
        , 'MASTER LOCK' as source
    from cte_sat_invoice_header__ml_ebs__latest as rct
        inner join cte_lsat_invoice_line__ml_ebs__latest as rctl
            on rctl.invoice_hk = rct.invoice_hk
                and rct.org_id = rctl.org_id
                and rctl.line_type = 'LINE'
                and rctl.unit_selling_price != 0
        inner join {{ ref('link_invoice_line_order_line') }} ilol 
            on ilol.invoice_line_hk = rctl.invoice_line_hk
        inner join {{ ref('link_invoice_payment_schedule') }} ips
            on ips.invoice_hk = rctl.invoice_hk
        inner join cte_sat_payment_schedule_all__ml_ebs__latest psa
            on psa.payment_schedule_hk = ips.payment_schedule_hk
            and psa.class||'' in ('INV','DM','CM')
        inner join cte_sat_customer_account__ml_ebs__latest as hca
            on rct.sold_to_customer_id = hca.cust_account_id
        inner join cte_sat_party__ml_ebs__latest as hp
            on hca.party_hk = hp.party_hk
        inner join cte_lsat_invoice_line_gl_dist__ml_ebs__latest as aps
            on rctl.invoice_hk = aps.invoice_hk
                and rctl.invoice_line_hk = aps.invoice_line_hk
                and aps.gl_posted_date is not null
                and aps.account_class = 'REV'
                -- and COALESCE(aps.account_set_flag, 'N') = DECODE(rct.invoicing_rule_id, null, 'N', 'Y')
        inner join cte_sat_cust_site_use__ml_ebs__latest as hcs
            on rct.bill_to_site_use_id = hcs.site_use_id
                and hcs.site_use_code = 'BILL_TO'
        inner join cte_sat_cust_acct_site__ml_ebs__latest as hcasa
            on hcs.cust_acct_site_hk = hcasa.cust_acct_site_hk
        inner join cte_sat_party_site__ml_ebs__latest as hps
            on hcasa.party_site_id = hps.party_site_id
        inner join cte_sat_location__ml_ebs__latest as hl
            on hps.location_id = hl.location_id
        left join {{ ref('v_shipment_consumer_price_hd_tmlc') }} as xref_cp
            on xref_cp.item_id = to_varchar(rctl.inventory_item_id) and xref_cp.date_posted = aps.gl_posted_date
    where rctl.inventory_item_id is null and rctl.memo_line_id is null

)
, base as (
    select
        rctl.invoice_line_hk as shipment_hk
        , to_varchar(rctl.inventory_item_id) as item_id
        , hp.party_name as customer
        , to_char(hp.party_id) as customer_id
        , hca.key_account_number
        , null as customer_account_name
        , null as sales_org
        , null as channel
        , rctl.quantity_invoiced as invoiced_qty
        , null as return_qty
        , psa.gl_date as date_posted
        , hcs.location
        , hl.address1 as address_1
        , hl.address2 as address_2
        , hl.address3 as address_3
        , hl.address4 as address_4
        , hl.province
        , hl.country
        , hl.city
        , hl.state
        , hl.zipcode as zip_code
        , rctl.quantity_invoiced * rctl.unit_selling_price as revenue_dollars
        , rctl.quantity_invoiced * xref_cp.consumer_price as shipment_consumer_dollars
        , null as actual_return_dollars
        , null as shipment_type
        , 'MASTER LOCK' as source
    from cte_sat_invoice_header__ml_ebs__latest as rct
        inner join cte_lsat_invoice_line__ml_ebs__latest as rctl
            on rctl.invoice_hk = rct.invoice_hk
                and rct.org_id = rctl.org_id
                and rctl.line_type = 'LINE'
                and rctl.unit_selling_price != 0
        inner join {{ ref('link_invoice_line_order_line') }} ilol 
            on ilol.invoice_line_hk = rctl.invoice_line_hk
        inner join cte_sat_order_lines_all__ml_ebs__latest ola 
            on ilol.order_line_hk = ola.order_line_hk
            and ola.item_type_code not in ('OPTION','CLASS','CONFIG')
        inner join {{ ref('link_invoice_payment_schedule') }} ips
            on ips.invoice_hk = rctl.invoice_hk
        inner join cte_sat_payment_schedule_all__ml_ebs__latest psa
            on psa.payment_schedule_hk = ips.payment_schedule_hk
            and psa.class||'' in ('INV','DM','CM')
        inner join cte_sat_customer_account__ml_ebs__latest as hca
            on rct.sold_to_customer_id = hca.cust_account_id
        inner join cte_sat_party__ml_ebs__latest as hp
            on hca.party_hk = hp.party_hk
        inner join cte_lsat_invoice_line_gl_dist__ml_ebs__latest as aps
            on rctl.invoice_hk = aps.invoice_hk
                and rctl.invoice_line_hk = aps.invoice_line_hk
                and aps.gl_posted_date is not null
                and aps.account_class = 'REV'
                -- and COALESCE(aps.account_set_flag, 'N') = DECODE(rct.invoicing_rule_id, null, 'N', 'Y')
        inner join cte_sat_cust_site_use__ml_ebs__latest as hcs
            on rct.bill_to_site_use_id = hcs.site_use_id
                and hcs.site_use_code = 'BILL_TO'
        inner join cte_sat_cust_acct_site__ml_ebs__latest as hcasa
            on hcs.cust_acct_site_hk = hcasa.cust_acct_site_hk
        inner join cte_sat_party_site__ml_ebs__latest as hps
            on hcasa.party_site_id = hps.party_site_id
        inner join cte_sat_location__ml_ebs__latest as hl
            on hps.location_id = hl.location_id
        left join {{ ref('v_shipment_consumer_price_hd_tmlc') }} as xref_cp
            on xref_cp.item_id = to_varchar(rctl.inventory_item_id) and xref_cp.date_posted = aps.gl_posted_date
)

select * from base
union all
select * from null_memo_null_inventory_id