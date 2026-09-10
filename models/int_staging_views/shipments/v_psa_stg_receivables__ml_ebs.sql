---- SRC LAYER ----
WITH
SRC_S              as ( SELECT * FROM {{ source('ml_ebs_ar', 'ar_receivables_trx_all') }} as SRC  ),
SRC_A              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S              as ( SELECT * FROM ml_ebs_ar.ar_receivables_trx_all )
, SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        CONCAT (NVL(ORG_ID,'-1'), '||',RECEIVABLES_TRX_ID)           as                                     RECEIVABLES_BK
      , ORG_ID
      , RECEIVABLES_TRX_ID
      , GLOBAL_ATTRIBUTE10
      , LAST_UPDATE_DATE
      , RISK_ELIMINATION_DAYS
      , GLOBAL_ATTRIBUTE5
      , GLOBAL_ATTRIBUTE4
      , STATUS
      , GLOBAL_ATTRIBUTE7
      , GL_ACCOUNT_SOURCE
      , GLOBAL_ATTRIBUTE6
      , GLOBAL_ATTRIBUTE1
      , GLOBAL_ATTRIBUTE3
      , GLOBAL_ATTRIBUTE2
      , GLOBAL_ATTRIBUTE9
      , TYPE
      , END_DATE_ACTIVE
      , GLOBAL_ATTRIBUTE8
      , CREATED_BY
      , ATTRIBUTE3
      , LAST_UPDATED_BY
      , ATTRIBUTE2
      , ATTRIBUTE1
      , CREATION_DATE
      , DEFAULT_ACCTG_DISTRIBUTION_SET
      , ATTRIBUTE9
      , ATTRIBUTE8
      , ATTRIBUTE7
      , ATTRIBUTE6
      , ATTRIBUTE5
      , NAME
      , ATTRIBUTE4
      , ATTRIBUTE_CATEGORY
      , TAX_RECOVERABLE_FLAG
      , ATTRIBUTE10
      , ATTRIBUTE14
      , ATTRIBUTE13
      , TAX_CODE_SOURCE
      , ATTRIBUTE12
      , ATTRIBUTE11
      , SET_OF_BOOKS_ID
      , LIABILITY_TAX_CODE
      , ACCOUNTING_AFFECT_FLAG
      , ASSET_TAX_CODE
      , DESCRIPTION
      , CODE_COMBINATION_ID
      , INACTIVE_DATE
      , START_DATE_ACTIVE
      , GLOBAL_ATTRIBUTE20
      , LAST_UPDATE_LOGIN
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
        RECEIVABLES_BK
      , ORG_ID
      , RECEIVABLES_TRX_ID
      , GLOBAL_ATTRIBUTE10
      , LAST_UPDATE_DATE
      , RISK_ELIMINATION_DAYS
      , GLOBAL_ATTRIBUTE5
      , GLOBAL_ATTRIBUTE4
      , STATUS
      , GLOBAL_ATTRIBUTE7
      , GL_ACCOUNT_SOURCE
      , GLOBAL_ATTRIBUTE6
      , GLOBAL_ATTRIBUTE1
      , GLOBAL_ATTRIBUTE3
      , GLOBAL_ATTRIBUTE2
      , GLOBAL_ATTRIBUTE9
      , TYPE
      , END_DATE_ACTIVE
      , GLOBAL_ATTRIBUTE8
      , CREATED_BY
      , ATTRIBUTE3
      , LAST_UPDATED_BY
      , ATTRIBUTE2
      , ATTRIBUTE1
      , CREATION_DATE
      , DEFAULT_ACCTG_DISTRIBUTION_SET
      , ATTRIBUTE9
      , ATTRIBUTE8
      , ATTRIBUTE7
      , ATTRIBUTE6
      , ATTRIBUTE5
      , NAME
      , ATTRIBUTE4
      , ATTRIBUTE_CATEGORY
      , TAX_RECOVERABLE_FLAG
      , ATTRIBUTE10
      , ATTRIBUTE14
      , ATTRIBUTE13
      , TAX_CODE_SOURCE
      , ATTRIBUTE12
      , ATTRIBUTE11
      , SET_OF_BOOKS_ID
      , LIABILITY_TAX_CODE
      , ACCOUNTING_AFFECT_FLAG
      , ASSET_TAX_CODE
      , DESCRIPTION
      , CODE_COMBINATION_ID
      , INACTIVE_DATE
      , START_DATE_ACTIVE
      , GLOBAL_ATTRIBUTE20
      , LAST_UPDATE_LOGIN
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
    WHERE rec_src = 'USWIOC.ORCL.EBSPRD.AR_RECEIVABLES_TRX_ALL'
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
          RECEIVABLES_BK
        , ORG_ID
        , RECEIVABLES_TRX_ID
        , GLOBAL_ATTRIBUTE10
        , LAST_UPDATE_DATE
        , RISK_ELIMINATION_DAYS
        , GLOBAL_ATTRIBUTE5
        , GLOBAL_ATTRIBUTE4
        , STATUS
        , GLOBAL_ATTRIBUTE7
        , GL_ACCOUNT_SOURCE
        , GLOBAL_ATTRIBUTE6
        , GLOBAL_ATTRIBUTE1
        , GLOBAL_ATTRIBUTE3
        , GLOBAL_ATTRIBUTE2
        , GLOBAL_ATTRIBUTE9
        , TYPE
        , END_DATE_ACTIVE
        , GLOBAL_ATTRIBUTE8
        , CREATED_BY
        , ATTRIBUTE3
        , LAST_UPDATED_BY
        , ATTRIBUTE2
        , ATTRIBUTE1
        , CREATION_DATE
        , DEFAULT_ACCTG_DISTRIBUTION_SET
        , ATTRIBUTE9
        , ATTRIBUTE8
        , ATTRIBUTE7
        , ATTRIBUTE6
        , ATTRIBUTE5
        , NAME
        , ATTRIBUTE4
        , ATTRIBUTE_CATEGORY
        , TAX_RECOVERABLE_FLAG
        , ATTRIBUTE10
        , ATTRIBUTE14
        , ATTRIBUTE13
        , TAX_CODE_SOURCE
        , ATTRIBUTE12
        , ATTRIBUTE11
        , SET_OF_BOOKS_ID
        , LIABILITY_TAX_CODE
        , ACCOUNTING_AFFECT_FLAG
        , ASSET_TAX_CODE
        , DESCRIPTION
        , CODE_COMBINATION_ID
        , INACTIVE_DATE
        , START_DATE_ACTIVE
        , GLOBAL_ATTRIBUTE20
        , LAST_UPDATE_LOGIN
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
              IFNULL(TRIM(GLOBAL_ATTRIBUTE10::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(RISK_ELIMINATION_DAYS::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE5::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE4::text), '^^') 
            , '||', IFNULL(TRIM(STATUS::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE7::text), '^^') 
            , '||', IFNULL(TRIM(GL_ACCOUNT_SOURCE::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE6::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE1::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE3::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE2::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE9::text), '^^') 
            , '||', IFNULL(TRIM(TYPE::text), '^^') 
            , '||', IFNULL(TRIM(END_DATE_ACTIVE::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE8::text), '^^') 
            , '||', IFNULL(TRIM(CREATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE3::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE2::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE1::text), '^^') 
            , '||', IFNULL(TRIM(CREATION_DATE::text), '^^') 
            , '||', IFNULL(TRIM(DEFAULT_ACCTG_DISTRIBUTION_SET::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE9::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE8::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE7::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE6::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE5::text), '^^') 
            , '||', IFNULL(TRIM(NAME::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE4::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(TAX_RECOVERABLE_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE10::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE14::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE13::text), '^^') 
            , '||', IFNULL(TRIM(TAX_CODE_SOURCE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE12::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE11::text), '^^') 
            , '||', IFNULL(TRIM(SET_OF_BOOKS_ID::text), '^^') 
            , '||', IFNULL(TRIM(LIABILITY_TAX_CODE::text), '^^') 
            , '||', IFNULL(TRIM(ACCOUNTING_AFFECT_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(ASSET_TAX_CODE::text), '^^') 
            , '||', IFNULL(TRIM(DESCRIPTION::text), '^^') 
            , '||', IFNULL(TRIM(CODE_COMBINATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(INACTIVE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(START_DATE_ACTIVE::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE20::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_LOGIN::text), '^^') 
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
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE19::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
