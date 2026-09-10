---- SRC LAYER ----
WITH
SRC_S              as ( SELECT * FROM {{ source('outd_ocf_egp', 'egp_item_classes_b') }} as SRC  ),
SRC_A              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S              as ( SELECT * FROM outd_ocf_egp.egp_item_classes_b )
, SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        ITEM_CLASS_CODE
      , ITEM_CLASS_ID
      , SEED_DATA_SOURCE
      , ATTRIBUTE_3
      , ATTRIBUTE_DATE_4
      , NIR_CHANGE_TYPE_ID
      , ATTRIBUTE_NUMBER_8
      , ATTRIBUTE_18
      , ATTRIBUTE_1
      , ATTRIBUTE_8
      , PUBLIC_FLAG
      , ATTRIBUTE_7
      , ORA_SEED_SET_2
      , SEMANTIC_REGEN_REQUEST_ID
      , CREATION_DATE
      , ATTRIBUTE_17
      , ATTRIBUTE_TIMESTAMP_4
      , ATTRIBUTE_15
      , ATTRIBUTE_2
      , OBJECT_VERSION_NUMBER
      , ATTRIBUTE_NUMBER_2
      , ITEM_NUM_GEN_METHOD
      , ITEM_DESC_GEN_METHOD
      , ATTRIBUTE_11
      , ORA_SEED_SET_1
      , LAST_UPDATE_DATE
      , ATTRIBUTE_NUMBER_5
      , LAST_UPDATE_LOGIN
      , MATCHING_SETUP_DATA_1
      , ATTRIBUTE_NUMBER_3
      , MATCHING_SETUP_DATA_2
      , CHANGE_ORDER_TYPE_ID
      , JOB_DEFINITION_NAME
      , ATTRIBUTE_DATE_5
      , JOB_DEFINITION_PACKAGE
      , ATTRIBUTE_TIMESTAMP_2
      , ATTRIBUTE_NUMBER_9
      , ATTRIBUTE_10
      , ATTRIBUTE_5
      , PARENT_ITEM_CLASS_ID
      , ATTRIBUTE_20
      , ITEM_CLASS_TYPE
      , ATTRIBUTE_DATE_2
      , ATTRIBUTE_14
      , ATTRIBUTE_12
      , ATTRIBUTE_TIMESTAMP_3
      , CREATED_BY
      , ATTRIBUTE_NUMBER_6
      , ATTRIBUTE_DATE_3
      , ATTRIBUTE_NUMBER_7
      , ATTRIBUTE_NUMBER_10
      , ATTRIBUTE_6
      , REQUEST_ID
      , ATTRIBUTE_9
      , CFG_ITEM_NUM_GEN_METHOD
      , DEFAULT_ITEM_CLASS_FLAG
      , ENABLED_FLAG
      , NIR_REQD
      , ATTRIBUTE_DATE_1
      , ATTRIBUTE_4
      , ATTRIBUTE_13
      , ATTRIBUTE_CATEGORY
      , ATTRIBUTE_TIMESTAMP_5
      , ITEM_CREATION_ALLOWED_FLAG
      , ATTRIBUTE_NUMBER_4
      , ATTRIBUTE_16
      , VERSION_ENABLED_FLAG
      , ATTRIBUTE_NUMBER_1
      , ATTRIBUTE_TIMESTAMP_1
      , ATTRIBUTE_19
      , LAST_UPDATED_BY
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED )                   as                                           LOAD_DTS
    FROM SRC_S
)

, LOGIC_A as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_A
)
---- RENAME LAYER ----

