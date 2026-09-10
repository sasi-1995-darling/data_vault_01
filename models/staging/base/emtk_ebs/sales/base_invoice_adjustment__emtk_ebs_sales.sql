/*
    HUB: Invoice Adjustment

    Sales_Invoice_Adjustment – Filter to "CM" and "DM" types  (exclude conversion records).
    Use Invoice_no, order_no, bill_to_customer_id, org_id as natural combo key.
    The bill_to_customer_id helps when order_num is blank.
    May still have some dupe so either use a date field to help pick or allow for it the key as transaction type

    Key fields and their better known alias.
    For the rest of this page, I may refer to either the Oracle Field name or its alias:
        TRX_NUMBER: "invoice_no"
        CUST_TRX_TYPE_ID: type key join (e.g. "Emtek Invoice", "Schaub Invoice", "Credit Memo", "Debit Memo Refund")
        INTERFACE_HEADER_ATTRIBUTE1: "order_num"
        INTERFACE_HEADER_ATTRIBUTE2: "order_type"
        ORG_ID: 101,'EMTEK', 181, 'SCHAUB'
*/

with
cte_ra_cust_trx_types_all as (
    select
        type as transaction_type -- such as INV, CM, DM, or CB	type
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

-- Use Invoice_no, order_no, bill_to_customer_id, org_id as natural combo key.
-- The bill_to_customer_id helps when order_num is blank.

, cte_invoice_adjustment as (
    select
        rcta.org_id -- BK
        , rcta.trx_number -- BK, invoice number 
        , rcta.interface_header_attribute1 -- BK, order number
        , rcta.interface_header_attribute2
        , rcta.cust_trx_type_id -- order_type ID 
        , rctta.transaction_type
        , rcta.customer_trx_id -- PK
        , rcta.trx_date -- BK, tie breaker
        -- all remaining columns from cte_ra_customer_trx_all
        , rcta.bill_to_customer_id -- excluded from BK
        , rcta.last_update_date
        , rcta._fivetran_synced
        , rcta.last_updated_by
        , rcta.creation_date
        , rcta.created_by
        , rcta.last_update_login
        , rcta.bill_to_contact_id
        , rcta.batch_id
        , rcta.batch_source_id
        , rcta.reason_code
        , rcta.sold_to_customer_id
        , rcta.bill_to_site_use_id
        , rcta.ship_to_customer_id
        , rcta.ship_to_contact_id
        , rcta.ship_to_site_use_id
        , rcta.remit_to_address_id
        , rcta.term_id
        , rcta.term_due_date
        , rcta.previous_customer_trx_id
        , rcta.primary_salesrep_id
        , rcta.printing_original_date
        , rcta.printing_last_printed
        , rcta.printing_option
        , rcta.printing_count
        , rcta.printing_pending
        , rcta.purchase_order
        , rcta.customer_reference
        , rcta.customer_reference_date
        , rcta.territory_id
        , rcta.attribute1
        , rcta.attribute2
        , rcta.attribute3
        , rcta.attribute4
        , rcta.attribute5
        , rcta.attribute6
        , rcta.attribute8
        , rcta.attribute9
        , rcta.attribute10
        , rcta.orig_system_batch_name
        , rcta.request_id
        , rcta.program_application_id
        , rcta.program_id
        , rcta.program_update_date
        , rcta.complete_flag
        , rcta.receipt_method_id
        , rcta.attribute11
        , rcta.attribute12
        , rcta.attribute13
        , rcta.attribute14
        , rcta.attribute15
        , rcta.ship_via
        , rcta.ship_date_actual
        , rcta.fob_point
        , rcta.customer_bank_account_id
        , rcta.interface_header_attribute3
        , rcta.interface_header_attribute4
        , rcta.interface_header_attribute5
        , rcta.interface_header_attribute6
        , rcta.interface_header_context
        , rcta.interface_header_attribute10
        , rcta.interface_header_attribute12
        , rcta.interface_header_attribute9
        , rcta.status_trx
        , rcta.doc_sequence_value
        , rcta.paying_customer_id
        , rcta.paying_site_use_id
        , rcta.created_from
        , rcta.payment_server_order_num
        , rcta.approval_code
        , rcta.ct_reference
        , rcta.bill_template_id
        , rcta.upgrade_method
        , rcta.legal_entity_id
        , rcta.payment_trxn_extension_id
        , rcta.payment_attributes
    from cte_ra_customer_trx_all as rcta
        inner join cte_ra_cust_trx_types_all as rctta on rcta.cust_trx_type_id = rctta.cust_trx_type_id
            and rcta.org_id = rctta.org_id
    where rctta.transaction_type in ('CM', 'DM') -- ONLY credit AND memo types 
        and (
            length(rcta.interface_header_attribute2) > 3 -- filter out Schaub conversion records from 2019 
            or rcta.interface_header_attribute2 is null
        )
)

select * from cte_invoice_adjustment
