---- SRC LAYER ----
WITH
SRC_SSM            as ( SELECT * FROM {{ ref('v_psa_stg_store_location_lookup__menards') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_SSM            as ( SELECT * FROM STAGING.v_psa_stg_store_location_lookup__menards )
*/
---- LOGIC LAYER ----

, LOGIC_SSM as (
    SELECT
        STORE_HK
      , LOAD_DTS
      , STORE_
      , PROTOTYPE
      , REC_DATE
      , OPEN_DATE
      , ADDRESS_1
      , ADDRESS_2
      , CITY
      , STATE
      , POSTAL_CD
      , TELEPHONE
      , FAX
      , MARKET
      , CLOSEOUT_START_DATE
      , APPLIANCES
      , SOFT_OPEN
      , LONGITUDE
      , LATITUDE
      , LIVE_GOODS
      , PET_GROCERY
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM SRC_SSM
)
---- RENAME LAYER ----

, RENAME_SSM as (
    SELECT
        STORE_HK
      , LOAD_DTS
      , STORE_
      , 	PROTOTYPE
      , 	REC_DATE
      , 	OPEN_DATE
      , 	ADDRESS_1
      , 	ADDRESS_2
      , 	CITY
      , 	STATE
      , 	POSTAL_CD
      , 	TELEPHONE
      , 	FAX
      , 	MARKET
      , 	CLOSEOUT_START_DATE
      , 	APPLIANCES
      , 	SOFT_OPEN
      , 	LONGITUDE
      , 	LATITUDE
      , 	LIVE_GOODS
      , 	PET_GROCERY
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM LOGIC_SSM
)
---- FILTER LAYER ----

, FILTER_SSM as (
    SELECT *
    FROM RENAME_SSM
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_SSM
)

---- FINAL LAYER ----
SELECT
          STORE_HK
        , LOAD_DTS
        , STORE_
        , 	PROTOTYPE
        , 	REC_DATE
        , 	OPEN_DATE
        , 	ADDRESS_1
        , 	ADDRESS_2
        , 	CITY
        , 	STATE
        , 	POSTAL_CD
        , 	TELEPHONE
        , 	FAX
        , 	MARKET
        , 	CLOSEOUT_START_DATE
        , 	APPLIANCES
        , 	SOFT_OPEN
        , 	LONGITUDE
        , 	LATITUDE
        , 	LIVE_GOODS
        , 	PET_GROCERY
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
	AND existing.LOAD_DTS=JOIN_RESULT.LOAD_DTS	
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF	
)
{% endif %}



{% if not is_incremental() %}
qualify 1=row_number() over(partition by store_hk, load_dts,hashdiff order by psa_load_dts)
union all
SELECT MD5_BINARY(GR.VALUE::varchar) AS STORE_HK
	, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) as LOAD_DTS
	, null as STORE_
	, null as PROTOTYPE
	, null as REC_DATE
	, null as OPEN_DATE
	, null as ADDRESS_1
	, null as ADDRESS_2
	, GR.VALUE as CITY
	, GR.VALUE as STATE
	, GR.VALUE as POSTAL_CD
	, null as TELEPHONE
	, null as FAX
	, null as MARKET
	, null as CLOSEOUT_START_DATE
	, null as APPLIANCES
	, null as SOFT_OPEN
	, null as LONGITUDE
	, null as LATITUDE
	, null as LIVE_GOODS
	, null as PET_GROCERY
	, null as PSA_LOAD_DTS
	, null as PSA_RECORD_SOURCE
	, null as PSA_DELETE_IND
	, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
        , DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS  BKCC
        , ''::BINARY as HASH_DIFF
        FROM
        TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}