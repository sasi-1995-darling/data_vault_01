---- SRC LAYER ----
WITH
SRC_WINNPROMO      as ( SELECT ERP_BKCC, LOAD_DTS, PROMOTION_BK, PROMOTION_HK, REC_SRC FROM {{ ref('v_psa_stg_consolidated_promo_flow_input__winn_rgm') }} as SRC  )

/*
SRC_WINNPROMO      as ( SELECT * FROM STAGING.v_psa_stg_consolidated_promo_flow_input__winn_rgm )
*/
---- LOGIC LAYER ----

, LOGIC_WINNPROMO as (
    SELECT
        PROMOTION_HK
      , PROMOTION_BK
      , ERP_BKCC                                                     as                                               BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_WINNPROMO
)
---- RENAME LAYER ----

, RENAME_WINNPROMO as (
    SELECT
        PROMOTION_HK
      , PROMOTION_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_WINNPROMO
)
---- FILTER LAYER ----

, FILTER_WINNPROMO as (
    SELECT *
    FROM RENAME_WINNPROMO
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_WINNPROMO
)

---- FINAL LAYER ----
SELECT
          PROMOTION_HK
        , PROMOTION_BK
        , BKCC
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.PROMOTION_HK = JOIN_RESULT.PROMOTION_HK
)
{% endif %}
/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per BKs and BKCC. */
qualify 1 = row_number() over (partition by PROMOTION_BK, BKCC order by LOAD_DTS)
{% if not is_incremental() %}

union all
SELECT 
MD5_BINARY(GR.VALUE) AS PROMOTION_HK,
GR.VALUE::text AS PROMOTION_BK,
DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
