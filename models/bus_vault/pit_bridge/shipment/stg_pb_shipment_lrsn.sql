{{
    config(
        materialized='ephemeral'
    )
}}

with cte_sat_bi_hdr__lrsn_psft as (
    select
        invoice_hk
        , bill_status
        , business_unit
        , invoice_amount
        , sold_to_cust_id
        , bill_to_cust_id
        , invoice_dt
        , _fivetran_deleted
        , entry_type
        , load_dts
    from {{ ref('sat_bi_hdr__lrsn_psft') }}
)

, cte_sat_bi_hdr__lrsn_psft__latest as (
    {{ generate_cte_satellite_latest(
        cte_name= 'cte_sat_bi_hdr__lrsn_psft'
        ,hk_field='invoice_hk') }}
)

, cte_sat_invoice_line__lrsn_psft as (
    select
        invoice_line_hk
        , user2
        , qty
        , gross_extended_bse
        , _fivetran_deleted
        , load_dts
    from {{ ref('sat_invoice_line__lrsn_psft') }}
)

, cte_sat_invoice_line__lrsn_psft__latest as (
    {{ generate_cte_satellite_latest(
        cte_name='cte_sat_invoice_line__lrsn_psft'
        ,hk_field='invoice_line_hk'
    ) }}
)

, cte_sat_customer__lrsn_psft as (
    select
        customer_hk
        , cust_id
        , cust_name
        , corporate_cust_id
        , l_corp_cust_name
        , _fivetran_deleted
        , load_dts
    from {{ ref('sat_customer__lrsn_psft') }}
)

, cte_sat_customer__lrsn_psft__latest as (
    {{ generate_cte_satellite_latest(
        cte_name='cte_sat_customer__lrsn_psft'
        ,hk_field='customer_hk'
    ) }}
)

, cte_msat_cust_cgrp__lrsn_psft as (
    select
        customer_hk
        , cust_grp_type
        , customer_group
        , _fivetran_deleted
        , load_dts
    from {{ ref('msat_cust_cgrp__lrsn_psft') }}
)

, cte_msat_cust_cgrp__lrsn_psft__latest as (
    {{ generate_cte_satellite_latest(
        cte_name='cte_msat_cust_cgrp__lrsn_psft'
        ,hk_field='customer_hk, cust_grp_type, customer_group'
    ) }}
)

/*Driving Key for this link - invoice_hk
  Sold_to_customer changes when the Invoice Status changes from "RDY" (ready to invoice) to "INV" (finalized Invoice)
  using the driving key to fetch the latest valid customer for the invoice.
  AS per the Larson SME : "becky.anderson@fbin.com" 2025-03-17*/
, cte_lnk_invoice_customer as (
    select
        invoice_hk,
        customer_soldto_hk,
        customer_billto_hk,
        load_dts
    from {{ ref('lnk_invoice_customer') }}
)

, cte_lnk_invoice_customer__latest as (
    {{ generate_cte_satellite_latest(
        cte_name='cte_lnk_invoice_customer'
        ,hk_field='invoice_hk'
    ) }}
)

