/*
    LINK: Invoice invoice-line link
*/

with
cte_ra_customer_trx_lines_all as (
    select
        customer_trx_line_id::varchar as customer_trx_line_id -- BK
        , last_update_date
        , _fivetran_synced
        , last_updated_by
        , creation_date
        , created_by
        , last_update_login
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

, cte_ra_customer_trx_all as (
    select
        trx_number
        , interface_header_attribute2
        , org_id
        , customer_trx_id
        , last_update_date
        , _fivetran_synced
        , last_updated_by
        , creation_date
        , created_by
        , last_update_login
        , cust_trx_type_id
        , trx_date
        , bill_to_contact_id
        , batch_id
        , batch_source_id
        , reason_code
        , sold_to_customer_id
        , bill_to_customer_id
        , bill_to_site_use_id
        , ship_to_customer_id
        , ship_to_contact_id
        , ship_to_site_use_id
        , remit_to_address_id
        , term_id
        , term_due_date
        , previous_customer_trx_id
        , primary_salesrep_id
        , printing_original_date
        , printing_last_printed
        , printing_option
        , printing_count
        , printing_pending
        , purchase_order
        , customer_reference
        , customer_reference_date
        , territory_id
        , attribute1
        , attribute2
        , attribute3
        , attribute4
        , attribute5
        , attribute6
        , attribute8
        , attribute9
        , attribute10
        , orig_system_batch_name
        , request_id
        , program_application_id
        , program_id
        , program_update_date
        , complete_flag
        , receipt_method_id
        , attribute11
        , attribute12
        , attribute13
        , attribute14
        , attribute15
        , ship_via
        , ship_date_actual
        , fob_point
        , customer_bank_account_id
        , interface_header_attribute3
        , interface_header_attribute4
        , interface_header_attribute5
        , interface_header_attribute6
        , interface_header_context
        , interface_header_attribute10
        , interface_header_attribute12
        , interface_header_attribute9
        , status_trx
        , doc_sequence_value
        , paying_customer_id
        , paying_site_use_id
        , created_from
        , payment_server_order_num
        , approval_code
        , ct_reference
        , bill_template_id
        , upgrade_method
        , legal_entity_id
        , payment_trxn_extension_id
        , payment_attributes
        , coalesce(interface_header_attribute1, '-1') as interface_header_attribute1
    from {{ source('emtk_ebs_sales__ar', 'ra_customer_trx_all') }}
    where _fivetran_deleted = false
)

, cte_ra_cust_trx_types_all as (
    select
        type
        , cust_trx_type_id
        , last_update_date
        , _fivetran_synced
        , last_updated_by
        , creation_date
        , created_by
        , last_update_login
        , post_to_gl
        , accounting_affect_flag
        , credit_memo_type_id
        , name
        , description
        , default_term
        , default_printing_option
        , default_status
        , gl_id_rev
        , gl_id_freight
        , gl_id_rec
        , set_of_books_id
        , allow_freight_flag
        , allow_overapplication_flag
        , creation_sign
        , end_date
        , start_date
        , tax_calculation_flag
        , natural_application_only_flag
        , org_id
        , zd_sync
    from {{ source('emtk_ebs_sales__ar', 'ra_cust_trx_types_all') }}
    where _fivetran_deleted = false
)

, cte_invoice_line_filtered as (
    select
        rctla.customer_trx_line_id -- BK
        , rcta.org_id -- 101,'EMTEK', 181, 'SCHAUB' 
        , rcta.trx_number -- invoice_no
        , rcta.interface_header_attribute1 -- "order_num" 
        , rcta.interface_header_attribute2 -- "order_type" 
        , rcta.cust_trx_type_id -- type key join (e.g. "Emtek Invoice", "Schaub Invoice"
        , rctla._fivetran_synced
    from cte_ra_customer_trx_lines_all as rctla
        inner join cte_ra_customer_trx_all as rcta
            on rctla.customer_trx_id = rcta.customer_trx_id
                and rctla.org_id = rcta.org_id
        inner join
            cte_ra_cust_trx_types_all as rctta
            on rcta.cust_trx_type_id = rctta.cust_trx_type_id
                and rcta.org_id = rctta.org_id
    where rctta.type = 'INV' -- ONLY invoice types
        and (
            length(rcta.interface_header_attribute2) > 3 -- filter out Schaub conversion records from 2019
            or rcta.interface_header_attribute2 is null
        )
)

select * from cte_invoice_line_filtered
