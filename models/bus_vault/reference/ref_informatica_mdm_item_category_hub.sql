---- SRC LAYER ----
WITH
SRC_SOITMCIN       as ( SELECT BRAND, ITEM_BK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_outbound_item_product_category__fbin_informatica') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY ITEM_BK, BRAND ORDER BY LOAD_DTS DESC))=1 )

/*
SRC_SOITMCIN       as ( SELECT * FROM STAGING.v_psa_stg_outbound_item_product_category__fbin_informatica )
*/
---- LOGIC LAYER ----

, LOGIC_SOITMCIN as (
    SELECT
        ITEM_BK
      , BRAND
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SOITMCIN
)
---- RENAME LAYER ----

, RENAME_SOITMCIN as (
    SELECT
        ITEM_BK
      , BRAND
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SOITMCIN
)
---- FILTER LAYER ----

, FILTER_SOITMCIN as (
    SELECT *
    FROM RENAME_SOITMCIN
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_SOITMCIN
)

---- FINAL LAYER ----
SELECT
          ITEM_BK
        , BRAND
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.ITEM_BK = JOIN_RESULT.ITEM_BK
    AND existing.BRAND = JOIN_RESULT.BRAND
)
{% endif %}
QUALIFY 1 = ROW_NUMBER() OVER (PARTITION BY ITEM_BK, BRAND ORDER BY LOAD_DTS)
{% if not is_incremental() %}

union all

SELECT  
GR.VALUE::TEXT  AS ITEM_BK
, GR.VALUE::TEXT AS BRAND
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)::TIMESTAMP  as LOAD_DTS
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}