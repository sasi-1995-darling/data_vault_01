---- SRC LAYER ----
WITH
SRC_stg_cust_pty   as ( SELECT * FROM {{ source('ml_ebs_ar', 'hz_cust_accounts') }} as SRC 
                         qualify 1 = (row_number() over(partition by CUST_ACCOUNT_ID order by psa_load_dts desc))),
SRC_stg_casa_pty   as ( SELECT * FROM {{ source('ml_ebs_ar', 'hz_cust_acct_sites_all') }} as SRC 
                         qualify 1 = (row_number() over(partition by CUST_ACCT_SITE_ID order by psa_load_dts desc))),
SRC_stg_pty        as ( SELECT * FROM {{ source('ml_ebs_ar', 'hz_party_sites') }} as SRC ),
SRC_bkcc_pty       as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_stg_cust_pty   as ( SELECT * FROM ml_ebs_ar.hz_cust_accounts )
, SRC_stg_casa_pty   as ( SELECT * FROM ml_ebs_ar.hz_cust_acct_sites_all )
, SRC_stg_pty        as ( SELECT * FROM ml_ebs_ar.hz_party_sites )
, SRC_bkcc_pty       as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_stg_cust_pty as (
    SELECT
        ACCOUNT_NUMBER                                               as                                        CUSTOMER_BK
      , ACCOUNT_NUMBER
      , CUST_ACCOUNT_ID                                              as                       STG_CUST_PTY_CUST_ACCOUNT_ID
    FROM SRC_stg_cust_pty
)

, LOGIC_stg_casa_pty as (
    SELECT
        CUST_ACCT_SITE_ID                                            as                                   CUSTOMER_SITE_BK
      , CUST_ACCT_SITE_ID
      , CUST_ACCOUNT_ID
      , PARTY_SITE_ID                                                as                         STG_CASA_PTY_PARTY_SITE_ID
    FROM SRC_stg_casa_pty
)

, LOGIC_stg_pty as (
    SELECT
        PARTY_SITE_ID
      , PARTY_ID
      , ACTUAL_CONTENT_SOURCE
      , ADDRESSEE
      , APPLICATION_ID
      , ATTRIBUTE1
      , ATTRIBUTE10
      , ATTRIBUTE11
      , ATTRIBUTE12
      , ATTRIBUTE13
      , ATTRIBUTE14
      , ATTRIBUTE15
      , ATTRIBUTE16
      , ATTRIBUTE17
      , ATTRIBUTE18
      , ATTRIBUTE19
      , ATTRIBUTE2
      , ATTRIBUTE20
      , ATTRIBUTE3
      , ATTRIBUTE4
      , ATTRIBUTE5
      , ATTRIBUTE6
      , ATTRIBUTE7
      , ATTRIBUTE8
      , ATTRIBUTE9
      , ATTRIBUTE_CATEGORY
      , CONTACT_KEY_OSM
      , CREATED_BY
      , CREATED_BY_MODULE
      , CREATION_DATE
      , CUSTOMER_KEY_OSM
      , DUNS_NUMBER_C
      , END_DATE_ACTIVE
      , GLOBAL_ATTRIBUTE1
      , GLOBAL_ATTRIBUTE10
      , GLOBAL_ATTRIBUTE11
      , GLOBAL_ATTRIBUTE12
      , GLOBAL_ATTRIBUTE13
      , GLOBAL_ATTRIBUTE14
      , GLOBAL_ATTRIBUTE15
      , GLOBAL_ATTRIBUTE16
      , GLOBAL_ATTRIBUTE17
      , GLOBAL_ATTRIBUTE18
      , GLOBAL_ATTRIBUTE19
      , GLOBAL_ATTRIBUTE2
      , GLOBAL_ATTRIBUTE20
      , GLOBAL_ATTRIBUTE3
      , GLOBAL_ATTRIBUTE4
      , GLOBAL_ATTRIBUTE5
      , GLOBAL_ATTRIBUTE6
      , GLOBAL_ATTRIBUTE7
      , GLOBAL_ATTRIBUTE8
      , GLOBAL_ATTRIBUTE9
      , GLOBAL_ATTRIBUTE_CATEGORY
      , GLOBAL_LOCATION_NUMBER
      , IDENTIFYING_ADDRESS_FLAG
      , LANGUAGE
      , LAST_UPDATED_BY
      , LAST_UPDATE_DATE
      , LAST_UPDATE_LOGIN
      , LOCATION_ID
      , MAILSTOP
      , OBJECT_VERSION_NUMBER
      , ORIG_SYSTEM_REFERENCE
      , PARTY_SITE_NAME
      , PARTY_SITE_NUMBER
      , PHONE_KEY_OSM
      , PROGRAM_APPLICATION_ID
      , PROGRAM_ID
      , PROGRAM_UPDATE_DATE
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , REGION
      , REQUEST_ID
      , START_DATE_ACTIVE
      , STATUS
      , WH_UPDATE_DATE
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED)                    as                                           LOAD_DTS
    FROM SRC_stg_pty
)

, LOGIC_bkcc_pty as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_bkcc_pty
)
---- RENAME LAYER ----

, RENAME_stg_cust_pty as (
    SELECT
        CUSTOMER_BK
      , ACCOUNT_NUMBER
      , STG_CUST_PTY_CUST_ACCOUNT_ID
    FROM LOGIC_stg_cust_pty
)

, RENAME_stg_casa_pty as (
    SELECT
        CUSTOMER_SITE_BK
      , CUST_ACCT_SITE_ID
      , CUST_ACCOUNT_ID
      , STG_CASA_PTY_PARTY_SITE_ID
    FROM LOGIC_stg_casa_pty
)

, RENAME_stg_pty as (
    SELECT
        PARTY_SITE_ID
      , PARTY_ID
      , ACTUAL_CONTENT_SOURCE
      , ADDRESSEE
      , APPLICATION_ID
      , ATTRIBUTE1
      , ATTRIBUTE10
      , ATTRIBUTE11
      , ATTRIBUTE12
      , ATTRIBUTE13
      , ATTRIBUTE14
      , ATTRIBUTE15
      , ATTRIBUTE16
      , ATTRIBUTE17
      , ATTRIBUTE18
      , ATTRIBUTE19
      , ATTRIBUTE2
      , ATTRIBUTE20
      , ATTRIBUTE3
      , ATTRIBUTE4
      , ATTRIBUTE5
      , ATTRIBUTE6
      , ATTRIBUTE7
      , ATTRIBUTE8
      , ATTRIBUTE9
      , ATTRIBUTE_CATEGORY
      , CONTACT_KEY_OSM
      , CREATED_BY
      , CREATED_BY_MODULE
      , CREATION_DATE
      , CUSTOMER_KEY_OSM
      , DUNS_NUMBER_C
      , END_DATE_ACTIVE
      , GLOBAL_ATTRIBUTE1
      , GLOBAL_ATTRIBUTE10
      , GLOBAL_ATTRIBUTE11
      , GLOBAL_ATTRIBUTE12
      , GLOBAL_ATTRIBUTE13
      , GLOBAL_ATTRIBUTE14
      , GLOBAL_ATTRIBUTE15
      , GLOBAL_ATTRIBUTE16
      , GLOBAL_ATTRIBUTE17
      , GLOBAL_ATTRIBUTE18
      , GLOBAL_ATTRIBUTE19
      , GLOBAL_ATTRIBUTE2
      , GLOBAL_ATTRIBUTE20
      , GLOBAL_ATTRIBUTE3
      , GLOBAL_ATTRIBUTE4
      , GLOBAL_ATTRIBUTE5
      , GLOBAL_ATTRIBUTE6
      , GLOBAL_ATTRIBUTE7
      , GLOBAL_ATTRIBUTE8
      , GLOBAL_ATTRIBUTE9
      , GLOBAL_ATTRIBUTE_CATEGORY
      , GLOBAL_LOCATION_NUMBER
      , IDENTIFYING_ADDRESS_FLAG
      , LANGUAGE
      , LAST_UPDATED_BY
      , LAST_UPDATE_DATE
      , LAST_UPDATE_LOGIN
      , LOCATION_ID
      , MAILSTOP
      , OBJECT_VERSION_NUMBER
      , ORIG_SYSTEM_REFERENCE
      , PARTY_SITE_NAME
      , PARTY_SITE_NUMBER
      , PHONE_KEY_OSM
      , PROGRAM_APPLICATION_ID
      , PROGRAM_ID
      , PROGRAM_UPDATE_DATE
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , REGION
      , REQUEST_ID
      , START_DATE_ACTIVE
      , STATUS
      , WH_UPDATE_DATE
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , LOAD_DTS
    FROM LOGIC_stg_pty
)

