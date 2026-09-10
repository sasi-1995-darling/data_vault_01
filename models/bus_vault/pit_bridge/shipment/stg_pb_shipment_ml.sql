{{
    config(
        materialized='ephemeral'
    )
}}

with cte_sat_invoice_header__ml_ebs as (
    select
        invoice_hk,
        customer_trx_id,
        org_id,
        sold_to_customer_id,
        bill_to_customer_id,
        invoice_currency_code,
        batch_source_id, 
        bill_to_site_use_id,
        complete_flag,
        _fivetran_deleted,
        load_dts
    from {{ ref('sat_invoice_header__ml_ebs') }}
)

, cte_sat_invoice_header__ml_ebs__latest as (
    {{ generate_cte_satellite_latest(
        cte_name='cte_sat_invoice_header__ml_ebs'
        ,hk_field='invoice_hk') }}
)

, cte_sat_invoice_line__ml_ebs as (
    select
        invoice_line_hk,
        customer_trx_id,
        org_id,
        line_type,
        quantity_invoiced,
        quantity_credited,
        extended_amount,
        inventory_item_id,
        unit_selling_price,
        memo_line_id,
        description,
        _fivetran_deleted,
        load_dts
    from {{ ref('sat_invoice_line__ml_ebs') }}
)

, cte_sat_invoice_line__ml_ebs__latest as (
    {{ generate_cte_satellite_latest(
        cte_name='cte_sat_invoice_line__ml_ebs'
        ,hk_field='invoice_line_hk') }}
)

, cte_sat_customer_account__ml_ebs as (
    select
        account_hk,
        cust_account_id,
        party_hk,
        key_account_number,
        customer_class_code,
        load_dts
    from {{ ref('sat_customer_account__ml_ebs') }}
)

, cte_sat_customer_account__ml_ebs__latest as (
    {{ generate_cte_satellite_latest(
        cte_name='cte_sat_customer_account__ml_ebs'
        ,hk_field='account_hk') }}
)

, cte_sat_party__ml_ebs as (
    select
        party_hk,
        party_id,
        party_name,
        load_dts
    from {{ ref('sat_party__ml_ebs') }}
)

, cte_sat_party__ml_ebs__latest as (
    {{ generate_cte_satellite_latest(
        cte_name='cte_sat_party__ml_ebs'
        ,hk_field='party_hk') }}
)

, cte_sat_invoice_line_gl_dist__ml_ebs as (
    select
        invoice_line_hk,
        cust_trx_line_gl_dist_id,
        customer_trx_id,
        customer_trx_line_id,
        gl_date,
        gl_posted_date,
        amount,
        account_set_flag,
        account_class,
        load_dts
    from {{ ref('sat_invoice_line_gl_dist__ml_ebs') }}
    where _fivetran_deleted = 'FALSE'
)

, cte_sat_invoice_line_gl_dist__ml_ebs__latest as (
    {{ generate_cte_satellite_latest(
        cte_name='cte_sat_invoice_line_gl_dist__ml_ebs'
        ,hk_field='invoice_line_hk, cust_trx_line_gl_dist_id') }}
)

, cte_sat_invoice_line_gl_dist__ml_ebs__latest_max as (
    select
        invoice_line_hk
        , customer_trx_id
        , customer_trx_line_id
        , max(gl_date) as gl_date
        , max(gl_posted_date) as gl_posted_date
        , sum(amount) as amount
        , account_set_flag
        , account_class
    from cte_sat_invoice_line_gl_dist__ml_ebs__latest
            where account_class = 'REV' 
            and gl_posted_date is not null
    group by all
)

, cte_sat_cust_site_use__ml_ebs as (
    select
        site_use_hk,
        site_use_id,
        site_use_code,
        cust_acct_site_hk,
        load_dts
    from {{ ref('sat_cust_site_use__ml_ebs') }}
)

, cte_sat_cust_site_use__ml_ebs__latest as (
    {{ generate_cte_satellite_latest(
        cte_name='cte_sat_cust_site_use__ml_ebs'
        ,hk_field='site_use_hk') }}
)

, cte_sat_cust_acct_site__ml_ebs as (
    select
        cust_acct_site_hk,
        party_site_id,
        load_dts
    from {{ ref('sat_cust_acct_site__ml_ebs') }}
)

, cte_sat_cust_acct_site__ml_ebs__latest as (
    {{ generate_cte_satellite_latest(
        cte_name='cte_sat_cust_acct_site__ml_ebs'
        ,hk_field='cust_acct_site_hk') }}
)