, RENAME_S as (
    SELECT
        ITEM_CLASS_CODE
      , ITEM_CLASS_ID
      , SEED_DATA_SOURCE
      , ATTRIBUTE_3
      , ATTRIBUTE_DATE_4
      , NIR_CHANGE_TYPE_ID
      , ATTRIBUTE_NUMBER_8
      , ATTRIBUTE_18
      , ATTRIBUTE_1
      , ATTRIBUTE_8
      , PUBLIC_FLAG
      , ATTRIBUTE_7
      , ORA_SEED_SET_2
      , SEMANTIC_REGEN_REQUEST_ID
      , CREATION_DATE
      , ATTRIBUTE_17
      , ATTRIBUTE_TIMESTAMP_4
      , ATTRIBUTE_15
      , ATTRIBUTE_2
      , OBJECT_VERSION_NUMBER
      , ATTRIBUTE_NUMBER_2
      , ITEM_NUM_GEN_METHOD
      , ITEM_DESC_GEN_METHOD
      , ATTRIBUTE_11
      , ORA_SEED_SET_1
      , LAST_UPDATE_DATE
      , ATTRIBUTE_NUMBER_5
      , LAST_UPDATE_LOGIN
      , MATCHING_SETUP_DATA_1
      , ATTRIBUTE_NUMBER_3
      , MATCHING_SETUP_DATA_2
      , CHANGE_ORDER_TYPE_ID
      , JOB_DEFINITION_NAME
      , ATTRIBUTE_DATE_5
      , JOB_DEFINITION_PACKAGE
      , ATTRIBUTE_TIMESTAMP_2
      , ATTRIBUTE_NUMBER_9
      , ATTRIBUTE_10
      , ATTRIBUTE_5
      , PARENT_ITEM_CLASS_ID
      , ATTRIBUTE_20
      , ITEM_CLASS_TYPE
      , ATTRIBUTE_DATE_2
      , ATTRIBUTE_14
      , ATTRIBUTE_12
      , ATTRIBUTE_TIMESTAMP_3
      , CREATED_BY
      , ATTRIBUTE_NUMBER_6
      , ATTRIBUTE_DATE_3
      , ATTRIBUTE_NUMBER_7
      , ATTRIBUTE_NUMBER_10
      , ATTRIBUTE_6
      , REQUEST_ID
      , ATTRIBUTE_9
      , CFG_ITEM_NUM_GEN_METHOD
      , DEFAULT_ITEM_CLASS_FLAG
      , ENABLED_FLAG
      , NIR_REQD
      , ATTRIBUTE_DATE_1
      , ATTRIBUTE_4
      , ATTRIBUTE_13
      , ATTRIBUTE_CATEGORY
      , ATTRIBUTE_TIMESTAMP_5
      , ITEM_CREATION_ALLOWED_FLAG
      , ATTRIBUTE_NUMBER_4
      , ATTRIBUTE_16
      , VERSION_ENABLED_FLAG
      , ATTRIBUTE_NUMBER_1
      , ATTRIBUTE_TIMESTAMP_1
      , ATTRIBUTE_19
      , LAST_UPDATED_BY
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , LOAD_DTS
    FROM LOGIC_S
)

, RENAME_A as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_A
)
---- FILTER LAYER ----

, FILTER_S as (
    SELECT *
    FROM RENAME_S
)

