---- SRC LAYER ----
WITH
SRC_stg_cust       as ( SELECT * FROM {{ source('ml_ebs_ar', 'hz_cust_accounts') }} as SRC                          
                         qualify 1 = (row_number() over(partition by CUST_ACCOUNT_ID order by psa_load_dts desc))),
SRC_stg_casa       as ( SELECT * FROM {{ source('ml_ebs_ar', 'hz_cust_acct_sites_all') }} as SRC ),
SRC_bkcc_casa      as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_stg_cust       as ( SELECT * FROM ml_ebs_ar.hz_cust_accounts )
, SRC_stg_casa       as ( SELECT * FROM ml_ebs_ar.hz_cust_acct_sites_all )
, SRC_bkcc_casa      as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_stg_cust as (
    SELECT
        ACCOUNT_NUMBER                                               as                                        CUSTOMER_BK
      , ACCOUNT_NUMBER
      , CUST_ACCOUNT_ID                                              as                           STG_CUST_CUST_ACCOUNT_ID
    FROM SRC_stg_cust
)

, LOGIC_stg_casa as (
    SELECT
        TO_VARCHAR(CUST_ACCT_SITE_ID)                                as                                   CUSTOMER_SITE_BK
      , CUST_ACCT_SITE_ID
      , ORG_ID
      , TERRITORY
      , GLOBAL_ATTRIBUTE10
      , LAST_UPDATE_DATE
      , PROGRAM_ID
      , GLOBAL_ATTRIBUTE5
      , GLOBAL_ATTRIBUTE4
      , GLOBAL_ATTRIBUTE7
      , STATUS
      , GLOBAL_ATTRIBUTE6
      , OBJECT_VERSION_NUMBER
      , GLOBAL_ATTRIBUTE1
      , GLOBAL_ATTRIBUTE3
      , GLOBAL_ATTRIBUTE2
      , GLOBAL_ATTRIBUTE9
      , MARKET_FLAG
      , GLOBAL_ATTRIBUTE8
      , TERRITORY_ID
      , BILL_TO_FLAG
      , ATTRIBUTE3
      , LANGUAGE
      , CREATED_BY_MODULE
      , CREATED_BY
      , ATTRIBUTE2
      , ORIG_SYSTEM_REFERENCE
      , LAST_UPDATED_BY
      , ATTRIBUTE1
      , PARTY_SITE_ID
      , CREATION_DATE
      , SHIP_TO_FLAG
      , ATTRIBUTE9
      , ATTRIBUTE8
      , ATTRIBUTE7
      , ATTRIBUTE6
      , ATTRIBUTE5
      , PROGRAM_UPDATE_DATE
      , ATTRIBUTE4
      , ATTRIBUTE_CATEGORY
      , CUSTOMER_CATEGORY_CODE
      , PROGRAM_APPLICATION_ID
      , ECE_TP_LOCATION_CODE
      , ATTRIBUTE10
      , ATTRIBUTE14
      , ATTRIBUTE13
      , CUST_ACCOUNT_ID
      , ATTRIBUTE12
      , ATTRIBUTE11
      , APPLICATION_ID
      , TRANSLATED_CUSTOMER_NAME
      , REQUEST_ID
      , SERVICE_TERRITORY_ID
      , KEY_ACCOUNT_FLAG
      , SECONDARY_SPECIALIST_ID
      , ATTRIBUTE20
      , GLOBAL_ATTRIBUTE20
      , LAST_UPDATE_LOGIN
      , GLOBAL_ATTRIBUTE_CATEGORY
      , TP_HEADER_ID
      , GLOBAL_ATTRIBUTE17
      , WH_UPDATE_DATE
      , GLOBAL_ATTRIBUTE18
      , GLOBAL_ATTRIBUTE15
      , GLOBAL_ATTRIBUTE16
      , GLOBAL_ATTRIBUTE13
      , GLOBAL_ATTRIBUTE14
      , GLOBAL_ATTRIBUTE11
      , PRIMARY_SPECIALIST_ID
      , GLOBAL_ATTRIBUTE12
      , ATTRIBUTE18
      , ATTRIBUTE17
      , ATTRIBUTE16
      , ATTRIBUTE15
      , GLOBAL_ATTRIBUTE19
      , ATTRIBUTE19
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED)                    as                                           LOAD_DTS
    FROM SRC_stg_casa
)

, LOGIC_bkcc_casa as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_bkcc_casa
)
---- RENAME LAYER ----

, RENAME_stg_cust as (
    SELECT
        CUSTOMER_BK
      , ACCOUNT_NUMBER
      , STG_CUST_CUST_ACCOUNT_ID
    FROM LOGIC_stg_cust
)

, RENAME_stg_casa as (
    SELECT
        CUSTOMER_SITE_BK
      , CUST_ACCT_SITE_ID
      , ORG_ID
      , TERRITORY
      , GLOBAL_ATTRIBUTE10
      , LAST_UPDATE_DATE
      , PROGRAM_ID
      , GLOBAL_ATTRIBUTE5
      , GLOBAL_ATTRIBUTE4
      , GLOBAL_ATTRIBUTE7
      , STATUS
      , GLOBAL_ATTRIBUTE6
      , OBJECT_VERSION_NUMBER
      , GLOBAL_ATTRIBUTE1
      , GLOBAL_ATTRIBUTE3
      , GLOBAL_ATTRIBUTE2
      , GLOBAL_ATTRIBUTE9
      , MARKET_FLAG
      , GLOBAL_ATTRIBUTE8
      , TERRITORY_ID
      , BILL_TO_FLAG
      , ATTRIBUTE3
      , LANGUAGE
      , CREATED_BY_MODULE
      , CREATED_BY
      , ATTRIBUTE2
      , ORIG_SYSTEM_REFERENCE
      , LAST_UPDATED_BY
      , ATTRIBUTE1
      , PARTY_SITE_ID
      , CREATION_DATE
      , SHIP_TO_FLAG
      , ATTRIBUTE9
      , ATTRIBUTE8
      , ATTRIBUTE7
      , ATTRIBUTE6
      , ATTRIBUTE5
      , PROGRAM_UPDATE_DATE
      , ATTRIBUTE4
      , ATTRIBUTE_CATEGORY
      , CUSTOMER_CATEGORY_CODE
      , PROGRAM_APPLICATION_ID
      , ECE_TP_LOCATION_CODE
      , ATTRIBUTE10
      , ATTRIBUTE14
      , ATTRIBUTE13
      , CUST_ACCOUNT_ID
      , ATTRIBUTE12
      , ATTRIBUTE11
      , APPLICATION_ID
      , TRANSLATED_CUSTOMER_NAME
      , REQUEST_ID
      , SERVICE_TERRITORY_ID
      , KEY_ACCOUNT_FLAG
      , SECONDARY_SPECIALIST_ID
      , ATTRIBUTE20
      , GLOBAL_ATTRIBUTE20
      , LAST_UPDATE_LOGIN
      , GLOBAL_ATTRIBUTE_CATEGORY
      , TP_HEADER_ID
      , GLOBAL_ATTRIBUTE17
      , WH_UPDATE_DATE
      , GLOBAL_ATTRIBUTE18
      , GLOBAL_ATTRIBUTE15
      , GLOBAL_ATTRIBUTE16
      , GLOBAL_ATTRIBUTE13
      , GLOBAL_ATTRIBUTE14
      , GLOBAL_ATTRIBUTE11
      , PRIMARY_SPECIALIST_ID
      , GLOBAL_ATTRIBUTE12
      , ATTRIBUTE18
      , ATTRIBUTE17
      , ATTRIBUTE16
      , ATTRIBUTE15
      , GLOBAL_ATTRIBUTE19
      , ATTRIBUTE19
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
    FROM LOGIC_stg_casa
)

, RENAME_bkcc_casa as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_bkcc_casa
)
---- FILTER LAYER ----

, FILTER_stg_cust as (
    SELECT *
    FROM RENAME_stg_cust
)

, FILTER_stg_casa as (
    SELECT *
    FROM RENAME_stg_casa
)

