---- SRC LAYER ----
WITH
SRC_SITMFB         as ( SELECT * FROM {{ ref('v_psa_stg_item_language__fib_ocf') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_SITMFB         as ( SELECT * FROM STAGING.v_psa_stg_item_language__fib_ocf )
*/
---- LOGIC LAYER ----

, LOGIC_SITMFB as (
    SELECT
        ITEM_HK
      , INVENTORY_ITEM_ID
      , LANGUAGE
      , ORGANIZATION_ID
      , CREATED_BY
      , LAST_UPDATE_DATE
      , LAST_UPDATED_BY
      , TEMPLATE_NAME
      , DESCRIPTION
      , LONG_DESCRIPTION
      , SOURCE_LANG
      , LAST_UPDATE_LOGIN
      , CREATION_DATE
      , OBJECT_VERSION_NUMBER
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
      , LANGUAGE
      , ORGANIZATION_ID
      , CREATED_BY
      , LAST_UPDATE_DATE
      , LAST_UPDATED_BY
      , TEMPLATE_NAME
      , DESCRIPTION
      , LONG_DESCRIPTION
      , SOURCE_LANG
      , LAST_UPDATE_LOGIN
      , CREATION_DATE
      , OBJECT_VERSION_NUMBER
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
        , LANGUAGE
        , ORGANIZATION_ID
        , CREATED_BY
        , LAST_UPDATE_DATE
        , LAST_UPDATED_BY
        , TEMPLATE_NAME
        , DESCRIPTION
        , LONG_DESCRIPTION
        , SOURCE_LANG
        , LAST_UPDATE_LOGIN
        , CREATION_DATE
        , OBJECT_VERSION_NUMBER
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
    AND existing.LANGUAGE = JOIN_RESULT.LANGUAGE 
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %} 
{% if not is_incremental() %}
/*the following qualify is to restrict multiple loads of touched records during the initial build. Ex: multiple row per hk, hashdiff */
qualify 1= row_number()over(partition by ITEM_HK, INVENTORY_ITEM_ID ,ORGANIZATION_ID,LANGUAGE,HASHDIFF order by PSA_LOAD_DTS)
union all
    SELECT        MD5_BINARY(GR.VALUE) AS ITEM_HK
    ,  GR.VALUE::NUMBER as INVENTORY_ITEM_ID
    , GR.VALUE as LANGUAGE
    , GR.VALUE::NUMBER as ORGANIZATION_ID
    , null as CREATED_BY
    , null as LAST_UPDATE_DATE
    , null as LAST_UPDATED_BY
    , null as TEMPLATE_NAME
    , null as DESCRIPTION
    , null as LONG_DESCRIPTION
    , null as SOURCE_LANG
    , null as LAST_UPDATE_LOGIN
    , null as CREATION_DATE
    , null as OBJECT_VERSION_NUMBER    
   , null as _FIVETRAN_DELETED
    , null as _FIVETRAN_SYNCED
, null as PSA_DELETE_IND
, null as PSA_LOAD_DTS
, null as PSA_RECORD_SOURCE
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)::TIMESTAMP as LOAD_DTS
,'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
, ''::BINARY as HASHDIFF
  FROM
        TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}