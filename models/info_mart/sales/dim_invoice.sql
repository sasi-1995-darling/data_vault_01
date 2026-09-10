-- dim invoice

with cte_hub_invoice as (
    select * from {{ ref('hub_invoice') }}
)

, cte_sat_invoice_detail__emtk_ebs as (
    select * from {{ ref('sat_invoice_detail__emtk_ebs') }}
)

, cte_sat_invoice_detail__emtk_ebs__latest as (
    {{ generate_cte_satellite_latest(
        cte_name='cte_sat_invoice_detail__emtk_ebs'
        ,hk_field='invoice_hk') }}
)

, cte_sat_invoice_detail__emtk_ebs__renamed as (
    select
        invoice_hk
        , org_id
        , trx_number
        , interface_header_attribute1 as order_num
        , interface_header_attribute2 as order_type
        , cust_trx_type_id
        , transaction_type
        , customer_trx_id
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
        , creation_date as src_created_at
        , last_update_date as src_last_updated_at
        , load_dts as valid_from
    from cte_sat_invoice_detail__emtk_ebs__latest
)

, cte_invoice as (
    select
        hub.invoice_hk as dim_invoice_pk
        , hub.invoice_bk
        , hub.brand
        , sat.org_id
        , sat.trx_number
        , sat.order_num -- interface_header_attribute1
        , sat.order_type -- interface_header_attribute2
        , sat.cust_trx_type_id
        , sat.transaction_type
        , sat.customer_trx_id
        , sat.trx_date
        , sat.bill_to_contact_id
        , sat.bill_to_customer_id
        , sat.batch_id
        , sat.batch_source_id
        , sat.reason_code
        , sat.sold_to_customer_id
        , sat.bill_to_site_use_id
        , sat.ship_to_customer_id
        , sat.ship_to_contact_id
        , sat.ship_to_site_use_id
        , sat.remit_to_address_id
        , sat.term_id
        , sat.term_due_date
        , sat.previous_customer_trx_id
        , sat.primary_salesrep_id
        , sat.printing_original_date
        , sat.printing_last_printed
        , sat.printing_option
        , sat.printing_count
        , sat.printing_pending
        , sat.purchase_order
        , sat.customer_reference
        , sat.customer_reference_date
        , sat.territory_id
        , sat.attribute1
        , sat.attribute2
        , sat.attribute3
        , sat.attribute4
        , sat.attribute5
        , sat.attribute6
        , sat.attribute8
        , sat.attribute9
        , sat.attribute10
        , sat.orig_system_batch_name
        , sat.request_id
        , sat.program_application_id
        , sat.program_id
        , sat.program_update_date
        , sat.complete_flag
        , sat.receipt_method_id
        , sat.attribute11
        , sat.attribute12
        , sat.attribute13
        , sat.attribute14
        , sat.attribute15
        , sat.ship_via
        , sat.ship_date_actual
        , sat.fob_point
        , sat.customer_bank_account_id
        , sat.interface_header_attribute3
        , sat.interface_header_attribute4
        , sat.interface_header_attribute5
        , sat.interface_header_attribute6
        , sat.interface_header_context
        , sat.interface_header_attribute10
        , sat.interface_header_attribute12
        , sat.interface_header_attribute9
        , sat.status_trx
        , sat.doc_sequence_value
        , sat.paying_customer_id
        , sat.paying_site_use_id
        , sat.created_from
        , sat.payment_server_order_num
        , sat.approval_code
        , sat.ct_reference
        , sat.bill_template_id
        , sat.upgrade_method
        , sat.legal_entity_id
        , sat.payment_trxn_extension_id
        , sat.payment_attributes
        , sat.src_created_at
        , sat.src_last_updated_at
        , sat.valid_from
    from cte_hub_invoice as hub
        inner join cte_sat_invoice_detail__emtk_ebs__renamed as sat
            on hub.invoice_hk = sat.invoice_hk
)

, cte_default as (
    select
        CAST(MD5_BINARY(-1) as BINARY(16)) as dim_invoice_pk
        , null as invoice_bk
        , null as sub_brand
        , null as org_id
        , null as trx_number
        , null as order_num
        , null as order_type
        , null as cust_trx_type_id
        , null as transaction_type
        , null as customer_trx_id
        , null as trx_date
        , null as bill_to_contact_id
        , null as batch_id
        , null as batch_source_id
        , null as reason_code
        , null as sold_to_customer_id
        , null as bill_to_customer_id
        , null as bill_to_site_use_id
        , null as ship_to_customer_id
        , null as ship_to_contact_id
        , null as ship_to_site_use_id
        , null as remit_to_address_id
        , null as term_id
        , null as term_due_date
        , null as previous_customer_trx_id
        , null as primary_salesrep_id
        , null as printing_original_date
        , null as printing_last_printed
        , null as printing_option
        , null as printing_count
        , null as printing_pending
        , null as purchase_order
        , null as customer_reference
        , null as customer_reference_date
        , null as territory_id
        , null as attribute1
        , null as attribute2
        , null as attribute3
        , null as attribute4
        , null as attribute5
        , null as attribute6
        , null as attribute8
        , null as attribute9
        , null as attribute10
        , null as orig_system_batch_name
        , null as request_id
        , null as program_application_id
        , null as program_id
        , null as program_update_date
        , null as complete_flag
        , null as receipt_method_id
        , null as attribute11
        , null as attribute12
        , null as attribute13
        , null as attribute14
        , null as attribute15
        , null as ship_via
        , null as ship_date_actual
        , null as fob_point
        , null as customer_bank_account_id
        , null as interface_header_attribute3
        , null as interface_header_attribute4
        , null as interface_header_attribute5
        , null as interface_header_attribute6
        , null as interface_header_context
        , null as interface_header_attribute10
        , null as interface_header_attribute12
        , null as interface_header_attribute9
        , null as status_trx
        , null as doc_sequence_value
        , null as paying_customer_id
        , null as paying_site_use_id
        , null as created_from
        , null as payment_server_order_num
        , null as approval_code
        , null as ct_reference
        , null as bill_template_id
        , null as upgrade_method
        , null as legal_entity_id
        , null as payment_trxn_extension_id
        , null as payment_attributes
        , null as src_created_at
        , null as src_last_updated_at
        , TO_TIMESTAMP('1900-01-01') as valid_from
)

, cte_final as (
    select * from cte_invoice
    union all
    select * from cte_default
)


select * from cte_final
