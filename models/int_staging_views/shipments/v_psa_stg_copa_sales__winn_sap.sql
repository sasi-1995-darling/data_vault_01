---- SRC LAYER ----
WITH
SRC_s              as ( SELECT ALTPERIO, ARTNR, AUART, AUGRU, BELNR, BUDAT, BUKRS, BZIRK, COPA_AWORG, COPA_AWSYS, COPA_AWTYP, COPA_BWZPT, FADAT, FKART, FRWAE, GJAHR, 
                               GLCHANGETIME, GLDELFLAG, GLREQUEST, GLSOURCESYSTEM, GSBER, HRKFT, HZDAT, KAUFN, KDPOS, KNDNR, KOKRS, KSTAR, KSTRG, KURSBK, KURSF, KURSKZ, 
                               KVGR1, KVGR2, KVGR3, MANDT, PALEDGER, PAOBJNR, PAPAOBJNR, PAPASUBNR, PASUBNR, PERDE, PERIO, PLIKZ, POSNR, PPRCTR, PRCTR, PRZNR, PSA_DELETE_IND,
                               PSA_LOAD_DTS, PSA_RECORD_SOURCE, PSPNR, PSTYV, QMNUM, RBELN, REC_WAERS, RKAUFNR, RKESTATU, RPOSN, SKOST, SPART, STO_BELNR, STO_POSNR, TIMESTMP, 
                               USNAM, VERSI, VKBUR, VKGRP, VKORG, VRGAR, VTWEG, VVAAL, VVACD, VVACL, VVACQ, VVADM, VVADV, VVAFC, VVAGM, VVANS, VVART, VVBLD, VVBON, VVCBA, 
                               VVCDR, VVCES, VVCJA, VVCJP, VVCMB, VVCMG, VVCMR, VVCMW, VVCOP, VVCRL, VVCRR, VVCST, VVDCI, VVDEF, VVDEV, VVDFR, VVDIP, VVDSA, VVDSP, VVEDI, 
                               VVERR, VVERW, VVFPP, VVFRA, VVFRC, VVFRM, VVFRO, VVGBP, VVGIS, VVGMG, VVGRI, VVGRR, VVGRS, VVHCD, VVHDL, VVHFR, VVICP, VVIND, VVLTS, VVMIN, 
                               VVMKF, VVMKT, VVMKV, VVMOD, VVMWP, VVNCD, VVNET, VVNSA, VVOCC, VVOIP, VVOPN, VVOTC, VVOVR, VVPRD, VVPRO, VVPRP, VVPRT, VVPRV, VVQTY, VVQTY_ME, 
                               VVRCD, VVRET, VVRFC, VVRND, VVRST, VVSBD, VVSBK, VVSBN, VVSDP, VVSEF, VVSEV, VVSHW, VVSIP, VVSOD, VVSPC, VVSPD, VVSPS, VVSSA, VVSTS, VVSUP, 
                               VVTHR, VVTRC, VVTRK, VVTSD, VVVBR, VVVBW, VVVIP, VVVLR, VVVMW, VVVPO, VVVPP, VVWHS, WADAT, WERKS, WWACC, WWCDV, WWCMP, WWDEF, WWDSP, WWDTC, 
                               WWDTS, WWDTZ, WWKNU, WWPBT, WWPCA, WWPCS, WWPFA, WWPFE, WWPFF, WWPFS, WWPII, WWPIP, WWPPY, WWPSH, WWPSL, WWPSR, WWPSS, WWRSN, WWSTC, WWSTP, 
                               WWSTS, WWSTZ, ZZDTP, ZZFIN, ZZHAN, ZZLIN, ZZMAJ, ZZMG1, ZZMIN, ZZORC, ZZPMI, ZZROM, ZZSEG, ZZTYP 
                               FROM {{ source('sap_ecc_prd', 'z_ce1new4') }} as SRC WHERE GJAHR >= 2024
                        /*This filter is to remove any extraneous SAP ECC COPA data that is already represented in historical SAP BW AZCOPA stage or outside of desired 
                        MDP time range to improve efficiency and performance of downstream objects*/ ),
