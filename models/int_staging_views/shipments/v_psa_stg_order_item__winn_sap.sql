---- SRC LAYER ----
WITH
SRC_vbap           as ( SELECT "/BEV1/SRFUND", ABDAT, ABFOR, ABGES, ABGRS, ABGRU, ABLFZ, ABSFZ, AEDAT, ANTLF, ANZSN, APLZL_OAA, APLZL_OLC, ARKTX, ARSNUM, ARSPOS, ATPKZ, 
                        AUFNR, AUFPL_OAA, AUFPL_OLC, AWAHR, BEDAE, BERID, BETC, BONUS, BPN, BRGEW, BUDGET_PD, BWTAR, BWTEX, CANCEL_ALLOW, CEPOK, CHARG, CHMVS, CHSPL, 
                        CLINT, CMKUA, CMPNT, CMPRE, CMPRE_FLT, CMTFG, CUOBJ, CUOBJ_CH, EAN11, EANNR, ERDAT, ERLRE, ERNAM, ERZET, EXART, FAKSP, FERC_IND, FISCAL_INCENTIVE, 
                        FISCAL_INCENTIVE_ID, FISTL, FIXMG, FKBER, FKREL, FMENG, FMFGUS_KEY, FONDS, FSH_CANDATE, FSH_COLLECTION, FSH_CRSD, FSH_GRID_COND_REC, FSH_ITEM, 
                        FSH_ITEM_GROUP, FSH_PQR_UEPOS, FSH_PSM_PFM_SPLIT, FSH_SEAREF, FSH_SEASON, FSH_SEASON_YEAR, FSH_THEME, FSH_TRANSACTION, FSH_VASREF, FSH_VAS_PRNT_ID, 
                        FSH_VAS_REL, GEWEI, GLCHANGETIME, GLDELFLAG, GLREQUEST, GLSOURCESYSTEM, GRANT_NBR, GRKOR, GRPOS, GSBER, HANDOVERDATE, HANDOVERLOC, HANDOVERTIME, 
                        IUID_RELEVANT, J_1BCFOP, J_1BTAXLW1, J_1BTAXLW2, J_1BTAXLW3, J_1BTAXLW4, J_1BTAXLW5, J_1BTXSDC, KALNR, KALSM_K, KALVAR, KANNR, KBMENG, KBVER, 
                        KDMAT, KEVER, KLMENG, KLVAR, KMEIN, KMPMG, KNTTP, KNUMA_AG, KNUMA_PI, KNUMH, KONDM, KOSCH, KOSTL, KOUPD, KOWRR, KPEIN, KTGRM, KWMENG, KZBWS, 
                        KZFME, KZTLF, KZVBR, KZWI1, KZWI2, KZWI3, KZWI4, KZWI5, KZWI6, LFMNG, LFREL, LGORT, LOGSYS_EXT, LPRIO, LSMENG, LSTANR, MAGRV, MANDT, 
                        MANUAL_TC_REASON, MATKL, MATNR, MATWA, MEINS, MFRGR, MILL_SE_GPOSN, MOD_ALLOW, MPROK, MSR_APPROV_BLOCK, MSR_REFUND_CODE, MSR_RET_REASON, MTVFP, 
                        MVGR1, MVGR2, MVGR3, MVGR4, MVGR5, MWSBP, NACHL, NETPR, NETWR, NRAB_KNUMH, NTGEW, OBJNR, PAOBJNR, PARGB, PAY_METHOD, PCTRF, PLAVO, PMATN, POSAR, 
                        POSEX, POSNR, POSNV, PRBME, PRCTR, PREFE, PRODH, PROSA, PROVG, PRSOK, PRS_OBJNR, PRS_SD_SPSNR, PRS_WORK_PERIOD, PSA_DELETE_IND, PSA_LOAD_DTS, 
                        PSA_RECORD_SOURCE, PSTYV, PS_PSP_PNR, REP_FREQ, REVACC_REFID, REVACC_REFTYPE, RKFKF, ROUTE, SERAIL, SERNR, SGT_RCAT, SHKZG, SKOPF, SKTOF, SLOCTYPE, 
                        SMENG, SOBKZ, SPART, SPCSTO, SPOSN, STADAT, STAFO, STCUR, STDAT, STKEY, STLKN, STLNR, STLTY, STMAN, STOCKLOC, STPOS, STPOZ, SUGRD, SUMBD, TAS, 
                        TAXM1, TAXM2, TAXM3, TAXM4, TAXM5, TAXM6, TAXM7, TAXM8, TAXM9, TAX_SUBJECT_ST, TC_AUT_DET, TECHS, TRMRISK_RELEVANT, UEBTK, UEBTO, UEPOS, UEPVW, 
                        UKONM, UMREF, UMVKN, UMVKZ, UMZIN, UMZIZ, UNTTO, UPFLU, UPMAT, VBEAF, VBEAV, VBELN, VBELV, VGBEL, VGPOS, VGREF, VGTYP, VKAUS, VKGRU, VOLEH, VOLUM, 
                        VOREF, VPMAT, VPWRK, VPZUO, VRKME, VSTEL, WAERK, WAVWR, WERKS, WGRU1, WGRU2, WKTNR, WKTPS, WRF_CHARSTC1, WRF_CHARSTC2, WRF_CHARSTC3, WTYSC_CLMITEM, 
                        XCHAR, XCHPF, ZIEME, ZMENG, ZSCHL_K, ZWERT, ZZAPRVGRP, ZZAUFNR, ZZKNUMA, ZZKZWI10, ZZKZWI11, ZZKZWI12, ZZKZWI13, ZZKZWI14, ZZKZWI15, ZZKZWI16, 
                        ZZKZWI17, ZZKZWI7, ZZKZWI8, ZZKZWI9, ZZLOCUSED, ZZRECMAN, ZZLPSBSRC, ZZLPSFRID, _DATAAGING FROM {{ source('sap_ecc_prd', 'z_vbap') }} as SRC ),
SRC_a              as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  ),
SRC_billto         as ( SELECT KUNNR, PARVW, POSNR, VBELN FROM {{ source('sap_ecc_prd', 'z_vbpa') }} as SRC 
                        WHERE PARVW = 'RE'
                        QUALIFY 1 = ROW_NUMBER()OVER(PARTITION BY VBELN, POSNR ORDER BY PSA_LOAD_DTS DESC) ),
SRC_shipto         as ( SELECT KUNNR, PARVW, POSNR, VBELN FROM {{ source('sap_ecc_prd', 'z_vbpa') }} as SRC 
                        WHERE PARVW = 'WE'
                        QUALIFY 1 = ROW_NUMBER()OVER(PARTITION BY VBELN, POSNR ORDER BY PSA_LOAD_DTS DESC) ),
SRC_payer          as ( SELECT KUNNR, PARVW, POSNR, VBELN FROM {{ source('sap_ecc_prd', 'z_vbpa') }} as SRC 
                        WHERE PARVW = 'RG'
                        QUALIFY 1 = ROW_NUMBER()OVER(PARTITION BY VBELN, POSNR ORDER BY PSA_LOAD_DTS DESC) ),
SRC_insurance      as ( SELECT KUNNR, PARVW, POSNR, VBELN FROM {{ source('sap_ecc_prd', 'z_vbpa') }} as SRC 
                        WHERE PARVW = 'YO'
                        QUALIFY 1 = ROW_NUMBER()OVER(PARTITION BY VBELN, POSNR ORDER BY PSA_LOAD_DTS DESC) ),
