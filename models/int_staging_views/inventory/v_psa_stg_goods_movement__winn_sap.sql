---- SRC LAYER ----
WITH
SRC_a              as ( SELECT MANDT, MBLNR, MJAHR, ZEILE, GLREQUEST, LINE_ID, PARENT_ID, LINE_DEPTH, MAA_URZEI, BWART, XAUTO, MATNR, WERKS, LGORT, CHARG, INSMK, ZUSCH, ZUSTD, SOBKZ, LIFNR, KUNNR, KDAUF, KDPOS, KDEIN, PLPLA, SHKZG, WAERS, DMBTR, BNBTR, BUALT, SHKUM, DMBUM, BWTAR, MENGE, MEINS, ERFMG, ERFME, BPMNG, BPRME, EBELN, EBELP, LFBJA, LFBNR, LFPOS, SJAHR, SMBLN, SMBLP, ELIKZ, SGTXT, EQUNR, WEMPF, ABLAD, GSBER, KOKRS, PARGB, PARBU, KOSTL, PROJN, AUFNR, ANLN1, ANLN2, XSKST, XSAUF, XSPRO, XSERG, GJAHR, XRUEM, XRUEJ, BUKRS, BELNR, BUZEI, BELUM, BUZUM, RSNUM, RSPOS, KZEAR, PBAMG, KZSTR, UMMAT, UMWRK, UMLGO, UMCHA, UMZST, UMZUS, UMBAR, UMSOK, KZBEW, KZVBR, KZZUG, WEUNB, PALAN, LGNUM, LGTYP, LGPLA, BESTQ, BWLVS, TBNUM, TBPOS, XBLVS, VSCHN, NSCHN, DYPLA, UBNUM, TBPRI, TANUM, WEANZ, GRUND, EVERS, EVERE, IMKEY, KSTRG, PAOBJNR, PRCTR, PS_PSP_PNR, NPLNR, AUFPL, APLZL, AUFPS, VPTNR, FIPOS, SAKTO, BSTMG, BSTME, XWSBR, EMLIF, ZZALTKT, EXBWR, VKWRT, AKTNR, ZEKKN, VFDAT, CUOBJ_CH, EXVKW, PPRCTR, RSART, GEBER, FISTL, MATBF, UMMAB, BUSTM, BUSTW, MENGU, WERTU, LBKUM, SALK3, VPRSV, FKBER, DABRBZ, VKWRA, DABRZ, XBEAU, LSMNG, LSMEH, KZBWS, QINSPST, URZEI, J_1BEXBASE, MWSKZ, TXJCD, EMATN, J_1AGIRUPD, VKMWS, HSDAT, BERKZ, MAT_KDAUF, MAT_KDPOS, MAT_PSPNR, XWOFF, BEMOT, PRZNR, LLIEF, LSTAR, XOBEW, GRANT_NBR, ZUSTD_T156M, SPE_GTS_STOCK_TY, KBLNR, KBLPOS, XMACC, VGART_MKPF, BUDAT_MKPF, CPUDT_MKPF, CPUTM_MKPF, USNAM_MKPF, XBLNR_MKPF, TCODE2_MKPF, VBELN_IM, VBELP_IM, SGT_SCAT, SGT_UMSCAT, SGT_RCAT, '/BEV2/ED_KZ_VER', '/BEV2/ED_USER', '/BEV2/ED_AEDAT', '/BEV2/ED_AETIM', DISUB_OWNER, FSH_SEASON_YEAR, FSH_SEASON, FSH_COLLECTION, FSH_THEME, FSH_UMSEA_YR, FSH_UMSEA, FSH_UMCOLL, FSH_UMTHEME, SGT_CHINT, FSH_DEALLOC_QTY, OINAVNW, OICONDCOD, CONDI, WRF_CHARSTC1, WRF_CHARSTC2, WRF_CHARSTC3, GLDELFLAG, GLCHANGETIME, GLSOURCESYSTEM, PSA_LOAD_DTS, PSA_RECORD_SOURCE, PSA_DELETE_IND FROM {{ source('sap_ecc_prd', 'z_mseg') }} as SRC  ),
SRC_bkcc           as ( SELECT REC_SRC, BKCC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_a              as ( SELECT * FROM sap_ecc_prd.z_mseg )
SRC_bkcc           as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_a as (
    SELECT
        MANDT
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
      , '/BEV2/ED_KZ_VER'                                             as                                     BEV2_ED_KZ_VER
      , '/BEV2/ED_USER'                                               as                                       BEV2_ED_USER
      , '/BEV2/ED_AEDAT'                                              as                                      BEV2_ED_AEDAT
      , '/BEV2/ED_AETIM'                                              as                                      BEV2_ED_AETIM
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
        ))                                                           as                                          LOAD_DTS
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
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_MSEG'
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
          coalesce(nullif(trim(UPPER(MATNR)), ''), '-1')                                                          as ITEM_BK
        , coalesce(nullif(trim(UPPER(VBELN_IM)), ''), '-1')                                                       as DELIVERY_BK
        , coalesce(nullif(trim(UPPER(VBELP_IM)), ''), '-1')                                                       as DELIVERY_LINE_ITEM_BK
        , coalesce(nullif(trim(UPPER(AUFNR)), ''), '-1')                                                          as PRODUCTION_ORDER_BK
        , IFF(NULLIF(TRIM(EBELN), '') IS NOT NULL OR NULLIF(TRIM(EBELP), '') IS NOT NULL, UPPER(CONCAT(EBELN,'||',EBELP)), '-1')                                         as PO_ITEM_BK
        , coalesce(nullif(trim(UPPER(WEMPF)), ''), '-1')                                                          as CUSTOMER_SHIP_LOCATION_BK
        , IFF(NULLIF(TRIM(KDAUF), '') IS NOT NULL OR NULLIF(TRIM(KDPOS), '') IS NOT NULL, UPPER(CONCAT(KDAUF, '||', KDPOS)), '-1')                                     as ORDER_LINE_BK
        , coalesce(nullif(trim(UPPER(MEINS)), ''), '-1')                                                          as UOM_BK
        , coalesce(nullif(trim(UPPER(KUNNR)), ''), '-1')                                                          as CUSTOMER_BK
        , coalesce(nullif(trim(UPPER(LIFNR)), ''), '-1')                                                          as SUPPLIER_BK
        , coalesce(nullif(trim(UPPER(LGORT)), ''), '-1')                                                          as GOODS_STORAGE_LOCATION_BK
        , coalesce(nullif(trim(UPPER(WERKS)), ''), '-1')                                                          as PLANT_BK
        , CONCAT(MBLNR,'||',MJAHR,'||',ZEILE,'||',LINE_ID)             as GOODS_MOVEMENT_ITEM_DOCUMENT_BK
        , MBLNR                                                        as GOODS_MOVEMENT_ITEM_DOCUMENT_NUM_BK
        , MJAHR                                                        as GOODS_MOVEMENT_ITEM_DOCUMENT_YR_BK
        , ZEILE                                                        as GOODS_MOVEMENT_ITEM_DOCUMENT_SEQ_NUM_BK
        , coalesce(nullif(trim(UPPER(LINE_ID)), ''), '-1')                                                     as GOODS_MOVEMENT_ITEM_DOCUMENT_LINE_NUM_BK
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
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(GOODS_MOVEMENT_ITEM_DOCUMENT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(ITEM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(DELIVERY_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(DELIVERY_LINE_ITEM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(PRODUCTION_ORDER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(PO_ITEM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(CUSTOMER_SHIP_LOCATION_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(ORDER_LINE_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(UOM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(CUSTOMER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(SUPPLIER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(GOODS_STORAGE_LOCATION_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(PLANT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as LNK_GOODS_MOVEMENT_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(GOODS_MOVEMENT_ITEM_DOCUMENT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as GOODS_MOVEMENT_ITEM_DOCUMENT_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PLANT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PLANT_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(GOODS_STORAGE_LOCATION_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as GOODS_STORAGE_LOCATION_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(SUPPLIER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as SUPPLIER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(CUSTOMER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as CUSTOMER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(UOM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as UOM_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ORDER_LINE_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ORDER_LINE_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(CUSTOMER_SHIP_LOCATION_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as CUSTOMER_SHIP_LOCATION_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PO_ITEM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PO_ITEM_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PRODUCTION_ORDER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PRODUCTION_ORDER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(DELIVERY_LINE_ITEM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as DELIVERY_LINE_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ITEM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ITEM_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(MANDT::text), '^^') 
            , '||', IFNULL(TRIM(PARENT_ID::text), '^^') 
            , '||', IFNULL(TRIM(LINE_DEPTH::text), '^^') 
            , '||', IFNULL(TRIM(MAA_URZEI::text), '^^') 
            , '||', IFNULL(TRIM(BWART::text), '^^') 
            , '||', IFNULL(TRIM(XAUTO::text), '^^') 
            , '||', IFNULL(TRIM(CHARG::text), '^^') 
            , '||', IFNULL(TRIM(INSMK::text), '^^') 
            , '||', IFNULL(TRIM(ZUSCH::text), '^^') 
            , '||', IFNULL(TRIM(ZUSTD::text), '^^') 
            , '||', IFNULL(TRIM(SOBKZ::text), '^^') 
            , '||', IFNULL(TRIM(KDEIN::text), '^^') 
            , '||', IFNULL(TRIM(PLPLA::text), '^^') 
            , '||', IFNULL(TRIM(SHKZG::text), '^^') 
            , '||', IFNULL(TRIM(WAERS::text), '^^') 
            , '||', IFNULL(TRIM(DMBTR::text), '^^') 
            , '||', IFNULL(TRIM(BNBTR::text), '^^') 
            , '||', IFNULL(TRIM(BUALT::text), '^^') 
            , '||', IFNULL(TRIM(SHKUM::text), '^^') 
            , '||', IFNULL(TRIM(DMBUM::text), '^^') 
            , '||', IFNULL(TRIM(BWTAR::text), '^^') 
            , '||', IFNULL(TRIM(MENGE::text), '^^') 
            , '||', IFNULL(TRIM(MEINS::text), '^^') 
            , '||', IFNULL(TRIM(ERFMG::text), '^^') 
            , '||', IFNULL(TRIM(ERFME::text), '^^') 
            , '||', IFNULL(TRIM(BPMNG::text), '^^') 
            , '||', IFNULL(TRIM(BPRME::text), '^^') 
            , '||', IFNULL(TRIM(LFBJA::text), '^^') 
            , '||', IFNULL(TRIM(LFBNR::text), '^^') 
            , '||', IFNULL(TRIM(LFPOS::text), '^^') 
            , '||', IFNULL(TRIM(SJAHR::text), '^^') 
            , '||', IFNULL(TRIM(SMBLN::text), '^^') 
            , '||', IFNULL(TRIM(SMBLP::text), '^^') 
            , '||', IFNULL(TRIM(ELIKZ::text), '^^') 
            , '||', IFNULL(TRIM(SGTXT::text), '^^') 
            , '||', IFNULL(TRIM(EQUNR::text), '^^') 
            , '||', IFNULL(TRIM(ABLAD::text), '^^') 
            , '||', IFNULL(TRIM(GSBER::text), '^^') 
            , '||', IFNULL(TRIM(KOKRS::text), '^^') 
            , '||', IFNULL(TRIM(PARGB::text), '^^') 
            , '||', IFNULL(TRIM(PARBU::text), '^^') 
            , '||', IFNULL(TRIM(KOSTL::text), '^^') 
            , '||', IFNULL(TRIM(PROJN::text), '^^') 
            , '||', IFNULL(TRIM(ANLN1::text), '^^') 
            , '||', IFNULL(TRIM(ANLN2::text), '^^') 
            , '||', IFNULL(TRIM(XSKST::text), '^^') 
            , '||', IFNULL(TRIM(XSAUF::text), '^^') 
            , '||', IFNULL(TRIM(XSPRO::text), '^^') 
            , '||', IFNULL(TRIM(XSERG::text), '^^') 
            , '||', IFNULL(TRIM(GJAHR::text), '^^') 
            , '||', IFNULL(TRIM(XRUEM::text), '^^') 
            , '||', IFNULL(TRIM(XRUEJ::text), '^^') 
            , '||', IFNULL(TRIM(BUKRS::text), '^^') 
            , '||', IFNULL(TRIM(BELNR::text), '^^') 
            , '||', IFNULL(TRIM(BUZEI::text), '^^') 
            , '||', IFNULL(TRIM(BELUM::text), '^^') 
            , '||', IFNULL(TRIM(BUZUM::text), '^^') 
            , '||', IFNULL(TRIM(RSNUM::text), '^^') 
            , '||', IFNULL(TRIM(RSPOS::text), '^^') 
            , '||', IFNULL(TRIM(KZEAR::text), '^^') 
            , '||', IFNULL(TRIM(PBAMG::text), '^^') 
            , '||', IFNULL(TRIM(KZSTR::text), '^^') 
            , '||', IFNULL(TRIM(UMMAT::text), '^^') 
            , '||', IFNULL(TRIM(UMWRK::text), '^^') 
            , '||', IFNULL(TRIM(UMLGO::text), '^^') 
            , '||', IFNULL(TRIM(UMCHA::text), '^^') 
            , '||', IFNULL(TRIM(UMZST::text), '^^') 
            , '||', IFNULL(TRIM(UMZUS::text), '^^') 
            , '||', IFNULL(TRIM(UMBAR::text), '^^') 
            , '||', IFNULL(TRIM(UMSOK::text), '^^') 
            , '||', IFNULL(TRIM(KZBEW::text), '^^') 
            , '||', IFNULL(TRIM(KZVBR::text), '^^') 
            , '||', IFNULL(TRIM(KZZUG::text), '^^') 
            , '||', IFNULL(TRIM(WEUNB::text), '^^') 
            , '||', IFNULL(TRIM(PALAN::text), '^^') 
            , '||', IFNULL(TRIM(LGNUM::text), '^^') 
            , '||', IFNULL(TRIM(LGTYP::text), '^^') 
            , '||', IFNULL(TRIM(LGPLA::text), '^^') 
            , '||', IFNULL(TRIM(BESTQ::text), '^^') 
            , '||', IFNULL(TRIM(BWLVS::text), '^^') 
            , '||', IFNULL(TRIM(TBNUM::text), '^^') 
            , '||', IFNULL(TRIM(TBPOS::text), '^^') 
            , '||', IFNULL(TRIM(XBLVS::text), '^^') 
            , '||', IFNULL(TRIM(VSCHN::text), '^^') 
            , '||', IFNULL(TRIM(NSCHN::text), '^^') 
            , '||', IFNULL(TRIM(DYPLA::text), '^^') 
            , '||', IFNULL(TRIM(UBNUM::text), '^^') 
            , '||', IFNULL(TRIM(TBPRI::text), '^^') 
            , '||', IFNULL(TRIM(TANUM::text), '^^') 
            , '||', IFNULL(TRIM(WEANZ::text), '^^') 
            , '||', IFNULL(TRIM(GRUND::text), '^^') 
            , '||', IFNULL(TRIM(EVERS::text), '^^') 
            , '||', IFNULL(TRIM(EVERE::text), '^^') 
            , '||', IFNULL(TRIM(IMKEY::text), '^^') 
            , '||', IFNULL(TRIM(KSTRG::text), '^^') 
            , '||', IFNULL(TRIM(PAOBJNR::text), '^^') 
            , '||', IFNULL(TRIM(PRCTR::text), '^^') 
            , '||', IFNULL(TRIM(PS_PSP_PNR::text), '^^') 
            , '||', IFNULL(TRIM(NPLNR::text), '^^') 
            , '||', IFNULL(TRIM(AUFPL::text), '^^') 
            , '||', IFNULL(TRIM(APLZL::text), '^^') 
            , '||', IFNULL(TRIM(AUFPS::text), '^^') 
            , '||', IFNULL(TRIM(VPTNR::text), '^^') 
            , '||', IFNULL(TRIM(FIPOS::text), '^^') 
            , '||', IFNULL(TRIM(SAKTO::text), '^^') 
            , '||', IFNULL(TRIM(BSTMG::text), '^^') 
            , '||', IFNULL(TRIM(BSTME::text), '^^') 
            , '||', IFNULL(TRIM(XWSBR::text), '^^') 
            , '||', IFNULL(TRIM(EMLIF::text), '^^') 
            , '||', IFNULL(TRIM(ZZALTKT::text), '^^') 
            , '||', IFNULL(TRIM(EXBWR::text), '^^') 
            , '||', IFNULL(TRIM(VKWRT::text), '^^') 
            , '||', IFNULL(TRIM(AKTNR::text), '^^') 
            , '||', IFNULL(TRIM(ZEKKN::text), '^^') 
            , '||', IFNULL(TRIM(VFDAT::text), '^^') 
            , '||', IFNULL(TRIM(CUOBJ_CH::text), '^^') 
            , '||', IFNULL(TRIM(EXVKW::text), '^^') 
            , '||', IFNULL(TRIM(PPRCTR::text), '^^') 
            , '||', IFNULL(TRIM(RSART::text), '^^') 
            , '||', IFNULL(TRIM(GEBER::text), '^^') 
            , '||', IFNULL(TRIM(FISTL::text), '^^') 
            , '||', IFNULL(TRIM(MATBF::text), '^^') 
            , '||', IFNULL(TRIM(UMMAB::text), '^^') 
            , '||', IFNULL(TRIM(BUSTM::text), '^^') 
            , '||', IFNULL(TRIM(BUSTW::text), '^^') 
            , '||', IFNULL(TRIM(MENGU::text), '^^') 
            , '||', IFNULL(TRIM(WERTU::text), '^^') 
            , '||', IFNULL(TRIM(LBKUM::text), '^^') 
            , '||', IFNULL(TRIM(SALK3::text), '^^') 
            , '||', IFNULL(TRIM(VPRSV::text), '^^') 
            , '||', IFNULL(TRIM(FKBER::text), '^^') 
            , '||', IFNULL(TRIM(DABRBZ::text), '^^') 
            , '||', IFNULL(TRIM(VKWRA::text), '^^') 
            , '||', IFNULL(TRIM(DABRZ::text), '^^') 
            , '||', IFNULL(TRIM(XBEAU::text), '^^') 
            , '||', IFNULL(TRIM(LSMNG::text), '^^') 
            , '||', IFNULL(TRIM(LSMEH::text), '^^') 
            , '||', IFNULL(TRIM(KZBWS::text), '^^') 
            , '||', IFNULL(TRIM(QINSPST::text), '^^') 
            , '||', IFNULL(TRIM(URZEI::text), '^^') 
            , '||', IFNULL(TRIM(J_1BEXBASE::text), '^^') 
            , '||', IFNULL(TRIM(MWSKZ::text), '^^') 
            , '||', IFNULL(TRIM(TXJCD::text), '^^') 
            , '||', IFNULL(TRIM(EMATN::text), '^^') 
            , '||', IFNULL(TRIM(J_1AGIRUPD::text), '^^') 
            , '||', IFNULL(TRIM(VKMWS::text), '^^') 
            , '||', IFNULL(TRIM(HSDAT::text), '^^') 
            , '||', IFNULL(TRIM(BERKZ::text), '^^') 
            , '||', IFNULL(TRIM(MAT_KDAUF::text), '^^') 
            , '||', IFNULL(TRIM(MAT_KDPOS::text), '^^') 
            , '||', IFNULL(TRIM(MAT_PSPNR::text), '^^') 
            , '||', IFNULL(TRIM(XWOFF::text), '^^') 
            , '||', IFNULL(TRIM(BEMOT::text), '^^') 
            , '||', IFNULL(TRIM(PRZNR::text), '^^') 
            , '||', IFNULL(TRIM(LLIEF::text), '^^') 
            , '||', IFNULL(TRIM(LSTAR::text), '^^') 
            , '||', IFNULL(TRIM(XOBEW::text), '^^') 
            , '||', IFNULL(TRIM(GRANT_NBR::text), '^^') 
            , '||', IFNULL(TRIM(ZUSTD_T156M::text), '^^') 
            , '||', IFNULL(TRIM(SPE_GTS_STOCK_TY::text), '^^') 
            , '||', IFNULL(TRIM(KBLNR::text), '^^') 
            , '||', IFNULL(TRIM(KBLPOS::text), '^^') 
            , '||', IFNULL(TRIM(XMACC::text), '^^') 
            , '||', IFNULL(TRIM(VGART_MKPF::text), '^^') 
            , '||', IFNULL(TRIM(BUDAT_MKPF::text), '^^') 
            , '||', IFNULL(TRIM(CPUDT_MKPF::text), '^^') 
            , '||', IFNULL(TRIM(CPUTM_MKPF::text), '^^') 
            , '||', IFNULL(TRIM(USNAM_MKPF::text), '^^') 
            , '||', IFNULL(TRIM(XBLNR_MKPF::text), '^^') 
            , '||', IFNULL(TRIM(TCODE2_MKPF::text), '^^') 
            , '||', IFNULL(TRIM(SGT_SCAT::text), '^^') 
            , '||', IFNULL(TRIM(SGT_UMSCAT::text), '^^') 
            , '||', IFNULL(TRIM(SGT_RCAT::text), '^^') 
            , '||', IFNULL(TRIM(BEV2_ED_KZ_VER::text), '^^') 
            , '||', IFNULL(TRIM(BEV2_ED_USER::text), '^^') 
            , '||', IFNULL(TRIM(BEV2_ED_AEDAT::text), '^^') 
            , '||', IFNULL(TRIM(BEV2_ED_AETIM::text), '^^') 
            , '||', IFNULL(TRIM(DISUB_OWNER::text), '^^') 
            , '||', IFNULL(TRIM(FSH_SEASON_YEAR::text), '^^') 
            , '||', IFNULL(TRIM(FSH_SEASON::text), '^^') 
            , '||', IFNULL(TRIM(FSH_COLLECTION::text), '^^') 
            , '||', IFNULL(TRIM(FSH_THEME::text), '^^') 
            , '||', IFNULL(TRIM(FSH_UMSEA_YR::text), '^^') 
            , '||', IFNULL(TRIM(FSH_UMSEA::text), '^^') 
            , '||', IFNULL(TRIM(FSH_UMCOLL::text), '^^') 
            , '||', IFNULL(TRIM(FSH_UMTHEME::text), '^^') 
            , '||', IFNULL(TRIM(SGT_CHINT::text), '^^') 
            , '||', IFNULL(TRIM(FSH_DEALLOC_QTY::text), '^^') 
            , '||', IFNULL(TRIM(OINAVNW::text), '^^') 
            , '||', IFNULL(TRIM(OICONDCOD::text), '^^') 
            , '||', IFNULL(TRIM(CONDI::text), '^^') 
            , '||', IFNULL(TRIM(WRF_CHARSTC1::text), '^^') 
            , '||', IFNULL(TRIM(WRF_CHARSTC2::text), '^^') 
            , '||', IFNULL(TRIM(WRF_CHARSTC3::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT