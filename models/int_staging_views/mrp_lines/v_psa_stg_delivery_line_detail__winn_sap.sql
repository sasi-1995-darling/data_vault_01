---- SRC LAYER ----
WITH
SRC_lips           as ( SELECT ABART, ABELN, ABELP, ABFOR, ABGES, ABRLI, ABRVW, ABTNR, AEDAT, AESKD, AKKUR, AKMNG, AKTNR, ANTLF, ANZSN, ARKTX, AUFNR, 
                        AUREL, BDART, BEDAR_LF, BERID, BERKZ, BESTQ, BPMNG, BRGEW, BUDGET_PD, BWART, BWLVS, BWTAR, BWTEX, CHARG, CHHPV, CHMVS, CHSPL, 
                        CLINT, CMPNT, CMPRE_FLT, CONS_ORDER, CUOBJ, CUOBJ_CH, DLVTP, EAN11, EANNR, EMATN, EMPST, EPRIO, ERDAT, ERNAM, ERZET, EXART, 
                        EXBWR, EXVKW, FAKSP, FARR_RELTYPE, FIPOS, FISTL, FKBER, FKREL, FLGWM, FMENG, FOBWA, FSH_COLLECTION, FSH_ITEM, FSH_ITEM_GROUP, 
                        FSH_KVGR10, FSH_KVGR6, FSH_KVGR7, FSH_KVGR8, FSH_KVGR9, FSH_RSNUM, FSH_RSPOS, FSH_SEASON, FSH_SEASON_YEAR, FSH_THEME, 
                        FSH_TRANSACTION, FSH_VAS_PRNT_ID, FSH_VAS_REL, GEBER, GEWEI, GLCHANGETIME, GLDELFLAG, GLREQUEST, GLSOURCESYSTEM, GMCONTROL, 
                        GRANT_NBR, GRKOR, GRUND, GSBER, HANDLE, HSDAT, HUPOS, INSMK, J_1BCFOP, J_1BTAXLW1, J_1BTAXLW2, J_1BTAXLW3, J_1BTAXLW4, 
                        J_1BTAXLW5, J_1BTXSDC, KANNR, KBNKZ, KCBRGEW, KCGEWEI, KCMENG, KCMENGVME, KCMENGVMEF, KCMENG_FLO, KCNTGEW, KCVOLEH, KCVOLUM, 
                        KDAUF, KDMAT, KDPOS, KMEIN, KMPMG, KNTTP, KNUMH_CH, KOKRS, KOMKZ, KONTO, KOQUI, KOSTL, KOWRR, KPEIN, KVGR1, KVGR2, KVGR3, KVGR4, 
                        KVGR5, KZBEF, KZBEW, KZBWS, KZDLG, KZEAR, KZECH, KZFME, KZPOD, KZTLF, KZUML, KZUMW, KZVBR, KZWI1, KZWI2, KZWI3, KZWI4, KZWI5, 
                        KZWI6, KZWSO, LADGR, LFBNR, LFDEZ, LFGJA, LFIMG, LFIMG_FLO, LFPOS, LGBZO, LGMNG, LGMNG_FLO, LGNUM, LGORT, LGPBE, LGPLA, LGTYP, 
                        LICHN, LIFEXPOS, LISPL, MAGRV, MANDT, MATKL, MATNR, MATWA, MBDAT, MBUHR, MEINS, MFRGR, MPROF, MTART, MTVFP, MVGR1, MVGR2, MVGR3, 
                        MVGR4, MVGR5, NACHL, NETPR, NETWR, NOATP, NOPCK, NOWAB, NTGEW, OBJKO, OBJPO, ORMNG, PAOBJNR, PCKPF, PLART, PODREL, POSAR, POSNR, 
                        POSNR_PP, POSNV, POSTING_CHANGE, PRBME, PRCTR, PREFE, PRE_VL_ETENS, PRODH, PROFL, PROSA, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, 
                        PSPNR, PSTYV, PS_PSP_PNR, QPLOS, QTLOS, RBLVS, RFVGTYP, RSART, RSNUM, RSPOS, RULES, SERAIL, SERNR, SGT_RCAT, SGT_SCAT, SHKZG, SHKZG_UM, 
                        SITKZ, SITUA, SOBKZ, SONUM, SPART, SPE_ALTERNATE, SPE_APO_QNTYDIV, SPE_APO_QNTYFAC, SPE_ATP_TMSTMP, SPE_AUTH_COMPLET, SPE_AUTH_NUMBER, 
                        SPE_BXP_DATE_EXT, SPE_COMPL_MVT, SPE_EXCEPT_CODE, SPE_EXP_DATE_EXT, SPE_EXP_DATE_INT, SPE_FOLLOW_UP, SPE_GEN_ELIKZ, SPE_HERKL, SPE_IMWRK, 
                        SPE_INSPOUT_GUID, SPE_KEEP_QTY, SPE_LIEFFZ, SPE_LIFEXPOS2, SPE_MAT_SUBST, SPE_ORIG_SYS, SPE_SCRAP_IND, SPE_STRUC, SPE_VERSION, STADAT, 
                        STAFO, SUMBD, TRAGR, UEBTK, UEBTO, UECHA, UEPOS, UEPVW, UMBAR, UMBSQ, UMCHA, UMLGO, UMMAT, UMREF, UMREV, UMSOK, UMVKN, UMVKZ, UMWRK, 
                        UM_PS_PSP_PNR, UNTTO, UPFLU, USONU, VBEAF, VBEAV, VBELN, VBELV, VBTYV, VERURPOS, VFDAT, VGBEL, VGPOS, VGREF, VGSYS, VGTYP, VKBUR, VKGRP, 
                        VKGRU, VOLEH, VOLUM, VPMAT, VPWRK, VPZUO, VRKME, VTWEG, WAVWR, WERKS, WKTNR, WKTPS, WRF_CHARSTC1, WRF_CHARSTC2, WRF_CHARSTC3, XCHAR, 
                        XCHPF, ZZAVAILABLE, ZZUPDATE_ETA FROM {{ source('sap_ecc_prd', 'z_lips') }} as SRC  ),
