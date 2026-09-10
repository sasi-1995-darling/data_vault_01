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

SRC_polml          as ( 
    SELECT 
        BKCC, 
        LOAD_DTS, 
        PO_ITEM_HK, 
        REC_SRC, 
        PO_HEADER_ID::TEXT as PO_HEADER_ID, 
        LINE_NUM
    FROM {{ ref('v_psa_stg_po_item__ml_ebs') }} as SRC 
    QUALIFY (ROW_NUMBER() OVER(PARTITION BY PO_ITEM_BK ORDER BY LOAD_DTS)) = 1 
),
SRC_polsap         as ( 
    SELECT 
        BKCC, 
        EBELN, 
        EBELP, 
        LOAD_DTS, 
        PO_ITEM_HK, 
        REC_SRC 
    FROM {{ ref('v_psa_stg_po_item__winn_sap') }} as SRC 
    {% if is_incremental() %}
    LEFT JOIN INCR_WATERMARK AS wm ON SRC.REC_SRC = wm.wm_REC_SRC
    WHERE (wm.watermark_dts IS NULL OR SRC.LOAD_DTS >= wm.watermark_dts)
    {% else %}
    QUALIFY (ROW_NUMBER() OVER(PARTITION BY PO_ITEM_BK ORDER BY LOAD_DTS)) = 1 
    {% endif %}
),
SRC_pollrsn        as ( 
    SELECT 
        BKCC, 
        LOAD_DTS, 
        PO_HEADER_BK, 
        PO_ITEM_HK, 
        REC_SRC, 
        LINE_NBR 
    FROM {{ ref('v_psa_stg_po_item__lrsn_psft') }} as SRC 
    {% if is_incremental() %}
    LEFT JOIN INCR_WATERMARK AS wm ON SRC.REC_SRC = wm.wm_REC_SRC
    WHERE (wm.watermark_dts IS NULL OR SRC.LOAD_DTS >= wm.watermark_dts)
    {% else %}
    QUALIFY (ROW_NUMBER() OVER(PARTITION BY hash(BUSINESS_UNIT, PO_ID, LINE_NBR) ORDER BY _FIVETRAN_SYNCED)) = 1 
    {% endif %}
),
SRC_poschlrsn      as ( 
    SELECT 
        BKCC, 
        LOAD_DTS, 
        PO_HEADER_BK, 
        PO_ITEM_HK, 
        REC_SRC, 
        LINE_NBR 
    FROM {{ ref('v_psa_stg_po_item_schedule_lines__lrsn_psft') }} as SRC 
    {% if is_incremental() %}
    LEFT JOIN INCR_WATERMARK AS wm ON SRC.REC_SRC = wm.wm_REC_SRC
    WHERE (wm.watermark_dts IS NULL OR SRC.LOAD_DTS >= wm.watermark_dts)
    {% else %}
    QUALIFY (ROW_NUMBER() OVER(PARTITION BY hash(BUSINESS_UNIT, PO_ID, LINE_NBR)  ORDER BY _FIVETRAN_SYNCED)) = 1 
    {% endif %}
),
SRC_poltte21       as ( 
    SELECT 
        BKCC, 
        LOAD_DTS, 
        PO_HEADER_BK, 
        PO_ITEM_HK, 
        REC_SRC, 
        ITEM_NO
    FROM {{ ref('v_psa_stg_po_item__tt_e21') }} as SRC 
    {% if is_incremental() %}
    LEFT JOIN INCR_WATERMARK AS wm ON SRC.REC_SRC = wm.wm_REC_SRC
    WHERE (wm.watermark_dts IS NULL OR SRC.LOAD_DTS >= wm.watermark_dts)
    {% else %}
    QUALIFY (ROW_NUMBER() OVER(PARTITION BY PO_ITEM_BK ORDER BY LOAD_DTS)) = 1 
    {% endif %}
),
SRC_polttgp        as ( 
    SELECT 
        BKCC, 
        LOAD_DTS, 
        PO_HEADER_BK, 
        PO_ITEM_HK, 
        REC_SRC, 
        ORD
    FROM {{ ref('v_psa_stg_po_item__tt_gp') }} as SRC 
    QUALIFY (ROW_NUMBER() OVER(PARTITION BY PO_ITEM_BK ORDER BY LOAD_DTS)) = 1 
),
SRC_polemtk        as ( 
    SELECT 
        BKCC, 
        LOAD_DTS, 
        PO_HEADER_BK, 
        PO_ITEM_HK, 
        REC_SRC, 
        LINE_NUM
    FROM {{ ref('v_psa_stg_po_item__emtk_ebs') }} as SRC
    QUALIFY (ROW_NUMBER() OVER(PARTITION BY PO_ITEM_HK ORDER BY LOAD_DTS)) = 1 
),
SRC_reservation        as ( 
    SELECT 
        BKCC, 
        EBELN, 
        EBELP, 
        LOAD_DTS, 
        PO_ITEM_HK, 
        REC_SRC
    FROM {{ ref('v_psa_stg_reservation_line__winn_sap') }} as SRC
    {% if is_incremental() %}
    LEFT JOIN INCR_WATERMARK AS wm ON SRC.REC_SRC = wm.wm_REC_SRC
    WHERE (wm.watermark_dts IS NULL OR SRC.LOAD_DTS >= wm.watermark_dts)
    {% else %}
    QUALIFY (ROW_NUMBER() OVER(PARTITION BY hash(EBELN,EBELP) ORDER BY GLCHANGETIME)) = 1 
    {% endif %}
),

SRC_INVENTORY         as (
    SELECT 
        BKCC, 
        EBELN, 
        EBELP, 
        LOAD_DTS, 
        PO_ITEM_HK, 
        REC_SRC
    FROM {{ ref('v_psa_stg_goods_movement__winn_sap') }} as SRC
    {% if is_incremental() %}
    LEFT JOIN INCR_WATERMARK AS wm ON SRC.REC_SRC = wm.wm_REC_SRC
    WHERE (wm.watermark_dts IS NULL OR SRC.LOAD_DTS >= wm.watermark_dts)
    {% else %}
    QUALIFY (ROW_NUMBER() OVER(PARTITION BY PO_ITEM_BK ORDER BY LOAD_DTS)) = 1 
    {% endif %}
),

SRC_polfib         as ( 
    SELECT 
        BKCC, 
        LINE_NUM,
        LOAD_DTS, 
        PO_HEADER_BK, 
        PO_ITEM_HK, 
        REC_SRC 
    FROM {{ ref('v_psa_stg_po_item__fib_ocf') }} as SRC 
    QUALIFY (ROW_NUMBER() OVER(PARTITION BY PO_ITEM_HK ORDER BY LOAD_DTS)) = 1 
),
SRC_polschebs      as ( 
    SELECT 
        BKCC, 
        LOAD_DTS, 
        PO_HEADER_BK, 
        PO_ITEM_HK, 
        PO_ITEM_BK, 
        REC_SRC 
    FROM {{ ref('v_psa_stg_po_item_schedule_lines__ml_ebs') }} as SRC 
    QUALIFY (ROW_NUMBER() OVER(PARTITION BY PO_ITEM_HK ORDER BY LOAD_DTS)) = 1 
),
SRC_polschemtk     as ( 
    SELECT 
        BKCC, 
        LOAD_DTS, 
        PO_HEADER_BK, 
        PO_ITEM_HK, 
        PO_ITEM_BK, 
        REC_SRC 
    FROM {{ ref('v_psa_stg_po_item_schedule_lines__emtk_ebs') }} as SRC 
    QUALIFY (ROW_NUMBER() OVER(PARTITION BY PO_ITEM_HK ORDER BY LOAD_DTS)) = 1 
),
SRC_polschfib      as ( 
    SELECT 
        BKCC, 
        LOAD_DTS, 
        PO_HEADER_BK, 
        PO_ITEM_HK, 
        PO_ITEM_BK, 
        REC_SRC 
    FROM {{ ref('v_psa_stg_po_item_schedule_lines__fib_ocf') }} as SRC 
    QUALIFY (ROW_NUMBER() OVER(PARTITION BY PO_ITEM_HK ORDER BY LOAD_DTS)) = 1 
)

/*
SRC_polml          as ( SELECT * FROM staging.v_psa_stg_po_item__ml_ebs )
SRC_polsap         as ( SELECT * FROM staging.v_psa_stg_po_item__winn_sap )
SRC_pollrsn        as ( SELECT * FROM staging.v_psa_stg_po_item__lrsn_psft )
SRC_poschlrsn      as ( SELECT * FROM staging.v_psa_stg_po_item_schedule_lines__lrsn_psft )
SRC_poltte21       as ( SELECT * FROM staging.v_psa_stg_po_item__tt_e21 )
SRC_polttgp        as ( SELECT * FROM staging.v_psa_stg_po_item__tt_gp )
SRC_polemtk        as ( SELECT * FROM staging.v_psa_stg_po_item__emtk_ebs )
SRC_reservation    as ( SELECT * FROM STAGING.v_psa_stg_reservation_line__winn_sap )
SRC_INVENTORY      as ( SELECT * FROM staging.v_psa_stg_goods_movement__winn_sap )
SRC_polfib         as ( SELECT * FROM staging.v_psa_stg_po_item__fib_ocf )
SRC_polschebs      as ( SELECT * FROM staging.v_psa_stg_po_item_schedule_lines__ml_ebs )
*/
---- LOGIC LAYER ----

, LOGIC_polml as (
    SELECT
        PO_ITEM_HK
      , PO_HEADER_ID::TEXT                                           as                                       PO_HEADER_ID
      , LINE_NUM::TEXT                                               as                                     PO_LINE_NUMBER
      , LOAD_DTS
      , BKCC
      , REC_SRC
    FROM SRC_polml
)

, LOGIC_polsap as (
    SELECT
        PO_ITEM_HK
      , EBELN                                                        as                                       PO_HEADER_ID
      , EBELP                                                        as                                     PO_LINE_NUMBER
      , LOAD_DTS
      , BKCC
      , REC_SRC
    FROM SRC_polsap
)

, LOGIC_pollrsn as (
    SELECT
        PO_ITEM_HK
      , PO_HEADER_BK                                                 as                                       PO_HEADER_ID
      , LINE_NBR::TEXT                                               as                                     PO_LINE_NUMBER
      , LOAD_DTS
      , BKCC
      , REC_SRC
    FROM SRC_pollrsn
)

, LOGIC_poschlrsn as (
    SELECT
        PO_ITEM_HK
      , PO_HEADER_BK                                                 as                                       PO_HEADER_ID
      , LINE_NBR::TEXT                                               as                                     PO_LINE_NUMBER
      , LOAD_DTS
      , BKCC
      , REC_SRC
    FROM SRC_poschlrsn
)

, LOGIC_poltte21 as (
    SELECT
        PO_ITEM_HK
      , PO_HEADER_BK                                                 as                                       PO_HEADER_ID
      , ITEM_NO::TEXT                                                as                                     PO_LINE_NUMBER
      , LOAD_DTS
      , BKCC
      , REC_SRC
    FROM SRC_poltte21
)

, LOGIC_polttgp as (
    SELECT
        PO_ITEM_HK
      , PO_HEADER_BK                                                 as                                       PO_HEADER_ID
      , ORD::TEXT                                                    as                                     PO_LINE_NUMBER
      , LOAD_DTS
      , BKCC
      , REC_SRC
    FROM SRC_polttgp
)

, LOGIC_polemtk as (
    SELECT
        PO_ITEM_HK
      , PO_HEADER_BK                                                 as                                       PO_HEADER_ID
      , LINE_NUM::TEXT                                               as                                     PO_LINE_NUMBER
      , LOAD_DTS
      , BKCC
      , REC_SRC
    FROM SRC_polemtk
)

