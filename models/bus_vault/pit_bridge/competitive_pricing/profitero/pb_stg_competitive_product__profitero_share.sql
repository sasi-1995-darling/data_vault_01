{{ config(materialized='ephemeral') }}
---- SRC LAYER ----
WITH
SRC_LCPR           as ( SELECT COMPETITIVE_PRODUCT_HK, RETAILER_HK, REC_SRC, BKCC FROM {{ ref('lnk_competitive_product_retailer') }} as SRC  ),
SRC_HCP            as ( SELECT COMPETITIVE_PRODUCT_BK, COMPETITIVE_PRODUCT_HK FROM {{ ref('hub_competitive_product') }} as SRC  ),
SRC_HR             as ( SELECT RETAILER_BK, RETAILER_HK FROM {{ ref('hub_retailer') }} as SRC  ),
-- PR Review Note: The following satellite tables in src_s should be modeled as Link Satellites.
SRC_S              as ( SELECT RANKING_PRODUCT_ID, RPC, EAN, UPC, MODEL, URL, REC_SRC, COMPETITIVE_PRODUCT_HK, RETAILER_HK, LOAD_DTS FROM
                            ( SELECT RANKING_PRODUCT_ID, RPC, EAN, UPC, MODEL, URL, REC_SRC, COMPETITIVE_PRODUCT_HK, RETAILER_HK, LOAD_DTS FROM {{ ref('sat_competitive_products__fiberon_profitero_share') }}
                              UNION ALL
                              SELECT RANKING_PRODUCT_ID, RPC, EAN, UPC, MODEL, URL, REC_SRC, COMPETITIVE_PRODUCT_HK, RETAILER_HK, LOAD_DTS FROM {{ ref('sat_competitive_products__fypon_profitero_share') }}
                              UNION ALL
                              SELECT RANKING_PRODUCT_ID, RPC, EAN, UPC, MODEL, URL, REC_SRC, COMPETITIVE_PRODUCT_HK, RETAILER_HK, LOAD_DTS FROM {{ ref('sat_competitive_products__larson_profitero_share') }}
                              UNION ALL
                              SELECT RANKING_PRODUCT_ID, RPC, EAN, UPC, MODEL, URL, REC_SRC, COMPETITIVE_PRODUCT_HK, RETAILER_HK, LOAD_DTS FROM {{ ref('sat_competitive_products__security_profitero_share') }}
                              UNION ALL
                              SELECT RANKING_PRODUCT_ID, RPC, EAN, UPC, MODEL, URL, REC_SRC, COMPETITIVE_PRODUCT_HK, RETAILER_HK, LOAD_DTS FROM {{ ref('sat_competitive_products__thermatru_profitero_share') }}
                              UNION ALL
                              SELECT RANKING_PRODUCT_ID, RPC, EAN, UPC, MODEL, URL, REC_SRC, COMPETITIVE_PRODUCT_HK, RETAILER_HK, LOAD_DTS FROM {{ ref('sat_competitive_products__winn_profitero_share') }}
                            ) as SRC
                        qualify row_number() over(partition by competitive_product_hk order by load_dts desc)=1 )

/*
SRC_LCPR           as ( SELECT * FROM raw_vault.LNK_COMPETITIVE_PRODUCT_RETAILER )
SRC_HCP            as ( SELECT * FROM raw_vault.HUB_COMPETITIVE_PRODUCT )
SRC_HR             as ( SELECT * FROM raw_vault.HUB_RETAILER )
SRC_S              as ( SELECT * FROM raw_vault.SAT_COMPETITIVE_PRODUCTS__PROFITERO_SHARE )
*/
---- LOGIC LAYER ----

, LOGIC_LCPR as (
    SELECT
        COMPETITIVE_PRODUCT_HK                                       as                        LCPR_COMPETITIVE_PRODUCT_HK
      , RETAILER_HK                                                  as                                   LCPR_RETAILER_HK
      , COMPETITIVE_PRODUCT_HK
      , RETAILER_HK
      , REC_SRC
      , REC_SRC                                                      as                                       LCPR_REC_SRC
      , BKCC
    FROM SRC_LCPR
)

, LOGIC_HCP as (
    SELECT
        COMPETITIVE_PRODUCT_HK                                       as                         HCP_COMPETITIVE_PRODUCT_HK
      , COMPETITIVE_PRODUCT_BK                                       as                         HCP_COMPETITIVE_PRODUCT_BK
      , COMPETITIVE_PRODUCT_HK
    FROM SRC_HCP
)

, LOGIC_HR as (
    SELECT
        RETAILER_HK                                                  as                                     HR_RETAILER_HK
      , RETAILER_BK                                                  as                                     HR_RETAILER_BK
      , RETAILER_HK
    FROM SRC_HR
)

, LOGIC_S as (
    SELECT
        COMPETITIVE_PRODUCT_HK                                       as                           S_COMPETITIVE_PRODUCT_HK
      , RETAILER_HK                                                  as                                      S_RETAILER_HK
      , RANKING_PRODUCT_ID
      , RPC
      , EAN
      , UPC
      , MODEL
      , URL
      , REC_SRC
      , REC_SRC                                                      as                                        SAT_REC_SRC
      , COMPETITIVE_PRODUCT_HK
      , RETAILER_HK
    FROM SRC_S
)
---- RENAME LAYER ----

, RENAME_LCPR as (
    SELECT
        LCPR_COMPETITIVE_PRODUCT_HK
      , LCPR_RETAILER_HK
      , COMPETITIVE_PRODUCT_HK
      , RETAILER_HK
      , REC_SRC
      , LCPR_REC_SRC
      , BKCC
    FROM LOGIC_LCPR
)

, RENAME_HCP as (
    SELECT
        HCP_COMPETITIVE_PRODUCT_HK
      , HCP_COMPETITIVE_PRODUCT_BK
      , COMPETITIVE_PRODUCT_HK
    FROM LOGIC_HCP
)

, RENAME_HR as (
    SELECT
        HR_RETAILER_HK
      , HR_RETAILER_BK
      , RETAILER_HK
    FROM LOGIC_HR
)

, RENAME_S as (
    SELECT
        S_COMPETITIVE_PRODUCT_HK
      , S_RETAILER_HK
      , RANKING_PRODUCT_ID
      , RPC
      , EAN
      , UPC
      , MODEL
      , URL
      , REC_SRC
      , SAT_REC_SRC
      , COMPETITIVE_PRODUCT_HK
      , RETAILER_HK
    FROM LOGIC_S
)
---- FILTER LAYER ----

, FILTER_LCPR as (
    SELECT *
    FROM RENAME_LCPR
)

, FILTER_HCP as (
    SELECT *
    FROM RENAME_HCP
)

, FILTER_HR as (
    SELECT *
    FROM RENAME_HR
)

, FILTER_S as (
    SELECT *
    FROM RENAME_S
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_LCPR
    LEFT JOIN FILTER_HCP
        ON LCPR_COMPETITIVE_PRODUCT_HK = HCP_COMPETITIVE_PRODUCT_HK
    LEFT JOIN FILTER_HR
        ON LCPR_RETAILER_HK = HR_RETAILER_HK
    LEFT JOIN FILTER_S
        ON LCPR_COMPETITIVE_PRODUCT_HK = S_COMPETITIVE_PRODUCT_HK AND LCPR_RETAILER_HK=S_RETAILER_HK
)

---- FINAL LAYER ----
SELECT
          LCPR_COMPETITIVE_PRODUCT_HK                                  as COMPETITIVE_PRODUCT_HK
        , COALESCE(HCP_COMPETITIVE_PRODUCT_BK,'N/A')                   as COMPETITIVE_PRODUCT_BK
        , LCPR_RETAILER_HK                                             as RETAILER_HK
        , COALESCE(HR_RETAILER_BK,'N/A')                               as RETAILER_BK
        , RANKING_PRODUCT_ID
        , RPC
        , EAN
        , UPC
        , MODEL
        , URL
        , 'PROFITERO_SHARE'                                            as SOURCE
        , SAT_REC_SRC
        , LCPR_REC_SRC                                                 as REC_SRC
        , BKCC
FROM JOIN_RESULT
