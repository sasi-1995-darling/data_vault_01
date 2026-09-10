---- SRC LAYER ----
WITH
SRC_HZP            as ( SELECT ADDRESS_1, ADDRESS_2, ADDRESS_3, ADDRESS_4, ANALYSIS_FY, ATTRIBUTE_1, ATTRIBUTE_10, ATTRIBUTE_11, ATTRIBUTE_12, ATTRIBUTE_13, ATTRIBUTE_14, ATTRIBUTE_15, ATTRIBUTE_16, ATTRIBUTE_17, ATTRIBUTE_18, ATTRIBUTE_19, ATTRIBUTE_2, ATTRIBUTE_20, ATTRIBUTE_21, ATTRIBUTE_22, ATTRIBUTE_23, ATTRIBUTE_24, ATTRIBUTE_25, ATTRIBUTE_26, ATTRIBUTE_27, ATTRIBUTE_28, ATTRIBUTE_29, ATTRIBUTE_3, ATTRIBUTE_30, ATTRIBUTE_4, ATTRIBUTE_5, ATTRIBUTE_6, ATTRIBUTE_7, ATTRIBUTE_8, ATTRIBUTE_9, ATTRIBUTE_CATEGORY, ATTRIBUTE_DATE_1, ATTRIBUTE_DATE_10, ATTRIBUTE_DATE_11, ATTRIBUTE_DATE_12, ATTRIBUTE_DATE_2, ATTRIBUTE_DATE_3, ATTRIBUTE_DATE_4, ATTRIBUTE_DATE_5, ATTRIBUTE_DATE_6, ATTRIBUTE_DATE_7, ATTRIBUTE_DATE_8, ATTRIBUTE_DATE_9, ATTRIBUTE_NUMBER_1, ATTRIBUTE_NUMBER_10, ATTRIBUTE_NUMBER_11, ATTRIBUTE_NUMBER_12, ATTRIBUTE_NUMBER_2, ATTRIBUTE_NUMBER_3, ATTRIBUTE_NUMBER_4, ATTRIBUTE_NUMBER_5, ATTRIBUTE_NUMBER_6, ATTRIBUTE_NUMBER_7, ATTRIBUTE_NUMBER_8, ATTRIBUTE_NUMBER_9, CATEGORY_CODE, CEO_NAME, CERTIFICATION_LEVEL, CERT_REASON_CODE, CITY, COMMENTS, CONFLICT_ID, COUNTRY, COUNTY, CPDRF_LAST_UPD, CPDRF_VER_PILLAR, CPDRF_VER_SOR, CREATED_BY, CREATED_BY_MODULE, CREATION_DATE, CURR_FY_POTENTIAL_REVENUE, DATE_OF_BIRTH, DUNS_NUMBER_C, EMAIL_ADDRESS, EMPLOYEES_TOTAL, FISCAL_YEAREND_MONTH, GENDER, GROUP_TYPE, GSA_INDICATOR_FLAG, HOME_COUNTRY, HQ_BRANCH_IND, IDEN_ADDR_LOCATION_ID, IDEN_ADDR_PARTY_SITE_ID, INTERNAL_FLAG, JGZZ_FISCAL_CODE, JOB_DEFINITION_NAME, JOB_DEFINITION_PACKAGE, LANGUAGE_NAME, LAST_UPDATED_BY, LAST_UPDATE_DATE, LAST_UPDATE_LOGIN, MARITAL_STATUS, MASTER_PARTY_ID, MISSION_STATEMENT, NEXT_FY_POTENTIAL_REVENUE, OBJECT_TYPE, OBJECT_VERSION_NUMBER, ORIG_SYSTEM_REFERENCE, PARTY_ID, PARTY_NAME, PARTY_NUMBER, PARTY_TYPE, PARTY_UNIQUE_NAME, PERSONAL_ADDRESS_FLAG, PERSONAL_EMAIL_FLAG, PERSONAL_PHONE_FLAG, PERSON_ACADEMIC_TITLE, PERSON_FIRST_NAME, PERSON_LAST_NAME, PERSON_LAST_NAME_PREFIX, PERSON_MIDDLE_NAME, PERSON_NAME_SUFFIX, PERSON_PREVIOUS_LAST_NAME, PERSON_PRE_NAME_ADJUNCT, PERSON_SECOND_LAST_NAME, PERSON_TITLE, POSTAL_CODE, PREFERRED_CONTACT_METHOD, PREFERRED_CONTACT_PERSON_ID, PREFERRED_NAME, PREFERRED_NAME_ID, PREF_FUNCTIONAL_CURRENCY, PRIMARY_EMAIL_CONTACT_PT_ID, PRIMARY_PHONE_AREA_CODE, PRIMARY_PHONE_CONTACT_PT_ID, PRIMARY_PHONE_COUNTRY_CODE, PRIMARY_PHONE_EXTENSION, PRIMARY_PHONE_LINE_TYPE, PRIMARY_PHONE_NUMBER, PRIMARY_PHONE_PURPOSE, PRIMARY_URL_CONTACT_PT_ID, PROVINCE, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, REQUEST_ID, SALES_ACCOUNT_ID, SALUTATION, SIC_CODE, SIC_CODE_TYPE, STATE, STATUS, THIRD_PARTY_FLAG, TRADING_PARTNER_IDENTIFIER, URL, USER_GUID, USER_LAST_UPDATE_DATE, VALIDATED_FLAG, YEAR_ESTABLISHED, _FIVETRAN_DELETED, _FIVETRAN_SYNCED FROM {{ source('outd_ocf_hz', 'hz_parties') }} as SRC  ),
SRC_A              as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  ),
SRC_SUPP           as ( SELECT PARTY_ID, SEGMENT_1, VENDOR_ID FROM {{ source('outd_ocf_poz', 'poz_suppliers') }} as SRC 
                        qualify 1= row_number()over(partition by vendor_id order by _fivetran_synced desc, psa_load_dts desc) )

