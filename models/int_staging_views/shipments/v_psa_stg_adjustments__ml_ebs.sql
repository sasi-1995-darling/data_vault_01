---- SRC LAYER ----
WITH
SRC_S              as ( SELECT * FROM {{ source('ml_ebs_ar', 'ar_adjustments_all') }} as SRC  ),
SRC_A              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S              as ( SELECT * FROM ml_ebs_ar.ar_adjustments_all )
, SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        to_char(CUSTOMER_TRX_ID)                                     as                                         INVOICE_BK
      , CUSTOMER_TRX_ID
      , ADJUSTMENT_ID
      , CREATED_FROM
      , USSGL_TRANSACTION_CODE_CONTEXT
      , ORG_ID
      , DISTRIBUTION_SET_ID
      , LINE_ADJUSTED
      , APPLY_DATE
      , SUBSEQUENT_TRX_ID
      , GLOBAL_ATTRIBUTE10
      , ASSOCIATED_CASH_RECEIPT_ID
      , PROGRAM_ID
      , INTEREST_LINE_ID
      , GLOBAL_ATTRIBUTE5
      , GLOBAL_ATTRIBUTE4
      , GLOBAL_ATTRIBUTE7
      , STATUS
      , GLOBAL_ATTRIBUTE6
      , GLOBAL_ATTRIBUTE1
      , AMOUNT
      , GLOBAL_ATTRIBUTE3
      , GLOBAL_ATTRIBUTE2
      , AX_ACCOUNTED_FLAG
      , CHARGEBACK_CUSTOMER_TRX_ID
      , POSTING_CONTROL_ID
      , GLOBAL_ATTRIBUTE9
      , GLOBAL_ATTRIBUTE8
      , TYPE
      , APPROVED_BY
      , CREATED_BY
      , ATTRIBUTE3
      , LAST_UPDATED_BY
      , ATTRIBUTE2
      , ATTRIBUTE1
      , MRC_ACCTD_AMOUNT
      , AUTOMATICALLY_GENERATED
      , MRC_GL_POSTED_DATE
      , ATTRIBUTE9
      , ATTRIBUTE8
      , ADJUSTMENT_TYPE
      , ATTRIBUTE7
      , USSGL_TRANSACTION_CODE
      , GL_DATE
      , ATTRIBUTE6
      , RECEIVABLES_CHARGES_ADJUSTED
      , ATTRIBUTE5
      , GL_POSTED_DATE
      , ATTRIBUTE4
      , POSTABLE
      , ATTRIBUTE_CATEGORY
      , RECEIVABLES_TRX_ID
      , PROGRAM_APPLICATION_ID
      , LINK_TO_TRX_HIST_ID
      , ADJUSTMENT_NUMBER
      , EVENT_ID
      , PAYMENT_SCHEDULE_ID
      , ATTRIBUTE10
      , CONS_INV_ID
      , ATTRIBUTE14
      , ATTRIBUTE13
      , INTEREST_HEADER_ID
      , ATTRIBUTE12
      , ATTRIBUTE11
      , SET_OF_BOOKS_ID
      , COMMENTS
      , REQUEST_ID
      , BATCH_ID
      , TAX_ADJUSTED
      , ASSOCIATED_APPLICATION_ID
      , CODE_COMBINATION_ID
      , FREIGHT_ADJUSTED
      , DOC_SEQUENCE_VALUE
      , CUSTOMER_TRX_LINE_ID
      , ADJ_TAX_ACCT_RULE
      , REASON_CODE
      , GLOBAL_ATTRIBUTE20
      , ACCTD_AMOUNT
      , LAST_UPDATE_LOGIN
      , UPGRADE_METHOD
      , GLOBAL_ATTRIBUTE_CATEGORY
      , GLOBAL_ATTRIBUTE17
      , GLOBAL_ATTRIBUTE18
      , GLOBAL_ATTRIBUTE15
      , GLOBAL_ATTRIBUTE16
      , MRC_POSTING_CONTROL_ID
      , GLOBAL_ATTRIBUTE13
      , GLOBAL_ATTRIBUTE14
      , GLOBAL_ATTRIBUTE11
      , GLOBAL_ATTRIBUTE12
      , DOC_SEQUENCE_ID
      , ATTRIBUTE15
      , GLOBAL_ATTRIBUTE19
      , PROGRAM_UPDATE_DATE
      , CREATION_DATE
      , LAST_UPDATE_DATE
      , _FIVETRAN_DELETED
      , _FIVETRAN_ID
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
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
        INVOICE_BK
      , CUSTOMER_TRX_ID
      , ADJUSTMENT_ID
      , CREATED_FROM
      , USSGL_TRANSACTION_CODE_CONTEXT
      , ORG_ID
      , DISTRIBUTION_SET_ID
      , LINE_ADJUSTED
      , APPLY_DATE
      , SUBSEQUENT_TRX_ID
      , GLOBAL_ATTRIBUTE10
      , ASSOCIATED_CASH_RECEIPT_ID
      , PROGRAM_ID
      , INTEREST_LINE_ID
      , GLOBAL_ATTRIBUTE5
      , GLOBAL_ATTRIBUTE4
      , GLOBAL_ATTRIBUTE7
      , STATUS
      , GLOBAL_ATTRIBUTE6
      , GLOBAL_ATTRIBUTE1
      , AMOUNT
      , GLOBAL_ATTRIBUTE3
      , GLOBAL_ATTRIBUTE2
      , AX_ACCOUNTED_FLAG
      , CHARGEBACK_CUSTOMER_TRX_ID
      , POSTING_CONTROL_ID
      , GLOBAL_ATTRIBUTE9
      , GLOBAL_ATTRIBUTE8
      , TYPE
      , APPROVED_BY
      , CREATED_BY
      , ATTRIBUTE3
      , LAST_UPDATED_BY
      , ATTRIBUTE2
      , ATTRIBUTE1
      , MRC_ACCTD_AMOUNT
      , AUTOMATICALLY_GENERATED
      , MRC_GL_POSTED_DATE
      , ATTRIBUTE9
      , ATTRIBUTE8
      , ADJUSTMENT_TYPE
      , ATTRIBUTE7
      , USSGL_TRANSACTION_CODE
      , GL_DATE
      , ATTRIBUTE6
      , RECEIVABLES_CHARGES_ADJUSTED
      , ATTRIBUTE5
      , GL_POSTED_DATE
      , ATTRIBUTE4
      , POSTABLE
      , ATTRIBUTE_CATEGORY
      , RECEIVABLES_TRX_ID
      , PROGRAM_APPLICATION_ID
      , LINK_TO_TRX_HIST_ID
      , ADJUSTMENT_NUMBER
      , EVENT_ID
      , PAYMENT_SCHEDULE_ID
      , ATTRIBUTE10
      , CONS_INV_ID
      , ATTRIBUTE14
      , ATTRIBUTE13
      , INTEREST_HEADER_ID
      , ATTRIBUTE12
      , ATTRIBUTE11
      , SET_OF_BOOKS_ID
      , COMMENTS
      , REQUEST_ID
      , BATCH_ID
      , TAX_ADJUSTED
      , ASSOCIATED_APPLICATION_ID
      , CODE_COMBINATION_ID
      , FREIGHT_ADJUSTED
      , DOC_SEQUENCE_VALUE
      , CUSTOMER_TRX_LINE_ID
      , ADJ_TAX_ACCT_RULE
      , REASON_CODE
      , GLOBAL_ATTRIBUTE20
      , ACCTD_AMOUNT
      , LAST_UPDATE_LOGIN
      , UPGRADE_METHOD
      , GLOBAL_ATTRIBUTE_CATEGORY
      , GLOBAL_ATTRIBUTE17
      , GLOBAL_ATTRIBUTE18
      , GLOBAL_ATTRIBUTE15
      , GLOBAL_ATTRIBUTE16
      , MRC_POSTING_CONTROL_ID
      , GLOBAL_ATTRIBUTE13
      , GLOBAL_ATTRIBUTE14
      , GLOBAL_ATTRIBUTE11
      , GLOBAL_ATTRIBUTE12
      , DOC_SEQUENCE_ID
      , ATTRIBUTE15
      , GLOBAL_ATTRIBUTE19
      , PROGRAM_UPDATE_DATE
      , CREATION_DATE
      , LAST_UPDATE_DATE
      , _FIVETRAN_DELETED
      , _FIVETRAN_ID
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
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
    WHERE rec_src = 'USWIOC.ORCL.EBSPRD.AR_ADJUSTMENTS_ALL'
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
        , ADJUSTMENT_ID
        , CREATED_FROM
        , USSGL_TRANSACTION_CODE_CONTEXT
        , ORG_ID
        , DISTRIBUTION_SET_ID
        , LINE_ADJUSTED
        , APPLY_DATE
        , SUBSEQUENT_TRX_ID
        , GLOBAL_ATTRIBUTE10
        , ASSOCIATED_CASH_RECEIPT_ID
        , PROGRAM_ID
        , INTEREST_LINE_ID
        , GLOBAL_ATTRIBUTE5
        , GLOBAL_ATTRIBUTE4
        , GLOBAL_ATTRIBUTE7
        , STATUS
        , GLOBAL_ATTRIBUTE6
        , GLOBAL_ATTRIBUTE1
        , AMOUNT
        , GLOBAL_ATTRIBUTE3
        , GLOBAL_ATTRIBUTE2
        , AX_ACCOUNTED_FLAG
        , CHARGEBACK_CUSTOMER_TRX_ID
        , POSTING_CONTROL_ID
        , GLOBAL_ATTRIBUTE9
        , GLOBAL_ATTRIBUTE8
        , TYPE
        , APPROVED_BY
        , CREATED_BY
        , ATTRIBUTE3
        , LAST_UPDATED_BY
        , ATTRIBUTE2
        , ATTRIBUTE1
        , MRC_ACCTD_AMOUNT
        , AUTOMATICALLY_GENERATED
        , MRC_GL_POSTED_DATE
        , ATTRIBUTE9
        , ATTRIBUTE8
        , ADJUSTMENT_TYPE
        , ATTRIBUTE7
        , USSGL_TRANSACTION_CODE
        , GL_DATE
        , ATTRIBUTE6
        , RECEIVABLES_CHARGES_ADJUSTED
        , ATTRIBUTE5
        , GL_POSTED_DATE
        , ATTRIBUTE4
        , POSTABLE
        , ATTRIBUTE_CATEGORY
        , RECEIVABLES_TRX_ID
        , PROGRAM_APPLICATION_ID
        , LINK_TO_TRX_HIST_ID
        , ADJUSTMENT_NUMBER
        , EVENT_ID
        , PAYMENT_SCHEDULE_ID
        , ATTRIBUTE10
        , CONS_INV_ID
        , ATTRIBUTE14
        , ATTRIBUTE13
        , INTEREST_HEADER_ID
        , ATTRIBUTE12
        , ATTRIBUTE11
        , SET_OF_BOOKS_ID
        , COMMENTS
        , REQUEST_ID
        , BATCH_ID
        , TAX_ADJUSTED
        , ASSOCIATED_APPLICATION_ID
        , CODE_COMBINATION_ID
        , FREIGHT_ADJUSTED
        , DOC_SEQUENCE_VALUE
        , CUSTOMER_TRX_LINE_ID
        , ADJ_TAX_ACCT_RULE
        , REASON_CODE
        , GLOBAL_ATTRIBUTE20
        , ACCTD_AMOUNT
        , LAST_UPDATE_LOGIN
        , UPGRADE_METHOD
        , GLOBAL_ATTRIBUTE_CATEGORY
        , GLOBAL_ATTRIBUTE17
        , GLOBAL_ATTRIBUTE18
        , GLOBAL_ATTRIBUTE15
        , GLOBAL_ATTRIBUTE16
        , MRC_POSTING_CONTROL_ID
        , GLOBAL_ATTRIBUTE13
        , GLOBAL_ATTRIBUTE14
        , GLOBAL_ATTRIBUTE11
        , GLOBAL_ATTRIBUTE12
        , DOC_SEQUENCE_ID
        , ATTRIBUTE15
        , GLOBAL_ATTRIBUTE19
        , PROGRAM_UPDATE_DATE
        , CREATION_DATE
        , LAST_UPDATE_DATE
        , _FIVETRAN_DELETED
        , _FIVETRAN_ID
        , _FIVETRAN_SYNCED
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(CUSTOMER_TRX_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as INVOICE_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(CUSTOMER_TRX_ID::text), '^^') 
            , '||', IFNULL(TRIM(ADJUSTMENT_ID::text), '^^') 
            , '||', IFNULL(TRIM(USSGL_TRANSACTION_CODE_CONTEXT::text), '^^') 
            , '||', IFNULL(TRIM(ORG_ID::text), '^^') 
            , '||', IFNULL(TRIM(DISTRIBUTION_SET_ID::text), '^^') 
            , '||', IFNULL(TRIM(LINE_ADJUSTED::text), '^^') 
            , '||', IFNULL(TRIM(APPLY_DATE::text), '^^') 
            , '||', IFNULL(TRIM(SUBSEQUENT_TRX_ID::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE10::text), '^^') 
            , '||', IFNULL(TRIM(ASSOCIATED_CASH_RECEIPT_ID::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_ID::text), '^^') 
            , '||', IFNULL(TRIM(INTEREST_LINE_ID::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE5::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE4::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE7::text), '^^') 
            , '||', IFNULL(TRIM(STATUS::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE6::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE1::text), '^^') 
            , '||', IFNULL(TRIM(AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE3::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE2::text), '^^') 
            , '||', IFNULL(TRIM(AX_ACCOUNTED_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(CHARGEBACK_CUSTOMER_TRX_ID::text), '^^') 
            , '||', IFNULL(TRIM(POSTING_CONTROL_ID::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE9::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE8::text), '^^') 
            , '||', IFNULL(TRIM(TYPE::text), '^^') 
            , '||', IFNULL(TRIM(APPROVED_BY::text), '^^') 
            , '||', IFNULL(TRIM(CREATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE3::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE2::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE1::text), '^^') 
            , '||', IFNULL(TRIM(MRC_ACCTD_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(AUTOMATICALLY_GENERATED::text), '^^') 
            , '||', IFNULL(TRIM(MRC_GL_POSTED_DATE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE9::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE8::text), '^^') 
            , '||', IFNULL(TRIM(ADJUSTMENT_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE7::text), '^^') 
            , '||', IFNULL(TRIM(USSGL_TRANSACTION_CODE::text), '^^') 
            , '||', IFNULL(TRIM(GL_DATE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE6::text), '^^') 
            , '||', IFNULL(TRIM(RECEIVABLES_CHARGES_ADJUSTED::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE5::text), '^^') 
            , '||', IFNULL(TRIM(GL_POSTED_DATE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE4::text), '^^') 
            , '||', IFNULL(TRIM(POSTABLE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(RECEIVABLES_TRX_ID::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_APPLICATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(LINK_TO_TRX_HIST_ID::text), '^^') 
            , '||', IFNULL(TRIM(ADJUSTMENT_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(EVENT_ID::text), '^^') 
            , '||', IFNULL(TRIM(PAYMENT_SCHEDULE_ID::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE10::text), '^^') 
            , '||', IFNULL(TRIM(CONS_INV_ID::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE14::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE13::text), '^^') 
            , '||', IFNULL(TRIM(INTEREST_HEADER_ID::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE12::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE11::text), '^^') 
            , '||', IFNULL(TRIM(SET_OF_BOOKS_ID::text), '^^') 
            , '||', IFNULL(TRIM(COMMENTS::text), '^^') 
            , '||', IFNULL(TRIM(REQUEST_ID::text), '^^') 
            , '||', IFNULL(TRIM(BATCH_ID::text), '^^') 
            , '||', IFNULL(TRIM(TAX_ADJUSTED::text), '^^') 
            , '||', IFNULL(TRIM(ASSOCIATED_APPLICATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(CODE_COMBINATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(FREIGHT_ADJUSTED::text), '^^') 
            , '||', IFNULL(TRIM(DOC_SEQUENCE_VALUE::text), '^^') 
            , '||', IFNULL(TRIM(CUSTOMER_TRX_LINE_ID::text), '^^') 
            , '||', IFNULL(TRIM(ADJ_TAX_ACCT_RULE::text), '^^') 
            , '||', IFNULL(TRIM(REASON_CODE::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE20::text), '^^') 
            , '||', IFNULL(TRIM(ACCTD_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_LOGIN::text), '^^') 
            , '||', IFNULL(TRIM(UPGRADE_METHOD::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE17::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE18::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE15::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE16::text), '^^') 
            , '||', IFNULL(TRIM(MRC_POSTING_CONTROL_ID::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE13::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE14::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE11::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE12::text), '^^') 
            , '||', IFNULL(TRIM(DOC_SEQUENCE_ID::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE15::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE19::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_UPDATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(CREATION_DATE::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
