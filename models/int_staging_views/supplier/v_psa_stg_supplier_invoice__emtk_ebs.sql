---- SRC LAYER ----
WITH
SRC_SRC            as ( SELECT * FROM {{ source('emtk_ebs_ap', 'ap_invoices_all') }} as SRC  ),
SRC_ref_bkcc       as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC 
                        WHERE rec_src = 'USWIOC.ORCL.EBSEMTK.AP_INVOICES_ALL' )

/*
SRC_SRC            as ( SELECT * FROM emtk_ebs_ap.ap_invoices_all )
SRC_ref_bkcc       as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_SRC as (
    SELECT
        INVOICE_ID                                                   as                                      INVOICE_ID_BK
      , INVOICE_ID
      , LAST_UPDATE_DATE
      , LAST_UPDATED_BY
      , VENDOR_ID
      , INVOICE_NUM
      , SET_OF_BOOKS_ID
      , INVOICE_CURRENCY_CODE
      , PAYMENT_CURRENCY_CODE
      , PAYMENT_CROSS_RATE
      , INVOICE_AMOUNT
      , VENDOR_SITE_ID
      , AMOUNT_PAID
      , DISCOUNT_AMOUNT_TAKEN
      , INVOICE_DATE
      , SOURCE
      , INVOICE_TYPE_LOOKUP_CODE
      , DESCRIPTION
      , BATCH_ID
      , AMOUNT_APPLICABLE_TO_DISCOUNT
      , TAX_AMOUNT
      , TERMS_ID
      , TERMS_DATE
      , PAYMENT_METHOD_LOOKUP_CODE
      , ACCTS_PAY_CODE_COMBINATION_ID
      , PAYMENT_STATUS_FLAG
      , CREATION_DATE
      , CREATED_BY
      , BASE_AMOUNT
      , VAT_CODE
      , LAST_UPDATE_LOGIN
      , EXCLUSIVE_PAYMENT_FLAG
      , PO_HEADER_ID
      , FREIGHT_AMOUNT
      , GOODS_RECEIVED_DATE
      , INVOICE_RECEIVED_DATE
      , VOUCHER_NUM
      , APPROVED_AMOUNT
      , RECURRING_PAYMENT_ID
      , EXCHANGE_RATE
      , EXCHANGE_RATE_TYPE
      , EXCHANGE_DATE
      , EARLIEST_SETTLEMENT_DATE
      , ORIGINAL_PREPAYMENT_AMOUNT
      , DOC_SEQUENCE_ID
      , DOC_SEQUENCE_VALUE
      , DOC_CATEGORY_CODE
      , ATTRIBUTE1
      , ATTRIBUTE2
      , ATTRIBUTE3
      , ATTRIBUTE4
      , ATTRIBUTE5
      , ATTRIBUTE6
      , ATTRIBUTE7
      , ATTRIBUTE8
      , ATTRIBUTE9
      , ATTRIBUTE10
      , ATTRIBUTE11
      , ATTRIBUTE12
      , ATTRIBUTE13
      , ATTRIBUTE14
      , ATTRIBUTE15
      , ATTRIBUTE_CATEGORY
      , APPROVAL_STATUS
      , APPROVAL_DESCRIPTION
      , INVOICE_DISTRIBUTION_TOTAL
      , POSTING_STATUS
      , PREPAY_FLAG
      , AUTHORIZED_BY
      , CANCELLED_DATE
      , CANCELLED_BY
      , CANCELLED_AMOUNT
      , TEMP_CANCELLED_AMOUNT
      , PROJECT_ACCOUNTING_CONTEXT
      , USSGL_TRANSACTION_CODE
      , USSGL_TRX_CODE_CONTEXT
      , PROJECT_ID
      , TASK_ID
      , EXPENDITURE_TYPE
      , EXPENDITURE_ITEM_DATE
      , PA_QUANTITY
      , EXPENDITURE_ORGANIZATION_ID
      , PA_DEFAULT_DIST_CCID
      , VENDOR_PREPAY_AMOUNT
      , PAYMENT_AMOUNT_TOTAL
      , AWT_FLAG
      , AWT_GROUP_ID
      , REFERENCE_1
      , REFERENCE_2
      , ORG_ID
      , PRE_WITHHOLDING_AMOUNT
      , GLOBAL_ATTRIBUTE_CATEGORY
      , GLOBAL_ATTRIBUTE1
      , GLOBAL_ATTRIBUTE2
      , GLOBAL_ATTRIBUTE3
      , GLOBAL_ATTRIBUTE4
      , GLOBAL_ATTRIBUTE5
      , GLOBAL_ATTRIBUTE6
      , GLOBAL_ATTRIBUTE7
      , GLOBAL_ATTRIBUTE8
      , GLOBAL_ATTRIBUTE9
      , GLOBAL_ATTRIBUTE10
      , GLOBAL_ATTRIBUTE11
      , GLOBAL_ATTRIBUTE12
      , GLOBAL_ATTRIBUTE13
      , GLOBAL_ATTRIBUTE14
      , GLOBAL_ATTRIBUTE15
      , GLOBAL_ATTRIBUTE16
      , GLOBAL_ATTRIBUTE17
      , GLOBAL_ATTRIBUTE18
      , GLOBAL_ATTRIBUTE19
      , GLOBAL_ATTRIBUTE20
      , AUTO_TAX_CALC_FLAG
      , PAYMENT_CROSS_RATE_TYPE
      , PAYMENT_CROSS_RATE_DATE
      , PAY_CURR_INVOICE_AMOUNT
      , MRC_BASE_AMOUNT
      , MRC_EXCHANGE_RATE
      , MRC_EXCHANGE_RATE_TYPE
      , MRC_EXCHANGE_DATE
      , GL_DATE
      , AWARD_ID
      , PAID_ON_BEHALF_EMPLOYEE_ID
      , AMT_DUE_CCARD_COMPANY
      , AMT_DUE_EMPLOYEE
      , APPROVAL_READY_FLAG
      , APPROVAL_ITERATION
      , WFAPPROVAL_STATUS
      , REQUESTER_ID
      , VALIDATION_REQUEST_ID
      , VALIDATED_TAX_AMOUNT
      , QUICK_CREDIT
      , CREDITED_INVOICE_ID
      , DISTRIBUTION_SET_ID
      , APPLICATION_ID
      , PRODUCT_TABLE
      , REFERENCE_KEY1
      , REFERENCE_KEY2
      , REFERENCE_KEY3
      , REFERENCE_KEY4
      , REFERENCE_KEY5
      , TOTAL_TAX_AMOUNT
      , SELF_ASSESSED_TAX_AMOUNT
      , TAX_RELATED_INVOICE_ID
      , TRX_BUSINESS_CATEGORY
      , USER_DEFINED_FISC_CLASS
      , TAXATION_COUNTRY
      , DOCUMENT_SUB_TYPE
      , SUPPLIER_TAX_INVOICE_NUMBER
      , SUPPLIER_TAX_INVOICE_DATE
      , SUPPLIER_TAX_EXCHANGE_RATE
      , TAX_INVOICE_RECORDING_DATE
      , TAX_INVOICE_INTERNAL_SEQ
      , LEGAL_ENTITY_ID
      , HISTORICAL_FLAG
      , FORCE_REVALIDATION_FLAG
      , BANK_CHARGE_BEARER
      , REMITTANCE_MESSAGE1
      , REMITTANCE_MESSAGE2
      , REMITTANCE_MESSAGE3
      , UNIQUE_REMITTANCE_IDENTIFIER
      , URI_CHECK_DIGIT
      , SETTLEMENT_PRIORITY
      , PAYMENT_REASON_CODE
      , PAYMENT_REASON_COMMENTS
      , PAYMENT_METHOD_CODE
      , DELIVERY_CHANNEL_CODE
      , QUICK_PO_HEADER_ID
      , NET_OF_RETAINAGE_FLAG
      , RELEASE_AMOUNT_NET_OF_TAX
      , CONTROL_AMOUNT
      , PARTY_ID
      , PARTY_SITE_ID
      , PAY_PROC_TRXN_TYPE_CODE
      , PAYMENT_FUNCTION
      , CUST_REGISTRATION_CODE
      , CUST_REGISTRATION_NUMBER
      , PORT_OF_ENTRY_CODE
      , EXTERNAL_BANK_ACCOUNT_ID
      , VENDOR_CONTACT_ID
      , INTERNAL_CONTACT_EMAIL
      , DISC_IS_INV_LESS_TAX_FLAG
      , EXCLUDE_FREIGHT_FROM_DISCOUNT
      , PAY_AWT_GROUP_ID
      , REMIT_TO_SUPPLIER_NAME
      , REMIT_TO_SUPPLIER_ID
      , REMIT_TO_SUPPLIER_SITE
      , REMIT_TO_SUPPLIER_SITE_ID
      , RELATIONSHIP_ID
      , ORIGINAL_INVOICE_AMOUNT
      , DISPUTE_REASON
      , PO_MATCHED_FLAG
      , VALIDATION_WORKER_ID
      , PAY_GROUP_LOOKUP_CODE_1
      , _FIVETRAN_ID
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED)                    as                                           LOAD_DTS
    FROM SRC_SRC
)

, LOGIC_ref_bkcc as (
    SELECT
        BKCC
      , REC_SRC
    FROM SRC_ref_bkcc
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM LOGIC_SRC
    INNER JOIN LOGIC_ref_bkcc
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          INVOICE_ID_BK
        , INVOICE_ID
        , LAST_UPDATE_DATE
        , LAST_UPDATED_BY
        , VENDOR_ID
        , INVOICE_NUM
        , SET_OF_BOOKS_ID
        , INVOICE_CURRENCY_CODE
        , PAYMENT_CURRENCY_CODE
        , PAYMENT_CROSS_RATE
        , INVOICE_AMOUNT
        , VENDOR_SITE_ID
        , AMOUNT_PAID
        , DISCOUNT_AMOUNT_TAKEN
        , INVOICE_DATE
        , SOURCE
        , INVOICE_TYPE_LOOKUP_CODE
        , DESCRIPTION
        , BATCH_ID
        , AMOUNT_APPLICABLE_TO_DISCOUNT
        , TAX_AMOUNT
        , TERMS_ID
        , TERMS_DATE
        , PAYMENT_METHOD_LOOKUP_CODE
        , ACCTS_PAY_CODE_COMBINATION_ID
        , PAYMENT_STATUS_FLAG
        , CREATION_DATE
        , CREATED_BY
        , BASE_AMOUNT
        , VAT_CODE
        , LAST_UPDATE_LOGIN
        , EXCLUSIVE_PAYMENT_FLAG
        , PO_HEADER_ID
        , FREIGHT_AMOUNT
        , GOODS_RECEIVED_DATE
        , INVOICE_RECEIVED_DATE
        , VOUCHER_NUM
        , APPROVED_AMOUNT
        , RECURRING_PAYMENT_ID
        , EXCHANGE_RATE
        , EXCHANGE_RATE_TYPE
        , EXCHANGE_DATE
        , EARLIEST_SETTLEMENT_DATE
        , ORIGINAL_PREPAYMENT_AMOUNT
        , DOC_SEQUENCE_ID
        , DOC_SEQUENCE_VALUE
        , DOC_CATEGORY_CODE
        , ATTRIBUTE1
        , ATTRIBUTE2
        , ATTRIBUTE3
        , ATTRIBUTE4
        , ATTRIBUTE5
        , ATTRIBUTE6
        , ATTRIBUTE7
        , ATTRIBUTE8
        , ATTRIBUTE9
        , ATTRIBUTE10
        , ATTRIBUTE11
        , ATTRIBUTE12
        , ATTRIBUTE13
        , ATTRIBUTE14
        , ATTRIBUTE15
        , ATTRIBUTE_CATEGORY
        , APPROVAL_STATUS
        , APPROVAL_DESCRIPTION
        , INVOICE_DISTRIBUTION_TOTAL
        , POSTING_STATUS
        , PREPAY_FLAG
        , AUTHORIZED_BY
        , CANCELLED_DATE
        , CANCELLED_BY
        , CANCELLED_AMOUNT
        , TEMP_CANCELLED_AMOUNT
        , PROJECT_ACCOUNTING_CONTEXT
        , USSGL_TRANSACTION_CODE
        , USSGL_TRX_CODE_CONTEXT
        , PROJECT_ID
        , TASK_ID
        , EXPENDITURE_TYPE
        , EXPENDITURE_ITEM_DATE
        , PA_QUANTITY
        , EXPENDITURE_ORGANIZATION_ID
        , PA_DEFAULT_DIST_CCID
        , VENDOR_PREPAY_AMOUNT
        , PAYMENT_AMOUNT_TOTAL
        , AWT_FLAG
        , AWT_GROUP_ID
        , REFERENCE_1
        , REFERENCE_2
        , ORG_ID
        , PRE_WITHHOLDING_AMOUNT
        , GLOBAL_ATTRIBUTE_CATEGORY
        , GLOBAL_ATTRIBUTE1
        , GLOBAL_ATTRIBUTE2
        , GLOBAL_ATTRIBUTE3
        , GLOBAL_ATTRIBUTE4
        , GLOBAL_ATTRIBUTE5
        , GLOBAL_ATTRIBUTE6
        , GLOBAL_ATTRIBUTE7
        , GLOBAL_ATTRIBUTE8
        , GLOBAL_ATTRIBUTE9
        , GLOBAL_ATTRIBUTE10
        , GLOBAL_ATTRIBUTE11
        , GLOBAL_ATTRIBUTE12
        , GLOBAL_ATTRIBUTE13
        , GLOBAL_ATTRIBUTE14
        , GLOBAL_ATTRIBUTE15
        , GLOBAL_ATTRIBUTE16
        , GLOBAL_ATTRIBUTE17
        , GLOBAL_ATTRIBUTE18
        , GLOBAL_ATTRIBUTE19
        , GLOBAL_ATTRIBUTE20
        , AUTO_TAX_CALC_FLAG
        , PAYMENT_CROSS_RATE_TYPE
        , PAYMENT_CROSS_RATE_DATE
        , PAY_CURR_INVOICE_AMOUNT
        , MRC_BASE_AMOUNT
        , MRC_EXCHANGE_RATE
        , MRC_EXCHANGE_RATE_TYPE
        , MRC_EXCHANGE_DATE
        , GL_DATE
        , AWARD_ID
        , PAID_ON_BEHALF_EMPLOYEE_ID
        , AMT_DUE_CCARD_COMPANY
        , AMT_DUE_EMPLOYEE
        , APPROVAL_READY_FLAG
        , APPROVAL_ITERATION
        , WFAPPROVAL_STATUS
        , REQUESTER_ID
        , VALIDATION_REQUEST_ID
        , VALIDATED_TAX_AMOUNT
        , QUICK_CREDIT
        , CREDITED_INVOICE_ID
        , DISTRIBUTION_SET_ID
        , APPLICATION_ID
        , PRODUCT_TABLE
        , REFERENCE_KEY1
        , REFERENCE_KEY2
        , REFERENCE_KEY3
        , REFERENCE_KEY4
        , REFERENCE_KEY5
        , TOTAL_TAX_AMOUNT
        , SELF_ASSESSED_TAX_AMOUNT
        , TAX_RELATED_INVOICE_ID
        , TRX_BUSINESS_CATEGORY
        , USER_DEFINED_FISC_CLASS
        , TAXATION_COUNTRY
        , DOCUMENT_SUB_TYPE
        , SUPPLIER_TAX_INVOICE_NUMBER
        , SUPPLIER_TAX_INVOICE_DATE
        , SUPPLIER_TAX_EXCHANGE_RATE
        , TAX_INVOICE_RECORDING_DATE
        , TAX_INVOICE_INTERNAL_SEQ
        , LEGAL_ENTITY_ID
        , HISTORICAL_FLAG
        , FORCE_REVALIDATION_FLAG
        , BANK_CHARGE_BEARER
        , REMITTANCE_MESSAGE1
        , REMITTANCE_MESSAGE2
        , REMITTANCE_MESSAGE3
        , UNIQUE_REMITTANCE_IDENTIFIER
        , URI_CHECK_DIGIT
        , SETTLEMENT_PRIORITY
        , PAYMENT_REASON_CODE
        , PAYMENT_REASON_COMMENTS
        , PAYMENT_METHOD_CODE
        , DELIVERY_CHANNEL_CODE
        , QUICK_PO_HEADER_ID
        , NET_OF_RETAINAGE_FLAG
        , RELEASE_AMOUNT_NET_OF_TAX
        , CONTROL_AMOUNT
        , PARTY_ID
        , PARTY_SITE_ID
        , PAY_PROC_TRXN_TYPE_CODE
        , PAYMENT_FUNCTION
        , CUST_REGISTRATION_CODE
        , CUST_REGISTRATION_NUMBER
        , PORT_OF_ENTRY_CODE
        , EXTERNAL_BANK_ACCOUNT_ID
        , VENDOR_CONTACT_ID
        , INTERNAL_CONTACT_EMAIL
        , DISC_IS_INV_LESS_TAX_FLAG
        , EXCLUDE_FREIGHT_FROM_DISCOUNT
        , PAY_AWT_GROUP_ID
        , REMIT_TO_SUPPLIER_NAME
        , REMIT_TO_SUPPLIER_ID
        , REMIT_TO_SUPPLIER_SITE
        , REMIT_TO_SUPPLIER_SITE_ID
        , RELATIONSHIP_ID
        , ORIGINAL_INVOICE_AMOUNT
        , DISPUTE_REASON
        , PO_MATCHED_FLAG
        , VALIDATION_WORKER_ID
        , PAY_GROUP_LOOKUP_CODE_1
        , _FIVETRAN_ID
        , _FIVETRAN_DELETED
        , _FIVETRAN_SYNCED
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , BKCC
        , REC_SRC
        , LOAD_DTS
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(INVOICE_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as SUPPLIER_INVOICE_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(VENDOR_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as SUPPLIER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(INVOICE_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(VENDOR_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as LNK_SUPPLIER_INVOICE_SUPPLIER_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(LAST_UPDATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(VENDOR_ID::text), '^^') 
            , '||', IFNULL(TRIM(INVOICE_NUM::text), '^^') 
            , '||', IFNULL(TRIM(SET_OF_BOOKS_ID::text), '^^') 
            , '||', IFNULL(TRIM(INVOICE_CURRENCY_CODE::text), '^^') 
            , '||', IFNULL(TRIM(PAYMENT_CURRENCY_CODE::text), '^^') 
            , '||', IFNULL(TRIM(PAYMENT_CROSS_RATE::text), '^^') 
            , '||', IFNULL(TRIM(INVOICE_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(VENDOR_SITE_ID::text), '^^') 
            , '||', IFNULL(TRIM(AMOUNT_PAID::text), '^^') 
            , '||', IFNULL(TRIM(DISCOUNT_AMOUNT_TAKEN::text), '^^') 
            , '||', IFNULL(TRIM(INVOICE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(SOURCE::text), '^^') 
            , '||', IFNULL(TRIM(INVOICE_TYPE_LOOKUP_CODE::text), '^^') 
            , '||', IFNULL(TRIM(DESCRIPTION::text), '^^') 
            , '||', IFNULL(TRIM(BATCH_ID::text), '^^') 
            , '||', IFNULL(TRIM(AMOUNT_APPLICABLE_TO_DISCOUNT::text), '^^') 
            , '||', IFNULL(TRIM(TAX_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(TERMS_ID::text), '^^') 
            , '||', IFNULL(TRIM(TERMS_DATE::text), '^^') 
            , '||', IFNULL(TRIM(PAYMENT_METHOD_LOOKUP_CODE::text), '^^') 
            , '||', IFNULL(TRIM(ACCTS_PAY_CODE_COMBINATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(PAYMENT_STATUS_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(CREATION_DATE::text), '^^') 
            , '||', IFNULL(TRIM(CREATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(BASE_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(VAT_CODE::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_LOGIN::text), '^^') 
            , '||', IFNULL(TRIM(EXCLUSIVE_PAYMENT_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(PO_HEADER_ID::text), '^^') 
            , '||', IFNULL(TRIM(FREIGHT_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(GOODS_RECEIVED_DATE::text), '^^') 
            , '||', IFNULL(TRIM(INVOICE_RECEIVED_DATE::text), '^^') 
            , '||', IFNULL(TRIM(VOUCHER_NUM::text), '^^') 
            , '||', IFNULL(TRIM(APPROVED_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(RECURRING_PAYMENT_ID::text), '^^') 
            , '||', IFNULL(TRIM(EXCHANGE_RATE::text), '^^') 
            , '||', IFNULL(TRIM(EXCHANGE_RATE_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(EXCHANGE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(EARLIEST_SETTLEMENT_DATE::text), '^^') 
            , '||', IFNULL(TRIM(ORIGINAL_PREPAYMENT_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(DOC_SEQUENCE_ID::text), '^^') 
            , '||', IFNULL(TRIM(DOC_SEQUENCE_VALUE::text), '^^') 
            , '||', IFNULL(TRIM(DOC_CATEGORY_CODE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE1::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE2::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE3::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE4::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE5::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE6::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE7::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE8::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE9::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE10::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE11::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE12::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE13::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE14::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE15::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(APPROVAL_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(APPROVAL_DESCRIPTION::text), '^^') 
            , '||', IFNULL(TRIM(INVOICE_DISTRIBUTION_TOTAL::text), '^^') 
            , '||', IFNULL(TRIM(POSTING_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(PREPAY_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(AUTHORIZED_BY::text), '^^') 
            , '||', IFNULL(TRIM(CANCELLED_DATE::text), '^^') 
            , '||', IFNULL(TRIM(CANCELLED_BY::text), '^^') 
            , '||', IFNULL(TRIM(CANCELLED_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(TEMP_CANCELLED_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(PROJECT_ACCOUNTING_CONTEXT::text), '^^') 
            , '||', IFNULL(TRIM(USSGL_TRANSACTION_CODE::text), '^^') 
            , '||', IFNULL(TRIM(USSGL_TRX_CODE_CONTEXT::text), '^^') 
            , '||', IFNULL(TRIM(PROJECT_ID::text), '^^') 
            , '||', IFNULL(TRIM(TASK_ID::text), '^^') 
            , '||', IFNULL(TRIM(EXPENDITURE_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(EXPENDITURE_ITEM_DATE::text), '^^') 
            , '||', IFNULL(TRIM(PA_QUANTITY::text), '^^') 
            , '||', IFNULL(TRIM(EXPENDITURE_ORGANIZATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(PA_DEFAULT_DIST_CCID::text), '^^') 
            , '||', IFNULL(TRIM(VENDOR_PREPAY_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(PAYMENT_AMOUNT_TOTAL::text), '^^') 
            , '||', IFNULL(TRIM(AWT_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(AWT_GROUP_ID::text), '^^') 
            , '||', IFNULL(TRIM(REFERENCE_1::text), '^^') 
            , '||', IFNULL(TRIM(REFERENCE_2::text), '^^') 
            , '||', IFNULL(TRIM(PRE_WITHHOLDING_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE1::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE2::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE3::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE4::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE5::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE6::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE7::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE8::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE9::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE10::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE11::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE12::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE13::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE14::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE15::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE16::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE17::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE18::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE19::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE20::text), '^^') 
            , '||', IFNULL(TRIM(AUTO_TAX_CALC_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(PAYMENT_CROSS_RATE_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(PAYMENT_CROSS_RATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(PAY_CURR_INVOICE_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(MRC_BASE_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(MRC_EXCHANGE_RATE::text), '^^') 
            , '||', IFNULL(TRIM(MRC_EXCHANGE_RATE_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(MRC_EXCHANGE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(GL_DATE::text), '^^') 
            , '||', IFNULL(TRIM(AWARD_ID::text), '^^') 
            , '||', IFNULL(TRIM(PAID_ON_BEHALF_EMPLOYEE_ID::text), '^^') 
            , '||', IFNULL(TRIM(AMT_DUE_CCARD_COMPANY::text), '^^') 
            , '||', IFNULL(TRIM(AMT_DUE_EMPLOYEE::text), '^^') 
            , '||', IFNULL(TRIM(APPROVAL_READY_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(APPROVAL_ITERATION::text), '^^') 
            , '||', IFNULL(TRIM(WFAPPROVAL_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(REQUESTER_ID::text), '^^') 
            , '||', IFNULL(TRIM(VALIDATION_REQUEST_ID::text), '^^') 
            , '||', IFNULL(TRIM(VALIDATED_TAX_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(QUICK_CREDIT::text), '^^') 
            , '||', IFNULL(TRIM(CREDITED_INVOICE_ID::text), '^^') 
            , '||', IFNULL(TRIM(DISTRIBUTION_SET_ID::text), '^^') 
            , '||', IFNULL(TRIM(APPLICATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(PRODUCT_TABLE::text), '^^') 
            , '||', IFNULL(TRIM(REFERENCE_KEY1::text), '^^') 
            , '||', IFNULL(TRIM(REFERENCE_KEY2::text), '^^') 
            , '||', IFNULL(TRIM(REFERENCE_KEY3::text), '^^') 
            , '||', IFNULL(TRIM(REFERENCE_KEY4::text), '^^') 
            , '||', IFNULL(TRIM(REFERENCE_KEY5::text), '^^') 
            , '||', IFNULL(TRIM(TOTAL_TAX_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(SELF_ASSESSED_TAX_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(TAX_RELATED_INVOICE_ID::text), '^^') 
            , '||', IFNULL(TRIM(TRX_BUSINESS_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(USER_DEFINED_FISC_CLASS::text), '^^') 
            , '||', IFNULL(TRIM(TAXATION_COUNTRY::text), '^^') 
            , '||', IFNULL(TRIM(DOCUMENT_SUB_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(SUPPLIER_TAX_INVOICE_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(SUPPLIER_TAX_INVOICE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(SUPPLIER_TAX_EXCHANGE_RATE::text), '^^') 
            , '||', IFNULL(TRIM(TAX_INVOICE_RECORDING_DATE::text), '^^') 
            , '||', IFNULL(TRIM(TAX_INVOICE_INTERNAL_SEQ::text), '^^') 
            , '||', IFNULL(TRIM(LEGAL_ENTITY_ID::text), '^^') 
            , '||', IFNULL(TRIM(HISTORICAL_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(FORCE_REVALIDATION_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(BANK_CHARGE_BEARER::text), '^^') 
            , '||', IFNULL(TRIM(REMITTANCE_MESSAGE1::text), '^^') 
            , '||', IFNULL(TRIM(REMITTANCE_MESSAGE2::text), '^^') 
            , '||', IFNULL(TRIM(REMITTANCE_MESSAGE3::text), '^^') 
            , '||', IFNULL(TRIM(UNIQUE_REMITTANCE_IDENTIFIER::text), '^^') 
            , '||', IFNULL(TRIM(URI_CHECK_DIGIT::text), '^^') 
            , '||', IFNULL(TRIM(SETTLEMENT_PRIORITY::text), '^^') 
            , '||', IFNULL(TRIM(PAYMENT_REASON_CODE::text), '^^') 
            , '||', IFNULL(TRIM(PAYMENT_REASON_COMMENTS::text), '^^') 
            , '||', IFNULL(TRIM(PAYMENT_METHOD_CODE::text), '^^') 
            , '||', IFNULL(TRIM(DELIVERY_CHANNEL_CODE::text), '^^') 
            , '||', IFNULL(TRIM(QUICK_PO_HEADER_ID::text), '^^') 
            , '||', IFNULL(TRIM(NET_OF_RETAINAGE_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(RELEASE_AMOUNT_NET_OF_TAX::text), '^^') 
            , '||', IFNULL(TRIM(CONTROL_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(PARTY_ID::text), '^^') 
            , '||', IFNULL(TRIM(PARTY_SITE_ID::text), '^^') 
            , '||', IFNULL(TRIM(PAY_PROC_TRXN_TYPE_CODE::text), '^^') 
            , '||', IFNULL(TRIM(PAYMENT_FUNCTION::text), '^^') 
            , '||', IFNULL(TRIM(CUST_REGISTRATION_CODE::text), '^^') 
            , '||', IFNULL(TRIM(CUST_REGISTRATION_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(PORT_OF_ENTRY_CODE::text), '^^') 
            , '||', IFNULL(TRIM(EXTERNAL_BANK_ACCOUNT_ID::text), '^^') 
            , '||', IFNULL(TRIM(VENDOR_CONTACT_ID::text), '^^') 
            , '||', IFNULL(TRIM(INTERNAL_CONTACT_EMAIL::text), '^^') 
            , '||', IFNULL(TRIM(DISC_IS_INV_LESS_TAX_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(EXCLUDE_FREIGHT_FROM_DISCOUNT::text), '^^') 
            , '||', IFNULL(TRIM(PAY_AWT_GROUP_ID::text), '^^') 
            , '||', IFNULL(TRIM(REMIT_TO_SUPPLIER_NAME::text), '^^') 
            , '||', IFNULL(TRIM(REMIT_TO_SUPPLIER_ID::text), '^^') 
            , '||', IFNULL(TRIM(REMIT_TO_SUPPLIER_SITE::text), '^^') 
            , '||', IFNULL(TRIM(REMIT_TO_SUPPLIER_SITE_ID::text), '^^') 
            , '||', IFNULL(TRIM(RELATIONSHIP_ID::text), '^^') 
            , '||', IFNULL(TRIM(ORIGINAL_INVOICE_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(DISPUTE_REASON::text), '^^') 
            , '||', IFNULL(TRIM(PO_MATCHED_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(VALIDATION_WORKER_ID::text), '^^') 
            , '||', IFNULL(TRIM(PAY_GROUP_LOOKUP_CODE_1::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
