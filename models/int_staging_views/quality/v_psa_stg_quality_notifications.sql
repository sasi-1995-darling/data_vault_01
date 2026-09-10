---- SRC LAYER ----
WITH
SRC_a              as ( SELECT * FROM {{ source('sap_ecc_prd', 'z_qmel') }} as SRC  ),
SRC_b              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_a              as ( SELECT * FROM SAP_ECC_PRD.Z_QMEL )
, SRC_b              as ( SELECT * FROM RAW_VAULT.REF_BUSINESS_KEY_COLLISION )
*/
---- LOGIC LAYER ----

, LOGIC_a as (
    SELECT
        to_char(coalesce(QMNUM,'-1'))                                as                            QUALITY_NOTIFICATION_BK
      , to_char(coalesce(MATNR,'-1'))     as                                            ITEM_BK
      , MANDT
      , QMNUM
      , GLREQUEST
      , QMART
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
      , "/SAPSMOSS/INSTN"  
      , "/SAPSMOSS/MNUMM" 
      , "/SAPSMOSS/OSSYS" 
      , "/SAPSMOSS/DBSYS" 
      , "/SAPSMOSS/REL" 
      , "/SAPSMOSS/COMP" 
      , "/SAPSMOSS/FRONT" 
      , "/SAPSMOSS/SYSTYP" 
      , "/SAPSMOSS/ADDID" 
      , "/SAPSMOSS/ADDREL" 
      , "/SAPSMOSS/TSTMP" 
      , "/SAPSMOSS/STATUS" 
      , "/SAPSMOSS/ERDAT" 
      , "/SAPSMOSS/ERZEIT" 
      , "/SAPSMOSS/SYSID" 
      , "/SAPSMOSS/MANDT" 
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
      , "/ISDFPS/MHIO_ADDATE" 
      , "/ISDFPS/MHIO_ADTIME"
      , "/ISDFPS/USERMODE" 
      , "/ISDFPS/OBJNR" 
      , LOGSYSTEM
      , "/ISDFPS/MEQUI" 
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
                ))   as                                    LOAD_DTS
    FROM SRC_a
)

, LOGIC_b as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_b
)
---- RENAME LAYER ----

, RENAME_a as (
    SELECT
        QUALITY_NOTIFICATION_BK
      , ITEM_BK
      , MANDT
      , QMNUM
      , GLREQUEST
      , QMART
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
      , "/SAPSMOSS/INSTN"                                         as                                 SAPSMOSS_INSTN
      , "/SAPSMOSS/MNUMM"                                         as                                 SAPSMOSS_MNUMM
      , "/SAPSMOSS/OSSYS"                                         as                                 SAPSMOSS_OSSYS
      , "/SAPSMOSS/DBSYS"                                         as                                 SAPSMOSS_DBSYS
      , "/SAPSMOSS/REL"                                           as                                 SAPSMOSS_REL
      , "/SAPSMOSS/COMP"                                          as                                 SAPSMOSS_COMP
      , "/SAPSMOSS/FRONT"                                         as                                 SAPSMOSS_FRONT
      , "/SAPSMOSS/SYSTYP"                                        as                                 SAPSMOSS_SYSTYP
      , "/SAPSMOSS/ADDID"                                         as                                 SAPSMOSS_ADDID
      , "/SAPSMOSS/ADDREL"                                        as                                 SAPSMOSS_ADDREL
      , "/SAPSMOSS/TSTMP"                                         as                                 SAPSMOSS_TSTMP
      , "/SAPSMOSS/STATUS"                                        as                                 SAPSMOSS_STATUS
      , "/SAPSMOSS/ERDAT"                                         as                                 SAPSMOSS_ERDAT
      , "/SAPSMOSS/ERZEIT"                                        as                                 SAPSMOSS_ERZEIT
      , "/SAPSMOSS/SYSID"                                         as                                 SAPSMOSS_SYSID
      , "/SAPSMOSS/MANDT"                                         as                                 SAPSMOSS_MANDT
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
      , "/ISDFPS/MHIO_ADDATE"                                         as                                 ISDFPS_MHIO_ADDATE
      , "/ISDFPS/MHIO_ADTIME"                                         as                                 ISDFPS_MHIO_ADTIME
      , "/ISDFPS/USERMODE"                                            as                                 ISDFPS_USERMODE
      , "/ISDFPS/OBJNR"                                               as                                 ISDFPS_OBJNR
      , LOGSYSTEM
      , "/ISDFPS/MEQUI"                                               as                                 ISDFPS_MEQUI
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
    FROM LOGIC_a
)

, RENAME_b as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_b
)
---- FILTER LAYER ----

, FILTER_a as (
    SELECT *
    FROM RENAME_a
)

, FILTER_b as (
    SELECT *
    FROM RENAME_b
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_QMEL'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_a
    INNER JOIN FILTER_b
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          QUALITY_NOTIFICATION_BK 
        , MANDT
        , QMNUM
        , GLREQUEST
        , QMART
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
        , REC_SRC
        , BKCC
        , IFF(MATNR IS NULL, '-1', CONCAT_WS('||', MATNR, BKCC)) as drvd_item_bkcc
        , IFF(QMNUM IS NULL, '-1', CONCAT_WS('||', QMNUM, BKCC)) as drvd_notification_bkcc
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ITEM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(QUALITY_NOTIFICATION_BK as VARCHAR)),''), '^^')
        ))) as QUALITY_NOTIFICATION_ITEM_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(drvd_notification_bkcc as VARCHAR)),''), '^^')
        ))) as QUALITY_NOTIFICATION_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
         COALESCE(NULLIF(TRIM(CAST(drvd_item_bkcc as VARCHAR)), ''), '^^')
         ))) as ITEM_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
            IFNULL(TRIM(MANDT::text), '^^') 
            , '||', IFNULL(TRIM(QMNUM::text), '^^')  
            , '||', IFNULL(TRIM(QMART::text), '^^') 
            , '||', IFNULL(TRIM(QMTXT::text), '^^') 
            , '||', IFNULL(TRIM(ARTPR::text), '^^') 
            , '||', IFNULL(TRIM(PRIOK::text), '^^') 
            , '||', IFNULL(TRIM(ERNAM::text), '^^') 
            , '||', IFNULL(TRIM(ERDAT::text), '^^') 
            , '||', IFNULL(TRIM(AENAM::text), '^^') 
            , '||', IFNULL(TRIM(AEDAT::text), '^^') 
            , '||', IFNULL(TRIM(MZEIT::text), '^^') 
            , '||', IFNULL(TRIM(QMDAT::text), '^^') 
            , '||', IFNULL(TRIM(QMNAM::text), '^^') 
            , '||', IFNULL(TRIM(STRMN::text), '^^') 
            , '||', IFNULL(TRIM(STRUR::text), '^^') 
            , '||', IFNULL(TRIM(LTRMN::text), '^^') 
            , '||', IFNULL(TRIM(LTRUR::text), '^^') 
            , '||', IFNULL(TRIM(WAERS::text), '^^') 
            , '||', IFNULL(TRIM(AUFNR::text), '^^') 
            , '||', IFNULL(TRIM(VERID::text), '^^') 
            , '||', IFNULL(TRIM(RM_MATNR::text), '^^') 
            , '||', IFNULL(TRIM(RM_WERKS::text), '^^') 
            , '||', IFNULL(TRIM(SA_AUFNR::text), '^^') 
            , '||', IFNULL(TRIM(MATNR::text), '^^') 
            , '||', IFNULL(TRIM(REVLV::text), '^^') 
            , '||', IFNULL(TRIM(MATKL::text), '^^') 
            , '||', IFNULL(TRIM(PRDHA::text), '^^') 
            , '||', IFNULL(TRIM(KZKRI::text), '^^') 
            , '||', IFNULL(TRIM(KZDKZ::text), '^^') 
            , '||', IFNULL(TRIM(KUNUM::text), '^^') 
            , '||', IFNULL(TRIM(FEKNZ::text), '^^') 
            , '||', IFNULL(TRIM(MAKNZ::text), '^^') 
            , '||', IFNULL(TRIM(OBJNR::text), '^^') 
            , '||', IFNULL(TRIM(QMDAB::text), '^^') 
            , '||', IFNULL(TRIM(QMZAB::text), '^^') 
            , '||', IFNULL(TRIM(RBNR::text), '^^') 
            , '||', IFNULL(TRIM(RBNRI::text), '^^') 
            , '||', IFNULL(TRIM(INDTX::text), '^^') 
            , '||', IFNULL(TRIM(KZMLA::text), '^^') 
            , '||', IFNULL(TRIM(HERKZ::text), '^^') 
            , '||', IFNULL(TRIM(BEZDT::text), '^^') 
            , '||', IFNULL(TRIM(BEZUR::text), '^^') 
            , '||', IFNULL(TRIM(LIFNUM::text), '^^') 
            , '||', IFNULL(TRIM(BUNAME::text), '^^') 
            , '||', IFNULL(TRIM(VBELN::text), '^^') 
            , '||', IFNULL(TRIM(BSTNK::text), '^^') 
            , '||', IFNULL(TRIM(BSTDK::text), '^^') 
            , '||', IFNULL(TRIM(SPART::text), '^^') 
            , '||', IFNULL(TRIM(VKORG::text), '^^') 
            , '||', IFNULL(TRIM(VTWEG::text), '^^') 
            , '||', IFNULL(TRIM(ADRNR::text), '^^') 
            , '||', IFNULL(TRIM(AEZEIT::text), '^^') 
            , '||', IFNULL(TRIM(ERZEIT::text), '^^') 
            , '||', IFNULL(TRIM(MAWERK::text), '^^') 
            , '||', IFNULL(TRIM(QMKAT::text), '^^') 
            , '||', IFNULL(TRIM(QMGRP::text), '^^') 
            , '||', IFNULL(TRIM(QMCOD::text), '^^') 
            , '||', IFNULL(TRIM(AUSWIRK::text), '^^') 
            , '||', IFNULL(TRIM(TEILEV::text), '^^') 
            , '||', IFNULL(TRIM(PRUEFLOS::text), '^^') 
            , '||', IFNULL(TRIM(CHARG::text), '^^') 
            , '||', IFNULL(TRIM(LGORTCHARG::text), '^^') 
            , '||', IFNULL(TRIM(LICHN::text), '^^') 
            , '||', IFNULL(TRIM(HERSTELLER::text), '^^') 
            , '||', IFNULL(TRIM(EMATNR::text), '^^') 
            , '||', IFNULL(TRIM(EKORG::text), '^^') 
            , '||', IFNULL(TRIM(BKGRP::text), '^^') 
            , '||', IFNULL(TRIM(LGORTVORG::text), '^^') 
            , '||', IFNULL(TRIM(FERTAUFNR::text), '^^') 
            , '||', IFNULL(TRIM(FERTAUFPL::text), '^^') 
            , '||', IFNULL(TRIM(EBELN::text), '^^') 
            , '||', IFNULL(TRIM(EBELP::text), '^^') 
            , '||', IFNULL(TRIM(MJAHR::text), '^^') 
            , '||', IFNULL(TRIM(MBLNR::text), '^^') 
            , '||', IFNULL(TRIM(MBLPO::text), '^^') 
            , '||', IFNULL(TRIM(LS_KDAUF::text), '^^') 
            , '||', IFNULL(TRIM(LS_KDPOS::text), '^^') 
            , '||', IFNULL(TRIM(LS_VBELN::text), '^^') 
            , '||', IFNULL(TRIM(LS_POSNR::text), '^^') 
            , '||', IFNULL(TRIM(CROBJTY::text), '^^') 
            , '||', IFNULL(TRIM(ARBPL::text), '^^') 
            , '||', IFNULL(TRIM(ARBPLWERK::text), '^^') 
            , '||', IFNULL(TRIM(FEART::text), '^^') 
            , '||', IFNULL(TRIM(PNLKN::text), '^^') 
            , '||', IFNULL(TRIM(MGEIG::text), '^^') 
            , '||', IFNULL(TRIM(MGFRD::text), '^^') 
            , '||', IFNULL(TRIM(MGEIN::text), '^^') 
            , '||', IFNULL(TRIM(BZMNG::text), '^^') 
            , '||', IFNULL(TRIM(RKMNG::text), '^^') 
            , '||', IFNULL(TRIM(RGMNG::text), '^^') 
            , '||', IFNULL(TRIM(RKDAT::text), '^^') 
            , '||', IFNULL(TRIM(COAUFNR::text), '^^') 
            , '||', IFNULL(TRIM(QWRNUM::text), '^^') 
            , '||', IFNULL(TRIM(REFNUM::text), '^^') 
            , '||', IFNULL(TRIM(KDMAT::text), '^^') 
            , '||', IFNULL(TRIM(IDNLF::text), '^^') 
            , '||', IFNULL(TRIM(SERIALNR::text), '^^') 
            , '||', IFNULL(TRIM(KZLOESCH::text), '^^') 
            , '||', IFNULL(TRIM(PRODDAT::text), '^^') 
            , '||', IFNULL(TRIM(DEVICEID::text), '^^') 
            , '||', IFNULL(TRIM(VKBUR::text), '^^') 
            , '||', IFNULL(TRIM(VKGRP::text), '^^') 
            , '||', IFNULL(TRIM(AUTKZ::text), '^^') 
            , '||', IFNULL(TRIM(BEDID::text), '^^') 
            , '||', IFNULL(TRIM(BEDZL::text), '^^') 
            , '||', IFNULL(TRIM(PROFIL_TYP::text), '^^') 
            , '||', IFNULL(TRIM(PROFIL_ID::text), '^^') 
            , '||', IFNULL(TRIM(HANDLE::text), '^^') 
            , '||', IFNULL(TRIM(TSEGFL::text), '^^') 
            , '||', IFNULL(TRIM(TSEGTP::text), '^^') 
            , '||', IFNULL(TRIM(TZONSO::text), '^^') 
            , '||', IFNULL(TRIM(TZONID::text), '^^') 
            , '||', IFNULL(TRIM(FUNKTION::text), '^^') 
            , '||', IFNULL(TRIM(SAPSMOSS_INSTN::text), '^^') 
            , '||', IFNULL(TRIM(SAPSMOSS_MNUMM::text), '^^') 
            , '||', IFNULL(TRIM(SAPSMOSS_OSSYS::text), '^^') 
            , '||', IFNULL(TRIM(SAPSMOSS_DBSYS::text), '^^') 
            , '||', IFNULL(TRIM(SAPSMOSS_REL::text), '^^') 
            , '||', IFNULL(TRIM(SAPSMOSS_COMP::text), '^^') 
            , '||', IFNULL(TRIM(SAPSMOSS_FRONT::text), '^^') 
            , '||', IFNULL(TRIM(SAPSMOSS_SYSTYP::text), '^^') 
            , '||', IFNULL(TRIM(SAPSMOSS_ADDID::text), '^^') 
            , '||', IFNULL(TRIM(SAPSMOSS_ADDREL::text), '^^') 
            , '||', IFNULL(TRIM(SAPSMOSS_TSTMP::text), '^^') 
            , '||', IFNULL(TRIM(SAPSMOSS_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(SAPSMOSS_ERDAT::text), '^^') 
            , '||', IFNULL(TRIM(SAPSMOSS_ERZEIT::text), '^^') 
            , '||', IFNULL(TRIM(SAPSMOSS_SYSID::text), '^^') 
            , '||', IFNULL(TRIM(SAPSMOSS_MANDT::text), '^^') 
            , '||', IFNULL(TRIM(PSP_NR::text), '^^') 
            , '||', IFNULL(TRIM(ESTIMATED_COSTS::text), '^^') 
            , '||', IFNULL(TRIM(CLAIMED_COSTS::text), '^^') 
            , '||', IFNULL(TRIM(RESULT_COSTS::text), '^^') 
            , '||', IFNULL(TRIM(CHANCE::text), '^^') 
            , '||', IFNULL(TRIM(OPPONENT::text), '^^') 
            , '||', IFNULL(TRIM(KALNR::text), '^^') 
            , '||', IFNULL(TRIM(KALVAR::text), '^^') 
            , '||', IFNULL(TRIM(OBJNR_REAL::text), '^^') 
            , '||', IFNULL(TRIM(OBJNR_STAT::text), '^^') 
            , '||', IFNULL(TRIM(PHASE::text), '^^') 
            , '||', IFNULL(TRIM(ISDFPS_MHIO_ADDATE::text), '^^') 
            , '||', IFNULL(TRIM(ISDFPS_MHIO_ADTIME::text), '^^') 
            , '||', IFNULL(TRIM(ISDFPS_USERMODE::text), '^^') 
            , '||', IFNULL(TRIM(ISDFPS_OBJNR::text), '^^') 
            , '||', IFNULL(TRIM(LOGSYSTEM::text), '^^') 
            , '||', IFNULL(TRIM(ISDFPS_MEQUI::text), '^^') 
            , '||', IFNULL(TRIM(SHN_OBJTY::text), '^^') 
            , '||', IFNULL(TRIM(SHN_OBJID::text), '^^') 
            , '||', IFNULL(TRIM(SHN_FUNCT_LOC::text), '^^') 
            , '||', IFNULL(TRIM(SHN_EQUIPMENT::text), '^^') 
            , '||', IFNULL(TRIM(SHN_ORIGIN::text), '^^') 
            , '||', IFNULL(TRIM(UII::text), '^^') 
            , '||', IFNULL(TRIM(ZZINST_MONTH::text), '^^') 
            , '||', IFNULL(TRIM(ZZINST_YEAR::text), '^^') 
            , '||', IFNULL(TRIM(ZZDATE_CODE::text), '^^') 
            , '||', IFNULL(TRIM(ZZREASON_KAT::text), '^^') 
            , '||', IFNULL(TRIM(ZZREASON_GRP::text), '^^') 
            , '||', IFNULL(TRIM(ZZREASON_COD::text), '^^') 
            , '||', IFNULL(TRIM(ZZACTION_KAT::text), '^^') 
            , '||', IFNULL(TRIM(ZZACTION_GRP::text), '^^') 
            , '||', IFNULL(TRIM(ZZACTION_COD::text), '^^') 
            , '||', IFNULL(TRIM(ZZCLAIM_DAMAGE::text), '^^') 
            , '||', IFNULL(TRIM(ZZCLAIM_INJURY::text), '^^') 
            , '||', IFNULL(TRIM(ZZCLAIM_LABOR::text), '^^') 
            , '||', IFNULL(TRIM(ZZCLAIM_PRODUCT::text), '^^') 
            , '||', IFNULL(TRIM(ZZCLAIM_LITIGATE::text), '^^') 
            , '||', IFNULL(TRIM(ZZCLAIM_SETTLE::text), '^^') 
            , '||', IFNULL(TRIM(ZZCLAIM_ENTITY1::text), '^^') 
            , '||', IFNULL(TRIM(ZZCLAIM_ENTITY2::text), '^^') 
            , '||', IFNULL(TRIM(ZZCLAIM_ENTITY3::text), '^^') 
            , '||', IFNULL(TRIM(ZZCLAIM_REF1::text), '^^') 
            , '||', IFNULL(TRIM(ZZCLAIM_REF2::text), '^^') 
            , '||', IFNULL(TRIM(ZZCLAIM_REF3::text), '^^') 
            , '||', IFNULL(TRIM(ZZBELNR::text), '^^') 
            , '||', IFNULL(TRIM(ZZBUZEI::text), '^^') 
            , '||', IFNULL(TRIM(ZZGJAHR::text), '^^') 
            , '||', IFNULL(TRIM(ZZBUKRS::text), '^^') 
            , '||', IFNULL(TRIM(ZZORIGPURCH::text), '^^') 
            , '||', IFNULL(TRIM(ZZRCPTAVAIL::text), '^^') 
            , '||', IFNULL(TRIM(ZZSFCNTINFO::text), '^^') 
            , '||', IFNULL(TRIM(ZZTOTALPROD::text), '^^') 
            , '||', IFNULL(TRIM(ZZINSTALLER_KAT::text), '^^') 
            , '||', IFNULL(TRIM(ZZINSTALLER_GRP::text), '^^') 
            , '||', IFNULL(TRIM(ZZINSTALLER_COD::text), '^^') 
            , '||', IFNULL(TRIM(ZZEMAIL_IND::text), '^^') 
            , '||', IFNULL(TRIM(ZZFIN_IMP::text), '^^') 
            , '||', IFNULL(TRIM(ZZCUST_IMP::text), '^^') 
            , '||', IFNULL(TRIM(ZZPROB_FREQ::text), '^^') 
            , '||', IFNULL(TRIM(ZZSTRAT_INIT::text), '^^') 
            , '||', IFNULL(TRIM(ZZEMP_IMP::text), '^^') 
            , '||', IFNULL(TRIM(ZZDATA_SUP::text), '^^') 
            , '||', IFNULL(TRIM(ZZTIME_RES::text), '^^') 
            , '||', IFNULL(TRIM(ZZINIT_SAV_PROJ::text), '^^') 
            , '||', IFNULL(TRIM(ZZFORECAST_SAV::text), '^^') 
            , '||', IFNULL(TRIM(ZZACTUAL_SAV::text), '^^') 
            , '||', IFNULL(TRIM(ZZHOTLIST::text), '^^') 
            , '||', IFNULL(TRIM(ZZCONFIDENTIAL::text), '^^') 
            , '||', IFNULL(TRIM(ZZPROJECTNO::text), '^^') 
            , '||', IFNULL(TRIM(ZZACK_DATE::text), '^^') 
            , '||', IFNULL(TRIM(ZZLOC_KAT::text), '^^') 
            , '||', IFNULL(TRIM(ZZLOC_GRP::text), '^^') 
            , '||', IFNULL(TRIM(ZZLOC_COD::text), '^^') 
            , '||', IFNULL(TRIM(ZZCLASS_KAT::text), '^^') 
            , '||', IFNULL(TRIM(ZZCLASS_GRP::text), '^^') 
            , '||', IFNULL(TRIM(ZZCLASS_COD::text), '^^') 
            , '||', IFNULL(TRIM(ZZCOMPLETE_KAT::text), '^^') 
            , '||', IFNULL(TRIM(ZZCOMPLETE_GRP::text), '^^') 
            , '||', IFNULL(TRIM(ZZCOMPLETE_COD::text), '^^') 
            , '||', IFNULL(TRIM(ZZPARTS_ON_HOLD::text), '^^') 
            , '||', IFNULL(TRIM(ZZPRODTIM::text), '^^') 
            , '||', IFNULL(TRIM(ZZOWNER::text), '^^') 
            , '||', IFNULL(TRIM(ZZBUSUNITOWN::text), '^^') 
            , '||', IFNULL(TRIM(ZZPROD_STOPPED::text), '^^') 
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^')
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT