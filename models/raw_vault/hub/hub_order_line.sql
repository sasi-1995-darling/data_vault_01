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

SRC_VBAP           as ( SELECT BKCC, LOAD_DTS, ORDER_LINE_BK, ORDER_LINE_HK, REC_SRC FROM {{ ref('v_psa_stg_order_item__winn_sap') }} as SRC
                        {% if is_incremental() %}
                        LEFT JOIN INCR_WATERMARK AS wm ON SRC.REC_SRC = wm.wm_REC_SRC
                        WHERE (wm.watermark_dts IS NULL OR SRC.LOAD_DTS >= wm.watermark_dts)
                        {% endif %}
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY ORDER_LINE_BK ORDER BY GLCHANGETIME ))=1 ),
SRC_OLMLEBS        as ( SELECT BKCC, LOAD_DTS, ORDER_LINE_BK, ORDER_LINE_HK, REC_SRC FROM {{ ref('v_psa_stg_order_line__ml_ebs') }} as SRC 
                        {% if is_incremental() %}
                        LEFT JOIN INCR_WATERMARK AS wm ON SRC.REC_SRC = wm.wm_REC_SRC
                        WHERE (wm.watermark_dts IS NULL OR SRC.LOAD_DTS >= wm.watermark_dts)
                        {% endif %}
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY LINE_ID ORDER BY _FIVETRAN_SYNCED  ))=1 ),
SRC_ILMLEBS        as ( SELECT BKCC, LOAD_DTS, ORDER_LINE_BK, ORDER_LINE_HK, REC_SRC FROM {{ ref('v_psa_stg_invoice_line__ml_ebs') }} as SRC
                        {% if is_incremental() %}
                        LEFT JOIN INCR_WATERMARK AS wm ON SRC.REC_SRC = wm.wm_REC_SRC
                        WHERE (wm.watermark_dts IS NULL OR SRC.LOAD_DTS >= wm.watermark_dts)
                        {% endif %}
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY INTERFACE_LINE_ATTRIBUTE6 ORDER BY _FIVETRAN_SYNCED ))=1 ),
SRC_VBUP           as ( SELECT BKCC, LOAD_DTS, ORDER_LINE_BK, ORDER_LINE_HK, REC_SRC FROM {{ ref('v_psa_stg_order_line_status__winn_sap') }} as SRC 
                        {% if is_incremental() %}
                        LEFT JOIN INCR_WATERMARK AS wm ON SRC.REC_SRC = wm.wm_REC_SRC
                        WHERE (wm.watermark_dts IS NULL OR SRC.LOAD_DTS >= wm.watermark_dts)
                        {% endif %} ),
