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
SRC_R              as ( SELECT BKCC, LOAD_DTS, REC_SRC, ROUTING_BK, ROUTING_HK FROM {{ ref('v_psa_stg_reservation_line__winn_sap') }} as SRC
                        {% if is_incremental() %}
                        LEFT JOIN INCR_WATERMARK AS wm ON SRC.REC_SRC = wm.wm_REC_SRC
                        WHERE (wm.watermark_dts IS NULL OR SRC.LOAD_DTS >= wm.watermark_dts)
                        {% endif %}
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY AUFPL ORDER BY GLCHANGETIME ))=1 ),
SRC_PROD_ORDER     as ( SELECT BKCC, LOAD_DTS, REC_SRC, ROUTING_NUMBER_OPERATIONS_HK, ROUTING_NUMBER_OPERATIONS_BK, PRODUCTION_ORDER_ROUTING_NUMBER_HK, PRODUCTION_ORDER_ROUTING_NUMBER_BK FROM {{ ref('v_psa_stg_production_order_header__winn_sap') }} as SRC
                        {% if is_incremental() %}
                        LEFT JOIN INCR_WATERMARK AS wm ON SRC.REC_SRC = wm.wm_REC_SRC
                        WHERE (wm.watermark_dts IS NULL OR SRC.LOAD_DTS >= wm.watermark_dts)
                        {% endif %}
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY ROUTING_NUMBER_OPERATIONS_HK, PRODUCTION_ORDER_ROUTING_NUMBER_HK ORDER BY LOAD_DTS ))=1 ),
SRC_ORDER_CONFIRMATION as ( SELECT BKCC, LOAD_DTS, REC_SRC, ROUTING_HK, ROUTING_BK FROM {{ ref('v_psa_stg_order_confirmation__winn_sap') }} as SRC
                        {% if is_incremental() %}
                        LEFT JOIN INCR_WATERMARK AS wm ON SRC.REC_SRC = wm.wm_REC_SRC
                        WHERE (wm.watermark_dts IS NULL OR SRC.LOAD_DTS >= wm.watermark_dts)
                        {% endif %}
                            QUALIFY (ROW_NUMBER() OVER(PARTITION BY AUFPL ORDER BY GLCHANGETIME ))=1 )

/*
SRC_R              as ( SELECT * FROM STAGING.V_PSA_STG_RESERVATION_LINE__WINN_SAP )
*/


---- UNION ALL SOURCES ----

, ALL_SOURCES AS (
    -- Source 1: Reservation Line
    SELECT ROUTING_HK, ROUTING_BK, BKCC, LOAD_DTS, REC_SRC
    FROM SRC_R

    UNION ALL

    -- Source 2: Production Order Header (Routing Number Operations)
    SELECT
        ROUTING_NUMBER_OPERATIONS_HK  AS ROUTING_HK,
        ROUTING_NUMBER_OPERATIONS_BK  AS ROUTING_BK,
        BKCC,
        LOAD_DTS,
        REC_SRC
    FROM SRC_PROD_ORDER

    UNION ALL

    -- Source 3: Production Order Header (Production Order Routing Number — derived)
    SELECT
        PRODUCTION_ORDER_ROUTING_NUMBER_HK  AS ROUTING_HK,
        PRODUCTION_ORDER_ROUTING_NUMBER_BK  AS ROUTING_BK,
        BKCC,
        LOAD_DTS,
        REC_SRC
    FROM SRC_PROD_ORDER

    UNION ALL

    -- Source 4: Order Confirmation
    SELECT ROUTING_HK, ROUTING_BK, BKCC, LOAD_DTS, REC_SRC
    FROM SRC_ORDER_CONFIRMATION
)

---- FINAL LAYER ----
SELECT
    ROUTING_HK,
    ROUTING_BK,
    BKCC,
    LOAD_DTS,
    REC_SRC
FROM ALL_SOURCES
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1
    FROM {{ this }} AS existing
    WHERE existing.ROUTING_HK = ALL_SOURCES.ROUTING_HK
)
{% endif %}
QUALIFY ROW_NUMBER() OVER (PARTITION BY ROUTING_BK, BKCC ORDER BY BKCC) = 1

{% if not is_incremental() %}

union all
SELECT 
MD5_BINARY(GR.VALUE) AS ROUTING_HK,
GR.VALUE::text AS ROUTING_BK,
DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}