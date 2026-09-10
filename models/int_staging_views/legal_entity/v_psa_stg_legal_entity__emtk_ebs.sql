---- SRC LAYER ----
WITH
    src_o AS (
        SELECT
            name,
            organization_id,
            business_group_id,
            location_id,
            soft_coding_keyflex_id,
            date_from,
            date_to,
            internal_external_flag,
            internal_address_line,
            type,
            request_id,
            program_application_id,
            program_id,
            program_update_date,
            attribute_category,
            attribute1,
            attribute2,
            attribute3,
            attribute4,
            attribute5,
            attribute6,
            attribute7,
            attribute8,
            attribute9,
            attribute10,
            attribute11,
            attribute12,
            attribute13,
            attribute14,
            attribute15,
            attribute16,
            attribute17,
            attribute18,
            attribute19,
            attribute20,
            last_update_date,
            last_updated_by,
            last_update_login,
            created_by,
            creation_date,
            object_version_number,
            party_id,
            comments,
            attribute21,
            attribute22,
            attribute23,
            attribute24,
            attribute25,
            attribute26,
            attribute27,
            attribute28,
            attribute29,
            attribute30,
            cost_allocation_keyflex_id_1,
            _fivetran_deleted,
            _fivetran_synced,
            psa_load_dts,
            psa_delete_ind
        FROM {{ source('emtk_ebs_hr', 'hr_all_organization_units') }} AS src
    ),
    src_org_info AS (
        SELECT
            organization_id,
            org_information_context,
            org_information1
        FROM {{ source('emtk_ebs_hr', 'hr_organization_information') }} AS src
        WHERE
            org_information_context = 'Legal Entity Accounting'
    ),
    src_a AS (
        SELECT
            rec_src,
            bkcc
        FROM {{ ref('ref_business_key_collision') }} AS src
    )

