---- SRC LAYER ----
WITH
SRC_SRC            as ( SELECT * FROM {{ source('ml_ebs_ap', 'ap_invoices_all') }} as SRC 
                        /* grain_valid=False: 1 duplicate BK+LOAD_DTS rows detected */
                        QUALIFY ROW_NUMBER() OVER(PARTITION BY INVOICE_ID, _FIVETRAN_SYNCED ORDER BY _FIVETRAN_SYNCED DESC) = 1 ),
SRC_ref_bkcc       as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC 
                        WHERE rec_src = 'USWIOC.ORCL.EBSPRD.AP_INVOICES_ALL' )

/*
SRC_SRC            as ( SELECT * FROM ml_ebs_ap.ap_invoices_all )
SRC_ref_bkcc       as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_SRC as (
    SELECT
        INVOICE_ID                                                   as                                      INVOICE_ID_BK
      , INVOICE_ID
      , HISTORICAL_FLAG
      , FREIGHT_AMOUNT
      , PAYMENT_STATUS_FLAG
      , APPROVAL_ITERATION
      , INVOICE_DATE
      , TAX_AMOUNT
      , QUICK_PO_HEADER_ID
      , DISPUTE_REASON
      , ATTRIBUTE3
      , ATTRIBUTE2
      , ATTRIBUTE1
      , AUTHORIZED_BY
      , PARTY_SITE_ID
      , ATTRIBUTE9
      , ATTRIBUTE8
      , ATTRIBUTE7
      , PAY_PROC_TRXN_TYPE_CODE
      , GL_DATE
      , ATTRIBUTE6
      , MRC_EXCHANGE_RATE_TYPE
      , ATTRIBUTE5
      , VENDOR_ID
      , ATTRIBUTE4
      , SUPPLIER_TAX_INVOICE_DATE
      , INVOICE_NUM
      , SOURCE
      , ATTRIBUTE10
      , EXCLUSIVE_PAYMENT_FLAG
      , SETTLEMENT_PRIORITY
      , ATTRIBUTE14
      , ATTRIBUTE13
      , ATTRIBUTE12
      , ATTRIBUTE11
      , UNIQUE_REMITTANCE_IDENTIFIER
      , APPROVAL_STATUS
      , TOTAL_TAX_AMOUNT
      , EXTERNAL_BANK_ACCOUNT_ID
      , NET_OF_RETAINAGE_FLAG
      , DESCRIPTION
      , MRC_EXCHANGE_DATE
      , APPROVAL_DESCRIPTION
      , APPROVAL_READY_FLAG
      , RECURRING_PAYMENT_ID
      , SUPPLIER_TAX_EXCHANGE_RATE
      , CANCELLED_AMOUNT
      , REMIT_TO_SUPPLIER_SITE_ID
      , INVOICE_AMOUNT
      , WFAPPROVAL_STATUS
      , ATTRIBUTE15
      , INVOICE_CURRENCY_CODE
      , CUST_REGISTRATION_NUMBER
      , DISTRIBUTION_SET_ID
      , DOCUMENT_SUB_TYPE
      , PA_QUANTITY
      , GLOBAL_ATTRIBUTE10
      , PORT_OF_ENTRY_CODE
      , INVOICE_TYPE_LOOKUP_CODE
      , PROJECT_ACCOUNTING_CONTEXT
      , LAST_UPDATED_BY
      , USER_DEFINED_FISC_CLASS
      , TERMS_ID
      , PAYMENT_AMOUNT_TOTAL
      , PAYMENT_CROSS_RATE_TYPE
      , AUTO_TAX_CALC_FLAG
      , EXCLUDE_FREIGHT_FROM_DISCOUNT
      , PARTY_ID
      , PAY_AWT_GROUP_ID
      , PAYMENT_FUNCTION
      , PRODUCT_TABLE
      , SET_OF_BOOKS_ID
      , BANK_CHARGE_BEARER
      , VENDOR_SITE_ID
      , PAYMENT_METHOD_LOOKUP_CODE
      , PAYMENT_CROSS_RATE_DATE
      , DOC_SEQUENCE_VALUE
      , REFERENCE_KEY1
      , DELIVERY_CHANNEL_CODE
      , REFERENCE_KEY2
      , REFERENCE_KEY3
      , REFERENCE_KEY4
      , REFERENCE_KEY5
      , GLOBAL_ATTRIBUTE_CATEGORY
      , QUICK_CREDIT
      , DOC_SEQUENCE_ID
      , APPROVED_AMOUNT
      , INTERNAL_CONTACT_EMAIL
      , REQUESTER_ID
      , URI_CHECK_DIGIT
      , ORG_ID
      , PAID_ON_BEHALF_EMPLOYEE_ID
      , PAYMENT_CROSS_RATE
      , AMOUNT_APPLICABLE_TO_DISCOUNT
      , TRX_BUSINESS_CATEGORY
      , GLOBAL_ATTRIBUTE5
      , GLOBAL_ATTRIBUTE4
      , REMIT_TO_SUPPLIER_SITE
      , GLOBAL_ATTRIBUTE7
      , VALIDATION_WORKER_ID
      , GLOBAL_ATTRIBUTE6
      , PAYMENT_METHOD_CODE
      , GLOBAL_ATTRIBUTE1
      , GLOBAL_ATTRIBUTE3
      , GLOBAL_ATTRIBUTE2
      , AWT_GROUP_ID
      , GLOBAL_ATTRIBUTE9
      , GLOBAL_ATTRIBUTE8
      , USSGL_TRANSACTION_CODE
      , DOC_CATEGORY_CODE
      , AWT_FLAG
      , CUST_REGISTRATION_CODE
      , TEMP_CANCELLED_AMOUNT
      , PREPAY_FLAG
      , ACCTS_PAY_CODE_COMBINATION_ID
      , TASK_ID
      , REFERENCE_1
      , REFERENCE_2
      , REMITTANCE_MESSAGE3
      , REMITTANCE_MESSAGE2
      , SUPPLIER_TAX_INVOICE_NUMBER
      , REMITTANCE_MESSAGE1
      , EXPENDITURE_TYPE
      , INVOICE_DISTRIBUTION_TOTAL
      , MRC_EXCHANGE_RATE
      , PROJECT_ID
      , VOUCHER_NUM
      , RELEASE_AMOUNT_NET_OF_TAX
      , GLOBAL_ATTRIBUTE20
      , TAX_RELATED_INVOICE_ID
      , USSGL_TRX_CODE_CONTEXT
      , TERMS_DATE
      , GLOBAL_ATTRIBUTE17
      , GLOBAL_ATTRIBUTE18
      , GLOBAL_ATTRIBUTE15
      , GLOBAL_ATTRIBUTE16
      , GLOBAL_ATTRIBUTE13
      , PO_HEADER_ID
      , GLOBAL_ATTRIBUTE14
      , PRE_WITHHOLDING_AMOUNT
      , GLOBAL_ATTRIBUTE11
      , AMT_DUE_EMPLOYEE
      , FORCE_REVALIDATION_FLAG
      , GLOBAL_ATTRIBUTE12
      , CONTROL_AMOUNT
      , GLOBAL_ATTRIBUTE19
      , MRC_BASE_AMOUNT
      , ORIGINAL_PREPAYMENT_AMOUNT
      , VENDOR_CONTACT_ID
      , EXPENDITURE_ORGANIZATION_ID
      , EXCHANGE_DATE
      , CREATED_BY
      , REMIT_TO_SUPPLIER_ID
      , AWARD_ID
      , SELF_ASSESSED_TAX_AMOUNT
      , CANCELLED_BY
      , LEGAL_ENTITY_ID
      , DISC_IS_INV_LESS_TAX_FLAG
      , DISCOUNT_AMOUNT_TAKEN
      , VAT_CODE
      , ATTRIBUTE_CATEGORY
      , AMOUNT_PAID
      , VENDOR_PREPAY_AMOUNT
      , PAYMENT_REASON_COMMENTS
      , PAY_CURR_INVOICE_AMOUNT
      , CREDITED_INVOICE_ID
      , BASE_AMOUNT
      , EXPENDITURE_ITEM_DATE
      , ORIGINAL_INVOICE_AMOUNT
      , APPLICATION_ID
      , BATCH_ID
      , TAX_INVOICE_INTERNAL_SEQ
      , PAYMENT_CURRENCY_CODE
      , EXCHANGE_RATE_TYPE
      , POSTING_STATUS
      , VALIDATED_TAX_AMOUNT
      , PAYMENT_REASON_CODE
      , REMIT_TO_SUPPLIER_NAME
      , LAST_UPDATE_LOGIN
      , PO_MATCHED_FLAG
      , TAXATION_COUNTRY
      , VALIDATION_REQUEST_ID
      , RELATIONSHIP_ID
      , AMT_DUE_CCARD_COMPANY
      , PA_DEFAULT_DIST_CCID
      , PAY_GROUP_LOOKUP_CODE
      , TAX_INVOICE_RECORDING_DATE
      , INVOICE_RECEIVED_DATE
      , EXCHANGE_RATE
      , CANCELLED_DATE
      , CREATION_DATE
      , GOODS_RECEIVED_DATE
      , LAST_UPDATE_DATE
      , EARLIEST_SETTLEMENT_DATE
      , _FIVETRAN_DELETED
      , _FIVETRAN_ID
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
        , HISTORICAL_FLAG
        , FREIGHT_AMOUNT
        , PAYMENT_STATUS_FLAG
        , APPROVAL_ITERATION
        , INVOICE_DATE
        , TAX_AMOUNT
        , QUICK_PO_HEADER_ID
        , DISPUTE_REASON
        , ATTRIBUTE3
        , ATTRIBUTE2
        , ATTRIBUTE1
        , AUTHORIZED_BY
        , PARTY_SITE_ID
        , ATTRIBUTE9
        , ATTRIBUTE8
        , ATTRIBUTE7
        , PAY_PROC_TRXN_TYPE_CODE
        , GL_DATE
        , ATTRIBUTE6
        , MRC_EXCHANGE_RATE_TYPE
        , ATTRIBUTE5
        , VENDOR_ID
        , ATTRIBUTE4
        , SUPPLIER_TAX_INVOICE_DATE
        , INVOICE_NUM
        , SOURCE
        , ATTRIBUTE10
        , EXCLUSIVE_PAYMENT_FLAG
        , SETTLEMENT_PRIORITY
        , ATTRIBUTE14
        , ATTRIBUTE13
        , ATTRIBUTE12
        , ATTRIBUTE11
        , UNIQUE_REMITTANCE_IDENTIFIER
        , APPROVAL_STATUS
        , TOTAL_TAX_AMOUNT
        , EXTERNAL_BANK_ACCOUNT_ID
        , NET_OF_RETAINAGE_FLAG
        , DESCRIPTION
        , MRC_EXCHANGE_DATE
        , APPROVAL_DESCRIPTION
        , APPROVAL_READY_FLAG
        , RECURRING_PAYMENT_ID
        , SUPPLIER_TAX_EXCHANGE_RATE
        , CANCELLED_AMOUNT
        , REMIT_TO_SUPPLIER_SITE_ID
        , INVOICE_AMOUNT
        , WFAPPROVAL_STATUS
        , ATTRIBUTE15
        , INVOICE_CURRENCY_CODE
        , CUST_REGISTRATION_NUMBER
        , DISTRIBUTION_SET_ID
        , DOCUMENT_SUB_TYPE
        , PA_QUANTITY
        , GLOBAL_ATTRIBUTE10
        , PORT_OF_ENTRY_CODE
        , INVOICE_TYPE_LOOKUP_CODE
        , PROJECT_ACCOUNTING_CONTEXT
        , LAST_UPDATED_BY
        , USER_DEFINED_FISC_CLASS
        , TERMS_ID
        , PAYMENT_AMOUNT_TOTAL
        , PAYMENT_CROSS_RATE_TYPE
        , AUTO_TAX_CALC_FLAG
        , EXCLUDE_FREIGHT_FROM_DISCOUNT
        , PARTY_ID
        , PAY_AWT_GROUP_ID
        , PAYMENT_FUNCTION
        , PRODUCT_TABLE
        , SET_OF_BOOKS_ID
        , BANK_CHARGE_BEARER
        , VENDOR_SITE_ID
        , PAYMENT_METHOD_LOOKUP_CODE
        , PAYMENT_CROSS_RATE_DATE
        , DOC_SEQUENCE_VALUE
        , REFERENCE_KEY1
        , DELIVERY_CHANNEL_CODE
        , REFERENCE_KEY2
        , REFERENCE_KEY3
        , REFERENCE_KEY4
        , REFERENCE_KEY5
        , GLOBAL_ATTRIBUTE_CATEGORY
        , QUICK_CREDIT
        , DOC_SEQUENCE_ID
        , APPROVED_AMOUNT
        , INTERNAL_CONTACT_EMAIL
        , REQUESTER_ID
        , URI_CHECK_DIGIT
        , ORG_ID
        , PAID_ON_BEHALF_EMPLOYEE_ID
        , PAYMENT_CROSS_RATE
        , AMOUNT_APPLICABLE_TO_DISCOUNT
        , TRX_BUSINESS_CATEGORY
        , GLOBAL_ATTRIBUTE5
        , GLOBAL_ATTRIBUTE4
        , REMIT_TO_SUPPLIER_SITE
        , GLOBAL_ATTRIBUTE7
        , VALIDATION_WORKER_ID
        , GLOBAL_ATTRIBUTE6
        , PAYMENT_METHOD_CODE
        , GLOBAL_ATTRIBUTE1
        , GLOBAL_ATTRIBUTE3
        , GLOBAL_ATTRIBUTE2
        , AWT_GROUP_ID
        , GLOBAL_ATTRIBUTE9
        , GLOBAL_ATTRIBUTE8
        , USSGL_TRANSACTION_CODE
        , DOC_CATEGORY_CODE
        , AWT_FLAG
        , CUST_REGISTRATION_CODE
        , TEMP_CANCELLED_AMOUNT
        , PREPAY_FLAG
        , ACCTS_PAY_CODE_COMBINATION_ID
        , TASK_ID
        , REFERENCE_1
        , REFERENCE_2
        , REMITTANCE_MESSAGE3
        , REMITTANCE_MESSAGE2
        , SUPPLIER_TAX_INVOICE_NUMBER
        , REMITTANCE_MESSAGE1
        , EXPENDITURE_TYPE
        , INVOICE_DISTRIBUTION_TOTAL
        , MRC_EXCHANGE_RATE
        , PROJECT_ID
        , VOUCHER_NUM
        , RELEASE_AMOUNT_NET_OF_TAX
        , GLOBAL_ATTRIBUTE20
        , TAX_RELATED_INVOICE_ID
        , USSGL_TRX_CODE_CONTEXT
        , TERMS_DATE
        , GLOBAL_ATTRIBUTE17
        , GLOBAL_ATTRIBUTE18
        , GLOBAL_ATTRIBUTE15
        , GLOBAL_ATTRIBUTE16
        , GLOBAL_ATTRIBUTE13
        , PO_HEADER_ID
        , GLOBAL_ATTRIBUTE14
        , PRE_WITHHOLDING_AMOUNT
        , GLOBAL_ATTRIBUTE11
        , AMT_DUE_EMPLOYEE
        , FORCE_REVALIDATION_FLAG
        , GLOBAL_ATTRIBUTE12
        , CONTROL_AMOUNT
        , GLOBAL_ATTRIBUTE19
        , MRC_BASE_AMOUNT
        , ORIGINAL_PREPAYMENT_AMOUNT
        , VENDOR_CONTACT_ID
        , EXPENDITURE_ORGANIZATION_ID
        , EXCHANGE_DATE
        , CREATED_BY
        , REMIT_TO_SUPPLIER_ID
        , AWARD_ID
        , SELF_ASSESSED_TAX_AMOUNT
        , CANCELLED_BY
        , LEGAL_ENTITY_ID
        , DISC_IS_INV_LESS_TAX_FLAG
        , DISCOUNT_AMOUNT_TAKEN
        , VAT_CODE
        , ATTRIBUTE_CATEGORY
        , AMOUNT_PAID
        , VENDOR_PREPAY_AMOUNT
        , PAYMENT_REASON_COMMENTS
        , PAY_CURR_INVOICE_AMOUNT
        , CREDITED_INVOICE_ID
        , BASE_AMOUNT
        , EXPENDITURE_ITEM_DATE
        , ORIGINAL_INVOICE_AMOUNT
        , APPLICATION_ID
        , BATCH_ID
        , TAX_INVOICE_INTERNAL_SEQ
        , PAYMENT_CURRENCY_CODE
        , EXCHANGE_RATE_TYPE
        , POSTING_STATUS
        , VALIDATED_TAX_AMOUNT
        , PAYMENT_REASON_CODE
        , REMIT_TO_SUPPLIER_NAME
        , LAST_UPDATE_LOGIN
        , PO_MATCHED_FLAG
        , TAXATION_COUNTRY
        , VALIDATION_REQUEST_ID
        , RELATIONSHIP_ID
        , AMT_DUE_CCARD_COMPANY
        , PA_DEFAULT_DIST_CCID
        , PAY_GROUP_LOOKUP_CODE
        , TAX_INVOICE_RECORDING_DATE
        , INVOICE_RECEIVED_DATE
        , EXCHANGE_RATE
        , CANCELLED_DATE
        , CREATION_DATE
        , GOODS_RECEIVED_DATE
        , LAST_UPDATE_DATE
        , EARLIEST_SETTLEMENT_DATE
        , _FIVETRAN_DELETED
        , _FIVETRAN_ID
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
              IFNULL(TRIM(HISTORICAL_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(FREIGHT_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(PAYMENT_STATUS_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(APPROVAL_ITERATION::text), '^^') 
            , '||', IFNULL(TRIM(INVOICE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(TAX_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(QUICK_PO_HEADER_ID::text), '^^') 
            , '||', IFNULL(TRIM(DISPUTE_REASON::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE3::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE2::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE1::text), '^^') 
            , '||', IFNULL(TRIM(AUTHORIZED_BY::text), '^^') 
            , '||', IFNULL(TRIM(PARTY_SITE_ID::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE9::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE8::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE7::text), '^^') 
            , '||', IFNULL(TRIM(PAY_PROC_TRXN_TYPE_CODE::text), '^^') 
            , '||', IFNULL(TRIM(GL_DATE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE6::text), '^^') 
            , '||', IFNULL(TRIM(MRC_EXCHANGE_RATE_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE5::text), '^^') 
            , '||', IFNULL(TRIM(VENDOR_ID::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE4::text), '^^') 
            , '||', IFNULL(TRIM(SUPPLIER_TAX_INVOICE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(INVOICE_NUM::text), '^^') 
            , '||', IFNULL(TRIM(SOURCE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE10::text), '^^') 
            , '||', IFNULL(TRIM(EXCLUSIVE_PAYMENT_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(SETTLEMENT_PRIORITY::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE14::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE13::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE12::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE11::text), '^^') 
            , '||', IFNULL(TRIM(UNIQUE_REMITTANCE_IDENTIFIER::text), '^^') 
            , '||', IFNULL(TRIM(APPROVAL_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(TOTAL_TAX_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(EXTERNAL_BANK_ACCOUNT_ID::text), '^^') 
            , '||', IFNULL(TRIM(NET_OF_RETAINAGE_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(DESCRIPTION::text), '^^') 
            , '||', IFNULL(TRIM(MRC_EXCHANGE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(APPROVAL_DESCRIPTION::text), '^^') 
            , '||', IFNULL(TRIM(APPROVAL_READY_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(RECURRING_PAYMENT_ID::text), '^^') 
            , '||', IFNULL(TRIM(SUPPLIER_TAX_EXCHANGE_RATE::text), '^^') 
            , '||', IFNULL(TRIM(CANCELLED_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(REMIT_TO_SUPPLIER_SITE_ID::text), '^^') 
            , '||', IFNULL(TRIM(INVOICE_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(WFAPPROVAL_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE15::text), '^^') 
            , '||', IFNULL(TRIM(INVOICE_CURRENCY_CODE::text), '^^') 
            , '||', IFNULL(TRIM(CUST_REGISTRATION_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(DISTRIBUTION_SET_ID::text), '^^') 
            , '||', IFNULL(TRIM(DOCUMENT_SUB_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(PA_QUANTITY::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE10::text), '^^') 
            , '||', IFNULL(TRIM(PORT_OF_ENTRY_CODE::text), '^^') 
            , '||', IFNULL(TRIM(INVOICE_TYPE_LOOKUP_CODE::text), '^^') 
            , '||', IFNULL(TRIM(PROJECT_ACCOUNTING_CONTEXT::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(USER_DEFINED_FISC_CLASS::text), '^^') 
            , '||', IFNULL(TRIM(TERMS_ID::text), '^^') 
            , '||', IFNULL(TRIM(PAYMENT_AMOUNT_TOTAL::text), '^^') 
            , '||', IFNULL(TRIM(PAYMENT_CROSS_RATE_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(AUTO_TAX_CALC_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(EXCLUDE_FREIGHT_FROM_DISCOUNT::text), '^^') 
            , '||', IFNULL(TRIM(PARTY_ID::text), '^^') 
            , '||', IFNULL(TRIM(PAY_AWT_GROUP_ID::text), '^^') 
            , '||', IFNULL(TRIM(PAYMENT_FUNCTION::text), '^^') 
            , '||', IFNULL(TRIM(PRODUCT_TABLE::text), '^^') 
            , '||', IFNULL(TRIM(SET_OF_BOOKS_ID::text), '^^') 
            , '||', IFNULL(TRIM(BANK_CHARGE_BEARER::text), '^^') 
            , '||', IFNULL(TRIM(VENDOR_SITE_ID::text), '^^') 
            , '||', IFNULL(TRIM(PAYMENT_METHOD_LOOKUP_CODE::text), '^^') 
            , '||', IFNULL(TRIM(PAYMENT_CROSS_RATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(DOC_SEQUENCE_VALUE::text), '^^') 
            , '||', IFNULL(TRIM(REFERENCE_KEY1::text), '^^') 
            , '||', IFNULL(TRIM(DELIVERY_CHANNEL_CODE::text), '^^') 
            , '||', IFNULL(TRIM(REFERENCE_KEY2::text), '^^') 
            , '||', IFNULL(TRIM(REFERENCE_KEY3::text), '^^') 
            , '||', IFNULL(TRIM(REFERENCE_KEY4::text), '^^') 
            , '||', IFNULL(TRIM(REFERENCE_KEY5::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(QUICK_CREDIT::text), '^^') 
            , '||', IFNULL(TRIM(DOC_SEQUENCE_ID::text), '^^') 
            , '||', IFNULL(TRIM(APPROVED_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(INTERNAL_CONTACT_EMAIL::text), '^^') 
            , '||', IFNULL(TRIM(REQUESTER_ID::text), '^^') 
            , '||', IFNULL(TRIM(URI_CHECK_DIGIT::text), '^^') 
            , '||', IFNULL(TRIM(PAID_ON_BEHALF_EMPLOYEE_ID::text), '^^') 
            , '||', IFNULL(TRIM(PAYMENT_CROSS_RATE::text), '^^') 
            , '||', IFNULL(TRIM(AMOUNT_APPLICABLE_TO_DISCOUNT::text), '^^') 
            , '||', IFNULL(TRIM(TRX_BUSINESS_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE5::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE4::text), '^^') 
            , '||', IFNULL(TRIM(REMIT_TO_SUPPLIER_SITE::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE7::text), '^^') 
            , '||', IFNULL(TRIM(VALIDATION_WORKER_ID::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE6::text), '^^') 
            , '||', IFNULL(TRIM(PAYMENT_METHOD_CODE::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE1::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE3::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE2::text), '^^') 
            , '||', IFNULL(TRIM(AWT_GROUP_ID::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE9::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE8::text), '^^') 
            , '||', IFNULL(TRIM(USSGL_TRANSACTION_CODE::text), '^^') 
            , '||', IFNULL(TRIM(DOC_CATEGORY_CODE::text), '^^') 
            , '||', IFNULL(TRIM(AWT_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(CUST_REGISTRATION_CODE::text), '^^') 
            , '||', IFNULL(TRIM(TEMP_CANCELLED_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(PREPAY_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(ACCTS_PAY_CODE_COMBINATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(TASK_ID::text), '^^') 
            , '||', IFNULL(TRIM(REFERENCE_1::text), '^^') 
            , '||', IFNULL(TRIM(REFERENCE_2::text), '^^') 
            , '||', IFNULL(TRIM(REMITTANCE_MESSAGE3::text), '^^') 
            , '||', IFNULL(TRIM(REMITTANCE_MESSAGE2::text), '^^') 
            , '||', IFNULL(TRIM(SUPPLIER_TAX_INVOICE_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(REMITTANCE_MESSAGE1::text), '^^') 
            , '||', IFNULL(TRIM(EXPENDITURE_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(INVOICE_DISTRIBUTION_TOTAL::text), '^^') 
            , '||', IFNULL(TRIM(MRC_EXCHANGE_RATE::text), '^^') 
            , '||', IFNULL(TRIM(PROJECT_ID::text), '^^') 
            , '||', IFNULL(TRIM(VOUCHER_NUM::text), '^^') 
            , '||', IFNULL(TRIM(RELEASE_AMOUNT_NET_OF_TAX::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE20::text), '^^') 
            , '||', IFNULL(TRIM(TAX_RELATED_INVOICE_ID::text), '^^') 
            , '||', IFNULL(TRIM(USSGL_TRX_CODE_CONTEXT::text), '^^') 
            , '||', IFNULL(TRIM(TERMS_DATE::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE17::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE18::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE15::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE16::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE13::text), '^^') 
            , '||', IFNULL(TRIM(PO_HEADER_ID::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE14::text), '^^') 
            , '||', IFNULL(TRIM(PRE_WITHHOLDING_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE11::text), '^^') 
            , '||', IFNULL(TRIM(AMT_DUE_EMPLOYEE::text), '^^') 
            , '||', IFNULL(TRIM(FORCE_REVALIDATION_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE12::text), '^^') 
            , '||', IFNULL(TRIM(CONTROL_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE19::text), '^^') 
            , '||', IFNULL(TRIM(MRC_BASE_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(ORIGINAL_PREPAYMENT_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(VENDOR_CONTACT_ID::text), '^^') 
            , '||', IFNULL(TRIM(EXPENDITURE_ORGANIZATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(EXCHANGE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(CREATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(REMIT_TO_SUPPLIER_ID::text), '^^') 
            , '||', IFNULL(TRIM(AWARD_ID::text), '^^') 
            , '||', IFNULL(TRIM(SELF_ASSESSED_TAX_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(CANCELLED_BY::text), '^^') 
            , '||', IFNULL(TRIM(LEGAL_ENTITY_ID::text), '^^') 
            , '||', IFNULL(TRIM(DISC_IS_INV_LESS_TAX_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(DISCOUNT_AMOUNT_TAKEN::text), '^^') 
            , '||', IFNULL(TRIM(VAT_CODE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(AMOUNT_PAID::text), '^^') 
            , '||', IFNULL(TRIM(VENDOR_PREPAY_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(PAYMENT_REASON_COMMENTS::text), '^^') 
            , '||', IFNULL(TRIM(PAY_CURR_INVOICE_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(CREDITED_INVOICE_ID::text), '^^') 
            , '||', IFNULL(TRIM(BASE_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(EXPENDITURE_ITEM_DATE::text), '^^') 
            , '||', IFNULL(TRIM(ORIGINAL_INVOICE_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(APPLICATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(BATCH_ID::text), '^^') 
            , '||', IFNULL(TRIM(TAX_INVOICE_INTERNAL_SEQ::text), '^^') 
            , '||', IFNULL(TRIM(PAYMENT_CURRENCY_CODE::text), '^^') 
            , '||', IFNULL(TRIM(EXCHANGE_RATE_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(POSTING_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(VALIDATED_TAX_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(PAYMENT_REASON_CODE::text), '^^') 
            , '||', IFNULL(TRIM(REMIT_TO_SUPPLIER_NAME::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_LOGIN::text), '^^') 
            , '||', IFNULL(TRIM(PO_MATCHED_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(TAXATION_COUNTRY::text), '^^') 
            , '||', IFNULL(TRIM(VALIDATION_REQUEST_ID::text), '^^') 
            , '||', IFNULL(TRIM(RELATIONSHIP_ID::text), '^^') 
            , '||', IFNULL(TRIM(AMT_DUE_CCARD_COMPANY::text), '^^') 
            , '||', IFNULL(TRIM(PA_DEFAULT_DIST_CCID::text), '^^') 
            , '||', IFNULL(TRIM(PAY_GROUP_LOOKUP_CODE::text), '^^') 
            , '||', IFNULL(TRIM(TAX_INVOICE_RECORDING_DATE::text), '^^') 
            , '||', IFNULL(TRIM(INVOICE_RECEIVED_DATE::text), '^^') 
            , '||', IFNULL(TRIM(EXCHANGE_RATE::text), '^^') 
            , '||', IFNULL(TRIM(CANCELLED_DATE::text), '^^') 
            , '||', IFNULL(TRIM(CREATION_DATE::text), '^^') 
            , '||', IFNULL(TRIM(GOODS_RECEIVED_DATE::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(EARLIEST_SETTLEMENT_DATE::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
