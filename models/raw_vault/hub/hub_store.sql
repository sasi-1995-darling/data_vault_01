{{
    config(
        full_refresh = var('force_full_refresh', false),
        tags = ['materialization_override', 'large_volume', 'hub']
    )
}}

{%- if is_incremental() %}
WITH INCR_WATERMARK AS (
    SELECT
        REC_SRC                             as wm_REC_SRC,
        DATEADD(DAY, -1, MAX(LOAD_DTS))     AS watermark_dts
    FROM {{ this }}
    GROUP BY REC_SRC
),
{%- else %}
WITH
{%- endif %}
SRC_SHD            as ( SELECT BKCC, LOAD_DTS, REC_SRC, STORE_BK, STORE_HK FROM {{ ref('v_psa_stg_sales_homedepot') }} as SRC
                        {% if is_incremental() %}
                        LEFT JOIN INCR_WATERMARK AS wm ON SRC.REC_SRC = wm.wm_REC_SRC
                        WHERE (wm.watermark_dts IS NULL OR SRC.LOAD_DTS >= wm.watermark_dts)
                        {% endif %}
                        QUALIFY ROW_NUMBER() OVER(PARTITION BY STORE_BK, BKCC ORDER BY LOAD_DTS) = 1 ),
SRC_STSM           as ( SELECT BKCC, LOAD_DTS, REC_SRC, STORE_BK, STORE_HK FROM {{ ref('v_psa_stg_sales_inventory__tsm_lowes') }} as SRC
                        {% if is_incremental() %}
                        LEFT JOIN INCR_WATERMARK AS wm ON SRC.REC_SRC = wm.wm_REC_SRC
                        WHERE (wm.watermark_dts IS NULL OR SRC.LOAD_DTS >= wm.watermark_dts)
                        {% endif %}
                        QUALIFY ROW_NUMBER() OVER(PARTITION BY STORE_BK, BKCC ORDER BY LOAD_DTS) = 1 ),
SRC_SILH           as ( SELECT BKCC, LOAD_DTS, REC_SRC, STORE_BK, STORE_HK FROM {{ ref('v_psa_stg_sales_inventory_moen_history__lowes') }} as SRC
                        {% if is_incremental() %}
                        LEFT JOIN INCR_WATERMARK AS wm ON SRC.REC_SRC = wm.wm_REC_SRC
                        WHERE (wm.watermark_dts IS NULL OR SRC.LOAD_DTS >= wm.watermark_dts)
                        {% endif %}
                        QUALIFY ROW_NUMBER() OVER(PARTITION BY STORE_BK, BKCC ORDER BY LOAD_DTS) = 1 ),
SRC_SIML           as ( SELECT BKCC, LOAD_DTS, REC_SRC, STORE_BK, STORE_HK FROM {{ ref('v_psa_stg_sales_inventory__masterlock_lowes') }} as SRC
                        {% if is_incremental() %}
                        LEFT JOIN INCR_WATERMARK AS wm ON SRC.REC_SRC = wm.wm_REC_SRC
                        WHERE (wm.watermark_dts IS NULL OR SRC.LOAD_DTS >= wm.watermark_dts)
                        {% endif %}
                        QUALIFY ROW_NUMBER() OVER(PARTITION BY STORE_BK, BKCC ORDER BY LOAD_DTS) = 1 ),
SRC_SIM            as ( SELECT BKCC, LOAD_DTS, REC_SRC, STORE_BK, STORE_HK FROM {{ ref('v_psa_stg_sales_inventory__moen_lowes') }} as SRC
                        {% if is_incremental() %}
                        LEFT JOIN INCR_WATERMARK AS wm ON SRC.REC_SRC = wm.wm_REC_SRC
                        WHERE (wm.watermark_dts IS NULL OR SRC.LOAD_DTS >= wm.watermark_dts)
                        {% endif %}
                        QUALIFY ROW_NUMBER() OVER(PARTITION BY STORE_BK, BKCC ORDER BY LOAD_DTS) = 1 ),
SRC_SLL            as ( SELECT BKCC, LOAD_DTS, REC_SRC, STORE_BK, STORE_HK FROM {{ ref('v_psa_stg_store__lowes') }} as SRC
                        {% if is_incremental() %}
                        LEFT JOIN INCR_WATERMARK AS wm ON SRC.REC_SRC = wm.wm_REC_SRC
                        WHERE (wm.watermark_dts IS NULL OR SRC.LOAD_DTS >= wm.watermark_dts)
                        {% endif %}
                        QUALIFY ROW_NUMBER() OVER(PARTITION BY STORE_BK, BKCC ORDER BY LOAD_DTS) = 1 ),
SRC_SLH            as ( SELECT BKCC, LOAD_DTS, REC_SRC, STORE_BK, STORE_HK FROM {{ ref('v_psa_stg_store__homedepot') }} as SRC
                        {% if is_incremental() %}
                        LEFT JOIN INCR_WATERMARK AS wm ON SRC.REC_SRC = wm.wm_REC_SRC
                        WHERE (wm.watermark_dts IS NULL OR SRC.LOAD_DTS >= wm.watermark_dts)
                        {% endif %}
                        QUALIFY ROW_NUMBER() OVER(PARTITION BY STORE_BK, BKCC ORDER BY LOAD_DTS) = 1 ),
SRC_SLM            as ( SELECT BKCC, LOAD_DTS, REC_SRC, STORE_BK, STORE_HK FROM {{ ref('v_psa_stg_store_location_lookup__menards') }} as SRC
                        {% if is_incremental() %}
                        LEFT JOIN INCR_WATERMARK AS wm ON SRC.REC_SRC = wm.wm_REC_SRC
                        WHERE (wm.watermark_dts IS NULL OR SRC.LOAD_DTS >= wm.watermark_dts)
                        {% endif %}
                        QUALIFY ROW_NUMBER() OVER(PARTITION BY STORE_BK, BKCC ORDER BY LOAD_DTS) = 1 ),
SRC_SLML           as ( SELECT BKCC, LOAD_DTS, REC_SRC, STORE_BK, STORE_HK FROM {{ ref('v_psa_stg_sales_inventory__larson_menards') }} as SRC
                        {% if is_incremental() %}
                        LEFT JOIN INCR_WATERMARK AS wm ON SRC.REC_SRC = wm.wm_REC_SRC
                        WHERE (wm.watermark_dts IS NULL OR SRC.LOAD_DTS >= wm.watermark_dts)
                        {% endif %}
                        QUALIFY ROW_NUMBER() OVER(PARTITION BY STORE_BK, BKCC ORDER BY LOAD_DTS) = 1 ),
SRC_SLM1           as ( SELECT BKCC, LOAD_DTS, REC_SRC, STORE_BK, STORE_HK FROM {{ ref('v_psa_stg_sales_inventory_history__moen_menards') }} as SRC
                        {% if is_incremental() %}
                        LEFT JOIN INCR_WATERMARK AS wm ON SRC.REC_SRC = wm.wm_REC_SRC
                        WHERE (wm.watermark_dts IS NULL OR SRC.LOAD_DTS >= wm.watermark_dts)
                        {% endif %}
                        QUALIFY ROW_NUMBER() OVER(PARTITION BY STORE_BK, BKCC ORDER BY LOAD_DTS) = 1 ),
SRC_SLT            as ( SELECT BKCC, LOAD_DTS, REC_SRC, STORE_BK, STORE_HK FROM {{ ref('v_psa_stg_sales_inventory__thermatru_lowes') }} as SRC
                        {% if is_incremental() %}
                        LEFT JOIN INCR_WATERMARK AS wm ON SRC.REC_SRC = wm.wm_REC_SRC
                        WHERE (wm.watermark_dts IS NULL OR SRC.LOAD_DTS >= wm.watermark_dts)
                        {% endif %}
                        QUALIFY ROW_NUMBER() OVER(PARTITION BY STORE_BK, BKCC ORDER BY LOAD_DTS) = 1 ),
SRC_SLMW           as ( SELECT BKCC, LOAD_DTS, REC_SRC, STORE_BK, STORE_HK FROM {{ ref('v_psa_stg_sales_inventory_weekly__moen_menards') }} as SRC
                        {% if is_incremental() %}
                        LEFT JOIN INCR_WATERMARK AS wm ON SRC.REC_SRC = wm.wm_REC_SRC
                        WHERE (wm.watermark_dts IS NULL OR SRC.LOAD_DTS >= wm.watermark_dts)
                        {% endif %}
                        QUALIFY ROW_NUMBER() OVER(PARTITION BY STORE_BK, BKCC ORDER BY LOAD_DTS) = 1 ),
SRC_SSA            as ( SELECT BKCC, LOAD_DTS, REC_SRC, STORE_BK, STORE_HK FROM {{ ref('v_psa_stg_sales__amazon') }} as SRC
                        {% if is_incremental() %}
                        LEFT JOIN INCR_WATERMARK AS wm ON SRC.REC_SRC = wm.wm_REC_SRC
                        WHERE (wm.watermark_dts IS NULL OR SRC.LOAD_DTS >= wm.watermark_dts)
                        {% endif %}
                        QUALIFY ROW_NUMBER() OVER(PARTITION BY STORE_BK, BKCC ORDER BY LOAD_DTS) = 1 ),
SRC_SPGWHD         as ( SELECT BKCC, LOAD_DTS, REC_SRC, STORE_BK, STORE_HK FROM {{ ref('v_psa_stg_pog_weekly__homedepot') }} as SRC
                        {% if is_incremental() %}
                        LEFT JOIN INCR_WATERMARK AS wm ON SRC.REC_SRC = wm.wm_REC_SRC
                        WHERE (wm.watermark_dts IS NULL OR SRC.LOAD_DTS >= wm.watermark_dts)
                        {% endif %}
                        QUALIFY ROW_NUMBER() OVER(PARTITION BY STORE_BK, BKCC ORDER BY LOAD_DTS) = 1 ),
SRC_SILL           as ( SELECT BKCC, LOAD_DTS, REC_SRC, STORE_BK, STORE_HK FROM {{ ref('v_psa_stg_sales_inventory__larson_lowes') }} as SRC
                        {% if is_incremental() %}
                        LEFT JOIN INCR_WATERMARK AS wm ON SRC.REC_SRC = wm.wm_REC_SRC
                        WHERE (wm.watermark_dts IS NULL OR SRC.LOAD_DTS >= wm.watermark_dts)
                        {% endif %}
                        QUALIFY ROW_NUMBER() OVER(PARTITION BY STORE_BK, BKCC ORDER BY LOAD_DTS) = 1 ),
SRC_SSF            as ( SELECT BKCC, LOAD_DTS, REC_SRC, STORE_BK, STORE_HK FROM {{ ref('v_psa_stg_store__ferguson') }} as SRC
                        {% if is_incremental() %}
                        LEFT JOIN INCR_WATERMARK AS wm ON SRC.REC_SRC = wm.wm_REC_SRC
                        WHERE (wm.watermark_dts IS NULL OR SRC.LOAD_DTS >= wm.watermark_dts)
                        {% endif %}
                        QUALIFY ROW_NUMBER() OVER(PARTITION BY STORE_BK, BKCC ORDER BY LOAD_DTS) = 1 ),
SRC_SSLF           as ( SELECT BKCC, LOAD_DTS, REC_SRC, STORE_BK, STORE_HK FROM {{ ref('v_psa_stg_sales__moen_ferguson_new') }} as SRC
                        {% if is_incremental() %}
                        LEFT JOIN INCR_WATERMARK AS wm ON SRC.REC_SRC = wm.wm_REC_SRC
                        WHERE (wm.watermark_dts IS NULL OR SRC.LOAD_DTS >= wm.watermark_dts)
                        {% endif %}
                        QUALIFY ROW_NUMBER() OVER(PARTITION BY STORE_BK, BKCC ORDER BY LOAD_DTS) = 1 ),
