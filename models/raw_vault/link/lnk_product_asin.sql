---- SRC LAYER ----
WITH
SRC_PrSpWINN       as ( SELECT * FROM {{ ref('v_psa_stg_sns_products__profitero_winn') }} as SRC 
                        WHERE CUSTOMER_PRODUCT_ID IS NOT NULL
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY LNK_PRODUCT_ASIN_HK ORDER BY LOAD_DTS DESC))=1 ),
SRC_PrSpSEC        as ( SELECT * FROM {{ ref('v_psa_stg_sns_products__profitero_security') }} as SRC 
                        WHERE CUSTOMER_PRODUCT_ID IS NOT NULL
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY LNK_PRODUCT_ASIN_HK ORDER BY LOAD_DTS DESC))=1 ),
SRC_AmPrWI         as ( SELECT * FROM {{ ref('v_psa_stg_amz_product__winn_profitero_share') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY LNK_PRODUCT_ASIN_HK ORDER BY LOAD_DTS DESC))=1 ),
SRC_AmPrSE         as ( SELECT * FROM {{ ref('v_psa_stg_amz_product__security_profitero_share') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY LNK_PRODUCT_ASIN_HK ORDER BY LOAD_DTS DESC))=1 )

/*
SRC_PrSpWINN       as ( SELECT * FROM STAGING.v_psa_stg_sns_products__profitero_winn )
, SRC_PrSpSEC        as ( SELECT * FROM STAGING.v_psa_stg_sns_products__profitero_security )
, SRC_AmPrWI         as ( SELECT * FROM STAGING.v_psa_stg_amz_product__winn_profitero_share )
, SRC_AmPrSE         as ( SELECT * FROM STAGING.v_psa_stg_amz_product__security_profitero_share )
*/
---- LOGIC LAYER ----

, LOGIC_PrSpWINN as (
    SELECT
        LNK_PRODUCT_ASIN_HK
      , PRODUCT_HK
      , ASIN_HK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PrSpWINN
)

, LOGIC_PrSpSEC as (
    SELECT
        LNK_PRODUCT_ASIN_HK
      , PRODUCT_HK
      , ASIN_HK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PrSpSEC
)

, LOGIC_AmPrWI as (
    SELECT
        LNK_PRODUCT_ASIN_HK
      , PRODUCT_HK
      , ASIN_HK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_AmPrWI
)

, LOGIC_AmPrSE as (
    SELECT
        LNK_PRODUCT_ASIN_HK
      , PRODUCT_HK
      , ASIN_HK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_AmPrSE
)
---- RENAME LAYER ----

, RENAME_PrSpWINN as (
    SELECT
        LNK_PRODUCT_ASIN_HK
      , PRODUCT_HK
      , ASIN_HK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PrSpWINN
)

, RENAME_PrSpSEC as (
    SELECT
        LNK_PRODUCT_ASIN_HK
      , PRODUCT_HK
      , ASIN_HK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PrSpSEC
)

, RENAME_AmPrWI as (
    SELECT
        LNK_PRODUCT_ASIN_HK
      , PRODUCT_HK
      , ASIN_HK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_AmPrWI
)

, RENAME_AmPrSE as (
    SELECT
        LNK_PRODUCT_ASIN_HK
      , PRODUCT_HK
      , ASIN_HK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_AmPrSE
)
---- FILTER LAYER ----

, FILTER_PrSpWINN as (
    SELECT *
    FROM RENAME_PrSpWINN
)

, FILTER_PrSpSEC as (
    SELECT *
    FROM RENAME_PrSpSEC
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
    SELECT * FROM FILTER_PrSpWINN
    UNION ALL
    SELECT * FROM FILTER_PrSpSEC
    UNION ALL
    SELECT * FROM FILTER_AmPrWI
    UNION ALL
    SELECT * FROM FILTER_AmPrSE
)

---- FINAL LAYER ----
SELECT
          LNK_PRODUCT_ASIN_HK
        , PRODUCT_HK
        , ASIN_HK
        , BKCC
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.LNK_PRODUCT_ASIN_HK = JOIN_RESULT.LNK_PRODUCT_ASIN_HK
)
{% endif %}QUALIFY ROW_NUMBER() OVER(PARTITION BY LNK_PRODUCT_ASIN_HK ORDER BY LOAD_DTS DESC)=1
{% if not is_incremental() %}
union all

SELECT MD5_BINARY(GR.VALUE) AS LNK_PRODUCT_ASIN_HK
, MD5_BINARY(GR.VALUE) AS PRODUCT_HK
,MD5_BINARY(GR.VALUE) AS ASIN_HK
, DECODE(GR.VALUE::varchar, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS BKCC
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)  AS LOAD_DTS
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}