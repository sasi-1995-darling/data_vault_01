---- SRC LAYER ----
WITH
SRC_S              as ( SELECT ACCTS_PAY_CODE_COMBINATION_ID, ACK_LEAD_TIME, ADDRESS_LINE1, ADDRESS_LINE2, ADDRESS_LINE3, ADDRESS_LINE4, ADDRESS_LINES_ALT, ADDRESS_STYLE, ALLOW_AWT_FLAG, ALWAYS_TAKE_DISC_FLAG, AMOUNT_INCLUDES_TAX_FLAG, AP_TAX_ROUNDING_RULE, AREA_CODE, ATTENTION_AR_FLAG, ATTRIBUTE1, ATTRIBUTE10, ATTRIBUTE11, ATTRIBUTE12, ATTRIBUTE13, ATTRIBUTE14, ATTRIBUTE15, ATTRIBUTE2, ATTRIBUTE3, ATTRIBUTE4, ATTRIBUTE5, ATTRIBUTE6, ATTRIBUTE7, ATTRIBUTE8, ATTRIBUTE9, ATTRIBUTE_CATEGORY, AUTO_TAX_CALC_FLAG, AUTO_TAX_CALC_OVERRIDE, AWT_GROUP_ID, BANK_ACCOUNT_NAME, BANK_ACCOUNT_NUM, BANK_ACCOUNT_TYPE, BANK_BRANCH_TYPE, BANK_CHARGE_BEARER, BANK_NUM, BANK_NUMBER, BILL_TO_LOCATION_ID, CAGE_CODE, CCR_COMMENTS, CHECK_DIGITS, CITY, COUNTRY, COUNTRY_OF_ORIGIN_CODE, COUNTY, CREATED_BY, CREATE_DEBIT_MEMO_FLAG, CREATION_DATE, CURRENT_CATALOG_NUM, CUSTOMER_NUM, DEBARMENT_END_DATE, DEBARMENT_START_DATE, DEFAULT_PAY_SITE_ID, DISTRIBUTION_SET_ID, DIVISION_NAME, DOING_BUS_AS_NAME, DUNS_NUMBER, ECE_TP_LOCATION_CODE, EDI_ID_NUMBER, EDI_PAYMENT_FORMAT, EDI_PAYMENT_METHOD, EDI_REMITTANCE_INSTRUCTION, EDI_REMITTANCE_METHOD, EDI_TRANSACTION_HANDLING, EMAIL_ADDRESS, EXCLUDE_FREIGHT_FROM_DISCOUNT, EXCLUSIVE_PAYMENT_FLAG, FAX, FAX_AREA_CODE, FOB_LOOKUP_CODE, FREIGHT_TERMS_LOOKUP_CODE, FUTURE_DATED_PAYMENT_CCID, GAPLESS_INV_NUM_FLAG, GLOBAL_ATTRIBUTE1, GLOBAL_ATTRIBUTE10, GLOBAL_ATTRIBUTE11, GLOBAL_ATTRIBUTE12, GLOBAL_ATTRIBUTE13, GLOBAL_ATTRIBUTE14, GLOBAL_ATTRIBUTE15, GLOBAL_ATTRIBUTE16, GLOBAL_ATTRIBUTE17, GLOBAL_ATTRIBUTE18, GLOBAL_ATTRIBUTE19, GLOBAL_ATTRIBUTE2, GLOBAL_ATTRIBUTE20, GLOBAL_ATTRIBUTE3, GLOBAL_ATTRIBUTE4, GLOBAL_ATTRIBUTE5, GLOBAL_ATTRIBUTE6, GLOBAL_ATTRIBUTE7, GLOBAL_ATTRIBUTE8, GLOBAL_ATTRIBUTE9, GLOBAL_ATTRIBUTE_CATEGORY, HOLD_ALL_PAYMENTS_FLAG, HOLD_FUTURE_PAYMENTS_FLAG, HOLD_REASON, HOLD_UNMATCHED_INVOICES_FLAG, INACTIVE_DATE, INVOICE_AMOUNT_LIMIT, INVOICE_CURRENCY_CODE, LANGUAGE, LAST_UPDATED_BY, LAST_UPDATE_DATE, LAST_UPDATE_LOGIN, LEGAL_BUSINESS_NAME, LOCATION_ID, MATCH_OPTION, OFFSET_TAX_FLAG, OFFSET_VAT_CODE, ORG_ID, PARTY_SITE_ID, PAYMENT_CURRENCY_CODE, PAYMENT_METHOD_LOOKUP_CODE, PAYMENT_PRIORITY, PAY_AWT_GROUP_ID, PAY_DATE_BASIS_LOOKUP_CODE, PAY_GROUP_LOOKUP_CODE, PAY_ON_CODE, PAY_ON_RECEIPT_SUMMARY_CODE, PAY_SITE_FLAG, PCARD_SITE_FLAG, PHONE, PREPAY_CODE_COMBINATION_ID, PRIMARY_PAY_SITE_FLAG, PROGRAM_APPLICATION_ID, PROGRAM_ID, PROGRAM_UPDATE_DATE, PROVINCE, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, PURCHASING_SITE_FLAG, REMITTANCE_EMAIL, REQUEST_ID, RETAINAGE_RATE, RFQ_ONLY_SITE_FLAG, SELLING_COMPANY_IDENTIFIER, SERVICES_TOLERANCE_ID, SHIPPING_CONTROL, SHIP_TO_LOCATION_ID, SHIP_VIA_LOOKUP_CODE, SMALL_BUSINESS_CODE, STATE, SUPPLIER_NOTIF_METHOD, TAX_REPORTING_SITE_FLAG, TCA_SYNC_CITY, TCA_SYNC_COUNTRY, TCA_SYNC_COUNTY, TCA_SYNC_PROVINCE, TCA_SYNC_STATE, TCA_SYNC_ZIP, TELEX, TERMS_DATE_BASIS, TERMS_ID, TOLERANCE_ID, TP_HEADER_ID, VALIDATION_NUMBER, VAT_CODE, VAT_REGISTRATION_NUM, VENDOR_ID, VENDOR_SITE_CODE, VENDOR_SITE_CODE_ALT, VENDOR_SITE_ID, ZIP, _FIVETRAN_DELETED, _FIVETRAN_ID, _FIVETRAN_SYNCED FROM {{ source('ml_ebs_ap', 'ap_supplier_sites_all') }} as SRC  ),
SRC_A              as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  ),
SRC_sup            as ( SELECT SEGMENT1, VENDOR_ID FROM {{ source('ml_ebs_ap', 'ap_suppliers') }} as SRC 
                        qualify 1= row_number()over(partition by vendor_id order by _fivetran_synced desc, psa_load_dts desc) )

