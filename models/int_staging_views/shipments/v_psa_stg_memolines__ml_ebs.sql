---- SRC LAYER ----
WITH
SRC_S              as ( SELECT * FROM {{ source('ml_ebs_ar', 'ar_memo_lines_all_b') }} as SRC  ),
SRC_A              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S              as ( SELECT * FROM ml_ebs_ar.ar_receivables_trx_all )
, SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        CONCAT (NVL(ORG_ID,'-1'), '||',MEMO_LINE_ID)                 as                                       MEMO_LINE_BK
      , ORG_ID
      , MEMO_LINE_ID
      , TAX_PRODUCT_CATEGORY
      , END_DATE
      , GLOBAL_ATTRIBUTE10
      , LAST_UPDATE_DATE
      , GLOBAL_ATTRIBUTE5
      , GLOBAL_ATTRIBUTE4
      , GLOBAL_ATTRIBUTE7
      , GLOBAL_ATTRIBUTE6
      , GLOBAL_ATTRIBUTE1
      , GLOBAL_ATTRIBUTE3
      , GLOBAL_ATTRIBUTE2
      , UNIT_STD_PRICE
      , GLOBAL_ATTRIBUTE9
      , GLOBAL_ATTRIBUTE8
      , CREATED_BY
      , ATTRIBUTE3
      , LAST_UPDATED_BY
      , ATTRIBUTE2
      , ATTRIBUTE1
      , CREATION_DATE
      , INVOICING_RULE_ID
      , ATTRIBUTE9
      , ATTRIBUTE8
      , ATTRIBUTE7
      , ATTRIBUTE6
      , ATTRIBUTE5
      , NAME
      , ATTRIBUTE4
      , ATTRIBUTE_CATEGORY
      , UOM_CODE
      , GL_ID_REV
      , ATTRIBUTE10
      , ATTRIBUTE14
      , ATTRIBUTE13
      , ATTRIBUTE12
      , ATTRIBUTE11
      , SET_OF_BOOKS_ID
      , DESCRIPTION
      , LINE_TYPE
      , GLOBAL_ATTRIBUTE20
      , START_DATE
      , LAST_UPDATE_LOGIN
      , ACCOUNTING_RULE_ID
      , GLOBAL_ATTRIBUTE_CATEGORY
      , GLOBAL_ATTRIBUTE17
      , GLOBAL_ATTRIBUTE18
      , GLOBAL_ATTRIBUTE15
      , GLOBAL_ATTRIBUTE16
      , GLOBAL_ATTRIBUTE13
      , GLOBAL_ATTRIBUTE14
      , GLOBAL_ATTRIBUTE11
      , GLOBAL_ATTRIBUTE12
      , ATTRIBUTE15
      , TAX_CODE
      , GLOBAL_ATTRIBUTE19
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
        MEMO_LINE_BK
      , ORG_ID
      , MEMO_LINE_ID
      , TAX_PRODUCT_CATEGORY
      , END_DATE
      , GLOBAL_ATTRIBUTE10
      , LAST_UPDATE_DATE
      , GLOBAL_ATTRIBUTE5
      , GLOBAL_ATTRIBUTE4
      , GLOBAL_ATTRIBUTE7
      , GLOBAL_ATTRIBUTE6
      , GLOBAL_ATTRIBUTE1
      , GLOBAL_ATTRIBUTE3
      , GLOBAL_ATTRIBUTE2
      , UNIT_STD_PRICE
      , GLOBAL_ATTRIBUTE9
      , GLOBAL_ATTRIBUTE8
      , CREATED_BY
      , ATTRIBUTE3
      , LAST_UPDATED_BY
      , ATTRIBUTE2
      , ATTRIBUTE1
      , CREATION_DATE
      , INVOICING_RULE_ID
      , ATTRIBUTE9
      , ATTRIBUTE8
      , ATTRIBUTE7
      , ATTRIBUTE6
      , ATTRIBUTE5
      , NAME
      , ATTRIBUTE4
      , ATTRIBUTE_CATEGORY
      , UOM_CODE
      , GL_ID_REV
      , ATTRIBUTE10
      , ATTRIBUTE14
      , ATTRIBUTE13
      , ATTRIBUTE12
      , ATTRIBUTE11
      , SET_OF_BOOKS_ID
      , DESCRIPTION
      , LINE_TYPE
      , GLOBAL_ATTRIBUTE20
      , START_DATE
      , LAST_UPDATE_LOGIN
      , ACCOUNTING_RULE_ID
      , GLOBAL_ATTRIBUTE_CATEGORY
      , GLOBAL_ATTRIBUTE17
      , GLOBAL_ATTRIBUTE18
      , GLOBAL_ATTRIBUTE15
      , GLOBAL_ATTRIBUTE16
      , GLOBAL_ATTRIBUTE13
      , GLOBAL_ATTRIBUTE14
      , GLOBAL_ATTRIBUTE11
      , GLOBAL_ATTRIBUTE12
      , ATTRIBUTE15
      , TAX_CODE
      , GLOBAL_ATTRIBUTE19
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
    WHERE rec_src = 'USWIOC.ORCL.EBSPRD.AR_MEMO_LINES_ALL_B'
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
          MEMO_LINE_BK
        , ORG_ID
        , MEMO_LINE_ID
        , TAX_PRODUCT_CATEGORY
        , END_DATE
        , GLOBAL_ATTRIBUTE10
        , LAST_UPDATE_DATE
        , GLOBAL_ATTRIBUTE5
        , GLOBAL_ATTRIBUTE4
        , GLOBAL_ATTRIBUTE7
        , GLOBAL_ATTRIBUTE6
        , GLOBAL_ATTRIBUTE1
        , GLOBAL_ATTRIBUTE3
        , GLOBAL_ATTRIBUTE2
        , UNIT_STD_PRICE
        , GLOBAL_ATTRIBUTE9
        , GLOBAL_ATTRIBUTE8
        , CREATED_BY
        , ATTRIBUTE3
        , LAST_UPDATED_BY
        , ATTRIBUTE2
        , ATTRIBUTE1
        , CREATION_DATE
        , INVOICING_RULE_ID
        , ATTRIBUTE9
        , ATTRIBUTE8
        , ATTRIBUTE7
        , ATTRIBUTE6
        , ATTRIBUTE5
        , NAME
        , ATTRIBUTE4
        , ATTRIBUTE_CATEGORY
        , UOM_CODE
        , GL_ID_REV
        , ATTRIBUTE10
        , ATTRIBUTE14
        , ATTRIBUTE13
        , ATTRIBUTE12
        , ATTRIBUTE11
        , SET_OF_BOOKS_ID
        , DESCRIPTION
        , LINE_TYPE
        , GLOBAL_ATTRIBUTE20
        , START_DATE
        , LAST_UPDATE_LOGIN
        , ACCOUNTING_RULE_ID
        , GLOBAL_ATTRIBUTE_CATEGORY
        , GLOBAL_ATTRIBUTE17
        , GLOBAL_ATTRIBUTE18
        , GLOBAL_ATTRIBUTE15
        , GLOBAL_ATTRIBUTE16
        , GLOBAL_ATTRIBUTE13
        , GLOBAL_ATTRIBUTE14
        , GLOBAL_ATTRIBUTE11
        , GLOBAL_ATTRIBUTE12
        , ATTRIBUTE15
        , TAX_CODE
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
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(TAX_PRODUCT_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(END_DATE::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE10::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE5::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE4::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE7::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE6::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE1::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE3::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE2::text), '^^') 
            , '||', IFNULL(TRIM(UNIT_STD_PRICE::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE9::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE8::text), '^^') 
            , '||', IFNULL(TRIM(CREATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE3::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE2::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE1::text), '^^') 
            , '||', IFNULL(TRIM(CREATION_DATE::text), '^^') 
            , '||', IFNULL(TRIM(INVOICING_RULE_ID::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE9::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE8::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE7::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE6::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE5::text), '^^') 
            , '||', IFNULL(TRIM(NAME::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE4::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(UOM_CODE::text), '^^') 
            , '||', IFNULL(TRIM(GL_ID_REV::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE10::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE14::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE13::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE12::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE11::text), '^^') 
            , '||', IFNULL(TRIM(SET_OF_BOOKS_ID::text), '^^') 
            , '||', IFNULL(TRIM(DESCRIPTION::text), '^^') 
            , '||', IFNULL(TRIM(LINE_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE20::text), '^^') 
            , '||', IFNULL(TRIM(START_DATE::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_LOGIN::text), '^^') 
            , '||', IFNULL(TRIM(ACCOUNTING_RULE_ID::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE17::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE18::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE15::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE16::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE13::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE14::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE11::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE12::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE15::text), '^^') 
            , '||', IFNULL(TRIM(TAX_CODE::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE19::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