SRC_vbak           as ( SELECT VBELN, VKORG, VTWEG, KUNNR FROM {{ source('sap_ecc_prd', 'z_vbak') }} as SRC
                        QUALIFY 1 = ROW_NUMBER()OVER(PARTITION BY VBELN ORDER BY PSA_LOAD_DTS DESC) )

/*
SRC_vbap           as ( SELECT * FROM sap_ecc_prd.z_vbap )
SRC_a              as ( SELECT * FROM raw_vault.ref_business_key_collision )
SRC_billto         as ( SELECT * FROM sap_ecc_prd.z_vbpa )
SRC_shipto         as ( SELECT * FROM sap_ecc_prd.z_vbpa )
SRC_vbak         as ( SELECT * FROM sap_ecc_prd.z_vbak )
SRC_payer          as ( SELECT * FROM sap_ecc_prd.z_vbpa )
SRC_insurance      as ( SELECT * FROM sap_ecc_prd.z_vbpa )
*/
---- LOGIC LAYER ----

, LOGIC_vbap as (
    SELECT
        CONCAT_WS('||', COALESCE(VBELN, ''), COALESCE(POSNR, ''))    as                                      ORDER_LINE_BK
      , COALESCE(NULLIF(TRIM(MATNR),''),'-1')                        as                                            ITEM_BK
      , TO_CHAR(COALESCE(VBELN,'-1'))                                as                                    ORDER_HEADER_BK
      , MANDT
      , VBELN
      , POSNR
      , GLREQUEST
      , MATNR
      , MATWA
      , PMATN
      , CHARG
      , MATKL
      , ARKTX
      , PSTYV
      , POSAR
      , LFREL
      , FKREL
      , UEPOS
      , GRPOS
      , ABGRU
      , PRODH
      , ZWERT
      , ZMENG
      , ZIEME
      , UMZIZ
      , UMZIN
      , MEINS
      , SMENG
      , ABLFZ
      , ABDAT
      , TRY_TO_DATE(ABDAT, 'YYYYMMDD')                               as                                           ABDAT_DT
      , ABSFZ
      , POSEX
      , KDMAT
      , KBVER
      , KEVER
      , VKGRU
      , VKAUS
      , GRKOR
      , FMENG
      , UEBTK
      , UEBTO
      , UNTTO
      , FAKSP
      , ATPKZ
      , RKFKF
      , SPART
      , GSBER
      , NETWR
      , WAERK
      , ANTLF
      , KZTLF
      , CHSPL
      , KWMENG
      , LSMENG
      , KBMENG
      , KLMENG
      , VRKME
      , UMVKZ
      , UMVKN
      , BRGEW
      , NTGEW
      , GEWEI
      , VOLUM
      , VOLEH
      , VBELV
      , POSNV
      , VGBEL
      , VGPOS
      , VOREF
      , UPFLU
      , ERLRE
      , LPRIO
      , WERKS
      , LGORT
      , VSTEL
      , ROUTE
      , STKEY
      , STDAT
      , TRY_TO_DATE(STDAT, 'YYYYMMDD')                               as                                           STDAT_DT
      , STLNR
      , STPOS
      , AWAHR
      , ERDAT
      , ERNAM
      , ERZET
      , TAXM1
      , TAXM2
      , TAXM3
      , TAXM4
      , TAXM5
      , TAXM6
      , TAXM7
      , TAXM8
      , TAXM9
      , VBEAF
      , VBEAV
      , VGREF
      , NETPR
      , KPEIN
      , KMEIN
      , SHKZG
      , SKTOF
      , MTVFP
      , SUMBD
      , KONDM
      , KTGRM
      , BONUS
      , PROVG
      , EANNR
      , PRSOK
      , BWTAR
      , BWTEX
      , XCHPF
      , XCHAR
      , LFMNG
      , STAFO
      , WAVWR
      , KZWI1
      , KZWI2
      , KZWI3
      , KZWI4
      , KZWI5
      , KZWI6
      , STCUR
      , AEDAT
      , TRY_TO_DATE(AEDAT, 'YYYYMMDD')                               as                                           AEDAT_DT
      , EAN11
      , FIXMG
      , PRCTR
      , MVGR1
      , MVGR2
      , MVGR3
      , MVGR4
      , MVGR5
      , KMPMG
      , SUGRD
      , SOBKZ
      , VPZUO
      , PAOBJNR
      , PS_PSP_PNR
      , AUFNR
      , VPMAT
      , VPWRK
      , PRBME
      , UMREF
      , KNTTP
      , KZVBR
      , SERNR
      , OBJNR
      , ABGRS
      , BEDAE
      , CMPRE
      , CMTFG
      , CMPNT
      , CMKUA
      , CUOBJ
      , CUOBJ_CH
      , CEPOK
      , KOUPD
      , SERAIL
      , ANZSN
      , NACHL
      , MAGRV
      , MPROK
      , VGTYP
      , PROSA
      , UEPVW
      , KALNR
      , KLVAR
      , SPOSN
      , KOWRR
      , STADAT
      , TRY_TO_DATE(STADAT, 'YYYYMMDD')                              as                                          STADAT_DT
      , EXART
      , PREFE
      , KNUMH
      , CLINT
      , CHMVS
      , STLTY
      , STLKN
      , STPOZ
      , STMAN
      , ZSCHL_K
      , KALSM_K
      , KALVAR
      , KOSCH
      , UPMAT
      , UKONM
      , MFRGR
      , PLAVO
      , KANNR
      , CMPRE_FLT
      , ABFOR
      , ABGES
      , J_1BCFOP
      , J_1BTAXLW1
      , J_1BTAXLW2
      , J_1BTXSDC
      , WKTNR
      , WKTPS
      , SKOPF
      , KZBWS
      , WGRU1
      , WGRU2
      , KNUMA_PI
      , KNUMA_AG
      , KZFME
      , LSTANR
      , TECHS
      , MWSBP
      , BERID
      , PCTRF
      , LOGSYS_EXT
      , J_1BTAXLW3
      , J_1BTAXLW4
      , J_1BTAXLW5
      , STOCKLOC
      , SLOCTYPE
      , MSR_RET_REASON
      , MSR_REFUND_CODE
      , MSR_APPROV_BLOCK
      , NRAB_KNUMH
      , TRMRISK_RELEVANT
      , SGT_RCAT
      , HANDOVERLOC
      , HANDOVERDATE
      , HANDOVERTIME
      , TC_AUT_DET
      , MANUAL_TC_REASON
      , FISCAL_INCENTIVE
      , TAX_SUBJECT_ST
      , FISCAL_INCENTIVE_ID
      , SPCSTO
      , _DATAAGING
      , REVACC_REFID
      , REVACC_REFTYPE
      , "/BEV1/SRFUND"                                               as                                             SRFUND
      , AUFPL_OLC
      , APLZL_OLC
      , FERC_IND
      , FSH_SEASON_YEAR
      , FSH_SEASON
      , FSH_COLLECTION
      , FSH_THEME
      , FSH_CRSD
      , FSH_SEAREF
      , FSH_CANDATE
      , FSH_PSM_PFM_SPLIT
      , FSH_VAS_REL
      , FSH_VAS_PRNT_ID
      , FSH_TRANSACTION
      , FSH_ITEM_GROUP
      , FSH_ITEM
      , FSH_VASREF
      , FSH_GRID_COND_REC
      , FSH_PQR_UEPOS
      , KOSTL
      , FONDS
      , FISTL
      , FKBER
      , GRANT_NBR
      , BUDGET_PD
      , IUID_RELEVANT
      , MILL_SE_GPOSN
      , PRS_OBJNR
      , PRS_SD_SPSNR
      , PRS_WORK_PERIOD
      , TAS
      , BETC
      , MOD_ALLOW
      , CANCEL_ALLOW
      , PAY_METHOD
      , BPN
      , REP_FREQ
      , FMFGUS_KEY
      , PARGB
      , AUFPL_OAA
      , APLZL_OAA
      , WRF_CHARSTC1
      , WRF_CHARSTC2
      , WRF_CHARSTC3
      , ARSNUM
      , ARSPOS
      , WTYSC_CLMITEM
      , ZZKNUMA
      , ZZKZWI7
      , ZZKZWI8
      , ZZKZWI9
      , ZZKZWI10
      , ZZKZWI11
      , ZZKZWI12
      , ZZKZWI13
      , ZZKZWI14
      , ZZKZWI15
      , ZZKZWI16
      , ZZKZWI17
      , ZZAUFNR
      , ZZAPRVGRP
      , ZZLOCUSED
      , ZZRECMAN
      , ZZLPSBSRC
      , ZZLPSFRID     
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
    FROM SRC_vbap
)

