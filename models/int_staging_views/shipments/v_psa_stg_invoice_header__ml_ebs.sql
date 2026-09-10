---- SRC LAYER ----
WITH
SRC_S              as ( SELECT * FROM {{ source('ml_ebs_ar', 'ra_customer_trx_all') }} as SRC  ),
SRC_A              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S              as ( SELECT * FROM ml_ebs_ar.ra_customer_trx_all )
, SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        to_char(CUSTOMER_TRX_ID)                                     as                                         INVOICE_BK
      , CUSTOMER_TRX_ID
      , CUSTOMER_REFERENCE
      , STATUS_TRX
      , SPECIAL_INSTRUCTIONS
      , BILLING_DATE
      , BILL_TO_CUSTOMER_ID
      , INITIAL_CUSTOMER_TRX_ID
      , TRX_DATE
      , POSTING_CONTROL_ID
      , TERRITORY_ID
      , ATTRIBUTE3
      , ATTRIBUTE2
      , ATTRIBUTE1
      , DRAWEE_SITE_USE_ID
      , DEFAULT_TAX_EXEMPT_FLAG
      , ATTRIBUTE9
      , ATTRIBUTE8
      , ATTRIBUTE7
      , ATTRIBUTE6
      , MRC_EXCHANGE_RATE_TYPE
      , ATTRIBUTE5
      , ATTRIBUTE4
      , COMPLETE_FLAG
      , PURCHASE_ORDER
      , CUSTOMER_REFERENCE_DATE
      , TRAILER_NUMBER
      , TERM_ID
      , ATTRIBUTE10
      , RELATED_CUSTOMER_TRX_ID
      , ATTRIBUTE14
      , ATTRIBUTE13
      , ATTRIBUTE12
      , ATTRIBUTE11
      , MRC_EXCHANGE_DATE
      , SOLD_TO_CONTACT_ID
      , TERM_DUE_DATE
      , PURCHASE_ORDER_DATE
      , APPROVAL_CODE
      , CT_REFERENCE
      , BILL_TO_SITE_USE_ID
      , SHIP_DATE_ACTUAL
      , INTERFACE_HEADER_CONTEXT
      , BR_ON_HOLD_FLAG
      , BILL_TEMPLATE_ID
      , DOCUMENT_TYPE_ID
      , PAYMENT_TRXN_EXTENSION_ID
      , CC_ERROR_FLAG
      , RECURRED_FROM_TRX_NUMBER
      , ATTRIBUTE15
      , INVOICE_CURRENCY_CODE
      , PRINTING_LAST_PRINTED
      , WAYBILL_NUMBER
      , SRC_INVOICING_RULE_ID
      , GLOBAL_ATTRIBUTE10
      , SHIP_VIA
      , DEFAULT_USSGL_TRX_CODE_CONTEXT
      , AX_ACCOUNTED_FLAG
      , SOLD_TO_SITE_USE_ID
      , MANDATE_LAST_TRX_FLAG
      , EXCHANGE_RATE
      , PAYMENT_SERVER_ORDER_NUM
      , CONTRACT_ID
      , INTERFACE_HEADER_ATTRIBUTE3
      , INTERFACE_HEADER_ATTRIBUTE2
      , INTERFACE_HEADER_ATTRIBUTE1
      , LAST_PRINTED_SEQUENCE_NUM
      , INTERFACE_HEADER_ATTRIBUTE7
      , INTERFACE_HEADER_ATTRIBUTE6
      , INTERFACE_HEADER_ATTRIBUTE5
      , INTERFACE_HEADER_ATTRIBUTE4
      , CC_ERROR_TEXT
      , INTERFACE_HEADER_ATTRIBUTE9
      , INTERFACE_HEADER_ATTRIBUTE8
      , START_DATE_COMMITMENT
      , INTEREST_HEADER_ID
      , SET_OF_BOOKS_ID
      , DRAWEE_CONTACT_ID
      , CREDIT_METHOD_FOR_INSTALLMENTS
      , CUST_TRX_TYPE_ID
      , CREDIT_METHOD_FOR_RULES
      , PRINTING_PENDING
      , DOC_SEQUENCE_VALUE
      , REMITTANCE_BANK_ACCOUNT_ID
      , REASON_CODE
      , PRINTING_COUNT
      , LATE_CHARGES_ASSESSED
      , EDI_PROCESSED_FLAG
      , UPGRADE_METHOD
      , GLOBAL_ATTRIBUTE_CATEGORY
      , ORIG_SYSTEM_BATCH_NAME
      , SHIP_TO_ADDRESS_ID
      , DOC_SEQUENCE_ID
      , PRINTING_ORIGINAL_DATE
      , PREPAYMENT_FLAG
      , ORG_ID
      , GLOBAL_ATTRIBUTE5
      , RELATED_BATCH_SOURCE_ID
      , GLOBAL_ATTRIBUTE4
      , GLOBAL_ATTRIBUTE7
      , GLOBAL_ATTRIBUTE6
      , GLOBAL_ATTRIBUTE1
      , INTERNAL_NOTES
      , GLOBAL_ATTRIBUTE3
      , GLOBAL_ATTRIBUTE2
      , RA_POST_LOOP_NUMBER
      , GLOBAL_ATTRIBUTE9
      , PAYING_CUSTOMER_ID
      , GLOBAL_ATTRIBUTE8
      , BILL_TO_ADDRESS_ID
      , PAYING_SITE_USE_ID
      , POST_REQUEST_ID
      , PAYMENT_ATTRIBUTES
      , AGREEMENT_ID
      , ADDRESS_VERIFICATION_CODE
      , CUSTOMER_BANK_ACCOUNT_ID
      , SHIP_TO_CUSTOMER_ID
      , DEFAULT_USSGL_TRANSACTION_CODE
      , EDI_PROCESSED_STATUS
      , SHIP_TO_CONTACT_ID
      , REMIT_BANK_ACCT_USE_ID
      , TRX_NUMBER
      , COMMENTS
      , GLOBAL_ATTRIBUTE30
      , GLOBAL_ATTRIBUTE28
      , GLOBAL_ATTRIBUTE29
      , GLOBAL_ATTRIBUTE26
      , GLOBAL_ATTRIBUTE27
      , GLOBAL_ATTRIBUTE24
      , GLOBAL_ATTRIBUTE25
      , GLOBAL_ATTRIBUTE22
      , GLOBAL_ATTRIBUTE23
      , MRC_EXCHANGE_RATE
      , END_DATE_COMMITMENT
      , DOCUMENT_CREATION_DATE
      , GLOBAL_ATTRIBUTE20
      , GLOBAL_ATTRIBUTE21
      , DRAWEE_BANK_ACCOUNT_ID
      , REV_REC_APPLICATION
      , GLOBAL_ATTRIBUTE17
      , GLOBAL_ATTRIBUTE18
      , GLOBAL_ATTRIBUTE15
      , GLOBAL_ATTRIBUTE16
      , DRAWEE_ID
      , GLOBAL_ATTRIBUTE13
      , GLOBAL_ATTRIBUTE14
      , GLOBAL_ATTRIBUTE11
      , GLOBAL_ATTRIBUTE12
      , REMIT_TO_ADDRESS_ID
      , FOB_POINT
      , BILL_TO_CONTACT_ID
      , GLOBAL_ATTRIBUTE19
      , REVERSED_CASH_RECEIPT_ID
      , CREATED_FROM
      , PURCHASE_ORDER_REVISION
      , RECEIPT_METHOD_ID
      , SOLD_TO_CUSTOMER_ID
      , REMITTANCE_BATCH_ID
      , EXCHANGE_DATE
      , FINANCE_CHARGES
      , CREATED_BY
      , BR_AMOUNT
      , LEGAL_ENTITY_ID
      , INVOICING_RULE_ID
      , PREVIOUS_CUSTOMER_TRX_ID
      , ATTRIBUTE_CATEGORY
      , SHIPMENT_ID
      , OVERRIDE_REMIT_ACCOUNT_FLAG
      , SHIP_TO_SITE_USE_ID
      , EXCHANGE_RATE_TYPE
      , INTERFACE_HEADER_ATTRIBUTE11
      , INTERFACE_HEADER_ATTRIBUTE12
      , INTERFACE_HEADER_ATTRIBUTE13
      , INTERFACE_HEADER_ATTRIBUTE14
      , INTERFACE_HEADER_ATTRIBUTE15
      , BILLING_EXT_REQUEST
      , BR_UNPAID_FLAG
      , OLD_TRX_NUMBER
      , PRINTING_OPTION
      , CC_ERROR_CODE
      , PRIMARY_SALESREP_ID
      , INTERFACE_HEADER_ATTRIBUTE10
      , BATCH_ID
      , BATCH_SOURCE_ID
      , APPLICATION_ID
      , CREATION_DATE
      , LAST_UPDATED_BY
      , LAST_UPDATE_DATE
      , LAST_UPDATE_LOGIN
      , REQUEST_ID
      , PROGRAM_APPLICATION_ID
      , PROGRAM_ID
      , PROGRAM_UPDATE_DATE
      , WH_UPDATE_DATE
      , _FIVETRAN_DELETED
      , _FIVETRAN_ID
      , _FIVETRAN_SYNCED
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED )                   as                                           LOAD_DTS
      , SOLD_TO_CUSTOMER_ID                                          as                                 SOLD_TO_ACCOUNT_BK
      , BILL_TO_SITE_USE_ID                                          as                                BILL_TO_SITE_USE_BK
    FROM SRC_S
)

