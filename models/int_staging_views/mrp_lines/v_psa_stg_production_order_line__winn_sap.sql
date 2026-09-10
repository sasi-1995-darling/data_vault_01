---- SRC LAYER ----
WITH
SRC_a              as ( SELECT * FROM {{ source('sap_ecc_prd', 'z_afpo') }} as SRC  ),
SRC_bkcc           as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_a              as ( SELECT * FROM sap_ecc_prd.z_afpo )
, SRC_bkcc           as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_a as (
    SELECT
        MANDT
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
    FROM SRC_a
)

, LOGIC_bkcc as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_bkcc
)
---- RENAME LAYER ----

, RENAME_a as (
    SELECT
        MANDT
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
    FROM LOGIC_a
)

, RENAME_bkcc as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_bkcc
)
---- FILTER LAYER ----

, FILTER_a as (
    SELECT *
    FROM RENAME_a
)

, FILTER_bkcc as (
    SELECT *
    FROM RENAME_bkcc
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_AFPO'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_a
    INNER JOIN FILTER_bkcc
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          AUFNR                                                        as PRODUCTION_ORDER_BK
        , POSNR                                                        as PRODUCTION_ORDER_LINE_ITEM_BK
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
        , CONVERT_TIMEZONE('UTC', IFF(
            PSA_DELETE_IND = 'Y',
            PSA_LOAD_DTS,
            TO_TIMESTAMP(
            SUBSTR(GLCHANGETIME, 1, 8) || ' ' ||
            SUBSTR(GLCHANGETIME, 9, 2) || ':' ||
            SUBSTR(GLCHANGETIME, 11, 2) || ':' ||
            SUBSTR(GLCHANGETIME, 13, 2) || '.' ||
            REGEXP_REPLACE(SUBSTR(GLCHANGETIME, 16), '^\\.', ''),
            'YYYYMMDD HH24:MI:SS.FF9'
            )
        ))                                                           as                                           LOAD_DTS
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(AUFNR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(AUFNR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(POSNR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PRODUCTION_ORDER_LINE_LHK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(AUFNR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(POSNR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PRODUCTION_ORDER_LINE_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(AUFNR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PRODUCTION_ORDER_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(MANDT::text), '^^')
            , '||', IFNULL(TRIM(PSOBS::text), '^^') 
            , '||', IFNULL(TRIM(QUNUM::text), '^^') 
            , '||', IFNULL(TRIM(QUPOS::text), '^^') 
            , '||', IFNULL(TRIM(PROJN::text), '^^') 
            , '||', IFNULL(TRIM(PLNUM::text), '^^') 
            , '||', IFNULL(TRIM(STRMP::text), '^^') 
            , '||', IFNULL(TRIM(ETRMP::text), '^^') 
            , '||', IFNULL(TRIM(KDAUF::text), '^^') 
            , '||', IFNULL(TRIM(KDPOS::text), '^^') 
            , '||', IFNULL(TRIM(KDEIN::text), '^^') 
            , '||', IFNULL(TRIM(BESKZ::text), '^^') 
            , '||', IFNULL(TRIM(PSAMG::text), '^^') 
            , '||', IFNULL(TRIM(PSMNG::text), '^^') 
            , '||', IFNULL(TRIM(WEMNG::text), '^^') 
            , '||', IFNULL(TRIM(IAMNG::text), '^^') 
            , '||', IFNULL(TRIM(AMEIN::text), '^^') 
            , '||', IFNULL(TRIM(MEINS::text), '^^') 
            , '||', IFNULL(TRIM(MATNR::text), '^^') 
            , '||', IFNULL(TRIM(PAMNG::text), '^^') 
            , '||', IFNULL(TRIM(PGMNG::text), '^^') 
            , '||', IFNULL(TRIM(KNTTP::text), '^^') 
            , '||', IFNULL(TRIM(TPAUF::text), '^^') 
            , '||', IFNULL(TRIM(LTRMI::text), '^^') 
            , '||', IFNULL(TRIM(LTRMP::text), '^^') 
            , '||', IFNULL(TRIM(KALNR::text), '^^') 
            , '||', IFNULL(TRIM(UEBTO::text), '^^') 
            , '||', IFNULL(TRIM(UEBTK::text), '^^') 
            , '||', IFNULL(TRIM(UNTTO::text), '^^') 
            , '||', IFNULL(TRIM(INSMK::text), '^^') 
            , '||', IFNULL(TRIM(WEPOS::text), '^^') 
            , '||', IFNULL(TRIM(BWTAR::text), '^^') 
            , '||', IFNULL(TRIM(BWTTY::text), '^^') 
            , '||', IFNULL(TRIM(PWERK::text), '^^') 
            , '||', IFNULL(TRIM(LGORT::text), '^^') 
            , '||', IFNULL(TRIM(UMREZ::text), '^^') 
            , '||', IFNULL(TRIM(UMREN::text), '^^') 
            , '||', IFNULL(TRIM(WEBAZ::text), '^^') 
            , '||', IFNULL(TRIM(ELIKZ::text), '^^') 
            , '||', IFNULL(TRIM(SAFNR::text), '^^') 
            , '||', IFNULL(TRIM(VERID::text), '^^') 
            , '||', IFNULL(TRIM(SERNR::text), '^^') 
            , '||', IFNULL(TRIM(TECHS::text), '^^') 
            , '||', IFNULL(TRIM(DWERK::text), '^^') 
            , '||', IFNULL(TRIM(DAUTY::text), '^^') 
            , '||', IFNULL(TRIM(DAUAT::text), '^^') 
            , '||', IFNULL(TRIM(DGLTP::text), '^^') 
            , '||', IFNULL(TRIM(DGLTS::text), '^^') 
            , '||', IFNULL(TRIM(DFREI::text), '^^') 
            , '||', IFNULL(TRIM(DNREL::text), '^^') 
            , '||', IFNULL(TRIM(VERTO::text), '^^') 
            , '||', IFNULL(TRIM(SOBKZ::text), '^^') 
            , '||', IFNULL(TRIM(KZVBR::text), '^^') 
            , '||', IFNULL(TRIM(WEWRT::text), '^^') 
            , '||', IFNULL(TRIM(WEUNB::text), '^^') 
            , '||', IFNULL(TRIM(ABLAD::text), '^^') 
            , '||', IFNULL(TRIM(WEMPF::text), '^^') 
            , '||', IFNULL(TRIM(CHARG::text), '^^') 
            , '||', IFNULL(TRIM(GSBER::text), '^^') 
            , '||', IFNULL(TRIM(WEAED::text), '^^') 
            , '||', IFNULL(TRIM(CUOBJ::text), '^^') 
            , '||', IFNULL(TRIM(KBNKZ::text), '^^') 
            , '||', IFNULL(TRIM(ARSNR::text), '^^') 
            , '||', IFNULL(TRIM(ARSPS::text), '^^') 
            , '||', IFNULL(TRIM(KRSNR::text), '^^') 
            , '||', IFNULL(TRIM(KRSPS::text), '^^') 
            , '||', IFNULL(TRIM(KCKEY::text), '^^') 
            , '||', IFNULL(TRIM(RTP01::text), '^^') 
            , '||', IFNULL(TRIM(RTP02::text), '^^') 
            , '||', IFNULL(TRIM(RTP03::text), '^^') 
            , '||', IFNULL(TRIM(RTP04::text), '^^') 
            , '||', IFNULL(TRIM(KSVON::text), '^^') 
            , '||', IFNULL(TRIM(KSBIS::text), '^^') 
            , '||', IFNULL(TRIM(OBJNP::text), '^^') 
            , '||', IFNULL(TRIM(NDISR::text), '^^') 
            , '||', IFNULL(TRIM(VFMNG::text), '^^') 
            , '||', IFNULL(TRIM(GSBTR::text), '^^') 
            , '||', IFNULL(TRIM(KZAVC::text), '^^') 
            , '||', IFNULL(TRIM(KZBWS::text), '^^') 
            , '||', IFNULL(TRIM(XLOEK::text), '^^') 
            , '||', IFNULL(TRIM(SERNP::text), '^^') 
            , '||', IFNULL(TRIM(ANZSN::text), '^^') 
            , '||', IFNULL(TRIM(OBJTYPE::text), '^^') 
            , '||', IFNULL(TRIM(CH_PROC::text), '^^') 
            , '||', IFNULL(TRIM(FXPRU::text), '^^') 
            , '||', IFNULL(TRIM(CUOBJ_ROOT::text), '^^') 
            , '||', IFNULL(TRIM(BERID::text), '^^') 
            , '||', IFNULL(TRIM(TECHS_COPY::text), '^^') 
            , '||', IFNULL(TRIM(SGT_SCAT::text), '^^') 
            , '||', IFNULL(TRIM(KUNNR2::text), '^^') 
            , '||', IFNULL(TRIM(FSH_SEASON_YEAR::text), '^^') 
            , '||', IFNULL(TRIM(FSH_SEASON::text), '^^') 
            , '||', IFNULL(TRIM(FSH_COLLECTION::text), '^^') 
            , '||', IFNULL(TRIM(FSH_THEME::text), '^^') 
            , '||', IFNULL(TRIM(FSH_SALLOC_QTY::text), '^^') 
            , '||', IFNULL(TRIM(MILL_OC_AUFNR_U::text), '^^') 
            , '||', IFNULL(TRIM(MILL_OC_RUMNG::text), '^^') 
            , '||', IFNULL(TRIM(MILL_OC_SORT::text), '^^') 
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
