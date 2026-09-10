---- SRC LAYER ----
WITH
SRC_SMLW           as ( SELECT * FROM {{ ref('v_psa_stg_sales_inventory_weekly__moen_menards') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_SMLW           as ( SELECT * FROM STAGING.v_psa_stg_sales_inventory_weekly__moen_menards )
*/
---- LOGIC LAYER ----

, LOGIC_SMLW as (
    SELECT
        STORE_HK
      , LOCATION
      , ITEM
      , _LINE
      , _FILE
      , LOAD_DTS
      , _MODIFIED
      , ITEM_NAME
      , SKU
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
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM SRC_SMLW
)
---- RENAME LAYER ----

, RENAME_SMLW as (
    SELECT
        STORE_HK
      , LOCATION
      , ITEM
      , _LINE
      , _FILE
      , LOAD_DTS
      , _MODIFIED
      , ITEM_NAME
      , SKU
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
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM LOGIC_SMLW
)
---- FILTER LAYER ----

, FILTER_SMLW as (
    SELECT *
    FROM RENAME_SMLW
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_SMLW
)

---- FINAL LAYER ----
SELECT
          STORE_HK
        , LOCATION
        , ITEM
        , _LINE
        , _FILE
        , LOAD_DTS
        , _MODIFIED
        , ITEM_NAME
        , SKU
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
	AND existing.LOCATION=JOIN_RESULT.LOCATION
	AND existing.ITEM=JOIN_RESULT.ITEM
	AND existing._LINE=JOIN_RESULT._LINE
	AND existing._FILE=JOIN_RESULT._FILE
	AND existing.LOAD_DTS=JOIN_RESULT.LOAD_DTS	
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF	
)
{% endif %}



{% if not is_incremental() %}
qualify 1=row_number() over(partition by store_hk, location, item, _line, _file, hashdiff order by psa_load_dts)
union all
SELECT MD5_BINARY(GR.VALUE::varchar) AS STORE_HK
	, GR.VALUE::varchar as LOCATION
	, GR.VALUE::varchar as ITEM
	, GR.VALUE::NUMBER(38,0) as _LINE
	, GR.VALUE::varchar as _FILE
	, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) as LOAD_DTS
	, null as _MODIFIED
	, null as ITEM_NAME
	, null as SKU
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
	, null as PSA_LOAD_DTS
	, null as PSA_RECORD_SOURCE
	, null as PSA_DELETE_IND
	, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
        , DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS  BKCC
        , ''::BINARY as HASH_DIFF
        FROM
        TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}