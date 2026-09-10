---- SRC LAYER ----
WITH
SRC_polsap         as ( SELECT "/BEV1/NEDEPFREE", "/BEV1/NEGEN_ITEM", "/BEV1/NESTRUCCAT", ABDAT, ABELN, ABELP, ABFTZ, ABMNG, ABSKZ, ABUEB, ADRN2, ADRNR, ADVCODE, AEDAT, AFNAM, AGDAT, AGMEM, AKTNR, ANFNR, ANFPS, ANZPU, ANZSN, APOMS, ARSNR, ARSPS, ATTYP, AUREL, BANFN, BEDNR, BERID, BLK_REASON_ID, BLK_REASON_TXT, BNFPO, BONBA, BONUS, BPRME, BPUMN, BPUMZ, BRGEW, BRTWR, BSGRU, BSTAE, BSTYP, BUDGET_PD, BUKRS, BWTAR, BWTTY, CCOMP, CHG_FPLNR, CHG_SRV, CMPL_DLV_ITM, CNFM_QTY, CONS_ORDER, CQU_SAR, CUOBJ, DIFF_INVOICE, DISUB_KUNNR, DISUB_OWNER, DISUB_POSNR, DISUB_PSPNR, DISUB_SOBKZ, DISUB_VBELN, DPAMT, DPDAT, DPPCT, DPTYP, DRDAT, DRUHR, DRUNR, EAN11, EBELN, EBELP, EBON2, EBON3, EBONF, EFFWR, EGLKZ, EHTYP, EILDT, EKKOL, ELIKZ, EMATN, EMLIF, EMNFR, EMPST, EREKZ, ETDRK, ETFZ1, ETFZ2, EVERS, EXCPE, EXLIN, EXSNR, EXT_RFX_ITEM, EXT_RFX_NUMBER, EXT_RFX_SYSTEM, FABKZ, FFZHI, FIPOS, FISCAL_INCENTIVE, FISCAL_INCENTIVE_ID, FISTL, FIXMG, FKBER, FLS_RSTO, FMFGUS_KEY, FPLNR, FSH_ATP_DATE, FSH_COLLECTION, FSH_GRID_COND_REC, FSH_ITEM, FSH_ITEM_GROUP, FSH_PQR_UEPOS, FSH_PSM_PFM_SPLIT, FSH_SEASON, FSH_SEASON_YEAR, FSH_SS, FSH_THEME, FSH_TRANSACTION, FSH_VAS_PRNT_ID, FSH_VAS_REL, GEBER, GEWEI, GLCHANGETIME, GLDELFLAG, GLREQUEST, GLSOURCESYSTEM, GNETWR, GRANT_NBR, HANDOVERLOC, IDNLF, INCO1, INCO2, INCO2_L, INCO3_L, INFNR, INSMK, INSNC, IPRKZ, ITCONS, IUID_RELEVANT, J_1AIDATEP, J_1AINDXP, J_1BINDUST, J_1BMATORG, J_1BMATUSE, J_1BNBM, J_1BOWNPRO, KANBA, KBLNR, KBLPOS, KNDBT, KNTTP, KOLIF, KONNR, KO_GSBER, KO_PARGB, KO_PPRCTR, KO_PRCTR, KTMNG, KTPNR, KUNNR, KZABS, KZBWS, KZFME, KZKFG, KZSTU, KZTLF, KZVBR, KZWI1, KZWI2, KZWI3, KZWI4, KZWI5, KZWI6, LABNR, LBLKZ, LEBRE, LEWED, LFRET, LGORT, LMEIN, LOEKZ, LTSNR, MAHN1, MAHN2, MAHN3, MAHNZ, MANDT, MANUAL_TC_REASON, MATKL, MATNR, MEINS, MENGE, MEPRF, MFRGR, MFRNR, MFRPN, MFZHI, MHDRZ, MLMAA, MPROF, MRPIND, MTART, MWSKZ, NAVNW, NETPR, NETWR, NFABD, NLABD, NOTKZ, NOVET, NRFHG, NTGEW, PACKNO, PEINH, PLIFZ, POL_ID, PRDAT, PRIO_REQ, PRIO_URG, PRSDR, PSA_DELETE_IND, PSA_LOAD_DTS, PSTYP, PUNEI, PUT_BACK, RDPRF, REASON_CODE, REFSITE, REF_ITEM, REPOS, RESLO, RETPC, RETPO, REVLV, SAISJ, SAISO, SATNR, SCHPR, SERNP, SERRU, SF_TXJCD, SGT_RCAT, SGT_SCAT, SIKGR, SKTOF, SOBKZ, SOURCE_ID, SOURCE_KEY, SPE_ABGRU, SPE_CHNG_SYS, SPE_CQ_CTRLTYPE, SPE_CQ_NOCQ, SPE_CRM_FKREL, SPE_CRM_REF_ITEM, SPE_CRM_REF_SO, SPE_CRM_SO, SPE_CRM_SO_ITEM, SPE_EWM_DTC, SPE_INSMK_SRC, SPINF, SRM_CONTRACT_ID, SRM_CONTRACT_ITM, SRV_BAS_COM, SSQSS, STAFO, STAPO, STATU, STATUS, TAX_SUBJECT_ST, TC_AUT_DET, TECHS, TRMRISK_RELEVANT, TWRKZ, TXJCD, TXZ01, TZONRC, UEBPO, UEBTK, UEBTO, UMREN, UMREZ, UMSOK, UNTTO, UPTYP, UPVOR, USEQU, VOLEH, VOLUM, VORAB, VRTKZ, VSART, WABWE, WEBAZ, WEBRE, WEORA, WEPOS, WERKS, WEUNB, WRF_CHARSTC1, WRF_CHARSTC2, WRF_CHARSTC3, XCONDITIONS, XERSY, XOBLR, ZACTKGWEIGHT, ZDIMKGWEIGHT, ZGTYP, ZWEIGHTUSED, ZWERT, ZZ3RDPO, ZZAEDAT, ZZAIR_FREIGHT, ZZAIR_FRGHT_BU, ZZASNIND_SENT, ZZCAUSE, ZZDRAW_REC, ZZFREIGHT, ZZFRTCD, ZZFRTCST, ZZFRZ_SHPDT, ZZHOT, ZZMPLFZ, ZZNO_EMAIL, ZZPRF_REC, ZZPROJ_NO, ZZREASON_CD, ZZREGION, ZZSHPC, ZZSHPD, ZZSUBREASON, ZZTRANSIT, ZZ_O8_BUFFER, ZZ_O8_COLOR, ZZ_O8_REF FROM {{ source('sap_ecc_prd', 'z_ekpo') }} as SRC  ),
SRC_posap          as ( SELECT BEDAT, EBELN, EKORG, LIFNR FROM {{ source('sap_ecc_prd', 'z_ekko') }} as SRC 
                        qualify 1 = (row_number() over(partition by ebeln order by psa_load_dts desc)) ),
