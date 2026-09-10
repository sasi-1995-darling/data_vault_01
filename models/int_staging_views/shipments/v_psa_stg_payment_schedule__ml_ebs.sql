---- SRC LAYER ----
WITH
SRC_S              as ( SELECT * FROM {{ source('ml_ebs_ar', 'ar_payment_schedules_all') }} as SRC  ),
SRC_A              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S              as ( SELECT * FROM ml_ebs_ar.ar_payment_schedules_all )
, SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        to_char(PAYMENT_SCHEDULE_ID)                                 as                                PAYMENT_SCHEDULE_BK
      , PAYMENT_SCHEDULE_ID
      , SECOND_LAST_CHARGE_DATE
      , ORG_ID
      , AMOUNT_DUE_ORIGINAL
      , AMOUNT_ADJUSTED
      , CASH_RECEIPT_ID
      , RECEIPT_CONFIRMED_FLAG
      , ASSOCIATED_CASH_RECEIPT_ID
      , AMOUNT_CREDITED
      , GLOBAL_ATTRIBUTE5
      , ACTUAL_DATE_CLOSED
      , GLOBAL_ATTRIBUTE4
      , GLOBAL_ATTRIBUTE7
      , GLOBAL_ATTRIBUTE6
      , AMOUNT_APPLIED
      , GLOBAL_ATTRIBUTE1
      , TRX_DATE
      , GLOBAL_ATTRIBUTE3
      , GLOBAL_ATTRIBUTE2
      , CASH_APPLIED_ID_LAST
      , CUSTOMER_SITE_USE_ID
      , GLOBAL_ATTRIBUTE9
      , GLOBAL_ATTRIBUTE8
      , ATTRIBUTE3
      , ATTRIBUTE2
      , ATTRIBUTE1
      , BR_AMOUNT_ASSIGNED
      , COLLECTOR_LAST
      , RESERVED_TYPE
      , MRC_ACCTD_AMOUNT_DUE_REMAINING
      , ATTRIBUTE9
      , ADJUSTMENT_AMOUNT_LAST
      , ATTRIBUTE8
      , ATTRIBUTE7
      , ATTRIBUTE6
      , GL_DATE
      , ATTRIBUTE5
      , MRC_EXCHANGE_RATE_TYPE
      , ATTRIBUTE4
      , CASH_GL_DATE_LAST
      , PROMISE_AMOUNT_LAST
      , GL_DATE_CLOSED
      , TERM_ID
      , ATTRIBUTE10
      , ATTRIBUTE14
      , ATTRIBUTE13
      , ATTRIBUTE12
      , ATTRIBUTE11
      , RECEIVABLES_CHARGES_CHARGED
      , TRX_NUMBER
      , CASH_RECEIPT_ID_LAST
      , FREIGHT_ORIGINAL
      , LAST_UNACCRUE_CHRG_DATE
      , PROMISE_DATE_LAST
      , PAYMENT_APPROVAL
      , MRC_EXCHANGE_DATE
      , DISCOUNT_ORIGINAL
      , MRC_EXCHANGE_RATE
      , TERMS_SEQUENCE_NUMBER
      , DISCOUNT_DATE
      , DUE_DATE
      , AMOUNT_ADJUSTED_PENDING
      , RECEIVABLES_CHARGES_REMAINING
      , CASH_APPLIED_STATUS_LAST
      , NUMBER_OF_DUE_DATES
      , DISPUTE_DATE
      , GLOBAL_ATTRIBUTE20
      , CASH_RECEIPT_DATE_LAST
      , SELECTED_FOR_RECEIPT_BATCH_ID
      , DISCOUNT_TAKEN_EARNED
      , DISCOUNT_REMAINING
      , GLOBAL_ATTRIBUTE17
      , GLOBAL_ATTRIBUTE18
      , GLOBAL_ATTRIBUTE15
      , FOLLOW_UP_DATE_LAST
      , GLOBAL_ATTRIBUTE16
      , GLOBAL_ATTRIBUTE13
      , GLOBAL_ATTRIBUTE14
      , GLOBAL_ATTRIBUTE11
      , MRC_CUSTOMER_TRX_ID
      , GLOBAL_ATTRIBUTE12
      , ATTRIBUTE15
      , INVOICE_CURRENCY_CODE
      , ADJUSTMENT_GL_DATE_LAST
      , GLOBAL_ATTRIBUTE19
      , REVERSED_CASH_RECEIPT_ID
      , EXCLUDE_FROM_CONS_BILL_FLAG
      , IN_COLLECTION
      , GLOBAL_ATTRIBUTE10
      , CASH_APPLIED_AMOUNT_LAST
      , EXCLUDE_FROM_DUNNING_FLAG
      , CLASS
      , SECOND_LAST_UNACCRUE_CHRG_DT
      , RESERVED_VALUE
      , STATUS
      , DISCOUNT_TAKEN_UNEARNED
      , EXCHANGE_DATE
      , ACCTD_AMOUNT_DUE_REMAINING
      , ADJUSTMENT_DATE_LAST
      , AMOUNT_LINE_ITEMS_ORIGINAL
      , CASH_RECEIPT_AMOUNT_LAST
      , CASH_APPLIED_DATE_LAST
      , AMOUNT_DUE_REMAINING
      , EXCHANGE_RATE
      , CUSTOMER_ID
      , FREIGHT_REMAINING
      , ATTRIBUTE_CATEGORY
      , FOLLOW_UP_CODE_LAST
      , AMOUNT_LINE_ITEMS_REMAINING
      , CONS_INV_ID
      , CONS_INV_ID_REV
      , CASH_RECEIPT_STATUS_LAST
      , TAX_REMAINING
      , CALL_DATE_LAST
      , DUNNING_LEVEL_OVERRIDE_DATE
      , CUST_TRX_TYPE_ID
      , TAX_ORIGINAL
      , EXCHANGE_RATE_TYPE
      , ACTIVE_CLAIM_FLAG
      , CUSTOMER_TRX_ID
      , AMOUNT_IN_DISPUTE
      , GLOBAL_ATTRIBUTE_CATEGORY
      , STAGED_DUNNING_LEVEL
      , ADJUSTMENT_ID_LAST
      , LAST_CHARGE_DATE
      , CREATED_BY
      , CREATION_DATE
      , LAST_UPDATED_BY
      , LAST_UPDATE_DATE
      , LAST_UPDATE_LOGIN
      , REQUEST_ID
      , PROGRAM_APPLICATION_ID
      , PROGRAM_ID
      , PROGRAM_UPDATE_DATE
      , _FIVETRAN_DELETED
      , _FIVETRAN_ID
      , _FIVETRAN_SYNCED
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED )                   as                                           LOAD_DTS
      , to_char(coalesce(CUSTOMER_TRX_ID,'-2'))                      as                                         INVOICE_BK
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
        PAYMENT_SCHEDULE_BK
      , PAYMENT_SCHEDULE_ID
      , SECOND_LAST_CHARGE_DATE
      , ORG_ID
      , AMOUNT_DUE_ORIGINAL
      , AMOUNT_ADJUSTED
      , CASH_RECEIPT_ID
      , RECEIPT_CONFIRMED_FLAG
      , ASSOCIATED_CASH_RECEIPT_ID
      , AMOUNT_CREDITED
      , GLOBAL_ATTRIBUTE5
      , ACTUAL_DATE_CLOSED
      , GLOBAL_ATTRIBUTE4
      , GLOBAL_ATTRIBUTE7
      , GLOBAL_ATTRIBUTE6
      , AMOUNT_APPLIED
      , GLOBAL_ATTRIBUTE1
      , TRX_DATE
      , GLOBAL_ATTRIBUTE3
      , GLOBAL_ATTRIBUTE2
      , CASH_APPLIED_ID_LAST
      , CUSTOMER_SITE_USE_ID
      , GLOBAL_ATTRIBUTE9
      , GLOBAL_ATTRIBUTE8
      , ATTRIBUTE3
      , ATTRIBUTE2
      , ATTRIBUTE1
      , BR_AMOUNT_ASSIGNED
      , COLLECTOR_LAST
      , RESERVED_TYPE
      , MRC_ACCTD_AMOUNT_DUE_REMAINING
      , ATTRIBUTE9
      , ADJUSTMENT_AMOUNT_LAST
      , ATTRIBUTE8
      , ATTRIBUTE7
      , ATTRIBUTE6
      , GL_DATE
      , ATTRIBUTE5
      , MRC_EXCHANGE_RATE_TYPE
      , ATTRIBUTE4
      , CASH_GL_DATE_LAST
      , PROMISE_AMOUNT_LAST
      , GL_DATE_CLOSED
      , TERM_ID
      , ATTRIBUTE10
      , ATTRIBUTE14
      , ATTRIBUTE13
      , ATTRIBUTE12
      , ATTRIBUTE11
      , RECEIVABLES_CHARGES_CHARGED
      , TRX_NUMBER
      , CASH_RECEIPT_ID_LAST
      , FREIGHT_ORIGINAL
      , LAST_UNACCRUE_CHRG_DATE
      , PROMISE_DATE_LAST
      , PAYMENT_APPROVAL
      , MRC_EXCHANGE_DATE
      , DISCOUNT_ORIGINAL
      , MRC_EXCHANGE_RATE
      , TERMS_SEQUENCE_NUMBER
      , DISCOUNT_DATE
      , DUE_DATE
      , AMOUNT_ADJUSTED_PENDING
      , RECEIVABLES_CHARGES_REMAINING
      , CASH_APPLIED_STATUS_LAST
      , NUMBER_OF_DUE_DATES
      , DISPUTE_DATE
      , GLOBAL_ATTRIBUTE20
      , CASH_RECEIPT_DATE_LAST
      , SELECTED_FOR_RECEIPT_BATCH_ID
      , DISCOUNT_TAKEN_EARNED
      , DISCOUNT_REMAINING
      , GLOBAL_ATTRIBUTE17
      , GLOBAL_ATTRIBUTE18
      , GLOBAL_ATTRIBUTE15
      , FOLLOW_UP_DATE_LAST
      , GLOBAL_ATTRIBUTE16
      , GLOBAL_ATTRIBUTE13
      , GLOBAL_ATTRIBUTE14
      , GLOBAL_ATTRIBUTE11
      , MRC_CUSTOMER_TRX_ID
      , GLOBAL_ATTRIBUTE12
      , ATTRIBUTE15
      , INVOICE_CURRENCY_CODE
      , ADJUSTMENT_GL_DATE_LAST
      , GLOBAL_ATTRIBUTE19
      , REVERSED_CASH_RECEIPT_ID
      , EXCLUDE_FROM_CONS_BILL_FLAG
      , IN_COLLECTION
      , GLOBAL_ATTRIBUTE10
      , CASH_APPLIED_AMOUNT_LAST
      , EXCLUDE_FROM_DUNNING_FLAG
      , CLASS
      , SECOND_LAST_UNACCRUE_CHRG_DT
      , RESERVED_VALUE
      , STATUS
      , DISCOUNT_TAKEN_UNEARNED
      , EXCHANGE_DATE
      , ACCTD_AMOUNT_DUE_REMAINING
      , ADJUSTMENT_DATE_LAST
      , AMOUNT_LINE_ITEMS_ORIGINAL
      , CASH_RECEIPT_AMOUNT_LAST
      , CASH_APPLIED_DATE_LAST
      , AMOUNT_DUE_REMAINING
      , EXCHANGE_RATE
      , CUSTOMER_ID
      , FREIGHT_REMAINING
      , ATTRIBUTE_CATEGORY
      , FOLLOW_UP_CODE_LAST
      , AMOUNT_LINE_ITEMS_REMAINING
      , CONS_INV_ID
      , CONS_INV_ID_REV
      , CASH_RECEIPT_STATUS_LAST
      , TAX_REMAINING
      , CALL_DATE_LAST
      , DUNNING_LEVEL_OVERRIDE_DATE
      , CUST_TRX_TYPE_ID
      , TAX_ORIGINAL
      , EXCHANGE_RATE_TYPE
      , ACTIVE_CLAIM_FLAG
      , CUSTOMER_TRX_ID
      , AMOUNT_IN_DISPUTE
      , GLOBAL_ATTRIBUTE_CATEGORY
      , STAGED_DUNNING_LEVEL
      , ADJUSTMENT_ID_LAST
      , LAST_CHARGE_DATE
      , CREATED_BY
      , CREATION_DATE
      , LAST_UPDATED_BY
      , LAST_UPDATE_DATE
      , LAST_UPDATE_LOGIN
      , REQUEST_ID
      , PROGRAM_APPLICATION_ID
      , PROGRAM_ID
      , PROGRAM_UPDATE_DATE
      , _FIVETRAN_DELETED
      , _FIVETRAN_ID
      , _FIVETRAN_SYNCED
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , LOAD_DTS
      , INVOICE_BK
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
    WHERE rec_src = 'USWIOC.ORCL.EBSPRD.PAYMENT_SCHEDULES_ALL'

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
          PAYMENT_SCHEDULE_BK
        , PAYMENT_SCHEDULE_ID
        , SECOND_LAST_CHARGE_DATE
        , ORG_ID
        , AMOUNT_DUE_ORIGINAL
        , AMOUNT_ADJUSTED
        , CASH_RECEIPT_ID
        , RECEIPT_CONFIRMED_FLAG
        , ASSOCIATED_CASH_RECEIPT_ID
        , AMOUNT_CREDITED
        , GLOBAL_ATTRIBUTE5
        , ACTUAL_DATE_CLOSED
        , GLOBAL_ATTRIBUTE4
        , GLOBAL_ATTRIBUTE7
        , GLOBAL_ATTRIBUTE6
        , AMOUNT_APPLIED
        , GLOBAL_ATTRIBUTE1
        , TRX_DATE
        , GLOBAL_ATTRIBUTE3
        , GLOBAL_ATTRIBUTE2
        , CASH_APPLIED_ID_LAST
        , CUSTOMER_SITE_USE_ID
        , GLOBAL_ATTRIBUTE9
        , GLOBAL_ATTRIBUTE8
        , ATTRIBUTE3
        , ATTRIBUTE2
        , ATTRIBUTE1
        , BR_AMOUNT_ASSIGNED
        , COLLECTOR_LAST
        , RESERVED_TYPE
        , MRC_ACCTD_AMOUNT_DUE_REMAINING
        , ATTRIBUTE9
        , ADJUSTMENT_AMOUNT_LAST
        , ATTRIBUTE8
        , ATTRIBUTE7
        , ATTRIBUTE6
        , GL_DATE
        , ATTRIBUTE5
        , MRC_EXCHANGE_RATE_TYPE
        , ATTRIBUTE4
        , CASH_GL_DATE_LAST
        , PROMISE_AMOUNT_LAST
        , GL_DATE_CLOSED
        , TERM_ID
        , ATTRIBUTE10
        , ATTRIBUTE14
        , ATTRIBUTE13
        , ATTRIBUTE12
        , ATTRIBUTE11
        , RECEIVABLES_CHARGES_CHARGED
        , TRX_NUMBER
        , CASH_RECEIPT_ID_LAST
        , FREIGHT_ORIGINAL
        , LAST_UNACCRUE_CHRG_DATE
        , PROMISE_DATE_LAST
        , PAYMENT_APPROVAL
        , MRC_EXCHANGE_DATE
        , DISCOUNT_ORIGINAL
        , MRC_EXCHANGE_RATE
        , TERMS_SEQUENCE_NUMBER
        , DISCOUNT_DATE
        , DUE_DATE
        , AMOUNT_ADJUSTED_PENDING
        , RECEIVABLES_CHARGES_REMAINING
        , CASH_APPLIED_STATUS_LAST
        , NUMBER_OF_DUE_DATES
        , DISPUTE_DATE
        , GLOBAL_ATTRIBUTE20
        , CASH_RECEIPT_DATE_LAST
        , SELECTED_FOR_RECEIPT_BATCH_ID
        , DISCOUNT_TAKEN_EARNED
        , DISCOUNT_REMAINING
        , GLOBAL_ATTRIBUTE17
        , GLOBAL_ATTRIBUTE18
        , GLOBAL_ATTRIBUTE15
        , FOLLOW_UP_DATE_LAST
        , GLOBAL_ATTRIBUTE16
        , GLOBAL_ATTRIBUTE13
        , GLOBAL_ATTRIBUTE14
        , GLOBAL_ATTRIBUTE11
        , MRC_CUSTOMER_TRX_ID
        , GLOBAL_ATTRIBUTE12
        , ATTRIBUTE15
        , INVOICE_CURRENCY_CODE
        , ADJUSTMENT_GL_DATE_LAST
        , GLOBAL_ATTRIBUTE19
        , REVERSED_CASH_RECEIPT_ID
        , EXCLUDE_FROM_CONS_BILL_FLAG
        , IN_COLLECTION
        , GLOBAL_ATTRIBUTE10
        , CASH_APPLIED_AMOUNT_LAST
        , EXCLUDE_FROM_DUNNING_FLAG
        , CLASS
        , SECOND_LAST_UNACCRUE_CHRG_DT
        , RESERVED_VALUE
        , STATUS
        , DISCOUNT_TAKEN_UNEARNED
        , EXCHANGE_DATE
        , ACCTD_AMOUNT_DUE_REMAINING
        , ADJUSTMENT_DATE_LAST
        , AMOUNT_LINE_ITEMS_ORIGINAL
        , CASH_RECEIPT_AMOUNT_LAST
        , CASH_APPLIED_DATE_LAST
        , AMOUNT_DUE_REMAINING
        , EXCHANGE_RATE
        , CUSTOMER_ID
        , FREIGHT_REMAINING
        , ATTRIBUTE_CATEGORY
        , FOLLOW_UP_CODE_LAST
        , AMOUNT_LINE_ITEMS_REMAINING
        , CONS_INV_ID
        , CONS_INV_ID_REV
        , CASH_RECEIPT_STATUS_LAST
        , TAX_REMAINING
        , CALL_DATE_LAST
        , DUNNING_LEVEL_OVERRIDE_DATE
        , CUST_TRX_TYPE_ID
        , TAX_ORIGINAL
        , EXCHANGE_RATE_TYPE
        , ACTIVE_CLAIM_FLAG
        , CUSTOMER_TRX_ID
        , AMOUNT_IN_DISPUTE
        , GLOBAL_ATTRIBUTE_CATEGORY
        , STAGED_DUNNING_LEVEL
        , ADJUSTMENT_ID_LAST
        , LAST_CHARGE_DATE
        , CREATED_BY
        , CREATION_DATE
        , LAST_UPDATED_BY
        , LAST_UPDATE_DATE
        , LAST_UPDATE_LOGIN
        , REQUEST_ID
        , PROGRAM_APPLICATION_ID
        , PROGRAM_ID
        , PROGRAM_UPDATE_DATE
        , _FIVETRAN_DELETED
        , _FIVETRAN_ID
        , _FIVETRAN_SYNCED
        , PSA_DELETE_IND
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , INVOICE_BK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PAYMENT_SCHEDULE_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PAYMENT_SCHEDULE_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(INVOICE_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as INVOICE_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PAYMENT_SCHEDULE_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(CUSTOMER_TRX_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as INVOICE_PAYMENT_SCHEDULE_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(SECOND_LAST_CHARGE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(ORG_ID::text), '^^') 
            , '||', IFNULL(TRIM(AMOUNT_DUE_ORIGINAL::text), '^^') 
            , '||', IFNULL(TRIM(AMOUNT_ADJUSTED::text), '^^') 
            , '||', IFNULL(TRIM(RECEIPT_CONFIRMED_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(ASSOCIATED_CASH_RECEIPT_ID::text), '^^') 
            , '||', IFNULL(TRIM(AMOUNT_CREDITED::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE5::text), '^^') 
            , '||', IFNULL(TRIM(ACTUAL_DATE_CLOSED::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE4::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE7::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE6::text), '^^') 
            , '||', IFNULL(TRIM(AMOUNT_APPLIED::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE1::text), '^^') 
            , '||', IFNULL(TRIM(TRX_DATE::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE3::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE2::text), '^^') 
            , '||', IFNULL(TRIM(CASH_APPLIED_ID_LAST::text), '^^') 
            , '||', IFNULL(TRIM(CUSTOMER_SITE_USE_ID::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE9::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE8::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE3::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE2::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE1::text), '^^') 
            , '||', IFNULL(TRIM(BR_AMOUNT_ASSIGNED::text), '^^') 
            , '||', IFNULL(TRIM(COLLECTOR_LAST::text), '^^') 
            , '||', IFNULL(TRIM(RESERVED_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(MRC_ACCTD_AMOUNT_DUE_REMAINING::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE9::text), '^^') 
            , '||', IFNULL(TRIM(ADJUSTMENT_AMOUNT_LAST::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE8::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE7::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE6::text), '^^') 
            , '||', IFNULL(TRIM(GL_DATE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE5::text), '^^') 
            , '||', IFNULL(TRIM(MRC_EXCHANGE_RATE_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE4::text), '^^') 
            , '||', IFNULL(TRIM(CASH_GL_DATE_LAST::text), '^^') 
            , '||', IFNULL(TRIM(PROMISE_AMOUNT_LAST::text), '^^') 
            , '||', IFNULL(TRIM(GL_DATE_CLOSED::text), '^^') 
            , '||', IFNULL(TRIM(TERM_ID::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE10::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE14::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE13::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE12::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE11::text), '^^') 
            , '||', IFNULL(TRIM(RECEIVABLES_CHARGES_CHARGED::text), '^^') 
            , '||', IFNULL(TRIM(TRX_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(CASH_RECEIPT_ID_LAST::text), '^^') 
            , '||', IFNULL(TRIM(FREIGHT_ORIGINAL::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UNACCRUE_CHRG_DATE::text), '^^') 
            , '||', IFNULL(TRIM(PROMISE_DATE_LAST::text), '^^') 
            , '||', IFNULL(TRIM(PAYMENT_APPROVAL::text), '^^') 
            , '||', IFNULL(TRIM(MRC_EXCHANGE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(DISCOUNT_ORIGINAL::text), '^^') 
            , '||', IFNULL(TRIM(MRC_EXCHANGE_RATE::text), '^^') 
            , '||', IFNULL(TRIM(TERMS_SEQUENCE_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(DISCOUNT_DATE::text), '^^') 
            , '||', IFNULL(TRIM(DUE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(AMOUNT_ADJUSTED_PENDING::text), '^^') 
            , '||', IFNULL(TRIM(RECEIVABLES_CHARGES_REMAINING::text), '^^') 
            , '||', IFNULL(TRIM(CASH_APPLIED_STATUS_LAST::text), '^^') 
            , '||', IFNULL(TRIM(NUMBER_OF_DUE_DATES::text), '^^') 
            , '||', IFNULL(TRIM(DISPUTE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE20::text), '^^') 
            , '||', IFNULL(TRIM(CASH_RECEIPT_DATE_LAST::text), '^^') 
            , '||', IFNULL(TRIM(SELECTED_FOR_RECEIPT_BATCH_ID::text), '^^') 
            , '||', IFNULL(TRIM(DISCOUNT_TAKEN_EARNED::text), '^^') 
            , '||', IFNULL(TRIM(DISCOUNT_REMAINING::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE17::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE18::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE15::text), '^^') 
            , '||', IFNULL(TRIM(FOLLOW_UP_DATE_LAST::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE16::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE13::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE14::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE11::text), '^^') 
            , '||', IFNULL(TRIM(MRC_CUSTOMER_TRX_ID::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE12::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE15::text), '^^') 
            , '||', IFNULL(TRIM(INVOICE_CURRENCY_CODE::text), '^^') 
            , '||', IFNULL(TRIM(ADJUSTMENT_GL_DATE_LAST::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE19::text), '^^') 
            , '||', IFNULL(TRIM(REVERSED_CASH_RECEIPT_ID::text), '^^') 
            , '||', IFNULL(TRIM(EXCLUDE_FROM_CONS_BILL_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(IN_COLLECTION::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE10::text), '^^') 
            , '||', IFNULL(TRIM(CASH_APPLIED_AMOUNT_LAST::text), '^^') 
            , '||', IFNULL(TRIM(EXCLUDE_FROM_DUNNING_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(CLASS::text), '^^') 
            , '||', IFNULL(TRIM(SECOND_LAST_UNACCRUE_CHRG_DT::text), '^^') 
            , '||', IFNULL(TRIM(RESERVED_VALUE::text), '^^') 
            , '||', IFNULL(TRIM(STATUS::text), '^^') 
            , '||', IFNULL(TRIM(DISCOUNT_TAKEN_UNEARNED::text), '^^') 
            , '||', IFNULL(TRIM(EXCHANGE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(ACCTD_AMOUNT_DUE_REMAINING::text), '^^') 
            , '||', IFNULL(TRIM(ADJUSTMENT_DATE_LAST::text), '^^') 
            , '||', IFNULL(TRIM(AMOUNT_LINE_ITEMS_ORIGINAL::text), '^^') 
            , '||', IFNULL(TRIM(CASH_RECEIPT_AMOUNT_LAST::text), '^^') 
            , '||', IFNULL(TRIM(CASH_APPLIED_DATE_LAST::text), '^^') 
            , '||', IFNULL(TRIM(AMOUNT_DUE_REMAINING::text), '^^') 
            , '||', IFNULL(TRIM(EXCHANGE_RATE::text), '^^') 
            , '||', IFNULL(TRIM(CUSTOMER_ID::text), '^^') 
            , '||', IFNULL(TRIM(FREIGHT_REMAINING::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(FOLLOW_UP_CODE_LAST::text), '^^') 
            , '||', IFNULL(TRIM(AMOUNT_LINE_ITEMS_REMAINING::text), '^^') 
            , '||', IFNULL(TRIM(CONS_INV_ID::text), '^^') 
            , '||', IFNULL(TRIM(CONS_INV_ID_REV::text), '^^') 
            , '||', IFNULL(TRIM(CASH_RECEIPT_STATUS_LAST::text), '^^') 
            , '||', IFNULL(TRIM(TAX_REMAINING::text), '^^') 
            , '||', IFNULL(TRIM(CALL_DATE_LAST::text), '^^') 
            , '||', IFNULL(TRIM(DUNNING_LEVEL_OVERRIDE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(CUST_TRX_TYPE_ID::text), '^^') 
            , '||', IFNULL(TRIM(TAX_ORIGINAL::text), '^^') 
            , '||', IFNULL(TRIM(EXCHANGE_RATE_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(ACTIVE_CLAIM_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(CUSTOMER_TRX_ID::text), '^^') 
            , '||', IFNULL(TRIM(AMOUNT_IN_DISPUTE::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(STAGED_DUNNING_LEVEL::text), '^^') 
            , '||', IFNULL(TRIM(ADJUSTMENT_ID_LAST::text), '^^') 
            , '||', IFNULL(TRIM(LAST_CHARGE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(CREATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(CREATION_DATE::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_LOGIN::text), '^^') 
            , '||', IFNULL(TRIM(REQUEST_ID::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_APPLICATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_ID::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_UPDATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
