{{
  config(
    full_refresh = var('force_full_refresh', false),
    tags = ['materialization_override', 'large_volume', 'hub']
  )
}}

{% if is_incremental() %}
---- INCREMENTAL WATERMARK ----
-- Compute per-REC_SRC watermark ONCE and reuse across all source CTEs.
WITH INCR_WATERMARK AS (
    SELECT
        REC_SRC as wm_REC_SRC,
        DATEADD(DAY, -1, MAX(LOAD_DTS)) AS watermark_dts
    FROM {{ this }}
    GROUP BY REC_SRC
),
{% else %}
WITH
{% endif %}

---- SRC LAYER ----

SRC_pursap         as ( SELECT * FROM {{ ref('v_psa_stg_purchase_requisition__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PURCHASE_REQUISITION_HK ORDER BY LOAD_DTS ))=1 ),
SRC_purml          as ( SELECT * FROM {{ ref('v_psa_stg_purchase_requisition__ml_ascp') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PURCHASE_REQUISITION_HK ORDER BY LOAD_DTS ))=1 ),
SRC_reservation    as ( SELECT * FROM {{ ref('v_psa_stg_reservation_line__winn_sap') }} as SRC 
                        {% if is_incremental() %}
                        LEFT JOIN INCR_WATERMARK AS wm ON SRC.REC_SRC = wm.wm_REC_SRC
                        WHERE (wm.watermark_dts IS NULL OR SRC.LOAD_DTS >= wm.watermark_dts)
                        {% else %}
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY BANFN ORDER BY GLCHANGETIME ))=1 
                        {% endif %}
                        )

/*
SRC_pursap         as ( SELECT * FROM staging.v_psa_stg_purchase_requisition__winn_sap )
SRC_reservation    as ( SELECT * FROM STAGING.v_psa_stg_reservation_line__winn_sap )
, SRC_purml          as ( SELECT * FROM staging.v_psa_stg_purchase_requisition__ml_ascp )
*/
---- LOGIC LAYER ----

, LOGIC_pursap as (
    SELECT
        PURCHASE_REQUISITION_HK
      , PURCHASE_REQUISITION_BK
      , LOAD_DTS
      , BKCC
      , REC_SRC
    FROM SRC_pursap
)

, LOGIC_purml as (
    SELECT
        PURCHASE_REQUISITION_HK
      , PURCHASE_REQUISITION_BK
      , LOAD_DTS
      , BKCC
      , REC_SRC
    FROM SRC_purml
)

, LOGIC_reservation as (
    SELECT
        PURCHASE_REQUISITION_HK
      , PURCHASE_REQUISITION_BK
      , LOAD_DTS
      , BKCC
      , REC_SRC
    FROM SRC_reservation
)
---- RENAME LAYER ----

, RENAME_pursap as (
    SELECT
        PURCHASE_REQUISITION_HK
      , PURCHASE_REQUISITION_BK
      , LOAD_DTS
      , BKCC
      , REC_SRC
    FROM LOGIC_pursap
)

, RENAME_purml as (
    SELECT
        PURCHASE_REQUISITION_HK
      , PURCHASE_REQUISITION_BK
      , LOAD_DTS
      , BKCC
      , REC_SRC
    FROM LOGIC_purml
)

, RENAME_reservation as (
    SELECT
        PURCHASE_REQUISITION_HK
      , PURCHASE_REQUISITION_BK
      , LOAD_DTS
      , BKCC
      , REC_SRC
    FROM LOGIC_reservation
)
---- FILTER LAYER ----

, FILTER_pursap as (
    SELECT *
    FROM RENAME_pursap
)

, FILTER_purml as (
    SELECT *
    FROM RENAME_purml
)

, FILTER_reservation as (
    SELECT *
    FROM RENAME_reservation
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_pursap
    UNION ALL
    SELECT * FROM FILTER_purml
    UNION ALL
    SELECT * FROM FILTER_reservation
)

---- FINAL LAYER ----
SELECT
          PURCHASE_REQUISITION_HK
        , PURCHASE_REQUISITION_BK
        , LOAD_DTS
        , BKCC
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.PURCHASE_REQUISITION_HK = JOIN_RESULT.PURCHASE_REQUISITION_HK
)
{% endif %}
QUALIFY 1= ROW_NUMBER() OVER (PARTITION BY PURCHASE_REQUISITION_BK, BKCC ORDER BY LOAD_DTS)
{% if not is_incremental() %}

union all
SELECT 
MD5_BINARY(GR.VALUE) AS PURCHASE_REQUISITION_HK,
GR.VALUE::text AS PURCHASE_REQUISITION_BK,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
