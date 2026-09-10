/*
    HUB: Invoice

    Sales_Invoice – Filter to just "INV" type records (exclude conversion records).
    Use Invoice_no, rcta.order_no, org_id as natural combo key

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
        type as transaction_type -- such as INV, CM, DM, or CB	
        , cust_trx_type_id
        , org_id
    from {{ source('emtk_ebs_sales__ar', 'ra_cust_trx_types_all') }}
    where _fivetran_deleted = false
)

, cte_ra_customer_trx_all as (
    select
        trx_number
        , org_id
        , interface_header_attribute2
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
        -- to eliminate nulls only
        , CAST(COALESCE(interface_header_attribute1, '-1') as VARCHAR) as interface_header_attribute1
    from {{ source('emtk_ebs_sales__ar', 'ra_customer_trx_all') }}
    where _fivetran_deleted = false
)

, cte_jtf_salesrep_lookup as (
    select
        salesrep_id -- sales rep join key
        , org_id -- BK
        , salesrep_number -- BK 
    from {{ source('emtk_ebs_sales__jtf', 'jtf_rs_salesreps') }}
    where _fivetran_deleted = false

)


, cte_invoice as (
    select
        rcta.org_id -- 101,'EMTEK', 181, 'SCHAUB' 
        , rcta.trx_number -- invoice_no
        , rcta.interface_header_attribute1 -- order_num
        , rcta.interface_header_attribute2 -- order_type description
        , rcta.cust_trx_type_id -- order_type ID 
        , rctta.transaction_type
        , rcta.customer_trx_id
        , rcta.trx_date
        -- all remaining columns from cte_ra_customer_trx_all
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
        , rcta.bill_to_customer_id
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
        , COALESCE(sl.salesrep_number, '-1') as salesrep_number -- BK 
    from cte_ra_customer_trx_all as rcta
        inner join
            cte_ra_cust_trx_types_all as rctta
            on rcta.cust_trx_type_id = rctta.cust_trx_type_id
                and rcta.org_id = rctta.org_id
        left outer join
            cte_jtf_salesrep_lookup as sl
            on rcta.primary_salesrep_id = sl.salesrep_id
                and rcta.org_id = sl.org_id
    where rctta.transaction_type = 'INV' -- ONLY invoice types
        and (
            LENGTH(rcta.interface_header_attribute2) > 3 -- filter out Schaub conversion records from 2019
            or rcta.interface_header_attribute2 is null
        )
)

select * from cte_invoice
