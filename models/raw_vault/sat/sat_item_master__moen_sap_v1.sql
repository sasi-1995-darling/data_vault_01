---- SRC LAYER ----
WITH
SRC_itmstrws       as ( SELECT * FROM {{ ref('v_psa_stg_item_master__moen_sap') }} as SRC 
                        {% if is_incremental() %}
                              where src.load_dts > (select dateadd('HOUR',-1,max(load_dts)) from {{ this }})
                            {% endif %}   )

/*
SRC_itmstrws       as ( SELECT * FROM STAGING.V_PSA_STG_ITEM_MASTER__MOEN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_itmstrws as (
    SELECT
        ITEM_HK
      , MATNR                                                        as                                            ITEM_ID
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
      , MTART                                                        as                                     ITEM_TYPE_CODE
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
      , MSTAE                                                        as                                        ITEM_STATUS
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
      , ZZDTP                                                        as                                       ITEM_LINE_ID
      , ZZFIN                                                        as                                     ITEM_FINISH_ID
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
      , ZZCPF                                                        as                             ITEM_PRICE_CATEGORY_ID
      , ZZFIRSTSHIPDATE
      , ZZBUSOWN                                                     as                                  BUSINESS_OWNER_ID
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
      , ZZBASE_MATNR                                                 as                                      BASE_MATERIAL
      , ZZPRL
      , ZZBUSUNITOWN                                                 as                                   BUSINESS_UNIT_ID
      , ZZCRITICAL_SUB
      , ZZBRAND
      , ZZMARKET
      , ZZPTG                                                        as                           ITEM_PRICE_TYPE_GROUP_ID
      , ZZMKG
      , ZZPLTG
      , ZZPLT                                                        as                                   ITEM_PLATFORM_ID
      , ZZPTGK                                                       as                                      ITEM_GROUP_ID
      , ZZPTK                                                        as                                       ITEM_TYPE_ID
      , ZZRMAREA                                                     as                                       ROOM_AREA_ID
      , ZZPACKQT
      , ZZOPTYPE
      , ZZVALTYPE
      , ZZMKG_FLAG                                                   as                                          IMAP_FLAG
      , ZZPLTG_FLAG
      , ZZSTOCKSTRATEGY
      , ZZNOOFHANDLES
      , ZZARCH                                                       as                               ITEM_ARCHITECTURE_ID
      , ZZARCHDET
      , ZZSTYLE
      , ZZLEGMATNR
      , ZZPRODUCTVITALITY
      , ZZWHENNEWDATE
      , ZZREPCATG                                                    as                              REPORTING_CATEGORY_ID
      , GLDELFLAG
      , GLCHANGETIME
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , LOAD_DTS
      , REC_SRC
      , HASHDIFF
    FROM SRC_itmstrws
)
---- RENAME LAYER ----

, RENAME_itmstrws as (
    SELECT
        ITEM_HK
      , ITEM_ID
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
      , ITEM_TYPE_CODE
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
      , ITEM_STATUS
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
      , ITEM_LINE_ID
      , ITEM_FINISH_ID
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
      , ITEM_PRICE_CATEGORY_ID
      , ZZFIRSTSHIPDATE
      , BUSINESS_OWNER_ID
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
      , BASE_MATERIAL
      , ZZPRL
      , BUSINESS_UNIT_ID
      , ZZCRITICAL_SUB
      , ZZBRAND
      , ZZMARKET
      , ITEM_PRICE_TYPE_GROUP_ID
      , ZZMKG
      , ZZPLTG
      , ITEM_PLATFORM_ID
      , ITEM_GROUP_ID
      , ITEM_TYPE_ID
      , ROOM_AREA_ID
      , ZZPACKQT
      , ZZOPTYPE
      , ZZVALTYPE
      , IMAP_FLAG
      , ZZPLTG_FLAG
      , ZZSTOCKSTRATEGY
      , ZZNOOFHANDLES
      , ITEM_ARCHITECTURE_ID
      , ZZARCHDET
      , ZZSTYLE
      , ZZLEGMATNR
      , ZZPRODUCTVITALITY
      , ZZWHENNEWDATE
      , REPORTING_CATEGORY_ID
      , GLDELFLAG
      , GLCHANGETIME
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , LOAD_DTS
      , REC_SRC
      , HASHDIFF
    FROM LOGIC_itmstrws
)
---- FILTER LAYER ----

, FILTER_itmstrws as (
    SELECT *
    FROM RENAME_itmstrws
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_itmstrws
)

---- FINAL LAYER ----
SELECT
          ITEM_HK
        , ITEM_ID
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
        , ITEM_TYPE_CODE
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
        , ITEM_STATUS
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
        , ITEM_LINE_ID
        , ITEM_FINISH_ID
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
        , ITEM_PRICE_CATEGORY_ID
        , ZZFIRSTSHIPDATE
        , BUSINESS_OWNER_ID
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
        , BASE_MATERIAL
        , ZZPRL
        , BUSINESS_UNIT_ID
        , ZZCRITICAL_SUB
        , ZZBRAND
        , ZZMARKET
        , ITEM_PRICE_TYPE_GROUP_ID
        , ZZMKG
        , ZZPLTG
        , ITEM_PLATFORM_ID
        , ITEM_GROUP_ID
        , ITEM_TYPE_ID
        , ROOM_AREA_ID
        , ZZPACKQT
        , ZZOPTYPE
        , ZZVALTYPE
        , IMAP_FLAG
        , ZZPLTG_FLAG
        , ZZSTOCKSTRATEGY
        , ZZNOOFHANDLES
        , ITEM_ARCHITECTURE_ID
        , ZZARCHDET
        , ZZSTYLE
        , ZZLEGMATNR
        , ZZPRODUCTVITALITY
        , ZZWHENNEWDATE
        , REPORTING_CATEGORY_ID
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
    WHERE existing.ITEM_HK = JOIN_RESULT.ITEM_HK
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %}
{% if not is_incremental() %}

/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per HK and hashdiff. */
qualify 1 = row_number() over (partition by ITEM_HK, ITEM_ID, BRAND_ID, ITEM_LINE_ID, ITEM_FINISH_ID, ITEM_PRICE_CATEGORY_ID, BUSINESS_OWNER_ID, BUSINESS_UNIT_ID, ITEM_PRICE_TYPE_GROUP_ID, ITEM_PLATFORM_ID, ITEM_GROUP_ID, ITEM_TYPE_ID, ROOM_AREA_ID, ITEM_ARCHITECTURE_ID, REPORTING_CATEGORY_ID, HASHDIFF order by PSA_LOAD_DTS)

union all
SELECT 
MD5_BINARY(GR.VALUE) AS ITEM_HK,
GR.VALUE::text AS ITEM_ID,
NULL AS MANDT,
NULL AS GLREQUEST,
NULL AS GLSOURCESYSTEM,
NULL AS ERSDA,
NULL AS ERNAM,
NULL AS LAEDA,
NULL AS AENAM,
NULL AS VPSTA,
NULL AS PSTAT,
NULL AS LVORM,
NULL AS ITEM_TYPE_CODE,
NULL AS MBRSH,
NULL AS MATKL,
NULL AS BISMT,
NULL AS MEINS,
NULL AS BSTME,
NULL AS ZEINR,
NULL AS ZEIAR,
NULL AS ZEIVR,
NULL AS ZEIFO,
NULL AS AESZN,
NULL AS BLATT,
NULL AS BLANZ,
NULL AS FERTH,
NULL AS FORMT,
NULL AS GROES,
NULL AS WRKST,
NULL AS NORMT,
NULL AS LABOR,
NULL AS EKWSL,
NULL AS BRGEW,
NULL AS NTGEW,
NULL AS GEWEI,
NULL AS VOLUM,
NULL AS VOLEH,
NULL AS BEHVO,
NULL AS RAUBE,
NULL AS TEMPB,
NULL AS DISST,
NULL AS TRAGR,
NULL AS STOFF,
NULL AS SPART,
NULL AS KUNNR,
NULL AS EANNR,
NULL AS WESCH,
NULL AS BWVOR,
NULL AS BWSCL,
NULL AS SAISO,
NULL AS ETIAR,
NULL AS ETIFO,
NULL AS ENTAR,
NULL AS EAN11,
NULL AS NUMTP,
NULL AS LAENG,
NULL AS BREIT,
NULL AS HOEHE,
NULL AS MEABM,
NULL AS PRDHA,
NULL AS AEKLK,
NULL AS CADKZ,
NULL AS QMPUR,
NULL AS ERGEW,
NULL AS ERGEI,
NULL AS ERVOL,
NULL AS ERVOE,
NULL AS GEWTO,
NULL AS VOLTO,
NULL AS VABME,
NULL AS KZREV,
NULL AS KZKFG,
NULL AS XCHPF,
NULL AS VHART,
NULL AS FUELG,
NULL AS STFAK,
NULL AS MAGRV,
NULL AS BEGRU,
NULL AS DATAB,
NULL AS LIQDT,
NULL AS SAISJ,
NULL AS PLGTP,
NULL AS MLGUT,
NULL AS EXTWG,
NULL AS SATNR,
NULL AS ATTYP,
NULL AS KZKUP,
NULL AS KZNFM,
NULL AS PMATA,
NULL AS ITEM_STATUS,
NULL AS MSTAV,
NULL AS MSTDE,
NULL AS MSTDV,
NULL AS TAKLV,
NULL AS RBNRM,
NULL AS MHDRZ,
NULL AS MHDHB,
NULL AS MHDLP,
NULL AS INHME,
NULL AS INHAL,
NULL AS VPREH,
NULL AS ETIAG,
NULL AS INHBR,
NULL AS CMETH,
NULL AS CUOBF,
NULL AS KZUMW,
NULL AS KOSCH,
NULL AS SPROF,
NULL AS NRFHG,
NULL AS MFRPN,
NULL AS MFRNR,
NULL AS BMATN,
NULL AS MPROF,
NULL AS KZWSM,
NULL AS SAITY,
NULL AS PROFL,
NULL AS IHIVI,
NULL AS ILOOS,
NULL AS SERLV,
NULL AS KZGVH,
NULL AS XGCHP,
NULL AS KZEFF,
NULL AS COMPL,
NULL AS IPRKZ,
NULL AS RDMHD,
NULL AS PRZUS,
NULL AS MTPOS_MARA,
NULL AS BFLME,
NULL AS MATFI,
NULL AS CMREL,
NULL AS BBTYP,
NULL AS SLED_BBD,
NULL AS GTIN_VARIANT,
NULL AS GENNR,
NULL AS RMATP,
NULL AS GDS_RELEVANT,
NULL AS WEORA,
NULL AS HUTYP_DFLT,
NULL AS PILFERABLE,
NULL AS WHSTC,
NULL AS WHMATGR,
NULL AS HNDLCODE,
NULL AS HAZMAT,
NULL AS HUTYP,
NULL AS TARE_VAR,
NULL AS MAXC,
NULL AS MAXC_TOL,
NULL AS MAXL,
NULL AS MAXB,
NULL AS MAXH,
NULL AS MAXDIM_UOM,
NULL AS HERKL,
NULL AS MFRGR,
NULL AS QQTIME,
NULL AS QQTIMEUOM,
NULL AS QGRP,
NULL AS SERIAL,
NULL AS PS_SMARTFORM,
NULL AS LOGUNIT,
NULL AS CWQREL,
NULL AS CWQPROC,
NULL AS CWQTOLGR,
NULL AS ADPROF,
NULL AS IPMIPPRODUCT,
NULL AS ALLOW_PMAT_IGNO,
NULL AS MEDIUM,
NULL AS COMMODITY,
NULL AS ANIMAL_ORIGIN,
NULL AS TEXTILE_COMP_IND,
NULL AS SGT_CSGR,
NULL AS SGT_COVSA,
NULL AS SGT_STAT,
NULL AS SGT_SCOPE,
NULL AS SGT_REL,
NULL AS FSH_MG_AT1,
NULL AS FSH_MG_AT2,
NULL AS FSH_MG_AT3,
NULL AS FSH_SEALV,
NULL AS FSH_SEAIM,
NULL AS FSH_SC_MID,
NULL AS ANP,
NULL AS PSM_CODE,
NULL AS BEV1_LULEINH,
NULL AS BEV1_LULDEGRP,
NULL AS BEV1_NESTRUCCAT,
NULL AS DSD_SL_TOLTYP,
NULL AS DSD_SV_CNT_GRP,
NULL AS DSD_VC_GROUP,
NULL AS VSO_R_TILT_IND,
NULL AS VSO_R_STACK_IND,
NULL AS VSO_R_BOT_IND,
NULL AS VSO_R_TOP_IND,
NULL AS VSO_R_STACK_NO,
NULL AS VSO_R_PAL_IND,
NULL AS VSO_R_PAL_OVR_D,
NULL AS VSO_R_PAL_OVR_W,
NULL AS VSO_R_PAL_B_HT,
NULL AS VSO_R_PAL_MIN_H,
NULL AS VSO_R_TOL_B_HT,
NULL AS VSO_R_NO_P_GVH,
NULL AS VSO_R_QUAN_UNIT,
NULL AS VSO_R_KZGVH_IND,
NULL AS PACKCODE,
NULL AS DG_PACK_STATUS,
NULL AS MCOND,
NULL AS RETDELC,
NULL AS LOGLEV_RETO,
NULL AS NSNID,
NULL AS ADSPC_SPC,
NULL AS IMATN,
NULL AS PICNUM,
NULL AS BSTAT,
NULL AS COLOR_ATINN,
NULL AS SIZE1_ATINN,
NULL AS SIZE2_ATINN,
NULL AS COLOR,
NULL AS SIZE1,
NULL AS SIZE2,
NULL AS FREE_CHAR,
NULL AS CARE_CODE,
NULL AS BRAND_ID,
NULL AS FIBER_CODE1,
NULL AS FIBER_PART1,
NULL AS FIBER_CODE2,
NULL AS FIBER_PART2,
NULL AS FIBER_CODE3,
NULL AS FIBER_PART3,
NULL AS FIBER_CODE4,
NULL AS FIBER_PART4,
NULL AS FIBER_CODE5,
NULL AS FIBER_PART5,
NULL AS FASHGRD,
NULL AS ZZTYP,
NULL AS ZZSEG,
NULL AS ZZLIN,
NULL AS ITEM_LINE_ID,
NULL AS ITEM_FINISH_ID,
NULL AS ZZHAN,
NULL AS ZZMAJ,
NULL AS ZZMIN,
NULL AS ZZPMI,
NULL AS ZZIDT,
NULL AS ZZMG1,
NULL AS ZZROM,
NULL AS ZZWST,
NULL AS ZZWST1,
NULL AS ZZSTS,
NULL AS ZZDDT,
NULL AS ZZQTP,
NULL AS ZZQCD,
NULL AS ZZLIFOCODE,
NULL AS ZZEXC,
NULL AS ZZPLG,
NULL AS ZZMFG,
NULL AS ZZPROJ,
NULL AS ZZPLA,
NULL AS ZZINVOWNER,
NULL AS ZZINVOWNER_MFG,
NULL AS ITEM_PRICE_CATEGORY_ID,
NULL AS ZZFIRSTSHIPDATE,
NULL AS BUSINESS_OWNER_ID,
NULL AS ZZBUSOWNINV,
NULL AS ZZFCSTP,
NULL AS ZZULTS,
NULL AS ZZDEPLOYRULE,
NULL AS ZZPARTPOPULATION,
NULL AS ZZLIFECYCLE,
NULL AS ZZPENDING_TRANS,
NULL AS ZZRISK_PRO,
NULL AS ZZFCST_BASE,
NULL AS ZZWETTED,
NULL AS ZZWSMEINS,
NULL AS ZZLEAD_PER,
NULL AS BASE_MATERIAL,
NULL AS ZZPRL,
NULL AS BUSINESS_UNIT_ID,
NULL AS ZZCRITICAL_SUB,
NULL AS ZZBRAND,
NULL AS ZZMARKET,
NULL AS ITEM_PRICE_TYPE_GROUP_ID,
NULL AS ZZMKG,
NULL AS ZZPLTG,
NULL AS ITEM_PLATFORM_ID,
NULL AS ITEM_GROUP_ID,
NULL AS ITEM_TYPE_ID,
NULL AS ROOM_AREA_ID,
NULL AS ZZPACKQT,
NULL AS ZZOPTYPE,
NULL AS ZZVALTYPE,
NULL AS IMAP_FLAG,
NULL AS ZZPLTG_FLAG,
NULL AS ZZSTOCKSTRATEGY,
NULL AS ZZNOOFHANDLES,
NULL AS ITEM_ARCHITECTURE_ID,
NULL AS ZZARCHDET,
NULL AS ZZSTYLE,
NULL AS ZZLEGMATNR,
NULL AS ZZPRODUCTVITALITY,
NULL AS ZZWHENNEWDATE,
NULL AS REPORTING_CATEGORY_ID,
NULL AS GLDELFLAG,
NULL AS GLCHANGETIME,
'N' AS PSA_DELETE_IND,
'1900-01-01'::TIMESTAMP AS PSA_LOAD_DTS,
NULL AS PSA_RECORD_SOURCE,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC,
''::BINARY AS HASHDIFF
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
