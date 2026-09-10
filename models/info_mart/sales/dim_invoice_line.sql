-- dim invoice line

with cte_hub_invoice_line as (
    select * from {{ ref('hub_invoice_line') }}
)

, cte_sat_invoice_line_detail__emtk_ebs as (
    select * from {{ ref('sat_invoice_line_detail__emtk_ebs') }}
)

, cte_sat_invoice_line_detail__emtk_ebs__latest as (
    {{ generate_cte_satellite_latest(
        cte_name='cte_sat_invoice_line_detail__emtk_ebs'
        ,hk_field='invoice_line_hk') }}
)

, cte_sat_invoice_line_detail__emtk_ebs__renamed as (
    select
        invoice_line_hk
        , customer_trx_line_id
        , customer_trx_id
        , line_number
        , reason_code
        , inventory_item_id
        , description
        , previous_customer_trx_id
        , previous_customer_trx_line_id
        , quantity_ordered
        , quantity_credited
        , quantity_invoiced
        , unit_standard_price
        , unit_selling_price
        , sales_order
        , sales_order_line
        , sales_order_date
        , line_type
        , attribute1
        , attribute2
        , attribute3
        , attribute4
        , attribute5
        , attribute6
        , attribute7
        , attribute8
        , attribute9
        , attribute10
        , request_id
        , program_application_id
        , program_id
        , program_update_date
        , rule_start_date
        , interface_line_context
        , interface_line_attribute1
        , interface_line_attribute2 as line_order_type
        , interface_line_attribute3
        , interface_line_attribute4
        , interface_line_attribute5
        , interface_line_attribute6
        , extended_amount
        , revenue_amount
        , link_to_cust_trx_line_id
        , attribute11
        , attribute12
        , attribute13
        , attribute14
        , attribute15
        , tax_rate
        , tax_exemption_id
        , memo_line_id
        , uom_code
        , interface_line_attribute10
        , interface_line_attribute12
        , interface_line_attribute9
        , vat_tax_id
        , autotax
        , tax_exempt_flag
        , tax_exempt_number
        , sales_tax_id
        , location_segment_id
        , org_id
        , taxable_amount
        , warehouse_id
        , translated_description
        , payment_set_id
        , ship_to_customer_id
        , ship_to_address_id
        , ship_to_site_use_id
        , tax_line_id
        , line_recoverable
        , tax_recoverable
        , tax_classification_code
        , amount_due_original
        , acctd_amount_due_original
        , payment_trxn_extension_id
        , creation_date as src_created_at
        , last_update_date as src_last_updated_at
        , load_dts as valid_from
    from cte_sat_invoice_line_detail__emtk_ebs__latest
)

