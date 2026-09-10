---- SRC LAYER ----
WITH
SRC_o              as ( SELECT * FROM {{ source('ml_ebs_hr', 'hr_all_organization_units') }} as SRC  ),
SRC_org_info       as ( SELECT * FROM {{ source('ml_ebs_hr', 'hr_organization_information') }} as SRC 
                        where 
                        org_information_context = 'CLASS'
                        and org_information1 in ( 'HR_LEGAL', 'OPERATING_UNIT')
                        
                        qualify 1=(row_number()over(partition by organization_id order by psa_load_dts)) ),
SRC_A              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_o              as ( SELECT * FROM ml_ebs_hr.hr_all_organization_units )
, SRC_org_info       as ( SELECT * FROM ml_ebs_hr.hr_organization_information )
, SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_o as (
    SELECT
        CONVERT_TIMEZONE('UTC',_FIVETRAN_SYNCED)                     as                                           LOAD_DTS
      , ORGANIZATION_ID
      , ATTRIBUTE30
      , BUSINESS_GROUP_ID
      , LAST_UPDATE_DATE
      , PROGRAM_ID
      , INTERNAL_ADDRESS_LINE
      , OBJECT_VERSION_NUMBER
      , ATTRIBUTE29
      , ATTRIBUTE28
      , ATTRIBUTE27
      , ATTRIBUTE26
      , TYPE
      , ATTRIBUTE3
      , CREATED_BY
      , ATTRIBUTE2
      , LAST_UPDATED_BY
      , ATTRIBUTE1
      , INTERNAL_EXTERNAL_FLAG
      , CREATION_DATE
      , ATTRIBUTE9
      , ATTRIBUTE8
      , ATTRIBUTE7
      , ATTRIBUTE6
      , PROGRAM_UPDATE_DATE
      , ATTRIBUTE5
      , NAME
      , ATTRIBUTE4
      , ATTRIBUTE_CATEGORY
      , PROGRAM_APPLICATION_ID
      , PARTY_ID
      , ATTRIBUTE10
      , ATTRIBUTE14
      , ATTRIBUTE13
      , ATTRIBUTE12
      , ATTRIBUTE11
      , REQUEST_ID
      , LOCATION_ID
      , ATTRIBUTE21
      , SOFT_CODING_KEYFLEX_ID
      , COST_ALLOCATION_KEYFLEX_ID
      , ATTRIBUTE20
      , ATTRIBUTE25
      , DATE_FROM
      , ATTRIBUTE24
      , ATTRIBUTE23
      , ATTRIBUTE22
      , LAST_UPDATE_LOGIN
      , ATTRIBUTE18
      , ATTRIBUTE17
      , ATTRIBUTE16
      , ATTRIBUTE15
      , DATE_TO
      , ATTRIBUTE19
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_DELETE_IND
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
        LOAD_DTS
      , ORGANIZATION_ID
      , ATTRIBUTE30
      , BUSINESS_GROUP_ID
      , LAST_UPDATE_DATE
      , PROGRAM_ID
      , INTERNAL_ADDRESS_LINE
      , OBJECT_VERSION_NUMBER
      , ATTRIBUTE29
      , ATTRIBUTE28
      , ATTRIBUTE27
      , ATTRIBUTE26
      , TYPE
      , ATTRIBUTE3
      , CREATED_BY
      , ATTRIBUTE2
      , LAST_UPDATED_BY
      , ATTRIBUTE1
      , INTERNAL_EXTERNAL_FLAG
      , CREATION_DATE
      , ATTRIBUTE9
      , ATTRIBUTE8
      , ATTRIBUTE7
      , ATTRIBUTE6
      , PROGRAM_UPDATE_DATE
      , ATTRIBUTE5
      , NAME
      , ATTRIBUTE4
      , ATTRIBUTE_CATEGORY
      , PROGRAM_APPLICATION_ID
      , PARTY_ID
      , ATTRIBUTE10
      , ATTRIBUTE14
      , ATTRIBUTE13
      , ATTRIBUTE12
      , ATTRIBUTE11
      , REQUEST_ID
      , LOCATION_ID
      , ATTRIBUTE21
      , SOFT_CODING_KEYFLEX_ID
      , COST_ALLOCATION_KEYFLEX_ID
      , ATTRIBUTE20
      , ATTRIBUTE25
      , DATE_FROM
      , ATTRIBUTE24
      , ATTRIBUTE23
      , ATTRIBUTE22
      , LAST_UPDATE_LOGIN
      , ATTRIBUTE18
      , ATTRIBUTE17
      , ATTRIBUTE16
      , ATTRIBUTE15
      , DATE_TO
      , ATTRIBUTE19
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_DELETE_IND
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
    WHERE rec_src = 'USWIOC.ORCL.EBSPRD.HR_ALL_ORGANIZATION_UNITS'
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
          LOAD_DTS
        , ORGANIZATION_ID
        , ATTRIBUTE30
        , BUSINESS_GROUP_ID
        , LAST_UPDATE_DATE
        , PROGRAM_ID
        , INTERNAL_ADDRESS_LINE
        , OBJECT_VERSION_NUMBER
        , ATTRIBUTE29
        , ATTRIBUTE28
        , ATTRIBUTE27
        , ATTRIBUTE26
        , TYPE
        , ATTRIBUTE3
        , CREATED_BY
        , ATTRIBUTE2
        , LAST_UPDATED_BY
        , ATTRIBUTE1
        , INTERNAL_EXTERNAL_FLAG
        , CREATION_DATE
        , ATTRIBUTE9
        , ATTRIBUTE8
        , ATTRIBUTE7
        , ATTRIBUTE6
        , PROGRAM_UPDATE_DATE
        , ATTRIBUTE5
        , NAME
        , ATTRIBUTE4
        , ATTRIBUTE_CATEGORY
        , PROGRAM_APPLICATION_ID
        , PARTY_ID
        , ATTRIBUTE10
        , ATTRIBUTE14
        , ATTRIBUTE13
        , ATTRIBUTE12
        , ATTRIBUTE11
        , REQUEST_ID
        , LOCATION_ID
        , ATTRIBUTE21
        , SOFT_CODING_KEYFLEX_ID
        , COST_ALLOCATION_KEYFLEX_ID
        , ATTRIBUTE20
        , ATTRIBUTE25
        , DATE_FROM
        , ATTRIBUTE24
        , ATTRIBUTE23
        , ATTRIBUTE22
        , LAST_UPDATE_LOGIN
        , ATTRIBUTE18
        , ATTRIBUTE17
        , ATTRIBUTE16
        , ATTRIBUTE15
        , DATE_TO
        , ATTRIBUTE19
        , _FIVETRAN_DELETED
        , _FIVETRAN_SYNCED
        , PSA_LOAD_DTS
        , PSA_DELETE_IND
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ORGANIZATION_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as LEGAL_ENTITY_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(ATTRIBUTE30::text), '^^') 
            , '||', IFNULL(TRIM(BUSINESS_GROUP_ID::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_ID::text), '^^') 
            , '||', IFNULL(TRIM(INTERNAL_ADDRESS_LINE::text), '^^') 
            , '||', IFNULL(TRIM(OBJECT_VERSION_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE29::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE28::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE27::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE26::text), '^^') 
            , '||', IFNULL(TRIM(TYPE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE3::text), '^^') 
            , '||', IFNULL(TRIM(CREATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE2::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE1::text), '^^') 
            , '||', IFNULL(TRIM(INTERNAL_EXTERNAL_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(CREATION_DATE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE9::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE8::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE7::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE6::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_UPDATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE5::text), '^^') 
            , '||', IFNULL(TRIM(NAME::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE4::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_APPLICATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(PARTY_ID::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE10::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE14::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE13::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE12::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE11::text), '^^') 
            , '||', IFNULL(TRIM(REQUEST_ID::text), '^^') 
            , '||', IFNULL(TRIM(LOCATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE21::text), '^^') 
            , '||', IFNULL(TRIM(SOFT_CODING_KEYFLEX_ID::text), '^^') 
            , '||', IFNULL(TRIM(COST_ALLOCATION_KEYFLEX_ID::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE20::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE25::text), '^^') 
            , '||', IFNULL(TRIM(DATE_FROM::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE24::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE23::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE22::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_LOGIN::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE18::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE17::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE16::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE15::text), '^^') 
            , '||', IFNULL(TRIM(DATE_TO::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE19::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
