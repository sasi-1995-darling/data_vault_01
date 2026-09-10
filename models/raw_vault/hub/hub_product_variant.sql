---- SRC LAYER ----
WITH
SRC_PV             as ( SELECT BKCC, LOAD_DTS, PRODUCT_VARIANT_BK, PRODUCT_VARIANT_HK, REC_SRC FROM {{ ref('v_psa_stg_dtc_product_variant__winn_shopify') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_VARIANT_HK ORDER BY LOAD_DTS ))=1 )

/*
SRC_PV             as ( SELECT * FROM STAGING.v_psa_stg_dtc_product_variant__winn_shopify )
*/
---- LOGIC LAYER ----

, LOGIC_PV as (
    SELECT
        PRODUCT_VARIANT_HK
      , PRODUCT_VARIANT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PV
)
---- RENAME LAYER ----

, RENAME_PV as (
    SELECT
        PRODUCT_VARIANT_HK
      , PRODUCT_VARIANT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PV
)
---- FILTER LAYER ----

, FILTER_PV as (
    SELECT *
    FROM RENAME_PV
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_PV
)

---- FINAL LAYER ----
SELECT
          PRODUCT_VARIANT_HK
        , PRODUCT_VARIANT_BK
        , BKCC
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.PRODUCT_VARIANT_HK = JOIN_RESULT.PRODUCT_VARIANT_HK
)
{% endif %}
{% if not is_incremental() %}

union all

SELECT MD5_BINARY(GR.VALUE)  as PRODUCT_VARIANT_HK
, GR.VALUE  AS PRODUCT_VARIANT_BK
, DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS BKCC
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)  AS LOAD_DTS
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}