---- SRC LAYER ----
WITH
SRC_SML            as ( SELECT * FROM {{ ref('v_psa_stg_sales_inventory__larson_menards') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_SML            as ( SELECT * FROM STAGING.v_psa_stg_sales_inventory__larson_menards )
*/
---- LOGIC LAYER ----

, LOGIC_SML as (
    SELECT
        STORE_HK
      , DAY
      , LOCATION
      , ITEM
      , _LINE
      , _FILE
      , LOAD_DTS
      , _MODIFIED
      , LOCATION_DESCRIPTION
      , FAMILY
      , ITEM_DESCRIPTION
      , ITEM_DESCRIPTION_2
      , METRICS
      , UNIT_SALES
      , SALES
      , MARGIN
      , MARGIN_PERCENTAGE
      , TOTAL_UNITS_ON_HAND
      , TOTAL_COST_ON_HAND
      , TOTAL_UNITS_ON_ORDER
      , TOTAL_COST_ON_ORDER
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM SRC_SML
)
---- RENAME LAYER ----

, RENAME_SML as (
    SELECT
        STORE_HK
      , DAY
      , LOCATION
      , ITEM
      , _LINE
      , _FILE
      , LOAD_DTS
      , _MODIFIED
      , LOCATION_DESCRIPTION
      , FAMILY
      , ITEM_DESCRIPTION
      , ITEM_DESCRIPTION_2
      , METRICS
      , UNIT_SALES
      , SALES
      , MARGIN
      , MARGIN_PERCENTAGE
      , TOTAL_UNITS_ON_HAND
      , TOTAL_COST_ON_HAND
      , TOTAL_UNITS_ON_ORDER
      , TOTAL_COST_ON_ORDER
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM LOGIC_SML
)
---- FILTER LAYER ----

, FILTER_SML as (
    SELECT *
    FROM RENAME_SML
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_SML
)

---- FINAL LAYER ----
SELECT
          STORE_HK
        , DAY
        , LOCATION
        , ITEM
        , _LINE
        , _FILE
        , LOAD_DTS
        , _MODIFIED
        , LOCATION_DESCRIPTION
        , FAMILY
        , ITEM_DESCRIPTION
        , ITEM_DESCRIPTION_2
        , METRICS
        , UNIT_SALES
        , SALES
        , MARGIN
        , MARGIN_PERCENTAGE
        , TOTAL_UNITS_ON_HAND
        , TOTAL_COST_ON_HAND
        , TOTAL_UNITS_ON_ORDER
        , TOTAL_COST_ON_ORDER
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
	AND existing.DAY=JOIN_RESULT.DAY
	AND existing.LOCATION=JOIN_RESULT.LOCATION
	AND existing.ITEM=JOIN_RESULT.ITEM
	AND existing._LINE=JOIN_RESULT._LINE
	AND existing._FILE=JOIN_RESULT._FILE
	AND existing.LOAD_DTS=JOIN_RESULT.LOAD_DTS	
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF	
)
{% endif %}



{% if not is_incremental() %}
qualify 1=row_number() over(partition by store_hk,day, location, item, _line, _file, hashdiff order by psa_load_dts)
union all
SELECT MD5_BINARY(GR.VALUE::varchar) AS STORE_HK
	, GR.VALUE::varchar as DAY
	, GR.VALUE::varchar as LOCATION
	, GR.VALUE::varchar as ITEM
	, GR.VALUE::NUMBER(38,0) as _LINE
	, GR.VALUE::varchar as _FILE
	, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) as LOAD_DTS
	, null as _MODIFIED
	, null as LOCATION_DESCRIPTION
	, null as FAMILY
	, null as ITEM_DESCRIPTION
	, null as ITEM_DESCRIPTION_2
	, null as METRICS
	, null as UNIT_SALES
	, null as SALES
	, null as MARGIN
	, null as MARGIN_PERCENTAGE
	, null as TOTAL_UNITS_ON_HAND
	, null as TOTAL_COST_ON_HAND
	, null as TOTAL_UNITS_ON_ORDER
	, null as TOTAL_COST_ON_ORDER
	, null as PSA_LOAD_DTS
	, null as PSA_RECORD_SOURCE
	, null as PSA_DELETE_IND
	, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
        , DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS  BKCC
        , ''::BINARY as HASH_DIFF
        FROM
        TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}