, cte_invoice_line as (
    select
        hub.invoice_line_hk as dim_invoice_line_pk
        , hub.invoice_line_bk
        , hub.brand
        , sat.customer_trx_line_id
        , sat.customer_trx_id
        , sat.line_number
        , sat.reason_code
        , sat.inventory_item_id
        , sat.description
        , sat.previous_customer_trx_id
        , sat.previous_customer_trx_line_id
        , sat.quantity_ordered
        , sat.quantity_credited
        , sat.quantity_invoiced
        , sat.unit_standard_price
        , sat.unit_selling_price
        , sat.sales_order
        , sat.sales_order_line
        , sat.sales_order_date
        , sat.line_type
        , sat.attribute1
        , sat.attribute2
        , sat.attribute3
        , sat.attribute4
        , sat.attribute5
        , sat.attribute6
        , sat.attribute7
        , sat.attribute8
        , sat.attribute9
        , sat.attribute10
        , sat.request_id
        , sat.program_application_id
        , sat.program_id
        , sat.program_update_date
        , sat.rule_start_date
        , sat.interface_line_context
        , sat.interface_line_attribute1
        , sat.line_order_type
        , sat.interface_line_attribute3
        , sat.interface_line_attribute4
        , sat.interface_line_attribute5
        , sat.interface_line_attribute6
        , sat.extended_amount
        , sat.revenue_amount
        , sat.link_to_cust_trx_line_id
        , sat.attribute11
        , sat.attribute12
        , sat.attribute13
        , sat.attribute14
        , sat.attribute15
        , sat.tax_rate
        , sat.tax_exemption_id
        , sat.memo_line_id
        , sat.uom_code
        , sat.interface_line_attribute10
        , sat.interface_line_attribute12
        , sat.interface_line_attribute9
        , sat.vat_tax_id
        , sat.autotax
        , sat.tax_exempt_flag
        , sat.tax_exempt_number
        , sat.sales_tax_id
        , sat.location_segment_id
        , sat.org_id
        , sat.taxable_amount
        , sat.warehouse_id
        , sat.translated_description
        , sat.payment_set_id
        , sat.ship_to_customer_id
        , sat.ship_to_address_id
        , sat.ship_to_site_use_id
        , sat.tax_line_id
        , sat.line_recoverable
        , sat.tax_recoverable
        , sat.tax_classification_code
        , sat.amount_due_original
        , sat.acctd_amount_due_original
        , sat.payment_trxn_extension_id
        , sat.src_created_at
        , sat.src_last_updated_at
        , sat.valid_from
    from cte_hub_invoice_line as hub
        inner join cte_sat_invoice_line_detail__emtk_ebs__renamed as sat
            on hub.invoice_line_hk = sat.invoice_line_hk
)

, cte_default as (
    select
        CAST(MD5_BINARY(-1) as BINARY(16)) as dim_invoice_line_pk
        , null as invoice_line_bk
        , null as sub_brand
        , null as customer_trx_line_id
        , null as customer_trx_id
        , null as line_number
        , null as reason_code
        , null as inventory_item_id
        , null as description
        , null as previous_customer_trx_id
        , null as previous_customer_trx_line_id
        , null as quantity_ordered
        , null as quantity_credited
        , null as quantity_invoiced
        , null as unit_standard_price
        , null as unit_selling_price
        , null as sales_order
        , null as sales_order_line
        , null as sales_order_date
        , null as line_type
        , null as attribute1
        , null as attribute2
        , null as attribute3
        , null as attribute4
        , null as attribute5
        , null as attribute6
        , null as attribute7
        , null as attribute8
        , null as attribute9
        , null as attribute10
        , null as request_id
        , null as program_application_id
        , null as program_id
        , null as program_update_date
        , null as rule_start_date
        , null as interface_line_context
        , null as interface_line_attribute1
        , null as line_order_type
        , null as interface_line_attribute3
        , null as interface_line_attribute4
        , null as interface_line_attribute5
        , null as interface_line_attribute6
        , null as extended_amount
        , null as revenue_amount
        , null as link_to_cust_trx_line_id
        , null as attribute11
        , null as attribute12
        , null as attribute13
        , null as attribute14
        , null as attribute15
        , null as tax_rate
        , null as tax_exemption_id
        , null as memo_line_id
        , null as uom_code
        , null as interface_line_attribute10
        , null as interface_line_attribute12
        , null as interface_line_attribute9
        , null as vat_tax_id
        , null as autotax
        , null as tax_exempt_flag
        , null as tax_exempt_number
        , null as sales_tax_id
        , null as location_segment_id
        , null as org_id
        , null as taxable_amount
        , null as warehouse_id
        , null as translated_description
        , null as payment_set_id
        , null as ship_to_customer_id
        , null as ship_to_address_id
        , null as ship_to_site_use_id
        , null as tax_line_id
        , null as line_recoverable
        , null as tax_recoverable
        , null as tax_classification_code
        , null as amount_due_original
        , null as acctd_amount_due_original
        , null as payment_trxn_extension_id
        , null as src_created_at
        , null as src_last_updated_at
        , TO_TIMESTAMP('1900-01-01') as valid_from
)

, cte_final as (
    select * from cte_invoice_line
    union all
    select * from cte_default
)

select * from cte_final
