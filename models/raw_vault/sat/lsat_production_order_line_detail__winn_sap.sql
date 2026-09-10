---- SRC LAYER ----
WITH
SRC_b              as ( SELECT * FROM {{ ref('v_psa_stg_production_order_line__winn_sap') }} as SRC 
                        {% if is_incremental() %}
                        WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}}){% endif %} )

/*
SRC_b              as ( SELECT * FROM STAGING.V_PSA_STG_PRODUCTION_ORDER_LINE__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_b as (
    SELECT
        PRODUCTION_ORDER_LINE_LHK
      , MANDT
      , AUFNR
      , POSNR
      , GLREQUEST
      , PSOBS
      , QUNUM
      , QUPOS
      , PROJN
      , PLNUM
      , STRMP
      , ETRMP
      , KDAUF
      , KDPOS
      , KDEIN
      , BESKZ
      , PSAMG
      , PSMNG
      , WEMNG
      , IAMNG
      , AMEIN
      , MEINS
      , MATNR
      , PAMNG
      , PGMNG
      , KNTTP
      , TPAUF
      , LTRMI
      , LTRMP
      , KALNR
      , UEBTO
      , UEBTK
      , UNTTO
      , INSMK
      , WEPOS
      , BWTAR
      , BWTTY
      , PWERK
      , LGORT
      , UMREZ
      , UMREN
      , WEBAZ
      , ELIKZ
      , SAFNR
      , VERID
      , SERNR
      , TECHS
      , DWERK
      , DAUTY
      , DAUAT
      , DGLTP
      , DGLTS
      , DFREI
      , DNREL
      , VERTO
      , SOBKZ
      , KZVBR
      , WEWRT
      , WEUNB
      , ABLAD
      , WEMPF
      , CHARG
      , GSBER
      , WEAED
      , CUOBJ
      , KBNKZ
      , ARSNR
      , ARSPS
      , KRSNR
      , KRSPS
      , KCKEY
      , RTP01
      , RTP02
      , RTP03
      , RTP04
      , KSVON
      , KSBIS
      , OBJNP
      , NDISR
      , VFMNG
      , GSBTR
      , KZAVC
      , KZBWS
      , XLOEK
      , SERNP
      , ANZSN
      , OBJTYPE
      , CH_PROC
      , FXPRU
      , CUOBJ_ROOT
      , BERID
      , TECHS_COPY
      , SGT_SCAT
      , KUNNR2
      , FSH_SEASON_YEAR
      , FSH_SEASON
      , FSH_COLLECTION
      , FSH_THEME
      , FSH_SALLOC_QTY
      , MILL_OC_AUFNR_U
      , MILL_OC_RUMNG
      , MILL_OC_SORT
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , HASHDIFF
      , REC_SRC
    FROM SRC_b
)
---- RENAME LAYER ----

, RENAME_b as (
    SELECT
        PRODUCTION_ORDER_LINE_LHK
      , MANDT
      , AUFNR
      , POSNR
      , GLREQUEST
      , PSOBS
      , QUNUM
      , QUPOS
      , PROJN
      , PLNUM
      , STRMP
      , ETRMP
      , KDAUF
      , KDPOS
      , KDEIN
      , BESKZ
      , PSAMG
      , PSMNG
      , WEMNG
      , IAMNG
      , AMEIN
      , MEINS
      , MATNR
      , PAMNG
      , PGMNG
      , KNTTP
      , TPAUF
      , LTRMI
      , LTRMP
      , KALNR
      , UEBTO
      , UEBTK
      , UNTTO
      , INSMK
      , WEPOS
      , BWTAR
      , BWTTY
      , PWERK
      , LGORT
      , UMREZ
      , UMREN
      , WEBAZ
      , ELIKZ
      , SAFNR
      , VERID
      , SERNR
      , TECHS
      , DWERK
      , DAUTY
      , DAUAT
      , DGLTP
      , DGLTS
      , DFREI
      , DNREL
      , VERTO
      , SOBKZ
      , KZVBR
      , WEWRT
      , WEUNB
      , ABLAD
      , WEMPF
      , CHARG
      , GSBER
      , WEAED
      , CUOBJ
      , KBNKZ
      , ARSNR
      , ARSPS
      , KRSNR
      , KRSPS
      , KCKEY
      , RTP01
      , RTP02
      , RTP03
      , RTP04
      , KSVON
      , KSBIS
      , OBJNP
      , NDISR
      , VFMNG
      , GSBTR
      , KZAVC
      , KZBWS
      , XLOEK
      , SERNP
      , ANZSN
      , OBJTYPE
      , CH_PROC
      , FXPRU
      , CUOBJ_ROOT
      , BERID
      , TECHS_COPY
      , SGT_SCAT
      , KUNNR2
      , FSH_SEASON_YEAR
      , FSH_SEASON
      , FSH_COLLECTION
      , FSH_THEME
      , FSH_SALLOC_QTY
      , MILL_OC_AUFNR_U
      , MILL_OC_RUMNG
      , MILL_OC_SORT
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , HASHDIFF
      , REC_SRC
    FROM LOGIC_b
)
---- FILTER LAYER ----

, FILTER_b as (
    SELECT *
    FROM RENAME_b
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_b
)

---- FINAL LAYER ----
SELECT
          PRODUCTION_ORDER_LINE_LHK
        , MANDT
        , AUFNR
        , POSNR
        , GLREQUEST
        , PSOBS
        , QUNUM
        , QUPOS
        , PROJN
        , PLNUM
        , STRMP
        , ETRMP
        , KDAUF
        , KDPOS
        , KDEIN
        , BESKZ
        , PSAMG
        , PSMNG
        , WEMNG
        , IAMNG
        , AMEIN
        , MEINS
        , MATNR
        , PAMNG
        , PGMNG
        , KNTTP
        , TPAUF
        , LTRMI
        , LTRMP
        , KALNR
        , UEBTO
        , UEBTK
        , UNTTO
        , INSMK
        , WEPOS
        , BWTAR
        , BWTTY
        , PWERK
        , LGORT
        , UMREZ
        , UMREN
        , WEBAZ
        , ELIKZ
        , SAFNR
        , VERID
        , SERNR
        , TECHS
        , DWERK
        , DAUTY
        , DAUAT
        , DGLTP
        , DGLTS
        , DFREI
        , DNREL
        , VERTO
        , SOBKZ
        , KZVBR
        , WEWRT
        , WEUNB
        , ABLAD
        , WEMPF
        , CHARG
        , GSBER
        , WEAED
        , CUOBJ
        , KBNKZ
        , ARSNR
        , ARSPS
        , KRSNR
        , KRSPS
        , KCKEY
        , RTP01
        , RTP02
        , RTP03
        , RTP04
        , KSVON
        , KSBIS
        , OBJNP
        , NDISR
        , VFMNG
        , GSBTR
        , KZAVC
        , KZBWS
        , XLOEK
        , SERNP
        , ANZSN
        , OBJTYPE
        , CH_PROC
        , FXPRU
        , CUOBJ_ROOT
        , BERID
        , TECHS_COPY
        , SGT_SCAT
        , KUNNR2
        , FSH_SEASON_YEAR
        , FSH_SEASON
        , FSH_COLLECTION
        , FSH_THEME
        , FSH_SALLOC_QTY
        , MILL_OC_AUFNR_U
        , MILL_OC_RUMNG
        , MILL_OC_SORT
        , GLDELFLAG
        , GLCHANGETIME
        , GLSOURCESYSTEM
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , HASHDIFF
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.PRODUCTION_ORDER_LINE_LHK = JOIN_RESULT.PRODUCTION_ORDER_LINE_LHK  
   AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %}
{% if not is_incremental() %}

/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per HK and hashdiff. */
qualify 1 = row_number() over (partition by PRODUCTION_ORDER_LINE_LHK, HASHDIFF order by LOAD_DTS)

union all
SELECT 
MD5_BINARY(GR.VALUE) AS PRODUCTION_ORDER_LINE_LHK,
NULL AS MANDT,
GR.VALUE::text AS AUFNR,
NULL AS POSNR,
NULL AS GLREQUEST,
NULL AS PSOBS,
NULL AS QUNUM,
NULL AS QUPOS,
NULL AS PROJN,
NULL AS PLNUM,
NULL AS STRMP,
NULL AS ETRMP,
NULL AS KDAUF,
NULL AS KDPOS,
NULL AS KDEIN,
NULL AS BESKZ,
NULL AS PSAMG,
NULL AS PSMNG,
NULL AS WEMNG,
NULL AS IAMNG,
NULL AS AMEIN,
NULL AS MEINS,
NULL AS MATNR,
NULL AS PAMNG,
NULL AS PGMNG,
NULL AS KNTTP,
NULL AS TPAUF,
NULL AS LTRMI,
NULL AS LTRMP,
NULL AS KALNR,
NULL AS UEBTO,
NULL AS UEBTK,
NULL AS UNTTO,
NULL AS INSMK,
NULL AS WEPOS,
NULL AS BWTAR,
NULL AS BWTTY,
NULL AS PWERK,
NULL AS LGORT,
NULL AS UMREZ,
NULL AS UMREN,
NULL AS WEBAZ,
NULL AS ELIKZ,
NULL AS SAFNR,
NULL AS VERID,
NULL AS SERNR,
NULL AS TECHS,
NULL AS DWERK,
NULL AS DAUTY,
NULL AS DAUAT,
NULL AS DGLTP,
NULL AS DGLTS,
NULL AS DFREI,
NULL AS DNREL,
NULL AS VERTO,
NULL AS SOBKZ,
NULL AS KZVBR,
NULL AS WEWRT,
NULL AS WEUNB,
NULL AS ABLAD,
NULL AS WEMPF,
NULL AS CHARG,
NULL AS GSBER,
NULL AS WEAED,
NULL AS CUOBJ,
NULL AS KBNKZ,
NULL AS ARSNR,
NULL AS ARSPS,
NULL AS KRSNR,
NULL AS KRSPS,
NULL AS KCKEY,
NULL AS RTP01,
NULL AS RTP02,
NULL AS RTP03,
NULL AS RTP04,
NULL AS KSVON,
NULL AS KSBIS,
NULL AS OBJNP,
NULL AS NDISR,
NULL AS VFMNG,
NULL AS GSBTR,
NULL AS KZAVC,
NULL AS KZBWS,
NULL AS XLOEK,
NULL AS SERNP,
NULL AS ANZSN,
NULL AS OBJTYPE,
NULL AS CH_PROC,
NULL AS FXPRU,
NULL AS CUOBJ_ROOT,
NULL AS BERID,
NULL AS TECHS_COPY,
NULL AS SGT_SCAT,
NULL AS KUNNR2,
NULL AS FSH_SEASON_YEAR,
NULL AS FSH_SEASON,
NULL AS FSH_COLLECTION,
NULL AS FSH_THEME,
NULL AS FSH_SALLOC_QTY,
NULL AS MILL_OC_AUFNR_U,
NULL AS MILL_OC_RUMNG,
NULL AS MILL_OC_SORT,
NULL AS GLDELFLAG,
NULL AS GLCHANGETIME,
NULL AS GLSOURCESYSTEM,
'1900-01-01'::TIMESTAMP AS PSA_LOAD_DTS,
NULL AS PSA_RECORD_SOURCE,
'N' AS PSA_DELETE_IND,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
''::BINARY AS HASHDIFF,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