SRC_a              as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_s              as ( SELECT * FROM sap_ecc_prd.z_ce1new4 )
SRC_a              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_s as (
    SELECT
        COALESCE(NULLIF(TRIM(ARTNR),''),'-1')                        as                                            ITEM_BK
      , COALESCE(NULLIF(TRIM(WERKS),''),'-1')                        as                                           PLANT_BK
      , COALESCE(NULLIF(TRIM(KNDNR),''),'-1')                        as                                        CUSTOMER_BK
      , COALESCE(NULLIF(TRIM(VKORG),''),'-1')                        as                              SALES_ORGANIZATION_BK
      , COALESCE(NULLIF(TRIM(VTWEG),''),'-1')                        as                            DISTRIBUTION_CHANNEL_BK
      , COALESCE(NULLIF(TRIM(SPART),''),'-1')                        as                                        DIVISION_BK
      , COALESCE(NULLIF(TRIM(KVGR1),''),'-2')                        as                                     KEY_ACCOUNT_BK
      , COALESCE(NULLIF(TRIM(KVGR2),''),'-2')                        as                               KEY_ACCOUNT_GROUP_BK
      , COALESCE(NULLIF(TRIM(PALEDGER),''),'-1')                     as                                   CURRENCY_TYPE_BK
      , COALESCE(NULLIF(TRIM(BELNR),''),'-1')                        as                                     COPA_HEADER_BK
      , COALESCE(NULLIF(TRIM(KAUFN),''),'-1')                        as                                    ORDER_HEADER_BK
      , CONCAT_WS('||', COALESCE(NULLIF(TRIM(KAUFN), ''), '-1'), COALESCE(NULLIF(TRIM(KDPOS), ''), '-1')) as                                      ORDER_LINE_BK
      , COALESCE(NULLIF(TRIM(KSTAR),''),'-1')                        as                                    COST_ELEMENT_BK
      , COALESCE(NULLIF(TRIM(SKOST),''),'-1')                        as                                     COST_CENTER_BK
      , COALESCE(NULLIF(TRIM(KOKRS),''),'-1')                        as                                CONTROLLING_AREA_BK
      , COALESCE(NULLIF(TRIM(PRCTR),''),'-2')                        as                                   PROFIT_CENTER_BK
      , MANDT
      , PALEDGER
      , VRGAR
      , VERSI
      , PERIO
      , PAOBJNR
      , PASUBNR
      , BELNR
      , WADAT
      , FADAT
      , BUDAT
      , GLREQUEST
      , HZDAT
      , USNAM
      , GJAHR
      , PERDE
      , ALTPERIO
      , PAPAOBJNR
      , PAPASUBNR
      , KNDNR
      , ARTNR
      , FKART
      , FRWAE
      , KURSF
      , KURSBK
      , KURSKZ
      , REC_WAERS
      , KAUFN
      , KDPOS
      , RKAUFNR
      , SKOST
      , PRZNR
      , BUKRS
      , KOKRS
      , WERKS
      , GSBER
      , VKORG
      , VTWEG
      , SPART
      , HRKFT
      , PLIKZ
      , KSTAR
      , PSPNR
      , KSTRG
      , RBELN
      , RPOSN
      , STO_BELNR
      , STO_POSNR
      , PRCTR
      , PPRCTR
      , RKESTATU
      , TIMESTMP
      , COPA_AWTYP
      , COPA_AWORG
      , COPA_BWZPT
      , COPA_AWSYS
      , AUGRU
      , PSTYV
      , WWRSN
      , WWKNU
      , ZZTYP
      , ZZSEG
      , ZZLIN
      , ZZDTP
      , ZZFIN
      , ZZHAN
      , ZZPMI
      , ZZROM
      , ZZMAJ
      , ZZMIN
      , ZZMG1
      , KVGR1
      , KVGR2
      , KVGR3
      , WWSTP
      , AUART
      , VKBUR
      , BZIRK
      , VKGRP
      , WWPCA
      , WWPCS
      , WWPFA
      , WWPFE
      , WWPFF
      , WWPFS
      , WWPII
      , WWPIP
      , WWPPY
      , WWPSH
      , WWPSL
      , WWPSR
      , WWPSS
      , WWPBT
      , WWCDV
      , WWDSP
      , WWSTC
      , WWSTS
      , WWSTZ
      , WWDTC
      , WWDTS
      , WWDTZ
      , QMNUM
      , WWDEF
      , WWCMP
      , ZZORC
      , WWACC
      , VVQTY
      , VVTRC
      , VVCRL
      , VVSBD
      , VVSBK
      , VVACL
      , VVIND
      , VVSIP
      , VVSPD
      , VVOIP
      , VVDIP
      , VVDCI
      , VVMOD
      , VVOVR
      , VVGRS
      , VVGIS
      , VVRST
      , VVHDL
      , VVFRA
      , VVFRC
      , VVFRM
      , VVACD
      , VVART
      , VVAAL
      , VVHFR
      , VVANS
      , VVCST
      , VVGMG
      , VVICP
      , VVAGM
      , VVVBW
      , VVVMW
      , VVERW
      , VVVBR
      , VVERR
      , VVCRR
      , VVFRO
      , VVCMW
      , VVCMR
      , VVCMG
      , VVMKT
      , VVADV
      , VVSEV
      , VVSEF
      , VVRND
      , VVDFR
      , VVDEF
      , VVDEV
      , VVCBA
      , VVADM
      , VVOCC
      , VVAFC
      , VVMKV
      , VVTHR
      , VVCES
      , VVBON
      , VVRET
      , VVMIN
      , VVACQ
      , VVCJA
      , VVDSP
      , VVEDI
      , VVHCD
      , VVLTS
      , VVOPN
      , VVPRO
      , VVSHW
      , VVSPC
      , VVSPS
      , VVTSD
      , VVVPO
      , VVBLD
      , VVCOP
      , VVGRR
      , VVMKF
      , VVMWP
      , VVNCD
      , VVPRD
      , VVPRV
      , VVSOD
      , VVSSA
      , VVSTS
      , VVSUP
      , VVTRK
      , VVVIP
      , VVVLR
      , VVWHS
      , VVRFC
      , VVDSA
      , VVOTC
      , VVPRT
      , VVRCD
      , VVSBN
      , VVCDR
      , VVCJP
      , VVPRP
      , VVVPP
      , VVFPP
      , VVNET
      , VVGBP
      , VVGRI
      , VVNSA
      , VVCMB
      , VVSDP
      , VVQTY_ME
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
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
        ))                                                           as                                           LOAD_DTS
      , POSNR                                                        as                                            S_POSNR
    FROM SRC_s
)

, LOGIC_a as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_a
)
---- RENAME LAYER ----

, RENAME_s as (
    SELECT
        ITEM_BK
      , PLANT_BK
      , CUSTOMER_BK
      , SALES_ORGANIZATION_BK
      , DISTRIBUTION_CHANNEL_BK
      , DIVISION_BK
      , KEY_ACCOUNT_BK
      , KEY_ACCOUNT_GROUP_BK
      , CURRENCY_TYPE_BK
      , COPA_HEADER_BK
      , ORDER_HEADER_BK
      , ORDER_LINE_BK
      , COST_ELEMENT_BK
      , COST_CENTER_BK
      , CONTROLLING_AREA_BK
      , PROFIT_CENTER_BK
      , MANDT
      , PALEDGER
      , VRGAR
      , VERSI
      , PERIO
      , PAOBJNR
      , PASUBNR
      , BELNR
      , WADAT
      , FADAT
      , BUDAT
      , GLREQUEST
      , HZDAT
      , USNAM
      , GJAHR
      , PERDE
      , ALTPERIO
      , PAPAOBJNR
      , PAPASUBNR
      , KNDNR
      , ARTNR
      , FKART
      , FRWAE
      , KURSF
      , KURSBK
      , KURSKZ
      , REC_WAERS
      , KAUFN
      , KDPOS
      , RKAUFNR
      , SKOST
      , PRZNR
      , BUKRS
      , KOKRS
      , WERKS
      , GSBER
      , VKORG
      , VTWEG
      , SPART
      , HRKFT
      , PLIKZ
      , KSTAR
      , PSPNR
      , KSTRG
      , RBELN
      , RPOSN
      , STO_BELNR
      , STO_POSNR
      , PRCTR
      , PPRCTR
      , RKESTATU
      , TIMESTMP
      , COPA_AWTYP
      , COPA_AWORG
      , COPA_BWZPT
      , COPA_AWSYS
      , AUGRU
      , PSTYV
      , WWRSN
      , WWKNU
      , ZZTYP
      , ZZSEG
      , ZZLIN
      , ZZDTP
      , ZZFIN
      , ZZHAN
      , ZZPMI
      , ZZROM
      , ZZMAJ
      , ZZMIN
      , ZZMG1
      , KVGR1
      , KVGR2
      , KVGR3
      , WWSTP
      , AUART
      , VKBUR
      , BZIRK
      , VKGRP
      , WWPCA
      , WWPCS
      , WWPFA
      , WWPFE
      , WWPFF
      , WWPFS
      , WWPII
      , WWPIP
      , WWPPY
      , WWPSH
      , WWPSL
      , WWPSR
      , WWPSS
      , WWPBT
      , WWCDV
      , WWDSP
      , WWSTC
      , WWSTS
      , WWSTZ
      , WWDTC
      , WWDTS
      , WWDTZ
      , QMNUM
      , WWDEF
      , WWCMP
      , ZZORC
      , WWACC
      , VVQTY
      , VVTRC
      , VVCRL
      , VVSBD
      , VVSBK
      , VVACL
      , VVIND
      , VVSIP
      , VVSPD
      , VVOIP
      , VVDIP
      , VVDCI
      , VVMOD
      , VVOVR
      , VVGRS
      , VVGIS
      , VVRST
      , VVHDL
      , VVFRA
      , VVFRC
      , VVFRM
      , VVACD
      , VVART
      , VVAAL
      , VVHFR
      , VVANS
      , VVCST
      , VVGMG
      , VVICP
      , VVAGM
      , VVVBW
      , VVVMW
      , VVERW
      , VVVBR
      , VVERR
      , VVCRR
      , VVFRO
      , VVCMW
      , VVCMR
      , VVCMG
      , VVMKT
      , VVADV
      , VVSEV
      , VVSEF
      , VVRND
      , VVDFR
      , VVDEF
      , VVDEV
      , VVCBA
      , VVADM
      , VVOCC
      , VVAFC
      , VVMKV
      , VVTHR
      , VVCES
      , VVBON
      , VVRET
      , VVMIN
      , VVACQ
      , VVCJA
      , VVDSP
      , VVEDI
      , VVHCD
      , VVLTS
      , VVOPN
      , VVPRO
      , VVSHW
      , VVSPC
      , VVSPS
      , VVTSD
      , VVVPO
      , VVBLD
      , VVCOP
      , VVGRR
      , VVMKF
      , VVMWP
      , VVNCD
      , VVPRD
      , VVPRV
      , VVSOD
      , VVSSA
      , VVSTS
      , VVSUP
      , VVTRK
      , VVVIP
      , VVVLR
      , VVWHS
      , VVRFC
      , VVDSA
      , VVOTC
      , VVPRT
      , VVRCD
      , VVSBN
      , VVCDR
      , VVCJP
      , VVPRP
      , VVVPP
      , VVFPP
      , VVNET
      , VVGBP
      , VVGRI
      , VVNSA
      , VVCMB
      , VVSDP
      , VVQTY_ME
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , S_POSNR
    FROM LOGIC_s
)

