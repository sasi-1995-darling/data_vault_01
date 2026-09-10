{{
  config(
    materialized = 'incremental',
    unique_key='LNK_COPA_SALES_HK',
    incremental_strategy= 'merge'
  )
}}


---- SRC LAYER ----
WITH
SRC_LNK_CS             as ( SELECT LNK_COPA_SALES_HK, COPA_HK, REC_SRC FROM {{ ref('lnk_copa_sales') }} as SRC ),
SRC_HUB_CS             as ( SELECT COPA_HK, BKCC FROM {{ ref('hub_copa') }} as SRC ),
SRC_LSAT_CS            as ( SELECT LNK_COPA_SALES_HK, MANDT, PALEDGER, VRGAR, PERIO, PAOBJNR, PASUBNR, BELNR, POSNR, WADAT, WADAT_DT, FADAT, FADAT_DT, BUDAT, BUDAT_DT, GJAHR, KNDNR, ARTNR, FKART, KURSF, REC_WAERS, KAUFN, KDPOS, RKAUFNR, SKOST, PRZNR, BUKRS, KOKRS, WERKS, GSBER, VKORG, VTWEG, SPART, KSTAR, PSPNR, KSTRG, RBELN, RPOSN, STO_BELNR, STO_POSNR, PRCTR, PPRCTR, AUGRU, PSTYV, WWRSN, WWKNU, ZZTYP, ZZSEG, ZZLIN, ZZDTP, ZZFIN, ZZHAN, ZZPMI, ZZROM, ZZMAJ, ZZMIN, ZZMG1, KVGR1, KVGR2, KVGR3, WWSTP, AUART, VKBUR, BZIRK, VKGRP, WWPCA, WWPCS, WWPFA, WWPFE, WWPFF, WWPFS, WWPII, WWPIP, WWPPY, WWPSH, WWPSL, WWPSR, WWPSS, WWPBT, WWCDV, WWDSP, WWSTC, WWSTS, WWSTZ, WWDTC, WWDTS, WWDTZ, QMNUM, WWDEF, WWCMP, ZZORC, VVQTY, VVTRC, VVCRL, VVSBD, VVSBK, VVACL, VVIND, VVSIP, VVSPD, VVOIP, VVDIP, VVDCI, VVMOD, VVOVR, VVGRS, VVGIS, VVRST, VVHDL, VVFRA, VVFRC, VVFRM, VVACD, VVART, VVAAL, VVHFR, VVANS, VVCST, VVGMG, VVICP, VVAGM, VVVBW, VVVMW, VVERW, VVVBR, VVERR, VVCRR, VVFRO, VVCMW, VVCMR, VVCMG, VVMKT, VVADV, VVSEV, VVSEF, VVRND, VVDFR, VVDEF, VVDEV, VVCBA, VVADM, VVOCC, VVAFC, VVMKV, VVTHR, VVCES, VVBON, VVRET, VVMIN, VVACQ, VVCJA, VVDSP, VVEDI, VVHCD, VVLTS, VVOPN, VVPRO, VVSHW, VVSPC, VVSPS, VVTSD, VVVPO, VVBLD, VVCOP, VVGRR, VVMKF, VVMWP, VVNCD, VVPRD, VVPRV, VVSOD, VVSSA, VVSTS, VVSUP, VVTRK, VVVIP, VVVLR, VVWHS, VVRFC, VVDSA, VVOTC, VVPRT, VVRCD, VVSBN, VVCDR, VVCJP, VVPRP, VVVPP, VVFPP, VVNET, VVGBP, VVGRI, VVNSA, VVCMB, VVSDP, VVQTY_ME
                            FROM {{ ref('lsat_copa_sales__winn_sap') }} as SRC
                            QUALIFY 1= ROW_NUMBER() OVER(PARTITION BY LNK_COPA_SALES_HK ORDER BY LOAD_DTS DESC)
                        /*This Jinja logic to intelligently bypass history data refreshes */
                        {% if target.name not in ['default', 'dev', 'qa'] %}
                            UNION ALL
                            SELECT LNK_COPA_SALES_HK, MANDT, PALEDGER, VRGAR, PERIO, PAOBJNR, PASUBNR, BELNR, POSNR, WADAT, WADAT_DT, FADAT, FADAT_DT, BUDAT, BUDAT_DT, GJAHR, KNDNR, ARTNR, FKART, KURSF, REC_WAERS, KAUFN, KDPOS, RKAUFNR, SKOST, PRZNR, BUKRS, KOKRS, WERKS, GSBER, VKORG, VTWEG, SPART, KSTAR, PSPNR, KSTRG, RBELN, RPOSN, STO_BELNR, STO_POSNR, PRCTR, PPRCTR, AUGRU, PSTYV, WWRSN, WWKNU, ZZTYP, ZZSEG, ZZLIN, ZZDTP, ZZFIN, ZZHAN, ZZPMI, ZZROM, ZZMAJ, ZZMIN, ZZMG1, KVGR1, KVGR2, KVGR3, WWSTP, AUART, VKBUR, BZIRK, VKGRP, WWPCA, WWPCS, WWPFA, WWPFE, WWPFF, WWPFS, WWPII, WWPIP, WWPPY, WWPSH, WWPSL, WWPSR, WWPSS, WWPBT, WWCDV, WWDSP, WWSTC, WWSTS, WWSTZ, WWDTC, WWDTS, WWDTZ, QMNUM, WWDEF, WWCMP, ZZORC, VVQTY, VVTRC, VVCRL, VVSBD, VVSBK, VVACL, VVIND, VVSIP, VVSPD, VVOIP, VVDIP, VVDCI, VVMOD, VVOVR, VVGRS, VVGIS, VVRST, VVHDL, VVFRA, VVFRC, VVFRM, VVACD, VVART, VVAAL, VVHFR, VVANS, VVCST, VVGMG, VVICP, VVAGM, VVVBW, VVVMW, VVERW, VVVBR, VVERR, VVCRR, VVFRO, VVCMW, VVCMR, VVCMG, VVMKT, VVADV, VVSEV, VVSEF, VVRND, VVDFR, VVDEF, VVDEV, VVCBA, VVADM, VVOCC, VVAFC, VVMKV, VVTHR, VVCES, VVBON, VVRET, VVMIN, VVACQ, VVCJA, VVDSP, VVEDI, VVHCD, VVLTS, VVOPN, VVPRO, VVSHW, VVSPC, VVSPS, VVTSD, VVVPO, VVBLD, VVCOP, VVGRR, VVMKF, VVMWP, VVNCD, VVPRD, VVPRV, VVSOD, VVSSA, VVSTS, VVSUP, VVTRK, VVVIP, VVVLR, VVWHS, VVRFC, VVDSA, VVOTC, VVPRT, VVRCD, VVSBN, VVCDR, VVCJP, VVPRP, VVVPP, VVFPP, VVNET, VVGBP, VVGRI, VVNSA, VVCMB, VVSDP, VVQTY_ME
                            FROM {{ ref('lsat_copa_sales_history__winn_sap') }} as SRC
                            QUALIFY 1= ROW_NUMBER() OVER(PARTITION BY LNK_COPA_SALES_HK ORDER BY LOAD_DTS DESC)                       
                        {% endif %} ) 

/*
SRC_LNK_CS             as ( SELECT * FROM RAW_VAULT.LNK_COPA_SALES )
SRC_HUB_CS             as ( SELECT * FROM RAW_VAULT.HUB_COPA )
SRC_LSAT_CS            as ( SELECT * FROM RAW_VAULT.LSAT_COPA_SALES__WINN_SAP )
SRC_LSAT_CSH           as ( SELECT * FROM RAW_VAULT.LSAT_COPA_SALES_HISTORY__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_LNK_CS as (
    SELECT
        LNK_COPA_SALES_HK
      , COPA_HK
      , REC_SRC
    FROM SRC_LNK_CS
)

, LOGIC_HUB_CS as (
    SELECT
        COPA_HK
      , BKCC
    FROM SRC_HUB_CS
)

, LOGIC_LSAT_CS as (
    SELECT
        LNK_COPA_SALES_HK
      , MANDT
      , PALEDGER
      , VRGAR
      , CAST(
            CASE
                WHEN LENGTH(TRIM(PERIO)) = 6
                    THEN SUBSTR(TRIM(PERIO), 1, 4) || SUBSTR(TRIM(PERIO), 5, 2)
                WHEN LENGTH(TRIM(PERIO)) = 4
                    THEN PERIO || '01'
                WHEN LENGTH(TRIM(PERIO)) = 2 AND GJAHR IS NOT NULL
                    THEN GJAHR || LPAD(TRIM(PERIO), 2, '0')
                WHEN LENGTH(TRIM(PERIO)) = 8
                    THEN SUBSTR(TRIM(PERIO), 1, 4) || SUBSTR(TRIM(PERIO), 5, 2)
                WHEN LENGTH(TRIM(PERIO)) = 7
                    AND LEFT(TRIM(PERIO), 4) = GJAHR
                    AND SUBSTR(TRIM(PERIO), 5, 1) = '0'
                    THEN LEFT(TRIM(PERIO), 4) || SUBSTR(TRIM(PERIO), 6, 2)
                WHEN LENGTH(GJAHR) = 4
                    AND LENGTH(TRIM(PERIO)) > 2
                    AND LENGTH(TRIM(PERIO)) < 6
                    THEN GJAHR || LPAD(LEFT(TRIM(PERIO), 2), 2, '0')
            END AS INTEGER
        )                                                                          as                               FISCAL_MONTH__YYYYMM
      , PAOBJNR
      , PASUBNR
      , BELNR
      , POSNR
      , CAST(WADAT as INTEGER)                                                     as                               ISSUE_DATE__YYYYMMDD
      , CAST(FADAT AS INTEGER)                                                     as                             BILLING_DATE__YYYYMMDD
      , CAST(BUDAT AS INTEGER)                                                     as                             POSTING_DATE__YYYYMMDD
      , CAST(GJAHR AS INTEGER)                                                     as                                  FISCAL_YEAR__YYYY
      , KNDNR
      , ARTNR
      , FKART
      , KURSF
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
      , KSTAR
      , PSPNR
      , KSTRG
      , RBELN
      , RPOSN
      , STO_BELNR
      , STO_POSNR
      , PRCTR
      , PPRCTR
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
      , CONCAT_WS('|', VTWEG, PSTYV, AUGRU, AUART, KNDNR, ARTNR )                  as                                     GL_KEY
      , CONCAT_WS('|', VTWEG, PSTYV, AUGRU, AUART, KNDNR )                         as                           GL_KEY_PARTIAL_2
      , CONCAT_WS('|', VTWEG, PSTYV, AUGRU, AUART )                                as                           GL_KEY_PARTIAL_3
      , CASE CONCAT_WS('|', VTWEG, PSTYV, AUGRU, AUART, KNDNR, ARTNR )
            WHEN 'DR|G2N|500|G2|0000100020|FSNOTAX' THEN '0000410060'
            WHEN 'DR|G2N|500|G2|0000100020|FSMISC' THEN '0000410070'
            WHEN 'DR|G2N|500|G2|0000100065|FSLABOR' THEN '0000640242'
            WHEN 'DR|G2N|502|G2|0000100065|FSLABOR' THEN '0000640242'
            WHEN 'DR|G2N|500|G2|0000100020|CSCLAIM' THEN '0000640740'
            WHEN 'DR|G2N|502|G2|0000100020|CSCLAIM' THEN '0000640740'
            WHEN 'DR|G2N|500|G2|0000100020|FSDAMAGE' THEN '0000640760'
            WHEN 'DR|G2N|500|G2|0000100020|FSLABOR' THEN '0000640760'
            WHEN 'WH|G2N|500|G2|0000100065|FSLABOR' THEN '0000640242'
            WHEN 'WH|G2N|502|G2|0000100065|FSLABOR' THEN '0000640242'
            WHEN 'DR|ZNC|500|G2|0000100065|FSLABOR' THEN '0000640242'
            WHEN 'DR|ZNC|502|G2|0000100065|FSLABOR' THEN '0000640242'
            WHEN 'DR|ZNC|500|G2|0000100020|FSDAMAGE' THEN '0000640760'
            WHEN 'DR|ZNC|500|G2|0000100020|FSLABOR' THEN '0000640760'
            WHEN 'WH|ZNC|500|G2|0000100065|FSLABOR' THEN '0000640242'
            WHEN 'WH|ZNC|502|G2|0000100065|FSLABOR' THEN '0000640242'
            ELSE NULL
        END AS GL_ACCOUNT_OVERRIDE_FULL
      , CASE CONCAT_WS('|', VTWEG, PSTYV, AUGRU, AUART, KNDNR )
            WHEN 'DR|G2N|500|G2|0000100020' THEN '0000410060'
            WHEN 'DR|TAN|500|CSUS|0000100020' THEN '0000410060'
            WHEN 'DR|TAN|500|L2|0000100020' THEN '0000410060'
            WHEN 'DR|G2N|500|G2|0000100055' THEN '0000640241'
            WHEN 'DR|G2N|502|G2|0000100055' THEN '0000640241'
            WHEN 'DR|G2N|523|G2|0000100020' THEN '0000640770'
            WHEN 'RT|G2N|500|G2|0000100055' THEN '0000640241'
            WHEN 'RT|G2N|502|G2|0000100055' THEN '0000640241'
            WHEN 'WH|G2N|500|G2|0000100055' THEN '0000640241'
            WHEN 'WH|G2N|502|G2|0000100055' THEN '0000640241'
            WHEN 'WH|G2N|500|G2|0000100065' THEN '0000640242'
            WHEN 'DR|ZNC|500|CSUS|0000100055' THEN '0000640241'
            WHEN 'DR|ZNC|502|CSUS|0000100055' THEN '0000640241'
            WHEN 'DR|ZNC|500|CSUS|0000100002' THEN '0000640550'
            WHEN 'DR|ZNC|500|CSUS|0000100005' THEN '0000640550'
            WHEN 'DR|ZNC|500|CSUS|0000100020' THEN '0000640550'
            WHEN 'DR|ZNC|502|CSUS|0000100020' THEN '0000640740'
            WHEN 'RT|ZNC|500|CSUS|0000100055' THEN '0000640241'
            WHEN 'RT|ZNC|502|CSUS|0000100055' THEN '0000640241'
            WHEN 'WH|ZNC|500|CSUS|0000100055' THEN '0000640241'
            WHEN 'WH|ZNC|502|CSUS|0000100055' THEN '0000640241'
            WHEN 'WH|KLN|500|KL|000020960' THEN '0000640242'
            WHEN 'WH|ZNC|500|CSUS|000020960' THEN '0000640242'
            WHEN 'WH|ZNC|500|CSUS|0000100065' THEN '0000640242'
            WHEN 'WH|ZNC|502|CSUS|0000100065' THEN '0000640242'
            WHEN 'WH|ZNC|500|CSUS|0000100020' THEN '0000640550'
            WHEN 'WH|ZNC|502|CSUS|0000100020' THEN '0000640740'
            ELSE NULL
        END AS GL_ACCOUNT_OVERRIDE_PARTIAL_2
      , CASE CONCAT_WS('|', VTWEG, PSTYV, AUGRU, AUART )
            WHEN 'WH|G2N|549|G2' THEN '0000630140'
            WHEN 'WH|G2N|502|G2' THEN '0000640243'
            WHEN 'RT|KLN|502|KL' THEN '0000640243'
            WHEN 'RT|ZNC|502|CSUS' THEN '0000640243'
            WHEN 'RT|KLN|500|KL' THEN '0000640244'
            WHEN 'RT|ZNC|500|CSUS' THEN '0000640244'
            WHEN 'WH|G2N|544|G2' THEN '0000640240'
            WHEN 'WH|TAS|544|ZTAV' THEN '0000640240'
            WHEN 'WH|KLN|502|KL' THEN '0000640243'
            WHEN 'WH|ZNC|502|CSUS' THEN '0000640243'
            WHEN 'WH|KLN|500|KL' THEN '0000640244'
            WHEN 'WH|ZNC|500|CSUS' THEN '0000640244'
            WHEN 'WH|G2N|542|G2' THEN '0000641110'
            WHEN 'WH|G2N|543|G2' THEN '0000641110'
            WHEN 'WH|TAS|542|ZTAV' THEN '0000641110'
            WHEN 'WH|TAS|543|ZTAV' THEN '0000641110'
            ELSE NULL
        END AS GL_ACCOUNT_OVERRIDE_PARTIAL_3
    FROM SRC_LSAT_CS
)

---- RENAME LAYER ----

, RENAME_LNK_CS as (
    SELECT
        LNK_COPA_SALES_HK
      , COPA_HK
      , REC_SRC
    FROM LOGIC_LNK_CS
)

, RENAME_HUB_CS as (
    SELECT
        COPA_HK                                                             as                                          HUB_COPA_HK
      , BKCC
    FROM LOGIC_HUB_CS
)

, RENAME_LSAT_CS as (
    SELECT
        LNK_COPA_SALES_HK                                                   as                               LSAT_LNK_COPA_SALES_HK
      , MANDT
      , PALEDGER
      , VRGAR                                                               as                                          RECORD_TYPE
      , FISCAL_MONTH__YYYYMM
      , PAOBJNR
      , PASUBNR
      , BELNR
      , POSNR
      , ISSUE_DATE__YYYYMMDD
      , BILLING_DATE__YYYYMMDD
      , POSTING_DATE__YYYYMMDD
      , FISCAL_YEAR__YYYY
      , KNDNR                                                                   as                                    CUSTOMER
      , ARTNR                                                                   as                              PRODUCT_NUMBER
      , FKART                                                                   as                                BILLING_TYPE
      , KURSF
      , REC_WAERS
      , KAUFN
      , KDPOS
      , RKAUFNR
      , SKOST                                                                   as                          SENDER_COST_CENTER
      , PRZNR
      , BUKRS                                                                   as                                COMPANY_CODE
      , KOKRS                                                                   as                            CONTROLLING_AREA
      , WERKS
      , GSBER
      , VKORG                                                                   as                           SALES_ORGANIZATION
      , VTWEG                                                                   as                         DISTRIBUTION_CHANNEL
      , SPART
      , KSTAR                                                                   as                                 COST_ELEMENT
      , PSPNR
      , KSTRG
      , RBELN
      , RPOSN
      , STO_BELNR
      , STO_POSNR
      , PRCTR
      , PPRCTR
      , AUGRU                                                                    as                                 ORDER_REASON
      , PSTYV                                                                    as                                 ITEM_CATEGORY
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
      , WWSTP                                                                       as                                    DEAL_TYPE
      , AUART                                                                       as                          SALES_DOCUMENT_TYPE
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
      , GL_KEY
      , GL_KEY_PARTIAL_2
      , GL_KEY_PARTIAL_3
      , GL_ACCOUNT_OVERRIDE_FULL
      , GL_ACCOUNT_OVERRIDE_PARTIAL_2
      , GL_ACCOUNT_OVERRIDE_PARTIAL_3
    FROM LOGIC_LSAT_CS
)

---- FILTER LAYER ----

, FILTER_LNK_CS as (
    SELECT *
    FROM RENAME_LNK_CS
    WHERE UPPER(REC_SRC) <> 'USAZET.SNOWFLAKE.FBIN.DERIVED'                            /* This filter is to exclude the ghost records */
)

