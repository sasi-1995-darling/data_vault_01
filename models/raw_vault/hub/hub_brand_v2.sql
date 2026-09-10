/*
PROFITERO BRAND SOURCE ARCHITECTURE:

Why CONSUMER FEEDBACK sources exist for both OLD + NEW profitero:
  - v_psa_stg_brands__*_profitero (OLD, 6 sources)
  - v_psa_stg_brands__*_profitero_share (NEW, 6 sources)
  These feed consumer feedback domain (reviews, ratings, brand sentiment)

Why COMPETITIVE SHARE sources exist ONLY for NEW profitero:
  - v_psa_stg_amz_product__winn_profitero_share (NEW, added in this migration)
  - v_psa_stg_amz_product__security_profitero_share (NEW, added in this migration)
  - NO OLD profitero competitive sources here

Explanation:
  OLD Profitero Architecture (single-brand schemas):
    - Consumer feedback domain: BRANDS table → v_psa_stg_brands__*_profitero → hub_brand_v2
    - Competitive share domain: SNS_PRODUCTS had BRAND_ID, but was DENORMALIZED
      → v_psa_stg_sns_products could feed BOTH competitive + brand analysis
      → No need for separate v_psa_stg for brands from competitive data
      → Old competitive used BRAND_ID as degenerate dimension (no hub_brand_v2 link)

  NEW Profitero Share Architecture (multi-brand shared schemas):
    - Consumer feedback domain: DIM_BRAND table → v_psa_stg_brands__*_profitero_share → hub_brand_v2
    - Competitive share domain: DIM_AMZ_PRODUCT table has DIM_BRAND_KEY, but NORMALIZED
      → Requires separate v_psa_stg_amz_product__*_profitero_share models
      → LEFT JOIN to DIM_ACCOUNT_PRODUCT enriches BRAND_HK for monitored portfolio
      → New competitive feeds hub_brand_v2 (proper DV2 architecture)

Result:
  - Consumer feedback: Both OLD + NEW feed hub_brand_v2 (12 sources total)
  - Competitive share: Only NEW feeds hub_brand_v2 (2 sources: SRC_AmPrWI, SRC_AmPrSE)
  - OLD competitive had brands as degenerate; NEW competitive has proper hub link
*/
---- SRC LAYER ----
WITH
SRC_PWI            as ( SELECT BKCC, BRAND_BK, BRAND_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_brands__winn_profitero') }} as SRC 
                        WHERE PRODUCT_BK IS NOT NULL
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY BRAND_HK ORDER BY LOAD_DTS ))=1 ),
SRC_PSE            as ( SELECT BKCC, BRAND_BK, BRAND_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_brands__security_profitero') }} as SRC 
                        WHERE PRODUCT_BK IS NOT NULL
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY BRAND_HK ORDER BY LOAD_DTS ))=1 ),
SRC_PFY            as ( SELECT BKCC, BRAND_BK, BRAND_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_brands__fypon_profitero') }} as SRC 
                        WHERE PRODUCT_BK IS NOT NULL
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY BRAND_HK ORDER BY LOAD_DTS ))=1 ),
SRC_PFI            as ( SELECT BKCC, BRAND_BK, BRAND_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_brands__fiberon_profitero') }} as SRC 
                        WHERE PRODUCT_BK IS NOT NULL
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY BRAND_HK ORDER BY LOAD_DTS ))=1 ),
SRC_PTT            as ( SELECT BKCC, BRAND_BK, BRAND_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_brands__thermatru_profitero') }} as SRC 
                        WHERE PRODUCT_BK IS NOT NULL
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY BRAND_HK ORDER BY LOAD_DTS ))=1 ),
SRC_PLR            as ( SELECT BKCC, BRAND_BK, BRAND_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_brands__larson_profitero') }} as SRC 
                        WHERE PRODUCT_BK IS NOT NULL
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY BRAND_HK ORDER BY LOAD_DTS ))=1 ),
SRC_RF             as ( SELECT BKCC, BRAND_BK, BRAND_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_brands__ref_file') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY BRAND_HK ORDER BY LOAD_DTS ))=1 ),
SRC_PSWI           as ( SELECT BKCC, BRAND_BK, BRAND_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_brands__winn_profitero_share') }} as SRC 
                        WHERE PRODUCT_BK IS NOT NULL
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY BRAND_HK ORDER BY LOAD_DTS ))=1 ),
SRC_PSSE           as ( SELECT BKCC, BRAND_BK, BRAND_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_brands__security_profitero_share') }} as SRC 
                        WHERE PRODUCT_BK IS NOT NULL
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY BRAND_HK ORDER BY LOAD_DTS ))=1 ),
SRC_PSFY           as ( SELECT BKCC, BRAND_BK, BRAND_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_brands__fypon_profitero_share') }} as SRC 
                        WHERE PRODUCT_BK IS NOT NULL
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY BRAND_HK ORDER BY LOAD_DTS ))=1 ),
SRC_PSFI           as ( SELECT BKCC, BRAND_BK, BRAND_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_brands__fiberon_profitero_share') }} as SRC 
                        WHERE PRODUCT_BK IS NOT NULL
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY BRAND_HK ORDER BY LOAD_DTS ))=1 ),
SRC_PSTT           as ( SELECT BKCC, BRAND_BK, BRAND_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_brands__thermatru_profitero_share') }} as SRC 
                        WHERE PRODUCT_BK IS NOT NULL
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY BRAND_HK ORDER BY LOAD_DTS ))=1 ),
SRC_PSLR           as ( SELECT BKCC, BRAND_BK, BRAND_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_brands__larson_profitero_share') }} as SRC 
                        WHERE PRODUCT_BK IS NOT NULL
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY BRAND_HK ORDER BY LOAD_DTS ))=1 ),
SRC_AmPrWI         as ( SELECT BKCC, BRAND_BK, BRAND_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_amz_product__winn_profitero_share') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY BRAND_HK ORDER BY LOAD_DTS ))=1 ),
SRC_AmPrSE         as ( SELECT BKCC, BRAND_BK, BRAND_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_amz_product__security_profitero_share') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY BRAND_HK ORDER BY LOAD_DTS ))=1 )

/*
SRC_PWI            as ( SELECT * FROM STAGING.v_psa_stg_brands__winn_profitero )
SRC_PSE            as ( SELECT * FROM STAGING.v_psa_stg_brands__security_profitero )
SRC_PFY            as ( SELECT * FROM STAGING.v_psa_stg_brands__fypon_profitero )
SRC_PFI            as ( SELECT * FROM STAGING.v_psa_stg_brands__fiberon_profitero )
SRC_PTT            as ( SELECT * FROM STAGING.v_psa_stg_brands__thermatru_profitero )
SRC_PLR            as ( SELECT * FROM STAGING.v_psa_stg_brands__larson_profitero )
SRC_RF             as ( SELECT * FROM STAGING.v_psa_stg_brands__ref_file )
SRC_PSWI           as ( SELECT * FROM STAGING.v_psa_stg_brands__winn_profitero_share )
SRC_PSSE           as ( SELECT * FROM STAGING.v_psa_stg_brands__security_profitero_share )
SRC_PSFY           as ( SELECT * FROM STAGING.v_psa_stg_brands__fypon_profitero_share )
SRC_PSFI           as ( SELECT * FROM STAGING.v_psa_stg_brands__fiberon_profitero_share )
SRC_PSTT           as ( SELECT * FROM STAGING.v_psa_stg_brands__thermatru_profitero_share )
SRC_PSLR           as ( SELECT * FROM STAGING.v_psa_stg_brands__larson_profitero_share )
SRC_AmPrWI         as ( SELECT * FROM STAGING.v_psa_stg_amz_product__winn_profitero_share )
SRC_AmPrSE         as ( SELECT * FROM STAGING.v_psa_stg_amz_product__security_profitero_share )
*/
---- LOGIC LAYER ----

, LOGIC_PWI as (
    SELECT
        BRAND_HK
      , BRAND_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PWI
)

, LOGIC_PSE as (
    SELECT
        BRAND_HK
      , BRAND_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PSE
)

, LOGIC_PFY as (
    SELECT
        BRAND_HK
      , BRAND_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PFY
)

, LOGIC_PFI as (
    SELECT
        BRAND_HK
      , BRAND_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PFI
)

, LOGIC_PTT as (
    SELECT
        BRAND_HK
      , BRAND_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PTT
)

, LOGIC_PLR as (
    SELECT
        BRAND_HK
      , BRAND_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PLR
)

, LOGIC_RF as (
    SELECT
        BRAND_HK
      , BRAND_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_RF
)

, LOGIC_PSWI as (
    SELECT
        BRAND_HK
      , BRAND_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PSWI
)

, LOGIC_PSSE as (
    SELECT
        BRAND_HK
      , BRAND_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PSSE
)

, LOGIC_PSFY as (
    SELECT
        BRAND_HK
      , BRAND_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PSFY
)

, LOGIC_PSFI as (
    SELECT
        BRAND_HK
      , BRAND_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PSFI
)

, LOGIC_PSTT as (
    SELECT
        BRAND_HK
      , BRAND_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PSTT
)

, LOGIC_PSLR as (
    SELECT
        BRAND_HK
      , BRAND_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PSLR
)

, LOGIC_AmPrWI as (
    SELECT
        BRAND_HK
      , BRAND_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_AmPrWI
)

, LOGIC_AmPrSE as (
    SELECT
        BRAND_HK
      , BRAND_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_AmPrSE
)
---- RENAME LAYER ----

, RENAME_PWI as (
    SELECT
        BRAND_HK
      , BRAND_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PWI
)

, RENAME_PSE as (
    SELECT
        BRAND_HK
      , BRAND_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PSE
)

, RENAME_PFY as (
    SELECT
        BRAND_HK
      , BRAND_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PFY
)

, RENAME_PFI as (
    SELECT
        BRAND_HK
      , BRAND_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PFI
)

, RENAME_PTT as (
    SELECT
        BRAND_HK
      , BRAND_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PTT
)

, RENAME_PLR as (
    SELECT
        BRAND_HK
      , BRAND_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PLR
)

, RENAME_RF as (
    SELECT
        BRAND_HK
      , BRAND_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_RF
)

, RENAME_PSWI as (
    SELECT
        BRAND_HK
      , BRAND_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PSWI
)

, RENAME_PSSE as (
    SELECT
        BRAND_HK
      , BRAND_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PSSE
)

, RENAME_PSFY as (
    SELECT
        BRAND_HK
      , BRAND_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PSFY
)

, RENAME_PSFI as (
    SELECT
        BRAND_HK
      , BRAND_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PSFI
)

, RENAME_PSTT as (
    SELECT
        BRAND_HK
      , BRAND_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PSTT
)

, RENAME_PSLR as (
    SELECT
        BRAND_HK
      , BRAND_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PSLR
)

, RENAME_AmPrWI as (
    SELECT
        BRAND_HK
      , BRAND_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_AmPrWI
)

, RENAME_AmPrSE as (
    SELECT
        BRAND_HK
      , BRAND_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_AmPrSE
)
---- FILTER LAYER ----

, FILTER_PWI as (
    SELECT *
    FROM RENAME_PWI
)

, FILTER_PSE as (
    SELECT *
    FROM RENAME_PSE
)

, FILTER_PFY as (
    SELECT *
    FROM RENAME_PFY
)

, FILTER_PFI as (
    SELECT *
    FROM RENAME_PFI
)

, FILTER_PTT as (
    SELECT *
    FROM RENAME_PTT
)

, FILTER_PLR as (
    SELECT *
    FROM RENAME_PLR
)

, FILTER_RF as (
    SELECT *
    FROM RENAME_RF
)

, FILTER_PSWI as (
    SELECT *
    FROM RENAME_PSWI
)

, FILTER_PSSE as (
    SELECT *
    FROM RENAME_PSSE
)

, FILTER_PSFY as (
    SELECT *
    FROM RENAME_PSFY
)

, FILTER_PSFI as (
    SELECT *
    FROM RENAME_PSFI
)

, FILTER_PSTT as (
    SELECT *
    FROM RENAME_PSTT
)

, FILTER_PSLR as (
    SELECT *
    FROM RENAME_PSLR
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
    SELECT * FROM FILTER_PWI
    UNION ALL
    SELECT * FROM FILTER_PSE
    UNION ALL
    SELECT * FROM FILTER_PFY
    UNION ALL
    SELECT * FROM FILTER_PFI
    UNION ALL
    SELECT * FROM FILTER_PTT
    UNION ALL
    SELECT * FROM FILTER_PLR
    UNION ALL
    SELECT * FROM FILTER_RF
    UNION ALL
    SELECT * FROM FILTER_PSWI
    UNION ALL
    SELECT * FROM FILTER_PSSE
    UNION ALL
    SELECT * FROM FILTER_PSFY
    UNION ALL
    SELECT * FROM FILTER_PSFI
    UNION ALL
    SELECT * FROM FILTER_PSTT
    UNION ALL
    SELECT * FROM FILTER_PSLR
    UNION ALL
    SELECT * FROM FILTER_AmPrWI
    UNION ALL
    SELECT * FROM FILTER_AmPrSE
)

---- FINAL LAYER ----
SELECT
          BRAND_HK
        , BRAND_BK
        , BKCC
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.BRAND_HK = JOIN_RESULT.BRAND_HK
)
{% endif %}
QUALIFY (ROW_NUMBER() OVER(PARTITION BY BRAND_HK ORDER BY LOAD_DTS))=1{% if not is_incremental() %}

union all

SELECT MD5_BINARY(GR.VALUE)  BRAND_HK
, GR.VALUE  AS BRAND_BK
, DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS BKCC
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)  AS LOAD_DTS
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}