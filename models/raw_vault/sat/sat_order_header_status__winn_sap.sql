---- SRC LAYER ----
WITH
SRC_VBUK           as ( SELECT * FROM {{ ref('v_psa_stg_order_header_status__winn_sap') }} as SRC 
                        {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %} )

/*
SRC_VBUK           as ( SELECT * FROM STAGING.v_psa_stg_order_header_status__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_VBUK as (
    SELECT
        ORDER_HEADER_HK
      , MANDT
      , VBELN
      , GLREQUEST
      , RFSTK
      , RFGSK
      , BESTK
      , LFSTK
      , LFGSK
      , WBSTK
      , FKSTK
      , FKSAK
      , BUCHK
      , ABSTK
      , GBSTK
      , KOSTK
      , LVSTK
      , UVALS
      , UVVLS
      , UVFAS
      , UVALL
      , UVVLK
      , UVFAK
      , UVPRS
      , VBTYP
      , VBOBJ
      , AEDAT
      , AEDAT_DT
      , FKIVK
      , RELIK
      , UVK01
      , UVK02
      , UVK03
      , UVK04
      , UVK05
      , UVS01
      , UVS02
      , UVS03
      , UVS04
      , UVS05
      , PKSTK
      , CMPSA
      , CMPSB
      , CMPSC
      , CMPSD
      , CMPSE
      , CMPSF
      , CMPSG
      , CMPSH
      , CMPSI
      , CMPSJ
      , CMPSK
      , CMPSL
      , CMPS0
      , CMPS1
      , CMPS2
      , CMGST
      , TRSTA
      , KOQUK
      , COSTA
      , SAPRL
      , UVPAS
      , UVPIS
      , UVWAS
      , UVPAK
      , UVPIK
      , UVWAK
      , UVGEK
      , CMPSM
      , DCSTK
      , VESTK
      , VLSTK
      , RRSTA
      , BLOCK
      , FSSTK
      , LSSTK
      , SPSTG
      , PDSTK
      , FMSTK
      , MANEK
      , SPE_TMPID
      , HDALL
      , HDALS
      , CMPS_CM
      , CMPS_TE
      , VBTYP_EXT
      , FSH_AR_STAT_HDR
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , HASHDIFF
    FROM SRC_VBUK
)
---- RENAME LAYER ----

, RENAME_VBUK as (
    SELECT
        ORDER_HEADER_HK
      , MANDT
      , VBELN
      , GLREQUEST
      , RFSTK
      , RFGSK
      , BESTK
      , LFSTK
      , LFGSK
      , WBSTK
      , FKSTK
      , FKSAK
      , BUCHK
      , ABSTK
      , GBSTK
      , KOSTK
      , LVSTK
      , UVALS
      , UVVLS
      , UVFAS
      , UVALL
      , UVVLK
      , UVFAK
      , UVPRS
      , VBTYP
      , VBOBJ
      , AEDAT
      , AEDAT_DT
      , FKIVK
      , RELIK
      , UVK01
      , UVK02
      , UVK03
      , UVK04
      , UVK05
      , UVS01
      , UVS02
      , UVS03
      , UVS04
      , UVS05
      , PKSTK
      , CMPSA
      , CMPSB
      , CMPSC
      , CMPSD
      , CMPSE
      , CMPSF
      , CMPSG
      , CMPSH
      , CMPSI
      , CMPSJ
      , CMPSK
      , CMPSL
      , CMPS0
      , CMPS1
      , CMPS2
      , CMGST
      , TRSTA
      , KOQUK
      , COSTA
      , SAPRL
      , UVPAS
      , UVPIS
      , UVWAS
      , UVPAK
      , UVPIK
      , UVWAK
      , UVGEK
      , CMPSM
      , DCSTK
      , VESTK
      , VLSTK
      , RRSTA
      , BLOCK
      , FSSTK
      , LSSTK
      , SPSTG
      , PDSTK
      , FMSTK
      , MANEK
      , SPE_TMPID
      , HDALL
      , HDALS
      , CMPS_CM
      , CMPS_TE
      , VBTYP_EXT
      , FSH_AR_STAT_HDR
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , HASHDIFF
    FROM LOGIC_VBUK
)
---- FILTER LAYER ----

, FILTER_VBUK as (
    SELECT *
    FROM RENAME_VBUK
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_VBUK
)

---- FINAL LAYER ----
SELECT
          ORDER_HEADER_HK
        , MANDT
        , VBELN
        , GLREQUEST
        , RFSTK
        , RFGSK
        , BESTK
        , LFSTK
        , LFGSK
        , WBSTK
        , FKSTK
        , FKSAK
        , BUCHK
        , ABSTK
        , GBSTK
        , KOSTK
        , LVSTK
        , UVALS
        , UVVLS
        , UVFAS
        , UVALL
        , UVVLK
        , UVFAK
        , UVPRS
        , VBTYP
        , VBOBJ
        , AEDAT
        , AEDAT_DT
        , FKIVK
        , RELIK
        , UVK01
        , UVK02
        , UVK03
        , UVK04
        , UVK05
        , UVS01
        , UVS02
        , UVS03
        , UVS04
        , UVS05
        , PKSTK
        , CMPSA
        , CMPSB
        , CMPSC
        , CMPSD
        , CMPSE
        , CMPSF
        , CMPSG
        , CMPSH
        , CMPSI
        , CMPSJ
        , CMPSK
        , CMPSL
        , CMPS0
        , CMPS1
        , CMPS2
        , CMGST
        , TRSTA
        , KOQUK
        , COSTA
        , SAPRL
        , UVPAS
        , UVPIS
        , UVWAS
        , UVPAK
        , UVPIK
        , UVWAK
        , UVGEK
        , CMPSM
        , DCSTK
        , VESTK
        , VLSTK
        , RRSTA
        , BLOCK
        , FSSTK
        , LSSTK
        , SPSTG
        , PDSTK
        , FMSTK
        , MANEK
        , SPE_TMPID
        , HDALL
        , HDALS
        , CMPS_CM
        , CMPS_TE
        , VBTYP_EXT
        , FSH_AR_STAT_HDR
        , GLDELFLAG
        , GLCHANGETIME
        , GLSOURCESYSTEM
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , REC_SRC
        , HASHDIFF
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.ORDER_HEADER_HK = JOIN_RESULT.ORDER_HEADER_HK
	AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF	
)
{% endif %}
{% if not is_incremental() %}

/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per HK and hashdiff. */
qualify 1 = row_number() over (partition by ORDER_HEADER_HK, HASHDIFF order by PSA_LOAD_DTS)

union all
SELECT 
MD5_BINARY(GR.VALUE) AS ORDER_HEADER_HK,
NULL AS MANDT,
GR.VALUE::text AS VBELN,
NULL AS GLREQUEST,
NULL AS RFSTK,
NULL AS RFGSK,
NULL AS BESTK,
NULL AS LFSTK,
NULL AS LFGSK,
NULL AS WBSTK,
NULL AS FKSTK,
NULL AS FKSAK,
NULL AS BUCHK,
NULL AS ABSTK,
NULL AS GBSTK,
NULL AS KOSTK,
NULL AS LVSTK,
NULL AS UVALS,
NULL AS UVVLS,
NULL AS UVFAS,
NULL AS UVALL,
NULL AS UVVLK,
NULL AS UVFAK,
NULL AS UVPRS,
NULL AS VBTYP,
NULL AS VBOBJ,
NULL AS AEDAT,
NULL AS AEDAT_DT,
NULL AS FKIVK,
NULL AS RELIK,
NULL AS UVK01,
NULL AS UVK02,
NULL AS UVK03,
NULL AS UVK04,
NULL AS UVK05,
NULL AS UVS01,
NULL AS UVS02,
NULL AS UVS03,
NULL AS UVS04,
NULL AS UVS05,
NULL AS PKSTK,
NULL AS CMPSA,
NULL AS CMPSB,
NULL AS CMPSC,
NULL AS CMPSD,
NULL AS CMPSE,
NULL AS CMPSF,
NULL AS CMPSG,
NULL AS CMPSH,
NULL AS CMPSI,
NULL AS CMPSJ,
NULL AS CMPSK,
NULL AS CMPSL,
NULL AS CMPS0,
NULL AS CMPS1,
NULL AS CMPS2,
NULL AS CMGST,
NULL AS TRSTA,
NULL AS KOQUK,
NULL AS COSTA,
NULL AS SAPRL,
NULL AS UVPAS,
NULL AS UVPIS,
NULL AS UVWAS,
NULL AS UVPAK,
NULL AS UVPIK,
NULL AS UVWAK,
NULL AS UVGEK,
NULL AS CMPSM,
NULL AS DCSTK,
NULL AS VESTK,
NULL AS VLSTK,
NULL AS RRSTA,
NULL AS BLOCK,
NULL AS FSSTK,
NULL AS LSSTK,
NULL AS SPSTG,
NULL AS PDSTK,
NULL AS FMSTK,
NULL AS MANEK,
NULL AS SPE_TMPID,
NULL AS HDALL,
NULL AS HDALS,
NULL AS CMPS_CM,
NULL AS CMPS_TE,
NULL AS VBTYP_EXT,
NULL AS FSH_AR_STAT_HDR,
NULL AS GLDELFLAG,
NULL AS GLCHANGETIME,
NULL AS GLSOURCESYSTEM,
'1900-01-01'::TIMESTAMP AS PSA_LOAD_DTS,
NULL AS PSA_RECORD_SOURCE,
'N' AS PSA_DELETE_IND,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC,
''::BINARY AS HASHDIFF
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
