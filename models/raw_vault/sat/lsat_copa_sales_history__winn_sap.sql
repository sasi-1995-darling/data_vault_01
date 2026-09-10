---- SRC LAYER ----
WITH
SRC_AZCOPA         as ( {% if not is_incremental() %} SELECT * FROM {{ ref('v_psa_stg_copa_sales_history__winn_sap') }} as SRC  {% endif %}
                        {% if is_incremental() %} SELECT * FROM {{ this }} limit 0 {% endif %} ) 
                        /*To improve efficiency and performance; scan and load historical SAP BW AZCOPA table only on initial run */

/*
SRC_AZCOPA         as ( SELECT * FROM STAGING.v_psa_stg_copa_sales_history__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_AZCOPA as (
    SELECT
        LNK_COPA_SALES_HK
      , MANDT
      , PALEDGER
      , VRGAR
      , VERSI
      , PERIO
      , PAOBJNR
      , PASUBNR
      , BELNR
      , POSNR
      , PERIV
      , BUDAT
      , BUDAT_DT
      , REC_WAERS
      , VVQTY_ME
      , GJAHR
      , GSBER
      , KNDNR
      , KOKRS
      , BUKRS
      , SPART
      , VTWEG
      , ARTNR
      , WERKS
      , PRCTR
      , VKORG
      , WRTTP
      , CURTYPE
      , VALUTYP
      , PSPNR
      , ZZDTP
      , ZZFIN
      , ZZHAN
      , ZZLIN
      , ZZMAJ
      , ZZMG1
      , ZZMIN
      , ZPTYPE
      , ZZPMI
      , ZCMRCAT
      , ZZROM
      , ZZSEG
      , ZZTYP
      , ZWORKDAY
      , WWPBT
      , FADAT
      , FADAT_DT
      , RPOSN
      , FKART
      , KAUFN
      , AUART
      , WWPFA
      , WADAT
      , WADAT_DT
      , KVGR1
      , QMNUM
      , AUGRU
      , WWPPY
      , WWKNU
      , WWPSR
      , BZIRK
      , VKGRP
      , VKBUR
      , WWPSH
      , WWPSL
      , TCTVAPRCTP
      , STO_BELNR
      , STO_POSNR
      , PRZNR
      , KTOPL
      , RKAUFNR
      , KSTAR
      , KSTRG
      , WWSTP
      , PPRCTR
      , RBELN
      , SKOST
      , KVGR3
      , KVGR2
      , WWCDV
      , WWCMP
      , WWDEF
      , WWDSP
      , WWDTC
      , WWDTS
      , WWDTZ
      , WWPCA
      , WWPCS
      , WWPFE
      , WWPFF
      , WWPFS
      , WWPII
      , WWPIP
      , WWPSS
      , WWRSN
      , WWSTC
      , WWSTS
      , WWSTZ
      , ZEXTRACTDATE
      , PSTYV
      , KSPOS
      , VVAAL
      , VVACD
      , VVACL
      , VVACQ
      , VVADM
      , VVADV
      , VVAFC
      , VVAGM
      , VVANS
      , VVART
      , VVBLD
      , VVBON
      , VVCBA
      , VVCDR
      , VVCES
      , VVCJA
      , VVCJP
      , VVCMB
      , VVCMG
      , VVCMR
      , VVCMW
      , VVCOP
      , VVCRL
      , VVCRR
      , VVCST
      , VVDCI
      , VVDEF
      , VVDEV
      , VVDFR
      , VVDIP
      , VVDSA
      , VVDSP
      , VVEDI
      , VVERR
      , VVERW
      , VVFPP
      , VVFRA
      , VVFRC
      , VVFRM
      , VVFRO
      , VVGBP
      , VVGIS
      , VVGMG
      , VVGRI
      , VVGRR
      , VVGRS
      , VVHCD
      , VVHDL
      , VVHFR
      , VVICP
      , VVIND
      , VVLTS
      , VVMIN
      , VVMKF
      , VVMKT
      , VVMKV
      , VVMOD
      , VVMWP
      , VVNCD
      , VVNET
      , VVNSA
      , VVOCC
      , VVOIP
      , VVOPN
      , VVOTC
      , VVOVR
      , VVPRD
      , VVPRO
      , VVPRP
      , VVPRV
      , VVRCD
      , VVRET
      , VVRFC
      , VVRND
      , VVRST
      , VVSBD
      , VVSBK
      , VVSBN
      , VVSDP
      , VVSEF
      , VVSEV
      , VVSHW
      , VVSIP
      , VVSOD
      , VVSPC
      , VVSPD
      , VVSPS
      , VVSSA
      , VVSTS
      , VVSUP
      , VVTHR
      , VVTRC
      , VVTRK
      , VVTSD
      , VVVBR
      , VVVBW
      , VVVIP
      , VVVLR
      , VVVMW
      , VVVPO
      , VVVPP
      , VVWHS
      , VVQTY
      , KURSF
      , ZKURSF
      , COUNTER1
      , COUNTER2
      , VVPRT
      , CUST_SALES
      , ZZORC
      , FENUM
      , KDPOS
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , HASHDIFF
    FROM SRC_AZCOPA
)
---- RENAME LAYER ----

, RENAME_AZCOPA as (
    SELECT
        LNK_COPA_SALES_HK
      , MANDT
      , PALEDGER
      , VRGAR
      , VERSI
      , PERIO
      , PAOBJNR
      , PASUBNR
      , BELNR
      , POSNR
      , PERIV
      , BUDAT
      , BUDAT_DT
      , REC_WAERS
      , VVQTY_ME
      , GJAHR
      , GSBER
      , KNDNR
      , KOKRS
      , BUKRS
      , SPART
      , VTWEG
      , ARTNR
      , WERKS
      , PRCTR
      , VKORG
      , WRTTP
      , CURTYPE
      , VALUTYP
      , PSPNR
      , ZZDTP
      , ZZFIN
      , ZZHAN
      , ZZLIN
      , ZZMAJ
      , ZZMG1
      , ZZMIN
      , ZPTYPE
      , ZZPMI
      , ZCMRCAT
      , ZZROM
      , ZZSEG
      , ZZTYP
      , ZWORKDAY
      , WWPBT
      , FADAT
      , FADAT_DT
      , RPOSN
      , FKART
      , KAUFN
      , AUART
      , WWPFA
      , WADAT
      , WADAT_DT
      , KVGR1
      , QMNUM
      , AUGRU
      , WWPPY
      , WWKNU
      , WWPSR
      , BZIRK
      , VKGRP
      , VKBUR
      , WWPSH
      , WWPSL
      , TCTVAPRCTP
      , STO_BELNR
      , STO_POSNR
      , PRZNR
      , KTOPL
      , RKAUFNR
      , KSTAR
      , KSTRG
      , WWSTP
      , PPRCTR
      , RBELN
      , SKOST
      , KVGR3
      , KVGR2
      , WWCDV
      , WWCMP
      , WWDEF
      , WWDSP
      , WWDTC
      , WWDTS
      , WWDTZ
      , WWPCA
      , WWPCS
      , WWPFE
      , WWPFF
      , WWPFS
      , WWPII
      , WWPIP
      , WWPSS
      , WWRSN
      , WWSTC
      , WWSTS
      , WWSTZ
      , ZEXTRACTDATE
      , PSTYV
      , KSPOS
      , VVAAL
      , VVACD
      , VVACL
      , VVACQ
      , VVADM
      , VVADV
      , VVAFC
      , VVAGM
      , VVANS
      , VVART
      , VVBLD
      , VVBON
      , VVCBA
      , VVCDR
      , VVCES
      , VVCJA
      , VVCJP
      , VVCMB
      , VVCMG
      , VVCMR
      , VVCMW
      , VVCOP
      , VVCRL
      , VVCRR
      , VVCST
      , VVDCI
      , VVDEF
      , VVDEV
      , VVDFR
      , VVDIP
      , VVDSA
      , VVDSP
      , VVEDI
      , VVERR
      , VVERW
      , VVFPP
      , VVFRA
      , VVFRC
      , VVFRM
      , VVFRO
      , VVGBP
      , VVGIS
      , VVGMG
      , VVGRI
      , VVGRR
      , VVGRS
      , VVHCD
      , VVHDL
      , VVHFR
      , VVICP
      , VVIND
      , VVLTS
      , VVMIN
      , VVMKF
      , VVMKT
      , VVMKV
      , VVMOD
      , VVMWP
      , VVNCD
      , VVNET
      , VVNSA
      , VVOCC
      , VVOIP
      , VVOPN
      , VVOTC
      , VVOVR
      , VVPRD
      , VVPRO
      , VVPRP
      , VVPRV
      , VVRCD
      , VVRET
      , VVRFC
      , VVRND
      , VVRST
      , VVSBD
      , VVSBK
      , VVSBN
      , VVSDP
      , VVSEF
      , VVSEV
      , VVSHW
      , VVSIP
      , VVSOD
      , VVSPC
      , VVSPD
      , VVSPS
      , VVSSA
      , VVSTS
      , VVSUP
      , VVTHR
      , VVTRC
      , VVTRK
      , VVTSD
      , VVVBR
      , VVVBW
      , VVVIP
      , VVVLR
      , VVVMW
      , VVVPO
      , VVVPP
      , VVWHS
      , VVQTY
      , KURSF
      , ZKURSF
      , COUNTER1
      , COUNTER2
      , VVPRT
      , CUST_SALES
      , ZZORC
      , FENUM
      , KDPOS
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , HASHDIFF
    FROM LOGIC_AZCOPA
)
---- FILTER LAYER ----

, FILTER_AZCOPA as (
    SELECT *
    FROM RENAME_AZCOPA
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_AZCOPA
)

---- FINAL LAYER ----
SELECT
          LNK_COPA_SALES_HK
        , MANDT
        , PALEDGER
        , VRGAR
        , VERSI
        , PERIO
        , PAOBJNR
        , PASUBNR
        , BELNR
        , POSNR
        , PERIV
        , BUDAT
        , BUDAT_DT
        , REC_WAERS
        , VVQTY_ME
        , GJAHR
        , GSBER
        , KNDNR
        , KOKRS
        , BUKRS
        , SPART
        , VTWEG
        , ARTNR
        , WERKS
        , PRCTR
        , VKORG
        , WRTTP
        , CURTYPE
        , VALUTYP
        , PSPNR
        , ZZDTP
        , ZZFIN
        , ZZHAN
        , ZZLIN
        , ZZMAJ
        , ZZMG1
        , ZZMIN
        , ZPTYPE
        , ZZPMI
        , ZCMRCAT
        , ZZROM
        , ZZSEG
        , ZZTYP
        , ZWORKDAY
        , WWPBT
        , FADAT
        , FADAT_DT
        , RPOSN
        , FKART
        , KAUFN
        , AUART
        , WWPFA
        , WADAT
        , WADAT_DT
        , KVGR1
        , QMNUM
        , AUGRU
        , WWPPY
        , WWKNU
        , WWPSR
        , BZIRK
        , VKGRP
        , VKBUR
        , WWPSH
        , WWPSL
        , TCTVAPRCTP
        , STO_BELNR
        , STO_POSNR
        , PRZNR
        , KTOPL
        , RKAUFNR
        , KSTAR
        , KSTRG
        , WWSTP
        , PPRCTR
        , RBELN
        , SKOST
        , KVGR3
        , KVGR2
        , WWCDV
        , WWCMP
        , WWDEF
        , WWDSP
        , WWDTC
        , WWDTS
        , WWDTZ
        , WWPCA
        , WWPCS
        , WWPFE
        , WWPFF
        , WWPFS
        , WWPII
        , WWPIP
        , WWPSS
        , WWRSN
        , WWSTC
        , WWSTS
        , WWSTZ
        , ZEXTRACTDATE
        , PSTYV
        , KSPOS
        , VVAAL
        , VVACD
        , VVACL
        , VVACQ
        , VVADM
        , VVADV
        , VVAFC
        , VVAGM
        , VVANS
        , VVART
        , VVBLD
        , VVBON
        , VVCBA
        , VVCDR
        , VVCES
        , VVCJA
        , VVCJP
        , VVCMB
        , VVCMG
        , VVCMR
        , VVCMW
        , VVCOP
        , VVCRL
        , VVCRR
        , VVCST
        , VVDCI
        , VVDEF
        , VVDEV
        , VVDFR
        , VVDIP
        , VVDSA
        , VVDSP
        , VVEDI
        , VVERR
        , VVERW
        , VVFPP
        , VVFRA
        , VVFRC
        , VVFRM
        , VVFRO
        , VVGBP
        , VVGIS
        , VVGMG
        , VVGRI
        , VVGRR
        , VVGRS
        , VVHCD
        , VVHDL
        , VVHFR
        , VVICP
        , VVIND
        , VVLTS
        , VVMIN
        , VVMKF
        , VVMKT
        , VVMKV
        , VVMOD
        , VVMWP
        , VVNCD
        , VVNET
        , VVNSA
        , VVOCC
        , VVOIP
        , VVOPN
        , VVOTC
        , VVOVR
        , VVPRD
        , VVPRO
        , VVPRP
        , VVPRV
        , VVRCD
        , VVRET
        , VVRFC
        , VVRND
        , VVRST
        , VVSBD
        , VVSBK
        , VVSBN
        , VVSDP
        , VVSEF
        , VVSEV
        , VVSHW
        , VVSIP
        , VVSOD
        , VVSPC
        , VVSPD
        , VVSPS
        , VVSSA
        , VVSTS
        , VVSUP
        , VVTHR
        , VVTRC
        , VVTRK
        , VVTSD
        , VVVBR
        , VVVBW
        , VVVIP
        , VVVLR
        , VVVMW
        , VVVPO
        , VVVPP
        , VVWHS
        , VVQTY
        , KURSF
        , ZKURSF
        , COUNTER1
        , COUNTER2
        , VVPRT
        , CUST_SALES
        , ZZORC
        , FENUM
        , KDPOS
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , REC_SRC
        , HASHDIFF
FROM JOIN_RESULT

{% if not is_incremental() %}
union all
SELECT 
MD5_BINARY(GR.VALUE) AS LNK_COPA_SALES_HK,
GR.VALUE::text AS MANDT,
GR.VALUE::text AS PALEDGER,
GR.VALUE::text AS VRGAR,
GR.VALUE::text AS VERSI,
GR.VALUE::text AS PERIO,
GR.VALUE::text AS PAOBJNR,
GR.VALUE::text AS PASUBNR,
GR.VALUE::text AS BELNR,
GR.VALUE::text AS POSNR,
NULL AS PERIV,
NULL AS BUDAT,
NULL AS BUDAT_DT,
NULL AS REC_WAERS,
NULL AS VVQTY_ME,
NULL AS GJAHR,
NULL AS GSBER,
NULL AS KNDNR,
NULL AS KOKRS,
NULL AS BUKRS,
NULL AS SPART,
NULL AS VTWEG,
NULL AS ARTNR,
NULL AS WERKS,
NULL AS PRCTR,
NULL AS VKORG,
NULL AS WRTTP,
NULL AS CURTYPE,
NULL AS VALUTYP,
NULL AS PSPNR,
NULL AS ZZDTP,
NULL AS ZZFIN,
NULL AS ZZHAN,
NULL AS ZZLIN,
NULL AS ZZMAJ,
NULL AS ZZMG1,
NULL AS ZZMIN,
NULL AS ZPTYPE,
NULL AS ZZPMI,
NULL AS ZCMRCAT,
NULL AS ZZROM,
NULL AS ZZSEG,
NULL AS ZZTYP,
NULL AS ZWORKDAY,
NULL AS WWPBT,
NULL AS FADAT,
NULL AS FADAT_DT,
NULL AS RPOSN,
NULL AS FKART,
NULL AS KAUFN,
NULL AS AUART,
NULL AS WWPFA,
NULL AS WADAT,
NULL AS WADAT_DT,
NULL AS KVGR1,
NULL AS QMNUM,
NULL AS AUGRU,
NULL AS WWPPY,
NULL AS WWKNU,
NULL AS WWPSR,
NULL AS BZIRK,
NULL AS VKGRP,
NULL AS VKBUR,
NULL AS WWPSH,
NULL AS WWPSL,
NULL AS TCTVAPRCTP,
NULL AS STO_BELNR,
NULL AS STO_POSNR,
NULL AS PRZNR,
NULL AS KTOPL,
NULL AS RKAUFNR,
NULL AS KSTAR,
NULL AS KSTRG,
NULL AS WWSTP,
NULL AS PPRCTR,
NULL AS RBELN,
NULL AS SKOST,
NULL AS KVGR3,
NULL AS KVGR2,
NULL AS WWCDV,
NULL AS WWCMP,
NULL AS WWDEF,
NULL AS WWDSP,
NULL AS WWDTC,
NULL AS WWDTS,
NULL AS WWDTZ,
NULL AS WWPCA,
NULL AS WWPCS,
NULL AS WWPFE,
NULL AS WWPFF,
NULL AS WWPFS,
NULL AS WWPII,
NULL AS WWPIP,
NULL AS WWPSS,
NULL AS WWRSN,
NULL AS WWSTC,
NULL AS WWSTS,
NULL AS WWSTZ,
NULL AS ZEXTRACTDATE,
NULL AS PSTYV,
NULL AS KSPOS,
NULL AS VVAAL,
NULL AS VVACD,
NULL AS VVACL,
NULL AS VVACQ,
NULL AS VVADM,
NULL AS VVADV,
NULL AS VVAFC,
NULL AS VVAGM,
NULL AS VVANS,
NULL AS VVART,
NULL AS VVBLD,
NULL AS VVBON,
NULL AS VVCBA,
NULL AS VVCDR,
NULL AS VVCES,
NULL AS VVCJA,
NULL AS VVCJP,
NULL AS VVCMB,
NULL AS VVCMG,
NULL AS VVCMR,
NULL AS VVCMW,
NULL AS VVCOP,
NULL AS VVCRL,
NULL AS VVCRR,
NULL AS VVCST,
NULL AS VVDCI,
NULL AS VVDEF,
NULL AS VVDEV,
NULL AS VVDFR,
NULL AS VVDIP,
NULL AS VVDSA,
NULL AS VVDSP,
NULL AS VVEDI,
NULL AS VVERR,
NULL AS VVERW,
NULL AS VVFPP,
NULL AS VVFRA,
NULL AS VVFRC,
NULL AS VVFRM,
NULL AS VVFRO,
NULL AS VVGBP,
NULL AS VVGIS,
NULL AS VVGMG,
NULL AS VVGRI,
NULL AS VVGRR,
NULL AS VVGRS,
NULL AS VVHCD,
NULL AS VVHDL,
NULL AS VVHFR,
NULL AS VVICP,
NULL AS VVIND,
NULL AS VVLTS,
NULL AS VVMIN,
NULL AS VVMKF,
NULL AS VVMKT,
NULL AS VVMKV,
NULL AS VVMOD,
NULL AS VVMWP,
NULL AS VVNCD,
NULL AS VVNET,
NULL AS VVNSA,
NULL AS VVOCC,
NULL AS VVOIP,
NULL AS VVOPN,
NULL AS VVOTC,
NULL AS VVOVR,
NULL AS VVPRD,
NULL AS VVPRO,
NULL AS VVPRP,
NULL AS VVPRV,
NULL AS VVRCD,
NULL AS VVRET,
NULL AS VVRFC,
NULL AS VVRND,
NULL AS VVRST,
NULL AS VVSBD,
NULL AS VVSBK,
NULL AS VVSBN,
NULL AS VVSDP,
NULL AS VVSEF,
NULL AS VVSEV,
NULL AS VVSHW,
NULL AS VVSIP,
NULL AS VVSOD,
NULL AS VVSPC,
NULL AS VVSPD,
NULL AS VVSPS,
NULL AS VVSSA,
NULL AS VVSTS,
NULL AS VVSUP,
NULL AS VVTHR,
NULL AS VVTRC,
NULL AS VVTRK,
NULL AS VVTSD,
NULL AS VVVBR,
NULL AS VVVBW,
NULL AS VVVIP,
NULL AS VVVLR,
NULL AS VVVMW,
NULL AS VVVPO,
NULL AS VVVPP,
NULL AS VVWHS,
NULL AS VVQTY,
NULL AS KURSF,
NULL AS ZKURSF,
NULL AS COUNTER1,
NULL AS COUNTER2,
NULL AS VVPRT,
NULL AS CUST_SALES,
NULL AS ZZORC,
NULL AS FENUM,
NULL AS KDPOS,
'1900-01-01'::TIMESTAMP AS PSA_LOAD_DTS,
NULL AS PSA_RECORD_SOURCE,
'N' AS PSA_DELETE_IND,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC,
''::BINARY AS HASHDIFF
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
