---- SRC LAYER ----
WITH
SRC_S              as ( SELECT ATTRIBUTE1, ATTRIBUTE10, ATTRIBUTE11, ATTRIBUTE12, ATTRIBUTE13, ATTRIBUTE14, ATTRIBUTE15, ATTRIBUTE2, ATTRIBUTE3, ATTRIBUTE4, ATTRIBUTE5, ATTRIBUTE6, ATTRIBUTE7, ATTRIBUTE8, ATTRIBUTE9, ATTRIBUTE_CATEGORY, CREATED_BY, CREATION_DATE, DESCRIPTION, DUE_CUTOFF_DAY, ENABLED_FLAG, END_DATE_ACTIVE, LANGUAGE, LAST_UPDATED_BY, LAST_UPDATE_DATE, LAST_UPDATE_LOGIN, NAME, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, RANK, SOURCE_LANG, START_DATE_ACTIVE, TERM_ID, TYPE, _FIVETRAN_DELETED, _FIVETRAN_ID, _FIVETRAN_SYNCED FROM {{ source('ml_ebs_ap', 'ap_terms_tl') }} as SRC  ),
SRC_A              as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S              as ( SELECT * FROM ml_ebs_ap.AP_TERMS_TL )
SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        TERM_ID::TEXT                                                as                                    PAYMENT_TERM_BK
      , TERM_ID
      , LANGUAGE
      , ATTRIBUTE10
      , ATTRIBUTE14
      , ATTRIBUTE13
      , ATTRIBUTE12
      , ATTRIBUTE11
      , RANK
      , DESCRIPTION
      , SOURCE_LANG
      , TYPE
      , END_DATE_ACTIVE
      , CREATED_BY
      , ATTRIBUTE3
      , LAST_UPDATED_BY
      , ATTRIBUTE2
      , START_DATE_ACTIVE
      , ATTRIBUTE1
      , ATTRIBUTE9
      , LAST_UPDATE_LOGIN
      , ATTRIBUTE8
      , ENABLED_FLAG
      , ATTRIBUTE7
      , ATTRIBUTE6
      , ATTRIBUTE5
      , NAME
      , ATTRIBUTE4
      , DUE_CUTOFF_DAY
      , ATTRIBUTE_CATEGORY
      , ATTRIBUTE15
      , CREATION_DATE
      , LAST_UPDATE_DATE
      , _FIVETRAN_ID
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED)                    as                                           LOAD_DTS
    FROM SRC_S
)

, LOGIC_A as (
    SELECT
        BKCC
      , REC_SRC
    FROM SRC_A
)
---- RENAME LAYER ----

, RENAME_S as (
    SELECT
        PAYMENT_TERM_BK
      , TERM_ID
      , LANGUAGE
      , ATTRIBUTE10
      , ATTRIBUTE14
      , ATTRIBUTE13
      , ATTRIBUTE12
      , ATTRIBUTE11
      , RANK
      , DESCRIPTION
      , SOURCE_LANG
      , TYPE
      , END_DATE_ACTIVE
      , CREATED_BY
      , ATTRIBUTE3
      , LAST_UPDATED_BY
      , ATTRIBUTE2
      , START_DATE_ACTIVE
      , ATTRIBUTE1
      , ATTRIBUTE9
      , LAST_UPDATE_LOGIN
      , ATTRIBUTE8
      , ENABLED_FLAG
      , ATTRIBUTE7
      , ATTRIBUTE6
      , ATTRIBUTE5
      , NAME
      , ATTRIBUTE4
      , DUE_CUTOFF_DAY
      , ATTRIBUTE_CATEGORY
      , ATTRIBUTE15
      , CREATION_DATE
      , LAST_UPDATE_DATE
      , _FIVETRAN_ID
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
    FROM LOGIC_S
)

, RENAME_A as (
    SELECT
        BKCC
      , REC_SRC
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
    WHERE rec_src = 'USWIOC.ORCL.EBSPRD.AP_TERMS_TL'
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
          PAYMENT_TERM_BK
        , TERM_ID
        , LANGUAGE
        , ATTRIBUTE10
        , ATTRIBUTE14
        , ATTRIBUTE13
        , ATTRIBUTE12
        , ATTRIBUTE11
        , RANK
        , DESCRIPTION
        , SOURCE_LANG
        , TYPE
        , END_DATE_ACTIVE
        , CREATED_BY
        , ATTRIBUTE3
        , LAST_UPDATED_BY
        , ATTRIBUTE2
        , START_DATE_ACTIVE
        , ATTRIBUTE1
        , ATTRIBUTE9
        , LAST_UPDATE_LOGIN
        , ATTRIBUTE8
        , ENABLED_FLAG
        , ATTRIBUTE7
        , ATTRIBUTE6
        , ATTRIBUTE5
        , NAME
        , ATTRIBUTE4
        , DUE_CUTOFF_DAY
        , ATTRIBUTE_CATEGORY
        , ATTRIBUTE15
        , CREATION_DATE
        , LAST_UPDATE_DATE
        , _FIVETRAN_ID
        , _FIVETRAN_DELETED
        , _FIVETRAN_SYNCED
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , BKCC
        , REC_SRC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(TERM_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PAYMENT_TERM_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(LANGUAGE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE10::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE14::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE13::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE12::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE11::text), '^^') 
            , '||', IFNULL(TRIM(RANK::text), '^^') 
            , '||', IFNULL(TRIM(DESCRIPTION::text), '^^') 
            , '||', IFNULL(TRIM(SOURCE_LANG::text), '^^') 
            , '||', IFNULL(TRIM(TYPE::text), '^^') 
            , '||', IFNULL(TRIM(END_DATE_ACTIVE::text), '^^') 
            , '||', IFNULL(TRIM(CREATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE3::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE2::text), '^^') 
            , '||', IFNULL(TRIM(START_DATE_ACTIVE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE1::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE9::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_LOGIN::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE8::text), '^^') 
            , '||', IFNULL(TRIM(ENABLED_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE7::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE6::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE5::text), '^^') 
            , '||', IFNULL(TRIM(NAME::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE4::text), '^^') 
            , '||', IFNULL(TRIM(DUE_CUTOFF_DAY::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE15::text), '^^') 
            , '||', IFNULL(TRIM(CREATION_DATE::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