, RENAME_a as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_a
)
---- FILTER LAYER ----

, FILTER_s as (
    SELECT *
    FROM RENAME_s
)

, FILTER_a as (
    SELECT *
    FROM RENAME_a
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.CE1NEW4'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_s
    INNER JOIN FILTER_a
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          ITEM_BK
        , PLANT_BK
        , CUSTOMER_BK
        , SALES_ORGANIZATION_BK
        , DISTRIBUTION_CHANNEL_BK
        , DIVISION_BK
        , KEY_ACCOUNT_BK
        , KEY_ACCOUNT_GROUP_BK
        , CURRENCY_TYPE_BK
        , COPA_HEADER_BK
        , COALESCE(NULLIF(TRIM(S_POSNR),''),'-1')                      as COPA_LINE_BK
        , ORDER_HEADER_BK
        , ORDER_LINE_BK
        , COST_ELEMENT_BK
        , COST_CENTER_BK
        , CONTROLLING_AREA_BK
        , PROFIT_CENTER_BK
        , MANDT
        , PALEDGER
        , VRGAR
        , VERSI
        , PERIO
        , PAOBJNR
        , PASUBNR
        , BELNR
        , TRIM(S_POSNR)                                                as POSNR
        , WADAT
        , TRY_TO_DATE(WADAT, 'YYYYMMDD')                               as WADAT_DT
        , FADAT
        , TRY_TO_DATE(FADAT, 'YYYYMMDD')                               as FADAT_DT
        , BUDAT
        , TRY_TO_DATE(BUDAT, 'YYYYMMDD')                               as BUDAT_DT
        , GLREQUEST
        , HZDAT
        , USNAM
        , GJAHR
        , PERDE
        , ALTPERIO
        , PAPAOBJNR
        , PAPASUBNR
        , KNDNR
        , ARTNR
        , FKART
        , FRWAE
        , KURSF
        , KURSBK
        , KURSKZ
        , REC_WAERS
        , KAUFN
        , KDPOS
        , RKAUFNR
        , SKOST
        , PRZNR
        , BUKRS
        , KOKRS
        , WERKS
        , GSBER
        , VKORG
        , VTWEG
        , SPART
        , HRKFT
        , PLIKZ
        , KSTAR
        , PSPNR
        , KSTRG
        , RBELN
        , RPOSN
        , STO_BELNR
        , STO_POSNR
        , PRCTR
        , PPRCTR
        , RKESTATU
        , TIMESTMP
        , COPA_AWTYP
        , COPA_AWORG
        , COPA_BWZPT
        , COPA_AWSYS
        , AUGRU
        , PSTYV
        , WWRSN
        , WWKNU
        , ZZTYP
        , ZZSEG
        , ZZLIN
        , ZZDTP
        , ZZFIN
        , ZZHAN
        , ZZPMI
        , ZZROM
        , ZZMAJ
        , ZZMIN
        , ZZMG1
        , KVGR1
        , KVGR2
        , KVGR3
        , WWSTP
        , AUART
        , VKBUR
        , BZIRK
        , VKGRP
        , WWPCA
        , WWPCS
        , WWPFA
        , WWPFE
        , WWPFF
        , WWPFS
        , WWPII
        , WWPIP
        , WWPPY
        , WWPSH
        , WWPSL
        , WWPSR
        , WWPSS
        , WWPBT
        , WWCDV
        , WWDSP
        , WWSTC
        , WWSTS
        , WWSTZ
        , WWDTC
        , WWDTS
        , WWDTZ
        , QMNUM
        , WWDEF
        , WWCMP
        , ZZORC
        , WWACC
        , VVQTY
        , VVTRC
        , VVCRL
        , VVSBD
        , VVSBK
        , VVACL
        , VVIND
        , VVSIP
        , VVSPD
        , VVOIP
        , VVDIP
        , VVDCI
        , VVMOD
        , VVOVR
        , VVGRS
        , VVGIS
        , VVRST
        , VVHDL
        , VVFRA
        , VVFRC
        , VVFRM
        , VVACD
        , VVART
        , VVAAL
        , VVHFR
        , VVANS
        , VVCST
        , VVGMG
        , VVICP
        , VVAGM
        , VVVBW
        , VVVMW
        , VVERW
        , VVVBR
        , VVERR
        , VVCRR
        , VVFRO
        , VVCMW
        , VVCMR
        , VVCMG
        , VVMKT
        , VVADV
        , VVSEV
        , VVSEF
        , VVRND
        , VVDFR
        , VVDEF
        , VVDEV
        , VVCBA
        , VVADM
        , VVOCC
        , VVAFC
        , VVMKV
        , VVTHR
        , VVCES
        , VVBON
        , VVRET
        , VVMIN
        , VVACQ
        , VVCJA
        , VVDSP
        , VVEDI
        , VVHCD
        , VVLTS
        , VVOPN
        , VVPRO
        , VVSHW
        , VVSPC
        , VVSPS
        , VVTSD
        , VVVPO
        , VVBLD
        , VVCOP
        , VVGRR
        , VVMKF
        , VVMWP
        , VVNCD
        , VVPRD
        , VVPRV
        , VVSOD
        , VVSSA
        , VVSTS
        , VVSUP
        , VVTRK
        , VVVIP
        , VVVLR
        , VVWHS
        , VVRFC
        , VVDSA
        , VVOTC
        , VVPRT
        , VVRCD
        , VVSBN
        , VVCDR
        , VVCJP
        , VVPRP
        , VVVPP
        , VVFPP
        , VVNET
        , VVGBP
        , VVGRI
        , VVNSA
        , VVCMB
        , VVSDP
        , VVQTY_ME
        , GLDELFLAG
        , GLCHANGETIME
        , GLSOURCESYSTEM
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ITEM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ITEM_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PLANT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PLANT_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(CUSTOMER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as CUSTOMER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(SALES_ORGANIZATION_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as SALES_ORGANIZATION_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(DISTRIBUTION_CHANNEL_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as DISTRIBUTION_CHANNEL_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(DIVISION_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as DIVISION_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(KEY_ACCOUNT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as KEY_ACCOUNT_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(KEY_ACCOUNT_GROUP_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as KEY_ACCOUNT_GROUP_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(CURRENCY_TYPE_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as CURRENCY_TYPE_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(COPA_HEADER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(COPA_LINE_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as COPA_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ORDER_HEADER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ORDER_HEADER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ORDER_LINE_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ORDER_LINE_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(COST_ELEMENT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as COST_ELEMENT_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(COST_CENTER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as COST_CENTER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(CONTROLLING_AREA_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as CONTROLLING_AREA_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PROFIT_CENTER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PROFIT_CENTER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(COPA_HEADER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(COPA_LINE_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(CONTROLLING_AREA_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(COST_CENTER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(COST_ELEMENT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(CURRENCY_TYPE_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(ORDER_HEADER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(ORDER_LINE_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(MANDT as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(VRGAR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(COALESCE(NULLIF(VERSI,' '), '-1') as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(PERIO as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(PAOBJNR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(PASUBNR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(CUSTOMER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(SALES_ORGANIZATION_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(DISTRIBUTION_CHANNEL_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(DIVISION_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(ITEM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(PLANT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as LNK_COPA_SALES_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(CUSTOMER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(SALES_ORGANIZATION_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(DISTRIBUTION_CHANNEL_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(DIVISION_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as LNK_CUSTOMER_SALES_ORGANIZATION_DISTRIBUTION_CHANNEL_DIVISION_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ITEM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(PLANT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PLANT_ITEM_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(CUSTOMER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(SALES_ORGANIZATION_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(DISTRIBUTION_CHANNEL_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(DIVISION_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(KEY_ACCOUNT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(KEY_ACCOUNT_GROUP_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as LNK_CUSTOMER_SALES_ORGANIZATION_DISTRIBUTION_CHANNEL_DIVISION_KEY_ACCOUNT_KEY_ACCOUNT_GROUP_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(MANDT::text), '^^') 
            , '||', IFNULL(TRIM(PALEDGER::text), '^^') 
            , '||', IFNULL(TRIM(VRGAR::text), '^^') 
            , '||', IFNULL(TRIM(VERSI::text), '^^') 
            , '||', IFNULL(TRIM(PERIO::text), '^^') 
            , '||', IFNULL(TRIM(PAOBJNR::text), '^^') 
            , '||', IFNULL(TRIM(PASUBNR::text), '^^') 
            , '||', IFNULL(TRIM(BELNR::text), '^^') 
            , '||', IFNULL(TRIM(POSNR::text), '^^') 
            , '||', IFNULL(TRIM(WADAT::text), '^^') 
            , '||', IFNULL(TRIM(FADAT::text), '^^') 
            , '||', IFNULL(TRIM(BUDAT::text), '^^') 
            , '||', IFNULL(TRIM(HZDAT::text), '^^') 
            , '||', IFNULL(TRIM(USNAM::text), '^^') 
            , '||', IFNULL(TRIM(GJAHR::text), '^^') 
            , '||', IFNULL(TRIM(PERDE::text), '^^') 
            , '||', IFNULL(TRIM(ALTPERIO::text), '^^') 
            , '||', IFNULL(TRIM(PAPAOBJNR::text), '^^') 
            , '||', IFNULL(TRIM(PAPASUBNR::text), '^^') 
            , '||', IFNULL(TRIM(KNDNR::text), '^^') 
            , '||', IFNULL(TRIM(ARTNR::text), '^^') 
            , '||', IFNULL(TRIM(FKART::text), '^^') 
            , '||', IFNULL(TRIM(FRWAE::text), '^^') 
            , '||', IFNULL(TRIM(KURSF::text), '^^') 
            , '||', IFNULL(TRIM(KURSBK::text), '^^') 
            , '||', IFNULL(TRIM(KURSKZ::text), '^^') 
            , '||', IFNULL(TRIM(REC_WAERS::text), '^^') 
            , '||', IFNULL(TRIM(KAUFN::text), '^^') 
            , '||', IFNULL(TRIM(KDPOS::text), '^^') 
            , '||', IFNULL(TRIM(RKAUFNR::text), '^^') 
            , '||', IFNULL(TRIM(SKOST::text), '^^') 
            , '||', IFNULL(TRIM(PRZNR::text), '^^') 
            , '||', IFNULL(TRIM(BUKRS::text), '^^') 
            , '||', IFNULL(TRIM(KOKRS::text), '^^') 
            , '||', IFNULL(TRIM(WERKS::text), '^^') 
            , '||', IFNULL(TRIM(GSBER::text), '^^') 
            , '||', IFNULL(TRIM(VKORG::text), '^^') 
            , '||', IFNULL(TRIM(VTWEG::text), '^^') 
            , '||', IFNULL(TRIM(SPART::text), '^^') 
            , '||', IFNULL(TRIM(HRKFT::text), '^^') 
            , '||', IFNULL(TRIM(PLIKZ::text), '^^') 
            , '||', IFNULL(TRIM(KSTAR::text), '^^') 
            , '||', IFNULL(TRIM(PSPNR::text), '^^') 
            , '||', IFNULL(TRIM(KSTRG::text), '^^') 
            , '||', IFNULL(TRIM(RBELN::text), '^^') 
            , '||', IFNULL(TRIM(RPOSN::text), '^^') 
            , '||', IFNULL(TRIM(STO_BELNR::text), '^^') 
            , '||', IFNULL(TRIM(STO_POSNR::text), '^^') 
            , '||', IFNULL(TRIM(PRCTR::text), '^^') 
            , '||', IFNULL(TRIM(PPRCTR::text), '^^') 
            , '||', IFNULL(TRIM(RKESTATU::text), '^^') 
            , '||', IFNULL(TRIM(TIMESTMP::text), '^^') 
            , '||', IFNULL(TRIM(COPA_AWTYP::text), '^^') 
            , '||', IFNULL(TRIM(COPA_AWORG::text), '^^') 
            , '||', IFNULL(TRIM(COPA_BWZPT::text), '^^') 
            , '||', IFNULL(TRIM(COPA_AWSYS::text), '^^') 
            , '||', IFNULL(TRIM(AUGRU::text), '^^') 
            , '||', IFNULL(TRIM(PSTYV::text), '^^') 
            , '||', IFNULL(TRIM(WWRSN::text), '^^') 
            , '||', IFNULL(TRIM(WWKNU::text), '^^') 
            , '||', IFNULL(TRIM(ZZTYP::text), '^^') 
            , '||', IFNULL(TRIM(ZZSEG::text), '^^') 
            , '||', IFNULL(TRIM(ZZLIN::text), '^^') 
            , '||', IFNULL(TRIM(ZZDTP::text), '^^') 
            , '||', IFNULL(TRIM(ZZFIN::text), '^^') 
            , '||', IFNULL(TRIM(ZZHAN::text), '^^') 
            , '||', IFNULL(TRIM(ZZPMI::text), '^^') 
            , '||', IFNULL(TRIM(ZZROM::text), '^^') 
            , '||', IFNULL(TRIM(ZZMAJ::text), '^^') 
            , '||', IFNULL(TRIM(ZZMIN::text), '^^') 
            , '||', IFNULL(TRIM(ZZMG1::text), '^^') 
            , '||', IFNULL(TRIM(KVGR1::text), '^^') 
            , '||', IFNULL(TRIM(KVGR2::text), '^^') 
            , '||', IFNULL(TRIM(KVGR3::text), '^^') 
            , '||', IFNULL(TRIM(WWSTP::text), '^^') 
            , '||', IFNULL(TRIM(AUART::text), '^^') 
            , '||', IFNULL(TRIM(VKBUR::text), '^^') 
            , '||', IFNULL(TRIM(BZIRK::text), '^^') 
            , '||', IFNULL(TRIM(VKGRP::text), '^^') 
            , '||', IFNULL(TRIM(WWPCA::text), '^^') 
            , '||', IFNULL(TRIM(WWPCS::text), '^^') 
            , '||', IFNULL(TRIM(WWPFA::text), '^^') 
            , '||', IFNULL(TRIM(WWPFE::text), '^^') 
            , '||', IFNULL(TRIM(WWPFF::text), '^^') 
            , '||', IFNULL(TRIM(WWPFS::text), '^^') 
            , '||', IFNULL(TRIM(WWPII::text), '^^') 
            , '||', IFNULL(TRIM(WWPIP::text), '^^') 
            , '||', IFNULL(TRIM(WWPPY::text), '^^') 
            , '||', IFNULL(TRIM(WWPSH::text), '^^') 
            , '||', IFNULL(TRIM(WWPSL::text), '^^') 
            , '||', IFNULL(TRIM(WWPSR::text), '^^') 
            , '||', IFNULL(TRIM(WWPSS::text), '^^') 
            , '||', IFNULL(TRIM(WWPBT::text), '^^') 
            , '||', IFNULL(TRIM(WWCDV::text), '^^') 
            , '||', IFNULL(TRIM(WWDSP::text), '^^') 
            , '||', IFNULL(TRIM(WWSTC::text), '^^') 
            , '||', IFNULL(TRIM(WWSTS::text), '^^') 
            , '||', IFNULL(TRIM(WWSTZ::text), '^^') 
            , '||', IFNULL(TRIM(WWDTC::text), '^^') 
            , '||', IFNULL(TRIM(WWDTS::text), '^^') 
            , '||', IFNULL(TRIM(WWDTZ::text), '^^') 
            , '||', IFNULL(TRIM(QMNUM::text), '^^') 
            , '||', IFNULL(TRIM(WWDEF::text), '^^') 
            , '||', IFNULL(TRIM(WWCMP::text), '^^') 
            , '||', IFNULL(TRIM(ZZORC::text), '^^') 
            , '||', IFNULL(TRIM(WWACC::text), '^^') 
            , '||', IFNULL(TRIM(VVQTY::text), '^^') 
            , '||', IFNULL(TRIM(VVTRC::text), '^^') 
            , '||', IFNULL(TRIM(VVCRL::text), '^^') 
            , '||', IFNULL(TRIM(VVSBD::text), '^^') 
            , '||', IFNULL(TRIM(VVSBK::text), '^^') 
            , '||', IFNULL(TRIM(VVACL::text), '^^') 
            , '||', IFNULL(TRIM(VVIND::text), '^^') 
            , '||', IFNULL(TRIM(VVSIP::text), '^^') 
            , '||', IFNULL(TRIM(VVSPD::text), '^^') 
            , '||', IFNULL(TRIM(VVOIP::text), '^^') 
            , '||', IFNULL(TRIM(VVDIP::text), '^^') 
            , '||', IFNULL(TRIM(VVDCI::text), '^^') 
            , '||', IFNULL(TRIM(VVMOD::text), '^^') 
            , '||', IFNULL(TRIM(VVOVR::text), '^^') 
            , '||', IFNULL(TRIM(VVGRS::text), '^^') 
            , '||', IFNULL(TRIM(VVGIS::text), '^^') 
            , '||', IFNULL(TRIM(VVRST::text), '^^') 
            , '||', IFNULL(TRIM(VVHDL::text), '^^') 
            , '||', IFNULL(TRIM(VVFRA::text), '^^') 
            , '||', IFNULL(TRIM(VVFRC::text), '^^') 
            , '||', IFNULL(TRIM(VVFRM::text), '^^') 
            , '||', IFNULL(TRIM(VVACD::text), '^^') 
            , '||', IFNULL(TRIM(VVART::text), '^^') 
            , '||', IFNULL(TRIM(VVAAL::text), '^^') 
            , '||', IFNULL(TRIM(VVHFR::text), '^^') 
            , '||', IFNULL(TRIM(VVANS::text), '^^') 
            , '||', IFNULL(TRIM(VVCST::text), '^^') 
            , '||', IFNULL(TRIM(VVGMG::text), '^^') 
            , '||', IFNULL(TRIM(VVICP::text), '^^') 
            , '||', IFNULL(TRIM(VVAGM::text), '^^') 
            , '||', IFNULL(TRIM(VVVBW::text), '^^') 
            , '||', IFNULL(TRIM(VVVMW::text), '^^') 
            , '||', IFNULL(TRIM(VVERW::text), '^^') 
            , '||', IFNULL(TRIM(VVVBR::text), '^^') 
            , '||', IFNULL(TRIM(VVERR::text), '^^') 
            , '||', IFNULL(TRIM(VVCRR::text), '^^') 
            , '||', IFNULL(TRIM(VVFRO::text), '^^') 
            , '||', IFNULL(TRIM(VVCMW::text), '^^') 
            , '||', IFNULL(TRIM(VVCMR::text), '^^') 
            , '||', IFNULL(TRIM(VVCMG::text), '^^') 
            , '||', IFNULL(TRIM(VVMKT::text), '^^') 
            , '||', IFNULL(TRIM(VVADV::text), '^^') 
            , '||', IFNULL(TRIM(VVSEV::text), '^^') 
            , '||', IFNULL(TRIM(VVSEF::text), '^^') 
            , '||', IFNULL(TRIM(VVRND::text), '^^') 
            , '||', IFNULL(TRIM(VVDFR::text), '^^') 
            , '||', IFNULL(TRIM(VVDEF::text), '^^') 
            , '||', IFNULL(TRIM(VVDEV::text), '^^') 
            , '||', IFNULL(TRIM(VVCBA::text), '^^') 
            , '||', IFNULL(TRIM(VVADM::text), '^^') 
            , '||', IFNULL(TRIM(VVOCC::text), '^^') 
            , '||', IFNULL(TRIM(VVAFC::text), '^^') 
            , '||', IFNULL(TRIM(VVMKV::text), '^^') 
            , '||', IFNULL(TRIM(VVTHR::text), '^^') 
            , '||', IFNULL(TRIM(VVCES::text), '^^') 
            , '||', IFNULL(TRIM(VVBON::text), '^^') 
            , '||', IFNULL(TRIM(VVRET::text), '^^') 
            , '||', IFNULL(TRIM(VVMIN::text), '^^') 
            , '||', IFNULL(TRIM(VVACQ::text), '^^') 
            , '||', IFNULL(TRIM(VVCJA::text), '^^') 
            , '||', IFNULL(TRIM(VVDSP::text), '^^') 
            , '||', IFNULL(TRIM(VVEDI::text), '^^') 
            , '||', IFNULL(TRIM(VVHCD::text), '^^') 
            , '||', IFNULL(TRIM(VVLTS::text), '^^') 
            , '||', IFNULL(TRIM(VVOPN::text), '^^') 
            , '||', IFNULL(TRIM(VVPRO::text), '^^') 
            , '||', IFNULL(TRIM(VVSHW::text), '^^') 
            , '||', IFNULL(TRIM(VVSPC::text), '^^') 
            , '||', IFNULL(TRIM(VVSPS::text), '^^') 
            , '||', IFNULL(TRIM(VVTSD::text), '^^') 
            , '||', IFNULL(TRIM(VVVPO::text), '^^') 
            , '||', IFNULL(TRIM(VVBLD::text), '^^') 
            , '||', IFNULL(TRIM(VVCOP::text), '^^') 
            , '||', IFNULL(TRIM(VVGRR::text), '^^') 
            , '||', IFNULL(TRIM(VVMKF::text), '^^') 
            , '||', IFNULL(TRIM(VVMWP::text), '^^') 
            , '||', IFNULL(TRIM(VVNCD::text), '^^') 
            , '||', IFNULL(TRIM(VVPRD::text), '^^') 
            , '||', IFNULL(TRIM(VVPRV::text), '^^') 
            , '||', IFNULL(TRIM(VVSOD::text), '^^') 
            , '||', IFNULL(TRIM(VVSSA::text), '^^') 
            , '||', IFNULL(TRIM(VVSTS::text), '^^') 
            , '||', IFNULL(TRIM(VVSUP::text), '^^') 
            , '||', IFNULL(TRIM(VVTRK::text), '^^') 
            , '||', IFNULL(TRIM(VVVIP::text), '^^') 
            , '||', IFNULL(TRIM(VVVLR::text), '^^') 
            , '||', IFNULL(TRIM(VVWHS::text), '^^') 
            , '||', IFNULL(TRIM(VVRFC::text), '^^') 
            , '||', IFNULL(TRIM(VVDSA::text), '^^') 
            , '||', IFNULL(TRIM(VVOTC::text), '^^') 
            , '||', IFNULL(TRIM(VVPRT::text), '^^') 
            , '||', IFNULL(TRIM(VVRCD::text), '^^') 
            , '||', IFNULL(TRIM(VVSBN::text), '^^') 
            , '||', IFNULL(TRIM(VVCDR::text), '^^') 
            , '||', IFNULL(TRIM(VVCJP::text), '^^') 
            , '||', IFNULL(TRIM(VVPRP::text), '^^') 
            , '||', IFNULL(TRIM(VVVPP::text), '^^') 
            , '||', IFNULL(TRIM(VVFPP::text), '^^') 
            , '||', IFNULL(TRIM(VVNET::text), '^^') 
            , '||', IFNULL(TRIM(VVGBP::text), '^^') 
            , '||', IFNULL(TRIM(VVGRI::text), '^^') 
            , '||', IFNULL(TRIM(VVNSA::text), '^^') 
            , '||', IFNULL(TRIM(VVCMB::text), '^^') 
            , '||', IFNULL(TRIM(VVSDP::text), '^^') 
            , '||', IFNULL(TRIM(VVQTY_ME::text), '^^') 
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^') 
            , '||', IFNULL(TRIM(GLSOURCESYSTEM::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
