---- SRC LAYER ----
WITH
SRC_S              as ( SELECT * FROM {{ source('ml_ebs_ar', 'ra_batch_sources_all') }} as SRC  ),
SRC_A              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S              as ( SELECT * FROM ml_ebs_ar.ra_batch_sources_all )
, SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        CONCAT (NVL(ORG_ID,'-1'), '||',BATCH_SOURCE_ID)              as                                    BATCH_SOURCE_BK
      , ORG_ID
      , BATCH_SOURCE_ID
      , BILL_CUSTOMER_RULE
      , COPY_INV_TIDFF_TO_CM_FLAG
      , GLOBAL_ATTRIBUTE5
      , GLOBAL_ATTRIBUTE4
      , GLOBAL_ATTRIBUTE7
      , AGREEMENT_RULE
      , GLOBAL_ATTRIBUTE6
      , GLOBAL_ATTRIBUTE1
      , GLOBAL_ATTRIBUTE3
      , GLOBAL_ATTRIBUTE2
      , BILL_CONTACT_RULE
      , GLOBAL_ATTRIBUTE9
      , GLOBAL_ATTRIBUTE8
      , BILL_ADDRESS_RULE
      , ATTRIBUTE3
      , ATTRIBUTE2
      , ATTRIBUTE1
      , ALLOW_DUPLICATE_TRX_NUM_FLAG
      , ATTRIBUTE9
      , ATTRIBUTE8
      , ATTRIBUTE7
      , ATTRIBUTE6
      , ATTRIBUTE5
      , GL_DATE_PERIOD_RULE
      , ATTRIBUTE4
      , CUST_TRX_TYPE_RULE
      , FOB_POINT_RULE
      , INVENTORY_ITEM_RULE
      , PAYMENT_DET_DEF_HIERARCHY
      , CREATE_CLEARING_FLAG
      , REV_ACC_ALLOCATION_RULE
      , ATTRIBUTE10
      , SALESPERSON_RULE
      , SALES_CREDIT_TYPE_RULE
      , ATTRIBUTE14
      , TERM_RULE
      , ATTRIBUTE13
      , ATTRIBUTE12
      , ATTRIBUTE11
      , GEN_LINE_LEVEL_BAL_FLAG
      , INVALID_TAX_RATE_RULE
      , DESCRIPTION
      , SHIP_CONTACT_RULE
      , RECEIPT_HANDLING_OPTION
      , GLOBAL_ATTRIBUTE20
      , START_DATE
      , GROUPING_RULE_ID
      , GLOBAL_ATTRIBUTE17
      , GLOBAL_ATTRIBUTE18
      , GLOBAL_ATTRIBUTE15
      , GLOBAL_ATTRIBUTE16
      , CUSTOMER_BANK_ACCOUNT_RULE
      , GLOBAL_ATTRIBUTE13
      , GLOBAL_ATTRIBUTE14
      , GLOBAL_ATTRIBUTE11
      , GLOBAL_ATTRIBUTE12
      , ATTRIBUTE15
      , GLOBAL_ATTRIBUTE19
      , SALES_TERRITORY_RULE
      , COPY_DOC_NUMBER_FLAG
      , BATCH_SOURCE_TYPE
      , END_DATE
      , GLOBAL_ATTRIBUTE10
      , LAST_BATCH_NUM
      , LAST_UPDATE_DATE
      , RELATED_DOCUMENT_RULE
      , AUTO_BATCH_NUMBERING_FLAG
      , SHIP_ADDRESS_RULE
      , STATUS
      , ALLOW_SALES_CREDIT_FLAG
      , INVALID_LINES_RULE
      , MEMO_REASON_RULE
      , ACCOUNTING_RULE_RULE
      , DERIVE_DATE_FLAG
      , CREATED_BY
      , LAST_UPDATED_BY
      , ACCOUNTING_FLEXFIELD_RULE
      , AUTO_TRX_NUMBERING_FLAG
      , LEGAL_ENTITY_ID
      , CREATION_DATE
      , UNIT_OF_MEASURE_RULE
      , NAME
      , DEFAULT_REFERENCE
      , ATTRIBUTE_CATEGORY
      , DEFAULT_INV_TRX_TYPE
      , MEMO_LINE_RULE
      , RECEIPT_METHOD_RULE
      , CREDIT_MEMO_BATCH_SOURCE_ID
      , SHIP_CUSTOMER_RULE
      , SOLD_CUSTOMER_RULE
      , SHIP_VIA_RULE
      , SALES_CREDIT_RULE
      , INVOICING_RULE_RULE
      , LAST_UPDATE_LOGIN
      , GLOBAL_ATTRIBUTE_CATEGORY
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
        BATCH_SOURCE_BK
      , ORG_ID
      , BATCH_SOURCE_ID
      , BILL_CUSTOMER_RULE
      , COPY_INV_TIDFF_TO_CM_FLAG
      , GLOBAL_ATTRIBUTE5
      , GLOBAL_ATTRIBUTE4
      , GLOBAL_ATTRIBUTE7
      , AGREEMENT_RULE
      , GLOBAL_ATTRIBUTE6
      , GLOBAL_ATTRIBUTE1
      , GLOBAL_ATTRIBUTE3
      , GLOBAL_ATTRIBUTE2
      , BILL_CONTACT_RULE
      , GLOBAL_ATTRIBUTE9
      , GLOBAL_ATTRIBUTE8
      , BILL_ADDRESS_RULE
      , ATTRIBUTE3
      , ATTRIBUTE2
      , ATTRIBUTE1
      , ALLOW_DUPLICATE_TRX_NUM_FLAG
      , ATTRIBUTE9
      , ATTRIBUTE8
      , ATTRIBUTE7
      , ATTRIBUTE6
      , ATTRIBUTE5
      , GL_DATE_PERIOD_RULE
      , ATTRIBUTE4
      , CUST_TRX_TYPE_RULE
      , FOB_POINT_RULE
      , INVENTORY_ITEM_RULE
      , PAYMENT_DET_DEF_HIERARCHY
      , CREATE_CLEARING_FLAG
      , REV_ACC_ALLOCATION_RULE
      , ATTRIBUTE10
      , SALESPERSON_RULE
      , SALES_CREDIT_TYPE_RULE
      , ATTRIBUTE14
      , TERM_RULE
      , ATTRIBUTE13
      , ATTRIBUTE12
      , ATTRIBUTE11
      , GEN_LINE_LEVEL_BAL_FLAG
      , INVALID_TAX_RATE_RULE
      , DESCRIPTION
      , SHIP_CONTACT_RULE
      , RECEIPT_HANDLING_OPTION
      , GLOBAL_ATTRIBUTE20
      , START_DATE
      , GROUPING_RULE_ID
      , GLOBAL_ATTRIBUTE17
      , GLOBAL_ATTRIBUTE18
      , GLOBAL_ATTRIBUTE15
      , GLOBAL_ATTRIBUTE16
      , CUSTOMER_BANK_ACCOUNT_RULE
      , GLOBAL_ATTRIBUTE13
      , GLOBAL_ATTRIBUTE14
      , GLOBAL_ATTRIBUTE11
      , GLOBAL_ATTRIBUTE12
      , ATTRIBUTE15
      , GLOBAL_ATTRIBUTE19
      , SALES_TERRITORY_RULE
      , COPY_DOC_NUMBER_FLAG
      , BATCH_SOURCE_TYPE
      , END_DATE
      , GLOBAL_ATTRIBUTE10
      , LAST_BATCH_NUM
      , LAST_UPDATE_DATE
      , RELATED_DOCUMENT_RULE
      , AUTO_BATCH_NUMBERING_FLAG
      , SHIP_ADDRESS_RULE
      , STATUS
      , ALLOW_SALES_CREDIT_FLAG
      , INVALID_LINES_RULE
      , MEMO_REASON_RULE
      , ACCOUNTING_RULE_RULE
      , DERIVE_DATE_FLAG
      , CREATED_BY
      , LAST_UPDATED_BY
      , ACCOUNTING_FLEXFIELD_RULE
      , AUTO_TRX_NUMBERING_FLAG
      , LEGAL_ENTITY_ID
      , CREATION_DATE
      , UNIT_OF_MEASURE_RULE
      , NAME
      , DEFAULT_REFERENCE
      , ATTRIBUTE_CATEGORY
      , DEFAULT_INV_TRX_TYPE
      , MEMO_LINE_RULE
      , RECEIPT_METHOD_RULE
      , CREDIT_MEMO_BATCH_SOURCE_ID
      , SHIP_CUSTOMER_RULE
      , SOLD_CUSTOMER_RULE
      , SHIP_VIA_RULE
      , SALES_CREDIT_RULE
      , INVOICING_RULE_RULE
      , LAST_UPDATE_LOGIN
      , GLOBAL_ATTRIBUTE_CATEGORY
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
    WHERE rec_src = 'USWIOC.ORCL.EBSPRD.BATCH_SOURCES'
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
          BATCH_SOURCE_BK
        , ORG_ID
        , BATCH_SOURCE_ID
        , BILL_CUSTOMER_RULE
        , COPY_INV_TIDFF_TO_CM_FLAG
        , GLOBAL_ATTRIBUTE5
        , GLOBAL_ATTRIBUTE4
        , GLOBAL_ATTRIBUTE7
        , AGREEMENT_RULE
        , GLOBAL_ATTRIBUTE6
        , GLOBAL_ATTRIBUTE1
        , GLOBAL_ATTRIBUTE3
        , GLOBAL_ATTRIBUTE2
        , BILL_CONTACT_RULE
        , GLOBAL_ATTRIBUTE9
        , GLOBAL_ATTRIBUTE8
        , BILL_ADDRESS_RULE
        , ATTRIBUTE3
        , ATTRIBUTE2
        , ATTRIBUTE1
        , ALLOW_DUPLICATE_TRX_NUM_FLAG
        , ATTRIBUTE9
        , ATTRIBUTE8
        , ATTRIBUTE7
        , ATTRIBUTE6
        , ATTRIBUTE5
        , GL_DATE_PERIOD_RULE
        , ATTRIBUTE4
        , CUST_TRX_TYPE_RULE
        , FOB_POINT_RULE
        , INVENTORY_ITEM_RULE
        , PAYMENT_DET_DEF_HIERARCHY
        , CREATE_CLEARING_FLAG
        , REV_ACC_ALLOCATION_RULE
        , ATTRIBUTE10
        , SALESPERSON_RULE
        , SALES_CREDIT_TYPE_RULE
        , ATTRIBUTE14
        , TERM_RULE
        , ATTRIBUTE13
        , ATTRIBUTE12
        , ATTRIBUTE11
        , GEN_LINE_LEVEL_BAL_FLAG
        , INVALID_TAX_RATE_RULE
        , DESCRIPTION
        , SHIP_CONTACT_RULE
        , RECEIPT_HANDLING_OPTION
        , GLOBAL_ATTRIBUTE20
        , START_DATE
        , GROUPING_RULE_ID
        , GLOBAL_ATTRIBUTE17
        , GLOBAL_ATTRIBUTE18
        , GLOBAL_ATTRIBUTE15
        , GLOBAL_ATTRIBUTE16
        , CUSTOMER_BANK_ACCOUNT_RULE
        , GLOBAL_ATTRIBUTE13
        , GLOBAL_ATTRIBUTE14
        , GLOBAL_ATTRIBUTE11
        , GLOBAL_ATTRIBUTE12
        , ATTRIBUTE15
        , GLOBAL_ATTRIBUTE19
        , SALES_TERRITORY_RULE
        , COPY_DOC_NUMBER_FLAG
        , BATCH_SOURCE_TYPE
        , END_DATE
        , GLOBAL_ATTRIBUTE10
        , LAST_BATCH_NUM
        , LAST_UPDATE_DATE
        , RELATED_DOCUMENT_RULE
        , AUTO_BATCH_NUMBERING_FLAG
        , SHIP_ADDRESS_RULE
        , STATUS
        , ALLOW_SALES_CREDIT_FLAG
        , INVALID_LINES_RULE
        , MEMO_REASON_RULE
        , ACCOUNTING_RULE_RULE
        , DERIVE_DATE_FLAG
        , CREATED_BY
        , LAST_UPDATED_BY
        , ACCOUNTING_FLEXFIELD_RULE
        , AUTO_TRX_NUMBERING_FLAG
        , LEGAL_ENTITY_ID
        , CREATION_DATE
        , UNIT_OF_MEASURE_RULE
        , NAME
        , DEFAULT_REFERENCE
        , ATTRIBUTE_CATEGORY
        , DEFAULT_INV_TRX_TYPE
        , MEMO_LINE_RULE
        , RECEIPT_METHOD_RULE
        , CREDIT_MEMO_BATCH_SOURCE_ID
        , SHIP_CUSTOMER_RULE
        , SOLD_CUSTOMER_RULE
        , SHIP_VIA_RULE
        , SALES_CREDIT_RULE
        , INVOICING_RULE_RULE
        , LAST_UPDATE_LOGIN
        , GLOBAL_ATTRIBUTE_CATEGORY
        , _FIVETRAN_DELETED
        , _FIVETRAN_ID
        , _FIVETRAN_SYNCED
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(BILL_CUSTOMER_RULE::text), '^^') 
            , '||', IFNULL(TRIM(COPY_INV_TIDFF_TO_CM_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE5::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE4::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE7::text), '^^') 
            , '||', IFNULL(TRIM(AGREEMENT_RULE::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE6::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE1::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE3::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE2::text), '^^') 
            , '||', IFNULL(TRIM(BILL_CONTACT_RULE::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE9::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE8::text), '^^') 
            , '||', IFNULL(TRIM(BILL_ADDRESS_RULE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE3::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE2::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE1::text), '^^') 
            , '||', IFNULL(TRIM(ALLOW_DUPLICATE_TRX_NUM_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE9::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE8::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE7::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE6::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE5::text), '^^') 
            , '||', IFNULL(TRIM(GL_DATE_PERIOD_RULE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE4::text), '^^') 
            , '||', IFNULL(TRIM(CUST_TRX_TYPE_RULE::text), '^^') 
            , '||', IFNULL(TRIM(FOB_POINT_RULE::text), '^^') 
            , '||', IFNULL(TRIM(INVENTORY_ITEM_RULE::text), '^^') 
            , '||', IFNULL(TRIM(PAYMENT_DET_DEF_HIERARCHY::text), '^^') 
            , '||', IFNULL(TRIM(CREATE_CLEARING_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(REV_ACC_ALLOCATION_RULE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE10::text), '^^') 
            , '||', IFNULL(TRIM(SALESPERSON_RULE::text), '^^') 
            , '||', IFNULL(TRIM(SALES_CREDIT_TYPE_RULE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE14::text), '^^') 
            , '||', IFNULL(TRIM(TERM_RULE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE13::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE12::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE11::text), '^^') 
            , '||', IFNULL(TRIM(GEN_LINE_LEVEL_BAL_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(INVALID_TAX_RATE_RULE::text), '^^') 
            , '||', IFNULL(TRIM(DESCRIPTION::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_CONTACT_RULE::text), '^^') 
            , '||', IFNULL(TRIM(RECEIPT_HANDLING_OPTION::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE20::text), '^^') 
            , '||', IFNULL(TRIM(START_DATE::text), '^^') 
            , '||', IFNULL(TRIM(GROUPING_RULE_ID::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE17::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE18::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE15::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE16::text), '^^') 
            , '||', IFNULL(TRIM(CUSTOMER_BANK_ACCOUNT_RULE::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE13::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE14::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE11::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE12::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE15::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE19::text), '^^') 
            , '||', IFNULL(TRIM(SALES_TERRITORY_RULE::text), '^^') 
            , '||', IFNULL(TRIM(COPY_DOC_NUMBER_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(BATCH_SOURCE_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(END_DATE::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE10::text), '^^') 
            , '||', IFNULL(TRIM(LAST_BATCH_NUM::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(RELATED_DOCUMENT_RULE::text), '^^') 
            , '||', IFNULL(TRIM(AUTO_BATCH_NUMBERING_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_ADDRESS_RULE::text), '^^') 
            , '||', IFNULL(TRIM(STATUS::text), '^^') 
            , '||', IFNULL(TRIM(ALLOW_SALES_CREDIT_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(INVALID_LINES_RULE::text), '^^') 
            , '||', IFNULL(TRIM(MEMO_REASON_RULE::text), '^^') 
            , '||', IFNULL(TRIM(ACCOUNTING_RULE_RULE::text), '^^') 
            , '||', IFNULL(TRIM(DERIVE_DATE_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(CREATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(ACCOUNTING_FLEXFIELD_RULE::text), '^^') 
            , '||', IFNULL(TRIM(AUTO_TRX_NUMBERING_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(LEGAL_ENTITY_ID::text), '^^') 
            , '||', IFNULL(TRIM(CREATION_DATE::text), '^^') 
            , '||', IFNULL(TRIM(UNIT_OF_MEASURE_RULE::text), '^^') 
            , '||', IFNULL(TRIM(NAME::text), '^^') 
            , '||', IFNULL(TRIM(DEFAULT_REFERENCE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(DEFAULT_INV_TRX_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(MEMO_LINE_RULE::text), '^^') 
            , '||', IFNULL(TRIM(RECEIPT_METHOD_RULE::text), '^^') 
            , '||', IFNULL(TRIM(CREDIT_MEMO_BATCH_SOURCE_ID::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_CUSTOMER_RULE::text), '^^') 
            , '||', IFNULL(TRIM(SOLD_CUSTOMER_RULE::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_VIA_RULE::text), '^^') 
            , '||', IFNULL(TRIM(SALES_CREDIT_RULE::text), '^^') 
            , '||', IFNULL(TRIM(INVOICING_RULE_RULE::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_LOGIN::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