, FILTER_bkcc_casa as (
    SELECT *
    FROM RENAME_bkcc_casa
    WHERE rec_src = 'USWIOC.ORCL.EBSPRD.HZ_CUST_ACCT_SITES_ALL'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_stg_cust
    INNER JOIN FILTER_stg_casa
        ON FILTER_stg_cust.STG_CUST_CUST_ACCOUNT_ID = FILTER_stg_casa.cust_account_id
    INNER JOIN FILTER_bkcc_casa
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          CUSTOMER_BK
        , CUSTOMER_SITE_BK
        , ACCOUNT_NUMBER
        , CUST_ACCT_SITE_ID
        , ORG_ID
        , TERRITORY
        , GLOBAL_ATTRIBUTE10
        , LAST_UPDATE_DATE
        , PROGRAM_ID
        , GLOBAL_ATTRIBUTE5
        , GLOBAL_ATTRIBUTE4
        , GLOBAL_ATTRIBUTE7
        , STATUS
        , GLOBAL_ATTRIBUTE6
        , OBJECT_VERSION_NUMBER
        , GLOBAL_ATTRIBUTE1
        , GLOBAL_ATTRIBUTE3
        , GLOBAL_ATTRIBUTE2
        , GLOBAL_ATTRIBUTE9
        , MARKET_FLAG
        , GLOBAL_ATTRIBUTE8
        , TERRITORY_ID
        , BILL_TO_FLAG
        , ATTRIBUTE3
        , LANGUAGE
        , CREATED_BY_MODULE
        , CREATED_BY
        , ATTRIBUTE2
        , ORIG_SYSTEM_REFERENCE
        , LAST_UPDATED_BY
        , ATTRIBUTE1
        , PARTY_SITE_ID
        , CREATION_DATE
        , SHIP_TO_FLAG
        , ATTRIBUTE9
        , ATTRIBUTE8
        , ATTRIBUTE7
        , ATTRIBUTE6
        , ATTRIBUTE5
        , PROGRAM_UPDATE_DATE
        , ATTRIBUTE4
        , ATTRIBUTE_CATEGORY
        , CUSTOMER_CATEGORY_CODE
        , PROGRAM_APPLICATION_ID
        , ECE_TP_LOCATION_CODE
        , ATTRIBUTE10
        , ATTRIBUTE14
        , ATTRIBUTE13
        , CUST_ACCOUNT_ID
        , ATTRIBUTE12
        , ATTRIBUTE11
        , APPLICATION_ID
        , TRANSLATED_CUSTOMER_NAME
        , REQUEST_ID
        , SERVICE_TERRITORY_ID
        , KEY_ACCOUNT_FLAG
        , SECONDARY_SPECIALIST_ID
        , ATTRIBUTE20
        , GLOBAL_ATTRIBUTE20
        , LAST_UPDATE_LOGIN
        , GLOBAL_ATTRIBUTE_CATEGORY
        , TP_HEADER_ID
        , GLOBAL_ATTRIBUTE17
        , WH_UPDATE_DATE
        , GLOBAL_ATTRIBUTE18
        , GLOBAL_ATTRIBUTE15
        , GLOBAL_ATTRIBUTE16
        , GLOBAL_ATTRIBUTE13
        , GLOBAL_ATTRIBUTE14
        , GLOBAL_ATTRIBUTE11
        , PRIMARY_SPECIALIST_ID
        , GLOBAL_ATTRIBUTE12
        , ATTRIBUTE18
        , ATTRIBUTE17
        , ATTRIBUTE16
        , ATTRIBUTE15
        , GLOBAL_ATTRIBUTE19
        , ATTRIBUTE19
        , _FIVETRAN_DELETED
        , _FIVETRAN_SYNCED
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ACCOUNT_NUMBER as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(CUST_ACCT_SITE_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as CUSTOMER_SITE_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(ORG_ID::text), '^^') 
            , '||', IFNULL(TRIM(TERRITORY::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE10::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_ID::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE5::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE4::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE7::text), '^^') 
            , '||', IFNULL(TRIM(STATUS::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE6::text), '^^') 
            , '||', IFNULL(TRIM(OBJECT_VERSION_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE1::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE3::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE2::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE9::text), '^^') 
            , '||', IFNULL(TRIM(MARKET_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE8::text), '^^') 
            , '||', IFNULL(TRIM(TERRITORY_ID::text), '^^') 
            , '||', IFNULL(TRIM(BILL_TO_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE3::text), '^^') 
            , '||', IFNULL(TRIM(LANGUAGE::text), '^^') 
            , '||', IFNULL(TRIM(CREATED_BY_MODULE::text), '^^') 
            , '||', IFNULL(TRIM(CREATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE2::text), '^^') 
            , '||', IFNULL(TRIM(ORIG_SYSTEM_REFERENCE::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE1::text), '^^') 
            , '||', IFNULL(TRIM(PARTY_SITE_ID::text), '^^') 
            , '||', IFNULL(TRIM(CREATION_DATE::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_TO_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE9::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE8::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE7::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE6::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE5::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_UPDATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE4::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(CUSTOMER_CATEGORY_CODE::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_APPLICATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(ECE_TP_LOCATION_CODE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE10::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE14::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE13::text), '^^') 
            , '||', IFNULL(TRIM(CUST_ACCOUNT_ID::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE12::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE11::text), '^^') 
            , '||', IFNULL(TRIM(APPLICATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(TRANSLATED_CUSTOMER_NAME::text), '^^') 
            , '||', IFNULL(TRIM(REQUEST_ID::text), '^^') 
            , '||', IFNULL(TRIM(SERVICE_TERRITORY_ID::text), '^^') 
            , '||', IFNULL(TRIM(KEY_ACCOUNT_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(SECONDARY_SPECIALIST_ID::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE20::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE20::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_LOGIN::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(TP_HEADER_ID::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE17::text), '^^') 
            , '||', IFNULL(TRIM(WH_UPDATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE18::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE15::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE16::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE13::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE14::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE11::text), '^^') 
            , '||', IFNULL(TRIM(PRIMARY_SPECIALIST_ID::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE12::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE18::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE17::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE16::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE15::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE19::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE19::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
