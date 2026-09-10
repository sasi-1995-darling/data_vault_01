---- SRC LAYER ----
WITH
SRC_S1             as ( SELECT * FROM {{ source('delighted_yale_psa', 'response') }} as SRC  ),
SRC_A1             as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S1             as ( SELECT * FROM delighted_yale_psa.response )
, SRC_A1             as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S1 as (
    SELECT
        COALESCE(PROPERTIES_SKUNUMBER,'0')                           as                                         PRODUCT_BK
      , CONVERT_TIMEZONE('UTC',to_timestamp(cast(updated_at as varchar))) as                                           LOAD_DTS
      , ID
      , _FIVETRAN_DELETED
      , PERSON_ID
      , _FIVETRAN_SYNCED
      , PROPERTIES_DELIGHTED_BROWSER
      , PROPERTIES_DELIGHTED_SOURCE
      , CREATED_AT
      , PROPERTIES_DELIGHTED_OPERATING_SYSTEM
      , SURVEY_TYPE
      , SCORE
      , UPDATED_AT
      , COMMENT
      , PERMALINK
      , PROPERTIES_DELIGHTED_DEVICE_TYPE
      , PROPERTIES_LOCK_TYPE
      , PROPERTIES_SKUNUMBER
      , PROPERTIES_LAST_NAME
      , PROPERTIES_APP_BRAND
      , PROPERTIES_FIRST_NAME
      , PROPERTIES_LOCK_SERIAL_NUMBER
      , PROPERTIES_DAYS_SINCE_LOCK_SETUP
      , PROPERTIES_PRODUCT_NAME
      , PROPERTIES_TECHNOLOGY
      , PROPERTIES_SHOPIFY_PRODUCT_NAME
      , PROPERTIES_PARENT_ID
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
    FROM SRC_S1
)

, LOGIC_A1 as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_A1
)
---- RENAME LAYER ----

, RENAME_S1 as (
    SELECT
        PRODUCT_BK
      , LOAD_DTS
      , ID
      , _FIVETRAN_DELETED
      , PERSON_ID
      , _FIVETRAN_SYNCED
      , PROPERTIES_DELIGHTED_BROWSER
      , PROPERTIES_DELIGHTED_SOURCE
      , CREATED_AT
      , PROPERTIES_DELIGHTED_OPERATING_SYSTEM
      , SURVEY_TYPE
      , SCORE
      , UPDATED_AT
      , COMMENT
      , PERMALINK
      , PROPERTIES_DELIGHTED_DEVICE_TYPE
      , PROPERTIES_LOCK_TYPE
      , PROPERTIES_SKUNUMBER
      , PROPERTIES_LAST_NAME
      , PROPERTIES_APP_BRAND
      , PROPERTIES_FIRST_NAME
      , PROPERTIES_LOCK_SERIAL_NUMBER
      , PROPERTIES_DAYS_SINCE_LOCK_SETUP
      , PROPERTIES_PRODUCT_NAME
      , PROPERTIES_TECHNOLOGY
      , PROPERTIES_SHOPIFY_PRODUCT_NAME
      , PROPERTIES_PARENT_ID
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
    FROM LOGIC_S1
)

, RENAME_A1 as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_A1
)
---- FILTER LAYER ----

, FILTER_S1 as (
    SELECT *
    FROM RENAME_S1
)

, FILTER_A1 as (
    SELECT *
    FROM RENAME_A1
    WHERE rec_src = 'US.DELIGHTED_YALE.RESPONSE'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_S1
    INNER JOIN FILTER_A1
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          PRODUCT_BK
        , LOAD_DTS
        , ID
        , _FIVETRAN_DELETED
        , PERSON_ID
        , _FIVETRAN_SYNCED
        , PROPERTIES_DELIGHTED_BROWSER
        , PROPERTIES_DELIGHTED_SOURCE
        , CREATED_AT
        , PROPERTIES_DELIGHTED_OPERATING_SYSTEM
        , SURVEY_TYPE
        , SCORE
        , UPDATED_AT
        , COMMENT
        , PERMALINK
        , PROPERTIES_DELIGHTED_DEVICE_TYPE
        , PROPERTIES_LOCK_TYPE
        , PROPERTIES_SKUNUMBER
        , PROPERTIES_LAST_NAME
        , PROPERTIES_APP_BRAND
        , PROPERTIES_FIRST_NAME
        , PROPERTIES_LOCK_SERIAL_NUMBER
        , PROPERTIES_DAYS_SINCE_LOCK_SETUP
        , PROPERTIES_PRODUCT_NAME
        , PROPERTIES_TECHNOLOGY
        , PROPERTIES_SHOPIFY_PRODUCT_NAME
        , PROPERTIES_PARENT_ID
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(PROPERTIES_PRODUCT_NAME::text), '^^')
            , '||', IFNULL(TRIM(PROPERTIES_TECHNOLOGY::text), '^^')
            , '||', IFNULL(TRIM(PROPERTIES_SHOPIFY_PRODUCT_NAME::text), '^^')
            , '||', IFNULL(TRIM(PROPERTIES_PARENT_ID::text), '^^')
            , '||', IFNULL(TRIM(PSA_LOAD_DTS::text), '^^')
            , '||', IFNULL(TRIM(PSA_RECORD_SOURCE::text), '^^')
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^')
        ), '^^||^^'))) as PROD_HASHDIFF
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PRODUCT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PRODUCT_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(ID::text), '^^') 
            , '||', IFNULL(TRIM(PERSON_ID::text), '^^') 
            , '||', IFNULL(TRIM(PROPERTIES_DELIGHTED_BROWSER::text), '^^') 
            , '||', IFNULL(TRIM(PROPERTIES_DELIGHTED_SOURCE::text), '^^') 
            , '||', IFNULL(TRIM(CREATED_AT::text), '^^') 
            , '||', IFNULL(TRIM(PROPERTIES_DELIGHTED_OPERATING_SYSTEM::text), '^^') 
            , '||', IFNULL(TRIM(SURVEY_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(SCORE::text), '^^') 
            , '||', IFNULL(TRIM(COMMENT::text), '^^') 
            , '||', IFNULL(TRIM(PERMALINK::text), '^^') 
            , '||', IFNULL(TRIM(PROPERTIES_DELIGHTED_DEVICE_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(PROPERTIES_LOCK_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(PROPERTIES_SKUNUMBER::text), '^^') 
            , '||', IFNULL(TRIM(PROPERTIES_LAST_NAME::text), '^^') 
            , '||', IFNULL(TRIM(PROPERTIES_APP_BRAND::text), '^^') 
            , '||', IFNULL(TRIM(PROPERTIES_FIRST_NAME::text), '^^') 
            , '||', IFNULL(TRIM(PROPERTIES_LOCK_SERIAL_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(PROPERTIES_DAYS_SINCE_LOCK_SETUP::text), '^^') 
            , '||', IFNULL(TRIM(PROPERTIES_PRODUCT_NAME::text), '^^') 
            , '||', IFNULL(TRIM(PROPERTIES_TECHNOLOGY::text), '^^') 
            , '||', IFNULL(TRIM(PROPERTIES_SHOPIFY_PRODUCT_NAME::text), '^^') 
            , '||', IFNULL(TRIM(PROPERTIES_PARENT_ID::text), '^^') 
            , '||', IFNULL(TRIM(PSA_LOAD_DTS::text), '^^') 
            , '||', IFNULL(TRIM(PSA_RECORD_SOURCE::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
