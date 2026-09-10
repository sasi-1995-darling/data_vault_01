---- SRC LAYER ----
WITH
SRC_SHOPORDLN      as ( SELECT * FROM {{ ref('v_psa_stg_dtc_order_line__winn_shopify') }} as SRC 
                        {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %} )

/*
SRC_SHOPORDLN      as ( SELECT * FROM STAGING.v_psa_stg_dtc_order_line__winn_shopify )
*/
---- LOGIC LAYER ----

, LOGIC_SHOPORDLN as (
    SELECT
        ORDER_ORDER_LINE_HK
      , ORDER_ID
      , ID
      , PRODUCT_ID
      , VARIANT_ID
      , NAME
      , TITLE
      , VENDOR
      , PRICE
      , PRICE_SET
      , QUANTITY
      , GRAMS
      , SKU
      , FULFILLABLE_QUANTITY
      , GIFT_CARD
      , REQUIRES_SHIPPING
      , TAXABLE
      , VARIANT_TITLE
      , PROPERTIES
      , INDEX
      , TOTAL_DISCOUNT
      , TOTAL_DISCOUNT_SET
      , PRE_TAX_PRICE
      , PRE_TAX_PRICE_SET
      , PRODUCT_EXISTS
      , FULFILLMENT_STATUS
      , VARIANT_INVENTORY_MANAGEMENT
      , TAX_CODE
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , HASHDIFF
    FROM SRC_SHOPORDLN
)
---- RENAME LAYER ----

, RENAME_SHOPORDLN as (
    SELECT
        ORDER_ORDER_LINE_HK
      , ORDER_ID
      , ID
      , PRODUCT_ID
      , VARIANT_ID
      , NAME
      , TITLE
      , VENDOR
      , PRICE
      , PRICE_SET
      , QUANTITY
      , GRAMS
      , SKU
      , FULFILLABLE_QUANTITY
      , GIFT_CARD
      , REQUIRES_SHIPPING
      , TAXABLE
      , VARIANT_TITLE
      , PROPERTIES
      , INDEX
      , TOTAL_DISCOUNT
      , TOTAL_DISCOUNT_SET
      , PRE_TAX_PRICE
      , PRE_TAX_PRICE_SET
      , PRODUCT_EXISTS
      , FULFILLMENT_STATUS
      , VARIANT_INVENTORY_MANAGEMENT
      , TAX_CODE
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , HASHDIFF
    FROM LOGIC_SHOPORDLN
)
---- FILTER LAYER ----

, FILTER_SHOPORDLN as (
    SELECT *
    FROM RENAME_SHOPORDLN
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_SHOPORDLN
)

---- FINAL LAYER ----
SELECT
          ORDER_ORDER_LINE_HK
        , ORDER_ID
        , ID
        , PRODUCT_ID
        , VARIANT_ID
        , NAME
        , TITLE
        , VENDOR
        , PRICE
        , PRICE_SET
        , QUANTITY
        , GRAMS
        , SKU
        , FULFILLABLE_QUANTITY
        , GIFT_CARD
        , REQUIRES_SHIPPING
        , TAXABLE
        , VARIANT_TITLE
        , PROPERTIES
        , INDEX
        , TOTAL_DISCOUNT
        , TOTAL_DISCOUNT_SET
        , PRE_TAX_PRICE
        , PRE_TAX_PRICE_SET
        , PRODUCT_EXISTS
        , FULFILLMENT_STATUS
        , VARIANT_INVENTORY_MANAGEMENT
        , TAX_CODE
        , _FIVETRAN_SYNCED
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , REC_SRC
        , HASHDIFF
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.ORDER_ORDER_LINE_HK = JOIN_RESULT.ORDER_ORDER_LINE_HK
	AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF	
)
{% endif %}
{% if not is_incremental() %}

/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per HK and hashdiff. */
qualify 1 = row_number() over (partition by ORDER_ORDER_LINE_HK, HASHDIFF order by PSA_LOAD_DTS)

union all
SELECT 
MD5_BINARY(GR.VALUE) AS ORDER_ORDER_LINE_HK,
GR.VALUE::number AS ORDER_ID,
GR.VALUE::number AS ID,
NULL AS PRODUCT_ID,
NULL AS VARIANT_ID,
NULL AS NAME,
NULL AS TITLE,
NULL AS VENDOR,
NULL AS PRICE,
NULL AS PRICE_SET,
NULL AS QUANTITY,
NULL AS GRAMS,
NULL AS SKU,
NULL AS FULFILLABLE_QUANTITY,
NULL AS GIFT_CARD,
NULL AS REQUIRES_SHIPPING,
NULL AS TAXABLE,
NULL AS VARIANT_TITLE,
NULL AS PROPERTIES,
GR.VALUE::number AS INDEX,
NULL AS TOTAL_DISCOUNT,
NULL AS TOTAL_DISCOUNT_SET,
NULL AS PRE_TAX_PRICE,
NULL AS PRE_TAX_PRICE_SET,
NULL AS PRODUCT_EXISTS,
NULL AS FULFILLMENT_STATUS,
NULL AS VARIANT_INVENTORY_MANAGEMENT,
NULL AS TAX_CODE,
NULL AS _FIVETRAN_SYNCED,
'1900-01-01'::TIMESTAMP AS PSA_LOAD_DTS,
NULL AS PSA_RECORD_SOURCE,
'N' AS PSA_DELETE_IND,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC,
''::BINARY AS HASHDIFF
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