SRC_a              as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_polsap         as ( SELECT * FROM sap_ecc_prd.z_ekpo )
SRC_posap          as ( SELECT * FROM sap_ecc_prd.z_ekko )
SRC_a              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_polsap as (
    SELECT
        CONCAT_WS('||', COALESCE(EBELN, ''), COALESCE(EBELP, ''))    as                                         PO_ITEM_BK
      , EBELN                                                        as                                       PO_HEADER_BK
      , MATNR                                                        as                                            ITEM_BK
      , BUKRS                                                        as                                    LEGAL_ENTITY_BK
      , EBELN
      , EBELP
      , MATNR
      , INFNR
      , GLREQUEST
      , GLSOURCESYSTEM
      , LOEKZ
      , STATU
      , AEDAT
      , TXZ01
      , EMATN
      , MANDT
      , BUKRS
      , WERKS
      , LGORT
      , BEDNR
      , MATKL
      , IDNLF
      , KTMNG
      , MENGE
      , MEINS
      , BPRME
      , BPUMZ
      , BPUMN
      , UMREZ
      , UMREN
      , NETPR
      , PEINH
      , NETWR
      , BRTWR
      , AGDAT
      , WEBAZ
      , MWSKZ
      , BONUS
      , INSMK
      , SPINF
      , PRSDR
      , SCHPR
      , MAHNZ
      , MAHN1
      , MAHN2
      , MAHN3
      , UEBTO
      , UEBTK
      , UNTTO
      , BWTAR
      , BWTTY
      , ABSKZ
      , AGMEM
      , ELIKZ
      , EREKZ
      , PSTYP
      , KNTTP
      , KZVBR
      , VRTKZ
      , TWRKZ
      , WEPOS
      , WEUNB
      , REPOS
      , WEBRE
      , KZABS
      , LABNR
      , KONNR
      , KTPNR
      , ABDAT
      , ABFTZ
      , ETFZ1
      , ETFZ2
      , KZSTU
      , NOTKZ
      , LMEIN
      , EVERS
      , ZWERT
      , NAVNW
      , ABMNG
      , PRDAT
      , BSTYP
      , EFFWR
      , XOBLR
      , KUNNR
      , ADRNR
      , EKKOL
      , SKTOF
      , STAFO
      , PLIFZ
      , NTGEW
      , GEWEI
      , TXJCD
      , ETDRK
      , SOBKZ
      , ARSNR
      , ARSPS
      , INSNC
      , SSQSS
      , ZGTYP
      , EAN11
      , BSTAE
      , REVLV
      , GEBER
      , FISTL
      , FIPOS
      , KO_GSBER
      , KO_PARGB
      , KO_PRCTR
      , KO_PPRCTR
      , MEPRF
      , BRGEW
      , VOLUM
      , VOLEH
      , INCO1
      , INCO2
      , VORAB
      , KOLIF
      , LTSNR
      , PACKNO
      , FPLNR
      , GNETWR
      , STAPO
      , UEBPO
      , LEWED
      , EMLIF
      , LBLKZ
      , SATNR
      , ATTYP
      , VSART
      , HANDOVERLOC
      , KANBA
      , ADRN2
      , CUOBJ
      , XERSY
      , EILDT
      , DRDAT
      , DRUHR
      , DRUNR
      , AKTNR
      , ABELN
      , ABELP
      , ANZPU
      , PUNEI
      , SAISO
      , SAISJ
      , EBON2
      , EBON3
      , EBONF
      , MLMAA
      , MHDRZ
      , ANFNR
      , ANFPS
      , KZKFG
      , USEQU
      , UMSOK
      , BANFN
      , BNFPO
      , MTART
      , UPTYP
      , UPVOR
      , KZWI1
      , KZWI2
      , KZWI3
      , KZWI4
      , KZWI5
      , KZWI6
      , SIKGR
      , MFZHI
      , FFZHI
      , RETPO
      , AUREL
      , BSGRU
      , LFRET
      , MFRGR
      , NRFHG
      , J_1BNBM
      , J_1BMATUSE
      , J_1BMATORG
      , J_1BOWNPRO
      , J_1BINDUST
      , ABUEB
      , NLABD
      , NFABD
      , KZBWS
      , BONBA
      , FABKZ
      , J_1AINDXP
      , J_1AIDATEP
      , MPROF
      , EGLKZ
      , KZTLF
      , KZFME
      , RDPRF
      , TECHS
      , CHG_SRV
      , CHG_FPLNR
      , MFRPN
      , MFRNR
      , EMNFR
      , NOVET
      , AFNAM
      , TZONRC
      , IPRKZ
      , LEBRE
      , BERID
      , XCONDITIONS
      , APOMS
      , CCOMP
      , GRANT_NBR
      , FKBER
      , STATUS
      , RESLO
      , KBLNR
      , KBLPOS
      , WEORA
      , SRV_BAS_COM
      , PRIO_URG
      , PRIO_REQ
      , EMPST
      , DIFF_INVOICE
      , TRMRISK_RELEVANT
      , SPE_ABGRU
      , SPE_CRM_SO
      , SPE_CRM_SO_ITEM
      , SPE_CRM_REF_SO
      , SPE_CRM_REF_ITEM
      , SPE_CRM_FKREL
      , SPE_CHNG_SYS
      , SPE_INSMK_SRC
      , SPE_CQ_CTRLTYPE
      , SPE_CQ_NOCQ
      , REASON_CODE
      , CQU_SAR
      , ANZSN
      , SPE_EWM_DTC
      , EXLIN
      , EXSNR
      , EHTYP
      , RETPC
      , DPTYP
      , DPPCT
      , DPAMT
      , DPDAT
      , FLS_RSTO
      , EXT_RFX_NUMBER
      , EXT_RFX_ITEM
      , EXT_RFX_SYSTEM
      , SRM_CONTRACT_ID
      , SRM_CONTRACT_ITM
      , BLK_REASON_ID
      , BLK_REASON_TXT
      , ITCONS
      , FIXMG
      , WABWE
      , CMPL_DLV_ITM
      , INCO2_L
      , INCO3_L
      , TC_AUT_DET
      , MANUAL_TC_REASON
      , FISCAL_INCENTIVE
      , TAX_SUBJECT_ST
      , FISCAL_INCENTIVE_ID
      , SF_TXJCD
      , "/BEV1/NEGEN_ITEM"                                           as                                   _BEV1_NEGEN_ITEM
      , "/BEV1/NEDEPFREE"                                            as                                    _BEV1_NEDEPFREE
      , "/BEV1/NESTRUCCAT"                                           as                                   _BEV1_NESTRUCCAT
      , ADVCODE
      , BUDGET_PD
      , EXCPE
      , FMFGUS_KEY
      , IUID_RELEVANT
      , MRPIND
      , SGT_SCAT
      , SGT_RCAT
      , WRF_CHARSTC1
      , WRF_CHARSTC2
      , WRF_CHARSTC3
      , ZZREGION
      , ZZSHPC
      , ZZSHPD
      , ZZFREIGHT
      , ZZNO_EMAIL
      , ZZFRZ_SHPDT
      , ZZPROJ_NO
      , ZZ3RDPO
      , ZZFRTCD
      , ZZFRTCST
      , ZZTRANSIT
      , ZZCAUSE
      , ZZAIR_FREIGHT
      , ZZAIR_FRGHT_BU
      , ZZMPLFZ
      , ZZ_O8_REF
      , ZZ_O8_COLOR
      , ZZ_O8_BUFFER
      , REFSITE
      , SERRU
      , SERNP
      , DISUB_SOBKZ
      , DISUB_PSPNR
      , DISUB_KUNNR
      , DISUB_VBELN
      , DISUB_POSNR
      , DISUB_OWNER
      , FSH_SEASON_YEAR
      , FSH_SEASON
      , FSH_COLLECTION
      , FSH_THEME
      , FSH_ATP_DATE
      , FSH_VAS_REL
      , FSH_VAS_PRNT_ID
      , FSH_TRANSACTION
      , FSH_ITEM_GROUP
      , FSH_ITEM
      , FSH_SS
      , FSH_GRID_COND_REC
      , FSH_PSM_PFM_SPLIT
      , CNFM_QTY
      , FSH_PQR_UEPOS
      , REF_ITEM
      , SOURCE_ID
      , SOURCE_KEY
      , PUT_BACK
      , POL_ID
      , CONS_ORDER
      , ZZREASON_CD
      , ZZPRF_REC
      , ZZDRAW_REC
      , ZZASNIND_SENT
      , ZZSUBREASON
      , ZZAEDAT
      , ZZHOT
      , KNDBT
      , ZACTKGWEIGHT
      , ZDIMKGWEIGHT
      , ZWEIGHTUSED
      , GLDELFLAG
      , GLCHANGETIME
      , PSA_LOAD_DTS
      , PSA_DELETE_IND
      , CONVERT_TIMEZONE('UTC', PSA_LOAD_DTS)                        as                                           LOAD_DTS
    FROM SRC_polsap
)

, LOGIC_posap as (
    SELECT
        LIFNR                                                        as                                        SUPPLIER_BK
      , LIFNR
      , BEDAT
      , EKORG
      , EBELN                                                        as                                        POSAP_EBELN
    FROM SRC_posap
)

, LOGIC_a as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_a
)
---- RENAME LAYER ----

, RENAME_polsap as (
    SELECT
        PO_ITEM_BK
      , PO_HEADER_BK
      , ITEM_BK
      , LEGAL_ENTITY_BK
      , EBELN
      , EBELP
      , MATNR
      , INFNR
      , GLREQUEST
      , GLSOURCESYSTEM
      , LOEKZ
      , STATU
      , AEDAT
      , TXZ01
      , EMATN
      , MANDT
      , BUKRS
      , WERKS
      , LGORT
      , BEDNR
      , MATKL
      , IDNLF
      , KTMNG
      , MENGE
      , MEINS
      , BPRME
      , BPUMZ
      , BPUMN
      , UMREZ
      , UMREN
      , NETPR
      , PEINH
      , NETWR
      , BRTWR
      , AGDAT
      , WEBAZ
      , MWSKZ
      , BONUS
      , INSMK
      , SPINF
      , PRSDR
      , SCHPR
      , MAHNZ
      , MAHN1
      , MAHN2
      , MAHN3
      , UEBTO
      , UEBTK
      , UNTTO
      , BWTAR
      , BWTTY
      , ABSKZ
      , AGMEM
      , ELIKZ
      , EREKZ
      , PSTYP
      , KNTTP
      , KZVBR
      , VRTKZ
      , TWRKZ
      , WEPOS
      , WEUNB
      , REPOS
      , WEBRE
      , KZABS
      , LABNR
      , KONNR
      , KTPNR
      , ABDAT
      , ABFTZ
      , ETFZ1
      , ETFZ2
      , KZSTU
      , NOTKZ
      , LMEIN
      , EVERS
      , ZWERT
      , NAVNW
      , ABMNG
      , PRDAT
      , BSTYP
      , EFFWR
      , XOBLR
      , KUNNR
      , ADRNR
      , EKKOL
      , SKTOF
      , STAFO
      , PLIFZ
      , NTGEW
      , GEWEI
      , TXJCD
      , ETDRK
      , SOBKZ
      , ARSNR
      , ARSPS
      , INSNC
      , SSQSS
      , ZGTYP
      , EAN11
      , BSTAE
      , REVLV
      , GEBER
      , FISTL
      , FIPOS
      , KO_GSBER
      , KO_PARGB
      , KO_PRCTR
      , KO_PPRCTR
      , MEPRF
      , BRGEW
      , VOLUM
      , VOLEH
      , INCO1
      , INCO2
      , VORAB
      , KOLIF
      , LTSNR
      , PACKNO
      , FPLNR
      , GNETWR
      , STAPO
      , UEBPO
      , LEWED
      , EMLIF
      , LBLKZ
      , SATNR
      , ATTYP
      , VSART
      , HANDOVERLOC
      , KANBA
      , ADRN2
      , CUOBJ
      , XERSY
      , EILDT
      , DRDAT
      , DRUHR
      , DRUNR
      , AKTNR
      , ABELN
      , ABELP
      , ANZPU
      , PUNEI
      , SAISO
      , SAISJ
      , EBON2
      , EBON3
      , EBONF
      , MLMAA
      , MHDRZ
      , ANFNR
      , ANFPS
      , KZKFG
      , USEQU
      , UMSOK
      , BANFN
      , BNFPO
      , MTART
      , UPTYP
      , UPVOR
      , KZWI1
      , KZWI2
      , KZWI3
      , KZWI4
      , KZWI5
      , KZWI6
      , SIKGR
      , MFZHI
      , FFZHI
      , RETPO
      , AUREL
      , BSGRU
      , LFRET
      , MFRGR
      , NRFHG
      , J_1BNBM
      , J_1BMATUSE
      , J_1BMATORG
      , J_1BOWNPRO
      , J_1BINDUST
      , ABUEB
      , NLABD
      , NFABD
      , KZBWS
      , BONBA
      , FABKZ
      , J_1AINDXP
      , J_1AIDATEP
      , MPROF
      , EGLKZ
      , KZTLF
      , KZFME
      , RDPRF
      , TECHS
      , CHG_SRV
      , CHG_FPLNR
      , MFRPN
      , MFRNR
      , EMNFR
      , NOVET
      , AFNAM
      , TZONRC
      , IPRKZ
      , LEBRE
      , BERID
      , XCONDITIONS
      , APOMS
      , CCOMP
      , GRANT_NBR
      , FKBER
      , STATUS
      , RESLO
      , KBLNR
      , KBLPOS
      , WEORA
      , SRV_BAS_COM
      , PRIO_URG
      , PRIO_REQ
      , EMPST
      , DIFF_INVOICE
      , TRMRISK_RELEVANT
      , SPE_ABGRU
      , SPE_CRM_SO
      , SPE_CRM_SO_ITEM
      , SPE_CRM_REF_SO
      , SPE_CRM_REF_ITEM
      , SPE_CRM_FKREL
      , SPE_CHNG_SYS
      , SPE_INSMK_SRC
      , SPE_CQ_CTRLTYPE
      , SPE_CQ_NOCQ
      , REASON_CODE
      , CQU_SAR
      , ANZSN
      , SPE_EWM_DTC
      , EXLIN
      , EXSNR
      , EHTYP
      , RETPC
      , DPTYP
      , DPPCT
      , DPAMT
      , DPDAT
      , FLS_RSTO
      , EXT_RFX_NUMBER
      , EXT_RFX_ITEM
      , EXT_RFX_SYSTEM
      , SRM_CONTRACT_ID
      , SRM_CONTRACT_ITM
      , BLK_REASON_ID
      , BLK_REASON_TXT
      , ITCONS
      , FIXMG
      , WABWE
      , CMPL_DLV_ITM
      , INCO2_L
      , INCO3_L
      , TC_AUT_DET
      , MANUAL_TC_REASON
      , FISCAL_INCENTIVE
      , TAX_SUBJECT_ST
      , FISCAL_INCENTIVE_ID
      , SF_TXJCD
      , _BEV1_NEGEN_ITEM
      , _BEV1_NEDEPFREE
      , _BEV1_NESTRUCCAT
      , ADVCODE
      , BUDGET_PD
      , EXCPE
      , FMFGUS_KEY
      , IUID_RELEVANT
      , MRPIND
      , SGT_SCAT
      , SGT_RCAT
      , WRF_CHARSTC1
      , WRF_CHARSTC2
      , WRF_CHARSTC3
      , ZZREGION
      , ZZSHPC
      , ZZSHPD
      , ZZFREIGHT
      , ZZNO_EMAIL
      , ZZFRZ_SHPDT
      , ZZPROJ_NO
      , ZZ3RDPO
      , ZZFRTCD
      , ZZFRTCST
      , ZZTRANSIT
      , ZZCAUSE
      , ZZAIR_FREIGHT
      , ZZAIR_FRGHT_BU
      , ZZMPLFZ
      , ZZ_O8_REF
      , ZZ_O8_COLOR
      , ZZ_O8_BUFFER
      , REFSITE
      , SERRU
      , SERNP
      , DISUB_SOBKZ
      , DISUB_PSPNR
      , DISUB_KUNNR
      , DISUB_VBELN
      , DISUB_POSNR
      , DISUB_OWNER
      , FSH_SEASON_YEAR
      , FSH_SEASON
      , FSH_COLLECTION
      , FSH_THEME
      , FSH_ATP_DATE
      , FSH_VAS_REL
      , FSH_VAS_PRNT_ID
      , FSH_TRANSACTION
      , FSH_ITEM_GROUP
      , FSH_ITEM
      , FSH_SS
      , FSH_GRID_COND_REC
      , FSH_PSM_PFM_SPLIT
      , CNFM_QTY
      , FSH_PQR_UEPOS
      , REF_ITEM
      , SOURCE_ID
      , SOURCE_KEY
      , PUT_BACK
      , POL_ID
      , CONS_ORDER
      , ZZREASON_CD
      , ZZPRF_REC
      , ZZDRAW_REC
      , ZZASNIND_SENT
      , ZZSUBREASON
      , ZZAEDAT
      , ZZHOT
      , KNDBT
      , ZACTKGWEIGHT
      , ZDIMKGWEIGHT
      , ZWEIGHTUSED
      , GLDELFLAG
      , GLCHANGETIME
      , PSA_LOAD_DTS
      , PSA_DELETE_IND
      , LOAD_DTS
    FROM LOGIC_polsap
)

