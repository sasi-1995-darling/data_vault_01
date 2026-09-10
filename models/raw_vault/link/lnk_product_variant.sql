---- SRC LAYER ----
WITH
SRC_LPV            as ( SELECT LNK_PRODUCT_VARIANT_HK, LOAD_DTS, PRODUCT_HK, PRODUCT_VARIANT_HK, REC_SRC FROM {{ ref('v_psa_stg_dtc_product_variant__winn_shopify') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY LNK_PRODUCT_VARIANT_HK ORDER BY LOAD_DTS))=1 )

/*
SRC_LPV            as ( SELECT * FROM STAGING.v_psa_stg_dtc_product_variant__winn_shopify )
*/
---- LOGIC LAYER ----

, LOGIC_LPV as (
    SELECT
        LNK_PRODUCT_VARIANT_HK
      , PRODUCT_HK
      , PRODUCT_VARIANT_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_LPV
)
---- RENAME LAYER ----

, RENAME_LPV as (
    SELECT
        LNK_PRODUCT_VARIANT_HK
      , PRODUCT_HK
      , PRODUCT_VARIANT_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_LPV
)
---- FILTER LAYER ----

, FILTER_LPV as (
    SELECT *
    FROM RENAME_LPV
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_LPV
)

---- FINAL LAYER ----
SELECT
          LNK_PRODUCT_VARIANT_HK
        , PRODUCT_HK
        , PRODUCT_VARIANT_HK
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.LNK_PRODUCT_VARIANT_HK = JOIN_RESULT.LNK_PRODUCT_VARIANT_HK
)
{% endif %}
--this is to consolidate records coming from 2 diff tables with the same bkcc
QUALIFY (ROW_NUMBER() OVER(PARTITION BY LNK_PRODUCT_VARIANT_HK ORDER BY LOAD_DTS DESC))=1
{% if not is_incremental() %}

union all
SELECT 
 MD5_BINARY(GR.VALUE) AS LNK_PRODUCT_VARIANT_HK
, MD5_BINARY(GR.VALUE) AS PRODUCT_HK
, MD5_BINARY(GR.VALUE) AS PRODUCT_VARIANT_HK
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)  AS LOAD_DTS
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}