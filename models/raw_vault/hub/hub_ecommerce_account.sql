---- SRC LAYER ----
WITH
SRC_GAEPH          as ( SELECT BKCC, ECOMMERCE_ACCOUNT_BK, ECOMMERCE_ACCOUNT_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_ecommerce_properties_history__winn_google_analytics') }} as SRC  ),
SRC_GAEP           as ( SELECT BKCC, ECOMMERCE_ACCOUNT_BK, ECOMMERCE_ACCOUNT_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_ecommerce_properties__winn_google_analytics') }} as SRC  ),
SRC_GAEA           as ( SELECT BKCC, ECOMMERCE_ACCOUNT_BK, ECOMMERCE_ACCOUNT_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_ecommerce_accounts__winn_google_analytics') }} as SRC  )

/*
SRC_GAEPH          as ( SELECT * FROM STAGING.v_psa_stg_ecommerce_properties_history__winn_google_analytics )
SRC_GAEP           as ( SELECT * FROM STAGING.v_psa_stg_ecommerce_properties__winn_google_analytics )
SRC_GAEA           as ( SELECT * FROM STAGING.v_psa_stg_ecommerce_accounts__winn_google_analytics )
*/
---- LOGIC LAYER ----

, LOGIC_GAEPH as (
    SELECT
        ECOMMERCE_ACCOUNT_HK
      , ECOMMERCE_ACCOUNT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_GAEPH
)

, LOGIC_GAEP as (
    SELECT
        ECOMMERCE_ACCOUNT_HK
      , ECOMMERCE_ACCOUNT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_GAEP
)

, LOGIC_GAEA as (
    SELECT
        ECOMMERCE_ACCOUNT_HK
      , ECOMMERCE_ACCOUNT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_GAEA
)
---- RENAME LAYER ----

, RENAME_GAEPH as (
    SELECT
        ECOMMERCE_ACCOUNT_HK
      , ECOMMERCE_ACCOUNT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_GAEPH
)

, RENAME_GAEP as (
    SELECT
        ECOMMERCE_ACCOUNT_HK
      , ECOMMERCE_ACCOUNT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_GAEP
)

, RENAME_GAEA as (
    SELECT
        ECOMMERCE_ACCOUNT_HK
      , ECOMMERCE_ACCOUNT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_GAEA
)
---- FILTER LAYER ----

, FILTER_GAEPH as (
    SELECT *
    FROM RENAME_GAEPH
)

, FILTER_GAEP as (
    SELECT *
    FROM RENAME_GAEP
)

, FILTER_GAEA as (
    SELECT *
    FROM RENAME_GAEA
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_GAEPH
    UNION ALL
    SELECT * FROM FILTER_GAEP
    UNION ALL
    SELECT * FROM FILTER_GAEA
)

---- FINAL LAYER ----
SELECT
          ECOMMERCE_ACCOUNT_HK
        , ECOMMERCE_ACCOUNT_BK
        , BKCC
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.ECOMMERCE_ACCOUNT_HK = JOIN_RESULT.ECOMMERCE_ACCOUNT_HK
)
{% endif %}
/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per BKs and BKCC. */
qualify 1 = row_number() over (partition by ECOMMERCE_ACCOUNT_BK, BKCC order by LOAD_DTS)
{% if not is_incremental() %}

union all
SELECT 
MD5_BINARY(GR.VALUE) AS ECOMMERCE_ACCOUNT_HK,
GR.VALUE::text AS ECOMMERCE_ACCOUNT_BK,
DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
