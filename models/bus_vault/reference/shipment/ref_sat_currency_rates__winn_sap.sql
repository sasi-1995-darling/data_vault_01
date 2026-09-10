---- SRC LAYER ----
WITH
SRC_a              as ( SELECT * FROM {{ ref('v_psa_stg_currency_rates__winn_sap') }} as SRC 
                        {% if is_incremental() %}
                        WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}}){% endif %}   )

/*
SRC_a              as ( SELECT * FROM STAGING.v_psa_stg_currency_rates__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_a as (
    SELECT
        CURR_RATES_BK
      , MANDT                                                        as                                             CLIENT
      , KURST                                                        as                                 EXCHANGE_RATE_TYPE
      , FCURR                                                        as                                      FROM_CURRENCY
      , TCURR                                                        as                                        TO_CURRENCY
      , CONVERSION_DATE
      , GDATU                                                        as                       EXCHANGE_RATE_EFFECTIVE_DATE
      , UKURS                                                        as                                      EXCHANGE_RATE
      , FFACT                                                        as                                FROM_CURRENCY_RATIO
      , TFACT                                                        as                                  TO_CURRENCY_RATIO
      , PSA_LOAD_DTS
      , LOAD_DTS
      , HASHDIFF
    FROM SRC_a
)
---- RENAME LAYER ----

, RENAME_a as (
    SELECT
        CURR_RATES_BK
      , CLIENT
      , EXCHANGE_RATE_TYPE
      , FROM_CURRENCY
      , TO_CURRENCY
      , CONVERSION_DATE
      , EXCHANGE_RATE_EFFECTIVE_DATE
      , EXCHANGE_RATE
      , FROM_CURRENCY_RATIO
      , TO_CURRENCY_RATIO
      , PSA_LOAD_DTS
      , LOAD_DTS
      , HASHDIFF
    FROM LOGIC_a
)
---- FILTER LAYER ----

, FILTER_a as (
    SELECT *
    FROM RENAME_a
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_a
)

---- FINAL LAYER ----
SELECT
          CURR_RATES_BK
        , CLIENT
        , EXCHANGE_RATE_TYPE
        , FROM_CURRENCY
        , TO_CURRENCY
        , CONVERSION_DATE
        , EXCHANGE_RATE_EFFECTIVE_DATE
        , EXCHANGE_RATE
        , FROM_CURRENCY_RATIO
        , TO_CURRENCY_RATIO
        , PSA_LOAD_DTS
        , LOAD_DTS
        , HASHDIFF
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.CURR_RATES_BK = JOIN_RESULT.CURR_RATES_BK
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %}
{% if not is_incremental() %}

/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per HK and hashdiff. */
qualify 1 = row_number() over (partition by CURR_RATES_BK, HASHDIFF order by PSA_LOAD_DTS)

union all
SELECT 
GR.VALUE::text AS CURR_RATES_BK,
NULL AS CLIENT,
NULL AS EXCHANGE_RATE_TYPE,
NULL AS FROM_CURRENCY,
NULL AS TO_CURRENCY,
NULL AS CONVERSION_DATE,
NULL AS EXCHANGE_RATE_EFFECTIVE_DATE,
NULL AS EXCHANGE_RATE,
NULL AS FROM_CURRENCY_RATIO,
NULL AS TO_CURRENCY_RATIO,
'1900-01-01'::TIMESTAMP AS PSA_LOAD_DTS,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
''::BINARY AS HASHDIFF,
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
