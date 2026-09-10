---- SRC LAYER ----
WITH
SRC_stg_addr_ca    as ( SELECT * FROM {{ source('ml_ebs_ar', 'hz_cust_accounts') }} as SRC 
                         qualify 1 = (row_number() over(partition by CUST_ACCOUNT_ID order by psa_load_dts desc))),
SRC_stg_addr_casa  as ( SELECT * FROM {{ source('ml_ebs_ar', 'hz_cust_acct_sites_all') }} as SRC 
                         qualify 1 = (row_number() over(partition by CUST_ACCT_SITE_ID order by psa_load_dts desc))),
SRC_stg_addr_pty   as ( SELECT * FROM {{ source('ml_ebs_ar', 'hz_party_sites') }} as SRC 
                        qualify 1 = (row_number() over(partition by party_site_id order by psa_load_dts desc))),
SRC_stg_addr       as ( SELECT * FROM {{ source('ml_ebs_ar', 'hz_locations') }} as SRC ),
SRC_bkcc_addr      as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_stg_addr_ca    as ( SELECT * FROM ml_ebs_ar.hz_cust_accounts )
, SRC_stg_addr_casa  as ( SELECT * FROM ml_ebs_ar.hz_cust_acct_sites_all )
, SRC_stg_addr_pty   as ( SELECT * FROM ml_ebs_ar.hz_party_sites )
, SRC_stg_addr       as ( SELECT * FROM ml_ebs_ar.hz_locations )
, SRC_bkcc_addr      as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_stg_addr_ca as (
    SELECT
        ACCOUNT_NUMBER                                               as                                        CUSTOMER_BK
      , ACCOUNT_NUMBER
      , CUST_ACCOUNT_ID                                              as                        STG_ADDR_CA_CUST_ACCOUNT_ID
    FROM SRC_stg_addr_ca
)

, LOGIC_stg_addr_casa as (
    SELECT
        CUST_ACCT_SITE_ID                                            as                                   CUSTOMER_SITE_BK
      , CUST_ACCOUNT_ID                                              as                      STG_ADDR_CASA_CUST_ACCOUNT_ID
      , PARTY_SITE_ID                                                as                        STG_ADDR_CASA_PARTY_SITE_ID
      , CUST_ACCT_SITE_ID
    FROM SRC_stg_addr_casa
)

, LOGIC_stg_addr_pty as (
    SELECT
        PARTY_SITE_ID                                                as                         STG_ADDR_PTY_PARTY_SITE_ID
      , LOCATION_ID                                                  as                           STG_ADDR_PTY_LOCATION_ID
    FROM SRC_stg_addr_pty
)