SRC_a              as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_lips           as ( SELECT * FROM sap_ecc_prd.z_lips )
SRC_a              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_lips as (
    SELECT
        VBELN                                                        as                                        DELIVERY_BK
      , POSNR                                                        as                              DELIVERY_LINE_ITEM_BK
      , COALESCE(NULLIF(TRIM(MATNR), ''), '-1')                      as                                            ITEM_BK
      , COALESCE(NULLIF(TRIM(VGBEL), ''), '-1')                      as                                    ORDER_HEADER_BK
      , CONCAT_WS('||', COALESCE(NULLIF(TRIM(VGBEL), ''), '-1'), COALESCE(NULLIF(TRIM(VGPOS), ''), '-1')) as                                      ORDER_LINE_BK
      , COALESCE(NULLIF(TRIM(WERKS), ''), '-1')                      as                                           PLANT_BK
      , COALESCE(NULLIF(TRIM(LGORT), ''), '-1')                      as                          GOODS_STORAGE_LOCATION_BK
      , COALESCE(NULLIF(TRIM(VTWEG), ''), '-1')                      as                            DISTRIBUTION_CHANNEL_BK
      , COALESCE(NULLIF(TRIM(SPART), ''), '-1')                      as                                        DIVISION_BK
      , COALESCE(NULLIF(TRIM(KOSTL), ''), '-1')                      as                                     COST_CENTER_BK
      , MANDT
      , VBELN
      , POSNR
      , GLREQUEST
      , PSTYV
      , ERNAM
      , ERZET
      , ERDAT
      , TRY_TO_DATE(ERDAT, 'YYYYMMDD')                               as                                           ERDAT_DT
      , MATNR
      , MATWA
      , MATKL
      , WERKS
      , LGORT
      , CHARG
      , LICHN
      , KDMAT
      , PRODH
      , LFIMG
      , MEINS
      , VRKME
      , UMVKZ
      , UMVKN
      , NTGEW
      , BRGEW
      , GEWEI
      , VOLUM
      , VOLEH
      , KZTLF
      , UEBTK
      , UEBTO
      , UNTTO
      , CHSPL
      , FAKSP
      , MBDAT
      , TRY_TO_DATE(MBDAT, 'YYYYMMDD')                               as                                           MBDAT_DT
      , LGMNG
      , ARKTX
      , LGPBE
      , VBELV
      , POSNV
      , VBTYV
      , VGSYS
      , VGBEL
      , VGPOS
      , UPFLU
      , UEPOS
      , FKREL
      , LADGR
      , TRAGR
      , KOMKZ
      , LGNUM
      , LISPL
      , LGTYP
      , LGPLA
      , BWTEX
      , BWART
      , BWLVS
      , KZDLG
      , BDART
      , PLART
      , MTART
      , XCHPF
      , XCHAR
      , VGREF
      , POSAR
      , BWTAR
      , SUMBD
      , MTVFP
      , EANNR
      , GSBER
      , VKBUR
      , VKGRP
      , VTWEG
      , SPART
      , GRKOR
      , FMENG
      , ANTLF
      , VBEAF
      , VBEAV
      , STAFO
      , WAVWR
      , KZWI1
      , KZWI2
      , KZWI3
      , KZWI4
      , KZWI5
      , KZWI6
      , SOBKZ
      , AEDAT
      , TRY_TO_DATE(AEDAT, 'YYYYMMDD')                               as                                           AEDAT_DT
      , EAN11
      , KVGR1
      , KVGR2
      , KVGR3
      , KVGR4
      , KVGR5
      , MVGR1
      , MVGR2
      , MVGR3
      , MVGR4
      , MVGR5
      , VPZUO
      , VGTYP
      , RFVGTYP
      , KOSTL
      , KOKRS
      , PAOBJNR
      , PRCTR
      , PS_PSP_PNR
      , AUFNR
      , POSNR_PP
      , KDAUF
      , KDPOS
      , VPMAT
      , VPWRK
      , PRBME
      , UMREF
      , KNTTP
      , KZVBR
      , FIPOS
      , FISTL
      , GEBER
      , PCKPF
      , BEDAR_LF
      , CMPNT
      , KCMENG
      , KCBRGEW
      , KCNTGEW
      , KCVOLUM
      , UECHA
      , CUOBJ
      , CUOBJ_CH
      , ANZSN
      , SERAIL
      , KCGEWEI
      , KCVOLEH
      , SERNR
      , ABRLI
      , ABART
      , ABRVW
      , QPLOS
      , QTLOS
      , NACHL
      , MAGRV
      , OBJKO
      , OBJPO
      , AESKD
      , SHKZG
      , PROSA
      , UEPVW
      , EMPST
      , ABTNR
      , KOQUI
      , STADAT
      , AKTNR
      , KNUMH_CH
      , PREFE
      , EXART
      , CLINT
      , CHMVS
      , ABELN
      , ABELP
      , LFIMG_FLO
      , LGMNG_FLO
      , KCMENG_FLO
      , KZUMW
      , KMPMG
      , AUREL
      , KPEIN
      , KMEIN
      , NETPR
      , NETWR
      , KOWRR
      , KZBEW
      , MFRGR
      , CHHPV
      , ABFOR
      , ABGES
      , MBUHR
      , WKTNR
      , WKTPS
      , J_1BCFOP
      , J_1BTAXLW1
      , J_1BTAXLW2
      , J_1BTXSDC
      , SITUA
      , RSNUM
      , RSPOS
      , RSART
      , KANNR
      , KZFME
      , PROFL
      , KCMENGVME
      , KCMENGVMEF
      , KZBWS
      , PSPNR
      , EPRIO
      , RULES
      , KZBEF
      , MPROF
      , EMATN
      , LGBZO
      , HANDLE
      , VERURPOS
      , LIFEXPOS
      , NOATP
      , NOPCK
      , RBLVS
      , BERID
      , BESTQ
      , UMBSQ
      , UMMAT
      , UMWRK
      , UMLGO
      , UMCHA
      , UMBAR
      , UMSOK
      , SONUM
      , USONU
      , AKKUR
      , AKMNG
      , VKGRU
      , SHKZG_UM
      , INSMK
      , KZECH
      , FLGWM
      , BERKZ
      , HUPOS
      , NOWAB
      , KONTO
      , KZEAR
      , HSDAT
      , VFDAT
      , LFGJA
      , LFBNR
      , LFPOS
      , GRUND
      , FOBWA
      , DLVTP
      , EXBWR
      , BPMNG
      , EXVKW
      , CMPRE_FLT
      , KZPOD
      , LFDEZ
      , UMREV
      , PODREL
      , KZUML
      , FKBER
      , GRANT_NBR
      , KZWSO
      , GMCONTROL
      , POSTING_CHANGE
      , UM_PS_PSP_PNR
      , PRE_VL_ETENS
      , SPE_GEN_ELIKZ
      , SPE_SCRAP_IND
      , SPE_AUTH_NUMBER
      , SPE_INSPOUT_GUID
      , SPE_FOLLOW_UP
      , SPE_EXP_DATE_EXT
      , SPE_EXP_DATE_INT
      , SPE_AUTH_COMPLET
      , ORMNG
      , SPE_ATP_TMSTMP
      , SPE_ORIG_SYS
      , SPE_LIEFFZ
      , SPE_IMWRK
      , SPE_LIFEXPOS2
      , SPE_EXCEPT_CODE
      , SPE_KEEP_QTY
      , SPE_ALTERNATE
      , SPE_MAT_SUBST
      , SPE_STRUC
      , SPE_APO_QNTYFAC
      , SPE_APO_QNTYDIV
      , SPE_HERKL
      , SPE_BXP_DATE_EXT
      , SPE_VERSION
      , SPE_COMPL_MVT
      , J_1BTAXLW4
      , J_1BTAXLW5
      , J_1BTAXLW3
      , BUDGET_PD
      , KBNKZ
      , FARR_RELTYPE
      , SITKZ
      , SGT_RCAT
      , SGT_SCAT
      , FSH_SEASON_YEAR
      , FSH_SEASON
      , FSH_COLLECTION
      , FSH_THEME
      , FSH_KVGR6
      , FSH_KVGR7
      , FSH_KVGR8
      , FSH_KVGR9
      , FSH_KVGR10
      , FSH_VAS_REL
      , FSH_VAS_PRNT_ID
      , FSH_TRANSACTION
      , FSH_ITEM_GROUP
      , FSH_ITEM
      , FSH_RSNUM
      , FSH_RSPOS
      , CONS_ORDER
      , WRF_CHARSTC1
      , WRF_CHARSTC2
      , WRF_CHARSTC3
      , ZZUPDATE_ETA
      , ZZAVAILABLE
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , IFF(
            PSA_DELETE_IND = 'Y',
            PSA_LOAD_DTS,
            CONVERT_TIMEZONE(
            'UTC',
            TO_TIMESTAMP_NTZ(
            SUBSTR(GLCHANGETIME, 1, 14) || '.' || SUBSTR(GLCHANGETIME, 16),
            'YYYYMMDDHH24MISS.FF9'
            )
            )
        )                                                            as                                           LOAD_DTS
    FROM SRC_lips
)

