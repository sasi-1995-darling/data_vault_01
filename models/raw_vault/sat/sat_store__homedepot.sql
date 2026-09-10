---- SRC LAYER ----
WITH
SRC_SLL            as ( SELECT * FROM {{ ref('v_psa_stg_store__homedepot') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_SLL            as ( SELECT * FROM STAGING.v_psa_stg_store__homedepot )
*/
---- LOGIC LAYER ----

, LOGIC_SLL as (
    SELECT
        STORE_HK
      , D_STORE_NBR
      , LOAD_DTS
      , STATE_TERRITORY_CODE
      , D_ALL_THD
      , D_BUYING_OFFICE
      , D_CITY
      , D_COUNTRY
      , D_DISTRICT
      , D_DIVISION
      , D_LOB
      , D_LATITUDE
      , D_LONGITUDE
      , D_MARKET
      , D_POSTAL_CODE
      , D_REGION
      , D_STORE
      , D_STORE_ADDRESS
      , D_STORE_NAME
      , D_TIME_ZONE
      , HOME_DEPOT_ACCOUNT
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
      , D_STORE_NBR
      , LOAD_DTS
      , STATE_TERRITORY_CODE
      , D_ALL_THD
      , D_BUYING_OFFICE
      , D_CITY
      , D_COUNTRY
      , D_DISTRICT
      , D_DIVISION
      , D_LOB
      , D_LATITUDE
      , D_LONGITUDE
      , D_MARKET
      , D_POSTAL_CODE
      , D_REGION
      , D_STORE
      , D_STORE_ADDRESS
      , D_STORE_NAME
      , D_TIME_ZONE
      , HOME_DEPOT_ACCOUNT
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
        , D_STORE_NBR
        , LOAD_DTS
        , STATE_TERRITORY_CODE
        , D_ALL_THD
        , D_BUYING_OFFICE
        , D_CITY
        , D_COUNTRY
        , D_DISTRICT
        , D_DIVISION
        , D_LOB
        , D_LATITUDE
        , D_LONGITUDE
        , D_MARKET
        , D_POSTAL_CODE
        , D_REGION
        , D_STORE
        , D_STORE_ADDRESS
        , D_STORE_NAME
        , D_TIME_ZONE
        , HOME_DEPOT_ACCOUNT
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
	AND existing.LOAD_DTS=JOIN_RESULT.LOAD_DTS	
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF	
)
{% endif %}

 
{% if not is_incremental() %}
union all
SELECT MD5_BINARY(GR.VALUE) AS STORE_HK
	, GR.VALUE as D_STORE_NBR	
	, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) as LOAD_DTS
	, null as STATE_TERRITORY_CODE
	, null as D_ALL_THD
	, null as D_BUYING_OFFICE
	, null as D_CITY
	, null as D_COUNTRY
	, null as D_DISTRICT
	, null as D_DIVISION
	, null as D_LOB
	, null as D_LATITUDE
	, null as D_LONGITUDE
	, null as D_MARKET
	, null as D_POSTAL_CODE
	, null as D_REGION
	, null as D_STORE
	, null as D_STORE_ADDRESS
	, null as D_STORE_NAME
	, null as D_TIME_ZONE
	, null as HOME_DEPOT_ACCOUNT
	, null as PSA_LOAD_DTS
	, null as PSA_RECORD_SOURCE
	, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
        , DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS  BKCC
        , ''::BINARY as HASH_DIFF
        FROM
        TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}