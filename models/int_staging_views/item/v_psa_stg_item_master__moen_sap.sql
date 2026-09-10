---- SRC LAYER ----
WITH
SRC_S              as ( SELECT  "/BEV1/LULDEGRP",  "/BEV1/LULEINH",  "/BEV1/NESTRUCCAT",  "/DSD/SL_TOLTYP",  "/DSD/SV_CNT_GRP",  "/DSD/VC_GROUP",  "/VSO/R_BOT_IND",  "/VSO/R_KZGVH_IND",  "/VSO/R_NO_P_GVH",  "/VSO/R_PAL_B_HT",  "/VSO/R_PAL_IND",  "/VSO/R_PAL_MIN_H",  "/VSO/R_PAL_OVR_D",  "/VSO/R_PAL_OVR_W",  "/VSO/R_QUAN_UNIT",  "/VSO/R_STACK_IND",  "/VSO/R_STACK_NO",  "/VSO/R_TILT_IND",  "/VSO/R_TOL_B_HT",  "/VSO/R_TOP_IND", ADPROF, ADSPC_SPC, AEKLK, AENAM, AESZN, ALLOW_PMAT_IGNO, ANIMAL_ORIGIN, ANP, ATTYP, BBTYP, BEGRU, BEHVO, BFLME, BISMT, BLANZ, BLATT, BMATN, BRAND_ID, BREIT, BRGEW, BSTAT, BSTME, BWSCL, BWVOR, CADKZ, CARE_CODE, CMETH, CMREL, COLOR, COLOR_ATINN, COMMODITY, COMPL, CUOBF, CWQPROC, CWQREL, CWQTOLGR, DATAB, DG_PACK_STATUS, DISST, EAN11, EANNR, EKWSL, ENTAR, ERGEI, ERGEW, ERNAM, ERSDA, ERVOE, ERVOL, ETIAG, ETIAR, ETIFO, EXTWG, FASHGRD, FERTH, FIBER_CODE1, FIBER_CODE2, FIBER_CODE3, FIBER_CODE4, FIBER_CODE5, FIBER_PART1, FIBER_PART2, FIBER_PART3, FIBER_PART4, FIBER_PART5, FORMT, FREE_CHAR, FSH_MG_AT1, FSH_MG_AT2, FSH_MG_AT3, FSH_SC_MID, FSH_SEAIM, FSH_SEALV, FUELG, GDS_RELEVANT, GENNR, GEWEI, GEWTO, GLCHANGETIME, GLDELFLAG, GLREQUEST, GLSOURCESYSTEM, GROES, GTIN_VARIANT, HAZMAT, HERKL, HNDLCODE, HOEHE, HUTYP, HUTYP_DFLT, IHIVI, ILOOS, IMATN, INHAL, INHBR, INHME, IPMIPPRODUCT, IPRKZ, KOSCH, KUNNR, KZEFF, KZGVH, KZKFG, KZKUP, KZNFM, KZREV, KZUMW, KZWSM, LABOR, LAEDA, LAENG, LIQDT, LOGLEV_RETO, LOGUNIT, LVORM, MAGRV, MANDT, MATFI, MATKL, MATNR, MAXB, MAXC, MAXC_TOL, MAXDIM_UOM, MAXH, MAXL, MBRSH, MCOND, MEABM, MEDIUM, MEINS, MFRGR, MFRNR, MFRPN, MHDHB, MHDLP, MHDRZ, MLGUT, MPROF, MSTAE, MSTAV, MSTDE, MSTDV, MTART, MTPOS_MARA, NORMT, NRFHG, NSNID, NTGEW, NUMTP, PACKCODE, PICNUM, PILFERABLE, PLGTP, PMATA, PRDHA, PROFL, PRZUS, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, PSM_CODE, PSTAT, PS_SMARTFORM, QGRP, QMPUR, QQTIME, QQTIMEUOM, RAUBE, RBNRM, RDMHD, RETDELC, RMATP, SAISJ, SAISO, SAITY, SATNR, SERIAL, SERLV, SGT_COVSA, SGT_CSGR, SGT_REL, SGT_SCOPE, SGT_STAT, SIZE1, SIZE1_ATINN, SIZE2, SIZE2_ATINN, SLED_BBD, SPART, SPROF, STFAK, STOFF, TAKLV, TARE_VAR, TEMPB, TEXTILE_COMP_IND, TRAGR, VABME, VHART, VOLEH, VOLTO, VOLUM, VPREH, VPSTA, WEORA, WESCH, WHMATGR, WHSTC, WRKST, XCHPF, XGCHP, ZEIAR, ZEIFO, ZEINR, ZEIVR, ZZARCH, ZZARCHDET, ZZBASE_MATNR, ZZBRAND, ZZBUSOWN, ZZBUSOWNINV, ZZBUSUNITOWN, ZZCPF, ZZCRITICAL_SUB, ZZDDT, ZZDEPLOYRULE, ZZDTP, ZZEXC, ZZFCSTP, ZZFCST_BASE, ZZFIN, ZZFIRSTSHIPDATE, ZZHAN, ZZIDT, ZZINVOWNER, ZZINVOWNER_MFG, ZZLEAD_PER, ZZLEGMATNR, ZZLIFECYCLE, ZZLIFOCODE, ZZLIN, ZZMAJ, ZZMARKET, ZZMFG, ZZMG1, ZZMIN, ZZMKG, ZZMKG_FLAG, ZZNOOFHANDLES, ZZOPTYPE, ZZPACKQT, ZZPARTPOPULATION, ZZPENDING_TRANS, ZZPLA, ZZPLG, ZZPLT, ZZPLTG, ZZPLTG_FLAG, ZZPMI, ZZPRL, ZZPRODUCTVITALITY, ZZPROJ, ZZPTG, ZZPTGK, ZZPTK, ZZQCD, ZZQTP, ZZREPCATG, ZZRISK_PRO, ZZRMAREA, ZZROM, ZZSEG, ZZSTOCKSTRATEGY, ZZSTS, ZZSTYLE, ZZTYP, ZZULTS, ZZVALTYPE, ZZWETTED, ZZWHENNEWDATE, ZZWSMEINS, ZZWST, ZZWST1 FROM {{ source('sap_ecc_prd', 'z_mara') }} as SRC  ),
SRC_A              as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S              as ( SELECT * FROM sap_ecc_prd.z_mara )
SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        MATNR                                                        as                                            ITEM_BK
      , MATNR
      , MANDT
      , GLREQUEST
      , GLSOURCESYSTEM
      , ERSDA
      , ERNAM
      , LAEDA
      , AENAM
      , VPSTA
      , PSTAT
      , LVORM
      , MTART
      , MBRSH
      , MATKL
      , BISMT
      , MEINS
      , BSTME
      , ZEINR
      , ZEIAR
      , ZEIVR
      , ZEIFO
      , AESZN
      , BLATT
      , BLANZ
      , FERTH
      , FORMT
      , GROES
      , WRKST
      , NORMT
      , LABOR
      , EKWSL
      , BRGEW
      , NTGEW
      , GEWEI
      , VOLUM
      , VOLEH
      , BEHVO
      , RAUBE
      , TEMPB
      , DISST
      , TRAGR
      , STOFF
      , SPART
      , KUNNR
      , EANNR
      , WESCH
      , BWVOR
      , BWSCL
      , SAISO
      , ETIAR
      , ETIFO
      , ENTAR
      , EAN11
      , NUMTP
      , LAENG
      , BREIT
      , HOEHE
      , MEABM
      , PRDHA
      , AEKLK
      , CADKZ
      , QMPUR
      , ERGEW
      , ERGEI
      , ERVOL
      , ERVOE
      , GEWTO
      , VOLTO
      , VABME
      , KZREV
      , KZKFG
      , XCHPF
      , VHART
      , FUELG
      , STFAK
      , MAGRV
      , BEGRU
      , DATAB
      , LIQDT
      , SAISJ
      , PLGTP
      , MLGUT
      , EXTWG
      , SATNR
      , ATTYP
      , KZKUP
      , KZNFM
      , PMATA
      , MSTAE
      , MSTAV
      , MSTDE
      , MSTDV
      , TAKLV
      , RBNRM
      , MHDRZ
      , MHDHB
      , MHDLP
      , INHME
      , INHAL
      , VPREH
      , ETIAG
      , INHBR
      , CMETH
      , CUOBF
      , KZUMW
      , KOSCH
      , SPROF
      , NRFHG
      , MFRPN
      , MFRNR
      , BMATN
      , MPROF
      , KZWSM
      , SAITY
      , PROFL
      , IHIVI
      , ILOOS
      , SERLV
      , KZGVH
      , XGCHP
      , KZEFF
      , COMPL
      , IPRKZ
      , RDMHD
      , PRZUS
      , MTPOS_MARA
      , BFLME
      , MATFI
      , CMREL
      , BBTYP
      , SLED_BBD
      , GTIN_VARIANT
      , GENNR
      , RMATP
      , GDS_RELEVANT
      , WEORA
      , HUTYP_DFLT
      , PILFERABLE
      , WHSTC
      , WHMATGR
      , HNDLCODE
      , HAZMAT
      , HUTYP
      , TARE_VAR
      , MAXC
      , MAXC_TOL
      , MAXL
      , MAXB
      , MAXH
      , MAXDIM_UOM
      , HERKL
      , MFRGR
      , QQTIME
      , QQTIMEUOM
      , QGRP
      , SERIAL
      , PS_SMARTFORM
      , LOGUNIT
      , CWQREL
      , CWQPROC
      , CWQTOLGR
      , ADPROF
      , IPMIPPRODUCT
      , ALLOW_PMAT_IGNO
      , MEDIUM
      , COMMODITY
      , ANIMAL_ORIGIN
      , TEXTILE_COMP_IND
      , SGT_CSGR
      , SGT_COVSA
      , SGT_STAT
      , SGT_SCOPE
      , SGT_REL
      , FSH_MG_AT1
      , FSH_MG_AT2
      , FSH_MG_AT3
      , FSH_SEALV
      , FSH_SEAIM
      , FSH_SC_MID
      , ANP
      , PSM_CODE
      , "/BEV1/LULEINH"                                             as                                       BEV1_LULEINH
      , "/BEV1/LULDEGRP"                                            as                                      BEV1_LULDEGRP
      , "/BEV1/NESTRUCCAT"                                          as                                    BEV1_NESTRUCCAT
      , "/DSD/SL_TOLTYP"                                            as                                      DSD_SL_TOLTYP
      , "/DSD/SV_CNT_GRP"                                           as                                     DSD_SV_CNT_GRP
      , "/DSD/VC_GROUP"                                             as                                       DSD_VC_GROUP
      , "/VSO/R_TILT_IND"                                           as                                     VSO_R_TILT_IND
      , "/VSO/R_STACK_IND"                                          as                                    VSO_R_STACK_IND
      , "/VSO/R_BOT_IND"                                            as                                      VSO_R_BOT_IND
      , "/VSO/R_TOP_IND"                                            as                                      VSO_R_TOP_IND
      , "/VSO/R_STACK_NO"                                           as                                     VSO_R_STACK_NO
      , "/VSO/R_PAL_IND"                                            as                                      VSO_R_PAL_IND
      , "/VSO/R_PAL_OVR_D"                                          as                                    VSO_R_PAL_OVR_D
      , "/VSO/R_PAL_OVR_W"                                          as                                    VSO_R_PAL_OVR_W
      , "/VSO/R_PAL_B_HT"                                           as                                     VSO_R_PAL_B_HT
      , "/VSO/R_PAL_MIN_H"                                          as                                    VSO_R_PAL_MIN_H
      , "/VSO/R_TOL_B_HT"                                           as                                     VSO_R_TOL_B_HT
      , "/VSO/R_NO_P_GVH"                                           as                                     VSO_R_NO_P_GVH
      , "/VSO/R_QUAN_UNIT"                                          as                                    VSO_R_QUAN_UNIT
      , "/VSO/R_KZGVH_IND"                                          as                                    VSO_R_KZGVH_IND
      , PACKCODE
      , DG_PACK_STATUS
      , MCOND
      , RETDELC
      , LOGLEV_RETO
      , NSNID
      , ADSPC_SPC
      , IMATN
      , PICNUM
      , BSTAT
      , COLOR_ATINN
      , SIZE1_ATINN
      , SIZE2_ATINN
      , COLOR
      , SIZE1
      , SIZE2
      , FREE_CHAR
      , CARE_CODE
      , BRAND_ID
      , FIBER_CODE1
      , FIBER_PART1
      , FIBER_CODE2
      , FIBER_PART2
      , FIBER_CODE3
      , FIBER_PART3
      , FIBER_CODE4
      , FIBER_PART4
      , FIBER_CODE5
      , FIBER_PART5
      , FASHGRD
      , ZZTYP
      , ZZSEG
      , ZZLIN
      , ZZDTP
      , ZZFIN
      , ZZHAN
      , ZZMAJ
      , ZZMIN
      , ZZPMI
      , ZZIDT
      , ZZMG1
      , ZZROM
      , ZZWST
      , ZZWST1
      , ZZSTS
      , ZZDDT
      , ZZQTP
      , ZZQCD
      , ZZLIFOCODE
      , ZZEXC
      , ZZPLG
      , ZZMFG
      , ZZPROJ
      , ZZPLA
      , ZZINVOWNER
      , ZZINVOWNER_MFG
      , ZZCPF
      , ZZFIRSTSHIPDATE
      , ZZBUSOWN
      , ZZBUSOWNINV
      , ZZFCSTP
      , ZZULTS
      , ZZDEPLOYRULE
      , ZZPARTPOPULATION
      , ZZLIFECYCLE
      , ZZPENDING_TRANS
      , ZZRISK_PRO
      , ZZFCST_BASE
      , ZZWETTED
      , ZZWSMEINS
      , ZZLEAD_PER
      , ZZBASE_MATNR
      , ZZPRL
      , ZZBUSUNITOWN
      , ZZCRITICAL_SUB
      , ZZBRAND
      , ZZMARKET
      , ZZPTG
      , ZZMKG
      , ZZPLTG
      , ZZPLT
      , ZZPTGK
      , ZZPTK
      , ZZRMAREA
      , ZZPACKQT
      , ZZOPTYPE
      , ZZVALTYPE
      , ZZMKG_FLAG
      , ZZPLTG_FLAG
      , ZZSTOCKSTRATEGY
      , ZZNOOFHANDLES
      , ZZARCH
      , ZZARCHDET
      , ZZSTYLE
      , ZZLEGMATNR
      , ZZPRODUCTVITALITY
      , ZZWHENNEWDATE
      , ZZREPCATG
      , GLDELFLAG
      , GLCHANGETIME
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , CONVERT_TIMEZONE('UTC', TO_TIMESTAMP(
            SUBSTR(GLCHANGETIME, 1, 8) || ' ' ||
            SUBSTR(GLCHANGETIME, 9, 2) || ':' ||
            SUBSTR(GLCHANGETIME, 11, 2) || ':' ||
            SUBSTR(GLCHANGETIME, 13, 2) || '.' ||
            REGEXP_REPLACE(SUBSTR(GLCHANGETIME, 16), '^\\.', ''),
            'YYYYMMDD HH24:MI:SS.FF9'
        ))                                                           as                                           LOAD_DTS
      , COALESCE(NULLIF(UPPER(TRIM(ZZBASE_MATNR)),''),'-2')          as                                   BASE_MATERIAL_BK
      , COALESCE(NULLIF(UPPER(TRIM(SPART)),''),'-2')                 as                                        DIVISION_BK
    FROM SRC_S
)

