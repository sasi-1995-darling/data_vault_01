---- SRC LAYER ----
WITH
SRC_DvItem         as ( SELECT * FROM {{ ref('v_psa_stg_item_details__datavations') }} as SRC 
                        {% if is_incremental() %}
                              where src.load_dts > (select dateadd('HOUR',-1,max(load_dts)) from {{ this }})
                            {% endif %}   )

/*
SRC_DvItem         as ( SELECT * FROM STAGING.v_psa_stg_item_details__datavations )
*/
---- LOGIC LAYER ----

, LOGIC_DvItem as (
    SELECT
        COMPETITIVE_PRODUCT_HK
      , LOAD_DTS
      , BRAND
      , CATEGORY
      , CREATED_AT
      , DEPARTMENT
      , INTERNET_IDS
      , ITEM_ID
      , ITEM_NAME
      , MODIFIED_AT
      , PARENT_CATEGORY
      , RETAILER
      , RETAILER_CATEGORY
      , SECTOR
      , STORE_ITEM_ID
      , PSA_LOAD_DTS
      , PSA_DELETE_IND
      , BKCC
      , REC_SRC
      , HASHDIFF
    FROM SRC_DvItem
)
---- RENAME LAYER ----

, RENAME_DvItem as (
    SELECT
        COMPETITIVE_PRODUCT_HK
      , LOAD_DTS
      , BRAND
      , CATEGORY
      , CREATED_AT
      , DEPARTMENT
      , INTERNET_IDS
      , ITEM_ID
      , ITEM_NAME
      , MODIFIED_AT
      , PARENT_CATEGORY
      , RETAILER
      , RETAILER_CATEGORY
      , SECTOR
      , STORE_ITEM_ID
      , PSA_LOAD_DTS
      , PSA_DELETE_IND
      , BKCC
      , REC_SRC
      , HASHDIFF
    FROM LOGIC_DvItem
)
---- FILTER LAYER ----

, FILTER_DvItem as (
    SELECT *
    FROM RENAME_DvItem
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_DvItem
)

---- FINAL LAYER ----
SELECT
          COMPETITIVE_PRODUCT_HK
        , LOAD_DTS
        , BRAND
        , CATEGORY
        , CREATED_AT
        , DEPARTMENT
        , INTERNET_IDS
        , ITEM_ID
        , ITEM_NAME
        , MODIFIED_AT
        , PARENT_CATEGORY
        , RETAILER
        , RETAILER_CATEGORY
        , SECTOR
        , STORE_ITEM_ID
        , PSA_LOAD_DTS
        , PSA_DELETE_IND
        , BKCC
        , REC_SRC
        , HASHDIFF
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.COMPETITIVE_PRODUCT_HK = JOIN_RESULT.COMPETITIVE_PRODUCT_HK
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF	
)
{% endif %}

 
{% if not is_incremental() %}
qualify 1 = row_number() over (partition by COMPETITIVE_PRODUCT_HK, HASHDIFF order by LOAD_DTS desc) 
union all
SELECT MD5_BINARY(GR.VALUE::varchar) COMPETITIVE_PRODUCT_HK
	, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) as LOAD_DTS
	, null as BRAND
	, null as CATEGORY
	, null as CREATED_AT
	, null as DEPARTMENT
	, null as INTERNET_IDS
	, null as ITEM_ID
	, null as ITEM_NAME
	, null as MODIFIED_AT
	, null as PARENT_CATEGORY
	, null as RETAILER
	, null as RETAILER_CATEGORY
	, null as SECTOR
	, null as STORE_ITEM_ID
    ,'1900-01-01'::TIMESTAMP AS PSA_LOAD_DTS
	, 'N' as PSA_DELETE_IND
        , DECODE(GR.VALUE::varchar, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS  BKCC
	, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
        , ''::BINARY as HASHDIFF
        FROM
        TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}