, LOGIC_a as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_a
)

, LOGIC_billto as (
    SELECT
        PARVW                                                        as                                       BILLTO_PARVW
      , KUNNR                                                        as                                       BILLTO_KUNNR
      , KUNNR
      , POSNR                                                        as                                       BILLTO_POSNR
      , VBELN                                                        as                                       BILLTO_VBELN
    FROM SRC_billto
)

, LOGIC_shipto as (
    SELECT
        PARVW                                                        as                                       SHIPTO_PARVW
      , KUNNR                                                        as                                       SHIPTO_KUNNR
      , POSNR                                                        as                                       SHIPTO_POSNR
      , VBELN                                                        as                                       SHIPTO_VBELN
    FROM SRC_shipto
)

, LOGIC_payer as (
    SELECT
        PARVW                                                        as                                        PAYER_PARVW
      , PARVW
      , KUNNR                                                        as                                        PAYER_KUNNR
      , POSNR                                                        as                                        PAYER_POSNR
      , VBELN                                                        as                                        PAYER_VBELN
    FROM SRC_payer
)

, LOGIC_insurance as (
    SELECT
        PARVW                                                        as                                    INSURANCE_PARVW
      , KUNNR                                                        as                                    INSURANCE_KUNNR
      , POSNR                                                        as                                    INSURANCE_POSNR
      , VBELN                                                        as                                    INSURANCE_VBELN
    FROM SRC_insurance
)

, LOGIC_vbak as (
    SELECT
        VKORG
      , VTWEG
      , VBELN                                                       as                                        VBAK_VBELN
      , KUNNR                                                       as                                        SOLDTO_KUNNR
    FROM SRC_vbak
)
---- RENAME LAYER ----

, RENAME_vbap as (
    SELECT
        ORDER_LINE_BK
      , ITEM_BK
      , ORDER_HEADER_BK
      , MANDT
      , VBELN
      , POSNR
      , GLREQUEST
      , MATNR
      , MATWA
      , PMATN
      , CHARG
      , MATKL
      , ARKTX
      , PSTYV
      , POSAR
      , LFREL
      , FKREL
      , UEPOS
      , GRPOS
      , ABGRU
      , PRODH
      , ZWERT
      , ZMENG
      , ZIEME
      , UMZIZ
      , UMZIN
      , MEINS
      , SMENG
      , ABLFZ
      , ABDAT
      , ABDAT_DT
      , ABSFZ
      , POSEX
      , KDMAT
      , KBVER
      , KEVER
      , VKGRU
      , VKAUS
      , GRKOR
      , FMENG
      , UEBTK
      , UEBTO
      , UNTTO
      , FAKSP
      , ATPKZ
      , RKFKF
      , SPART
      , GSBER
      , NETWR
      , WAERK
      , ANTLF
      , KZTLF
      , CHSPL
      , KWMENG
      , LSMENG
      , KBMENG
      , KLMENG
      , VRKME
      , UMVKZ
      , UMVKN
      , BRGEW
      , NTGEW
      , GEWEI
      , VOLUM
      , VOLEH
      , VBELV
      , POSNV
      , VGBEL
      , VGPOS
      , VOREF
      , UPFLU
      , ERLRE
      , LPRIO
      , WERKS
      , LGORT
      , VSTEL
      , ROUTE
      , STKEY
      , STDAT
      , STDAT_DT
      , STLNR
      , STPOS
      , AWAHR
      , ERDAT
      , ERNAM
      , ERZET
      , TAXM1
      , TAXM2
      , TAXM3
      , TAXM4
      , TAXM5
      , TAXM6
      , TAXM7
      , TAXM8
      , TAXM9
      , VBEAF
      , VBEAV
      , VGREF
      , NETPR
      , KPEIN
      , KMEIN
      , SHKZG
      , SKTOF
      , MTVFP
      , SUMBD
      , KONDM
      , KTGRM
      , BONUS
      , PROVG
      , EANNR
      , PRSOK
      , BWTAR
      , BWTEX
      , XCHPF
      , XCHAR
      , LFMNG
      , STAFO
      , WAVWR
      , KZWI1
      , KZWI2
      , KZWI3
      , KZWI4
      , KZWI5
      , KZWI6
      , STCUR
      , AEDAT
      , AEDAT_DT
      , EAN11
      , FIXMG
      , PRCTR
      , MVGR1
      , MVGR2
      , MVGR3
      , MVGR4
      , MVGR5
      , KMPMG
      , SUGRD
      , SOBKZ
      , VPZUO
      , PAOBJNR
      , PS_PSP_PNR
      , AUFNR
      , VPMAT
      , VPWRK
      , PRBME
      , UMREF
      , KNTTP
      , KZVBR
      , SERNR
      , OBJNR
      , ABGRS
      , BEDAE
      , CMPRE
      , CMTFG
      , CMPNT
      , CMKUA
      , CUOBJ
      , CUOBJ_CH
      , CEPOK
      , KOUPD
      , SERAIL
      , ANZSN
      , NACHL
      , MAGRV
      , MPROK
      , VGTYP
      , PROSA
      , UEPVW
      , KALNR
      , KLVAR
      , SPOSN
      , KOWRR
      , STADAT
      , STADAT_DT
      , EXART
      , PREFE
      , KNUMH
      , CLINT
      , CHMVS
      , STLTY
      , STLKN
      , STPOZ
      , STMAN
      , ZSCHL_K
      , KALSM_K
      , KALVAR
      , KOSCH
      , UPMAT
      , UKONM
      , MFRGR
      , PLAVO
      , KANNR
      , CMPRE_FLT
      , ABFOR
      , ABGES
      , J_1BCFOP
      , J_1BTAXLW1
      , J_1BTAXLW2
      , J_1BTXSDC
      , WKTNR
      , WKTPS
      , SKOPF
      , KZBWS
      , WGRU1
      , WGRU2
      , KNUMA_PI
      , KNUMA_AG
      , KZFME
      , LSTANR
      , TECHS
      , MWSBP
      , BERID
      , PCTRF
      , LOGSYS_EXT
      , J_1BTAXLW3
      , J_1BTAXLW4
      , J_1BTAXLW5
      , STOCKLOC
      , SLOCTYPE
      , MSR_RET_REASON
      , MSR_REFUND_CODE
      , MSR_APPROV_BLOCK
      , NRAB_KNUMH
      , TRMRISK_RELEVANT
      , SGT_RCAT
      , HANDOVERLOC
      , HANDOVERDATE
      , HANDOVERTIME
      , TC_AUT_DET
      , MANUAL_TC_REASON
      , FISCAL_INCENTIVE
      , TAX_SUBJECT_ST
      , FISCAL_INCENTIVE_ID
      , SPCSTO
      , _DATAAGING
      , REVACC_REFID
      , REVACC_REFTYPE
      , SRFUND
      , AUFPL_OLC
      , APLZL_OLC
      , FERC_IND
      , FSH_SEASON_YEAR
      , FSH_SEASON
      , FSH_COLLECTION
      , FSH_THEME
      , FSH_CRSD
      , FSH_SEAREF
      , FSH_CANDATE
      , FSH_PSM_PFM_SPLIT
      , FSH_VAS_REL
      , FSH_VAS_PRNT_ID
      , FSH_TRANSACTION
      , FSH_ITEM_GROUP
      , FSH_ITEM
      , FSH_VASREF
      , FSH_GRID_COND_REC
      , FSH_PQR_UEPOS
      , KOSTL
      , FONDS
      , FISTL
      , FKBER
      , GRANT_NBR
      , BUDGET_PD
      , IUID_RELEVANT
      , MILL_SE_GPOSN
      , PRS_OBJNR
      , PRS_SD_SPSNR
      , PRS_WORK_PERIOD
      , TAS
      , BETC
      , MOD_ALLOW
      , CANCEL_ALLOW
      , PAY_METHOD
      , BPN
      , REP_FREQ
      , FMFGUS_KEY
      , PARGB
      , AUFPL_OAA
      , APLZL_OAA
      , WRF_CHARSTC1
      , WRF_CHARSTC2
      , WRF_CHARSTC3
      , ARSNUM
      , ARSPOS
      , WTYSC_CLMITEM
      , ZZKNUMA
      , ZZKZWI7
      , ZZKZWI8
      , ZZKZWI9
      , ZZKZWI10
      , ZZKZWI11
      , ZZKZWI12
      , ZZKZWI13
      , ZZKZWI14
      , ZZKZWI15
      , ZZKZWI16
      , ZZKZWI17
      , ZZAUFNR
      , ZZAPRVGRP
      , ZZLOCUSED
      , ZZRECMAN
      , ZZLPSBSRC
      , ZZLPSFRID   
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
    FROM LOGIC_vbap
)

, RENAME_a as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_a
)

, RENAME_payer as (
    SELECT
        PAYER_PARVW
      , PARVW
      , PAYER_KUNNR
      , PAYER_POSNR
      , PAYER_VBELN
    FROM LOGIC_payer
)

, RENAME_billto as (
    SELECT
        BILLTO_PARVW
      , BILLTO_KUNNR
      , KUNNR
      , BILLTO_POSNR
      , BILLTO_VBELN
    FROM LOGIC_billto
)

, RENAME_shipto as (
    SELECT
        SHIPTO_PARVW
      , SHIPTO_KUNNR
      , SHIPTO_POSNR
      , SHIPTO_VBELN
    FROM LOGIC_shipto
)


, RENAME_insurance as (
    SELECT
        INSURANCE_PARVW
      , INSURANCE_KUNNR
      , INSURANCE_POSNR
      , INSURANCE_VBELN
    FROM LOGIC_insurance
)

, RENAME_vbak as (
    SELECT
        VKORG
      , VTWEG
      , VBAK_VBELN
      , SOLDTO_KUNNR
    FROM LOGIC_vbak
)
---- FILTER LAYER ----

, FILTER_vbap as (
    SELECT *
    FROM RENAME_vbap
)

, FILTER_a as (
    SELECT *
    FROM RENAME_a
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_VBAP'
)

, FILTER_billto as (
    SELECT *
    FROM RENAME_billto
)

, FILTER_shipto as (
    SELECT *
    FROM RENAME_shipto
)


, FILTER_payer as (
    SELECT *
    FROM RENAME_payer
)

, FILTER_insurance as (
    SELECT *
    FROM RENAME_insurance
)

, FILTER_vbak as (
    SELECT *
    FROM RENAME_vbak
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_vbap
    INNER JOIN FILTER_a
        ON '1' = '1'
    LEFT JOIN FILTER_billto
        ON vbeln = billto_vbeln
AND posnr = billto_posnr
    LEFT JOIN FILTER_shipto
        ON vbeln = shipto_vbeln
AND posnr = shipto_posnr
    LEFT JOIN FILTER_payer
        ON vbeln = payer_vbeln
AND posnr = payer_posnr
    LEFT JOIN FILTER_insurance
        ON vbeln = insurance_vbeln
AND posnr = insurance_posnr
    LEFT JOIN FILTER_vbak
        ON VBELN = VBAK_VBELN
)

