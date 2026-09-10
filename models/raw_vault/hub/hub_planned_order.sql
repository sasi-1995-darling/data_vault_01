---- SRC LAYER ----
WITH
SRC_plnsap         as ( SELECT * FROM {{ ref('v_psa_stg_planned_order__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PLANNED_ORDER_HK ORDER BY LOAD_DTS ))=1 ),
SRC_plnml          as ( SELECT * FROM {{ ref('v_psa_stg_planned_order__ml_ascp') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PLANNED_ORDER_HK ORDER BY LOAD_DTS ))=1 ),
SRC_reservation    as ( SELECT * FROM {{ ref('v_psa_stg_reservation_line__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PLANNED_ORDER_BK ORDER BY LOAD_DTS ))=1 )

/*
SRC_plnsap         as ( SELECT * FROM staging.v_psa_stg_planned_order__winn_sap )
SRC_reservation    as ( SELECT * FROM STAGING.v_psa_stg_reservation_line__winn_sap )
, SRC_plnml          as ( SELECT * FROM staging.v_psa_stg_planned_order__ml_ascp )
*/
---- LOGIC LAYER ----

, LOGIC_plnsap as (
    SELECT
        PLANNED_ORDER_HK
      , PLANNED_ORDER_BK
      , LOAD_DTS
      , BKCC
      , REC_SRC
    FROM SRC_plnsap
)

, LOGIC_plnml as (
    SELECT
        PLANNED_ORDER_HK
      , PLANNED_ORDER_BK::TEXT                                       as                                   PLANNED_ORDER_BK
      , LOAD_DTS
      , BKCC
      , REC_SRC
    FROM SRC_plnml
)

, LOGIC_reservation as (
    SELECT
        PLANNED_ORDER_HK
      , PLANNED_ORDER_BK
      , LOAD_DTS
      , BKCC
      , REC_SRC
    FROM SRC_reservation
)
---- RENAME LAYER ----

, RENAME_plnsap as (
    SELECT
        PLANNED_ORDER_HK
      , PLANNED_ORDER_BK
      , LOAD_DTS
      , BKCC
      , REC_SRC
    FROM LOGIC_plnsap
)

, RENAME_plnml as (
    SELECT
        PLANNED_ORDER_HK
      , PLANNED_ORDER_BK
      , LOAD_DTS
      , BKCC
      , REC_SRC
    FROM LOGIC_plnml
)

, RENAME_reservation as (
    SELECT
        PLANNED_ORDER_HK
      , PLANNED_ORDER_BK
      , LOAD_DTS
      , BKCC
      , REC_SRC
    FROM LOGIC_reservation
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

, FILTER_reservation as (
    SELECT *
    FROM RENAME_reservation
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_plnsap
    UNION ALL
    SELECT * FROM FILTER_plnml
    UNION ALL
    SELECT * FROM FILTER_reservation
)

---- FINAL LAYER ----
SELECT
          PLANNED_ORDER_HK
        , PLANNED_ORDER_BK
        , LOAD_DTS
        , BKCC
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.PLANNED_ORDER_HK = JOIN_RESULT.PLANNED_ORDER_HK
)
{% endif %}
QUALIFY 1= ROW_NUMBER() OVER (PARTITION BY PLANNED_ORDER_HK ORDER BY LOAD_DTS)
{% if not is_incremental() %}

union all
SELECT 
MD5_BINARY(GR.VALUE) AS PLANNED_ORDER_HK,
GR.VALUE::text AS PLANNED_ORDER_BK,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
