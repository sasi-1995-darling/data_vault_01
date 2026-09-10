---- SRC LAYER ----
WITH
SRC_a              as ( SELECT LNK_GOODS_MOVEMENT_HK, MANDT, MBLNR, MJAHR, ZEILE, GLREQUEST, LINE_ID, PARENT_ID, LINE_DEPTH, MAA_URZEI, BWART, XAUTO, MATNR, WERKS, LGORT, CHARG, INSMK, ZUSCH, ZUSTD, SOBKZ, LIFNR, KUNNR, KDAUF, KDPOS, KDEIN, PLPLA, SHKZG, WAERS, DMBTR, BNBTR, BUALT, SHKUM, DMBUM, BWTAR, MENGE, MEINS, ERFMG, ERFME, BPMNG, BPRME, EBELN, EBELP, LFBJA, LFBNR, LFPOS, SJAHR, SMBLN, SMBLP, ELIKZ, SGTXT, EQUNR, WEMPF, ABLAD, GSBER, KOKRS, PARGB, PARBU, KOSTL, PROJN, AUFNR, ANLN1, ANLN2, XSKST, XSAUF, XSPRO, XSERG, GJAHR, XRUEM, XRUEJ, BUKRS, BELNR, BUZEI, BELUM, BUZUM, RSNUM, RSPOS, KZEAR, PBAMG, KZSTR, UMMAT, UMWRK, UMLGO, UMCHA, UMZST, UMZUS, UMBAR, UMSOK, KZBEW, KZVBR, KZZUG, WEUNB, PALAN, LGNUM, LGTYP, LGPLA, BESTQ, BWLVS, TBNUM, TBPOS, XBLVS, VSCHN, NSCHN, DYPLA, UBNUM, TBPRI, TANUM, WEANZ, GRUND, EVERS, EVERE, IMKEY, KSTRG, PAOBJNR, PRCTR, PS_PSP_PNR, NPLNR, AUFPL, APLZL, AUFPS, VPTNR, FIPOS, SAKTO, BSTMG, BSTME, XWSBR, EMLIF, ZZALTKT, EXBWR, VKWRT, AKTNR, ZEKKN, VFDAT, CUOBJ_CH, EXVKW, PPRCTR, RSART, GEBER, FISTL, MATBF, UMMAB, BUSTM, BUSTW, MENGU, WERTU, LBKUM, SALK3, VPRSV, FKBER, DABRBZ, VKWRA, DABRZ, XBEAU, LSMNG, LSMEH, KZBWS, QINSPST, URZEI, J_1BEXBASE, MWSKZ, TXJCD, EMATN, J_1AGIRUPD, VKMWS, HSDAT, BERKZ, MAT_KDAUF, MAT_KDPOS, MAT_PSPNR, XWOFF, BEMOT, PRZNR, LLIEF, LSTAR, XOBEW, GRANT_NBR, ZUSTD_T156M, SPE_GTS_STOCK_TY, KBLNR, KBLPOS, XMACC, VGART_MKPF, BUDAT_MKPF, CPUDT_MKPF, CPUTM_MKPF, USNAM_MKPF, XBLNR_MKPF, TCODE2_MKPF, VBELN_IM, VBELP_IM, SGT_SCAT, SGT_UMSCAT, SGT_RCAT, BEV2_ED_KZ_VER, BEV2_ED_USER, BEV2_ED_AEDAT, BEV2_ED_AETIM, DISUB_OWNER, FSH_SEASON_YEAR, FSH_SEASON, FSH_COLLECTION, FSH_THEME, FSH_UMSEA_YR, FSH_UMSEA, FSH_UMCOLL, FSH_UMTHEME, SGT_CHINT, FSH_DEALLOC_QTY, OINAVNW, OICONDCOD, CONDI, WRF_CHARSTC1, WRF_CHARSTC2, WRF_CHARSTC3, GLDELFLAG, GLCHANGETIME, GLSOURCESYSTEM, PSA_LOAD_DTS, PSA_RECORD_SOURCE, PSA_DELETE_IND, LOAD_DTS, HASHDIFF, REC_SRC FROM {{ ref('v_psa_stg_goods_movement__winn_sap') }} as SRC 
                        {% if is_incremental() %}
                        WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}}){% endif %} )

/*
SRC_a              as ( SELECT * FROM STAGING.V_PSA_STG_INVENTORY_MOVEMENT__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_a as (
    SELECT
        LNK_GOODS_MOVEMENT_HK
      , MANDT
      , MBLNR
      , MJAHR
      , ZEILE
      , GLREQUEST
      , LINE_ID
      , PARENT_ID
      , LINE_DEPTH
      , MAA_URZEI
      , BWART
      , XAUTO
      , MATNR
      , WERKS
      , LGORT
      , CHARG
      , INSMK
      , ZUSCH
      , ZUSTD
      , SOBKZ
      , LIFNR
      , KUNNR
      , KDAUF
      , KDPOS
      , KDEIN
      , PLPLA
      , SHKZG
      , WAERS
      , DMBTR
      , BNBTR
      , BUALT
      , SHKUM
      , DMBUM
      , BWTAR
      , MENGE
      , MEINS
      , ERFMG
      , ERFME
      , BPMNG
      , BPRME
      , EBELN
      , EBELP
      , LFBJA
      , LFBNR
      , LFPOS
      , SJAHR
      , SMBLN
      , SMBLP
      , ELIKZ
      , SGTXT
      , EQUNR
      , WEMPF
      , ABLAD
      , GSBER
      , KOKRS
      , PARGB
      , PARBU
      , KOSTL
      , PROJN
      , AUFNR
      , ANLN1
      , ANLN2
      , XSKST
      , XSAUF
      , XSPRO
      , XSERG
      , GJAHR
      , XRUEM
      , XRUEJ
      , BUKRS
      , BELNR
      , BUZEI
      , BELUM
      , BUZUM
      , RSNUM
      , RSPOS
      , KZEAR
      , PBAMG
      , KZSTR
      , UMMAT
      , UMWRK
      , UMLGO
      , UMCHA
      , UMZST
      , UMZUS
      , UMBAR
      , UMSOK
      , KZBEW
      , KZVBR
      , KZZUG
      , WEUNB
      , PALAN
      , LGNUM
      , LGTYP
      , LGPLA
      , BESTQ
      , BWLVS
      , TBNUM
      , TBPOS
      , XBLVS
      , VSCHN
      , NSCHN
      , DYPLA
      , UBNUM
      , TBPRI
      , TANUM
      , WEANZ
      , GRUND
      , EVERS
      , EVERE
      , IMKEY
      , KSTRG
      , PAOBJNR
      , PRCTR
      , PS_PSP_PNR
      , NPLNR
      , AUFPL
      , APLZL
      , AUFPS
      , VPTNR
      , FIPOS
      , SAKTO
      , BSTMG
      , BSTME
      , XWSBR
      , EMLIF
      , ZZALTKT
      , EXBWR
      , VKWRT
      , AKTNR
      , ZEKKN
      , VFDAT
      , CUOBJ_CH
      , EXVKW
      , PPRCTR
      , RSART
      , GEBER
      , FISTL
      , MATBF
      , UMMAB
      , BUSTM
      , BUSTW
      , MENGU
      , WERTU
      , LBKUM
      , SALK3
      , VPRSV
      , FKBER
      , DABRBZ
      , VKWRA
      , DABRZ
      , XBEAU
      , LSMNG
      , LSMEH
      , KZBWS
      , QINSPST
      , URZEI
      , J_1BEXBASE
      , MWSKZ
      , TXJCD
      , EMATN
      , J_1AGIRUPD
      , VKMWS
      , HSDAT
      , BERKZ
      , MAT_KDAUF
      , MAT_KDPOS
      , MAT_PSPNR
      , XWOFF
      , BEMOT
      , PRZNR
      , LLIEF
      , LSTAR
      , XOBEW
      , GRANT_NBR
      , ZUSTD_T156M
      , SPE_GTS_STOCK_TY
      , KBLNR
      , KBLPOS
      , XMACC
      , VGART_MKPF
      , BUDAT_MKPF
      , CPUDT_MKPF
      , CPUTM_MKPF
      , USNAM_MKPF
      , XBLNR_MKPF
      , TCODE2_MKPF
      , VBELN_IM
      , VBELP_IM
      , SGT_SCAT
      , SGT_UMSCAT
      , SGT_RCAT
      , BEV2_ED_KZ_VER
      , BEV2_ED_USER
      , BEV2_ED_AEDAT
      , BEV2_ED_AETIM
      , DISUB_OWNER
      , FSH_SEASON_YEAR
      , FSH_SEASON
      , FSH_COLLECTION
      , FSH_THEME
      , FSH_UMSEA_YR
      , FSH_UMSEA
      , FSH_UMCOLL
      , FSH_UMTHEME
      , SGT_CHINT
      , FSH_DEALLOC_QTY
      , OINAVNW
      , OICONDCOD
      , CONDI
      , WRF_CHARSTC1
      , WRF_CHARSTC2
      , WRF_CHARSTC3
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , HASHDIFF
      , REC_SRC
    FROM SRC_a
)
---- RENAME LAYER ----

, RENAME_a as (
    SELECT
        LNK_GOODS_MOVEMENT_HK
      , MANDT
      , MBLNR
      , MJAHR
      , ZEILE
      , GLREQUEST
      , LINE_ID
      , PARENT_ID
      , LINE_DEPTH
      , MAA_URZEI
      , BWART
      , XAUTO
      , MATNR
      , WERKS
      , LGORT
      , CHARG
      , INSMK
      , ZUSCH
      , ZUSTD
      , SOBKZ
      , LIFNR
      , KUNNR
      , KDAUF
      , KDPOS
      , KDEIN
      , PLPLA
      , SHKZG
      , WAERS
      , DMBTR
      , BNBTR
      , BUALT
      , SHKUM
      , DMBUM
      , BWTAR
      , MENGE
      , MEINS
      , ERFMG
      , ERFME
      , BPMNG
      , BPRME
      , EBELN
      , EBELP
      , LFBJA
      , LFBNR
      , LFPOS
      , SJAHR
      , SMBLN
      , SMBLP
      , ELIKZ
      , SGTXT
      , EQUNR
      , WEMPF
      , ABLAD
      , GSBER
      , KOKRS
      , PARGB
      , PARBU
      , KOSTL
      , PROJN
      , AUFNR
      , ANLN1
      , ANLN2
      , XSKST
      , XSAUF
      , XSPRO
      , XSERG
      , GJAHR
      , XRUEM
      , XRUEJ
      , BUKRS
      , BELNR
      , BUZEI
      , BELUM
      , BUZUM
      , RSNUM
      , RSPOS
      , KZEAR
      , PBAMG
      , KZSTR
      , UMMAT
      , UMWRK
      , UMLGO
      , UMCHA
      , UMZST
      , UMZUS
      , UMBAR
      , UMSOK
      , KZBEW
      , KZVBR
      , KZZUG
      , WEUNB
      , PALAN
      , LGNUM
      , LGTYP
      , LGPLA
      , BESTQ
      , BWLVS
      , TBNUM
      , TBPOS
      , XBLVS
      , VSCHN
      , NSCHN
      , DYPLA
      , UBNUM
      , TBPRI
      , TANUM
      , WEANZ
      , GRUND
      , EVERS
      , EVERE
      , IMKEY
      , KSTRG
      , PAOBJNR
      , PRCTR
      , PS_PSP_PNR
      , NPLNR
      , AUFPL
      , APLZL
      , AUFPS
      , VPTNR
      , FIPOS
      , SAKTO
      , BSTMG
      , BSTME
      , XWSBR
      , EMLIF
      , ZZALTKT
      , EXBWR
      , VKWRT
      , AKTNR
      , ZEKKN
      , VFDAT
      , CUOBJ_CH
      , EXVKW
      , PPRCTR
      , RSART
      , GEBER
      , FISTL
      , MATBF
      , UMMAB
      , BUSTM
      , BUSTW
      , MENGU
      , WERTU
      , LBKUM
      , SALK3
      , VPRSV
      , FKBER
      , DABRBZ
      , VKWRA
      , DABRZ
      , XBEAU
      , LSMNG
      , LSMEH
      , KZBWS
      , QINSPST
      , URZEI
      , J_1BEXBASE
      , MWSKZ
      , TXJCD
      , EMATN
      , J_1AGIRUPD
      , VKMWS
      , HSDAT
      , BERKZ
      , MAT_KDAUF
      , MAT_KDPOS
      , MAT_PSPNR
      , XWOFF
      , BEMOT
      , PRZNR
      , LLIEF
      , LSTAR
      , XOBEW
      , GRANT_NBR
      , ZUSTD_T156M
      , SPE_GTS_STOCK_TY
      , KBLNR
      , KBLPOS
      , XMACC
      , VGART_MKPF
      , BUDAT_MKPF
      , CPUDT_MKPF
      , CPUTM_MKPF
      , USNAM_MKPF
      , XBLNR_MKPF
      , TCODE2_MKPF
      , VBELN_IM
      , VBELP_IM
      , SGT_SCAT
      , SGT_UMSCAT
      , SGT_RCAT
      , BEV2_ED_KZ_VER
      , BEV2_ED_USER
      , BEV2_ED_AEDAT
      , BEV2_ED_AETIM
      , DISUB_OWNER
      , FSH_SEASON_YEAR
      , FSH_SEASON
      , FSH_COLLECTION
      , FSH_THEME
      , FSH_UMSEA_YR
      , FSH_UMSEA
      , FSH_UMCOLL
      , FSH_UMTHEME
      , SGT_CHINT
      , FSH_DEALLOC_QTY
      , OINAVNW
      , OICONDCOD
      , CONDI
      , WRF_CHARSTC1
      , WRF_CHARSTC2
      , WRF_CHARSTC3
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , HASHDIFF
      , REC_SRC      
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
          LNK_GOODS_MOVEMENT_HK
        , MANDT
        , MBLNR
        , MJAHR
        , ZEILE
        , GLREQUEST
        , LINE_ID
        , PARENT_ID
        , LINE_DEPTH
        , MAA_URZEI
        , BWART
        , XAUTO
        , MATNR
        , WERKS
        , LGORT
        , CHARG
        , INSMK
        , ZUSCH
        , ZUSTD
        , SOBKZ
        , LIFNR
        , KUNNR
        , KDAUF
        , KDPOS
        , KDEIN
        , PLPLA
        , SHKZG
        , WAERS
        , DMBTR
        , BNBTR
        , BUALT
        , SHKUM
        , DMBUM
        , BWTAR
        , MENGE
        , MEINS
        , ERFMG
        , ERFME
        , BPMNG
        , BPRME
        , EBELN
        , EBELP
        , LFBJA
        , LFBNR
        , LFPOS
        , SJAHR
        , SMBLN
        , SMBLP
        , ELIKZ
        , SGTXT
        , EQUNR
        , WEMPF
        , ABLAD
        , GSBER
        , KOKRS
        , PARGB
        , PARBU
        , KOSTL
        , PROJN
        , AUFNR
        , ANLN1
        , ANLN2
        , XSKST
        , XSAUF
        , XSPRO
        , XSERG
        , GJAHR
        , XRUEM
        , XRUEJ
        , BUKRS
        , BELNR
        , BUZEI
        , BELUM
        , BUZUM
        , RSNUM
        , RSPOS
        , KZEAR
        , PBAMG
        , KZSTR
        , UMMAT
        , UMWRK
        , UMLGO
        , UMCHA
        , UMZST
        , UMZUS
        , UMBAR
        , UMSOK
        , KZBEW
        , KZVBR
        , KZZUG
        , WEUNB
        , PALAN
        , LGNUM
        , LGTYP
        , LGPLA
        , BESTQ
        , BWLVS
        , TBNUM
        , TBPOS
        , XBLVS
        , VSCHN
        , NSCHN
        , DYPLA
        , UBNUM
        , TBPRI
        , TANUM
        , WEANZ
        , GRUND
        , EVERS
        , EVERE
        , IMKEY
        , KSTRG
        , PAOBJNR
        , PRCTR
        , PS_PSP_PNR
        , NPLNR
        , AUFPL
        , APLZL
        , AUFPS
        , VPTNR
        , FIPOS
        , SAKTO
        , BSTMG
        , BSTME
        , XWSBR
        , EMLIF
        , ZZALTKT
        , EXBWR
        , VKWRT
        , AKTNR
        , ZEKKN
        , VFDAT
        , CUOBJ_CH
        , EXVKW
        , PPRCTR
        , RSART
        , GEBER
        , FISTL
        , MATBF
        , UMMAB
        , BUSTM
        , BUSTW
        , MENGU
        , WERTU
        , LBKUM
        , SALK3
        , VPRSV
        , FKBER
        , DABRBZ
        , VKWRA
        , DABRZ
        , XBEAU
        , LSMNG
        , LSMEH
        , KZBWS
        , QINSPST
        , URZEI
        , J_1BEXBASE
        , MWSKZ
        , TXJCD
        , EMATN
        , J_1AGIRUPD
        , VKMWS
        , HSDAT
        , BERKZ
        , MAT_KDAUF
        , MAT_KDPOS
        , MAT_PSPNR
        , XWOFF
        , BEMOT
        , PRZNR
        , LLIEF
        , LSTAR
        , XOBEW
        , GRANT_NBR
        , ZUSTD_T156M
        , SPE_GTS_STOCK_TY
        , KBLNR
        , KBLPOS
        , XMACC
        , VGART_MKPF
        , BUDAT_MKPF
        , CPUDT_MKPF
        , CPUTM_MKPF
        , USNAM_MKPF
        , XBLNR_MKPF
        , TCODE2_MKPF
        , VBELN_IM
        , VBELP_IM
        , SGT_SCAT
        , SGT_UMSCAT
        , SGT_RCAT
        , BEV2_ED_KZ_VER
        , BEV2_ED_USER
        , BEV2_ED_AEDAT
        , BEV2_ED_AETIM
        , DISUB_OWNER
        , FSH_SEASON_YEAR
        , FSH_SEASON
        , FSH_COLLECTION
        , FSH_THEME
        , FSH_UMSEA_YR
        , FSH_UMSEA
        , FSH_UMCOLL
        , FSH_UMTHEME
        , SGT_CHINT
        , FSH_DEALLOC_QTY
        , OINAVNW
        , OICONDCOD
        , CONDI
        , WRF_CHARSTC1
        , WRF_CHARSTC2
        , WRF_CHARSTC3
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
    WHERE existing.LNK_GOODS_MOVEMENT_HK = JOIN_RESULT.LNK_GOODS_MOVEMENT_HK  
AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %}
{% if not is_incremental() %}

/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per HK and hashdiff. */
qualify 1 = row_number() over (partition by LNK_GOODS_MOVEMENT_HK, HASHDIFF order by PSA_LOAD_DTS)

