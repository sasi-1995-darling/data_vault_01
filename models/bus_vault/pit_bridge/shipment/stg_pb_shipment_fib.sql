{{
    config(
        materialized='ephemeral'
    )
}}

with cte_sat_invoice_header__fib_ocf as (
    select
        invoice_hk
        , complete_flag
        , interface_header_attribute_5
        , trx_number
        , created_by
        , load_dts
        , _fivetran_deleted
    from {{ ref('sat_invoice_header__fib_ocf') }}
)

, cte_sat_invoice_header__fib_ocf_latest as (
    {{ generate_cte_satellite_latest(
        cte_name= 'cte_sat_invoice_header__fib_ocf'
        ,hk_field= 'invoice_hk'
    ) }}
)

, cte_sat_invoice_line__fib_ocf as (
    select
        invoice_line_hk
        , sales_order
        , line_type
        , quantity_invoiced
        , quantity_credited
        , extended_amount
        , interface_line_attribute_4
        , interface_line_attribute_6
        , interface_line_attribute_5
        , interface_line_context
        , _fivetran_deleted
        , load_dts
    from {{ ref('sat_invoice_line__fib_ocf') }}
)

, cte_sat_invoice_line__fib_ocf_latest as (
    {{ generate_cte_satellite_latest(
        cte_name= 'cte_sat_invoice_line__fib_ocf'
        ,hk_field= 'invoice_line_hk'
    ) }}
)

, cte_sat_payment_schedule_all__fib_ocf as (
    select
        payment_schedule_hk
        , class
        , gl_date
        , _fivetran_deleted
        , load_dts
    from {{ ref('sat_payment_schedule_all__fib_ocf') }}
)

, cte_sat_payment_schedule_all__fib_ocf_latest as (
    {{ generate_cte_satellite_latest(
        cte_name= 'cte_sat_payment_schedule_all__fib_ocf'
        ,hk_field= 'payment_schedule_hk'
    ) }}
)

, cte_sat_customer__fib_ocf as (
    select
        customer_hk
        , account_number
        , account_name
        , _fivetran_deleted
        , load_dts
    from {{ ref('sat_customer__fib_ocf') }}
)

, cte_sat_customer__fib_ocf_latest as (
    {{ generate_cte_satellite_latest(
        cte_name= 'cte_sat_customer__fib_ocf'
        ,hk_field= 'customer_hk'
    ) }}
)

, cte_sat_plant__fib_ocf as (
    select
        plant_hk
        , organization_id
        , organization_code
        , _fivetran_deleted
        , load_dts
    from {{ ref('sat_plant__fib_ocf') }}
)

, cte_sat_plant__fib_ocf_latest as (
    {{ generate_cte_satellite_latest('cte_sat_plant__fib_ocf', 'plant_hk') }}
)

, cte_sat_plant__fib_ocf_master_latest as (
    select
        plant_hk
        , organization_id
        , organization_code
        , _fivetran_deleted
        , load_dts
    from cte_sat_plant__fib_ocf_latest
    where organization_code = 'MASTER'
)

, cte_sat_item_language__fib_ocf as (
    select
        item_hk
        , inventory_item_id
        , organization_id
        , description
        , language
        , hash(item_hk, inventory_item_id, organization_id, language) as pk
        , load_dts
        , _fivetran_deleted
    from {{ ref('sat_item_language__fib_ocf') }}
)

, cte_sat_item_language__fib_ocf_latest as (
    {{ generate_cte_satellite_latest('cte_sat_item_language__fib_ocf', 'pk') }}
)

