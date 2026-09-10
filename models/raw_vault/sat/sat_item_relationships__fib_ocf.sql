---- SRC LAYER ----
WITH
SRC_SITMFB         as ( SELECT * FROM {{ ref('v_psa_stg_item_relationships__fib_ocf') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_SITMFB         as ( SELECT * FROM STAGING.v_psa_stg_item_relationships__fib_ocf )
*/
---- LOGIC LAYER ----

, LOGIC_SITMFB as (
    SELECT
        ITEM_HK
      , ITEM_RELATIONSHIP_ID
      , INVENTORY_ITEM_ID
      , ORGANIZATION_ID
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
      , SUB_TYPE                                                     as                                ATTRIBUTE_NUMBER_13
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , LOAD_DTS
      , REC_SRC
      , HASHDIFF
    FROM SRC_SITMFB
)
---- RENAME LAYER ----

, RENAME_SITMFB as (
    SELECT
        ITEM_HK
      , ITEM_RELATIONSHIP_ID
      , INVENTORY_ITEM_ID
      , ORGANIZATION_ID
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
      , ATTRIBUTE_NUMBER_13
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , LOAD_DTS
      , REC_SRC
      , HASHDIFF
    FROM LOGIC_SITMFB
)
---- FILTER LAYER ----

, FILTER_SITMFB as (
    SELECT *
    FROM RENAME_SITMFB
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_SITMFB
)

---- FINAL LAYER ----
SELECT
          ITEM_HK
        , ITEM_RELATIONSHIP_ID
        , INVENTORY_ITEM_ID
        , ORGANIZATION_ID
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
        , ATTRIBUTE_NUMBER_13
        , _FIVETRAN_DELETED
        , _FIVETRAN_SYNCED
        , PSA_DELETE_IND
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , LOAD_DTS
        , REC_SRC
        , HASHDIFF
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.ITEM_HK= JOIN_RESULT.ITEM_HK
     AND existing.ITEM_RELATIONSHIP_ID = JOIN_RESULT.ITEM_RELATIONSHIP_ID
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %} 
{% if not is_incremental() %}
/*the following qualify is to restrict multiple loads of touched records during the initial build. Ex: multiple row per hk, hashdiff */
qualify 1= row_number()over(partition by ITEM_HK, ITEM_RELATIONSHIP_ID, HASHDIFF order by PSA_LOAD_DTS)
union all
    SELECT        MD5_BINARY(GR.VALUE) AS ITEM_HK
    , GR.VALUE::NUMBER as ITEM_RELATIONSHIP_ID 
    , null as INVENTORY_ITEM_ID
    , null as ORGANIZATION_ID
    , null as ITEM_RELATIONSHIP_TYPE
    , null as ATTRIBUTE_17
    , null as ATTRIBUTE_1
    , null as PROGRAM_NAME
    , null as VERSION_END_DATE
    , null as ACD_TYPE
    , null as RELATED_ITEM_ID
    , null as ATTRIBUTE_8
    , null as ATTRIBUTE_22
    , null as ATTRIBUTE_11
    , null as ATTRIBUTE_10
    , null as IMPLEMENTATION_DATE
    , null as OBJECT_VERSION_NUMBER
    , null as LAST_UPDATED_BY
    , null as ATTRIBUTE_DATE_3
    , null as ATTRIBUTE_7
    , null as REVISION_ID
    , null as JOB_DEFINITION_PACKAGE
    , null as ATTRIBUTE_25
    , null as FIRST_ARTICLE_STATUS
    , null as ATTRIBUTE_14
    , null as ATTRIBUTE_NUMBER_7
    , null as REQUEST_ID
    , null as ATTRIBUTE_23
    , null as ATTRIBUTE_15
    , null as DESCRIPTION
    , null as ATTRIBUTE_29
    , null as INACTIVE_FLAG
    , null as ATTRIBUTE_TIMESTAMP_4
    , null as ATTRIBUTE_16
    , null as ATTRIBUTE_DATE_5
    , null as PREFERENCE_NUMBER
    , null as APPROVAL_STATUS
    , null as ATTRIBUTE_TIMESTAMP_1
    , null as ATTRIBUTE_30
    , null as ATTRIBUTE_NUMBER_8
    , null as CREATION_DATE
    , null as START_DATE_ACTIVE
    , null as ATTRIBUTE_DATE_2
    , null as ATTRIBUTE_NUMBER_10
    , null as CHANGE_LINE_ID
    , null as PROGRAM_APP_NAME
    , null as ATTRIBUTE_TIMESTAMP_5
    , null as MASTER_ORGANIZATION_ID
    , null as SOURCE_SYSTEM_ID
    , null as ATTRIBUTE_21
    , null as ATTRIBUTE_4
    , null as ATTRIBUTE_TIMESTAMP_3
    , null as ATTRIBUTE_2
    , null as VERSION_START_DATE
    , null as ATTRIBUTE_13
    , null as CROSS_REFERENCE
    , null as ATTRIBUTE_NUMBER_5
    , null as ATTRIBUTE_18
    , null as ATTRIBUTE_27
    , null as TRADING_PARTNER_ID
    , null as ATTRIBUTE_NUMBER_6
    , null as RELATEDITEM_RANK
    , null as ATTRIBUTE_NUMBER_1
    , null as TP_ITEM_ID
    , null as RECIPROCAL_FLAG
    , null as ATTRIBUTE_NUMBER_9
    , null as END_DATE_ACTIVE
    , null as ATTRIBUTE_12
    , null as VERSION_ID
    , null as ALT_ITEM_RELATIONSHIP_CODE
    , null as ATTRIBUTE_19
    , null as ATTRIBUTE_26
    , null as UOM_CODE
    , null as ATTRIBUTE_28
    , null as ATTRIBUTE_NUMBER_3
    , null as ATTRIBUTE_DATE_1
    , null as ATTRIBUTE_NUMBER_2
    , null as JOB_DEFINITION_NAME
    , null as CREATED_BY
    , null as ATTRIBUTE_NUMBER_4
    , null as LAST_UPDATE_LOGIN
    , null as ATTRIBUTE_CATEGORY
    , null as STATUS_CODE
    , null as ATTRIBUTE_TIMESTAMP_2
    , null as PLANNING_ENABLED_FLAG
    , null as ATTRIBUTE_20
    , null as ATTRIBUTE_24
    , null as ATTRIBUTE_DATE_4
    , null as ORG_INDEPENDENT_FLAG
    , null as LAST_UPDATE_DATE
    , null as ATTRIBUTE_6
    , null as EPC_GTIN_SERIAL
    , null as MRP_PLANNING_CODE
    , null as ATTRIBUTE_3
    , null as ATTRIBUTE_9
    , null as ATTRIBUTE_5
    , null as RELATIONSHIP_RANK
    , null as CHANGE_BIT_MAP
    , null as ATTRIBUTE_NUMBER_13
    , null as _FIVETRAN_DELETED
    , null as _FIVETRAN_SYNCED
    , null as PSA_DELETE_IND
    , null as PSA_LOAD_DTS
    , null as PSA_RECORD_SOURCE, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)::TIMESTAMP as LOAD_DTS
,'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
, ''::BINARY as HASHDIFF
  FROM
        TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}