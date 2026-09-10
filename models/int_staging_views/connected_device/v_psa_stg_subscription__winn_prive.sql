---- SRC LAYER ----
WITH
SRC_D1             as ( SELECT BILLING_ADDRESS_1, BILLING_CADENCE_COUNT, BILLING_CADENCE_UNIT, BILLING_CITY, BILLING_COUNTRY, BILLING_FIRST_NAME, BILLING_LAST_NAME, BILLING_PROVINCE, BILLING_ZIP, CANCEL_DATE, CANCEL_REASON, CREATED_AT, CURRENCY_CODE, DELIVERY_CADENCE_COUNT, DELIVERY_CADENCE_UNIT, DELIVERY_PRICE, EXTERNAL_ID, FRIENDLY_ID, ID, IS_PREPAID, NEXT_BILLING_DATE, NEXT_DELIVERY_DATE, PAYMENT_METHOD_BRAND, PAYMENT_METHOD_EXPIRY_MONTH, PAYMENT_METHOD_EXPIRY_YEAR, PAYMENT_METHOD_EXTERNAL_ID, PAYMENT_METHOD_LAST_4_DIGIT, PAYMENT_METHOD_NAME, PAYMENT_METHOD_TYPE, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, PURCHASE_DATE, STATUS, SUBSCRIBER_ID, UPDATED_AT, _FIVETRAN_DELETED, _FIVETRAN_SYNCED FROM {{ source('prive_moen', 'subscription') }} as SRC  ),
SRC_A1             as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_D1             as ( SELECT * FROM PRIVE_MOEN.SUBSCRIPTION )
SRC_A1             as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_D1 as (
    SELECT
        ID                                                           as                                    SUBSCRIPTION_BK
      , CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED)                    as                                           LOAD_DTS
      , ID
      , _FIVETRAN_DELETED
      , SUBSCRIBER_ID
      , _FIVETRAN_SYNCED
      , PAYMENT_METHOD_TYPE
      , BILLING_LAST_NAME
      , CREATED_AT
      , EXTERNAL_ID
      , PAYMENT_METHOD_EXPIRY_MONTH
      , DELIVERY_CADENCE_COUNT
      , CURRENCY_CODE
      , BILLING_PROVINCE
      , PAYMENT_METHOD_BRAND
      , UPDATED_AT
      , BILLING_CADENCE_UNIT
      , BILLING_ADDRESS_1
      , PAYMENT_METHOD_EXPIRY_YEAR
      , FRIENDLY_ID
      , BILLING_FIRST_NAME
      , NEXT_BILLING_DATE
      , BILLING_COUNTRY
      , IS_PREPAID
      , PAYMENT_METHOD_NAME
      , DELIVERY_CADENCE_UNIT
      , BILLING_CITY
      , NEXT_DELIVERY_DATE
      , PAYMENT_METHOD_LAST_4_DIGIT
      , BILLING_CADENCE_COUNT
      , PAYMENT_METHOD_EXTERNAL_ID
      , PURCHASE_DATE
      , STATUS
      , DELIVERY_PRICE
      , BILLING_ZIP
      , CANCEL_REASON
      , CANCEL_DATE
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
    FROM SRC_D1
)

, LOGIC_A1 as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_A1
)
---- RENAME LAYER ----

, RENAME_D1 as (
    SELECT
        SUBSCRIPTION_BK
      , LOAD_DTS
      , ID
      , _FIVETRAN_DELETED
      , SUBSCRIBER_ID
      , _FIVETRAN_SYNCED
      , PAYMENT_METHOD_TYPE
      , BILLING_LAST_NAME
      , CREATED_AT
      , EXTERNAL_ID
      , PAYMENT_METHOD_EXPIRY_MONTH
      , DELIVERY_CADENCE_COUNT
      , CURRENCY_CODE
      , BILLING_PROVINCE
      , PAYMENT_METHOD_BRAND
      , UPDATED_AT
      , BILLING_CADENCE_UNIT
      , BILLING_ADDRESS_1
      , PAYMENT_METHOD_EXPIRY_YEAR
      , FRIENDLY_ID
      , BILLING_FIRST_NAME
      , NEXT_BILLING_DATE
      , BILLING_COUNTRY
      , IS_PREPAID
      , PAYMENT_METHOD_NAME
      , DELIVERY_CADENCE_UNIT
      , BILLING_CITY
      , NEXT_DELIVERY_DATE
      , PAYMENT_METHOD_LAST_4_DIGIT
      , BILLING_CADENCE_COUNT
      , PAYMENT_METHOD_EXTERNAL_ID
      , PURCHASE_DATE
      , STATUS
      , DELIVERY_PRICE
      , BILLING_ZIP
      , CANCEL_REASON
      , CANCEL_DATE
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
    FROM LOGIC_D1
)

, RENAME_A1 as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_A1
)
---- FILTER LAYER ----

, FILTER_D1 as (
    SELECT *
    FROM RENAME_D1
)

, FILTER_A1 as (
    SELECT *
    FROM RENAME_A1
    WHERE rec_src = 'US.PRIVE_MOEN.SUBSCRIPTION'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_D1
    INNER JOIN FILTER_A1
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          SUBSCRIPTION_BK
        , LOAD_DTS
        , ID
        , _FIVETRAN_DELETED
        , SUBSCRIBER_ID
        , _FIVETRAN_SYNCED
        , PAYMENT_METHOD_TYPE
        , BILLING_LAST_NAME
        , CREATED_AT
        , EXTERNAL_ID
        , PAYMENT_METHOD_EXPIRY_MONTH
        , DELIVERY_CADENCE_COUNT
        , CURRENCY_CODE
        , BILLING_PROVINCE
        , PAYMENT_METHOD_BRAND
        , UPDATED_AT
        , BILLING_CADENCE_UNIT
        , BILLING_ADDRESS_1
        , PAYMENT_METHOD_EXPIRY_YEAR
        , FRIENDLY_ID
        , BILLING_FIRST_NAME
        , NEXT_BILLING_DATE
        , BILLING_COUNTRY
        , IS_PREPAID
        , PAYMENT_METHOD_NAME
        , DELIVERY_CADENCE_UNIT
        , BILLING_CITY
        , NEXT_DELIVERY_DATE
        , PAYMENT_METHOD_LAST_4_DIGIT
        , BILLING_CADENCE_COUNT
        , PAYMENT_METHOD_EXTERNAL_ID
        , PURCHASE_DATE
        , STATUS
        , DELIVERY_PRICE
        , BILLING_ZIP
        , CANCEL_REASON
        , CANCEL_DATE
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(SUBSCRIPTION_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as SUBSCRIPTION_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(SUBSCRIBER_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as SUBSCRIBER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(SUBSCRIBER_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as LNK_SUBSCRIBER_SUBSCRIPTION_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
            , '||', IFNULL(TRIM(PAYMENT_METHOD_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(BILLING_LAST_NAME::text), '^^') 
            , '||', IFNULL(TRIM(CREATED_AT::text), '^^') 
            , '||', IFNULL(TRIM(EXTERNAL_ID::text), '^^') 
            , '||', IFNULL(TRIM(PAYMENT_METHOD_EXPIRY_MONTH::text), '^^') 
            , '||', IFNULL(TRIM(DELIVERY_CADENCE_COUNT::text), '^^') 
            , '||', IFNULL(TRIM(CURRENCY_CODE::text), '^^') 
            , '||', IFNULL(TRIM(BILLING_PROVINCE::text), '^^') 
            , '||', IFNULL(TRIM(PAYMENT_METHOD_BRAND::text), '^^') 
            , '||', IFNULL(TRIM(UPDATED_AT::text), '^^') 
            , '||', IFNULL(TRIM(BILLING_CADENCE_UNIT::text), '^^') 
            , '||', IFNULL(TRIM(BILLING_ADDRESS_1::text), '^^') 
            , '||', IFNULL(TRIM(PAYMENT_METHOD_EXPIRY_YEAR::text), '^^') 
            , '||', IFNULL(TRIM(FRIENDLY_ID::text), '^^') 
            , '||', IFNULL(TRIM(BILLING_FIRST_NAME::text), '^^') 
            , '||', IFNULL(TRIM(NEXT_BILLING_DATE::text), '^^') 
            , '||', IFNULL(TRIM(BILLING_COUNTRY::text), '^^') 
            , '||', IFNULL(TRIM(IS_PREPAID::text), '^^') 
            , '||', IFNULL(TRIM(PAYMENT_METHOD_NAME::text), '^^') 
            , '||', IFNULL(TRIM(DELIVERY_CADENCE_UNIT::text), '^^') 
            , '||', IFNULL(TRIM(BILLING_CITY::text), '^^') 
            , '||', IFNULL(TRIM(NEXT_DELIVERY_DATE::text), '^^') 
            , '||', IFNULL(TRIM(PAYMENT_METHOD_LAST_4_DIGIT::text), '^^') 
            , '||', IFNULL(TRIM(BILLING_CADENCE_COUNT::text), '^^') 
            , '||', IFNULL(TRIM(PAYMENT_METHOD_EXTERNAL_ID::text), '^^') 
            , '||', IFNULL(TRIM(PURCHASE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(STATUS::text), '^^') 
            , '||', IFNULL(TRIM(DELIVERY_PRICE::text), '^^') 
            , '||', IFNULL(TRIM(BILLING_ZIP::text), '^^') 
            , '||', IFNULL(TRIM(CANCEL_REASON::text), '^^') 
            , '||', IFNULL(TRIM(CANCEL_DATE::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