, LOGIC_stg_addr as (
    SELECT
        LOCATION_ID
      , RURAL_ROUTE_NUMBER
      , SALES_TAX_INSIDE_CITY_LIMITS
      , STREET_SUFFIX
      , PROGRAM_ID
      , DO_NOT_VALIDATE_FLAG
      , GLOBAL_ATTRIBUTE5
      , GLOBAL_ATTRIBUTE4
      , POSITION
      , GLOBAL_ATTRIBUTE7
      , FLOOR
      , GLOBAL_ATTRIBUTE6
      , GLOBAL_ATTRIBUTE1
      , GLOBAL_ATTRIBUTE3
      , GLOBAL_ATTRIBUTE2
      , ADDRESS_KEY
      , GLOBAL_ATTRIBUTE9
      , GLOBAL_ATTRIBUTE8
      , CONTENT_SOURCE_TYPE
      , ATTRIBUTE3
      , LANGUAGE
      , CREATED_BY_MODULE
      , ATTRIBUTE2
      , ORIG_SYSTEM_REFERENCE
      , ATTRIBUTE1
      , ATTRIBUTE9
      , ATTRIBUTE8
      , ATTRIBUTE7
      , ATTRIBUTE6
      , ATTRIBUTE5
      , ATTRIBUTE4
      , SHORT_DESCRIPTION
      , ADDRESS_ERROR_CODE
      , ATTRIBUTE10
      , HOUSE_NUMBER
      , ADDRESS_LINES_PHONETIC
      , ATTRIBUTE14
      , ATTRIBUTE13
      , ATTRIBUTE12
      , ATTRIBUTE11
      , DELIVERY_POINT_CODE
      , SECONDARY_SUFFIX_ELEMENT
      , TIMEZONE_ID
      , SALES_TAX_GEOCODE
      , POSTAL_CODE
      , POST_OFFICE
      , DESCRIPTION
      , ADDRESS_EFFECTIVE_DATE
      , ATTRIBUTE20
      , SUITE
      , GEOMETRY_STATUS_CODE
      , GLOBAL_ATTRIBUTE20
      , STREET
      , GLOBAL_ATTRIBUTE17
      , GLOBAL_ATTRIBUTE18
      , GLOBAL_ATTRIBUTE15
      , GLOBAL_ATTRIBUTE16
      , GLOBAL_ATTRIBUTE13
      , CITY
      , FA_LOCATION_ID
      , GLOBAL_ATTRIBUTE14
      , GLOBAL_ATTRIBUTE11
      , GLOBAL_ATTRIBUTE12
      , ATTRIBUTE18
      , ATTRIBUTE17
      , ATTRIBUTE16
      , ATTRIBUTE15
      , GLOBAL_ATTRIBUTE19
      , ATTRIBUTE19
      , POSTAL_PLUS4_CODE
      , RURAL_ROUTE_TYPE
      , STREET_NUMBER
      , OVERSEAS_ADDRESS_FLAG
      , GLOBAL_ATTRIBUTE10
      , LAST_UPDATE_DATE
      , GEOMETRY_SOURCE
      , LOCATION_DIRECTIONS
      , OBJECT_VERSION_NUMBER
      , COUNTRY
      , LIFE_CYCLE_STATUS
      , COUNTY
      , CREATED_BY
      , LAST_UPDATED_BY
      , CREATION_DATE
      , PROGRAM_UPDATE_DATE
      , APARTMENT_FLAG
      , ATTRIBUTE_CATEGORY
      , ACTUAL_CONTENT_SOURCE
      , PROGRAM_APPLICATION_ID
      , LOC_HIERARCHY_ID
      , VALIDATION_STATUS_CODE
      , APPLICATION_ID
      , STATE
      , REQUEST_ID
      , APARTMENT_NUMBER
      , ADDRESS_STYLE
      , DATE_VALIDATED
      , TIME_ZONE
      , BUILDING
      , ADDRESS1
      , ADDRESS_EXPIRATION_DATE
      , ADDRESS3
      , ADDRESS2
      , ADDRESS4
      , DODAAC
      , LAST_UPDATE_LOGIN
      , PO_BOX_NUMBER
      , CLLI_CODE
      , GLOBAL_ATTRIBUTE_CATEGORY
      , VALIDATED_FLAG
      , WH_UPDATE_DATE
      , PROVINCE
      , ROOM
      , TRAILING_DIRECTORY_CODE
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED)                    as                                           LOAD_DTS
    FROM SRC_stg_addr
)

, LOGIC_bkcc_addr as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_bkcc_addr
)
---- RENAME LAYER ----

, RENAME_stg_addr_ca as (
    SELECT
        CUSTOMER_BK
      , ACCOUNT_NUMBER
      , STG_ADDR_CA_CUST_ACCOUNT_ID
    FROM LOGIC_stg_addr_ca
)

, RENAME_stg_addr_casa as (
    SELECT
        CUSTOMER_SITE_BK
      , STG_ADDR_CASA_CUST_ACCOUNT_ID
      , STG_ADDR_CASA_PARTY_SITE_ID
      , CUST_ACCT_SITE_ID
    FROM LOGIC_stg_addr_casa
)

, RENAME_stg_addr_pty as (
    SELECT
        STG_ADDR_PTY_PARTY_SITE_ID
      , STG_ADDR_PTY_LOCATION_ID
    FROM LOGIC_stg_addr_pty
)

