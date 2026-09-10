---- SRC LAYER ----
WITH
SRC_PrSlSEC        as ( SELECT * FROM {{ ref('v_psa_stg_sns_sales__profitero_security') }} as SRC 
                        {% if is_incremental() %}
                              where src.load_dts > (select dateadd('HOUR',-1,max(load_dts)) from {{ this }} where rec_src = 'US.PROFITERO_WINN.SALES')
                            {% endif %}   )

/*
SRC_PrSlSEC        as ( SELECT * FROM STAGING.v_psa_stg_sns_sales__profitero_security )
*/
---- LOGIC LAYER ----

, LOGIC_PrSlSEC as (
    SELECT
        ASIN_SNS_CATEGORY_HK
      , SNS_CATEGORY_HK
      , ASIN_HK
      , DATE
      , LOAD_DTS
      , ASIN
      , SNS_CATEGORY_ID
      , PLATFORM
      , FIRST_PARTY_SALES
      , THIRD_PARTY_SALES
      , TOTAL_SALES
      , FIRST_PARTY_UNITS
      , THIRD_PARTY_UNITS
      , TOTAL_UNITS
      , REPORTED_IN_ARA
      , UPDATED_AT
      , IS_DELETED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , BKCC
      , REC_SRC
      , HASHDIFF
    FROM SRC_PrSlSEC
)
---- RENAME LAYER ----

, RENAME_PrSlSEC as (
    SELECT
        ASIN_SNS_CATEGORY_HK
      , SNS_CATEGORY_HK
      , ASIN_HK
      , DATE
      , LOAD_DTS
      , ASIN
      , SNS_CATEGORY_ID
      , PLATFORM
      , FIRST_PARTY_SALES
      , THIRD_PARTY_SALES
      , TOTAL_SALES
      , FIRST_PARTY_UNITS
      , THIRD_PARTY_UNITS
      , TOTAL_UNITS
      , REPORTED_IN_ARA
      , UPDATED_AT
      , IS_DELETED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , BKCC
      , REC_SRC
      , HASHDIFF
    FROM LOGIC_PrSlSEC
)
---- FILTER LAYER ----

, FILTER_PrSlSEC as (
    SELECT *
    FROM RENAME_PrSlSEC
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_PrSlSEC
)

---- FINAL LAYER ----
SELECT
          ASIN_SNS_CATEGORY_HK
        , SNS_CATEGORY_HK
        , ASIN_HK
        , DATE
        , LOAD_DTS
        , ASIN
        , SNS_CATEGORY_ID
        , PLATFORM
        , FIRST_PARTY_SALES
        , THIRD_PARTY_SALES
        , TOTAL_SALES
        , FIRST_PARTY_UNITS
        , THIRD_PARTY_UNITS
        , TOTAL_UNITS
        , REPORTED_IN_ARA
        , UPDATED_AT
        , IS_DELETED
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , BKCC
        , REC_SRC
        , HASHDIFF
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.ASIN_HK = JOIN_RESULT.ASIN_HK
    AND existing.SNS_CATEGORY_HK = JOIN_RESULT.SNS_CATEGORY_HK
    AND existing.DATE = JOIN_RESULT.DATE
    AND existing.LOAD_DTS = JOIN_RESULT.LOAD_DTS
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF	
)
{% endif %}

 
{% if not is_incremental() %}
qualify 1 = row_number() over (partition by ASIN_HK, SNS_CATEGORY_HK, DATE, HASHDIFF order by LOAD_DTS desc) 
union all
SELECT MD5_BINARY(GR.VALUE::varchar) AS ASIN_SNS_CATEGORY_HK
	,MD5_BINARY(GR.VALUE::varchar) AS ASIN_HK
	,MD5_BINARY(GR.VALUE::varchar) AS SNS_CATEGORY_HK
	, GR.VALUE::varchar as DATE
	, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) as LOAD_DTS
	, null as ASIN
	, null as SNS_CATEGORY_ID
	, null as PLATFORM
	, null as FIRST_PARTY_SALES
	, null as THIRD_PARTY_SALES
	, null as TOTAL_SALES
	, null as FIRST_PARTY_UNITS
	, null as THIRD_PARTY_UNITS
	, null as TOTAL_UNITS
	, null as REPORTED_IN_ARA
	, null as UPDATED_AT
	, null as IS_DELETED
	, null as PSA_LOAD_DTS
	, null as PSA_RECORD_SOURCE
	, null as PSA_DELETE_IND
	, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
        , DECODE(GR.VALUE::varchar, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS  BKCC
        , ''::BINARY as HASH_DIFF
        FROM
        TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}