/*
SRC_o              as ( SELECT * FROM emtk_ebs_hr.hr_all_organization_units )
SRC_org_info       as ( SELECT * FROM emtk_ebs_hr.hr_organization_information )
SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_o as (
    SELECT
        NAME                                                         as                                    LEGAL_ENTITY_BK
      , ORGANIZATION_ID
      , NAME
      , BUSINESS_GROUP_ID
      , LOCATION_ID
      , SOFT_CODING_KEYFLEX_ID
      , DATE_FROM
      , DATE_TO
      , INTERNAL_EXTERNAL_FLAG
      , INTERNAL_ADDRESS_LINE
      , TYPE
      , REQUEST_ID
      , PROGRAM_APPLICATION_ID
      , PROGRAM_ID
      , PROGRAM_UPDATE_DATE
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
      , LAST_UPDATE_DATE
      , LAST_UPDATED_BY
      , LAST_UPDATE_LOGIN
      , CREATED_BY
      , CREATION_DATE
      , OBJECT_VERSION_NUMBER
      , PARTY_ID
      , COMMENTS
      , ATTRIBUTE21
      , ATTRIBUTE22
      , ATTRIBUTE23
      , ATTRIBUTE24
      , ATTRIBUTE25
      , ATTRIBUTE26
      , ATTRIBUTE27
      , ATTRIBUTE28
      , ATTRIBUTE29
      , ATTRIBUTE30
      , COST_ALLOCATION_KEYFLEX_ID_1
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_DELETE_IND
      , CONVERT_TIMEZONE('UTC',_FIVETRAN_SYNCED)                     as                                           LOAD_DTS
    FROM SRC_o
)

, LOGIC_org_info as (
    SELECT
        ORGANIZATION_ID                                              as                           org_info_organization_id
      , ORG_INFORMATION_CONTEXT
      , ORG_INFORMATION1
    FROM SRC_org_info
)

, LOGIC_A as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_A
)
---- RENAME LAYER ----

, RENAME_o as (
    SELECT
        LEGAL_ENTITY_BK
      , ORGANIZATION_ID
      , NAME
      , BUSINESS_GROUP_ID
      , LOCATION_ID
      , SOFT_CODING_KEYFLEX_ID
      , DATE_FROM
      , DATE_TO
      , INTERNAL_EXTERNAL_FLAG
      , INTERNAL_ADDRESS_LINE
      , TYPE
      , REQUEST_ID
      , PROGRAM_APPLICATION_ID
      , PROGRAM_ID
      , PROGRAM_UPDATE_DATE
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
      , LAST_UPDATE_DATE
      , LAST_UPDATED_BY
      , LAST_UPDATE_LOGIN
      , CREATED_BY
      , CREATION_DATE
      , OBJECT_VERSION_NUMBER
      , PARTY_ID
      , COMMENTS
      , ATTRIBUTE21
      , ATTRIBUTE22
      , ATTRIBUTE23
      , ATTRIBUTE24
      , ATTRIBUTE25
      , ATTRIBUTE26
      , ATTRIBUTE27
      , ATTRIBUTE28
      , ATTRIBUTE29
      , ATTRIBUTE30
      , COST_ALLOCATION_KEYFLEX_ID_1
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_DELETE_IND
      , LOAD_DTS
    FROM LOGIC_o
)

, RENAME_A as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_A
)

, RENAME_org_info as (
    SELECT
        org_info_organization_id
      , ORG_INFORMATION_CONTEXT
      , ORG_INFORMATION1
    FROM LOGIC_org_info
)
---- FILTER LAYER ----

, FILTER_o as (
    SELECT *
    FROM RENAME_o
)

, FILTER_org_info as (
    SELECT *
    FROM RENAME_org_info
)

, FILTER_A as (
    SELECT *
    FROM RENAME_A
    WHERE rec_src = 'USWIOC.ORCL.EBSEMTK.HR_ALL_ORGANIZATION_UNITS'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_o
    INNER JOIN FILTER_org_info
        ON FILTER_o.organization_id = org_info_organization_id
    INNER JOIN FILTER_A
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          LEGAL_ENTITY_BK
        , ORGANIZATION_ID
        , NAME
        , BUSINESS_GROUP_ID
        , LOCATION_ID
        , SOFT_CODING_KEYFLEX_ID
        , DATE_FROM
        , DATE_TO
        , INTERNAL_EXTERNAL_FLAG
        , INTERNAL_ADDRESS_LINE
        , TYPE
        , REQUEST_ID
        , PROGRAM_APPLICATION_ID
        , PROGRAM_ID
        , PROGRAM_UPDATE_DATE
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
        , LAST_UPDATE_DATE
        , LAST_UPDATED_BY
        , LAST_UPDATE_LOGIN
        , CREATED_BY
        , CREATION_DATE
        , OBJECT_VERSION_NUMBER
        , PARTY_ID
        , COMMENTS
        , ATTRIBUTE21
        , ATTRIBUTE22
        , ATTRIBUTE23
        , ATTRIBUTE24
        , ATTRIBUTE25
        , ATTRIBUTE26
        , ATTRIBUTE27
        , ATTRIBUTE28
        , ATTRIBUTE29
        , ATTRIBUTE30
        , COST_ALLOCATION_KEYFLEX_ID_1
        , _FIVETRAN_DELETED
        , _FIVETRAN_SYNCED
        , PSA_LOAD_DTS
        , PSA_DELETE_IND
        , REC_SRC
        , LOAD_DTS
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(NAME as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as LEGAL_ENTITY_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(BUSINESS_GROUP_ID::text), '^^') 
            , '||', IFNULL(TRIM(LOCATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(SOFT_CODING_KEYFLEX_ID::text), '^^') 
            , '||', IFNULL(TRIM(DATE_FROM::text), '^^') 
            , '||', IFNULL(TRIM(DATE_TO::text), '^^') 
            , '||', IFNULL(TRIM(INTERNAL_EXTERNAL_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(INTERNAL_ADDRESS_LINE::text), '^^') 
            , '||', IFNULL(TRIM(TYPE::text), '^^') 
            , '||', IFNULL(TRIM(REQUEST_ID::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_APPLICATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_ID::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_UPDATE_DATE::text), '^^') 
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
            , '||', IFNULL(TRIM(LAST_UPDATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_LOGIN::text), '^^') 
            , '||', IFNULL(TRIM(CREATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(CREATION_DATE::text), '^^') 
            , '||', IFNULL(TRIM(OBJECT_VERSION_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(PARTY_ID::text), '^^') 
            , '||', IFNULL(TRIM(COMMENTS::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE21::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE22::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE23::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE24::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE25::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE26::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE27::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE28::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE29::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE30::text), '^^') 
            , '||', IFNULL(TRIM(COST_ALLOCATION_KEYFLEX_ID_1::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
