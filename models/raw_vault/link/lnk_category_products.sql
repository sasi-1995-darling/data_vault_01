---- SRC LAYER ----
WITH
SRC_PrCWinn        as ( SELECT * FROM {{ ref('v_psa_stg_categories__profitero_winn') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_CATEGORY_HK ORDER BY LOAD_DTS))=1 ),
SRC_PrCSec         as ( SELECT * FROM {{ ref('v_psa_stg_categories__profitero_security') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_CATEGORY_HK ORDER BY LOAD_DTS))=1 ),
SRC_PrCFib         as ( SELECT * FROM {{ ref('v_psa_stg_categories__profitero_fiberon') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_CATEGORY_HK ORDER BY LOAD_DTS))=1 ),
SRC_PrCFyp         as ( SELECT * FROM {{ ref('v_psa_stg_categories__profitero_fypon') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_CATEGORY_HK ORDER BY LOAD_DTS))=1 ),
SRC_PrCLrsn        as ( SELECT * FROM {{ ref('v_psa_stg_categories__profitero_larson') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_CATEGORY_HK ORDER BY LOAD_DTS))=1 ),
SRC_PrCTt          as ( SELECT * FROM {{ ref('v_psa_stg_categories__profitero_thermatru') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_CATEGORY_HK ORDER BY LOAD_DTS))=1 )

/*
SRC_PrCWinn        as ( SELECT * FROM STAGING.v_psa_stg_categories__profitero_winn )
, SRC_PrCSec         as ( SELECT * FROM STAGING.v_psa_stg_categories__profitero_security )
, SRC_PrCFib         as ( SELECT * FROM STAGING.v_psa_stg_categories__profitero_fiberon )
, SRC_PrCFyp         as ( SELECT * FROM STAGING.v_psa_stg_categories__profitero_fypon )
, SRC_PrCLrsn        as ( SELECT * FROM STAGING.v_psa_stg_categories__profitero_larson )
, SRC_PrCTt          as ( SELECT * FROM STAGING.v_psa_stg_categories__profitero_thermatru )
*/
---- LOGIC LAYER ----

, LOGIC_PrCWinn as (
    SELECT
        PRODUCT_CATEGORY_HK
      , PRODUCT_HK
      , CATEGORY_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PrCWinn
)

, LOGIC_PrCSec as (
    SELECT
        PRODUCT_CATEGORY_HK
      , PRODUCT_HK
      , CATEGORY_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PrCSec
)

, LOGIC_PrCFib as (
    SELECT
        PRODUCT_CATEGORY_HK
      , PRODUCT_HK
      , CATEGORY_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PrCFib
)

, LOGIC_PrCFyp as (
    SELECT
        PRODUCT_CATEGORY_HK
      , PRODUCT_HK
      , CATEGORY_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PrCFyp
)

, LOGIC_PrCLrsn as (
    SELECT
        PRODUCT_CATEGORY_HK
      , PRODUCT_HK
      , CATEGORY_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PrCLrsn
)

, LOGIC_PrCTt as (
    SELECT
        PRODUCT_CATEGORY_HK
      , PRODUCT_HK
      , CATEGORY_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PrCTt
)
---- RENAME LAYER ----

, RENAME_PrCWinn as (
    SELECT
        PRODUCT_CATEGORY_HK
      , PRODUCT_HK
      , CATEGORY_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PrCWinn
)

, RENAME_PrCSec as (
    SELECT
        PRODUCT_CATEGORY_HK
      , PRODUCT_HK
      , CATEGORY_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PrCSec
)

, RENAME_PrCFib as (
    SELECT
        PRODUCT_CATEGORY_HK
      , PRODUCT_HK
      , CATEGORY_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PrCFib
)

, RENAME_PrCFyp as (
    SELECT
        PRODUCT_CATEGORY_HK
      , PRODUCT_HK
      , CATEGORY_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PrCFyp
)

, RENAME_PrCLrsn as (
    SELECT
        PRODUCT_CATEGORY_HK
      , PRODUCT_HK
      , CATEGORY_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PrCLrsn
)

, RENAME_PrCTt as (
    SELECT
        PRODUCT_CATEGORY_HK
      , PRODUCT_HK
      , CATEGORY_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PrCTt
)
---- FILTER LAYER ----

, FILTER_PrCWinn as (
    SELECT *
    FROM RENAME_PrCWinn
)

, FILTER_PrCSec as (
    SELECT *
    FROM RENAME_PrCSec
)

, FILTER_PrCFib as (
    SELECT *
    FROM RENAME_PrCFib
)

, FILTER_PrCFyp as (
    SELECT *
    FROM RENAME_PrCFyp
)

, FILTER_PrCLrsn as (
    SELECT *
    FROM RENAME_PrCLrsn
)

, FILTER_PrCTt as (
    SELECT *
    FROM RENAME_PrCTt
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_PrCWinn
    UNION ALL
    SELECT * FROM FILTER_PrCSec
    UNION ALL
    SELECT * FROM FILTER_PrCFib
    UNION ALL
    SELECT * FROM FILTER_PrCFyp
    UNION ALL
    SELECT * FROM FILTER_PrCLrsn
    UNION ALL
    SELECT * FROM FILTER_PrCTt
)

---- FINAL LAYER ----
SELECT
          PRODUCT_CATEGORY_HK
        , PRODUCT_HK
        , CATEGORY_HK
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.PRODUCT_CATEGORY_HK = JOIN_RESULT.PRODUCT_CATEGORY_HK
)
{% endif %}
--this is to consolidate records coming from 2 diff tables with the same bkcc
QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_CATEGORY_HK ORDER BY LOAD_DTS))=1
{% if not is_incremental() %}

union all
SELECT 
 MD5_BINARY(GR.VALUE) AS PRODUCT_CATEGORY_HK
, MD5_BINARY(GR.VALUE) AS PRODUCT_HK
, MD5_BINARY(GR.VALUE) AS CATEGORY_HK
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)  AS LOAD_DTS
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}