---- SRC LAYER ----
WITH
SRC_SITMFB         as ( SELECT * FROM {{ ref('v_psa_stg_item_categories__fib_ocf') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_SITMFB         as ( SELECT * FROM STAGING.v_psa_stg_ITEM_CATEGORIES__fib_ocf  )
*/
---- LOGIC LAYER ----

, LOGIC_SITMFB as (
    SELECT
        ITEM_HK
      , INVENTORY_ITEM_ID
      , ORGANIZATION_ID
      , CATEGORY_ID
      , CATEGORY_SET_ID
      , CREATION_DATE
      , ALT_ITEM_CAT_CODE
      , START_DATE
      , LAST_UPDATED_BY
      , PROGRAM_NAME
      , PROGRAM_APP_NAME
      , OBJECT_VERSION_NUMBER
      , CREATED_BY
      , ITEM_CATEGORY_ASSIGNMENT_ID
      , END_DATE
      , LAST_UPDATE_DATE
      , LAST_UPDATE_LOGIN
      , JOB_DEFINITION_PACKAGE
      , JOB_DEFINITION_NAME
      , SEQUENCE_NUMBER
      , REQUEST_ID
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
      , INVENTORY_ITEM_ID
      , ORGANIZATION_ID
      , CATEGORY_ID
      , CATEGORY_SET_ID
      , CREATION_DATE
      , ALT_ITEM_CAT_CODE
      , START_DATE
      , LAST_UPDATED_BY
      , PROGRAM_NAME
      , PROGRAM_APP_NAME
      , OBJECT_VERSION_NUMBER
      , CREATED_BY
      , ITEM_CATEGORY_ASSIGNMENT_ID
      , END_DATE
      , LAST_UPDATE_DATE
      , LAST_UPDATE_LOGIN
      , JOB_DEFINITION_PACKAGE
      , JOB_DEFINITION_NAME
      , SEQUENCE_NUMBER
      , REQUEST_ID
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
        , INVENTORY_ITEM_ID
        , ORGANIZATION_ID
        , CATEGORY_ID
        , CATEGORY_SET_ID
        , CREATION_DATE
        , ALT_ITEM_CAT_CODE
        , START_DATE
        , LAST_UPDATED_BY
        , PROGRAM_NAME
        , PROGRAM_APP_NAME
        , OBJECT_VERSION_NUMBER
        , CREATED_BY
        , ITEM_CATEGORY_ASSIGNMENT_ID
        , END_DATE
        , LAST_UPDATE_DATE
        , LAST_UPDATE_LOGIN
        , JOB_DEFINITION_PACKAGE
        , JOB_DEFINITION_NAME
        , SEQUENCE_NUMBER
        , REQUEST_ID
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
     AND existing.INVENTORY_ITEM_ID = JOIN_RESULT.INVENTORY_ITEM_ID 
     AND existing.ORGANIZATION_ID = JOIN_RESULT.ORGANIZATION_ID 
     AND existing.CATEGORY_ID = JOIN_RESULT.CATEGORY_ID 
     AND existing.CATEGORY_SET_ID = JOIN_RESULT.CATEGORY_SET_ID
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %} 
{% if not is_incremental() %}
/*the following qualify is to restrict multiple loads of touched records during the initial build. Ex: multiple row per hk, hashdiff */
qualify 1= row_number()over(partition by ITEM_HK, INVENTORY_ITEM_ID ,ORGANIZATION_ID,CATEGORY_ID,CATEGORY_SET_ID,HASHDIFF order by PSA_LOAD_DTS)
union all
    SELECT        MD5_BINARY(GR.VALUE) AS ITEM_HK
    ,  GR.VALUE::NUMBER as INVENTORY_ITEM_ID
    , GR.VALUE::NUMBER as ORGANIZATION_ID
    , GR.VALUE::NUMBER as CATEGORY_ID
    , GR.VALUE::NUMBER as CATEGORY_SET_ID
    , null as CREATION_DATE
    , null as ALT_ITEM_CAT_CODE
    , null as START_DATE
    , null as LAST_UPDATED_BY
    , null as PROGRAM_NAME
    , null as PROGRAM_APP_NAME
    , null as OBJECT_VERSION_NUMBER
    , null as CREATED_BY
    , null as ITEM_CATEGORY_ASSIGNMENT_ID
    , null as END_DATE
    , null as LAST_UPDATE_DATE
    , null as LAST_UPDATE_LOGIN
    , null as JOB_DEFINITION_PACKAGE
    , null as JOB_DEFINITION_NAME
    , null as SEQUENCE_NUMBER
    , null as REQUEST_ID
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