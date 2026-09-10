---- SRC LAYER ----
WITH
SRC_a              as ( SELECT * FROM {{ ref('v_psa_stg_po_item__winn_sap') }} as SRC 
                         {% if is_incremental() %}
                              where src.load_dts > (select dateadd('HOUR',-1,max(load_dts)) from {{ this }})
                            {% endif %}   )

/*
SRC_a              as ( SELECT * FROM staging.v_psa_stg_po_item__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_a as (
    SELECT
        PO_ITEM_HK
      , EBELN
      , EBELP
      , MATNR
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
      , INFNR
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
      , HASHDIFF
    FROM SRC_a
)
---- RENAME LAYER ----

, RENAME_a as (
    SELECT
        PO_ITEM_HK
      , EBELN
      , EBELP
      , MATNR
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
      , INFNR
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
      , HASHDIFF
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
          PO_ITEM_HK
        , EBELN
        , EBELP
        , MATNR
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
        , INFNR
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
        , HASHDIFF
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.PO_ITEM_HK = JOIN_RESULT.PO_ITEM_HK 
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %}
{% if not is_incremental() %}

/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per HK and hashdiff. */
qualify 1 = row_number() over (partition by PO_ITEM_HK, HASHDIFF order by PSA_LOAD_DTS)

union all
SELECT 
MD5_BINARY(GR.VALUE) AS PO_ITEM_HK,
GR.VALUE::text AS EBELN,
GR.VALUE::text AS EBELP,
NULL AS MATNR,
NULL AS GLREQUEST,
NULL AS GLSOURCESYSTEM,
NULL AS LOEKZ,
NULL AS STATU,
NULL AS AEDAT,
NULL AS TXZ01,
NULL AS EMATN,
NULL AS MANDT,
NULL AS BUKRS,
NULL AS WERKS,
NULL AS LGORT,
NULL AS BEDNR,
NULL AS MATKL,
NULL AS INFNR,
NULL AS IDNLF,
NULL AS KTMNG,
NULL AS MENGE,
NULL AS MEINS,
NULL AS BPRME,
NULL AS BPUMZ,
NULL AS BPUMN,
NULL AS UMREZ,
NULL AS UMREN,
NULL AS NETPR,
NULL AS PEINH,
NULL AS NETWR,
NULL AS BRTWR,
NULL AS AGDAT,
NULL AS WEBAZ,
NULL AS MWSKZ,
NULL AS BONUS,
NULL AS INSMK,
NULL AS SPINF,
NULL AS PRSDR,
NULL AS SCHPR,
NULL AS MAHNZ,
NULL AS MAHN1,
NULL AS MAHN2,
NULL AS MAHN3,
NULL AS UEBTO,
NULL AS UEBTK,
NULL AS UNTTO,
NULL AS BWTAR,
NULL AS BWTTY,
NULL AS ABSKZ,
NULL AS AGMEM,
NULL AS ELIKZ,
NULL AS EREKZ,
NULL AS PSTYP,
NULL AS KNTTP,
NULL AS KZVBR,
NULL AS VRTKZ,
NULL AS TWRKZ,
NULL AS WEPOS,
NULL AS WEUNB,
NULL AS REPOS,
NULL AS WEBRE,
NULL AS KZABS,
NULL AS LABNR,
NULL AS KONNR,
NULL AS KTPNR,
NULL AS ABDAT,
NULL AS ABFTZ,
NULL AS ETFZ1,
NULL AS ETFZ2,
NULL AS KZSTU,
NULL AS NOTKZ,
NULL AS LMEIN,
NULL AS EVERS,
NULL AS ZWERT,
NULL AS NAVNW,
NULL AS ABMNG,
NULL AS PRDAT,
NULL AS BSTYP,
NULL AS EFFWR,
NULL AS XOBLR,
NULL AS KUNNR,
NULL AS ADRNR,
NULL AS EKKOL,
NULL AS SKTOF,
NULL AS STAFO,
NULL AS PLIFZ,
NULL AS NTGEW,
NULL AS GEWEI,
NULL AS TXJCD,
NULL AS ETDRK,
NULL AS SOBKZ,
NULL AS ARSNR,
NULL AS ARSPS,
NULL AS INSNC,
NULL AS SSQSS,
NULL AS ZGTYP,
NULL AS EAN11,
NULL AS BSTAE,
NULL AS REVLV,
NULL AS GEBER,
NULL AS FISTL,
NULL AS FIPOS,
NULL AS KO_GSBER,
NULL AS KO_PARGB,
NULL AS KO_PRCTR,
NULL AS KO_PPRCTR,
NULL AS MEPRF,
NULL AS BRGEW,
NULL AS VOLUM,
NULL AS VOLEH,
NULL AS INCO1,
NULL AS INCO2,
NULL AS VORAB,
NULL AS KOLIF,
NULL AS LTSNR,
NULL AS PACKNO,
NULL AS FPLNR,
NULL AS GNETWR,
NULL AS STAPO,
NULL AS UEBPO,
NULL AS LEWED,
NULL AS EMLIF,
NULL AS LBLKZ,
NULL AS SATNR,
NULL AS ATTYP,
NULL AS VSART,
NULL AS HANDOVERLOC,
NULL AS KANBA,
NULL AS ADRN2,
NULL AS CUOBJ,
NULL AS XERSY,
NULL AS EILDT,
NULL AS DRDAT,
NULL AS DRUHR,
NULL AS DRUNR,
NULL AS AKTNR,
NULL AS ABELN,
NULL AS ABELP,
NULL AS ANZPU,
NULL AS PUNEI,
NULL AS SAISO,
NULL AS SAISJ,
NULL AS EBON2,
NULL AS EBON3,
NULL AS EBONF,
NULL AS MLMAA,
NULL AS MHDRZ,
NULL AS ANFNR,
NULL AS ANFPS,
NULL AS KZKFG,
NULL AS USEQU,
NULL AS UMSOK,
NULL AS BANFN,
NULL AS BNFPO,
NULL AS MTART,
NULL AS UPTYP,
NULL AS UPVOR,
NULL AS KZWI1,
NULL AS KZWI2,
NULL AS KZWI3,
NULL AS KZWI4,
NULL AS KZWI5,
NULL AS KZWI6,
NULL AS SIKGR,
NULL AS MFZHI,
NULL AS FFZHI,
NULL AS RETPO,
NULL AS AUREL,
NULL AS BSGRU,
NULL AS LFRET,
NULL AS MFRGR,
NULL AS NRFHG,
NULL AS J_1BNBM,
NULL AS J_1BMATUSE,
NULL AS J_1BMATORG,
NULL AS J_1BOWNPRO,
NULL AS J_1BINDUST,
NULL AS ABUEB,
NULL AS NLABD,
NULL AS NFABD,
NULL AS KZBWS,
NULL AS BONBA,
NULL AS FABKZ,
NULL AS J_1AINDXP,
NULL AS J_1AIDATEP,
NULL AS MPROF,
NULL AS EGLKZ,
NULL AS KZTLF,
NULL AS KZFME,
NULL AS RDPRF,
NULL AS TECHS,
NULL AS CHG_SRV,
NULL AS CHG_FPLNR,
NULL AS MFRPN,
NULL AS MFRNR,
NULL AS EMNFR,
NULL AS NOVET,
NULL AS AFNAM,
NULL AS TZONRC,
NULL AS IPRKZ,
NULL AS LEBRE,
NULL AS BERID,
NULL AS XCONDITIONS,
NULL AS APOMS,
NULL AS CCOMP,
NULL AS GRANT_NBR,
NULL AS FKBER,
NULL AS STATUS,
NULL AS RESLO,
NULL AS KBLNR,
NULL AS KBLPOS,
NULL AS WEORA,
NULL AS SRV_BAS_COM,
NULL AS PRIO_URG,
NULL AS PRIO_REQ,
NULL AS EMPST,
NULL AS DIFF_INVOICE,
NULL AS TRMRISK_RELEVANT,
NULL AS SPE_ABGRU,
NULL AS SPE_CRM_SO,
NULL AS SPE_CRM_SO_ITEM,
NULL AS SPE_CRM_REF_SO,
NULL AS SPE_CRM_REF_ITEM,
NULL AS SPE_CRM_FKREL,
NULL AS SPE_CHNG_SYS,
NULL AS SPE_INSMK_SRC,
NULL AS SPE_CQ_CTRLTYPE,
NULL AS SPE_CQ_NOCQ,
NULL AS REASON_CODE,
NULL AS CQU_SAR,
NULL AS ANZSN,
NULL AS SPE_EWM_DTC,
NULL AS EXLIN,
NULL AS EXSNR,
NULL AS EHTYP,
NULL AS RETPC,
NULL AS DPTYP,
NULL AS DPPCT,
NULL AS DPAMT,
NULL AS DPDAT,
NULL AS FLS_RSTO,
NULL AS EXT_RFX_NUMBER,
NULL AS EXT_RFX_ITEM,
NULL AS EXT_RFX_SYSTEM,
NULL AS SRM_CONTRACT_ID,
NULL AS SRM_CONTRACT_ITM,
NULL AS BLK_REASON_ID,
NULL AS BLK_REASON_TXT,
NULL AS ITCONS,
NULL AS FIXMG,
NULL AS WABWE,
NULL AS CMPL_DLV_ITM,
NULL AS INCO2_L,
NULL AS INCO3_L,
NULL AS TC_AUT_DET,
NULL AS MANUAL_TC_REASON,
NULL AS FISCAL_INCENTIVE,
NULL AS TAX_SUBJECT_ST,
NULL AS FISCAL_INCENTIVE_ID,
NULL AS SF_TXJCD,
NULL AS _BEV1_NEGEN_ITEM,
NULL AS _BEV1_NEDEPFREE,
NULL AS _BEV1_NESTRUCCAT,
NULL AS ADVCODE,
NULL AS BUDGET_PD,
NULL AS EXCPE,
NULL AS FMFGUS_KEY,
NULL AS IUID_RELEVANT,
NULL AS MRPIND,
NULL AS SGT_SCAT,
NULL AS SGT_RCAT,
NULL AS WRF_CHARSTC1,
NULL AS WRF_CHARSTC2,
NULL AS WRF_CHARSTC3,
NULL AS ZZREGION,
NULL AS ZZSHPC,
NULL AS ZZSHPD,
NULL AS ZZFREIGHT,
NULL AS ZZNO_EMAIL,
NULL AS ZZFRZ_SHPDT,
NULL AS ZZPROJ_NO,
NULL AS ZZ3RDPO,
NULL AS ZZFRTCD,
NULL AS ZZFRTCST,
NULL AS ZZTRANSIT,
NULL AS ZZCAUSE,
NULL AS ZZAIR_FREIGHT,
NULL AS ZZAIR_FRGHT_BU,
NULL AS ZZMPLFZ,
NULL AS ZZ_O8_REF,
NULL AS ZZ_O8_COLOR,
NULL AS ZZ_O8_BUFFER,
NULL AS REFSITE,
NULL AS SERRU,
NULL AS SERNP,
NULL AS DISUB_SOBKZ,
NULL AS DISUB_PSPNR,
NULL AS DISUB_KUNNR,
NULL AS DISUB_VBELN,
NULL AS DISUB_POSNR,
NULL AS DISUB_OWNER,
NULL AS FSH_SEASON_YEAR,
NULL AS FSH_SEASON,
NULL AS FSH_COLLECTION,
NULL AS FSH_THEME,
NULL AS FSH_ATP_DATE,
NULL AS FSH_VAS_REL,
NULL AS FSH_VAS_PRNT_ID,
NULL AS FSH_TRANSACTION,
NULL AS FSH_ITEM_GROUP,
NULL AS FSH_ITEM,
NULL AS FSH_SS,
NULL AS FSH_GRID_COND_REC,
NULL AS FSH_PSM_PFM_SPLIT,
NULL AS CNFM_QTY,
NULL AS FSH_PQR_UEPOS,
NULL AS REF_ITEM,
NULL AS SOURCE_ID,
NULL AS SOURCE_KEY,
NULL AS PUT_BACK,
NULL AS POL_ID,
NULL AS CONS_ORDER,
NULL AS ZZREASON_CD,
NULL AS ZZPRF_REC,
NULL AS ZZDRAW_REC,
NULL AS ZZASNIND_SENT,
NULL AS ZZSUBREASON,
NULL AS ZZAEDAT,
NULL AS ZZHOT,
NULL AS KNDBT,
NULL AS ZACTKGWEIGHT,
NULL AS ZDIMKGWEIGHT,
NULL AS ZWEIGHTUSED,
NULL AS GLDELFLAG,
NULL AS GLCHANGETIME,
'1900-01-01'::TIMESTAMP AS PSA_LOAD_DTS,
'N' AS PSA_DELETE_IND,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC,
DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC,
''::BINARY AS HASHDIFF
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
