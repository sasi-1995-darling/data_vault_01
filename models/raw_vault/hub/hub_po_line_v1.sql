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

SRC_R              as ( SELECT BKCC, LOAD_DTS, PO_LINE_BK, PO_LINE_HK, REC_SRC FROM {{ ref('v_psa_stg_reservation_line__winn_sap') }} as SRC 
                        {% if is_incremental() %}
                        LEFT JOIN INCR_WATERMARK AS wm ON SRC.REC_SRC = wm.wm_REC_SRC
                        WHERE (wm.watermark_dts IS NULL OR SRC.LOAD_DTS >= wm.watermark_dts)
                        {% endif %}
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY HASH(EBELN, EBELP, EBELE) ORDER BY GLCHANGETIME ))=1 )

---- FINAL LAYER ----
SELECT
    PO_LINE_HK,
    PO_LINE_BK,
    BKCC,
    LOAD_DTS,
    REC_SRC
FROM SRC_R
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1
    FROM {{ this }} AS existing
    WHERE existing.PO_LINE_HK = SRC_R.PO_LINE_HK
)
{% endif %}

{% if not is_incremental() %}

union all
SELECT 
MD5_BINARY(GR.VALUE) AS PO_LINE_HK,
GR.VALUE::text AS PO_LINE_BK,
DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}