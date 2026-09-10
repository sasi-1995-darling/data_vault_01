---- SRC LAYER ----
WITH
SRC_PROD           as ( SELECT * FROM {{ ref('v_psa_stg_amz_product__winn_profitero_share') }} as SRC 
                        {% if is_incremental() %}
                              where src.load_dts > (select dateadd('HOUR',-1,max(load_dts)) from {{ this }})
                            {% endif %}  
                            -- Temporary workaround: This QUALIFY clause is required because this model is currently implemented as a Satellite instead of a Link Satellite. A follow-up technical debt story should be created to address the modeling issue.
                            QUALIFY ROW_NUMBER() OVER (PARTITION BY ASIN_HK, HASHDIFF ORDER BY PSA_LOAD_DTS) = 1
                             )

/*
SRC_PROD           as ( SELECT * FROM STAGING.v_psa_stg_amz_product__winn_profitero_share )
*/
---- LOGIC LAYER ----

, LOGIC_PROD as (
    SELECT
        ASIN_HK
      , LOAD_DTS
      , ASIN
      , AMZ_PRODUCT_ID
      , DIM_BRAND_KEY
      , DIM_AMZ_PRODUCT_KEY
      , CUSTOMER_PRODUCT_ID
      , BRAND_ID
      , NAME
      , UPC
      , EAN
      , MODEL
      , UPDATED_AT
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , BKCC
      , REC_SRC
      , HASHDIFF
    FROM SRC_PROD
)
---- RENAME LAYER ----

, RENAME_PROD as (
    SELECT
        ASIN_HK
      , LOAD_DTS
      , ASIN
      , AMZ_PRODUCT_ID
      , DIM_BRAND_KEY
      , DIM_AMZ_PRODUCT_KEY
      , CUSTOMER_PRODUCT_ID
      , BRAND_ID
      , NAME
      , UPC
      , EAN
      , MODEL
      , UPDATED_AT
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , BKCC
      , REC_SRC
      , HASHDIFF
    FROM LOGIC_PROD
)
---- FILTER LAYER ----

, FILTER_PROD as (
    SELECT *
    FROM RENAME_PROD
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_PROD
)

---- FINAL LAYER ----
SELECT
          ASIN_HK
        , LOAD_DTS
        , ASIN
        , AMZ_PRODUCT_ID
        , DIM_BRAND_KEY
        , DIM_AMZ_PRODUCT_KEY
        , CUSTOMER_PRODUCT_ID
        , BRAND_ID
        , NAME
        , UPC
        , EAN
        , MODEL
        , UPDATED_AT
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
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% else %}

union all
SELECT 
MD5_BINARY(GR.VALUE) AS ASIN_HK,
'1900-01-01T00:00:00'::TIMESTAMP_NTZ AS LOAD_DTS,
GR.VALUE AS ASIN,
NULL AS AMZ_PRODUCT_ID,
NULL AS DIM_BRAND_KEY,
NULL AS DIM_AMZ_PRODUCT_KEY,
NULL AS CUSTOMER_PRODUCT_ID,
NULL AS BRAND_ID,
NULL AS NAME,
NULL AS UPC,
NULL AS EAN,
NULL AS MODEL,
NULL AS UPDATED_AT,
'1900-01-01'::TIMESTAMP AS PSA_LOAD_DTS,
NULL AS PSA_RECORD_SOURCE,
'N' AS PSA_DELETE_IND,
DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC,
MD5_BINARY('') AS HASHDIFF
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}