, FILTER_A as (
    SELECT *
    FROM RENAME_A
    WHERE rec_src = 'USCLOUD.ORCL.OCFPRD.EGP_ITEM_CLASSES_B'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_S
    INNER JOIN FILTER_A
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          coalesce(nullif(trim(ITEM_CLASS_CODE), ''), '-1')            as ITEM_CLASS_BK
        , ITEM_CLASS_CODE
        , ITEM_CLASS_ID
        , SEED_DATA_SOURCE
        , ATTRIBUTE_3
        , ATTRIBUTE_DATE_4
        , NIR_CHANGE_TYPE_ID
        , ATTRIBUTE_NUMBER_8
        , ATTRIBUTE_18
        , ATTRIBUTE_1
        , ATTRIBUTE_8
        , PUBLIC_FLAG
        , ATTRIBUTE_7
        , ORA_SEED_SET_2
        , SEMANTIC_REGEN_REQUEST_ID
        , CREATION_DATE
        , ATTRIBUTE_17
        , ATTRIBUTE_TIMESTAMP_4
        , ATTRIBUTE_15
        , ATTRIBUTE_2
        , OBJECT_VERSION_NUMBER
        , ATTRIBUTE_NUMBER_2
        , ITEM_NUM_GEN_METHOD
        , ITEM_DESC_GEN_METHOD
        , ATTRIBUTE_11
        , ORA_SEED_SET_1
        , LAST_UPDATE_DATE
        , ATTRIBUTE_NUMBER_5
        , LAST_UPDATE_LOGIN
        , MATCHING_SETUP_DATA_1
        , ATTRIBUTE_NUMBER_3
        , MATCHING_SETUP_DATA_2
        , CHANGE_ORDER_TYPE_ID
        , JOB_DEFINITION_NAME
        , ATTRIBUTE_DATE_5
        , JOB_DEFINITION_PACKAGE
        , ATTRIBUTE_TIMESTAMP_2
        , ATTRIBUTE_NUMBER_9
        , ATTRIBUTE_10
        , ATTRIBUTE_5
        , PARENT_ITEM_CLASS_ID
        , ATTRIBUTE_20
        , ITEM_CLASS_TYPE
        , ATTRIBUTE_DATE_2
        , ATTRIBUTE_14
        , ATTRIBUTE_12
        , ATTRIBUTE_TIMESTAMP_3
        , CREATED_BY
        , ATTRIBUTE_NUMBER_6
        , ATTRIBUTE_DATE_3
        , ATTRIBUTE_NUMBER_7
        , ATTRIBUTE_NUMBER_10
        , ATTRIBUTE_6
        , REQUEST_ID
        , ATTRIBUTE_9
        , CFG_ITEM_NUM_GEN_METHOD
        , DEFAULT_ITEM_CLASS_FLAG
        , ENABLED_FLAG
        , NIR_REQD
        , ATTRIBUTE_DATE_1
        , ATTRIBUTE_4
        , ATTRIBUTE_13
        , ATTRIBUTE_CATEGORY
        , ATTRIBUTE_TIMESTAMP_5
        , ITEM_CREATION_ALLOWED_FLAG
        , ATTRIBUTE_NUMBER_4
        , ATTRIBUTE_16
        , VERSION_ENABLED_FLAG
        , ATTRIBUTE_NUMBER_1
        , ATTRIBUTE_TIMESTAMP_1
        , ATTRIBUTE_19
        , LAST_UPDATED_BY
        , _FIVETRAN_DELETED
        , _FIVETRAN_SYNCED
        , PSA_DELETE_IND
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(SEED_DATA_SOURCE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_3::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_DATE_4::text), '^^') 
            , '||', IFNULL(TRIM(NIR_CHANGE_TYPE_ID::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_8::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_18::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_1::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_8::text), '^^') 
            , '||', IFNULL(TRIM(PUBLIC_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_7::text), '^^') 
            , '||', IFNULL(TRIM(ORA_SEED_SET_2::text), '^^') 
            , '||', IFNULL(TRIM(SEMANTIC_REGEN_REQUEST_ID::text), '^^') 
            , '||', IFNULL(TRIM(CREATION_DATE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_17::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_TIMESTAMP_4::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_15::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_2::text), '^^') 
            , '||', IFNULL(TRIM(OBJECT_VERSION_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_2::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_NUM_GEN_METHOD::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_DESC_GEN_METHOD::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_11::text), '^^') 
            , '||', IFNULL(TRIM(ORA_SEED_SET_1::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_5::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_LOGIN::text), '^^') 
            , '||', IFNULL(TRIM(MATCHING_SETUP_DATA_1::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_3::text), '^^') 
            , '||', IFNULL(TRIM(MATCHING_SETUP_DATA_2::text), '^^') 
            , '||', IFNULL(TRIM(CHANGE_ORDER_TYPE_ID::text), '^^') 
            , '||', IFNULL(TRIM(JOB_DEFINITION_NAME::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_DATE_5::text), '^^') 
            , '||', IFNULL(TRIM(JOB_DEFINITION_PACKAGE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_TIMESTAMP_2::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_9::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_10::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_5::text), '^^') 
            , '||', IFNULL(TRIM(PARENT_ITEM_CLASS_ID::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_20::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_CLASS_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_DATE_2::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_14::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_12::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_TIMESTAMP_3::text), '^^') 
            , '||', IFNULL(TRIM(CREATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_6::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_DATE_3::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_7::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_10::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_6::text), '^^') 
            , '||', IFNULL(TRIM(REQUEST_ID::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_9::text), '^^') 
            , '||', IFNULL(TRIM(CFG_ITEM_NUM_GEN_METHOD::text), '^^') 
            , '||', IFNULL(TRIM(DEFAULT_ITEM_CLASS_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(ENABLED_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(NIR_REQD::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_DATE_1::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_4::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_13::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_TIMESTAMP_5::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_CREATION_ALLOWED_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_4::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_16::text), '^^') 
            , '||', IFNULL(TRIM(VERSION_ENABLED_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_1::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_TIMESTAMP_1::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_19::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
