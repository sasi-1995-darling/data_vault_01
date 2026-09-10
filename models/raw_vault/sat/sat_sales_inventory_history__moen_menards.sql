---- SRC LAYER ----
WITH
SRC_SMM            as ( SELECT * FROM {{ ref('v_psa_stg_sales_inventory_history__moen_menards') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_SMM            as ( SELECT * FROM STAGING.v_psa_stg_sales_inventory_history__moen_menards )
*/
---- LOGIC LAYER ----

, LOGIC_SMM as (
    SELECT
        STORE_HK
      , ITEM
      , FILE_NAME
      , LOAD_DTS
      , FILE_ROW_NUMBER
      , LOCATION
      , LOCATION_NAME
      , ITEM_NAME
      , SKU
      , METRICS
      , UNIT_SALES
      , DOLLAR_SALES
      , DOLLAR_MARGIN
      , MARGIN_PERCENT
      , TOTAL_UNITS_ON_HAND
      , TOTAL_DOLLAR_COST_ON_HAND
      , TOTAL_UNITS_ON_ORDER
      , TOTAL_DOLLAR_COST_ON_ORDER
      , STORE_CURRENT_UNITS_ON_HAND
      , STORE_DOLLAR_COST_ON_HAND
      , STORE_UNITS_ON_ORDER
      , STORE_DOLLAR_COST_ON_ORDER
      , FILE_LAST_MODIFIED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM SRC_SMM
)
---- RENAME LAYER ----

, RENAME_SMM as (
    SELECT
        STORE_HK
      , ITEM
      , FILE_NAME
      , LOAD_DTS
      , FILE_ROW_NUMBER
      , LOCATION
      , LOCATION_NAME
      , ITEM_NAME
      , SKU
      , METRICS
      , UNIT_SALES
      , DOLLAR_SALES
      , DOLLAR_MARGIN
      , MARGIN_PERCENT
      , TOTAL_UNITS_ON_HAND
      , TOTAL_DOLLAR_COST_ON_HAND
      , TOTAL_UNITS_ON_ORDER
      , TOTAL_DOLLAR_COST_ON_ORDER
      , STORE_CURRENT_UNITS_ON_HAND
      , STORE_DOLLAR_COST_ON_HAND
      , STORE_UNITS_ON_ORDER
      , STORE_DOLLAR_COST_ON_ORDER
      , FILE_LAST_MODIFIED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM LOGIC_SMM
)
---- FILTER LAYER ----

, FILTER_SMM as (
    SELECT *
    FROM RENAME_SMM
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_SMM
)

---- FINAL LAYER ----
SELECT
          STORE_HK
        , ITEM
        , FILE_NAME
        , LOAD_DTS
        , FILE_ROW_NUMBER
        , LOCATION
        , LOCATION_NAME
        , ITEM_NAME
        , SKU
        , METRICS
        , UNIT_SALES
        , DOLLAR_SALES
        , DOLLAR_MARGIN
        , MARGIN_PERCENT
        , TOTAL_UNITS_ON_HAND
        , TOTAL_DOLLAR_COST_ON_HAND
        , TOTAL_UNITS_ON_ORDER
        , TOTAL_DOLLAR_COST_ON_ORDER
        , STORE_CURRENT_UNITS_ON_HAND
        , STORE_DOLLAR_COST_ON_HAND
        , STORE_UNITS_ON_ORDER
        , STORE_DOLLAR_COST_ON_ORDER
        , FILE_LAST_MODIFIED
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , REC_SRC
        , BKCC
        , HASHDIFF
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.STORE_HK = JOIN_RESULT.STORE_HK 
	AND existing.ITEM=JOIN_RESULT.ITEM
	AND existing.FILE_NAME=JOIN_RESULT.FILE_NAME
	AND existing.FILE_ROW_NUMBER=JOIN_RESULT.FILE_ROW_NUMBER
	AND existing.LOAD_DTS=JOIN_RESULT.LOAD_DTS	
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF	
)
{% endif %}



{% if not is_incremental() %}
qualify 1=row_number() over(partition by store_hk, item, file_name,file_row_number, load_dts,hashdiff order by psa_load_dts)
union all
SELECT MD5_BINARY(GR.VALUE::varchar) AS STORE_HK
	, GR.VALUE::varchar as ITEM
	, GR.VALUE::varchar as FILE_NAME
	, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) as LOAD_DTS
	, GR.VALUE::VARCHAR as FILE_ROW_NUMBER
	, null as LOCATION
	, null as LOCATION_NAME
	, null as ITEM_NAME
	, null as SKU
	, null as METRICS
	, null as UNIT_SALES
	, null as DOLLAR_SALES
	, null as DOLLAR_MARGIN
	, null as MARGIN_PERCENT
	, null as TOTAL_UNITS_ON_HAND
	, null as TOTAL_DOLLAR_COST_ON_HAND
	, null as TOTAL_UNITS_ON_ORDER
	, null as TOTAL_DOLLAR_COST_ON_ORDER
	, null as STORE_CURRENT_UNITS_ON_HAND
	, null as STORE_DOLLAR_COST_ON_HAND
	, null as STORE_UNITS_ON_ORDER
	, null as STORE_DOLLAR_COST_ON_ORDER	
	, null as FILE_LAST_MODIFIED
	, null as PSA_LOAD_DTS
	, null as PSA_RECORD_SOURCE
	, null as PSA_DELETE_IND
	, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
        , DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS  BKCC
        , ''::BINARY as HASH_DIFF
        FROM
        TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}