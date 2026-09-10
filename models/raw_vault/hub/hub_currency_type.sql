---- SRC LAYER ----
WITH
SRC_CE1NEW4        as ( SELECT BKCC, CURRENCY_TYPE_BK, CURRENCY_TYPE_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_copa_sales__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY CURRENCY_TYPE_BK ORDER BY GLCHANGETIME ))=1 ),
SRC_AZCOPA         as ( SELECT BKCC, CURRENCY_TYPE_BK, CURRENCY_TYPE_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_copa_sales_history__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY CURRENCY_TYPE_BK ORDER BY ZEXTRACTDATE ))=1 )

/*
SRC_CE1NEW4        as ( SELECT * FROM STAGING.v_psa_stg_copa_sales__winn_sap )
SRC_AZCOPA         as ( SELECT * FROM STAGING.v_psa_stg_copa_sales_history__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_CE1NEW4 as (
    SELECT
        CURRENCY_TYPE_HK
      , CURRENCY_TYPE_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_CE1NEW4
)

, LOGIC_AZCOPA as (
    SELECT
        CURRENCY_TYPE_HK
      , CURRENCY_TYPE_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_AZCOPA
)
---- RENAME LAYER ----

, RENAME_CE1NEW4 as (
    SELECT
        CURRENCY_TYPE_HK
      , CURRENCY_TYPE_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_CE1NEW4
)

, RENAME_AZCOPA as (
    SELECT
        CURRENCY_TYPE_HK
      , CURRENCY_TYPE_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_AZCOPA
)
---- FILTER LAYER ----

, FILTER_CE1NEW4 as (
    SELECT *
    FROM RENAME_CE1NEW4
)

, FILTER_AZCOPA as (
    SELECT *
    FROM RENAME_AZCOPA
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_CE1NEW4
    UNION ALL
    SELECT * FROM FILTER_AZCOPA
)

---- FINAL LAYER ----
SELECT
          CURRENCY_TYPE_HK
        , CURRENCY_TYPE_BK
        , BKCC
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.CURRENCY_TYPE_HK = JOIN_RESULT.CURRENCY_TYPE_HK
)
{% endif %}
/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per BKs and BKCC. */
qualify 1 = row_number() over (partition by CURRENCY_TYPE_BK, BKCC order by LOAD_DTS)
{% if not is_incremental() %}

union all
SELECT 
MD5_BINARY(GR.VALUE) AS CURRENCY_TYPE_HK,
GR.VALUE::text AS CURRENCY_TYPE_BK,
DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
