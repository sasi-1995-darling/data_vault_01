---- SRC LAYER ----
WITH
SRC_S              as ( SELECT * FROM {{ source('ml_ebs_ar', 'ra_cust_trx_line_gl_dist_all') }} as SRC  ),
SRC_A              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S              as ( SELECT * FROM ml_ebs_ar.ra_cust_trx_line_gl_dist_all )
, SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        to_char(coalesce(CUSTOMER_TRX_LINE_ID,'-1'))                 as                                    INVOICE_LINE_BK
      , CUST_TRX_LINE_GL_DIST_ID
      , CUSTOMER_TRX_LINE_ID
      , ORG_ID
      , GLOBAL_ATTRIBUTE10
      , LAST_UPDATE_DATE
      , PROGRAM_ID
      , GLOBAL_ATTRIBUTE5
      , USER_GENERATED_FLAG
      , GLOBAL_ATTRIBUTE4
      , GLOBAL_ATTRIBUTE7
      , GLOBAL_ATTRIBUTE6
      , GLOBAL_ATTRIBUTE1
      , AMOUNT
      , GLOBAL_ATTRIBUTE3
      , GLOBAL_ATTRIBUTE2
      , POSTING_CONTROL_ID
      , RA_POST_LOOP_NUMBER
      , GLOBAL_ATTRIBUTE9
      , GLOBAL_ATTRIBUTE8
      , CREATED_BY
      , ATTRIBUTE3
      , LAST_UPDATED_BY
      , ATTRIBUTE2
      , ATTRIBUTE1
      , MRC_ACCTD_AMOUNT
      , CREATION_DATE
      , ATTRIBUTE9
      , MRC_GL_POSTED_DATE
      , ATTRIBUTE8
      , ATTRIBUTE7
      , POST_REQUEST_ID
      , USSGL_TRANSACTION_CODE
      , ATTRIBUTE6
      , GL_DATE
      , PROGRAM_UPDATE_DATE
      , REC_OFFSET_FLAG
      , ATTRIBUTE5
      , GL_POSTED_DATE
      , ATTRIBUTE4
      , ACCOUNT_CLASS
      , ATTRIBUTE_CATEGORY
      , PROGRAM_APPLICATION_ID
      , EVENT_ID
      , ATTRIBUTE10
      , ATTRIBUTE14
      , ATTRIBUTE13
      , LATEST_REC_FLAG
      , ATTRIBUTE12
      , MRC_ACCOUNT_CLASS
      , ATTRIBUTE11
      , SET_OF_BOOKS_ID
      , COMMENTS
      , COLLECTED_TAX_CCID
      , REQUEST_ID
      , GLOBAL_ATTRIBUTE30
      , GLOBAL_ATTRIBUTE28
      , GLOBAL_ATTRIBUTE29
      , CCID_CHANGE_FLAG
      , GLOBAL_ATTRIBUTE26
      , GLOBAL_ATTRIBUTE27
      , COLLECTED_TAX_CONCAT_SEG
      , GLOBAL_ATTRIBUTE24
      , GLOBAL_ATTRIBUTE25
      , GLOBAL_ATTRIBUTE22
      , MRC_AMOUNT
      , CODE_COMBINATION_ID
      , GLOBAL_ATTRIBUTE23
      , ROUNDING_CORRECTION_FLAG
      , ACCOUNT_SET_FLAG
      , CONCATENATED_SEGMENTS
      , CUSTOMER_TRX_ID
      , GLOBAL_ATTRIBUTE20
      , ACCTD_AMOUNT
      , GLOBAL_ATTRIBUTE21
      , REV_ADJ_CLASS_TEMP
      , LAST_UPDATE_LOGIN
      , REVENUE_ADJUSTMENT_ID
      , CUST_TRX_LINE_SALESREP_ID
      , GLOBAL_ATTRIBUTE_CATEGORY
      , GLOBAL_ATTRIBUTE17
      , GLOBAL_ATTRIBUTE18
      , GLOBAL_ATTRIBUTE15
      , GLOBAL_ATTRIBUTE16
      , MRC_POSTING_CONTROL_ID
      , GLOBAL_ATTRIBUTE13
      , GLOBAL_ATTRIBUTE14
      , MRC_CUSTOMER_TRX_ID
      , PERCENT
      , GLOBAL_ATTRIBUTE11
      , GLOBAL_ATTRIBUTE12
      , ORIGINAL_GL_DATE
      , ATTRIBUTE15
      , COGS_REQUEST_ID
      , GLOBAL_ATTRIBUTE19
      , _FIVETRAN_DELETED
      , _FIVETRAN_ID
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED )                   as                                           LOAD_DTS
      , to_char(CUSTOMER_TRX_ID)                                     as                                         INVOICE_BK
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
        INVOICE_LINE_BK
      , CUST_TRX_LINE_GL_DIST_ID
      , CUSTOMER_TRX_LINE_ID
      , ORG_ID
      , GLOBAL_ATTRIBUTE10
      , LAST_UPDATE_DATE
      , PROGRAM_ID
      , GLOBAL_ATTRIBUTE5
      , USER_GENERATED_FLAG
      , GLOBAL_ATTRIBUTE4
      , GLOBAL_ATTRIBUTE7
      , GLOBAL_ATTRIBUTE6
      , GLOBAL_ATTRIBUTE1
      , AMOUNT
      , GLOBAL_ATTRIBUTE3
      , GLOBAL_ATTRIBUTE2
      , POSTING_CONTROL_ID
      , RA_POST_LOOP_NUMBER
      , GLOBAL_ATTRIBUTE9
      , GLOBAL_ATTRIBUTE8
      , CREATED_BY
      , ATTRIBUTE3
      , LAST_UPDATED_BY
      , ATTRIBUTE2
      , ATTRIBUTE1
      , MRC_ACCTD_AMOUNT
      , CREATION_DATE
      , ATTRIBUTE9
      , MRC_GL_POSTED_DATE
      , ATTRIBUTE8
      , ATTRIBUTE7
      , POST_REQUEST_ID
      , USSGL_TRANSACTION_CODE
      , ATTRIBUTE6
      , GL_DATE
      , PROGRAM_UPDATE_DATE
      , REC_OFFSET_FLAG
      , ATTRIBUTE5
      , GL_POSTED_DATE
      , ATTRIBUTE4
      , ACCOUNT_CLASS
      , ATTRIBUTE_CATEGORY
      , PROGRAM_APPLICATION_ID
      , EVENT_ID
      , ATTRIBUTE10
      , ATTRIBUTE14
      , ATTRIBUTE13
      , LATEST_REC_FLAG
      , ATTRIBUTE12
      , MRC_ACCOUNT_CLASS
      , ATTRIBUTE11
      , SET_OF_BOOKS_ID
      , COMMENTS
      , COLLECTED_TAX_CCID
      , REQUEST_ID
      , GLOBAL_ATTRIBUTE30
      , GLOBAL_ATTRIBUTE28
      , GLOBAL_ATTRIBUTE29
      , CCID_CHANGE_FLAG
      , GLOBAL_ATTRIBUTE26
      , GLOBAL_ATTRIBUTE27
      , COLLECTED_TAX_CONCAT_SEG
      , GLOBAL_ATTRIBUTE24
      , GLOBAL_ATTRIBUTE25
      , GLOBAL_ATTRIBUTE22
      , MRC_AMOUNT
      , CODE_COMBINATION_ID
      , GLOBAL_ATTRIBUTE23
      , ROUNDING_CORRECTION_FLAG
      , ACCOUNT_SET_FLAG
      , CONCATENATED_SEGMENTS
      , CUSTOMER_TRX_ID
      , GLOBAL_ATTRIBUTE20
      , ACCTD_AMOUNT
      , GLOBAL_ATTRIBUTE21
      , REV_ADJ_CLASS_TEMP
      , LAST_UPDATE_LOGIN
      , REVENUE_ADJUSTMENT_ID
      , CUST_TRX_LINE_SALESREP_ID
      , GLOBAL_ATTRIBUTE_CATEGORY
      , GLOBAL_ATTRIBUTE17
      , GLOBAL_ATTRIBUTE18
      , GLOBAL_ATTRIBUTE15
      , GLOBAL_ATTRIBUTE16
      , MRC_POSTING_CONTROL_ID
      , GLOBAL_ATTRIBUTE13
      , GLOBAL_ATTRIBUTE14
      , MRC_CUSTOMER_TRX_ID
      , PERCENT
      , GLOBAL_ATTRIBUTE11
      , GLOBAL_ATTRIBUTE12
      , ORIGINAL_GL_DATE
      , ATTRIBUTE15
      , COGS_REQUEST_ID
      , GLOBAL_ATTRIBUTE19
      , _FIVETRAN_DELETED
      , _FIVETRAN_ID
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
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
    WHERE rec_src = 'USWIOC.ORCL.EBSPRD.RA_CUST_TRX_LINE_GL_DIST_ALL'
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
          INVOICE_LINE_BK
        , CUST_TRX_LINE_GL_DIST_ID
        , CUSTOMER_TRX_LINE_ID
        , ORG_ID
        , GLOBAL_ATTRIBUTE10
        , LAST_UPDATE_DATE
        , PROGRAM_ID
        , GLOBAL_ATTRIBUTE5
        , USER_GENERATED_FLAG
        , GLOBAL_ATTRIBUTE4
        , GLOBAL_ATTRIBUTE7
        , GLOBAL_ATTRIBUTE6
        , GLOBAL_ATTRIBUTE1
        , AMOUNT
        , GLOBAL_ATTRIBUTE3
        , GLOBAL_ATTRIBUTE2
        , POSTING_CONTROL_ID
        , RA_POST_LOOP_NUMBER
        , GLOBAL_ATTRIBUTE9
        , GLOBAL_ATTRIBUTE8
        , CREATED_BY
        , ATTRIBUTE3
        , LAST_UPDATED_BY
        , ATTRIBUTE2
        , ATTRIBUTE1
        , MRC_ACCTD_AMOUNT
        , CREATION_DATE
        , ATTRIBUTE9
        , MRC_GL_POSTED_DATE
        , ATTRIBUTE8
        , ATTRIBUTE7
        , POST_REQUEST_ID
        , USSGL_TRANSACTION_CODE
        , ATTRIBUTE6
        , GL_DATE
        , PROGRAM_UPDATE_DATE
        , REC_OFFSET_FLAG
        , ATTRIBUTE5
        , GL_POSTED_DATE
        , ATTRIBUTE4
        , ACCOUNT_CLASS
        , ATTRIBUTE_CATEGORY
        , PROGRAM_APPLICATION_ID
        , EVENT_ID
        , ATTRIBUTE10
        , ATTRIBUTE14
        , ATTRIBUTE13
        , LATEST_REC_FLAG
        , ATTRIBUTE12
        , MRC_ACCOUNT_CLASS
        , ATTRIBUTE11
        , SET_OF_BOOKS_ID
        , COMMENTS
        , COLLECTED_TAX_CCID
        , REQUEST_ID
        , GLOBAL_ATTRIBUTE30
        , GLOBAL_ATTRIBUTE28
        , GLOBAL_ATTRIBUTE29
        , CCID_CHANGE_FLAG
        , GLOBAL_ATTRIBUTE26
        , GLOBAL_ATTRIBUTE27
        , COLLECTED_TAX_CONCAT_SEG
        , GLOBAL_ATTRIBUTE24
        , GLOBAL_ATTRIBUTE25
        , GLOBAL_ATTRIBUTE22
        , MRC_AMOUNT
        , CODE_COMBINATION_ID
        , GLOBAL_ATTRIBUTE23
        , ROUNDING_CORRECTION_FLAG
        , ACCOUNT_SET_FLAG
        , CONCATENATED_SEGMENTS
        , CUSTOMER_TRX_ID
        , GLOBAL_ATTRIBUTE20
        , ACCTD_AMOUNT
        , GLOBAL_ATTRIBUTE21
        , REV_ADJ_CLASS_TEMP
        , LAST_UPDATE_LOGIN
        , REVENUE_ADJUSTMENT_ID
        , CUST_TRX_LINE_SALESREP_ID
        , GLOBAL_ATTRIBUTE_CATEGORY
        , GLOBAL_ATTRIBUTE17
        , GLOBAL_ATTRIBUTE18
        , GLOBAL_ATTRIBUTE15
        , GLOBAL_ATTRIBUTE16
        , MRC_POSTING_CONTROL_ID
        , GLOBAL_ATTRIBUTE13
        , GLOBAL_ATTRIBUTE14
        , MRC_CUSTOMER_TRX_ID
        , PERCENT
        , GLOBAL_ATTRIBUTE11
        , GLOBAL_ATTRIBUTE12
        , ORIGINAL_GL_DATE
        , ATTRIBUTE15
        , COGS_REQUEST_ID
        , GLOBAL_ATTRIBUTE19
        , _FIVETRAN_DELETED
        , _FIVETRAN_ID
        , _FIVETRAN_SYNCED
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , INVOICE_BK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(INVOICE_LINE_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as INVOICE_LINE_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(CUSTOMER_TRX_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as INVOICE_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(CUST_TRX_LINE_GL_DIST_ID::text), '^^') 
            , '||', IFNULL(TRIM(CUSTOMER_TRX_LINE_ID::text), '^^') 
            , '||', IFNULL(TRIM(ORG_ID::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE10::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_ID::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE5::text), '^^') 
            , '||', IFNULL(TRIM(USER_GENERATED_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE4::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE7::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE6::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE1::text), '^^') 
            , '||', IFNULL(TRIM(AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE3::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE2::text), '^^') 
            , '||', IFNULL(TRIM(POSTING_CONTROL_ID::text), '^^') 
            , '||', IFNULL(TRIM(RA_POST_LOOP_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE9::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE8::text), '^^') 
            , '||', IFNULL(TRIM(CREATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE3::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE2::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE1::text), '^^') 
            , '||', IFNULL(TRIM(MRC_ACCTD_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(CREATION_DATE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE9::text), '^^') 
            , '||', IFNULL(TRIM(MRC_GL_POSTED_DATE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE8::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE7::text), '^^') 
            , '||', IFNULL(TRIM(POST_REQUEST_ID::text), '^^') 
            , '||', IFNULL(TRIM(USSGL_TRANSACTION_CODE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE6::text), '^^') 
            , '||', IFNULL(TRIM(GL_DATE::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_UPDATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(REC_OFFSET_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE5::text), '^^') 
            , '||', IFNULL(TRIM(GL_POSTED_DATE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE4::text), '^^') 
            , '||', IFNULL(TRIM(ACCOUNT_CLASS::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_APPLICATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(EVENT_ID::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE10::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE14::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE13::text), '^^') 
            , '||', IFNULL(TRIM(LATEST_REC_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE12::text), '^^') 
            , '||', IFNULL(TRIM(MRC_ACCOUNT_CLASS::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE11::text), '^^') 
            , '||', IFNULL(TRIM(SET_OF_BOOKS_ID::text), '^^') 
            , '||', IFNULL(TRIM(COMMENTS::text), '^^') 
            , '||', IFNULL(TRIM(COLLECTED_TAX_CCID::text), '^^') 
            , '||', IFNULL(TRIM(REQUEST_ID::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE30::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE28::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE29::text), '^^') 
            , '||', IFNULL(TRIM(CCID_CHANGE_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE26::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE27::text), '^^') 
            , '||', IFNULL(TRIM(COLLECTED_TAX_CONCAT_SEG::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE24::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE25::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE22::text), '^^') 
            , '||', IFNULL(TRIM(MRC_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(CODE_COMBINATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE23::text), '^^') 
            , '||', IFNULL(TRIM(ROUNDING_CORRECTION_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(ACCOUNT_SET_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(CONCATENATED_SEGMENTS::text), '^^') 
            , '||', IFNULL(TRIM(CUSTOMER_TRX_ID::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE20::text), '^^') 
            , '||', IFNULL(TRIM(ACCTD_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE21::text), '^^') 
            , '||', IFNULL(TRIM(REV_ADJ_CLASS_TEMP::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_LOGIN::text), '^^') 
            , '||', IFNULL(TRIM(REVENUE_ADJUSTMENT_ID::text), '^^') 
            , '||', IFNULL(TRIM(CUST_TRX_LINE_SALESREP_ID::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE17::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE18::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE15::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE16::text), '^^') 
            , '||', IFNULL(TRIM(MRC_POSTING_CONTROL_ID::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE13::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE14::text), '^^') 
            , '||', IFNULL(TRIM(MRC_CUSTOMER_TRX_ID::text), '^^') 
            , '||', IFNULL(TRIM(PERCENT::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE11::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE12::text), '^^') 
            , '||', IFNULL(TRIM(ORIGINAL_GL_DATE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE15::text), '^^') 
            , '||', IFNULL(TRIM(COGS_REQUEST_ID::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE19::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