/*
SRC_S              as ( SELECT * FROM ml_ebs_ap.ap_supplier_sites_all )
SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
SRC_sup            as ( SELECT * FROM ml_ebs_ap.ap_suppliers )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        VENDOR_SITE_ID::TEXT                                         as                                   SUPPLIER_SITE_BK
      , VENDOR_SITE_ID
      , VENDOR_ID
      , ZIP
      , CHECK_DIGITS
      , ORG_ID
      , ALWAYS_TAKE_DISC_FLAG
      , FREIGHT_TERMS_LOOKUP_CODE
      , AUTO_TAX_CALC_OVERRIDE
      , BANK_NUM
      , EDI_REMITTANCE_INSTRUCTION
      , OFFSET_TAX_FLAG
      , PROGRAM_ID
      , LEGAL_BUSINESS_NAME
      , PAY_DATE_BASIS_LOOKUP_CODE
      , CURRENT_CATALOG_NUM
      , GLOBAL_ATTRIBUTE5
      , GLOBAL_ATTRIBUTE4
      , GLOBAL_ATTRIBUTE7
      , GLOBAL_ATTRIBUTE6
      , EDI_TRANSACTION_HANDLING
      , GLOBAL_ATTRIBUTE1
      , EMAIL_ADDRESS
      , GLOBAL_ATTRIBUTE3
      , GLOBAL_ATTRIBUTE2
      , GAPLESS_INV_NUM_FLAG
      , BANK_BRANCH_TYPE
      , AWT_GROUP_ID
      , GLOBAL_ATTRIBUTE9
      , GLOBAL_ATTRIBUTE8
      , ATTRIBUTE3
      , LANGUAGE
      , ATTRIBUTE2
      , ATTRIBUTE1
      , PAY_ON_RECEIPT_SUMMARY_CODE
      , PARTY_SITE_ID
      , INVOICE_AMOUNT_LIMIT
      , AP_TAX_ROUNDING_RULE
      , DEFAULT_PAY_SITE_ID
      , EDI_REMITTANCE_METHOD
      , AMOUNT_INCLUDES_TAX_FLAG
      , ATTRIBUTE9
      , ATTRIBUTE8
      , SUPPLIER_NOTIF_METHOD
      , TCA_SYNC_STATE
      , ATTRIBUTE7
      , ATTRIBUTE6
      , TELEX
      , ATTRIBUTE5
      , TCA_SYNC_COUNTRY
      , ATTRIBUTE4
      , TOLERANCE_ID
      , OFFSET_VAT_CODE
      , ACCTS_PAY_CODE_COMBINATION_ID
      , FAX_AREA_CODE
      , ECE_TP_LOCATION_CODE
      , ATTRIBUTE10
      , EXCLUSIVE_PAYMENT_FLAG
      , ATTRIBUTE14
      , ATTRIBUTE13
      , EDI_PAYMENT_FORMAT
      , ATTRIBUTE12
      , ATTRIBUTE11
      , COUNTRY_OF_ORIGIN_CODE
      , BILL_TO_LOCATION_ID
      , EDI_PAYMENT_METHOD
      , PREPAY_CODE_COMBINATION_ID
      , VENDOR_SITE_CODE
      , REMITTANCE_EMAIL
      , CUSTOMER_NUM
      , TCA_SYNC_CITY
      , SERVICES_TOLERANCE_ID
      , BANK_NUMBER
      , GLOBAL_ATTRIBUTE20
      , PAY_ON_CODE
      , TP_HEADER_ID
      , GLOBAL_ATTRIBUTE17
      , GLOBAL_ATTRIBUTE18
      , GLOBAL_ATTRIBUTE15
      , GLOBAL_ATTRIBUTE16
      , CITY
      , GLOBAL_ATTRIBUTE13
      , GLOBAL_ATTRIBUTE14
      , DEBARMENT_END_DATE
      , GLOBAL_ATTRIBUTE11
      , BANK_ACCOUNT_TYPE
      , GLOBAL_ATTRIBUTE12
      , TCA_SYNC_ZIP
      , ATTENTION_AR_FLAG
      , ATTRIBUTE15
      , INVOICE_CURRENCY_CODE
      , ALLOW_AWT_FLAG
      , GLOBAL_ATTRIBUTE19
      , CREATE_DEBIT_MEMO_FLAG
      , DISTRIBUTION_SET_ID
      , GLOBAL_ATTRIBUTE10
      , BANK_ACCOUNT_NUM
      , AREA_CODE
      , PCARD_SITE_FLAG
      , COUNTRY
      , BANK_ACCOUNT_NAME
      , CAGE_CODE
      , TCA_SYNC_COUNTY
      , ACK_LEAD_TIME
      , SHIP_TO_LOCATION_ID
      , FUTURE_DATED_PAYMENT_CCID
      , TAX_REPORTING_SITE_FLAG
      , COUNTY
      , CREATED_BY
      , LAST_UPDATED_BY
      , HOLD_REASON
      , CCR_COMMENTS
      , DOING_BUS_AS_NAME
      , VAT_CODE
      , VENDOR_SITE_CODE_ALT
      , TERMS_ID
      , SMALL_BUSINESS_CODE
      , ATTRIBUTE_CATEGORY
      , PROGRAM_APPLICATION_ID
      , PRIMARY_PAY_SITE_FLAG
      , PAY_SITE_FLAG
      , VALIDATION_NUMBER
      , AUTO_TAX_CALC_FLAG
      , EXCLUDE_FREIGHT_FROM_DISCOUNT
      , TERMS_DATE_BASIS
      , PAY_AWT_GROUP_ID
      , TCA_SYNC_PROVINCE
      , PHONE
      , VAT_REGISTRATION_NUM
      , STATE
      , DUNS_NUMBER
      , REQUEST_ID
      , BANK_CHARGE_BEARER
      , ADDRESS_STYLE
      , HOLD_FUTURE_PAYMENTS_FLAG
      , EDI_ID_NUMBER
      , PAYMENT_PRIORITY
      , ADDRESS_LINE1
      , ADDRESS_LINES_ALT
      , PURCHASING_SITE_FLAG
      , ADDRESS_LINE2
      , ADDRESS_LINE3
      , ADDRESS_LINE4
      , PAYMENT_METHOD_LOOKUP_CODE
      , RFQ_ONLY_SITE_FLAG
      , LOCATION_ID
      , PAYMENT_CURRENCY_CODE
      , HOLD_ALL_PAYMENTS_FLAG
      , SELLING_COMPANY_IDENTIFIER
      , DEBARMENT_START_DATE
      , LAST_UPDATE_LOGIN
      , MATCH_OPTION
      , RETAINAGE_RATE
      , GLOBAL_ATTRIBUTE_CATEGORY
      , SHIP_VIA_LOOKUP_CODE
      , FOB_LOOKUP_CODE
      , SHIPPING_CONTROL
      , HOLD_UNMATCHED_INVOICES_FLAG
      , PROVINCE
      , DIVISION_NAME
      , FAX
      , PAY_GROUP_LOOKUP_CODE
      , PROGRAM_UPDATE_DATE
      , INACTIVE_DATE
      , CREATION_DATE
      , LAST_UPDATE_DATE
      , _FIVETRAN_DELETED
      , _FIVETRAN_ID
      , _FIVETRAN_SYNCED
      , CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED )                   as                                           LOAD_DTS
      , PSA_RECORD_SOURCE
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

, LOGIC_sup as (
    SELECT
        SEGMENT1                                                     as                                        SUPPLIER_BK
      , VENDOR_ID                                                    as                                      SUP_VENDOR_ID
      , SEGMENT1
    FROM SRC_sup
)
---- RENAME LAYER ----

, RENAME_S as (
    SELECT
        SUPPLIER_SITE_BK
      , VENDOR_SITE_ID
      , VENDOR_ID
      , ZIP
      , CHECK_DIGITS
      , ORG_ID
      , ALWAYS_TAKE_DISC_FLAG
      , FREIGHT_TERMS_LOOKUP_CODE
      , AUTO_TAX_CALC_OVERRIDE
      , BANK_NUM
      , EDI_REMITTANCE_INSTRUCTION
      , OFFSET_TAX_FLAG
      , PROGRAM_ID
      , LEGAL_BUSINESS_NAME
      , PAY_DATE_BASIS_LOOKUP_CODE
      , CURRENT_CATALOG_NUM
      , GLOBAL_ATTRIBUTE5
      , GLOBAL_ATTRIBUTE4
      , GLOBAL_ATTRIBUTE7
      , GLOBAL_ATTRIBUTE6
      , EDI_TRANSACTION_HANDLING
      , GLOBAL_ATTRIBUTE1
      , EMAIL_ADDRESS
      , GLOBAL_ATTRIBUTE3
      , GLOBAL_ATTRIBUTE2
      , GAPLESS_INV_NUM_FLAG
      , BANK_BRANCH_TYPE
      , AWT_GROUP_ID
      , GLOBAL_ATTRIBUTE9
      , GLOBAL_ATTRIBUTE8
      , ATTRIBUTE3
      , LANGUAGE
      , ATTRIBUTE2
      , ATTRIBUTE1
      , PAY_ON_RECEIPT_SUMMARY_CODE
      , PARTY_SITE_ID
      , INVOICE_AMOUNT_LIMIT
      , AP_TAX_ROUNDING_RULE
      , DEFAULT_PAY_SITE_ID
      , EDI_REMITTANCE_METHOD
      , AMOUNT_INCLUDES_TAX_FLAG
      , ATTRIBUTE9
      , ATTRIBUTE8
      , SUPPLIER_NOTIF_METHOD
      , TCA_SYNC_STATE
      , ATTRIBUTE7
      , ATTRIBUTE6
      , TELEX
      , ATTRIBUTE5
      , TCA_SYNC_COUNTRY
      , ATTRIBUTE4
      , TOLERANCE_ID
      , OFFSET_VAT_CODE
      , ACCTS_PAY_CODE_COMBINATION_ID
      , FAX_AREA_CODE
      , ECE_TP_LOCATION_CODE
      , ATTRIBUTE10
      , EXCLUSIVE_PAYMENT_FLAG
      , ATTRIBUTE14
      , ATTRIBUTE13
      , EDI_PAYMENT_FORMAT
      , ATTRIBUTE12
      , ATTRIBUTE11
      , COUNTRY_OF_ORIGIN_CODE
      , BILL_TO_LOCATION_ID
      , EDI_PAYMENT_METHOD
      , PREPAY_CODE_COMBINATION_ID
      , VENDOR_SITE_CODE
      , REMITTANCE_EMAIL
      , CUSTOMER_NUM
      , TCA_SYNC_CITY
      , SERVICES_TOLERANCE_ID
      , BANK_NUMBER
      , GLOBAL_ATTRIBUTE20
      , PAY_ON_CODE
      , TP_HEADER_ID
      , GLOBAL_ATTRIBUTE17
      , GLOBAL_ATTRIBUTE18
      , GLOBAL_ATTRIBUTE15
      , GLOBAL_ATTRIBUTE16
      , CITY
      , GLOBAL_ATTRIBUTE13
      , GLOBAL_ATTRIBUTE14
      , DEBARMENT_END_DATE
      , GLOBAL_ATTRIBUTE11
      , BANK_ACCOUNT_TYPE
      , GLOBAL_ATTRIBUTE12
      , TCA_SYNC_ZIP
      , ATTENTION_AR_FLAG
      , ATTRIBUTE15
      , INVOICE_CURRENCY_CODE
      , ALLOW_AWT_FLAG
      , GLOBAL_ATTRIBUTE19
      , CREATE_DEBIT_MEMO_FLAG
      , DISTRIBUTION_SET_ID
      , GLOBAL_ATTRIBUTE10
      , BANK_ACCOUNT_NUM
      , AREA_CODE
      , PCARD_SITE_FLAG
      , COUNTRY
      , BANK_ACCOUNT_NAME
      , CAGE_CODE
      , TCA_SYNC_COUNTY
      , ACK_LEAD_TIME
      , SHIP_TO_LOCATION_ID
      , FUTURE_DATED_PAYMENT_CCID
      , TAX_REPORTING_SITE_FLAG
      , COUNTY
      , CREATED_BY
      , LAST_UPDATED_BY
      , HOLD_REASON
      , CCR_COMMENTS
      , DOING_BUS_AS_NAME
      , VAT_CODE
      , VENDOR_SITE_CODE_ALT
      , TERMS_ID
      , SMALL_BUSINESS_CODE
      , ATTRIBUTE_CATEGORY
      , PROGRAM_APPLICATION_ID
      , PRIMARY_PAY_SITE_FLAG
      , PAY_SITE_FLAG
      , VALIDATION_NUMBER
      , AUTO_TAX_CALC_FLAG
      , EXCLUDE_FREIGHT_FROM_DISCOUNT
      , TERMS_DATE_BASIS
      , PAY_AWT_GROUP_ID
      , TCA_SYNC_PROVINCE
      , PHONE
      , VAT_REGISTRATION_NUM
      , STATE
      , DUNS_NUMBER
      , REQUEST_ID
      , BANK_CHARGE_BEARER
      , ADDRESS_STYLE
      , HOLD_FUTURE_PAYMENTS_FLAG
      , EDI_ID_NUMBER
      , PAYMENT_PRIORITY
      , ADDRESS_LINE1
      , ADDRESS_LINES_ALT
      , PURCHASING_SITE_FLAG
      , ADDRESS_LINE2
      , ADDRESS_LINE3
      , ADDRESS_LINE4
      , PAYMENT_METHOD_LOOKUP_CODE
      , RFQ_ONLY_SITE_FLAG
      , LOCATION_ID
      , PAYMENT_CURRENCY_CODE
      , HOLD_ALL_PAYMENTS_FLAG
      , SELLING_COMPANY_IDENTIFIER
      , DEBARMENT_START_DATE
      , LAST_UPDATE_LOGIN
      , MATCH_OPTION
      , RETAINAGE_RATE
      , GLOBAL_ATTRIBUTE_CATEGORY
      , SHIP_VIA_LOOKUP_CODE
      , FOB_LOOKUP_CODE
      , SHIPPING_CONTROL
      , HOLD_UNMATCHED_INVOICES_FLAG
      , PROVINCE
      , DIVISION_NAME
      , FAX
      , PAY_GROUP_LOOKUP_CODE
      , PROGRAM_UPDATE_DATE
      , INACTIVE_DATE
      , CREATION_DATE
      , LAST_UPDATE_DATE
      , _FIVETRAN_DELETED
      , _FIVETRAN_ID
      , _FIVETRAN_SYNCED
      , LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_LOAD_DTS
      , PSA_DELETE_IND
    FROM LOGIC_S
)

, RENAME_sup as (
    SELECT
        SUPPLIER_BK
      , SUP_VENDOR_ID
      , SEGMENT1
    FROM LOGIC_sup
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
    WHERE rec_src = 'USWIOC.ORCL.EBSPRD.AP_SUPPLIER_SITES_ALL'
)

, FILTER_sup as (
    SELECT *
    FROM RENAME_sup
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_S
    INNER JOIN FILTER_A
        ON '1' = '1'
    LEFT JOIN FILTER_sup
        ON FILTER_S.VENDOR_ID = SUP_VENDOR_ID
)

---- FINAL LAYER ----
SELECT
          SUPPLIER_SITE_BK
        , VENDOR_SITE_ID
        , VENDOR_ID
        , ZIP
        , CHECK_DIGITS
        , ORG_ID
        , ALWAYS_TAKE_DISC_FLAG
        , FREIGHT_TERMS_LOOKUP_CODE
        , AUTO_TAX_CALC_OVERRIDE
        , BANK_NUM
        , EDI_REMITTANCE_INSTRUCTION
        , OFFSET_TAX_FLAG
        , PROGRAM_ID
        , LEGAL_BUSINESS_NAME
        , PAY_DATE_BASIS_LOOKUP_CODE
        , CURRENT_CATALOG_NUM
        , GLOBAL_ATTRIBUTE5
        , GLOBAL_ATTRIBUTE4
        , GLOBAL_ATTRIBUTE7
        , GLOBAL_ATTRIBUTE6
        , EDI_TRANSACTION_HANDLING
        , GLOBAL_ATTRIBUTE1
        , EMAIL_ADDRESS
        , GLOBAL_ATTRIBUTE3
        , GLOBAL_ATTRIBUTE2
        , GAPLESS_INV_NUM_FLAG
        , BANK_BRANCH_TYPE
        , AWT_GROUP_ID
        , GLOBAL_ATTRIBUTE9
        , GLOBAL_ATTRIBUTE8
        , ATTRIBUTE3
        , LANGUAGE
        , ATTRIBUTE2
        , ATTRIBUTE1
        , PAY_ON_RECEIPT_SUMMARY_CODE
        , PARTY_SITE_ID
        , INVOICE_AMOUNT_LIMIT
        , AP_TAX_ROUNDING_RULE
        , DEFAULT_PAY_SITE_ID
        , EDI_REMITTANCE_METHOD
        , AMOUNT_INCLUDES_TAX_FLAG
        , ATTRIBUTE9
        , ATTRIBUTE8
        , SUPPLIER_NOTIF_METHOD
        , TCA_SYNC_STATE
        , ATTRIBUTE7
        , ATTRIBUTE6
        , TELEX
        , ATTRIBUTE5
        , TCA_SYNC_COUNTRY
        , ATTRIBUTE4
        , TOLERANCE_ID
        , OFFSET_VAT_CODE
        , ACCTS_PAY_CODE_COMBINATION_ID
        , FAX_AREA_CODE
        , ECE_TP_LOCATION_CODE
        , ATTRIBUTE10
        , EXCLUSIVE_PAYMENT_FLAG
        , ATTRIBUTE14
        , ATTRIBUTE13
        , EDI_PAYMENT_FORMAT
        , ATTRIBUTE12
        , ATTRIBUTE11
        , COUNTRY_OF_ORIGIN_CODE
        , BILL_TO_LOCATION_ID
        , EDI_PAYMENT_METHOD
        , PREPAY_CODE_COMBINATION_ID
        , VENDOR_SITE_CODE
        , REMITTANCE_EMAIL
        , CUSTOMER_NUM
        , TCA_SYNC_CITY
        , SERVICES_TOLERANCE_ID
        , BANK_NUMBER
        , GLOBAL_ATTRIBUTE20
        , PAY_ON_CODE
        , TP_HEADER_ID
        , GLOBAL_ATTRIBUTE17
        , GLOBAL_ATTRIBUTE18
        , GLOBAL_ATTRIBUTE15
        , GLOBAL_ATTRIBUTE16
        , CITY
        , GLOBAL_ATTRIBUTE13
        , GLOBAL_ATTRIBUTE14
        , DEBARMENT_END_DATE
        , GLOBAL_ATTRIBUTE11
        , BANK_ACCOUNT_TYPE
        , GLOBAL_ATTRIBUTE12
        , TCA_SYNC_ZIP
        , ATTENTION_AR_FLAG
        , ATTRIBUTE15
        , INVOICE_CURRENCY_CODE
        , ALLOW_AWT_FLAG
        , GLOBAL_ATTRIBUTE19
        , CREATE_DEBIT_MEMO_FLAG
        , DISTRIBUTION_SET_ID
        , GLOBAL_ATTRIBUTE10
        , BANK_ACCOUNT_NUM
        , AREA_CODE
        , PCARD_SITE_FLAG
        , COUNTRY
        , BANK_ACCOUNT_NAME
        , CAGE_CODE
        , TCA_SYNC_COUNTY
        , ACK_LEAD_TIME
        , SHIP_TO_LOCATION_ID
        , FUTURE_DATED_PAYMENT_CCID
        , TAX_REPORTING_SITE_FLAG
        , COUNTY
        , CREATED_BY
        , LAST_UPDATED_BY
        , HOLD_REASON
        , CCR_COMMENTS
        , DOING_BUS_AS_NAME
        , VAT_CODE
        , VENDOR_SITE_CODE_ALT
        , TERMS_ID
        , SMALL_BUSINESS_CODE
        , ATTRIBUTE_CATEGORY
        , PROGRAM_APPLICATION_ID
        , PRIMARY_PAY_SITE_FLAG
        , PAY_SITE_FLAG
        , VALIDATION_NUMBER
        , AUTO_TAX_CALC_FLAG
        , EXCLUDE_FREIGHT_FROM_DISCOUNT
        , TERMS_DATE_BASIS
        , PAY_AWT_GROUP_ID
        , TCA_SYNC_PROVINCE
        , PHONE
        , VAT_REGISTRATION_NUM
        , STATE
        , DUNS_NUMBER
        , REQUEST_ID
        , BANK_CHARGE_BEARER
        , ADDRESS_STYLE
        , HOLD_FUTURE_PAYMENTS_FLAG
        , EDI_ID_NUMBER
        , PAYMENT_PRIORITY
        , ADDRESS_LINE1
        , ADDRESS_LINES_ALT
        , PURCHASING_SITE_FLAG
        , ADDRESS_LINE2
        , ADDRESS_LINE3
        , ADDRESS_LINE4
        , PAYMENT_METHOD_LOOKUP_CODE
        , RFQ_ONLY_SITE_FLAG
        , LOCATION_ID
        , PAYMENT_CURRENCY_CODE
        , HOLD_ALL_PAYMENTS_FLAG
        , SELLING_COMPANY_IDENTIFIER
        , DEBARMENT_START_DATE
        , LAST_UPDATE_LOGIN
        , MATCH_OPTION
        , RETAINAGE_RATE
        , GLOBAL_ATTRIBUTE_CATEGORY
        , SHIP_VIA_LOOKUP_CODE
        , FOB_LOOKUP_CODE
        , SHIPPING_CONTROL
        , HOLD_UNMATCHED_INVOICES_FLAG
        , PROVINCE
        , DIVISION_NAME
        , FAX
        , PAY_GROUP_LOOKUP_CODE
        , PROGRAM_UPDATE_DATE
        , INACTIVE_DATE
        , CREATION_DATE
        , LAST_UPDATE_DATE
        , _FIVETRAN_DELETED
        , _FIVETRAN_ID
        , _FIVETRAN_SYNCED
        , LOAD_DTS
        , SUPPLIER_BK
        , /*To handle the optional null default for the Hash key generation and to match with the Ghost Key Hash value */
IFF( TERMS_ID IS NULL, '-2', CONCAT_WS('||',  TERMS_ID, BKCC)) as DRVD_PAYMENT_TERM_BKCC
        , PSA_RECORD_SOURCE
        , PSA_LOAD_DTS
        , PSA_DELETE_IND
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(SEGMENT1 as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(VENDOR_SITE_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as SUPPLIER_SITE_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(SEGMENT1 as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as SUPPLIER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(SEGMENT1 as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(VENDOR_SITE_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as LNK_SUPPLIER_SITE_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(DRVD_PAYMENT_TERM_BKCC as VARCHAR)),''), '^^')
        ))) as PAYMENT_TERM_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(SEGMENT1 as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(VENDOR_SITE_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(TERMS_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as LNK_SUPPLIER_SITE_PAYMENT_TERM_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(VENDOR_ID::text), '^^') 
            , '||', IFNULL(TRIM(ZIP::text), '^^') 
            , '||', IFNULL(TRIM(CHECK_DIGITS::text), '^^') 
            , '||', IFNULL(TRIM(ORG_ID::text), '^^') 
            , '||', IFNULL(TRIM(ALWAYS_TAKE_DISC_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(FREIGHT_TERMS_LOOKUP_CODE::text), '^^') 
            , '||', IFNULL(TRIM(AUTO_TAX_CALC_OVERRIDE::text), '^^') 
            , '||', IFNULL(TRIM(BANK_NUM::text), '^^') 
            , '||', IFNULL(TRIM(EDI_REMITTANCE_INSTRUCTION::text), '^^') 
            , '||', IFNULL(TRIM(OFFSET_TAX_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_ID::text), '^^') 
            , '||', IFNULL(TRIM(LEGAL_BUSINESS_NAME::text), '^^') 
            , '||', IFNULL(TRIM(PAY_DATE_BASIS_LOOKUP_CODE::text), '^^') 
            , '||', IFNULL(TRIM(CURRENT_CATALOG_NUM::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE5::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE4::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE7::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE6::text), '^^') 
            , '||', IFNULL(TRIM(EDI_TRANSACTION_HANDLING::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE1::text), '^^') 
            , '||', IFNULL(TRIM(EMAIL_ADDRESS::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE3::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE2::text), '^^') 
            , '||', IFNULL(TRIM(GAPLESS_INV_NUM_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(BANK_BRANCH_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(AWT_GROUP_ID::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE9::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE8::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE3::text), '^^') 
            , '||', IFNULL(TRIM(LANGUAGE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE2::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE1::text), '^^') 
            , '||', IFNULL(TRIM(PAY_ON_RECEIPT_SUMMARY_CODE::text), '^^') 
            , '||', IFNULL(TRIM(PARTY_SITE_ID::text), '^^') 
            , '||', IFNULL(TRIM(INVOICE_AMOUNT_LIMIT::text), '^^') 
            , '||', IFNULL(TRIM(AP_TAX_ROUNDING_RULE::text), '^^') 
            , '||', IFNULL(TRIM(DEFAULT_PAY_SITE_ID::text), '^^') 
            , '||', IFNULL(TRIM(EDI_REMITTANCE_METHOD::text), '^^') 
            , '||', IFNULL(TRIM(AMOUNT_INCLUDES_TAX_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE9::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE8::text), '^^') 
            , '||', IFNULL(TRIM(SUPPLIER_NOTIF_METHOD::text), '^^') 
            , '||', IFNULL(TRIM(TCA_SYNC_STATE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE7::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE6::text), '^^') 
            , '||', IFNULL(TRIM(TELEX::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE5::text), '^^') 
            , '||', IFNULL(TRIM(TCA_SYNC_COUNTRY::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE4::text), '^^') 
            , '||', IFNULL(TRIM(TOLERANCE_ID::text), '^^') 
            , '||', IFNULL(TRIM(OFFSET_VAT_CODE::text), '^^') 
            , '||', IFNULL(TRIM(ACCTS_PAY_CODE_COMBINATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(FAX_AREA_CODE::text), '^^') 
            , '||', IFNULL(TRIM(ECE_TP_LOCATION_CODE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE10::text), '^^') 
            , '||', IFNULL(TRIM(EXCLUSIVE_PAYMENT_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE14::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE13::text), '^^') 
            , '||', IFNULL(TRIM(EDI_PAYMENT_FORMAT::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE12::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE11::text), '^^') 
            , '||', IFNULL(TRIM(COUNTRY_OF_ORIGIN_CODE::text), '^^') 
            , '||', IFNULL(TRIM(BILL_TO_LOCATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(EDI_PAYMENT_METHOD::text), '^^') 
            , '||', IFNULL(TRIM(PREPAY_CODE_COMBINATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(VENDOR_SITE_CODE::text), '^^') 
            , '||', IFNULL(TRIM(REMITTANCE_EMAIL::text), '^^') 
            , '||', IFNULL(TRIM(CUSTOMER_NUM::text), '^^') 
            , '||', IFNULL(TRIM(TCA_SYNC_CITY::text), '^^') 
            , '||', IFNULL(TRIM(SERVICES_TOLERANCE_ID::text), '^^') 
            , '||', IFNULL(TRIM(BANK_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE20::text), '^^') 
            , '||', IFNULL(TRIM(PAY_ON_CODE::text), '^^') 
            , '||', IFNULL(TRIM(TP_HEADER_ID::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE17::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE18::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE15::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE16::text), '^^') 
            , '||', IFNULL(TRIM(CITY::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE13::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE14::text), '^^') 
            , '||', IFNULL(TRIM(DEBARMENT_END_DATE::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE11::text), '^^') 
            , '||', IFNULL(TRIM(BANK_ACCOUNT_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE12::text), '^^') 
            , '||', IFNULL(TRIM(TCA_SYNC_ZIP::text), '^^') 
            , '||', IFNULL(TRIM(ATTENTION_AR_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE15::text), '^^') 
            , '||', IFNULL(TRIM(INVOICE_CURRENCY_CODE::text), '^^') 
            , '||', IFNULL(TRIM(ALLOW_AWT_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE19::text), '^^') 
            , '||', IFNULL(TRIM(CREATE_DEBIT_MEMO_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(DISTRIBUTION_SET_ID::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE10::text), '^^') 
            , '||', IFNULL(TRIM(BANK_ACCOUNT_NUM::text), '^^') 
            , '||', IFNULL(TRIM(AREA_CODE::text), '^^') 
            , '||', IFNULL(TRIM(PCARD_SITE_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(COUNTRY::text), '^^') 
            , '||', IFNULL(TRIM(BANK_ACCOUNT_NAME::text), '^^') 
            , '||', IFNULL(TRIM(CAGE_CODE::text), '^^') 
            , '||', IFNULL(TRIM(TCA_SYNC_COUNTY::text), '^^') 
            , '||', IFNULL(TRIM(ACK_LEAD_TIME::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_TO_LOCATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(FUTURE_DATED_PAYMENT_CCID::text), '^^') 
            , '||', IFNULL(TRIM(TAX_REPORTING_SITE_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(COUNTY::text), '^^') 
            , '||', IFNULL(TRIM(CREATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(HOLD_REASON::text), '^^') 
            , '||', IFNULL(TRIM(CCR_COMMENTS::text), '^^') 
            , '||', IFNULL(TRIM(DOING_BUS_AS_NAME::text), '^^') 
            , '||', IFNULL(TRIM(VAT_CODE::text), '^^') 
            , '||', IFNULL(TRIM(VENDOR_SITE_CODE_ALT::text), '^^') 
            , '||', IFNULL(TRIM(TERMS_ID::text), '^^') 
            , '||', IFNULL(TRIM(SMALL_BUSINESS_CODE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_APPLICATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(PRIMARY_PAY_SITE_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(PAY_SITE_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(VALIDATION_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(AUTO_TAX_CALC_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(EXCLUDE_FREIGHT_FROM_DISCOUNT::text), '^^') 
            , '||', IFNULL(TRIM(TERMS_DATE_BASIS::text), '^^') 
            , '||', IFNULL(TRIM(PAY_AWT_GROUP_ID::text), '^^') 
            , '||', IFNULL(TRIM(TCA_SYNC_PROVINCE::text), '^^') 
            , '||', IFNULL(TRIM(PHONE::text), '^^') 
            , '||', IFNULL(TRIM(VAT_REGISTRATION_NUM::text), '^^') 
            , '||', IFNULL(TRIM(STATE::text), '^^') 
            , '||', IFNULL(TRIM(DUNS_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(REQUEST_ID::text), '^^') 
            , '||', IFNULL(TRIM(BANK_CHARGE_BEARER::text), '^^') 
            , '||', IFNULL(TRIM(ADDRESS_STYLE::text), '^^') 
            , '||', IFNULL(TRIM(HOLD_FUTURE_PAYMENTS_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(EDI_ID_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(PAYMENT_PRIORITY::text), '^^') 
            , '||', IFNULL(TRIM(ADDRESS_LINE1::text), '^^') 
            , '||', IFNULL(TRIM(ADDRESS_LINES_ALT::text), '^^') 
            , '||', IFNULL(TRIM(PURCHASING_SITE_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(ADDRESS_LINE2::text), '^^') 
            , '||', IFNULL(TRIM(ADDRESS_LINE3::text), '^^') 
            , '||', IFNULL(TRIM(ADDRESS_LINE4::text), '^^') 
            , '||', IFNULL(TRIM(PAYMENT_METHOD_LOOKUP_CODE::text), '^^') 
            , '||', IFNULL(TRIM(RFQ_ONLY_SITE_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(LOCATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(PAYMENT_CURRENCY_CODE::text), '^^') 
            , '||', IFNULL(TRIM(HOLD_ALL_PAYMENTS_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(SELLING_COMPANY_IDENTIFIER::text), '^^') 
            , '||', IFNULL(TRIM(DEBARMENT_START_DATE::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_LOGIN::text), '^^') 
            , '||', IFNULL(TRIM(MATCH_OPTION::text), '^^') 
            , '||', IFNULL(TRIM(RETAINAGE_RATE::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_VIA_LOOKUP_CODE::text), '^^') 
            , '||', IFNULL(TRIM(FOB_LOOKUP_CODE::text), '^^') 
            , '||', IFNULL(TRIM(SHIPPING_CONTROL::text), '^^') 
            , '||', IFNULL(TRIM(HOLD_UNMATCHED_INVOICES_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(PROVINCE::text), '^^') 
            , '||', IFNULL(TRIM(DIVISION_NAME::text), '^^') 
            , '||', IFNULL(TRIM(FAX::text), '^^') 
            , '||', IFNULL(TRIM(PAY_GROUP_LOOKUP_CODE::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_UPDATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(INACTIVE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(CREATION_DATE::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