, RENAME_posap as (
    SELECT
        SUPPLIER_BK
      , LIFNR
      , BEDAT
      , EKORG
      , POSAP_EBELN
    FROM LOGIC_posap
)

, RENAME_a as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_a
)
---- FILTER LAYER ----

, FILTER_polsap as (
    SELECT *
    FROM RENAME_polsap
)

, FILTER_posap as (
    SELECT *
    FROM RENAME_posap
)

, FILTER_a as (
    SELECT *
    FROM RENAME_a
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_EKPO'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    -- The following conditional change event clause is added to track When a PO item's MATNR changes and reverts (220C2SRN --> 220C2SRN-01 --> 220C2SRN). This will be a part of Link HK
    , CONDITIONAL_CHANGE_EVENT(HASH(LIFNR,MATNR,BUKRS,INFNR,EKORG)) OVER(PARTITION BY EBELN,EBELP ORDER BY PSA_LOAD_DTS ) AS CCE
    FROM FILTER_polsap
    LEFT JOIN FILTER_posap
        ON FILTER_polsap.EBELN = FILTER_posap.POSAP_EBELN
    INNER JOIN FILTER_a
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          PO_ITEM_BK
        , PO_HEADER_BK
        , SUPPLIER_BK
        , ITEM_BK
        , LEGAL_ENTITY_BK
        , EKORG
        , EBELN
        , EBELP
        , MATNR
        , INFNR
        , GLREQUEST
        , GLSOURCESYSTEM
        , LOEKZ
        , STATU
        , AEDAT
        , TXZ01
        , EMATN
        , MANDT
        , BUKRS
        , WERKS
        , LGORT
        , BEDNR
        , MATKL
        , IDNLF
        , KTMNG
        , MENGE
        , MEINS
        , BPRME
        , BPUMZ
        , BPUMN
        , UMREZ
        , UMREN
        , NETPR
        , PEINH
        , NETWR
        , BRTWR
        , AGDAT
        , WEBAZ
        , MWSKZ
        , BONUS
        , INSMK
        , SPINF
        , PRSDR
        , SCHPR
        , MAHNZ
        , MAHN1
        , MAHN2
        , MAHN3
        , UEBTO
        , UEBTK
        , UNTTO
        , BWTAR
        , BWTTY
        , ABSKZ
        , AGMEM
        , ELIKZ
        , EREKZ
        , PSTYP
        , KNTTP
        , KZVBR
        , VRTKZ
        , TWRKZ
        , WEPOS
        , WEUNB
        , REPOS
        , WEBRE
        , KZABS
        , LABNR
        , KONNR
        , KTPNR
        , ABDAT
        , ABFTZ
        , ETFZ1
        , ETFZ2
        , KZSTU
        , NOTKZ
        , LMEIN
        , EVERS
        , ZWERT
        , NAVNW
        , ABMNG
        , PRDAT
        , BSTYP
        , EFFWR
        , XOBLR
        , KUNNR
        , ADRNR
        , EKKOL
        , SKTOF
        , STAFO
        , PLIFZ
        , NTGEW
        , GEWEI
        , TXJCD
        , ETDRK
        , SOBKZ
        , ARSNR
        , ARSPS
        , INSNC
        , SSQSS
        , ZGTYP
        , EAN11
        , BSTAE
        , REVLV
        , GEBER
        , FISTL
        , FIPOS
        , KO_GSBER
        , KO_PARGB
        , KO_PRCTR
        , KO_PPRCTR
        , MEPRF
        , BRGEW
        , VOLUM
        , VOLEH
        , INCO1
        , INCO2
        , VORAB
        , KOLIF
        , LTSNR
        , PACKNO
        , FPLNR
        , GNETWR
        , STAPO
        , UEBPO
        , LEWED
        , EMLIF
        , LBLKZ
        , SATNR
        , ATTYP
        , VSART
        , HANDOVERLOC
        , KANBA
        , ADRN2
        , CUOBJ
        , XERSY
        , EILDT
        , DRDAT
        , DRUHR
        , DRUNR
        , AKTNR
        , ABELN
        , ABELP
        , ANZPU
        , PUNEI
        , SAISO
        , SAISJ
        , EBON2
        , EBON3
        , EBONF
        , MLMAA
        , MHDRZ
        , ANFNR
        , ANFPS
        , KZKFG
        , USEQU
        , UMSOK
        , BANFN
        , BNFPO
        , MTART
        , UPTYP
        , UPVOR
        , KZWI1
        , KZWI2
        , KZWI3
        , KZWI4
        , KZWI5
        , KZWI6
        , SIKGR
        , MFZHI
        , FFZHI
        , RETPO
        , AUREL
        , BSGRU
        , LFRET
        , MFRGR
        , NRFHG
        , J_1BNBM
        , J_1BMATUSE
        , J_1BMATORG
        , J_1BOWNPRO
        , J_1BINDUST
        , ABUEB
        , NLABD
        , NFABD
        , KZBWS
        , BONBA
        , FABKZ
        , J_1AINDXP
        , J_1AIDATEP
        , MPROF
        , EGLKZ
        , KZTLF
        , KZFME
        , RDPRF
        , TECHS
        , CHG_SRV
        , CHG_FPLNR
        , MFRPN
        , MFRNR
        , EMNFR
        , NOVET
        , AFNAM
        , TZONRC
        , IPRKZ
        , LEBRE
        , BERID
        , XCONDITIONS
        , APOMS
        , CCOMP
        , GRANT_NBR
        , FKBER
        , STATUS
        , RESLO
        , KBLNR
        , KBLPOS
        , WEORA
        , SRV_BAS_COM
        , PRIO_URG
        , PRIO_REQ
        , EMPST
        , DIFF_INVOICE
        , TRMRISK_RELEVANT
        , SPE_ABGRU
        , SPE_CRM_SO
        , SPE_CRM_SO_ITEM
        , SPE_CRM_REF_SO
        , SPE_CRM_REF_ITEM
        , SPE_CRM_FKREL
        , SPE_CHNG_SYS
        , SPE_INSMK_SRC
        , SPE_CQ_CTRLTYPE
        , SPE_CQ_NOCQ
        , REASON_CODE
        , CQU_SAR
        , ANZSN
        , SPE_EWM_DTC
        , EXLIN
        , EXSNR
        , EHTYP
        , RETPC
        , DPTYP
        , DPPCT
        , DPAMT
        , DPDAT
        , FLS_RSTO
        , EXT_RFX_NUMBER
        , EXT_RFX_ITEM
        , EXT_RFX_SYSTEM
        , SRM_CONTRACT_ID
        , SRM_CONTRACT_ITM
        , BLK_REASON_ID
        , BLK_REASON_TXT
        , ITCONS
        , FIXMG
        , WABWE
        , CMPL_DLV_ITM
        , INCO2_L
        , INCO3_L
        , TC_AUT_DET
        , MANUAL_TC_REASON
        , FISCAL_INCENTIVE
        , TAX_SUBJECT_ST
        , FISCAL_INCENTIVE_ID
        , SF_TXJCD
        , _BEV1_NEGEN_ITEM
        , _BEV1_NEDEPFREE
        , _BEV1_NESTRUCCAT
        , ADVCODE
        , BUDGET_PD
        , EXCPE
        , FMFGUS_KEY
        , IUID_RELEVANT
        , MRPIND
        , SGT_SCAT
        , SGT_RCAT
        , WRF_CHARSTC1
        , WRF_CHARSTC2
        , WRF_CHARSTC3
        , ZZREGION
        , ZZSHPC
        , ZZSHPD
        , ZZFREIGHT
        , ZZNO_EMAIL
        , ZZFRZ_SHPDT
        , ZZPROJ_NO
        , ZZ3RDPO
        , ZZFRTCD
        , ZZFRTCST
        , ZZTRANSIT
        , ZZCAUSE
        , ZZAIR_FREIGHT
        , ZZAIR_FRGHT_BU
        , ZZMPLFZ
        , ZZ_O8_REF
        , ZZ_O8_COLOR
        , ZZ_O8_BUFFER
        , REFSITE
        , SERRU
        , SERNP
        , DISUB_SOBKZ
        , DISUB_PSPNR
        , DISUB_KUNNR
        , DISUB_VBELN
        , DISUB_POSNR
        , DISUB_OWNER
        , FSH_SEASON_YEAR
        , FSH_SEASON
        , FSH_COLLECTION
        , FSH_THEME
        , FSH_ATP_DATE
        , FSH_VAS_REL
        , FSH_VAS_PRNT_ID
        , FSH_TRANSACTION
        , FSH_ITEM_GROUP
        , FSH_ITEM
        , FSH_SS
        , FSH_GRID_COND_REC
        , FSH_PSM_PFM_SPLIT
        , CNFM_QTY
        , FSH_PQR_UEPOS
        , REF_ITEM
        , SOURCE_ID
        , SOURCE_KEY
        , PUT_BACK
        , POL_ID
        , CONS_ORDER
        , ZZREASON_CD
        , ZZPRF_REC
        , ZZDRAW_REC
        , ZZASNIND_SENT
        , ZZSUBREASON
        , ZZAEDAT
        , ZZHOT
        , KNDBT
        , ZACTKGWEIGHT
        , ZDIMKGWEIGHT
        , ZWEIGHTUSED
        , GLDELFLAG
        , GLCHANGETIME
        , PSA_LOAD_DTS
        , PSA_DELETE_IND
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(EBELN as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(EBELP as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PO_ITEM_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(EBELN as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(EBELP as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(LIFNR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(MATNR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BUKRS as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(INFNR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(EKORG as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(CCE as VARCHAR)),''), '^^')
        ))) as LNK_PO_ITEM_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(EBELN as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PO_HEADER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(LIFNR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as SUPPLIER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(MATNR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ITEM_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(BUKRS as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as LEGAL_ENTITY_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(INFNR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PURCHASING_RECORD_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(EKORG as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PURCHASING_ORG_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(MATNR::text), '^^') 
            , '||', IFNULL(TRIM(INFNR::text), '^^') 
            , '||', IFNULL(TRIM(LOEKZ::text), '^^') 
            , '||', IFNULL(TRIM(STATU::text), '^^') 
            , '||', IFNULL(TRIM(AEDAT::text), '^^') 
            , '||', IFNULL(TRIM(TXZ01::text), '^^') 
            , '||', IFNULL(TRIM(EMATN::text), '^^') 
            , '||', IFNULL(TRIM(MANDT::text), '^^') 
            , '||', IFNULL(TRIM(BUKRS::text), '^^') 
            , '||', IFNULL(TRIM(WERKS::text), '^^') 
            , '||', IFNULL(TRIM(LGORT::text), '^^') 
            , '||', IFNULL(TRIM(BEDNR::text), '^^') 
            , '||', IFNULL(TRIM(MATKL::text), '^^') 
            , '||', IFNULL(TRIM(IDNLF::text), '^^') 
            , '||', IFNULL(TRIM(KTMNG::text), '^^') 
            , '||', IFNULL(TRIM(MENGE::text), '^^') 
            , '||', IFNULL(TRIM(MEINS::text), '^^') 
            , '||', IFNULL(TRIM(BPRME::text), '^^') 
            , '||', IFNULL(TRIM(BPUMZ::text), '^^') 
            , '||', IFNULL(TRIM(BPUMN::text), '^^') 
            , '||', IFNULL(TRIM(UMREZ::text), '^^') 
            , '||', IFNULL(TRIM(UMREN::text), '^^') 
            , '||', IFNULL(TRIM(NETPR::text), '^^') 
            , '||', IFNULL(TRIM(PEINH::text), '^^') 
            , '||', IFNULL(TRIM(NETWR::text), '^^') 
            , '||', IFNULL(TRIM(BRTWR::text), '^^') 
            , '||', IFNULL(TRIM(AGDAT::text), '^^') 
            , '||', IFNULL(TRIM(WEBAZ::text), '^^') 
            , '||', IFNULL(TRIM(MWSKZ::text), '^^') 
            , '||', IFNULL(TRIM(BONUS::text), '^^') 
            , '||', IFNULL(TRIM(INSMK::text), '^^') 
            , '||', IFNULL(TRIM(SPINF::text), '^^') 
            , '||', IFNULL(TRIM(PRSDR::text), '^^') 
            , '||', IFNULL(TRIM(SCHPR::text), '^^') 
            , '||', IFNULL(TRIM(MAHNZ::text), '^^') 
            , '||', IFNULL(TRIM(MAHN1::text), '^^') 
            , '||', IFNULL(TRIM(MAHN2::text), '^^') 
            , '||', IFNULL(TRIM(MAHN3::text), '^^') 
            , '||', IFNULL(TRIM(UEBTO::text), '^^') 
            , '||', IFNULL(TRIM(UEBTK::text), '^^') 
            , '||', IFNULL(TRIM(UNTTO::text), '^^') 
            , '||', IFNULL(TRIM(BWTAR::text), '^^') 
            , '||', IFNULL(TRIM(BWTTY::text), '^^') 
            , '||', IFNULL(TRIM(ABSKZ::text), '^^') 
            , '||', IFNULL(TRIM(AGMEM::text), '^^') 
            , '||', IFNULL(TRIM(ELIKZ::text), '^^') 
            , '||', IFNULL(TRIM(EREKZ::text), '^^') 
            , '||', IFNULL(TRIM(PSTYP::text), '^^') 
            , '||', IFNULL(TRIM(KNTTP::text), '^^') 
            , '||', IFNULL(TRIM(KZVBR::text), '^^') 
            , '||', IFNULL(TRIM(VRTKZ::text), '^^') 
            , '||', IFNULL(TRIM(TWRKZ::text), '^^') 
            , '||', IFNULL(TRIM(WEPOS::text), '^^') 
            , '||', IFNULL(TRIM(WEUNB::text), '^^') 
            , '||', IFNULL(TRIM(REPOS::text), '^^') 
            , '||', IFNULL(TRIM(WEBRE::text), '^^') 
            , '||', IFNULL(TRIM(KZABS::text), '^^') 
            , '||', IFNULL(TRIM(LABNR::text), '^^') 
            , '||', IFNULL(TRIM(KONNR::text), '^^') 
            , '||', IFNULL(TRIM(KTPNR::text), '^^') 
            , '||', IFNULL(TRIM(ABDAT::text), '^^') 
            , '||', IFNULL(TRIM(ABFTZ::text), '^^') 
            , '||', IFNULL(TRIM(ETFZ1::text), '^^') 
            , '||', IFNULL(TRIM(ETFZ2::text), '^^') 
            , '||', IFNULL(TRIM(KZSTU::text), '^^') 
            , '||', IFNULL(TRIM(NOTKZ::text), '^^') 
            , '||', IFNULL(TRIM(LMEIN::text), '^^') 
            , '||', IFNULL(TRIM(EVERS::text), '^^') 
            , '||', IFNULL(TRIM(ZWERT::text), '^^') 
            , '||', IFNULL(TRIM(NAVNW::text), '^^') 
            , '||', IFNULL(TRIM(ABMNG::text), '^^') 
            , '||', IFNULL(TRIM(PRDAT::text), '^^') 
            , '||', IFNULL(TRIM(BSTYP::text), '^^') 
            , '||', IFNULL(TRIM(EFFWR::text), '^^') 
            , '||', IFNULL(TRIM(XOBLR::text), '^^') 
            , '||', IFNULL(TRIM(KUNNR::text), '^^') 
            , '||', IFNULL(TRIM(ADRNR::text), '^^') 
            , '||', IFNULL(TRIM(EKKOL::text), '^^') 
            , '||', IFNULL(TRIM(SKTOF::text), '^^') 
            , '||', IFNULL(TRIM(STAFO::text), '^^') 
            , '||', IFNULL(TRIM(PLIFZ::text), '^^') 
            , '||', IFNULL(TRIM(NTGEW::text), '^^') 
            , '||', IFNULL(TRIM(GEWEI::text), '^^') 
            , '||', IFNULL(TRIM(TXJCD::text), '^^') 
            , '||', IFNULL(TRIM(ETDRK::text), '^^') 
            , '||', IFNULL(TRIM(SOBKZ::text), '^^') 
            , '||', IFNULL(TRIM(ARSNR::text), '^^') 
            , '||', IFNULL(TRIM(ARSPS::text), '^^') 
            , '||', IFNULL(TRIM(INSNC::text), '^^') 
            , '||', IFNULL(TRIM(SSQSS::text), '^^') 
            , '||', IFNULL(TRIM(ZGTYP::text), '^^') 
            , '||', IFNULL(TRIM(EAN11::text), '^^') 
            , '||', IFNULL(TRIM(BSTAE::text), '^^') 
            , '||', IFNULL(TRIM(REVLV::text), '^^') 
            , '||', IFNULL(TRIM(GEBER::text), '^^') 
            , '||', IFNULL(TRIM(FISTL::text), '^^') 
            , '||', IFNULL(TRIM(FIPOS::text), '^^') 
            , '||', IFNULL(TRIM(KO_GSBER::text), '^^') 
            , '||', IFNULL(TRIM(KO_PARGB::text), '^^') 
            , '||', IFNULL(TRIM(KO_PRCTR::text), '^^') 
            , '||', IFNULL(TRIM(KO_PPRCTR::text), '^^') 
            , '||', IFNULL(TRIM(MEPRF::text), '^^') 
            , '||', IFNULL(TRIM(BRGEW::text), '^^') 
            , '||', IFNULL(TRIM(VOLUM::text), '^^') 
            , '||', IFNULL(TRIM(VOLEH::text), '^^') 
            , '||', IFNULL(TRIM(INCO1::text), '^^') 
            , '||', IFNULL(TRIM(INCO2::text), '^^') 
            , '||', IFNULL(TRIM(VORAB::text), '^^') 
            , '||', IFNULL(TRIM(KOLIF::text), '^^') 
            , '||', IFNULL(TRIM(LTSNR::text), '^^') 
            , '||', IFNULL(TRIM(PACKNO::text), '^^') 
            , '||', IFNULL(TRIM(FPLNR::text), '^^') 
            , '||', IFNULL(TRIM(GNETWR::text), '^^') 
            , '||', IFNULL(TRIM(STAPO::text), '^^') 
            , '||', IFNULL(TRIM(UEBPO::text), '^^') 
            , '||', IFNULL(TRIM(LEWED::text), '^^') 
            , '||', IFNULL(TRIM(EMLIF::text), '^^') 
            , '||', IFNULL(TRIM(LBLKZ::text), '^^') 
            , '||', IFNULL(TRIM(SATNR::text), '^^') 
            , '||', IFNULL(TRIM(ATTYP::text), '^^') 
            , '||', IFNULL(TRIM(VSART::text), '^^') 
            , '||', IFNULL(TRIM(HANDOVERLOC::text), '^^') 
            , '||', IFNULL(TRIM(KANBA::text), '^^') 
            , '||', IFNULL(TRIM(ADRN2::text), '^^') 
            , '||', IFNULL(TRIM(CUOBJ::text), '^^') 
            , '||', IFNULL(TRIM(XERSY::text), '^^') 
            , '||', IFNULL(TRIM(EILDT::text), '^^') 
            , '||', IFNULL(TRIM(DRDAT::text), '^^') 
            , '||', IFNULL(TRIM(DRUHR::text), '^^') 
            , '||', IFNULL(TRIM(DRUNR::text), '^^') 
            , '||', IFNULL(TRIM(AKTNR::text), '^^') 
            , '||', IFNULL(TRIM(ABELN::text), '^^') 
            , '||', IFNULL(TRIM(ABELP::text), '^^') 
            , '||', IFNULL(TRIM(ANZPU::text), '^^') 
            , '||', IFNULL(TRIM(PUNEI::text), '^^') 
            , '||', IFNULL(TRIM(SAISO::text), '^^') 
            , '||', IFNULL(TRIM(SAISJ::text), '^^') 
            , '||', IFNULL(TRIM(EBON2::text), '^^') 
            , '||', IFNULL(TRIM(EBON3::text), '^^') 
            , '||', IFNULL(TRIM(EBONF::text), '^^') 
            , '||', IFNULL(TRIM(MLMAA::text), '^^') 
            , '||', IFNULL(TRIM(MHDRZ::text), '^^') 
            , '||', IFNULL(TRIM(ANFNR::text), '^^') 
            , '||', IFNULL(TRIM(ANFPS::text), '^^') 
            , '||', IFNULL(TRIM(KZKFG::text), '^^') 
            , '||', IFNULL(TRIM(USEQU::text), '^^') 
            , '||', IFNULL(TRIM(UMSOK::text), '^^') 
            , '||', IFNULL(TRIM(BANFN::text), '^^') 
            , '||', IFNULL(TRIM(BNFPO::text), '^^') 
            , '||', IFNULL(TRIM(MTART::text), '^^') 
            , '||', IFNULL(TRIM(UPTYP::text), '^^') 
            , '||', IFNULL(TRIM(UPVOR::text), '^^') 
            , '||', IFNULL(TRIM(KZWI1::text), '^^') 
            , '||', IFNULL(TRIM(KZWI2::text), '^^') 
            , '||', IFNULL(TRIM(KZWI3::text), '^^') 
            , '||', IFNULL(TRIM(KZWI4::text), '^^') 
            , '||', IFNULL(TRIM(KZWI5::text), '^^') 
            , '||', IFNULL(TRIM(KZWI6::text), '^^') 
            , '||', IFNULL(TRIM(SIKGR::text), '^^') 
            , '||', IFNULL(TRIM(MFZHI::text), '^^') 
            , '||', IFNULL(TRIM(FFZHI::text), '^^') 
            , '||', IFNULL(TRIM(RETPO::text), '^^') 
            , '||', IFNULL(TRIM(AUREL::text), '^^') 
            , '||', IFNULL(TRIM(BSGRU::text), '^^') 
            , '||', IFNULL(TRIM(LFRET::text), '^^') 
            , '||', IFNULL(TRIM(MFRGR::text), '^^') 
            , '||', IFNULL(TRIM(NRFHG::text), '^^') 
            , '||', IFNULL(TRIM(J_1BNBM::text), '^^') 
            , '||', IFNULL(TRIM(J_1BMATUSE::text), '^^') 
            , '||', IFNULL(TRIM(J_1BMATORG::text), '^^') 
            , '||', IFNULL(TRIM(J_1BOWNPRO::text), '^^') 
            , '||', IFNULL(TRIM(J_1BINDUST::text), '^^') 
            , '||', IFNULL(TRIM(ABUEB::text), '^^') 
            , '||', IFNULL(TRIM(NLABD::text), '^^') 
            , '||', IFNULL(TRIM(NFABD::text), '^^') 
            , '||', IFNULL(TRIM(KZBWS::text), '^^') 
            , '||', IFNULL(TRIM(BONBA::text), '^^') 
            , '||', IFNULL(TRIM(FABKZ::text), '^^') 
            , '||', IFNULL(TRIM(J_1AINDXP::text), '^^') 
            , '||', IFNULL(TRIM(J_1AIDATEP::text), '^^') 
            , '||', IFNULL(TRIM(MPROF::text), '^^') 
            , '||', IFNULL(TRIM(EGLKZ::text), '^^') 
            , '||', IFNULL(TRIM(KZTLF::text), '^^') 
            , '||', IFNULL(TRIM(KZFME::text), '^^') 
            , '||', IFNULL(TRIM(RDPRF::text), '^^') 
            , '||', IFNULL(TRIM(TECHS::text), '^^') 
            , '||', IFNULL(TRIM(CHG_SRV::text), '^^') 
            , '||', IFNULL(TRIM(CHG_FPLNR::text), '^^') 
            , '||', IFNULL(TRIM(MFRPN::text), '^^') 
            , '||', IFNULL(TRIM(MFRNR::text), '^^') 
            , '||', IFNULL(TRIM(EMNFR::text), '^^') 
            , '||', IFNULL(TRIM(NOVET::text), '^^') 
            , '||', IFNULL(TRIM(AFNAM::text), '^^') 
            , '||', IFNULL(TRIM(TZONRC::text), '^^') 
            , '||', IFNULL(TRIM(IPRKZ::text), '^^') 
            , '||', IFNULL(TRIM(LEBRE::text), '^^') 
            , '||', IFNULL(TRIM(BERID::text), '^^') 
            , '||', IFNULL(TRIM(XCONDITIONS::text), '^^') 
            , '||', IFNULL(TRIM(APOMS::text), '^^') 
            , '||', IFNULL(TRIM(CCOMP::text), '^^') 
            , '||', IFNULL(TRIM(GRANT_NBR::text), '^^') 
            , '||', IFNULL(TRIM(FKBER::text), '^^') 
            , '||', IFNULL(TRIM(STATUS::text), '^^') 
            , '||', IFNULL(TRIM(RESLO::text), '^^') 
            , '||', IFNULL(TRIM(KBLNR::text), '^^') 
            , '||', IFNULL(TRIM(KBLPOS::text), '^^') 
            , '||', IFNULL(TRIM(WEORA::text), '^^') 
            , '||', IFNULL(TRIM(SRV_BAS_COM::text), '^^') 
            , '||', IFNULL(TRIM(PRIO_URG::text), '^^') 
            , '||', IFNULL(TRIM(PRIO_REQ::text), '^^') 
            , '||', IFNULL(TRIM(EMPST::text), '^^') 
            , '||', IFNULL(TRIM(DIFF_INVOICE::text), '^^') 
            , '||', IFNULL(TRIM(TRMRISK_RELEVANT::text), '^^') 
            , '||', IFNULL(TRIM(SPE_ABGRU::text), '^^') 
            , '||', IFNULL(TRIM(SPE_CRM_SO::text), '^^') 
            , '||', IFNULL(TRIM(SPE_CRM_SO_ITEM::text), '^^') 
            , '||', IFNULL(TRIM(SPE_CRM_REF_SO::text), '^^') 
            , '||', IFNULL(TRIM(SPE_CRM_REF_ITEM::text), '^^') 
            , '||', IFNULL(TRIM(SPE_CRM_FKREL::text), '^^') 
            , '||', IFNULL(TRIM(SPE_CHNG_SYS::text), '^^') 
            , '||', IFNULL(TRIM(SPE_INSMK_SRC::text), '^^') 
            , '||', IFNULL(TRIM(SPE_CQ_CTRLTYPE::text), '^^') 
            , '||', IFNULL(TRIM(SPE_CQ_NOCQ::text), '^^') 
            , '||', IFNULL(TRIM(REASON_CODE::text), '^^') 
            , '||', IFNULL(TRIM(CQU_SAR::text), '^^') 
            , '||', IFNULL(TRIM(ANZSN::text), '^^') 
            , '||', IFNULL(TRIM(SPE_EWM_DTC::text), '^^') 
            , '||', IFNULL(TRIM(EXLIN::text), '^^') 
            , '||', IFNULL(TRIM(EXSNR::text), '^^') 
            , '||', IFNULL(TRIM(EHTYP::text), '^^') 
            , '||', IFNULL(TRIM(RETPC::text), '^^') 
            , '||', IFNULL(TRIM(DPTYP::text), '^^') 
            , '||', IFNULL(TRIM(DPPCT::text), '^^') 
            , '||', IFNULL(TRIM(DPAMT::text), '^^') 
            , '||', IFNULL(TRIM(DPDAT::text), '^^') 
            , '||', IFNULL(TRIM(FLS_RSTO::text), '^^') 
            , '||', IFNULL(TRIM(EXT_RFX_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(EXT_RFX_ITEM::text), '^^') 
            , '||', IFNULL(TRIM(EXT_RFX_SYSTEM::text), '^^') 
            , '||', IFNULL(TRIM(SRM_CONTRACT_ID::text), '^^') 
            , '||', IFNULL(TRIM(SRM_CONTRACT_ITM::text), '^^') 
            , '||', IFNULL(TRIM(BLK_REASON_ID::text), '^^') 
            , '||', IFNULL(TRIM(BLK_REASON_TXT::text), '^^') 
            , '||', IFNULL(TRIM(ITCONS::text), '^^') 
            , '||', IFNULL(TRIM(FIXMG::text), '^^') 
            , '||', IFNULL(TRIM(WABWE::text), '^^') 
            , '||', IFNULL(TRIM(CMPL_DLV_ITM::text), '^^') 
            , '||', IFNULL(TRIM(INCO2_L::text), '^^') 
            , '||', IFNULL(TRIM(INCO3_L::text), '^^') 
            , '||', IFNULL(TRIM(TC_AUT_DET::text), '^^') 
            , '||', IFNULL(TRIM(MANUAL_TC_REASON::text), '^^') 
            , '||', IFNULL(TRIM(FISCAL_INCENTIVE::text), '^^') 
            , '||', IFNULL(TRIM(TAX_SUBJECT_ST::text), '^^') 
            , '||', IFNULL(TRIM(FISCAL_INCENTIVE_ID::text), '^^') 
            , '||', IFNULL(TRIM(SF_TXJCD::text), '^^') 
            , '||', IFNULL(TRIM(_BEV1_NEGEN_ITEM::text), '^^') 
            , '||', IFNULL(TRIM(_BEV1_NEDEPFREE::text), '^^') 
            , '||', IFNULL(TRIM(_BEV1_NESTRUCCAT::text), '^^') 
            , '||', IFNULL(TRIM(ADVCODE::text), '^^') 
            , '||', IFNULL(TRIM(BUDGET_PD::text), '^^') 
            , '||', IFNULL(TRIM(EXCPE::text), '^^') 
            , '||', IFNULL(TRIM(FMFGUS_KEY::text), '^^') 
            , '||', IFNULL(TRIM(IUID_RELEVANT::text), '^^') 
            , '||', IFNULL(TRIM(MRPIND::text), '^^') 
            , '||', IFNULL(TRIM(SGT_SCAT::text), '^^') 
            , '||', IFNULL(TRIM(SGT_RCAT::text), '^^') 
            , '||', IFNULL(TRIM(WRF_CHARSTC1::text), '^^') 
            , '||', IFNULL(TRIM(WRF_CHARSTC2::text), '^^') 
            , '||', IFNULL(TRIM(WRF_CHARSTC3::text), '^^') 
            , '||', IFNULL(TRIM(ZZREGION::text), '^^') 
            , '||', IFNULL(TRIM(ZZSHPC::text), '^^') 
            , '||', IFNULL(TRIM(ZZSHPD::text), '^^') 
            , '||', IFNULL(TRIM(ZZFREIGHT::text), '^^') 
            , '||', IFNULL(TRIM(ZZNO_EMAIL::text), '^^') 
            , '||', IFNULL(TRIM(ZZFRZ_SHPDT::text), '^^') 
            , '||', IFNULL(TRIM(ZZPROJ_NO::text), '^^') 
            , '||', IFNULL(TRIM(ZZ3RDPO::text), '^^') 
            , '||', IFNULL(TRIM(ZZFRTCD::text), '^^') 
            , '||', IFNULL(TRIM(ZZFRTCST::text), '^^') 
            , '||', IFNULL(TRIM(ZZTRANSIT::text), '^^') 
            , '||', IFNULL(TRIM(ZZCAUSE::text), '^^') 
            , '||', IFNULL(TRIM(ZZAIR_FREIGHT::text), '^^') 
            , '||', IFNULL(TRIM(ZZAIR_FRGHT_BU::text), '^^') 
            , '||', IFNULL(TRIM(ZZMPLFZ::text), '^^') 
            , '||', IFNULL(TRIM(ZZ_O8_REF::text), '^^') 
            , '||', IFNULL(TRIM(ZZ_O8_COLOR::text), '^^') 
            , '||', IFNULL(TRIM(ZZ_O8_BUFFER::text), '^^') 
            , '||', IFNULL(TRIM(REFSITE::text), '^^') 
            , '||', IFNULL(TRIM(SERRU::text), '^^') 
            , '||', IFNULL(TRIM(SERNP::text), '^^') 
            , '||', IFNULL(TRIM(DISUB_SOBKZ::text), '^^') 
            , '||', IFNULL(TRIM(DISUB_PSPNR::text), '^^') 
            , '||', IFNULL(TRIM(DISUB_KUNNR::text), '^^') 
            , '||', IFNULL(TRIM(DISUB_VBELN::text), '^^') 
            , '||', IFNULL(TRIM(DISUB_POSNR::text), '^^') 
            , '||', IFNULL(TRIM(DISUB_OWNER::text), '^^') 
            , '||', IFNULL(TRIM(FSH_SEASON_YEAR::text), '^^') 
            , '||', IFNULL(TRIM(FSH_SEASON::text), '^^') 
            , '||', IFNULL(TRIM(FSH_COLLECTION::text), '^^') 
            , '||', IFNULL(TRIM(FSH_THEME::text), '^^') 
            , '||', IFNULL(TRIM(FSH_ATP_DATE::text), '^^') 
            , '||', IFNULL(TRIM(FSH_VAS_REL::text), '^^') 
            , '||', IFNULL(TRIM(FSH_VAS_PRNT_ID::text), '^^') 
            , '||', IFNULL(TRIM(FSH_TRANSACTION::text), '^^') 
            , '||', IFNULL(TRIM(FSH_ITEM_GROUP::text), '^^') 
            , '||', IFNULL(TRIM(FSH_ITEM::text), '^^') 
            , '||', IFNULL(TRIM(FSH_SS::text), '^^') 
            , '||', IFNULL(TRIM(FSH_GRID_COND_REC::text), '^^') 
            , '||', IFNULL(TRIM(FSH_PSM_PFM_SPLIT::text), '^^') 
            , '||', IFNULL(TRIM(CNFM_QTY::text), '^^') 
            , '||', IFNULL(TRIM(FSH_PQR_UEPOS::text), '^^') 
            , '||', IFNULL(TRIM(REF_ITEM::text), '^^') 
            , '||', IFNULL(TRIM(SOURCE_ID::text), '^^') 
            , '||', IFNULL(TRIM(SOURCE_KEY::text), '^^') 
            , '||', IFNULL(TRIM(PUT_BACK::text), '^^') 
            , '||', IFNULL(TRIM(POL_ID::text), '^^') 
            , '||', IFNULL(TRIM(CONS_ORDER::text), '^^') 
            , '||', IFNULL(TRIM(ZZREASON_CD::text), '^^') 
            , '||', IFNULL(TRIM(ZZPRF_REC::text), '^^') 
            , '||', IFNULL(TRIM(ZZDRAW_REC::text), '^^') 
            , '||', IFNULL(TRIM(ZZASNIND_SENT::text), '^^') 
            , '||', IFNULL(TRIM(ZZSUBREASON::text), '^^') 
            , '||', IFNULL(TRIM(ZZAEDAT::text), '^^') 
            , '||', IFNULL(TRIM(ZZHOT::text), '^^') 
            , '||', IFNULL(TRIM(KNDBT::text), '^^') 
            , '||', IFNULL(TRIM(ZACTKGWEIGHT::text), '^^') 
            , '||', IFNULL(TRIM(ZDIMKGWEIGHT::text), '^^') 
            , '||', IFNULL(TRIM(ZWEIGHTUSED::text), '^^') 
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT