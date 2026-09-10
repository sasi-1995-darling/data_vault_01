---- SRC LAYER ----
WITH
SRC_PrSpWINN       as ( SELECT * FROM {{ ref('v_psa_stg_sns_products__profitero_winn') }} as SRC 
                        {% if is_incremental() %}
                              where src.load_dts > (select dateadd('HOUR',-1,max(load_dts)) from {{ this }} where rec_src = 'US.PROFITERO_WINN.SNS_PRODUCTS')
                            {% endif %}   )

/*
SRC_PrSpWINN       as ( SELECT * FROM STAGING.v_psa_stg_sns_products__profitero_winn )
*/
---- LOGIC LAYER ----

, LOGIC_PrSpWINN as (
    SELECT
        ASIN_HK
      , LOAD_DTS
      , ASIN
      , CUSTOMER_PRODUCT_ID
      , BRAND_ID
      , NAME
      , UPC
      , EAN
      , MODEL
      , UPDATED_AT
      , IS_DELETED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , BKCC
      , REC_SRC
      , HASHDIFF
    FROM SRC_PrSpWINN
)
---- RENAME LAYER ----

, RENAME_PrSpWINN as (
    SELECT
        ASIN_HK
      , LOAD_DTS
      , ASIN
      , CUSTOMER_PRODUCT_ID
      , BRAND_ID
      , NAME
      , UPC
      , EAN
      , MODEL
      , UPDATED_AT
      , IS_DELETED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , BKCC
      , REC_SRC
      , HASHDIFF
    FROM LOGIC_PrSpWINN
)
---- FILTER LAYER ----

, FILTER_PrSpWINN as (
    SELECT *
    FROM RENAME_PrSpWINN
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_PrSpWINN
)

---- FINAL LAYER ----
SELECT
          ASIN_HK
        , LOAD_DTS
        , ASIN
        , CUSTOMER_PRODUCT_ID
        , BRAND_ID
        , NAME
        , UPC
        , EAN
        , MODEL
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
    AND existing.LOAD_DTS = JOIN_RESULT.LOAD_DTS
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF	
)
{% endif %}

 
{% if not is_incremental() %}
qualify 1 = row_number() over (partition by ASIN_HK, HASHDIFF order by LOAD_DTS desc) 
union all
SELECT MD5_BINARY(GR.VALUE::varchar) AS ASIN_HK
	, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) as LOAD_DTS
,GR.VALUE::varchar as ASIN
	, null as CUSTOMER_PRODUCT_ID
	, null as BRAND_ID
	, null as NAME
	, null as UPC
	, null as EAN
	, null as MODEL
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