, RENAME_stg_addr as (
    SELECT
        LOCATION_ID
      , RURAL_ROUTE_NUMBER
      , SALES_TAX_INSIDE_CITY_LIMITS
      , STREET_SUFFIX
      , PROGRAM_ID
      , DO_NOT_VALIDATE_FLAG
      , GLOBAL_ATTRIBUTE5
      , GLOBAL_ATTRIBUTE4
      , POSITION
      , GLOBAL_ATTRIBUTE7
      , FLOOR
      , GLOBAL_ATTRIBUTE6
      , GLOBAL_ATTRIBUTE1
      , GLOBAL_ATTRIBUTE3
      , GLOBAL_ATTRIBUTE2
      , ADDRESS_KEY
      , GLOBAL_ATTRIBUTE9
      , GLOBAL_ATTRIBUTE8
      , CONTENT_SOURCE_TYPE
      , ATTRIBUTE3
      , LANGUAGE
      , CREATED_BY_MODULE
      , ATTRIBUTE2
      , ORIG_SYSTEM_REFERENCE
      , ATTRIBUTE1
      , ATTRIBUTE9
      , ATTRIBUTE8
      , ATTRIBUTE7
      , ATTRIBUTE6
      , ATTRIBUTE5
      , ATTRIBUTE4
      , SHORT_DESCRIPTION
      , ADDRESS_ERROR_CODE
      , ATTRIBUTE10
      , HOUSE_NUMBER
      , ADDRESS_LINES_PHONETIC
      , ATTRIBUTE14
      , ATTRIBUTE13
      , ATTRIBUTE12
      , ATTRIBUTE11
      , DELIVERY_POINT_CODE
      , SECONDARY_SUFFIX_ELEMENT
      , TIMEZONE_ID
      , SALES_TAX_GEOCODE
      , POSTAL_CODE
      , POST_OFFICE
      , DESCRIPTION
      , ADDRESS_EFFECTIVE_DATE
      , ATTRIBUTE20
      , SUITE
      , GEOMETRY_STATUS_CODE
      , GLOBAL_ATTRIBUTE20
      , STREET
      , GLOBAL_ATTRIBUTE17
      , GLOBAL_ATTRIBUTE18
      , GLOBAL_ATTRIBUTE15
      , GLOBAL_ATTRIBUTE16
      , GLOBAL_ATTRIBUTE13
      , CITY
      , FA_LOCATION_ID
      , GLOBAL_ATTRIBUTE14
      , GLOBAL_ATTRIBUTE11
      , GLOBAL_ATTRIBUTE12
      , ATTRIBUTE18
      , ATTRIBUTE17
      , ATTRIBUTE16
      , ATTRIBUTE15
      , GLOBAL_ATTRIBUTE19
      , ATTRIBUTE19
      , POSTAL_PLUS4_CODE
      , RURAL_ROUTE_TYPE
      , STREET_NUMBER
      , OVERSEAS_ADDRESS_FLAG
      , GLOBAL_ATTRIBUTE10
      , LAST_UPDATE_DATE
      , GEOMETRY_SOURCE
      , LOCATION_DIRECTIONS
      , OBJECT_VERSION_NUMBER
      , COUNTRY
      , LIFE_CYCLE_STATUS
      , COUNTY
      , CREATED_BY
      , LAST_UPDATED_BY
      , CREATION_DATE
      , PROGRAM_UPDATE_DATE
      , APARTMENT_FLAG
      , ATTRIBUTE_CATEGORY
      , ACTUAL_CONTENT_SOURCE
      , PROGRAM_APPLICATION_ID
      , LOC_HIERARCHY_ID
      , VALIDATION_STATUS_CODE
      , APPLICATION_ID
      , STATE
      , REQUEST_ID
      , APARTMENT_NUMBER
      , ADDRESS_STYLE
      , DATE_VALIDATED
      , TIME_ZONE
      , BUILDING
      , ADDRESS1
      , ADDRESS_EXPIRATION_DATE
      , ADDRESS3
      , ADDRESS2
      , ADDRESS4
      , DODAAC
      , LAST_UPDATE_LOGIN
      , PO_BOX_NUMBER
      , CLLI_CODE
      , GLOBAL_ATTRIBUTE_CATEGORY
      , VALIDATED_FLAG
      , WH_UPDATE_DATE
      , PROVINCE
      , ROOM
      , TRAILING_DIRECTORY_CODE
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , LOAD_DTS
    FROM LOGIC_stg_addr
)