, FILTER_HUB_CS as (
    SELECT *
    FROM RENAME_HUB_CS
)

, FILTER_LSAT_CS as (
    SELECT *
    FROM RENAME_LSAT_CS
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_LNK_CS
    LEFT JOIN FILTER_HUB_CS
        ON FILTER_LNK_CS.COPA_HK = FILTER_HUB_CS.HUB_COPA_HK
    LEFT JOIN FILTER_LSAT_CS
        ON FILTER_LNK_CS.LNK_COPA_SALES_HK = FILTER_LSAT_CS.LSAT_LNK_COPA_SALES_HK
)

---- FINAL LAYER ----
SELECT
          'PB_COPA'                                                             as                                            PB_REC_SRC
        , CURRENT_DATE                                                          as                                          SNAPSHOTDATE
        , CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP)                            as                                           PB_LOAD_DTS
        , LNK_COPA_SALES_HK
        , MANDT
        , PALEDGER
        , RECORD_TYPE
        , FISCAL_MONTH__YYYYMM
        , PAOBJNR
        , PASUBNR
        , BELNR
        , POSNR
        , ISSUE_DATE__YYYYMMDD
        , BILLING_DATE__YYYYMMDD
        , POSTING_DATE__YYYYMMDD
        , FISCAL_YEAR__YYYY
        , CUSTOMER                                                                    
        , PRODUCT_NUMBER
        , BILLING_TYPE
        , KURSF
        , REC_WAERS
        , KAUFN
        , KDPOS
        , RKAUFNR
        , SENDER_COST_CENTER
        , PRZNR
        , COMPANY_CODE
        , CONTROLLING_AREA
        , WERKS
        , GSBER
        , SALES_ORGANIZATION
        , DISTRIBUTION_CHANNEL
        , SPART
        , COST_ELEMENT
        , PSPNR
        , KSTRG
        , RBELN
        , RPOSN
        , STO_BELNR
        , STO_POSNR
        , PRCTR
        , PPRCTR
        , ORDER_REASON
        , ITEM_CATEGORY
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
        , DEAL_TYPE
        , SALES_DOCUMENT_TYPE
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
        , GL_KEY
        , GL_KEY_PARTIAL_2
        , GL_KEY_PARTIAL_3
        , GL_ACCOUNT_OVERRIDE_FULL
        , GL_ACCOUNT_OVERRIDE_PARTIAL_2
        , GL_ACCOUNT_OVERRIDE_PARTIAL_3
        , REC_SRC
        , BKCC 
FROM JOIN_RESULT
{% if is_incremental() %}
    WHERE LNK_COPA_SALES_HK NOT IN (
        SELECT LNK_COPA_SALES_HK 
        FROM {{ this }}
    )
{% endif %}