---- SRC LAYER ----
WITH
SRC_S              as ( SELECT * FROM {{ source('ml_ebs_ap', 'ap_suppliers') }} as SRC  ),
SRC_A              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S              as ( SELECT * FROM ml_ebs_ap.ap_suppliers )
, SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        SEGMENT1::TEXT                                               as                                        SUPPLIER_BK
      , SEGMENT1
      , VENDOR_ID
      , CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED )                   as                                           LOAD_DTS
      , CHECK_DIGITS
      , ALWAYS_TAKE_DISC_FLAG
      , UNIQUE_TAX_REFERENCE_NUM
      , FREIGHT_TERMS_LOOKUP_CODE
      , AUTO_TAX_CALC_OVERRIDE
      , HOLD_BY
      , BANK_NUM
      , EDI_REMITTANCE_INSTRUCTION
      , EXPENSE_CODE_COMBINATION_ID
      , OFFSET_TAX_FLAG
      , PROGRAM_ID
      , PAY_DATE_BASIS_LOOKUP_CODE
      , GLOBAL_ATTRIBUTE5
      , GLOBAL_ATTRIBUTE4
      , GLOBAL_ATTRIBUTE7
      , GLOBAL_ATTRIBUTE6
      , EDI_TRANSACTION_HANDLING
      , SEGMENT4
      , GLOBAL_ATTRIBUTE1
      , SEGMENT3
      , GLOBAL_ATTRIBUTE3
      , MINORITY_GROUP_LOOKUP_CODE
      , SEGMENT5
      , GLOBAL_ATTRIBUTE2
      , BANK_BRANCH_TYPE
      , AWT_GROUP_ID
      , GLOBAL_ATTRIBUTE9
      , MATCH_STATUS_FLAG
      , GLOBAL_ATTRIBUTE8
      , TCA_SYNC_VAT_REG_NUM
      , ATTRIBUTE3
      , DAYS_LATE_RECEIPT_ALLOWED
      , ATTRIBUTE2
      , ATTRIBUTE1
      , INVOICE_AMOUNT_LIMIT
      , AP_TAX_ROUNDING_RULE
      , NI_NUMBER
      , EDI_REMITTANCE_METHOD
      , AMOUNT_INCLUDES_TAX_FLAG
      , ATTRIBUTE9
      , ATTRIBUTE8
      , COMPANY_REGISTRATION_NUMBER
      , ATTRIBUTE7
      , QTY_RCV_EXCEPTION_CODE
      , ATTRIBUTE6
      , ATTRIBUTE5
      , ATTRIBUTE4
      , CREDIT_LIMIT
      , TCA_SYNC_NUM_1099
      , OFFSET_VAT_CODE
      , SMALL_BUSINESS_FLAG
      , ACCTS_PAY_CODE_COMBINATION_ID
      , DISC_LOST_CODE_COMBINATION_ID
      , ATTRIBUTE10
      , EXCLUSIVE_PAYMENT_FLAG
      , NAME_CONTROL
      , ATTRIBUTE14
      , ATTRIBUTE13
      , EDI_PAYMENT_FORMAT
      , ATTRIBUTE12
      , ATTRIBUTE11
      , WITHHOLDING_STATUS_LOOKUP_CODE
      , TRADING_NAME
      , BILL_TO_LOCATION_ID
      , EXCHANGE_DATE_LOOKUP_CODE
      , EDI_PAYMENT_METHOD
      , PREPAY_CODE_COMBINATION_ID
      , LAST_NAME
      , PRICE_TOLERANCE
      , BUS_CLASS_LAST_CERTIFIED_DATE
      , HOLD_DATE
      , PARENT_PARTY_ID
      , CUSTOMER_NUM
      , STATE_REPORTABLE_FLAG
      , BANK_NUMBER
      , GLOBAL_ATTRIBUTE20
      , VENDOR_NAME_ALT
      , PARENT_VENDOR_ID
      , VENDOR_TYPE_LOOKUP_CODE
      , GLOBAL_ATTRIBUTE17
      , GLOBAL_ATTRIBUTE18
      , CIS_ENABLED_FLAG
      , GLOBAL_ATTRIBUTE15
      , GLOBAL_ATTRIBUTE16
      , GLOBAL_ATTRIBUTE13
      , GLOBAL_ATTRIBUTE14
      , GLOBAL_ATTRIBUTE11
      , BANK_ACCOUNT_TYPE
      , GLOBAL_ATTRIBUTE12
      , ORGANIZATION_TYPE_LOOKUP_CODE
      , RECEIVING_ROUTING_ID
      , ATTRIBUTE15
      , NUM_1099
      , ALLOW_AWT_FLAG
      , INVOICE_CURRENCY_CODE
      , GLOBAL_ATTRIBUTE19
      , CREATE_DEBIT_MEMO_FLAG
      , VENDOR_NAME
      , DISTRIBUTION_SET_ID
      , EMPLOYEE_ID
      , GLOBAL_ATTRIBUTE10
      , BANK_ACCOUNT_NUM
      , AUTO_CALCULATE_INTEREST_FLAG
      , SECOND_NAME
      , BANK_ACCOUNT_NAME
      , TAX_VERIFICATION_DATE
      , SALUTATION
      , NATIONAL_INSURANCE_NUMBER
      , HOLD_FLAG
      , INSPECTION_REQUIRED_FLAG
      , WORK_REFERENCE
      , SHIP_TO_LOCATION_ID
      , ONE_TIME_FLAG
      , FUTURE_DATED_PAYMENT_CCID
      , WOMEN_OWNED_FLAG
      , CREATED_BY
      , LAST_UPDATED_BY
      , HOLD_REASON
      , WITHHOLDING_START_DATE
      , VAT_CODE
      , VERIFICATION_NUMBER
      , PARTNERSHIP_NAME
      , RECEIPT_REQUIRED_FLAG
      , FEDERAL_REPORTABLE_FLAG
      , INDIVIDUAL_1099
      , TCA_SYNC_VENDOR_NAME
      , ENFORCE_SHIP_TO_LOCATION_CODE
      , TAX_REPORTING_NAME
      , TERMS_ID
      , ATTRIBUTE_CATEGORY
      , PROGRAM_APPLICATION_ID
      , VALIDATION_NUMBER
      , AUTO_TAX_CALC_FLAG
      , EXCLUDE_FREIGHT_FROM_DISCOUNT
      , BUS_CLASS_LAST_CERTIFIED_BY
      , TERMS_DATE_BASIS
      , PARTY_ID
      , PAY_AWT_GROUP_ID
      , PURCHASING_HOLD_REASON
      , ALLOW_SUBSTITUTE_RECEIPTS_FLAG
      , CREDIT_STATUS_LOOKUP_CODE
      , VAT_REGISTRATION_NUM
      , SET_OF_BOOKS_ID
      , PARTNERSHIP_UTR
      , REQUEST_ID
      , BANK_CHARGE_BEARER
      , FIRST_NAME
      , HOLD_FUTURE_PAYMENTS_FLAG
      , PAYMENT_PRIORITY
      , RECEIPT_DAYS_EXCEPTION_CODE
      , DISC_TAKEN_CODE_COMBINATION_ID
      , PAYMENT_METHOD_LOOKUP_CODE
      , CIS_PARENT_VENDOR_ID
      , TYPE_1099
      , STANDARD_INDUSTRY_CLASS
      , VERIFICATION_REQUEST_ID
      , PAYMENT_CURRENCY_CODE
      , HOLD_ALL_PAYMENTS_FLAG
      , CIS_VERIFICATION_DATE
      , SUMMARY_FLAG
      , QTY_RCV_TOLERANCE
      , ALLOW_UNORDERED_RECEIPTS_FLAG
      , SEGMENT2
      , LAST_UPDATE_LOGIN
      , MATCH_OPTION
      , ENABLED_FLAG
      , GLOBAL_ATTRIBUTE_CATEGORY
      , SHIP_VIA_LOOKUP_CODE
      , FOB_LOOKUP_CODE
      , DAYS_EARLY_RECEIPT_ALLOWED
      , HOLD_UNMATCHED_INVOICES_FLAG
      , MIN_ORDER_AMOUNT
      , PAY_GROUP_LOOKUP_CODE
      , _FIVETRAN_DELETED
      , _FIVETRAN_ID
      , _FIVETRAN_SYNCED
      , PROGRAM_UPDATE_DATE
      , START_DATE_ACTIVE
      , END_DATE_ACTIVE
      , CREATION_DATE
      , LAST_UPDATE_DATE
      , PSA_LOAD_DTS
      , PSA_DELETE_IND
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
        SUPPLIER_BK
      , SEGMENT1
      , VENDOR_ID
      , LOAD_DTS
      , CHECK_DIGITS
      , ALWAYS_TAKE_DISC_FLAG
      , UNIQUE_TAX_REFERENCE_NUM
      , FREIGHT_TERMS_LOOKUP_CODE
      , AUTO_TAX_CALC_OVERRIDE
      , HOLD_BY
      , BANK_NUM
      , EDI_REMITTANCE_INSTRUCTION
      , EXPENSE_CODE_COMBINATION_ID
      , OFFSET_TAX_FLAG
      , PROGRAM_ID
      , PAY_DATE_BASIS_LOOKUP_CODE
      , GLOBAL_ATTRIBUTE5
      , GLOBAL_ATTRIBUTE4
      , GLOBAL_ATTRIBUTE7
      , GLOBAL_ATTRIBUTE6
      , EDI_TRANSACTION_HANDLING
      , SEGMENT4
      , GLOBAL_ATTRIBUTE1
      , SEGMENT3
      , GLOBAL_ATTRIBUTE3
      , MINORITY_GROUP_LOOKUP_CODE
      , SEGMENT5
      , GLOBAL_ATTRIBUTE2
      , BANK_BRANCH_TYPE
      , AWT_GROUP_ID
      , GLOBAL_ATTRIBUTE9
      , MATCH_STATUS_FLAG
      , GLOBAL_ATTRIBUTE8
      , TCA_SYNC_VAT_REG_NUM
      , ATTRIBUTE3
      , DAYS_LATE_RECEIPT_ALLOWED
      , ATTRIBUTE2
      , ATTRIBUTE1
      , INVOICE_AMOUNT_LIMIT
      , AP_TAX_ROUNDING_RULE
      , NI_NUMBER
      , EDI_REMITTANCE_METHOD
      , AMOUNT_INCLUDES_TAX_FLAG
      , ATTRIBUTE9
      , ATTRIBUTE8
      , COMPANY_REGISTRATION_NUMBER
      , ATTRIBUTE7
      , QTY_RCV_EXCEPTION_CODE
      , ATTRIBUTE6
      , ATTRIBUTE5
      , ATTRIBUTE4
      , CREDIT_LIMIT
      , TCA_SYNC_NUM_1099
      , OFFSET_VAT_CODE
      , SMALL_BUSINESS_FLAG
      , ACCTS_PAY_CODE_COMBINATION_ID
      , DISC_LOST_CODE_COMBINATION_ID
      , ATTRIBUTE10
      , EXCLUSIVE_PAYMENT_FLAG
      , NAME_CONTROL
      , ATTRIBUTE14
      , ATTRIBUTE13
      , EDI_PAYMENT_FORMAT
      , ATTRIBUTE12
      , ATTRIBUTE11
      , WITHHOLDING_STATUS_LOOKUP_CODE
      , TRADING_NAME
      , BILL_TO_LOCATION_ID
      , EXCHANGE_DATE_LOOKUP_CODE
      , EDI_PAYMENT_METHOD
      , PREPAY_CODE_COMBINATION_ID
      , LAST_NAME
      , PRICE_TOLERANCE
      , BUS_CLASS_LAST_CERTIFIED_DATE
      , HOLD_DATE
      , PARENT_PARTY_ID
      , CUSTOMER_NUM
      , STATE_REPORTABLE_FLAG
      , BANK_NUMBER
      , GLOBAL_ATTRIBUTE20
      , VENDOR_NAME_ALT
      , PARENT_VENDOR_ID
      , VENDOR_TYPE_LOOKUP_CODE
      , GLOBAL_ATTRIBUTE17
      , GLOBAL_ATTRIBUTE18
      , CIS_ENABLED_FLAG
      , GLOBAL_ATTRIBUTE15
      , GLOBAL_ATTRIBUTE16
      , GLOBAL_ATTRIBUTE13
      , GLOBAL_ATTRIBUTE14
      , GLOBAL_ATTRIBUTE11
      , BANK_ACCOUNT_TYPE
      , GLOBAL_ATTRIBUTE12
      , ORGANIZATION_TYPE_LOOKUP_CODE
      , RECEIVING_ROUTING_ID
      , ATTRIBUTE15
      , NUM_1099
      , ALLOW_AWT_FLAG
      , INVOICE_CURRENCY_CODE
      , GLOBAL_ATTRIBUTE19
      , CREATE_DEBIT_MEMO_FLAG
      , VENDOR_NAME
      , DISTRIBUTION_SET_ID
      , EMPLOYEE_ID
      , GLOBAL_ATTRIBUTE10
      , BANK_ACCOUNT_NUM
      , AUTO_CALCULATE_INTEREST_FLAG
      , SECOND_NAME
      , BANK_ACCOUNT_NAME
      , TAX_VERIFICATION_DATE
      , SALUTATION
      , NATIONAL_INSURANCE_NUMBER
      , HOLD_FLAG
      , INSPECTION_REQUIRED_FLAG
      , WORK_REFERENCE
      , SHIP_TO_LOCATION_ID
      , ONE_TIME_FLAG
      , FUTURE_DATED_PAYMENT_CCID
      , WOMEN_OWNED_FLAG
      , CREATED_BY
      , LAST_UPDATED_BY
      , HOLD_REASON
      , WITHHOLDING_START_DATE
      , VAT_CODE
      , VERIFICATION_NUMBER
      , PARTNERSHIP_NAME
      , RECEIPT_REQUIRED_FLAG
      , FEDERAL_REPORTABLE_FLAG
      , INDIVIDUAL_1099
      , TCA_SYNC_VENDOR_NAME
      , ENFORCE_SHIP_TO_LOCATION_CODE
      , TAX_REPORTING_NAME
      , TERMS_ID
      , ATTRIBUTE_CATEGORY
      , PROGRAM_APPLICATION_ID
      , VALIDATION_NUMBER
      , AUTO_TAX_CALC_FLAG
      , EXCLUDE_FREIGHT_FROM_DISCOUNT
      , BUS_CLASS_LAST_CERTIFIED_BY
      , TERMS_DATE_BASIS
      , PARTY_ID
      , PAY_AWT_GROUP_ID
      , PURCHASING_HOLD_REASON
      , ALLOW_SUBSTITUTE_RECEIPTS_FLAG
      , CREDIT_STATUS_LOOKUP_CODE
      , VAT_REGISTRATION_NUM
      , SET_OF_BOOKS_ID
      , PARTNERSHIP_UTR
      , REQUEST_ID
      , BANK_CHARGE_BEARER
      , FIRST_NAME
      , HOLD_FUTURE_PAYMENTS_FLAG
      , PAYMENT_PRIORITY
      , RECEIPT_DAYS_EXCEPTION_CODE
      , DISC_TAKEN_CODE_COMBINATION_ID
      , PAYMENT_METHOD_LOOKUP_CODE
      , CIS_PARENT_VENDOR_ID
      , TYPE_1099
      , STANDARD_INDUSTRY_CLASS
      , VERIFICATION_REQUEST_ID
      , PAYMENT_CURRENCY_CODE
      , HOLD_ALL_PAYMENTS_FLAG
      , CIS_VERIFICATION_DATE
      , SUMMARY_FLAG
      , QTY_RCV_TOLERANCE
      , ALLOW_UNORDERED_RECEIPTS_FLAG
      , SEGMENT2
      , LAST_UPDATE_LOGIN
      , MATCH_OPTION
      , ENABLED_FLAG
      , GLOBAL_ATTRIBUTE_CATEGORY
      , SHIP_VIA_LOOKUP_CODE
      , FOB_LOOKUP_CODE
      , DAYS_EARLY_RECEIPT_ALLOWED
      , HOLD_UNMATCHED_INVOICES_FLAG
      , MIN_ORDER_AMOUNT
      , PAY_GROUP_LOOKUP_CODE
      , _FIVETRAN_DELETED
      , _FIVETRAN_ID
      , _FIVETRAN_SYNCED
      , PROGRAM_UPDATE_DATE
      , START_DATE_ACTIVE
      , END_DATE_ACTIVE
      , CREATION_DATE
      , LAST_UPDATE_DATE
      , PSA_LOAD_DTS
      , PSA_DELETE_IND
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
    WHERE rec_src = 'USWIOC.ORCL.EBSPRD.AP_SUPPLIER'
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
          SUPPLIER_BK
        , SEGMENT1
        , VENDOR_ID
        , LOAD_DTS
        , CHECK_DIGITS
        , ALWAYS_TAKE_DISC_FLAG
        , UNIQUE_TAX_REFERENCE_NUM
        , FREIGHT_TERMS_LOOKUP_CODE
        , AUTO_TAX_CALC_OVERRIDE
        , HOLD_BY
        , BANK_NUM
        , EDI_REMITTANCE_INSTRUCTION
        , EXPENSE_CODE_COMBINATION_ID
        , OFFSET_TAX_FLAG
        , PROGRAM_ID
        , PAY_DATE_BASIS_LOOKUP_CODE
        , GLOBAL_ATTRIBUTE5
        , GLOBAL_ATTRIBUTE4
        , GLOBAL_ATTRIBUTE7
        , GLOBAL_ATTRIBUTE6
        , EDI_TRANSACTION_HANDLING
        , SEGMENT4
        , GLOBAL_ATTRIBUTE1
        , SEGMENT3
        , GLOBAL_ATTRIBUTE3
        , MINORITY_GROUP_LOOKUP_CODE
        , SEGMENT5
        , GLOBAL_ATTRIBUTE2
        , BANK_BRANCH_TYPE
        , AWT_GROUP_ID
        , GLOBAL_ATTRIBUTE9
        , MATCH_STATUS_FLAG
        , GLOBAL_ATTRIBUTE8
        , TCA_SYNC_VAT_REG_NUM
        , ATTRIBUTE3
        , DAYS_LATE_RECEIPT_ALLOWED
        , ATTRIBUTE2
        , ATTRIBUTE1
        , INVOICE_AMOUNT_LIMIT
        , AP_TAX_ROUNDING_RULE
        , NI_NUMBER
        , EDI_REMITTANCE_METHOD
        , AMOUNT_INCLUDES_TAX_FLAG
        , ATTRIBUTE9
        , ATTRIBUTE8
        , COMPANY_REGISTRATION_NUMBER
        , ATTRIBUTE7
        , QTY_RCV_EXCEPTION_CODE
        , ATTRIBUTE6
        , ATTRIBUTE5
        , ATTRIBUTE4
        , CREDIT_LIMIT
        , TCA_SYNC_NUM_1099
        , OFFSET_VAT_CODE
        , SMALL_BUSINESS_FLAG
        , ACCTS_PAY_CODE_COMBINATION_ID
        , DISC_LOST_CODE_COMBINATION_ID
        , ATTRIBUTE10
        , EXCLUSIVE_PAYMENT_FLAG
        , NAME_CONTROL
        , ATTRIBUTE14
        , ATTRIBUTE13
        , EDI_PAYMENT_FORMAT
        , ATTRIBUTE12
        , ATTRIBUTE11
        , WITHHOLDING_STATUS_LOOKUP_CODE
        , TRADING_NAME
        , BILL_TO_LOCATION_ID
        , EXCHANGE_DATE_LOOKUP_CODE
        , EDI_PAYMENT_METHOD
        , PREPAY_CODE_COMBINATION_ID
        , LAST_NAME
        , PRICE_TOLERANCE
        , BUS_CLASS_LAST_CERTIFIED_DATE
        , HOLD_DATE
        , PARENT_PARTY_ID
        , CUSTOMER_NUM
        , STATE_REPORTABLE_FLAG
        , BANK_NUMBER
        , GLOBAL_ATTRIBUTE20
        , VENDOR_NAME_ALT
        , PARENT_VENDOR_ID
        , VENDOR_TYPE_LOOKUP_CODE
        , GLOBAL_ATTRIBUTE17
        , GLOBAL_ATTRIBUTE18
        , CIS_ENABLED_FLAG
        , GLOBAL_ATTRIBUTE15
        , GLOBAL_ATTRIBUTE16
        , GLOBAL_ATTRIBUTE13
        , GLOBAL_ATTRIBUTE14
        , GLOBAL_ATTRIBUTE11
        , BANK_ACCOUNT_TYPE
        , GLOBAL_ATTRIBUTE12
        , ORGANIZATION_TYPE_LOOKUP_CODE
        , RECEIVING_ROUTING_ID
        , ATTRIBUTE15
        , NUM_1099
        , ALLOW_AWT_FLAG
        , INVOICE_CURRENCY_CODE
        , GLOBAL_ATTRIBUTE19
        , CREATE_DEBIT_MEMO_FLAG
        , VENDOR_NAME
        , DISTRIBUTION_SET_ID
        , EMPLOYEE_ID
        , GLOBAL_ATTRIBUTE10
        , BANK_ACCOUNT_NUM
        , AUTO_CALCULATE_INTEREST_FLAG
        , SECOND_NAME
        , BANK_ACCOUNT_NAME
        , TAX_VERIFICATION_DATE
        , SALUTATION
        , NATIONAL_INSURANCE_NUMBER
        , HOLD_FLAG
        , INSPECTION_REQUIRED_FLAG
        , WORK_REFERENCE
        , SHIP_TO_LOCATION_ID
        , ONE_TIME_FLAG
        , FUTURE_DATED_PAYMENT_CCID
        , WOMEN_OWNED_FLAG
        , CREATED_BY
        , LAST_UPDATED_BY
        , HOLD_REASON
        , WITHHOLDING_START_DATE
        , VAT_CODE
        , VERIFICATION_NUMBER
        , PARTNERSHIP_NAME
        , RECEIPT_REQUIRED_FLAG
        , FEDERAL_REPORTABLE_FLAG
        , INDIVIDUAL_1099
        , TCA_SYNC_VENDOR_NAME
        , ENFORCE_SHIP_TO_LOCATION_CODE
        , TAX_REPORTING_NAME
        , TERMS_ID
        , ATTRIBUTE_CATEGORY
        , PROGRAM_APPLICATION_ID
        , VALIDATION_NUMBER
        , AUTO_TAX_CALC_FLAG
        , EXCLUDE_FREIGHT_FROM_DISCOUNT
        , BUS_CLASS_LAST_CERTIFIED_BY
        , TERMS_DATE_BASIS
        , PARTY_ID
        , PAY_AWT_GROUP_ID
        , PURCHASING_HOLD_REASON
        , ALLOW_SUBSTITUTE_RECEIPTS_FLAG
        , CREDIT_STATUS_LOOKUP_CODE
        , VAT_REGISTRATION_NUM
        , SET_OF_BOOKS_ID
        , PARTNERSHIP_UTR
        , REQUEST_ID
        , BANK_CHARGE_BEARER
        , FIRST_NAME
        , HOLD_FUTURE_PAYMENTS_FLAG
        , PAYMENT_PRIORITY
        , RECEIPT_DAYS_EXCEPTION_CODE
        , DISC_TAKEN_CODE_COMBINATION_ID
        , PAYMENT_METHOD_LOOKUP_CODE
        , CIS_PARENT_VENDOR_ID
        , TYPE_1099
        , STANDARD_INDUSTRY_CLASS
        , VERIFICATION_REQUEST_ID
        , PAYMENT_CURRENCY_CODE
        , HOLD_ALL_PAYMENTS_FLAG
        , CIS_VERIFICATION_DATE
        , SUMMARY_FLAG
        , QTY_RCV_TOLERANCE
        , ALLOW_UNORDERED_RECEIPTS_FLAG
        , SEGMENT2
        , LAST_UPDATE_LOGIN
        , MATCH_OPTION
        , ENABLED_FLAG
        , GLOBAL_ATTRIBUTE_CATEGORY
        , SHIP_VIA_LOOKUP_CODE
        , FOB_LOOKUP_CODE
        , DAYS_EARLY_RECEIPT_ALLOWED
        , HOLD_UNMATCHED_INVOICES_FLAG
        , MIN_ORDER_AMOUNT
        , PAY_GROUP_LOOKUP_CODE
        , _FIVETRAN_DELETED
        , _FIVETRAN_ID
        , _FIVETRAN_SYNCED
        , PROGRAM_UPDATE_DATE
        , START_DATE_ACTIVE
        , END_DATE_ACTIVE
        , CREATION_DATE
        , LAST_UPDATE_DATE
        , PSA_LOAD_DTS
        , PSA_DELETE_IND
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(SEGMENT1 as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as SUPPLIER_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(CHECK_DIGITS::text), '^^') 
            , '||', IFNULL(TRIM(ALWAYS_TAKE_DISC_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(UNIQUE_TAX_REFERENCE_NUM::text), '^^') 
            , '||', IFNULL(TRIM(FREIGHT_TERMS_LOOKUP_CODE::text), '^^') 
            , '||', IFNULL(TRIM(AUTO_TAX_CALC_OVERRIDE::text), '^^') 
            , '||', IFNULL(TRIM(HOLD_BY::text), '^^') 
            , '||', IFNULL(TRIM(BANK_NUM::text), '^^') 
            , '||', IFNULL(TRIM(EDI_REMITTANCE_INSTRUCTION::text), '^^') 
            , '||', IFNULL(TRIM(EXPENSE_CODE_COMBINATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(OFFSET_TAX_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_ID::text), '^^') 
            , '||', IFNULL(TRIM(PAY_DATE_BASIS_LOOKUP_CODE::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE5::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE4::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE7::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE6::text), '^^') 
            , '||', IFNULL(TRIM(EDI_TRANSACTION_HANDLING::text), '^^') 
            , '||', IFNULL(TRIM(SEGMENT4::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE1::text), '^^') 
            , '||', IFNULL(TRIM(SEGMENT3::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE3::text), '^^') 
            , '||', IFNULL(TRIM(MINORITY_GROUP_LOOKUP_CODE::text), '^^') 
            , '||', IFNULL(TRIM(SEGMENT5::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE2::text), '^^') 
            , '||', IFNULL(TRIM(BANK_BRANCH_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(AWT_GROUP_ID::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE9::text), '^^') 
            , '||', IFNULL(TRIM(MATCH_STATUS_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE8::text), '^^') 
            , '||', IFNULL(TRIM(TCA_SYNC_VAT_REG_NUM::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE3::text), '^^') 
            , '||', IFNULL(TRIM(DAYS_LATE_RECEIPT_ALLOWED::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE2::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE1::text), '^^') 
            , '||', IFNULL(TRIM(INVOICE_AMOUNT_LIMIT::text), '^^') 
            , '||', IFNULL(TRIM(AP_TAX_ROUNDING_RULE::text), '^^') 
            , '||', IFNULL(TRIM(NI_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(EDI_REMITTANCE_METHOD::text), '^^') 
            , '||', IFNULL(TRIM(AMOUNT_INCLUDES_TAX_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE9::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE8::text), '^^') 
            , '||', IFNULL(TRIM(COMPANY_REGISTRATION_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE7::text), '^^') 
            , '||', IFNULL(TRIM(QTY_RCV_EXCEPTION_CODE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE6::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE5::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE4::text), '^^') 
            , '||', IFNULL(TRIM(CREDIT_LIMIT::text), '^^') 
            , '||', IFNULL(TRIM(TCA_SYNC_NUM_1099::text), '^^') 
            , '||', IFNULL(TRIM(OFFSET_VAT_CODE::text), '^^') 
            , '||', IFNULL(TRIM(SMALL_BUSINESS_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(ACCTS_PAY_CODE_COMBINATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(DISC_LOST_CODE_COMBINATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE10::text), '^^') 
            , '||', IFNULL(TRIM(EXCLUSIVE_PAYMENT_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(NAME_CONTROL::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE14::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE13::text), '^^') 
            , '||', IFNULL(TRIM(EDI_PAYMENT_FORMAT::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE12::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE11::text), '^^') 
            , '||', IFNULL(TRIM(WITHHOLDING_STATUS_LOOKUP_CODE::text), '^^') 
            , '||', IFNULL(TRIM(TRADING_NAME::text), '^^') 
            , '||', IFNULL(TRIM(BILL_TO_LOCATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(EXCHANGE_DATE_LOOKUP_CODE::text), '^^') 
            , '||', IFNULL(TRIM(EDI_PAYMENT_METHOD::text), '^^') 
            , '||', IFNULL(TRIM(PREPAY_CODE_COMBINATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(LAST_NAME::text), '^^') 
            , '||', IFNULL(TRIM(PRICE_TOLERANCE::text), '^^') 
            , '||', IFNULL(TRIM(BUS_CLASS_LAST_CERTIFIED_DATE::text), '^^') 
            , '||', IFNULL(TRIM(HOLD_DATE::text), '^^') 
            , '||', IFNULL(TRIM(PARENT_PARTY_ID::text), '^^') 
            , '||', IFNULL(TRIM(CUSTOMER_NUM::text), '^^') 
            , '||', IFNULL(TRIM(STATE_REPORTABLE_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(BANK_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE20::text), '^^') 
            , '||', IFNULL(TRIM(VENDOR_NAME_ALT::text), '^^') 
            , '||', IFNULL(TRIM(PARENT_VENDOR_ID::text), '^^') 
            , '||', IFNULL(TRIM(VENDOR_TYPE_LOOKUP_CODE::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE17::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE18::text), '^^') 
            , '||', IFNULL(TRIM(CIS_ENABLED_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE15::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE16::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE13::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE14::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE11::text), '^^') 
            , '||', IFNULL(TRIM(BANK_ACCOUNT_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE12::text), '^^') 
            , '||', IFNULL(TRIM(ORGANIZATION_TYPE_LOOKUP_CODE::text), '^^') 
            , '||', IFNULL(TRIM(RECEIVING_ROUTING_ID::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE15::text), '^^') 
            , '||', IFNULL(TRIM(NUM_1099::text), '^^') 
            , '||', IFNULL(TRIM(ALLOW_AWT_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(INVOICE_CURRENCY_CODE::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE19::text), '^^') 
            , '||', IFNULL(TRIM(CREATE_DEBIT_MEMO_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(VENDOR_NAME::text), '^^') 
            , '||', IFNULL(TRIM(DISTRIBUTION_SET_ID::text), '^^') 
            , '||', IFNULL(TRIM(EMPLOYEE_ID::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE10::text), '^^') 
            , '||', IFNULL(TRIM(BANK_ACCOUNT_NUM::text), '^^') 
            , '||', IFNULL(TRIM(AUTO_CALCULATE_INTEREST_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(SECOND_NAME::text), '^^') 
            , '||', IFNULL(TRIM(BANK_ACCOUNT_NAME::text), '^^') 
            , '||', IFNULL(TRIM(TAX_VERIFICATION_DATE::text), '^^') 
            , '||', IFNULL(TRIM(SALUTATION::text), '^^') 
            , '||', IFNULL(TRIM(NATIONAL_INSURANCE_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(HOLD_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(INSPECTION_REQUIRED_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(WORK_REFERENCE::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_TO_LOCATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(ONE_TIME_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(FUTURE_DATED_PAYMENT_CCID::text), '^^') 
            , '||', IFNULL(TRIM(WOMEN_OWNED_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(CREATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(HOLD_REASON::text), '^^') 
            , '||', IFNULL(TRIM(WITHHOLDING_START_DATE::text), '^^') 
            , '||', IFNULL(TRIM(VAT_CODE::text), '^^') 
            , '||', IFNULL(TRIM(VERIFICATION_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(PARTNERSHIP_NAME::text), '^^') 
            , '||', IFNULL(TRIM(RECEIPT_REQUIRED_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(FEDERAL_REPORTABLE_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(INDIVIDUAL_1099::text), '^^') 
            , '||', IFNULL(TRIM(TCA_SYNC_VENDOR_NAME::text), '^^') 
            , '||', IFNULL(TRIM(ENFORCE_SHIP_TO_LOCATION_CODE::text), '^^') 
            , '||', IFNULL(TRIM(TAX_REPORTING_NAME::text), '^^') 
            , '||', IFNULL(TRIM(TERMS_ID::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_APPLICATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(VALIDATION_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(AUTO_TAX_CALC_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(EXCLUDE_FREIGHT_FROM_DISCOUNT::text), '^^') 
            , '||', IFNULL(TRIM(BUS_CLASS_LAST_CERTIFIED_BY::text), '^^') 
            , '||', IFNULL(TRIM(TERMS_DATE_BASIS::text), '^^') 
            , '||', IFNULL(TRIM(PARTY_ID::text), '^^') 
            , '||', IFNULL(TRIM(PAY_AWT_GROUP_ID::text), '^^') 
            , '||', IFNULL(TRIM(PURCHASING_HOLD_REASON::text), '^^') 
            , '||', IFNULL(TRIM(ALLOW_SUBSTITUTE_RECEIPTS_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(CREDIT_STATUS_LOOKUP_CODE::text), '^^') 
            , '||', IFNULL(TRIM(VAT_REGISTRATION_NUM::text), '^^') 
            , '||', IFNULL(TRIM(SET_OF_BOOKS_ID::text), '^^') 
            , '||', IFNULL(TRIM(PARTNERSHIP_UTR::text), '^^') 
            , '||', IFNULL(TRIM(REQUEST_ID::text), '^^') 
            , '||', IFNULL(TRIM(BANK_CHARGE_BEARER::text), '^^') 
            , '||', IFNULL(TRIM(FIRST_NAME::text), '^^') 
            , '||', IFNULL(TRIM(HOLD_FUTURE_PAYMENTS_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(PAYMENT_PRIORITY::text), '^^') 
            , '||', IFNULL(TRIM(RECEIPT_DAYS_EXCEPTION_CODE::text), '^^') 
            , '||', IFNULL(TRIM(DISC_TAKEN_CODE_COMBINATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(PAYMENT_METHOD_LOOKUP_CODE::text), '^^') 
            , '||', IFNULL(TRIM(CIS_PARENT_VENDOR_ID::text), '^^') 
            , '||', IFNULL(TRIM(TYPE_1099::text), '^^') 
            , '||', IFNULL(TRIM(STANDARD_INDUSTRY_CLASS::text), '^^') 
            , '||', IFNULL(TRIM(VERIFICATION_REQUEST_ID::text), '^^') 
            , '||', IFNULL(TRIM(PAYMENT_CURRENCY_CODE::text), '^^') 
            , '||', IFNULL(TRIM(HOLD_ALL_PAYMENTS_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(CIS_VERIFICATION_DATE::text), '^^') 
            , '||', IFNULL(TRIM(SUMMARY_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(QTY_RCV_TOLERANCE::text), '^^') 
            , '||', IFNULL(TRIM(ALLOW_UNORDERED_RECEIPTS_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(SEGMENT2::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_LOGIN::text), '^^') 
            , '||', IFNULL(TRIM(MATCH_OPTION::text), '^^') 
            , '||', IFNULL(TRIM(ENABLED_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_VIA_LOOKUP_CODE::text), '^^') 
            , '||', IFNULL(TRIM(FOB_LOOKUP_CODE::text), '^^') 
            , '||', IFNULL(TRIM(DAYS_EARLY_RECEIPT_ALLOWED::text), '^^') 
            , '||', IFNULL(TRIM(HOLD_UNMATCHED_INVOICES_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(MIN_ORDER_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(PAY_GROUP_LOOKUP_CODE::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_UPDATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(START_DATE_ACTIVE::text), '^^') 
            , '||', IFNULL(TRIM(END_DATE_ACTIVE::text), '^^') 
            , '||', IFNULL(TRIM(CREATION_DATE::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