, cte_sat_party_site__ml_ebs as (
    select
        party_site_hk,
        party_site_id,
        location_id,
        load_dts
    from {{ ref('sat_party_site__ml_ebs') }}
)

, cte_sat_party_site__ml_ebs__latest as (
    {{ generate_cte_satellite_latest(
        cte_name='cte_sat_party_site__ml_ebs'
        ,hk_field='party_site_hk') }}
)

, cte_sat_location__ml_ebs as (
    select
        location_hk,
        location_id,
        load_dts
    from {{ ref('sat_location__ml_ebs_v1') }}
)

, cte_sat_location__ml_ebs__latest as (
    {{ generate_cte_satellite_latest(
        cte_name='cte_sat_location__ml_ebs'
        ,hk_field='location_hk') }}
)

, cte_sat_order_lines_all__ml_ebs as (
    select
        order_line_hk,
        line_type_id,
        item_type_code,
        _fivetran_deleted,
        load_dts
    from {{ ref('sat_order_lines_all__ml_ebs') }}
)

, cte_sat_order_lines_all__ml_ebs__latest as (
    {{ generate_cte_satellite_latest(
        cte_name='cte_sat_order_lines_all__ml_ebs'
        ,hk_field='order_line_hk') }}
)

, cte_sat_payment_schedule_all__ml_ebs as (
    select
        payment_schedule_hk,
        gl_date,
        class,
        _fivetran_deleted,
        load_dts
    from {{ ref('sat_payment_schedule_all__ml_ebs') }}
)

, cte_sat_payment_schedule_all__ml_ebs__latest as (
    {{ generate_cte_satellite_latest(
        cte_name='cte_sat_payment_schedule_all__ml_ebs'
        ,hk_field='payment_schedule_hk') }}
)

, cte_sat_item_base__ml_ebs as (
    select
        item_hk,
        inventory_item_id,
        material,
        load_dts
    from {{ ref('sat_item_base__ml_ebs_v1') }}
)

, cte_sat_item_base__ml_ebs__latest as (
    {{ generate_cte_satellite_latest(
        cte_name='cte_sat_item_base__ml_ebs'
        ,hk_field='item_hk') }}
)

, cte_sat_invoice_adjustments__ml_ebs as (
    select
        invoice_hk,
        adjustment_id,
        org_id,
        customer_trx_line_id,
        receivables_trx_id,
        gl_date,
        type,
        amount,
        receivables_charges_adjusted,
        status,
        _fivetran_deleted,
        load_dts
    from {{ ref('sat_invoice_adjustments__ml_ebs') }}
)

, cte_sat_invoice_adjustments__ml_ebs__latest as (
    {{ generate_cte_satellite_latest(
        cte_name='cte_sat_invoice_adjustments__ml_ebs'
        ,hk_field='invoice_hk, adjustment_id') }}
)

, cte_ref_sat_currency_rates__ml_ebs as (
    select
        curr_rates_bk,
        from_currency,
        to_currency,
        conversion_date,
        conversion_rate,
        conversion_type,
        load_dts
    from {{ ref('ref_sat_currency_rates__ml_ebs') }}
)

, cte_ref_sat_currency_rates__ml_ebs__latest as (
    {{ generate_cte_satellite_latest(
        cte_name='cte_ref_sat_currency_rates__ml_ebs'
        ,hk_field='curr_rates_bk,conversion_type') }}
)

, cte_ref_sat_batch_sources__ml_ebs as (
    select
        batch_source_bk,
        batch_source_id,
        org_id,
        name,
        load_dts
    from {{ ref('ref_sat_batch_sources__ml_ebs') }}
)

, cte_ref_sat_batch_sources__ml_ebs__latest as (
    {{ generate_cte_satellite_latest(
        cte_name='cte_ref_sat_batch_sources__ml_ebs'
        ,hk_field='batch_source_bk') }}
)

, cte_ref_sat_transaction_types__ml_ebs as (
    select
        transaction_type_bk,
        name,
        load_dts
    from {{ ref('ref_sat_transaction_types__ml_ebs') }}
)

, cte_ref_sat_transaction_types__ml_ebs__latest as (
    {{ generate_cte_satellite_latest(
        cte_name='cte_ref_sat_transaction_types__ml_ebs'
        ,hk_field='transaction_type_bk') }}
)

