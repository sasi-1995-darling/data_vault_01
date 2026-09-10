---- SRC LAYER ----
WITH
SRC_a              as ( SELECT * FROM {{ ref('v_psa_stg_ref_lookup_values__ml_ascp') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY LOOKUP_VALUE_HK ORDER BY LOAD_DTS DESC ))=1 )

/*
SRC_a              as ( SELECT * FROM STAGING.V_PSA_STG_REF_LOOKUP_VALUES__ML_ASCP )
*/
---- LOGIC LAYER ----

, LOGIC_a as (
    SELECT
        LOOKUP_VALUE_HK
      , LOOKUP_VALUE_BK
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
      , LOAD_DTS
      , REC_SRC
      , HASHDIFF
      , BKCC
    FROM SRC_a
)
---- RENAME LAYER ----

, RENAME_a as (
    SELECT
        LOOKUP_VALUE_HK
      , LOOKUP_VALUE_BK
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
      , LOAD_DTS
      , REC_SRC
      , HASHDIFF
      , BKCC
    FROM LOGIC_a
)
---- FILTER LAYER ----

, FILTER_a as (
    SELECT *
    FROM RENAME_a
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_a
)

---- FINAL LAYER ----
SELECT
          LOOKUP_VALUE_HK
        , LOOKUP_VALUE_BK
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
        , LOAD_DTS
        , REC_SRC
        , HASHDIFF
        , BKCC
FROM JOIN_RESULT
