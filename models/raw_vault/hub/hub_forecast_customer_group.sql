---- SRC LAYER ----
WITH
SRC_s              as ( SELECT BKCC, KEY_ACCOUNT_BK, KEY_ACCOUNT_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_key_account__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY KEY_ACCOUNT_HK ORDER BY LOAD_DTS ))=1 ),
SRC_s1             as ( SELECT BKCC, KEY_ACCOUNT_GROUP_BK, KEY_ACCOUNT_GROUP_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_key_account_group__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY KEY_ACCOUNT_GROUP_HK ORDER BY LOAD_DTS ))=1 ),
SRC_demand         as ( SELECT BKCC, FORECAST_CUSTOMER_GROUP_BK, FORECAST_CUSTOMER_GROUP_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_demand_planning_history__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY FORECAST_CUSTOMER_GROUP_HK ORDER BY LOAD_DTS ))=1 )   

/*
SRC_s              as ( SELECT * FROM STAGING.v_psa_stg_key_account__winn_sap )
SRC_s1              as ( SELECT * FROM STAGING.v_psa_stg_key_account_group__winn_sap )
SRC_demand          as ( SELECT * FROM STAGING.v_psa_stg_key_account_group__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_s as (
    SELECT
        KEY_ACCOUNT_HK   as    FORECAST_CUSTOMER_GROUP_HK
      , KEY_ACCOUNT_BK   as    FORECAST_CUSTOMER_GROUP_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_s
)

, LOGIC_s1 as (
    SELECT
        KEY_ACCOUNT_GROUP_HK   as    FORECAST_CUSTOMER_GROUP_HK
      , KEY_ACCOUNT_GROUP_BK   as    FORECAST_CUSTOMER_GROUP_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_s1
)

, LOGIC_demand as (
    SELECT
        FORECAST_CUSTOMER_GROUP_HK
      , FORECAST_CUSTOMER_GROUP_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_demand
)
---- RENAME LAYER ----

, RENAME_s as (
    SELECT
        FORECAST_CUSTOMER_GROUP_HK
      , FORECAST_CUSTOMER_GROUP_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_s
)

, RENAME_s1 as (
    SELECT
        FORECAST_CUSTOMER_GROUP_HK
      , FORECAST_CUSTOMER_GROUP_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_s1
)

, RENAME_demand as (
    SELECT
        FORECAST_CUSTOMER_GROUP_HK
      , FORECAST_CUSTOMER_GROUP_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_demand
)
---- FILTER LAYER ----

, FILTER_s as (
    SELECT *
    FROM RENAME_s
)

, FILTER_s1 as (
    SELECT *
    FROM RENAME_s1
)

, FILTER_demand as (
    SELECT *
    FROM RENAME_demand
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_s
    UNION ALL
    SELECT *
    FROM FILTER_s1
    UNION ALL
    SELECT *
    FROM FILTER_demand
)

---- FINAL LAYER ----
SELECT
          FORECAST_CUSTOMER_GROUP_HK
        , FORECAST_CUSTOMER_GROUP_BK
        , BKCC
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.FORECAST_CUSTOMER_GROUP_HK = JOIN_RESULT.FORECAST_CUSTOMER_GROUP_HK
)
{% endif %}
QUALIFY 1= ROW_NUMBER() OVER (PARTITION BY FORECAST_CUSTOMER_GROUP_BK, BKCC ORDER BY LOAD_DTS)
{% if not is_incremental() %}

union all
SELECT 
MD5_BINARY(GR.VALUE) AS FORECAST_CUSTOMER_GROUP_HK,
GR.VALUE::text AS FORECAST_CUSTOMER_GROUP_BK,
DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