/*
SRC_HZP            as ( SELECT * FROM outd_ocf_hz.hz_parties )
SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
SRC_SUPP           as ( SELECT * FROM outd_ocf_poz.poz_suppliers )
*/
---- LOGIC LAYER ----

, LOGIC_HZP as (
    SELECT
        CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED )                   as                                           LOAD_DTS
      , PARTY_ID
      , PERSON_ACADEMIC_TITLE
      , ATTRIBUTE_15
      , ATTRIBUTE_30
      , ATTRIBUTE_21
      , PRIMARY_PHONE_EXTENSION
      , PERSON_SECOND_LAST_NAME
      , ATTRIBUTE_7
      , COUNTY
      , ATTRIBUTE_16
      , ATTRIBUTE_NUMBER_3
      , ATTRIBUTE_13
      , ATTRIBUTE_NUMBER_5
      , PARTY_UNIQUE_NAME
      , PREFERRED_CONTACT_PERSON_ID
      , ATTRIBUTE_NUMBER_8
      , DUNS_NUMBER_C
      , HOME_COUNTRY
      , CPDRF_VER_SOR
      , PREFERRED_NAME
      , ATTRIBUTE_DATE_9
      , CREATED_BY_MODULE
      , PRIMARY_PHONE_COUNTRY_CODE
      , PRIMARY_PHONE_AREA_CODE
      , CREATION_DATE
      , ATTRIBUTE_DATE_5
      , IDEN_ADDR_PARTY_SITE_ID
      , CITY
      , PERSON_PRE_NAME_ADJUNCT
      , ATTRIBUTE_28
      , ATTRIBUTE_17
      , ATTRIBUTE_22
      , SALUTATION
      , LAST_UPDATE_DATE
      , PERSON_FIRST_NAME
      , PERSON_LAST_NAME_PREFIX
      , USER_GUID
      , ATTRIBUTE_12
      , ATTRIBUTE_4
      , FISCAL_YEAREND_MONTH
      , PERSONAL_EMAIL_FLAG
      , ATTRIBUTE_10
      , CPDRF_VER_PILLAR
      , YEAR_ESTABLISHED
      , EMAIL_ADDRESS
      , ATTRIBUTE_DATE_1
      , URL
      , ATTRIBUTE_6
      , LAST_UPDATED_BY
      , NEXT_FY_POTENTIAL_REVENUE
      , ATTRIBUTE_26
      , OBJECT_TYPE
      , VALIDATED_FLAG
      , CEO_NAME
      , LANGUAGE_NAME
      , ATTRIBUTE_NUMBER_10
      , ATTRIBUTE_23
      , PERSON_MIDDLE_NAME
      , ATTRIBUTE_29
      , ANALYSIS_FY
      , GROUP_TYPE
      , PROVINCE
      , PREFERRED_CONTACT_METHOD
      , ATTRIBUTE_DATE_7
      , PRIMARY_PHONE_PURPOSE
      , ATTRIBUTE_NUMBER_12
      , PARTY_NUMBER
      , STATE
      , PERSON_PREVIOUS_LAST_NAME
      , SIC_CODE_TYPE
      , JOB_DEFINITION_NAME
      , ADDRESS_4
      , ADDRESS_3
      , ATTRIBUTE_NUMBER_7
      , ATTRIBUTE_DATE_11
      , ATTRIBUTE_DATE_2
      , ATTRIBUTE_DATE_4
      , ATTRIBUTE_25
      , PERSONAL_ADDRESS_FLAG
      , EMPLOYEES_TOTAL
      , ATTRIBUTE_18
      , ORIG_SYSTEM_REFERENCE
      , IDEN_ADDR_LOCATION_ID
      , ATTRIBUTE_DATE_10
      , ATTRIBUTE_14
      , ATTRIBUTE_19
      , COMMENTS
      , REQUEST_ID
      , PRIMARY_URL_CONTACT_PT_ID
      , CURR_FY_POTENTIAL_REVENUE
      , ATTRIBUTE_NUMBER_9
      , ATTRIBUTE_20
      , PARTY_NAME
      , PERSON_NAME_SUFFIX
      , STATUS
      , THIRD_PARTY_FLAG
      , ATTRIBUTE_DATE_6
      , ATTRIBUTE_CATEGORY
      , ATTRIBUTE_5
      , POSTAL_CODE
      , MARITAL_STATUS
      , ATTRIBUTE_9
      , ATTRIBUTE_3
      , GSA_INDICATOR_FLAG
      , ATTRIBUTE_DATE_8
      , PRIMARY_PHONE_NUMBER
      , ADDRESS_1
      , JGZZ_FISCAL_CODE
      , MISSION_STATEMENT
      , CERT_REASON_CODE
      , PRIMARY_PHONE_LINE_TYPE
      , ATTRIBUTE_24
      , CREATED_BY
      , PERSON_LAST_NAME
      , ATTRIBUTE_2
      , JOB_DEFINITION_PACKAGE
      , PRIMARY_EMAIL_CONTACT_PT_ID
      , COUNTRY
      , ATTRIBUTE_1
      , USER_LAST_UPDATE_DATE
      , ATTRIBUTE_DATE_12
      , SALES_ACCOUNT_ID
      , TRADING_PARTNER_IDENTIFIER
      , LAST_UPDATE_LOGIN
      , MASTER_PARTY_ID
      , GENDER
      , PARTY_TYPE
      , ATTRIBUTE_DATE_3
      , CONFLICT_ID
      , SIC_CODE
      , OBJECT_VERSION_NUMBER
      , CERTIFICATION_LEVEL
      , ATTRIBUTE_27
      , ATTRIBUTE_NUMBER_4
      , DATE_OF_BIRTH
      , PERSONAL_PHONE_FLAG
      , ATTRIBUTE_NUMBER_1
      , ATTRIBUTE_NUMBER_6
      , PREFERRED_NAME_ID
      , ADDRESS_2
      , ATTRIBUTE_11
      , CATEGORY_CODE
      , ATTRIBUTE_NUMBER_2
      , ATTRIBUTE_NUMBER_11
      , ATTRIBUTE_8
      , PRIMARY_PHONE_CONTACT_PT_ID
      , INTERNAL_FLAG
      , PREF_FUNCTIONAL_CURRENCY
      , CPDRF_LAST_UPD
      , HQ_BRANCH_IND
      , PERSON_TITLE
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_DELETE_IND
      , PSA_RECORD_SOURCE
    FROM SRC_HZP
)

, LOGIC_A as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_A
)

, LOGIC_SUPP as (
    SELECT
        SEGMENT_1::TEXT                                              as                                        SUPPLIER_BK
      , SEGMENT_1
      , VENDOR_ID
      , PARTY_ID                                                     as                                      SUPP_PARTY_ID
    FROM SRC_SUPP
)
---- RENAME LAYER ----

, RENAME_SUPP as (
    SELECT
        SUPPLIER_BK
      , SEGMENT_1
      , VENDOR_ID
      , SUPP_PARTY_ID
    FROM LOGIC_SUPP
)

, RENAME_HZP as (
    SELECT
        LOAD_DTS
      , PARTY_ID
      , PERSON_ACADEMIC_TITLE
      , ATTRIBUTE_15
      , ATTRIBUTE_30
      , ATTRIBUTE_21
      , PRIMARY_PHONE_EXTENSION
      , PERSON_SECOND_LAST_NAME
      , ATTRIBUTE_7
      , COUNTY
      , ATTRIBUTE_16
      , ATTRIBUTE_NUMBER_3
      , ATTRIBUTE_13
      , ATTRIBUTE_NUMBER_5
      , PARTY_UNIQUE_NAME
      , PREFERRED_CONTACT_PERSON_ID
      , ATTRIBUTE_NUMBER_8
      , DUNS_NUMBER_C
      , HOME_COUNTRY
      , CPDRF_VER_SOR
      , PREFERRED_NAME
      , ATTRIBUTE_DATE_9
      , CREATED_BY_MODULE
      , PRIMARY_PHONE_COUNTRY_CODE
      , PRIMARY_PHONE_AREA_CODE
      , CREATION_DATE
      , ATTRIBUTE_DATE_5
      , IDEN_ADDR_PARTY_SITE_ID
      , CITY
      , PERSON_PRE_NAME_ADJUNCT
      , ATTRIBUTE_28
      , ATTRIBUTE_17
      , ATTRIBUTE_22
      , SALUTATION
      , LAST_UPDATE_DATE
      , PERSON_FIRST_NAME
      , PERSON_LAST_NAME_PREFIX
      , USER_GUID
      , ATTRIBUTE_12
      , ATTRIBUTE_4
      , FISCAL_YEAREND_MONTH
      , PERSONAL_EMAIL_FLAG
      , ATTRIBUTE_10
      , CPDRF_VER_PILLAR
      , YEAR_ESTABLISHED
      , EMAIL_ADDRESS
      , ATTRIBUTE_DATE_1
      , URL
      , ATTRIBUTE_6
      , LAST_UPDATED_BY
      , NEXT_FY_POTENTIAL_REVENUE
      , ATTRIBUTE_26
      , OBJECT_TYPE
      , VALIDATED_FLAG
      , CEO_NAME
      , LANGUAGE_NAME
      , ATTRIBUTE_NUMBER_10
      , ATTRIBUTE_23
      , PERSON_MIDDLE_NAME
      , ATTRIBUTE_29
      , ANALYSIS_FY
      , GROUP_TYPE
      , PROVINCE
      , PREFERRED_CONTACT_METHOD
      , ATTRIBUTE_DATE_7
      , PRIMARY_PHONE_PURPOSE
      , ATTRIBUTE_NUMBER_12
      , PARTY_NUMBER
      , STATE
      , PERSON_PREVIOUS_LAST_NAME
      , SIC_CODE_TYPE
      , JOB_DEFINITION_NAME
      , ADDRESS_4
      , ADDRESS_3
      , ATTRIBUTE_NUMBER_7
      , ATTRIBUTE_DATE_11
      , ATTRIBUTE_DATE_2
      , ATTRIBUTE_DATE_4
      , ATTRIBUTE_25
      , PERSONAL_ADDRESS_FLAG
      , EMPLOYEES_TOTAL
      , ATTRIBUTE_18
      , ORIG_SYSTEM_REFERENCE
      , IDEN_ADDR_LOCATION_ID
      , ATTRIBUTE_DATE_10
      , ATTRIBUTE_14
      , ATTRIBUTE_19
      , COMMENTS
      , REQUEST_ID
      , PRIMARY_URL_CONTACT_PT_ID
      , CURR_FY_POTENTIAL_REVENUE
      , ATTRIBUTE_NUMBER_9
      , ATTRIBUTE_20
      , PARTY_NAME
      , PERSON_NAME_SUFFIX
      , STATUS
      , THIRD_PARTY_FLAG
      , ATTRIBUTE_DATE_6
      , ATTRIBUTE_CATEGORY
      , ATTRIBUTE_5
      , POSTAL_CODE
      , MARITAL_STATUS
      , ATTRIBUTE_9
      , ATTRIBUTE_3
      , GSA_INDICATOR_FLAG
      , ATTRIBUTE_DATE_8
      , PRIMARY_PHONE_NUMBER
      , ADDRESS_1
      , JGZZ_FISCAL_CODE
      , MISSION_STATEMENT
      , CERT_REASON_CODE
      , PRIMARY_PHONE_LINE_TYPE
      , ATTRIBUTE_24
      , CREATED_BY
      , PERSON_LAST_NAME
      , ATTRIBUTE_2
      , JOB_DEFINITION_PACKAGE
      , PRIMARY_EMAIL_CONTACT_PT_ID
      , COUNTRY
      , ATTRIBUTE_1
      , USER_LAST_UPDATE_DATE
      , ATTRIBUTE_DATE_12
      , SALES_ACCOUNT_ID
      , TRADING_PARTNER_IDENTIFIER
      , LAST_UPDATE_LOGIN
      , MASTER_PARTY_ID
      , GENDER
      , PARTY_TYPE
      , ATTRIBUTE_DATE_3
      , CONFLICT_ID
      , SIC_CODE
      , OBJECT_VERSION_NUMBER
      , CERTIFICATION_LEVEL
      , ATTRIBUTE_27
      , ATTRIBUTE_NUMBER_4
      , DATE_OF_BIRTH
      , PERSONAL_PHONE_FLAG
      , ATTRIBUTE_NUMBER_1
      , ATTRIBUTE_NUMBER_6
      , PREFERRED_NAME_ID
      , ADDRESS_2
      , ATTRIBUTE_11
      , CATEGORY_CODE
      , ATTRIBUTE_NUMBER_2
      , ATTRIBUTE_NUMBER_11
      , ATTRIBUTE_8
      , PRIMARY_PHONE_CONTACT_PT_ID
      , INTERNAL_FLAG
      , PREF_FUNCTIONAL_CURRENCY
      , CPDRF_LAST_UPD
      , HQ_BRANCH_IND
      , PERSON_TITLE
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_DELETE_IND
      , PSA_RECORD_SOURCE
    FROM LOGIC_HZP
)