, RENAME_bkcc_addr as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_bkcc_addr
)
---- FILTER LAYER ----

, FILTER_stg_addr_ca as (
    SELECT *
    FROM RENAME_stg_addr_ca
)

, FILTER_stg_addr_casa as (
    SELECT *
    FROM RENAME_stg_addr_casa
)

, FILTER_stg_addr_pty as (
    SELECT *
    FROM RENAME_stg_addr_pty
)

, FILTER_stg_addr as (
    SELECT *
    FROM RENAME_stg_addr
)

, FILTER_bkcc_addr as (
    SELECT *
    FROM RENAME_bkcc_addr
    WHERE rec_src = 'USWIOC.ORCL.EBSPRD.HZ_LOCATIONS'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_stg_addr_ca
    INNER JOIN FILTER_stg_addr_casa
        ON FILTER_stg_addr_ca.STG_ADDR_CA_CUST_ACCOUNT_ID = FILTER_stg_addr_casa.STG_ADDR_CASA_CUST_ACCOUNT_ID
    INNER JOIN FILTER_bkcc_addr
        ON '1' = '1'
    INNER JOIN FILTER_stg_addr_pty
        ON FILTER_stg_addr_casa.STG_ADDR_CASA_PARTY_SITE_ID = FILTER_stg_addr_pty.STG_ADDR_PTY_PARTY_SITE_ID
    INNER JOIN FILTER_stg_addr
        ON FILTER_stg_addr_pty.STG_ADDR_PTY_LOCATION_ID = FILTER_stg_addr.location_id
)

---- FINAL LAYER ----
SELECT
          CUSTOMER_BK
        , CUSTOMER_SITE_BK
        , ACCOUNT_NUMBER
        , CUST_ACCT_SITE_ID
        , LOCATION_ID
        , RURAL_ROUTE_NUMBER
        , SALES_TAX_INSIDE_CITY_LIMITS
        , STREET_SUFFIX
        , PROGRAM_ID
        , DO_NOT_VALIDATE_FLAG
        , GLOBAL_ATTRIBUTE5
        , GLOBAL_ATTRIBUTE4
        , POSITION
        , GLOBAL_ATTRIBUTE7
        , FLOOR
        , GLOBAL_ATTRIBUTE6
        , GLOBAL_ATTRIBUTE1
        , GLOBAL_ATTRIBUTE3
        , GLOBAL_ATTRIBUTE2
        , ADDRESS_KEY
        , GLOBAL_ATTRIBUTE9
        , GLOBAL_ATTRIBUTE8
        , CONTENT_SOURCE_TYPE
        , ATTRIBUTE3
        , LANGUAGE
        , CREATED_BY_MODULE
        , ATTRIBUTE2
        , ORIG_SYSTEM_REFERENCE
        , ATTRIBUTE1
        , ATTRIBUTE9
        , ATTRIBUTE8
        , ATTRIBUTE7
        , ATTRIBUTE6
        , ATTRIBUTE5
        , ATTRIBUTE4
        , SHORT_DESCRIPTION
        , ADDRESS_ERROR_CODE
        , ATTRIBUTE10
        , HOUSE_NUMBER
        , ADDRESS_LINES_PHONETIC
        , ATTRIBUTE14
        , ATTRIBUTE13
        , ATTRIBUTE12
        , ATTRIBUTE11
        , DELIVERY_POINT_CODE
        , SECONDARY_SUFFIX_ELEMENT
        , TIMEZONE_ID
        , SALES_TAX_GEOCODE
        , POSTAL_CODE
        , POST_OFFICE
        , DESCRIPTION
        , ADDRESS_EFFECTIVE_DATE
        , ATTRIBUTE20
        , SUITE
        , GEOMETRY_STATUS_CODE
        , GLOBAL_ATTRIBUTE20
        , STREET
        , GLOBAL_ATTRIBUTE17
        , GLOBAL_ATTRIBUTE18
        , GLOBAL_ATTRIBUTE15
        , GLOBAL_ATTRIBUTE16
        , GLOBAL_ATTRIBUTE13
        , CITY
        , FA_LOCATION_ID
        , GLOBAL_ATTRIBUTE14
        , GLOBAL_ATTRIBUTE11
        , GLOBAL_ATTRIBUTE12
        , ATTRIBUTE18
        , ATTRIBUTE17
        , ATTRIBUTE16
        , ATTRIBUTE15
        , GLOBAL_ATTRIBUTE19
        , ATTRIBUTE19
        , POSTAL_PLUS4_CODE
        , RURAL_ROUTE_TYPE
        , STREET_NUMBER
        , OVERSEAS_ADDRESS_FLAG
        , GLOBAL_ATTRIBUTE10
        , LAST_UPDATE_DATE
        , GEOMETRY_SOURCE
        , LOCATION_DIRECTIONS
        , OBJECT_VERSION_NUMBER
        , COUNTRY
        , LIFE_CYCLE_STATUS
        , COUNTY
        , CREATED_BY
        , LAST_UPDATED_BY
        , CREATION_DATE
        , PROGRAM_UPDATE_DATE
        , APARTMENT_FLAG
        , ATTRIBUTE_CATEGORY
        , ACTUAL_CONTENT_SOURCE
        , PROGRAM_APPLICATION_ID
        , LOC_HIERARCHY_ID
        , VALIDATION_STATUS_CODE
        , APPLICATION_ID
        , STATE
        , REQUEST_ID
        , APARTMENT_NUMBER
        , ADDRESS_STYLE
        , DATE_VALIDATED
        , TIME_ZONE
        , BUILDING
        , ADDRESS1
        , ADDRESS_EXPIRATION_DATE
        , ADDRESS3
        , ADDRESS2
        , ADDRESS4
        , DODAAC
        , LAST_UPDATE_LOGIN
        , PO_BOX_NUMBER
        , CLLI_CODE
        , GLOBAL_ATTRIBUTE_CATEGORY
        , VALIDATED_FLAG
        , WH_UPDATE_DATE
        , PROVINCE
        , ROOM
        , TRAILING_DIRECTORY_CODE
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
        , COALESCE(NULLIF(TRIM(CAST(CUST_ACCT_SITE_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as CUSTOMER_SITE_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(LOCATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(RURAL_ROUTE_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(SALES_TAX_INSIDE_CITY_LIMITS::text), '^^') 
            , '||', IFNULL(TRIM(STREET_SUFFIX::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_ID::text), '^^') 
            , '||', IFNULL(TRIM(DO_NOT_VALIDATE_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE5::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE4::text), '^^') 
            , '||', IFNULL(TRIM(POSITION::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE7::text), '^^') 
            , '||', IFNULL(TRIM(FLOOR::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE6::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE1::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE3::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE2::text), '^^') 
            , '||', IFNULL(TRIM(ADDRESS_KEY::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE9::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE8::text), '^^') 
            , '||', IFNULL(TRIM(CONTENT_SOURCE_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE3::text), '^^') 
            , '||', IFNULL(TRIM(LANGUAGE::text), '^^') 
            , '||', IFNULL(TRIM(CREATED_BY_MODULE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE2::text), '^^') 
            , '||', IFNULL(TRIM(ORIG_SYSTEM_REFERENCE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE1::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE9::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE8::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE7::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE6::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE5::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE4::text), '^^') 
            , '||', IFNULL(TRIM(SHORT_DESCRIPTION::text), '^^') 
            , '||', IFNULL(TRIM(ADDRESS_ERROR_CODE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE10::text), '^^') 
            , '||', IFNULL(TRIM(HOUSE_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(ADDRESS_LINES_PHONETIC::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE14::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE13::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE12::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE11::text), '^^') 
            , '||', IFNULL(TRIM(DELIVERY_POINT_CODE::text), '^^') 
            , '||', IFNULL(TRIM(SECONDARY_SUFFIX_ELEMENT::text), '^^') 
            , '||', IFNULL(TRIM(TIMEZONE_ID::text), '^^') 
            , '||', IFNULL(TRIM(SALES_TAX_GEOCODE::text), '^^') 
            , '||', IFNULL(TRIM(POSTAL_CODE::text), '^^') 
            , '||', IFNULL(TRIM(POST_OFFICE::text), '^^') 
            , '||', IFNULL(TRIM(DESCRIPTION::text), '^^') 
            , '||', IFNULL(TRIM(ADDRESS_EFFECTIVE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE20::text), '^^') 
            , '||', IFNULL(TRIM(SUITE::text), '^^') 
            , '||', IFNULL(TRIM(GEOMETRY_STATUS_CODE::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE20::text), '^^') 
            , '||', IFNULL(TRIM(STREET::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE17::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE18::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE15::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE16::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE13::text), '^^') 
            , '||', IFNULL(TRIM(CITY::text), '^^') 
            , '||', IFNULL(TRIM(FA_LOCATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE14::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE11::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE12::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE18::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE17::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE16::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE15::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE19::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE19::text), '^^') 
            , '||', IFNULL(TRIM(POSTAL_PLUS4_CODE::text), '^^') 
            , '||', IFNULL(TRIM(RURAL_ROUTE_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(STREET_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(OVERSEAS_ADDRESS_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE10::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(GEOMETRY_SOURCE::text), '^^') 
            , '||', IFNULL(TRIM(LOCATION_DIRECTIONS::text), '^^') 
            , '||', IFNULL(TRIM(OBJECT_VERSION_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(COUNTRY::text), '^^') 
            , '||', IFNULL(TRIM(LIFE_CYCLE_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(COUNTY::text), '^^') 
            , '||', IFNULL(TRIM(CREATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(CREATION_DATE::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_UPDATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(APARTMENT_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(ACTUAL_CONTENT_SOURCE::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_APPLICATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(LOC_HIERARCHY_ID::text), '^^') 
            , '||', IFNULL(TRIM(VALIDATION_STATUS_CODE::text), '^^') 
            , '||', IFNULL(TRIM(APPLICATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(STATE::text), '^^') 
            , '||', IFNULL(TRIM(REQUEST_ID::text), '^^') 
            , '||', IFNULL(TRIM(APARTMENT_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(ADDRESS_STYLE::text), '^^') 
            , '||', IFNULL(TRIM(DATE_VALIDATED::text), '^^') 
            , '||', IFNULL(TRIM(TIME_ZONE::text), '^^') 
            , '||', IFNULL(TRIM(BUILDING::text), '^^') 
            , '||', IFNULL(TRIM(ADDRESS1::text), '^^') 
            , '||', IFNULL(TRIM(ADDRESS_EXPIRATION_DATE::text), '^^') 
            , '||', IFNULL(TRIM(ADDRESS3::text), '^^') 
            , '||', IFNULL(TRIM(ADDRESS2::text), '^^') 
            , '||', IFNULL(TRIM(ADDRESS4::text), '^^') 
            , '||', IFNULL(TRIM(DODAAC::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_LOGIN::text), '^^') 
            , '||', IFNULL(TRIM(PO_BOX_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(CLLI_CODE::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(VALIDATED_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(WH_UPDATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(PROVINCE::text), '^^') 
            , '||', IFNULL(TRIM(ROOM::text), '^^') 
            , '||', IFNULL(TRIM(TRAILING_DIRECTORY_CODE::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^')             
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
