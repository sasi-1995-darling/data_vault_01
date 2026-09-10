/*
    HUB: Invoice Line

    Lines have 3 types, "LINE", "FREIGHT" and "TAX".
    The Discoverer report filtered out the "TAX", but we'll probably want to bring those records into Snowflake anyway.
    The invoice lines can tie back to both the Sales Invoice records as well as the Sales Invoice Adjusments.
    In this link, we'll use the system key at the PK as there is no other consistent NK.

*/

with
cte_ra_customer_trx_lines_all as (
    select
        customer_trx_line_id::varchar as customer_trx_line_id -- BK
        , customer_trx_id
        , last_update_date
        , _fivetran_synced
        , last_updated_by
        , creation_date
        , created_by
        , last_update_login
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
        , interface_line_attribute2
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
    from {{ source('emtk_ebs_sales__ar', 'ra_customer_trx_lines_all') }}
    where _fivetran_deleted = false
)

, cte_mtl_system_items_b as (
    select
        inventory_item_id
        , organization_id
        , segment1
    from {{ source('emtk_ebs_common__inv', 'mtl_system_items_b') }}
    where _fivetran_deleted = false
)

, cte_ap_financials_system_params_all as (
    select
        last_update_date
        , _fivetran_synced
        , last_updated_by
        , bill_to_location_id
        , accts_pay_code_combination_id
        , prepay_code_combination_id
        , disc_taken_code_combination_id
        , inventory_organization_id
        , last_update_login
        , creation_date
        , created_by
        , org_id
    from {{ source('emtk_ebs_sales__ap', 'financials_system_params_all') }}
    where _fivetran_deleted = false
)

, cte_item_bk as (
    select
        fp.org_id
        , si.segment1
        , si.inventory_item_id
        , si.organization_id
    from
        cte_mtl_system_items_b as si
        inner join
            cte_ap_financials_system_params_all as fp
            on si.organization_id = fp.inventory_organization_id
)

, cte_final as (
    select
        rctla.customer_trx_line_id -- BK
        , rctla.customer_trx_id
        , rctla.last_update_date
        , rctla._fivetran_synced
        , rctla.last_updated_by
        , rctla.creation_date
        , rctla.created_by
        , rctla.last_update_login
        , rctla.line_number
        , rctla.reason_code
        , rctla.inventory_item_id
        , rctla.description
        , rctla.previous_customer_trx_id
        , rctla.previous_customer_trx_line_id
        , rctla.quantity_ordered
        , rctla.quantity_credited
        , rctla.quantity_invoiced
        , rctla.unit_standard_price
        , rctla.unit_selling_price
        , rctla.sales_order
        , rctla.sales_order_line
        , rctla.sales_order_date
        , rctla.line_type
        , rctla.attribute1
        , rctla.attribute2
        , rctla.attribute3
        , rctla.attribute4
        , rctla.attribute5
        , rctla.attribute6
        , rctla.attribute7
        , rctla.attribute8
        , rctla.attribute9
        , rctla.attribute10
        , rctla.request_id
        , rctla.program_application_id
        , rctla.program_id
        , rctla.program_update_date
        , rctla.rule_start_date
        , rctla.interface_line_context
        , rctla.interface_line_attribute1
        , rctla.interface_line_attribute2
        , rctla.interface_line_attribute3
        , rctla.interface_line_attribute4
        , rctla.interface_line_attribute5
        , rctla.interface_line_attribute6
        , rctla.extended_amount
        , rctla.revenue_amount
        , rctla.link_to_cust_trx_line_id
        , rctla.attribute11
        , rctla.attribute12
        , rctla.attribute13
        , rctla.attribute14
        , rctla.attribute15
        , rctla.tax_rate
        , rctla.tax_exemption_id
        , rctla.memo_line_id
        , rctla.uom_code
        , rctla.interface_line_attribute10
        , rctla.interface_line_attribute12
        , rctla.interface_line_attribute9
        , rctla.vat_tax_id
        , rctla.autotax
        , rctla.tax_exempt_flag
        , rctla.tax_exempt_number
        , rctla.sales_tax_id
        , rctla.location_segment_id
        , rctla.org_id
        , rctla.taxable_amount
        , rctla.warehouse_id
        , rctla.translated_description
        , rctla.payment_set_id
        , rctla.ship_to_customer_id
        , rctla.ship_to_address_id
        , rctla.ship_to_site_use_id
        , rctla.tax_line_id
        , rctla.line_recoverable
        , rctla.tax_recoverable
        , rctla.tax_classification_code
        , rctla.amount_due_original
        , rctla.acctd_amount_due_original
        , rctla.payment_trxn_extension_id
        , coalesce(i.org_id, -1) as item_org_id -- item BK
        , coalesce(i.segment1, '-1') as item_segment1 -- item BK
        , i.organization_id

    from cte_ra_customer_trx_lines_all as rctla
        left outer join cte_item_bk as i 
            on rctla.inventory_item_id = i.inventory_item_id
                and i.organization_id = COALESCE(rctla.warehouse_id, 182)
)

select * from cte_final
