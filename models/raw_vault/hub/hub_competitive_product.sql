---- SRC LAYER ----
WITH
SRC_PrPrdWinn      as ( SELECT * FROM {{ ref('v_psa_stg_competitive_products__profitero_winn') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY COMPETITIVE_PRODUCT_HK ORDER BY LOAD_DTS ))=1 ),
SRC_PrPrdSec       as ( SELECT * FROM {{ ref('v_psa_stg_competitive_products__profitero_security') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY COMPETITIVE_PRODUCT_HK ORDER BY LOAD_DTS ))=1 ),
SRC_PrPrdFib       as ( SELECT * FROM {{ ref('v_psa_stg_competitive_products__profitero_fiberon') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY COMPETITIVE_PRODUCT_HK ORDER BY LOAD_DTS ))=1 ),
SRC_PrPrdFyp       as ( SELECT * FROM {{ ref('v_psa_stg_competitive_products__profitero_fypon') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY COMPETITIVE_PRODUCT_HK ORDER BY LOAD_DTS ))=1 ),
SRC_DvPOS          as ( SELECT * FROM {{ ref('v_psa_stg_pos_main_weekly__datavations') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY COMPETITIVE_PRODUCT_HK ORDER BY LOAD_DTS ))=1 ),
SRC_PrPrdLrsn      as ( SELECT * FROM {{ ref('v_psa_stg_competitive_products__profitero_larson') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY COMPETITIVE_PRODUCT_HK ORDER BY LOAD_DTS ))=1 ),
SRC_DvItem         as ( SELECT * FROM {{ ref('v_psa_stg_item_details__datavations') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY COMPETITIVE_PRODUCT_HK ORDER BY LOAD_DTS ))=1 ),
SRC_PrPrdTt        as ( SELECT * FROM {{ ref('v_psa_stg_competitive_products__profitero_thermatru') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY COMPETITIVE_PRODUCT_HK ORDER BY LOAD_DTS ))=1 ),
SRC_PrPrdFibSh     as ( SELECT * FROM {{ ref('v_psa_stg_competitive_products__fiberon_profitero_share') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY COMPETITIVE_PRODUCT_HK ORDER BY LOAD_DTS ))=1 ),
SRC_PrPrdFypSh     as ( SELECT * FROM {{ ref('v_psa_stg_competitive_products__fypon_profitero_share') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY COMPETITIVE_PRODUCT_HK ORDER BY LOAD_DTS ))=1 ),
SRC_PrPrdLrsnSh    as ( SELECT * FROM {{ ref('v_psa_stg_competitive_products__larson_profitero_share') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY COMPETITIVE_PRODUCT_HK ORDER BY LOAD_DTS ))=1 ),
SRC_PrPrdSecSh     as ( SELECT * FROM {{ ref('v_psa_stg_competitive_products__security_profitero_share') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY COMPETITIVE_PRODUCT_HK ORDER BY LOAD_DTS ))=1 ),
SRC_PrPrdTtSh      as ( SELECT * FROM {{ ref('v_psa_stg_competitive_products__thermatru_profitero_share') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY COMPETITIVE_PRODUCT_HK ORDER BY LOAD_DTS ))=1 ),
SRC_PrPrdMoenSh    as ( SELECT * FROM {{ ref('v_psa_stg_competitive_products__winn_profitero_share') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY COMPETITIVE_PRODUCT_HK ORDER BY LOAD_DTS ))=1 )

/*
SRC_PrPrdWinn      as ( SELECT * FROM STAGING.v_psa_stg_competitive_products__profitero_winn )
, SRC_PrPrdSec       as ( SELECT * FROM STAGING.v_psa_stg_competitive_products__profitero_security )
, SRC_PrPrdFib       as ( SELECT * FROM STAGING.v_psa_stg_competitive_products__profitero_fiberon )
, SRC_PrPrdFyp       as ( SELECT * FROM STAGING.v_psa_stg_competitive_products__profitero_fypon )
, SRC_DvPOS          as ( SELECT * FROM STAGING.v_psa_stg_pos_main_weekly__datavations )
, SRC_PrPrdLrsn      as ( SELECT * FROM STAGING.v_psa_stg_competitive_products__profitero_larson )
, SRC_DvItem         as ( SELECT * FROM STAGING.v_psa_stg_item_details__datavations )
, SRC_PrPrdTt        as ( SELECT * FROM STAGING.v_psa_stg_competitive_products__profitero_thermatru )
*/
---- LOGIC LAYER ----