union all
SELECT
MD5_BINARY(GR.VALUE) AS LNK_GOODS_MOVEMENT_HK,
NULL AS MANDT,
GR.VALUE::text AS MBLNR,
GR.VALUE::text AS MJAHR,
GR.VALUE::text AS ZEILE,
NULL AS GLREQUEST,
GR.VALUE::text AS LINE_ID,
NULL AS PARENT_ID,
NULL AS LINE_DEPTH,
NULL AS MAA_URZEI,
NULL AS BWART,
NULL AS XAUTO,
GR.VALUE::text AS MATNR,
GR.VALUE::text AS WERKS,
GR.VALUE::text AS LGORT,
NULL AS CHARG,
NULL AS INSMK,
NULL AS ZUSCH,
NULL AS ZUSTD,
NULL AS SOBKZ,
GR.VALUE::text AS LIFNR,
GR.VALUE::text AS KUNNR,
GR.VALUE::text AS KDAUF,
GR.VALUE::text AS KDPOS,
NULL AS KDEIN,
NULL AS PLPLA,
NULL AS SHKZG,
NULL AS WAERS,
NULL AS DMBTR,
NULL AS BNBTR,
NULL AS BUALT,
NULL AS SHKUM,
NULL AS DMBUM,
NULL AS BWTAR,
NULL AS MENGE,
GR.VALUE::text AS MEINS,
NULL AS ERFMG,
NULL AS ERFME,
NULL AS BPMNG,
NULL AS BPRME,
GR.VALUE::text AS EBELN,
GR.VALUE::text AS EBELP,
NULL AS LFBJA,
NULL AS LFBNR,
NULL AS LFPOS,
NULL AS SJAHR,
NULL AS SMBLN,
NULL AS SMBLP,
NULL AS ELIKZ,
NULL AS SGTXT,
NULL AS EQUNR,
GR.VALUE::text AS WEMPF,
NULL AS ABLAD,
NULL AS GSBER,
NULL AS KOKRS,
NULL AS PARGB,
NULL AS PARBU,
NULL AS KOSTL,
NULL AS PROJN,
GR.VALUE::text AS AUFNR,
NULL AS ANLN1,
NULL AS ANLN2,
NULL AS XSKST,
NULL AS XSAUF,
NULL AS XSPRO,
NULL AS XSERG,
NULL AS GJAHR,
NULL AS XRUEM,
NULL AS XRUEJ,
NULL AS BUKRS,
NULL AS BELNR,
NULL AS BUZEI,
NULL AS BELUM,
NULL AS BUZUM,
NULL AS RSNUM,
NULL AS RSPOS,
NULL AS KZEAR,
NULL AS PBAMG,
NULL AS KZSTR,
NULL AS UMMAT,
NULL AS UMWRK,
NULL AS UMLGO,
NULL AS UMCHA,
NULL AS UMZST,
NULL AS UMZUS,
NULL AS UMBAR,
NULL AS UMSOK,
NULL AS KZBEW,
NULL AS KZVBR,
NULL AS KZZUG,
NULL AS WEUNB,
NULL AS PALAN,
NULL AS LGNUM,
NULL AS LGTYP,
NULL AS LGPLA,
NULL AS BESTQ,
NULL AS BWLVS,
NULL AS TBNUM,
NULL AS TBPOS,
NULL AS XBLVS,
NULL AS VSCHN,
NULL AS NSCHN,
NULL AS DYPLA,
NULL AS UBNUM,
NULL AS TBPRI,
NULL AS TANUM,
NULL AS WEANZ,
NULL AS GRUND,
NULL AS EVERS,
NULL AS EVERE,
NULL AS IMKEY,
NULL AS KSTRG,
NULL AS PAOBJNR,
NULL AS PRCTR,
NULL AS PS_PSP_PNR,
NULL AS NPLNR,
NULL AS AUFPL,
NULL AS APLZL,
NULL AS AUFPS,
NULL AS VPTNR,
NULL AS FIPOS,
NULL AS SAKTO,
NULL AS BSTMG,
NULL AS BSTME,
NULL AS XWSBR,
NULL AS EMLIF,
NULL AS ZZALTKT,
NULL AS EXBWR,
NULL AS VKWRT,
NULL AS AKTNR,
NULL AS ZEKKN,
NULL AS VFDAT,
NULL AS CUOBJ_CH,
NULL AS EXVKW,
NULL AS PPRCTR,
NULL AS RSART,
NULL AS GEBER,
NULL AS FISTL,
NULL AS MATBF,
NULL AS UMMAB,
NULL AS BUSTM,
NULL AS BUSTW,
NULL AS MENGU,
NULL AS WERTU,
NULL AS LBKUM,
NULL AS SALK3,
NULL AS VPRSV,
NULL AS FKBER,
NULL AS DABRBZ,
NULL AS VKWRA,
NULL AS DABRZ,
NULL AS XBEAU,
NULL AS LSMNG,
NULL AS LSMEH,
NULL AS KZBWS,
NULL AS QINSPST,
NULL AS URZEI,
NULL AS J_1BEXBASE,
NULL AS MWSKZ,
NULL AS TXJCD,
NULL AS EMATN,
NULL AS J_1AGIRUPD,
NULL AS VKMWS,
NULL AS HSDAT,
NULL AS BERKZ,
NULL AS MAT_KDAUF,
NULL AS MAT_KDPOS,
NULL AS MAT_PSPNR,
NULL AS XWOFF,
NULL AS BEMOT,
NULL AS PRZNR,
NULL AS LLIEF,
NULL AS LSTAR,
NULL AS XOBEW,
NULL AS GRANT_NBR,
NULL AS ZUSTD_T156M,
NULL AS SPE_GTS_STOCK_TY,
NULL AS KBLNR,
NULL AS KBLPOS,
NULL AS XMACC,
NULL AS VGART_MKPF,
NULL AS BUDAT_MKPF,
NULL AS CPUDT_MKPF,
NULL AS CPUTM_MKPF,
NULL AS USNAM_MKPF,
NULL AS XBLNR_MKPF,
NULL AS TCODE2_MKPF,
GR.VALUE::text AS VBELN_IM,
GR.VALUE::text AS VBELP_IM,
NULL AS SGT_SCAT,
NULL AS SGT_UMSCAT,
NULL AS SGT_RCAT,
NULL AS BEV2_ED_KZ_VER,
NULL AS BEV2_ED_USER,
NULL AS BEV2_ED_AEDAT,
NULL AS BEV2_ED_AETIM,
NULL AS DISUB_OWNER,
NULL AS FSH_SEASON_YEAR,
NULL AS FSH_SEASON,
NULL AS FSH_COLLECTION,
NULL AS FSH_THEME,
NULL AS FSH_UMSEA_YR,
NULL AS FSH_UMSEA,
NULL AS FSH_UMCOLL,
NULL AS FSH_UMTHEME,
NULL AS SGT_CHINT,
NULL AS FSH_DEALLOC_QTY,
NULL AS OINAVNW,
NULL AS OICONDCOD,
NULL AS CONDI,
NULL AS WRF_CHARSTC1,
NULL AS WRF_CHARSTC2,
NULL AS WRF_CHARSTC3,
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
