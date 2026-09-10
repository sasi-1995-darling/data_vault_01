---- SRC LAYER ----
WITH
SRC_SLL            as ( SELECT * FROM {{ ref('v_psa_stg_store__homedepot_ft') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_SLL            as ( SELECT * FROM STAGING.v_psa_stg_store__homedepot_ft )
*/
---- LOGIC LAYER ----

, LOGIC_SLL as (
    SELECT
        STORE_HK
      , STORE_BK
      , D_STORE_NBR
      , HOME_DEPOT_ACCOUNT
      , LOAD_DTS
      , D_REGION
      , D_MARKET
      , D_ALL_THD
      , D_DISTRICT
      , D_MARKET_NAME
      , _FIVETRAN_DELETED
      , D_TIME_ZONE
      , D_LOB
      , D_REGION_NBR
      , D_STORE
      , D_DISTRICT_NAME
      , STATE_TERRITORY_CODE
      , D_LONGITUDE
      , D_STORE_NAME
      , D_STORE_ADDRESS
      , D_BUYING_OFFICE
      , D_COUNTRY
      , D_REGION_NAME
      , D_BYO_NAME
      , D_LATITUDE
      , D_MARKET_NBR
      , D_DIVISION_NAME
      , D_CITY
      , D_BYO_NBR
      , D_DISTRICT_NBR
      , D_POSTAL_CODE
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM SRC_SLL
)
---- RENAME LAYER ----

, RENAME_SLL as (
    SELECT
        STORE_HK
      , STORE_BK
      , D_STORE_NBR
      , HOME_DEPOT_ACCOUNT
      , LOAD_DTS
      , D_REGION
      , D_MARKET
      , D_ALL_THD
      , D_DISTRICT
      , D_MARKET_NAME
      , _FIVETRAN_DELETED
      , D_TIME_ZONE
      , D_LOB
      , D_REGION_NBR
      , D_STORE
      , D_DISTRICT_NAME
      , STATE_TERRITORY_CODE
      , D_LONGITUDE
      , D_STORE_NAME
      , D_STORE_ADDRESS
      , D_BUYING_OFFICE
      , D_COUNTRY
      , D_REGION_NAME
      , D_BYO_NAME
      , D_LATITUDE
      , D_MARKET_NBR
      , D_DIVISION_NAME
      , D_CITY
      , D_BYO_NBR
      , D_DISTRICT_NBR
      , D_POSTAL_CODE
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
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
        , STORE_BK
        , D_STORE_NBR
        , HOME_DEPOT_ACCOUNT
        , LOAD_DTS
        , D_REGION
        , D_MARKET
        , D_ALL_THD
        , D_DISTRICT
        , D_MARKET_NAME
        , _FIVETRAN_DELETED
        , D_TIME_ZONE
        , D_LOB
        , D_REGION_NBR
        , D_STORE
        , D_DISTRICT_NAME
        , STATE_TERRITORY_CODE
        , D_LONGITUDE
        , D_STORE_NAME
        , D_STORE_ADDRESS
        , D_BUYING_OFFICE
        , D_COUNTRY
        , D_REGION_NAME
        , D_BYO_NAME
        , D_LATITUDE
        , D_MARKET_NBR
        , D_DIVISION_NAME
        , D_CITY
        , D_BYO_NBR
        , D_DISTRICT_NBR
        , D_POSTAL_CODE
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
	AND existing.HOME_DEPOT_ACCOUNT=JOIN_RESULT.HOME_DEPOT_ACCOUNT	
	AND existing.LOAD_DTS=JOIN_RESULT.LOAD_DTS	
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF	
)
{% endif %}

 
{% if not is_incremental() %}
qualify 1=row_number() over(partition by store_hk,home_depot_account,hashdiff order by psa_load_dts)
union all
SELECT MD5_BINARY(GR.VALUE::varchar) as STORE_HK
, GR.VALUE::varchar as STORE_BK
, GR.VALUE::varchar as D_STORE_NBR
, GR.VALUE::varchar as HOME_DEPOT_ACCOUNT
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) as LOAD_DTS
, null as D_REGION
, null as D_MARKET
, null as D_ALL_THD
, null as D_DISTRICT
, null as D_MARKET_NAME
, null as _FIVETRAN_DELETED
, null as D_TIME_ZONE
, null as D_LOB
, null as D_REGION_NBR
, null as D_STORE
, null as D_DISTRICT_NAME
, null as STATE_TERRITORY_CODE
, null as D_LONGITUDE
, null as D_STORE_NAME
, null as D_STORE_ADDRESS
, null as D_BUYING_OFFICE
, null as D_COUNTRY
, null as D_REGION_NAME
, null as D_BYO_NAME
, null as D_LATITUDE
, null as D_MARKET_NBR
, null as D_DIVISION_NAME
, null as D_CITY
, null as D_BYO_NBR
, null as D_DISTRICT_NBR
, null as D_POSTAL_CODE
, null as PSA_LOAD_DTS
, null as PSA_RECORD_SOURCE
, null as PSA_DELETE_IND
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' as REC_SRC
, DECODE(GR.VALUE::varchar, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') as BKCC
, ''::BINARY as HASHDIFF
FROM
        TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}