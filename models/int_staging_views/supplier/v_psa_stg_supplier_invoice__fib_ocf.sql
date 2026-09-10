---- SRC LAYER ----
WITH
SRC_SRC            as ( SELECT * FROM {{ source('outd_ocf_ap', 'ap_invoices_all') }} as SRC  ),
SRC_ref_bkcc       as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC 
                        WHERE rec_src = 'USCLOUD.ORCL.OCFPRD.AP_INVOICES_ALL' )

/*
SRC_SRC            as ( SELECT * FROM outd_ocf_ap.ap_invoices_all )
SRC_ref_bkcc       as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_SRC as (
    SELECT
        INVOICE_ID                                                   as                                      INVOICE_ID_BK
      , INVOICE_ID
      , DOC_SEQUENCE_ID
      , DOC_SEQUENCE_VALUE
      , INVOICE_NUM
      , ORG_ID
      , VENDOR_ID
      , STREAM_DEFINITION_CODE
      , STREAM_DETAIL_ID
      , OBJECT_VERSION_NUMBER
      , EXCHANGE_RATE_TYPE
      , EXCHANGE_RATE
      , EXCHANGE_DATE
      , EMPLOYEE_ADDRESS_CODE
      , INTERCOMPANY_FLAG
      , PARTY_ID
      , CUST_REGISTRATION_CODE
      , CUST_REGISTRATION_NUMBER
      , PROJECT_ID
      , TASK_ID
      , EXPENDITURE_TYPE
      , PO_MATCHED_FLAG
      , VALIDATION_WORKER_ID
      , LOCKED_BY
      , FREIGHT_AMOUNT
      , REMIT_TO_SUPPLIER_ID
      , REMIT_TO_ADDRESS_NAME
      , REMIT_TO_ADDRESS_ID
      , RELATIONSHIP_ID
      , GOODS_RECEIVED_DATE
      , INVOICE_RECEIVED_DATE
      , VOUCHER_NUM
      , APPROVED_AMOUNT
      , RECURRING_PAYMENT_ID
      , EARLIEST_SETTLEMENT_DATE
      , PO_HEADER_ID
      , ATTRIBUTE_7
      , ATTRIBUTE_8
      , VALIDATION_REQUEST_ID
      , ROUTING_ATTRIBUTE_1
      , SUPPLIER_TAX_EXCHANGE_RATE
      , TAX_INVOICE_RECORDING_DATE
      , TAX_INVOICE_INTERNAL_SEQ
      , QUICK_PO_HEADER_ID
      , NET_OF_RETAINAGE_FLAG
      , DATA_SET_ID
      , FUNDS_STATUS
      , FIRST_PARTY_REGISTRATION_ID
      , THIRD_PARTY_REGISTRATION_ID
      , ATTRIBUTE_2
      , ATTRIBUTE_3
      , ATTRIBUTE_4
      , ATTRIBUTE_5
      , EXPENDITURE_ITEM_DATE
      , ACCTS_PAY_CODE_COMBINATION_ID
      , CONTROL_AMOUNT
      , GLOBAL_ATTRIBUTE_15
      , GLOBAL_ATTRIBUTE_NUMBER_4
      , GLOBAL_ATTRIBUTE_NUMBER_5
      , ATTRIBUTE_NUMBER_1
      , ATTRIBUTE_NUMBER_5
      , GLOBAL_ATTRIBUTE_16
      , ATTRIBUTE_NUMBER_2
      , ATTRIBUTE_NUMBER_3
      , ATTRIBUTE_NUMBER_4
      , GLOBAL_ATTRIBUTE_13
      , GLOBAL_ATTRIBUTE_14
      , LAST_UPDATE_DATE
      , INVOICE_CURRENCY_CODE
      , PAYMENT_CURRENCY_CODE
      , DIGITAL_PAYMENT_ACCOUNT_ID
      , FINANCING_STATUS_CODE
      , FINANCING_STATUS_DATE
      , BASE_AMOUNT
      , LAST_UPDATE_LOGIN
      , INTERNAL_CONTACT_EMAIL
      , IMPORT_DOCUMENT_NUMBER
      , PA_QUANTITY
      , EXPENDITURE_ORGANIZATION_ID
      , GLOBAL_ATTRIBUTE_DATE_1
      , ATTRIBUTE_DATE_5
      , PAYMENT_CROSS_RATE_TYPE
      , PAYMENT_CROSS_RATE_DATE
      , PAY_CURR_INVOICE_AMOUNT
      , MRC_BASE_AMOUNT
      , MRC_EXCHANGE_RATE
      , ACC_REFERENCE_VALUE_1
      , EXTERNAL_BANK_ACCOUNT_ID
      , VENDOR_CONTACT_ID
      , PORT_OF_ENTRY_CODE
      , FISCAL_DOC_ACCESS_KEY
      , REMIT_TO_SUPPLIER_NAME
      , ATTRIBUTE_9
      , ROUTING_STATUS_LOOKUP_CODE
      , ROUTING_ATTRIBUTE_2
      , ROUTING_ATTRIBUTE_3
      , ROUTING_ATTRIBUTE_4
      , GLOBAL_ATTRIBUTE_CATEGORY
      , TAXATION_COUNTRY
      , REQUESTER_ID
      , ATTRIBUTE_CATEGORY
      , ATTRIBUTE_11
      , ATTRIBUTE_12
      , ATTRIBUTE_13
      , ATTRIBUTE_14
      , TOTAL_TAX_AMOUNT
      , SELF_ASSESSED_TAX_AMOUNT
      , TAX_RELATED_INVOICE_ID
      , TRX_BUSINESS_CATEGORY
      , USER_DEFINED_FISC_CLASS
      , PARTY_SITE_ID
      , PAY_PROC_TRXN_TYPE_CODE
      , PAYMENT_FUNCTION
      , DISC_IS_INV_LESS_TAX_FLAG
      , EXCLUDE_FREIGHT_FROM_DISCOUNT
      , GLOBAL_ATTRIBUTE_DATE_2
      , GLOBAL_ATTRIBUTE_DATE_3
      , GLOBAL_ATTRIBUTE_DATE_4
      , EXCLUSIVE_PAYMENT_FLAG
      , AWARD_ID
      , GLOBAL_ATTRIBUTE_10
      , GLOBAL_ATTRIBUTE_6
      , GLOBAL_ATTRIBUTE_7
      , GLOBAL_ATTRIBUTE_8
      , GLOBAL_ATTRIBUTE_9
      , AMOUNT_PAID
      , DISCOUNT_AMOUNT_TAKEN
      , INVOICE_DATE
      , SOURCE
      , INVOICE_TYPE_LOOKUP_CODE
      , DESCRIPTION
      , BATCH_ID
      , AMOUNT_APPLICABLE_TO_DISCOUNT
      , TERMS_ID
      , UNIQUE_REMITTANCE_IDENTIFIER
      , URI_CHECK_DIGIT
      , GLOBAL_ATTRIBUTE_12
      , LAST_UPDATED_BY
      , SET_OF_BOOKS_ID
      , INVOICE_AMOUNT
      , VENDOR_SITE_ID
      , GLOBAL_ATTRIBUTE_NUMBER_1
      , GLOBAL_ATTRIBUTE_NUMBER_2
      , GLOBAL_ATTRIBUTE_NUMBER_3
      , PAID_ON_BEHALF_EMPLOYEE_ID
      , AMT_DUE_CCARD_COMPANY
      , AMT_DUE_EMPLOYEE
      , APPROVAL_READY_FLAG
      , APPROVAL_ITERATION
      , WFAPPROVAL_STATUS
      , REFERENCE_1
      , REFERENCE_2
      , LEGAL_ENTITY_ID
      , TERMS_DATE
      , PRE_WITHHOLDING_AMOUNT
      , GLOBAL_ATTRIBUTE_1
      , GLOBAL_ATTRIBUTE_2
      , GLOBAL_ATTRIBUTE_3
      , GLOBAL_ATTRIBUTE_4
      , GLOBAL_ATTRIBUTE_5
      , RELEASE_AMOUNT_NET_OF_TAX
      , GLOBAL_ATTRIBUTE_11
      , SETTLEMENT_PRIORITY
      , PAYMENT_REASON_CODE
      , PAYMENT_REASON_COMMENTS
      , PAYMENT_METHOD_CODE
      , DELIVERY_CHANNEL_CODE
      , ROUTING_ATTRIBUTE_5
      , IMAGE_DOCUMENT_NUM
      , PA_DEFAULT_DIST_CCID
      , PAYMENT_AMOUNT_TOTAL
      , AWT_FLAG
      , AWT_GROUP_ID
      , REFERENCE_KEY_3
      , REFERENCE_KEY_4
      , DISTRIBUTION_SET_ID
      , APPLICATION_ID
      , PRODUCT_TABLE
      , REFERENCE_KEY_1
      , REFERENCE_KEY_2
      , ATTRIBUTE_10
      , MRC_POSTING_STATUS
      , GL_DATE
      , ATTRIBUTE_6
      , CHECK_VAT_AMOUNT_PAID
      , REQUEST_ID
      , JOB_DEFINITION_NAME
      , PAYMENT_METHOD_LOOKUP_CODE
      , PAY_GROUP_LOOKUP_CODE
      , LOCK_TIME
      , IMPORT_DOCUMENT_DATE
      , CORRECTION_YEAR
      , CORRECTION_PERIOD
      , GLOBAL_ATTRIBUTE_DATE_5
      , ATTRIBUTE_DATE_1
      , ATTRIBUTE_DATE_2
      , ATTRIBUTE_DATE_3
      , ATTRIBUTE_1
      , MRC_EXCHANGE_DATE
      , DOC_CATEGORY_CODE
      , JOB_DEFINITION_PACKAGE
      , PAYMENT_STATUS_FLAG
      , CREATION_DATE
      , CREATED_BY
      , TRANSACTION_DEADLINE
      , MERGE_REQUEST_ID
      , MRC_EXCHANGE_RATE_TYPE
      , ATTRIBUTE_DATE_4
      , BUDGET_DATE
      , ADDITIONAL_NOTE
      , ATTRIBUTE_15
      , LOGICAL_DOCUMENT_ID
      , QUICK_CREDIT
      , CREDITED_INVOICE_ID
      , VALIDATED_TAX_AMOUNT
      , CANCELLED_DATE
      , REFERENCE_KEY_5
      , GLOBAL_ATTRIBUTE_19
      , GLOBAL_ATTRIBUTE_20
      , GLOBAL_ATTRIBUTE_17
      , GLOBAL_ATTRIBUTE_18
      , HISTORICAL_FLAG
      , FORCE_REVALIDATION_FLAG
      , BANK_CHARGE_BEARER
      , PAYMENT_CROSS_RATE
      , REMITTANCE_MESSAGE_1
      , REMITTANCE_MESSAGE_2
      , REMITTANCE_MESSAGE_3
      , APPROVAL_STATUS
      , APPROVAL_DESCRIPTION
      , POSTING_STATUS
      , DOCUMENT_SUB_TYPE
      , SUPPLIER_TAX_INVOICE_NUMBER
      , SUPPLIER_TAX_INVOICE_DATE
      , CANCELLED_BY
      , CANCELLED_AMOUNT
      , TEMP_CANCELLED_AMOUNT
      , USSGL_TRANSACTION_CODE
      , USSGL_TRX_CODE_CONTEXT
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
        , DOC_SEQUENCE_ID
        , DOC_SEQUENCE_VALUE
        , INVOICE_NUM
        , ORG_ID
        , VENDOR_ID
        , STREAM_DEFINITION_CODE
        , STREAM_DETAIL_ID
        , OBJECT_VERSION_NUMBER
        , EXCHANGE_RATE_TYPE
        , EXCHANGE_RATE
        , EXCHANGE_DATE
        , EMPLOYEE_ADDRESS_CODE
        , INTERCOMPANY_FLAG
        , PARTY_ID
        , CUST_REGISTRATION_CODE
        , CUST_REGISTRATION_NUMBER
        , PROJECT_ID
        , TASK_ID
        , EXPENDITURE_TYPE
        , PO_MATCHED_FLAG
        , VALIDATION_WORKER_ID
        , LOCKED_BY
        , FREIGHT_AMOUNT
        , REMIT_TO_SUPPLIER_ID
        , REMIT_TO_ADDRESS_NAME
        , REMIT_TO_ADDRESS_ID
        , RELATIONSHIP_ID
        , GOODS_RECEIVED_DATE
        , INVOICE_RECEIVED_DATE
        , VOUCHER_NUM
        , APPROVED_AMOUNT
        , RECURRING_PAYMENT_ID
        , EARLIEST_SETTLEMENT_DATE
        , PO_HEADER_ID
        , ATTRIBUTE_7
        , ATTRIBUTE_8
        , VALIDATION_REQUEST_ID
        , ROUTING_ATTRIBUTE_1
        , SUPPLIER_TAX_EXCHANGE_RATE
        , TAX_INVOICE_RECORDING_DATE
        , TAX_INVOICE_INTERNAL_SEQ
        , QUICK_PO_HEADER_ID
        , NET_OF_RETAINAGE_FLAG
        , DATA_SET_ID
        , FUNDS_STATUS
        , FIRST_PARTY_REGISTRATION_ID
        , THIRD_PARTY_REGISTRATION_ID
        , ATTRIBUTE_2
        , ATTRIBUTE_3
        , ATTRIBUTE_4
        , ATTRIBUTE_5
        , EXPENDITURE_ITEM_DATE
        , ACCTS_PAY_CODE_COMBINATION_ID
        , CONTROL_AMOUNT
        , GLOBAL_ATTRIBUTE_15
        , GLOBAL_ATTRIBUTE_NUMBER_4
        , GLOBAL_ATTRIBUTE_NUMBER_5
        , ATTRIBUTE_NUMBER_1
        , ATTRIBUTE_NUMBER_5
        , GLOBAL_ATTRIBUTE_16
        , ATTRIBUTE_NUMBER_2
        , ATTRIBUTE_NUMBER_3
        , ATTRIBUTE_NUMBER_4
        , GLOBAL_ATTRIBUTE_13
        , GLOBAL_ATTRIBUTE_14
        , LAST_UPDATE_DATE
        , INVOICE_CURRENCY_CODE
        , PAYMENT_CURRENCY_CODE
        , DIGITAL_PAYMENT_ACCOUNT_ID
        , FINANCING_STATUS_CODE
        , FINANCING_STATUS_DATE
        , BASE_AMOUNT
        , LAST_UPDATE_LOGIN
        , INTERNAL_CONTACT_EMAIL
        , IMPORT_DOCUMENT_NUMBER
        , PA_QUANTITY
        , EXPENDITURE_ORGANIZATION_ID
        , GLOBAL_ATTRIBUTE_DATE_1
        , ATTRIBUTE_DATE_5
        , PAYMENT_CROSS_RATE_TYPE
        , PAYMENT_CROSS_RATE_DATE
        , PAY_CURR_INVOICE_AMOUNT
        , MRC_BASE_AMOUNT
        , MRC_EXCHANGE_RATE
        , ACC_REFERENCE_VALUE_1
        , EXTERNAL_BANK_ACCOUNT_ID
        , VENDOR_CONTACT_ID
        , PORT_OF_ENTRY_CODE
        , FISCAL_DOC_ACCESS_KEY
        , REMIT_TO_SUPPLIER_NAME
        , ATTRIBUTE_9
        , ROUTING_STATUS_LOOKUP_CODE
        , ROUTING_ATTRIBUTE_2
        , ROUTING_ATTRIBUTE_3
        , ROUTING_ATTRIBUTE_4
        , GLOBAL_ATTRIBUTE_CATEGORY
        , TAXATION_COUNTRY
        , REQUESTER_ID
        , ATTRIBUTE_CATEGORY
        , ATTRIBUTE_11
        , ATTRIBUTE_12
        , ATTRIBUTE_13
        , ATTRIBUTE_14
        , TOTAL_TAX_AMOUNT
        , SELF_ASSESSED_TAX_AMOUNT
        , TAX_RELATED_INVOICE_ID
        , TRX_BUSINESS_CATEGORY
        , USER_DEFINED_FISC_CLASS
        , PARTY_SITE_ID
        , PAY_PROC_TRXN_TYPE_CODE
        , PAYMENT_FUNCTION
        , DISC_IS_INV_LESS_TAX_FLAG
        , EXCLUDE_FREIGHT_FROM_DISCOUNT
        , GLOBAL_ATTRIBUTE_DATE_2
        , GLOBAL_ATTRIBUTE_DATE_3
        , GLOBAL_ATTRIBUTE_DATE_4
        , EXCLUSIVE_PAYMENT_FLAG
        , AWARD_ID
        , GLOBAL_ATTRIBUTE_10
        , GLOBAL_ATTRIBUTE_6
        , GLOBAL_ATTRIBUTE_7
        , GLOBAL_ATTRIBUTE_8
        , GLOBAL_ATTRIBUTE_9
        , AMOUNT_PAID
        , DISCOUNT_AMOUNT_TAKEN
        , INVOICE_DATE
        , SOURCE
        , INVOICE_TYPE_LOOKUP_CODE
        , DESCRIPTION
        , BATCH_ID
        , AMOUNT_APPLICABLE_TO_DISCOUNT
        , TERMS_ID
        , UNIQUE_REMITTANCE_IDENTIFIER
        , URI_CHECK_DIGIT
        , GLOBAL_ATTRIBUTE_12
        , LAST_UPDATED_BY
        , SET_OF_BOOKS_ID
        , INVOICE_AMOUNT
        , VENDOR_SITE_ID
        , GLOBAL_ATTRIBUTE_NUMBER_1
        , GLOBAL_ATTRIBUTE_NUMBER_2
        , GLOBAL_ATTRIBUTE_NUMBER_3
        , PAID_ON_BEHALF_EMPLOYEE_ID
        , AMT_DUE_CCARD_COMPANY
        , AMT_DUE_EMPLOYEE
        , APPROVAL_READY_FLAG
        , APPROVAL_ITERATION
        , WFAPPROVAL_STATUS
        , REFERENCE_1
        , REFERENCE_2
        , LEGAL_ENTITY_ID
        , TERMS_DATE
        , PRE_WITHHOLDING_AMOUNT
        , GLOBAL_ATTRIBUTE_1
        , GLOBAL_ATTRIBUTE_2
        , GLOBAL_ATTRIBUTE_3
        , GLOBAL_ATTRIBUTE_4
        , GLOBAL_ATTRIBUTE_5
        , RELEASE_AMOUNT_NET_OF_TAX
        , GLOBAL_ATTRIBUTE_11
        , SETTLEMENT_PRIORITY
        , PAYMENT_REASON_CODE
        , PAYMENT_REASON_COMMENTS
        , PAYMENT_METHOD_CODE
        , DELIVERY_CHANNEL_CODE
        , ROUTING_ATTRIBUTE_5
        , IMAGE_DOCUMENT_NUM
        , PA_DEFAULT_DIST_CCID
        , PAYMENT_AMOUNT_TOTAL
        , AWT_FLAG
        , AWT_GROUP_ID
        , REFERENCE_KEY_3
        , REFERENCE_KEY_4
        , DISTRIBUTION_SET_ID
        , APPLICATION_ID
        , PRODUCT_TABLE
        , REFERENCE_KEY_1
        , REFERENCE_KEY_2
        , ATTRIBUTE_10
        , MRC_POSTING_STATUS
        , GL_DATE
        , ATTRIBUTE_6
        , CHECK_VAT_AMOUNT_PAID
        , REQUEST_ID
        , JOB_DEFINITION_NAME
        , PAYMENT_METHOD_LOOKUP_CODE
        , PAY_GROUP_LOOKUP_CODE
        , LOCK_TIME
        , IMPORT_DOCUMENT_DATE
        , CORRECTION_YEAR
        , CORRECTION_PERIOD
        , GLOBAL_ATTRIBUTE_DATE_5
        , ATTRIBUTE_DATE_1
        , ATTRIBUTE_DATE_2
        , ATTRIBUTE_DATE_3
        , ATTRIBUTE_1
        , MRC_EXCHANGE_DATE
        , DOC_CATEGORY_CODE
        , JOB_DEFINITION_PACKAGE
        , PAYMENT_STATUS_FLAG
        , CREATION_DATE
        , CREATED_BY
        , TRANSACTION_DEADLINE
        , MERGE_REQUEST_ID
        , MRC_EXCHANGE_RATE_TYPE
        , ATTRIBUTE_DATE_4
        , BUDGET_DATE
        , ADDITIONAL_NOTE
        , ATTRIBUTE_15
        , LOGICAL_DOCUMENT_ID
        , QUICK_CREDIT
        , CREDITED_INVOICE_ID
        , VALIDATED_TAX_AMOUNT
        , CANCELLED_DATE
        , REFERENCE_KEY_5
        , GLOBAL_ATTRIBUTE_19
        , GLOBAL_ATTRIBUTE_20
        , GLOBAL_ATTRIBUTE_17
        , GLOBAL_ATTRIBUTE_18
        , HISTORICAL_FLAG
        , FORCE_REVALIDATION_FLAG
        , BANK_CHARGE_BEARER
        , PAYMENT_CROSS_RATE
        , REMITTANCE_MESSAGE_1
        , REMITTANCE_MESSAGE_2
        , REMITTANCE_MESSAGE_3
        , APPROVAL_STATUS
        , APPROVAL_DESCRIPTION
        , POSTING_STATUS
        , DOCUMENT_SUB_TYPE
        , SUPPLIER_TAX_INVOICE_NUMBER
        , SUPPLIER_TAX_INVOICE_DATE
        , CANCELLED_BY
        , CANCELLED_AMOUNT
        , TEMP_CANCELLED_AMOUNT
        , USSGL_TRANSACTION_CODE
        , USSGL_TRX_CODE_CONTEXT
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
              IFNULL(TRIM(DOC_SEQUENCE_ID::text), '^^') 
            , '||', IFNULL(TRIM(DOC_SEQUENCE_VALUE::text), '^^') 
            , '||', IFNULL(TRIM(INVOICE_NUM::text), '^^') 
            , '||', IFNULL(TRIM(VENDOR_ID::text), '^^') 
            , '||', IFNULL(TRIM(STREAM_DEFINITION_CODE::text), '^^') 
            , '||', IFNULL(TRIM(STREAM_DETAIL_ID::text), '^^') 
            , '||', IFNULL(TRIM(OBJECT_VERSION_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(EXCHANGE_RATE_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(EXCHANGE_RATE::text), '^^') 
            , '||', IFNULL(TRIM(EXCHANGE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(EMPLOYEE_ADDRESS_CODE::text), '^^') 
            , '||', IFNULL(TRIM(INTERCOMPANY_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(PARTY_ID::text), '^^') 
            , '||', IFNULL(TRIM(CUST_REGISTRATION_CODE::text), '^^') 
            , '||', IFNULL(TRIM(CUST_REGISTRATION_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(PROJECT_ID::text), '^^') 
            , '||', IFNULL(TRIM(TASK_ID::text), '^^') 
            , '||', IFNULL(TRIM(EXPENDITURE_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(PO_MATCHED_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(VALIDATION_WORKER_ID::text), '^^') 
            , '||', IFNULL(TRIM(LOCKED_BY::text), '^^') 
            , '||', IFNULL(TRIM(FREIGHT_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(REMIT_TO_SUPPLIER_ID::text), '^^') 
            , '||', IFNULL(TRIM(REMIT_TO_ADDRESS_NAME::text), '^^') 
            , '||', IFNULL(TRIM(REMIT_TO_ADDRESS_ID::text), '^^') 
            , '||', IFNULL(TRIM(RELATIONSHIP_ID::text), '^^') 
            , '||', IFNULL(TRIM(GOODS_RECEIVED_DATE::text), '^^') 
            , '||', IFNULL(TRIM(INVOICE_RECEIVED_DATE::text), '^^') 
            , '||', IFNULL(TRIM(VOUCHER_NUM::text), '^^') 
            , '||', IFNULL(TRIM(APPROVED_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(RECURRING_PAYMENT_ID::text), '^^') 
            , '||', IFNULL(TRIM(EARLIEST_SETTLEMENT_DATE::text), '^^') 
            , '||', IFNULL(TRIM(PO_HEADER_ID::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_7::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_8::text), '^^') 
            , '||', IFNULL(TRIM(VALIDATION_REQUEST_ID::text), '^^') 
            , '||', IFNULL(TRIM(ROUTING_ATTRIBUTE_1::text), '^^') 
            , '||', IFNULL(TRIM(SUPPLIER_TAX_EXCHANGE_RATE::text), '^^') 
            , '||', IFNULL(TRIM(TAX_INVOICE_RECORDING_DATE::text), '^^') 
            , '||', IFNULL(TRIM(TAX_INVOICE_INTERNAL_SEQ::text), '^^') 
            , '||', IFNULL(TRIM(QUICK_PO_HEADER_ID::text), '^^') 
            , '||', IFNULL(TRIM(NET_OF_RETAINAGE_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(DATA_SET_ID::text), '^^') 
            , '||', IFNULL(TRIM(FUNDS_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(FIRST_PARTY_REGISTRATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(THIRD_PARTY_REGISTRATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_2::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_3::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_4::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_5::text), '^^') 
            , '||', IFNULL(TRIM(EXPENDITURE_ITEM_DATE::text), '^^') 
            , '||', IFNULL(TRIM(ACCTS_PAY_CODE_COMBINATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(CONTROL_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_15::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_NUMBER_4::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_NUMBER_5::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_1::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_5::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_16::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_2::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_3::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_4::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_13::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_14::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(INVOICE_CURRENCY_CODE::text), '^^') 
            , '||', IFNULL(TRIM(PAYMENT_CURRENCY_CODE::text), '^^') 
            , '||', IFNULL(TRIM(DIGITAL_PAYMENT_ACCOUNT_ID::text), '^^') 
            , '||', IFNULL(TRIM(FINANCING_STATUS_CODE::text), '^^') 
            , '||', IFNULL(TRIM(FINANCING_STATUS_DATE::text), '^^') 
            , '||', IFNULL(TRIM(BASE_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_LOGIN::text), '^^') 
            , '||', IFNULL(TRIM(INTERNAL_CONTACT_EMAIL::text), '^^') 
            , '||', IFNULL(TRIM(IMPORT_DOCUMENT_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(PA_QUANTITY::text), '^^') 
            , '||', IFNULL(TRIM(EXPENDITURE_ORGANIZATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_DATE_1::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_DATE_5::text), '^^') 
            , '||', IFNULL(TRIM(PAYMENT_CROSS_RATE_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(PAYMENT_CROSS_RATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(PAY_CURR_INVOICE_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(MRC_BASE_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(MRC_EXCHANGE_RATE::text), '^^') 
            , '||', IFNULL(TRIM(ACC_REFERENCE_VALUE_1::text), '^^') 
            , '||', IFNULL(TRIM(EXTERNAL_BANK_ACCOUNT_ID::text), '^^') 
            , '||', IFNULL(TRIM(VENDOR_CONTACT_ID::text), '^^') 
            , '||', IFNULL(TRIM(PORT_OF_ENTRY_CODE::text), '^^') 
            , '||', IFNULL(TRIM(FISCAL_DOC_ACCESS_KEY::text), '^^') 
            , '||', IFNULL(TRIM(REMIT_TO_SUPPLIER_NAME::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_9::text), '^^') 
            , '||', IFNULL(TRIM(ROUTING_STATUS_LOOKUP_CODE::text), '^^') 
            , '||', IFNULL(TRIM(ROUTING_ATTRIBUTE_2::text), '^^') 
            , '||', IFNULL(TRIM(ROUTING_ATTRIBUTE_3::text), '^^') 
            , '||', IFNULL(TRIM(ROUTING_ATTRIBUTE_4::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(TAXATION_COUNTRY::text), '^^') 
            , '||', IFNULL(TRIM(REQUESTER_ID::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_11::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_12::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_13::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_14::text), '^^') 
            , '||', IFNULL(TRIM(TOTAL_TAX_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(SELF_ASSESSED_TAX_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(TAX_RELATED_INVOICE_ID::text), '^^') 
            , '||', IFNULL(TRIM(TRX_BUSINESS_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(USER_DEFINED_FISC_CLASS::text), '^^') 
            , '||', IFNULL(TRIM(PARTY_SITE_ID::text), '^^') 
            , '||', IFNULL(TRIM(PAY_PROC_TRXN_TYPE_CODE::text), '^^') 
            , '||', IFNULL(TRIM(PAYMENT_FUNCTION::text), '^^') 
            , '||', IFNULL(TRIM(DISC_IS_INV_LESS_TAX_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(EXCLUDE_FREIGHT_FROM_DISCOUNT::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_DATE_2::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_DATE_3::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_DATE_4::text), '^^') 
            , '||', IFNULL(TRIM(EXCLUSIVE_PAYMENT_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(AWARD_ID::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_10::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_6::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_7::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_8::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_9::text), '^^') 
            , '||', IFNULL(TRIM(AMOUNT_PAID::text), '^^') 
            , '||', IFNULL(TRIM(DISCOUNT_AMOUNT_TAKEN::text), '^^') 
            , '||', IFNULL(TRIM(INVOICE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(SOURCE::text), '^^') 
            , '||', IFNULL(TRIM(INVOICE_TYPE_LOOKUP_CODE::text), '^^') 
            , '||', IFNULL(TRIM(DESCRIPTION::text), '^^') 
            , '||', IFNULL(TRIM(BATCH_ID::text), '^^') 
            , '||', IFNULL(TRIM(AMOUNT_APPLICABLE_TO_DISCOUNT::text), '^^') 
            , '||', IFNULL(TRIM(TERMS_ID::text), '^^') 
            , '||', IFNULL(TRIM(UNIQUE_REMITTANCE_IDENTIFIER::text), '^^') 
            , '||', IFNULL(TRIM(URI_CHECK_DIGIT::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_12::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(SET_OF_BOOKS_ID::text), '^^') 
            , '||', IFNULL(TRIM(INVOICE_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(VENDOR_SITE_ID::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_NUMBER_1::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_NUMBER_2::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_NUMBER_3::text), '^^') 
            , '||', IFNULL(TRIM(PAID_ON_BEHALF_EMPLOYEE_ID::text), '^^') 
            , '||', IFNULL(TRIM(AMT_DUE_CCARD_COMPANY::text), '^^') 
            , '||', IFNULL(TRIM(AMT_DUE_EMPLOYEE::text), '^^') 
            , '||', IFNULL(TRIM(APPROVAL_READY_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(APPROVAL_ITERATION::text), '^^') 
            , '||', IFNULL(TRIM(WFAPPROVAL_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(REFERENCE_1::text), '^^') 
            , '||', IFNULL(TRIM(REFERENCE_2::text), '^^') 
            , '||', IFNULL(TRIM(LEGAL_ENTITY_ID::text), '^^') 
            , '||', IFNULL(TRIM(TERMS_DATE::text), '^^') 
            , '||', IFNULL(TRIM(PRE_WITHHOLDING_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_1::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_2::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_3::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_4::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_5::text), '^^') 
            , '||', IFNULL(TRIM(RELEASE_AMOUNT_NET_OF_TAX::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_11::text), '^^') 
            , '||', IFNULL(TRIM(SETTLEMENT_PRIORITY::text), '^^') 
            , '||', IFNULL(TRIM(PAYMENT_REASON_CODE::text), '^^') 
            , '||', IFNULL(TRIM(PAYMENT_REASON_COMMENTS::text), '^^') 
            , '||', IFNULL(TRIM(PAYMENT_METHOD_CODE::text), '^^') 
            , '||', IFNULL(TRIM(DELIVERY_CHANNEL_CODE::text), '^^') 
            , '||', IFNULL(TRIM(ROUTING_ATTRIBUTE_5::text), '^^') 
            , '||', IFNULL(TRIM(IMAGE_DOCUMENT_NUM::text), '^^') 
            , '||', IFNULL(TRIM(PA_DEFAULT_DIST_CCID::text), '^^') 
            , '||', IFNULL(TRIM(PAYMENT_AMOUNT_TOTAL::text), '^^') 
            , '||', IFNULL(TRIM(AWT_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(AWT_GROUP_ID::text), '^^') 
            , '||', IFNULL(TRIM(REFERENCE_KEY_3::text), '^^') 
            , '||', IFNULL(TRIM(REFERENCE_KEY_4::text), '^^') 
            , '||', IFNULL(TRIM(DISTRIBUTION_SET_ID::text), '^^') 
            , '||', IFNULL(TRIM(APPLICATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(PRODUCT_TABLE::text), '^^') 
            , '||', IFNULL(TRIM(REFERENCE_KEY_1::text), '^^') 
            , '||', IFNULL(TRIM(REFERENCE_KEY_2::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_10::text), '^^') 
            , '||', IFNULL(TRIM(MRC_POSTING_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(GL_DATE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_6::text), '^^') 
            , '||', IFNULL(TRIM(CHECK_VAT_AMOUNT_PAID::text), '^^') 
            , '||', IFNULL(TRIM(REQUEST_ID::text), '^^') 
            , '||', IFNULL(TRIM(JOB_DEFINITION_NAME::text), '^^') 
            , '||', IFNULL(TRIM(PAYMENT_METHOD_LOOKUP_CODE::text), '^^') 
            , '||', IFNULL(TRIM(PAY_GROUP_LOOKUP_CODE::text), '^^') 
            , '||', IFNULL(TRIM(LOCK_TIME::text), '^^') 
            , '||', IFNULL(TRIM(IMPORT_DOCUMENT_DATE::text), '^^') 
            , '||', IFNULL(TRIM(CORRECTION_YEAR::text), '^^') 
            , '||', IFNULL(TRIM(CORRECTION_PERIOD::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_DATE_5::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_DATE_1::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_DATE_2::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_DATE_3::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_1::text), '^^') 
            , '||', IFNULL(TRIM(MRC_EXCHANGE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(DOC_CATEGORY_CODE::text), '^^') 
            , '||', IFNULL(TRIM(JOB_DEFINITION_PACKAGE::text), '^^') 
            , '||', IFNULL(TRIM(PAYMENT_STATUS_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(CREATION_DATE::text), '^^') 
            , '||', IFNULL(TRIM(CREATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(TRANSACTION_DEADLINE::text), '^^') 
            , '||', IFNULL(TRIM(MERGE_REQUEST_ID::text), '^^') 
            , '||', IFNULL(TRIM(MRC_EXCHANGE_RATE_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_DATE_4::text), '^^') 
            , '||', IFNULL(TRIM(BUDGET_DATE::text), '^^') 
            , '||', IFNULL(TRIM(ADDITIONAL_NOTE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_15::text), '^^') 
            , '||', IFNULL(TRIM(LOGICAL_DOCUMENT_ID::text), '^^') 
            , '||', IFNULL(TRIM(QUICK_CREDIT::text), '^^') 
            , '||', IFNULL(TRIM(CREDITED_INVOICE_ID::text), '^^') 
            , '||', IFNULL(TRIM(VALIDATED_TAX_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(CANCELLED_DATE::text), '^^') 
            , '||', IFNULL(TRIM(REFERENCE_KEY_5::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_19::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_20::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_17::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_18::text), '^^') 
            , '||', IFNULL(TRIM(HISTORICAL_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(FORCE_REVALIDATION_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(BANK_CHARGE_BEARER::text), '^^') 
            , '||', IFNULL(TRIM(PAYMENT_CROSS_RATE::text), '^^') 
            , '||', IFNULL(TRIM(REMITTANCE_MESSAGE_1::text), '^^') 
            , '||', IFNULL(TRIM(REMITTANCE_MESSAGE_2::text), '^^') 
            , '||', IFNULL(TRIM(REMITTANCE_MESSAGE_3::text), '^^') 
            , '||', IFNULL(TRIM(APPROVAL_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(APPROVAL_DESCRIPTION::text), '^^') 
            , '||', IFNULL(TRIM(POSTING_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(DOCUMENT_SUB_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(SUPPLIER_TAX_INVOICE_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(SUPPLIER_TAX_INVOICE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(CANCELLED_BY::text), '^^') 
            , '||', IFNULL(TRIM(CANCELLED_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(TEMP_CANCELLED_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(USSGL_TRANSACTION_CODE::text), '^^') 
            , '||', IFNULL(TRIM(USSGL_TRX_CODE_CONTEXT::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
