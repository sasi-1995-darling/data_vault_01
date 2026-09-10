---- SRC LAYER ----
WITH
SRC_SLL            as ( SELECT * FROM {{ ref('v_psa_stg_store__lowes') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_SLL            as ( SELECT * FROM STAGING.v_psa_stg_store__lowes )
*/
---- LOGIC LAYER ----

, LOGIC_SLL as (
    SELECT
        STORE_HK
      , LOCATION_ID
      , LOAD_DTS
      , LOCATION_DESC
      , DELIVERY_ADDRESS
      , DELIVERY_CITY
      , DELIVERY_STATE
      , DELIVERY_CODE
      , SALESFLOOR_FOOTAGE
      , DISTRICT_DISTRICT
      , REGION_ID
      , REGION_DESC
      , DIVISION_DIVISION
      , ADVERTISING_AREA
      , GEO_ID
      , GEO_DESC
      , FORECAST_ZONE
      , SUPPORTING_CENTER
      , SUPPORTING_FDC
      , SUPPORTING_TRANSLOAD
      , FILE_NAME
      , OPEN_DATE
      , _FILE
      , PM_SNAPSHOT_DATE
      , _MODIFIED
      , REAL_DATE
      , _LINE
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM SRC_SLL
)
---- RENAME LAYER ----

, RENAME_SLL as (
    SELECT
        STORE_HK
      , LOCATION_ID
      , LOAD_DTS
      , LOCATION_DESC
      , DELIVERY_ADDRESS
      , DELIVERY_CITY
      , DELIVERY_STATE
      , DELIVERY_CODE
      , SALESFLOOR_FOOTAGE
      , DISTRICT_DISTRICT
      , REGION_ID
      , REGION_DESC
      , DIVISION_DIVISION
      , ADVERTISING_AREA
      , GEO_ID
      , GEO_DESC
      , FORECAST_ZONE
      , SUPPORTING_CENTER
      , SUPPORTING_FDC
      , SUPPORTING_TRANSLOAD
      , FILE_NAME
      , OPEN_DATE
      , _FILE
      , PM_SNAPSHOT_DATE
      , _MODIFIED
      , REAL_DATE
      , _LINE
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM LOGIC_SLL
)
---- FILTER LAYER ----

, FILTER_SLL as (
    SELECT *
    FROM RENAME_SLL
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_SLL
)

---- FINAL LAYER ----
SELECT
          STORE_HK
        , LOCATION_ID
        , LOAD_DTS
        , LOCATION_DESC
        , DELIVERY_ADDRESS
        , DELIVERY_CITY
        , DELIVERY_STATE
        , DELIVERY_CODE
        , SALESFLOOR_FOOTAGE
        , DISTRICT_DISTRICT
        , REGION_ID
        , REGION_DESC
        , DIVISION_DIVISION
        , ADVERTISING_AREA
        , GEO_ID
        , GEO_DESC
        , FORECAST_ZONE
        , SUPPORTING_CENTER
        , SUPPORTING_FDC
        , SUPPORTING_TRANSLOAD
        , FILE_NAME
        , OPEN_DATE
        , _FILE
        , PM_SNAPSHOT_DATE
        , _MODIFIED
        , REAL_DATE
        , _LINE
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , REC_SRC
        , BKCC
        , HASHDIFF
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.STORE_HK = JOIN_RESULT.STORE_HK 
	AND existing.LOCATION_ID = JOIN_RESULT.LOCATION_ID
	AND existing.LOAD_DTS=JOIN_RESULT.LOAD_DTS	
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF	
)
{% endif %}
 
{% if not is_incremental() %}
union all
SELECT MD5_BINARY(GR.VALUE) AS STORE_HK
	, GR.VALUE as LOCATION_ID	
	, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) as LOAD_DTS
	, null as LOCATION_DESC
	, null as DELIVERY_ADDRESS
	, null as DELIVERY_CITY
	, null as DELIVERY_STATE
	, null as DELIVERY_CODE
	, null as SALESFLOOR_FOOTAGE
	, null as DISTRICT_DISTRICT
	, null as REGION_ID
	, null as REGION_DESC
	, null as DIVISION_DIVISION
	, null as ADVERTISING_AREA
	, null as GEO_ID
	, null as GEO_DESC
	, null as FORECAST_ZONE
	, null as SUPPORTING_CENTER
	, null as SUPPORTING_FDC
	, null as SUPPORTING_TRANSLOAD
	, null as FILE_NAME
	, null as OPEN_DATE
	, null as _FILE
	, null as PM_SNAPSHOT_DATE
	, null as _MODIFIED
	, null as REAL_DATE
	, null as _LINE, null as PSA_LOAD_DTS
	, null as PSA_RECORD_SOURCE
	, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
        , DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS  BKCC
        , ''::BINARY as HASH_DIFF
        FROM
        TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}