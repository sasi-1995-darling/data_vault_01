---- SRC LAYER ----
WITH
SRC_a              as ( SELECT * FROM {{ ref('v_psa_stg_order_line_status__winn_sap') }} as SRC 
                        {% if is_incremental() %}
                        WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}}){% endif %} )

/*
SRC_a              as ( SELECT * FROM STAGING.V_PSA_STG_ORDER_LINE_STATUS__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_a as (
    SELECT
        ORDER_LINE_HK
      , MANDT
      , VBELN
      , POSNR
      , GLREQUEST
      , RFSTA
      , RFGSA
      , BESTA
      , LFSTA
      , LFGSA
      , WBSTA
      , FKSTA
      , FKSAA
      , ABSTA
      , GBSTA
      , KOSTA
      , LVSTA
      , UVALL
      , UVVLK
      , UVFAK
      , UVPRS
      , FKIVP
      , UVP01
      , UVP02
      , UVP03
      , UVP04
      , UVP05
      , PKSTA
      , KOQUA
      , COSTA
      , CMPPI
      , CMPPJ
      , UVPIK
      , UVPAK
      , UVWAK
      , DCSTA
      , RRSTA
      , VLSTP
      , FSSTA
      , LSSTA
      , PDSTA
      , MANEK
      , HDALL
      , LTSPS
      , FSH_AR_STAT_ITM
      , MILL_VS_VSSTA
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , HASHDIFF
      , BKCC
    FROM SRC_a
)
---- RENAME LAYER ----

, RENAME_a as (
    SELECT
        ORDER_LINE_HK
      , MANDT
      , VBELN
      , POSNR
      , GLREQUEST
      , RFSTA
      , RFGSA
      , BESTA
      , LFSTA
      , LFGSA
      , WBSTA
      , FKSTA
      , FKSAA
      , ABSTA
      , GBSTA
      , KOSTA
      , LVSTA
      , UVALL
      , UVVLK
      , UVFAK
      , UVPRS
      , FKIVP
      , UVP01
      , UVP02
      , UVP03
      , UVP04
      , UVP05
      , PKSTA
      , KOQUA
      , COSTA
      , CMPPI
      , CMPPJ
      , UVPIK
      , UVPAK
      , UVWAK
      , DCSTA
      , RRSTA
      , VLSTP
      , FSSTA
      , LSSTA
      , PDSTA
      , MANEK
      , HDALL
      , LTSPS
      , FSH_AR_STAT_ITM
      , MILL_VS_VSSTA
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , HASHDIFF
      , BKCC
    FROM LOGIC_a
)
---- FILTER LAYER ----

, FILTER_a as (
    SELECT *
    FROM RENAME_a
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_a
)

---- FINAL LAYER ----
SELECT
          ORDER_LINE_HK
        , MANDT
        , VBELN
        , POSNR
        , GLREQUEST
        , RFSTA
        , RFGSA
        , BESTA
        , LFSTA
        , LFGSA
        , WBSTA
        , FKSTA
        , FKSAA
        , ABSTA
        , GBSTA
        , KOSTA
        , LVSTA
        , UVALL
        , UVVLK
        , UVFAK
        , UVPRS
        , FKIVP
        , UVP01
        , UVP02
        , UVP03
        , UVP04
        , UVP05
        , PKSTA
        , KOQUA
        , COSTA
        , CMPPI
        , CMPPJ
        , UVPIK
        , UVPAK
        , UVWAK
        , DCSTA
        , RRSTA
        , VLSTP
        , FSSTA
        , LSSTA
        , PDSTA
        , MANEK
        , HDALL
        , LTSPS
        , FSH_AR_STAT_ITM
        , MILL_VS_VSSTA
        , GLDELFLAG
        , GLCHANGETIME
        , GLSOURCESYSTEM
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , REC_SRC
        , HASHDIFF
        , BKCC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.ORDER_LINE_HK = JOIN_RESULT.ORDER_LINE_HK 
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %}
{% if not is_incremental() %}

/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per HK and hashdiff. */
qualify 1 = row_number() over (partition by ORDER_LINE_HK, HASHDIFF order by PSA_LOAD_DTS)

union all
SELECT 
MD5_BINARY(GR.VALUE) AS ORDER_LINE_HK,
GR.VALUE::text AS MANDT,
GR.VALUE::text AS VBELN,
GR.VALUE::text AS POSNR,
NULL AS GLREQUEST,
NULL AS RFSTA,
NULL AS RFGSA,
NULL AS BESTA,
NULL AS LFSTA,
NULL AS LFGSA,
NULL AS WBSTA,
NULL AS FKSTA,
NULL AS FKSAA,
NULL AS ABSTA,
NULL AS GBSTA,
NULL AS KOSTA,
NULL AS LVSTA,
NULL AS UVALL,
NULL AS UVVLK,
NULL AS UVFAK,
NULL AS UVPRS,
NULL AS FKIVP,
NULL AS UVP01,
NULL AS UVP02,
NULL AS UVP03,
NULL AS UVP04,
NULL AS UVP05,
NULL AS PKSTA,
NULL AS KOQUA,
NULL AS COSTA,
NULL AS CMPPI,
NULL AS CMPPJ,
NULL AS UVPIK,
NULL AS UVPAK,
NULL AS UVWAK,
NULL AS DCSTA,
NULL AS RRSTA,
NULL AS VLSTP,
NULL AS FSSTA,
NULL AS LSSTA,
NULL AS PDSTA,
NULL AS MANEK,
NULL AS HDALL,
NULL AS LTSPS,
NULL AS FSH_AR_STAT_ITM,
NULL AS MILL_VS_VSSTA,
NULL AS GLDELFLAG,
NULL AS GLCHANGETIME,
NULL AS GLSOURCESYSTEM,
'1900-01-01'::TIMESTAMP AS PSA_LOAD_DTS,
NULL AS PSA_RECORD_SOURCE,
'N' AS PSA_DELETE_IND,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC,
''::BINARY AS HASHDIFF,
DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
