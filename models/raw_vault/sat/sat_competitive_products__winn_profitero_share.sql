---- SRC LAYER ----
WITH
SRC as (
    SELECT
        COMPETITIVE_PRODUCT_HK
      , LOAD_DTS
      , COMPETITIVE_PRODUCT_ID
      , RANKING_PRODUCT_ID
      , RPC
      , EAN
      , UPC
      , MODEL
      , URL
      , RETAILER_ID
      , UPDATED_AT
      , IS_DELETED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , PRODUCT_ID
      , RETAILER_HK
      , PRODUCT_HK
      , BKCC
      , REC_SRC
      , HASHDIFF
    FROM {{ ref('v_psa_stg_competitive_products__winn_profitero_share') }}
    {% if is_incremental() %}
    WHERE LOAD_DTS > (SELECT DATEADD('HOUR', -1, MAX(LOAD_DTS)) FROM {{ this }})
    {% endif %}
)

---- LOGIC LAYER ----
, LOGIC as (
    SELECT
        COMPETITIVE_PRODUCT_HK
      , LOAD_DTS
      , COMPETITIVE_PRODUCT_ID
      , RANKING_PRODUCT_ID
      , RPC
      , EAN
      , UPC
      , MODEL
      , URL
      , RETAILER_ID
      , UPDATED_AT
      , IS_DELETED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , PRODUCT_ID
      , RETAILER_HK
      , PRODUCT_HK
      , BKCC
      , REC_SRC
      , HASHDIFF
    FROM SRC
)

---- FINAL LAYER ----
SELECT
      COMPETITIVE_PRODUCT_HK
    , LOAD_DTS
    , COMPETITIVE_PRODUCT_ID
    , RANKING_PRODUCT_ID
    , RPC
    , EAN
    , UPC
    , MODEL
    , URL
    , RETAILER_ID
    , UPDATED_AT
    , IS_DELETED
    , PSA_LOAD_DTS
    , PSA_RECORD_SOURCE
    , PSA_DELETE_IND
    , PRODUCT_ID
    , RETAILER_HK
    , PRODUCT_HK
    , BKCC
    , REC_SRC
    , HASHDIFF
FROM LOGIC
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1
    FROM {{ this }} existing
    WHERE existing.COMPETITIVE_PRODUCT_HK = LOGIC.COMPETITIVE_PRODUCT_HK
    AND   existing.HASHDIFF               = LOGIC.HASHDIFF
)
{% endif %}

{% if not is_incremental() %}
QUALIFY 1 = ROW_NUMBER() OVER (PARTITION BY COMPETITIVE_PRODUCT_HK, HASHDIFF ORDER BY LOAD_DTS DESC)
UNION ALL
SELECT MD5_BINARY(GR.VALUE::varchar) COMPETITIVE_PRODUCT_HK
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) as LOAD_DTS
, null as COMPETITIVE_PRODUCT_ID
, null as RANKING_PRODUCT_ID
, null as RPC
, null as EAN
, null as UPC
, null as MODEL
, null as URL
, null as RETAILER_ID
, null as UPDATED_AT
, null as IS_DELETED
, null as PSA_LOAD_DTS
, null as PSA_RECORD_SOURCE
, null as PSA_DELETE_IND
, null as PRODUCT_ID
, MD5_BINARY(GR.VALUE::varchar) RETAILER_HK
, MD5_BINARY(GR.VALUE::varchar) PRODUCT_HK
        , DECODE(GR.VALUE::varchar, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS  BKCC
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
        , ''::BINARY as HASH_DIFF
        FROM
        TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
