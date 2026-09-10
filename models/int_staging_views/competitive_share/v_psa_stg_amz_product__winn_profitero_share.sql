/*
ARCHITECTURE NOTE: Why 2 Tables in NEW Profitero Share?

OLD Profitero (single-brand schemas):
  - SNS_PRODUCTS table was DENORMALIZED: ASIN + CUSTOMER_PRODUCT_ID + BRAND_ID in one row
  - v_psa_stg_sns_products fed both competitive analysis AND consumer feedback (brands domain)

NEW Profitero Share (multi-brand shared schemas):
  - NORMALIZED into 2 tables:
    1. DIM_AMZ_PRODUCT = Competitive universe (~4.4M ASINs discovered on Amazon)
       - Basic tracking: ASIN, NAME, UPC, EAN, MODEL, DIM_BRAND_KEY
    2. DIM_ACCOUNT_PRODUCT = Monitored product portfolio (~30K products across all brands)
       - Detailed tracking: FBIN brands + key competitors in Profitero monitoring account
       - Includes internal product IDs (ACCOUNT_PRODUCT_ID) for linking to other Profitero data
       - PROVIDED_RPC = the ASIN that this account product is sold under on Amazon
  
JOIN Logic:
  - LEFT JOIN DIM_AMZ_PRODUCT to DIM_ACCOUNT_PRODUCT on AMZ_PRODUCT_ID = PROVIDED_RPC
  - Match rate: 0.27% (8,517 monitored products out of 4.4M competitive universe)
  - Enriches competitive ASINs with PRODUCT_HK, BRAND_HK, and LNK_PRODUCT_BRAND_HK for monitored portfolio

This enables:
  - hub_brand_v2: Tracks all brands in monitored portfolio (FBIN + competitors)
  - lnk_product_brand: Links products to brands for competitive intelligence
  - hub_product_v2: Tracks monitored products for detailed analysis
*/
---- SRC LAYER ----
WITH
SRC_S              as ( SELECT * FROM {{ source('profitero_share_moen', 'dim_amz_product') }} as SRC 
                        -- DEDUP: this is intentional exact-row dedup, NOT business-key dedup — partition on the ENTIRE row (all descriptive attrs) to collapse exact-duplicate reloads from the source. Earliest PSA load wins on true attribute change; identical payloads reduce to one row. 
                        qualify 1 = row_number() over (partition by dim_amz_product_key, amz_product_id, dim_brand_key, name, ean, upc,model, created_at, updated_at  order by psa_delete_ind, psa_load_dts) ),
SRC_P              as ( SELECT * FROM {{ source('profitero_share_moen', 'dim_account_product') }} as SRC 
                        -- DEDUP: this is intentional exact-row dedup, NOT business-key dedup — partition on the ENTIRE row (all descriptive attrs) to collapse exact-duplicate reloads from the source. Earliest PSA load wins on true attribute change; identical payloads reduce to one row. 
                        qualify 1 = row_number() over (partition by dim_account_product_key, account_product_id, account_product_name, dim_brand_key, provided_rpc, ean, upc, product_model, map_price, product_url, dim_retailer_key, url_key, variation_key, created_at, updated_at, scraped_rpc, product_duplicate_group_id  order by psa_delete_ind, psa_load_dts)),
SRC_a              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S              as ( SELECT * FROM PSA_PROD.PROFITERO_SHARE_MOEN.DIM_AMZ_PRODUCT )
, SRC_P              as ( SELECT * FROM PSA_PROD.PROFITERO_SHARE_MOEN.DIM_ACCOUNT_PRODUCT )
, SRC_a              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        coalesce(nullif(trim(AMZ_PRODUCT_ID::varchar), ''), '-1')    as                                       ASIN_BK
      , AMZ_PRODUCT_ID::varchar                                      as                                          ASIN
      , DIM_AMZ_PRODUCT_KEY::varchar                                 as                             CUSTOMER_PRODUCT_ID
      , DIM_BRAND_KEY::varchar                                       as                                      BRAND_ID
      , CONVERT_TIMEZONE('UTC', IFF(PSA_DELETE_IND = 'Y', PSA_LOAD_DTS, coalesce(UPDATED_AT, PSA_LOAD_DTS))) as                                           LOAD_DTS
      , AMZ_PRODUCT_ID
      , DIM_BRAND_KEY
      , DIM_AMZ_PRODUCT_KEY
      , NAME
      , UPC
      , EAN
      , MODEL
      , UPDATED_AT
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
    FROM SRC_S
)

, LOGIC_P as (
    SELECT
        ACCOUNT_PRODUCT_ID::varchar                                  as                                    PRODUCT_BK_RAW
      , PROVIDED_RPC::varchar                                        as                                PROVIDED_RPC
      , PSA_DELETE_IND                                             as                                PRODUCT_PSA_DELETE_IND
    FROM SRC_P
    -- Lookup table qualify clause below is intentional to further dedup at PROVIDED_RPC & PROVIDED_RPC level
    qualify 1 = row_number() over(partition by account_product_id, provided_rpc order by updated_at desc, psa_load_dts desc)
)

, LOGIC_a as (
    SELECT
        BKCC
      , REC_SRC
    FROM SRC_a
)
---- RENAME LAYER ----

, RENAME_S as (
    SELECT
        ASIN_BK
      , ASIN
      , CUSTOMER_PRODUCT_ID
      , BRAND_ID
      , LOAD_DTS
      , AMZ_PRODUCT_ID
      , DIM_BRAND_KEY
      , DIM_AMZ_PRODUCT_KEY
      , NAME
      , UPC
      , EAN
      , MODEL
      , UPDATED_AT
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
    FROM LOGIC_S
)

, RENAME_P as (
    SELECT
        PRODUCT_BK_RAW
      , PROVIDED_RPC
      , PRODUCT_PSA_DELETE_IND
    FROM LOGIC_P
)

, RENAME_a as (
    SELECT
        BKCC
      , REC_SRC
    FROM LOGIC_a
)
---- FILTER LAYER ----

, FILTER_S as (
    SELECT *
    FROM RENAME_S
)

, FILTER_P as (
    SELECT *
    FROM RENAME_P
    WHERE PRODUCT_PSA_DELETE_IND ='N'
)

, FILTER_a as (
    SELECT *
    FROM RENAME_a
    WHERE rec_src = 'US.PROFITERO_SHARE_MOEN.DIM_AMZ_PRODUCT'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT 
        s.*
      , p.PRODUCT_BK_RAW
      , a.BKCC
      , a.REC_SRC
    FROM FILTER_S s
    LEFT JOIN FILTER_P p
        ON s.ASIN = p.PROVIDED_RPC
    INNER JOIN FILTER_a a
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          MD5_BINARY(UPPER(CONCAT_WS('||',
              COALESCE(NULLIF(TRIM(CAST(ASIN AS VARCHAR)),''),'^^')
            , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
          )))                                                         as                                   ASIN_HK
        , ASIN_BK
        , ASIN
        , COALESCE(NULLIF(TRIM(CAST(PRODUCT_BK_RAW AS VARCHAR)), ''), '-1') as                                PRODUCT_BK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
               COALESCE(NULLIF(TRIM(CAST(PRODUCT_BK_RAW AS VARCHAR)),''),'^^')
            , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
             )))                                                      as                                PRODUCT_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
               COALESCE(NULLIF(TRIM(CAST(PRODUCT_BK_RAW AS VARCHAR)),''),'^^'),
               COALESCE(NULLIF(TRIM(CAST(ASIN AS VARCHAR)),''),'^^')
            , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
             )))                                                      as                         LNK_PRODUCT_ASIN_HK
        , CUSTOMER_PRODUCT_ID
        , COALESCE(NULLIF(TRIM(CAST(BRAND_ID AS VARCHAR)), ''), '-1') as                                         BRAND_BK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(BRAND_ID AS VARCHAR)),''),'^^')
            , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
          )))                                                         as                                          BRAND_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
               COALESCE(NULLIF(TRIM(CAST(PRODUCT_BK_RAW AS VARCHAR)),''),'^^'),
               COALESCE(NULLIF(TRIM(CAST(BRAND_ID AS VARCHAR)),''),'^^')
            , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
             )))                                                      as                          LNK_PRODUCT_BRAND_HK
        , BRAND_ID
        , LOAD_DTS
        , AMZ_PRODUCT_ID
        , DIM_BRAND_KEY
        , DIM_AMZ_PRODUCT_KEY
        , NAME
        , UPC
        , EAN
        , MODEL
        , UPDATED_AT
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , BKCC
        , REC_SRC
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(NAME::text),'^^'),'||',
              IFNULL(TRIM(AMZ_PRODUCT_ID::text),'^^'),'||',
              IFNULL(TRIM(DIM_BRAND_KEY::text),'^^'),'||',
              IFNULL(TRIM(DIM_AMZ_PRODUCT_KEY::text),'^^'),'||',
              IFNULL(TRIM(BRAND_ID::text),'^^'),'||',
              IFNULL(TRIM(UPC::text),'^^'),'||',
              IFNULL(TRIM(EAN::text),'^^'),'||',
              IFNULL(TRIM(MODEL::text),'^^'),'||',
              IFNULL(TRIM(PSA_DELETE_IND::text),'^^'),'||',
              IFNULL(TRIM(UPDATED_AT::text),'^^')
          ), '^^||^^||^^||^^||^^')))                                  as                               HASHDIFF
FROM JOIN_RESULT
