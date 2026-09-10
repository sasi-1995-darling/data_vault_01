---- SRC LAYER ----
WITH
SRC_b              as ( SELECT * FROM {{ ref('v_psa_stg_plant_item__moen_sap') }} as SRC 
                        {% if is_incremental() %}
                        WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}}){% endif %} )

/*
SRC_b              as ( SELECT * FROM STAGING.v_psa_stg_plant_item__moen_sap )
*/
---- LOGIC LAYER ----

, LOGIC_b as (
    SELECT
        LNK_ITEM_PLANT_SPECIAL_PROCUREMENT_HK
      , MANDT
      , MATNR
      , WERKS
      , GLREQUEST
      , GLSOURCESYSTEM
      , PSTAT
      , LVORM
      , BWTTY
      , XCHAR
      , MMSTA
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
      , MAX_TROC
      , TARGET_STOCK
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
      , PSA_LOAD_DTS
      , PSA_DELETE_IND
      , PSA_RECORD_SOURCE
      , VINT2
      , NKMPR
      , AUSDT
      , MIN_TROC
      , LFMON
      , PPS_HUNIT
      , ZZOBSDT
      , LOAD_DTS
      , HASHDIFF
      , REC_SRC
    FROM SRC_b
)
---- RENAME LAYER ----

, RENAME_b as (
    SELECT
        LNK_ITEM_PLANT_SPECIAL_PROCUREMENT_HK
      , MANDT
      , MATNR
      , WERKS
      , GLREQUEST
      , GLSOURCESYSTEM
      , PSTAT
      , LVORM
      , BWTTY
      , XCHAR
      , MMSTA
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
      , MAX_TROC
      , TARGET_STOCK
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
      , PSA_LOAD_DTS
      , PSA_DELETE_IND
      , PSA_RECORD_SOURCE
      , VINT2
      , NKMPR
      , AUSDT
      , MIN_TROC
      , LFMON
      , PPS_HUNIT
      , ZZOBSDT
      , LOAD_DTS
      , HASHDIFF
      , REC_SRC
    FROM LOGIC_b
)
---- FILTER LAYER ----

, FILTER_b as (
    SELECT *
    FROM RENAME_b
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_b
)

---- FINAL LAYER ----
SELECT
          LNK_ITEM_PLANT_SPECIAL_PROCUREMENT_HK
        , MANDT
        , MATNR
        , WERKS
        , GLREQUEST
        , GLSOURCESYSTEM
        , PSTAT
        , LVORM
        , BWTTY
        , XCHAR
        , MMSTA
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
        , MAX_TROC
        , TARGET_STOCK
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
        , PSA_LOAD_DTS
        , PSA_DELETE_IND
        , PSA_RECORD_SOURCE
        , VINT2
        , NKMPR
        , AUSDT
        , MIN_TROC
        , LFMON
        , PPS_HUNIT
        , ZZOBSDT
        , LOAD_DTS
        , HASHDIFF
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.LNK_ITEM_PLANT_SPECIAL_PROCUREMENT_HK = JOIN_RESULT.LNK_ITEM_PLANT_SPECIAL_PROCUREMENT_HK
   AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %}
{% if not is_incremental() %}

/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per HK and hashdiff. */
qualify 1 = row_number() over (partition by LNK_ITEM_PLANT_SPECIAL_PROCUREMENT_HK, HASHDIFF order by PSA_LOAD_DTS)

union all
SELECT 
MD5_BINARY(GR.VALUE) AS LNK_ITEM_PLANT_SPECIAL_PROCUREMENT_HK,
NULL AS MANDT,
GR.VALUE::text AS MATNR,
GR.VALUE::text AS WERKS,
NULL AS GLREQUEST,
NULL AS GLSOURCESYSTEM,
NULL AS PSTAT,
NULL AS LVORM,
NULL AS BWTTY,
NULL AS XCHAR,
NULL AS MMSTA,
NULL AS MMSTD,
NULL AS MAABC,
NULL AS KZKRI,
NULL AS EKGRP,
NULL AS AUSME,
NULL AS DISPR,
NULL AS DISMM,
NULL AS DISPO,
NULL AS KZDIE,
NULL AS PLIFZ,
NULL AS WEBAZ,
NULL AS PERKZ,
NULL AS AUSSS,
NULL AS DISLS,
NULL AS BESKZ,
NULL AS SOBSL,
NULL AS MINBE,
NULL AS EISBE,
NULL AS BSTMI,
NULL AS BSTMA,
NULL AS BSTFE,
NULL AS BSTRF,
NULL AS MABST,
NULL AS LOSFX,
NULL AS SBDKZ,
NULL AS LAGPR,
NULL AS ALTSL,
NULL AS KZAUS,
NULL AS NFMAT,
NULL AS KZBED,
NULL AS MISKZ,
NULL AS FHORI,
NULL AS PFREI,
NULL AS FFREI,
NULL AS RGEKZ,
NULL AS FEVOR,
NULL AS BEARZ,
NULL AS RUEZT,
NULL AS TRANZ,
NULL AS BASMG,
NULL AS DZEIT,
NULL AS MAXLZ,
NULL AS LZEIH,
NULL AS KZPRO,
NULL AS GPMKZ,
NULL AS UEETO,
NULL AS UEETK,
NULL AS UNETO,
NULL AS WZEIT,
NULL AS ATPKZ,
NULL AS VZUSL,
NULL AS HERBL,
NULL AS INSMK,
NULL AS SPROZ,
NULL AS QUAZT,
NULL AS SSQSS,
NULL AS MPDAU,
NULL AS KZPPV,
NULL AS KZDKZ,
NULL AS WSTGH,
NULL AS PRFRQ,
NULL AS UMLMC,
NULL AS LADGR,
NULL AS XCHPF,
NULL AS USEQU,
NULL AS LGRAD,
NULL AS AUFTL,
NULL AS PLVAR,
NULL AS OTYPE,
NULL AS OBJID,
NULL AS MTVFP,
NULL AS PERIV,
NULL AS KZKFK,
NULL AS VRVEZ,
NULL AS VBAMG,
NULL AS VBEAZ,
NULL AS LIZYK,
NULL AS BWSCL,
NULL AS KAUTB,
NULL AS KORDB,
NULL AS STAWN,
NULL AS HERKL,
NULL AS HERKR,
NULL AS EXPME,
NULL AS MTVER,
NULL AS PRCTR,
NULL AS TRAME,
NULL AS MRPPP,
NULL AS SAUFT,
NULL AS FXHOR,
NULL AS VRMOD,
NULL AS VINT1,
NULL AS VERKZ,
NULL AS STLAL,
NULL AS STLAN,
NULL AS PLNNR,
NULL AS APLAL,
NULL AS LOSGR,
NULL AS SOBSK,
NULL AS FRTME,
NULL AS LGPRO,
NULL AS DISGR,
NULL AS KAUSF,
NULL AS QZGTP,
NULL AS QMATV,
NULL AS TAKZT,
NULL AS RWPRO,
NULL AS COPAM,
NULL AS ABCIN,
NULL AS AWSLS,
NULL AS SERNP,
NULL AS CUOBJ,
NULL AS STDPD,
NULL AS SFEPR,
NULL AS XMCNG,
NULL AS QSSYS,
NULL AS LFRHY,
NULL AS RDPRF,
NULL AS VRBMT,
NULL AS VRBWK,
NULL AS VRBDT,
NULL AS VRBFK,
NULL AS AUTRU,
NULL AS PREFE,
NULL AS PRENC,
NULL AS PRENO,
NULL AS PREND,
NULL AS PRENE,
NULL AS PRENG,
NULL AS ITARK,
NULL AS SERVG,
NULL AS KZKUP,
NULL AS STRGR,
NULL AS CUOBV,
NULL AS LGFSB,
NULL AS SCHGT,
NULL AS CCFIX,
NULL AS EPRIO,
NULL AS QMATA,
NULL AS RESVP,
NULL AS PLNTY,
NULL AS UOMGR,
NULL AS UMRSL,
NULL AS ABFAC,
NULL AS SFCPF,
NULL AS SHFLG,
NULL AS SHZET,
NULL AS MDACH,
NULL AS KZECH,
NULL AS MEGRU,
NULL AS MFRGR,
NULL AS VKUMC,
NULL AS VKTRW,
NULL AS KZAGL,
NULL AS FVIDK,
NULL AS FXPRU,
NULL AS LOGGR,
NULL AS FPRFM,
NULL AS GLGMG,
NULL AS VKGLG,
NULL AS INDUS,
NULL AS MOWNR,
NULL AS MOGRU,
NULL AS CASNR,
NULL AS GPNUM,
NULL AS STEUC,
NULL AS FABKZ,
NULL AS MATGR,
NULL AS VSPVB,
NULL AS DPLFS,
NULL AS DPLPU,
NULL AS DPLHO,
NULL AS MINLS,
NULL AS MAXLS,
NULL AS FIXLS,
NULL AS LTINC,
NULL AS COMPL,
NULL AS CONVT,
NULL AS SHPRO,
NULL AS AHDIS,
NULL AS DIBER,
NULL AS KZPSP,
NULL AS OCMPF,
NULL AS APOKZ,
NULL AS MCRUE,
NULL AS LFGJA,
NULL AS EISLO,
NULL AS NCOST,
NULL AS ROTATION_DATE,
NULL AS UCHKZ,
NULL AS UCMAT,
NULL AS BWESB,
NULL AS SGT_COVS,
NULL AS SGT_STATC,
NULL AS SGT_SCOPE,
NULL AS SGT_MRPSI,
NULL AS SGT_PRCM,
NULL AS SGT_CHINT,
NULL AS SGT_STK_PRT,
NULL AS SGT_DEFSC,
NULL AS SGT_MRP_ATP_STATUS,
NULL AS SGT_MMSTD,
NULL AS FSH_MG_ARUN_REQ,
NULL AS FSH_SEAIM,
NULL AS FSH_VAR_GROUP,
NULL AS FSH_KZECH,
NULL AS FSH_CALENDAR_GROUP,
NULL AS PPSKZ,
NULL AS PPS_STRATEGY,
NULL AS PPS_PLANNING_TYPE,
NULL AS PPS_HEUR_ID,
NULL AS PPS_FIXPEG,
NULL AS PPS_PEG_STRATEGY,
NULL AS PPS_GRPRT,
NULL AS PPS_GIPRT,
NULL AS PPS_CONHAP,
NULL AS PPS_CONHAP_OUT,
NULL AS PPS_HUNIT_OUT,
NULL AS PPS_ATPCHECK,
NULL AS PPS_PEG_FUT_AL,
NULL AS PPS_PEG_PAST_AL,
NULL AS SAPMP_TOLPRPL,
NULL AS SAPMP_TOLPRMI,
NULL AS VSO_R_PKGRP,
NULL AS VSO_R_LANE_NUM,
NULL AS VSO_R_PAL_VEND,
NULL AS VSO_R_FORK_DIR,
NULL AS IUID_RELEVANT,
NULL AS IUID_TYPE,
NULL AS UID_IEA,
NULL AS CONS_PROCG,
NULL AS GI_PR_TIME,
NULL AS MULTIPLE_EKGRP,
NULL AS REF_SCHEMA,
NULL AS MAX_TROC,
NULL AS TARGET_STOCK,
NULL AS ZZDPLA,
NULL AS ZZPLTSL,
NULL AS ZZEXLTM,
NULL AS ZZXMATNR,
NULL AS ZZSLSRCE,
NULL AS ZZGOVTMATCLASS,
NULL AS ZZSUPPLY_VAR_FCT,
NULL AS ZZATCOSTATUS,
NULL AS ZZ_SNP_HORIZ,
NULL AS ZZTARGET_DUR,
NULL AS ZZCTM,
NULL AS ZZTARGET_METHOD,
NULL AS ZZPLANNER_PPS,
NULL AS ZZDPREX,
NULL AS ZZSPREX,
NULL AS ZZRRP_TYPE,
NULL AS ZZHEUR_ID,
NULL AS ZZSS_METHOD,
NULL AS ZZCONVH,
NULL AS ZZPEG_STRATEGY,
NULL AS ZZPEG_PAST_MAX,
NULL AS ZZPEG_FUTURE_MAX,
NULL AS ZZDELDATE,
NULL AS ZZFINLBQ,
NULL AS ZZWARRANTYDT,
NULL AS ZZPROD_PRIORITY,
NULL AS ZZPEROD_SPL_PROF,
NULL AS ZZSERVICE_TIME,
NULL AS ZZPLANNING_TIME,
NULL AS ZZFROZEN_PERIOD,
NULL AS ZZIOMINMAXTYPE,
NULL AS ZZIOMINSSVALUE,
NULL AS ZZIOMAXSSVALUE,
NULL AS ZZIOMINMAXREASON,
NULL AS ZZCOVPROFEQUAL,
NULL AS ZZIOOUTPUTCONT,
NULL AS ZZIOSAFETYSTOCK,
NULL AS ZZRISKMITWEEKS,
NULL AS ZZRISKMITSTOCK,
NULL AS ZZMANUALSSVALUE,
NULL AS ZZMANUALSSREASON,
NULL AS ZZIONOTES,
NULL AS ZZIOPRODTIME,
NULL AS ZZOPT,
NULL AS ZZPRODUCTIONOFFSET,
NULL AS ZZLEADTIMEOFFSET,
NULL AS GLDELFLAG,
NULL AS GLCHANGETIME,
'1900-01-01'::TIMESTAMP AS PSA_LOAD_DTS,
'N' AS PSA_DELETE_IND,
NULL AS PSA_RECORD_SOURCE,
NULL AS VINT2,
NULL AS NKMPR,
NULL AS AUSDT,
NULL AS MIN_TROC,
NULL AS LFMON,
NULL AS PPS_HUNIT,
NULL AS ZZOBSDT,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
''::BINARY AS HASHDIFF,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}