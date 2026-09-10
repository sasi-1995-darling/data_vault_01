{{
    config(
        materialized='ephemeral'
    )
}}

with cte_lsat_invoice_customer_sales_organization_distribution_channel_division__hofr_ecl as (
    select
        lnk_invoice_customer_sales_organization_distribution_channel_division_item_hk
        , unique_key
        , sales
        , qty
        , date
        , sapcode
        , load_dts
    from {{ ref('lsat_invoice_customer_sales_organization_distribution_channel_division__hofr_ecl') }}
)

, cte_lsat_invoice_customer_sales_organization_distribution_channel_division__hofr_ecl_latest as (
    {{ generate_cte_satellite_latest('cte_lsat_invoice_customer_sales_organization_distribution_channel_division__hofr_ecl','lnk_invoice_customer_sales_organization_distribution_channel_division_item_hk') }}        
)

, cte_sat_item_master__moen_sap_v1 as (
    select
        item_hk
        , base_material
        , load_dts
    from {{ ref('sat_item_master__moen_sap_v1') }}
)

, cte_sat_item_master__moen_sap_v1_latest as (
    {{ generate_cte_satellite_latest('cte_sat_item_master__moen_sap_v1', 'item_hk') }}
)

, cte_customer_sales_attributes as (
    select
        customer_sales_attributes_key
        , customer_hk
        , sales_organization_hk
        , distribution_channel_hk
        , division_hk
        , customer
        , account_number
        , account_name
    from {{ ref('pb_customer_sales_attributes') }}
    where bkcc = 'Hiding_Tiger'
)

, base as (
    select
        lnkhofr.lnk_invoice_customer_sales_organization_distribution_channel_division_item_hk as shipment_hk
        , lsathofr.unique_key as shipment_id
        , hbcust.customer_hk
        , hbitm.item_hk as item_id
        , md5_binary(nullif(concat_ws(
            '||'
            , coalesce(nullif(upper(trim(satitm.base_material::varchar)), ''), '^^')
            , coalesce(nullif(upper(trim((hbitm.bkcc)::varchar)), ''), '^^')
        ), '^^||^^')) as base_material_id
        , hbitm.item_bk as item_number
        , satitm.base_material
        , pbcustsa.customer
        , to_char(hbcust.customer_bk) as customer_id
        , pbcustsa.account_number as key_account_number
        , pbcustsa.account_name as customer_account_name
        , hbslo.sales_organization_bk as sales_org
        , hbdist.distribution_channel_bk as channel
        , try_to_date(lsathofr.date, 'YYYYMMDD') as date_posted
        , null as location_id
        , 0 as return_qty
        , 0 as actual_returns_dollars
        , lsathofr.sales as revenue_dollars
        , lsathofr.qty as invoiced_qty
        , null as shipment_type
        , 'MOEN' as source
        , hbivhd.invoice_hk
        , hbivhd.invoice_bk
        , null as payment_schedule_bk
        , null as adjustment_id
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
        , hbslo.sales_organization_hk
        , hbslo.sales_organization_bk
        , hbdist.distribution_channel_hk
        , hbdist.distribution_channel_bk
        , hbdiv.division_hk
        , hbdiv.division_bk
        , null::binary as plant_hk
        , null as plant_bk
        , pbcustsa.customer_sales_attributes_key
        , lnkhofr.rec_src
        , hbcust.bkcc
    from {{ ref('lnk_invoice_customer_sales_organization_distribution_channel_division') }} as lnkhofr
        inner join {{ ref('hub_invoice_header') }} as hbivhd
            on lnkhofr.invoice_hk = hbivhd.invoice_hk
        inner join {{ ref('hub_customer_v1') }} as hbcust
            on lnkhofr.customer_hk = hbcust.customer_hk
        inner join {{ ref('hub_sales_organization') }} as hbslo
            on lnkhofr.sales_organization_hk = hbslo.sales_organization_hk
        inner join {{ ref('hub_distribution_channel') }} as hbdist
            on lnkhofr.distribution_channel_hk = hbdist.distribution_channel_hk
        inner join {{ ref('hub_division') }} as hbdiv
            on lnkhofr.division_hk = hbdiv.division_hk
        inner join {{ ref('hub_item_v1') }} as hbitm
            on lnkhofr.item_hk = hbitm.item_hk
        left join
            cte_lsat_invoice_customer_sales_organization_distribution_channel_division__hofr_ecl_latest as lsathofr
            on lnkhofr.lnk_invoice_customer_sales_organization_distribution_channel_division_item_hk
                = lsathofr.lnk_invoice_customer_sales_organization_distribution_channel_division_item_hk
        left join cte_sat_item_master__moen_sap_v1_latest as satitm
            on hbitm.item_hk = satitm.item_hk
        left join cte_customer_sales_attributes as pbcustsa
            on hbcust.customer_hk = pbcustsa.customer_hk
                and hbslo.sales_organization_hk = pbcustsa.sales_organization_hk
                and hbdist.distribution_channel_hk = pbcustsa.distribution_channel_hk
                and hbdiv.division_hk = pbcustsa.division_hk
    where try_to_date(lsathofr.date, 'YYYYMMDD') < '2023-07-02' --cutoff date for legacy HOFR data 
        and hbcust.customer_bk not in (     --customers excluded from legacy Qlik datasource across historic HOFR data
            '0000011814'
            , '0000000059'
            , '0000019769'
            , '0000012795'
            , '0000007477'
            , '0000011111'
            , '0000011585'
            , '0000011614'
            , '0000006210'
            , '0000005011'
            , '0000007909'
            , '0000001016'
            , '0000012417'
            , '0000011174'
            , '0000020498'
            , '0000001351'
            , '0000006981'
            , '0000007024'
            , '0000016458'
            , '0000019765'
            , '0000000287'
            , '0000019912'
            , '0000000726'
        )
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
from base
