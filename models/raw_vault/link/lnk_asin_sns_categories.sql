---- SRC LAYER ----
WITH
SRC_PrSlWINN       as ( SELECT * FROM {{ ref('v_psa_stg_sns_sales__profitero_winn') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY ASIN_SNS_CATEGORY_HK ORDER BY LOAD_DTS))=1 ),
SRC_PrSlSEC        as ( SELECT * FROM {{ ref('v_psa_stg_sns_sales__profitero_security') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY ASIN_SNS_CATEGORY_HK ORDER BY LOAD_DTS))=1 ),
SRC_ShSlWIN        as ( SELECT * FROM {{ ref('v_psa_stg_amz_product_sale__winn_profitero_share') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY ASIN_SNS_CATEGORY_HK ORDER BY LOAD_DTS))=1 ),
SRC_ShSlSEC        as ( SELECT * FROM {{ ref('v_psa_stg_amz_product_sale__security_profitero_share') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY ASIN_SNS_CATEGORY_HK ORDER BY LOAD_DTS))=1 )

/*
SRC_PrSlWINN       as ( SELECT * FROM STAGING.v_psa_stg_sns_sales__profitero_winn )
, SRC_PrSlSEC        as ( SELECT * FROM STAGING.v_psa_stg_sns_sales__profitero_security )
*/
---- LOGIC LAYER ----

, LOGIC_PrSlWINN as (
    SELECT
        ASIN_SNS_CATEGORY_HK
      , SNS_CATEGORY_HK
      , ASIN_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PrSlWINN
)

, LOGIC_PrSlSEC as (
    SELECT
        ASIN_SNS_CATEGORY_HK
      , SNS_CATEGORY_HK
      , ASIN_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PrSlSEC
)

, LOGIC_ShSlWIN as (
    SELECT
        ASIN_SNS_CATEGORY_HK
      , SNS_CATEGORY_HK
      , ASIN_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_ShSlWIN
)

, LOGIC_ShSlSEC as (
    SELECT
        ASIN_SNS_CATEGORY_HK
      , SNS_CATEGORY_HK
      , ASIN_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_ShSlSEC
)
---- RENAME LAYER ----

, RENAME_PrSlWINN as (
    SELECT
        ASIN_SNS_CATEGORY_HK
      , SNS_CATEGORY_HK
      , ASIN_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PrSlWINN
)

, RENAME_PrSlSEC as (
    SELECT
        ASIN_SNS_CATEGORY_HK
      , SNS_CATEGORY_HK
      , ASIN_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PrSlSEC
)

, RENAME_ShSlWIN as (
    SELECT
        ASIN_SNS_CATEGORY_HK
      , SNS_CATEGORY_HK
      , ASIN_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_ShSlWIN
)

, RENAME_ShSlSEC as (
    SELECT
        ASIN_SNS_CATEGORY_HK
      , SNS_CATEGORY_HK
      , ASIN_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_ShSlSEC
)
---- FILTER LAYER ----

, FILTER_PrSlWINN as (
    SELECT *
    FROM RENAME_PrSlWINN
)

, FILTER_PrSlSEC as (
    SELECT *
    FROM RENAME_PrSlSEC
)

, FILTER_ShSlWIN as (
    SELECT *
    FROM RENAME_ShSlWIN
)

, FILTER_ShSlSEC as (
    SELECT *
    FROM RENAME_ShSlSEC
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_PrSlWINN
    UNION ALL
    SELECT * FROM FILTER_PrSlSEC
    UNION ALL
    SELECT * FROM FILTER_ShSlWIN
    UNION ALL
    SELECT * FROM FILTER_ShSlSEC
)

---- FINAL LAYER ----
SELECT
          ASIN_SNS_CATEGORY_HK
        , SNS_CATEGORY_HK
        , ASIN_HK
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.ASIN_SNS_CATEGORY_HK = JOIN_RESULT.ASIN_SNS_CATEGORY_HK
)
{% endif %}
--this is to consolidate records coming from 2 diff tables with the same bkcc
QUALIFY (ROW_NUMBER() OVER(PARTITION BY ASIN_SNS_CATEGORY_HK ORDER BY LOAD_DTS))=1
{% if not is_incremental() %}

union all
SELECT 
 MD5_BINARY(GR.VALUE) AS ASIN_SNS_CATEGORY_HK
, MD5_BINARY(GR.VALUE) AS SNS_CATEGORY_HK
, MD5_BINARY(GR.VALUE) AS ASIN_HK
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)  AS LOAD_DTS
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}