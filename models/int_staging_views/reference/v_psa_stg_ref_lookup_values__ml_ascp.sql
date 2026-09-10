---- SRC LAYER ----
WITH
SRC_a              as ( SELECT * FROM {{ source('ml_ascp_prod_applsys', 'fnd_lookup_values') }} as SRC  ),
SRC_b              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_a              as ( SELECT * FROM ml_ascp_prod_applsys.fnd_lookup_values )
, SRC_b              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_a as (
    SELECT
        LOOKUP_CODE
      , LOOKUP_TYPE
      , MEANING
      , VIEW_APPLICATION_ID
      , DESCRIPTION
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
      , ATTRIBUTE_CATEGORY
      , ENABLED_FLAG
      , START_DATE_ACTIVE
      , END_DATE_ACTIVE
      , LANGUAGE
      , LEAF_NODE
      , SECURITY_GROUP_ID
      , SOURCE_LANG
      , TAG
      , TERRITORY_CODE
      , ZD_EDITION_NAME
      , ZD_SYNC
      , CREATED_BY
      , CREATION_DATE
      , LAST_UPDATED_BY
      , LAST_UPDATE_DATE
      , LAST_UPDATE_LOGIN
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , _FIVETRAN_DELETED
      , _FIVETRAN_ID
      , _FIVETRAN_SYNCED
      , CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED)                    as                                           LOAD_DTS
    FROM SRC_a
)

, LOGIC_b as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_b
)
---- RENAME LAYER ----

, RENAME_a as (
    SELECT
        LOOKUP_CODE
      , LOOKUP_TYPE
      , MEANING
      , VIEW_APPLICATION_ID
      , DESCRIPTION
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
      , ATTRIBUTE_CATEGORY
      , ENABLED_FLAG
      , START_DATE_ACTIVE
      , END_DATE_ACTIVE
      , LANGUAGE
      , LEAF_NODE
      , SECURITY_GROUP_ID
      , SOURCE_LANG
      , TAG
      , TERRITORY_CODE
      , ZD_EDITION_NAME
      , ZD_SYNC
      , CREATED_BY
      , CREATION_DATE
      , LAST_UPDATED_BY
      , LAST_UPDATE_DATE
      , LAST_UPDATE_LOGIN
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , _FIVETRAN_DELETED
      , _FIVETRAN_ID
      , _FIVETRAN_SYNCED
      , LOAD_DTS
    FROM LOGIC_a
)

, RENAME_b as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_b
)
---- FILTER LAYER ----

, FILTER_a as (
    SELECT *
    FROM RENAME_a
)

, FILTER_b as (
    SELECT *
    FROM RENAME_b
    WHERE rec_src ='USWIOC.ORCL.EBSPRD.FND_LOOKUP_VALUES'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_a
    INNER JOIN FILTER_b
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          CONCAT(LOOKUP_TYPE, '||',LOOKUP_CODE, '||', VIEW_APPLICATION_ID) as LOOKUP_VALUE_BK
        , LOOKUP_CODE
        , LOOKUP_TYPE
        , MEANING
        , VIEW_APPLICATION_ID
        , DESCRIPTION
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
        , ATTRIBUTE_CATEGORY
        , ENABLED_FLAG
        , START_DATE_ACTIVE
        , END_DATE_ACTIVE
        , LANGUAGE
        , LEAF_NODE
        , SECURITY_GROUP_ID
        , SOURCE_LANG
        , TAG
        , TERRITORY_CODE
        , ZD_EDITION_NAME
        , ZD_SYNC
        , CREATED_BY
        , CREATION_DATE
        , LAST_UPDATED_BY
        , LAST_UPDATE_DATE
        , LAST_UPDATE_LOGIN
        , PSA_DELETE_IND
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , _FIVETRAN_DELETED
        , _FIVETRAN_ID
        , _FIVETRAN_SYNCED
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(LOOKUP_TYPE as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(LOOKUP_CODE as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(VIEW_APPLICATION_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as LOOKUP_VALUE_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(LOOKUP_CODE::text), '^^') 
            , '||', IFNULL(TRIM(LOOKUP_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(MEANING::text), '^^') 
            , '||', IFNULL(TRIM(VIEW_APPLICATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(DESCRIPTION::text), '^^') 
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
            , '||', IFNULL(TRIM(ATTRIBUTE_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(ENABLED_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(START_DATE_ACTIVE::text), '^^') 
            , '||', IFNULL(TRIM(END_DATE_ACTIVE::text), '^^') 
            , '||', IFNULL(TRIM(LANGUAGE::text), '^^') 
            , '||', IFNULL(TRIM(LEAF_NODE::text), '^^') 
            , '||', IFNULL(TRIM(SECURITY_GROUP_ID::text), '^^') 
            , '||', IFNULL(TRIM(SOURCE_LANG::text), '^^') 
            , '||', IFNULL(TRIM(TAG::text), '^^') 
            , '||', IFNULL(TRIM(TERRITORY_CODE::text), '^^') 
            , '||', IFNULL(TRIM(ZD_EDITION_NAME::text), '^^') 
            , '||', IFNULL(TRIM(ZD_SYNC::text), '^^') 
            , '||', IFNULL(TRIM(CREATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(CREATION_DATE::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_LOGIN::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