, RENAME_A as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_A
)
---- FILTER LAYER ----

, FILTER_HZP as (
    SELECT *
    FROM RENAME_HZP
)

, FILTER_A as (
    SELECT *
    FROM RENAME_A
    WHERE rec_src = 'USCLOUD.ORCL.OCFPRD.HZ_PARTIES'
)

, FILTER_SUPP as (
    SELECT *
    FROM RENAME_SUPP
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_HZP
    INNER JOIN FILTER_A
        ON '1' = '1'
    INNER JOIN FILTER_SUPP
        ON FILTER_HZP.PARTY_ID = SUPP_PARTY_ID
)

---- FINAL LAYER ----
SELECT
          SUPPLIER_BK
        , SEGMENT_1
        , VENDOR_ID
        , LOAD_DTS
        , PARTY_ID
        , PERSON_ACADEMIC_TITLE
        , ATTRIBUTE_15
        , ATTRIBUTE_30
        , ATTRIBUTE_21
        , PRIMARY_PHONE_EXTENSION
        , PERSON_SECOND_LAST_NAME
        , ATTRIBUTE_7
        , COUNTY
        , ATTRIBUTE_16
        , ATTRIBUTE_NUMBER_3
        , ATTRIBUTE_13
        , ATTRIBUTE_NUMBER_5
        , PARTY_UNIQUE_NAME
        , PREFERRED_CONTACT_PERSON_ID
        , ATTRIBUTE_NUMBER_8
        , DUNS_NUMBER_C
        , HOME_COUNTRY
        , CPDRF_VER_SOR
        , PREFERRED_NAME
        , ATTRIBUTE_DATE_9
        , CREATED_BY_MODULE
        , PRIMARY_PHONE_COUNTRY_CODE
        , PRIMARY_PHONE_AREA_CODE
        , CREATION_DATE
        , ATTRIBUTE_DATE_5
        , IDEN_ADDR_PARTY_SITE_ID
        , CITY
        , PERSON_PRE_NAME_ADJUNCT
        , ATTRIBUTE_28
        , ATTRIBUTE_17
        , ATTRIBUTE_22
        , SALUTATION
        , LAST_UPDATE_DATE
        , PERSON_FIRST_NAME
        , PERSON_LAST_NAME_PREFIX
        , USER_GUID
        , ATTRIBUTE_12
        , ATTRIBUTE_4
        , FISCAL_YEAREND_MONTH
        , PERSONAL_EMAIL_FLAG
        , ATTRIBUTE_10
        , CPDRF_VER_PILLAR
        , YEAR_ESTABLISHED
        , EMAIL_ADDRESS
        , ATTRIBUTE_DATE_1
        , URL
        , ATTRIBUTE_6
        , LAST_UPDATED_BY
        , NEXT_FY_POTENTIAL_REVENUE
        , ATTRIBUTE_26
        , OBJECT_TYPE
        , VALIDATED_FLAG
        , CEO_NAME
        , LANGUAGE_NAME
        , ATTRIBUTE_NUMBER_10
        , ATTRIBUTE_23
        , PERSON_MIDDLE_NAME
        , ATTRIBUTE_29
        , ANALYSIS_FY
        , GROUP_TYPE
        , PROVINCE
        , PREFERRED_CONTACT_METHOD
        , ATTRIBUTE_DATE_7
        , PRIMARY_PHONE_PURPOSE
        , ATTRIBUTE_NUMBER_12
        , PARTY_NUMBER
        , STATE
        , PERSON_PREVIOUS_LAST_NAME
        , SIC_CODE_TYPE
        , JOB_DEFINITION_NAME
        , ADDRESS_4
        , ADDRESS_3
        , ATTRIBUTE_NUMBER_7
        , ATTRIBUTE_DATE_11
        , ATTRIBUTE_DATE_2
        , ATTRIBUTE_DATE_4
        , ATTRIBUTE_25
        , PERSONAL_ADDRESS_FLAG
        , EMPLOYEES_TOTAL
        , ATTRIBUTE_18
        , ORIG_SYSTEM_REFERENCE
        , IDEN_ADDR_LOCATION_ID
        , ATTRIBUTE_DATE_10
        , ATTRIBUTE_14
        , ATTRIBUTE_19
        , COMMENTS
        , REQUEST_ID
        , PRIMARY_URL_CONTACT_PT_ID
        , CURR_FY_POTENTIAL_REVENUE
        , ATTRIBUTE_NUMBER_9
        , ATTRIBUTE_20
        , PARTY_NAME
        , PERSON_NAME_SUFFIX
        , STATUS
        , THIRD_PARTY_FLAG
        , ATTRIBUTE_DATE_6
        , ATTRIBUTE_CATEGORY
        , ATTRIBUTE_5
        , POSTAL_CODE
        , MARITAL_STATUS
        , ATTRIBUTE_9
        , ATTRIBUTE_3
        , GSA_INDICATOR_FLAG
        , ATTRIBUTE_DATE_8
        , PRIMARY_PHONE_NUMBER
        , ADDRESS_1
        , JGZZ_FISCAL_CODE
        , MISSION_STATEMENT
        , CERT_REASON_CODE
        , PRIMARY_PHONE_LINE_TYPE
        , ATTRIBUTE_24
        , CREATED_BY
        , PERSON_LAST_NAME
        , ATTRIBUTE_2
        , JOB_DEFINITION_PACKAGE
        , PRIMARY_EMAIL_CONTACT_PT_ID
        , COUNTRY
        , ATTRIBUTE_1
        , USER_LAST_UPDATE_DATE
        , ATTRIBUTE_DATE_12
        , SALES_ACCOUNT_ID
        , TRADING_PARTNER_IDENTIFIER
        , LAST_UPDATE_LOGIN
        , MASTER_PARTY_ID
        , GENDER
        , PARTY_TYPE
        , ATTRIBUTE_DATE_3
        , CONFLICT_ID
        , SIC_CODE
        , OBJECT_VERSION_NUMBER
        , CERTIFICATION_LEVEL
        , ATTRIBUTE_27
        , ATTRIBUTE_NUMBER_4
        , DATE_OF_BIRTH
        , PERSONAL_PHONE_FLAG
        , ATTRIBUTE_NUMBER_1
        , ATTRIBUTE_NUMBER_6
        , PREFERRED_NAME_ID
        , ADDRESS_2
        , ATTRIBUTE_11
        , CATEGORY_CODE
        , ATTRIBUTE_NUMBER_2
        , ATTRIBUTE_NUMBER_11
        , ATTRIBUTE_8
        , PRIMARY_PHONE_CONTACT_PT_ID
        , INTERNAL_FLAG
        , PREF_FUNCTIONAL_CURRENCY
        , CPDRF_LAST_UPD
        , HQ_BRANCH_IND
        , PERSON_TITLE
        , _FIVETRAN_DELETED
        , _FIVETRAN_SYNCED
        , PSA_LOAD_DTS
        , PSA_DELETE_IND
        , PSA_RECORD_SOURCE
        , SUPP_PARTY_ID
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(SEGMENT_1 as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as SUPPLIER_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(PARTY_ID::text), '^^') 
            , '||', IFNULL(TRIM(PERSON_ACADEMIC_TITLE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_15::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_30::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_21::text), '^^') 
            , '||', IFNULL(TRIM(PRIMARY_PHONE_EXTENSION::text), '^^') 
            , '||', IFNULL(TRIM(PERSON_SECOND_LAST_NAME::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_7::text), '^^') 
            , '||', IFNULL(TRIM(COUNTY::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_16::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_3::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_13::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_5::text), '^^') 
            , '||', IFNULL(TRIM(PARTY_UNIQUE_NAME::text), '^^') 
            , '||', IFNULL(TRIM(PREFERRED_CONTACT_PERSON_ID::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_8::text), '^^') 
            , '||', IFNULL(TRIM(DUNS_NUMBER_C::text), '^^') 
            , '||', IFNULL(TRIM(HOME_COUNTRY::text), '^^') 
            , '||', IFNULL(TRIM(CPDRF_VER_SOR::text), '^^') 
            , '||', IFNULL(TRIM(PREFERRED_NAME::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_DATE_9::text), '^^') 
            , '||', IFNULL(TRIM(CREATED_BY_MODULE::text), '^^') 
            , '||', IFNULL(TRIM(PRIMARY_PHONE_COUNTRY_CODE::text), '^^') 
            , '||', IFNULL(TRIM(PRIMARY_PHONE_AREA_CODE::text), '^^') 
            , '||', IFNULL(TRIM(CREATION_DATE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_DATE_5::text), '^^') 
            , '||', IFNULL(TRIM(IDEN_ADDR_PARTY_SITE_ID::text), '^^') 
            , '||', IFNULL(TRIM(CITY::text), '^^') 
            , '||', IFNULL(TRIM(PERSON_PRE_NAME_ADJUNCT::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_28::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_17::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_22::text), '^^') 
            , '||', IFNULL(TRIM(SALUTATION::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(PERSON_FIRST_NAME::text), '^^') 
            , '||', IFNULL(TRIM(PERSON_LAST_NAME_PREFIX::text), '^^') 
            , '||', IFNULL(TRIM(USER_GUID::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_12::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_4::text), '^^') 
            , '||', IFNULL(TRIM(FISCAL_YEAREND_MONTH::text), '^^') 
            , '||', IFNULL(TRIM(PERSONAL_EMAIL_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_10::text), '^^') 
            , '||', IFNULL(TRIM(CPDRF_VER_PILLAR::text), '^^') 
            , '||', IFNULL(TRIM(YEAR_ESTABLISHED::text), '^^') 
            , '||', IFNULL(TRIM(EMAIL_ADDRESS::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_DATE_1::text), '^^') 
            , '||', IFNULL(TRIM(URL::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_6::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(NEXT_FY_POTENTIAL_REVENUE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_26::text), '^^') 
            , '||', IFNULL(TRIM(OBJECT_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(VALIDATED_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(CEO_NAME::text), '^^') 
            , '||', IFNULL(TRIM(LANGUAGE_NAME::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_10::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_23::text), '^^') 
            , '||', IFNULL(TRIM(PERSON_MIDDLE_NAME::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_29::text), '^^') 
            , '||', IFNULL(TRIM(ANALYSIS_FY::text), '^^') 
            , '||', IFNULL(TRIM(GROUP_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(PROVINCE::text), '^^') 
            , '||', IFNULL(TRIM(PREFERRED_CONTACT_METHOD::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_DATE_7::text), '^^') 
            , '||', IFNULL(TRIM(PRIMARY_PHONE_PURPOSE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_12::text), '^^') 
            , '||', IFNULL(TRIM(PARTY_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(STATE::text), '^^') 
            , '||', IFNULL(TRIM(PERSON_PREVIOUS_LAST_NAME::text), '^^') 
            , '||', IFNULL(TRIM(SIC_CODE_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(JOB_DEFINITION_NAME::text), '^^') 
            , '||', IFNULL(TRIM(ADDRESS_4::text), '^^') 
            , '||', IFNULL(TRIM(ADDRESS_3::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_7::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_DATE_11::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_DATE_2::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_DATE_4::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_25::text), '^^') 
            , '||', IFNULL(TRIM(PERSONAL_ADDRESS_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(EMPLOYEES_TOTAL::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_18::text), '^^') 
            , '||', IFNULL(TRIM(ORIG_SYSTEM_REFERENCE::text), '^^') 
            , '||', IFNULL(TRIM(IDEN_ADDR_LOCATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_DATE_10::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_14::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_19::text), '^^') 
            , '||', IFNULL(TRIM(COMMENTS::text), '^^') 
            , '||', IFNULL(TRIM(REQUEST_ID::text), '^^') 
            , '||', IFNULL(TRIM(PRIMARY_URL_CONTACT_PT_ID::text), '^^') 
            , '||', IFNULL(TRIM(CURR_FY_POTENTIAL_REVENUE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_9::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_20::text), '^^') 
            , '||', IFNULL(TRIM(PARTY_NAME::text), '^^') 
            , '||', IFNULL(TRIM(PERSON_NAME_SUFFIX::text), '^^') 
            , '||', IFNULL(TRIM(STATUS::text), '^^') 
            , '||', IFNULL(TRIM(THIRD_PARTY_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_DATE_6::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_5::text), '^^') 
            , '||', IFNULL(TRIM(POSTAL_CODE::text), '^^') 
            , '||', IFNULL(TRIM(MARITAL_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_9::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_3::text), '^^') 
            , '||', IFNULL(TRIM(GSA_INDICATOR_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_DATE_8::text), '^^') 
            , '||', IFNULL(TRIM(PRIMARY_PHONE_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(ADDRESS_1::text), '^^') 
            , '||', IFNULL(TRIM(JGZZ_FISCAL_CODE::text), '^^') 
            , '||', IFNULL(TRIM(MISSION_STATEMENT::text), '^^') 
            , '||', IFNULL(TRIM(CERT_REASON_CODE::text), '^^') 
            , '||', IFNULL(TRIM(PRIMARY_PHONE_LINE_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_24::text), '^^') 
            , '||', IFNULL(TRIM(CREATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(PERSON_LAST_NAME::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_2::text), '^^') 
            , '||', IFNULL(TRIM(JOB_DEFINITION_PACKAGE::text), '^^') 
            , '||', IFNULL(TRIM(PRIMARY_EMAIL_CONTACT_PT_ID::text), '^^') 
            , '||', IFNULL(TRIM(COUNTRY::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_1::text), '^^') 
            , '||', IFNULL(TRIM(USER_LAST_UPDATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_DATE_12::text), '^^') 
            , '||', IFNULL(TRIM(SALES_ACCOUNT_ID::text), '^^') 
            , '||', IFNULL(TRIM(TRADING_PARTNER_IDENTIFIER::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_LOGIN::text), '^^') 
            , '||', IFNULL(TRIM(MASTER_PARTY_ID::text), '^^') 
            , '||', IFNULL(TRIM(GENDER::text), '^^') 
            , '||', IFNULL(TRIM(PARTY_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_DATE_3::text), '^^') 
            , '||', IFNULL(TRIM(CONFLICT_ID::text), '^^') 
            , '||', IFNULL(TRIM(SIC_CODE::text), '^^') 
            , '||', IFNULL(TRIM(OBJECT_VERSION_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(CERTIFICATION_LEVEL::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_27::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_4::text), '^^') 
            , '||', IFNULL(TRIM(DATE_OF_BIRTH::text), '^^') 
            , '||', IFNULL(TRIM(PERSONAL_PHONE_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_1::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_6::text), '^^') 
            , '||', IFNULL(TRIM(PREFERRED_NAME_ID::text), '^^') 
            , '||', IFNULL(TRIM(ADDRESS_2::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_11::text), '^^') 
            , '||', IFNULL(TRIM(CATEGORY_CODE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_2::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_11::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_8::text), '^^') 
            , '||', IFNULL(TRIM(PRIMARY_PHONE_CONTACT_PT_ID::text), '^^') 
            , '||', IFNULL(TRIM(INTERNAL_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(PREF_FUNCTIONAL_CURRENCY::text), '^^') 
            , '||', IFNULL(TRIM(CPDRF_LAST_UPD::text), '^^') 
            , '||', IFNULL(TRIM(HQ_BRANCH_IND::text), '^^') 
            , '||', IFNULL(TRIM(PERSON_TITLE::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
