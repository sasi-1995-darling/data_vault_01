---- SRC LAYER ----
WITH
SRC_S              as ( SELECT * FROM {{ source('sap_ecc_prd', 'z_ce1new4') }} as SRC 
                        where try_to_date(budat, 'YYYYMMDD')  >= '2023-12-31' ),
SRC_A              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S              as ( SELECT * FROM sap_ecc_prd.z_ce1new4 )
, SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        CONCAT(
            mandt, '||',
            paledger, '||',
            vrgar, '||',
            versi, '||',
            perio, '||',
            paobjnr, '||',
            pasubnr, '||',
            belnr, '||',
            trim(posnr)
        )                                                            as                                      COPA_SALES_BK
      , MANDT
      , PALEDGER
      , VRGAR
      , VERSI
      , PERIO
      , PAOBJNR
      , PASUBNR
      , BELNR
      , POSNR
      , GLREQUEST
      , HZDAT
      , USNAM
      , GJAHR
      , PERDE
      , WADAT
      , try_to_date(WADAT,  'YYYYMMDD')                               as                                           WADAT_DT
      , FADAT
      , try_to_date(FADAT,  'YYYYMMDD')                               as                                           FADAT_DT
      , BUDAT
      , try_to_date(BUDAT,  'YYYYMMDD')                               as                                           BUDAT_DT
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
      , VVQTY_ME
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
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , CONVERT_TIMEZONE('UTC', 
            IFF(PSA_DELETE_IND = 'Y', PSA_LOAD_DTS, TO_TIMESTAMP(
            SUBSTR(GLCHANGETIME, 1, 8) || ' ' ||
            SUBSTR(GLCHANGETIME, 9, 2) || ':' ||
            SUBSTR(GLCHANGETIME, 11, 2) || ':' ||
            SUBSTR(GLCHANGETIME, 13, 2) || '.' ||
            REGEXP_REPLACE(SUBSTR(GLCHANGETIME, 16), '^\\.', ''),
            'YYYYMMDD HH24:MI:SS.FF9'
        )))                                                          as                                           LOAD_DTS
      , coalesce(nullif(trim(ARTNR), ''), '-1')                      as                                            ITEM_BK
      , coalesce(nullif(trim(KNDNR  ), ''), '-1')                    as                                        CUSTOMER_BK
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
        COPA_SALES_BK
      , MANDT
      , PALEDGER
      , VRGAR
      , VERSI
      , PERIO
      , PAOBJNR
      , PASUBNR
      , BELNR
      , POSNR
      , GLREQUEST
      , HZDAT
      , USNAM
      , GJAHR
      , PERDE
      , WADAT
      , WADAT_DT
      , FADAT
      , FADAT_DT
      , BUDAT
      , BUDAT_DT
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
      , VVQTY_ME
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
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , ITEM_BK
      , CUSTOMER_BK
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
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.CE1NEW4'
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
          COPA_SALES_BK
        , MANDT
        , PALEDGER
        , VRGAR
        , VERSI
        , PERIO
        , PAOBJNR
        , PASUBNR
        , BELNR
        , POSNR
        , GLREQUEST
        , HZDAT
        , USNAM
        , GJAHR
        , PERDE
        , WADAT
        , WADAT_DT
        , FADAT
        , FADAT_DT
        , BUDAT
        , BUDAT_DT
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
        , VVQTY_ME
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
        , GLDELFLAG
        , GLCHANGETIME
        , GLSOURCESYSTEM
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , ITEM_BK
        , CUSTOMER_BK
        , PLANT_BK
        , CONCAT(
        kndnr, '||',
        vkorg, '||',
        vtweg, '||',
        spart
    ) as CUST_SALES_AREA_BK
        , CONCAT(
artnr, '||',kndnr, '||',mandt, '||',paledger, '||',vrgar, '||',versi, '||',perio, '||',paobjnr, '||',pasubnr, '||',belnr, '||',trim(posnr), '||',kndnr, '||',vkorg, '||',vtweg, '||',spart
) as ITEM_CUST_SHIPMENT_BK
        , CONCAT(
mandt, '||',paledger, '||',vrgar, '||',versi, '||',perio, '||',paobjnr, '||',pasubnr, '||',belnr, '||',trim(posnr), '||',werks
) as PLANT_SHIPMENT_BK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(COPA_SALES_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as COPA_SALES_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ITEM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ITEM_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(CUSTOMER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as CUSTOMER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PLANT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PLANT_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(CUST_SALES_AREA_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as CUST_SALES_AREA_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ITEM_CUST_SHIPMENT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ITEM_CUST_SHIPMENT_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PLANT_SHIPMENT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PLANT_SHIPMENT_HK
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
            , '||', IFNULL(TRIM(GLREQUEST::text), '^^') 
            , '||', IFNULL(TRIM(HZDAT::text), '^^') 
            , '||', IFNULL(TRIM(USNAM::text), '^^') 
            , '||', IFNULL(TRIM(GJAHR::text), '^^') 
            , '||', IFNULL(TRIM(PERDE::text), '^^') 
            , '||', IFNULL(TRIM(WADAT::text), '^^') 
            , '||', IFNULL(TRIM(WADAT_DT::text), '^^') 
            , '||', IFNULL(TRIM(FADAT::text), '^^') 
            , '||', IFNULL(TRIM(FADAT_DT::text), '^^') 
            , '||', IFNULL(TRIM(BUDAT::text), '^^') 
            , '||', IFNULL(TRIM(BUDAT_DT::text), '^^') 
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
            , '||', IFNULL(TRIM(VVQTY_ME::text), '^^') 
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
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
