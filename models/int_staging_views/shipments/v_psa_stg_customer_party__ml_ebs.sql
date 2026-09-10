---- SRC LAYER ----
WITH
SRC_p              as ( SELECT * FROM {{ source('ml_ebs_ar', 'hz_parties') }} as SRC  ),
SRC_ca             as ( SELECT * FROM {{ source('ml_ebs_ar', 'hz_cust_accounts') }} as SRC  
                        qualify 1 = (row_number() over(partition by CUST_ACCOUNT_ID order by psa_load_dts desc))),
SRC_bkcc           as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_p              as ( SELECT * FROM ml_ebs_ar.hz_parties )
, SRC_ca             as ( SELECT * FROM ml_ebs_ar.hz_cust_accounts )
, SRC_bkcc           as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_p as (
    SELECT
        PARTY_ID
      , PARTY_NAME
      , PARTY_NUMBER
      , PARTY_TYPE
      , ADDRESS1
      , ADDRESS2
      , ADDRESS3
      , ADDRESS4
      , CITY
      , STATE
      , PROVINCE
      , COUNTY
      , COUNTRY
      , POSTAL_CODE
      , ANALYSIS_FY
      , APPLICATION_ID
      , ATTRIBUTE_CATEGORY
      , ATTRIBUTE1
      , ATTRIBUTE2
      , ATTRIBUTE3
      , ATTRIBUTE4
      , ATTRIBUTE5
      , ATTRIBUTE6
      , ATTRIBUTE7
      , ATTRIBUTE8
      , ATTRIBUTE9
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
      , ATTRIBUTE20
      , ATTRIBUTE21
      , ATTRIBUTE22
      , ATTRIBUTE23
      , ATTRIBUTE24
      , CATEGORY_CODE
      , CERT_REASON_CODE
      , CERTIFICATION_LEVEL
      , COMPETITOR_FLAG
      , CURR_FY_POTENTIAL_REVENUE
      , CUSTOMER_KEY
      , DO_NOT_MAIL_FLAG
      , DUNS_NUMBER
      , DUNS_NUMBER_C
      , EMAIL_ADDRESS
      , EMPLOYEES_TOTAL
      , FISCAL_YEAREND_MONTH
      , GLOBAL_ATTRIBUTE_CATEGORY
      , GLOBAL_ATTRIBUTE1
      , GLOBAL_ATTRIBUTE2
      , GLOBAL_ATTRIBUTE3
      , GLOBAL_ATTRIBUTE4
      , GLOBAL_ATTRIBUTE5
      , GLOBAL_ATTRIBUTE6
      , GLOBAL_ATTRIBUTE7
      , GLOBAL_ATTRIBUTE8
      , GLOBAL_ATTRIBUTE9
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
      , GLOBAL_ATTRIBUTE20
      , GROUP_TYPE
      , GSA_INDICATOR_FLAG
      , HOME_COUNTRY
      , HQ_BRANCH_IND
      , JGZZ_FISCAL_CODE
      , KNOWN_AS
      , KNOWN_AS2
      , KNOWN_AS3
      , KNOWN_AS4
      , KNOWN_AS5
      , LANGUAGE_NAME
      , MISSION_STATEMENT
      , NEXT_FY_POTENTIAL_REVENUE
      , OBJECT_VERSION_NUMBER
      , ORG_BO_VERSION
      , ORG_CUST_BO_VERSION
      , ORGANIZATION_NAME_PHONETIC
      , ORIG_SYSTEM_REFERENCE
      , PERSON_ACADEMIC_TITLE
      , PERSON_BO_VERSION
      , PERSON_CUST_BO_VERSION
      , PERSON_FIRST_NAME
      , PERSON_FIRST_NAME_PHONETIC
      , PERSON_IDEN_TYPE
      , PERSON_IDENTIFIER
      , PERSON_LAST_NAME
      , PERSON_LAST_NAME_PHONETIC
      , PERSON_MIDDLE_NAME
      , PERSON_NAME_SUFFIX
      , PERSON_PRE_NAME_ADJUNCT
      , PERSON_PREVIOUS_LAST_NAME
      , PERSON_TITLE
      , SALUTATION
      , PREFERRED_CONTACT_METHOD
      , PRIMARY_PHONE_AREA_CODE
      , PRIMARY_PHONE_CONTACT_PT_ID
      , PRIMARY_PHONE_COUNTRY_CODE
      , PRIMARY_PHONE_EXTENSION
      , PRIMARY_PHONE_LINE_TYPE
      , PRIMARY_PHONE_NUMBER
      , PRIMARY_PHONE_PURPOSE
      , PROGRAM_APPLICATION_ID
      , PROGRAM_ID
      , PROGRAM_UPDATE_DATE
      , REFERENCE_USE_FLAG
      , REQUEST_ID
      , SIC_CODE
      , SIC_CODE_TYPE
      , STATUS
      , TAX_NAME
      , TAX_REFERENCE
      , THIRD_PARTY_FLAG
      , TOTAL_NUM_OF_ORDERS
      , TOTAL_ORDERED_AMOUNT
      , URL
      , VALIDATED_FLAG
      , YEAR_ESTABLISHED
      , CREATED_BY
      , CREATED_BY_MODULE
      , CREATION_DATE
      , LAST_ORDERED_DATE
      , LAST_UPDATE_DATE
      , LAST_UPDATE_LOGIN
      , LAST_UPDATED_BY
      , WH_UPDATE_DATE
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED)                        as                                           LOAD_DTS
    FROM SRC_p
)

