---- SRC LAYER ----
WITH
SRC_a as ( 
    SELECT 
	*
    FROM {{ ref('v_psa_stg_item_catalog_history__amazon') }} as SRC
    {% if is_incremental() %}
    WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}}){% endif %}
)
/*
SRC_a as ( SELECT * FROM int_staging.v_psa_stg_item_catalog_history__amazon )
*/

---- LOGIC LAYER ----

, LOGIC_a as (
    SELECT
        ITEM_HK
      , ASIN  -- Multi-Active dependent child key
      , ADULT_PRODUCT
      , AUTOGRAPHED
      , BRAND
      , DISPLAY_NAME
      , CLASSIFICATION_ID
      , COLOR
      , CONTRIBUTORS
      , ITEM_CLASSIFICATION
      , ITEM_NAME
      , MANUFACTURER
      , MEMORABILIA
      , MODEL_NUMBER
      , PACKAGE_QUANTITY
      , PART_NUMBER
      , RELEASE_DATE
      , SIZE
      , STYLE
      , TRADE_IN_ELIGIBLE
      , WEBSITE_DISPLAY_GROUP
      , WEBSITE_DISPLAY_GROUP_NAME
      , LOAD_DTS
      , HASHDIFF
      , REC_SRC
    FROM SRC_a
)

---- RENAME LAYER ----

, RENAME_a as (
    SELECT
        ITEM_HK
      , ASIN
      , ADULT_PRODUCT
      , AUTOGRAPHED
      , BRAND
      , DISPLAY_NAME
      , CLASSIFICATION_ID
      , COLOR
      , CONTRIBUTORS
      , ITEM_CLASSIFICATION
      , ITEM_NAME
      , MANUFACTURER
      , MEMORABILIA
      , MODEL_NUMBER
      , PACKAGE_QUANTITY
      , PART_NUMBER
      , RELEASE_DATE
      , SIZE
      , STYLE
      , TRADE_IN_ELIGIBLE
      , WEBSITE_DISPLAY_GROUP
      , WEBSITE_DISPLAY_GROUP_NAME
      , LOAD_DTS
      , HASHDIFF
      , REC_SRC
    FROM LOGIC_a
)

---- FILTER LAYER ----

, FILTER_a as (
    SELECT *
    FROM RENAME_a
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_a
)

---- FINAL LAYER ----
SELECT
      ITEM_HK
    , ASIN  -- Multi-Active dependent child key
    , ADULT_PRODUCT
    , AUTOGRAPHED
    , BRAND
    , DISPLAY_NAME
    , CLASSIFICATION_ID
    , COLOR
    , CONTRIBUTORS
    , ITEM_CLASSIFICATION
    , ITEM_NAME
    , MANUFACTURER
    , MEMORABILIA
    , MODEL_NUMBER
    , PACKAGE_QUANTITY
    , PART_NUMBER
    , RELEASE_DATE
    , SIZE
    , STYLE
    , TRADE_IN_ELIGIBLE
    , WEBSITE_DISPLAY_GROUP
    , WEBSITE_DISPLAY_GROUP_NAME
    , LOAD_DTS
    , HASHDIFF
    , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.ITEM_HK = JOIN_RESULT.ITEM_HK
      AND existing.ASIN = JOIN_RESULT.ASIN
      AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %}

{% if not is_incremental() %}
qualify 1 = row_number() over (partition by ITEM_HK, ASIN, HASHDIFF order by LOAD_DTS)

union all

-- Ghost records
SELECT 
    MD5_BINARY(GR.VALUE) AS ITEM_HK,
    GR.VALUE::text AS ASIN,
    NULL AS ADULT_PRODUCT,
    NULL AS AUTOGRAPHED,
    GR.VALUE::text AS BRAND,
    GR.VALUE::text AS DISPLAY_NAME,
    GR.VALUE::text AS CLASSIFICATION_ID,
    GR.VALUE::text AS COLOR,
    NULL AS CONTRIBUTORS,
    GR.VALUE::text AS ITEM_CLASSIFICATION,
    GR.VALUE::text AS ITEM_NAME,
    GR.VALUE::text AS MANUFACTURER,
    NULL AS MEMORABILIA,
    GR.VALUE::text AS MODEL_NUMBER,
    NULL AS PACKAGE_QUANTITY,
    GR.VALUE::text AS PART_NUMBER,
    NULL AS RELEASE_DATE,
    GR.VALUE::text AS SIZE,
    GR.VALUE::text AS STYLE,
    NULL AS TRADE_IN_ELIGIBLE,
    GR.VALUE::text AS WEBSITE_DISPLAY_GROUP,
    GR.VALUE::text AS WEBSITE_DISPLAY_GROUP_NAME,
    CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
    ''::BINARY AS HASHDIFF,
    'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}