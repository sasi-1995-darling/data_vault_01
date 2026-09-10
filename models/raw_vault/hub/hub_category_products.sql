---- SRC LAYER ----
WITH
SRC_PrCatWinn      as ( SELECT * FROM {{ ref('v_psa_stg_category_products__profitero_winn') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY CATEGORY_HK ORDER BY LOAD_DTS ))=1 ),
SRC_PrCatSec       as ( SELECT * FROM {{ ref('v_psa_stg_category_products__profitero_security') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY CATEGORY_HK ORDER BY LOAD_DTS ))=1 ),
SRC_PrCatFib       as ( SELECT * FROM {{ ref('v_psa_stg_category_products__profitero_fiberon') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY CATEGORY_HK ORDER BY LOAD_DTS ))=1 ),
SRC_PrCatLrn       as ( SELECT * FROM {{ ref('v_psa_stg_category_products__profitero_larson') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY CATEGORY_HK ORDER BY LOAD_DTS ))=1 ),
SRC_PrCatThm       as ( SELECT * FROM {{ ref('v_psa_stg_category_products__profitero_thermatru') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY CATEGORY_HK ORDER BY LOAD_DTS ))=1 ),
SRC_PrCatFyp       as ( SELECT * FROM {{ ref('v_psa_stg_category_products__profitero_fypon') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY CATEGORY_HK ORDER BY LOAD_DTS ))=1 )

/*
SRC_PrCatWinn      as ( SELECT * FROM STAGING.v_psa_stg_category_products__profitero_winn )
, SRC_PrCatSec       as ( SELECT * FROM STAGING.v_psa_stg_category_products__profitero_security )
, SRC_PrCatFib       as ( SELECT * FROM STAGING.v_psa_stg_category_products__profitero_fiberon )
, SRC_PrCatLrn       as ( SELECT * FROM STAGING.v_psa_stg_category_products__profitero_larson )
, SRC_PrCatThm       as ( SELECT * FROM STAGING.v_psa_stg_category_products__profitero_thermatru )
, SRC_PrCatFyp       as ( SELECT * FROM STAGING.v_psa_stg_category_products__profitero_fypon )
*/
---- LOGIC LAYER ----

, LOGIC_PrCatWinn as (
    SELECT
        CATEGORY_HK
      , CATEGORY_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PrCatWinn
)

, LOGIC_PrCatSec as (
    SELECT
        CATEGORY_HK
      , CATEGORY_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PrCatSec
)

, LOGIC_PrCatFib as (
    SELECT
        CATEGORY_HK
      , CATEGORY_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PrCatFib
)

, LOGIC_PrCatLrn as (
    SELECT
        CATEGORY_HK
      , CATEGORY_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PrCatLrn
)

, LOGIC_PrCatThm as (
    SELECT
        CATEGORY_HK
      , CATEGORY_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PrCatThm
)

, LOGIC_PrCatFyp as (
    SELECT
        CATEGORY_HK
      , CATEGORY_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PrCatFyp
)
---- RENAME LAYER ----

, RENAME_PrCatWinn as (
    SELECT
        CATEGORY_HK
      , CATEGORY_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PrCatWinn
)

, RENAME_PrCatSec as (
    SELECT
        CATEGORY_HK
      , CATEGORY_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PrCatSec
)

, RENAME_PrCatFib as (
    SELECT
        CATEGORY_HK
      , CATEGORY_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PrCatFib
)

, RENAME_PrCatFyp as (
    SELECT
        CATEGORY_HK
      , CATEGORY_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PrCatFyp
)

, RENAME_PrCatLrn as (
    SELECT
        CATEGORY_HK
      , CATEGORY_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PrCatLrn
)

, RENAME_PrCatThm as (
    SELECT
        CATEGORY_HK
      , CATEGORY_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PrCatThm
)
---- FILTER LAYER ----

, FILTER_PrCatWinn as (
    SELECT *
    FROM RENAME_PrCatWinn
)

, FILTER_PrCatSec as (
    SELECT *
    FROM RENAME_PrCatSec
)

, FILTER_PrCatFib as (
    SELECT *
    FROM RENAME_PrCatFib
)

, FILTER_PrCatLrn as (
    SELECT *
    FROM RENAME_PrCatLrn
)

, FILTER_PrCatThm as (
    SELECT *
    FROM RENAME_PrCatThm
)

, FILTER_PrCatFyp as (
    SELECT *
    FROM RENAME_PrCatFyp
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_PrCatWinn
    UNION
    SELECT * FROM FILTER_PrCatSec
    UNION
    SELECT * FROM FILTER_PrCatFib
    UNION
    SELECT * FROM FILTER_PrCatLrn
    UNION
    SELECT * FROM FILTER_PrCatThm
    UNION
    SELECT * FROM FILTER_PrCatFyp
)

---- FINAL LAYER ----
SELECT
          CATEGORY_HK
        , CATEGORY_BK
        , BKCC
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.CATEGORY_HK = JOIN_RESULT.CATEGORY_HK
)
{% endif %}
QUALIFY ROW_NUMBER() OVER(PARTITION BY CATEGORY_HK ORDER BY LOAD_DTS DESC)=1
{% if not is_incremental() %}
union all

SELECT MD5_BINARY(GR.VALUE::varchar)  CATEGORY_HK
, GR.VALUE::varchar  AS CATEGORY_BK
, DECODE(GR.VALUE::varchar, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS BKCC
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)  AS LOAD_DTS
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}