---- SRC LAYER ----
WITH
SRC_S              as ( SELECT * FROM {{ source('outd_ocf_egp', 'egp_item_relationships_b') }} as SRC  ),
SRC_A              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  ),
SRC_S2             as ( SELECT * FROM {{ source('outd_ocf_egp', 'egp_system_items_b') }} as SRC 
                        qualify 1 = row_number()over (partition by inventory_item_id order by psa_load_dts )  )

/*
SRC_S              as ( SELECT * FROM outd_ocf_egp.egp_item_relationships_b )
, SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
, SRC_S2             as ( SELECT * FROM outd_ocf_egp.egp_system_items_b )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        INVENTORY_ITEM_ID
      , ORGANIZATION_ID
      , ITEM_RELATIONSHIP_ID
      , ITEM_RELATIONSHIP_TYPE
      , ATTRIBUTE_17
      , ATTRIBUTE_1
      , PROGRAM_NAME
      , VERSION_END_DATE
      , ACD_TYPE
      , RELATED_ITEM_ID
      , ATTRIBUTE_8
      , ATTRIBUTE_22
      , ATTRIBUTE_11
      , ATTRIBUTE_10
      , IMPLEMENTATION_DATE
      , OBJECT_VERSION_NUMBER
      , LAST_UPDATED_BY
      , ATTRIBUTE_DATE_3
      , ATTRIBUTE_7
      , REVISION_ID
      , JOB_DEFINITION_PACKAGE
      , ATTRIBUTE_25
      , FIRST_ARTICLE_STATUS
      , ATTRIBUTE_14
      , ATTRIBUTE_NUMBER_7
      , REQUEST_ID
      , ATTRIBUTE_23
      , ATTRIBUTE_15
      , DESCRIPTION
      , ATTRIBUTE_29
      , INACTIVE_FLAG
      , ATTRIBUTE_TIMESTAMP_4
      , ATTRIBUTE_16
      , ATTRIBUTE_DATE_5
      , PREFERENCE_NUMBER
      , APPROVAL_STATUS
      , ATTRIBUTE_TIMESTAMP_1
      , ATTRIBUTE_30
      , ATTRIBUTE_NUMBER_8
      , CREATION_DATE
      , START_DATE_ACTIVE
      , ATTRIBUTE_DATE_2
      , ATTRIBUTE_NUMBER_10
      , CHANGE_LINE_ID
      , PROGRAM_APP_NAME
      , ATTRIBUTE_TIMESTAMP_5
      , MASTER_ORGANIZATION_ID
      , SOURCE_SYSTEM_ID
      , ATTRIBUTE_21
      , ATTRIBUTE_4
      , ATTRIBUTE_TIMESTAMP_3
      , ATTRIBUTE_2
      , VERSION_START_DATE
      , ATTRIBUTE_13
      , CROSS_REFERENCE
      , ATTRIBUTE_NUMBER_5
      , ATTRIBUTE_18
      , ATTRIBUTE_27
      , TRADING_PARTNER_ID
      , ATTRIBUTE_NUMBER_6
      , RELATEDITEM_RANK
      , ATTRIBUTE_NUMBER_1
      , TP_ITEM_ID
      , RECIPROCAL_FLAG
      , ATTRIBUTE_NUMBER_9
      , END_DATE_ACTIVE
      , ATTRIBUTE_12
      , VERSION_ID
      , ALT_ITEM_RELATIONSHIP_CODE
      , ATTRIBUTE_19
      , ATTRIBUTE_26
      , UOM_CODE
      , ATTRIBUTE_28
      , ATTRIBUTE_NUMBER_3
      , ATTRIBUTE_DATE_1
      , ATTRIBUTE_NUMBER_2
      , JOB_DEFINITION_NAME
      , CREATED_BY
      , ATTRIBUTE_NUMBER_4
      , LAST_UPDATE_LOGIN
      , ATTRIBUTE_CATEGORY
      , STATUS_CODE
      , ATTRIBUTE_TIMESTAMP_2
      , PLANNING_ENABLED_FLAG
      , ATTRIBUTE_20
      , ATTRIBUTE_24
      , ATTRIBUTE_DATE_4
      , ORG_INDEPENDENT_FLAG
      , LAST_UPDATE_DATE
      , ATTRIBUTE_6
      , EPC_GTIN_SERIAL
      , MRP_PLANNING_CODE
      , ATTRIBUTE_3
      , ATTRIBUTE_9
      , ATTRIBUTE_5
      , RELATIONSHIP_RANK
      , CHANGE_BIT_MAP
      , SUB_TYPE
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

, LOGIC_S2 as (
    SELECT
        ITEM_NUMBER
      , INVENTORY_ITEM_ID                                            as                               S2_INVENTORY_ITEM_ID
    FROM SRC_S2
)
---- RENAME LAYER ----

, RENAME_S as (
    SELECT
        INVENTORY_ITEM_ID
      , ORGANIZATION_ID
      , ITEM_RELATIONSHIP_ID
      , ITEM_RELATIONSHIP_TYPE
      , ATTRIBUTE_17
      , ATTRIBUTE_1
      , PROGRAM_NAME
      , VERSION_END_DATE
      , ACD_TYPE
      , RELATED_ITEM_ID
      , ATTRIBUTE_8
      , ATTRIBUTE_22
      , ATTRIBUTE_11
      , ATTRIBUTE_10
      , IMPLEMENTATION_DATE
      , OBJECT_VERSION_NUMBER
      , LAST_UPDATED_BY
      , ATTRIBUTE_DATE_3
      , ATTRIBUTE_7
      , REVISION_ID
      , JOB_DEFINITION_PACKAGE
      , ATTRIBUTE_25
      , FIRST_ARTICLE_STATUS
      , ATTRIBUTE_14
      , ATTRIBUTE_NUMBER_7
      , REQUEST_ID
      , ATTRIBUTE_23
      , ATTRIBUTE_15
      , DESCRIPTION
      , ATTRIBUTE_29
      , INACTIVE_FLAG
      , ATTRIBUTE_TIMESTAMP_4
      , ATTRIBUTE_16
      , ATTRIBUTE_DATE_5
      , PREFERENCE_NUMBER
      , APPROVAL_STATUS
      , ATTRIBUTE_TIMESTAMP_1
      , ATTRIBUTE_30
      , ATTRIBUTE_NUMBER_8
      , CREATION_DATE
      , START_DATE_ACTIVE
      , ATTRIBUTE_DATE_2
      , ATTRIBUTE_NUMBER_10
      , CHANGE_LINE_ID
      , PROGRAM_APP_NAME
      , ATTRIBUTE_TIMESTAMP_5
      , MASTER_ORGANIZATION_ID
      , SOURCE_SYSTEM_ID
      , ATTRIBUTE_21
      , ATTRIBUTE_4
      , ATTRIBUTE_TIMESTAMP_3
      , ATTRIBUTE_2
      , VERSION_START_DATE
      , ATTRIBUTE_13
      , CROSS_REFERENCE
      , ATTRIBUTE_NUMBER_5
      , ATTRIBUTE_18
      , ATTRIBUTE_27
      , TRADING_PARTNER_ID
      , ATTRIBUTE_NUMBER_6
      , RELATEDITEM_RANK
      , ATTRIBUTE_NUMBER_1
      , TP_ITEM_ID
      , RECIPROCAL_FLAG
      , ATTRIBUTE_NUMBER_9
      , END_DATE_ACTIVE
      , ATTRIBUTE_12
      , VERSION_ID
      , ALT_ITEM_RELATIONSHIP_CODE
      , ATTRIBUTE_19
      , ATTRIBUTE_26
      , UOM_CODE
      , ATTRIBUTE_28
      , ATTRIBUTE_NUMBER_3
      , ATTRIBUTE_DATE_1
      , ATTRIBUTE_NUMBER_2
      , JOB_DEFINITION_NAME
      , CREATED_BY
      , ATTRIBUTE_NUMBER_4
      , LAST_UPDATE_LOGIN
      , ATTRIBUTE_CATEGORY
      , STATUS_CODE
      , ATTRIBUTE_TIMESTAMP_2
      , PLANNING_ENABLED_FLAG
      , ATTRIBUTE_20
      , ATTRIBUTE_24
      , ATTRIBUTE_DATE_4
      , ORG_INDEPENDENT_FLAG
      , LAST_UPDATE_DATE
      , ATTRIBUTE_6
      , EPC_GTIN_SERIAL
      , MRP_PLANNING_CODE
      , ATTRIBUTE_3
      , ATTRIBUTE_9
      , ATTRIBUTE_5
      , RELATIONSHIP_RANK
      , CHANGE_BIT_MAP
      , SUB_TYPE
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

, RENAME_S2 as (
    SELECT
        ITEM_NUMBER
      , S2_INVENTORY_ITEM_ID
    FROM LOGIC_S2
)
---- FILTER LAYER ----

, FILTER_S as (
    SELECT *
    FROM RENAME_S
)

, FILTER_A as (
    SELECT *
    FROM RENAME_A
    WHERE rec_src = 'USCLOUD.ORCL.OCFPRD.EGP_ITEM_RELATIONSHIPS_B'
)

, FILTER_S2 as (
    SELECT *
    FROM RENAME_S2
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_S
    INNER JOIN FILTER_A
        ON '1' = '1'
    LEFT JOIN FILTER_S2
        ON inventory_item_id = S2_inventory_item_id
)

---- FINAL LAYER ----
SELECT
          coalesce(nullif(trim(ITEM_NUMBER), ''), '-1')                as ITEM_BK
        , INVENTORY_ITEM_ID
        , ORGANIZATION_ID
        , ITEM_RELATIONSHIP_ID
        , ITEM_RELATIONSHIP_TYPE
        , ATTRIBUTE_17
        , ATTRIBUTE_1
        , PROGRAM_NAME
        , VERSION_END_DATE
        , ACD_TYPE
        , RELATED_ITEM_ID
        , ATTRIBUTE_8
        , ATTRIBUTE_22
        , ATTRIBUTE_11
        , ATTRIBUTE_10
        , IMPLEMENTATION_DATE
        , OBJECT_VERSION_NUMBER
        , LAST_UPDATED_BY
        , ATTRIBUTE_DATE_3
        , ATTRIBUTE_7
        , REVISION_ID
        , JOB_DEFINITION_PACKAGE
        , ATTRIBUTE_25
        , FIRST_ARTICLE_STATUS
        , ATTRIBUTE_14
        , ATTRIBUTE_NUMBER_7
        , REQUEST_ID
        , ATTRIBUTE_23
        , ATTRIBUTE_15
        , DESCRIPTION
        , ATTRIBUTE_29
        , INACTIVE_FLAG
        , ATTRIBUTE_TIMESTAMP_4
        , ATTRIBUTE_16
        , ATTRIBUTE_DATE_5
        , PREFERENCE_NUMBER
        , APPROVAL_STATUS
        , ATTRIBUTE_TIMESTAMP_1
        , ATTRIBUTE_30
        , ATTRIBUTE_NUMBER_8
        , CREATION_DATE
        , START_DATE_ACTIVE
        , ATTRIBUTE_DATE_2
        , ATTRIBUTE_NUMBER_10
        , CHANGE_LINE_ID
        , PROGRAM_APP_NAME
        , ATTRIBUTE_TIMESTAMP_5
        , MASTER_ORGANIZATION_ID
        , SOURCE_SYSTEM_ID
        , ATTRIBUTE_21
        , ATTRIBUTE_4
        , ATTRIBUTE_TIMESTAMP_3
        , ATTRIBUTE_2
        , VERSION_START_DATE
        , ATTRIBUTE_13
        , CROSS_REFERENCE
        , ATTRIBUTE_NUMBER_5
        , ATTRIBUTE_18
        , ATTRIBUTE_27
        , TRADING_PARTNER_ID
        , ATTRIBUTE_NUMBER_6
        , RELATEDITEM_RANK
        , ATTRIBUTE_NUMBER_1
        , TP_ITEM_ID
        , RECIPROCAL_FLAG
        , ATTRIBUTE_NUMBER_9
        , END_DATE_ACTIVE
        , ATTRIBUTE_12
        , VERSION_ID
        , ALT_ITEM_RELATIONSHIP_CODE
        , ATTRIBUTE_19
        , ATTRIBUTE_26
        , UOM_CODE
        , ATTRIBUTE_28
        , ATTRIBUTE_NUMBER_3
        , ATTRIBUTE_DATE_1
        , ATTRIBUTE_NUMBER_2
        , JOB_DEFINITION_NAME
        , CREATED_BY
        , ATTRIBUTE_NUMBER_4
        , LAST_UPDATE_LOGIN
        , ATTRIBUTE_CATEGORY
        , STATUS_CODE
        , ATTRIBUTE_TIMESTAMP_2
        , PLANNING_ENABLED_FLAG
        , ATTRIBUTE_20
        , ATTRIBUTE_24
        , ATTRIBUTE_DATE_4
        , ORG_INDEPENDENT_FLAG
        , LAST_UPDATE_DATE
        , ATTRIBUTE_6
        , EPC_GTIN_SERIAL
        , MRP_PLANNING_CODE
        , ATTRIBUTE_3
        , ATTRIBUTE_9
        , ATTRIBUTE_5
        , RELATIONSHIP_RANK
        , CHANGE_BIT_MAP
        , SUB_TYPE
        , _FIVETRAN_DELETED
        , _FIVETRAN_SYNCED
        , PSA_DELETE_IND
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ITEM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ITEM_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(INVENTORY_ITEM_ID::text), '^^') 
            , '||', IFNULL(TRIM(ORGANIZATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_RELATIONSHIP_ID::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_RELATIONSHIP_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_17::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_1::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_NAME::text), '^^') 
            , '||', IFNULL(TRIM(VERSION_END_DATE::text), '^^') 
            , '||', IFNULL(TRIM(ACD_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(RELATED_ITEM_ID::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_8::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_22::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_11::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_10::text), '^^') 
            , '||', IFNULL(TRIM(IMPLEMENTATION_DATE::text), '^^') 
            , '||', IFNULL(TRIM(OBJECT_VERSION_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_DATE_3::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_7::text), '^^') 
            , '||', IFNULL(TRIM(REVISION_ID::text), '^^') 
            , '||', IFNULL(TRIM(JOB_DEFINITION_PACKAGE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_25::text), '^^') 
            , '||', IFNULL(TRIM(FIRST_ARTICLE_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_14::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_7::text), '^^') 
            , '||', IFNULL(TRIM(REQUEST_ID::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_23::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_15::text), '^^') 
            , '||', IFNULL(TRIM(DESCRIPTION::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_29::text), '^^') 
            , '||', IFNULL(TRIM(INACTIVE_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_TIMESTAMP_4::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_16::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_DATE_5::text), '^^') 
            , '||', IFNULL(TRIM(PREFERENCE_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(APPROVAL_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_TIMESTAMP_1::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_30::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_8::text), '^^') 
            , '||', IFNULL(TRIM(CREATION_DATE::text), '^^') 
            , '||', IFNULL(TRIM(START_DATE_ACTIVE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_DATE_2::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_10::text), '^^') 
            , '||', IFNULL(TRIM(CHANGE_LINE_ID::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_APP_NAME::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_TIMESTAMP_5::text), '^^') 
            , '||', IFNULL(TRIM(MASTER_ORGANIZATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(SOURCE_SYSTEM_ID::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_21::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_4::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_TIMESTAMP_3::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_2::text), '^^') 
            , '||', IFNULL(TRIM(VERSION_START_DATE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_13::text), '^^') 
            , '||', IFNULL(TRIM(CROSS_REFERENCE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_5::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_18::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_27::text), '^^') 
            , '||', IFNULL(TRIM(TRADING_PARTNER_ID::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_6::text), '^^') 
            , '||', IFNULL(TRIM(RELATEDITEM_RANK::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_1::text), '^^') 
            , '||', IFNULL(TRIM(TP_ITEM_ID::text), '^^') 
            , '||', IFNULL(TRIM(RECIPROCAL_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_9::text), '^^') 
            , '||', IFNULL(TRIM(END_DATE_ACTIVE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_12::text), '^^') 
            , '||', IFNULL(TRIM(VERSION_ID::text), '^^') 
            , '||', IFNULL(TRIM(ALT_ITEM_RELATIONSHIP_CODE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_19::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_26::text), '^^') 
            , '||', IFNULL(TRIM(UOM_CODE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_28::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_3::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_DATE_1::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_2::text), '^^') 
            , '||', IFNULL(TRIM(JOB_DEFINITION_NAME::text), '^^') 
            , '||', IFNULL(TRIM(CREATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_4::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_LOGIN::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(STATUS_CODE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_TIMESTAMP_2::text), '^^') 
            , '||', IFNULL(TRIM(PLANNING_ENABLED_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_20::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_24::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_DATE_4::text), '^^') 
            , '||', IFNULL(TRIM(ORG_INDEPENDENT_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_6::text), '^^') 
            , '||', IFNULL(TRIM(EPC_GTIN_SERIAL::text), '^^') 
            , '||', IFNULL(TRIM(MRP_PLANNING_CODE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_3::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_9::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_5::text), '^^') 
            , '||', IFNULL(TRIM(RELATIONSHIP_RANK::text), '^^') 
            , '||', IFNULL(TRIM(CHANGE_BIT_MAP::text), '^^') 
            , '||', IFNULL(TRIM(SUB_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
