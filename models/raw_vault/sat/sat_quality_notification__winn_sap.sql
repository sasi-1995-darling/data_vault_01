---- SRC LAYER ----
WITH
SRC_SQN            as ( SELECT * FROM {{ ref('v_psa_stg_quality_notifications') }} as SRC 
                        {% if is_incremental() %}
                          WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                          {% endif %} )

/*
SRC_SQN            as ( SELECT * FROM STAGING.v_psa_stg_quality_notifications )
*/
---- LOGIC LAYER ----

, LOGIC_SQN as (
    SELECT
        QUALITY_NOTIFICATION_HK
      , GLREQUEST
      , QMART
      , QMNUM
      , QMTXT
      , ARTPR
      , PRIOK
      , ERNAM
      , ERDAT
      , AENAM
      , AEDAT
      , MZEIT
      , QMDAT
      , QMNAM
      , STRMN
      , STRUR
      , LTRMN
      , LTRUR
      , WAERS
      , AUFNR
      , VERID
      , RM_MATNR
      , RM_WERKS
      , SA_AUFNR
      , MATNR
      , REVLV
      , MATKL
      , PRDHA
      , KZKRI
      , KZDKZ
      , KUNUM
      , FEKNZ
      , MAKNZ
      , OBJNR
      , QMDAB
      , QMZAB
      , RBNR
      , RBNRI
      , INDTX
      , KZMLA
      , HERKZ
      , BEZDT
      , BEZUR
      , LIFNUM
      , BUNAME
      , VBELN
      , BSTNK
      , BSTDK
      , SPART
      , VKORG
      , VTWEG
      , ADRNR
      , AEZEIT
      , ERZEIT
      , MAWERK
      , QMKAT
      , QMGRP
      , QMCOD
      , AUSWIRK
      , TEILEV
      , PRUEFLOS
      , CHARG
      , LGORTCHARG
      , LICHN
      , HERSTELLER
      , EMATNR
      , EKORG
      , BKGRP
      , LGORTVORG
      , FERTAUFNR
      , FERTAUFPL
      , EBELN
      , EBELP
      , MJAHR
      , MBLNR
      , MBLPO
      , LS_KDAUF
      , LS_KDPOS
      , LS_VBELN
      , LS_POSNR
      , CROBJTY
      , ARBPL
      , ARBPLWERK
      , FEART
      , PNLKN
      , MGEIG
      , MGFRD
      , MGEIN
      , BZMNG
      , RKMNG
      , RGMNG
      , RKDAT
      , COAUFNR
      , QWRNUM
      , REFNUM
      , KDMAT
      , IDNLF
      , SERIALNR
      , KZLOESCH
      , PRODDAT
      , DEVICEID
      , VKBUR
      , VKGRP
      , AUTKZ
      , BEDID
      , BEDZL
      , PROFIL_TYP
      , PROFIL_ID
      , HANDLE
      , TSEGFL
      , TSEGTP
      , TZONSO
      , TZONID
      , FUNKTION
      , SAPSMOSS_INSTN
      , SAPSMOSS_MNUMM
      , SAPSMOSS_OSSYS
      , SAPSMOSS_DBSYS
      , SAPSMOSS_REL
      , SAPSMOSS_COMP
      , SAPSMOSS_FRONT
      , SAPSMOSS_SYSTYP
      , SAPSMOSS_ADDID
      , SAPSMOSS_ADDREL
      , SAPSMOSS_TSTMP
      , SAPSMOSS_STATUS
      , SAPSMOSS_ERDAT
      , SAPSMOSS_ERZEIT
      , SAPSMOSS_SYSID
      , SAPSMOSS_MANDT
      , PSP_NR
      , ESTIMATED_COSTS
      , CLAIMED_COSTS
      , RESULT_COSTS
      , CHANCE
      , OPPONENT
      , KALNR
      , KALVAR
      , OBJNR_REAL
      , OBJNR_STAT
      , PHASE
      , ISDFPS_MHIO_ADDATE
      , ISDFPS_MHIO_ADTIME
      , ISDFPS_USERMODE
      , ISDFPS_OBJNR
      , LOGSYSTEM
      , ISDFPS_MEQUI
      , SHN_OBJTY
      , SHN_OBJID
      , SHN_FUNCT_LOC
      , SHN_EQUIPMENT
      , SHN_ORIGIN
      , UII
      , ZZINST_MONTH
      , ZZINST_YEAR
      , ZZDATE_CODE
      , ZZREASON_KAT
      , ZZREASON_GRP
      , ZZREASON_COD
      , ZZACTION_KAT
      , ZZACTION_GRP
      , ZZACTION_COD
      , ZZCLAIM_DAMAGE
      , ZZCLAIM_INJURY
      , ZZCLAIM_LABOR
      , ZZCLAIM_PRODUCT
      , ZZCLAIM_LITIGATE
      , ZZCLAIM_SETTLE
      , ZZCLAIM_ENTITY1
      , ZZCLAIM_ENTITY2
      , ZZCLAIM_ENTITY3
      , ZZCLAIM_REF1
      , ZZCLAIM_REF2
      , ZZCLAIM_REF3
      , ZZBELNR
      , ZZBUZEI
      , ZZGJAHR
      , ZZBUKRS
      , ZZORIGPURCH
      , ZZRCPTAVAIL
      , ZZSFCNTINFO
      , ZZTOTALPROD
      , ZZINSTALLER_KAT
      , ZZINSTALLER_GRP
      , ZZINSTALLER_COD
      , ZZEMAIL_IND
      , ZZFIN_IMP
      , ZZCUST_IMP
      , ZZPROB_FREQ
      , ZZSTRAT_INIT
      , ZZEMP_IMP
      , ZZDATA_SUP
      , ZZTIME_RES
      , ZZINIT_SAV_PROJ
      , ZZFORECAST_SAV
      , ZZACTUAL_SAV
      , ZZHOTLIST
      , ZZCONFIDENTIAL
      , ZZPROJECTNO
      , ZZACK_DATE
      , ZZLOC_KAT
      , ZZLOC_GRP
      , ZZLOC_COD
      , ZZCLASS_KAT
      , ZZCLASS_GRP
      , ZZCLASS_COD
      , ZZCOMPLETE_KAT
      , ZZCOMPLETE_GRP
      , ZZCOMPLETE_COD
      , ZZPARTS_ON_HOLD
      , ZZPRODTIM
      , ZZOWNER
      , ZZBUSUNITOWN
      , ZZPROD_STOPPED
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_DELETE_IND
      , HASHDIFF
      , BKCC
      , rec_src
      , load_dts
    FROM SRC_SQN
)
---- RENAME LAYER ----

, RENAME_SQN as (
    SELECT
        QUALITY_NOTIFICATION_HK
      , GLREQUEST
      , QMART
      , QMNUM
      , QMTXT
      , ARTPR
      , PRIOK
      , ERNAM
      , ERDAT
      , AENAM
      , AEDAT
      , MZEIT
      , QMDAT
      , QMNAM
      , STRMN
      , STRUR
      , LTRMN
      , LTRUR
      , WAERS
      , AUFNR
      , VERID
      , RM_MATNR
      , RM_WERKS
      , SA_AUFNR
      , MATNR
      , REVLV
      , MATKL
      , PRDHA
      , KZKRI
      , KZDKZ
      , KUNUM
      , FEKNZ
      , MAKNZ
      , OBJNR
      , QMDAB
      , QMZAB
      , RBNR
      , RBNRI
      , INDTX
      , KZMLA
      , HERKZ
      , BEZDT
      , BEZUR
      , LIFNUM
      , BUNAME
      , VBELN
      , BSTNK
      , BSTDK
      , SPART
      , VKORG
      , VTWEG
      , ADRNR
      , AEZEIT
      , ERZEIT
      , MAWERK
      , QMKAT
      , QMGRP
      , QMCOD
      , AUSWIRK
      , TEILEV
      , PRUEFLOS
      , CHARG
      , LGORTCHARG
      , LICHN
      , HERSTELLER
      , EMATNR
      , EKORG
      , BKGRP
      , LGORTVORG
      , FERTAUFNR
      , FERTAUFPL
      , EBELN
      , EBELP
      , MJAHR
      , MBLNR
      , MBLPO
      , LS_KDAUF
      , LS_KDPOS
      , LS_VBELN
      , LS_POSNR
      , CROBJTY
      , ARBPL
      , ARBPLWERK
      , FEART
      , PNLKN
      , MGEIG
      , MGFRD
      , MGEIN
      , BZMNG
      , RKMNG
      , RGMNG
      , RKDAT
      , COAUFNR
      , QWRNUM
      , REFNUM
      , KDMAT
      , IDNLF
      , SERIALNR
      , KZLOESCH
      , PRODDAT
      , DEVICEID
      , VKBUR
      , VKGRP
      , AUTKZ
      , BEDID
      , BEDZL
      , PROFIL_TYP
      , PROFIL_ID
      , HANDLE
      , TSEGFL
      , TSEGTP
      , TZONSO
      , TZONID
      , FUNKTION
      , SAPSMOSS_INSTN
      , SAPSMOSS_MNUMM
      , SAPSMOSS_OSSYS
      , SAPSMOSS_DBSYS
      , SAPSMOSS_REL
      , SAPSMOSS_COMP
      , SAPSMOSS_FRONT
      , SAPSMOSS_SYSTYP
      , SAPSMOSS_ADDID
      , SAPSMOSS_ADDREL
      , SAPSMOSS_TSTMP
      , SAPSMOSS_STATUS
      , SAPSMOSS_ERDAT
      , SAPSMOSS_ERZEIT
      , SAPSMOSS_SYSID
      , SAPSMOSS_MANDT
      , PSP_NR
      , ESTIMATED_COSTS
      , CLAIMED_COSTS
      , RESULT_COSTS
      , CHANCE
      , OPPONENT
      , KALNR
      , KALVAR
      , OBJNR_REAL
      , OBJNR_STAT
      , PHASE
      , ISDFPS_MHIO_ADDATE
      , ISDFPS_MHIO_ADTIME
      , ISDFPS_USERMODE
      , ISDFPS_OBJNR
      , LOGSYSTEM
      , ISDFPS_MEQUI
      , SHN_OBJTY
      , SHN_OBJID
      , SHN_FUNCT_LOC
      , SHN_EQUIPMENT
      , SHN_ORIGIN
      , UII
      , ZZINST_MONTH
      , ZZINST_YEAR
      , ZZDATE_CODE
      , ZZREASON_KAT
      , ZZREASON_GRP
      , ZZREASON_COD
      , ZZACTION_KAT
      , ZZACTION_GRP
      , ZZACTION_COD
      , ZZCLAIM_DAMAGE
      , ZZCLAIM_INJURY
      , ZZCLAIM_LABOR
      , ZZCLAIM_PRODUCT
      , ZZCLAIM_LITIGATE
      , ZZCLAIM_SETTLE
      , ZZCLAIM_ENTITY1
      , ZZCLAIM_ENTITY2
      , ZZCLAIM_ENTITY3
      , ZZCLAIM_REF1
      , ZZCLAIM_REF2
      , ZZCLAIM_REF3
      , ZZBELNR
      , ZZBUZEI
      , ZZGJAHR
      , ZZBUKRS
      , ZZORIGPURCH
      , ZZRCPTAVAIL
      , ZZSFCNTINFO
      , ZZTOTALPROD
      , ZZINSTALLER_KAT
      , ZZINSTALLER_GRP
      , ZZINSTALLER_COD
      , ZZEMAIL_IND
      , ZZFIN_IMP
      , ZZCUST_IMP
      , ZZPROB_FREQ
      , ZZSTRAT_INIT
      , ZZEMP_IMP
      , ZZDATA_SUP
      , ZZTIME_RES
      , ZZINIT_SAV_PROJ
      , ZZFORECAST_SAV
      , ZZACTUAL_SAV
      , ZZHOTLIST
      , ZZCONFIDENTIAL
      , ZZPROJECTNO
      , ZZACK_DATE
      , ZZLOC_KAT
      , ZZLOC_GRP
      , ZZLOC_COD
      , ZZCLASS_KAT
      , ZZCLASS_GRP
      , ZZCLASS_COD
      , ZZCOMPLETE_KAT
      , ZZCOMPLETE_GRP
      , ZZCOMPLETE_COD
      , ZZPARTS_ON_HOLD
      , ZZPRODTIM
      , ZZOWNER
      , ZZBUSUNITOWN
      , ZZPROD_STOPPED
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_DELETE_IND
      , HASHDIFF
      , BKCC
      , rec_src
      , load_dts
    FROM LOGIC_SQN
)
---- FILTER LAYER ----

, FILTER_SQN as (
    SELECT *
    FROM RENAME_SQN
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_SQN
)

---- FINAL LAYER ----
SELECT
          QUALITY_NOTIFICATION_HK
        , GLREQUEST
        , QMART
        , QMNUM
        , QMTXT
        , ARTPR
        , PRIOK
        , ERNAM
        , ERDAT
        , AENAM
        , AEDAT
        , MZEIT
        , QMDAT
        , QMNAM
        , STRMN
        , STRUR
        , LTRMN
        , LTRUR
        , WAERS
        , AUFNR
        , VERID
        , RM_MATNR
        , RM_WERKS
        , SA_AUFNR
        , MATNR
        , REVLV
        , MATKL
        , PRDHA
        , KZKRI
        , KZDKZ
        , KUNUM
        , FEKNZ
        , MAKNZ
        , OBJNR
        , QMDAB
        , QMZAB
        , RBNR
        , RBNRI
        , INDTX
        , KZMLA
        , HERKZ
        , BEZDT
        , BEZUR
        , LIFNUM
        , BUNAME
        , VBELN
        , BSTNK
        , BSTDK
        , SPART
        , VKORG
        , VTWEG
        , ADRNR
        , AEZEIT
        , ERZEIT
        , MAWERK
        , QMKAT
        , QMGRP
        , QMCOD
        , AUSWIRK
        , TEILEV
        , PRUEFLOS
        , CHARG
        , LGORTCHARG
        , LICHN
        , HERSTELLER
        , EMATNR
        , EKORG
        , BKGRP
        , LGORTVORG
        , FERTAUFNR
        , FERTAUFPL
        , EBELN
        , EBELP
        , MJAHR
        , MBLNR
        , MBLPO
        , LS_KDAUF
        , LS_KDPOS
        , LS_VBELN
        , LS_POSNR
        , CROBJTY
        , ARBPL
        , ARBPLWERK
        , FEART
        , PNLKN
        , MGEIG
        , MGFRD
        , MGEIN
        , BZMNG
        , RKMNG
        , RGMNG
        , RKDAT
        , COAUFNR
        , QWRNUM
        , REFNUM
        , KDMAT
        , IDNLF
        , SERIALNR
        , KZLOESCH
        , PRODDAT
        , DEVICEID
        , VKBUR
        , VKGRP
        , AUTKZ
        , BEDID
        , BEDZL
        , PROFIL_TYP
        , PROFIL_ID
        , HANDLE
        , TSEGFL
        , TSEGTP
        , TZONSO
        , TZONID
        , FUNKTION
        , SAPSMOSS_INSTN
        , SAPSMOSS_MNUMM
        , SAPSMOSS_OSSYS
        , SAPSMOSS_DBSYS
        , SAPSMOSS_REL
        , SAPSMOSS_COMP
        , SAPSMOSS_FRONT
        , SAPSMOSS_SYSTYP
        , SAPSMOSS_ADDID
        , SAPSMOSS_ADDREL
        , SAPSMOSS_TSTMP
        , SAPSMOSS_STATUS
        , SAPSMOSS_ERDAT
        , SAPSMOSS_ERZEIT
        , SAPSMOSS_SYSID
        , SAPSMOSS_MANDT
        , PSP_NR
        , ESTIMATED_COSTS
        , CLAIMED_COSTS
        , RESULT_COSTS
        , CHANCE
        , OPPONENT
        , KALNR
        , KALVAR
        , OBJNR_REAL
        , OBJNR_STAT
        , PHASE
        , ISDFPS_MHIO_ADDATE
        , ISDFPS_MHIO_ADTIME
        , ISDFPS_USERMODE
        , ISDFPS_OBJNR
        , LOGSYSTEM
        , ISDFPS_MEQUI
        , SHN_OBJTY
        , SHN_OBJID
        , SHN_FUNCT_LOC
        , SHN_EQUIPMENT
        , SHN_ORIGIN
        , UII
        , ZZINST_MONTH
        , ZZINST_YEAR
        , ZZDATE_CODE
        , ZZREASON_KAT
        , ZZREASON_GRP
        , ZZREASON_COD
        , ZZACTION_KAT
        , ZZACTION_GRP
        , ZZACTION_COD
        , ZZCLAIM_DAMAGE
        , ZZCLAIM_INJURY
        , ZZCLAIM_LABOR
        , ZZCLAIM_PRODUCT
        , ZZCLAIM_LITIGATE
        , ZZCLAIM_SETTLE
        , ZZCLAIM_ENTITY1
        , ZZCLAIM_ENTITY2
        , ZZCLAIM_ENTITY3
        , ZZCLAIM_REF1
        , ZZCLAIM_REF2
        , ZZCLAIM_REF3
        , ZZBELNR
        , ZZBUZEI
        , ZZGJAHR
        , ZZBUKRS
        , ZZORIGPURCH
        , ZZRCPTAVAIL
        , ZZSFCNTINFO
        , ZZTOTALPROD
        , ZZINSTALLER_KAT
        , ZZINSTALLER_GRP
        , ZZINSTALLER_COD
        , ZZEMAIL_IND
        , ZZFIN_IMP
        , ZZCUST_IMP
        , ZZPROB_FREQ
        , ZZSTRAT_INIT
        , ZZEMP_IMP
        , ZZDATA_SUP
        , ZZTIME_RES
        , ZZINIT_SAV_PROJ
        , ZZFORECAST_SAV
        , ZZACTUAL_SAV
        , ZZHOTLIST
        , ZZCONFIDENTIAL
        , ZZPROJECTNO
        , ZZACK_DATE
        , ZZLOC_KAT
        , ZZLOC_GRP
        , ZZLOC_COD
        , ZZCLASS_KAT
        , ZZCLASS_GRP
        , ZZCLASS_COD
        , ZZCOMPLETE_KAT
        , ZZCOMPLETE_GRP
        , ZZCOMPLETE_COD
        , ZZPARTS_ON_HOLD
        , ZZPRODTIM
        , ZZOWNER
        , ZZBUSUNITOWN
        , ZZPROD_STOPPED
        , GLDELFLAG
        , GLCHANGETIME
        , GLSOURCESYSTEM
        , PSA_DELETE_IND
        , LOAD_DTS
        , BKCC
        , REC_SRC
        , HASHDIFF
FROM JOIN_RESULT
{% if is_incremental() %}
 WHERE NOT EXISTS (
  SELECT 1 
  FROM {{ this }} existing
  WHERE existing.QUALITY_NOTIFICATION_HK= JOIN_RESULT.QUALITY_NOTIFICATION_HK
  AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
 )
 {% endif %} 
 {% if not is_incremental() %}
 /*the following qualify is to restrict multiple loads of touched records during the initial build. Ex: multiple row per hk, hashdiff */
 qualify 1= row_number()over(partition by QUALITY_NOTIFICATION_HK, HASHDIFF order by LOAD_DTS)
 union all
  SELECT 
  MD5_BINARY(GR.VALUE) AS QUALITY_NOTIFICATION_HK
 , NULL as GLREQUEST
, NULL as QMART
, NULL as QMNUM
, NULL as QMTXT
, NULL as ARTPR
, NULL as PRIOK
, NULL as ERNAM
, NULL as ERDAT
, NULL as AENAM
, NULL as AEDAT
, NULL as MZEIT
, NULL as QMDAT
, NULL as QMNAM
, NULL as STRMN
, NULL as STRUR
, NULL as LTRMN
, NULL as LTRUR
, NULL as WAERS
, NULL as AUFNR
, NULL as VERID
, NULL as RM_MATNR
, NULL as RM_WERKS
, NULL as SA_AUFNR
, NULL as MATNR
, NULL as REVLV
, NULL as MATKL
, NULL as PRDHA
, NULL as KZKRI
, NULL as KZDKZ
, NULL as KUNUM
, NULL as FEKNZ
, NULL as MAKNZ
, NULL as OBJNR
, NULL as QMDAB
, NULL as QMZAB
, NULL as RBNR
, NULL as RBNRI
, NULL as INDTX
, NULL as KZMLA
, NULL as HERKZ
, NULL as BEZDT
, NULL as BEZUR
, NULL as LIFNUM
, NULL as BUNAME
, NULL as VBELN
, NULL as BSTNK
, NULL as BSTDK
, NULL as SPART
, NULL as VKORG
, NULL as VTWEG
, NULL as ADRNR
, NULL as AEZEIT
, NULL as ERZEIT
, NULL as MAWERK
, NULL as QMKAT
, NULL as QMGRP
, NULL as QMCOD
, NULL as AUSWIRK
, NULL as TEILEV
, NULL as PRUEFLOS
, NULL as CHARG
, NULL as LGORTCHARG
, NULL as LICHN
, NULL as HERSTELLER
, NULL as EMATNR
, NULL as EKORG
, NULL as BKGRP
, NULL as LGORTVORG
, NULL as FERTAUFNR
, NULL as FERTAUFPL
, NULL as EBELN
, NULL as EBELP
, NULL as MJAHR
, NULL as MBLNR
, NULL as MBLPO
, NULL as LS_KDAUF
, NULL as LS_KDPOS
, NULL as LS_VBELN
, NULL as LS_POSNR
, NULL as CROBJTY
, NULL as ARBPL
, NULL as ARBPLWERK
, NULL as FEART
, NULL as PNLKN
, NULL as MGEIG
, NULL as MGFRD
, NULL as MGEIN
, NULL as BZMNG
, NULL as RKMNG
, NULL as RGMNG
, NULL as RKDAT
, NULL as COAUFNR
, NULL as QWRNUM
, NULL as REFNUM
, NULL as KDMAT
, NULL as IDNLF
, NULL as SERIALNR
, NULL as KZLOESCH
, NULL as PRODDAT
, NULL as DEVICEID
, NULL as VKBUR
, NULL as VKGRP
, NULL as AUTKZ
, NULL as BEDID
, NULL as BEDZL
, NULL as PROFIL_TYP
, NULL as PROFIL_ID
, NULL as HANDLE
, NULL as TSEGFL
, NULL as TSEGTP
, NULL as TZONSO
, NULL as TZONID
, NULL as FUNKTION
, NULL as SAPSMOSS_INSTN
, NULL as SAPSMOSS_MNUMM
, NULL as SAPSMOSS_OSSYS
, NULL as SAPSMOSS_DBSYS
, NULL as SAPSMOSS_REL
, NULL as SAPSMOSS_COMP
, NULL as SAPSMOSS_FRONT
, NULL as SAPSMOSS_SYSTYP
, NULL as SAPSMOSS_ADDID
, NULL as SAPSMOSS_ADDREL
, NULL as SAPSMOSS_TSTMP
, NULL as SAPSMOSS_STATUS
, NULL as SAPSMOSS_ERDAT
, NULL as SAPSMOSS_ERZEIT
, NULL as SAPSMOSS_SYSID
, NULL as SAPSMOSS_MANDT
, NULL as PSP_NR
, NULL as ESTIMATED_COSTS
, NULL as CLAIMED_COSTS
, NULL as RESULT_COSTS
, NULL as CHANCE
, NULL as OPPONENT
, NULL as KALNR
, NULL as KALVAR
, NULL as OBJNR_REAL
, NULL as OBJNR_STAT
, NULL as PHASE
, NULL as ISDFPS_MHIO_ADDATE
, NULL as ISDFPS_MHIO_ADTIME
, NULL as ISDFPS_USERMODE
, NULL as ISDFPS_OBJNR
, NULL as LOGSYSTEM
, NULL as ISDFPS_MEQUI
, NULL as SHN_OBJTY
, NULL as SHN_OBJID
, NULL as SHN_FUNCT_LOC
, NULL as SHN_EQUIPMENT
, NULL as SHN_ORIGIN
, NULL as UII
, NULL as ZZINST_MONTH
, NULL as ZZINST_YEAR
, NULL as ZZDATE_CODE
, NULL as ZZREASON_KAT
, NULL as ZZREASON_GRP
, NULL as ZZREASON_COD
, NULL as ZZACTION_KAT
, NULL as ZZACTION_GRP
, NULL as ZZACTION_COD
, NULL as ZZCLAIM_DAMAGE
, NULL as ZZCLAIM_INJURY
, NULL as ZZCLAIM_LABOR
, NULL as ZZCLAIM_PRODUCT
, NULL as ZZCLAIM_LITIGATE
, NULL as ZZCLAIM_SETTLE
, NULL as ZZCLAIM_ENTITY1
, NULL as ZZCLAIM_ENTITY2
, NULL as ZZCLAIM_ENTITY3
, NULL as ZZCLAIM_REF1
, NULL as ZZCLAIM_REF2
, NULL as ZZCLAIM_REF3
, NULL as ZZBELNR
, NULL as ZZBUZEI
, NULL as ZZGJAHR
, NULL as ZZBUKRS
, NULL as ZZORIGPURCH
, NULL as ZZRCPTAVAIL
, NULL as ZZSFCNTINFO
, NULL as ZZTOTALPROD
, NULL as ZZINSTALLER_KAT
, NULL as ZZINSTALLER_GRP
, NULL as ZZINSTALLER_COD
, NULL as ZZEMAIL_IND
, NULL as ZZFIN_IMP
, NULL as ZZCUST_IMP
, NULL as ZZPROB_FREQ
, NULL as ZZSTRAT_INIT
, NULL as ZZEMP_IMP
, NULL as ZZDATA_SUP
, NULL as ZZTIME_RES
, NULL as ZZINIT_SAV_PROJ
, NULL as ZZFORECAST_SAV
, NULL as ZZACTUAL_SAV
, NULL as ZZHOTLIST
, NULL as ZZCONFIDENTIAL
, NULL as ZZPROJECTNO
, NULL as ZZACK_DATE
, NULL as ZZLOC_KAT
, NULL as ZZLOC_GRP
, NULL as ZZLOC_COD
, NULL as ZZCLASS_KAT
, NULL as ZZCLASS_GRP
, NULL as ZZCLASS_COD
, NULL as ZZCOMPLETE_KAT
, NULL as ZZCOMPLETE_GRP
, NULL as ZZCOMPLETE_COD
, NULL as ZZPARTS_ON_HOLD
, NULL as ZZPRODTIM
, NULL as ZZOWNER
, NULL as ZZBUSUNITOWN
, NULL as ZZPROD_STOPPED
, NULL as GLDELFLAG
, NULL as GLCHANGETIME
, NULL as GLSOURCESYSTEM
, NULL as PSA_DELETE_IND
, CONVERT_TIMEZONE('UTC','1900-01-01') as LOAD_DTS
, DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC
,'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
, ''::BINARY as HASHDIFF FROM
  TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
 {% endif %}