---- SRC LAYER ----
WITH
SRC_S              as ( SELECT * FROM {{ source('outd_ocf_ar', 'ra_customer_trx_all') }} as SRC  ),
SRC_A              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  ),
SRC_S2             as ( SELECT * FROM {{ source('outd_ocf_hz', 'hz_cust_accounts') }} as SRC 
                        qualify 1 = row_number()over (partition by CUST_ACCOUNT_ID order by psa_load_dts )  ),
SRC_S3             as ( SELECT * FROM {{ source('outd_ocf_hz', 'hz_cust_accounts') }} as SRC 
                        qualify 1 = row_number()over (partition by CUST_ACCOUNT_ID order by psa_load_dts )  ),
SRC_S4             as ( SELECT * FROM {{ source('outd_ocf_hz', 'hz_cust_accounts') }} as SRC 
                        qualify 1 = row_number()over (partition by CUST_ACCOUNT_ID order by psa_load_dts )  )

/*
SRC_S              as ( SELECT * FROM outd_ocf_ar.ra_customer_trx_all )
, SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
, SRC_S2             as ( SELECT * FROM outd_ocf_hz.hz_cust_accounts )
, SRC_S3             as ( SELECT * FROM outd_ocf_hz.hz_cust_accounts )
, SRC_S4             as ( SELECT * FROM outd_ocf_hz.hz_cust_accounts )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        to_char(CUSTOMER_TRX_ID)                                     as                                         INVOICE_BK
      , CUSTOMER_TRX_ID
      , POST_REQUEST_ID
      , REVERSED_CASH_RECEIPT_ID
      , FINANCE_CHARGES
      , GLOBAL_ATTRIBUTE_NUMBER_9
      , REQUIRES_MANUAL_SCHEDULING
      , GLOBAL_ATTRIBUTE_NUMBER_1
      , INVOICE_CURRENCY_CODE
      , SOLD_TO_PARTY_ID
      , WAYBILL_NUMBER
      , GLOBAL_ATTRIBUTE_3
      , CT_REFERENCE
      , GLOBAL_ATTRIBUTE_4
      , LATE_CHARGES_ASSESSED
      , LAST_UPDATE_LOGIN
      , ATTRIBUTE_7
      , AGREEMENT_ID
      , LAST_UPDATED_BY
      , GLOBAL_ATTRIBUTE_2
      , READY_FOR_XML_DELIVERY_FLAG
      , PRINTING_COUNT
      , PAYMENT_TRXN_EXTENSION_ID
      , PURCHASE_ORDER_REVISION
      , MRC_EXCHANGE_DATE
      , PRINTING_PENDING
      , FIRST_PTY_REG_ID
      , GLOBAL_ATTRIBUTE_27
      , ATTRIBUTE_8
      , CONTRACT_ID
      , TRX_NUMBER
      , SHIP_TO_CONTACT_ID
      , GLOBAL_ATTRIBUTE_7
      , DOCUMENT_STATUS_CODE
      , INTERCOMPANY_FLAG
      , SOLD_TO_SITE_USE_ID
      , GLOBAL_ATTRIBUTE_8
      , GLOBAL_ATTRIBUTE_NUMBER_2
      , LEGAL_ENTITY_ID
      , BILL_TO_ADDRESS_ID
      , GLOBAL_ATTRIBUTE_13
      , ATTRIBUTE_5
      , DOC_SEQUENCE_VALUE
      , GLOBAL_ATTRIBUTE_21
      , GLOBAL_ATTRIBUTE_6
      , DOCUMENT_SUB_TYPE
      , ATTRIBUTE_3
      , END_DATE_COMMITMENT
      , REMIT_TO_ADDRESS_ID
      , PURCHASE_ORDER_DATE
      , CC_ERROR_TEXT
      , USER_DEFINED_FISC_CLASS
      , SHIP_TO_CUSTOMER_ID
      , INTERFACE_HEADER_NUMBER_2
      , CUST_TRX_TYPE_SEQ_ID
      , DRAWEE_SITE_USE_ID
      , ATTRIBUTE_NUMBER_5
      , GLOBAL_ATTRIBUTE_14
      , BILLING_EXT_REQUEST_ID
      , GLOBAL_ATTRIBUTE_22
      , UPGRADE_METHOD
      , TRX_BUSINESS_CATEGORY
      , BILL_PLAN_PERIOD
      , INTERFACE_HEADER_ATTRIBUTE_8
      , INTERFACE_HEADER_DATE_3
      , SOLD_TO_CUSTOMER_ID
      , INTERFACE_HEADER_ATTRIBUTE_6
      , FISCAL_DOC_ACCESS_KEY
      , PAYING_CUSTOMER_ID
      , INTEREST_HEADER_ID
      , ATTRIBUTE_DATE_2
      , CREATION_DATE
      , BATCH_SOURCE_SEQ_ID
      , SHIP_TO_PARTY_ADDRESS_ID
      , INTERFACE_HEADER_NUMBER_3
      , ATTRIBUTE_CATEGORY
      , ATTRIBUTE_4
      , ATTRIBUTE_NUMBER_3
      , CONTROL_COMPLETION_REASON_CODE
      , ATTRIBUTE_9
      , ORIG_SYSTEM_BATCH_NAME
      , GLOBAL_ATTRIBUTE_17
      , SOURCE_DOCUMENT_ID
      , INTERFACE_HEADER_NUMBER_5
      , THIRD_PTY_REG_ID
      , TRX_DATE
      , GLOBAL_ATTRIBUTE_29
      , BILLING_DATE
      , GLOBAL_ATTRIBUTE_10
      , ORG_ID
      , EXCHANGE_RATE_TYPE
      , DEFAULT_TAX_EXEMPT_FLAG
      , SHIPMENT_ID
      , INTERFACE_HEADER_DATE_2
      , BILL_TO_SITE_USE_ID
      , REMIT_TO_ADDRESS_SEQ_ID
      , DOC_SEQUENCE_ID
      , TERM_DUE_DATE
      , POSTING_CONTROL_ID
      , RELATED_CUSTOMER_TRX_ID
      , SHIP_DATE_ACTUAL
      , ATTRIBUTE_14
      , GLOBAL_ATTRIBUTE_NUMBER_12
      , MRC_EXCHANGE_RATE
      , INTERFACE_HEADER_DATE_5
      , INTERFACE_HEADER_ATTRIBUTE_14
      , ATTRIBUTE_13
      , OBJECT_VERSION_NUMBER
      , GLOBAL_ATTRIBUTE_NUMBER_4
      , ATTRIBUTE_NUMBER_2
      , BILL_PLAN_ID
      , BATCH_ID
      , RECEIPT_METHOD_ID
      , INTERFACE_HEADER_ATTRIBUTE_15
      , REMIT_BANK_ACCT_USE_ID
      , PRINTING_OPTION
      , FOB_POINT
      , APPLICATION_ID
      , DEFAULT_TAXATION_COUNTRY
      , GLOBAL_ATTRIBUTE_11
      , EDI_PROCESSED_STATUS
      , PRIMARY_RESOURCE_SALESREP_ID
      , INTERFACE_HEADER_NUMBER_1
      , GLOBAL_ATTRIBUTE_12
      , INTERFACE_HEADER_DATE_1
      , PROGRAM_ID
      , DEFAULT_USSGL_TRANSACTION_CODE
      , CREDIT_METHOD_FOR_INSTALLMENTS
      , RECURRED_FROM_TRX_NUMBER
      , SHIP_TO_SITE_USE_ID
      , WH_UPDATE_DATE
      , SHIP_TO_PARTY_CONTACT_ID
      , GLOBAL_ATTRIBUTE_5
      , OVERRIDE_REMIT_ACCOUNT_FLAG
      , RA_POST_LOOP_NUMBER
      , REMITTANCE_BANK_ACCOUNT_ID
      , BR_ON_HOLD_FLAG
      , PREVIOUS_CUSTOMER_TRX_ID
      , ATTRIBUTE_6
      , BILL_TEMPLATE_NAME
      , PROGRAM_UPDATE_DATE
      , TRX_CLASS
      , REQUEST_ID
      , GLOBAL_ATTRIBUTE_NUMBER_6
      , MRC_EXCHANGE_RATE_TYPE
      , BILL_TEMPLATE_ID
      , GLOBAL_ATTRIBUTE_19
      , GLOBAL_ATTRIBUTE_DATE_1
      , GLOBAL_ATTRIBUTE_NUMBER_8
      , INTERFACE_HEADER_CONTEXT
      , INTERFACE_HEADER_ATTRIBUTE_4
      , GLOBAL_ATTRIBUTE_9
      , SET_OF_BOOKS_ID
      , BR_AMOUNT
      , INITIAL_CUSTOMER_TRX_ID
      , SOURCE_DOCUMENT_TYPE
      , INTERNAL_NOTES
      , ATTRIBUTE_11
      , LAST_UPDATE_DATE
      , INTERFACE_HEADER_ATTRIBUTE_11
      , GLOBAL_ATTRIBUTE_NUMBER_3
      , BR_UNPAID_FLAG
      , GLOBAL_ATTRIBUTE_26
      , PURCHASE_ORDER
      , ATTRIBUTE_DATE_4
      , INVOICING_RULE_ID
      , BILL_TO_CUSTOMER_ID
      , BILL_TO_CONTACT_ID
      , ATTRIBUTE_DATE_5
      , GLOBAL_ATTRIBUTE_NUMBER_5
      , ATTRIBUTE_DATE_3
      , ATTRIBUTE_10
      , GLOBAL_ATTRIBUTE_24
      , INTERFACE_HEADER_ATTRIBUTE_2
      , INTERFACE_HEADER_ATTRIBUTE_12
      , RELATED_BATCH_SOURCE_SEQ_ID
      , INTERFACE_HEADER_ATTRIBUTE_3
      , STATUS_TRX
      , AX_ACCOUNTED_FLAG
      , INTERFACE_HEADER_ATTRIBUTE_5
      , SHIP_TO_ADDRESS_ID
      , START_DATE_COMMITMENT
      , OLD_TRX_NUMBER
      , DEL_CONTACT_EMAIL_ADDRESS
      , ATTRIBUTE_12
      , INTERFACE_HEADER_ATTRIBUTE_9
      , LAST_PRINTED_SEQUENCE_NUM
      , DOCUMENT_TYPE_ID
      , INTERFACE_HEADER_ATTRIBUTE_13
      , CC_ERROR_CODE
      , GLOBAL_ATTRIBUTE_18
      , SRC_INVOICING_RULE_ID
      , GLOBAL_ATTRIBUTE_23
      , GLOBAL_ATTRIBUTE_NUMBER_7
      , GLOBAL_ATTRIBUTE_28
      , REV_REC_APPLICATION
      , ATTRIBUTE_15
      , SHIP_VIA
      , GLOBAL_ATTRIBUTE_15
      , CUSTOMER_BANK_ACCOUNT_ID
      , EDI_PROCESSED_FLAG
      , SPECIAL_INSTRUCTIONS
      , TERM_ID
      , PAYMENT_ATTRIBUTES
      , ATTRIBUTE_NUMBER_4
      , ADDRESS_VERIFICATION_CODE
      , CREATED_BY
      , GLOBAL_ATTRIBUTE_DATE_5
      , GLOBAL_ATTRIBUTE_NUMBER_10
      , GLOBAL_ATTRIBUTE_DATE_3
      , PAYING_SITE_USE_ID
      , GLOBAL_ATTRIBUTE_20
      , APPROVAL_CODE
      , DRAWEE_CONTACT_ID
      , EXCHANGE_RATE
      , CUSTOMER_REFERENCE
      , CREDIT_METHOD_FOR_RULES
      , PRINTING_ORIGINAL_DATE
      , COMMENTS
      , INTERFACE_HEADER_ATTRIBUTE_7
      , CREATED_FROM
      , PROGRAM_APPLICATION_ID
      , ATTRIBUTE_NUMBER_1
      , GLOBAL_ATTRIBUTE_16
      , GLOBAL_ATTRIBUTE_DATE_2
      , SOURCE_SYSTEM
      , TERRITORY_ID
      , SHIP_TO_PARTY_SITE_USE_ID
      , INTERFACE_HEADER_ATTRIBUTE_1
      , INTERFACE_HEADER_ATTRIBUTE_10
      , STRUCTURED_PAYMENT_REFERENCE
      , GLOBAL_ATTRIBUTE_1
      , SOLD_TO_CONTACT_ID
      , GLOBAL_ATTRIBUTE_NUMBER_11
      , GLOBAL_ATTRIBUTE_25
      , PREPAYMENT_FLAG
      , EXCHANGE_DATE
      , DELIVERY_METHOD_CODE
      , DRAWEE_ID
      , ATTRIBUTE_2
      , COMPLETE_FLAG
      , DOCUMENT_CREATION_DATE
      , DEFAULT_USSGL_TRX_CODE_CONTEXT
      , GLOBAL_ATTRIBUTE_CATEGORY
      , DRAWEE_BANK_ACCOUNT_ID
      , INTERFACE_HEADER_DATE_4
      , GLOBAL_ATTRIBUTE_30
      , GLOBAL_ATTRIBUTE_DATE_4
      , ATTRIBUTE_DATE_1
      , PAYMENT_SERVER_ORDER_NUM
      , REMITTANCE_BATCH_ID
      , ATTRIBUTE_1
      , SHIP_TO_PARTY_ID
      , PRINT_REQUEST_ID
      , REASON_CODE
      , CC_ERROR_FLAG
      , CUSTOMER_REFERENCE_DATE
      , PRINTING_LAST_PRINTED
      , FISCAL_DOC_STATUS
      , INTERFACE_HEADER_NUMBER_4
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED )                   as                                           LOAD_DTS
    FROM SRC_S
)

, LOGIC_A as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_A
)

, LOGIC_S2 as (
    SELECT
        CUST_ACCOUNT_ID                                              as                                 S2_CUST_ACCOUNT_ID
      , ACCOUNT_NUMBER                                               as                                  S2_ACCOUNT_NUMBER
    FROM SRC_S2
)

, LOGIC_S3 as (
    SELECT
        CUST_ACCOUNT_ID                                              as                                 S3_CUST_ACCOUNT_ID
      , ACCOUNT_NUMBER                                               as                                  S3_ACCOUNT_NUMBER
    FROM SRC_S3
)

, LOGIC_S4 as (
    SELECT
        CUST_ACCOUNT_ID                                              as                                 S4_CUST_ACCOUNT_ID
      , ACCOUNT_NUMBER                                               as                                  S4_ACCOUNT_NUMBER
    FROM SRC_S4
)
---- RENAME LAYER ----

, RENAME_S as (
    SELECT
        INVOICE_BK
      , CUSTOMER_TRX_ID
      , POST_REQUEST_ID
      , REVERSED_CASH_RECEIPT_ID
      , FINANCE_CHARGES
      , GLOBAL_ATTRIBUTE_NUMBER_9
      , REQUIRES_MANUAL_SCHEDULING
      , GLOBAL_ATTRIBUTE_NUMBER_1
      , INVOICE_CURRENCY_CODE
      , SOLD_TO_PARTY_ID
      , WAYBILL_NUMBER
      , GLOBAL_ATTRIBUTE_3
      , CT_REFERENCE
      , GLOBAL_ATTRIBUTE_4
      , LATE_CHARGES_ASSESSED
      , LAST_UPDATE_LOGIN
      , ATTRIBUTE_7
      , AGREEMENT_ID
      , LAST_UPDATED_BY
      , GLOBAL_ATTRIBUTE_2
      , READY_FOR_XML_DELIVERY_FLAG
      , PRINTING_COUNT
      , PAYMENT_TRXN_EXTENSION_ID
      , PURCHASE_ORDER_REVISION
      , MRC_EXCHANGE_DATE
      , PRINTING_PENDING
      , FIRST_PTY_REG_ID
      , GLOBAL_ATTRIBUTE_27
      , ATTRIBUTE_8
      , CONTRACT_ID
      , TRX_NUMBER
      , SHIP_TO_CONTACT_ID
      , GLOBAL_ATTRIBUTE_7
      , DOCUMENT_STATUS_CODE
      , INTERCOMPANY_FLAG
      , SOLD_TO_SITE_USE_ID
      , GLOBAL_ATTRIBUTE_8
      , GLOBAL_ATTRIBUTE_NUMBER_2
      , LEGAL_ENTITY_ID
      , BILL_TO_ADDRESS_ID
      , GLOBAL_ATTRIBUTE_13
      , ATTRIBUTE_5
      , DOC_SEQUENCE_VALUE
      , GLOBAL_ATTRIBUTE_21
      , GLOBAL_ATTRIBUTE_6
      , DOCUMENT_SUB_TYPE
      , ATTRIBUTE_3
      , END_DATE_COMMITMENT
      , REMIT_TO_ADDRESS_ID
      , PURCHASE_ORDER_DATE
      , CC_ERROR_TEXT
      , USER_DEFINED_FISC_CLASS
      , SHIP_TO_CUSTOMER_ID
      , INTERFACE_HEADER_NUMBER_2
      , CUST_TRX_TYPE_SEQ_ID
      , DRAWEE_SITE_USE_ID
      , ATTRIBUTE_NUMBER_5
      , GLOBAL_ATTRIBUTE_14
      , BILLING_EXT_REQUEST_ID
      , GLOBAL_ATTRIBUTE_22
      , UPGRADE_METHOD
      , TRX_BUSINESS_CATEGORY
      , BILL_PLAN_PERIOD
      , INTERFACE_HEADER_ATTRIBUTE_8
      , INTERFACE_HEADER_DATE_3
      , SOLD_TO_CUSTOMER_ID
      , INTERFACE_HEADER_ATTRIBUTE_6
      , FISCAL_DOC_ACCESS_KEY
      , PAYING_CUSTOMER_ID
      , INTEREST_HEADER_ID
      , ATTRIBUTE_DATE_2
      , CREATION_DATE
      , BATCH_SOURCE_SEQ_ID
      , SHIP_TO_PARTY_ADDRESS_ID
      , INTERFACE_HEADER_NUMBER_3
      , ATTRIBUTE_CATEGORY
      , ATTRIBUTE_4
      , ATTRIBUTE_NUMBER_3
      , CONTROL_COMPLETION_REASON_CODE
      , ATTRIBUTE_9
      , ORIG_SYSTEM_BATCH_NAME
      , GLOBAL_ATTRIBUTE_17
      , SOURCE_DOCUMENT_ID
      , INTERFACE_HEADER_NUMBER_5
      , THIRD_PTY_REG_ID
      , TRX_DATE
      , GLOBAL_ATTRIBUTE_29
      , BILLING_DATE
      , GLOBAL_ATTRIBUTE_10
      , ORG_ID
      , EXCHANGE_RATE_TYPE
      , DEFAULT_TAX_EXEMPT_FLAG
      , SHIPMENT_ID
      , INTERFACE_HEADER_DATE_2
      , BILL_TO_SITE_USE_ID
      , REMIT_TO_ADDRESS_SEQ_ID
      , DOC_SEQUENCE_ID
      , TERM_DUE_DATE
      , POSTING_CONTROL_ID
      , RELATED_CUSTOMER_TRX_ID
      , SHIP_DATE_ACTUAL
      , ATTRIBUTE_14
      , GLOBAL_ATTRIBUTE_NUMBER_12
      , MRC_EXCHANGE_RATE
      , INTERFACE_HEADER_DATE_5
      , INTERFACE_HEADER_ATTRIBUTE_14
      , ATTRIBUTE_13
      , OBJECT_VERSION_NUMBER
      , GLOBAL_ATTRIBUTE_NUMBER_4
      , ATTRIBUTE_NUMBER_2
      , BILL_PLAN_ID
      , BATCH_ID
      , RECEIPT_METHOD_ID
      , INTERFACE_HEADER_ATTRIBUTE_15
      , REMIT_BANK_ACCT_USE_ID
      , PRINTING_OPTION
      , FOB_POINT
      , APPLICATION_ID
      , DEFAULT_TAXATION_COUNTRY
      , GLOBAL_ATTRIBUTE_11
      , EDI_PROCESSED_STATUS
      , PRIMARY_RESOURCE_SALESREP_ID
      , INTERFACE_HEADER_NUMBER_1
      , GLOBAL_ATTRIBUTE_12
      , INTERFACE_HEADER_DATE_1
      , PROGRAM_ID
      , DEFAULT_USSGL_TRANSACTION_CODE
      , CREDIT_METHOD_FOR_INSTALLMENTS
      , RECURRED_FROM_TRX_NUMBER
      , SHIP_TO_SITE_USE_ID
      , WH_UPDATE_DATE
      , SHIP_TO_PARTY_CONTACT_ID
      , GLOBAL_ATTRIBUTE_5
      , OVERRIDE_REMIT_ACCOUNT_FLAG
      , RA_POST_LOOP_NUMBER
      , REMITTANCE_BANK_ACCOUNT_ID
      , BR_ON_HOLD_FLAG
      , PREVIOUS_CUSTOMER_TRX_ID
      , ATTRIBUTE_6
      , BILL_TEMPLATE_NAME
      , PROGRAM_UPDATE_DATE
      , TRX_CLASS
      , REQUEST_ID
      , GLOBAL_ATTRIBUTE_NUMBER_6
      , MRC_EXCHANGE_RATE_TYPE
      , BILL_TEMPLATE_ID
      , GLOBAL_ATTRIBUTE_19
      , GLOBAL_ATTRIBUTE_DATE_1
      , GLOBAL_ATTRIBUTE_NUMBER_8
      , INTERFACE_HEADER_CONTEXT
      , INTERFACE_HEADER_ATTRIBUTE_4
      , GLOBAL_ATTRIBUTE_9
      , SET_OF_BOOKS_ID
      , BR_AMOUNT
      , INITIAL_CUSTOMER_TRX_ID
      , SOURCE_DOCUMENT_TYPE
      , INTERNAL_NOTES
      , ATTRIBUTE_11
      , LAST_UPDATE_DATE
      , INTERFACE_HEADER_ATTRIBUTE_11
      , GLOBAL_ATTRIBUTE_NUMBER_3
      , BR_UNPAID_FLAG
      , GLOBAL_ATTRIBUTE_26
      , PURCHASE_ORDER
      , ATTRIBUTE_DATE_4
      , INVOICING_RULE_ID
      , BILL_TO_CUSTOMER_ID
      , BILL_TO_CONTACT_ID
      , ATTRIBUTE_DATE_5
      , GLOBAL_ATTRIBUTE_NUMBER_5
      , ATTRIBUTE_DATE_3
      , ATTRIBUTE_10
      , GLOBAL_ATTRIBUTE_24
      , INTERFACE_HEADER_ATTRIBUTE_2
      , INTERFACE_HEADER_ATTRIBUTE_12
      , RELATED_BATCH_SOURCE_SEQ_ID
      , INTERFACE_HEADER_ATTRIBUTE_3
      , STATUS_TRX
      , AX_ACCOUNTED_FLAG
      , INTERFACE_HEADER_ATTRIBUTE_5
      , SHIP_TO_ADDRESS_ID
      , START_DATE_COMMITMENT
      , OLD_TRX_NUMBER
      , DEL_CONTACT_EMAIL_ADDRESS
      , ATTRIBUTE_12
      , INTERFACE_HEADER_ATTRIBUTE_9
      , LAST_PRINTED_SEQUENCE_NUM
      , DOCUMENT_TYPE_ID
      , INTERFACE_HEADER_ATTRIBUTE_13
      , CC_ERROR_CODE
      , GLOBAL_ATTRIBUTE_18
      , SRC_INVOICING_RULE_ID
      , GLOBAL_ATTRIBUTE_23
      , GLOBAL_ATTRIBUTE_NUMBER_7
      , GLOBAL_ATTRIBUTE_28
      , REV_REC_APPLICATION
      , ATTRIBUTE_15
      , SHIP_VIA
      , GLOBAL_ATTRIBUTE_15
      , CUSTOMER_BANK_ACCOUNT_ID
      , EDI_PROCESSED_FLAG
      , SPECIAL_INSTRUCTIONS
      , TERM_ID
      , PAYMENT_ATTRIBUTES
      , ATTRIBUTE_NUMBER_4
      , ADDRESS_VERIFICATION_CODE
      , CREATED_BY
      , GLOBAL_ATTRIBUTE_DATE_5
      , GLOBAL_ATTRIBUTE_NUMBER_10
      , GLOBAL_ATTRIBUTE_DATE_3
      , PAYING_SITE_USE_ID
      , GLOBAL_ATTRIBUTE_20
      , APPROVAL_CODE
      , DRAWEE_CONTACT_ID
      , EXCHANGE_RATE
      , CUSTOMER_REFERENCE
      , CREDIT_METHOD_FOR_RULES
      , PRINTING_ORIGINAL_DATE
      , COMMENTS
      , INTERFACE_HEADER_ATTRIBUTE_7
      , CREATED_FROM
      , PROGRAM_APPLICATION_ID
      , ATTRIBUTE_NUMBER_1
      , GLOBAL_ATTRIBUTE_16
      , GLOBAL_ATTRIBUTE_DATE_2
      , SOURCE_SYSTEM
      , TERRITORY_ID
      , SHIP_TO_PARTY_SITE_USE_ID
      , INTERFACE_HEADER_ATTRIBUTE_1
      , INTERFACE_HEADER_ATTRIBUTE_10
      , STRUCTURED_PAYMENT_REFERENCE
      , GLOBAL_ATTRIBUTE_1
      , SOLD_TO_CONTACT_ID
      , GLOBAL_ATTRIBUTE_NUMBER_11
      , GLOBAL_ATTRIBUTE_25
      , PREPAYMENT_FLAG
      , EXCHANGE_DATE
      , DELIVERY_METHOD_CODE
      , DRAWEE_ID
      , ATTRIBUTE_2
      , COMPLETE_FLAG
      , DOCUMENT_CREATION_DATE
      , DEFAULT_USSGL_TRX_CODE_CONTEXT
      , GLOBAL_ATTRIBUTE_CATEGORY
      , DRAWEE_BANK_ACCOUNT_ID
      , INTERFACE_HEADER_DATE_4
      , GLOBAL_ATTRIBUTE_30
      , GLOBAL_ATTRIBUTE_DATE_4
      , ATTRIBUTE_DATE_1
      , PAYMENT_SERVER_ORDER_NUM
      , REMITTANCE_BATCH_ID
      , ATTRIBUTE_1
      , SHIP_TO_PARTY_ID
      , PRINT_REQUEST_ID
      , REASON_CODE
      , CC_ERROR_FLAG
      , CUSTOMER_REFERENCE_DATE
      , PRINTING_LAST_PRINTED
      , FISCAL_DOC_STATUS
      , INTERFACE_HEADER_NUMBER_4
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , LOAD_DTS
    FROM LOGIC_S
)

, RENAME_A as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_A
)

, RENAME_S2 as (
    SELECT
        S2_CUST_ACCOUNT_ID
      , S2_ACCOUNT_NUMBER
    FROM LOGIC_S2
)

, RENAME_S3 as (
    SELECT
        S3_CUST_ACCOUNT_ID
      , S3_ACCOUNT_NUMBER
    FROM LOGIC_S3
)

, RENAME_S4 as (
    SELECT
        S4_CUST_ACCOUNT_ID
      , S4_ACCOUNT_NUMBER
    FROM LOGIC_S4
)
---- FILTER LAYER ----

, FILTER_S as (
    SELECT *
    FROM RENAME_S
)

, FILTER_A as (
    SELECT *
    FROM RENAME_A
    WHERE rec_src = 'USCLOUD.ORCL.OCFPRD.CUSTOMER_TRX_ALL'
)

, FILTER_S2 as (
    SELECT *
    FROM RENAME_S2
)

, FILTER_S3 as (
    SELECT *
    FROM RENAME_S3
)

, FILTER_S4 as (
    SELECT *
    FROM RENAME_S4
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_S
    INNER JOIN FILTER_A
        ON '1' = '1'
    LEFT JOIN FILTER_S2
        ON BILL_TO_CUSTOMER_ID = S2_CUST_ACCOUNT_ID
    LEFT JOIN FILTER_S3
        ON SOLD_TO_CUSTOMER_ID = S2_CUST_ACCOUNT_ID
    LEFT JOIN FILTER_S4
        ON SHIP_TO_CUSTOMER_ID = S2_CUST_ACCOUNT_ID
)

---- FINAL LAYER ----
SELECT
          INVOICE_BK
        , CUSTOMER_TRX_ID
        , POST_REQUEST_ID
        , REVERSED_CASH_RECEIPT_ID
        , FINANCE_CHARGES
        , GLOBAL_ATTRIBUTE_NUMBER_9
        , REQUIRES_MANUAL_SCHEDULING
        , GLOBAL_ATTRIBUTE_NUMBER_1
        , INVOICE_CURRENCY_CODE
        , SOLD_TO_PARTY_ID
        , WAYBILL_NUMBER
        , GLOBAL_ATTRIBUTE_3
        , CT_REFERENCE
        , GLOBAL_ATTRIBUTE_4
        , LATE_CHARGES_ASSESSED
        , LAST_UPDATE_LOGIN
        , ATTRIBUTE_7
        , AGREEMENT_ID
        , LAST_UPDATED_BY
        , GLOBAL_ATTRIBUTE_2
        , READY_FOR_XML_DELIVERY_FLAG
        , PRINTING_COUNT
        , PAYMENT_TRXN_EXTENSION_ID
        , PURCHASE_ORDER_REVISION
        , MRC_EXCHANGE_DATE
        , PRINTING_PENDING
        , FIRST_PTY_REG_ID
        , GLOBAL_ATTRIBUTE_27
        , ATTRIBUTE_8
        , CONTRACT_ID
        , TRX_NUMBER
        , SHIP_TO_CONTACT_ID
        , GLOBAL_ATTRIBUTE_7
        , DOCUMENT_STATUS_CODE
        , INTERCOMPANY_FLAG
        , SOLD_TO_SITE_USE_ID
        , GLOBAL_ATTRIBUTE_8
        , GLOBAL_ATTRIBUTE_NUMBER_2
        , LEGAL_ENTITY_ID
        , BILL_TO_ADDRESS_ID
        , GLOBAL_ATTRIBUTE_13
        , ATTRIBUTE_5
        , DOC_SEQUENCE_VALUE
        , GLOBAL_ATTRIBUTE_21
        , GLOBAL_ATTRIBUTE_6
        , DOCUMENT_SUB_TYPE
        , ATTRIBUTE_3
        , END_DATE_COMMITMENT
        , REMIT_TO_ADDRESS_ID
        , PURCHASE_ORDER_DATE
        , CC_ERROR_TEXT
        , USER_DEFINED_FISC_CLASS
        , SHIP_TO_CUSTOMER_ID
        , INTERFACE_HEADER_NUMBER_2
        , CUST_TRX_TYPE_SEQ_ID
        , DRAWEE_SITE_USE_ID
        , ATTRIBUTE_NUMBER_5
        , GLOBAL_ATTRIBUTE_14
        , BILLING_EXT_REQUEST_ID
        , GLOBAL_ATTRIBUTE_22
        , UPGRADE_METHOD
        , TRX_BUSINESS_CATEGORY
        , BILL_PLAN_PERIOD
        , INTERFACE_HEADER_ATTRIBUTE_8
        , INTERFACE_HEADER_DATE_3
        , SOLD_TO_CUSTOMER_ID
        , INTERFACE_HEADER_ATTRIBUTE_6
        , FISCAL_DOC_ACCESS_KEY
        , PAYING_CUSTOMER_ID
        , INTEREST_HEADER_ID
        , ATTRIBUTE_DATE_2
        , CREATION_DATE
        , BATCH_SOURCE_SEQ_ID
        , SHIP_TO_PARTY_ADDRESS_ID
        , INTERFACE_HEADER_NUMBER_3
        , ATTRIBUTE_CATEGORY
        , ATTRIBUTE_4
        , ATTRIBUTE_NUMBER_3
        , CONTROL_COMPLETION_REASON_CODE
        , ATTRIBUTE_9
        , ORIG_SYSTEM_BATCH_NAME
        , GLOBAL_ATTRIBUTE_17
        , SOURCE_DOCUMENT_ID
        , INTERFACE_HEADER_NUMBER_5
        , THIRD_PTY_REG_ID
        , TRX_DATE
        , GLOBAL_ATTRIBUTE_29
        , BILLING_DATE
        , GLOBAL_ATTRIBUTE_10
        , ORG_ID
        , EXCHANGE_RATE_TYPE
        , DEFAULT_TAX_EXEMPT_FLAG
        , SHIPMENT_ID
        , INTERFACE_HEADER_DATE_2
        , BILL_TO_SITE_USE_ID
        , REMIT_TO_ADDRESS_SEQ_ID
        , DOC_SEQUENCE_ID
        , TERM_DUE_DATE
        , POSTING_CONTROL_ID
        , RELATED_CUSTOMER_TRX_ID
        , SHIP_DATE_ACTUAL
        , ATTRIBUTE_14
        , GLOBAL_ATTRIBUTE_NUMBER_12
        , MRC_EXCHANGE_RATE
        , INTERFACE_HEADER_DATE_5
        , INTERFACE_HEADER_ATTRIBUTE_14
        , ATTRIBUTE_13
        , OBJECT_VERSION_NUMBER
        , GLOBAL_ATTRIBUTE_NUMBER_4
        , ATTRIBUTE_NUMBER_2
        , BILL_PLAN_ID
        , BATCH_ID
        , RECEIPT_METHOD_ID
        , INTERFACE_HEADER_ATTRIBUTE_15
        , REMIT_BANK_ACCT_USE_ID
        , PRINTING_OPTION
        , FOB_POINT
        , APPLICATION_ID
        , DEFAULT_TAXATION_COUNTRY
        , GLOBAL_ATTRIBUTE_11
        , EDI_PROCESSED_STATUS
        , PRIMARY_RESOURCE_SALESREP_ID
        , INTERFACE_HEADER_NUMBER_1
        , GLOBAL_ATTRIBUTE_12
        , INTERFACE_HEADER_DATE_1
        , PROGRAM_ID
        , DEFAULT_USSGL_TRANSACTION_CODE
        , CREDIT_METHOD_FOR_INSTALLMENTS
        , RECURRED_FROM_TRX_NUMBER
        , SHIP_TO_SITE_USE_ID
        , WH_UPDATE_DATE
        , SHIP_TO_PARTY_CONTACT_ID
        , GLOBAL_ATTRIBUTE_5
        , OVERRIDE_REMIT_ACCOUNT_FLAG
        , RA_POST_LOOP_NUMBER
        , REMITTANCE_BANK_ACCOUNT_ID
        , BR_ON_HOLD_FLAG
        , PREVIOUS_CUSTOMER_TRX_ID
        , ATTRIBUTE_6
        , BILL_TEMPLATE_NAME
        , PROGRAM_UPDATE_DATE
        , TRX_CLASS
        , REQUEST_ID
        , GLOBAL_ATTRIBUTE_NUMBER_6
        , MRC_EXCHANGE_RATE_TYPE
        , BILL_TEMPLATE_ID
        , GLOBAL_ATTRIBUTE_19
        , GLOBAL_ATTRIBUTE_DATE_1
        , GLOBAL_ATTRIBUTE_NUMBER_8
        , INTERFACE_HEADER_CONTEXT
        , INTERFACE_HEADER_ATTRIBUTE_4
        , GLOBAL_ATTRIBUTE_9
        , SET_OF_BOOKS_ID
        , BR_AMOUNT
        , INITIAL_CUSTOMER_TRX_ID
        , SOURCE_DOCUMENT_TYPE
        , INTERNAL_NOTES
        , ATTRIBUTE_11
        , LAST_UPDATE_DATE
        , INTERFACE_HEADER_ATTRIBUTE_11
        , GLOBAL_ATTRIBUTE_NUMBER_3
        , BR_UNPAID_FLAG
        , GLOBAL_ATTRIBUTE_26
        , PURCHASE_ORDER
        , ATTRIBUTE_DATE_4
        , INVOICING_RULE_ID
        , BILL_TO_CUSTOMER_ID
        , BILL_TO_CONTACT_ID
        , ATTRIBUTE_DATE_5
        , GLOBAL_ATTRIBUTE_NUMBER_5
        , ATTRIBUTE_DATE_3
        , ATTRIBUTE_10
        , GLOBAL_ATTRIBUTE_24
        , INTERFACE_HEADER_ATTRIBUTE_2
        , INTERFACE_HEADER_ATTRIBUTE_12
        , RELATED_BATCH_SOURCE_SEQ_ID
        , INTERFACE_HEADER_ATTRIBUTE_3
        , STATUS_TRX
        , AX_ACCOUNTED_FLAG
        , INTERFACE_HEADER_ATTRIBUTE_5
        , SHIP_TO_ADDRESS_ID
        , START_DATE_COMMITMENT
        , OLD_TRX_NUMBER
        , DEL_CONTACT_EMAIL_ADDRESS
        , ATTRIBUTE_12
        , INTERFACE_HEADER_ATTRIBUTE_9
        , LAST_PRINTED_SEQUENCE_NUM
        , DOCUMENT_TYPE_ID
        , INTERFACE_HEADER_ATTRIBUTE_13
        , CC_ERROR_CODE
        , GLOBAL_ATTRIBUTE_18
        , SRC_INVOICING_RULE_ID
        , GLOBAL_ATTRIBUTE_23
        , GLOBAL_ATTRIBUTE_NUMBER_7
        , GLOBAL_ATTRIBUTE_28
        , REV_REC_APPLICATION
        , ATTRIBUTE_15
        , SHIP_VIA
        , GLOBAL_ATTRIBUTE_15
        , CUSTOMER_BANK_ACCOUNT_ID
        , EDI_PROCESSED_FLAG
        , SPECIAL_INSTRUCTIONS
        , TERM_ID
        , PAYMENT_ATTRIBUTES
        , ATTRIBUTE_NUMBER_4
        , ADDRESS_VERIFICATION_CODE
        , CREATED_BY
        , GLOBAL_ATTRIBUTE_DATE_5
        , GLOBAL_ATTRIBUTE_NUMBER_10
        , GLOBAL_ATTRIBUTE_DATE_3
        , PAYING_SITE_USE_ID
        , GLOBAL_ATTRIBUTE_20
        , APPROVAL_CODE
        , DRAWEE_CONTACT_ID
        , EXCHANGE_RATE
        , CUSTOMER_REFERENCE
        , CREDIT_METHOD_FOR_RULES
        , PRINTING_ORIGINAL_DATE
        , COMMENTS
        , INTERFACE_HEADER_ATTRIBUTE_7
        , CREATED_FROM
        , PROGRAM_APPLICATION_ID
        , ATTRIBUTE_NUMBER_1
        , GLOBAL_ATTRIBUTE_16
        , GLOBAL_ATTRIBUTE_DATE_2
        , SOURCE_SYSTEM
        , TERRITORY_ID
        , SHIP_TO_PARTY_SITE_USE_ID
        , INTERFACE_HEADER_ATTRIBUTE_1
        , INTERFACE_HEADER_ATTRIBUTE_10
        , STRUCTURED_PAYMENT_REFERENCE
        , GLOBAL_ATTRIBUTE_1
        , SOLD_TO_CONTACT_ID
        , GLOBAL_ATTRIBUTE_NUMBER_11
        , GLOBAL_ATTRIBUTE_25
        , PREPAYMENT_FLAG
        , EXCHANGE_DATE
        , DELIVERY_METHOD_CODE
        , DRAWEE_ID
        , ATTRIBUTE_2
        , COMPLETE_FLAG
        , DOCUMENT_CREATION_DATE
        , DEFAULT_USSGL_TRX_CODE_CONTEXT
        , GLOBAL_ATTRIBUTE_CATEGORY
        , DRAWEE_BANK_ACCOUNT_ID
        , INTERFACE_HEADER_DATE_4
        , GLOBAL_ATTRIBUTE_30
        , GLOBAL_ATTRIBUTE_DATE_4
        , ATTRIBUTE_DATE_1
        , PAYMENT_SERVER_ORDER_NUM
        , REMITTANCE_BATCH_ID
        , ATTRIBUTE_1
        , SHIP_TO_PARTY_ID
        , PRINT_REQUEST_ID
        , REASON_CODE
        , CC_ERROR_FLAG
        , CUSTOMER_REFERENCE_DATE
        , PRINTING_LAST_PRINTED
        , FISCAL_DOC_STATUS
        , INTERFACE_HEADER_NUMBER_4
        , _FIVETRAN_DELETED
        , _FIVETRAN_SYNCED
        , PSA_DELETE_IND
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , coalesce(nullif(trim(S4_ACCOUNT_NUMBER), ''), '-1')          as CUSTOMER_SHIPTO_BK
        , coalesce(nullif(trim(S3_ACCOUNT_NUMBER), ''), '-1')          as CUSTOMER_SOLDTO_BK
        , coalesce(nullif(trim(S2_ACCOUNT_NUMBER), ''), '-1')          as CUSTOMER_BILLTO_BK
        , conditional_change_event(hash(* exclude(psa_load_dts, load_dts,  _fivetran_synced))) over(partition by INVOICE_BK order by _fivetran_synced) as CCE
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(INVOICE_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as INVOICE_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(CUSTOMER_SOLDTO_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as CUSTOMER_SOLDTO_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(CUSTOMER_SHIPTO_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as CUSTOMER_SHIPTO_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(CUSTOMER_BILLTO_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as CUSTOMER_BILLTO_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(INVOICE_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(CUSTOMER_SOLDTO_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(CUSTOMER_SHIPTO_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(CUSTOMER_BILLTO_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as INVOICE_CUSTOMER_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(CUSTOMER_TRX_ID::text), '^^') 
            , '||', IFNULL(TRIM(POST_REQUEST_ID::text), '^^') 
            , '||', IFNULL(TRIM(REVERSED_CASH_RECEIPT_ID::text), '^^') 
            , '||', IFNULL(TRIM(FINANCE_CHARGES::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_NUMBER_9::text), '^^') 
            , '||', IFNULL(TRIM(REQUIRES_MANUAL_SCHEDULING::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_NUMBER_1::text), '^^') 
            , '||', IFNULL(TRIM(INVOICE_CURRENCY_CODE::text), '^^') 
            , '||', IFNULL(TRIM(SOLD_TO_PARTY_ID::text), '^^') 
            , '||', IFNULL(TRIM(WAYBILL_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_3::text), '^^') 
            , '||', IFNULL(TRIM(CT_REFERENCE::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_4::text), '^^') 
            , '||', IFNULL(TRIM(LATE_CHARGES_ASSESSED::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_LOGIN::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_7::text), '^^') 
            , '||', IFNULL(TRIM(AGREEMENT_ID::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_2::text), '^^') 
            , '||', IFNULL(TRIM(READY_FOR_XML_DELIVERY_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(PRINTING_COUNT::text), '^^') 
            , '||', IFNULL(TRIM(PAYMENT_TRXN_EXTENSION_ID::text), '^^') 
            , '||', IFNULL(TRIM(PURCHASE_ORDER_REVISION::text), '^^') 
            , '||', IFNULL(TRIM(MRC_EXCHANGE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(PRINTING_PENDING::text), '^^') 
            , '||', IFNULL(TRIM(FIRST_PTY_REG_ID::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_27::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_8::text), '^^') 
            , '||', IFNULL(TRIM(CONTRACT_ID::text), '^^') 
            , '||', IFNULL(TRIM(TRX_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_TO_CONTACT_ID::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_7::text), '^^') 
            , '||', IFNULL(TRIM(DOCUMENT_STATUS_CODE::text), '^^') 
            , '||', IFNULL(TRIM(INTERCOMPANY_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(SOLD_TO_SITE_USE_ID::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_8::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_NUMBER_2::text), '^^') 
            , '||', IFNULL(TRIM(LEGAL_ENTITY_ID::text), '^^') 
            , '||', IFNULL(TRIM(BILL_TO_ADDRESS_ID::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_13::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_5::text), '^^') 
            , '||', IFNULL(TRIM(DOC_SEQUENCE_VALUE::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_21::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_6::text), '^^') 
            , '||', IFNULL(TRIM(DOCUMENT_SUB_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_3::text), '^^') 
            , '||', IFNULL(TRIM(END_DATE_COMMITMENT::text), '^^') 
            , '||', IFNULL(TRIM(REMIT_TO_ADDRESS_ID::text), '^^') 
            , '||', IFNULL(TRIM(PURCHASE_ORDER_DATE::text), '^^') 
            , '||', IFNULL(TRIM(CC_ERROR_TEXT::text), '^^') 
            , '||', IFNULL(TRIM(USER_DEFINED_FISC_CLASS::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_TO_CUSTOMER_ID::text), '^^') 
            , '||', IFNULL(TRIM(INTERFACE_HEADER_NUMBER_2::text), '^^') 
            , '||', IFNULL(TRIM(CUST_TRX_TYPE_SEQ_ID::text), '^^') 
            , '||', IFNULL(TRIM(DRAWEE_SITE_USE_ID::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_5::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_14::text), '^^') 
            , '||', IFNULL(TRIM(BILLING_EXT_REQUEST_ID::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_22::text), '^^') 
            , '||', IFNULL(TRIM(UPGRADE_METHOD::text), '^^') 
            , '||', IFNULL(TRIM(TRX_BUSINESS_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(BILL_PLAN_PERIOD::text), '^^') 
            , '||', IFNULL(TRIM(INTERFACE_HEADER_ATTRIBUTE_8::text), '^^') 
            , '||', IFNULL(TRIM(INTERFACE_HEADER_DATE_3::text), '^^') 
            , '||', IFNULL(TRIM(SOLD_TO_CUSTOMER_ID::text), '^^') 
            , '||', IFNULL(TRIM(INTERFACE_HEADER_ATTRIBUTE_6::text), '^^') 
            , '||', IFNULL(TRIM(FISCAL_DOC_ACCESS_KEY::text), '^^') 
            , '||', IFNULL(TRIM(PAYING_CUSTOMER_ID::text), '^^') 
            , '||', IFNULL(TRIM(INTEREST_HEADER_ID::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_DATE_2::text), '^^') 
            , '||', IFNULL(TRIM(CREATION_DATE::text), '^^') 
            , '||', IFNULL(TRIM(BATCH_SOURCE_SEQ_ID::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_TO_PARTY_ADDRESS_ID::text), '^^') 
            , '||', IFNULL(TRIM(INTERFACE_HEADER_NUMBER_3::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_4::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_3::text), '^^') 
            , '||', IFNULL(TRIM(CONTROL_COMPLETION_REASON_CODE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_9::text), '^^') 
            , '||', IFNULL(TRIM(ORIG_SYSTEM_BATCH_NAME::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_17::text), '^^') 
            , '||', IFNULL(TRIM(SOURCE_DOCUMENT_ID::text), '^^') 
            , '||', IFNULL(TRIM(INTERFACE_HEADER_NUMBER_5::text), '^^') 
            , '||', IFNULL(TRIM(THIRD_PTY_REG_ID::text), '^^') 
            , '||', IFNULL(TRIM(TRX_DATE::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_29::text), '^^') 
            , '||', IFNULL(TRIM(BILLING_DATE::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_10::text), '^^') 
            , '||', IFNULL(TRIM(ORG_ID::text), '^^') 
            , '||', IFNULL(TRIM(EXCHANGE_RATE_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(DEFAULT_TAX_EXEMPT_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(SHIPMENT_ID::text), '^^') 
            , '||', IFNULL(TRIM(INTERFACE_HEADER_DATE_2::text), '^^') 
            , '||', IFNULL(TRIM(BILL_TO_SITE_USE_ID::text), '^^') 
            , '||', IFNULL(TRIM(REMIT_TO_ADDRESS_SEQ_ID::text), '^^') 
            , '||', IFNULL(TRIM(DOC_SEQUENCE_ID::text), '^^') 
            , '||', IFNULL(TRIM(TERM_DUE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(POSTING_CONTROL_ID::text), '^^') 
            , '||', IFNULL(TRIM(RELATED_CUSTOMER_TRX_ID::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_DATE_ACTUAL::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_14::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_NUMBER_12::text), '^^') 
            , '||', IFNULL(TRIM(MRC_EXCHANGE_RATE::text), '^^') 
            , '||', IFNULL(TRIM(INTERFACE_HEADER_DATE_5::text), '^^') 
            , '||', IFNULL(TRIM(INTERFACE_HEADER_ATTRIBUTE_14::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_13::text), '^^') 
            , '||', IFNULL(TRIM(OBJECT_VERSION_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_NUMBER_4::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_2::text), '^^') 
            , '||', IFNULL(TRIM(BILL_PLAN_ID::text), '^^') 
            , '||', IFNULL(TRIM(BATCH_ID::text), '^^') 
            , '||', IFNULL(TRIM(RECEIPT_METHOD_ID::text), '^^') 
            , '||', IFNULL(TRIM(INTERFACE_HEADER_ATTRIBUTE_15::text), '^^') 
            , '||', IFNULL(TRIM(REMIT_BANK_ACCT_USE_ID::text), '^^') 
            , '||', IFNULL(TRIM(PRINTING_OPTION::text), '^^') 
            , '||', IFNULL(TRIM(FOB_POINT::text), '^^') 
            , '||', IFNULL(TRIM(APPLICATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(DEFAULT_TAXATION_COUNTRY::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_11::text), '^^') 
            , '||', IFNULL(TRIM(EDI_PROCESSED_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(PRIMARY_RESOURCE_SALESREP_ID::text), '^^') 
            , '||', IFNULL(TRIM(INTERFACE_HEADER_NUMBER_1::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_12::text), '^^') 
            , '||', IFNULL(TRIM(INTERFACE_HEADER_DATE_1::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_ID::text), '^^') 
            , '||', IFNULL(TRIM(DEFAULT_USSGL_TRANSACTION_CODE::text), '^^') 
            , '||', IFNULL(TRIM(CREDIT_METHOD_FOR_INSTALLMENTS::text), '^^') 
            , '||', IFNULL(TRIM(RECURRED_FROM_TRX_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_TO_SITE_USE_ID::text), '^^') 
            , '||', IFNULL(TRIM(WH_UPDATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_TO_PARTY_CONTACT_ID::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_5::text), '^^') 
            , '||', IFNULL(TRIM(OVERRIDE_REMIT_ACCOUNT_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(RA_POST_LOOP_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(REMITTANCE_BANK_ACCOUNT_ID::text), '^^') 
            , '||', IFNULL(TRIM(BR_ON_HOLD_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(PREVIOUS_CUSTOMER_TRX_ID::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_6::text), '^^') 
            , '||', IFNULL(TRIM(BILL_TEMPLATE_NAME::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_UPDATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(TRX_CLASS::text), '^^') 
            , '||', IFNULL(TRIM(REQUEST_ID::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_NUMBER_6::text), '^^') 
            , '||', IFNULL(TRIM(MRC_EXCHANGE_RATE_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(BILL_TEMPLATE_ID::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_19::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_DATE_1::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_NUMBER_8::text), '^^') 
            , '||', IFNULL(TRIM(INTERFACE_HEADER_CONTEXT::text), '^^') 
            , '||', IFNULL(TRIM(INTERFACE_HEADER_ATTRIBUTE_4::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_9::text), '^^') 
            , '||', IFNULL(TRIM(SET_OF_BOOKS_ID::text), '^^') 
            , '||', IFNULL(TRIM(BR_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(INITIAL_CUSTOMER_TRX_ID::text), '^^') 
            , '||', IFNULL(TRIM(SOURCE_DOCUMENT_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(INTERNAL_NOTES::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_11::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(INTERFACE_HEADER_ATTRIBUTE_11::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_NUMBER_3::text), '^^') 
            , '||', IFNULL(TRIM(BR_UNPAID_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_26::text), '^^') 
            , '||', IFNULL(TRIM(PURCHASE_ORDER::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_DATE_4::text), '^^') 
            , '||', IFNULL(TRIM(INVOICING_RULE_ID::text), '^^') 
            , '||', IFNULL(TRIM(BILL_TO_CUSTOMER_ID::text), '^^') 
            , '||', IFNULL(TRIM(BILL_TO_CONTACT_ID::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_DATE_5::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_NUMBER_5::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_DATE_3::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_10::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_24::text), '^^') 
            , '||', IFNULL(TRIM(INTERFACE_HEADER_ATTRIBUTE_2::text), '^^') 
            , '||', IFNULL(TRIM(INTERFACE_HEADER_ATTRIBUTE_12::text), '^^') 
            , '||', IFNULL(TRIM(RELATED_BATCH_SOURCE_SEQ_ID::text), '^^') 
            , '||', IFNULL(TRIM(INTERFACE_HEADER_ATTRIBUTE_3::text), '^^') 
            , '||', IFNULL(TRIM(STATUS_TRX::text), '^^') 
            , '||', IFNULL(TRIM(AX_ACCOUNTED_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(INTERFACE_HEADER_ATTRIBUTE_5::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_TO_ADDRESS_ID::text), '^^') 
            , '||', IFNULL(TRIM(START_DATE_COMMITMENT::text), '^^') 
            , '||', IFNULL(TRIM(OLD_TRX_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(DEL_CONTACT_EMAIL_ADDRESS::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_12::text), '^^') 
            , '||', IFNULL(TRIM(INTERFACE_HEADER_ATTRIBUTE_9::text), '^^') 
            , '||', IFNULL(TRIM(LAST_PRINTED_SEQUENCE_NUM::text), '^^') 
            , '||', IFNULL(TRIM(DOCUMENT_TYPE_ID::text), '^^') 
            , '||', IFNULL(TRIM(INTERFACE_HEADER_ATTRIBUTE_13::text), '^^') 
            , '||', IFNULL(TRIM(CC_ERROR_CODE::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_18::text), '^^') 
            , '||', IFNULL(TRIM(SRC_INVOICING_RULE_ID::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_23::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_NUMBER_7::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_28::text), '^^') 
            , '||', IFNULL(TRIM(REV_REC_APPLICATION::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_15::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_VIA::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_15::text), '^^') 
            , '||', IFNULL(TRIM(CUSTOMER_BANK_ACCOUNT_ID::text), '^^') 
            , '||', IFNULL(TRIM(EDI_PROCESSED_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(SPECIAL_INSTRUCTIONS::text), '^^') 
            , '||', IFNULL(TRIM(TERM_ID::text), '^^') 
            , '||', IFNULL(TRIM(PAYMENT_ATTRIBUTES::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_4::text), '^^') 
            , '||', IFNULL(TRIM(ADDRESS_VERIFICATION_CODE::text), '^^') 
            , '||', IFNULL(TRIM(CREATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_DATE_5::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_NUMBER_10::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_DATE_3::text), '^^') 
            , '||', IFNULL(TRIM(PAYING_SITE_USE_ID::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_20::text), '^^') 
            , '||', IFNULL(TRIM(APPROVAL_CODE::text), '^^') 
            , '||', IFNULL(TRIM(DRAWEE_CONTACT_ID::text), '^^') 
            , '||', IFNULL(TRIM(EXCHANGE_RATE::text), '^^') 
            , '||', IFNULL(TRIM(CUSTOMER_REFERENCE::text), '^^') 
            , '||', IFNULL(TRIM(CREDIT_METHOD_FOR_RULES::text), '^^') 
            , '||', IFNULL(TRIM(PRINTING_ORIGINAL_DATE::text), '^^') 
            , '||', IFNULL(TRIM(COMMENTS::text), '^^') 
            , '||', IFNULL(TRIM(INTERFACE_HEADER_ATTRIBUTE_7::text), '^^') 
            , '||', IFNULL(TRIM(CREATED_FROM::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_APPLICATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_1::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_16::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_DATE_2::text), '^^') 
            , '||', IFNULL(TRIM(SOURCE_SYSTEM::text), '^^') 
            , '||', IFNULL(TRIM(TERRITORY_ID::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_TO_PARTY_SITE_USE_ID::text), '^^') 
            , '||', IFNULL(TRIM(INTERFACE_HEADER_ATTRIBUTE_1::text), '^^') 
            , '||', IFNULL(TRIM(INTERFACE_HEADER_ATTRIBUTE_10::text), '^^') 
            , '||', IFNULL(TRIM(STRUCTURED_PAYMENT_REFERENCE::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_1::text), '^^') 
            , '||', IFNULL(TRIM(SOLD_TO_CONTACT_ID::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_NUMBER_11::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_25::text), '^^') 
            , '||', IFNULL(TRIM(PREPAYMENT_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(EXCHANGE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(DELIVERY_METHOD_CODE::text), '^^') 
            , '||', IFNULL(TRIM(DRAWEE_ID::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_2::text), '^^') 
            , '||', IFNULL(TRIM(COMPLETE_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(DOCUMENT_CREATION_DATE::text), '^^') 
            , '||', IFNULL(TRIM(DEFAULT_USSGL_TRX_CODE_CONTEXT::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(DRAWEE_BANK_ACCOUNT_ID::text), '^^') 
            , '||', IFNULL(TRIM(INTERFACE_HEADER_DATE_4::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_30::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_DATE_4::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_DATE_1::text), '^^') 
            , '||', IFNULL(TRIM(PAYMENT_SERVER_ORDER_NUM::text), '^^') 
            , '||', IFNULL(TRIM(REMITTANCE_BATCH_ID::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_1::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_TO_PARTY_ID::text), '^^') 
            , '||', IFNULL(TRIM(PRINT_REQUEST_ID::text), '^^') 
            , '||', IFNULL(TRIM(REASON_CODE::text), '^^') 
            , '||', IFNULL(TRIM(CC_ERROR_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(CUSTOMER_REFERENCE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(PRINTING_LAST_PRINTED::text), '^^') 
            , '||', IFNULL(TRIM(FISCAL_DOC_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(INTERFACE_HEADER_NUMBER_4::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
            , '||', IFNULL(TRIM(CCE::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
