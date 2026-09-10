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

SRC_ml             as ( SELECT BKCC, LOAD_DTS, PO_HEADER_BK, PO_HEADER_HK, REC_SRC FROM {{ ref('v_psa_stg_po_header__ml_ebs') }} as SRC 
                        {% if is_incremental() %}
                        LEFT JOIN INCR_WATERMARK AS wm ON SRC.REC_SRC = wm.wm_REC_SRC
                        WHERE (wm.watermark_dts IS NULL OR SRC.LOAD_DTS >= wm.watermark_dts)
                        {% else %}
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PO_HEADER_HK ORDER BY LOAD_DTS ))=1 
                        {% endif %}
                        ),
SRC_sap            as ( SELECT BKCC, LOAD_DTS, PO_HEADER_BK, PO_HEADER_HK, REC_SRC FROM {{ ref('v_psa_stg_po_header__winn_sap') }} as SRC 
                        {% if is_incremental() %}
                        LEFT JOIN INCR_WATERMARK AS wm ON SRC.REC_SRC = wm.wm_REC_SRC
                        WHERE (wm.watermark_dts IS NULL OR SRC.LOAD_DTS >= wm.watermark_dts)
                        {% else %}
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PO_HEADER_HK ORDER BY LOAD_DTS ))=1 
                        {% endif %}
                        ),
SRC_psft           as ( SELECT BKCC, LOAD_DTS, PO_HEADER_BK, PO_HEADER_HK, REC_SRC FROM {{ ref('v_psa_stg_po_header__lrsn_psft') }} as SRC 
                        {% if is_incremental() %}
                        LEFT JOIN INCR_WATERMARK AS wm ON SRC.REC_SRC = wm.wm_REC_SRC
                        WHERE (wm.watermark_dts IS NULL OR SRC.LOAD_DTS >= wm.watermark_dts)
                        {% else %}
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY hash(BUSINESS_UNIT, PO_ID) ORDER BY PSA_LOAD_DTS ))=1 
                        {% endif %}
                        ),
SRC_porsap         as ( SELECT BKCC, LOAD_DTS, PO_HEADER_BK, PO_HEADER_HK, REC_SRC FROM {{ ref('v_psa_stg_po_receipt__winn_sap') }} as SRC 
                        {% if is_incremental() %}
                        LEFT JOIN INCR_WATERMARK AS wm ON SRC.REC_SRC = wm.wm_REC_SRC
                        WHERE (wm.watermark_dts IS NULL OR SRC.LOAD_DTS >= wm.watermark_dts)
                        {% else %}
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY hash(EBELN) ORDER BY PSA_LOAD_DTS ))=1 
                        {% endif %}
                        ),
SRC_tte21          as ( SELECT BKCC, LOAD_DTS, PO_HEADER_BK, PO_HEADER_HK, REC_SRC FROM {{ ref('v_psa_stg_po_header__tt_e21') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PO_HEADER_HK ORDER BY LOAD_DTS ))=1 ),
SRC_ttgp           as ( SELECT BKCC, LOAD_DTS, PO_HEADER_BK, PO_HEADER_HK, REC_SRC FROM {{ ref('v_psa_stg_po_header__tt_gp') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PO_HEADER_HK ORDER BY LOAD_DTS ))=1 ),
SRC_ttemtk         as ( SELECT BKCC, LOAD_DTS, PO_HEADER_BK, PO_HEADER_HK, REC_SRC FROM {{ ref('v_psa_stg_po_header__emtk_ebs') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PO_HEADER_HK ORDER BY LOAD_DTS ))=1 ),
SRC_reservation    as ( SELECT BKCC, LOAD_DTS, PO_HEADER_BK, PO_HEADER_HK, REC_SRC FROM {{ ref('v_psa_stg_reservation_line__winn_sap') }} as SRC 
                        {% if is_incremental() %}
                        LEFT JOIN INCR_WATERMARK AS wm ON SRC.REC_SRC = wm.wm_REC_SRC
                        WHERE (wm.watermark_dts IS NULL OR SRC.LOAD_DTS >= wm.watermark_dts)
                        {% else %}
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY hash(KDAUF, KDPOS) ORDER BY GLCHANGETIME ))=1 
                        {% endif %}
                         ),
SRC_pofib          as ( SELECT BKCC, LOAD_DTS, PO_HEADER_BK, PO_HEADER_HK, REC_SRC FROM {{ ref('v_psa_stg_po_header__fib_ocf') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PO_HEADER_HK ORDER BY LOAD_DTS ))=1 )

/*
SRC_ml             as ( SELECT * FROM STAGING.v_psa_stg_po_header__ml_ebs )
SRC_sap            as ( SELECT * FROM STAGING.v_psa_stg_po_header__winn_sap )
SRC_psft           as ( SELECT * FROM STAGING.v_psa_stg_po_header__lrsn_psft )
SRC_porsap         as ( SELECT * FROM STAGING.v_psa_stg_po_receipt__winn_sap )
SRC_tte21          as ( SELECT * FROM STAGING.v_psa_stg_po_header__tt_e21 )
SRC_ttgp           as ( SELECT * FROM STAGING.v_psa_stg_po_header__tt_gp )
SRC_ttemtk         as ( SELECT * FROM STAGING.v_psa_stg_po_header__emtk_ebs )
SRC_reservation    as ( SELECT * FROM STAGING.v_psa_stg_reservation_line__winn_sap )
SRC_pofib          as ( SELECT * FROM STAGING.v_psa_stg_po_header__fib_ocf )
*/
---- LOGIC LAYER ----

, LOGIC_ml as (
    SELECT
        PO_HEADER_HK
      , PO_HEADER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_ml
)

, LOGIC_sap as (
    SELECT
        PO_HEADER_HK
      , PO_HEADER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_sap
)

, LOGIC_psft as (
    SELECT
        PO_HEADER_HK
      , PO_HEADER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_psft
)

, LOGIC_porsap as (
    SELECT
        PO_HEADER_HK
      , PO_HEADER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_porsap
)

, LOGIC_tte21 as (
    SELECT
        PO_HEADER_HK
      , PO_HEADER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_tte21
)

, LOGIC_ttgp as (
    SELECT
        PO_HEADER_HK
      , PO_HEADER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_ttgp
)

, LOGIC_ttemtk as (
    SELECT
        PO_HEADER_HK
      , PO_HEADER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_ttemtk
)

, LOGIC_reservation as (
    SELECT
        PO_HEADER_HK
      , PO_HEADER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_reservation
)

, LOGIC_pofib as (
    SELECT
        PO_HEADER_HK
      , PO_HEADER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_pofib
)
---- RENAME LAYER ----

, RENAME_ml as (
    SELECT
        PO_HEADER_HK
      , PO_HEADER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_ml
)

, RENAME_sap as (
    SELECT
        PO_HEADER_HK
      , PO_HEADER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_sap
)

, RENAME_psft as (
    SELECT
        PO_HEADER_HK
      , PO_HEADER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_psft
)

, RENAME_porsap as (
    SELECT
        PO_HEADER_HK
      , PO_HEADER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_porsap
)

, RENAME_tte21 as (
    SELECT
        PO_HEADER_HK
      , PO_HEADER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_tte21
)

, RENAME_ttgp as (
    SELECT
        PO_HEADER_HK
      , PO_HEADER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_ttgp
)

, RENAME_ttemtk as (
    SELECT
        PO_HEADER_HK
      , PO_HEADER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_ttemtk
)

, RENAME_reservation as (
    SELECT
        PO_HEADER_HK
      , PO_HEADER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_reservation
)

, RENAME_pofib as (
    SELECT
        PO_HEADER_HK
      , PO_HEADER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_pofib
)
---- FILTER LAYER ----

, FILTER_ml as (
    SELECT *
    FROM RENAME_ml
)

, FILTER_sap as (
    SELECT *
    FROM RENAME_sap
)

, FILTER_psft as (
    SELECT *
    FROM RENAME_psft
)

, FILTER_porsap as (
    SELECT *
    FROM RENAME_porsap
)

, FILTER_tte21 as (
    SELECT *
    FROM RENAME_tte21
)

, FILTER_ttgp as (
    SELECT *
    FROM RENAME_ttgp
)

, FILTER_ttemtk as (
    SELECT *
    FROM RENAME_ttemtk
)

, FILTER_reservation as (
    SELECT *
    FROM RENAME_reservation
)

, FILTER_pofib as (
    SELECT *
    FROM RENAME_pofib
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_ml
    UNION ALL
    SELECT * FROM FILTER_sap
    UNION ALL
    SELECT * FROM FILTER_psft
    UNION ALL
    SELECT * FROM FILTER_porsap
    UNION ALL
    SELECT * FROM FILTER_tte21
    UNION ALL
    SELECT * FROM FILTER_ttgp
    UNION ALL
    SELECT * FROM FILTER_ttemtk
    UNION ALL
    SELECT * FROM FILTER_reservation
    UNION ALL
    SELECT * FROM FILTER_pofib
)

---- FINAL LAYER ----
SELECT
          PO_HEADER_HK
        , PO_HEADER_BK
        , BKCC
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.PO_HEADER_HK = JOIN_RESULT.PO_HEADER_HK
)
{% endif %}

qualify 1 = row_number() over(partition by PO_HEADER_BK, BKCC order by DECODE(REC_SRC, 'USOHNO.SAP.ECCPRD.Z_EKKO', 1, 'USOHNO.SAP.ECCPRD.Z_RESB', 10, 2) )
{% if not is_incremental() %}
union all
SELECT 
MD5_BINARY(GR.VALUE)  AS PO_HEADER_HK
, GR.VALUE AS PO_HEADER_BK
, DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS BKCC
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)  AS LOAD_DTS
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}