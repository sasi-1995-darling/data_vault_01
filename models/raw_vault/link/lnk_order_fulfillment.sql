---- SRC LAYER ----
WITH
SRC_LOF            as ( SELECT FULFILLMENT_HK, LNK_ORDER_FULFILLMENT_HK, LOAD_DTS, ORDER_HEADER_HK, REC_SRC FROM {{ ref('v_psa_stg_dtc_fulfillment__winn_shopify') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY LNK_ORDER_FULFILLMENT_HK ORDER BY LOAD_DTS))=1 )

/*
SRC_LOF            as ( SELECT * FROM STAGING.v_psa_stg_dtc_fulfillment__winn_shopify )
*/
---- LOGIC LAYER ----

, LOGIC_LOF as (
    SELECT
        LNK_ORDER_FULFILLMENT_HK
      , FULFILLMENT_HK
      , ORDER_HEADER_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_LOF
)
---- RENAME LAYER ----

, RENAME_LOF as (
    SELECT
        LNK_ORDER_FULFILLMENT_HK
      , FULFILLMENT_HK
      , ORDER_HEADER_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_LOF
)
---- FILTER LAYER ----

, FILTER_LOF as (
    SELECT *
    FROM RENAME_LOF
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_LOF
)

---- FINAL LAYER ----
SELECT
          LNK_ORDER_FULFILLMENT_HK
        , FULFILLMENT_HK
        , ORDER_HEADER_HK
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.LNK_ORDER_FULFILLMENT_HK = JOIN_RESULT.LNK_ORDER_FULFILLMENT_HK
)
{% endif %}
--this is to consolidate records coming from 2 diff tables with the same bkcc
QUALIFY (ROW_NUMBER() OVER(PARTITION BY LNK_ORDER_FULFILLMENT_HK ORDER BY LOAD_DTS DESC))=1
{% if not is_incremental() %}

union all
SELECT 
 MD5_BINARY(GR.VALUE) AS LNK_ORDER_FULFILLMENT_HK
, MD5_BINARY(GR.VALUE) AS FULFILLMENT_HK
, MD5_BINARY(GR.VALUE) AS ORDER_HEADER_HK
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)  AS LOAD_DTS
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}