, LOGIC_PrPrdWinn as (
    SELECT
        COMPETITIVE_PRODUCT_HK
      , COMPETITIVE_PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PrPrdWinn
)

, LOGIC_PrPrdSec as (
    SELECT
        COMPETITIVE_PRODUCT_HK
      , COMPETITIVE_PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PrPrdSec
)

, LOGIC_PrPrdFib as (
    SELECT
        COMPETITIVE_PRODUCT_HK
      , COMPETITIVE_PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PrPrdFib
)

, LOGIC_PrPrdFyp as (
    SELECT
        COMPETITIVE_PRODUCT_HK
      , COMPETITIVE_PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PrPrdFyp
)

, LOGIC_DvPOS as (
    SELECT
        COMPETITIVE_PRODUCT_HK
      , COMPETITIVE_PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_DvPOS
)

, LOGIC_PrPrdLrsn as (
    SELECT
        COMPETITIVE_PRODUCT_HK
      , COMPETITIVE_PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PrPrdLrsn
)

, LOGIC_DvItem as (
    SELECT
        COMPETITIVE_PRODUCT_HK
      , COMPETITIVE_PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_DvItem
)

, LOGIC_PrPrdTt as (
    SELECT
        COMPETITIVE_PRODUCT_HK
      , COMPETITIVE_PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PrPrdTt
)

, LOGIC_PrPrdFibSh as (
    SELECT
        COMPETITIVE_PRODUCT_HK
      , COMPETITIVE_PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PrPrdFibSh
)

, LOGIC_PrPrdFypSh as (
    SELECT
        COMPETITIVE_PRODUCT_HK
      , COMPETITIVE_PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PrPrdFypSh
)

, LOGIC_PrPrdLrsnSh as (
    SELECT
        COMPETITIVE_PRODUCT_HK
      , COMPETITIVE_PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PrPrdLrsnSh
)

, LOGIC_PrPrdSecSh as (
    SELECT
        COMPETITIVE_PRODUCT_HK
      , COMPETITIVE_PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PrPrdSecSh
)

, LOGIC_PrPrdTtSh as (
    SELECT
        COMPETITIVE_PRODUCT_HK
      , COMPETITIVE_PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PrPrdTtSh
)

, LOGIC_PrPrdMoenSh as (
    SELECT
        COMPETITIVE_PRODUCT_HK
      , COMPETITIVE_PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PrPrdMoenSh
)
---- RENAME LAYER ----

, RENAME_PrPrdWinn as (
    SELECT
        COMPETITIVE_PRODUCT_HK
      , COMPETITIVE_PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PrPrdWinn
)

, RENAME_PrPrdSec as (
    SELECT
        COMPETITIVE_PRODUCT_HK
      , COMPETITIVE_PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PrPrdSec
)

, RENAME_PrPrdFib as (
    SELECT
        COMPETITIVE_PRODUCT_HK
      , COMPETITIVE_PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PrPrdFib
)

, RENAME_PrPrdFyp as (
    SELECT
        COMPETITIVE_PRODUCT_HK
      , COMPETITIVE_PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PrPrdFyp
)

, RENAME_PrPrdLrsn as (
    SELECT
        COMPETITIVE_PRODUCT_HK
      , COMPETITIVE_PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PrPrdLrsn
)

, RENAME_PrPrdTt as (
    SELECT
        COMPETITIVE_PRODUCT_HK
      , COMPETITIVE_PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PrPrdTt
)

, RENAME_PrPrdFibSh as (
    SELECT
        COMPETITIVE_PRODUCT_HK
      , COMPETITIVE_PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PrPrdFibSh
)

, RENAME_PrPrdFypSh as (
    SELECT
        COMPETITIVE_PRODUCT_HK
      , COMPETITIVE_PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PrPrdFypSh
)

, RENAME_PrPrdLrsnSh as (
    SELECT
        COMPETITIVE_PRODUCT_HK
      , COMPETITIVE_PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PrPrdLrsnSh
)