, RENAME_bkcc_pty as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_bkcc_pty
)
---- FILTER LAYER ----

, FILTER_stg_cust_pty as (
    SELECT *
    FROM RENAME_stg_cust_pty
)

, FILTER_stg_casa_pty as (
    SELECT *
    FROM RENAME_stg_casa_pty
)

, FILTER_stg_pty as (
    SELECT *
    FROM RENAME_stg_pty
)

, FILTER_bkcc_pty as (
    SELECT *
    FROM RENAME_bkcc_pty
    WHERE rec_src = 'USWIOC.ORCL.EBSPRD.HZ_PARTY_SITES'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_stg_cust_pty
    INNER JOIN FILTER_stg_casa_pty
        ON FILTER_stg_cust_pty.STG_CUST_PTY_CUST_ACCOUNT_ID = FILTER_stg_casa_pty.cust_account_id
    INNER JOIN FILTER_stg_pty
        ON FILTER_stg_casa_pty.STG_CASA_PTY_PARTY_SITE_ID = FILTER_stg_pty.party_site_id
    INNER JOIN FILTER_bkcc_pty
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          CUSTOMER_BK
        , CUSTOMER_SITE_BK
        , ACCOUNT_NUMBER
        , CUST_ACCT_SITE_ID
        , PARTY_SITE_ID
        , PARTY_ID
        , ACTUAL_CONTENT_SOURCE
        , ADDRESSEE
        , APPLICATION_ID
        , ATTRIBUTE1
        , ATTRIBUTE10
        , ATTRIBUTE11
        , ATTRIBUTE12
        , ATTRIBUTE13
        , ATTRIBUTE14
        , ATTRIBUTE15
        , ATTRIBUTE16
        , ATTRIBUTE17
        , ATTRIBUTE18
        , ATTRIBUTE19
        , ATTRIBUTE2
        , ATTRIBUTE20
        , ATTRIBUTE3
        , ATTRIBUTE4
        , ATTRIBUTE5
        , ATTRIBUTE6
        , ATTRIBUTE7
        , ATTRIBUTE8
        , ATTRIBUTE9
        , ATTRIBUTE_CATEGORY
        , CONTACT_KEY_OSM
        , CREATED_BY
        , CREATED_BY_MODULE
        , CREATION_DATE
        , CUSTOMER_KEY_OSM
        , DUNS_NUMBER_C
        , END_DATE_ACTIVE
        , GLOBAL_ATTRIBUTE1
        , GLOBAL_ATTRIBUTE10
        , GLOBAL_ATTRIBUTE11
        , GLOBAL_ATTRIBUTE12
        , GLOBAL_ATTRIBUTE13
        , GLOBAL_ATTRIBUTE14
        , GLOBAL_ATTRIBUTE15
        , GLOBAL_ATTRIBUTE16
        , GLOBAL_ATTRIBUTE17
        , GLOBAL_ATTRIBUTE18
        , GLOBAL_ATTRIBUTE19
        , GLOBAL_ATTRIBUTE2
        , GLOBAL_ATTRIBUTE20
        , GLOBAL_ATTRIBUTE3
        , GLOBAL_ATTRIBUTE4
        , GLOBAL_ATTRIBUTE5
        , GLOBAL_ATTRIBUTE6
        , GLOBAL_ATTRIBUTE7
        , GLOBAL_ATTRIBUTE8
        , GLOBAL_ATTRIBUTE9
        , GLOBAL_ATTRIBUTE_CATEGORY
        , GLOBAL_LOCATION_NUMBER
        , IDENTIFYING_ADDRESS_FLAG
        , LANGUAGE
        , LAST_UPDATED_BY
        , LAST_UPDATE_DATE
        , LAST_UPDATE_LOGIN
        , LOCATION_ID
        , MAILSTOP
        , OBJECT_VERSION_NUMBER
        , ORIG_SYSTEM_REFERENCE
        , PARTY_SITE_NAME
        , PARTY_SITE_NUMBER
        , PHONE_KEY_OSM
        , PROGRAM_APPLICATION_ID
        , PROGRAM_ID
        , PROGRAM_UPDATE_DATE
        , PSA_DELETE_IND
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , REGION
        , REQUEST_ID
        , START_DATE_ACTIVE
        , STATUS
        , WH_UPDATE_DATE
        , _FIVETRAN_DELETED
        , _FIVETRAN_SYNCED
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ACCOUNT_NUMBER as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(CUST_ACCT_SITE_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as CUSTOMER_SITE_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(PARTY_SITE_ID::text), '^^')             
            , '||', IFNULL(TRIM(PARTY_ID::text), '^^') 
            , '||', IFNULL(TRIM(ACTUAL_CONTENT_SOURCE::text), '^^') 
            , '||', IFNULL(TRIM(ADDRESSEE::text), '^^') 
            , '||', IFNULL(TRIM(APPLICATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE1::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE10::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE11::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE12::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE13::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE14::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE15::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE16::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE17::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE18::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE19::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE2::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE20::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE3::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE4::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE5::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE6::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE7::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE8::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE9::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(CONTACT_KEY_OSM::text), '^^') 
            , '||', IFNULL(TRIM(CREATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(CREATED_BY_MODULE::text), '^^') 
            , '||', IFNULL(TRIM(CREATION_DATE::text), '^^') 
            , '||', IFNULL(TRIM(CUSTOMER_KEY_OSM::text), '^^') 
            , '||', IFNULL(TRIM(DUNS_NUMBER_C::text), '^^') 
            , '||', IFNULL(TRIM(END_DATE_ACTIVE::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE1::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE10::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE11::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE12::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE13::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE14::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE15::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE16::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE17::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE18::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE19::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE2::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE20::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE3::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE4::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE5::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE6::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE7::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE8::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE9::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_LOCATION_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(IDENTIFYING_ADDRESS_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(LANGUAGE::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_LOGIN::text), '^^') 
            , '||', IFNULL(TRIM(LOCATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(MAILSTOP::text), '^^') 
            , '||', IFNULL(TRIM(OBJECT_VERSION_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(ORIG_SYSTEM_REFERENCE::text), '^^') 
            , '||', IFNULL(TRIM(PARTY_SITE_NAME::text), '^^') 
            , '||', IFNULL(TRIM(PARTY_SITE_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(PHONE_KEY_OSM::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_APPLICATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_ID::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_UPDATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
            , '||', IFNULL(TRIM(REGION::text), '^^') 
            , '||', IFNULL(TRIM(REQUEST_ID::text), '^^') 
            , '||', IFNULL(TRIM(START_DATE_ACTIVE::text), '^^') 
            , '||', IFNULL(TRIM(STATUS::text), '^^') 
            , '||', IFNULL(TRIM(WH_UPDATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^')             
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
