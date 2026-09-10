---- SRC LAYER ----
WITH
SRC_o              as ( SELECT ACTIVITY_CODE, ATTRIBUTE_1, ATTRIBUTE_10, ATTRIBUTE_11, ATTRIBUTE_12, ATTRIBUTE_13, ATTRIBUTE_14, ATTRIBUTE_15, ATTRIBUTE_16, ATTRIBUTE_17, ATTRIBUTE_18, ATTRIBUTE_19, ATTRIBUTE_2, ATTRIBUTE_20, ATTRIBUTE_3, ATTRIBUTE_4, ATTRIBUTE_5, ATTRIBUTE_6, ATTRIBUTE_7, ATTRIBUTE_8, ATTRIBUTE_9, ATTRIBUTE_CATEGORY, ATTRIBUTE_DATE_1, ATTRIBUTE_DATE_2, ATTRIBUTE_DATE_3, ATTRIBUTE_DATE_4, ATTRIBUTE_DATE_5, ATTRIBUTE_NUMBER_1, ATTRIBUTE_NUMBER_2, ATTRIBUTE_NUMBER_3, ATTRIBUTE_NUMBER_4, ATTRIBUTE_NUMBER_5, CREATED_BY, CREATION_DATE, EFFECTIVE_FROM, EFFECTIVE_TO, ENTERPRISE_ID, GEOGRAPHY_ID, LAST_UPDATED_BY, LAST_UPDATE_DATE, LAST_UPDATE_LOGIN, LEGAL_EMPLOYER_FLAG, LEGAL_ENTITY_ID, LEGAL_ENTITY_IDENTIFIER, LE_INFORMATION_1, LE_INFORMATION_10, LE_INFORMATION_11, LE_INFORMATION_12, LE_INFORMATION_13, LE_INFORMATION_14, LE_INFORMATION_15, LE_INFORMATION_16, LE_INFORMATION_17, LE_INFORMATION_18, LE_INFORMATION_19, LE_INFORMATION_2, LE_INFORMATION_20, LE_INFORMATION_3, LE_INFORMATION_4, LE_INFORMATION_5, LE_INFORMATION_6, LE_INFORMATION_7, LE_INFORMATION_8, LE_INFORMATION_9, LE_INFORMATION_CONTEXT, LE_INFORMATION_DATE_1, LE_INFORMATION_DATE_2, LE_INFORMATION_DATE_3, LE_INFORMATION_DATE_4, LE_INFORMATION_DATE_5, LE_INFORMATION_NUMBER_1, LE_INFORMATION_NUMBER_2, LE_INFORMATION_NUMBER_3, LE_INFORMATION_NUMBER_4, LE_INFORMATION_NUMBER_5, NAME, OBJECT_VERSION_NUMBER, PARENT_PSU_ID, PARTY_ID, PSA_DELETE_IND, PSA_LOAD_DTS, PSU_FLAG, SUB_ACTIVITY_CODE, TRANSACTING_ENTITY_FLAG, TYPE_OF_COMPANY, _FIVETRAN_DELETED, _FIVETRAN_SYNCED FROM {{ source('outd_ocf_xle', 'xle_entity_profiles') }} as SRC  ),
SRC_A              as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_o              as ( SELECT * FROM outd_ocf_xle.xle_entity_profiles )
SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_o as (
    SELECT
        CONVERT_TIMEZONE('UTC',_FIVETRAN_SYNCED)                     as                                           LOAD_DTS
      , LEGAL_ENTITY_IDENTIFIER                                      as                                    LEGAL_ENTITY_BK
      , LEGAL_ENTITY_IDENTIFIER
      , LEGAL_ENTITY_ID
      , LE_INFORMATION_DATE_4
      , ATTRIBUTE_DATE_3
      , ATTRIBUTE_DATE_4
      , ATTRIBUTE_DATE_5
      , ACTIVITY_CODE
      , SUB_ACTIVITY_CODE
      , LE_INFORMATION_5
      , EFFECTIVE_FROM
      , EFFECTIVE_TO
      , LE_INFORMATION_CONTEXT
      , LE_INFORMATION_1
      , LE_INFORMATION_3
      , PARTY_ID
      , ATTRIBUTE_CATEGORY
      , ATTRIBUTE_1
      , ATTRIBUTE_2
      , ATTRIBUTE_3
      , ATTRIBUTE_4
      , ATTRIBUTE_5
      , LE_INFORMATION_15
      , LE_INFORMATION_16
      , LE_INFORMATION_13
      , LE_INFORMATION_14
      , ATTRIBUTE_DATE_2
      , LE_INFORMATION_17
      , LE_INFORMATION_18
      , NAME
      , GEOGRAPHY_ID
      , TRANSACTING_ENTITY_FLAG
      , ATTRIBUTE_12
      , ATTRIBUTE_13
      , ATTRIBUTE_14
      , LE_INFORMATION_DATE_5
      , TYPE_OF_COMPANY
      , ATTRIBUTE_6
      , ATTRIBUTE_7
      , ATTRIBUTE_8
      , ATTRIBUTE_9
      , ATTRIBUTE_10
      , ATTRIBUTE_11
      , ATTRIBUTE_16
      , ATTRIBUTE_17
      , LE_INFORMATION_8
      , LE_INFORMATION_9
      , LE_INFORMATION_10
      , LE_INFORMATION_11
      , LE_INFORMATION_12
      , ATTRIBUTE_NUMBER_2
      , ATTRIBUTE_NUMBER_3
      , ATTRIBUTE_NUMBER_4
      , ATTRIBUTE_18
      , ATTRIBUTE_15
      , ATTRIBUTE_19
      , ATTRIBUTE_20
      , ATTRIBUTE_NUMBER_1
      , ATTRIBUTE_NUMBER_5
      , ATTRIBUTE_DATE_1
      , LE_INFORMATION_NUMBER_1
      , LE_INFORMATION_NUMBER_2
      , LE_INFORMATION_NUMBER_3
      , LE_INFORMATION_NUMBER_4
      , LE_INFORMATION_NUMBER_5
      , LE_INFORMATION_DATE_1
      , LE_INFORMATION_DATE_2
      , LE_INFORMATION_DATE_3
      , PSU_FLAG
      , LEGAL_EMPLOYER_FLAG
      , PARENT_PSU_ID
      , ENTERPRISE_ID
      , LE_INFORMATION_4
      , LE_INFORMATION_2
      , LE_INFORMATION_6
      , LE_INFORMATION_7
      , LE_INFORMATION_19
      , LE_INFORMATION_20
      , LAST_UPDATED_BY
      , CREATION_DATE
      , LAST_UPDATE_LOGIN
      , LAST_UPDATE_DATE
      , CREATED_BY
      , OBJECT_VERSION_NUMBER
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_DELETE_IND
    FROM SRC_o
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
      , LEGAL_ENTITY_BK
      , LEGAL_ENTITY_IDENTIFIER
      , LEGAL_ENTITY_ID
      , LE_INFORMATION_DATE_4
      , ATTRIBUTE_DATE_3
      , ATTRIBUTE_DATE_4
      , ATTRIBUTE_DATE_5
      , ACTIVITY_CODE
      , SUB_ACTIVITY_CODE
      , LE_INFORMATION_5
      , EFFECTIVE_FROM
      , EFFECTIVE_TO
      , LE_INFORMATION_CONTEXT
      , LE_INFORMATION_1
      , LE_INFORMATION_3
      , PARTY_ID
      , ATTRIBUTE_CATEGORY
      , ATTRIBUTE_1
      , ATTRIBUTE_2
      , ATTRIBUTE_3
      , ATTRIBUTE_4
      , ATTRIBUTE_5
      , LE_INFORMATION_15
      , LE_INFORMATION_16
      , LE_INFORMATION_13
      , LE_INFORMATION_14
      , ATTRIBUTE_DATE_2
      , LE_INFORMATION_17
      , LE_INFORMATION_18
      , NAME
      , GEOGRAPHY_ID
      , TRANSACTING_ENTITY_FLAG
      , ATTRIBUTE_12
      , ATTRIBUTE_13
      , ATTRIBUTE_14
      , LE_INFORMATION_DATE_5
      , TYPE_OF_COMPANY
      , ATTRIBUTE_6
      , ATTRIBUTE_7
      , ATTRIBUTE_8
      , ATTRIBUTE_9
      , ATTRIBUTE_10
      , ATTRIBUTE_11
      , ATTRIBUTE_16
      , ATTRIBUTE_17
      , LE_INFORMATION_8
      , LE_INFORMATION_9
      , LE_INFORMATION_10
      , LE_INFORMATION_11
      , LE_INFORMATION_12
      , ATTRIBUTE_NUMBER_2
      , ATTRIBUTE_NUMBER_3
      , ATTRIBUTE_NUMBER_4
      , ATTRIBUTE_18
      , ATTRIBUTE_15
      , ATTRIBUTE_19
      , ATTRIBUTE_20
      , ATTRIBUTE_NUMBER_1
      , ATTRIBUTE_NUMBER_5
      , ATTRIBUTE_DATE_1
      , LE_INFORMATION_NUMBER_1
      , LE_INFORMATION_NUMBER_2
      , LE_INFORMATION_NUMBER_3
      , LE_INFORMATION_NUMBER_4
      , LE_INFORMATION_NUMBER_5
      , LE_INFORMATION_DATE_1
      , LE_INFORMATION_DATE_2
      , LE_INFORMATION_DATE_3
      , PSU_FLAG
      , LEGAL_EMPLOYER_FLAG
      , PARENT_PSU_ID
      , ENTERPRISE_ID
      , LE_INFORMATION_4
      , LE_INFORMATION_2
      , LE_INFORMATION_6
      , LE_INFORMATION_7
      , LE_INFORMATION_19
      , LE_INFORMATION_20
      , LAST_UPDATED_BY
      , CREATION_DATE
      , LAST_UPDATE_LOGIN
      , LAST_UPDATE_DATE
      , CREATED_BY
      , OBJECT_VERSION_NUMBER
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
---- FILTER LAYER ----

, FILTER_o as (
    SELECT *
    FROM RENAME_o
)

, FILTER_A as (
    SELECT *
    FROM RENAME_A
    WHERE rec_src = 'USCLOUD.ORCL.OCFPRD.XLE_ENTITY_PROFILES'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_o
    INNER JOIN FILTER_A
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          LOAD_DTS
        , LEGAL_ENTITY_BK
        , LEGAL_ENTITY_IDENTIFIER
        , LEGAL_ENTITY_ID
        , LE_INFORMATION_DATE_4
        , ATTRIBUTE_DATE_3
        , ATTRIBUTE_DATE_4
        , ATTRIBUTE_DATE_5
        , ACTIVITY_CODE
        , SUB_ACTIVITY_CODE
        , LE_INFORMATION_5
        , EFFECTIVE_FROM
        , EFFECTIVE_TO
        , LE_INFORMATION_CONTEXT
        , LE_INFORMATION_1
        , LE_INFORMATION_3
        , PARTY_ID
        , ATTRIBUTE_CATEGORY
        , ATTRIBUTE_1
        , ATTRIBUTE_2
        , ATTRIBUTE_3
        , ATTRIBUTE_4
        , ATTRIBUTE_5
        , LE_INFORMATION_15
        , LE_INFORMATION_16
        , LE_INFORMATION_13
        , LE_INFORMATION_14
        , ATTRIBUTE_DATE_2
        , LE_INFORMATION_17
        , LE_INFORMATION_18
        , NAME
        , GEOGRAPHY_ID
        , TRANSACTING_ENTITY_FLAG
        , ATTRIBUTE_12
        , ATTRIBUTE_13
        , ATTRIBUTE_14
        , LE_INFORMATION_DATE_5
        , TYPE_OF_COMPANY
        , ATTRIBUTE_6
        , ATTRIBUTE_7
        , ATTRIBUTE_8
        , ATTRIBUTE_9
        , ATTRIBUTE_10
        , ATTRIBUTE_11
        , ATTRIBUTE_16
        , ATTRIBUTE_17
        , LE_INFORMATION_8
        , LE_INFORMATION_9
        , LE_INFORMATION_10
        , LE_INFORMATION_11
        , LE_INFORMATION_12
        , ATTRIBUTE_NUMBER_2
        , ATTRIBUTE_NUMBER_3
        , ATTRIBUTE_NUMBER_4
        , ATTRIBUTE_18
        , ATTRIBUTE_15
        , ATTRIBUTE_19
        , ATTRIBUTE_20
        , ATTRIBUTE_NUMBER_1
        , ATTRIBUTE_NUMBER_5
        , ATTRIBUTE_DATE_1
        , LE_INFORMATION_NUMBER_1
        , LE_INFORMATION_NUMBER_2
        , LE_INFORMATION_NUMBER_3
        , LE_INFORMATION_NUMBER_4
        , LE_INFORMATION_NUMBER_5
        , LE_INFORMATION_DATE_1
        , LE_INFORMATION_DATE_2
        , LE_INFORMATION_DATE_3
        , PSU_FLAG
        , LEGAL_EMPLOYER_FLAG
        , PARENT_PSU_ID
        , ENTERPRISE_ID
        , LE_INFORMATION_4
        , LE_INFORMATION_2
        , LE_INFORMATION_6
        , LE_INFORMATION_7
        , LE_INFORMATION_19
        , LE_INFORMATION_20
        , LAST_UPDATED_BY
        , CREATION_DATE
        , LAST_UPDATE_LOGIN
        , LAST_UPDATE_DATE
        , CREATED_BY
        , OBJECT_VERSION_NUMBER
        , _FIVETRAN_DELETED
        , _FIVETRAN_SYNCED
        , PSA_LOAD_DTS
        , PSA_DELETE_IND
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(LEGAL_ENTITY_IDENTIFIER as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as LEGAL_ENTITY_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(LEGAL_ENTITY_ID::text), '^^') 
            , '||', IFNULL(TRIM(LE_INFORMATION_DATE_4::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_DATE_3::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_DATE_4::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_DATE_5::text), '^^') 
            , '||', IFNULL(TRIM(ACTIVITY_CODE::text), '^^') 
            , '||', IFNULL(TRIM(SUB_ACTIVITY_CODE::text), '^^') 
            , '||', IFNULL(TRIM(LE_INFORMATION_5::text), '^^') 
            , '||', IFNULL(TRIM(EFFECTIVE_FROM::text), '^^') 
            , '||', IFNULL(TRIM(EFFECTIVE_TO::text), '^^') 
            , '||', IFNULL(TRIM(LE_INFORMATION_CONTEXT::text), '^^') 
            , '||', IFNULL(TRIM(LE_INFORMATION_1::text), '^^') 
            , '||', IFNULL(TRIM(LE_INFORMATION_3::text), '^^') 
            , '||', IFNULL(TRIM(PARTY_ID::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_1::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_2::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_3::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_4::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_5::text), '^^') 
            , '||', IFNULL(TRIM(LE_INFORMATION_15::text), '^^') 
            , '||', IFNULL(TRIM(LE_INFORMATION_16::text), '^^') 
            , '||', IFNULL(TRIM(LE_INFORMATION_13::text), '^^') 
            , '||', IFNULL(TRIM(LE_INFORMATION_14::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_DATE_2::text), '^^') 
            , '||', IFNULL(TRIM(LE_INFORMATION_17::text), '^^') 
            , '||', IFNULL(TRIM(LE_INFORMATION_18::text), '^^') 
            , '||', IFNULL(TRIM(NAME::text), '^^') 
            , '||', IFNULL(TRIM(GEOGRAPHY_ID::text), '^^') 
            , '||', IFNULL(TRIM(TRANSACTING_ENTITY_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_12::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_13::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_14::text), '^^') 
            , '||', IFNULL(TRIM(LE_INFORMATION_DATE_5::text), '^^') 
            , '||', IFNULL(TRIM(TYPE_OF_COMPANY::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_6::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_7::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_8::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_9::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_10::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_11::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_16::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_17::text), '^^') 
            , '||', IFNULL(TRIM(LE_INFORMATION_8::text), '^^') 
            , '||', IFNULL(TRIM(LE_INFORMATION_9::text), '^^') 
            , '||', IFNULL(TRIM(LE_INFORMATION_10::text), '^^') 
            , '||', IFNULL(TRIM(LE_INFORMATION_11::text), '^^') 
            , '||', IFNULL(TRIM(LE_INFORMATION_12::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_2::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_3::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_4::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_18::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_15::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_19::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_20::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_1::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_5::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_DATE_1::text), '^^') 
            , '||', IFNULL(TRIM(LE_INFORMATION_NUMBER_1::text), '^^') 
            , '||', IFNULL(TRIM(LE_INFORMATION_NUMBER_2::text), '^^') 
            , '||', IFNULL(TRIM(LE_INFORMATION_NUMBER_3::text), '^^') 
            , '||', IFNULL(TRIM(LE_INFORMATION_NUMBER_4::text), '^^') 
            , '||', IFNULL(TRIM(LE_INFORMATION_NUMBER_5::text), '^^') 
            , '||', IFNULL(TRIM(LE_INFORMATION_DATE_1::text), '^^') 
            , '||', IFNULL(TRIM(LE_INFORMATION_DATE_2::text), '^^') 
            , '||', IFNULL(TRIM(LE_INFORMATION_DATE_3::text), '^^') 
            , '||', IFNULL(TRIM(PSU_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(LEGAL_EMPLOYER_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(PARENT_PSU_ID::text), '^^') 
            , '||', IFNULL(TRIM(ENTERPRISE_ID::text), '^^') 
            , '||', IFNULL(TRIM(LE_INFORMATION_4::text), '^^') 
            , '||', IFNULL(TRIM(LE_INFORMATION_2::text), '^^') 
            , '||', IFNULL(TRIM(LE_INFORMATION_6::text), '^^') 
            , '||', IFNULL(TRIM(LE_INFORMATION_7::text), '^^') 
            , '||', IFNULL(TRIM(LE_INFORMATION_19::text), '^^') 
            , '||', IFNULL(TRIM(LE_INFORMATION_20::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(CREATION_DATE::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_LOGIN::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(CREATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(OBJECT_VERSION_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
