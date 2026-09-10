---- SRC LAYER ----
WITH
SRC_PV             as ( SELECT * FROM {{ ref('v_psa_stg_dtc_product_variant__winn_shopify') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', -1, MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_PV             as ( SELECT * FROM staging.v_psa_stg_dtc_product_variant__winn_shopify )
*/
---- LOGIC LAYER ----

, LOGIC_PV as (
    SELECT
        LNK_PRODUCT_VARIANT_HK
      , LOAD_DTS
      , PRODUCT_ID
      , ID
      , INVENTORY_ITEM_ID
      , IMAGE_ID
      , TITLE
      , PRICE
      , SKU
      , POSITION
      , INVENTORY_POLICY
      , FULFILLMENT_SERVICE
      , INVENTORY_MANAGEMENT
      , CREATED_AT
      , UPDATED_AT
      , TAXABLE
      , BARCODE
      , GRAMS
      , INVENTORY_QUANTITY
      , WEIGHT
      , WEIGHT_UNIT
      , OPTION_1
      , OPTION_2
      , OPTION_3
      , TAX_CODE
      , OLD_INVENTORY_QUANTITY
      , REQUIRES_SHIPPING
      , PRESENTMENT_PRICES
      , INVENTORY_QUANTITY_ADJUSTMENT
      , _FIVETRAN_SYNCED
      , REQUIRES_COMPONENTS
      , COMPARE_AT_PRICE
      , METAFIELD
      , SELLABLE_ONLINE_QUANTITY
      , DISPLAY_NAME
      , LEGACY_RESOURCE_ID
      , AVAILABLE_FOR_SALE
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM SRC_PV
)
---- RENAME LAYER ----

, RENAME_PV as (
    SELECT
        LNK_PRODUCT_VARIANT_HK
      , LOAD_DTS
      , PRODUCT_ID
      , ID
      , INVENTORY_ITEM_ID
      , IMAGE_ID
      , TITLE
      , PRICE
      , SKU
      , POSITION
      , INVENTORY_POLICY
      , FULFILLMENT_SERVICE
      , INVENTORY_MANAGEMENT
      , CREATED_AT
      , UPDATED_AT
      , TAXABLE
      , BARCODE
      , GRAMS
      , INVENTORY_QUANTITY
      , WEIGHT
      , WEIGHT_UNIT
      , OPTION_1
      , OPTION_2
      , OPTION_3
      , TAX_CODE
      , OLD_INVENTORY_QUANTITY
      , REQUIRES_SHIPPING
      , PRESENTMENT_PRICES
      , INVENTORY_QUANTITY_ADJUSTMENT
      , _FIVETRAN_SYNCED
      , REQUIRES_COMPONENTS
      , COMPARE_AT_PRICE
      , METAFIELD
      , SELLABLE_ONLINE_QUANTITY
      , DISPLAY_NAME
      , LEGACY_RESOURCE_ID
      , AVAILABLE_FOR_SALE
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
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
          LNK_PRODUCT_VARIANT_HK
        , LOAD_DTS
        , PRODUCT_ID
        , ID
        , INVENTORY_ITEM_ID
        , IMAGE_ID
        , TITLE
        , PRICE
        , SKU
        , POSITION
        , INVENTORY_POLICY
        , FULFILLMENT_SERVICE
        , INVENTORY_MANAGEMENT
        , CREATED_AT
        , UPDATED_AT
        , TAXABLE
        , BARCODE
        , GRAMS
        , INVENTORY_QUANTITY
        , WEIGHT
        , WEIGHT_UNIT
        , OPTION_1
        , OPTION_2
        , OPTION_3
        , TAX_CODE
        , OLD_INVENTORY_QUANTITY
        , REQUIRES_SHIPPING
        , PRESENTMENT_PRICES
        , INVENTORY_QUANTITY_ADJUSTMENT
        , _FIVETRAN_SYNCED
        , REQUIRES_COMPONENTS
        , COMPARE_AT_PRICE
        , METAFIELD
        , SELLABLE_ONLINE_QUANTITY
        , DISPLAY_NAME
        , LEGACY_RESOURCE_ID
        , AVAILABLE_FOR_SALE
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , REC_SRC
        , BKCC
        , HASHDIFF
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.LNK_PRODUCT_VARIANT_HK = JOIN_RESULT.LNK_PRODUCT_VARIANT_HK
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %} 
qualify 1= row_number()over(partition by LNK_PRODUCT_VARIANT_HK, HASHDIFF order by LOAD_DTS)
{% if not is_incremental() %}
union all
SELECT
MD5_BINARY(GR.VALUE) AS LNK_PRODUCT_VARIANT_HK
,CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)  AS LOAD_DTS
,null as PRODUCT_ID
,null as ID
,null as INVENTORY_ITEM_ID
,null as IMAGE_ID
,null as TITLE
,null as PRICE
,null as SKU
,null as POSITION
,null as INVENTORY_POLICY
,null as FULFILLMENT_SERVICE
,null as INVENTORY_MANAGEMENT
,null as CREATED_AT
,null as UPDATED_AT
,null as TAXABLE
,null as BARCODE
,null as GRAMS
,null as INVENTORY_QUANTITY
,null as WEIGHT
,null as WEIGHT_UNIT
,null as OPTION_1
,null as OPTION_2
,null as OPTION_3
,null as TAX_CODE
,null as OLD_INVENTORY_QUANTITY
,null as REQUIRES_SHIPPING
,null as PRESENTMENT_PRICES
,null as INVENTORY_QUANTITY_ADJUSTMENT
,null as _FIVETRAN_SYNCED
,null as REQUIRES_COMPONENTS
,null as COMPARE_AT_PRICE
,null as METAFIELD
,null as SELLABLE_ONLINE_QUANTITY
,null as DISPLAY_NAME
,null as LEGACY_RESOURCE_ID
,null as AVAILABLE_FOR_SALE
,null as PSA_LOAD_DTS
,null as PSA_RECORD_SOURCE
,'N' as PSA_DELETE_IND
,'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
, DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS BKCC
, ''::BINARY as HASHDIFF
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR

{% endif %}