, LOGIC_reservation as (
    SELECT
        PO_ITEM_HK
      , EBELN                                                        as                                       PO_HEADER_ID
      , EBELP                                                        as                                     PO_LINE_NUMBER
      , LOAD_DTS
      , BKCC
      , REC_SRC
    FROM SRC_reservation
)
, LOGIC_INVENTORY as (
    SELECT
        PO_ITEM_HK
      , EBELN                                                        as                                       PO_HEADER_ID
      , EBELP                                                        as                                     PO_LINE_NUMBER
      , LOAD_DTS
      , BKCC
      , REC_SRC
    FROM SRC_INVENTORY
)

, LOGIC_polfib as (
    SELECT
        PO_ITEM_HK
      , PO_HEADER_BK                                                 as                                       PO_HEADER_ID
      , LINE_NUM::TEXT                                               as                                     PO_LINE_NUMBER
      , LOAD_DTS
      , BKCC
      , REC_SRC
    FROM SRC_polfib
)

, LOGIC_polschebs as (
    SELECT
        PO_ITEM_HK
      , PO_HEADER_BK                                                 as                                       PO_HEADER_ID
      , PO_ITEM_BK                                                   as                                     PO_LINE_NUMBER
      , LOAD_DTS
      , BKCC
      , REC_SRC
    FROM SRC_polschebs
)

, LOGIC_polschemtk as (
    SELECT
        PO_ITEM_HK
      , PO_HEADER_BK                                                 as                                       PO_HEADER_ID
      , PO_ITEM_BK                                                   as                                     PO_LINE_NUMBER
      , LOAD_DTS
      , BKCC
      , REC_SRC
    FROM SRC_polschemtk
)

, LOGIC_polschfib as (
    SELECT
        PO_ITEM_HK
      , PO_HEADER_BK                                                 as                                       PO_HEADER_ID
      , PO_ITEM_BK                                                   as                                     PO_LINE_NUMBER
      , LOAD_DTS
      , BKCC
      , REC_SRC
    FROM SRC_polschfib
)
---- RENAME LAYER ----

, RENAME_polml as (
    SELECT
        PO_ITEM_HK
      , PO_HEADER_ID
      , PO_LINE_NUMBER
      , LOAD_DTS
      , BKCC
      , REC_SRC
    FROM LOGIC_polml
)

, RENAME_polsap as (
    SELECT
        PO_ITEM_HK
      , PO_HEADER_ID
      , PO_LINE_NUMBER
      , LOAD_DTS
      , BKCC
      , REC_SRC
    FROM LOGIC_polsap
)

, RENAME_pollrsn as (
    SELECT
        PO_ITEM_HK
      , PO_HEADER_ID
      , PO_LINE_NUMBER
      , LOAD_DTS
      , BKCC
      , REC_SRC
    FROM LOGIC_pollrsn
)

, RENAME_poschlrsn as (
    SELECT
        PO_ITEM_HK
      , PO_HEADER_ID
      , PO_LINE_NUMBER
      , LOAD_DTS
      , BKCC
      , REC_SRC
    FROM LOGIC_poschlrsn
)

, RENAME_poltte21 as (
    SELECT
        PO_ITEM_HK
      , PO_HEADER_ID
      , PO_LINE_NUMBER
      , LOAD_DTS
      , BKCC
      , REC_SRC
    FROM LOGIC_poltte21
)

, RENAME_polttgp as (
    SELECT
        PO_ITEM_HK
      , PO_HEADER_ID
      , PO_LINE_NUMBER
      , LOAD_DTS
      , BKCC
      , REC_SRC
    FROM LOGIC_polttgp
)

, RENAME_polemtk as (
    SELECT
        PO_ITEM_HK
      , PO_HEADER_ID
      , PO_LINE_NUMBER
      , LOAD_DTS
      , BKCC
      , REC_SRC
    FROM LOGIC_polemtk
)

, RENAME_INVENTORY as (
    SELECT
        PO_ITEM_HK
      , PO_HEADER_ID
      , PO_LINE_NUMBER
      , LOAD_DTS
      , BKCC
      , REC_SRC
    FROM LOGIC_INVENTORY
)

, RENAME_reservation as (
    SELECT
        PO_ITEM_HK
      , PO_HEADER_ID
      , PO_LINE_NUMBER
      , LOAD_DTS
      , BKCC
      , REC_SRC
    FROM LOGIC_reservation
)

, RENAME_polfib as (
    SELECT
        PO_ITEM_HK
      , PO_HEADER_ID
      , PO_LINE_NUMBER
      , LOAD_DTS
      , BKCC
      , REC_SRC
    FROM LOGIC_polfib
)

, RENAME_polschebs as (
    SELECT
        PO_ITEM_HK
      , PO_HEADER_ID
      , PO_LINE_NUMBER
      , LOAD_DTS
      , BKCC
      , REC_SRC
    FROM LOGIC_polschebs
)

, RENAME_polschemtk as (
    SELECT
        PO_ITEM_HK
      , PO_HEADER_ID
      , PO_LINE_NUMBER
      , LOAD_DTS
      , BKCC
      , REC_SRC
    FROM LOGIC_polschemtk
)

, RENAME_polschfib as (
    SELECT
        PO_ITEM_HK
      , PO_HEADER_ID
      , PO_LINE_NUMBER
      , LOAD_DTS
      , BKCC
      , REC_SRC
    FROM LOGIC_polschfib
)
---- FILTER LAYER ----

, FILTER_polml as (
    SELECT *
    FROM RENAME_polml
)

, FILTER_polsap as (
    SELECT *
    FROM RENAME_polsap
)

, FILTER_pollrsn as (
    SELECT *
    FROM RENAME_pollrsn
)

, FILTER_poschlrsn as (
    SELECT *
    FROM RENAME_poschlrsn
)

, FILTER_poltte21 as (
    SELECT *
    FROM RENAME_poltte21
)

, FILTER_polttgp as (
    SELECT *
    FROM RENAME_polttgp
)

, FILTER_polemtk as (
    SELECT *
    FROM RENAME_polemtk
)

, FILTER_INVENTORY as (
    SELECT *
    FROM RENAME_INVENTORY
)

, FILTER_reservation as (
    SELECT *
    FROM RENAME_reservation
)

, FILTER_polfib as (
    SELECT *
    FROM RENAME_polfib
)

, FILTER_polschebs as (
    SELECT *
    FROM RENAME_polschebs
)

, FILTER_polschemtk as (
    SELECT *
    FROM RENAME_polschemtk
)

, FILTER_polschfib as (
    SELECT *
    FROM RENAME_polschfib
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_polml
    UNION ALL
    SELECT * FROM FILTER_polsap
    UNION ALL
    SELECT * FROM FILTER_pollrsn
    UNION ALL
    SELECT * FROM FILTER_poschlrsn
    UNION ALL
    SELECT * FROM FILTER_poltte21
    UNION ALL
    SELECT * FROM FILTER_polttgp
    UNION ALL
    SELECT * FROM FILTER_polemtk
    UNION ALL
    SELECT * FROM FILTER_reservation
    UNION ALL
    SELECT * FROM FILTER_INVENTORY
    UNION ALL
    SELECT * FROM FILTER_polfib
    UNION ALL
    SELECT * FROM FILTER_polschebs
    UNION ALL
    SELECT * FROM FILTER_polschemtk
    UNION ALL
    SELECT * FROM FILTER_polschfib
)

---- FINAL LAYER ----
SELECT
          PO_ITEM_HK
        , PO_HEADER_ID
        , PO_LINE_NUMBER
        , LOAD_DTS
        , BKCC
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.PO_ITEM_HK = JOIN_RESULT.PO_ITEM_HK
)
{% endif %}
qualify 1= row_number() over(partition by PO_ITEM_HK order by load_dts)
{% if not is_incremental() %}
union all
SELECT 
MD5_BINARY(GR.VALUE) AS PO_ITEM_HK
, GR.VALUE AS PO_HEADER_ID
, GR.VALUE AS PO_LINE_NUMBER
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)  AS LOAD_DTS
, DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS BKCC
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