SRC_SSLFC          as ( SELECT BKCC, LOAD_DTS, REC_SRC, STORE_BK, STORE_HK FROM {{ ref('v_psa_stg_sales__moen_cfg_ferguson_new') }} as SRC
                        {% if is_incremental() %}
                        LEFT JOIN INCR_WATERMARK AS wm ON SRC.REC_SRC = wm.wm_REC_SRC
                        WHERE (wm.watermark_dts IS NULL OR SRC.LOAD_DTS >= wm.watermark_dts)
                        {% endif %}
                        QUALIFY ROW_NUMBER() OVER(PARTITION BY STORE_BK, BKCC ORDER BY LOAD_DTS) = 1 ),
SRC_SSLFGR         as ( SELECT BKCC, LOAD_DTS, REC_SRC, STORE_BK, STORE_HK FROM {{ ref('v_psa_stg_pos_gross_sales_history_ref__moen_ferguson_new') }} as SRC
                        {% if is_incremental() %}
                        LEFT JOIN INCR_WATERMARK AS wm ON SRC.REC_SRC = wm.wm_REC_SRC
                        WHERE (wm.watermark_dts IS NULL OR SRC.LOAD_DTS >= wm.watermark_dts)
                        {% endif %}
                        QUALIFY ROW_NUMBER() OVER(PARTITION BY STORE_BK, BKCC ORDER BY LOAD_DTS) = 1 ),
SRC_SSPGLW         as ( SELECT BKCC, LOAD_DTS, REC_SRC, STORE_BK, STORE_HK FROM {{ ref('v_psa_stg_pog_weekly__lowes_vpp') }} as SRC
                        {% if is_incremental() %}
                        LEFT JOIN INCR_WATERMARK AS wm ON SRC.REC_SRC = wm.wm_REC_SRC
                        WHERE (wm.watermark_dts IS NULL OR SRC.LOAD_DTS >= wm.watermark_dts)
                        {% endif %}
                        QUALIFY ROW_NUMBER() OVER(PARTITION BY STORE_BK, BKCC ORDER BY LOAD_DTS) = 1 ),
SRC_SIMLAPI        as ( SELECT BKCC, LOAD_DTS, REC_SRC, STORE_BK, STORE_HK FROM {{ ref('v_psa_stg_sales_inventory__masterlock_lowes_ft_api') }} as SRC
                        {% if is_incremental() %}
                        LEFT JOIN INCR_WATERMARK AS wm ON SRC.REC_SRC = wm.wm_REC_SRC
                        WHERE (wm.watermark_dts IS NULL OR SRC.LOAD_DTS >= wm.watermark_dts)
                        {% endif %}
                        QUALIFY ROW_NUMBER() OVER(PARTITION BY STORE_BK, BKCC ORDER BY LOAD_DTS) = 1 ),
SRC_SILLAPI        as ( SELECT BKCC, LOAD_DTS, REC_SRC, STORE_BK, STORE_HK FROM {{ ref('v_psa_stg_sales_inventory__larson_lowes_ft_api') }} as SRC
                        {% if is_incremental() %}
                        LEFT JOIN INCR_WATERMARK AS wm ON SRC.REC_SRC = wm.wm_REC_SRC
                        WHERE (wm.watermark_dts IS NULL OR SRC.LOAD_DTS >= wm.watermark_dts)
                        {% endif %}
                        QUALIFY ROW_NUMBER() OVER(PARTITION BY STORE_BK, BKCC ORDER BY LOAD_DTS) = 1 ),
SRC_SIMAPI         as ( SELECT BKCC, LOAD_DTS, REC_SRC, STORE_BK, STORE_HK FROM {{ ref('v_psa_stg_sales_inventory__moen_lowes_ft_api') }} as SRC
                        {% if is_incremental() %}
                        LEFT JOIN INCR_WATERMARK AS wm ON SRC.REC_SRC = wm.wm_REC_SRC
                        WHERE (wm.watermark_dts IS NULL OR SRC.LOAD_DTS >= wm.watermark_dts)
                        {% endif %}
                        QUALIFY ROW_NUMBER() OVER(PARTITION BY STORE_BK, BKCC ORDER BY LOAD_DTS) = 1 ),
