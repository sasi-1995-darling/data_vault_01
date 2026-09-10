---- SRC LAYER ----
WITH
SRC_s              as ( SELECT FULFILLABLE_QUANTITY, FULFILLMENT_STATUS, GIFT_CARD, GRAMS, ID, INDEX, NAME, ORDER_ID, PRE_TAX_PRICE, PRE_TAX_PRICE_SET, PRICE, 
                        PRICE_SET, PRODUCT_EXISTS, PRODUCT_ID, PROPERTIES, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, QUANTITY, REQUIRES_SHIPPING, SKU, 
                        TAXABLE, TAX_CODE, TITLE, TOTAL_DISCOUNT, TOTAL_DISCOUNT_SET, VARIANT_ID, VARIANT_INVENTORY_MANAGEMENT, VARIANT_TITLE, VENDOR, _FIVETRAN_SYNCED
                        /* Syndicate delete filter: suppress truncate-reload artifact deletes (Y+N in same batch) */
                        , CASE WHEN PSA_DELETE_IND = 'Y'
                               AND COUNT_IF(PSA_DELETE_IND = 'N') OVER (PARTITION BY ORDER_ID, ID, PSA_LOAD_DTS) > 0
                               THEN TRUE ELSE FALSE END AS TRUNCATE_RELOAD_FLAG
                        FROM {{ source('shopify_moen', 'order_line') }} as SRC 
                        ),
SRC_a              as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  ),
SRC_o              as ( SELECT ID, NAME FROM {{ source('shopify_moen', 'ORDER') }} as SRC 
                        /* The following qualify clause is required to pull the latest row synced by fivetran based on these PK columns, 
                        only the most recent record present in the source is needed*/
                        qualify 1 = row_number() over(partition by id order by _fivetran_synced desc)  )

/*
SRC_s              as ( SELECT * FROM shopify_moen.order_line )
SRC_a              as ( SELECT * FROM raw_vault.ref_business_key_collision )
SRC_o              as ( SELECT * FROM shopify_moen.ORDER )
*/
---- LOGIC LAYER ----

, LOGIC_s as (
    SELECT
        ORDER_ID
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
    FROM SRC_s
)

, LOGIC_a as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_a
)

, LOGIC_o as (
    SELECT
        NAME                                                         as                                             O_NAME
      , ID                                                           as                                               O_ID
    FROM SRC_o
)
---- RENAME LAYER ----

, RENAME_s as (
    SELECT
        ORDER_ID
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
    FROM LOGIC_s
)

, RENAME_a as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_a
)

, RENAME_o as (
    SELECT
        O_NAME
      , O_ID
    FROM LOGIC_o
)
---- FILTER LAYER ----

, FILTER_s as (
    SELECT *
    FROM RENAME_s
)

, FILTER_a as (
    SELECT *
    FROM RENAME_a
    WHERE rec_src = 'US.API.SHOPIFY_MOEN.ORDER_LINE'
)

, FILTER_o as (
    SELECT *
    FROM RENAME_o
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_s
    INNER JOIN FILTER_a
        ON '1' = '1'
    LEFT JOIN FILTER_o
        ON FILTER_s.ORDER_ID = O_ID
)

---- FINAL LAYER ----
SELECT
          ORDER_ID
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
        , CONVERT_TIMEZONE('UTC', IFF(
            PSA_DELETE_IND = 'Y',
            PSA_LOAD_DTS,
            _FIVETRAN_SYNCED
        ))                     as LOAD_DTS
        , REC_SRC
        , BKCC
        , CONCAT_WS('||', COALESCE(O_NAME, '-1'), COALESCE(INDEX, '-1')) as ORDER_LINE_BK
        , COALESCE(O_NAME, '-1')                                       as ORDER_HEADER_BK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ORDER_LINE_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ORDER_LINE_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ORDER_HEADER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ORDER_HEADER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ORDER_HEADER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(ORDER_LINE_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ORDER_ORDER_LINE_HK
        -- Track delete-indicator flip sequence so true delete would not prevent the resurrection from going to sats/lsats.
        , CONDITIONAL_CHANGE_EVENT(PSA_DELETE_IND) OVER(PARTITION BY ORDER_ID, ID ORDER BY _FIVETRAN_SYNCED, PSA_LOAD_DTS) AS CCE
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(ORDER_ID::text), '^^') 
            , '||', IFNULL(TRIM(ID::text), '^^') 
            , '||', IFNULL(TRIM(PRODUCT_ID::text), '^^') 
            , '||', IFNULL(TRIM(VARIANT_ID::text), '^^') 
            , '||', IFNULL(TRIM(NAME::text), '^^') 
            , '||', IFNULL(TRIM(TITLE::text), '^^') 
            , '||', IFNULL(TRIM(VENDOR::text), '^^') 
            , '||', IFNULL(TRIM(PRICE::text), '^^') 
            , '||', IFNULL(TRIM(PRICE_SET::text), '^^') 
            , '||', IFNULL(TRIM(QUANTITY::text), '^^') 
            , '||', IFNULL(TRIM(GRAMS::text), '^^') 
            , '||', IFNULL(TRIM(SKU::text), '^^') 
            , '||', IFNULL(TRIM(FULFILLABLE_QUANTITY::text), '^^') 
            , '||', IFNULL(TRIM(GIFT_CARD::text), '^^') 
            , '||', IFNULL(TRIM(REQUIRES_SHIPPING::text), '^^') 
            , '||', IFNULL(TRIM(TAXABLE::text), '^^') 
            , '||', IFNULL(TRIM(VARIANT_TITLE::text), '^^') 
            , '||', IFNULL(TRIM(PROPERTIES::text), '^^') 
            , '||', IFNULL(TRIM(INDEX::text), '^^') 
            , '||', IFNULL(TRIM(TOTAL_DISCOUNT::text), '^^') 
            , '||', IFNULL(TRIM(TOTAL_DISCOUNT_SET::text), '^^') 
            , '||', IFNULL(TRIM(PRE_TAX_PRICE::text), '^^') 
            , '||', IFNULL(TRIM(PRE_TAX_PRICE_SET::text), '^^') 
            , '||', IFNULL(TRIM(PRODUCT_EXISTS::text), '^^') 
            , '||', IFNULL(TRIM(FULFILLMENT_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(VARIANT_INVENTORY_MANAGEMENT::text), '^^') 
            , '||', IFNULL(TRIM(TAX_CODE::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
            , '||', IFNULL(TRIM(CCE::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
