---- SRC LAYER ----
WITH
SRC_S1             as ( SELECT APP_ID, APP_STORE_ID, AUTHOR, BODY, COUNTRY, COUNTRY_CODE, COUNTRY_ID, DETECTED_LANGUAGE, DETECTED_LANGUAGE_ID, DEVICE, DEVICE_FRIENDLY_NAME, ID, INTERNAL_URL, OS_VERSION, OS_VERSION_FRIENDLY_NAME, PERMALINK_URL, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, PUBLISHED_AT, PUBLISHED_AT_DATETIME, RATING, REPLY_DATE, REPLY_TEXT, REPLY_URL, SENTIMENT, STORE_ID, SUBJECT, TOPICS, TOPIC_IDS, TRANSLATED_BODY, TRANSLATED_SUBJECT, VERSION, _FIVETRAN_SYNCED FROM {{ source('custom_fivetran_appbot_sdk', 'reviews') }} as SRC 
                        WHERE PSA_DELETE_IND = 'N' ),
SRC_A1             as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  ),
SRC_C              as ( SELECT CUTOFF_DT FROM {{ ref('v_psa_stg_ref_appbot_talend_migration_cutoff_date') }} as SRC  ),
SRC_S2             as ( SELECT ID, IDENTIFIER, STORE FROM {{ source('custom_fivetran_appbot_sdk', 'apps') }} as SRC  )

/*
SRC_S1             as ( SELECT * FROM custom_fivetran_appbot_sdk.reviews )
SRC_A1             as ( SELECT * FROM raw_vault.ref_business_key_collision )
SRC_C              as ( SELECT * FROM raw_vault.v_psa_stg_ref_appbot_talend_migration_cutoff_date )
SRC_S2             as ( SELECT * FROM custom_fivetran_appbot_sdk.apps )
*/
---- LOGIC LAYER ----

, LOGIC_S1 as (
    SELECT
        CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED)                    as                                           LOAD_DTS
      , APP_ID
      , APP_STORE_ID
      , ID
      , AUTHOR
      , RATING
      , BODY
      , SUBJECT
      , PUBLISHED_AT
      , PUBLISHED_AT_DATETIME
      , VERSION
      , COUNTRY
      , COUNTRY_ID
      , COUNTRY_CODE
      , TRANSLATED_SUBJECT
      , TRANSLATED_BODY
      , REPLY_TEXT
      , REPLY_DATE
      , TOPICS
      , TOPIC_IDS
      , STORE_ID
      , DEVICE
      , DEVICE_FRIENDLY_NAME
      , OS_VERSION
      , OS_VERSION_FRIENDLY_NAME
      , SENTIMENT
      , DETECTED_LANGUAGE
      , DETECTED_LANGUAGE_ID
      , PERMALINK_URL
      , REPLY_URL
      , INTERNAL_URL
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , _FIVETRAN_SYNCED
    FROM SRC_S1
)

, LOGIC_A1 as (
    SELECT
        BKCC
      , REC_SRC
    FROM SRC_A1
)

, LOGIC_C as (
    SELECT
        CUTOFF_DT
    FROM SRC_C
)

, LOGIC_S2 as (
    SELECT
        STORE                                                        as                                        RETAILER_BK
      , IDENTIFIER                                                   as                                         PRODUCT_BK
      , ID                                                           as                                          S2_APP_ID
    FROM SRC_S2
)
---- RENAME LAYER ----

, RENAME_S2 as (
    SELECT
        RETAILER_BK
      , PRODUCT_BK
      , S2_APP_ID
    FROM LOGIC_S2
)

, RENAME_S1 as (
    SELECT
        LOAD_DTS
      , APP_ID
      , APP_STORE_ID
      , ID
      , AUTHOR
      , RATING
      , BODY
      , SUBJECT
      , PUBLISHED_AT
      , PUBLISHED_AT_DATETIME
      , VERSION
      , COUNTRY
      , COUNTRY_ID
      , COUNTRY_CODE
      , TRANSLATED_SUBJECT
      , TRANSLATED_BODY
      , REPLY_TEXT
      , REPLY_DATE
      , TOPICS
      , TOPIC_IDS
      , STORE_ID
      , DEVICE
      , DEVICE_FRIENDLY_NAME
      , OS_VERSION
      , OS_VERSION_FRIENDLY_NAME
      , SENTIMENT
      , DETECTED_LANGUAGE
      , DETECTED_LANGUAGE_ID
      , PERMALINK_URL
      , REPLY_URL
      , INTERNAL_URL
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , _FIVETRAN_SYNCED
    FROM LOGIC_S1
)

, RENAME_A1 as (
    SELECT
        BKCC
      , REC_SRC
    FROM LOGIC_A1
)

, RENAME_C as (
    SELECT
        CUTOFF_DT
    FROM LOGIC_C
)
---- FILTER LAYER ----

, FILTER_S1 as (
    SELECT *
    FROM RENAME_S1
)

, FILTER_A1 as (
    SELECT *
    FROM RENAME_A1
    WHERE rec_src = 'US.APPBOT_FT.REVIEWS'
)

, FILTER_C as (
    SELECT *
    FROM RENAME_C
)

, FILTER_S2 as (
    SELECT *
    FROM RENAME_S2
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_S1
    INNER JOIN FILTER_A1
        ON '1' = '1'
    INNER JOIN FILTER_C
        ON '1' = '1'
    LEFT JOIN FILTER_S2
        ON APP_ID = S2_APP_ID
)

---- FINAL LAYER ----
SELECT
          RETAILER_BK
        , PRODUCT_BK
        , LOAD_DTS
        , APP_ID
        , APP_STORE_ID
        , ID
        , AUTHOR
        , RATING
        , BODY
        , SUBJECT
        , PUBLISHED_AT
        , PUBLISHED_AT_DATETIME
        , VERSION
        , COUNTRY
        , COUNTRY_ID
        , COUNTRY_CODE
        , TRANSLATED_SUBJECT
        , TRANSLATED_BODY
        , REPLY_TEXT
        , REPLY_DATE
        , TOPICS
        , TOPIC_IDS
        , STORE_ID
        , DEVICE
        , DEVICE_FRIENDLY_NAME
        , OS_VERSION
        , OS_VERSION_FRIENDLY_NAME
        , SENTIMENT
        , DETECTED_LANGUAGE
        , DETECTED_LANGUAGE_ID
        , PERMALINK_URL
        , REPLY_URL
        , INTERNAL_URL
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , BKCC
        , REC_SRC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PRODUCT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(RETAILER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PRODUCT_RETAILER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PRODUCT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PRODUCT_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(RETAILER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as RETAILER_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(APP_ID::text), '^^') 
            , '||', IFNULL(TRIM(APP_STORE_ID::text), '^^') 
            , '||', IFNULL(TRIM(ID::text), '^^') 
            , '||', IFNULL(TRIM(AUTHOR::text), '^^') 
            , '||', IFNULL(TRIM(RATING::text), '^^') 
            , '||', IFNULL(TRIM(BODY::text), '^^') 
            , '||', IFNULL(TRIM(SUBJECT::text), '^^') 
            , '||', IFNULL(TRIM(PUBLISHED_AT::text), '^^') 
            , '||', IFNULL(TRIM(PUBLISHED_AT_DATETIME::text), '^^') 
            , '||', IFNULL(TRIM(VERSION::text), '^^') 
            , '||', IFNULL(TRIM(COUNTRY::text), '^^') 
            , '||', IFNULL(TRIM(COUNTRY_ID::text), '^^') 
            , '||', IFNULL(TRIM(COUNTRY_CODE::text), '^^') 
            , '||', IFNULL(TRIM(TRANSLATED_SUBJECT::text), '^^') 
            , '||', IFNULL(TRIM(TRANSLATED_BODY::text), '^^') 
            , '||', IFNULL(TRIM(REPLY_TEXT::text), '^^') 
            , '||', IFNULL(TRIM(REPLY_DATE::text), '^^') 
            , '||', IFNULL(TRIM(TOPICS::text), '^^') 
            , '||', IFNULL(TRIM(TOPIC_IDS::text), '^^') 
            , '||', IFNULL(TRIM(STORE_ID::text), '^^') 
            , '||', IFNULL(TRIM(DEVICE::text), '^^') 
            , '||', IFNULL(TRIM(DEVICE_FRIENDLY_NAME::text), '^^') 
            , '||', IFNULL(TRIM(OS_VERSION::text), '^^') 
            , '||', IFNULL(TRIM(OS_VERSION_FRIENDLY_NAME::text), '^^') 
            , '||', IFNULL(TRIM(SENTIMENT::text), '^^') 
            , '||', IFNULL(TRIM(DETECTED_LANGUAGE::text), '^^') 
            , '||', IFNULL(TRIM(DETECTED_LANGUAGE_ID::text), '^^') 
            , '||', IFNULL(TRIM(PERMALINK_URL::text), '^^') 
            , '||', IFNULL(TRIM(REPLY_URL::text), '^^') 
            , '||', IFNULL(TRIM(INTERNAL_URL::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
WHERE TO_DATE(PUBLISHED_AT) > CUTOFF_DT