SRC_SLTAPI         as ( SELECT BKCC, LOAD_DTS, REC_SRC, STORE_BK, STORE_HK FROM {{ ref('v_psa_stg_sales_inventory__thermatru_lowes_ft_api') }} as SRC
                        {% if is_incremental() %}
                        LEFT JOIN INCR_WATERMARK AS wm ON SRC.REC_SRC = wm.wm_REC_SRC
                        WHERE (wm.watermark_dts IS NULL OR SRC.LOAD_DTS >= wm.watermark_dts)
                        {% endif %}
                        QUALIFY ROW_NUMBER() OVER(PARTITION BY STORE_BK, BKCC ORDER BY LOAD_DTS) = 1 ),
SRC_SSAF           as ( SELECT BKCC, LOAD_DTS, REC_SRC, STORE_BK, STORE_HK FROM {{ ref('v_psa_stg_sales_tmlc__amazon_fivetran') }} as SRC
                        {% if is_incremental() %}
                        LEFT JOIN INCR_WATERMARK AS wm ON SRC.REC_SRC = wm.wm_REC_SRC
                        WHERE (wm.watermark_dts IS NULL OR SRC.LOAD_DTS >= wm.watermark_dts)
                        {% endif %}
                        QUALIFY ROW_NUMBER() OVER(PARTITION BY STORE_BK, BKCC ORDER BY LOAD_DTS) = 1 ),
SRC_SLHFT          as ( SELECT BKCC, LOAD_DTS, REC_SRC, STORE_BK, STORE_HK FROM {{ ref('v_psa_stg_store__homedepot_ft') }} as SRC
                        {% if is_incremental() %}
                        LEFT JOIN INCR_WATERMARK AS wm ON SRC.REC_SRC = wm.wm_REC_SRC
                        WHERE (wm.watermark_dts IS NULL OR SRC.LOAD_DTS >= wm.watermark_dts)
                        {% endif %}
                        QUALIFY ROW_NUMBER() OVER(PARTITION BY STORE_BK, BKCC ORDER BY LOAD_DTS) = 1 ),
SRC_SDCIWHDF       as ( SELECT BKCC, LOAD_DTS, REC_SRC, STORE_BK, STORE_HK FROM {{ ref('v_psa_stg_dc_inventory_with_store__homedepot_ft') }} as SRC
                        {% if is_incremental() %}
                        LEFT JOIN INCR_WATERMARK AS wm ON SRC.REC_SRC = wm.wm_REC_SRC
                        WHERE (wm.watermark_dts IS NULL OR SRC.LOAD_DTS >= wm.watermark_dts)
                        {% endif %}
                        QUALIFY ROW_NUMBER() OVER(PARTITION BY STORE_BK, BKCC ORDER BY LOAD_DTS) = 1 )
