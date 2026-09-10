---- SRC LAYER ----
WITH
SRC_S1             as ( SELECT * FROM {{ ref('v_psa_stg_customer_products__winn_profitero') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  ),
SRC_S2             as ( SELECT * FROM {{ ref('v_psa_stg_customer_products__security_profitero') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  ),
SRC_S3             as ( SELECT * FROM {{ ref('v_psa_stg_customer_products__fypon_profitero') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  ),
SRC_S4             as ( SELECT * FROM {{ ref('v_psa_stg_customer_products__fiberon_profitero') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  ),
SRC_S5             as ( SELECT * FROM {{ ref('v_psa_stg_customer_products__thermatru_profitero') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  ),
SRC_S6             as ( SELECT * FROM {{ ref('v_psa_stg_customer_products__larson_profitero') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_S1             as ( SELECT * FROM staging.v_psa_stg_customer_products__winn_profitero )
, SRC_S2             as ( SELECT * FROM staging.v_psa_stg_customer_products__security_profitero )
, SRC_S3             as ( SELECT * FROM staging.v_psa_stg_customer_products__fypon_profitero )
, SRC_S4             as ( SELECT * FROM staging.v_psa_stg_customer_products__fiberon_profitero )
, SRC_S5             as ( SELECT * FROM staging.v_psa_stg_customer_products__thermatru_profitero )
, SRC_S6             as ( SELECT * FROM staging.v_psa_stg_customer_products__larson_profitero )
*/
---- LOGIC LAYER ----

, LOGIC_S1 as (
    SELECT
        PRODUCT_HK
      , LOAD_DTS
      , MODEL
      , NAME
      , BRAND_ID
      , RPC
      , EAN
      , UPC
      , MAP_PRICE
      , UPDATED_AT
      , IS_DELETED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM SRC_S1
)

, LOGIC_S2 as (
    SELECT
        PRODUCT_HK
      , LOAD_DTS
      , MODEL
      , NAME
      , BRAND_ID
      , RPC
      , EAN
      , UPC
      , MAP_PRICE
      , UPDATED_AT
      , IS_DELETED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM SRC_S2
)

, LOGIC_S3 as (
    SELECT
        PRODUCT_HK
      , LOAD_DTS
      , MODEL
      , NAME
      , BRAND_ID
      , RPC
      , EAN
      , UPC
      , MAP_PRICE
      , UPDATED_AT
      , IS_DELETED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM SRC_S3
)

, LOGIC_S4 as (
    SELECT
        PRODUCT_HK
      , LOAD_DTS
      , MODEL
      , NAME
      , BRAND_ID
      , RPC
      , EAN
      , UPC
      , MAP_PRICE
      , UPDATED_AT
      , IS_DELETED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM SRC_S4
)

, LOGIC_S5 as (
    SELECT
        PRODUCT_HK
      , LOAD_DTS
      , MODEL
      , NAME
      , BRAND_ID
      , RPC
      , EAN
      , UPC
      , MAP_PRICE
      , UPDATED_AT
      , IS_DELETED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM SRC_S5
)

, LOGIC_S6 as (
    SELECT
        PRODUCT_HK
      , LOAD_DTS
      , MODEL
      , NAME
      , BRAND_ID
      , RPC
      , EAN
      , UPC
      , MAP_PRICE
      , UPDATED_AT
      , IS_DELETED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM SRC_S6
)
---- RENAME LAYER ----

, RENAME_S1 as (
    SELECT
        PRODUCT_HK
      , LOAD_DTS
      , MODEL
      , NAME
      , BRAND_ID
      , RPC
      , EAN
      , UPC
      , MAP_PRICE
      , UPDATED_AT
      , IS_DELETED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM LOGIC_S1
)

, RENAME_S2 as (
    SELECT
        PRODUCT_HK
      , LOAD_DTS
      , MODEL
      , NAME
      , BRAND_ID
      , RPC
      , EAN
      , UPC
      , MAP_PRICE
      , UPDATED_AT
      , IS_DELETED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM LOGIC_S2
)

, RENAME_S3 as (
    SELECT
        PRODUCT_HK
      , LOAD_DTS
      , MODEL
      , NAME
      , BRAND_ID
      , RPC
      , EAN
      , UPC
      , MAP_PRICE
      , UPDATED_AT
      , IS_DELETED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM LOGIC_S3
)

, RENAME_S4 as (
    SELECT
        PRODUCT_HK
      , LOAD_DTS
      , MODEL
      , NAME
      , BRAND_ID
      , RPC
      , EAN
      , UPC
      , MAP_PRICE
      , UPDATED_AT
      , IS_DELETED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM LOGIC_S4
)

, RENAME_S5 as (
    SELECT
        PRODUCT_HK
      , LOAD_DTS
      , MODEL
      , NAME
      , BRAND_ID
      , RPC
      , EAN
      , UPC
      , MAP_PRICE
      , UPDATED_AT
      , IS_DELETED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM LOGIC_S5
)

, RENAME_S6 as (
    SELECT
        PRODUCT_HK
      , LOAD_DTS
      , MODEL
      , NAME
      , BRAND_ID
      , RPC
      , EAN
      , UPC
      , MAP_PRICE
      , UPDATED_AT
      , IS_DELETED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM LOGIC_S6
)
---- FILTER LAYER ----

, FILTER_S1 as (
    SELECT *
    FROM RENAME_S1
)

, FILTER_S2 as (
    SELECT *
    FROM RENAME_S2
)

, FILTER_S3 as (
    SELECT *
    FROM RENAME_S3
)

, FILTER_S4 as (
    SELECT *
    FROM RENAME_S4
)

, FILTER_S5 as (
    SELECT *
    FROM RENAME_S5
)

, FILTER_S6 as (
    SELECT *
    FROM RENAME_S6
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_S1
    UNION ALL
    SELECT * FROM FILTER_S2
    UNION ALL
    SELECT * FROM FILTER_S3
    UNION ALL
    SELECT * FROM FILTER_S4
    UNION ALL
    SELECT * FROM FILTER_S5
    UNION ALL
    SELECT * FROM FILTER_S6
)

---- FINAL LAYER ----
SELECT
          PRODUCT_HK
        , LOAD_DTS
        , MODEL
        , NAME
        , BRAND_ID
        , RPC
        , EAN
        , UPC
        , MAP_PRICE
        , UPDATED_AT
        , IS_DELETED
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
    WHERE existing.PRODUCT_HK = JOIN_RESULT.PRODUCT_HK     AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF	
)
{% endif %}
qualify 1= row_number()over(partition by PRODUCT_HK, HASHDIFF order by PSA_LOAD_DTS DESC) 
 
{% if not is_incremental() %}

union all
SELECT 
	MD5_BINARY(GR.VALUE) AS PRODUCT_HK
	, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) as LOAD_DTS
	, null as MODEL
	, null as NAME
	, null as BRAND_ID
	, null as RPC
	, null as EAN
	, null as UPC
	, null as MAP_PRICE
	, null as UPDATED_AT
	, null as IS_DELETED
	, null as PSA_LOAD_DTS
	, null as PSA_RECORD_SOURCE
	, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
	, DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS  BKCC
	, ''::BINARY as HASH_DIFF
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}