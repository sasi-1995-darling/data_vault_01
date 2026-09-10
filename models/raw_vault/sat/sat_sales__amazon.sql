---- SRC LAYER ----
WITH
SRC_SSA            as ( SELECT * FROM {{ ref('v_psa_stg_sales__amazon') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_SSA            as ( SELECT * FROM STAGING.v_psa_stg_sales__amazon )
*/
---- LOGIC LAYER ----

, LOGIC_SSA as (
    SELECT
        STORE_HK
      , LOAD_DTS
      , REPORT_END_DATE
      , VENDORCENTRAL_ACCOUNT
      , ASIN
      , CUSTOMER_RETURNS
      , REPORT_START_DATE
      , ORDERDED_REVENUE_AMT
      , ORDERDED_REV_CURRCODE
      , ORDERDED_UNITS
      , SHIPPED_COGS_AMT
      , SHIPPED_COGS_CURRCODE
      , SHIPPED_REVENUE_AMT
      , SHIPPED_REV_CURRCODE
      , SHIPPED_UNITS
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM SRC_SSA
)
---- RENAME LAYER ----

, RENAME_SSA as (
    SELECT
        STORE_HK
      , LOAD_DTS
      , REPORT_END_DATE
      , VENDORCENTRAL_ACCOUNT
      , ASIN
      , CUSTOMER_RETURNS
      , REPORT_START_DATE
      , ORDERDED_REVENUE_AMT
      , ORDERDED_REV_CURRCODE
      , ORDERDED_UNITS
      , SHIPPED_COGS_AMT
      , SHIPPED_COGS_CURRCODE
      , SHIPPED_REVENUE_AMT
      , SHIPPED_REV_CURRCODE
      , SHIPPED_UNITS
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM LOGIC_SSA
)
---- FILTER LAYER ----

, FILTER_SSA as (
    SELECT *
    FROM RENAME_SSA
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_SSA
)

---- FINAL LAYER ----
SELECT
          STORE_HK
        , LOAD_DTS
        , REPORT_END_DATE
        , VENDORCENTRAL_ACCOUNT
        , ASIN
        , CUSTOMER_RETURNS
        , REPORT_START_DATE
        , ORDERDED_REVENUE_AMT
        , ORDERDED_REV_CURRCODE
        , ORDERDED_UNITS
        , SHIPPED_COGS_AMT
        , SHIPPED_COGS_CURRCODE
        , SHIPPED_REVENUE_AMT
        , SHIPPED_REV_CURRCODE
        , SHIPPED_UNITS
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
	AND existing.REPORT_END_DATE=JOIN_RESULT.REPORT_END_DATE
	AND existing.VENDORCENTRAL_ACCOUNT=JOIN_RESULT.VENDORCENTRAL_ACCOUNT
	AND existing.ASIN=JOIN_RESULT.ASIN
	AND existing.CUSTOMER_RETURNS=JOIN_RESULT.CUSTOMER_RETURNS
	AND existing.LOAD_DTS=JOIN_RESULT.LOAD_DTS	
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF	
)
{% endif %}

qualify 1 = row_number() over (partition by STORE_HK,REPORT_END_DATE,VENDORCENTRAL_ACCOUNT,ASIN,CUSTOMER_RETURNS,HASHDIFF order by PSA_LOAD_DTS desc)  
{% if not is_incremental() %}

union all
SELECT MD5_BINARY(GR.VALUE::varchar) AS STORE_HK
	, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) as LOAD_DTS
	, GR.VALUE::varchar as REPORT_END_DATE
	, GR.VALUE::varchar as VENDORCENTRAL_ACCOUNT
	, GR.VALUE::varchar as ASIN
	, GR.VALUE::varchar as CUSTOMER_RETURNS
	, null as REPORT_START_DATE
	, null as ORDERDED_REVENUE_AMT
	, null as ORDERDED_REV_CURRCODE
	, null as ORDERDED_UNITS
	, null as SHIPPED_COGS_AMT
	, null as SHIPPED_COGS_CURRCODE
	, null as SHIPPED_REVENUE_AMT
	, null as SHIPPED_REV_CURRCODE
	, null as SHIPPED_UNITS
	, null as PSA_LOAD_DTS
	, null as PSA_RECORD_SOURCE
	, null as PSA_DELETE_IND
	, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
        , DECODE(GR.VALUE::varchar, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS  BKCC
        , ''::BINARY as HASH_DIFF
        FROM
        TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}