SRC_CE1NEW4        as ( SELECT BKCC, LOAD_DTS, ORDER_LINE_BK, ORDER_LINE_HK, REC_SRC FROM {{ ref('v_psa_stg_copa_sales__winn_sap') }} as SRC 
                        {% if is_incremental() %}
                        LEFT JOIN INCR_WATERMARK AS wm ON SRC.REC_SRC = wm.wm_REC_SRC
                        WHERE (wm.watermark_dts IS NULL OR SRC.LOAD_DTS >= wm.watermark_dts)
                        {% endif %}
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY ORDER_LINE_BK ORDER BY GLCHANGETIME  ))=1 ),
SRC_AZCOPA         as ( {% if not is_incremental() %} SELECT BKCC, LOAD_DTS, ORDER_LINE_BK, ORDER_LINE_HK, REC_SRC FROM {{ ref('v_psa_stg_copa_sales_history__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY KAUFN, KDPOS ORDER BY ZEXTRACTDATE  ))=1  
                        {% else %}
                        SELECT BKCC, LOAD_DTS, ORDER_LINE_BK, ORDER_LINE_HK, REC_SRC FROM {{ this }} WHERE FALSE 
                        {% endif %} 
                        /*To improve efficiency and performance; scan and load historical SAP BW AZCOPA table only on initial run */ ), 
SRC_ZSERVLEVEL     as ( SELECT BKCC, LOAD_DTS, ORDER_LINE_BK, ORDER_LINE_HK, REC_SRC FROM {{ ref('v_psa_stg_service_levels__winn_sap') }} as SRC 
                        {% if is_incremental() %}
                        LEFT JOIN INCR_WATERMARK AS wm ON SRC.REC_SRC = wm.wm_REC_SRC
                        WHERE (wm.watermark_dts IS NULL OR SRC.LOAD_DTS >= wm.watermark_dts)
                        {% endif %}
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY ORDER_LINE_BK ORDER BY GLCHANGETIME  ))=1 ),
SRC_RESERVATION    as ( SELECT BKCC, LOAD_DTS, ORDER_LINE_BK, ORDER_LINE_HK, REC_SRC FROM {{ ref('v_psa_stg_reservation_line__winn_sap') }} as SRC
                        {% if is_incremental() %}
                        LEFT JOIN INCR_WATERMARK AS wm ON SRC.REC_SRC = wm.wm_REC_SRC
                        WHERE (wm.watermark_dts IS NULL OR SRC.LOAD_DTS >= wm.watermark_dts)
                        {% endif %}
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY hash(KDAUF, KDPOS) ORDER BY GLCHANGETIME ))=1 ),
SRC_INVENTORY      as ( SELECT BKCC, LOAD_DTS, ORDER_LINE_BK, ORDER_LINE_HK, REC_SRC FROM {{ ref('v_psa_stg_goods_movement__winn_sap') }} as SRC 
                        {% if is_incremental() %}
                        LEFT JOIN INCR_WATERMARK AS wm ON SRC.REC_SRC = wm.wm_REC_SRC
                        WHERE (wm.watermark_dts IS NULL OR SRC.LOAD_DTS >= wm.watermark_dts)
                        {% endif %}
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY KDAUF, KDPOS ORDER BY GLCHANGETIME ))=1 ),
SRC_SHOPORDLN      as ( SELECT BKCC, LOAD_DTS, ORDER_LINE_BK, ORDER_LINE_HK, REC_SRC FROM {{ ref('v_psa_stg_dtc_order_line__winn_shopify') }} as SRC
                        {% if is_incremental() %}
                        LEFT JOIN INCR_WATERMARK AS wm ON SRC.REC_SRC = wm.wm_REC_SRC
                        WHERE (wm.watermark_dts IS NULL OR SRC.LOAD_DTS >= wm.watermark_dts)
                        {% endif %}  ),
SRC_VOD            as ( SELECT BKCC, LOAD_DTS, ORDER_LINE_BK, ORDER_LINE_HK, REC_SRC FROM {{ ref('v_psa_stg_vendor_order_details__amazon') }} as SRC 
                        {% if is_incremental() %}
                        LEFT JOIN INCR_WATERMARK AS wm ON SRC.REC_SRC = wm.wm_REC_SRC
                        WHERE (wm.watermark_dts IS NULL OR SRC.LOAD_DTS >= wm.watermark_dts)
                        {% endif %}
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY ORDER_LINE_BK ORDER BY _FIVETRAN_SYNCED  ))=1 ),
SRC_VBEP           as ( SELECT BKCC, LOAD_DTS, ORDER_LINE_BK, ORDER_LINE_HK, REC_SRC FROM {{ ref('v_psa_stg_sales_order_item_scheduled_shipping__winn_sap') }} as SRC 
                        {% if is_incremental() %}
                        LEFT JOIN INCR_WATERMARK AS wm ON SRC.REC_SRC = wm.wm_REC_SRC
                        WHERE (wm.watermark_dts IS NULL OR SRC.LOAD_DTS >= wm.watermark_dts)
                        {% endif %}
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY VBELN, POSNR ORDER BY GLCHANGETIME ))=1 ),
SRC_LIPS           as ( SELECT BKCC, LOAD_DTS, ORDER_LINE_BK, ORDER_LINE_HK, REC_SRC FROM {{ ref('v_psa_stg_delivery_line_detail__winn_sap') }} as SRC 
                        {% if is_incremental() %}
                        LEFT JOIN INCR_WATERMARK AS wm ON SRC.REC_SRC = wm.wm_REC_SRC
                        WHERE (wm.watermark_dts IS NULL OR SRC.LOAD_DTS >= wm.watermark_dts)
                        {% endif %}
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY VGBEL, VGPOS ORDER BY GLCHANGETIME  ))=1 ),
SRC_OHTTE21        as ( SELECT BKCC, LOAD_DTS, ORDER_LINE_BK, ORDER_LINE_HK, REC_SRC FROM {{ref('v_psa_stg_order_line__tt_e21') }}  as  SRC 
                        {% if is_incremental() %}
                        LEFT JOIN INCR_WATERMARK AS wm ON SRC.REC_SRC = wm.wm_REC_SRC
                        WHERE (wm.watermark_dts IS NULL OR SRC.LOAD_DTS >= wm.watermark_dts)
                        {% endif %}),
SRC_BD        as ( SELECT BKCC, LOAD_DTS, ORDER_LINE_BK, ORDER_LINE_HK, REC_SRC FROM {{ref('v_psa_stg_business_data__winn_sap') }}  as  SRC 
                        {% if is_incremental() %}
                        LEFT JOIN INCR_WATERMARK AS wm ON SRC.REC_SRC = wm.wm_REC_SRC
                        WHERE (wm.watermark_dts IS NULL OR SRC.LOAD_DTS >= wm.watermark_dts)
                        {% endif %}
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY ORDER_LINE_BK ORDER BY GLCHANGETIME))=1 )

---- FINAL LAYER ----
-- Dedup all unioned sources first (runs on both incremental and initial load) to prevent multiple loads of touched records during the initial build, such as multiple rows per BKs and BKCC
, JOIN_RESULT as (
SELECT
          ORDER_LINE_HK
        , ORDER_LINE_BK
        , BKCC
        , LOAD_DTS
        , REC_SRC
FROM (
    /*This Jinja logic to intelligently bypass unnecessary full downstream refreshes */
    {% if target.name not in ['default', 'dev'] %}
    SELECT * FROM SRC_VBAP
    UNION ALL
    SELECT * FROM SRC_OLMLEBS
    UNION ALL
    SELECT * FROM SRC_ILMLEBS
    UNION ALL
    SELECT * FROM SRC_VBUP
    UNION ALL
    SELECT * FROM SRC_CE1NEW4
    UNION ALL
    SELECT * FROM SRC_AZCOPA
    UNION ALL
    SELECT * FROM SRC_ZSERVLEVEL
    UNION ALL
    SELECT * FROM SRC_RESERVATION
    UNION ALL
    SELECT * FROM SRC_INVENTORY
    UNION ALL
    SELECT * FROM SRC_SHOPORDLN
    UNION ALL
    SELECT * FROM SRC_VOD
    UNION ALL
    {% endif %}
    SELECT * FROM SRC_VBEP
    UNION ALL
    SELECT * FROM SRC_LIPS
    UNION ALL
    SELECT * FROM SRC_OHTTE21
    UNION ALL
    SELECT * FROM SRC_BD
) AS UNIONED_SRC

QUALIFY 1 = ROW_NUMBER() OVER (PARTITION BY ORDER_LINE_BK, BKCC ORDER BY LOAD_DTS)
)

SELECT * FROM JOIN_RESULT

{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.ORDER_LINE_HK = JOIN_RESULT.ORDER_LINE_HK
)
{% else %}

UNION ALL
SELECT 
MD5_BINARY(GR.VALUE) AS ORDER_LINE_HK,
GR.VALUE::text AS ORDER_LINE_BK,
DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