, LOGIC_A as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_A
)
---- RENAME LAYER ----

, RENAME_S as (
    SELECT
        INVOICE_BK
      , CUSTOMER_TRX_ID
      , CUSTOMER_REFERENCE
      , STATUS_TRX
      , SPECIAL_INSTRUCTIONS
      , BILLING_DATE
      , BILL_TO_CUSTOMER_ID
      , INITIAL_CUSTOMER_TRX_ID
      , TRX_DATE
      , POSTING_CONTROL_ID
      , TERRITORY_ID
      , ATTRIBUTE3
      , ATTRIBUTE2
      , ATTRIBUTE1
      , DRAWEE_SITE_USE_ID
      , DEFAULT_TAX_EXEMPT_FLAG
      , ATTRIBUTE9
      , ATTRIBUTE8
      , ATTRIBUTE7
      , ATTRIBUTE6
      , MRC_EXCHANGE_RATE_TYPE
      , ATTRIBUTE5
      , ATTRIBUTE4
      , COMPLETE_FLAG
      , PURCHASE_ORDER
      , CUSTOMER_REFERENCE_DATE
      , TRAILER_NUMBER
      , TERM_ID
      , ATTRIBUTE10
      , RELATED_CUSTOMER_TRX_ID
      , ATTRIBUTE14
      , ATTRIBUTE13
      , ATTRIBUTE12
      , ATTRIBUTE11
      , MRC_EXCHANGE_DATE
      , SOLD_TO_CONTACT_ID
      , TERM_DUE_DATE
      , PURCHASE_ORDER_DATE
      , APPROVAL_CODE
      , CT_REFERENCE
      , BILL_TO_SITE_USE_ID
      , SHIP_DATE_ACTUAL
      , INTERFACE_HEADER_CONTEXT
      , BR_ON_HOLD_FLAG
      , BILL_TEMPLATE_ID
      , DOCUMENT_TYPE_ID
      , PAYMENT_TRXN_EXTENSION_ID
      , CC_ERROR_FLAG
      , RECURRED_FROM_TRX_NUMBER
      , ATTRIBUTE15
      , INVOICE_CURRENCY_CODE
      , PRINTING_LAST_PRINTED
      , WAYBILL_NUMBER
      , SRC_INVOICING_RULE_ID
      , GLOBAL_ATTRIBUTE10
      , SHIP_VIA
      , DEFAULT_USSGL_TRX_CODE_CONTEXT
      , AX_ACCOUNTED_FLAG
      , SOLD_TO_SITE_USE_ID
      , MANDATE_LAST_TRX_FLAG
      , EXCHANGE_RATE
      , PAYMENT_SERVER_ORDER_NUM
      , CONTRACT_ID
      , INTERFACE_HEADER_ATTRIBUTE3
      , INTERFACE_HEADER_ATTRIBUTE2
      , INTERFACE_HEADER_ATTRIBUTE1
      , LAST_PRINTED_SEQUENCE_NUM
      , INTERFACE_HEADER_ATTRIBUTE7
      , INTERFACE_HEADER_ATTRIBUTE6
      , INTERFACE_HEADER_ATTRIBUTE5
      , INTERFACE_HEADER_ATTRIBUTE4
      , CC_ERROR_TEXT
      , INTERFACE_HEADER_ATTRIBUTE9
      , INTERFACE_HEADER_ATTRIBUTE8
      , START_DATE_COMMITMENT
      , INTEREST_HEADER_ID
      , SET_OF_BOOKS_ID
      , DRAWEE_CONTACT_ID
      , CREDIT_METHOD_FOR_INSTALLMENTS
      , CUST_TRX_TYPE_ID
      , CREDIT_METHOD_FOR_RULES
      , PRINTING_PENDING
      , DOC_SEQUENCE_VALUE
      , REMITTANCE_BANK_ACCOUNT_ID
      , REASON_CODE
      , PRINTING_COUNT
      , LATE_CHARGES_ASSESSED
      , EDI_PROCESSED_FLAG
      , UPGRADE_METHOD
      , GLOBAL_ATTRIBUTE_CATEGORY
      , ORIG_SYSTEM_BATCH_NAME
      , SHIP_TO_ADDRESS_ID
      , DOC_SEQUENCE_ID
      , PRINTING_ORIGINAL_DATE
      , PREPAYMENT_FLAG
      , ORG_ID
      , GLOBAL_ATTRIBUTE5
      , RELATED_BATCH_SOURCE_ID
      , GLOBAL_ATTRIBUTE4
      , GLOBAL_ATTRIBUTE7
      , GLOBAL_ATTRIBUTE6
      , GLOBAL_ATTRIBUTE1
      , INTERNAL_NOTES
      , GLOBAL_ATTRIBUTE3
      , GLOBAL_ATTRIBUTE2
      , RA_POST_LOOP_NUMBER
      , GLOBAL_ATTRIBUTE9
      , PAYING_CUSTOMER_ID
      , GLOBAL_ATTRIBUTE8
      , BILL_TO_ADDRESS_ID
      , PAYING_SITE_USE_ID
      , POST_REQUEST_ID
      , PAYMENT_ATTRIBUTES
      , AGREEMENT_ID
      , ADDRESS_VERIFICATION_CODE
      , CUSTOMER_BANK_ACCOUNT_ID
      , SHIP_TO_CUSTOMER_ID
      , DEFAULT_USSGL_TRANSACTION_CODE
      , EDI_PROCESSED_STATUS
      , SHIP_TO_CONTACT_ID
      , REMIT_BANK_ACCT_USE_ID
      , TRX_NUMBER
      , COMMENTS
      , GLOBAL_ATTRIBUTE30
      , GLOBAL_ATTRIBUTE28
      , GLOBAL_ATTRIBUTE29
      , GLOBAL_ATTRIBUTE26
      , GLOBAL_ATTRIBUTE27
      , GLOBAL_ATTRIBUTE24
      , GLOBAL_ATTRIBUTE25
      , GLOBAL_ATTRIBUTE22
      , GLOBAL_ATTRIBUTE23
      , MRC_EXCHANGE_RATE
      , END_DATE_COMMITMENT
      , DOCUMENT_CREATION_DATE
      , GLOBAL_ATTRIBUTE20
      , GLOBAL_ATTRIBUTE21
      , DRAWEE_BANK_ACCOUNT_ID
      , REV_REC_APPLICATION
      , GLOBAL_ATTRIBUTE17
      , GLOBAL_ATTRIBUTE18
      , GLOBAL_ATTRIBUTE15
      , GLOBAL_ATTRIBUTE16
      , DRAWEE_ID
      , GLOBAL_ATTRIBUTE13
      , GLOBAL_ATTRIBUTE14
      , GLOBAL_ATTRIBUTE11
      , GLOBAL_ATTRIBUTE12
      , REMIT_TO_ADDRESS_ID
      , FOB_POINT
      , BILL_TO_CONTACT_ID
      , GLOBAL_ATTRIBUTE19
      , REVERSED_CASH_RECEIPT_ID
      , CREATED_FROM
      , PURCHASE_ORDER_REVISION
      , RECEIPT_METHOD_ID
      , SOLD_TO_CUSTOMER_ID
      , REMITTANCE_BATCH_ID
      , EXCHANGE_DATE
      , FINANCE_CHARGES
      , CREATED_BY
      , BR_AMOUNT
      , LEGAL_ENTITY_ID
      , INVOICING_RULE_ID
      , PREVIOUS_CUSTOMER_TRX_ID
      , ATTRIBUTE_CATEGORY
      , SHIPMENT_ID
      , OVERRIDE_REMIT_ACCOUNT_FLAG
      , SHIP_TO_SITE_USE_ID
      , EXCHANGE_RATE_TYPE
      , INTERFACE_HEADER_ATTRIBUTE11
      , INTERFACE_HEADER_ATTRIBUTE12
      , INTERFACE_HEADER_ATTRIBUTE13
      , INTERFACE_HEADER_ATTRIBUTE14
      , INTERFACE_HEADER_ATTRIBUTE15
      , BILLING_EXT_REQUEST
      , BR_UNPAID_FLAG
      , OLD_TRX_NUMBER
      , PRINTING_OPTION
      , CC_ERROR_CODE
      , PRIMARY_SALESREP_ID
      , INTERFACE_HEADER_ATTRIBUTE10
      , BATCH_ID
      , BATCH_SOURCE_ID
      , APPLICATION_ID
      , CREATION_DATE
      , LAST_UPDATED_BY
      , LAST_UPDATE_DATE
      , LAST_UPDATE_LOGIN
      , REQUEST_ID
      , PROGRAM_APPLICATION_ID
      , PROGRAM_ID
      , PROGRAM_UPDATE_DATE
      , WH_UPDATE_DATE
      , _FIVETRAN_DELETED
      , _FIVETRAN_ID
      , _FIVETRAN_SYNCED
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , LOAD_DTS
      , SOLD_TO_ACCOUNT_BK
      , BILL_TO_SITE_USE_BK
    FROM LOGIC_S
)

