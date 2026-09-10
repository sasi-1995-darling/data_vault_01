---- SRC LAYER ----
WITH
SRC_CEH            as ( SELECT BDATJ, BKCC, KLVAR, LOAD_DTS, MATNR, POPER, PRODUCT_COST_ESTIMATE_HK, REC_SRC, WERKS FROM {{ ref('v_psa_stg_cost_estimate_header__moen_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_COST_ESTIMATE_HK ORDER BY LOAD_DTS ))=1 ),
SRC_CEC            as ( SELECT BDATJ, BKCC, KLVAR, LOAD_DTS, MATNR, POPER, PRODUCT_COST_ESTIMATE_HK, REC_SRC, WERKS FROM {{ ref('v_psa_stg_cost_estimate_component__moen_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_COST_ESTIMATE_HK ORDER BY LOAD_DTS ))=1 )

/*
SRC_CEH            as ( SELECT * FROM STAGING.v_psa_stg_cost_estimate_header__moen_sap )
SRC_CEC            as ( SELECT * FROM STAGING.v_psa_stg_cost_estimate_component__moen_sap )
*/
---- LOGIC LAYER ----

, LOGIC_CEH as (
    SELECT
        PRODUCT_COST_ESTIMATE_HK
      , MATNR                                                        as                                            ITEM_BK
      , WERKS                                                        as                                           PLANT_BK
      , POPER
      , BDATJ
      , KLVAR                                                        as                                 COSTING_VARIANT_BK
      , BKCC
      , REC_SRC
      , LOAD_DTS
    FROM SRC_CEH
)

, LOGIC_CEC as (
    SELECT
        PRODUCT_COST_ESTIMATE_HK
      , MATNR                                                        as                                            ITEM_BK
      , WERKS                                                        as                                           PLANT_BK
      , POPER
      , BDATJ
      , KLVAR                                                        as                                 COSTING_VARIANT_BK
      , BKCC
      , REC_SRC
      , LOAD_DTS
    FROM SRC_CEC
)
---- RENAME LAYER ----

, RENAME_CEH as (
    SELECT
        PRODUCT_COST_ESTIMATE_HK
      , ITEM_BK
      , PLANT_BK
      , POPER
      , BDATJ
      , COSTING_VARIANT_BK
      , BKCC
      , REC_SRC
      , LOAD_DTS
    FROM LOGIC_CEH
)

, RENAME_CEC as (
    SELECT
        PRODUCT_COST_ESTIMATE_HK
      , ITEM_BK
      , PLANT_BK
      , POPER
      , BDATJ
      , COSTING_VARIANT_BK
      , BKCC
      , REC_SRC
      , LOAD_DTS
    FROM LOGIC_CEC
)
---- FILTER LAYER ----

, FILTER_CEH as (
    SELECT *
    FROM RENAME_CEH
)

, FILTER_CEC as (
    SELECT *
    FROM RENAME_CEC
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_CEH
    UNION
    SELECT * FROM FILTER_CEC
)

---- FINAL LAYER ----
SELECT
          PRODUCT_COST_ESTIMATE_HK
        , ITEM_BK
        , PLANT_BK
        , POPER
        , BDATJ
        , COSTING_VARIANT_BK
        , BKCC
        , REC_SRC
        , LOAD_DTS
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.PRODUCT_COST_ESTIMATE_HK = JOIN_RESULT.PRODUCT_COST_ESTIMATE_HK
)
{% endif %}

QUALIFY ROW_NUMBER() OVER(PARTITION BY PRODUCT_COST_ESTIMATE_HK ORDER BY LOAD_DTS DESC)=1
{% if not is_incremental() %}
-- Hub
union all

SELECT MD5_BINARY(GR.VALUE)  PRODUCT_COST_ESTIMATE_HK
, GR.VALUE  AS ITEM_BK
, GR.VALUE  AS PLANT_BK
, GR.VALUE AS POPER
, GR.VALUE AS BDATJ
, GR.VALUE AS COSTING_VARIANT_BK
, DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS BKCC
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP_LTZ)  AS LOAD_DTS
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}