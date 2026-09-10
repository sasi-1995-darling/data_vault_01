{{ config(materialized='ephemeral') }}

-- Pre-deduplicated categories (latest per sns_category_hk)
WITH sns_prdcts AS (
    SELECT         
          ASIN_HK
        , LOAD_DTS
        , ASIN
        , CUSTOMER_PRODUCT_ID
        , BRAND_ID
        , NAME
        , UPC
        , EAN
        , MODEL
        , IS_DELETED
        , BKCC
        , REC_SRC
    FROM (
        SELECT  
          ASIN_HK
        , LOAD_DTS
        , ASIN
        , CUSTOMER_PRODUCT_ID
        , BRAND_ID
        , NAME
        , UPC
        , EAN
        , MODEL
        , IS_DELETED
        , BKCC
        , REC_SRC
        FROM {{ ref('sat_sns_products__profitero_winn') }}

        UNION ALL
        
        SELECT   ASIN_HK
        , LOAD_DTS
        , ASIN
        , CUSTOMER_PRODUCT_ID
        , BRAND_ID
        , NAME
        , UPC
        , EAN
        , MODEL
        , IS_DELETED
        , BKCC
        , REC_SRC
        FROM {{ ref('sat_sns_products__profitero_security') }}
    )
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY asin_hk
        ORDER BY load_dts DESC
    ) = 1
)

TABLE sns_prdcts