, LOGIC_ca as (
    SELECT
        ACCOUNT_NUMBER                                               as                                        CUSTOMER_BK
      , PARTY_ID                                                     as                                        CA_PARTY_ID
      , ACCOUNT_NUMBER
    FROM SRC_ca
)

, LOGIC_bkcc as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_bkcc
)
---- RENAME LAYER ----

, RENAME_ca as (
    SELECT
        CUSTOMER_BK
      , CA_PARTY_ID
      , ACCOUNT_NUMBER
    FROM LOGIC_ca
)

, RENAME_p as (
    SELECT
        PARTY_ID
      , PARTY_NAME
      , PARTY_NUMBER
      , PARTY_TYPE
      , ADDRESS1
      , ADDRESS2
      , ADDRESS3
      , ADDRESS4
      , CITY
      , STATE
      , PROVINCE
      , COUNTY
      , COUNTRY
      , POSTAL_CODE
      , ANALYSIS_FY
      , APPLICATION_ID
      , ATTRIBUTE_CATEGORY
      , ATTRIBUTE1
      , ATTRIBUTE2
      , ATTRIBUTE3
      , ATTRIBUTE4
      , ATTRIBUTE5
      , ATTRIBUTE6
      , ATTRIBUTE7
      , ATTRIBUTE8
      , ATTRIBUTE9
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
      , ATTRIBUTE20
      , ATTRIBUTE21
      , ATTRIBUTE22
      , ATTRIBUTE23
      , ATTRIBUTE24
      , CATEGORY_CODE
      , CERT_REASON_CODE
      , CERTIFICATION_LEVEL
      , COMPETITOR_FLAG
      , CURR_FY_POTENTIAL_REVENUE
      , CUSTOMER_KEY
      , DO_NOT_MAIL_FLAG
      , DUNS_NUMBER
      , DUNS_NUMBER_C
      , EMAIL_ADDRESS
      , EMPLOYEES_TOTAL
      , FISCAL_YEAREND_MONTH
      , GLOBAL_ATTRIBUTE_CATEGORY
      , GLOBAL_ATTRIBUTE1
      , GLOBAL_ATTRIBUTE2
      , GLOBAL_ATTRIBUTE3
      , GLOBAL_ATTRIBUTE4
      , GLOBAL_ATTRIBUTE5
      , GLOBAL_ATTRIBUTE6
      , GLOBAL_ATTRIBUTE7
      , GLOBAL_ATTRIBUTE8
      , GLOBAL_ATTRIBUTE9
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
      , GLOBAL_ATTRIBUTE20
      , GROUP_TYPE
      , GSA_INDICATOR_FLAG
      , HOME_COUNTRY
      , HQ_BRANCH_IND
      , JGZZ_FISCAL_CODE
      , KNOWN_AS
      , KNOWN_AS2
      , KNOWN_AS3
      , KNOWN_AS4
      , KNOWN_AS5
      , LANGUAGE_NAME
      , MISSION_STATEMENT
      , NEXT_FY_POTENTIAL_REVENUE
      , OBJECT_VERSION_NUMBER
      , ORG_BO_VERSION
      , ORG_CUST_BO_VERSION
      , ORGANIZATION_NAME_PHONETIC
      , ORIG_SYSTEM_REFERENCE
      , PERSON_ACADEMIC_TITLE
      , PERSON_BO_VERSION
      , PERSON_CUST_BO_VERSION
      , PERSON_FIRST_NAME
      , PERSON_FIRST_NAME_PHONETIC
      , PERSON_IDEN_TYPE
      , PERSON_IDENTIFIER
      , PERSON_LAST_NAME
      , PERSON_LAST_NAME_PHONETIC
      , PERSON_MIDDLE_NAME
      , PERSON_NAME_SUFFIX
      , PERSON_PRE_NAME_ADJUNCT
      , PERSON_PREVIOUS_LAST_NAME
      , PERSON_TITLE
      , SALUTATION
      , PREFERRED_CONTACT_METHOD
      , PRIMARY_PHONE_AREA_CODE
      , PRIMARY_PHONE_CONTACT_PT_ID
      , PRIMARY_PHONE_COUNTRY_CODE
      , PRIMARY_PHONE_EXTENSION
      , PRIMARY_PHONE_LINE_TYPE
      , PRIMARY_PHONE_NUMBER
      , PRIMARY_PHONE_PURPOSE
      , PROGRAM_APPLICATION_ID
      , PROGRAM_ID
      , PROGRAM_UPDATE_DATE
      , REFERENCE_USE_FLAG
      , REQUEST_ID
      , SIC_CODE
      , SIC_CODE_TYPE
      , STATUS
      , TAX_NAME
      , TAX_REFERENCE
      , THIRD_PARTY_FLAG
      , TOTAL_NUM_OF_ORDERS
      , TOTAL_ORDERED_AMOUNT
      , URL
      , VALIDATED_FLAG
      , YEAR_ESTABLISHED
      , CREATED_BY
      , CREATED_BY_MODULE
      , CREATION_DATE
      , LAST_ORDERED_DATE
      , LAST_UPDATE_DATE
      , LAST_UPDATE_LOGIN
      , LAST_UPDATED_BY
      , WH_UPDATE_DATE
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , LOAD_DTS
    FROM LOGIC_p
)

, RENAME_bkcc as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_bkcc
)
---- FILTER LAYER ----

, FILTER_p as (
    SELECT *
    FROM RENAME_p
    WHERE category_code = 'MLC-ACCOUNT'
)

, FILTER_ca as (
    SELECT *
    FROM RENAME_ca
)

, FILTER_bkcc as (
    SELECT *
    FROM RENAME_bkcc
    WHERE rec_src = 'USWIOC.ORCL.EBSPRD.HZ_CUST_ACCOUNTS'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_p
    INNER JOIN FILTER_ca
        ON FILTER_p.PARTY_ID = FILTER_ca.CA_PARTY_ID
    INNER JOIN FILTER_bkcc
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          CUSTOMER_BK
        , ACCOUNT_NUMBER
        , PARTY_ID
        , PARTY_NAME
        , PARTY_NUMBER
        , PARTY_TYPE
        , ADDRESS1
        , ADDRESS2
        , ADDRESS3
        , ADDRESS4
        , CITY
        , STATE
        , PROVINCE
        , COUNTY
        , COUNTRY
        , POSTAL_CODE
        , ANALYSIS_FY
        , APPLICATION_ID
        , ATTRIBUTE_CATEGORY
        , ATTRIBUTE1
        , ATTRIBUTE2
        , ATTRIBUTE3
        , ATTRIBUTE4
        , ATTRIBUTE5
        , ATTRIBUTE6
        , ATTRIBUTE7
        , ATTRIBUTE8
        , ATTRIBUTE9
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
        , ATTRIBUTE20
        , ATTRIBUTE21
        , ATTRIBUTE22
        , ATTRIBUTE23
        , ATTRIBUTE24
        , CATEGORY_CODE
        , CERT_REASON_CODE
        , CERTIFICATION_LEVEL
        , COMPETITOR_FLAG
        , CURR_FY_POTENTIAL_REVENUE
        , CUSTOMER_KEY
        , DO_NOT_MAIL_FLAG
        , DUNS_NUMBER
        , DUNS_NUMBER_C
        , EMAIL_ADDRESS
        , EMPLOYEES_TOTAL
        , FISCAL_YEAREND_MONTH
        , GLOBAL_ATTRIBUTE_CATEGORY
        , GLOBAL_ATTRIBUTE1
        , GLOBAL_ATTRIBUTE2
        , GLOBAL_ATTRIBUTE3
        , GLOBAL_ATTRIBUTE4
        , GLOBAL_ATTRIBUTE5
        , GLOBAL_ATTRIBUTE6
        , GLOBAL_ATTRIBUTE7
        , GLOBAL_ATTRIBUTE8
        , GLOBAL_ATTRIBUTE9
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
        , GLOBAL_ATTRIBUTE20
        , GROUP_TYPE
        , GSA_INDICATOR_FLAG
        , HOME_COUNTRY
        , HQ_BRANCH_IND
        , JGZZ_FISCAL_CODE
        , KNOWN_AS
        , KNOWN_AS2
        , KNOWN_AS3
        , KNOWN_AS4
        , KNOWN_AS5
        , LANGUAGE_NAME
        , MISSION_STATEMENT
        , NEXT_FY_POTENTIAL_REVENUE
        , OBJECT_VERSION_NUMBER
        , ORG_BO_VERSION
        , ORG_CUST_BO_VERSION
        , ORGANIZATION_NAME_PHONETIC
        , ORIG_SYSTEM_REFERENCE
        , PERSON_ACADEMIC_TITLE
        , PERSON_BO_VERSION
        , PERSON_CUST_BO_VERSION
        , PERSON_FIRST_NAME
        , PERSON_FIRST_NAME_PHONETIC
        , PERSON_IDEN_TYPE
        , PERSON_IDENTIFIER
        , PERSON_LAST_NAME
        , PERSON_LAST_NAME_PHONETIC
        , PERSON_MIDDLE_NAME
        , PERSON_NAME_SUFFIX
        , PERSON_PRE_NAME_ADJUNCT
        , PERSON_PREVIOUS_LAST_NAME
        , PERSON_TITLE
        , SALUTATION
        , PREFERRED_CONTACT_METHOD
        , PRIMARY_PHONE_AREA_CODE
        , PRIMARY_PHONE_CONTACT_PT_ID
        , PRIMARY_PHONE_COUNTRY_CODE
        , PRIMARY_PHONE_EXTENSION
        , PRIMARY_PHONE_LINE_TYPE
        , PRIMARY_PHONE_NUMBER
        , PRIMARY_PHONE_PURPOSE
        , PROGRAM_APPLICATION_ID
        , PROGRAM_ID
        , PROGRAM_UPDATE_DATE
        , REFERENCE_USE_FLAG
        , REQUEST_ID
        , SIC_CODE
        , SIC_CODE_TYPE
        , STATUS
        , TAX_NAME
        , TAX_REFERENCE
        , THIRD_PARTY_FLAG
        , TOTAL_NUM_OF_ORDERS
        , TOTAL_ORDERED_AMOUNT
        , URL
        , VALIDATED_FLAG
        , YEAR_ESTABLISHED
        , CREATED_BY
        , CREATED_BY_MODULE
        , CREATION_DATE
        , LAST_ORDERED_DATE
        , LAST_UPDATE_DATE
        , LAST_UPDATE_LOGIN
        , LAST_UPDATED_BY
        , WH_UPDATE_DATE
        , _FIVETRAN_DELETED
        , _FIVETRAN_SYNCED
        , PSA_DELETE_IND
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ACCOUNT_NUMBER as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as CUSTOMER_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(ACCOUNT_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(PARTY_ID::text), '^^') 
            , '||', IFNULL(TRIM(PARTY_NAME::text), '^^') 
            , '||', IFNULL(TRIM(PARTY_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(PARTY_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(ADDRESS1::text), '^^') 
            , '||', IFNULL(TRIM(ADDRESS2::text), '^^') 
            , '||', IFNULL(TRIM(ADDRESS3::text), '^^') 
            , '||', IFNULL(TRIM(ADDRESS4::text), '^^') 
            , '||', IFNULL(TRIM(CITY::text), '^^') 
            , '||', IFNULL(TRIM(STATE::text), '^^') 
            , '||', IFNULL(TRIM(PROVINCE::text), '^^') 
            , '||', IFNULL(TRIM(COUNTY::text), '^^') 
            , '||', IFNULL(TRIM(COUNTRY::text), '^^') 
            , '||', IFNULL(TRIM(POSTAL_CODE::text), '^^') 
            , '||', IFNULL(TRIM(ANALYSIS_FY::text), '^^') 
            , '||', IFNULL(TRIM(APPLICATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE1::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE2::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE3::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE4::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE5::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE6::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE7::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE8::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE9::text), '^^') 
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
            , '||', IFNULL(TRIM(ATTRIBUTE20::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE21::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE22::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE23::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE24::text), '^^') 
            , '||', IFNULL(TRIM(CATEGORY_CODE::text), '^^') 
            , '||', IFNULL(TRIM(CERT_REASON_CODE::text), '^^') 
            , '||', IFNULL(TRIM(CERTIFICATION_LEVEL::text), '^^') 
            , '||', IFNULL(TRIM(COMPETITOR_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(CURR_FY_POTENTIAL_REVENUE::text), '^^') 
            , '||', IFNULL(TRIM(CUSTOMER_KEY::text), '^^') 
            , '||', IFNULL(TRIM(DO_NOT_MAIL_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(DUNS_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(DUNS_NUMBER_C::text), '^^') 
            , '||', IFNULL(TRIM(EMAIL_ADDRESS::text), '^^') 
            , '||', IFNULL(TRIM(EMPLOYEES_TOTAL::text), '^^') 
            , '||', IFNULL(TRIM(FISCAL_YEAREND_MONTH::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE1::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE2::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE3::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE4::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE5::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE6::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE7::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE8::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE9::text), '^^') 
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
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE20::text), '^^') 
            , '||', IFNULL(TRIM(GROUP_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(GSA_INDICATOR_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(HOME_COUNTRY::text), '^^') 
            , '||', IFNULL(TRIM(HQ_BRANCH_IND::text), '^^') 
            , '||', IFNULL(TRIM(JGZZ_FISCAL_CODE::text), '^^') 
            , '||', IFNULL(TRIM(KNOWN_AS::text), '^^') 
            , '||', IFNULL(TRIM(KNOWN_AS2::text), '^^') 
            , '||', IFNULL(TRIM(KNOWN_AS3::text), '^^') 
            , '||', IFNULL(TRIM(KNOWN_AS4::text), '^^') 
            , '||', IFNULL(TRIM(KNOWN_AS5::text), '^^') 
            , '||', IFNULL(TRIM(LANGUAGE_NAME::text), '^^') 
            , '||', IFNULL(TRIM(MISSION_STATEMENT::text), '^^') 
            , '||', IFNULL(TRIM(NEXT_FY_POTENTIAL_REVENUE::text), '^^') 
            , '||', IFNULL(TRIM(OBJECT_VERSION_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(ORG_BO_VERSION::text), '^^') 
            , '||', IFNULL(TRIM(ORG_CUST_BO_VERSION::text), '^^') 
            , '||', IFNULL(TRIM(ORGANIZATION_NAME_PHONETIC::text), '^^') 
            , '||', IFNULL(TRIM(ORIG_SYSTEM_REFERENCE::text), '^^') 
            , '||', IFNULL(TRIM(PERSON_ACADEMIC_TITLE::text), '^^') 
            , '||', IFNULL(TRIM(PERSON_BO_VERSION::text), '^^') 
            , '||', IFNULL(TRIM(PERSON_CUST_BO_VERSION::text), '^^') 
            , '||', IFNULL(TRIM(PERSON_FIRST_NAME::text), '^^') 
            , '||', IFNULL(TRIM(PERSON_FIRST_NAME_PHONETIC::text), '^^') 
            , '||', IFNULL(TRIM(PERSON_IDEN_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(PERSON_IDENTIFIER::text), '^^') 
            , '||', IFNULL(TRIM(PERSON_LAST_NAME::text), '^^') 
            , '||', IFNULL(TRIM(PERSON_LAST_NAME_PHONETIC::text), '^^') 
            , '||', IFNULL(TRIM(PERSON_MIDDLE_NAME::text), '^^') 
            , '||', IFNULL(TRIM(PERSON_NAME_SUFFIX::text), '^^') 
            , '||', IFNULL(TRIM(PERSON_PRE_NAME_ADJUNCT::text), '^^') 
            , '||', IFNULL(TRIM(PERSON_PREVIOUS_LAST_NAME::text), '^^') 
            , '||', IFNULL(TRIM(PERSON_TITLE::text), '^^') 
            , '||', IFNULL(TRIM(SALUTATION::text), '^^') 
            , '||', IFNULL(TRIM(PREFERRED_CONTACT_METHOD::text), '^^') 
            , '||', IFNULL(TRIM(PRIMARY_PHONE_AREA_CODE::text), '^^') 
            , '||', IFNULL(TRIM(PRIMARY_PHONE_CONTACT_PT_ID::text), '^^') 
            , '||', IFNULL(TRIM(PRIMARY_PHONE_COUNTRY_CODE::text), '^^') 
            , '||', IFNULL(TRIM(PRIMARY_PHONE_EXTENSION::text), '^^') 
            , '||', IFNULL(TRIM(PRIMARY_PHONE_LINE_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(PRIMARY_PHONE_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(PRIMARY_PHONE_PURPOSE::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_APPLICATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_ID::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_UPDATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(REFERENCE_USE_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(REQUEST_ID::text), '^^') 
            , '||', IFNULL(TRIM(SIC_CODE::text), '^^') 
            , '||', IFNULL(TRIM(SIC_CODE_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(STATUS::text), '^^') 
            , '||', IFNULL(TRIM(TAX_NAME::text), '^^') 
            , '||', IFNULL(TRIM(TAX_REFERENCE::text), '^^') 
            , '||', IFNULL(TRIM(THIRD_PARTY_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(TOTAL_NUM_OF_ORDERS::text), '^^') 
            , '||', IFNULL(TRIM(TOTAL_ORDERED_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(URL::text), '^^') 
            , '||', IFNULL(TRIM(VALIDATED_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(YEAR_ESTABLISHED::text), '^^') 
            , '||', IFNULL(TRIM(CREATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(CREATED_BY_MODULE::text), '^^') 
            , '||', IFNULL(TRIM(CREATION_DATE::text), '^^') 
            , '||', IFNULL(TRIM(LAST_ORDERED_DATE::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_LOGIN::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(WH_UPDATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^')             
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
            , '||', IFNULL(TRIM(PSA_RECORD_SOURCE::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT