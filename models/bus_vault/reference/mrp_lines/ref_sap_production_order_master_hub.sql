---- SRC LAYER ----
WITH
SRC_sap            as ( SELECT * FROM {{ ref('v_psa_stg_production_order_master__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCTION_ORDER_BK ORDER BY LOAD_DTS desc))=1 )

/*
SRC_sap            as ( SELECT * FROM STAGING.V_PSA_STG_PRODUCTION_ORDER_MASTER__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_sap as (
    SELECT
        PRODUCTION_ORDER_BK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_sap
)
---- RENAME LAYER ----

, RENAME_sap as (
    SELECT
        PRODUCTION_ORDER_BK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_sap
)
---- FILTER LAYER ----

, FILTER_sap as (
    SELECT *
    FROM RENAME_sap
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_sap
)

---- FINAL LAYER ----
SELECT
          PRODUCTION_ORDER_BK
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.PRODUCTION_ORDER_BK = JOIN_RESULT.PRODUCTION_ORDER_BK
)
{% endif %}
{% if not is_incremental() %}
union all

SELECT  GR.VALUE  AS PRODUCTION_ORDER_BK
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)  as LOAD_DTS
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}