, LOGIC_A as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_A
)
---- RENAME LAYER ----

, RENAME_S as (
    SELECT
        ITEM_BK
      , MATNR
      , MANDT
      , GLREQUEST
      , GLSOURCESYSTEM
      , ERSDA
      , ERNAM
      , LAEDA
      , AENAM
      , VPSTA
      , PSTAT
      , LVORM
      , MTART
      , MBRSH
      , MATKL
      , BISMT
      , MEINS
      , BSTME
      , ZEINR
      , ZEIAR
      , ZEIVR
      , ZEIFO
      , AESZN
      , BLATT
      , BLANZ
      , FERTH
      , FORMT
      , GROES
      , WRKST
      , NORMT
      , LABOR
      , EKWSL
      , BRGEW
      , NTGEW
      , GEWEI
      , VOLUM
      , VOLEH
      , BEHVO
      , RAUBE
      , TEMPB
      , DISST
      , TRAGR
      , STOFF
      , SPART
      , KUNNR
      , EANNR
      , WESCH
      , BWVOR
      , BWSCL
      , SAISO
      , ETIAR
      , ETIFO
      , ENTAR
      , EAN11
      , NUMTP
      , LAENG
      , BREIT
      , HOEHE
      , MEABM
      , PRDHA
      , AEKLK
      , CADKZ
      , QMPUR
      , ERGEW
      , ERGEI
      , ERVOL
      , ERVOE
      , GEWTO
      , VOLTO
      , VABME
      , KZREV
      , KZKFG
      , XCHPF
      , VHART
      , FUELG
      , STFAK
      , MAGRV
      , BEGRU
      , DATAB
      , LIQDT
      , SAISJ
      , PLGTP
      , MLGUT
      , EXTWG
      , SATNR
      , ATTYP
      , KZKUP
      , KZNFM
      , PMATA
      , MSTAE
      , MSTAV
      , MSTDE
      , MSTDV
      , TAKLV
      , RBNRM
      , MHDRZ
      , MHDHB
      , MHDLP
      , INHME
      , INHAL
      , VPREH
      , ETIAG
      , INHBR
      , CMETH
      , CUOBF
      , KZUMW
      , KOSCH
      , SPROF
      , NRFHG
      , MFRPN
      , MFRNR
      , BMATN
      , MPROF
      , KZWSM
      , SAITY
      , PROFL
      , IHIVI
      , ILOOS
      , SERLV
      , KZGVH
      , XGCHP
      , KZEFF
      , COMPL
      , IPRKZ
      , RDMHD
      , PRZUS
      , MTPOS_MARA
      , BFLME
      , MATFI
      , CMREL
      , BBTYP
      , SLED_BBD
      , GTIN_VARIANT
      , GENNR
      , RMATP
      , GDS_RELEVANT
      , WEORA
      , HUTYP_DFLT
      , PILFERABLE
      , WHSTC
      , WHMATGR
      , HNDLCODE
      , HAZMAT
      , HUTYP
      , TARE_VAR
      , MAXC
      , MAXC_TOL
      , MAXL
      , MAXB
      , MAXH
      , MAXDIM_UOM
      , HERKL
      , MFRGR
      , QQTIME
      , QQTIMEUOM
      , QGRP
      , SERIAL
      , PS_SMARTFORM
      , LOGUNIT
      , CWQREL
      , CWQPROC
      , CWQTOLGR
      , ADPROF
      , IPMIPPRODUCT
      , ALLOW_PMAT_IGNO
      , MEDIUM
      , COMMODITY
      , ANIMAL_ORIGIN
      , TEXTILE_COMP_IND
      , SGT_CSGR
      , SGT_COVSA
      , SGT_STAT
      , SGT_SCOPE
      , SGT_REL
      , FSH_MG_AT1
      , FSH_MG_AT2
      , FSH_MG_AT3
      , FSH_SEALV
      , FSH_SEAIM
      , FSH_SC_MID
      , ANP
      , PSM_CODE
      , BEV1_LULEINH
      , BEV1_LULDEGRP
      , BEV1_NESTRUCCAT
      , DSD_SL_TOLTYP
      , DSD_SV_CNT_GRP
      , DSD_VC_GROUP
      , VSO_R_TILT_IND
      , VSO_R_STACK_IND
      , VSO_R_BOT_IND
      , VSO_R_TOP_IND
      , VSO_R_STACK_NO
      , VSO_R_PAL_IND
      , VSO_R_PAL_OVR_D
      , VSO_R_PAL_OVR_W
      , VSO_R_PAL_B_HT
      , VSO_R_PAL_MIN_H
      , VSO_R_TOL_B_HT
      , VSO_R_NO_P_GVH
      , VSO_R_QUAN_UNIT
      , VSO_R_KZGVH_IND
      , PACKCODE
      , DG_PACK_STATUS
      , MCOND
      , RETDELC
      , LOGLEV_RETO
      , NSNID
      , ADSPC_SPC
      , IMATN
      , PICNUM
      , BSTAT
      , COLOR_ATINN
      , SIZE1_ATINN
      , SIZE2_ATINN
      , COLOR
      , SIZE1
      , SIZE2
      , FREE_CHAR
      , CARE_CODE
      , BRAND_ID
      , FIBER_CODE1
      , FIBER_PART1
      , FIBER_CODE2
      , FIBER_PART2
      , FIBER_CODE3
      , FIBER_PART3
      , FIBER_CODE4
      , FIBER_PART4
      , FIBER_CODE5
      , FIBER_PART5
      , FASHGRD
      , ZZTYP
      , ZZSEG
      , ZZLIN
      , ZZDTP
      , ZZFIN
      , ZZHAN
      , ZZMAJ
      , ZZMIN
      , ZZPMI
      , ZZIDT
      , ZZMG1
      , ZZROM
      , ZZWST
      , ZZWST1
      , ZZSTS
      , ZZDDT
      , ZZQTP
      , ZZQCD
      , ZZLIFOCODE
      , ZZEXC
      , ZZPLG
      , ZZMFG
      , ZZPROJ
      , ZZPLA
      , ZZINVOWNER
      , ZZINVOWNER_MFG
      , ZZCPF
      , ZZFIRSTSHIPDATE
      , ZZBUSOWN
      , ZZBUSOWNINV
      , ZZFCSTP
      , ZZULTS
      , ZZDEPLOYRULE
      , ZZPARTPOPULATION
      , ZZLIFECYCLE
      , ZZPENDING_TRANS
      , ZZRISK_PRO
      , ZZFCST_BASE
      , ZZWETTED
      , ZZWSMEINS
      , ZZLEAD_PER
      , ZZBASE_MATNR
      , ZZPRL
      , ZZBUSUNITOWN
      , ZZCRITICAL_SUB
      , ZZBRAND
      , ZZMARKET
      , ZZPTG
      , ZZMKG
      , ZZPLTG
      , ZZPLT
      , ZZPTGK
      , ZZPTK
      , ZZRMAREA
      , ZZPACKQT
      , ZZOPTYPE
      , ZZVALTYPE
      , ZZMKG_FLAG
      , ZZPLTG_FLAG
      , ZZSTOCKSTRATEGY
      , ZZNOOFHANDLES
      , ZZARCH
      , ZZARCHDET
      , ZZSTYLE
      , ZZLEGMATNR
      , ZZPRODUCTVITALITY
      , ZZWHENNEWDATE
      , ZZREPCATG
      , GLDELFLAG
      , GLCHANGETIME
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , LOAD_DTS
      , BASE_MATERIAL_BK
      , DIVISION_BK
    FROM LOGIC_S
)

