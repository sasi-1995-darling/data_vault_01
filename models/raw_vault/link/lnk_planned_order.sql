---- SRC LAYER ----
WITH
SRC_plnsap         as ( SELECT * FROM {{ ref('v_psa_stg_planned_order__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY LNK_PLANNED_ORDER_HK ORDER BY LOAD_DTS ))=1 ),
SRC_plnml          as ( SELECT * FROM {{ ref('v_psa_stg_planned_order__ml_ascp') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY LNK_PLANNED_ORDER_HK ORDER BY LOAD_DTS ))=1 )

/*
SRC_plnsap         as ( SELECT * FROM staging.v_psa_stg_planned_order__winn_sap )
, SRC_plnml          as ( SELECT * FROM staging.v_psa_stg_planned_order__ml_ascp )
*/
---- LOGIC LAYER ----

, LOGIC_plnsap as (
    SELECT
        LNK_PLANNED_ORDER_HK
      , PLANNED_ORDER_HK
      , SUPPLIER_HK
      , ITEM_HK
      , PLANT_HK
      , PURCHASING_ORG_HK
      , PURCHASING_RECORD_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_plnsap
)

, LOGIC_plnml as (
    SELECT
        LNK_PLANNED_ORDER_HK
      , PLANNED_ORDER_HK
      , SUPPLIER_HK
      , ITEM_HK
      , PLANT_HK
      , PURCHASING_ORG_HK
      , PURCHASING_RECORD_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_plnml
)
---- RENAME LAYER ----

, RENAME_plnsap as (
    SELECT
        LNK_PLANNED_ORDER_HK
      , PLANNED_ORDER_HK
      , SUPPLIER_HK
      , ITEM_HK
      , PLANT_HK
      , PURCHASING_ORG_HK
      , PURCHASING_RECORD_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_plnsap
)

, RENAME_plnml as (
    SELECT
        LNK_PLANNED_ORDER_HK
      , PLANNED_ORDER_HK
      , SUPPLIER_HK
      , ITEM_HK
      , PLANT_HK
      , PURCHASING_ORG_HK
      , PURCHASING_RECORD_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_plnml
)
---- FILTER LAYER ----

, FILTER_plnsap as (
    SELECT *
    FROM RENAME_plnsap
)

, FILTER_plnml as (
    SELECT *
    FROM RENAME_plnml
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_plnsap
    UNION ALL
    SELECT * FROM FILTER_plnml
)

---- FINAL LAYER ----
SELECT
          LNK_PLANNED_ORDER_HK
        , PLANNED_ORDER_HK
        , SUPPLIER_HK
        , ITEM_HK
        , PLANT_HK
        , PURCHASING_ORG_HK
        , PURCHASING_RECORD_HK
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.LNK_PLANNED_ORDER_HK = JOIN_RESULT.LNK_PLANNED_ORDER_HK
)
{% endif %}
{% if not is_incremental() %}

union all
SELECT 
MD5_BINARY(GR.VALUE) AS LNK_PLANNED_ORDER_HK,
MD5_BINARY(GR.VALUE) AS PLANNED_ORDER_HK,
MD5_BINARY(GR.VALUE) AS SUPPLIER_HK,
MD5_BINARY(GR.VALUE) AS ITEM_HK,
MD5_BINARY(GR.VALUE) AS PLANT_HK,
MD5_BINARY(GR.VALUE) AS PURCHASING_ORG_HK,
MD5_BINARY(GR.VALUE) AS PURCHASING_RECORD_HK,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