, RENAME_PrPrdSecSh as (
    SELECT
        COMPETITIVE_PRODUCT_HK
      , COMPETITIVE_PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PrPrdSecSh
)

, RENAME_PrPrdTtSh as (
    SELECT
        COMPETITIVE_PRODUCT_HK
      , COMPETITIVE_PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PrPrdTtSh
)

, RENAME_PrPrdMoenSh as (
    SELECT
        COMPETITIVE_PRODUCT_HK
      , COMPETITIVE_PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PrPrdMoenSh
)

, RENAME_DvItem as (
    SELECT
        COMPETITIVE_PRODUCT_HK
      , COMPETITIVE_PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_DvItem
)

, RENAME_DvPOS as (
    SELECT
        COMPETITIVE_PRODUCT_HK
      , COMPETITIVE_PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_DvPOS
)
---- FILTER LAYER ----

, FILTER_PrPrdWinn as (
    SELECT *
    FROM RENAME_PrPrdWinn
)

, FILTER_PrPrdSec as (
    SELECT *
    FROM RENAME_PrPrdSec
)

, FILTER_PrPrdFib as (
    SELECT *
    FROM RENAME_PrPrdFib
)

, FILTER_PrPrdFyp as (
    SELECT *
    FROM RENAME_PrPrdFyp
)

, FILTER_DvPOS as (
    SELECT *
    FROM RENAME_DvPOS
)

, FILTER_PrPrdLrsn as (
    SELECT *
    FROM RENAME_PrPrdLrsn
)

, FILTER_DvItem as (
    SELECT *
    FROM RENAME_DvItem
)

, FILTER_PrPrdTt as (
    SELECT *
    FROM RENAME_PrPrdTt
)

, FILTER_PrPrdFibSh as (
    SELECT *
    FROM RENAME_PrPrdFibSh
)

, FILTER_PrPrdFypSh as (
    SELECT *
    FROM RENAME_PrPrdFypSh
)

, FILTER_PrPrdLrsnSh as (
    SELECT *
    FROM RENAME_PrPrdLrsnSh
)

, FILTER_PrPrdSecSh as (
    SELECT *
    FROM RENAME_PrPrdSecSh
)

, FILTER_PrPrdTtSh as (
    SELECT *
    FROM RENAME_PrPrdTtSh
)

, FILTER_PrPrdMoenSh as (
    SELECT *
    FROM RENAME_PrPrdMoenSh
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_PrPrdWinn
    UNION ALL
    SELECT * FROM FILTER_PrPrdSec
    UNION ALL
    SELECT * FROM FILTER_PrPrdFib
    UNION ALL
    SELECT * FROM FILTER_PrPrdFyp
    UNION ALL
    SELECT * FROM FILTER_DvPOS
    UNION ALL
    SELECT * FROM FILTER_PrPrdLrsn
    UNION ALL
    SELECT * FROM FILTER_DvItem
    UNION ALL
    SELECT * FROM FILTER_PrPrdTt
    UNION ALL
    SELECT * FROM FILTER_PrPrdFibSh
    UNION ALL
    SELECT * FROM FILTER_PrPrdFypSh
    UNION ALL
    SELECT * FROM FILTER_PrPrdLrsnSh
    UNION ALL
    SELECT * FROM FILTER_PrPrdSecSh
    UNION ALL
    SELECT * FROM FILTER_PrPrdTtSh
    UNION ALL
    SELECT * FROM FILTER_PrPrdMoenSh
)

---- FINAL LAYER ----
SELECT
          COMPETITIVE_PRODUCT_HK
        , COMPETITIVE_PRODUCT_BK
        , BKCC
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.COMPETITIVE_PRODUCT_HK = JOIN_RESULT.COMPETITIVE_PRODUCT_HK
)
{% endif %}
QUALIFY ROW_NUMBER() OVER(PARTITION BY COMPETITIVE_PRODUCT_HK ORDER BY LOAD_DTS)=1
{% if not is_incremental() %}
union all

SELECT MD5_BINARY(GR.VALUE::varchar)  COMPETITIVE_PRODUCT_HK
, GR.VALUE::varchar  AS COMPETITIVE_PRODUCT_BK
, DECODE(GR.VALUE::varchar, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS BKCC
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)  AS LOAD_DTS
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}