, base as (
    select
        lil.invoice_line_hk as shipment_hk
        , hih.invoice_hk
        , hi.item_hk as item_id
        , lips.payment_schedule_hk
        , lcust.customer_billto_hk as customer_hk
        , hil.invoice_line_bk
        , null as adjustment_id
        , md5_binary(nullif(concat_ws(
            '||'
            , coalesce(nullif(upper(coalesce(trim(sitl_m.description), trim(sitl.description))::varchar), ''), '^^')
            , coalesce(nullif(upper(trim((hi.bkcc)::varchar)), ''), '^^')
        ), '^^||^^')) as base_material_id
        , hih.invoice_bk
        , hil.invoice_line_bk as shipment_id
        , hps.payment_schedule_bk
        , hi.item_bk as item_number
        , upper(coalesce(trim(sitl_m.description), trim(sitl.description))) as base_material
        , scust.account_number as customer_id
        , null as location_id
        , scust.account_name as customer
        , null as key_account_number
        , case
            when scust.account_name in (
                    'DIAMonD HILL PLYWOOD-DARLINGTON'
                    , 'DIAMonD HILL PLYWOOD-GREENVILLE'
                    , 'DIAMonD HILL PLYWOOD-KNOXVILLE'
                    , 'DIAMonD HILL PLYWOOD-RALEIGH'
                    , 'DIAMonD HILL PLYWOOD-RICHMonD'
                )
                then 'DIAMOND HILL'
            when scust.account_name in (
                    'FIBER COMPOSITES LLC (FCMKT)'
                    , 'FIBER COMPOSITES LLC (FCPROD)'
                    , 'FIBER COMPOSITES LLC (FCR&D)'
                    , 'FIBER COMPOSITES LLC (FCSAM)'
                    , 'FIBER COMPOSITES LLC (FCSMIND)'
                    , 'FIBER COMPOSITES LLC (FCSTORE)'
                    , 'FIBER COMPOSITES LLC (FCWAR)'
                )
                then 'FIBER COMPOSITES LLC'
            when scust.account_name in (
                    'HOME DEPOT (HD.COM)'
                    , 'HOME DEPOT (HD)'
                    , 'HOME DEPOT (HDSO)'
                    , 'HOME DEPOT DC ACCOUNTING (HDDC)'
                    , 'HOME DEPOT FLATBED DC ACCNTG (HFDC)'
                    , 'GLOBAL CUSTOM COMMERCE'
                    , 'MCFARLand CASCADE'
                )
                then 'HOME DEPOT'
            when scust.account_name in (
                    'LANSING BLDG PROD-PEARL'
                    , 'LANSING BUILDING PRODUCTS'
                    , 'OREPAC'
                    , 'OREPAC-TACOMA'
                )
                then 'OREPAC'
            when scust.account_name in (
                    'WOODGRAIN MILLWORK HBP'
                    , 'WOODGRAIN MILLWORK INC'
                    , 'WOODGRAIN MILLWORK-CORP'
                )
                then 'WOODGRAIN'
            else scust.account_name
        end as customer_account_name
        , null as sales_org
        , null as channel
        , case
            when sln.interface_line_attribute_4 ilike '%RMA%'
                then 0
            else coalesce(sln.quantity_invoiced, 0) - coalesce(sln.quantity_credited, 0)
        end as invoiced_qty
        , case
            when sln.interface_line_attribute_4 ilike '%RMA%'
                then coalesce(sln.quantity_invoiced, 0) - coalesce(sln.quantity_credited, 0)
            else 0
        end as return_qty
        , date(sps.gl_date) as date_posted
        , case
            when sln.interface_line_attribute_4 ilike '%RMA%'
                then 0
            else coalesce(sln.extended_amount, 0)   --added coalesce to resolve nulls in older invoice records per QA feedback 
        end as revenue_dollars
        , case
            when sln.interface_line_attribute_4 ilike '%RMA%'
                then sln.extended_amount
            else 0
        end as actual_returns_dollars
        , sps.class as shipment_type
        , 'FIBERON' as source
        , lil.rec_src
        , hih.bkcc
        /*Logic used in legacy tableau data source to exclude error transaction records*/
        , case
            when shdr.trx_number in (
                    '160002', '160003', '161001', '161002', '161003', '161004', '161005', '161006', '161007', '161008'
                    , '161009', '161010', '161012', '161013', '161014', '161015', '161016', '161017', '161018', '161019'
                    , '161020'
                    , '161022'
                    , '161023'
                    , '161024'
                    , '9999'
                    , '10000'
                    , '10001'
                    , '10999'
                    , '11000'
                    , '153000'
                    , '160001'
                    , '161000', '194000', '194001', '194002', '194003', '194004', '194042', '195000', '195024', '198001'
                    , '198002', '206001', '206002', '206003', '206004', '206005', '206006', '206007', '207000', '208000'
                    , '208001', '208004', '207001', '208002', '208003'
                )
                and shdr.created_by in ('lynzee.eddins@fiberondecking.com')
                and sps.gl_date between '2023-10-01' and '2023-12-30'
                then 'Y'
            when shdr.trx_number in ('237000', '237001', '237002', '238000', '240000', '221000')
                then 'Y'
            when sln.sales_order in ('812866', '813072')
                then 'Y'
            else 'N'
        end as fiberon_special_exclusion_flag
    from {{ ref('link_invoice_line') }} as lil
        inner join {{ ref('hub_invoice_line_v1') }} as hil
            on lil.invoice_line_hk = hil.invoice_line_hk and hil.bkcc = 'Jumping_River'
        inner join {{ ref('hub_invoice_header') }} as hih
            on lil.invoice_hk = hih.invoice_hk
        inner join {{ ref('hub_item_v1') }} as hi
            on lil.item_hk = hi.item_hk
        inner join {{ ref('link_invoice_payment_schedule') }} as lips
            on hih.invoice_hk = lips.invoice_hk
        inner join {{ ref('hub_payment_schedule') }} as hps
            on lips.payment_schedule_hk = hps.payment_schedule_hk
        left join {{ ref('lnk_invoice_customer') }} as lcust
            on hih.invoice_hk = lcust.invoice_hk
        left join cte_sat_invoice_header__fib_ocf_latest as shdr
            on hih.invoice_hk = shdr.invoice_hk
                and shdr._fivetran_deleted = 'false'
        left join cte_sat_invoice_line__fib_ocf_latest as sln
            on hil.invoice_line_hk = sln.invoice_line_hk
                and sln.line_type = 'LINE'
                and sln._fivetran_deleted = 'false'
        left join cte_sat_payment_schedule_all__fib_ocf_latest as sps
            on hps.payment_schedule_hk = sps.payment_schedule_hk
                and sps.class in ('INV', 'CM', 'DM')
                and sps._fivetran_deleted = 'false'
        left join cte_sat_customer__fib_ocf_latest as scust
            on lcust.customer_billto_hk = scust.customer_hk
                and scust._fivetran_deleted = 'false'
        left join {{ ref('link_plant_item_v1') }} as l
            on hi.item_hk = l.item_hk
        left join cte_sat_plant__fib_ocf_master_latest as sorg_m
            on 1 = 1 and sorg_m._fivetran_deleted = 'false'
        left join cte_sat_plant__fib_ocf_latest as sorg
            on l.plant_hk = sorg.plant_hk and sorg._fivetran_deleted = 'false'
        left join cte_sat_item_language__fib_ocf_latest as sitl
            on hi.item_hk = sitl.item_hk and sorg.organization_id = sitl.organization_id and sitl.language = 'US'
                and sitl._fivetran_deleted = 'false'
        left join cte_sat_item_language__fib_ocf_latest as sitl_m
            on hi.item_hk = sitl_m.item_hk
                and sorg_m.organization_id = sitl_m.organization_id
                and sitl_m.language = 'US'
                and sitl_m._fivetran_deleted = 'false'
    where
        shdr.complete_flag = 'Y'   /*only load completed invoices*/
        and coalesce(sln.interface_line_context, '') in (
            'DOO', ' ', ''
        )   /* only load line contexts that are included in legacy reporting source from OCF*/
        and (
            nullif(trim(interface_line_attribute_6), '') is null
            or nullif(trim(interface_line_attribute_6), '') = nullif(trim(interface_line_attribute_5), '')
            or interface_header_attribute_5 in (
                '300000200902700', '300000263084576', '300000037728308', '300000037707064'
            )
        ) /*OR logic needed to include discounted records that have been utilized in the Tableau data source (most likely in error)*/
        and fiberon_special_exclusion_flag = 'N'  /*used to exclude error records based on above flag logic */
)

select distinct
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