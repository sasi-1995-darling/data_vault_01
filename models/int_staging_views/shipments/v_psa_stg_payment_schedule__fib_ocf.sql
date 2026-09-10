---- SRC LAYER ----
WITH
SRC_S              as ( SELECT * FROM {{ source('outd_ocf_ar', 'ar_payment_schedules_all') }} as SRC  ),
SRC_A              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S              as ( SELECT * FROM outd_ocf_ar.ar_payment_schedules_all )
, SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        TO_CHAR(PAYMENT_SCHEDULE_ID)                                 as                                PAYMENT_SCHEDULE_BK
      , PAYMENT_SCHEDULE_ID
      , COLLECTION_BASED_FORECAST_AMT
      , CALL_DATE_LAST
      , TRX_NUMBER
      , ADJUSTMENT_AMOUNT_LAST
      , FOLLOW_UP_DATE_LAST
      , FOLLOW_UP_CODE_LAST
      , PROMISE_DATE_LAST
      , PROMISE_AMOUNT_LAST
      , COLLECTOR_LAST
      , TRX_DATE
      , FREIGHT_ORIGINAL
      , FREIGHT_REMAINING
      , TAX_ORIGINAL
      , TAX_REMAINING
      , DISCOUNT_ORIGINAL
      , DUE_DATE
      , AMOUNT_DUE_ORIGINAL
      , AMOUNT_DUE_REMAINING
      , NUMBER_OF_DUE_DATES
      , STATUS
      , INVOICE_CURRENCY_CODE
      , CLASS
      , CUSTOMER_ID
      , CUSTOMER_SITE_USE_ID
      , CUSTOMER_TRX_ID
      , CASH_RECEIPT_ID
      , ASSOCIATED_CASH_RECEIPT_ID
      , TERM_ID
      , MODULE_ID
      , AMOUNT_ON_ACCOUNT
      , AMOUNT_OTHER_ACCOUNT
      , STAGED_DUNNING_LEVEL
      , DUNNING_LEVEL_OVERRIDE_DATE
      , LAST_UPDATE_DATE
      , LAST_UPDATED_BY
      , CREATION_DATE
      , CREATED_BY
      , LAST_UPDATE_LOGIN
      , TERMS_SEQUENCE_NUMBER
      , GL_DATE_CLOSED
      , ACTUAL_DATE_CLOSED
      , DISCOUNT_DATE
      , AMOUNT_LINE_ITEMS_ORIGINAL
      , AMOUNT_ADJUSTED
      , AMOUNT_IN_DISPUTE
      , AMOUNT_CREDITED
      , AMOUNT_LINE_ITEMS_REMAINING
      , AMOUNT_APPLIED
      , RECEIVABLES_CHARGES_CHARGED
      , RECEIVABLES_CHARGES_REMAINING
      , LEGAL_ENTITY_ID
      , COLLECTION_BASED_FORECAST_DATE
      , GLOBAL_ATTRIBUTE_CATEGORY
      , CONS_INV_ID
      , GLOBAL_ATTRIBUTE_NUMBER_2
      , EXPECTED_COLLECTION_AMOUNT
      , EXPECTED_COLLECTION_DATE
      , PROGRAM_APPLICATION_ID
      , PROGRAM_ID
      , GLOBAL_ATTRIBUTE_11
      , GLOBAL_ATTRIBUTE_12
      , GLOBAL_ATTRIBUTE_13
      , GLOBAL_ATTRIBUTE_14
      , GLOBAL_ATTRIBUTE_15
      , GLOBAL_ATTRIBUTE_16
      , GLOBAL_ATTRIBUTE_17
      , GLOBAL_ATTRIBUTE_18
      , GLOBAL_ATTRIBUTE_19
      , CONS_INV_ID_REV
      , EXCLUDE_FROM_DUNNING_FLAG
      , BR_AMOUNT_ASSIGNED
      , RESERVED_TYPE
      , RESERVED_VALUE
      , ACTIVE_CLAIM_FLAG
      , EXCLUDE_FROM_CONS_BILL_FLAG
      , PAYMENT_APPROVAL
      , OBJECT_VERSION_NUMBER
      , CUST_TRX_TYPE_SEQ_ID
      , GLOBAL_ATTRIBUTE_NUMBER_1
      , DISCOUNT_REMAINING
      , DISCOUNT_TAKEN_EARNED
      , DISCOUNT_TAKEN_UNEARNED
      , IN_COLLECTION
      , CASH_APPLIED_ID_LAST
      , CASH_APPLIED_DATE_LAST
      , CASH_APPLIED_AMOUNT_LAST
      , CASH_APPLIED_STATUS_LAST
      , CASH_GL_DATE_LAST
      , CASH_RECEIPT_ID_LAST
      , CASH_RECEIPT_DATE_LAST
      , CASH_RECEIPT_AMOUNT_LAST
      , CASH_RECEIPT_STATUS_LAST
      , EXCHANGE_RATE_TYPE
      , EXCHANGE_DATE
      , EXCHANGE_RATE
      , GLOBAL_ATTRIBUTE_20
      , REVERSED_CASH_RECEIPT_ID
      , AMOUNT_ADJUSTED_PENDING
      , ATTRIBUTE_11
      , ATTRIBUTE_12
      , ATTRIBUTE_13
      , ATTRIBUTE_9
      , ATTRIBUTE_10
      , ATTRIBUTE_15
      , GL_DATE
      , ACCTD_AMOUNT_DUE_REMAINING
      , ATTRIBUTE_14
      , ATTRIBUTE_4
      , ATTRIBUTE_5
      , ATTRIBUTE_6
      , ATTRIBUTE_7
      , ATTRIBUTE_8
      , DISPUTE_DATE
      , ORG_ID
      , GLOBAL_ATTRIBUTE_1
      , GLOBAL_ATTRIBUTE_2
      , GLOBAL_ATTRIBUTE_3
      , GLOBAL_ATTRIBUTE_4
      , ATTRIBUTE_CATEGORY
      , ATTRIBUTE_1
      , ATTRIBUTE_2
      , PROGRAM_UPDATE_DATE
      , RECEIPT_CONFIRMED_FLAG
      , REQUEST_ID
      , SELECTED_FOR_RECEIPT_BATCH_ID
      , LAST_CHARGE_DATE
      , SECOND_LAST_CHARGE_DATE
      , GLOBAL_ATTRIBUTE_5
      , GLOBAL_ATTRIBUTE_6
      , GLOBAL_ATTRIBUTE_7
      , GLOBAL_ATTRIBUTE_8
      , GLOBAL_ATTRIBUTE_9
      , GLOBAL_ATTRIBUTE_10
      , ATTRIBUTE_3
      , ADJUSTMENT_ID_LAST
      , ADJUSTMENT_DATE_LAST
      , ADJUSTMENT_GL_DATE_LAST
      , GLOBAL_ATTRIBUTE_NUMBER_3
      , GLOBAL_ATTRIBUTE_NUMBER_4
      , GLOBAL_ATTRIBUTE_NUMBER_5
      , GLOBAL_ATTRIBUTE_DATE_1
      , GLOBAL_ATTRIBUTE_DATE_2
      , GLOBAL_ATTRIBUTE_DATE_3
      , GLOBAL_ATTRIBUTE_DATE_4
      , GLOBAL_ATTRIBUTE_DATE_5
      , DEL_CONTACT_EMAIL_ADDRESS
      , PRINT_REQUEST_ID
      , SEED_DATA_SOURCE
      , _FIVETRAN_SYNCED
      , _FIVETRAN_DELETED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , to_char(coalesce(CUSTOMER_TRX_ID,'-2'))                      as                                         INVOICE_BK
      , CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED )                   as                                           LOAD_DTS
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
      , COLLECTION_BASED_FORECAST_AMT
      , CALL_DATE_LAST
      , TRX_NUMBER
      , ADJUSTMENT_AMOUNT_LAST
      , FOLLOW_UP_DATE_LAST
      , FOLLOW_UP_CODE_LAST
      , PROMISE_DATE_LAST
      , PROMISE_AMOUNT_LAST
      , COLLECTOR_LAST
      , TRX_DATE
      , FREIGHT_ORIGINAL
      , FREIGHT_REMAINING
      , TAX_ORIGINAL
      , TAX_REMAINING
      , DISCOUNT_ORIGINAL
      , DUE_DATE
      , AMOUNT_DUE_ORIGINAL
      , AMOUNT_DUE_REMAINING
      , NUMBER_OF_DUE_DATES
      , STATUS
      , INVOICE_CURRENCY_CODE
      , CLASS
      , CUSTOMER_ID
      , CUSTOMER_SITE_USE_ID
      , CUSTOMER_TRX_ID
      , CASH_RECEIPT_ID
      , ASSOCIATED_CASH_RECEIPT_ID
      , TERM_ID
      , MODULE_ID
      , AMOUNT_ON_ACCOUNT
      , AMOUNT_OTHER_ACCOUNT
      , STAGED_DUNNING_LEVEL
      , DUNNING_LEVEL_OVERRIDE_DATE
      , LAST_UPDATE_DATE
      , LAST_UPDATED_BY
      , CREATION_DATE
      , CREATED_BY
      , LAST_UPDATE_LOGIN
      , TERMS_SEQUENCE_NUMBER
      , GL_DATE_CLOSED
      , ACTUAL_DATE_CLOSED
      , DISCOUNT_DATE
      , AMOUNT_LINE_ITEMS_ORIGINAL
      , AMOUNT_ADJUSTED
      , AMOUNT_IN_DISPUTE
      , AMOUNT_CREDITED
      , AMOUNT_LINE_ITEMS_REMAINING
      , AMOUNT_APPLIED
      , RECEIVABLES_CHARGES_CHARGED
      , RECEIVABLES_CHARGES_REMAINING
      , LEGAL_ENTITY_ID
      , COLLECTION_BASED_FORECAST_DATE
      , GLOBAL_ATTRIBUTE_CATEGORY
      , CONS_INV_ID
      , GLOBAL_ATTRIBUTE_NUMBER_2
      , EXPECTED_COLLECTION_AMOUNT
      , EXPECTED_COLLECTION_DATE
      , PROGRAM_APPLICATION_ID
      , PROGRAM_ID
      , GLOBAL_ATTRIBUTE_11
      , GLOBAL_ATTRIBUTE_12
      , GLOBAL_ATTRIBUTE_13
      , GLOBAL_ATTRIBUTE_14
      , GLOBAL_ATTRIBUTE_15
      , GLOBAL_ATTRIBUTE_16
      , GLOBAL_ATTRIBUTE_17
      , GLOBAL_ATTRIBUTE_18
      , GLOBAL_ATTRIBUTE_19
      , CONS_INV_ID_REV
      , EXCLUDE_FROM_DUNNING_FLAG
      , BR_AMOUNT_ASSIGNED
      , RESERVED_TYPE
      , RESERVED_VALUE
      , ACTIVE_CLAIM_FLAG
      , EXCLUDE_FROM_CONS_BILL_FLAG
      , PAYMENT_APPROVAL
      , OBJECT_VERSION_NUMBER
      , CUST_TRX_TYPE_SEQ_ID
      , GLOBAL_ATTRIBUTE_NUMBER_1
      , DISCOUNT_REMAINING
      , DISCOUNT_TAKEN_EARNED
      , DISCOUNT_TAKEN_UNEARNED
      , IN_COLLECTION
      , CASH_APPLIED_ID_LAST
      , CASH_APPLIED_DATE_LAST
      , CASH_APPLIED_AMOUNT_LAST
      , CASH_APPLIED_STATUS_LAST
      , CASH_GL_DATE_LAST
      , CASH_RECEIPT_ID_LAST
      , CASH_RECEIPT_DATE_LAST
      , CASH_RECEIPT_AMOUNT_LAST
      , CASH_RECEIPT_STATUS_LAST
      , EXCHANGE_RATE_TYPE
      , EXCHANGE_DATE
      , EXCHANGE_RATE
      , GLOBAL_ATTRIBUTE_20
      , REVERSED_CASH_RECEIPT_ID
      , AMOUNT_ADJUSTED_PENDING
      , ATTRIBUTE_11
      , ATTRIBUTE_12
      , ATTRIBUTE_13
      , ATTRIBUTE_9
      , ATTRIBUTE_10
      , ATTRIBUTE_15
      , GL_DATE
      , ACCTD_AMOUNT_DUE_REMAINING
      , ATTRIBUTE_14
      , ATTRIBUTE_4
      , ATTRIBUTE_5
      , ATTRIBUTE_6
      , ATTRIBUTE_7
      , ATTRIBUTE_8
      , DISPUTE_DATE
      , ORG_ID
      , GLOBAL_ATTRIBUTE_1
      , GLOBAL_ATTRIBUTE_2
      , GLOBAL_ATTRIBUTE_3
      , GLOBAL_ATTRIBUTE_4
      , ATTRIBUTE_CATEGORY
      , ATTRIBUTE_1
      , ATTRIBUTE_2
      , PROGRAM_UPDATE_DATE
      , RECEIPT_CONFIRMED_FLAG
      , REQUEST_ID
      , SELECTED_FOR_RECEIPT_BATCH_ID
      , LAST_CHARGE_DATE
      , SECOND_LAST_CHARGE_DATE
      , GLOBAL_ATTRIBUTE_5
      , GLOBAL_ATTRIBUTE_6
      , GLOBAL_ATTRIBUTE_7
      , GLOBAL_ATTRIBUTE_8
      , GLOBAL_ATTRIBUTE_9
      , GLOBAL_ATTRIBUTE_10
      , ATTRIBUTE_3
      , ADJUSTMENT_ID_LAST
      , ADJUSTMENT_DATE_LAST
      , ADJUSTMENT_GL_DATE_LAST
      , GLOBAL_ATTRIBUTE_NUMBER_3
      , GLOBAL_ATTRIBUTE_NUMBER_4
      , GLOBAL_ATTRIBUTE_NUMBER_5
      , GLOBAL_ATTRIBUTE_DATE_1
      , GLOBAL_ATTRIBUTE_DATE_2
      , GLOBAL_ATTRIBUTE_DATE_3
      , GLOBAL_ATTRIBUTE_DATE_4
      , GLOBAL_ATTRIBUTE_DATE_5
      , DEL_CONTACT_EMAIL_ADDRESS
      , PRINT_REQUEST_ID
      , SEED_DATA_SOURCE
      , _FIVETRAN_SYNCED
      , _FIVETRAN_DELETED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , INVOICE_BK
      , LOAD_DTS
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
    WHERE rec_src = 'USCLOUD.ORCL.OCFPRD.AR_PAYMENT_SCHEDULES_ALL'
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
        , COLLECTION_BASED_FORECAST_AMT
        , CALL_DATE_LAST
        , TRX_NUMBER
        , ADJUSTMENT_AMOUNT_LAST
        , FOLLOW_UP_DATE_LAST
        , FOLLOW_UP_CODE_LAST
        , PROMISE_DATE_LAST
        , PROMISE_AMOUNT_LAST
        , COLLECTOR_LAST
        , TRX_DATE
        , FREIGHT_ORIGINAL
        , FREIGHT_REMAINING
        , TAX_ORIGINAL
        , TAX_REMAINING
        , DISCOUNT_ORIGINAL
        , DUE_DATE
        , AMOUNT_DUE_ORIGINAL
        , AMOUNT_DUE_REMAINING
        , NUMBER_OF_DUE_DATES
        , STATUS
        , INVOICE_CURRENCY_CODE
        , CLASS
        , CUSTOMER_ID
        , CUSTOMER_SITE_USE_ID
        , CUSTOMER_TRX_ID
        , CASH_RECEIPT_ID
        , ASSOCIATED_CASH_RECEIPT_ID
        , TERM_ID
        , MODULE_ID
        , AMOUNT_ON_ACCOUNT
        , AMOUNT_OTHER_ACCOUNT
        , STAGED_DUNNING_LEVEL
        , DUNNING_LEVEL_OVERRIDE_DATE
        , LAST_UPDATE_DATE
        , LAST_UPDATED_BY
        , CREATION_DATE
        , CREATED_BY
        , LAST_UPDATE_LOGIN
        , TERMS_SEQUENCE_NUMBER
        , GL_DATE_CLOSED
        , ACTUAL_DATE_CLOSED
        , DISCOUNT_DATE
        , AMOUNT_LINE_ITEMS_ORIGINAL
        , AMOUNT_ADJUSTED
        , AMOUNT_IN_DISPUTE
        , AMOUNT_CREDITED
        , AMOUNT_LINE_ITEMS_REMAINING
        , AMOUNT_APPLIED
        , RECEIVABLES_CHARGES_CHARGED
        , RECEIVABLES_CHARGES_REMAINING
        , LEGAL_ENTITY_ID
        , COLLECTION_BASED_FORECAST_DATE
        , GLOBAL_ATTRIBUTE_CATEGORY
        , CONS_INV_ID
        , GLOBAL_ATTRIBUTE_NUMBER_2
        , EXPECTED_COLLECTION_AMOUNT
        , EXPECTED_COLLECTION_DATE
        , PROGRAM_APPLICATION_ID
        , PROGRAM_ID
        , GLOBAL_ATTRIBUTE_11
        , GLOBAL_ATTRIBUTE_12
        , GLOBAL_ATTRIBUTE_13
        , GLOBAL_ATTRIBUTE_14
        , GLOBAL_ATTRIBUTE_15
        , GLOBAL_ATTRIBUTE_16
        , GLOBAL_ATTRIBUTE_17
        , GLOBAL_ATTRIBUTE_18
        , GLOBAL_ATTRIBUTE_19
        , CONS_INV_ID_REV
        , EXCLUDE_FROM_DUNNING_FLAG
        , BR_AMOUNT_ASSIGNED
        , RESERVED_TYPE
        , RESERVED_VALUE
        , ACTIVE_CLAIM_FLAG
        , EXCLUDE_FROM_CONS_BILL_FLAG
        , PAYMENT_APPROVAL
        , OBJECT_VERSION_NUMBER
        , CUST_TRX_TYPE_SEQ_ID
        , GLOBAL_ATTRIBUTE_NUMBER_1
        , DISCOUNT_REMAINING
        , DISCOUNT_TAKEN_EARNED
        , DISCOUNT_TAKEN_UNEARNED
        , IN_COLLECTION
        , CASH_APPLIED_ID_LAST
        , CASH_APPLIED_DATE_LAST
        , CASH_APPLIED_AMOUNT_LAST
        , CASH_APPLIED_STATUS_LAST
        , CASH_GL_DATE_LAST
        , CASH_RECEIPT_ID_LAST
        , CASH_RECEIPT_DATE_LAST
        , CASH_RECEIPT_AMOUNT_LAST
        , CASH_RECEIPT_STATUS_LAST
        , EXCHANGE_RATE_TYPE
        , EXCHANGE_DATE
        , EXCHANGE_RATE
        , GLOBAL_ATTRIBUTE_20
        , REVERSED_CASH_RECEIPT_ID
        , AMOUNT_ADJUSTED_PENDING
        , ATTRIBUTE_11
        , ATTRIBUTE_12
        , ATTRIBUTE_13
        , ATTRIBUTE_9
        , ATTRIBUTE_10
        , ATTRIBUTE_15
        , GL_DATE
        , ACCTD_AMOUNT_DUE_REMAINING
        , ATTRIBUTE_14
        , ATTRIBUTE_4
        , ATTRIBUTE_5
        , ATTRIBUTE_6
        , ATTRIBUTE_7
        , ATTRIBUTE_8
        , DISPUTE_DATE
        , ORG_ID
        , GLOBAL_ATTRIBUTE_1
        , GLOBAL_ATTRIBUTE_2
        , GLOBAL_ATTRIBUTE_3
        , GLOBAL_ATTRIBUTE_4
        , ATTRIBUTE_CATEGORY
        , ATTRIBUTE_1
        , ATTRIBUTE_2
        , PROGRAM_UPDATE_DATE
        , RECEIPT_CONFIRMED_FLAG
        , REQUEST_ID
        , SELECTED_FOR_RECEIPT_BATCH_ID
        , LAST_CHARGE_DATE
        , SECOND_LAST_CHARGE_DATE
        , GLOBAL_ATTRIBUTE_5
        , GLOBAL_ATTRIBUTE_6
        , GLOBAL_ATTRIBUTE_7
        , GLOBAL_ATTRIBUTE_8
        , GLOBAL_ATTRIBUTE_9
        , GLOBAL_ATTRIBUTE_10
        , ATTRIBUTE_3
        , ADJUSTMENT_ID_LAST
        , ADJUSTMENT_DATE_LAST
        , ADJUSTMENT_GL_DATE_LAST
        , GLOBAL_ATTRIBUTE_NUMBER_3
        , GLOBAL_ATTRIBUTE_NUMBER_4
        , GLOBAL_ATTRIBUTE_NUMBER_5
        , GLOBAL_ATTRIBUTE_DATE_1
        , GLOBAL_ATTRIBUTE_DATE_2
        , GLOBAL_ATTRIBUTE_DATE_3
        , GLOBAL_ATTRIBUTE_DATE_4
        , GLOBAL_ATTRIBUTE_DATE_5
        , DEL_CONTACT_EMAIL_ADDRESS
        , PRINT_REQUEST_ID
        , SEED_DATA_SOURCE
        , _FIVETRAN_SYNCED
        , _FIVETRAN_DELETED
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , INVOICE_BK
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , conditional_change_event(hash(* exclude(psa_load_dts, load_dts, _fivetran_synced))) over(partition by PAYMENT_SCHEDULE_BK order by _fivetran_synced) as CCE
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PAYMENT_SCHEDULE_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PAYMENT_SCHEDULE_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(INVOICE_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as INVOICE_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(INVOICE_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(PAYMENT_SCHEDULE_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as INVOICE_PAYMENT_SCHEDULE_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(PAYMENT_SCHEDULE_ID::text), '^^') 
            , '||', IFNULL(TRIM(COLLECTION_BASED_FORECAST_AMT::text), '^^') 
            , '||', IFNULL(TRIM(CALL_DATE_LAST::text), '^^') 
            , '||', IFNULL(TRIM(TRX_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(ADJUSTMENT_AMOUNT_LAST::text), '^^') 
            , '||', IFNULL(TRIM(FOLLOW_UP_DATE_LAST::text), '^^') 
            , '||', IFNULL(TRIM(FOLLOW_UP_CODE_LAST::text), '^^') 
            , '||', IFNULL(TRIM(PROMISE_DATE_LAST::text), '^^') 
            , '||', IFNULL(TRIM(PROMISE_AMOUNT_LAST::text), '^^') 
            , '||', IFNULL(TRIM(COLLECTOR_LAST::text), '^^') 
            , '||', IFNULL(TRIM(TRX_DATE::text), '^^') 
            , '||', IFNULL(TRIM(FREIGHT_ORIGINAL::text), '^^') 
            , '||', IFNULL(TRIM(FREIGHT_REMAINING::text), '^^') 
            , '||', IFNULL(TRIM(TAX_ORIGINAL::text), '^^') 
            , '||', IFNULL(TRIM(TAX_REMAINING::text), '^^') 
            , '||', IFNULL(TRIM(DISCOUNT_ORIGINAL::text), '^^') 
            , '||', IFNULL(TRIM(DUE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(AMOUNT_DUE_ORIGINAL::text), '^^') 
            , '||', IFNULL(TRIM(AMOUNT_DUE_REMAINING::text), '^^') 
            , '||', IFNULL(TRIM(NUMBER_OF_DUE_DATES::text), '^^') 
            , '||', IFNULL(TRIM(STATUS::text), '^^') 
            , '||', IFNULL(TRIM(INVOICE_CURRENCY_CODE::text), '^^') 
            , '||', IFNULL(TRIM(CLASS::text), '^^') 
            , '||', IFNULL(TRIM(CUSTOMER_ID::text), '^^') 
            , '||', IFNULL(TRIM(CUSTOMER_SITE_USE_ID::text), '^^') 
            , '||', IFNULL(TRIM(CUSTOMER_TRX_ID::text), '^^') 
            , '||', IFNULL(TRIM(CASH_RECEIPT_ID::text), '^^') 
            , '||', IFNULL(TRIM(ASSOCIATED_CASH_RECEIPT_ID::text), '^^') 
            , '||', IFNULL(TRIM(TERM_ID::text), '^^') 
            , '||', IFNULL(TRIM(MODULE_ID::text), '^^') 
            , '||', IFNULL(TRIM(AMOUNT_ON_ACCOUNT::text), '^^') 
            , '||', IFNULL(TRIM(AMOUNT_OTHER_ACCOUNT::text), '^^') 
            , '||', IFNULL(TRIM(STAGED_DUNNING_LEVEL::text), '^^') 
            , '||', IFNULL(TRIM(DUNNING_LEVEL_OVERRIDE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(CREATION_DATE::text), '^^') 
            , '||', IFNULL(TRIM(CREATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_LOGIN::text), '^^') 
            , '||', IFNULL(TRIM(TERMS_SEQUENCE_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(GL_DATE_CLOSED::text), '^^') 
            , '||', IFNULL(TRIM(ACTUAL_DATE_CLOSED::text), '^^') 
            , '||', IFNULL(TRIM(DISCOUNT_DATE::text), '^^') 
            , '||', IFNULL(TRIM(AMOUNT_LINE_ITEMS_ORIGINAL::text), '^^') 
            , '||', IFNULL(TRIM(AMOUNT_ADJUSTED::text), '^^') 
            , '||', IFNULL(TRIM(AMOUNT_IN_DISPUTE::text), '^^') 
            , '||', IFNULL(TRIM(AMOUNT_CREDITED::text), '^^') 
            , '||', IFNULL(TRIM(AMOUNT_LINE_ITEMS_REMAINING::text), '^^') 
            , '||', IFNULL(TRIM(AMOUNT_APPLIED::text), '^^') 
            , '||', IFNULL(TRIM(RECEIVABLES_CHARGES_CHARGED::text), '^^') 
            , '||', IFNULL(TRIM(RECEIVABLES_CHARGES_REMAINING::text), '^^') 
            , '||', IFNULL(TRIM(LEGAL_ENTITY_ID::text), '^^') 
            , '||', IFNULL(TRIM(COLLECTION_BASED_FORECAST_DATE::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(CONS_INV_ID::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_NUMBER_2::text), '^^') 
            , '||', IFNULL(TRIM(EXPECTED_COLLECTION_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(EXPECTED_COLLECTION_DATE::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_APPLICATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_ID::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_11::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_12::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_13::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_14::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_15::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_16::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_17::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_18::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_19::text), '^^') 
            , '||', IFNULL(TRIM(CONS_INV_ID_REV::text), '^^') 
            , '||', IFNULL(TRIM(EXCLUDE_FROM_DUNNING_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(BR_AMOUNT_ASSIGNED::text), '^^') 
            , '||', IFNULL(TRIM(RESERVED_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(RESERVED_VALUE::text), '^^') 
            , '||', IFNULL(TRIM(ACTIVE_CLAIM_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(EXCLUDE_FROM_CONS_BILL_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(PAYMENT_APPROVAL::text), '^^') 
            , '||', IFNULL(TRIM(OBJECT_VERSION_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(CUST_TRX_TYPE_SEQ_ID::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_NUMBER_1::text), '^^') 
            , '||', IFNULL(TRIM(DISCOUNT_REMAINING::text), '^^') 
            , '||', IFNULL(TRIM(DISCOUNT_TAKEN_EARNED::text), '^^') 
            , '||', IFNULL(TRIM(DISCOUNT_TAKEN_UNEARNED::text), '^^') 
            , '||', IFNULL(TRIM(IN_COLLECTION::text), '^^') 
            , '||', IFNULL(TRIM(CASH_APPLIED_ID_LAST::text), '^^') 
            , '||', IFNULL(TRIM(CASH_APPLIED_DATE_LAST::text), '^^') 
            , '||', IFNULL(TRIM(CASH_APPLIED_AMOUNT_LAST::text), '^^') 
            , '||', IFNULL(TRIM(CASH_APPLIED_STATUS_LAST::text), '^^') 
            , '||', IFNULL(TRIM(CASH_GL_DATE_LAST::text), '^^') 
            , '||', IFNULL(TRIM(CASH_RECEIPT_ID_LAST::text), '^^') 
            , '||', IFNULL(TRIM(CASH_RECEIPT_DATE_LAST::text), '^^') 
            , '||', IFNULL(TRIM(CASH_RECEIPT_AMOUNT_LAST::text), '^^') 
            , '||', IFNULL(TRIM(CASH_RECEIPT_STATUS_LAST::text), '^^') 
            , '||', IFNULL(TRIM(EXCHANGE_RATE_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(EXCHANGE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(EXCHANGE_RATE::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_20::text), '^^') 
            , '||', IFNULL(TRIM(REVERSED_CASH_RECEIPT_ID::text), '^^') 
            , '||', IFNULL(TRIM(AMOUNT_ADJUSTED_PENDING::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_11::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_12::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_13::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_9::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_10::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_15::text), '^^') 
            , '||', IFNULL(TRIM(GL_DATE::text), '^^') 
            , '||', IFNULL(TRIM(ACCTD_AMOUNT_DUE_REMAINING::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_14::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_4::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_5::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_6::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_7::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_8::text), '^^') 
            , '||', IFNULL(TRIM(DISPUTE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(ORG_ID::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_1::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_2::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_3::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_4::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_1::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_2::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_UPDATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(RECEIPT_CONFIRMED_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(REQUEST_ID::text), '^^') 
            , '||', IFNULL(TRIM(SELECTED_FOR_RECEIPT_BATCH_ID::text), '^^') 
            , '||', IFNULL(TRIM(LAST_CHARGE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(SECOND_LAST_CHARGE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_5::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_6::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_7::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_8::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_9::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_10::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_3::text), '^^') 
            , '||', IFNULL(TRIM(ADJUSTMENT_ID_LAST::text), '^^') 
            , '||', IFNULL(TRIM(ADJUSTMENT_DATE_LAST::text), '^^') 
            , '||', IFNULL(TRIM(ADJUSTMENT_GL_DATE_LAST::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_NUMBER_3::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_NUMBER_4::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_NUMBER_5::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_DATE_1::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_DATE_2::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_DATE_3::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_DATE_4::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_DATE_5::text), '^^') 
            , '||', IFNULL(TRIM(DEL_CONTACT_EMAIL_ADDRESS::text), '^^') 
            , '||', IFNULL(TRIM(PRINT_REQUEST_ID::text), '^^') 
            , '||', IFNULL(TRIM(SEED_DATA_SOURCE::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
            , '||', IFNULL(TRIM(CCE::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
