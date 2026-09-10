---- SRC LAYER ----
WITH
SRC_LIPS           as ( SELECT * FROM {{ ref('v_psa_stg_delivery_line_detail__winn_sap') }} as SRC 
                        {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %} )

/*
SRC_LIPS           as ( SELECT * FROM STAGING.v_psa_stg_delivery_line_detail__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_LIPS as (
    SELECT
        DELIVERY_LINE_DETAIL_LHK
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
      , HASHDIFF
    FROM SRC_LIPS
)
---- RENAME LAYER ----

, RENAME_LIPS as (
    SELECT
        DELIVERY_LINE_DETAIL_LHK
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
      , HASHDIFF
    FROM LOGIC_LIPS
)
---- FILTER LAYER ----

, FILTER_LIPS as (
    SELECT *
    FROM RENAME_LIPS
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_LIPS
)

---- FINAL LAYER ----
SELECT
          DELIVERY_LINE_DETAIL_LHK
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
        , HASHDIFF
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.DELIVERY_LINE_DETAIL_LHK = JOIN_RESULT.DELIVERY_LINE_DETAIL_LHK
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %}
{% if not is_incremental() %}

/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per HK and hashdiff. */
qualify 1 = row_number() over (partition by DELIVERY_LINE_DETAIL_LHK, HASHDIFF order by PSA_LOAD_DTS)

union all
SELECT 
MD5_BINARY(GR.VALUE) AS DELIVERY_LINE_DETAIL_LHK,
NULL AS MANDT,
GR.VALUE::text AS VBELN,
GR.VALUE::text AS POSNR,
NULL AS GLREQUEST,
NULL AS PSTYV,
NULL AS ERNAM,
NULL AS ERZET,
NULL AS ERDAT,
NULL AS ERDAT_DT,
GR.VALUE::text AS MATNR,
GR.VALUE::text AS MATWA,
NULL AS MATKL,
GR.VALUE::text AS WERKS,
GR.VALUE::text AS LGORT,
NULL AS CHARG,
NULL AS LICHN,
NULL AS KDMAT,
NULL AS PRODH,
NULL AS LFIMG,
NULL AS MEINS,
NULL AS VRKME,
NULL AS UMVKZ,
NULL AS UMVKN,
NULL AS NTGEW,
NULL AS BRGEW,
NULL AS GEWEI,
NULL AS VOLUM,
NULL AS VOLEH,
NULL AS KZTLF,
NULL AS UEBTK,
NULL AS UEBTO,
NULL AS UNTTO,
NULL AS CHSPL,
NULL AS FAKSP,
NULL AS MBDAT,
NULL AS MBDAT_DT,
NULL AS LGMNG,
NULL AS ARKTX,
NULL AS LGPBE,
NULL AS VBELV,
NULL AS POSNV,
NULL AS VBTYV,
NULL AS VGSYS,
GR.VALUE::text AS VGBEL,
GR.VALUE::text AS VGPOS,
NULL AS UPFLU,
NULL AS UEPOS,
NULL AS FKREL,
NULL AS LADGR,
NULL AS TRAGR,
NULL AS KOMKZ,
NULL AS LGNUM,
NULL AS LISPL,
NULL AS LGTYP,
NULL AS LGPLA,
NULL AS BWTEX,
NULL AS BWART,
NULL AS BWLVS,
NULL AS KZDLG,
NULL AS BDART,
NULL AS PLART,
NULL AS MTART,
NULL AS XCHPF,
NULL AS XCHAR,
NULL AS VGREF,
NULL AS POSAR,
NULL AS BWTAR,
NULL AS SUMBD,
NULL AS MTVFP,
NULL AS EANNR,
NULL AS GSBER,
NULL AS VKBUR,
NULL AS VKGRP,
GR.VALUE::text AS VTWEG,
GR.VALUE::text AS SPART,
NULL AS GRKOR,
NULL AS FMENG,
NULL AS ANTLF,
NULL AS VBEAF,
NULL AS VBEAV,
NULL AS STAFO,
NULL AS WAVWR,
NULL AS KZWI1,
NULL AS KZWI2,
NULL AS KZWI3,
NULL AS KZWI4,
NULL AS KZWI5,
NULL AS KZWI6,
NULL AS SOBKZ,
NULL AS AEDAT,
NULL AS AEDAT_DT,
NULL AS EAN11,
NULL AS KVGR1,
NULL AS KVGR2,
NULL AS KVGR3,
NULL AS KVGR4,
NULL AS KVGR5,
NULL AS MVGR1,
NULL AS MVGR2,
NULL AS MVGR3,
NULL AS MVGR4,
NULL AS MVGR5,
NULL AS VPZUO,
NULL AS VGTYP,
NULL AS RFVGTYP,
GR.VALUE::text AS KOSTL,
NULL AS KOKRS,
NULL AS PAOBJNR,
NULL AS PRCTR,
NULL AS PS_PSP_PNR,
NULL AS AUFNR,
NULL AS POSNR_PP,
NULL AS KDAUF,
NULL AS KDPOS,
NULL AS VPMAT,
NULL AS VPWRK,
NULL AS PRBME,
NULL AS UMREF,
NULL AS KNTTP,
NULL AS KZVBR,
NULL AS FIPOS,
NULL AS FISTL,
NULL AS GEBER,
NULL AS PCKPF,
NULL AS BEDAR_LF,
NULL AS CMPNT,
NULL AS KCMENG,
NULL AS KCBRGEW,
NULL AS KCNTGEW,
NULL AS KCVOLUM,
NULL AS UECHA,
NULL AS CUOBJ,
NULL AS CUOBJ_CH,
NULL AS ANZSN,
NULL AS SERAIL,
NULL AS KCGEWEI,
NULL AS KCVOLEH,
NULL AS SERNR,
NULL AS ABRLI,
NULL AS ABART,
NULL AS ABRVW,
NULL AS QPLOS,
NULL AS QTLOS,
NULL AS NACHL,
NULL AS MAGRV,
NULL AS OBJKO,
NULL AS OBJPO,
NULL AS AESKD,
NULL AS SHKZG,
NULL AS PROSA,
NULL AS UEPVW,
NULL AS EMPST,
NULL AS ABTNR,
NULL AS KOQUI,
NULL AS STADAT,
NULL AS AKTNR,
NULL AS KNUMH_CH,
NULL AS PREFE,
NULL AS EXART,
NULL AS CLINT,
NULL AS CHMVS,
NULL AS ABELN,
NULL AS ABELP,
NULL AS LFIMG_FLO,
NULL AS LGMNG_FLO,
NULL AS KCMENG_FLO,
NULL AS KZUMW,
NULL AS KMPMG,
NULL AS AUREL,
NULL AS KPEIN,
NULL AS KMEIN,
NULL AS NETPR,
NULL AS NETWR,
NULL AS KOWRR,
NULL AS KZBEW,
NULL AS MFRGR,
NULL AS CHHPV,
NULL AS ABFOR,
NULL AS ABGES,
NULL AS MBUHR,
NULL AS WKTNR,
NULL AS WKTPS,
NULL AS J_1BCFOP,
NULL AS J_1BTAXLW1,
NULL AS J_1BTAXLW2,
NULL AS J_1BTXSDC,
NULL AS SITUA,
NULL AS RSNUM,
NULL AS RSPOS,
NULL AS RSART,
NULL AS KANNR,
NULL AS KZFME,
NULL AS PROFL,
NULL AS KCMENGVME,
NULL AS KCMENGVMEF,
NULL AS KZBWS,
NULL AS PSPNR,
NULL AS EPRIO,
NULL AS RULES,
NULL AS KZBEF,
NULL AS MPROF,
NULL AS EMATN,
NULL AS LGBZO,
NULL AS HANDLE,
NULL AS VERURPOS,
NULL AS LIFEXPOS,
NULL AS NOATP,
NULL AS NOPCK,
NULL AS RBLVS,
NULL AS BERID,
NULL AS BESTQ,
NULL AS UMBSQ,
NULL AS UMMAT,
NULL AS UMWRK,
NULL AS UMLGO,
NULL AS UMCHA,
NULL AS UMBAR,
NULL AS UMSOK,
NULL AS SONUM,
NULL AS USONU,
NULL AS AKKUR,
NULL AS AKMNG,
NULL AS VKGRU,
NULL AS SHKZG_UM,
NULL AS INSMK,
NULL AS KZECH,
NULL AS FLGWM,
NULL AS BERKZ,
NULL AS HUPOS,
NULL AS NOWAB,
NULL AS KONTO,
NULL AS KZEAR,
NULL AS HSDAT,
NULL AS VFDAT,
NULL AS LFGJA,
NULL AS LFBNR,
NULL AS LFPOS,
NULL AS GRUND,
NULL AS FOBWA,
NULL AS DLVTP,
NULL AS EXBWR,
NULL AS BPMNG,
NULL AS EXVKW,
NULL AS CMPRE_FLT,
NULL AS KZPOD,
NULL AS LFDEZ,
NULL AS UMREV,
NULL AS PODREL,
NULL AS KZUML,
NULL AS FKBER,
NULL AS GRANT_NBR,
NULL AS KZWSO,
NULL AS GMCONTROL,
NULL AS POSTING_CHANGE,
NULL AS UM_PS_PSP_PNR,
NULL AS PRE_VL_ETENS,
NULL AS SPE_GEN_ELIKZ,
NULL AS SPE_SCRAP_IND,
NULL AS SPE_AUTH_NUMBER,
NULL AS SPE_INSPOUT_GUID,
NULL AS SPE_FOLLOW_UP,
NULL AS SPE_EXP_DATE_EXT,
NULL AS SPE_EXP_DATE_INT,
NULL AS SPE_AUTH_COMPLET,
NULL AS ORMNG,
NULL AS SPE_ATP_TMSTMP,
NULL AS SPE_ORIG_SYS,
NULL AS SPE_LIEFFZ,
NULL AS SPE_IMWRK,
NULL AS SPE_LIFEXPOS2,
NULL AS SPE_EXCEPT_CODE,
NULL AS SPE_KEEP_QTY,
NULL AS SPE_ALTERNATE,
NULL AS SPE_MAT_SUBST,
NULL AS SPE_STRUC,
NULL AS SPE_APO_QNTYFAC,
NULL AS SPE_APO_QNTYDIV,
NULL AS SPE_HERKL,
NULL AS SPE_BXP_DATE_EXT,
NULL AS SPE_VERSION,
NULL AS SPE_COMPL_MVT,
NULL AS J_1BTAXLW4,
NULL AS J_1BTAXLW5,
NULL AS J_1BTAXLW3,
NULL AS BUDGET_PD,
NULL AS KBNKZ,
NULL AS FARR_RELTYPE,
NULL AS SITKZ,
NULL AS SGT_RCAT,
NULL AS SGT_SCAT,
NULL AS FSH_SEASON_YEAR,
NULL AS FSH_SEASON,
NULL AS FSH_COLLECTION,
NULL AS FSH_THEME,
NULL AS FSH_KVGR6,
NULL AS FSH_KVGR7,
NULL AS FSH_KVGR8,
NULL AS FSH_KVGR9,
NULL AS FSH_KVGR10,
NULL AS FSH_VAS_REL,
NULL AS FSH_VAS_PRNT_ID,
NULL AS FSH_TRANSACTION,
NULL AS FSH_ITEM_GROUP,
NULL AS FSH_ITEM,
NULL AS FSH_RSNUM,
NULL AS FSH_RSPOS,
NULL AS CONS_ORDER,
NULL AS WRF_CHARSTC1,
NULL AS WRF_CHARSTC2,
NULL AS WRF_CHARSTC3,
NULL AS ZZUPDATE_ETA,
NULL AS ZZAVAILABLE,
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
