---- SRC LAYER ----
WITH
SRC_item           as ( 
    SELECT 
        ASIN
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
      , _FIVETRAN_SYNCED
    FROM {{ source('amazon_sp_ft_moen_inc', 'item_summary') }} as SRC
),
SRC_xref           as ( 
    SELECT 
        ASIN
      , MODEL_STYLE_NUMBER
    FROM {{ source('amazon_xref', 'amazon_moen_catalog_hist') }} as SRC
),
SRC_bkcc           as ( 
    SELECT BKCC, REC_SRC 
    FROM {{ ref('ref_business_key_collision') }} as SRC
)

/*
SRC_item           as ( SELECT * FROM edp_bronze_prod.amazon_sp_ft_moen_inc.item_summary )
SRC_xref           as ( SELECT * FROM edp_bronze_prod.amazon_xref.amazon_moen_catalog_hist )
SRC_bkcc           as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/

---- LOGIC LAYER ----

, LOGIC_item as (
    SELECT
        ASIN
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
      , _FIVETRAN_SYNCED
    FROM SRC_item
)

, LOGIC_xref as (
    SELECT
        ASIN
      , MODEL_STYLE_NUMBER
      , COALESCE(NULLIF(UPPER(TRIM(MODEL_STYLE_NUMBER)), ''), '-1') as ITEM_BK
    FROM SRC_xref
    -- Deduplicate: one model_style_number per ASIN
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ASIN ORDER BY MODEL_STYLE_NUMBER) = 1
)

, LOGIC_bkcc as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_bkcc
)

---- RENAME LAYER ----

, RENAME_item as (
    SELECT
        ASIN
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
      , _FIVETRAN_SYNCED
    FROM LOGIC_item
)

, RENAME_xref as (
    SELECT
        ASIN
      , MODEL_STYLE_NUMBER
      , ITEM_BK
    FROM LOGIC_xref
)

, RENAME_bkcc as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_bkcc
)

---- FILTER LAYER ----

, FILTER_item as (
    SELECT *
    FROM RENAME_item
)

, FILTER_xref as (
    SELECT *
    FROM RENAME_xref
)

, FILTER_bkcc as (
    SELECT *
    FROM RENAME_bkcc
    WHERE REC_SRC = 'USOHNO.SAP.ECCPRD.Z_MARA'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT 
        FILTER_item.ASIN
      , FILTER_item.ADULT_PRODUCT
      , FILTER_item.AUTOGRAPHED
      , FILTER_item.BRAND
      , FILTER_item.DISPLAY_NAME
      , FILTER_item.CLASSIFICATION_ID
      , FILTER_item.COLOR
      , FILTER_item.CONTRIBUTORS
      , FILTER_item.ITEM_CLASSIFICATION
      , FILTER_item.ITEM_NAME
      , FILTER_item.MANUFACTURER
      , FILTER_item.MEMORABILIA
      , FILTER_item.MODEL_NUMBER
      , FILTER_item.PACKAGE_QUANTITY
      , FILTER_item.PART_NUMBER
      , FILTER_item.RELEASE_DATE
      , FILTER_item.SIZE
      , FILTER_item.STYLE
      , FILTER_item.TRADE_IN_ELIGIBLE
      , FILTER_item.WEBSITE_DISPLAY_GROUP
      , FILTER_item.WEBSITE_DISPLAY_GROUP_NAME
      , FILTER_item._FIVETRAN_SYNCED
      , FILTER_xref.MODEL_STYLE_NUMBER
      , FILTER_xref.ITEM_BK
      , FILTER_bkcc.REC_SRC
      , FILTER_bkcc.BKCC
    FROM FILTER_item
    INNER JOIN FILTER_xref
        ON FILTER_item.ASIN = FILTER_xref.ASIN
    INNER JOIN FILTER_bkcc
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
      ASIN
    , MODEL_STYLE_NUMBER
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
    , _FIVETRAN_SYNCED
    , ITEM_BK
    , CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED) as LOAD_DTS
    , REC_SRC
    , BKCC
    , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(ITEM_BK), ''), '^^'),
          COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
      ))) as ITEM_HK
    , MD5_BINARY(UPPER(NULLIF(CONCAT(
          IFNULL(TRIM(ASIN::text), '^^')
        , '||', IFNULL(TRIM(ADULT_PRODUCT::text), '^^')
        , '||', IFNULL(TRIM(AUTOGRAPHED::text), '^^')
        , '||', IFNULL(TRIM(BRAND::text), '^^')
        , '||', IFNULL(TRIM(DISPLAY_NAME::text), '^^')
        , '||', IFNULL(TRIM(CLASSIFICATION_ID::text), '^^')
        , '||', IFNULL(TRIM(COLOR::text), '^^')
        , '||', IFNULL(TRIM(CONTRIBUTORS::text), '^^')
        , '||', IFNULL(TRIM(ITEM_CLASSIFICATION::text), '^^')
        , '||', IFNULL(TRIM(ITEM_NAME::text), '^^')
        , '||', IFNULL(TRIM(MANUFACTURER::text), '^^')
        , '||', IFNULL(TRIM(MEMORABILIA::text), '^^')
        , '||', IFNULL(TRIM(MODEL_NUMBER::text), '^^')
        , '||', IFNULL(TRIM(PACKAGE_QUANTITY::text), '^^')
        , '||', IFNULL(TRIM(PART_NUMBER::text), '^^')
        , '||', IFNULL(TRIM(RELEASE_DATE::text), '^^')
        , '||', IFNULL(TRIM(SIZE::text), '^^')
        , '||', IFNULL(TRIM(STYLE::text), '^^')
        , '||', IFNULL(TRIM(TRADE_IN_ELIGIBLE::text), '^^')
        , '||', IFNULL(TRIM(WEBSITE_DISPLAY_GROUP::text), '^^')
        , '||', IFNULL(TRIM(WEBSITE_DISPLAY_GROUP_NAME::text), '^^')
        , '||', IFNULL(TRIM(_FIVETRAN_SYNCED::text), '^^')
      ), '^^||^^'))) as HASHDIFF

FROM JOIN_RESULT