, cte_ref_sat_receivables_trx__ml_ebs as (
select
    receivables_bk,
    receivables_trx_id,
    attribute2,
    org_id,
    type,
    load_dts
from {{ ref('ref_sat_receivables_trx__ml_ebs') }}
)

, cte_ref_sat_receivables_trx__ml_ebs__latest as (
    {{ generate_cte_satellite_latest(
        cte_name='cte_ref_sat_receivables_trx__ml_ebs'
        ,hk_field='receivables_bk') }}
)

, cte_ref_sat_memo_line__ml_ebs as (
    select
        memo_line_bk,
        memo_line_id,
        attribute2,
        org_id,
        load_dts
    from {{ ref('ref_sat_memo_line__ml_ebs') }}
)

, cte_ref_sat_memo_line__ml_ebs__latest as (
    {{ generate_cte_satellite_latest(
        cte_name='cte_ref_sat_memo_line__ml_ebs'
        ,hk_field='memo_line_bk') }}
)

, base as (
    select
        ilol.invoice_line_hk as shipment_hk
        , hih.invoice_hk
        , hi.item_hk as item_id
        , hpays.payment_schedule_hk
        , hup.party_hk as customer_hk
        , null as adjustment_id
        , md5_binary(nullif(concat_ws(
            '||'
            , coalesce(nullif(upper(trim(ml.material::varchar)), ''), '^^')
            , coalesce(nullif(upper(trim((hi.bkcc)::varchar)), ''), '^^')
        ), '^^||^^')) as base_material_id
        , hih.invoice_bk
        , hil.invoice_line_bk as shipment_id
        , hpays.payment_schedule_bk
        , hi.item_bk as item_number
        , ml.material as base_material
        , to_char(hp.party_id) as customer_id
        , hloc.location_bk as location_id
        , hp.party_name as customer
        , hca.key_account_number
        , null as customer_account_name
        , null as sales_org
        , null as channel
        , case
            when rct.org_id in ('498', '820', '578', '538', '758')
                and (oltype.name ilike 'CREDIT NO RETURN%' or rsbs.name ilike 'MANUAL%')
                then 0
            when not coalesce(oltype.name, 'XX') ilike any ('%RMA%', '%RETURN%')
                then coalesce(rctl.quantity_invoiced, quantity_credited, 0)
            else 0
        end as invoiced_qty
        , case
            when rct.org_id in ('498', '820', '578', '538', '758')
                and (oltype.name ilike 'CREDIT NO RETURN%' or rsbs.name ilike 'MANUAL%')
                then 0
            when rct.org_id in ('498', '820', '578', '538', '758')
                and oltype.name not ilike 'CREDIT NO RETURN%'
                and rsbs.name not ilike 'MANUAL%'
                and oltype.name ilike any ('%RMA%', '%RETURN%')
                then coalesce(rctl.quantity_invoiced, quantity_credited, 0)
            when rct.org_id not in ('498', '820', '578', '538', '758')
                and oltype.name ilike any ('%RMA%', '%RETURN%')
                then coalesce(rctl.quantity_invoiced, quantity_credited, 0)
            else 0
        end as return_qty
        , psa.gl_date as date_posted
        , case
            when not coalesce(oltype.name, 'XX') ilike any ('%RMA%', '%RETURN%')
                then coalesce(aps.amount, rctl.extended_amount, 0)  --added 0 to coalesce logic to resolve nulls in older invoice records per QA feedback
                    * decode(rct.invoice_currency_code, 'USD', 1, rconv.conversion_rate)
            else 0
        end as revenue_dollars
        , case
            when oltype.name ilike any ('%RMA%', '%RETURN%')
                then coalesce(aps.amount, rctl.extended_amount)
                    * decode(rct.invoice_currency_code, 'USD', 1, rconv.conversion_rate)
            else 0
        end as actual_returns_dollars
        , null as shipment_type
        , 'MASTER LOCK' as source
        , ilol.rec_src     
        , hil.bkcc      
    from {{ ref('link_invoice_line_order_line') }} as ilol
        inner join {{ ref('hub_invoice_line_v1') }} as hil
            on ilol.invoice_line_hk = hil.invoice_line_hk
        inner join {{ ref('link_invoice_line') }} as lil
            on hil.invoice_line_hk = lil.invoice_line_hk
        inner join {{ ref('hub_invoice_header') }} as hih
            on lil.invoice_hk = hih.invoice_hk
        inner join cte_sat_invoice_header__ml_ebs__latest as rct
            on hih.invoice_hk = rct.invoice_hk
                and rct._fivetran_deleted = 'FALSE'
        inner join cte_sat_invoice_line__ml_ebs__latest as rctl
            on lil.invoice_line_hk = rctl.invoice_line_hk
                and rct.customer_trx_id = rctl.customer_trx_id
                and rct.org_id = rctl.org_id
                and rctl.line_type = 'LINE'
                and rctl.unit_selling_price != 0
                and rctl._fivetran_deleted = 'FALSE'
        inner join cte_sat_invoice_line_gl_dist__ml_ebs__latest_max as aps
            on rctl.invoice_line_hk = aps.invoice_line_hk
                and aps.gl_posted_date is not null
                and aps.account_class = 'REV'
        inner join {{ ref('link_invoice_payment_schedule') }} as ips
            on hih.invoice_hk = ips.invoice_hk
        inner join {{ ref('hub_payment_schedule') }} as hpays
            on ips.payment_schedule_hk = hpays.payment_schedule_hk
        inner join cte_sat_customer_account__ml_ebs__latest as hca
            on coalesce(rct.sold_to_customer_id, rct.bill_to_customer_id) = hca.cust_account_id
        inner join cte_sat_payment_schedule_all__ml_ebs__latest as psa
            on hpays.payment_schedule_hk = psa.payment_schedule_hk
                and psa.class || '' in ('INV', 'DM', 'CM')
                and psa._fivetran_deleted = 'FALSE'
        left join cte_sat_item_base__ml_ebs__latest as ml
            on to_char(rctl.inventory_item_id) = to_char(ml.inventory_item_id)
        left join {{ ref('hub_item_v1') }} as hi
            on ml.item_hk = hi.item_hk
        left join cte_sat_order_lines_all__ml_ebs__latest as ola
            on ilol.order_line_hk = ola.order_line_hk
                and ola._fivetran_deleted = 'FALSE'
        left join cte_ref_sat_transaction_types__ml_ebs__latest as oltype
            on ola.line_type_id = oltype.transaction_type_bk
        left join cte_ref_sat_batch_sources__ml_ebs__latest as rsbs
            on rct.batch_source_id = rsbs.batch_source_id
                and rct.org_id = rsbs.org_id
        left join cte_ref_sat_memo_line__ml_ebs__latest as rsml
            on rctl.memo_line_id = rsml.memo_line_id
                and rctl.org_id = rsml.org_id
        left join cte_ref_sat_currency_rates__ml_ebs__latest as rconv
            on rct.invoice_currency_code = rconv.from_currency
                and rconv.to_currency = 'USD'
                and rconv.conversion_type = 'Spot'
                and psa.gl_date = rconv.conversion_date
        left join {{ ref('hub_party') }} as hup
            on hca.party_hk = hup.party_hk
        left join cte_sat_party__ml_ebs__latest as hp
            on hca.party_hk = hp.party_hk
        left join cte_sat_cust_site_use__ml_ebs__latest as hcs
            on rct.bill_to_site_use_id = hcs.site_use_id
                and hcs.site_use_code = 'BILL_TO'
        left join cte_sat_cust_acct_site__ml_ebs__latest as hcasa
            on hcs.cust_acct_site_hk = hcasa.cust_acct_site_hk
        left join cte_sat_party_site__ml_ebs__latest as hps
            on hcasa.party_site_id = hps.party_site_id
        left join cte_sat_location__ml_ebs__latest as hl
            on hps.location_id = hl.location_id
        left join {{ ref('hub_location_v1') }} as hloc
            on hl.location_hk = hloc.location_hk
    where (
        coalesce(ola.item_type_code, 'OTHER') not in ('OPTION', 'CLASS', 'CONFIG')
    ) and upper(hca.customer_class_code) not in ('INTERCOMPANY SALES', 'MLC SUBSIDIARY')
    and rsbs.name != 'Conversion Batch Source' -- YALE data 
    and coalesce(rsml.attribute2, 'Y') = 'Y'
    and rct.complete_flag = 'Y'
    and coalesce(rctl.description, 'No Description') != 'Freight'
)