, RENAME_A as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_A
)
---- FILTER LAYER ----

, FILTER_S as (
    SELECT *
    FROM RENAME_S
)

, FILTER_A as (
    SELECT *
    FROM RENAME_A
    WHERE rec_src = 'USWIOC.ORCL.EBSPRD.CUSTOMER_TRX_ALL'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_S
    INNER JOIN FILTER_A
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          INVOICE_BK
        , CUSTOMER_TRX_ID
        , CUSTOMER_REFERENCE
        , STATUS_TRX
        , SPECIAL_INSTRUCTIONS
        , BILLING_DATE
        , BILL_TO_CUSTOMER_ID
        , INITIAL_CUSTOMER_TRX_ID
        , TRX_DATE
        , POSTING_CONTROL_ID
        , TERRITORY_ID
        , ATTRIBUTE3
        , ATTRIBUTE2
        , ATTRIBUTE1
        , DRAWEE_SITE_USE_ID
        , DEFAULT_TAX_EXEMPT_FLAG
        , ATTRIBUTE9
        , ATTRIBUTE8
        , ATTRIBUTE7
        , ATTRIBUTE6
        , MRC_EXCHANGE_RATE_TYPE
        , ATTRIBUTE5
        , ATTRIBUTE4
        , COMPLETE_FLAG
        , PURCHASE_ORDER
        , CUSTOMER_REFERENCE_DATE
        , TRAILER_NUMBER
        , TERM_ID
        , ATTRIBUTE10
        , RELATED_CUSTOMER_TRX_ID
        , ATTRIBUTE14
        , ATTRIBUTE13
        , ATTRIBUTE12
        , ATTRIBUTE11
        , MRC_EXCHANGE_DATE
        , SOLD_TO_CONTACT_ID
        , TERM_DUE_DATE
        , PURCHASE_ORDER_DATE
        , APPROVAL_CODE
        , CT_REFERENCE
        , BILL_TO_SITE_USE_ID
        , SHIP_DATE_ACTUAL
        , INTERFACE_HEADER_CONTEXT
        , BR_ON_HOLD_FLAG
        , BILL_TEMPLATE_ID
        , DOCUMENT_TYPE_ID
        , PAYMENT_TRXN_EXTENSION_ID
        , CC_ERROR_FLAG
        , RECURRED_FROM_TRX_NUMBER
        , ATTRIBUTE15
        , INVOICE_CURRENCY_CODE
        , PRINTING_LAST_PRINTED
        , WAYBILL_NUMBER
        , SRC_INVOICING_RULE_ID
        , GLOBAL_ATTRIBUTE10
        , SHIP_VIA
        , DEFAULT_USSGL_TRX_CODE_CONTEXT
        , AX_ACCOUNTED_FLAG
        , SOLD_TO_SITE_USE_ID
        , MANDATE_LAST_TRX_FLAG
        , EXCHANGE_RATE
        , PAYMENT_SERVER_ORDER_NUM
        , CONTRACT_ID
        , INTERFACE_HEADER_ATTRIBUTE3
        , INTERFACE_HEADER_ATTRIBUTE2
        , INTERFACE_HEADER_ATTRIBUTE1
        , LAST_PRINTED_SEQUENCE_NUM
        , INTERFACE_HEADER_ATTRIBUTE7
        , INTERFACE_HEADER_ATTRIBUTE6
        , INTERFACE_HEADER_ATTRIBUTE5
        , INTERFACE_HEADER_ATTRIBUTE4
        , CC_ERROR_TEXT
        , INTERFACE_HEADER_ATTRIBUTE9
        , INTERFACE_HEADER_ATTRIBUTE8
        , START_DATE_COMMITMENT
        , INTEREST_HEADER_ID
        , SET_OF_BOOKS_ID
        , DRAWEE_CONTACT_ID
        , CREDIT_METHOD_FOR_INSTALLMENTS
        , CUST_TRX_TYPE_ID
        , CREDIT_METHOD_FOR_RULES
        , PRINTING_PENDING
        , DOC_SEQUENCE_VALUE
        , REMITTANCE_BANK_ACCOUNT_ID
        , REASON_CODE
        , PRINTING_COUNT
        , LATE_CHARGES_ASSESSED
        , EDI_PROCESSED_FLAG
        , UPGRADE_METHOD
        , GLOBAL_ATTRIBUTE_CATEGORY
        , ORIG_SYSTEM_BATCH_NAME
        , SHIP_TO_ADDRESS_ID
        , DOC_SEQUENCE_ID
        , PRINTING_ORIGINAL_DATE
        , PREPAYMENT_FLAG
        , ORG_ID
        , GLOBAL_ATTRIBUTE5
        , RELATED_BATCH_SOURCE_ID
        , GLOBAL_ATTRIBUTE4
        , GLOBAL_ATTRIBUTE7
        , GLOBAL_ATTRIBUTE6
        , GLOBAL_ATTRIBUTE1
        , INTERNAL_NOTES
        , GLOBAL_ATTRIBUTE3
        , GLOBAL_ATTRIBUTE2
        , RA_POST_LOOP_NUMBER
        , GLOBAL_ATTRIBUTE9
        , PAYING_CUSTOMER_ID
        , GLOBAL_ATTRIBUTE8
        , BILL_TO_ADDRESS_ID
        , PAYING_SITE_USE_ID
        , POST_REQUEST_ID
        , PAYMENT_ATTRIBUTES
        , AGREEMENT_ID
        , ADDRESS_VERIFICATION_CODE
        , CUSTOMER_BANK_ACCOUNT_ID
        , SHIP_TO_CUSTOMER_ID
        , DEFAULT_USSGL_TRANSACTION_CODE
        , EDI_PROCESSED_STATUS
        , SHIP_TO_CONTACT_ID
        , REMIT_BANK_ACCT_USE_ID
        , TRX_NUMBER
        , COMMENTS
        , GLOBAL_ATTRIBUTE30
        , GLOBAL_ATTRIBUTE28
        , GLOBAL_ATTRIBUTE29
        , GLOBAL_ATTRIBUTE26
        , GLOBAL_ATTRIBUTE27
        , GLOBAL_ATTRIBUTE24
        , GLOBAL_ATTRIBUTE25
        , GLOBAL_ATTRIBUTE22
        , GLOBAL_ATTRIBUTE23
        , MRC_EXCHANGE_RATE
        , END_DATE_COMMITMENT
        , DOCUMENT_CREATION_DATE
        , GLOBAL_ATTRIBUTE20
        , GLOBAL_ATTRIBUTE21
        , DRAWEE_BANK_ACCOUNT_ID
        , REV_REC_APPLICATION
        , GLOBAL_ATTRIBUTE17
        , GLOBAL_ATTRIBUTE18
        , GLOBAL_ATTRIBUTE15
        , GLOBAL_ATTRIBUTE16
        , DRAWEE_ID
        , GLOBAL_ATTRIBUTE13
        , GLOBAL_ATTRIBUTE14
        , GLOBAL_ATTRIBUTE11
        , GLOBAL_ATTRIBUTE12
        , REMIT_TO_ADDRESS_ID
        , FOB_POINT
        , BILL_TO_CONTACT_ID
        , GLOBAL_ATTRIBUTE19
        , REVERSED_CASH_RECEIPT_ID
        , CREATED_FROM
        , PURCHASE_ORDER_REVISION
        , RECEIPT_METHOD_ID
        , SOLD_TO_CUSTOMER_ID
        , REMITTANCE_BATCH_ID
        , EXCHANGE_DATE
        , FINANCE_CHARGES
        , CREATED_BY
        , BR_AMOUNT
        , LEGAL_ENTITY_ID
        , INVOICING_RULE_ID
        , PREVIOUS_CUSTOMER_TRX_ID
        , ATTRIBUTE_CATEGORY
        , SHIPMENT_ID
        , OVERRIDE_REMIT_ACCOUNT_FLAG
        , SHIP_TO_SITE_USE_ID
        , EXCHANGE_RATE_TYPE
        , INTERFACE_HEADER_ATTRIBUTE11
        , INTERFACE_HEADER_ATTRIBUTE12
        , INTERFACE_HEADER_ATTRIBUTE13
        , INTERFACE_HEADER_ATTRIBUTE14
        , INTERFACE_HEADER_ATTRIBUTE15
        , BILLING_EXT_REQUEST
        , BR_UNPAID_FLAG
        , OLD_TRX_NUMBER
        , PRINTING_OPTION
        , CC_ERROR_CODE
        , PRIMARY_SALESREP_ID
        , INTERFACE_HEADER_ATTRIBUTE10
        , BATCH_ID
        , BATCH_SOURCE_ID
        , APPLICATION_ID
        , CREATION_DATE
        , LAST_UPDATED_BY
        , LAST_UPDATE_DATE
        , LAST_UPDATE_LOGIN
        , REQUEST_ID
        , PROGRAM_APPLICATION_ID
        , PROGRAM_ID
        , PROGRAM_UPDATE_DATE
        , WH_UPDATE_DATE
        , _FIVETRAN_DELETED
        , _FIVETRAN_ID
        , _FIVETRAN_SYNCED
        , PSA_DELETE_IND
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , SOLD_TO_ACCOUNT_BK
        , BILL_TO_SITE_USE_BK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(CUSTOMER_TRX_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as INVOICE_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(SOLD_TO_CUSTOMER_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as SOLD_TO_ACCOUNT_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(CUSTOMER_TRX_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(SOLD_TO_CUSTOMER_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as INVOICE_SOLD_TO_ACCOUNT_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(bill_to_site_use_id as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as BILL_TO_SITE_USE_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(CUSTOMER_TRX_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(bill_to_site_use_id as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as INVOICE_BILL_TO_SITE_USE_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(CUSTOMER_REFERENCE::text), '^^') 
            , '||', IFNULL(TRIM(STATUS_TRX::text), '^^') 
            , '||', IFNULL(TRIM(SPECIAL_INSTRUCTIONS::text), '^^') 
            , '||', IFNULL(TRIM(BILL_TO_CUSTOMER_ID::text), '^^') 
            , '||', IFNULL(TRIM(INITIAL_CUSTOMER_TRX_ID::text), '^^') 
            , '||', IFNULL(TRIM(TRX_DATE::text), '^^') 
            , '||', IFNULL(TRIM(POSTING_CONTROL_ID::text), '^^') 
            , '||', IFNULL(TRIM(TERRITORY_ID::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE3::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE2::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE1::text), '^^') 
            , '||', IFNULL(TRIM(DRAWEE_SITE_USE_ID::text), '^^') 
            , '||', IFNULL(TRIM(DEFAULT_TAX_EXEMPT_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE9::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE8::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE7::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE6::text), '^^') 
            , '||', IFNULL(TRIM(MRC_EXCHANGE_RATE_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE5::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE4::text), '^^') 
            , '||', IFNULL(TRIM(COMPLETE_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(PURCHASE_ORDER::text), '^^') 
            , '||', IFNULL(TRIM(CUSTOMER_REFERENCE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(TRAILER_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(TERM_ID::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE10::text), '^^') 
            , '||', IFNULL(TRIM(RELATED_CUSTOMER_TRX_ID::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE14::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE13::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE12::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE11::text), '^^') 
            , '||', IFNULL(TRIM(MRC_EXCHANGE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(SOLD_TO_CONTACT_ID::text), '^^') 
            , '||', IFNULL(TRIM(TERM_DUE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(PURCHASE_ORDER_DATE::text), '^^') 
            , '||', IFNULL(TRIM(APPROVAL_CODE::text), '^^') 
            , '||', IFNULL(TRIM(CT_REFERENCE::text), '^^') 
            , '||', IFNULL(TRIM(BILL_TO_SITE_USE_ID::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_DATE_ACTUAL::text), '^^') 
            , '||', IFNULL(TRIM(INTERFACE_HEADER_CONTEXT::text), '^^') 
            , '||', IFNULL(TRIM(BR_ON_HOLD_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(BILL_TEMPLATE_ID::text), '^^') 
            , '||', IFNULL(TRIM(DOCUMENT_TYPE_ID::text), '^^') 
            , '||', IFNULL(TRIM(PAYMENT_TRXN_EXTENSION_ID::text), '^^') 
            , '||', IFNULL(TRIM(CC_ERROR_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(RECURRED_FROM_TRX_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE15::text), '^^') 
            , '||', IFNULL(TRIM(INVOICE_CURRENCY_CODE::text), '^^') 
            , '||', IFNULL(TRIM(PRINTING_LAST_PRINTED::text), '^^') 
            , '||', IFNULL(TRIM(WAYBILL_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(SRC_INVOICING_RULE_ID::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE10::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_VIA::text), '^^') 
            , '||', IFNULL(TRIM(DEFAULT_USSGL_TRX_CODE_CONTEXT::text), '^^') 
            , '||', IFNULL(TRIM(AX_ACCOUNTED_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(SOLD_TO_SITE_USE_ID::text), '^^') 
            , '||', IFNULL(TRIM(MANDATE_LAST_TRX_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(EXCHANGE_RATE::text), '^^') 
            , '||', IFNULL(TRIM(PAYMENT_SERVER_ORDER_NUM::text), '^^') 
            , '||', IFNULL(TRIM(CONTRACT_ID::text), '^^') 
            , '||', IFNULL(TRIM(INTERFACE_HEADER_ATTRIBUTE3::text), '^^') 
            , '||', IFNULL(TRIM(INTERFACE_HEADER_ATTRIBUTE2::text), '^^') 
            , '||', IFNULL(TRIM(INTERFACE_HEADER_ATTRIBUTE1::text), '^^') 
            , '||', IFNULL(TRIM(LAST_PRINTED_SEQUENCE_NUM::text), '^^') 
            , '||', IFNULL(TRIM(INTERFACE_HEADER_ATTRIBUTE7::text), '^^') 
            , '||', IFNULL(TRIM(INTERFACE_HEADER_ATTRIBUTE6::text), '^^') 
            , '||', IFNULL(TRIM(INTERFACE_HEADER_ATTRIBUTE5::text), '^^') 
            , '||', IFNULL(TRIM(INTERFACE_HEADER_ATTRIBUTE4::text), '^^') 
            , '||', IFNULL(TRIM(CC_ERROR_TEXT::text), '^^') 
            , '||', IFNULL(TRIM(INTERFACE_HEADER_ATTRIBUTE9::text), '^^') 
            , '||', IFNULL(TRIM(INTERFACE_HEADER_ATTRIBUTE8::text), '^^') 
            , '||', IFNULL(TRIM(START_DATE_COMMITMENT::text), '^^') 
            , '||', IFNULL(TRIM(INTEREST_HEADER_ID::text), '^^') 
            , '||', IFNULL(TRIM(SET_OF_BOOKS_ID::text), '^^') 
            , '||', IFNULL(TRIM(DRAWEE_CONTACT_ID::text), '^^') 
            , '||', IFNULL(TRIM(CREDIT_METHOD_FOR_INSTALLMENTS::text), '^^') 
            , '||', IFNULL(TRIM(CUST_TRX_TYPE_ID::text), '^^') 
            , '||', IFNULL(TRIM(CREDIT_METHOD_FOR_RULES::text), '^^') 
            , '||', IFNULL(TRIM(PRINTING_PENDING::text), '^^') 
            , '||', IFNULL(TRIM(DOC_SEQUENCE_VALUE::text), '^^') 
            , '||', IFNULL(TRIM(REMITTANCE_BANK_ACCOUNT_ID::text), '^^') 
            , '||', IFNULL(TRIM(REASON_CODE::text), '^^') 
            , '||', IFNULL(TRIM(PRINTING_COUNT::text), '^^') 
            , '||', IFNULL(TRIM(LATE_CHARGES_ASSESSED::text), '^^') 
            , '||', IFNULL(TRIM(EDI_PROCESSED_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(UPGRADE_METHOD::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(ORIG_SYSTEM_BATCH_NAME::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_TO_ADDRESS_ID::text), '^^') 
            , '||', IFNULL(TRIM(DOC_SEQUENCE_ID::text), '^^') 
            , '||', IFNULL(TRIM(PRINTING_ORIGINAL_DATE::text), '^^') 
            , '||', IFNULL(TRIM(PREPAYMENT_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(ORG_ID::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE5::text), '^^') 
            , '||', IFNULL(TRIM(RELATED_BATCH_SOURCE_ID::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE4::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE7::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE6::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE1::text), '^^') 
            , '||', IFNULL(TRIM(INTERNAL_NOTES::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE3::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE2::text), '^^') 
            , '||', IFNULL(TRIM(RA_POST_LOOP_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE9::text), '^^') 
            , '||', IFNULL(TRIM(PAYING_CUSTOMER_ID::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE8::text), '^^') 
            , '||', IFNULL(TRIM(BILL_TO_ADDRESS_ID::text), '^^') 
            , '||', IFNULL(TRIM(PAYING_SITE_USE_ID::text), '^^') 
            , '||', IFNULL(TRIM(POST_REQUEST_ID::text), '^^') 
            , '||', IFNULL(TRIM(PAYMENT_ATTRIBUTES::text), '^^') 
            , '||', IFNULL(TRIM(AGREEMENT_ID::text), '^^') 
            , '||', IFNULL(TRIM(ADDRESS_VERIFICATION_CODE::text), '^^') 
            , '||', IFNULL(TRIM(CUSTOMER_BANK_ACCOUNT_ID::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_TO_CUSTOMER_ID::text), '^^') 
            , '||', IFNULL(TRIM(DEFAULT_USSGL_TRANSACTION_CODE::text), '^^') 
            , '||', IFNULL(TRIM(EDI_PROCESSED_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_TO_CONTACT_ID::text), '^^') 
            , '||', IFNULL(TRIM(REMIT_BANK_ACCT_USE_ID::text), '^^') 
            , '||', IFNULL(TRIM(TRX_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(COMMENTS::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE30::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE28::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE29::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE26::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE27::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE24::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE25::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE22::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE23::text), '^^') 
            , '||', IFNULL(TRIM(MRC_EXCHANGE_RATE::text), '^^') 
            , '||', IFNULL(TRIM(END_DATE_COMMITMENT::text), '^^') 
            , '||', IFNULL(TRIM(DOCUMENT_CREATION_DATE::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE20::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE21::text), '^^') 
            , '||', IFNULL(TRIM(DRAWEE_BANK_ACCOUNT_ID::text), '^^') 
            , '||', IFNULL(TRIM(REV_REC_APPLICATION::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE17::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE18::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE15::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE16::text), '^^') 
            , '||', IFNULL(TRIM(DRAWEE_ID::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE13::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE14::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE11::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE12::text), '^^') 
            , '||', IFNULL(TRIM(REMIT_TO_ADDRESS_ID::text), '^^') 
            , '||', IFNULL(TRIM(FOB_POINT::text), '^^') 
            , '||', IFNULL(TRIM(BILL_TO_CONTACT_ID::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE19::text), '^^') 
            , '||', IFNULL(TRIM(REVERSED_CASH_RECEIPT_ID::text), '^^') 
            , '||', IFNULL(TRIM(CREATED_FROM::text), '^^') 
            , '||', IFNULL(TRIM(PURCHASE_ORDER_REVISION::text), '^^') 
            , '||', IFNULL(TRIM(RECEIPT_METHOD_ID::text), '^^') 
            , '||', IFNULL(TRIM(SOLD_TO_CUSTOMER_ID::text), '^^') 
            , '||', IFNULL(TRIM(REMITTANCE_BATCH_ID::text), '^^') 
            , '||', IFNULL(TRIM(EXCHANGE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(FINANCE_CHARGES::text), '^^') 
            , '||', IFNULL(TRIM(CREATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(BR_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(LEGAL_ENTITY_ID::text), '^^') 
            , '||', IFNULL(TRIM(INVOICING_RULE_ID::text), '^^') 
            , '||', IFNULL(TRIM(PREVIOUS_CUSTOMER_TRX_ID::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(SHIPMENT_ID::text), '^^') 
            , '||', IFNULL(TRIM(OVERRIDE_REMIT_ACCOUNT_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_TO_SITE_USE_ID::text), '^^') 
            , '||', IFNULL(TRIM(EXCHANGE_RATE_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(INTERFACE_HEADER_ATTRIBUTE11::text), '^^') 
            , '||', IFNULL(TRIM(INTERFACE_HEADER_ATTRIBUTE12::text), '^^') 
            , '||', IFNULL(TRIM(INTERFACE_HEADER_ATTRIBUTE13::text), '^^') 
            , '||', IFNULL(TRIM(INTERFACE_HEADER_ATTRIBUTE14::text), '^^') 
            , '||', IFNULL(TRIM(INTERFACE_HEADER_ATTRIBUTE15::text), '^^') 
            , '||', IFNULL(TRIM(BILLING_EXT_REQUEST::text), '^^') 
            , '||', IFNULL(TRIM(BR_UNPAID_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(OLD_TRX_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(PRINTING_OPTION::text), '^^') 
            , '||', IFNULL(TRIM(CC_ERROR_CODE::text), '^^') 
            , '||', IFNULL(TRIM(PRIMARY_SALESREP_ID::text), '^^') 
            , '||', IFNULL(TRIM(INTERFACE_HEADER_ATTRIBUTE10::text), '^^') 
            , '||', IFNULL(TRIM(BATCH_ID::text), '^^') 
            , '||', IFNULL(TRIM(BATCH_SOURCE_ID::text), '^^') 
            , '||', IFNULL(TRIM(APPLICATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(CREATION_DATE::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_LOGIN::text), '^^') 
            , '||', IFNULL(TRIM(REQUEST_ID::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_APPLICATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_ID::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_UPDATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT