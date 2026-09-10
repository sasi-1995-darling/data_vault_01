---- SRC LAYER ----
WITH
SRC_PrSpWINN       as ( SELECT * FROM {{ ref('v_psa_stg_sns_products__profitero_winn') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY ASIN_HK ORDER BY LOAD_DTS ))=1 ),
SRC_PrSpSEC        as ( SELECT * FROM {{ ref('v_psa_stg_sns_products__profitero_security') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY ASIN_HK ORDER BY LOAD_DTS ))=1 ),
SRC_PrSalWIN       as ( SELECT * FROM {{ ref('v_psa_stg_sns_sales__profitero_winn') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY ASIN_HK ORDER BY LOAD_DTS ))=1 ),
SRC_PrSalSEC       as ( SELECT * FROM {{ ref('v_psa_stg_sns_sales__profitero_security') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY ASIN_HK ORDER BY LOAD_DTS ))=1 ),
SRC_PrShSpWIN      as ( SELECT * FROM {{ ref('v_psa_stg_amz_product__winn_profitero_share') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY ASIN_HK ORDER BY LOAD_DTS ))=1 ),
SRC_PrShSpSEC      as ( SELECT * FROM {{ ref('v_psa_stg_amz_product__security_profitero_share') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY ASIN_HK ORDER BY LOAD_DTS ))=1 ),
SRC_PrShSlWIN      as ( SELECT * FROM {{ ref('v_psa_stg_amz_product_sale__winn_profitero_share') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY ASIN_HK ORDER BY LOAD_DTS ))=1 ),
SRC_PrShSlSEC      as ( SELECT * FROM {{ ref('v_psa_stg_amz_product_sale__security_profitero_share') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY ASIN_HK ORDER BY LOAD_DTS ))=1 )

/*
SRC_PrSpWINN       as ( SELECT * FROM STAGING.v_psa_stg_sns_products__profitero_winn )
, SRC_PrSpSEC        as ( SELECT * FROM STAGING.v_psa_stg_sns_products__profitero_security )
, SRC_PrSalWIN       as ( SELECT * FROM STAGING.v_psa_stg_sns_sales__profitero_winn )
, SRC_PrSalSEC       as ( SELECT * FROM STAGING.v_psa_stg_sns_sales__profitero_security )
*/
---- LOGIC LAYER ----

, LOGIC_PrSpWINN as (
    SELECT
        ASIN_HK
      , ASIN_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PrSpWINN
)

, LOGIC_PrSpSEC as (
    SELECT
        ASIN_HK
      , ASIN_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PrSpSEC
)

, LOGIC_PrSalWIN as (
    SELECT
        ASIN_HK
      , ASIN_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PrSalWIN
)

, LOGIC_PrSalSEC as (
    SELECT
        ASIN_HK
      , ASIN_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PrSalSEC
)

, LOGIC_PrShSpWIN as (
    SELECT
        ASIN_HK
      , ASIN_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PrShSpWIN
)

, LOGIC_PrShSpSEC as (
    SELECT
        ASIN_HK
      , ASIN_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PrShSpSEC
)

, LOGIC_PrShSlWIN as (
    SELECT
        ASIN_HK
      , ASIN_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PrShSlWIN
)

, LOGIC_PrShSlSEC as (
    SELECT
        ASIN_HK
      , ASIN_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PrShSlSEC
)
---- RENAME LAYER ----

, RENAME_PrSpWINN as (
    SELECT
        ASIN_HK
      , ASIN_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PrSpWINN
)

, RENAME_PrSpSEC as (
    SELECT
        ASIN_HK
      , ASIN_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PrSpSEC
)

, RENAME_PrSalWIN as (
    SELECT
        ASIN_HK
      , ASIN_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PrSalWIN
)

, RENAME_PrSalSEC as (
    SELECT
        ASIN_HK
      , ASIN_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PrSalSEC
)

, RENAME_PrShSpWIN as (
    SELECT
        ASIN_HK
      , ASIN_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PrShSpWIN
)

, RENAME_PrShSpSEC as (
    SELECT
        ASIN_HK
      , ASIN_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PrShSpSEC
)

, RENAME_PrShSlWIN as (
    SELECT
        ASIN_HK
      , ASIN_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PrShSlWIN
)

, RENAME_PrShSlSEC as (
    SELECT
        ASIN_HK
      , ASIN_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PrShSlSEC
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

, FILTER_PrSalWIN as (
    SELECT *
    FROM RENAME_PrSalWIN
)

, FILTER_PrSalSEC as (
    SELECT *
    FROM RENAME_PrSalSEC
)

, FILTER_PrShSpWIN as (
    SELECT *
    FROM RENAME_PrShSpWIN
)

, FILTER_PrShSpSEC as (
    SELECT *
    FROM RENAME_PrShSpSEC
)

, FILTER_PrShSlWIN as (
    SELECT *
    FROM RENAME_PrShSlWIN
)

, FILTER_PrShSlSEC as (
    SELECT *
    FROM RENAME_PrShSlSEC
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_PrSpWINN
    UNION ALL
    SELECT * FROM FILTER_PrSpSEC
    UNION ALL
    SELECT * FROM FILTER_PrSalWIN
    UNION ALL
    SELECT * FROM FILTER_PrSalSEC
    UNION ALL
    SELECT * FROM FILTER_PrShSpWIN
    UNION ALL
    SELECT * FROM FILTER_PrShSpSEC
    UNION ALL
    SELECT * FROM FILTER_PrShSlWIN
    UNION ALL
    SELECT * FROM FILTER_PrShSlSEC
)

---- FINAL LAYER ----
SELECT
          ASIN_HK
        , ASIN_BK
        , BKCC
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.ASIN_HK = JOIN_RESULT.ASIN_HK
)
{% endif %}
QUALIFY ROW_NUMBER() OVER(PARTITION BY ASIN_HK ORDER BY LOAD_DTS DESC)=1
{% if not is_incremental() %}
union all

SELECT MD5_BINARY(GR.VALUE::varchar)  ASIN_HK
, GR.VALUE::varchar  AS ASIN_BK
, DECODE(GR.VALUE::varchar, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS BKCC
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)  AS LOAD_DTS
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}