, base_adj_invoice as (
    select
        md5_binary(concat(coalesce(hih.invoice_bk, ''), '||', coalesce(sadj.adjustment_id, ''))) as shipment_hk
        , hih.invoice_hk
        , null as item_id
        , hpays.payment_schedule_hk
        , hup.party_hk as customer_hk
        , sadj.adjustment_id
        , null as base_material_id
        , hih.invoice_bk
        , concat(coalesce(hih.invoice_bk, ''), '||', coalesce(sadj.adjustment_id, '')) as shipment_id
        , hpays.payment_schedule_bk
        , null as item_number
        , null as base_material
        , to_char(hp.party_id) as customer_id
        , hloc.location_bk as location_id
        , hp.party_name as customer
        , hca.key_account_number
        , null as customer_account_name
        , null as sales_org
        , null as channel
        , 0 as invoiced_qty
        , 0 as return_qty
        , sadj.gl_date as date_posted
        , decode(
            sadj.type
            , 'INVOICE', coalesce(sadj.amount, 0)
            , 'LINE', coalesce(sadj.amount, 0)
            , 'CHARGES', coalesce(sadj.receivables_charges_adjusted, 0)
        )
        * decode(rct.invoice_currency_code, 'USD', 1, rconv.conversion_rate) as revenue_dollars
        , 0 as actual_returns_dollars
        , null as shipment_type
        , 'MASTER LOCK' as source
        , ips.rec_src
        , hih.bkcc
    from {{ ref('link_invoice_payment_schedule') }} as ips
        inner join {{ ref('hub_invoice_header') }} as hih
            on ips.invoice_hk = hih.invoice_hk
        inner join {{ ref('hub_payment_schedule') }} as hpays
            on ips.payment_schedule_hk = hpays.payment_schedule_hk
        inner join cte_sat_invoice_header__ml_ebs__latest as rct
            on hih.invoice_hk = rct.invoice_hk
                and rct._fivetran_deleted = 'FALSE'
        inner join cte_sat_invoice_adjustments__ml_ebs__latest as sadj
            on hih.invoice_hk = sadj.invoice_hk
                and sadj.customer_trx_line_id is null
                and sadj._fivetran_deleted = 'FALSE'
        inner join cte_ref_sat_receivables_trx__ml_ebs__latest as rart
            on sadj.receivables_trx_id = rart.receivables_trx_id
                and sadj.org_id = rart.org_id
        inner join cte_sat_customer_account__ml_ebs__latest as hca
            on coalesce(rct.sold_to_customer_id, rct.bill_to_customer_id) = hca.cust_account_id
        left join cte_ref_sat_batch_sources__ml_ebs__latest as rsbs
            on rct.batch_source_id = rsbs.batch_source_id
                and rct.org_id = rsbs.org_id
        left join cte_ref_sat_currency_rates__ml_ebs__latest as rconv
            on rct.invoice_currency_code = rconv.from_currency
                and rconv.to_currency = 'USD'
                and rconv.conversion_type = 'Spot'
                and sadj.gl_date = rconv.conversion_date
        left join {{ ref('hub_party') }} as hup
            on hca.party_hk = hup.party_hk
        left join cte_sat_party__ml_ebs__latest as hp
            on hca.party_hk = hp.party_hk
        left join cte_sat_cust_site_use__ml_ebs__latest as hcs
            on rct.bill_to_site_use_id = hcs.site_use_id
                and hcs.site_use_code = 'BILL_TO'
        left join cte_sat_cust_acct_site__ml_ebs__latest as hcasa
            on hcs.cust_acct_site_hk = hcasa.cust_acct_site_hk
        left join cte_sat_party_site__ml_ebs__latest as hps
            on hcasa.party_site_id = hps.party_site_id
        left join cte_sat_location__ml_ebs__latest as hl
            on hps.location_id = hl.location_id
        left join {{ ref('hub_location_v1') }} as hloc
            on hl.location_hk = hloc.location_hk
    where 1 = 1
        and sadj.status = 'A'
        and sadj.type in ('INVOICE', 'LINE', 'CHARGES')
        and rsbs.name != 'Conversion Batch Source' -- YALE data 
        and rart.type = 'ADJUST'
        and coalesce(rart.attribute2, 'N') = 'Y'
        and upper(hca.customer_class_code) not in ('INTERCOMPANY SALES', 'MLC SUBSIDIARY')
)

select
    shipment_hk as shipment_id
    , item_id
    , base_material_id
    , customer_id
    , location_id
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
    , coalesce(revenue_dollars, 0) as revenue_dollars --added coalesce to resolve null revenue_dollars on old invoice records per QA's feedback
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

union

select
    shipment_hk as shipment_id
    , item_id
    , base_material_id
    , customer_id
    , location_id
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
    , coalesce(revenue_dollars, 0) as revenue_dollars  --added coalesce to resolve null revenue_dollars on old invoice records per QA's feedback
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
from base_adj_invoice
