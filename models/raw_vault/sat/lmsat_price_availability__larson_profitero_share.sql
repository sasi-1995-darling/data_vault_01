---- SRC LAYER ----
WITH
SRC as (
    SELECT
        PRODUCT_RETAILER_HK
      , LOAD_DTS
      , DATE
      , CUSTOMER_PRODUCT_ID
      , RETAILER_ID
      , PRODUCT_ID
      , UPDATED_AT
      , AVAILABILITY
      , MATCH_TYPE
      , REGULAR_PRICE
      , PROMOTION_TEXT
      , PROMOTION_PRICE
      , FIRST_PARTY_WON_BUY_BOX
      , THIRD_PARTY_SELLER
      , ADD_ON_ITEM
      , PRIME_EXCLUSIVE
      , PROMO_TYPE
      , IS_DELETED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , PRODUCT_HK
      , RETAILER_HK
      , RETAILER_LOCATION_HK
      , DIM_RETAILER_LOCATION_KEY
      , BKCC
      , REC_SRC
      , HASHDIFF
    FROM {{ ref('v_psa_stg_price_availability__larson_profitero_share') }}
    {% if is_incremental() %}
    WHERE LOAD_DTS > (SELECT DATEADD('HOUR', -1, MAX(LOAD_DTS)) FROM {{ this }})
    {% endif %}
)

---- LOGIC LAYER ----
, LOGIC as (
    SELECT
        PRODUCT_RETAILER_HK
      , LOAD_DTS
      , DATE
      , CUSTOMER_PRODUCT_ID
      , RETAILER_ID
      , PRODUCT_ID
      , UPDATED_AT
      , AVAILABILITY
      , MATCH_TYPE
      , REGULAR_PRICE
      , PROMOTION_TEXT
      , PROMOTION_PRICE
      , FIRST_PARTY_WON_BUY_BOX
      , THIRD_PARTY_SELLER
      , ADD_ON_ITEM
      , PRIME_EXCLUSIVE
      , PROMO_TYPE
      , IS_DELETED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , PRODUCT_HK
      , RETAILER_HK
      , RETAILER_LOCATION_HK
      , DIM_RETAILER_LOCATION_KEY
      , BKCC
      , REC_SRC
      , HASHDIFF
    FROM SRC
)

---- FINAL LAYER ----
SELECT
      PRODUCT_RETAILER_HK
    , LOAD_DTS
    , DATE
    , CUSTOMER_PRODUCT_ID
    , RETAILER_ID
    , PRODUCT_ID
    , UPDATED_AT
    , AVAILABILITY
    , MATCH_TYPE
    , REGULAR_PRICE
    , PROMOTION_TEXT
    , PROMOTION_PRICE
    , FIRST_PARTY_WON_BUY_BOX
    , THIRD_PARTY_SELLER
    , ADD_ON_ITEM
    , PRIME_EXCLUSIVE
    , PROMO_TYPE
    , IS_DELETED
    , PSA_LOAD_DTS
    , PSA_RECORD_SOURCE
    , PSA_DELETE_IND
    , PRODUCT_HK
    , RETAILER_HK
    , RETAILER_LOCATION_HK
    , DIM_RETAILER_LOCATION_KEY
    , BKCC
    , REC_SRC
    , HASHDIFF
FROM LOGIC
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1
    FROM {{ this }} existing
    WHERE existing.PRODUCT_RETAILER_HK     = LOGIC.PRODUCT_RETAILER_HK
    AND   existing.DATE                    = LOGIC.DATE
    AND   existing.RETAILER_ID             = LOGIC.RETAILER_ID
    AND   existing.HASHDIFF                = LOGIC.HASHDIFF
)
{% endif %}
QUALIFY 1 = ROW_NUMBER() OVER (PARTITION BY PRODUCT_RETAILER_HK, DATE, RETAILER_ID, HASHDIFF ORDER BY LOAD_DTS DESC)
{% if not is_incremental() %}
UNION ALL
SELECT MD5_BINARY(GR.VALUE::varchar) AS PRODUCT_RETAILER_HK
    , CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) as LOAD_DTS
    , GR.VALUE::varchar as DATE
    , GR.VALUE::varchar as CUSTOMER_PRODUCT_ID
    , GR.VALUE::varchar as RETAILER_ID
    , GR.VALUE::varchar as PRODUCT_ID
    , null as UPDATED_AT
    , null as AVAILABILITY
    , null as MATCH_TYPE
    , null as REGULAR_PRICE
    , null as PROMOTION_TEXT
    , null as PROMOTION_PRICE
    , null as FIRST_PARTY_WON_BUY_BOX
    , null as THIRD_PARTY_SELLER
    , null as ADD_ON_ITEM
    , null as PRIME_EXCLUSIVE
    , null as PROMO_TYPE
    , null as IS_DELETED
    , null as PSA_LOAD_DTS
    , null as PSA_RECORD_SOURCE
    , null as PSA_DELETE_IND
    , MD5_BINARY(GR.VALUE::varchar) AS PRODUCT_HK
    , MD5_BINARY(GR.VALUE::varchar) AS RETAILER_HK
    , MD5_BINARY(GR.VALUE::varchar) AS RETAILER_LOCATION_HK
    , null as DIM_RETAILER_LOCATION_KEY
        , DECODE(GR.VALUE::varchar, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS  BKCC
    , 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
        , ''::BINARY as HASH_DIFF
        FROM
        TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
