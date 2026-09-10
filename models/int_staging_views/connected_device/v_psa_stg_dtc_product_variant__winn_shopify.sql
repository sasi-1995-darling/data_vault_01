---- SRC LAYER ----
WITH
SRC_D1             as ( SELECT AVAILABLE_FOR_SALE, BARCODE, COMPARE_AT_PRICE, CREATED_AT, DISPLAY_NAME, FULFILLMENT_SERVICE, GRAMS, ID, IMAGE_ID, INVENTORY_ITEM_ID, INVENTORY_MANAGEMENT, INVENTORY_POLICY, INVENTORY_QUANTITY, INVENTORY_QUANTITY_ADJUSTMENT, LEGACY_RESOURCE_ID, METAFIELD, OLD_INVENTORY_QUANTITY, OPTION_1, OPTION_2, OPTION_3, POSITION, PRESENTMENT_PRICES, PRICE, PRODUCT_ID, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, REQUIRES_COMPONENTS, REQUIRES_SHIPPING, SELLABLE_ONLINE_QUANTITY, SKU, TAXABLE, TAX_CODE, TITLE, UPDATED_AT, WEIGHT, WEIGHT_UNIT, _FIVETRAN_SYNCED
                        /* Syndicate delete filter: suppress truncate-reload artifact deletes (Y+N in same batch) */
                        , CASE WHEN PSA_DELETE_IND = 'Y'
                             AND COUNT_IF(PSA_DELETE_IND = 'N') OVER (PARTITION BY ID, _FIVETRAN_SYNCED) > 0
                               THEN TRUE ELSE FALSE END AS TRUNCATE_RELOAD_FLAG
                        FROM {{ source('shopify_moen', 'product_variant') }} as SRC
                        QUALIFY NOT TRUNCATE_RELOAD_FLAG
                      ),
SRC_A1             as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_D1             as ( SELECT * FROM SHOPIFY_MOEN.PRODUCT_VARIANT )
SRC_A1             as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_D1 as (
    SELECT
        TO_CHAR(ID)                                                  as                                 PRODUCT_VARIANT_BK
      , TO_CHAR(PRODUCT_ID)                                          as                                         PRODUCT_BK
      , CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED)                        as                                           LOAD_DTS
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
    FROM SRC_D1
)

, LOGIC_A1 as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_A1
)
---- RENAME LAYER ----

, RENAME_D1 as (
    SELECT
        PRODUCT_VARIANT_BK
      , PRODUCT_BK
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
    FROM LOGIC_D1
)

, RENAME_A1 as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_A1
)
---- FILTER LAYER ----

, FILTER_D1 as (
    SELECT *
    FROM RENAME_D1
)

, FILTER_A1 as (
    SELECT *
    FROM RENAME_A1
    WHERE rec_src = 'US.SHOPIFY_MOEN.PRODUCT_VARIANT'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_D1
    INNER JOIN FILTER_A1
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          PRODUCT_VARIANT_BK
        , PRODUCT_BK
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
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PRODUCT_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PRODUCT_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PRODUCT_VARIANT_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(PRODUCT_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as LNK_PRODUCT_VARIANT_HK
        -- Track delete-indicator flip sequence so true delete would not prevent the resurrection from going to sats/lsats.
        , CONDITIONAL_CHANGE_EVENT(PSA_DELETE_IND) OVER(PARTITION BY ID ORDER BY _FIVETRAN_SYNCED, PSA_LOAD_DTS) AS CCE
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(INVENTORY_ITEM_ID::text), '^^') 
            , '||', IFNULL(TRIM(IMAGE_ID::text), '^^') 
            , '||', IFNULL(TRIM(TITLE::text), '^^') 
            , '||', IFNULL(TRIM(PRICE::text), '^^') 
            , '||', IFNULL(TRIM(SKU::text), '^^') 
            , '||', IFNULL(TRIM(POSITION::text), '^^') 
            , '||', IFNULL(TRIM(INVENTORY_POLICY::text), '^^') 
            , '||', IFNULL(TRIM(FULFILLMENT_SERVICE::text), '^^') 
            , '||', IFNULL(TRIM(INVENTORY_MANAGEMENT::text), '^^') 
            , '||', IFNULL(TRIM(CREATED_AT::text), '^^') 
            , '||', IFNULL(TRIM(UPDATED_AT::text), '^^') 
            , '||', IFNULL(TRIM(TAXABLE::text), '^^') 
            , '||', IFNULL(TRIM(BARCODE::text), '^^') 
            , '||', IFNULL(TRIM(GRAMS::text), '^^') 
            , '||', IFNULL(TRIM(INVENTORY_QUANTITY::text), '^^') 
            , '||', IFNULL(TRIM(WEIGHT::text), '^^') 
            , '||', IFNULL(TRIM(WEIGHT_UNIT::text), '^^') 
            , '||', IFNULL(TRIM(OPTION_1::text), '^^') 
            , '||', IFNULL(TRIM(OPTION_2::text), '^^') 
            , '||', IFNULL(TRIM(OPTION_3::text), '^^') 
            , '||', IFNULL(TRIM(TAX_CODE::text), '^^') 
            , '||', IFNULL(TRIM(OLD_INVENTORY_QUANTITY::text), '^^') 
            , '||', IFNULL(TRIM(REQUIRES_SHIPPING::text), '^^') 
            , '||', IFNULL(TRIM(PRESENTMENT_PRICES::text), '^^') 
            , '||', IFNULL(TRIM(INVENTORY_QUANTITY_ADJUSTMENT::text), '^^') 
            , '||', IFNULL(TRIM(REQUIRES_COMPONENTS::text), '^^') 
            , '||', IFNULL(TRIM(COMPARE_AT_PRICE::text), '^^') 
            , '||', IFNULL(TRIM(METAFIELD::text), '^^') 
            , '||', IFNULL(TRIM(SELLABLE_ONLINE_QUANTITY::text), '^^') 
            , '||', IFNULL(TRIM(DISPLAY_NAME::text), '^^') 
            , '||', IFNULL(TRIM(LEGACY_RESOURCE_ID::text), '^^') 
            , '||', IFNULL(TRIM(AVAILABLE_FOR_SALE::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
            , '||', IFNULL(TRIM(CCE::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
