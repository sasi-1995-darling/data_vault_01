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
SRC_h AS (
    SELECT
        BKCC,
        LOAD_DTS,
        PRODUCTION_ORDER_BK,
        PRODUCTION_ORDER_HK,
        LEAD_PRODUCTION_ORDER_HK,
        LEAD_PRODUCTION_ORDER_BK,
        REC_SRC
    FROM {{ ref('v_psa_stg_production_order_header__winn_sap') }} AS SRC
    {% if is_incremental() %}
    LEFT JOIN INCR_WATERMARK AS wm ON SRC.REC_SRC = wm.wm_REC_SRC
    WHERE (wm.watermark_dts IS NULL OR SRC.LOAD_DTS >= wm.watermark_dts)
    {% endif %}
    QUALIFY ROW_NUMBER() OVER (PARTITION BY AUFNR ORDER BY GLCHANGETIME) = 1
),

SRC_l AS (
    SELECT
        BKCC,
        LOAD_DTS,
        PRODUCTION_ORDER_BK,
        PRODUCTION_ORDER_HK,
        REC_SRC
    FROM {{ ref('v_psa_stg_production_order_line__winn_sap') }} AS SRC
    {% if is_incremental() %}
    LEFT JOIN INCR_WATERMARK AS wm ON SRC.REC_SRC = wm.wm_REC_SRC
    WHERE (wm.watermark_dts IS NULL OR SRC.LOAD_DTS >= wm.watermark_dts)
    {% endif %}
    QUALIFY ROW_NUMBER() OVER (PARTITION BY AUFNR ORDER BY GLCHANGETIME) = 1
),

SRC_INVENTORY AS (
    SELECT
        BKCC,
        LOAD_DTS,
        PRODUCTION_ORDER_BK,
        PRODUCTION_ORDER_HK,
        REC_SRC
    FROM {{ ref('v_psa_stg_goods_movement__winn_sap') }} AS SRC
    {% if is_incremental() %}
    LEFT JOIN INCR_WATERMARK AS wm ON SRC.REC_SRC = wm.wm_REC_SRC
    WHERE (wm.watermark_dts IS NULL OR SRC.LOAD_DTS >= wm.watermark_dts)
    {% endif %}
    -- QUALIFY ROW_NUMBER() OVER (PARTITION BY AUFNR ORDER BY GLCHANGETIME) = 1
),

SRC_RESERVATION AS (
    SELECT
        BKCC,
        LOAD_DTS,
        PRODUCTION_ORDER_BK,
        PRODUCTION_ORDER_HK,
        REC_SRC
    FROM {{ ref('v_psa_stg_reservation_line__winn_sap') }} AS SRC
    {% if is_incremental() %}
    LEFT JOIN INCR_WATERMARK AS wm ON SRC.REC_SRC = wm.wm_REC_SRC
    WHERE (wm.watermark_dts IS NULL OR SRC.LOAD_DTS >= wm.watermark_dts)
    {% endif %}
    -- QUALIFY ROW_NUMBER() OVER (PARTITION BY AUFNR ORDER BY GLCHANGETIME) = 1
),

SRC_ORDER_CONFIRMATION AS (
    SELECT
        BKCC,
        LOAD_DTS,
        PRODUCTION_ORDER_BK,
        PRODUCTION_ORDER_HK,
        REC_SRC
    FROM {{ ref('v_psa_stg_order_confirmation__winn_sap') }} AS SRC
    {% if is_incremental() %}
    LEFT JOIN INCR_WATERMARK AS wm ON SRC.REC_SRC = wm.wm_REC_SRC
    WHERE (wm.watermark_dts IS NULL OR SRC.LOAD_DTS >= wm.watermark_dts)
    {% endif %}
    QUALIFY ROW_NUMBER() OVER (PARTITION BY AUFNR ORDER BY GLCHANGETIME) = 1
),

---- UNION ALL SOURCES ----

ALL_SOURCES AS (
    SELECT PRODUCTION_ORDER_HK, PRODUCTION_ORDER_BK, BKCC, LOAD_DTS, REC_SRC
    FROM SRC_h
    UNION ALL
    SELECT PRODUCTION_ORDER_HK, PRODUCTION_ORDER_BK, BKCC, LOAD_DTS, REC_SRC
    FROM SRC_l
    UNION ALL
    SELECT PRODUCTION_ORDER_HK, PRODUCTION_ORDER_BK, BKCC, LOAD_DTS, REC_SRC
    FROM SRC_INVENTORY
    UNION ALL
    SELECT PRODUCTION_ORDER_HK, PRODUCTION_ORDER_BK, BKCC, LOAD_DTS, REC_SRC
    FROM SRC_RESERVATION
    UNION ALL
    SELECT PRODUCTION_ORDER_HK, PRODUCTION_ORDER_BK, BKCC, LOAD_DTS, REC_SRC
    FROM SRC_ORDER_CONFIRMATION
    UNION ALL
    SELECT LEAD_PRODUCTION_ORDER_HK, LEAD_PRODUCTION_ORDER_BK, BKCC, LOAD_DTS, REC_SRC
    FROM SRC_h
)

---- FINAL LAYER ----
SELECT
    PRODUCTION_ORDER_HK,
    PRODUCTION_ORDER_BK,
    BKCC,
    LOAD_DTS,
    REC_SRC
FROM ALL_SOURCES
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1
    FROM {{ this }} AS existing
    WHERE existing.PRODUCTION_ORDER_HK = ALL_SOURCES.PRODUCTION_ORDER_HK
)
{% endif %}
QUALIFY ROW_NUMBER() OVER (PARTITION BY PRODUCTION_ORDER_BK, BKCC ORDER BY BKCC) = 1

{% if not is_incremental() %}

union all
SELECT 
MD5_BINARY(GR.VALUE) AS PRODUCTION_ORDER_HK,
GR.VALUE::text AS PRODUCTION_ORDER_BK,
DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}