, base as (
    select
        lil.invoice_line_hk as shipment_hk
        , hih.invoice_hk
        , hi.item_hk as item_id
        , null::binary as payment_schedule_hk
        , lic.customer_soldto_hk as customer_hk
        , hil.invoice_line_bk
        , null as adjustment_id
        , md5_binary(nullif(concat_ws(
            '||'
            , coalesce(nullif(upper(trim(regexp_replace(hi.item_bk::varchar, '[\x00-\x1F]', ''))), ''), '^^')
            , coalesce(nullif(upper(trim((hi.bkcc)::varchar)), ''), '^^')
        ), '^^||^^')) as base_material_id
        , hih.invoice_bk
        , hil.invoice_line_bk as shipment_id
        , null as payment_schedule_bk
        , hi.item_bk as item_number
        , hi.item_bk as base_material
        , coalesce(nullif(trim(shdr.sold_to_cust_id), ''), shdr.bill_to_cust_id) as customer_id
        , null as location_id
        , coalesce(scust_s.cust_name, scust_b.cust_name) as customer
        , coalesce(scust_s.corporate_cust_id, scust_b.corporate_cust_id) as key_account_number
        , coalesce(scust_s.l_corp_cust_name, scust_b.l_corp_cust_name) as customer_account_name
        , null as sales_org
        , null as channel
        , case
            when sln.user2 = 'S'
                then sln.qty
            when sln.user2 = 'D'
                and shdr.invoice_amount > 0
                then decode(shdr.entry_type, 'CR', sln.qty, 0)
            else 0
        end as invoiced_qty
        , case
            when sln.user2 in ('R', 'B')
                then sln.qty
            when nullif(trim(sln.user2), '') is null
                then sln.qty
            when sln.user2 in ('C')
                and decode(shdr.entry_type, 'CR', 0, sln.qty)
                then sln.qty
            when sln.user2 in ('D')
                and shdr.invoice_amount < 0
                then decode(shdr.entry_type, 'CR', sln.qty, 0)
            else 0
        end as return_qty
        , shdr.invoice_dt as date_posted
        , case
            when sln.user2 = 'S'
                then sln.gross_extended_bse
            when sln.user2 = 'D'
                and shdr.invoice_amount > 0
                then sln.gross_extended_bse
            else 0
        end as revenue_dollars
        , case
            when sln.user2 in ('R', 'C', 'B')
                then sln.gross_extended_bse
            when nullif(trim(sln.user2), '') is null
                then sln.gross_extended_bse
            when sln.user2 = 'D'
                and shdr.invoice_amount < 0
                then sln.gross_extended_bse
            else 0
        end as actual_returns_dollars
        , decode(sln.user2, 'S', 'Sales', 'B', 'BuyBack', 'R', 'Return', 'C', 'CreditMemo', 'D', 'DebitMemo')
            as shipment_type
        , 'LARSON' as source
        , lil.rec_src  
        , hil.bkcc 
    from {{ ref('link_invoice_line') }} as lil
        inner join {{ ref('hub_invoice_line_v1') }} as hil
            on lil.invoice_line_hk = hil.invoice_line_hk and hil.bkcc = 'Swimming_Ocean'
        inner join {{ ref('hub_invoice_header') }} as hih
            on lil.invoice_hk = hih.invoice_hk
        inner join {{ ref('hub_item_v1') }} as hi
            on lil.item_hk = hi.item_hk
        left join cte_lnk_invoice_customer__latest as lic
            on lil.invoice_hk = lic.invoice_hk
        left join cte_sat_bi_hdr__lrsn_psft__latest as shdr
            on hih.invoice_hk = shdr.invoice_hk
                and shdr._fivetran_deleted = 'false'
        left join cte_sat_invoice_line__lrsn_psft__latest as sln
            on lil.invoice_line_hk = sln.invoice_line_hk
                and sln._fivetran_deleted = 'false'
        left join cte_sat_customer__lrsn_psft__latest as scust_s
            on lic.customer_soldto_hk = scust_s.customer_hk
                and scust_s.cust_id != '-1'
                and scust_s._fivetran_deleted = 'false'
        left join cte_sat_customer__lrsn_psft__latest as scust_b
            on lic.customer_billto_hk = scust_b.customer_hk
                and scust_b.cust_id != '-1'
        left join cte_msat_cust_cgrp__lrsn_psft__latest as scust_grp
            on lic.customer_billto_hk = scust_grp.customer_hk
                and scust_grp.customer_group = 'GILBERTSON'
                and scust_grp.cust_grp_type = 'COMP'
                and scust_grp._fivetran_deleted = 'false'
    where
        shdr.bill_status = 'INV' /* --Only load Finalized Invoices*/
        and shdr.business_unit = 'LAR01' /* --Only load LAR01 (AEI01 is reported separately)*/
        and scust_grp.customer_hk is null /* --Exclude Gilbertson invoices*/
        and shdr.invoice_amount != 0
)

select
    shipment_hk as shipment_id
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
    , null as sales_document     
    , null as sales_deal     
    , null as customer_purchase_order_type
	, null as order_category
    , null as copa_record_type
    , null as fiscal_month__yyyymm
    , null as product_number
    , null as sender_cost_center
    , null as cost_element
    , null as company_code
    , null as sales_quantity
    , null as standard_cost
    , null as gross_billing_price
    , null as order_reason
    , null as fiscal_year__yyyy
    , null as item_category
    , null as sales_document_type
    , null::binary as order_header_hk
    , null as order_header_bk
    , null::binary as order_line_hk
    , null as order_line_bk
    , null::binary as sales_organization_hk
    , null as sales_organization_bk
    , null::binary as distribution_channel_hk
    , null as distribution_channel_bk
    , null::binary as division_hk
    , null as division_bk
    , null::binary as plant_hk
    , null as plant_bk
    , null::binary as customer_sales_attributes_key	
    , rec_src     
    , bkcc 
from base