---- FINAL LAYER ----
SELECT
          ORDER_LINE_BK
        , ITEM_BK
        , ORDER_HEADER_BK
        , COALESCE(NULLIF(TRIM(SOLDTO_KUNNR),''),'-1')                   as CUSTOMER_SOLDTO_BK
        , COALESCE(NULLIF(TRIM(BILLTO_KUNNR),''),'-1')                 as CUSTOMER_BILLTO_BK
        , COALESCE(NULLIF(TRIM(SHIPTO_KUNNR),''),'-1')                 as CUSTOMER_SHIPTO_BK
        , COALESCE(NULLIF(TRIM(PAYER_KUNNR),''),'-1')                  as CUSTOMER_PAYER_BK
        , COALESCE(NULLIF(TRIM(INSURANCE_KUNNR),''),'-1')              as CUSTOMER_INSURANCEPARTNER_BK
        , COALESCE(NULLIF(TRIM(WERKS),''),'-1')                        as PLANT_BK
        , COALESCE(NULLIF(TRIM(SPART),''),'-1')                        as DIVISION_BK
        , COALESCE(NULLIF(TRIM(VKORG),''),'-1')                        as SALES_ORGANIZATION_BK
        , COALESCE(NULLIF(TRIM(VTWEG),''),'-1')                        as DISTRIBUTION_CHANNEL_BK
        , MANDT
        , VBELN
        , POSNR
        , GLREQUEST
        , MATNR
        , MATWA
        , PMATN
        , CHARG
        , MATKL
        , ARKTX
        , PSTYV
        , POSAR
        , LFREL
        , FKREL
        , UEPOS
        , GRPOS
        , ABGRU
        , PRODH
        , ZWERT
        , ZMENG
        , ZIEME
        , UMZIZ
        , UMZIN
        , MEINS
        , SMENG
        , ABLFZ
        , ABDAT
        , ABDAT_DT
        , ABSFZ
        , POSEX
        , KDMAT
        , KBVER
        , KEVER
        , VKGRU
        , VKAUS
        , GRKOR
        , FMENG
        , UEBTK
        , UEBTO
        , UNTTO
        , FAKSP
        , ATPKZ
        , RKFKF
        , SPART
        , GSBER
        , NETWR
        , WAERK
        , ANTLF
        , KZTLF
        , CHSPL
        , KWMENG
        , LSMENG
        , KBMENG
        , KLMENG
        , VRKME
        , UMVKZ
        , UMVKN
        , BRGEW
        , NTGEW
        , GEWEI
        , VOLUM
        , VOLEH
        , VBELV
        , POSNV
        , VGBEL
        , VGPOS
        , VOREF
        , UPFLU
        , ERLRE
        , LPRIO
        , WERKS
        , LGORT
        , VSTEL
        , ROUTE
        , STKEY
        , STDAT
        , STDAT_DT
        , STLNR
        , STPOS
        , AWAHR
        , ERDAT
        , ERNAM
        , ERZET
        , TAXM1
        , TAXM2
        , TAXM3
        , TAXM4
        , TAXM5
        , TAXM6
        , TAXM7
        , TAXM8
        , TAXM9
        , VBEAF
        , VBEAV
        , VGREF
        , NETPR
        , KPEIN
        , KMEIN
        , SHKZG
        , SKTOF
        , MTVFP
        , SUMBD
        , KONDM
        , KTGRM
        , BONUS
        , PROVG
        , EANNR
        , PRSOK
        , BWTAR
        , BWTEX
        , XCHPF
        , XCHAR
        , LFMNG
        , STAFO
        , WAVWR
        , KZWI1
        , KZWI2
        , KZWI3
        , KZWI4
        , KZWI5
        , KZWI6
        , STCUR
        , AEDAT
        , AEDAT_DT
        , EAN11
        , FIXMG
        , PRCTR
        , MVGR1
        , MVGR2
        , MVGR3
        , MVGR4
        , MVGR5
        , KMPMG
        , SUGRD
        , SOBKZ
        , VPZUO
        , PAOBJNR
        , PS_PSP_PNR
        , AUFNR
        , VPMAT
        , VPWRK
        , PRBME
        , UMREF
        , KNTTP
        , KZVBR
        , SERNR
        , OBJNR
        , ABGRS
        , BEDAE
        , CMPRE
        , CMTFG
        , CMPNT
        , CMKUA
        , CUOBJ
        , CUOBJ_CH
        , CEPOK
        , KOUPD
        , SERAIL
        , ANZSN
        , NACHL
        , MAGRV
        , MPROK
        , VGTYP
        , PROSA
        , UEPVW
        , KALNR
        , KLVAR
        , SPOSN
        , KOWRR
        , STADAT
        , STADAT_DT
        , EXART
        , PREFE
        , KNUMH
        , CLINT
        , CHMVS
        , STLTY
        , STLKN
        , STPOZ
        , STMAN
        , ZSCHL_K
        , KALSM_K
        , KALVAR
        , KOSCH
        , UPMAT
        , UKONM
        , MFRGR
        , PLAVO
        , KANNR
        , CMPRE_FLT
        , ABFOR
        , ABGES
        , J_1BCFOP
        , J_1BTAXLW1
        , J_1BTAXLW2
        , J_1BTXSDC
        , WKTNR
        , WKTPS
        , SKOPF
        , KZBWS
        , WGRU1
        , WGRU2
        , KNUMA_PI
        , KNUMA_AG
        , KZFME
        , LSTANR
        , TECHS
        , MWSBP
        , BERID
        , PCTRF
        , LOGSYS_EXT
        , J_1BTAXLW3
        , J_1BTAXLW4
        , J_1BTAXLW5
        , STOCKLOC
        , SLOCTYPE
        , MSR_RET_REASON
        , MSR_REFUND_CODE
        , MSR_APPROV_BLOCK
        , NRAB_KNUMH
        , TRMRISK_RELEVANT
        , SGT_RCAT
        , HANDOVERLOC
        , HANDOVERDATE
        , HANDOVERTIME
        , TC_AUT_DET
        , MANUAL_TC_REASON
        , FISCAL_INCENTIVE
        , TAX_SUBJECT_ST
        , FISCAL_INCENTIVE_ID
        , SPCSTO
        , _DATAAGING
        , REVACC_REFID
        , REVACC_REFTYPE
        , SRFUND
        , AUFPL_OLC
        , APLZL_OLC
        , FERC_IND
        , FSH_SEASON_YEAR
        , FSH_SEASON
        , FSH_COLLECTION
        , FSH_THEME
        , FSH_CRSD
        , FSH_SEAREF
        , FSH_CANDATE
        , FSH_PSM_PFM_SPLIT
        , FSH_VAS_REL
        , FSH_VAS_PRNT_ID
        , FSH_TRANSACTION
        , FSH_ITEM_GROUP
        , FSH_ITEM
        , FSH_VASREF
        , FSH_GRID_COND_REC
        , FSH_PQR_UEPOS
        , KOSTL
        , FONDS
        , FISTL
        , FKBER
        , GRANT_NBR
        , BUDGET_PD
        , IUID_RELEVANT
        , MILL_SE_GPOSN
        , PRS_OBJNR
        , PRS_SD_SPSNR
        , PRS_WORK_PERIOD
        , TAS
        , BETC
        , MOD_ALLOW
        , CANCEL_ALLOW
        , PAY_METHOD
        , BPN
        , REP_FREQ
        , FMFGUS_KEY
        , PARGB
        , AUFPL_OAA
        , APLZL_OAA
        , WRF_CHARSTC1
        , WRF_CHARSTC2
        , WRF_CHARSTC3
        , ARSNUM
        , ARSPOS
        , WTYSC_CLMITEM
        , ZZKNUMA
        , ZZKZWI7
        , ZZKZWI8
        , ZZKZWI9
        , ZZKZWI10
        , ZZKZWI11
        , ZZKZWI12
        , ZZKZWI13
        , ZZKZWI14
        , ZZKZWI15
        , ZZKZWI16
        , ZZKZWI17
        , ZZAUFNR
        , ZZAPRVGRP
        , ZZLOCUSED
        , ZZRECMAN
        , ZZLPSBSRC
        , ZZLPSFRID   
        , GLDELFLAG
        , GLCHANGETIME
        , GLSOURCESYSTEM
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , PAYER_PARVW
        , PARVW
        , BILLTO_PARVW
        , SHIPTO_PARVW
        , INSURANCE_PARVW
        , PAYER_KUNNR
        , BILLTO_KUNNR
        , KUNNR
        , SHIPTO_KUNNR
        , SOLDTO_KUNNR
        , INSURANCE_KUNNR
        , VKORG
        , VTWEG
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(VBELN as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(POSNR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ORDER_LINE_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(VBELN as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ORDER_HEADER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(VBELN as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(POSNR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(ITEM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(CUSTOMER_SOLDTO_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(CUSTOMER_BILLTO_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(CUSTOMER_SHIPTO_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(CUSTOMER_PAYER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(CUSTOMER_INSURANCEPARTNER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as SO_ITEM_LHK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ITEM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ITEM_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(CUSTOMER_SOLDTO_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as CUSTOMER_SOLDTO_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(CUSTOMER_BILLTO_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as CUSTOMER_BILLTO_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(CUSTOMER_SHIPTO_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as CUSTOMER_SHIPTO_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(CUSTOMER_INSURANCEPARTNER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as CUSTOMER_INSURANCEPARTNER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(CUSTOMER_PAYER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as CUSTOMER_PAYER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PLANT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PLANT_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(DIVISION_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as DIVISION_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(SALES_ORGANIZATION_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as SALES_ORGANIZATION_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(DISTRIBUTION_CHANNEL_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as DISTRIBUTION_CHANNEL_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(MANDT::text), '^^') 
            , '||', IFNULL(TRIM(VBELN::text), '^^') 
            , '||', IFNULL(TRIM(POSNR::text), '^^') 
            , '||', IFNULL(TRIM(MATNR::text), '^^') 
            , '||', IFNULL(TRIM(MATWA::text), '^^')  
            , '||', IFNULL(TRIM(PMATN::text), '^^') 
            , '||', IFNULL(TRIM(CHARG::text), '^^') 
            , '||', IFNULL(TRIM(MATKL::text), '^^') 
            , '||', IFNULL(TRIM(ARKTX::text), '^^') 
            , '||', IFNULL(TRIM(PSTYV::text), '^^') 
            , '||', IFNULL(TRIM(POSAR::text), '^^') 
            , '||', IFNULL(TRIM(LFREL::text), '^^') 
            , '||', IFNULL(TRIM(FKREL::text), '^^') 
            , '||', IFNULL(TRIM(UEPOS::text), '^^') 
            , '||', IFNULL(TRIM(GRPOS::text), '^^') 
            , '||', IFNULL(TRIM(ABGRU::text), '^^') 
            , '||', IFNULL(TRIM(PRODH::text), '^^') 
            , '||', IFNULL(TRIM(ZWERT::text), '^^') 
            , '||', IFNULL(TRIM(ZMENG::text), '^^') 
            , '||', IFNULL(TRIM(ZIEME::text), '^^') 
            , '||', IFNULL(TRIM(UMZIZ::text), '^^') 
            , '||', IFNULL(TRIM(UMZIN::text), '^^') 
            , '||', IFNULL(TRIM(MEINS::text), '^^') 
            , '||', IFNULL(TRIM(SMENG::text), '^^') 
            , '||', IFNULL(TRIM(ABLFZ::text), '^^') 
            , '||', IFNULL(TRIM(ABDAT::text), '^^') 
            , '||', IFNULL(TRIM(ABSFZ::text), '^^') 
            , '||', IFNULL(TRIM(POSEX::text), '^^') 
            , '||', IFNULL(TRIM(KDMAT::text), '^^') 
            , '||', IFNULL(TRIM(KBVER::text), '^^') 
            , '||', IFNULL(TRIM(KEVER::text), '^^') 
            , '||', IFNULL(TRIM(VKGRU::text), '^^') 
            , '||', IFNULL(TRIM(VKAUS::text), '^^') 
            , '||', IFNULL(TRIM(GRKOR::text), '^^') 
            , '||', IFNULL(TRIM(FMENG::text), '^^') 
            , '||', IFNULL(TRIM(UEBTK::text), '^^') 
            , '||', IFNULL(TRIM(UEBTO::text), '^^') 
            , '||', IFNULL(TRIM(UNTTO::text), '^^') 
            , '||', IFNULL(TRIM(FAKSP::text), '^^') 
            , '||', IFNULL(TRIM(ATPKZ::text), '^^') 
            , '||', IFNULL(TRIM(RKFKF::text), '^^') 
            , '||', IFNULL(TRIM(SPART::text), '^^') 
            , '||', IFNULL(TRIM(GSBER::text), '^^') 
            , '||', IFNULL(TRIM(NETWR::text), '^^') 
            , '||', IFNULL(TRIM(WAERK::text), '^^') 
            , '||', IFNULL(TRIM(ANTLF::text), '^^') 
            , '||', IFNULL(TRIM(KZTLF::text), '^^') 
            , '||', IFNULL(TRIM(CHSPL::text), '^^') 
            , '||', IFNULL(TRIM(KWMENG::text), '^^') 
            , '||', IFNULL(TRIM(LSMENG::text), '^^') 
            , '||', IFNULL(TRIM(KBMENG::text), '^^') 
            , '||', IFNULL(TRIM(KLMENG::text), '^^') 
            , '||', IFNULL(TRIM(VRKME::text), '^^') 
            , '||', IFNULL(TRIM(UMVKZ::text), '^^') 
            , '||', IFNULL(TRIM(UMVKN::text), '^^') 
            , '||', IFNULL(TRIM(BRGEW::text), '^^') 
            , '||', IFNULL(TRIM(NTGEW::text), '^^') 
            , '||', IFNULL(TRIM(GEWEI::text), '^^') 
            , '||', IFNULL(TRIM(VOLUM::text), '^^') 
            , '||', IFNULL(TRIM(VOLEH::text), '^^') 
            , '||', IFNULL(TRIM(VBELV::text), '^^') 
            , '||', IFNULL(TRIM(POSNV::text), '^^') 
            , '||', IFNULL(TRIM(VGBEL::text), '^^') 
            , '||', IFNULL(TRIM(VGPOS::text), '^^') 
            , '||', IFNULL(TRIM(VOREF::text), '^^') 
            , '||', IFNULL(TRIM(UPFLU::text), '^^') 
            , '||', IFNULL(TRIM(ERLRE::text), '^^') 
            , '||', IFNULL(TRIM(LPRIO::text), '^^') 
            , '||', IFNULL(TRIM(WERKS::text), '^^') 
            , '||', IFNULL(TRIM(LGORT::text), '^^') 
            , '||', IFNULL(TRIM(VSTEL::text), '^^') 
            , '||', IFNULL(TRIM(ROUTE::text), '^^') 
            , '||', IFNULL(TRIM(STKEY::text), '^^') 
            , '||', IFNULL(TRIM(STDAT::text), '^^') 
            , '||', IFNULL(TRIM(STLNR::text), '^^') 
            , '||', IFNULL(TRIM(STPOS::text), '^^') 
            , '||', IFNULL(TRIM(AWAHR::text), '^^') 
            , '||', IFNULL(TRIM(ERDAT::text), '^^') 
            , '||', IFNULL(TRIM(ERNAM::text), '^^') 
            , '||', IFNULL(TRIM(ERZET::text), '^^') 
            , '||', IFNULL(TRIM(TAXM1::text), '^^') 
            , '||', IFNULL(TRIM(TAXM2::text), '^^') 
            , '||', IFNULL(TRIM(TAXM3::text), '^^') 
            , '||', IFNULL(TRIM(TAXM4::text), '^^') 
            , '||', IFNULL(TRIM(TAXM5::text), '^^') 
            , '||', IFNULL(TRIM(TAXM6::text), '^^') 
            , '||', IFNULL(TRIM(TAXM7::text), '^^') 
            , '||', IFNULL(TRIM(TAXM8::text), '^^') 
            , '||', IFNULL(TRIM(TAXM9::text), '^^') 
            , '||', IFNULL(TRIM(VBEAF::text), '^^') 
            , '||', IFNULL(TRIM(VBEAV::text), '^^') 
            , '||', IFNULL(TRIM(VGREF::text), '^^') 
            , '||', IFNULL(TRIM(NETPR::text), '^^') 
            , '||', IFNULL(TRIM(KPEIN::text), '^^') 
            , '||', IFNULL(TRIM(KMEIN::text), '^^') 
            , '||', IFNULL(TRIM(SHKZG::text), '^^') 
            , '||', IFNULL(TRIM(SKTOF::text), '^^') 
            , '||', IFNULL(TRIM(MTVFP::text), '^^') 
            , '||', IFNULL(TRIM(SUMBD::text), '^^') 
            , '||', IFNULL(TRIM(KONDM::text), '^^') 
            , '||', IFNULL(TRIM(KTGRM::text), '^^') 
            , '||', IFNULL(TRIM(BONUS::text), '^^') 
            , '||', IFNULL(TRIM(PROVG::text), '^^') 
            , '||', IFNULL(TRIM(EANNR::text), '^^') 
            , '||', IFNULL(TRIM(PRSOK::text), '^^') 
            , '||', IFNULL(TRIM(BWTAR::text), '^^') 
            , '||', IFNULL(TRIM(BWTEX::text), '^^') 
            , '||', IFNULL(TRIM(XCHPF::text), '^^') 
            , '||', IFNULL(TRIM(XCHAR::text), '^^') 
            , '||', IFNULL(TRIM(LFMNG::text), '^^') 
            , '||', IFNULL(TRIM(STAFO::text), '^^') 
            , '||', IFNULL(TRIM(WAVWR::text), '^^') 
            , '||', IFNULL(TRIM(KZWI1::text), '^^') 
            , '||', IFNULL(TRIM(KZWI2::text), '^^') 
            , '||', IFNULL(TRIM(KZWI3::text), '^^') 
            , '||', IFNULL(TRIM(KZWI4::text), '^^') 
            , '||', IFNULL(TRIM(KZWI5::text), '^^') 
            , '||', IFNULL(TRIM(KZWI6::text), '^^') 
            , '||', IFNULL(TRIM(STCUR::text), '^^') 
            , '||', IFNULL(TRIM(AEDAT::text), '^^') 
            , '||', IFNULL(TRIM(EAN11::text), '^^') 
            , '||', IFNULL(TRIM(FIXMG::text), '^^') 
            , '||', IFNULL(TRIM(PRCTR::text), '^^') 
            , '||', IFNULL(TRIM(MVGR1::text), '^^') 
            , '||', IFNULL(TRIM(MVGR2::text), '^^') 
            , '||', IFNULL(TRIM(MVGR3::text), '^^') 
            , '||', IFNULL(TRIM(MVGR4::text), '^^') 
            , '||', IFNULL(TRIM(MVGR5::text), '^^') 
            , '||', IFNULL(TRIM(KMPMG::text), '^^') 
            , '||', IFNULL(TRIM(SUGRD::text), '^^') 
            , '||', IFNULL(TRIM(SOBKZ::text), '^^') 
            , '||', IFNULL(TRIM(VPZUO::text), '^^') 
            , '||', IFNULL(TRIM(PAOBJNR::text), '^^') 
            , '||', IFNULL(TRIM(PS_PSP_PNR::text), '^^') 
            , '||', IFNULL(TRIM(AUFNR::text), '^^') 
            , '||', IFNULL(TRIM(VPMAT::text), '^^') 
            , '||', IFNULL(TRIM(VPWRK::text), '^^') 
            , '||', IFNULL(TRIM(PRBME::text), '^^') 
            , '||', IFNULL(TRIM(UMREF::text), '^^') 
            , '||', IFNULL(TRIM(KNTTP::text), '^^') 
            , '||', IFNULL(TRIM(KZVBR::text), '^^') 
            , '||', IFNULL(TRIM(SERNR::text), '^^') 
            , '||', IFNULL(TRIM(OBJNR::text), '^^') 
            , '||', IFNULL(TRIM(ABGRS::text), '^^') 
            , '||', IFNULL(TRIM(BEDAE::text), '^^') 
            , '||', IFNULL(TRIM(CMPRE::text), '^^') 
            , '||', IFNULL(TRIM(CMTFG::text), '^^') 
            , '||', IFNULL(TRIM(CMPNT::text), '^^') 
            , '||', IFNULL(TRIM(CMKUA::text), '^^') 
            , '||', IFNULL(TRIM(CUOBJ::text), '^^') 
            , '||', IFNULL(TRIM(CUOBJ_CH::text), '^^') 
            , '||', IFNULL(TRIM(CEPOK::text), '^^') 
            , '||', IFNULL(TRIM(KOUPD::text), '^^') 
            , '||', IFNULL(TRIM(SERAIL::text), '^^') 
            , '||', IFNULL(TRIM(ANZSN::text), '^^') 
            , '||', IFNULL(TRIM(NACHL::text), '^^') 
            , '||', IFNULL(TRIM(MAGRV::text), '^^') 
            , '||', IFNULL(TRIM(MPROK::text), '^^') 
            , '||', IFNULL(TRIM(VGTYP::text), '^^') 
            , '||', IFNULL(TRIM(PROSA::text), '^^') 
            , '||', IFNULL(TRIM(UEPVW::text), '^^') 
            , '||', IFNULL(TRIM(KALNR::text), '^^') 
            , '||', IFNULL(TRIM(KLVAR::text), '^^') 
            , '||', IFNULL(TRIM(SPOSN::text), '^^') 
            , '||', IFNULL(TRIM(KOWRR::text), '^^') 
            , '||', IFNULL(TRIM(STADAT::text), '^^') 
            , '||', IFNULL(TRIM(EXART::text), '^^') 
            , '||', IFNULL(TRIM(PREFE::text), '^^') 
            , '||', IFNULL(TRIM(KNUMH::text), '^^') 
            , '||', IFNULL(TRIM(CLINT::text), '^^') 
            , '||', IFNULL(TRIM(CHMVS::text), '^^') 
            , '||', IFNULL(TRIM(STLTY::text), '^^') 
            , '||', IFNULL(TRIM(STLKN::text), '^^') 
            , '||', IFNULL(TRIM(STPOZ::text), '^^') 
            , '||', IFNULL(TRIM(STMAN::text), '^^') 
            , '||', IFNULL(TRIM(ZSCHL_K::text), '^^') 
            , '||', IFNULL(TRIM(KALSM_K::text), '^^') 
            , '||', IFNULL(TRIM(KALVAR::text), '^^') 
            , '||', IFNULL(TRIM(KOSCH::text), '^^') 
            , '||', IFNULL(TRIM(UPMAT::text), '^^') 
            , '||', IFNULL(TRIM(UKONM::text), '^^') 
            , '||', IFNULL(TRIM(MFRGR::text), '^^') 
            , '||', IFNULL(TRIM(PLAVO::text), '^^') 
            , '||', IFNULL(TRIM(KANNR::text), '^^') 
            , '||', IFNULL(TRIM(CMPRE_FLT::text), '^^') 
            , '||', IFNULL(TRIM(ABFOR::text), '^^') 
            , '||', IFNULL(TRIM(ABGES::text), '^^') 
            , '||', IFNULL(TRIM(J_1BCFOP::text), '^^') 
            , '||', IFNULL(TRIM(J_1BTAXLW1::text), '^^') 
            , '||', IFNULL(TRIM(J_1BTAXLW2::text), '^^') 
            , '||', IFNULL(TRIM(J_1BTXSDC::text), '^^') 
            , '||', IFNULL(TRIM(WKTNR::text), '^^') 
            , '||', IFNULL(TRIM(WKTPS::text), '^^') 
            , '||', IFNULL(TRIM(SKOPF::text), '^^') 
            , '||', IFNULL(TRIM(KZBWS::text), '^^') 
            , '||', IFNULL(TRIM(WGRU1::text), '^^') 
            , '||', IFNULL(TRIM(WGRU2::text), '^^') 
            , '||', IFNULL(TRIM(KNUMA_PI::text), '^^') 
            , '||', IFNULL(TRIM(KNUMA_AG::text), '^^') 
            , '||', IFNULL(TRIM(KZFME::text), '^^') 
            , '||', IFNULL(TRIM(LSTANR::text), '^^') 
            , '||', IFNULL(TRIM(TECHS::text), '^^') 
            , '||', IFNULL(TRIM(MWSBP::text), '^^') 
            , '||', IFNULL(TRIM(BERID::text), '^^') 
            , '||', IFNULL(TRIM(PCTRF::text), '^^') 
            , '||', IFNULL(TRIM(LOGSYS_EXT::text), '^^') 
            , '||', IFNULL(TRIM(J_1BTAXLW3::text), '^^') 
            , '||', IFNULL(TRIM(J_1BTAXLW4::text), '^^') 
            , '||', IFNULL(TRIM(J_1BTAXLW5::text), '^^') 
            , '||', IFNULL(TRIM(STOCKLOC::text), '^^') 
            , '||', IFNULL(TRIM(SLOCTYPE::text), '^^') 
            , '||', IFNULL(TRIM(MSR_RET_REASON::text), '^^') 
            , '||', IFNULL(TRIM(MSR_REFUND_CODE::text), '^^') 
            , '||', IFNULL(TRIM(MSR_APPROV_BLOCK::text), '^^') 
            , '||', IFNULL(TRIM(NRAB_KNUMH::text), '^^') 
            , '||', IFNULL(TRIM(TRMRISK_RELEVANT::text), '^^') 
            , '||', IFNULL(TRIM(SGT_RCAT::text), '^^') 
            , '||', IFNULL(TRIM(HANDOVERLOC::text), '^^') 
            , '||', IFNULL(TRIM(HANDOVERDATE::text), '^^') 
            , '||', IFNULL(TRIM(HANDOVERTIME::text), '^^') 
            , '||', IFNULL(TRIM(TC_AUT_DET::text), '^^') 
            , '||', IFNULL(TRIM(MANUAL_TC_REASON::text), '^^') 
            , '||', IFNULL(TRIM(FISCAL_INCENTIVE::text), '^^') 
            , '||', IFNULL(TRIM(TAX_SUBJECT_ST::text), '^^') 
            , '||', IFNULL(TRIM(FISCAL_INCENTIVE_ID::text), '^^') 
            , '||', IFNULL(TRIM(SPCSTO::text), '^^') 
            , '||', IFNULL(TRIM(_DATAAGING::text), '^^') 
            , '||', IFNULL(TRIM(REVACC_REFID::text), '^^') 
            , '||', IFNULL(TRIM(REVACC_REFTYPE::text), '^^') 
            , '||', IFNULL(TRIM(SRFUND::text), '^^') 
            , '||', IFNULL(TRIM(AUFPL_OLC::text), '^^') 
            , '||', IFNULL(TRIM(APLZL_OLC::text), '^^') 
            , '||', IFNULL(TRIM(FERC_IND::text), '^^') 
            , '||', IFNULL(TRIM(FSH_SEASON_YEAR::text), '^^') 
            , '||', IFNULL(TRIM(FSH_SEASON::text), '^^') 
            , '||', IFNULL(TRIM(FSH_COLLECTION::text), '^^') 
            , '||', IFNULL(TRIM(FSH_THEME::text), '^^') 
            , '||', IFNULL(TRIM(FSH_CRSD::text), '^^') 
            , '||', IFNULL(TRIM(FSH_SEAREF::text), '^^') 
            , '||', IFNULL(TRIM(FSH_CANDATE::text), '^^') 
            , '||', IFNULL(TRIM(FSH_PSM_PFM_SPLIT::text), '^^') 
            , '||', IFNULL(TRIM(FSH_VAS_REL::text), '^^') 
            , '||', IFNULL(TRIM(FSH_VAS_PRNT_ID::text), '^^') 
            , '||', IFNULL(TRIM(FSH_TRANSACTION::text), '^^') 
            , '||', IFNULL(TRIM(FSH_ITEM_GROUP::text), '^^') 
            , '||', IFNULL(TRIM(FSH_ITEM::text), '^^') 
            , '||', IFNULL(TRIM(FSH_VASREF::text), '^^') 
            , '||', IFNULL(TRIM(FSH_GRID_COND_REC::text), '^^') 
            , '||', IFNULL(TRIM(FSH_PQR_UEPOS::text), '^^') 
            , '||', IFNULL(TRIM(KOSTL::text), '^^') 
            , '||', IFNULL(TRIM(FONDS::text), '^^') 
            , '||', IFNULL(TRIM(FISTL::text), '^^') 
            , '||', IFNULL(TRIM(FKBER::text), '^^') 
            , '||', IFNULL(TRIM(GRANT_NBR::text), '^^') 
            , '||', IFNULL(TRIM(BUDGET_PD::text), '^^') 
            , '||', IFNULL(TRIM(IUID_RELEVANT::text), '^^') 
            , '||', IFNULL(TRIM(MILL_SE_GPOSN::text), '^^') 
            , '||', IFNULL(TRIM(PRS_OBJNR::text), '^^') 
            , '||', IFNULL(TRIM(PRS_SD_SPSNR::text), '^^') 
            , '||', IFNULL(TRIM(PRS_WORK_PERIOD::text), '^^') 
            , '||', IFNULL(TRIM(TAS::text), '^^') 
            , '||', IFNULL(TRIM(BETC::text), '^^') 
            , '||', IFNULL(TRIM(MOD_ALLOW::text), '^^') 
            , '||', IFNULL(TRIM(CANCEL_ALLOW::text), '^^') 
            , '||', IFNULL(TRIM(PAY_METHOD::text), '^^') 
            , '||', IFNULL(TRIM(BPN::text), '^^') 
            , '||', IFNULL(TRIM(REP_FREQ::text), '^^') 
            , '||', IFNULL(TRIM(FMFGUS_KEY::text), '^^') 
            , '||', IFNULL(TRIM(PARGB::text), '^^') 
            , '||', IFNULL(TRIM(AUFPL_OAA::text), '^^') 
            , '||', IFNULL(TRIM(APLZL_OAA::text), '^^') 
            , '||', IFNULL(TRIM(WRF_CHARSTC1::text), '^^') 
            , '||', IFNULL(TRIM(WRF_CHARSTC2::text), '^^') 
            , '||', IFNULL(TRIM(WRF_CHARSTC3::text), '^^') 
            , '||', IFNULL(TRIM(ARSNUM::text), '^^') 
            , '||', IFNULL(TRIM(ARSPOS::text), '^^') 
            , '||', IFNULL(TRIM(WTYSC_CLMITEM::text), '^^') 
            , '||', IFNULL(TRIM(ZZKNUMA::text), '^^') 
            , '||', IFNULL(TRIM(ZZKZWI7::text), '^^') 
            , '||', IFNULL(TRIM(ZZKZWI8::text), '^^') 
            , '||', IFNULL(TRIM(ZZKZWI9::text), '^^') 
            , '||', IFNULL(TRIM(ZZKZWI10::text), '^^') 
            , '||', IFNULL(TRIM(ZZKZWI11::text), '^^') 
            , '||', IFNULL(TRIM(ZZKZWI12::text), '^^') 
            , '||', IFNULL(TRIM(ZZKZWI13::text), '^^') 
            , '||', IFNULL(TRIM(ZZKZWI14::text), '^^') 
            , '||', IFNULL(TRIM(ZZKZWI15::text), '^^') 
            , '||', IFNULL(TRIM(ZZKZWI16::text), '^^') 
            , '||', IFNULL(TRIM(ZZKZWI17::text), '^^') 
            , '||', IFNULL(TRIM(ZZAUFNR::text), '^^') 
            , '||', IFNULL(TRIM(ZZAPRVGRP::text), '^^') 
            , '||', IFNULL(TRIM(ZZLOCUSED::text), '^^') 
            , '||', IFNULL(TRIM(ZZRECMAN::text), '^^') 
            , '||', IFNULL(TRIM(ZZLPSBSRC::text), '^^') 
            , '||', IFNULL(TRIM(ZZLPSFRID::text), '^^') 
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
            , '||', IFNULL(TRIM(PAYER_PARVW::text), '^^') 
            , '||', IFNULL(TRIM(BILLTO_PARVW::text), '^^') 
            , '||', IFNULL(TRIM(SHIPTO_PARVW::text), '^^')
            , '||', IFNULL(TRIM(INSURANCE_PARVW::text), '^^') 
            , '||', IFNULL(TRIM(PAYER_KUNNR::text), '^^') 
            , '||', IFNULL(TRIM(BILLTO_KUNNR::text), '^^') 
            , '||', IFNULL(TRIM(SHIPTO_KUNNR::text), '^^') 
            , '||', IFNULL(TRIM(SOLDTO_KUNNR::text), '^^') 
            , '||', IFNULL(TRIM(INSURANCE_KUNNR::text), '^^') 
            , '||', IFNULL(TRIM(VKORG::text), '^^') 
            , '||', IFNULL(TRIM(VTWEG::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT