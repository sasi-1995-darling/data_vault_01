---- SRC LAYER ----
WITH
SRC_S              as ( SELECT ATTRIBUTE1, ATTRIBUTE10, ATTRIBUTE11, ATTRIBUTE12, ATTRIBUTE13, ATTRIBUTE14, ATTRIBUTE15, ATTRIBUTE2, ATTRIBUTE3, ATTRIBUTE4, ATTRIBUTE5, ATTRIBUTE6, ATTRIBUTE7, ATTRIBUTE8, ATTRIBUTE9, ATTRIBUTE_CATEGORY, CALENDAR, CREATED_BY, CREATION_DATE, DISCOUNT_AMOUNT, DISCOUNT_AMOUNT_2, DISCOUNT_AMOUNT_3, DISCOUNT_CRITERIA, DISCOUNT_CRITERIA_2, DISCOUNT_CRITERIA_3, DISCOUNT_DAYS, DISCOUNT_DAYS_2, DISCOUNT_DAYS_3, DISCOUNT_DAY_OF_MONTH, DISCOUNT_DAY_OF_MONTH_2, DISCOUNT_DAY_OF_MONTH_3, DISCOUNT_MONTHS_FORWARD, DISCOUNT_MONTHS_FORWARD_2, DISCOUNT_MONTHS_FORWARD_3, DISCOUNT_PERCENT, DISCOUNT_PERCENT_2, DISCOUNT_PERCENT_3, DUE_AMOUNT, DUE_DAYS, DUE_DAY_OF_MONTH, DUE_MONTHS_FORWARD, DUE_PERCENT, FIXED_DATE, LAST_UPDATED_BY, LAST_UPDATE_DATE, LAST_UPDATE_LOGIN, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, SEQUENCE_NUM, TERM_ID, _FIVETRAN_DELETED, _FIVETRAN_ID, _FIVETRAN_SYNCED FROM {{ source('ml_ebs_ap', 'ap_terms_lines') }} as SRC  ),
SRC_A              as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S              as ( SELECT * FROM ml_ebs_ap.AP_TERMS_LINES )
SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        TERM_ID::TEXT                                                as                                    PAYMENT_TERM_BK
      , TERM_ID
      , SEQUENCE_NUM
      , ATTRIBUTE10
      , DISCOUNT_AMOUNT_3
      , DISCOUNT_AMOUNT_2
      , DISCOUNT_CRITERIA_3
      , DISCOUNT_CRITERIA_2
      , DISCOUNT_PERCENT_3
      , ATTRIBUTE14
      , DISCOUNT_PERCENT_2
      , ATTRIBUTE13
      , ATTRIBUTE12
      , ATTRIBUTE11
      , DISCOUNT_MONTHS_FORWARD_2
      , DISCOUNT_MONTHS_FORWARD_3
      , DUE_AMOUNT
      , FIXED_DATE
      , LAST_UPDATE_DATE
      , DUE_PERCENT
      , DISCOUNT_PERCENT
      , DISCOUNT_DAYS
      , DISCOUNT_DAY_OF_MONTH_2
      , DISCOUNT_DAY_OF_MONTH_3
      , DISCOUNT_CRITERIA
      , CREATED_BY
      , DISCOUNT_MONTHS_FORWARD
      , DISCOUNT_DAYS_3
      , ATTRIBUTE3
      , LAST_UPDATED_BY
      , DISCOUNT_DAYS_2
      , ATTRIBUTE2
      , ATTRIBUTE1
      , CREATION_DATE
      , ATTRIBUTE9
      , LAST_UPDATE_LOGIN
      , ATTRIBUTE8
      , ATTRIBUTE7
      , ATTRIBUTE6
      , DUE_MONTHS_FORWARD
      , ATTRIBUTE5
      , ATTRIBUTE4
      , DISCOUNT_DAY_OF_MONTH
      , ATTRIBUTE_CATEGORY
      , DUE_DAYS
      , DUE_DAY_OF_MONTH
      , DISCOUNT_AMOUNT
      , CALENDAR
      , ATTRIBUTE15
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
      , SEQUENCE_NUM
      , ATTRIBUTE10
      , DISCOUNT_AMOUNT_3
      , DISCOUNT_AMOUNT_2
      , DISCOUNT_CRITERIA_3
      , DISCOUNT_CRITERIA_2
      , DISCOUNT_PERCENT_3
      , ATTRIBUTE14
      , DISCOUNT_PERCENT_2
      , ATTRIBUTE13
      , ATTRIBUTE12
      , ATTRIBUTE11
      , DISCOUNT_MONTHS_FORWARD_2
      , DISCOUNT_MONTHS_FORWARD_3
      , DUE_AMOUNT
      , FIXED_DATE
      , LAST_UPDATE_DATE
      , DUE_PERCENT
      , DISCOUNT_PERCENT
      , DISCOUNT_DAYS
      , DISCOUNT_DAY_OF_MONTH_2
      , DISCOUNT_DAY_OF_MONTH_3
      , DISCOUNT_CRITERIA
      , CREATED_BY
      , DISCOUNT_MONTHS_FORWARD
      , DISCOUNT_DAYS_3
      , ATTRIBUTE3
      , LAST_UPDATED_BY
      , DISCOUNT_DAYS_2
      , ATTRIBUTE2
      , ATTRIBUTE1
      , CREATION_DATE
      , ATTRIBUTE9
      , LAST_UPDATE_LOGIN
      , ATTRIBUTE8
      , ATTRIBUTE7
      , ATTRIBUTE6
      , DUE_MONTHS_FORWARD
      , ATTRIBUTE5
      , ATTRIBUTE4
      , DISCOUNT_DAY_OF_MONTH
      , ATTRIBUTE_CATEGORY
      , DUE_DAYS
      , DUE_DAY_OF_MONTH
      , DISCOUNT_AMOUNT
      , CALENDAR
      , ATTRIBUTE15
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
    WHERE rec_src = 'USWIOC.ORCL.EBSPRD.AP_TERMS_LINES'
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
        , SEQUENCE_NUM
        , ATTRIBUTE10
        , DISCOUNT_AMOUNT_3
        , DISCOUNT_AMOUNT_2
        , DISCOUNT_CRITERIA_3
        , DISCOUNT_CRITERIA_2
        , DISCOUNT_PERCENT_3
        , ATTRIBUTE14
        , DISCOUNT_PERCENT_2
        , ATTRIBUTE13
        , ATTRIBUTE12
        , ATTRIBUTE11
        , DISCOUNT_MONTHS_FORWARD_2
        , DISCOUNT_MONTHS_FORWARD_3
        , DUE_AMOUNT
        , FIXED_DATE
        , LAST_UPDATE_DATE
        , DUE_PERCENT
        , DISCOUNT_PERCENT
        , DISCOUNT_DAYS
        , DISCOUNT_DAY_OF_MONTH_2
        , DISCOUNT_DAY_OF_MONTH_3
        , DISCOUNT_CRITERIA
        , CREATED_BY
        , DISCOUNT_MONTHS_FORWARD
        , DISCOUNT_DAYS_3
        , ATTRIBUTE3
        , LAST_UPDATED_BY
        , DISCOUNT_DAYS_2
        , ATTRIBUTE2
        , ATTRIBUTE1
        , CREATION_DATE
        , ATTRIBUTE9
        , LAST_UPDATE_LOGIN
        , ATTRIBUTE8
        , ATTRIBUTE7
        , ATTRIBUTE6
        , DUE_MONTHS_FORWARD
        , ATTRIBUTE5
        , ATTRIBUTE4
        , DISCOUNT_DAY_OF_MONTH
        , ATTRIBUTE_CATEGORY
        , DUE_DAYS
        , DUE_DAY_OF_MONTH
        , DISCOUNT_AMOUNT
        , CALENDAR
        , ATTRIBUTE15
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
              IFNULL(TRIM(SEQUENCE_NUM::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE10::text), '^^') 
            , '||', IFNULL(TRIM(DISCOUNT_AMOUNT_3::text), '^^') 
            , '||', IFNULL(TRIM(DISCOUNT_AMOUNT_2::text), '^^') 
            , '||', IFNULL(TRIM(DISCOUNT_CRITERIA_3::text), '^^') 
            , '||', IFNULL(TRIM(DISCOUNT_CRITERIA_2::text), '^^') 
            , '||', IFNULL(TRIM(DISCOUNT_PERCENT_3::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE14::text), '^^') 
            , '||', IFNULL(TRIM(DISCOUNT_PERCENT_2::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE13::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE12::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE11::text), '^^') 
            , '||', IFNULL(TRIM(DISCOUNT_MONTHS_FORWARD_2::text), '^^') 
            , '||', IFNULL(TRIM(DISCOUNT_MONTHS_FORWARD_3::text), '^^') 
            , '||', IFNULL(TRIM(DUE_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(FIXED_DATE::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(DUE_PERCENT::text), '^^') 
            , '||', IFNULL(TRIM(DISCOUNT_PERCENT::text), '^^') 
            , '||', IFNULL(TRIM(DISCOUNT_DAYS::text), '^^') 
            , '||', IFNULL(TRIM(DISCOUNT_DAY_OF_MONTH_2::text), '^^') 
            , '||', IFNULL(TRIM(DISCOUNT_DAY_OF_MONTH_3::text), '^^') 
            , '||', IFNULL(TRIM(DISCOUNT_CRITERIA::text), '^^') 
            , '||', IFNULL(TRIM(CREATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(DISCOUNT_MONTHS_FORWARD::text), '^^') 
            , '||', IFNULL(TRIM(DISCOUNT_DAYS_3::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE3::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(DISCOUNT_DAYS_2::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE2::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE1::text), '^^') 
            , '||', IFNULL(TRIM(CREATION_DATE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE9::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_LOGIN::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE8::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE7::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE6::text), '^^') 
            , '||', IFNULL(TRIM(DUE_MONTHS_FORWARD::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE5::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE4::text), '^^') 
            , '||', IFNULL(TRIM(DISCOUNT_DAY_OF_MONTH::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(DUE_DAYS::text), '^^') 
            , '||', IFNULL(TRIM(DUE_DAY_OF_MONTH::text), '^^') 
            , '||', IFNULL(TRIM(DISCOUNT_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(CALENDAR::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE15::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