, LOGIC_a as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_a
)
---- RENAME LAYER ----

, RENAME_lips as (
    SELECT
        DELIVERY_BK
      , DELIVERY_LINE_ITEM_BK
      , ITEM_BK
      , ORDER_HEADER_BK
      , ORDER_LINE_BK
      , PLANT_BK
      , GOODS_STORAGE_LOCATION_BK
      , DISTRIBUTION_CHANNEL_BK
      , DIVISION_BK
      , COST_CENTER_BK
      , MANDT
      , VBELN
      , POSNR
      , GLREQUEST
      , PSTYV
      , ERNAM
      , ERZET
      , ERDAT
      , ERDAT_DT
      , MATNR
      , MATWA
      , MATKL
      , WERKS
      , LGORT
      , CHARG
      , LICHN
      , KDMAT
      , PRODH
      , LFIMG
      , MEINS
      , VRKME
      , UMVKZ
      , UMVKN
      , NTGEW
      , BRGEW
      , GEWEI
      , VOLUM
      , VOLEH
      , KZTLF
      , UEBTK
      , UEBTO
      , UNTTO
      , CHSPL
      , FAKSP
      , MBDAT
      , MBDAT_DT
      , LGMNG
      , ARKTX
      , LGPBE
      , VBELV
      , POSNV
      , VBTYV
      , VGSYS
      , VGBEL
      , VGPOS
      , UPFLU
      , UEPOS
      , FKREL
      , LADGR
      , TRAGR
      , KOMKZ
      , LGNUM
      , LISPL
      , LGTYP
      , LGPLA
      , BWTEX
      , BWART
      , BWLVS
      , KZDLG
      , BDART
      , PLART
      , MTART
      , XCHPF
      , XCHAR
      , VGREF
      , POSAR
      , BWTAR
      , SUMBD
      , MTVFP
      , EANNR
      , GSBER
      , VKBUR
      , VKGRP
      , VTWEG
      , SPART
      , GRKOR
      , FMENG
      , ANTLF
      , VBEAF
      , VBEAV
      , STAFO
      , WAVWR
      , KZWI1
      , KZWI2
      , KZWI3
      , KZWI4
      , KZWI5
      , KZWI6
      , SOBKZ
      , AEDAT
      , AEDAT_DT
      , EAN11
      , KVGR1
      , KVGR2
      , KVGR3
      , KVGR4
      , KVGR5
      , MVGR1
      , MVGR2
      , MVGR3
      , MVGR4
      , MVGR5
      , VPZUO
      , VGTYP
      , RFVGTYP
      , KOSTL
      , KOKRS
      , PAOBJNR
      , PRCTR
      , PS_PSP_PNR
      , AUFNR
      , POSNR_PP
      , KDAUF
      , KDPOS
      , VPMAT
      , VPWRK
      , PRBME
      , UMREF
      , KNTTP
      , KZVBR
      , FIPOS
      , FISTL
      , GEBER
      , PCKPF
      , BEDAR_LF
      , CMPNT
      , KCMENG
      , KCBRGEW
      , KCNTGEW
      , KCVOLUM
      , UECHA
      , CUOBJ
      , CUOBJ_CH
      , ANZSN
      , SERAIL
      , KCGEWEI
      , KCVOLEH
      , SERNR
      , ABRLI
      , ABART
      , ABRVW
      , QPLOS
      , QTLOS
      , NACHL
      , MAGRV
      , OBJKO
      , OBJPO
      , AESKD
      , SHKZG
      , PROSA
      , UEPVW
      , EMPST
      , ABTNR
      , KOQUI
      , STADAT
      , AKTNR
      , KNUMH_CH
      , PREFE
      , EXART
      , CLINT
      , CHMVS
      , ABELN
      , ABELP
      , LFIMG_FLO
      , LGMNG_FLO
      , KCMENG_FLO
      , KZUMW
      , KMPMG
      , AUREL
      , KPEIN
      , KMEIN
      , NETPR
      , NETWR
      , KOWRR
      , KZBEW
      , MFRGR
      , CHHPV
      , ABFOR
      , ABGES
      , MBUHR
      , WKTNR
      , WKTPS
      , J_1BCFOP
      , J_1BTAXLW1
      , J_1BTAXLW2
      , J_1BTXSDC
      , SITUA
      , RSNUM
      , RSPOS
      , RSART
      , KANNR
      , KZFME
      , PROFL
      , KCMENGVME
      , KCMENGVMEF
      , KZBWS
      , PSPNR
      , EPRIO
      , RULES
      , KZBEF
      , MPROF
      , EMATN
      , LGBZO
      , HANDLE
      , VERURPOS
      , LIFEXPOS
      , NOATP
      , NOPCK
      , RBLVS
      , BERID
      , BESTQ
      , UMBSQ
      , UMMAT
      , UMWRK
      , UMLGO
      , UMCHA
      , UMBAR
      , UMSOK
      , SONUM
      , USONU
      , AKKUR
      , AKMNG
      , VKGRU
      , SHKZG_UM
      , INSMK
      , KZECH
      , FLGWM
      , BERKZ
      , HUPOS
      , NOWAB
      , KONTO
      , KZEAR
      , HSDAT
      , VFDAT
      , LFGJA
      , LFBNR
      , LFPOS
      , GRUND
      , FOBWA
      , DLVTP
      , EXBWR
      , BPMNG
      , EXVKW
      , CMPRE_FLT
      , KZPOD
      , LFDEZ
      , UMREV
      , PODREL
      , KZUML
      , FKBER
      , GRANT_NBR
      , KZWSO
      , GMCONTROL
      , POSTING_CHANGE
      , UM_PS_PSP_PNR
      , PRE_VL_ETENS
      , SPE_GEN_ELIKZ
      , SPE_SCRAP_IND
      , SPE_AUTH_NUMBER
      , SPE_INSPOUT_GUID
      , SPE_FOLLOW_UP
      , SPE_EXP_DATE_EXT
      , SPE_EXP_DATE_INT
      , SPE_AUTH_COMPLET
      , ORMNG
      , SPE_ATP_TMSTMP
      , SPE_ORIG_SYS
      , SPE_LIEFFZ
      , SPE_IMWRK
      , SPE_LIFEXPOS2
      , SPE_EXCEPT_CODE
      , SPE_KEEP_QTY
      , SPE_ALTERNATE
      , SPE_MAT_SUBST
      , SPE_STRUC
      , SPE_APO_QNTYFAC
      , SPE_APO_QNTYDIV
      , SPE_HERKL
      , SPE_BXP_DATE_EXT
      , SPE_VERSION
      , SPE_COMPL_MVT
      , J_1BTAXLW4
      , J_1BTAXLW5
      , J_1BTAXLW3
      , BUDGET_PD
      , KBNKZ
      , FARR_RELTYPE
      , SITKZ
      , SGT_RCAT
      , SGT_SCAT
      , FSH_SEASON_YEAR
      , FSH_SEASON
      , FSH_COLLECTION
      , FSH_THEME
      , FSH_KVGR6
      , FSH_KVGR7
      , FSH_KVGR8
      , FSH_KVGR9
      , FSH_KVGR10
      , FSH_VAS_REL
      , FSH_VAS_PRNT_ID
      , FSH_TRANSACTION
      , FSH_ITEM_GROUP
      , FSH_ITEM
      , FSH_RSNUM
      , FSH_RSPOS
      , CONS_ORDER
      , WRF_CHARSTC1
      , WRF_CHARSTC2
      , WRF_CHARSTC3
      , ZZUPDATE_ETA
      , ZZAVAILABLE
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
    FROM LOGIC_lips
)