, RENAME_A as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_A
)
---- FILTER LAYER ----

, FILTER_S as (
    SELECT *
    FROM RENAME_S
)

, FILTER_A as (
    SELECT *
    FROM RENAME_A
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_MARA'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_S
    INNER JOIN FILTER_A
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          ITEM_BK
        , MATNR
        , MANDT
        , GLREQUEST
        , GLSOURCESYSTEM
        , ERSDA
        , ERNAM
        , LAEDA
        , AENAM
        , VPSTA
        , PSTAT
        , LVORM
        , MTART
        , MBRSH
        , MATKL
        , BISMT
        , MEINS
        , BSTME
        , ZEINR
        , ZEIAR
        , ZEIVR
        , ZEIFO
        , AESZN
        , BLATT
        , BLANZ
        , FERTH
        , FORMT
        , GROES
        , WRKST
        , NORMT
        , LABOR
        , EKWSL
        , BRGEW
        , NTGEW
        , GEWEI
        , VOLUM
        , VOLEH
        , BEHVO
        , RAUBE
        , TEMPB
        , DISST
        , TRAGR
        , STOFF
        , SPART
        , KUNNR
        , EANNR
        , WESCH
        , BWVOR
        , BWSCL
        , SAISO
        , ETIAR
        , ETIFO
        , ENTAR
        , EAN11
        , NUMTP
        , LAENG
        , BREIT
        , HOEHE
        , MEABM
        , PRDHA
        , AEKLK
        , CADKZ
        , QMPUR
        , ERGEW
        , ERGEI
        , ERVOL
        , ERVOE
        , GEWTO
        , VOLTO
        , VABME
        , KZREV
        , KZKFG
        , XCHPF
        , VHART
        , FUELG
        , STFAK
        , MAGRV
        , BEGRU
        , DATAB
        , LIQDT
        , SAISJ
        , PLGTP
        , MLGUT
        , EXTWG
        , SATNR
        , ATTYP
        , KZKUP
        , KZNFM
        , PMATA
        , MSTAE
        , MSTAV
        , MSTDE
        , MSTDV
        , TAKLV
        , RBNRM
        , MHDRZ
        , MHDHB
        , MHDLP
        , INHME
        , INHAL
        , VPREH
        , ETIAG
        , INHBR
        , CMETH
        , CUOBF
        , KZUMW
        , KOSCH
        , SPROF
        , NRFHG
        , MFRPN
        , MFRNR
        , BMATN
        , MPROF
        , KZWSM
        , SAITY
        , PROFL
        , IHIVI
        , ILOOS
        , SERLV
        , KZGVH
        , XGCHP
        , KZEFF
        , COMPL
        , IPRKZ
        , RDMHD
        , PRZUS
        , MTPOS_MARA
        , BFLME
        , MATFI
        , CMREL
        , BBTYP
        , SLED_BBD
        , GTIN_VARIANT
        , GENNR
        , RMATP
        , GDS_RELEVANT
        , WEORA
        , HUTYP_DFLT
        , PILFERABLE
        , WHSTC
        , WHMATGR
        , HNDLCODE
        , HAZMAT
        , HUTYP
        , TARE_VAR
        , MAXC
        , MAXC_TOL
        , MAXL
        , MAXB
        , MAXH
        , MAXDIM_UOM
        , HERKL
        , MFRGR
        , QQTIME
        , QQTIMEUOM
        , QGRP
        , SERIAL
        , PS_SMARTFORM
        , LOGUNIT
        , CWQREL
        , CWQPROC
        , CWQTOLGR
        , ADPROF
        , IPMIPPRODUCT
        , ALLOW_PMAT_IGNO
        , MEDIUM
        , COMMODITY
        , ANIMAL_ORIGIN
        , TEXTILE_COMP_IND
        , SGT_CSGR
        , SGT_COVSA
        , SGT_STAT
        , SGT_SCOPE
        , SGT_REL
        , FSH_MG_AT1
        , FSH_MG_AT2
        , FSH_MG_AT3
        , FSH_SEALV
        , FSH_SEAIM
        , FSH_SC_MID
        , ANP
        , PSM_CODE
        , BEV1_LULEINH
        , BEV1_LULDEGRP
        , BEV1_NESTRUCCAT
        , DSD_SL_TOLTYP
        , DSD_SV_CNT_GRP
        , DSD_VC_GROUP
        , VSO_R_TILT_IND
        , VSO_R_STACK_IND
        , VSO_R_BOT_IND
        , VSO_R_TOP_IND
        , VSO_R_STACK_NO
        , VSO_R_PAL_IND
        , VSO_R_PAL_OVR_D
        , VSO_R_PAL_OVR_W
        , VSO_R_PAL_B_HT
        , VSO_R_PAL_MIN_H
        , VSO_R_TOL_B_HT
        , VSO_R_NO_P_GVH
        , VSO_R_QUAN_UNIT
        , VSO_R_KZGVH_IND
        , PACKCODE
        , DG_PACK_STATUS
        , MCOND
        , RETDELC
        , LOGLEV_RETO
        , NSNID
        , ADSPC_SPC
        , IMATN
        , PICNUM
        , BSTAT
        , COLOR_ATINN
        , SIZE1_ATINN
        , SIZE2_ATINN
        , COLOR
        , SIZE1
        , SIZE2
        , FREE_CHAR
        , CARE_CODE
        , BRAND_ID
        , FIBER_CODE1
        , FIBER_PART1
        , FIBER_CODE2
        , FIBER_PART2
        , FIBER_CODE3
        , FIBER_PART3
        , FIBER_CODE4
        , FIBER_PART4
        , FIBER_CODE5
        , FIBER_PART5
        , FASHGRD
        , ZZTYP
        , ZZSEG
        , ZZLIN
        , ZZDTP
        , ZZFIN
        , ZZHAN
        , ZZMAJ
        , ZZMIN
        , ZZPMI
        , ZZIDT
        , ZZMG1
        , ZZROM
        , ZZWST
        , ZZWST1
        , ZZSTS
        , ZZDDT
        , ZZQTP
        , ZZQCD
        , ZZLIFOCODE
        , ZZEXC
        , ZZPLG
        , ZZMFG
        , ZZPROJ
        , ZZPLA
        , ZZINVOWNER
        , ZZINVOWNER_MFG
        , ZZCPF
        , ZZFIRSTSHIPDATE
        , ZZBUSOWN
        , ZZBUSOWNINV
        , ZZFCSTP
        , ZZULTS
        , ZZDEPLOYRULE
        , ZZPARTPOPULATION
        , ZZLIFECYCLE
        , ZZPENDING_TRANS
        , ZZRISK_PRO
        , ZZFCST_BASE
        , ZZWETTED
        , ZZWSMEINS
        , ZZLEAD_PER
        , ZZBASE_MATNR
        , ZZPRL
        , ZZBUSUNITOWN
        , ZZCRITICAL_SUB
        , ZZBRAND
        , ZZMARKET
        , ZZPTG
        , ZZMKG
        , ZZPLTG
        , ZZPLT
        , ZZPTGK
        , ZZPTK
        , ZZRMAREA
        , ZZPACKQT
        , ZZOPTYPE
        , ZZVALTYPE
        , ZZMKG_FLAG
        , ZZPLTG_FLAG
        , ZZSTOCKSTRATEGY
        , ZZNOOFHANDLES
        , ZZARCH
        , ZZARCHDET
        , ZZSTYLE
        , ZZLEGMATNR
        , ZZPRODUCTVITALITY
        , ZZWHENNEWDATE
        , ZZREPCATG
        , GLDELFLAG
        , GLCHANGETIME
        , PSA_DELETE_IND
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , LOAD_DTS
        , REC_SRC
        , BKCC
        ,  '-2'                                                        as PLANT_BK
        , BASE_MATERIAL_BK
        , DIVISION_BK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ITEM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ITEM_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PLANT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PLANT_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ITEM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(PLANT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PLANT_ITEM_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(BASE_MATERIAL_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as BASE_MATERIAL_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(DIVISION_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as DIVISION_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ITEM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BASE_MATERIAL_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(DIVISION_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as LNK_ITEM_BASE_MATERIAL_DIVISION_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(MANDT::text), '^^') 
            , '||', IFNULL(TRIM(GLSOURCESYSTEM::text), '^^') 
            , '||', IFNULL(TRIM(ERSDA::text), '^^') 
            , '||', IFNULL(TRIM(ERNAM::text), '^^') 
            , '||', IFNULL(TRIM(LAEDA::text), '^^') 
            , '||', IFNULL(TRIM(AENAM::text), '^^') 
            , '||', IFNULL(TRIM(VPSTA::text), '^^') 
            , '||', IFNULL(TRIM(PSTAT::text), '^^') 
            , '||', IFNULL(TRIM(LVORM::text), '^^') 
            , '||', IFNULL(TRIM(MTART::text), '^^') 
            , '||', IFNULL(TRIM(MBRSH::text), '^^') 
            , '||', IFNULL(TRIM(MATKL::text), '^^') 
            , '||', IFNULL(TRIM(BISMT::text), '^^') 
            , '||', IFNULL(TRIM(MEINS::text), '^^') 
            , '||', IFNULL(TRIM(BSTME::text), '^^') 
            , '||', IFNULL(TRIM(ZEINR::text), '^^') 
            , '||', IFNULL(TRIM(ZEIAR::text), '^^') 
            , '||', IFNULL(TRIM(ZEIVR::text), '^^') 
            , '||', IFNULL(TRIM(ZEIFO::text), '^^') 
            , '||', IFNULL(TRIM(AESZN::text), '^^') 
            , '||', IFNULL(TRIM(BLATT::text), '^^') 
            , '||', IFNULL(TRIM(BLANZ::text), '^^') 
            , '||', IFNULL(TRIM(FERTH::text), '^^') 
            , '||', IFNULL(TRIM(FORMT::text), '^^') 
            , '||', IFNULL(TRIM(GROES::text), '^^') 
            , '||', IFNULL(TRIM(WRKST::text), '^^') 
            , '||', IFNULL(TRIM(NORMT::text), '^^') 
            , '||', IFNULL(TRIM(LABOR::text), '^^') 
            , '||', IFNULL(TRIM(EKWSL::text), '^^') 
            , '||', IFNULL(TRIM(BRGEW::text), '^^') 
            , '||', IFNULL(TRIM(NTGEW::text), '^^') 
            , '||', IFNULL(TRIM(GEWEI::text), '^^') 
            , '||', IFNULL(TRIM(VOLUM::text), '^^') 
            , '||', IFNULL(TRIM(VOLEH::text), '^^') 
            , '||', IFNULL(TRIM(BEHVO::text), '^^') 
            , '||', IFNULL(TRIM(RAUBE::text), '^^') 
            , '||', IFNULL(TRIM(TEMPB::text), '^^') 
            , '||', IFNULL(TRIM(DISST::text), '^^') 
            , '||', IFNULL(TRIM(TRAGR::text), '^^') 
            , '||', IFNULL(TRIM(STOFF::text), '^^') 
            , '||', IFNULL(TRIM(SPART::text), '^^') 
            , '||', IFNULL(TRIM(KUNNR::text), '^^') 
            , '||', IFNULL(TRIM(EANNR::text), '^^') 
            , '||', IFNULL(TRIM(WESCH::text), '^^') 
            , '||', IFNULL(TRIM(BWVOR::text), '^^') 
            , '||', IFNULL(TRIM(BWSCL::text), '^^') 
            , '||', IFNULL(TRIM(SAISO::text), '^^') 
            , '||', IFNULL(TRIM(ETIAR::text), '^^') 
            , '||', IFNULL(TRIM(ETIFO::text), '^^') 
            , '||', IFNULL(TRIM(ENTAR::text), '^^') 
            , '||', IFNULL(TRIM(EAN11::text), '^^') 
            , '||', IFNULL(TRIM(NUMTP::text), '^^') 
            , '||', IFNULL(TRIM(LAENG::text), '^^') 
            , '||', IFNULL(TRIM(BREIT::text), '^^') 
            , '||', IFNULL(TRIM(HOEHE::text), '^^') 
            , '||', IFNULL(TRIM(MEABM::text), '^^') 
            , '||', IFNULL(TRIM(PRDHA::text), '^^') 
            , '||', IFNULL(TRIM(AEKLK::text), '^^') 
            , '||', IFNULL(TRIM(CADKZ::text), '^^') 
            , '||', IFNULL(TRIM(QMPUR::text), '^^') 
            , '||', IFNULL(TRIM(ERGEW::text), '^^') 
            , '||', IFNULL(TRIM(ERGEI::text), '^^') 
            , '||', IFNULL(TRIM(ERVOL::text), '^^') 
            , '||', IFNULL(TRIM(ERVOE::text), '^^') 
            , '||', IFNULL(TRIM(GEWTO::text), '^^') 
            , '||', IFNULL(TRIM(VOLTO::text), '^^') 
            , '||', IFNULL(TRIM(VABME::text), '^^') 
            , '||', IFNULL(TRIM(KZREV::text), '^^') 
            , '||', IFNULL(TRIM(KZKFG::text), '^^') 
            , '||', IFNULL(TRIM(XCHPF::text), '^^') 
            , '||', IFNULL(TRIM(VHART::text), '^^') 
            , '||', IFNULL(TRIM(FUELG::text), '^^') 
            , '||', IFNULL(TRIM(STFAK::text), '^^') 
            , '||', IFNULL(TRIM(MAGRV::text), '^^') 
            , '||', IFNULL(TRIM(BEGRU::text), '^^') 
            , '||', IFNULL(TRIM(DATAB::text), '^^') 
            , '||', IFNULL(TRIM(LIQDT::text), '^^') 
            , '||', IFNULL(TRIM(SAISJ::text), '^^') 
            , '||', IFNULL(TRIM(PLGTP::text), '^^') 
            , '||', IFNULL(TRIM(MLGUT::text), '^^') 
            , '||', IFNULL(TRIM(EXTWG::text), '^^') 
            , '||', IFNULL(TRIM(SATNR::text), '^^') 
            , '||', IFNULL(TRIM(ATTYP::text), '^^') 
            , '||', IFNULL(TRIM(KZKUP::text), '^^') 
            , '||', IFNULL(TRIM(KZNFM::text), '^^') 
            , '||', IFNULL(TRIM(PMATA::text), '^^') 
            , '||', IFNULL(TRIM(MSTAE::text), '^^') 
            , '||', IFNULL(TRIM(MSTAV::text), '^^') 
            , '||', IFNULL(TRIM(MSTDE::text), '^^') 
            , '||', IFNULL(TRIM(MSTDV::text), '^^') 
            , '||', IFNULL(TRIM(TAKLV::text), '^^') 
            , '||', IFNULL(TRIM(RBNRM::text), '^^') 
            , '||', IFNULL(TRIM(MHDRZ::text), '^^') 
            , '||', IFNULL(TRIM(MHDHB::text), '^^') 
            , '||', IFNULL(TRIM(MHDLP::text), '^^') 
            , '||', IFNULL(TRIM(INHME::text), '^^') 
            , '||', IFNULL(TRIM(INHAL::text), '^^') 
            , '||', IFNULL(TRIM(VPREH::text), '^^') 
            , '||', IFNULL(TRIM(ETIAG::text), '^^') 
            , '||', IFNULL(TRIM(INHBR::text), '^^') 
            , '||', IFNULL(TRIM(CMETH::text), '^^') 
            , '||', IFNULL(TRIM(CUOBF::text), '^^') 
            , '||', IFNULL(TRIM(KZUMW::text), '^^') 
            , '||', IFNULL(TRIM(KOSCH::text), '^^') 
            , '||', IFNULL(TRIM(SPROF::text), '^^') 
            , '||', IFNULL(TRIM(NRFHG::text), '^^') 
            , '||', IFNULL(TRIM(MFRPN::text), '^^') 
            , '||', IFNULL(TRIM(MFRNR::text), '^^') 
            , '||', IFNULL(TRIM(BMATN::text), '^^') 
            , '||', IFNULL(TRIM(MPROF::text), '^^') 
            , '||', IFNULL(TRIM(KZWSM::text), '^^') 
            , '||', IFNULL(TRIM(SAITY::text), '^^') 
            , '||', IFNULL(TRIM(PROFL::text), '^^') 
            , '||', IFNULL(TRIM(IHIVI::text), '^^') 
            , '||', IFNULL(TRIM(ILOOS::text), '^^') 
            , '||', IFNULL(TRIM(SERLV::text), '^^') 
            , '||', IFNULL(TRIM(KZGVH::text), '^^') 
            , '||', IFNULL(TRIM(XGCHP::text), '^^') 
            , '||', IFNULL(TRIM(KZEFF::text), '^^') 
            , '||', IFNULL(TRIM(COMPL::text), '^^') 
            , '||', IFNULL(TRIM(IPRKZ::text), '^^') 
            , '||', IFNULL(TRIM(RDMHD::text), '^^') 
            , '||', IFNULL(TRIM(PRZUS::text), '^^') 
            , '||', IFNULL(TRIM(MTPOS_MARA::text), '^^') 
            , '||', IFNULL(TRIM(BFLME::text), '^^') 
            , '||', IFNULL(TRIM(MATFI::text), '^^') 
            , '||', IFNULL(TRIM(CMREL::text), '^^') 
            , '||', IFNULL(TRIM(BBTYP::text), '^^') 
            , '||', IFNULL(TRIM(SLED_BBD::text), '^^') 
            , '||', IFNULL(TRIM(GTIN_VARIANT::text), '^^') 
            , '||', IFNULL(TRIM(GENNR::text), '^^') 
            , '||', IFNULL(TRIM(RMATP::text), '^^') 
            , '||', IFNULL(TRIM(GDS_RELEVANT::text), '^^') 
            , '||', IFNULL(TRIM(WEORA::text), '^^') 
            , '||', IFNULL(TRIM(HUTYP_DFLT::text), '^^') 
            , '||', IFNULL(TRIM(PILFERABLE::text), '^^') 
            , '||', IFNULL(TRIM(WHSTC::text), '^^') 
            , '||', IFNULL(TRIM(WHMATGR::text), '^^') 
            , '||', IFNULL(TRIM(HNDLCODE::text), '^^') 
            , '||', IFNULL(TRIM(HAZMAT::text), '^^') 
            , '||', IFNULL(TRIM(HUTYP::text), '^^') 
            , '||', IFNULL(TRIM(TARE_VAR::text), '^^') 
            , '||', IFNULL(TRIM(MAXC::text), '^^') 
            , '||', IFNULL(TRIM(MAXC_TOL::text), '^^') 
            , '||', IFNULL(TRIM(MAXL::text), '^^') 
            , '||', IFNULL(TRIM(MAXB::text), '^^') 
            , '||', IFNULL(TRIM(MAXH::text), '^^') 
            , '||', IFNULL(TRIM(MAXDIM_UOM::text), '^^') 
            , '||', IFNULL(TRIM(HERKL::text), '^^') 
            , '||', IFNULL(TRIM(MFRGR::text), '^^') 
            , '||', IFNULL(TRIM(QQTIME::text), '^^') 
            , '||', IFNULL(TRIM(QQTIMEUOM::text), '^^') 
            , '||', IFNULL(TRIM(QGRP::text), '^^') 
            , '||', IFNULL(TRIM(SERIAL::text), '^^') 
            , '||', IFNULL(TRIM(PS_SMARTFORM::text), '^^') 
            , '||', IFNULL(TRIM(LOGUNIT::text), '^^') 
            , '||', IFNULL(TRIM(CWQREL::text), '^^') 
            , '||', IFNULL(TRIM(CWQPROC::text), '^^') 
            , '||', IFNULL(TRIM(CWQTOLGR::text), '^^') 
            , '||', IFNULL(TRIM(ADPROF::text), '^^') 
            , '||', IFNULL(TRIM(IPMIPPRODUCT::text), '^^') 
            , '||', IFNULL(TRIM(ALLOW_PMAT_IGNO::text), '^^') 
            , '||', IFNULL(TRIM(MEDIUM::text), '^^') 
            , '||', IFNULL(TRIM(COMMODITY::text), '^^') 
            , '||', IFNULL(TRIM(ANIMAL_ORIGIN::text), '^^') 
            , '||', IFNULL(TRIM(TEXTILE_COMP_IND::text), '^^') 
            , '||', IFNULL(TRIM(SGT_CSGR::text), '^^') 
            , '||', IFNULL(TRIM(SGT_COVSA::text), '^^') 
            , '||', IFNULL(TRIM(SGT_STAT::text), '^^') 
            , '||', IFNULL(TRIM(SGT_SCOPE::text), '^^') 
            , '||', IFNULL(TRIM(SGT_REL::text), '^^') 
            , '||', IFNULL(TRIM(FSH_MG_AT1::text), '^^') 
            , '||', IFNULL(TRIM(FSH_MG_AT2::text), '^^') 
            , '||', IFNULL(TRIM(FSH_MG_AT3::text), '^^') 
            , '||', IFNULL(TRIM(FSH_SEALV::text), '^^') 
            , '||', IFNULL(TRIM(FSH_SEAIM::text), '^^') 
            , '||', IFNULL(TRIM(FSH_SC_MID::text), '^^') 
            , '||', IFNULL(TRIM(ANP::text), '^^') 
            , '||', IFNULL(TRIM(PSM_CODE::text), '^^') 
            , '||', IFNULL(TRIM(BEV1_LULEINH::text), '^^') 
            , '||', IFNULL(TRIM(BEV1_LULDEGRP::text), '^^') 
            , '||', IFNULL(TRIM(BEV1_NESTRUCCAT::text), '^^') 
            , '||', IFNULL(TRIM(DSD_SL_TOLTYP::text), '^^') 
            , '||', IFNULL(TRIM(DSD_SV_CNT_GRP::text), '^^') 
            , '||', IFNULL(TRIM(DSD_VC_GROUP::text), '^^') 
            , '||', IFNULL(TRIM(VSO_R_TILT_IND::text), '^^') 
            , '||', IFNULL(TRIM(VSO_R_STACK_IND::text), '^^') 
            , '||', IFNULL(TRIM(VSO_R_BOT_IND::text), '^^') 
            , '||', IFNULL(TRIM(VSO_R_TOP_IND::text), '^^') 
            , '||', IFNULL(TRIM(VSO_R_STACK_NO::text), '^^') 
            , '||', IFNULL(TRIM(VSO_R_PAL_IND::text), '^^') 
            , '||', IFNULL(TRIM(VSO_R_PAL_OVR_D::text), '^^') 
            , '||', IFNULL(TRIM(VSO_R_PAL_OVR_W::text), '^^') 
            , '||', IFNULL(TRIM(VSO_R_PAL_B_HT::text), '^^') 
            , '||', IFNULL(TRIM(VSO_R_PAL_MIN_H::text), '^^') 
            , '||', IFNULL(TRIM(VSO_R_TOL_B_HT::text), '^^') 
            , '||', IFNULL(TRIM(VSO_R_NO_P_GVH::text), '^^') 
            , '||', IFNULL(TRIM(VSO_R_QUAN_UNIT::text), '^^') 
            , '||', IFNULL(TRIM(VSO_R_KZGVH_IND::text), '^^') 
            , '||', IFNULL(TRIM(PACKCODE::text), '^^') 
            , '||', IFNULL(TRIM(DG_PACK_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(MCOND::text), '^^') 
            , '||', IFNULL(TRIM(RETDELC::text), '^^') 
            , '||', IFNULL(TRIM(LOGLEV_RETO::text), '^^') 
            , '||', IFNULL(TRIM(NSNID::text), '^^') 
            , '||', IFNULL(TRIM(ADSPC_SPC::text), '^^') 
            , '||', IFNULL(TRIM(IMATN::text), '^^') 
            , '||', IFNULL(TRIM(PICNUM::text), '^^') 
            , '||', IFNULL(TRIM(BSTAT::text), '^^') 
            , '||', IFNULL(TRIM(COLOR_ATINN::text), '^^') 
            , '||', IFNULL(TRIM(SIZE1_ATINN::text), '^^') 
            , '||', IFNULL(TRIM(SIZE2_ATINN::text), '^^') 
            , '||', IFNULL(TRIM(COLOR::text), '^^') 
            , '||', IFNULL(TRIM(SIZE1::text), '^^') 
            , '||', IFNULL(TRIM(SIZE2::text), '^^') 
            , '||', IFNULL(TRIM(FREE_CHAR::text), '^^') 
            , '||', IFNULL(TRIM(CARE_CODE::text), '^^') 
            , '||', IFNULL(TRIM(BRAND_ID::text), '^^') 
            , '||', IFNULL(TRIM(FIBER_CODE1::text), '^^') 
            , '||', IFNULL(TRIM(FIBER_PART1::text), '^^') 
            , '||', IFNULL(TRIM(FIBER_CODE2::text), '^^') 
            , '||', IFNULL(TRIM(FIBER_PART2::text), '^^') 
            , '||', IFNULL(TRIM(FIBER_CODE3::text), '^^') 
            , '||', IFNULL(TRIM(FIBER_PART3::text), '^^') 
            , '||', IFNULL(TRIM(FIBER_CODE4::text), '^^') 
            , '||', IFNULL(TRIM(FIBER_PART4::text), '^^') 
            , '||', IFNULL(TRIM(FIBER_CODE5::text), '^^') 
            , '||', IFNULL(TRIM(FIBER_PART5::text), '^^') 
            , '||', IFNULL(TRIM(FASHGRD::text), '^^') 
            , '||', IFNULL(TRIM(ZZTYP::text), '^^') 
            , '||', IFNULL(TRIM(ZZSEG::text), '^^') 
            , '||', IFNULL(TRIM(ZZLIN::text), '^^') 
            , '||', IFNULL(TRIM(ZZDTP::text), '^^') 
            , '||', IFNULL(TRIM(ZZFIN::text), '^^') 
            , '||', IFNULL(TRIM(ZZHAN::text), '^^') 
            , '||', IFNULL(TRIM(ZZMAJ::text), '^^') 
            , '||', IFNULL(TRIM(ZZMIN::text), '^^') 
            , '||', IFNULL(TRIM(ZZPMI::text), '^^') 
            , '||', IFNULL(TRIM(ZZIDT::text), '^^') 
            , '||', IFNULL(TRIM(ZZMG1::text), '^^') 
            , '||', IFNULL(TRIM(ZZROM::text), '^^') 
            , '||', IFNULL(TRIM(ZZWST::text), '^^') 
            , '||', IFNULL(TRIM(ZZWST1::text), '^^') 
            , '||', IFNULL(TRIM(ZZSTS::text), '^^') 
            , '||', IFNULL(TRIM(ZZDDT::text), '^^') 
            , '||', IFNULL(TRIM(ZZQTP::text), '^^') 
            , '||', IFNULL(TRIM(ZZQCD::text), '^^') 
            , '||', IFNULL(TRIM(ZZLIFOCODE::text), '^^') 
            , '||', IFNULL(TRIM(ZZEXC::text), '^^') 
            , '||', IFNULL(TRIM(ZZPLG::text), '^^') 
            , '||', IFNULL(TRIM(ZZMFG::text), '^^') 
            , '||', IFNULL(TRIM(ZZPROJ::text), '^^') 
            , '||', IFNULL(TRIM(ZZPLA::text), '^^') 
            , '||', IFNULL(TRIM(ZZINVOWNER::text), '^^') 
            , '||', IFNULL(TRIM(ZZINVOWNER_MFG::text), '^^') 
            , '||', IFNULL(TRIM(ZZCPF::text), '^^') 
            , '||', IFNULL(TRIM(ZZFIRSTSHIPDATE::text), '^^') 
            , '||', IFNULL(TRIM(ZZBUSOWN::text), '^^') 
            , '||', IFNULL(TRIM(ZZBUSOWNINV::text), '^^') 
            , '||', IFNULL(TRIM(ZZFCSTP::text), '^^') 
            , '||', IFNULL(TRIM(ZZULTS::text), '^^') 
            , '||', IFNULL(TRIM(ZZDEPLOYRULE::text), '^^') 
            , '||', IFNULL(TRIM(ZZPARTPOPULATION::text), '^^') 
            , '||', IFNULL(TRIM(ZZLIFECYCLE::text), '^^') 
            , '||', IFNULL(TRIM(ZZPENDING_TRANS::text), '^^') 
            , '||', IFNULL(TRIM(ZZRISK_PRO::text), '^^') 
            , '||', IFNULL(TRIM(ZZFCST_BASE::text), '^^') 
            , '||', IFNULL(TRIM(ZZWETTED::text), '^^') 
            , '||', IFNULL(TRIM(ZZWSMEINS::text), '^^') 
            , '||', IFNULL(TRIM(ZZLEAD_PER::text), '^^') 
            , '||', IFNULL(TRIM(ZZBASE_MATNR::text), '^^') 
            , '||', IFNULL(TRIM(ZZPRL::text), '^^') 
            , '||', IFNULL(TRIM(ZZBUSUNITOWN::text), '^^') 
            , '||', IFNULL(TRIM(ZZCRITICAL_SUB::text), '^^') 
            , '||', IFNULL(TRIM(ZZBRAND::text), '^^') 
            , '||', IFNULL(TRIM(ZZMARKET::text), '^^') 
            , '||', IFNULL(TRIM(ZZPTG::text), '^^') 
            , '||', IFNULL(TRIM(ZZMKG::text), '^^') 
            , '||', IFNULL(TRIM(ZZPLTG::text), '^^') 
            , '||', IFNULL(TRIM(ZZPLT::text), '^^') 
            , '||', IFNULL(TRIM(ZZPTGK::text), '^^') 
            , '||', IFNULL(TRIM(ZZPTK::text), '^^') 
            , '||', IFNULL(TRIM(ZZRMAREA::text), '^^') 
            , '||', IFNULL(TRIM(ZZPACKQT::text), '^^') 
            , '||', IFNULL(TRIM(ZZOPTYPE::text), '^^') 
            , '||', IFNULL(TRIM(ZZVALTYPE::text), '^^') 
            , '||', IFNULL(TRIM(ZZMKG_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(ZZPLTG_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(ZZSTOCKSTRATEGY::text), '^^') 
            , '||', IFNULL(TRIM(ZZNOOFHANDLES::text), '^^') 
            , '||', IFNULL(TRIM(ZZARCH::text), '^^') 
            , '||', IFNULL(TRIM(ZZARCHDET::text), '^^') 
            , '||', IFNULL(TRIM(ZZSTYLE::text), '^^') 
            , '||', IFNULL(TRIM(ZZLEGMATNR::text), '^^') 
            , '||', IFNULL(TRIM(ZZPRODUCTVITALITY::text), '^^') 
            , '||', IFNULL(TRIM(ZZWHENNEWDATE::text), '^^') 
            , '||', IFNULL(TRIM(ZZREPCATG::text), '^^') 
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
