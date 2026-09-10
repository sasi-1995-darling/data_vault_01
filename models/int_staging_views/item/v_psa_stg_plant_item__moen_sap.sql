---- SRC LAYER ----
WITH
SRC_S              as ( SELECT * FROM {{ source('sap_ecc_prd', 'z_marc') }} as SRC  ),
SRC_A              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S              as ( SELECT * FROM sap_ecc_prd.z_marc )
, SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        MATNR                                                        as                                            ITEM_BK
      , EKGRP                                                        as                                            PURCHASING_ORG_BK
      , SOBSL                                                        as                                            SPECIAL_PROCUREMENT_BK
      , MATNR
      , WERKS
      , MANDT
      , GLREQUEST
      , GLSOURCESYSTEM
      , PSTAT
      , LVORM
      , BWTTY
      , XCHAR
      , MMSTA
      , MMSTA                                                        as                                    MATERIAL_STATUS
      , MMSTD
      , MAABC
      , KZKRI
      , EKGRP 
      , AUSME
      , DISPR
      , DISMM
      , DISPO
      , KZDIE
      , PLIFZ
      , WEBAZ
      , PERKZ
      , AUSSS
      , DISLS
      , BESKZ
      , SOBSL
      , MINBE
      , EISBE
      , BSTMI
      , BSTMA
      , BSTFE
      , BSTRF
      , MABST
      , LOSFX
      , SBDKZ
      , LAGPR
      , ALTSL
      , KZAUS
      , AUSDT
      , NFMAT
      , KZBED
      , MISKZ
      , FHORI
      , PFREI
      , FFREI
      , RGEKZ
      , FEVOR
      , BEARZ
      , RUEZT
      , TRANZ
      , BASMG
      , DZEIT
      , MAXLZ
      , LZEIH
      , KZPRO
      , GPMKZ
      , UEETO
      , UEETK
      , UNETO
      , WZEIT
      , ATPKZ
      , VZUSL
      , HERBL
      , INSMK
      , SPROZ
      , QUAZT
      , SSQSS
      , MPDAU
      , KZPPV
      , KZDKZ
      , WSTGH
      , PRFRQ
      , NKMPR
      , UMLMC
      , LADGR
      , XCHPF
      , USEQU
      , LGRAD
      , AUFTL
      , PLVAR
      , OTYPE
      , OBJID
      , MTVFP
      , PERIV
      , KZKFK
      , VRVEZ
      , VBAMG
      , VBEAZ
      , LIZYK
      , BWSCL
      , KAUTB
      , KORDB
      , STAWN
      , HERKL
      , HERKR
      , EXPME
      , MTVER
      , PRCTR
      , TRAME
      , MRPPP
      , SAUFT
      , FXHOR
      , VRMOD
      , VINT1
      , VINT2
      , VERKZ
      , STLAL
      , STLAN
      , PLNNR
      , APLAL
      , LOSGR
      , SOBSK
      , FRTME
      , LGPRO
      , DISGR
      , KAUSF
      , QZGTP
      , QMATV
      , TAKZT
      , RWPRO
      , COPAM
      , ABCIN
      , AWSLS
      , SERNP
      , CUOBJ
      , STDPD
      , SFEPR
      , XMCNG
      , QSSYS
      , LFRHY
      , RDPRF
      , VRBMT
      , VRBWK
      , VRBDT
      , VRBFK
      , AUTRU
      , PREFE
      , PRENC
      , PRENO
      , PREND
      , PRENE
      , PRENG
      , ITARK
      , SERVG
      , KZKUP
      , STRGR
      , CUOBV
      , LGFSB
      , SCHGT
      , CCFIX
      , EPRIO
      , QMATA
      , RESVP
      , PLNTY
      , UOMGR
      , UMRSL
      , ABFAC
      , SFCPF
      , SHFLG
      , SHZET
      , MDACH
      , KZECH
      , MEGRU
      , MFRGR
      , VKUMC
      , VKTRW
      , KZAGL
      , FVIDK
      , FXPRU
      , LOGGR
      , FPRFM
      , GLGMG
      , VKGLG
      , INDUS
      , MOWNR
      , MOGRU
      , CASNR
      , GPNUM
      , STEUC
      , FABKZ
      , MATGR
      , VSPVB
      , DPLFS
      , DPLPU
      , DPLHO
      , MINLS
      , MAXLS
      , FIXLS
      , LTINC
      , COMPL
      , CONVT
      , SHPRO
      , AHDIS
      , DIBER
      , KZPSP
      , OCMPF
      , APOKZ
      , MCRUE
      , LFMON
      , LFGJA
      , EISLO
      , NCOST
      , ROTATION_DATE
      , UCHKZ
      , UCMAT
      , BWESB
      , SGT_COVS
      , SGT_STATC
      , SGT_SCOPE
      , SGT_MRPSI
      , SGT_PRCM
      , SGT_CHINT
      , SGT_STK_PRT
      , SGT_DEFSC
      , SGT_MRP_ATP_STATUS
      , SGT_MMSTD
      , FSH_MG_ARUN_REQ
      , FSH_SEAIM
      , FSH_VAR_GROUP
      , FSH_KZECH
      , FSH_CALENDAR_GROUP
      , PPSKZ
      , PPS_STRATEGY
      , PPS_PLANNING_TYPE
      , PPS_HEUR_ID
      , PPS_FIXPEG
      , PPS_PEG_STRATEGY
      , PPS_GRPRT
      , PPS_GIPRT
      , PPS_CONHAP
      , PPS_HUNIT
      , PPS_CONHAP_OUT
      , PPS_HUNIT_OUT
      , PPS_ATPCHECK
      , PPS_PEG_FUT_AL
      , PPS_PEG_PAST_AL
      , "/SAPMP/TOLPRPL"                                             as                                      SAPMP_TOLPRPL
      , "/SAPMP/TOLPRMI"                                             as                                      SAPMP_TOLPRMI
      , "/VSO/R_PKGRP"                                               as                                        VSO_R_PKGRP
      , "/VSO/R_LANE_NUM"                                            as                                     VSO_R_LANE_NUM
      , "/VSO/R_PAL_VEND"                                            as                                     VSO_R_PAL_VEND
      , "/VSO/R_FORK_DIR"                                            as                                     VSO_R_FORK_DIR
      , IUID_RELEVANT
      , IUID_TYPE
      , UID_IEA
      , CONS_PROCG
      , GI_PR_TIME
      , MULTIPLE_EKGRP
      , REF_SCHEMA
      , MIN_TROC
      , MAX_TROC
      , TARGET_STOCK
      , ZZOBSDT
      , ZZDPLA
      , ZZPLTSL
      , ZZEXLTM
      , ZZXMATNR
      , ZZSLSRCE
      , ZZGOVTMATCLASS
      , ZZSUPPLY_VAR_FCT
      , ZZATCOSTATUS
      , ZZ_SNP_HORIZ
      , ZZTARGET_DUR
      , ZZCTM
      , ZZTARGET_METHOD
      , ZZPLANNER_PPS
      , ZZDPREX
      , ZZSPREX
      , ZZRRP_TYPE
      , ZZHEUR_ID
      , ZZSS_METHOD
      , ZZCONVH
      , ZZPEG_STRATEGY
      , ZZPEG_PAST_MAX
      , ZZPEG_FUTURE_MAX
      , ZZDELDATE
      , ZZFINLBQ
      , ZZWARRANTYDT
      , ZZPROD_PRIORITY
      , ZZPEROD_SPL_PROF
      , ZZSERVICE_TIME
      , ZZPLANNING_TIME
      , ZZFROZEN_PERIOD
      , ZZIOMINMAXTYPE
      , ZZIOMINSSVALUE
      , ZZIOMAXSSVALUE
      , ZZIOMINMAXREASON
      , ZZCOVPROFEQUAL
      , ZZIOOUTPUTCONT
      , ZZIOSAFETYSTOCK
      , ZZRISKMITWEEKS
      , ZZRISKMITSTOCK
      , ZZMANUALSSVALUE
      , ZZMANUALSSREASON
      , ZZIONOTES
      , ZZIOPRODTIME
      , ZZOPT
      , ZZPRODUCTIONOFFSET
      , ZZLEADTIMEOFFSET
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
      , WERKS                                                        as                                           PLANT_BK
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
      , PURCHASING_ORG_BK
      , SPECIAL_PROCUREMENT_BK
      , MATNR
      , WERKS
      , MANDT
      , GLREQUEST
      , GLSOURCESYSTEM
      , PSTAT
      , LVORM
      , BWTTY
      , XCHAR
      , MMSTA
      , MATERIAL_STATUS
      , MMSTD
      , MAABC
      , KZKRI
      , EKGRP
      , AUSME
      , DISPR
      , DISMM
      , DISPO
      , KZDIE
      , PLIFZ
      , WEBAZ
      , PERKZ
      , AUSSS
      , DISLS
      , BESKZ
      , SOBSL
      , MINBE
      , EISBE
      , BSTMI
      , BSTMA
      , BSTFE
      , BSTRF
      , MABST
      , LOSFX
      , SBDKZ
      , LAGPR
      , ALTSL
      , KZAUS
      , AUSDT
      , NFMAT
      , KZBED
      , MISKZ
      , FHORI
      , PFREI
      , FFREI
      , RGEKZ
      , FEVOR
      , BEARZ
      , RUEZT
      , TRANZ
      , BASMG
      , DZEIT
      , MAXLZ
      , LZEIH
      , KZPRO
      , GPMKZ
      , UEETO
      , UEETK
      , UNETO
      , WZEIT
      , ATPKZ
      , VZUSL
      , HERBL
      , INSMK
      , SPROZ
      , QUAZT
      , SSQSS
      , MPDAU
      , KZPPV
      , KZDKZ
      , WSTGH
      , PRFRQ
      , NKMPR
      , UMLMC
      , LADGR
      , XCHPF
      , USEQU
      , LGRAD
      , AUFTL
      , PLVAR
      , OTYPE
      , OBJID
      , MTVFP
      , PERIV
      , KZKFK
      , VRVEZ
      , VBAMG
      , VBEAZ
      , LIZYK
      , BWSCL
      , KAUTB
      , KORDB
      , STAWN
      , HERKL
      , HERKR
      , EXPME
      , MTVER
      , PRCTR
      , TRAME
      , MRPPP
      , SAUFT
      , FXHOR
      , VRMOD
      , VINT1
      , VINT2
      , VERKZ
      , STLAL
      , STLAN
      , PLNNR
      , APLAL
      , LOSGR
      , SOBSK
      , FRTME
      , LGPRO
      , DISGR
      , KAUSF
      , QZGTP
      , QMATV
      , TAKZT
      , RWPRO
      , COPAM
      , ABCIN
      , AWSLS
      , SERNP
      , CUOBJ
      , STDPD
      , SFEPR
      , XMCNG
      , QSSYS
      , LFRHY
      , RDPRF
      , VRBMT
      , VRBWK
      , VRBDT
      , VRBFK
      , AUTRU
      , PREFE
      , PRENC
      , PRENO
      , PREND
      , PRENE
      , PRENG
      , ITARK
      , SERVG
      , KZKUP
      , STRGR
      , CUOBV
      , LGFSB
      , SCHGT
      , CCFIX
      , EPRIO
      , QMATA
      , RESVP
      , PLNTY
      , UOMGR
      , UMRSL
      , ABFAC
      , SFCPF
      , SHFLG
      , SHZET
      , MDACH
      , KZECH
      , MEGRU
      , MFRGR
      , VKUMC
      , VKTRW
      , KZAGL
      , FVIDK
      , FXPRU
      , LOGGR
      , FPRFM
      , GLGMG
      , VKGLG
      , INDUS
      , MOWNR
      , MOGRU
      , CASNR
      , GPNUM
      , STEUC
      , FABKZ
      , MATGR
      , VSPVB
      , DPLFS
      , DPLPU
      , DPLHO
      , MINLS
      , MAXLS
      , FIXLS
      , LTINC
      , COMPL
      , CONVT
      , SHPRO
      , AHDIS
      , DIBER
      , KZPSP
      , OCMPF
      , APOKZ
      , MCRUE
      , LFMON
      , LFGJA
      , EISLO
      , NCOST
      , ROTATION_DATE
      , UCHKZ
      , UCMAT
      , BWESB
      , SGT_COVS
      , SGT_STATC
      , SGT_SCOPE
      , SGT_MRPSI
      , SGT_PRCM
      , SGT_CHINT
      , SGT_STK_PRT
      , SGT_DEFSC
      , SGT_MRP_ATP_STATUS
      , SGT_MMSTD
      , FSH_MG_ARUN_REQ
      , FSH_SEAIM
      , FSH_VAR_GROUP
      , FSH_KZECH
      , FSH_CALENDAR_GROUP
      , PPSKZ
      , PPS_STRATEGY
      , PPS_PLANNING_TYPE
      , PPS_HEUR_ID
      , PPS_FIXPEG
      , PPS_PEG_STRATEGY
      , PPS_GRPRT
      , PPS_GIPRT
      , PPS_CONHAP
      , PPS_HUNIT
      , PPS_CONHAP_OUT
      , PPS_HUNIT_OUT
      , PPS_ATPCHECK
      , PPS_PEG_FUT_AL
      , PPS_PEG_PAST_AL
      , SAPMP_TOLPRPL
      , SAPMP_TOLPRMI
      , VSO_R_PKGRP
      , VSO_R_LANE_NUM
      , VSO_R_PAL_VEND
      , VSO_R_FORK_DIR
      , IUID_RELEVANT
      , IUID_TYPE
      , UID_IEA
      , CONS_PROCG
      , GI_PR_TIME
      , MULTIPLE_EKGRP
      , REF_SCHEMA
      , MIN_TROC
      , MAX_TROC
      , TARGET_STOCK
      , ZZOBSDT
      , ZZDPLA
      , ZZPLTSL
      , ZZEXLTM
      , ZZXMATNR
      , ZZSLSRCE
      , ZZGOVTMATCLASS
      , ZZSUPPLY_VAR_FCT
      , ZZATCOSTATUS
      , ZZ_SNP_HORIZ
      , ZZTARGET_DUR
      , ZZCTM
      , ZZTARGET_METHOD
      , ZZPLANNER_PPS
      , ZZDPREX
      , ZZSPREX
      , ZZRRP_TYPE
      , ZZHEUR_ID
      , ZZSS_METHOD
      , ZZCONVH
      , ZZPEG_STRATEGY
      , ZZPEG_PAST_MAX
      , ZZPEG_FUTURE_MAX
      , ZZDELDATE
      , ZZFINLBQ
      , ZZWARRANTYDT
      , ZZPROD_PRIORITY
      , ZZPEROD_SPL_PROF
      , ZZSERVICE_TIME
      , ZZPLANNING_TIME
      , ZZFROZEN_PERIOD
      , ZZIOMINMAXTYPE
      , ZZIOMINSSVALUE
      , ZZIOMAXSSVALUE
      , ZZIOMINMAXREASON
      , ZZCOVPROFEQUAL
      , ZZIOOUTPUTCONT
      , ZZIOSAFETYSTOCK
      , ZZRISKMITWEEKS
      , ZZRISKMITSTOCK
      , ZZMANUALSSVALUE
      , ZZMANUALSSREASON
      , ZZIONOTES
      , ZZIOPRODTIME
      , ZZOPT
      , ZZPRODUCTIONOFFSET
      , ZZLEADTIMEOFFSET
      , GLDELFLAG
      , GLCHANGETIME
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , LOAD_DTS
      , PLANT_BK
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
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_MARC'
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
        , PURCHASING_ORG_BK
        , SPECIAL_PROCUREMENT_BK
        , MATNR
        , WERKS
        , MANDT
        , GLREQUEST
        , GLSOURCESYSTEM
        , PSTAT
        , LVORM
        , BWTTY
        , XCHAR
        , MMSTA
        , MATERIAL_STATUS
        , MMSTD
        , MAABC
        , KZKRI
        , EKGRP
        , AUSME
        , DISPR
        , DISMM
        , DISPO
        , KZDIE
        , PLIFZ
        , WEBAZ
        , PERKZ
        , AUSSS
        , DISLS
        , BESKZ
        , SOBSL
        , MINBE
        , EISBE
        , BSTMI
        , BSTMA
        , BSTFE
        , BSTRF
        , MABST
        , LOSFX
        , SBDKZ
        , LAGPR
        , ALTSL
        , KZAUS
        , AUSDT
        , NFMAT
        , KZBED
        , MISKZ
        , FHORI
        , PFREI
        , FFREI
        , RGEKZ
        , FEVOR
        , BEARZ
        , RUEZT
        , TRANZ
        , BASMG
        , DZEIT
        , MAXLZ
        , LZEIH
        , KZPRO
        , GPMKZ
        , UEETO
        , UEETK
        , UNETO
        , WZEIT
        , ATPKZ
        , VZUSL
        , HERBL
        , INSMK
        , SPROZ
        , QUAZT
        , SSQSS
        , MPDAU
        , KZPPV
        , KZDKZ
        , WSTGH
        , PRFRQ
        , NKMPR
        , UMLMC
        , LADGR
        , XCHPF
        , USEQU
        , LGRAD
        , AUFTL
        , PLVAR
        , OTYPE
        , OBJID
        , MTVFP
        , PERIV
        , KZKFK
        , VRVEZ
        , VBAMG
        , VBEAZ
        , LIZYK
        , BWSCL
        , KAUTB
        , KORDB
        , STAWN
        , HERKL
        , HERKR
        , EXPME
        , MTVER
        , PRCTR
        , TRAME
        , MRPPP
        , SAUFT
        , FXHOR
        , VRMOD
        , VINT1
        , VINT2
        , VERKZ
        , STLAL
        , STLAN
        , PLNNR
        , APLAL
        , LOSGR
        , SOBSK
        , FRTME
        , LGPRO
        , DISGR
        , KAUSF
        , QZGTP
        , QMATV
        , TAKZT
        , RWPRO
        , COPAM
        , ABCIN
        , AWSLS
        , SERNP
        , CUOBJ
        , STDPD
        , SFEPR
        , XMCNG
        , QSSYS
        , LFRHY
        , RDPRF
        , VRBMT
        , VRBWK
        , VRBDT
        , VRBFK
        , AUTRU
        , PREFE
        , PRENC
        , PRENO
        , PREND
        , PRENE
        , PRENG
        , ITARK
        , SERVG
        , KZKUP
        , STRGR
        , CUOBV
        , LGFSB
        , SCHGT
        , CCFIX
        , EPRIO
        , QMATA
        , RESVP
        , PLNTY
        , UOMGR
        , UMRSL
        , ABFAC
        , SFCPF
        , SHFLG
        , SHZET
        , MDACH
        , KZECH
        , MEGRU
        , MFRGR
        , VKUMC
        , VKTRW
        , KZAGL
        , FVIDK
        , FXPRU
        , LOGGR
        , FPRFM
        , GLGMG
        , VKGLG
        , INDUS
        , MOWNR
        , MOGRU
        , CASNR
        , GPNUM
        , STEUC
        , FABKZ
        , MATGR
        , VSPVB
        , DPLFS
        , DPLPU
        , DPLHO
        , MINLS
        , MAXLS
        , FIXLS
        , LTINC
        , COMPL
        , CONVT
        , SHPRO
        , AHDIS
        , DIBER
        , KZPSP
        , OCMPF
        , APOKZ
        , MCRUE
        , LFMON
        , LFGJA
        , EISLO
        , NCOST
        , ROTATION_DATE
        , UCHKZ
        , UCMAT
        , BWESB
        , SGT_COVS
        , SGT_STATC
        , SGT_SCOPE
        , SGT_MRPSI
        , SGT_PRCM
        , SGT_CHINT
        , SGT_STK_PRT
        , SGT_DEFSC
        , SGT_MRP_ATP_STATUS
        , SGT_MMSTD
        , FSH_MG_ARUN_REQ
        , FSH_SEAIM
        , FSH_VAR_GROUP
        , FSH_KZECH
        , FSH_CALENDAR_GROUP
        , PPSKZ
        , PPS_STRATEGY
        , PPS_PLANNING_TYPE
        , PPS_HEUR_ID
        , PPS_FIXPEG
        , PPS_PEG_STRATEGY
        , PPS_GRPRT
        , PPS_GIPRT
        , PPS_CONHAP
        , PPS_HUNIT
        , PPS_CONHAP_OUT
        , PPS_HUNIT_OUT
        , PPS_ATPCHECK
        , PPS_PEG_FUT_AL
        , PPS_PEG_PAST_AL
        , SAPMP_TOLPRPL
        , SAPMP_TOLPRMI
        , VSO_R_PKGRP
        , VSO_R_LANE_NUM
        , VSO_R_PAL_VEND
        , VSO_R_FORK_DIR
        , IUID_RELEVANT
        , IUID_TYPE
        , UID_IEA
        , CONS_PROCG
        , GI_PR_TIME
        , MULTIPLE_EKGRP
        , REF_SCHEMA
        , MIN_TROC
        , MAX_TROC
        , TARGET_STOCK
        , ZZOBSDT
        , ZZDPLA
        , ZZPLTSL
        , ZZEXLTM
        , ZZXMATNR
        , ZZSLSRCE
        , ZZGOVTMATCLASS
        , ZZSUPPLY_VAR_FCT
        , ZZATCOSTATUS
        , ZZ_SNP_HORIZ
        , ZZTARGET_DUR
        , ZZCTM
        , ZZTARGET_METHOD
        , ZZPLANNER_PPS
        , ZZDPREX
        , ZZSPREX
        , ZZRRP_TYPE
        , ZZHEUR_ID
        , ZZSS_METHOD
        , ZZCONVH
        , ZZPEG_STRATEGY
        , ZZPEG_PAST_MAX
        , ZZPEG_FUTURE_MAX
        , ZZDELDATE
        , ZZFINLBQ
        , ZZWARRANTYDT
        , ZZPROD_PRIORITY
        , ZZPEROD_SPL_PROF
        , ZZSERVICE_TIME
        , ZZPLANNING_TIME
        , ZZFROZEN_PERIOD
        , ZZIOMINMAXTYPE
        , ZZIOMINSSVALUE
        , ZZIOMAXSSVALUE
        , ZZIOMINMAXREASON
        , ZZCOVPROFEQUAL
        , ZZIOOUTPUTCONT
        , ZZIOSAFETYSTOCK
        , ZZRISKMITWEEKS
        , ZZRISKMITSTOCK
        , ZZMANUALSSVALUE
        , ZZMANUALSSREASON
        , ZZIONOTES
        , ZZIOPRODTIME
        , ZZOPT
        , ZZPRODUCTIONOFFSET
        , ZZLEADTIMEOFFSET
        , GLDELFLAG
        , GLCHANGETIME
        , PSA_DELETE_IND
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , PLANT_BK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ITEM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ITEM_HK
       , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(EKGRP as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PURCHASING_ORG_HK
       , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(SOBSL as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as SPECIAL_PROCUREMENT_HK
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
          COALESCE(NULLIF(TRIM(CAST(ITEM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(PLANT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(PURCHASING_ORG_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PLANT_ITEM_PURCHASING_ORG_LHK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(WERKS as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(MATNR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(SOBSL as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as LNK_ITEM_PLANT_SPECIAL_PROCUREMENT_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(MANDT::text), '^^') 
            , '||', IFNULL(TRIM(GLREQUEST::text), '^^') 
            , '||', IFNULL(TRIM(GLSOURCESYSTEM::text), '^^') 
            , '||', IFNULL(TRIM(PSTAT::text), '^^') 
            , '||', IFNULL(TRIM(LVORM::text), '^^') 
            , '||', IFNULL(TRIM(BWTTY::text), '^^') 
            , '||', IFNULL(TRIM(XCHAR::text), '^^') 
            , '||', IFNULL(TRIM(MMSTA::text), '^^') 
            , '||', IFNULL(TRIM(MATERIAL_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(MMSTD::text), '^^') 
            , '||', IFNULL(TRIM(MAABC::text), '^^') 
            , '||', IFNULL(TRIM(KZKRI::text), '^^') 
            , '||', IFNULL(TRIM(EKGRP::text), '^^') 
            , '||', IFNULL(TRIM(AUSME::text), '^^') 
            , '||', IFNULL(TRIM(DISPR::text), '^^') 
            , '||', IFNULL(TRIM(DISMM::text), '^^') 
            , '||', IFNULL(TRIM(DISPO::text), '^^') 
            , '||', IFNULL(TRIM(KZDIE::text), '^^') 
            , '||', IFNULL(TRIM(PLIFZ::text), '^^') 
            , '||', IFNULL(TRIM(WEBAZ::text), '^^') 
            , '||', IFNULL(TRIM(PERKZ::text), '^^') 
            , '||', IFNULL(TRIM(AUSSS::text), '^^') 
            , '||', IFNULL(TRIM(DISLS::text), '^^') 
            , '||', IFNULL(TRIM(BESKZ::text), '^^') 
            , '||', IFNULL(TRIM(SOBSL::text), '^^') 
            , '||', IFNULL(TRIM(MINBE::text), '^^') 
            , '||', IFNULL(TRIM(EISBE::text), '^^') 
            , '||', IFNULL(TRIM(BSTMI::text), '^^') 
            , '||', IFNULL(TRIM(BSTMA::text), '^^') 
            , '||', IFNULL(TRIM(BSTFE::text), '^^') 
            , '||', IFNULL(TRIM(BSTRF::text), '^^') 
            , '||', IFNULL(TRIM(MABST::text), '^^') 
            , '||', IFNULL(TRIM(LOSFX::text), '^^') 
            , '||', IFNULL(TRIM(SBDKZ::text), '^^') 
            , '||', IFNULL(TRIM(LAGPR::text), '^^') 
            , '||', IFNULL(TRIM(ALTSL::text), '^^') 
            , '||', IFNULL(TRIM(KZAUS::text), '^^') 
            , '||', IFNULL(TRIM(AUSDT::text), '^^') 
            , '||', IFNULL(TRIM(NFMAT::text), '^^') 
            , '||', IFNULL(TRIM(KZBED::text), '^^') 
            , '||', IFNULL(TRIM(MISKZ::text), '^^') 
            , '||', IFNULL(TRIM(FHORI::text), '^^') 
            , '||', IFNULL(TRIM(PFREI::text), '^^') 
            , '||', IFNULL(TRIM(FFREI::text), '^^') 
            , '||', IFNULL(TRIM(RGEKZ::text), '^^') 
            , '||', IFNULL(TRIM(FEVOR::text), '^^') 
            , '||', IFNULL(TRIM(BEARZ::text), '^^') 
            , '||', IFNULL(TRIM(RUEZT::text), '^^') 
            , '||', IFNULL(TRIM(TRANZ::text), '^^') 
            , '||', IFNULL(TRIM(BASMG::text), '^^') 
            , '||', IFNULL(TRIM(DZEIT::text), '^^') 
            , '||', IFNULL(TRIM(MAXLZ::text), '^^') 
            , '||', IFNULL(TRIM(LZEIH::text), '^^') 
            , '||', IFNULL(TRIM(KZPRO::text), '^^') 
            , '||', IFNULL(TRIM(GPMKZ::text), '^^') 
            , '||', IFNULL(TRIM(UEETO::text), '^^') 
            , '||', IFNULL(TRIM(UEETK::text), '^^') 
            , '||', IFNULL(TRIM(UNETO::text), '^^') 
            , '||', IFNULL(TRIM(WZEIT::text), '^^') 
            , '||', IFNULL(TRIM(ATPKZ::text), '^^') 
            , '||', IFNULL(TRIM(VZUSL::text), '^^') 
            , '||', IFNULL(TRIM(HERBL::text), '^^') 
            , '||', IFNULL(TRIM(INSMK::text), '^^') 
            , '||', IFNULL(TRIM(SPROZ::text), '^^') 
            , '||', IFNULL(TRIM(QUAZT::text), '^^') 
            , '||', IFNULL(TRIM(SSQSS::text), '^^') 
            , '||', IFNULL(TRIM(MPDAU::text), '^^') 
            , '||', IFNULL(TRIM(KZPPV::text), '^^') 
            , '||', IFNULL(TRIM(KZDKZ::text), '^^') 
            , '||', IFNULL(TRIM(WSTGH::text), '^^') 
            , '||', IFNULL(TRIM(PRFRQ::text), '^^') 
            , '||', IFNULL(TRIM(NKMPR::text), '^^') 
            , '||', IFNULL(TRIM(UMLMC::text), '^^') 
            , '||', IFNULL(TRIM(LADGR::text), '^^') 
            , '||', IFNULL(TRIM(XCHPF::text), '^^') 
            , '||', IFNULL(TRIM(USEQU::text), '^^') 
            , '||', IFNULL(TRIM(LGRAD::text), '^^') 
            , '||', IFNULL(TRIM(AUFTL::text), '^^') 
            , '||', IFNULL(TRIM(PLVAR::text), '^^') 
            , '||', IFNULL(TRIM(OTYPE::text), '^^') 
            , '||', IFNULL(TRIM(OBJID::text), '^^') 
            , '||', IFNULL(TRIM(MTVFP::text), '^^') 
            , '||', IFNULL(TRIM(PERIV::text), '^^') 
            , '||', IFNULL(TRIM(KZKFK::text), '^^') 
            , '||', IFNULL(TRIM(VRVEZ::text), '^^') 
            , '||', IFNULL(TRIM(VBAMG::text), '^^') 
            , '||', IFNULL(TRIM(VBEAZ::text), '^^') 
            , '||', IFNULL(TRIM(LIZYK::text), '^^') 
            , '||', IFNULL(TRIM(BWSCL::text), '^^') 
            , '||', IFNULL(TRIM(KAUTB::text), '^^') 
            , '||', IFNULL(TRIM(KORDB::text), '^^') 
            , '||', IFNULL(TRIM(STAWN::text), '^^') 
            , '||', IFNULL(TRIM(HERKL::text), '^^') 
            , '||', IFNULL(TRIM(HERKR::text), '^^') 
            , '||', IFNULL(TRIM(EXPME::text), '^^') 
            , '||', IFNULL(TRIM(MTVER::text), '^^') 
            , '||', IFNULL(TRIM(PRCTR::text), '^^') 
            , '||', IFNULL(TRIM(TRAME::text), '^^') 
            , '||', IFNULL(TRIM(MRPPP::text), '^^') 
            , '||', IFNULL(TRIM(SAUFT::text), '^^') 
            , '||', IFNULL(TRIM(FXHOR::text), '^^') 
            , '||', IFNULL(TRIM(VRMOD::text), '^^') 
            , '||', IFNULL(TRIM(VINT1::text), '^^') 
            , '||', IFNULL(TRIM(VINT2::text), '^^') 
            , '||', IFNULL(TRIM(VERKZ::text), '^^') 
            , '||', IFNULL(TRIM(STLAL::text), '^^') 
            , '||', IFNULL(TRIM(STLAN::text), '^^') 
            , '||', IFNULL(TRIM(PLNNR::text), '^^') 
            , '||', IFNULL(TRIM(APLAL::text), '^^') 
            , '||', IFNULL(TRIM(LOSGR::text), '^^') 
            , '||', IFNULL(TRIM(SOBSK::text), '^^') 
            , '||', IFNULL(TRIM(FRTME::text), '^^') 
            , '||', IFNULL(TRIM(LGPRO::text), '^^') 
            , '||', IFNULL(TRIM(DISGR::text), '^^') 
            , '||', IFNULL(TRIM(KAUSF::text), '^^') 
            , '||', IFNULL(TRIM(QZGTP::text), '^^') 
            , '||', IFNULL(TRIM(QMATV::text), '^^') 
            , '||', IFNULL(TRIM(TAKZT::text), '^^') 
            , '||', IFNULL(TRIM(RWPRO::text), '^^') 
            , '||', IFNULL(TRIM(COPAM::text), '^^') 
            , '||', IFNULL(TRIM(ABCIN::text), '^^') 
            , '||', IFNULL(TRIM(AWSLS::text), '^^') 
            , '||', IFNULL(TRIM(SERNP::text), '^^') 
            , '||', IFNULL(TRIM(CUOBJ::text), '^^') 
            , '||', IFNULL(TRIM(STDPD::text), '^^') 
            , '||', IFNULL(TRIM(SFEPR::text), '^^') 
            , '||', IFNULL(TRIM(XMCNG::text), '^^') 
            , '||', IFNULL(TRIM(QSSYS::text), '^^') 
            , '||', IFNULL(TRIM(LFRHY::text), '^^') 
            , '||', IFNULL(TRIM(RDPRF::text), '^^') 
            , '||', IFNULL(TRIM(VRBMT::text), '^^') 
            , '||', IFNULL(TRIM(VRBWK::text), '^^') 
            , '||', IFNULL(TRIM(VRBDT::text), '^^') 
            , '||', IFNULL(TRIM(VRBFK::text), '^^') 
            , '||', IFNULL(TRIM(AUTRU::text), '^^') 
            , '||', IFNULL(TRIM(PREFE::text), '^^') 
            , '||', IFNULL(TRIM(PRENC::text), '^^') 
            , '||', IFNULL(TRIM(PRENO::text), '^^') 
            , '||', IFNULL(TRIM(PREND::text), '^^') 
            , '||', IFNULL(TRIM(PRENE::text), '^^') 
            , '||', IFNULL(TRIM(PRENG::text), '^^') 
            , '||', IFNULL(TRIM(ITARK::text), '^^') 
            , '||', IFNULL(TRIM(SERVG::text), '^^') 
            , '||', IFNULL(TRIM(KZKUP::text), '^^') 
            , '||', IFNULL(TRIM(STRGR::text), '^^') 
            , '||', IFNULL(TRIM(CUOBV::text), '^^') 
            , '||', IFNULL(TRIM(LGFSB::text), '^^') 
            , '||', IFNULL(TRIM(SCHGT::text), '^^') 
            , '||', IFNULL(TRIM(CCFIX::text), '^^') 
            , '||', IFNULL(TRIM(EPRIO::text), '^^') 
            , '||', IFNULL(TRIM(QMATA::text), '^^') 
            , '||', IFNULL(TRIM(RESVP::text), '^^') 
            , '||', IFNULL(TRIM(PLNTY::text), '^^') 
            , '||', IFNULL(TRIM(UOMGR::text), '^^') 
            , '||', IFNULL(TRIM(UMRSL::text), '^^') 
            , '||', IFNULL(TRIM(ABFAC::text), '^^') 
            , '||', IFNULL(TRIM(SFCPF::text), '^^') 
            , '||', IFNULL(TRIM(SHFLG::text), '^^') 
            , '||', IFNULL(TRIM(SHZET::text), '^^') 
            , '||', IFNULL(TRIM(MDACH::text), '^^') 
            , '||', IFNULL(TRIM(KZECH::text), '^^') 
            , '||', IFNULL(TRIM(MEGRU::text), '^^') 
            , '||', IFNULL(TRIM(MFRGR::text), '^^') 
            , '||', IFNULL(TRIM(VKUMC::text), '^^') 
            , '||', IFNULL(TRIM(VKTRW::text), '^^') 
            , '||', IFNULL(TRIM(KZAGL::text), '^^') 
            , '||', IFNULL(TRIM(FVIDK::text), '^^') 
            , '||', IFNULL(TRIM(FXPRU::text), '^^') 
            , '||', IFNULL(TRIM(LOGGR::text), '^^') 
            , '||', IFNULL(TRIM(FPRFM::text), '^^') 
            , '||', IFNULL(TRIM(GLGMG::text), '^^') 
            , '||', IFNULL(TRIM(VKGLG::text), '^^') 
            , '||', IFNULL(TRIM(INDUS::text), '^^') 
            , '||', IFNULL(TRIM(MOWNR::text), '^^') 
            , '||', IFNULL(TRIM(MOGRU::text), '^^') 
            , '||', IFNULL(TRIM(CASNR::text), '^^') 
            , '||', IFNULL(TRIM(GPNUM::text), '^^') 
            , '||', IFNULL(TRIM(STEUC::text), '^^') 
            , '||', IFNULL(TRIM(FABKZ::text), '^^') 
            , '||', IFNULL(TRIM(MATGR::text), '^^') 
            , '||', IFNULL(TRIM(VSPVB::text), '^^') 
            , '||', IFNULL(TRIM(DPLFS::text), '^^') 
            , '||', IFNULL(TRIM(DPLPU::text), '^^') 
            , '||', IFNULL(TRIM(DPLHO::text), '^^') 
            , '||', IFNULL(TRIM(MINLS::text), '^^') 
            , '||', IFNULL(TRIM(MAXLS::text), '^^') 
            , '||', IFNULL(TRIM(FIXLS::text), '^^') 
            , '||', IFNULL(TRIM(LTINC::text), '^^') 
            , '||', IFNULL(TRIM(COMPL::text), '^^') 
            , '||', IFNULL(TRIM(CONVT::text), '^^') 
            , '||', IFNULL(TRIM(SHPRO::text), '^^') 
            , '||', IFNULL(TRIM(AHDIS::text), '^^') 
            , '||', IFNULL(TRIM(DIBER::text), '^^') 
            , '||', IFNULL(TRIM(KZPSP::text), '^^') 
            , '||', IFNULL(TRIM(OCMPF::text), '^^') 
            , '||', IFNULL(TRIM(APOKZ::text), '^^') 
            , '||', IFNULL(TRIM(MCRUE::text), '^^') 
            , '||', IFNULL(TRIM(LFMON::text), '^^') 
            , '||', IFNULL(TRIM(LFGJA::text), '^^') 
            , '||', IFNULL(TRIM(EISLO::text), '^^') 
            , '||', IFNULL(TRIM(NCOST::text), '^^') 
            , '||', IFNULL(TRIM(ROTATION_DATE::text), '^^') 
            , '||', IFNULL(TRIM(UCHKZ::text), '^^') 
            , '||', IFNULL(TRIM(UCMAT::text), '^^') 
            , '||', IFNULL(TRIM(BWESB::text), '^^') 
            , '||', IFNULL(TRIM(SGT_COVS::text), '^^') 
            , '||', IFNULL(TRIM(SGT_STATC::text), '^^') 
            , '||', IFNULL(TRIM(SGT_SCOPE::text), '^^') 
            , '||', IFNULL(TRIM(SGT_MRPSI::text), '^^') 
            , '||', IFNULL(TRIM(SGT_PRCM::text), '^^') 
            , '||', IFNULL(TRIM(SGT_CHINT::text), '^^') 
            , '||', IFNULL(TRIM(SGT_STK_PRT::text), '^^') 
            , '||', IFNULL(TRIM(SGT_DEFSC::text), '^^') 
            , '||', IFNULL(TRIM(SGT_MRP_ATP_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(SGT_MMSTD::text), '^^') 
            , '||', IFNULL(TRIM(FSH_MG_ARUN_REQ::text), '^^') 
            , '||', IFNULL(TRIM(FSH_SEAIM::text), '^^') 
            , '||', IFNULL(TRIM(FSH_VAR_GROUP::text), '^^') 
            , '||', IFNULL(TRIM(FSH_KZECH::text), '^^') 
            , '||', IFNULL(TRIM(FSH_CALENDAR_GROUP::text), '^^') 
            , '||', IFNULL(TRIM(PPSKZ::text), '^^') 
            , '||', IFNULL(TRIM(PPS_STRATEGY::text), '^^') 
            , '||', IFNULL(TRIM(PPS_PLANNING_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(PPS_HEUR_ID::text), '^^') 
            , '||', IFNULL(TRIM(PPS_FIXPEG::text), '^^') 
            , '||', IFNULL(TRIM(PPS_PEG_STRATEGY::text), '^^') 
            , '||', IFNULL(TRIM(PPS_GRPRT::text), '^^') 
            , '||', IFNULL(TRIM(PPS_GIPRT::text), '^^') 
            , '||', IFNULL(TRIM(PPS_CONHAP::text), '^^') 
            , '||', IFNULL(TRIM(PPS_HUNIT::text), '^^') 
            , '||', IFNULL(TRIM(PPS_CONHAP_OUT::text), '^^') 
            , '||', IFNULL(TRIM(PPS_HUNIT_OUT::text), '^^') 
            , '||', IFNULL(TRIM(PPS_ATPCHECK::text), '^^') 
            , '||', IFNULL(TRIM(PPS_PEG_FUT_AL::text), '^^') 
            , '||', IFNULL(TRIM(PPS_PEG_PAST_AL::text), '^^') 
            , '||', IFNULL(TRIM(SAPMP_TOLPRPL::text), '^^') 
            , '||', IFNULL(TRIM(SAPMP_TOLPRMI::text), '^^') 
            , '||', IFNULL(TRIM(VSO_R_PKGRP::text), '^^') 
            , '||', IFNULL(TRIM(VSO_R_LANE_NUM::text), '^^') 
            , '||', IFNULL(TRIM(VSO_R_PAL_VEND::text), '^^') 
            , '||', IFNULL(TRIM(VSO_R_FORK_DIR::text), '^^') 
            , '||', IFNULL(TRIM(IUID_RELEVANT::text), '^^') 
            , '||', IFNULL(TRIM(IUID_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(UID_IEA::text), '^^') 
            , '||', IFNULL(TRIM(CONS_PROCG::text), '^^') 
            , '||', IFNULL(TRIM(GI_PR_TIME::text), '^^') 
            , '||', IFNULL(TRIM(MULTIPLE_EKGRP::text), '^^') 
            , '||', IFNULL(TRIM(REF_SCHEMA::text), '^^') 
            , '||', IFNULL(TRIM(MIN_TROC::text), '^^') 
            , '||', IFNULL(TRIM(MAX_TROC::text), '^^') 
            , '||', IFNULL(TRIM(TARGET_STOCK::text), '^^') 
            , '||', IFNULL(TRIM(ZZOBSDT::text), '^^') 
            , '||', IFNULL(TRIM(ZZDPLA::text), '^^') 
            , '||', IFNULL(TRIM(ZZPLTSL::text), '^^') 
            , '||', IFNULL(TRIM(ZZEXLTM::text), '^^') 
            , '||', IFNULL(TRIM(ZZXMATNR::text), '^^') 
            , '||', IFNULL(TRIM(ZZSLSRCE::text), '^^') 
            , '||', IFNULL(TRIM(ZZGOVTMATCLASS::text), '^^') 
            , '||', IFNULL(TRIM(ZZSUPPLY_VAR_FCT::text), '^^') 
            , '||', IFNULL(TRIM(ZZATCOSTATUS::text), '^^') 
            , '||', IFNULL(TRIM(ZZ_SNP_HORIZ::text), '^^') 
            , '||', IFNULL(TRIM(ZZTARGET_DUR::text), '^^') 
            , '||', IFNULL(TRIM(ZZCTM::text), '^^') 
            , '||', IFNULL(TRIM(ZZTARGET_METHOD::text), '^^') 
            , '||', IFNULL(TRIM(ZZPLANNER_PPS::text), '^^') 
            , '||', IFNULL(TRIM(ZZDPREX::text), '^^') 
            , '||', IFNULL(TRIM(ZZSPREX::text), '^^') 
            , '||', IFNULL(TRIM(ZZRRP_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(ZZHEUR_ID::text), '^^') 
            , '||', IFNULL(TRIM(ZZSS_METHOD::text), '^^') 
            , '||', IFNULL(TRIM(ZZCONVH::text), '^^') 
            , '||', IFNULL(TRIM(ZZPEG_STRATEGY::text), '^^') 
            , '||', IFNULL(TRIM(ZZPEG_PAST_MAX::text), '^^') 
            , '||', IFNULL(TRIM(ZZPEG_FUTURE_MAX::text), '^^') 
            , '||', IFNULL(TRIM(ZZDELDATE::text), '^^') 
            , '||', IFNULL(TRIM(ZZFINLBQ::text), '^^') 
            , '||', IFNULL(TRIM(ZZWARRANTYDT::text), '^^') 
            , '||', IFNULL(TRIM(ZZPROD_PRIORITY::text), '^^') 
            , '||', IFNULL(TRIM(ZZPEROD_SPL_PROF::text), '^^') 
            , '||', IFNULL(TRIM(ZZSERVICE_TIME::text), '^^') 
            , '||', IFNULL(TRIM(ZZPLANNING_TIME::text), '^^') 
            , '||', IFNULL(TRIM(ZZFROZEN_PERIOD::text), '^^') 
            , '||', IFNULL(TRIM(ZZIOMINMAXTYPE::text), '^^') 
            , '||', IFNULL(TRIM(ZZIOMINSSVALUE::text), '^^') 
            , '||', IFNULL(TRIM(ZZIOMAXSSVALUE::text), '^^') 
            , '||', IFNULL(TRIM(ZZIOMINMAXREASON::text), '^^') 
            , '||', IFNULL(TRIM(ZZCOVPROFEQUAL::text), '^^') 
            , '||', IFNULL(TRIM(ZZIOOUTPUTCONT::text), '^^') 
            , '||', IFNULL(TRIM(ZZIOSAFETYSTOCK::text), '^^') 
            , '||', IFNULL(TRIM(ZZRISKMITWEEKS::text), '^^') 
            , '||', IFNULL(TRIM(ZZRISKMITSTOCK::text), '^^') 
            , '||', IFNULL(TRIM(ZZMANUALSSVALUE::text), '^^') 
            , '||', IFNULL(TRIM(ZZMANUALSSREASON::text), '^^') 
            , '||', IFNULL(TRIM(ZZIONOTES::text), '^^') 
            , '||', IFNULL(TRIM(ZZIOPRODTIME::text), '^^') 
            , '||', IFNULL(TRIM(ZZOPT::text), '^^') 
            , '||', IFNULL(TRIM(ZZPRODUCTIONOFFSET::text), '^^') 
            , '||', IFNULL(TRIM(ZZLEADTIMEOFFSET::text), '^^') 
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT