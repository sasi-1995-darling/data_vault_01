---- SRC LAYER ----
WITH
SRC_SITMN          as ( SELECT * FROM {{ ref('v_psa_stg_plant_item__moen_sap') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_SITMN          as ( SELECT * FROM STAGING.v_psa_stg_plant_item__MOEN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_SITMN as (
    SELECT
        PLANT_ITEM_HK
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
      , HASHDIFF
    FROM SRC_SITMN
)
---- RENAME LAYER ----

, RENAME_SITMN as (
    SELECT
        PLANT_ITEM_HK
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
      , HASHDIFF
    FROM LOGIC_SITMN
)
---- FILTER LAYER ----

, FILTER_SITMN as (
    SELECT *
    FROM RENAME_SITMN
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_SITMN
)

---- FINAL LAYER ----
SELECT
          PLANT_ITEM_HK
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
        , HASHDIFF
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.PLANT_ITEM_HK= JOIN_RESULT.PLANT_ITEM_HK
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %} 
{% if not is_incremental() %}
/*the following qualify is to restrict multiple loads of touched records during the initial build. Ex: multiple row per hk, hashdiff */
qualify 1= row_number()over(partition by PLANT_ITEM_HK, HASHDIFF order by PSA_LOAD_DTS)
union all
    SELECT        MD5_BINARY(GR.VALUE) AS PLANT_ITEM_HK     
         , GR.VALUE as MATNR
    , null as WERKS
    , null as MANDT
    , null as GLREQUEST
    , null as GLSOURCESYSTEM
    , null as PSTAT
    , null as LVORM
    , null as BWTTY
    , null as XCHAR
    , null as MMSTA
    , null as MATERIAL_STATUS
    , null as MMSTD
    , null as MAABC
    , null as KZKRI
    , null as EKGRP
    , null as AUSME
    , null as DISPR
    , null as DISMM
    , null as DISPO
    , null as KZDIE
    , null as PLIFZ
    , null as WEBAZ
    , null as PERKZ
    , null as AUSSS
    , null as DISLS
    , null as BESKZ
    , null as SOBSL
    , null as MINBE
    , null as EISBE
    , null as BSTMI
    , null as BSTMA
    , null as BSTFE
    , null as BSTRF
    , null as MABST
    , null as LOSFX
    , null as SBDKZ
    , null as LAGPR
    , null as ALTSL
    , null as KZAUS
    , null as AUSDT
    , null as NFMAT
    , null as KZBED
    , null as MISKZ
    , null as FHORI
    , null as PFREI
    , null as FFREI
    , null as RGEKZ
    , null as FEVOR
    , null as BEARZ
    , null as RUEZT
    , null as TRANZ
    , null as BASMG
    , null as DZEIT
    , null as MAXLZ
    , null as LZEIH
    , null as KZPRO
    , null as GPMKZ
    , null as UEETO
    , null as UEETK
    , null as UNETO
    , null as WZEIT
    , null as ATPKZ
    , null as VZUSL
    , null as HERBL
    , null as INSMK
    , null as SPROZ
    , null as QUAZT
    , null as SSQSS
    , null as MPDAU
    , null as KZPPV
    , null as KZDKZ
    , null as WSTGH
    , null as PRFRQ
    , null as NKMPR
    , null as UMLMC
    , null as LADGR
    , null as XCHPF
    , null as USEQU
    , null as LGRAD
    , null as AUFTL
    , null as PLVAR
    , null as OTYPE
    , null as OBJID
    , null as MTVFP
    , null as PERIV
    , null as KZKFK
    , null as VRVEZ
    , null as VBAMG
    , null as VBEAZ
    , null as LIZYK
    , null as BWSCL
    , null as KAUTB
    , null as KORDB
    , null as STAWN
    , null as HERKL
    , null as HERKR
    , null as EXPME
    , null as MTVER
    , null as PRCTR
    , null as TRAME
    , null as MRPPP
    , null as SAUFT
    , null as FXHOR
    , null as VRMOD
    , null as VINT1
    , null as VINT2
    , null as VERKZ
    , null as STLAL
    , null as STLAN
    , null as PLNNR
    , null as APLAL
    , null as LOSGR
    , null as SOBSK
    , null as FRTME
    , null as LGPRO
    , null as DISGR
    , null as KAUSF
    , null as QZGTP
    , null as QMATV
    , null as TAKZT
    , null as RWPRO
    , null as COPAM
    , null as ABCIN
    , null as AWSLS
    , null as SERNP
    , null as CUOBJ
    , null as STDPD
    , null as SFEPR
    , null as XMCNG
    , null as QSSYS
    , null as LFRHY
    , null as RDPRF
    , null as VRBMT
    , null as VRBWK
    , null as VRBDT
    , null as VRBFK
    , null as AUTRU
    , null as PREFE
    , null as PRENC
    , null as PRENO
    , null as PREND
    , null as PRENE
    , null as PRENG
    , null as ITARK
    , null as SERVG
    , null as KZKUP
    , null as STRGR
    , null as CUOBV
    , null as LGFSB
    , null as SCHGT
    , null as CCFIX
    , null as EPRIO
    , null as QMATA
    , null as RESVP
    , null as PLNTY
    , null as UOMGR
    , null as UMRSL
    , null as ABFAC
    , null as SFCPF
    , null as SHFLG
    , null as SHZET
    , null as MDACH
    , null as KZECH
    , null as MEGRU
    , null as MFRGR
    , null as VKUMC
    , null as VKTRW
    , null as KZAGL
    , null as FVIDK
    , null as FXPRU
    , null as LOGGR
    , null as FPRFM
    , null as GLGMG
    , null as VKGLG
    , null as INDUS
    , null as MOWNR
    , null as MOGRU
    , null as CASNR
    , null as GPNUM
    , null as STEUC
    , null as FABKZ
    , null as MATGR
    , null as VSPVB
    , null as DPLFS
    , null as DPLPU
    , null as DPLHO
    , null as MINLS
    , null as MAXLS
    , null as FIXLS
    , null as LTINC
    , null as COMPL
    , null as CONVT
    , null as SHPRO
    , null as AHDIS
    , null as DIBER
    , null as KZPSP
    , null as OCMPF
    , null as APOKZ
    , null as MCRUE
    , null as LFMON
    , null as LFGJA
    , null as EISLO
    , null as NCOST
    , null as ROTATION_DATE
    , null as UCHKZ
    , null as UCMAT
    , null as BWESB
    , null as SGT_COVS
    , null as SGT_STATC
    , null as SGT_SCOPE
    , null as SGT_MRPSI
    , null as SGT_PRCM
    , null as SGT_CHINT
    , null as SGT_STK_PRT
    , null as SGT_DEFSC
    , null as SGT_MRP_ATP_STATUS
    , null as SGT_MMSTD
    , null as FSH_MG_ARUN_REQ
    , null as FSH_SEAIM
    , null as FSH_VAR_GROUP
    , null as FSH_KZECH
    , null as FSH_CALENDAR_GROUP
    , null as PPSKZ
    , null as PPS_STRATEGY
    , null as PPS_PLANNING_TYPE
    , null as PPS_HEUR_ID
    , null as PPS_FIXPEG
    , null as PPS_PEG_STRATEGY
    , null as PPS_GRPRT
    , null as PPS_GIPRT
    , null as PPS_CONHAP
    , null as PPS_HUNIT
    , null as PPS_CONHAP_OUT
    , null as PPS_HUNIT_OUT
    , null as PPS_ATPCHECK
    , null as PPS_PEG_FUT_AL
    , null as PPS_PEG_PAST_AL
    , null as SAPMP_TOLPRPL
    , null as SAPMP_TOLPRMI
    , null as VSO_R_PKGRP
    , null as VSO_R_LANE_NUM
    , null as VSO_R_PAL_VEND
    , null as VSO_R_FORK_DIR
    , null as IUID_RELEVANT
    , null as IUID_TYPE
    , null as UID_IEA
    , null as CONS_PROCG
    , null as GI_PR_TIME
    , null as MULTIPLE_EKGRP
    , null as REF_SCHEMA
    , null as MIN_TROC
    , null as MAX_TROC
    , null as TARGET_STOCK
    , null as ZZOBSDT
    , null as ZZDPLA
    , null as ZZPLTSL
    , null as ZZEXLTM
    , null as ZZXMATNR
    , null as ZZSLSRCE
    , null as ZZGOVTMATCLASS
    , null as ZZSUPPLY_VAR_FCT
    , null as ZZATCOSTATUS
    , null as ZZ_SNP_HORIZ
    , null as ZZTARGET_DUR
    , null as ZZCTM
    , null as ZZTARGET_METHOD
    , null as ZZPLANNER_PPS
    , null as ZZDPREX
    , null as ZZSPREX
    , null as ZZRRP_TYPE
    , null as ZZHEUR_ID
    , null as ZZSS_METHOD
    , null as ZZCONVH
    , null as ZZPEG_STRATEGY
    , null as ZZPEG_PAST_MAX
    , null as ZZPEG_FUTURE_MAX
    , null as ZZDELDATE
    , null as ZZFINLBQ
    , null as ZZWARRANTYDT
    , null as ZZPROD_PRIORITY
    , null as ZZPEROD_SPL_PROF
    , null as ZZSERVICE_TIME
    , null as ZZPLANNING_TIME
    , null as ZZFROZEN_PERIOD
    , null as ZZIOMINMAXTYPE
    , null as ZZIOMINSSVALUE
    , null as ZZIOMAXSSVALUE
    , null as ZZIOMINMAXREASON
    , null as ZZCOVPROFEQUAL
    , null as ZZIOOUTPUTCONT
    , null as ZZIOSAFETYSTOCK
    , null as ZZRISKMITWEEKS
    , null as ZZRISKMITSTOCK
    , null as ZZMANUALSSVALUE
    , null as ZZMANUALSSREASON
    , null as ZZIONOTES
    , null as ZZIOPRODTIME
    , null as ZZOPT
    , null as ZZPRODUCTIONOFFSET
    , null as ZZLEADTIMEOFFSET
    , null as GLDELFLAG
    , null as GLCHANGETIME
    , null as PSA_DELETE_IND
    , null as PSA_LOAD_DTS
    , null as PSA_RECORD_SOURCE
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)::TIMESTAMP as LOAD_DTS
,'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
, ''::BINARY as HASHDIFF
  FROM
        TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}