/*
SRC_SHD            as ( SELECT * FROM STAGING.v_psa_stg_sales_homedepot )
SRC_STSM           as ( SELECT * FROM STAGING.v_psa_stg_sales_inventory__tsm_lowes )
SRC_SILH           as ( SELECT * FROM STAGING.v_psa_stg_sales_inventory_moen_history__lowes )
SRC_SIML           as ( SELECT * FROM STAGING.v_psa_stg_sales_inventory__masterlock_lowes )
SRC_SIM            as ( SELECT * FROM STAGING.v_psa_stg_sales_inventory__moen_lowes )
SRC_SLL            as ( SELECT * FROM STAGING.v_psa_stg_store__lowes )
SRC_SLH            as ( SELECT * FROM STAGING.v_psa_stg_store__homedepot )
SRC_SLM            as ( SELECT * FROM STAGING.v_psa_stg_store_location_lookup__menards )
SRC_SLML           as ( SELECT * FROM STAGING.v_psa_stg_sales_inventory__larson_menards )
SRC_SLM1           as ( SELECT * FROM STAGING.v_psa_stg_sales_inventory_history__moen_menards )
SRC_SLT            as ( SELECT * FROM STAGING.v_psa_stg_sales_inventory__thermatru_lowes )
SRC_SLMW           as ( SELECT * FROM STAGING.v_psa_stg_sales_inventory_weekly__moen_menards )
SRC_SSA            as ( SELECT * FROM STAGING.v_psa_stg_sales__amazon )
SRC_SPGWHD         as ( SELECT * FROM STAGING.v_psa_stg_pog_weekly__homedepot )
SRC_SILL           as ( SELECT * FROM STAGING.v_psa_stg_sales_inventory__larson_lowes )
SRC_SSF            as ( SELECT * FROM STAGING.v_psa_stg_store__ferguson )
SRC_SSLF           as ( SELECT * FROM STAGING.v_psa_stg_sales__moen_ferguson_new )
SRC_SSLFC          as ( SELECT * FROM STAGING.v_psa_stg_sales__moen_cfg_ferguson_new )
SRC_SSLFGR         as ( SELECT * FROM STAGING.v_psa_stg_pos_gross_sales_history_ref__moen_ferguson_new )
SRC_SSPGLW         as ( SELECT * FROM STAGING.v_psa_stg_pog_weekly__lowes_vpp )
SRC_SIMLAPI        as ( SELECT * FROM STAGING.v_psa_stg_sales_inventory__masterlock_lowes_ft_api )
SRC_SILLAPI        as ( SELECT * FROM STAGING.v_psa_stg_sales_inventory__larson_lowes_ft_api )
SRC_SIMAPI         as ( SELECT * FROM STAGING.v_psa_stg_sales_inventory__moen_lowes_ft_api )
SRC_SLTAPI         as ( SELECT * FROM STAGING.v_psa_stg_sales_inventory__thermatru_lowes_ft_api )
SRC_SSAF           as ( SELECT * FROM STAGING.v_psa_stg_sales_tmlc__amazon_fivetran )
*/
---- JOIN LAYER ----
-- Dedup all unioned sources first to prevent multiple rows per BK+BKCC
, JOIN_RESULT as (
    SELECT
          STORE_HK
        , STORE_BK
        , BKCC
        , LOAD_DTS
        , REC_SRC
    FROM (
        SELECT * FROM SRC_SHD
        UNION ALL
        SELECT * FROM SRC_STSM
        UNION ALL
        SELECT * FROM SRC_SILH
        UNION ALL
        SELECT * FROM SRC_SIML
        UNION ALL
        SELECT * FROM SRC_SIM
        UNION ALL
        SELECT * FROM SRC_SLL
        UNION ALL
        SELECT * FROM SRC_SLH
        UNION ALL
        SELECT * FROM SRC_SLM
        UNION ALL
        SELECT * FROM SRC_SLML
        UNION ALL
        SELECT * FROM SRC_SLM1
        UNION ALL
        SELECT * FROM SRC_SLT
        UNION ALL
        SELECT * FROM SRC_SLMW
        UNION ALL
        SELECT * FROM SRC_SSA
        UNION ALL
        SELECT * FROM SRC_SPGWHD
        UNION ALL
        SELECT * FROM SRC_SILL
        UNION ALL
        SELECT * FROM SRC_SSF
        UNION ALL
        SELECT * FROM SRC_SSLF
        UNION ALL
        SELECT * FROM SRC_SSLFC
        UNION ALL
        SELECT * FROM SRC_SSLFGR
        UNION ALL
        SELECT * FROM SRC_SSPGLW
        UNION ALL
        SELECT * FROM SRC_SIMLAPI
        UNION ALL
        SELECT * FROM SRC_SILLAPI
        UNION ALL
        SELECT * FROM SRC_SIMAPI
        UNION ALL
        SELECT * FROM SRC_SLTAPI
        UNION ALL
        SELECT * FROM SRC_SSAF
        UNION ALL
        SELECT * FROM SRC_SLHFT
        UNION ALL
        SELECT * FROM SRC_SDCIWHDF
    ) AS UNIONED_SRC
    QUALIFY 1 = ROW_NUMBER() OVER (PARTITION BY STORE_BK, BKCC ORDER BY LOAD_DTS)
)

---- FINAL LAYER ----
SELECT * FROM JOIN_RESULT

{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1
    FROM {{ this }} existing
    WHERE existing.STORE_HK = JOIN_RESULT.STORE_HK
)
{% else %}

UNION ALL

SELECT MD5_BINARY(GR.VALUE::varchar)  STORE_HK
, GR.VALUE::varchar  AS STORE_BK
, DECODE(GR.VALUE::varchar, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS BKCC
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)  AS LOAD_DTS
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
