/*
PROFITERO PRODUCT-BRAND LINK SOURCE ARCHITECTURE:

Why CONSUMER FEEDBACK sources exist for both OLD + NEW profitero:
  - v_psa_stg_brands__*_profitero (OLD, 6 sources)
  - v_psa_stg_brands__*_profitero_share (NEW, 6 sources)
  These feed consumer feedback domain (reviews, ratings, product-brand attribution)

Why COMPETITIVE SHARE sources exist ONLY for NEW profitero:
  - v_psa_stg_amz_product__winn_profitero_share (NEW, added in this migration)
  - v_psa_stg_amz_product__security_profitero_share (NEW, added in this migration)
  - NO OLD profitero competitive sources here

Explanation:
  OLD Profitero Architecture (single-brand schemas):
    - Consumer feedback domain: BRANDS ↔ CUSTOMER_PRODUCTS linkage
      → v_psa_stg_brands__*_profitero → lnk_product_brand
    - Competitive share domain: SNS_PRODUCTS had BRAND_ID as denormalized attribute
      → v_psa_stg_sns_products fed competitive analysis with BRAND_ID directly
      → No product-brand LINK needed (brand was degenerate dimension on sat_sns_products)
      → Old competitive did NOT feed lnk_product_brand

  NEW Profitero Share Architecture (multi-brand shared schemas):
    - Consumer feedback domain: DIM_BRAND ↔ DIM_ACCOUNT_PRODUCT linkage
      → v_psa_stg_brands__*_profitero_share → lnk_product_brand
    - Competitive share domain: DIM_AMZ_PRODUCT has DIM_BRAND_KEY (normalized)
      → Requires separate v_psa_stg_amz_product__*_profitero_share models
      → LEFT JOIN to DIM_ACCOUNT_PRODUCT enriches PRODUCT_HK + BRAND_HK + LNK_PRODUCT_BRAND_HK
      → New competitive feeds lnk_product_brand (proper DV2 architecture)

Result:
  - Consumer feedback: Both OLD + NEW feed lnk_product_brand (12 sources total)
  - Competitive share: Only NEW feeds lnk_product_brand (2 sources: SRC_AmPrWI, SRC_AmPrSE)
  - OLD competitive had brand as degenerate; NEW competitive has proper link
  - This enables competitive intelligence queries that join product-brand relationships
*/
---- SRC LAYER ----
WITH
SRC_ReWin          as ( SELECT BRAND_HK, LOAD_DTS, PRODUCT_BRAND_HK, PRODUCT_HK, REC_SRC FROM {{ ref('v_psa_stg_brands__winn_profitero') }} as SRC 
                        where product_bk is not null
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_BRAND_HK ORDER BY LOAD_DTS))=1 ),
SRC_ReSec          as ( SELECT BRAND_HK, LOAD_DTS, PRODUCT_BRAND_HK, PRODUCT_HK, REC_SRC FROM {{ ref('v_psa_stg_brands__security_profitero') }} as SRC 
                        where product_bk is not null
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_BRAND_HK ORDER BY LOAD_DTS))=1 ),
SRC_ReFyp          as ( SELECT BRAND_HK, LOAD_DTS, PRODUCT_BRAND_HK, PRODUCT_HK, REC_SRC FROM {{ ref('v_psa_stg_brands__fypon_profitero') }} as SRC 
                        where product_bk is not null
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_BRAND_HK ORDER BY LOAD_DTS))=1 ),
SRC_ReFib          as ( SELECT BRAND_HK, LOAD_DTS, PRODUCT_BRAND_HK, PRODUCT_HK, REC_SRC FROM {{ ref('v_psa_stg_brands__fiberon_profitero') }} as SRC 
                        where product_bk is not null
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_BRAND_HK ORDER BY LOAD_DTS))=1 ),
SRC_ReTT           as ( SELECT BRAND_HK, LOAD_DTS, PRODUCT_BRAND_HK, PRODUCT_HK, REC_SRC FROM {{ ref('v_psa_stg_brands__thermatru_profitero') }} as SRC 
                        where product_bk is not null
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_BRAND_HK ORDER BY LOAD_DTS))=1 ),
SRC_ReLar          as ( SELECT BRAND_HK, LOAD_DTS, PRODUCT_BRAND_HK, PRODUCT_HK, REC_SRC FROM {{ ref('v_psa_stg_brands__larson_profitero') }} as SRC 
                        where product_bk is not null
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_BRAND_HK ORDER BY LOAD_DTS))=1 ),
SRC_ReWinPS        as ( SELECT BRAND_HK, LOAD_DTS, PRODUCT_BRAND_HK, PRODUCT_HK, REC_SRC FROM {{ ref('v_psa_stg_brands__winn_profitero_share') }} as SRC 
                        where product_bk is not null
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_BRAND_HK ORDER BY LOAD_DTS))=1 ),
SRC_ReSecPS        as ( SELECT BRAND_HK, LOAD_DTS, PRODUCT_BRAND_HK, PRODUCT_HK, REC_SRC FROM {{ ref('v_psa_stg_brands__security_profitero_share') }} as SRC 
                        where product_bk is not null
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_BRAND_HK ORDER BY LOAD_DTS))=1 ),
SRC_ReFypPS        as ( SELECT BRAND_HK, LOAD_DTS, PRODUCT_BRAND_HK, PRODUCT_HK, REC_SRC FROM {{ ref('v_psa_stg_brands__fypon_profitero_share') }} as SRC 
                        where product_bk is not null
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_BRAND_HK ORDER BY LOAD_DTS))=1 ),
SRC_ReFibPS        as ( SELECT BRAND_HK, LOAD_DTS, PRODUCT_BRAND_HK, PRODUCT_HK, REC_SRC FROM {{ ref('v_psa_stg_brands__fiberon_profitero_share') }} as SRC 
                        where product_bk is not null
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_BRAND_HK ORDER BY LOAD_DTS))=1 ),
SRC_ReTTPS         as ( SELECT BRAND_HK, LOAD_DTS, PRODUCT_BRAND_HK, PRODUCT_HK, REC_SRC FROM {{ ref('v_psa_stg_brands__thermatru_profitero_share') }} as SRC 
                        where product_bk is not null
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_BRAND_HK ORDER BY LOAD_DTS))=1 ),
SRC_ReLarPS        as ( SELECT BRAND_HK, LOAD_DTS, PRODUCT_BRAND_HK, PRODUCT_HK, REC_SRC FROM {{ ref('v_psa_stg_brands__larson_profitero_share') }} as SRC 
                        where product_bk is not null
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_BRAND_HK ORDER BY LOAD_DTS))=1 ),
SRC_AmPrWI         as ( SELECT BRAND_HK, LOAD_DTS, LNK_PRODUCT_BRAND_HK, PRODUCT_HK, REC_SRC FROM {{ ref('v_psa_stg_amz_product__winn_profitero_share') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY LNK_PRODUCT_BRAND_HK ORDER BY LOAD_DTS))=1 ),
SRC_AmPrSE         as ( SELECT BRAND_HK, LOAD_DTS, LNK_PRODUCT_BRAND_HK, PRODUCT_HK, REC_SRC FROM {{ ref('v_psa_stg_amz_product__security_profitero_share') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY LNK_PRODUCT_BRAND_HK ORDER BY LOAD_DTS))=1 )

/*
SRC_ReWin          as ( SELECT * FROM STAGING.v_psa_stg_brands__winn_profitero )
SRC_ReSec          as ( SELECT * FROM STAGING.v_psa_stg_brands__security_profitero )
SRC_ReFyp          as ( SELECT * FROM STAGING.v_psa_stg_brands__fypon_profitero )
SRC_ReFib          as ( SELECT * FROM STAGING.v_psa_stg_brands__fiberon_profitero )
SRC_ReTT           as ( SELECT * FROM STAGING.v_psa_stg_brands__thermatru_profitero )
SRC_ReLar          as ( SELECT * FROM STAGING.v_psa_stg_brands__larson_profitero )
SRC_ReWinPS        as ( SELECT * FROM STAGING.v_psa_stg_brands__winn_profitero_share )
SRC_ReSecPS        as ( SELECT * FROM STAGING.v_psa_stg_brands__security_profitero_share )
SRC_ReFypPS        as ( SELECT * FROM STAGING.v_psa_stg_brands__fypon_profitero_share )
SRC_ReFibPS        as ( SELECT * FROM STAGING.v_psa_stg_brands__fiberon_profitero_share )
SRC_ReTTPS         as ( SELECT * FROM STAGING.v_psa_stg_brands__thermatru_profitero_share )
SRC_ReLarPS        as ( SELECT * FROM STAGING.v_psa_stg_brands__larson_profitero_share )
SRC_AmPrWI         as ( SELECT * FROM STAGING.v_psa_stg_amz_product__winn_profitero_share )
SRC_AmPrSE         as ( SELECT * FROM STAGING.v_psa_stg_amz_product__security_profitero_share )
*/
---- LOGIC LAYER ----

, LOGIC_ReWin as (
    SELECT
        PRODUCT_BRAND_HK
      , PRODUCT_HK
      , BRAND_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_ReWin
)

, LOGIC_ReSec as (
    SELECT
        PRODUCT_BRAND_HK
      , PRODUCT_HK
      , BRAND_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_ReSec
)

, LOGIC_ReFyp as (
    SELECT
        PRODUCT_BRAND_HK
      , PRODUCT_HK
      , BRAND_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_ReFyp
)

, LOGIC_ReFib as (
    SELECT
        PRODUCT_BRAND_HK
      , PRODUCT_HK
      , BRAND_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_ReFib
)

, LOGIC_ReTT as (
    SELECT
        PRODUCT_BRAND_HK
      , PRODUCT_HK
      , BRAND_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_ReTT
)

, LOGIC_ReLar as (
    SELECT
        PRODUCT_BRAND_HK
      , PRODUCT_HK
      , BRAND_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_ReLar
)

, LOGIC_ReWinPS as (
    SELECT
        PRODUCT_BRAND_HK
      , PRODUCT_HK
      , BRAND_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_ReWinPS
)

, LOGIC_ReSecPS as (
    SELECT
        PRODUCT_BRAND_HK
      , PRODUCT_HK
      , BRAND_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_ReSecPS
)

, LOGIC_ReFypPS as (
    SELECT
        PRODUCT_BRAND_HK
      , PRODUCT_HK
      , BRAND_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_ReFypPS
)

, LOGIC_ReFibPS as (
    SELECT
        PRODUCT_BRAND_HK
      , PRODUCT_HK
      , BRAND_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_ReFibPS
)

, LOGIC_ReTTPS as (
    SELECT
        PRODUCT_BRAND_HK
      , PRODUCT_HK
      , BRAND_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_ReTTPS
)

, LOGIC_ReLarPS as (
    SELECT
        PRODUCT_BRAND_HK
      , PRODUCT_HK
      , BRAND_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_ReLarPS
)

, LOGIC_AmPrWI as (
    SELECT
        LNK_PRODUCT_BRAND_HK                                             as                            PRODUCT_BRAND_HK
      , PRODUCT_HK
      , BRAND_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_AmPrWI
)

, LOGIC_AmPrSE as (
    SELECT
        LNK_PRODUCT_BRAND_HK                                             as                            PRODUCT_BRAND_HK
      , PRODUCT_HK
      , BRAND_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_AmPrSE
)
---- RENAME LAYER ----

, RENAME_ReWin as (
    SELECT
        PRODUCT_BRAND_HK
      , PRODUCT_HK
      , BRAND_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_ReWin
)

, RENAME_ReSec as (
    SELECT
        PRODUCT_BRAND_HK
      , PRODUCT_HK
      , BRAND_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_ReSec
)

, RENAME_ReFyp as (
    SELECT
        PRODUCT_BRAND_HK
      , PRODUCT_HK
      , BRAND_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_ReFyp
)

, RENAME_ReFib as (
    SELECT
        PRODUCT_BRAND_HK
      , PRODUCT_HK
      , BRAND_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_ReFib
)

, RENAME_ReTT as (
    SELECT
        PRODUCT_BRAND_HK
      , PRODUCT_HK
      , BRAND_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_ReTT
)

, RENAME_ReLar as (
    SELECT
        PRODUCT_BRAND_HK
      , PRODUCT_HK
      , BRAND_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_ReLar
)

, RENAME_ReWinPS as (
    SELECT
        PRODUCT_BRAND_HK
      , PRODUCT_HK
      , BRAND_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_ReWinPS
)

, RENAME_ReSecPS as (
    SELECT
        PRODUCT_BRAND_HK
      , PRODUCT_HK
      , BRAND_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_ReSecPS
)

, RENAME_ReFypPS as (
    SELECT
        PRODUCT_BRAND_HK
      , PRODUCT_HK
      , BRAND_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_ReFypPS
)

, RENAME_ReFibPS as (
    SELECT
        PRODUCT_BRAND_HK
      , PRODUCT_HK
      , BRAND_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_ReFibPS
)

, RENAME_ReTTPS as (
    SELECT
        PRODUCT_BRAND_HK
      , PRODUCT_HK
      , BRAND_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_ReTTPS
)

, RENAME_ReLarPS as (
    SELECT
        PRODUCT_BRAND_HK
      , PRODUCT_HK
      , BRAND_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_ReLarPS
)

, RENAME_AmPrWI as (
    SELECT
        PRODUCT_BRAND_HK
      , PRODUCT_HK
      , BRAND_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_AmPrWI
)

, RENAME_AmPrSE as (
    SELECT
        PRODUCT_BRAND_HK
      , PRODUCT_HK
      , BRAND_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_AmPrSE
)
---- FILTER LAYER ----

, FILTER_ReWin as (
    SELECT *
    FROM RENAME_ReWin
)

, FILTER_ReSec as (
    SELECT *
    FROM RENAME_ReSec
)

, FILTER_ReFyp as (
    SELECT *
    FROM RENAME_ReFyp
)

, FILTER_ReFib as (
    SELECT *
    FROM RENAME_ReFib
)

, FILTER_ReTT as (
    SELECT *
    FROM RENAME_ReTT
)

, FILTER_ReLar as (
    SELECT *
    FROM RENAME_ReLar
)

, FILTER_ReWinPS as (
    SELECT *
    FROM RENAME_ReWinPS
)

, FILTER_ReSecPS as (
    SELECT *
    FROM RENAME_ReSecPS
)

, FILTER_ReFypPS as (
    SELECT *
    FROM RENAME_ReFypPS
)

, FILTER_ReFibPS as (
    SELECT *
    FROM RENAME_ReFibPS
)

, FILTER_ReTTPS as (
    SELECT *
    FROM RENAME_ReTTPS
)

, FILTER_ReLarPS as (
    SELECT *
    FROM RENAME_ReLarPS
)

, FILTER_AmPrWI as (
    SELECT *
    FROM RENAME_AmPrWI
)

, FILTER_AmPrSE as (
    SELECT *
    FROM RENAME_AmPrSE
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_ReWin
    UNION ALL
    SELECT * FROM FILTER_ReSec
    UNION ALL
    SELECT * FROM FILTER_ReFyp
    UNION ALL
    SELECT * FROM FILTER_ReFib
    UNION ALL
    SELECT * FROM FILTER_ReTT
    UNION ALL
    SELECT * FROM FILTER_ReLar
    UNION ALL
    SELECT * FROM FILTER_ReWinPS
    UNION ALL
    SELECT * FROM FILTER_ReSecPS
    UNION ALL
    SELECT * FROM FILTER_ReFypPS
    UNION ALL
    SELECT * FROM FILTER_ReFibPS
    UNION ALL
    SELECT * FROM FILTER_ReTTPS
    UNION ALL
    SELECT * FROM FILTER_ReLarPS
    UNION ALL
    SELECT * FROM FILTER_AmPrWI
    UNION ALL
    SELECT * FROM FILTER_AmPrSE
)

---- FINAL LAYER ----
SELECT
          PRODUCT_BRAND_HK
        , PRODUCT_HK
        , BRAND_HK
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.PRODUCT_BRAND_HK = JOIN_RESULT.PRODUCT_BRAND_HK
)
{% endif %}

qualify 1= row_number()over(partition by PRODUCT_BRAND_HK order by LOAD_DTS) 

{% if not is_incremental() %}
union all
SELECT 
 MD5_BINARY(GR.VALUE) AS PRODUCT_BRAND_HK
, MD5_BINARY(GR.VALUE) AS PRODUCT_HK
, MD5_BINARY(GR.VALUE) AS BRAND_HK
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)  AS LOAD_DTS
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}