, RENAME_a as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_a
)
---- FILTER LAYER ----

, FILTER_lips as (
    SELECT *
    FROM RENAME_lips
)

, FILTER_a as (
    SELECT *
    FROM RENAME_a
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_LIPS'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_lips
    INNER JOIN FILTER_a
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          DELIVERY_BK
        , DELIVERY_LINE_ITEM_BK
        , ITEM_BK
        , ORDER_HEADER_BK
        , ORDER_LINE_BK
        , PLANT_BK
        , GOODS_STORAGE_LOCATION_BK
        , DISTRIBUTION_CHANNEL_BK
        , DIVISION_BK
        , COST_CENTER_BK
        , MANDT
        , VBELN
        , POSNR
        , GLREQUEST
        , PSTYV
        , ERNAM
        , ERZET
        , ERDAT
        , ERDAT_DT
        , MATNR
        , MATWA
        , MATKL
        , WERKS
        , LGORT
        , CHARG
        , LICHN
        , KDMAT
        , PRODH
        , LFIMG
        , MEINS
        , VRKME
        , UMVKZ
        , UMVKN
        , NTGEW
        , BRGEW
        , GEWEI
        , VOLUM
        , VOLEH
        , KZTLF
        , UEBTK
        , UEBTO
        , UNTTO
        , CHSPL
        , FAKSP
        , MBDAT
        , MBDAT_DT
        , LGMNG
        , ARKTX
        , LGPBE
        , VBELV
        , POSNV
        , VBTYV
        , VGSYS
        , VGBEL
        , VGPOS
        , UPFLU
        , UEPOS
        , FKREL
        , LADGR
        , TRAGR
        , KOMKZ
        , LGNUM
        , LISPL
        , LGTYP
        , LGPLA
        , BWTEX
        , BWART
        , BWLVS
        , KZDLG
        , BDART
        , PLART
        , MTART
        , XCHPF
        , XCHAR
        , VGREF
        , POSAR
        , BWTAR
        , SUMBD
        , MTVFP
        , EANNR
        , GSBER
        , VKBUR
        , VKGRP
        , VTWEG
        , SPART
        , GRKOR
        , FMENG
        , ANTLF
        , VBEAF
        , VBEAV
        , STAFO
        , WAVWR
        , KZWI1
        , KZWI2
        , KZWI3
        , KZWI4
        , KZWI5
        , KZWI6
        , SOBKZ
        , AEDAT
        , AEDAT_DT
        , EAN11
        , KVGR1
        , KVGR2
        , KVGR3
        , KVGR4
        , KVGR5
        , MVGR1
        , MVGR2
        , MVGR3
        , MVGR4
        , MVGR5
        , VPZUO
        , VGTYP
        , RFVGTYP
        , KOSTL
        , KOKRS
        , PAOBJNR
        , PRCTR
        , PS_PSP_PNR
        , AUFNR
        , POSNR_PP
        , KDAUF
        , KDPOS
        , VPMAT
        , VPWRK
        , PRBME
        , UMREF
        , KNTTP
        , KZVBR
        , FIPOS
        , FISTL
        , GEBER
        , PCKPF
        , BEDAR_LF
        , CMPNT
        , KCMENG
        , KCBRGEW
        , KCNTGEW
        , KCVOLUM
        , UECHA
        , CUOBJ
        , CUOBJ_CH
        , ANZSN
        , SERAIL
        , KCGEWEI
        , KCVOLEH
        , SERNR
        , ABRLI
        , ABART
        , ABRVW
        , QPLOS
        , QTLOS
        , NACHL
        , MAGRV
        , OBJKO
        , OBJPO
        , AESKD
        , SHKZG
        , PROSA
        , UEPVW
        , EMPST
        , ABTNR
        , KOQUI
        , STADAT
        , AKTNR
        , KNUMH_CH
        , PREFE
        , EXART
        , CLINT
        , CHMVS
        , ABELN
        , ABELP
        , LFIMG_FLO
        , LGMNG_FLO
        , KCMENG_FLO
        , KZUMW
        , KMPMG
        , AUREL
        , KPEIN
        , KMEIN
        , NETPR
        , NETWR
        , KOWRR
        , KZBEW
        , MFRGR
        , CHHPV
        , ABFOR
        , ABGES
        , MBUHR
        , WKTNR
        , WKTPS
        , J_1BCFOP
        , J_1BTAXLW1
        , J_1BTAXLW2
        , J_1BTXSDC
        , SITUA
        , RSNUM
        , RSPOS
        , RSART
        , KANNR
        , KZFME
        , PROFL
        , KCMENGVME
        , KCMENGVMEF
        , KZBWS
        , PSPNR
        , EPRIO
        , RULES
        , KZBEF
        , MPROF
        , EMATN
        , LGBZO
        , HANDLE
        , VERURPOS
        , LIFEXPOS
        , NOATP
        , NOPCK
        , RBLVS
        , BERID
        , BESTQ
        , UMBSQ
        , UMMAT
        , UMWRK
        , UMLGO
        , UMCHA
        , UMBAR
        , UMSOK
        , SONUM
        , USONU
        , AKKUR
        , AKMNG
        , VKGRU
        , SHKZG_UM
        , INSMK
        , KZECH
        , FLGWM
        , BERKZ
        , HUPOS
        , NOWAB
        , KONTO
        , KZEAR
        , HSDAT
        , VFDAT
        , LFGJA
        , LFBNR
        , LFPOS
        , GRUND
        , FOBWA
        , DLVTP
        , EXBWR
        , BPMNG
        , EXVKW
        , CMPRE_FLT
        , KZPOD
        , LFDEZ
        , UMREV
        , PODREL
        , KZUML
        , FKBER
        , GRANT_NBR
        , KZWSO
        , GMCONTROL
        , POSTING_CHANGE
        , UM_PS_PSP_PNR
        , PRE_VL_ETENS
        , SPE_GEN_ELIKZ
        , SPE_SCRAP_IND
        , SPE_AUTH_NUMBER
        , SPE_INSPOUT_GUID
        , SPE_FOLLOW_UP
        , SPE_EXP_DATE_EXT
        , SPE_EXP_DATE_INT
        , SPE_AUTH_COMPLET
        , ORMNG
        , SPE_ATP_TMSTMP
        , SPE_ORIG_SYS
        , SPE_LIEFFZ
        , SPE_IMWRK
        , SPE_LIFEXPOS2
        , SPE_EXCEPT_CODE
        , SPE_KEEP_QTY
        , SPE_ALTERNATE
        , SPE_MAT_SUBST
        , SPE_STRUC
        , SPE_APO_QNTYFAC
        , SPE_APO_QNTYDIV
        , SPE_HERKL
        , SPE_BXP_DATE_EXT
        , SPE_VERSION
        , SPE_COMPL_MVT
        , J_1BTAXLW4
        , J_1BTAXLW5
        , J_1BTAXLW3
        , BUDGET_PD
        , KBNKZ
        , FARR_RELTYPE
        , SITKZ
        , SGT_RCAT
        , SGT_SCAT
        , FSH_SEASON_YEAR
        , FSH_SEASON
        , FSH_COLLECTION
        , FSH_THEME
        , FSH_KVGR6
        , FSH_KVGR7
        , FSH_KVGR8
        , FSH_KVGR9
        , FSH_KVGR10
        , FSH_VAS_REL
        , FSH_VAS_PRNT_ID
        , FSH_TRANSACTION
        , FSH_ITEM_GROUP
        , FSH_ITEM
        , FSH_RSNUM
        , FSH_RSPOS
        , CONS_ORDER
        , WRF_CHARSTC1
        , WRF_CHARSTC2
        , WRF_CHARSTC3
        , ZZUPDATE_ETA
        , ZZAVAILABLE
        , GLDELFLAG
        , GLCHANGETIME
        , GLSOURCESYSTEM
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(VBELN as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as DELIVERY_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(VBELN as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(POSNR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as DELIVERY_LINE_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ITEM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ITEM_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ORDER_HEADER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ORDER_HEADER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ORDER_LINE_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ORDER_LINE_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PLANT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PLANT_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(GOODS_STORAGE_LOCATION_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as GOODS_STORAGE_LOCATION_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(DISTRIBUTION_CHANNEL_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as DISTRIBUTION_CHANNEL_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(DIVISION_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as DIVISION_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(COST_CENTER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as COST_CENTER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(VBELN as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(VBELN as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(POSNR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(ITEM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(ORDER_HEADER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(ORDER_LINE_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(PLANT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(GOODS_STORAGE_LOCATION_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(DISTRIBUTION_CHANNEL_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(DIVISION_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(COST_CENTER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as DELIVERY_LINE_DETAIL_LHK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(MANDT::text), '^^') 
            , '||', IFNULL(TRIM(VBELN::text), '^^') 
            , '||', IFNULL(TRIM(POSNR::text), '^^') 
            , '||', IFNULL(TRIM(PSTYV::text), '^^') 
            , '||', IFNULL(TRIM(ERNAM::text), '^^') 
            , '||', IFNULL(TRIM(ERZET::text), '^^') 
            , '||', IFNULL(TRIM(ERDAT::text), '^^') 
            , '||', IFNULL(TRIM(MATNR::text), '^^') 
            , '||', IFNULL(TRIM(MATWA::text), '^^') 
            , '||', IFNULL(TRIM(MATKL::text), '^^') 
            , '||', IFNULL(TRIM(WERKS::text), '^^') 
            , '||', IFNULL(TRIM(LGORT::text), '^^') 
            , '||', IFNULL(TRIM(CHARG::text), '^^') 
            , '||', IFNULL(TRIM(LICHN::text), '^^') 
            , '||', IFNULL(TRIM(KDMAT::text), '^^') 
            , '||', IFNULL(TRIM(PRODH::text), '^^') 
            , '||', IFNULL(TRIM(LFIMG::text), '^^') 
            , '||', IFNULL(TRIM(MEINS::text), '^^') 
            , '||', IFNULL(TRIM(VRKME::text), '^^') 
            , '||', IFNULL(TRIM(UMVKZ::text), '^^') 
            , '||', IFNULL(TRIM(UMVKN::text), '^^') 
            , '||', IFNULL(TRIM(NTGEW::text), '^^') 
            , '||', IFNULL(TRIM(BRGEW::text), '^^') 
            , '||', IFNULL(TRIM(GEWEI::text), '^^') 
            , '||', IFNULL(TRIM(VOLUM::text), '^^') 
            , '||', IFNULL(TRIM(VOLEH::text), '^^') 
            , '||', IFNULL(TRIM(KZTLF::text), '^^') 
            , '||', IFNULL(TRIM(UEBTK::text), '^^') 
            , '||', IFNULL(TRIM(UEBTO::text), '^^') 
            , '||', IFNULL(TRIM(UNTTO::text), '^^') 
            , '||', IFNULL(TRIM(CHSPL::text), '^^') 
            , '||', IFNULL(TRIM(FAKSP::text), '^^') 
            , '||', IFNULL(TRIM(MBDAT::text), '^^') 
            , '||', IFNULL(TRIM(LGMNG::text), '^^') 
            , '||', IFNULL(TRIM(ARKTX::text), '^^') 
            , '||', IFNULL(TRIM(LGPBE::text), '^^') 
            , '||', IFNULL(TRIM(VBELV::text), '^^') 
            , '||', IFNULL(TRIM(POSNV::text), '^^') 
            , '||', IFNULL(TRIM(VBTYV::text), '^^') 
            , '||', IFNULL(TRIM(VGSYS::text), '^^') 
            , '||', IFNULL(TRIM(VGBEL::text), '^^') 
            , '||', IFNULL(TRIM(VGPOS::text), '^^') 
            , '||', IFNULL(TRIM(UPFLU::text), '^^') 
            , '||', IFNULL(TRIM(UEPOS::text), '^^') 
            , '||', IFNULL(TRIM(FKREL::text), '^^') 
            , '||', IFNULL(TRIM(LADGR::text), '^^') 
            , '||', IFNULL(TRIM(TRAGR::text), '^^') 
            , '||', IFNULL(TRIM(KOMKZ::text), '^^') 
            , '||', IFNULL(TRIM(LGNUM::text), '^^') 
            , '||', IFNULL(TRIM(LISPL::text), '^^') 
            , '||', IFNULL(TRIM(LGTYP::text), '^^') 
            , '||', IFNULL(TRIM(LGPLA::text), '^^') 
            , '||', IFNULL(TRIM(BWTEX::text), '^^') 
            , '||', IFNULL(TRIM(BWART::text), '^^') 
            , '||', IFNULL(TRIM(BWLVS::text), '^^') 
            , '||', IFNULL(TRIM(KZDLG::text), '^^') 
            , '||', IFNULL(TRIM(BDART::text), '^^') 
            , '||', IFNULL(TRIM(PLART::text), '^^') 
            , '||', IFNULL(TRIM(MTART::text), '^^') 
            , '||', IFNULL(TRIM(XCHPF::text), '^^') 
            , '||', IFNULL(TRIM(XCHAR::text), '^^') 
            , '||', IFNULL(TRIM(VGREF::text), '^^') 
            , '||', IFNULL(TRIM(POSAR::text), '^^') 
            , '||', IFNULL(TRIM(BWTAR::text), '^^') 
            , '||', IFNULL(TRIM(SUMBD::text), '^^') 
            , '||', IFNULL(TRIM(MTVFP::text), '^^') 
            , '||', IFNULL(TRIM(EANNR::text), '^^') 
            , '||', IFNULL(TRIM(GSBER::text), '^^') 
            , '||', IFNULL(TRIM(VKBUR::text), '^^') 
            , '||', IFNULL(TRIM(VKGRP::text), '^^') 
            , '||', IFNULL(TRIM(VTWEG::text), '^^') 
            , '||', IFNULL(TRIM(SPART::text), '^^') 
            , '||', IFNULL(TRIM(GRKOR::text), '^^') 
            , '||', IFNULL(TRIM(FMENG::text), '^^') 
            , '||', IFNULL(TRIM(ANTLF::text), '^^') 
            , '||', IFNULL(TRIM(VBEAF::text), '^^') 
            , '||', IFNULL(TRIM(VBEAV::text), '^^') 
            , '||', IFNULL(TRIM(STAFO::text), '^^') 
            , '||', IFNULL(TRIM(WAVWR::text), '^^') 
            , '||', IFNULL(TRIM(KZWI1::text), '^^') 
            , '||', IFNULL(TRIM(KZWI2::text), '^^') 
            , '||', IFNULL(TRIM(KZWI3::text), '^^') 
            , '||', IFNULL(TRIM(KZWI4::text), '^^') 
            , '||', IFNULL(TRIM(KZWI5::text), '^^') 
            , '||', IFNULL(TRIM(KZWI6::text), '^^') 
            , '||', IFNULL(TRIM(SOBKZ::text), '^^') 
            , '||', IFNULL(TRIM(AEDAT::text), '^^') 
            , '||', IFNULL(TRIM(EAN11::text), '^^') 
            , '||', IFNULL(TRIM(KVGR1::text), '^^') 
            , '||', IFNULL(TRIM(KVGR2::text), '^^') 
            , '||', IFNULL(TRIM(KVGR3::text), '^^') 
            , '||', IFNULL(TRIM(KVGR4::text), '^^') 
            , '||', IFNULL(TRIM(KVGR5::text), '^^') 
            , '||', IFNULL(TRIM(MVGR1::text), '^^') 
            , '||', IFNULL(TRIM(MVGR2::text), '^^') 
            , '||', IFNULL(TRIM(MVGR3::text), '^^') 
            , '||', IFNULL(TRIM(MVGR4::text), '^^') 
            , '||', IFNULL(TRIM(MVGR5::text), '^^') 
            , '||', IFNULL(TRIM(VPZUO::text), '^^') 
            , '||', IFNULL(TRIM(VGTYP::text), '^^') 
            , '||', IFNULL(TRIM(RFVGTYP::text), '^^') 
            , '||', IFNULL(TRIM(KOSTL::text), '^^') 
            , '||', IFNULL(TRIM(KOKRS::text), '^^') 
            , '||', IFNULL(TRIM(PAOBJNR::text), '^^') 
            , '||', IFNULL(TRIM(PRCTR::text), '^^') 
            , '||', IFNULL(TRIM(PS_PSP_PNR::text), '^^') 
            , '||', IFNULL(TRIM(AUFNR::text), '^^') 
            , '||', IFNULL(TRIM(POSNR_PP::text), '^^') 
            , '||', IFNULL(TRIM(KDAUF::text), '^^') 
            , '||', IFNULL(TRIM(KDPOS::text), '^^') 
            , '||', IFNULL(TRIM(VPMAT::text), '^^') 
            , '||', IFNULL(TRIM(VPWRK::text), '^^') 
            , '||', IFNULL(TRIM(PRBME::text), '^^') 
            , '||', IFNULL(TRIM(UMREF::text), '^^') 
            , '||', IFNULL(TRIM(KNTTP::text), '^^') 
            , '||', IFNULL(TRIM(KZVBR::text), '^^') 
            , '||', IFNULL(TRIM(FIPOS::text), '^^') 
            , '||', IFNULL(TRIM(FISTL::text), '^^') 
            , '||', IFNULL(TRIM(GEBER::text), '^^') 
            , '||', IFNULL(TRIM(PCKPF::text), '^^') 
            , '||', IFNULL(TRIM(BEDAR_LF::text), '^^') 
            , '||', IFNULL(TRIM(CMPNT::text), '^^') 
            , '||', IFNULL(TRIM(KCMENG::text), '^^') 
            , '||', IFNULL(TRIM(KCBRGEW::text), '^^') 
            , '||', IFNULL(TRIM(KCNTGEW::text), '^^') 
            , '||', IFNULL(TRIM(KCVOLUM::text), '^^') 
            , '||', IFNULL(TRIM(UECHA::text), '^^') 
            , '||', IFNULL(TRIM(CUOBJ::text), '^^') 
            , '||', IFNULL(TRIM(CUOBJ_CH::text), '^^') 
            , '||', IFNULL(TRIM(ANZSN::text), '^^') 
            , '||', IFNULL(TRIM(SERAIL::text), '^^') 
            , '||', IFNULL(TRIM(KCGEWEI::text), '^^') 
            , '||', IFNULL(TRIM(KCVOLEH::text), '^^') 
            , '||', IFNULL(TRIM(SERNR::text), '^^') 
            , '||', IFNULL(TRIM(ABRLI::text), '^^') 
            , '||', IFNULL(TRIM(ABART::text), '^^') 
            , '||', IFNULL(TRIM(ABRVW::text), '^^') 
            , '||', IFNULL(TRIM(QPLOS::text), '^^') 
            , '||', IFNULL(TRIM(QTLOS::text), '^^') 
            , '||', IFNULL(TRIM(NACHL::text), '^^') 
            , '||', IFNULL(TRIM(MAGRV::text), '^^') 
            , '||', IFNULL(TRIM(OBJKO::text), '^^') 
            , '||', IFNULL(TRIM(OBJPO::text), '^^') 
            , '||', IFNULL(TRIM(AESKD::text), '^^') 
            , '||', IFNULL(TRIM(SHKZG::text), '^^') 
            , '||', IFNULL(TRIM(PROSA::text), '^^') 
            , '||', IFNULL(TRIM(UEPVW::text), '^^') 
            , '||', IFNULL(TRIM(EMPST::text), '^^') 
            , '||', IFNULL(TRIM(ABTNR::text), '^^') 
            , '||', IFNULL(TRIM(KOQUI::text), '^^') 
            , '||', IFNULL(TRIM(STADAT::text), '^^') 
            , '||', IFNULL(TRIM(AKTNR::text), '^^') 
            , '||', IFNULL(TRIM(KNUMH_CH::text), '^^') 
            , '||', IFNULL(TRIM(PREFE::text), '^^') 
            , '||', IFNULL(TRIM(EXART::text), '^^') 
            , '||', IFNULL(TRIM(CLINT::text), '^^') 
            , '||', IFNULL(TRIM(CHMVS::text), '^^') 
            , '||', IFNULL(TRIM(ABELN::text), '^^') 
            , '||', IFNULL(TRIM(ABELP::text), '^^') 
            , '||', IFNULL(TRIM(LFIMG_FLO::text), '^^') 
            , '||', IFNULL(TRIM(LGMNG_FLO::text), '^^') 
            , '||', IFNULL(TRIM(KCMENG_FLO::text), '^^') 
            , '||', IFNULL(TRIM(KZUMW::text), '^^') 
            , '||', IFNULL(TRIM(KMPMG::text), '^^') 
            , '||', IFNULL(TRIM(AUREL::text), '^^') 
            , '||', IFNULL(TRIM(KPEIN::text), '^^') 
            , '||', IFNULL(TRIM(KMEIN::text), '^^') 
            , '||', IFNULL(TRIM(NETPR::text), '^^') 
            , '||', IFNULL(TRIM(NETWR::text), '^^') 
            , '||', IFNULL(TRIM(KOWRR::text), '^^') 
            , '||', IFNULL(TRIM(KZBEW::text), '^^') 
            , '||', IFNULL(TRIM(MFRGR::text), '^^') 
            , '||', IFNULL(TRIM(CHHPV::text), '^^') 
            , '||', IFNULL(TRIM(ABFOR::text), '^^') 
            , '||', IFNULL(TRIM(ABGES::text), '^^') 
            , '||', IFNULL(TRIM(MBUHR::text), '^^') 
            , '||', IFNULL(TRIM(WKTNR::text), '^^') 
            , '||', IFNULL(TRIM(WKTPS::text), '^^') 
            , '||', IFNULL(TRIM(J_1BCFOP::text), '^^') 
            , '||', IFNULL(TRIM(J_1BTAXLW1::text), '^^') 
            , '||', IFNULL(TRIM(J_1BTAXLW2::text), '^^') 
            , '||', IFNULL(TRIM(J_1BTXSDC::text), '^^') 
            , '||', IFNULL(TRIM(SITUA::text), '^^') 
            , '||', IFNULL(TRIM(RSNUM::text), '^^') 
            , '||', IFNULL(TRIM(RSPOS::text), '^^') 
            , '||', IFNULL(TRIM(RSART::text), '^^') 
            , '||', IFNULL(TRIM(KANNR::text), '^^') 
            , '||', IFNULL(TRIM(KZFME::text), '^^') 
            , '||', IFNULL(TRIM(PROFL::text), '^^') 
            , '||', IFNULL(TRIM(KCMENGVME::text), '^^') 
            , '||', IFNULL(TRIM(KCMENGVMEF::text), '^^') 
            , '||', IFNULL(TRIM(KZBWS::text), '^^') 
            , '||', IFNULL(TRIM(PSPNR::text), '^^') 
            , '||', IFNULL(TRIM(EPRIO::text), '^^') 
            , '||', IFNULL(TRIM(RULES::text), '^^') 
            , '||', IFNULL(TRIM(KZBEF::text), '^^') 
            , '||', IFNULL(TRIM(MPROF::text), '^^') 
            , '||', IFNULL(TRIM(EMATN::text), '^^') 
            , '||', IFNULL(TRIM(LGBZO::text), '^^') 
            , '||', IFNULL(TRIM(HANDLE::text), '^^') 
            , '||', IFNULL(TRIM(VERURPOS::text), '^^') 
            , '||', IFNULL(TRIM(LIFEXPOS::text), '^^') 
            , '||', IFNULL(TRIM(NOATP::text), '^^') 
            , '||', IFNULL(TRIM(NOPCK::text), '^^') 
            , '||', IFNULL(TRIM(RBLVS::text), '^^') 
            , '||', IFNULL(TRIM(BERID::text), '^^') 
            , '||', IFNULL(TRIM(BESTQ::text), '^^') 
            , '||', IFNULL(TRIM(UMBSQ::text), '^^') 
            , '||', IFNULL(TRIM(UMMAT::text), '^^') 
            , '||', IFNULL(TRIM(UMWRK::text), '^^') 
            , '||', IFNULL(TRIM(UMLGO::text), '^^') 
            , '||', IFNULL(TRIM(UMCHA::text), '^^') 
            , '||', IFNULL(TRIM(UMBAR::text), '^^') 
            , '||', IFNULL(TRIM(UMSOK::text), '^^') 
            , '||', IFNULL(TRIM(SONUM::text), '^^') 
            , '||', IFNULL(TRIM(USONU::text), '^^') 
            , '||', IFNULL(TRIM(AKKUR::text), '^^') 
            , '||', IFNULL(TRIM(AKMNG::text), '^^') 
            , '||', IFNULL(TRIM(VKGRU::text), '^^') 
            , '||', IFNULL(TRIM(SHKZG_UM::text), '^^') 
            , '||', IFNULL(TRIM(INSMK::text), '^^') 
            , '||', IFNULL(TRIM(KZECH::text), '^^') 
            , '||', IFNULL(TRIM(FLGWM::text), '^^') 
            , '||', IFNULL(TRIM(BERKZ::text), '^^') 
            , '||', IFNULL(TRIM(HUPOS::text), '^^') 
            , '||', IFNULL(TRIM(NOWAB::text), '^^') 
            , '||', IFNULL(TRIM(KONTO::text), '^^') 
            , '||', IFNULL(TRIM(KZEAR::text), '^^') 
            , '||', IFNULL(TRIM(HSDAT::text), '^^') 
            , '||', IFNULL(TRIM(VFDAT::text), '^^') 
            , '||', IFNULL(TRIM(LFGJA::text), '^^') 
            , '||', IFNULL(TRIM(LFBNR::text), '^^') 
            , '||', IFNULL(TRIM(LFPOS::text), '^^') 
            , '||', IFNULL(TRIM(GRUND::text), '^^') 
            , '||', IFNULL(TRIM(FOBWA::text), '^^') 
            , '||', IFNULL(TRIM(DLVTP::text), '^^') 
            , '||', IFNULL(TRIM(EXBWR::text), '^^') 
            , '||', IFNULL(TRIM(BPMNG::text), '^^') 
            , '||', IFNULL(TRIM(EXVKW::text), '^^') 
            , '||', IFNULL(TRIM(CMPRE_FLT::text), '^^') 
            , '||', IFNULL(TRIM(KZPOD::text), '^^') 
            , '||', IFNULL(TRIM(LFDEZ::text), '^^') 
            , '||', IFNULL(TRIM(UMREV::text), '^^') 
            , '||', IFNULL(TRIM(PODREL::text), '^^') 
            , '||', IFNULL(TRIM(KZUML::text), '^^') 
            , '||', IFNULL(TRIM(FKBER::text), '^^') 
            , '||', IFNULL(TRIM(GRANT_NBR::text), '^^') 
            , '||', IFNULL(TRIM(KZWSO::text), '^^') 
            , '||', IFNULL(TRIM(GMCONTROL::text), '^^') 
            , '||', IFNULL(TRIM(POSTING_CHANGE::text), '^^') 
            , '||', IFNULL(TRIM(UM_PS_PSP_PNR::text), '^^') 
            , '||', IFNULL(TRIM(PRE_VL_ETENS::text), '^^') 
            , '||', IFNULL(TRIM(SPE_GEN_ELIKZ::text), '^^') 
            , '||', IFNULL(TRIM(SPE_SCRAP_IND::text), '^^') 
            , '||', IFNULL(TRIM(SPE_AUTH_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(SPE_INSPOUT_GUID::text), '^^') 
            , '||', IFNULL(TRIM(SPE_FOLLOW_UP::text), '^^') 
            , '||', IFNULL(TRIM(SPE_EXP_DATE_EXT::text), '^^') 
            , '||', IFNULL(TRIM(SPE_EXP_DATE_INT::text), '^^') 
            , '||', IFNULL(TRIM(SPE_AUTH_COMPLET::text), '^^') 
            , '||', IFNULL(TRIM(ORMNG::text), '^^') 
            , '||', IFNULL(TRIM(SPE_ATP_TMSTMP::text), '^^') 
            , '||', IFNULL(TRIM(SPE_ORIG_SYS::text), '^^') 
            , '||', IFNULL(TRIM(SPE_LIEFFZ::text), '^^') 
            , '||', IFNULL(TRIM(SPE_IMWRK::text), '^^') 
            , '||', IFNULL(TRIM(SPE_LIFEXPOS2::text), '^^') 
            , '||', IFNULL(TRIM(SPE_EXCEPT_CODE::text), '^^') 
            , '||', IFNULL(TRIM(SPE_KEEP_QTY::text), '^^') 
            , '||', IFNULL(TRIM(SPE_ALTERNATE::text), '^^') 
            , '||', IFNULL(TRIM(SPE_MAT_SUBST::text), '^^') 
            , '||', IFNULL(TRIM(SPE_STRUC::text), '^^') 
            , '||', IFNULL(TRIM(SPE_APO_QNTYFAC::text), '^^') 
            , '||', IFNULL(TRIM(SPE_APO_QNTYDIV::text), '^^') 
            , '||', IFNULL(TRIM(SPE_HERKL::text), '^^') 
            , '||', IFNULL(TRIM(SPE_BXP_DATE_EXT::text), '^^') 
            , '||', IFNULL(TRIM(SPE_VERSION::text), '^^') 
            , '||', IFNULL(TRIM(SPE_COMPL_MVT::text), '^^') 
            , '||', IFNULL(TRIM(J_1BTAXLW4::text), '^^') 
            , '||', IFNULL(TRIM(J_1BTAXLW5::text), '^^') 
            , '||', IFNULL(TRIM(J_1BTAXLW3::text), '^^') 
            , '||', IFNULL(TRIM(BUDGET_PD::text), '^^') 
            , '||', IFNULL(TRIM(KBNKZ::text), '^^') 
            , '||', IFNULL(TRIM(FARR_RELTYPE::text), '^^') 
            , '||', IFNULL(TRIM(SITKZ::text), '^^') 
            , '||', IFNULL(TRIM(SGT_RCAT::text), '^^') 
            , '||', IFNULL(TRIM(SGT_SCAT::text), '^^') 
            , '||', IFNULL(TRIM(FSH_SEASON_YEAR::text), '^^') 
            , '||', IFNULL(TRIM(FSH_SEASON::text), '^^') 
            , '||', IFNULL(TRIM(FSH_COLLECTION::text), '^^') 
            , '||', IFNULL(TRIM(FSH_THEME::text), '^^') 
            , '||', IFNULL(TRIM(FSH_KVGR6::text), '^^') 
            , '||', IFNULL(TRIM(FSH_KVGR7::text), '^^') 
            , '||', IFNULL(TRIM(FSH_KVGR8::text), '^^') 
            , '||', IFNULL(TRIM(FSH_KVGR9::text), '^^') 
            , '||', IFNULL(TRIM(FSH_KVGR10::text), '^^') 
            , '||', IFNULL(TRIM(FSH_VAS_REL::text), '^^') 
            , '||', IFNULL(TRIM(FSH_VAS_PRNT_ID::text), '^^') 
            , '||', IFNULL(TRIM(FSH_TRANSACTION::text), '^^') 
            , '||', IFNULL(TRIM(FSH_ITEM_GROUP::text), '^^') 
            , '||', IFNULL(TRIM(FSH_ITEM::text), '^^') 
            , '||', IFNULL(TRIM(FSH_RSNUM::text), '^^') 
            , '||', IFNULL(TRIM(FSH_RSPOS::text), '^^') 
            , '||', IFNULL(TRIM(CONS_ORDER::text), '^^') 
            , '||', IFNULL(TRIM(WRF_CHARSTC1::text), '^^') 
            , '||', IFNULL(TRIM(WRF_CHARSTC2::text), '^^') 
            , '||', IFNULL(TRIM(WRF_CHARSTC3::text), '^^') 
            , '||', IFNULL(TRIM(ZZUPDATE_ETA::text), '^^') 
            , '||', IFNULL(TRIM(ZZAVAILABLE::text), '^^') 
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
