---- SRC LAYER ----
WITH
SRC_SML            as ( SELECT * FROM {{ ref('v_psa_stg_curr_rates__ml_ebs') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY CURR_RATES_BK ORDER BY LOAD_DTS ))=1 ),
SRC_SWINN          as ( SELECT * FROM {{ ref('v_psa_stg_currency_rates__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY CURR_RATES_BK ORDER BY LOAD_DTS ))=1 )
/*
SRC_SML            as ( SELECT * FROM STAGING.v_psa_stg_curr_rates__ml_ebs )
*/

/*
SRC_SWINN          as ( SELECT * FROM STAGING.v_psa_stg_currency_rates__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_SML as (
    SELECT
        CURR_RATES_BK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SML
)

, LOGIC_SWINN as (
    SELECT
        CURR_RATES_BK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SWINN
)
---- RENAME LAYER ----

, RENAME_SML as (
    SELECT
        CURR_RATES_BK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SML
)

, RENAME_SWINN as (
    SELECT
        CURR_RATES_BK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SWINN
)
---- FILTER LAYER ----

, FILTER_SML as (
    SELECT *
    FROM RENAME_SML
)

, FILTER_SWINN as (
    SELECT *
    FROM RENAME_SWINN
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_SML
    UNION ALL
    SELECT * FROM FILTER_SWINN
)

---- FINAL LAYER ----
SELECT
          CURR_RATES_BK
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.CURR_RATES_BK = JOIN_RESULT.CURR_RATES_BK
)
{% endif %}
{% if not is_incremental() %}
union all

SELECT  GR.VALUE  AS CURR_RATES_BK
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)::TIMESTAMP  as LOAD_DTS
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
