---- SRC LAYER ----
WITH
SRC_CE1NEW4        as ( SELECT * FROM {{ ref('v_psa_stg_copa_sales__winn_sap') }} as SRC 
                        {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %} )

/*
SRC_CE1NEW4        as ( SELECT * FROM STAGING.v_psa_stg_copa_sales__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_CE1NEW4 as (
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
      , WADAT
      , WADAT_DT
      , FADAT
      , FADAT_DT
      , BUDAT
      , BUDAT_DT
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
      , HASHDIFF
      , hash(
            * exclude(
                GLREQUEST,
                GLCHANGETIME,
                PSA_LOAD_DTS,
                PSA_RECORD_SOURCE,
                PSA_DELETE_IND,
                LOAD_DTS,
                REC_SRC,
                HASHDIFF,
                WADAT_DT,
                BUDAT_DT,
                FADAT_DT,
                ITEM_BK,
                PLANT_BK,
                CUSTOMER_BK,
                SALES_ORGANIZATION_BK,
                DISTRIBUTION_CHANNEL_BK,
                DIVISION_BK,
                KEY_ACCOUNT_BK,
                KEY_ACCOUNT_GROUP_BK,
                CURRENCY_TYPE_BK,
                COPA_HEADER_BK,
                ORDER_HEADER_BK,
                ORDER_LINE_BK,
                COST_ELEMENT_BK,
                COST_CENTER_BK,
                CONTROLLING_AREA_BK,
                PROFIT_CENTER_BK,
                LNK_COPA_SALES_HK
            )
        ) as REC_HASH -- this field is to support the qualify clause computation for performance improvement 
    FROM SRC_CE1NEW4
)
---- RENAME LAYER ----

, RENAME_CE1NEW4 as (
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
      , WADAT
      , WADAT_DT
      , FADAT
      , FADAT_DT
      , BUDAT
      , BUDAT_DT
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
      , HASHDIFF
      , REC_HASH
    FROM LOGIC_CE1NEW4
)
---- FILTER LAYER ----

, FILTER_CE1NEW4 as (
    SELECT *
    FROM RENAME_CE1NEW4
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_CE1NEW4
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
        , WADAT
        , WADAT_DT
        , FADAT
        , FADAT_DT
        , BUDAT
        , BUDAT_DT
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
        , HASHDIFF
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.LNK_COPA_SALES_HK = JOIN_RESULT.LNK_COPA_SALES_HK
	AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF	
)
{% endif %}
{% if not is_incremental() %}

/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per HK and hashdiff. */
qualify 1 = row_number() over (partition by REC_HASH order by PSA_LOAD_DTS)

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
NULL AS WADAT,
NULL AS WADAT_DT,
NULL AS FADAT,
NULL AS FADAT_DT,
NULL AS BUDAT,
NULL AS BUDAT_DT,
NULL AS GLREQUEST,
NULL AS HZDAT,
NULL AS USNAM,
NULL AS GJAHR,
NULL AS PERDE,
NULL AS ALTPERIO,
NULL AS PAPAOBJNR,
NULL AS PAPASUBNR,
NULL AS KNDNR,
NULL AS ARTNR,
NULL AS FKART,
NULL AS FRWAE,
NULL AS KURSF,
NULL AS KURSBK,
NULL AS KURSKZ,
NULL AS REC_WAERS,
NULL AS KAUFN,
NULL AS KDPOS,
NULL AS RKAUFNR,
NULL AS SKOST,
NULL AS PRZNR,
NULL AS BUKRS,
NULL AS KOKRS,
NULL AS WERKS,
NULL AS GSBER,
NULL AS VKORG,
NULL AS VTWEG,
NULL AS SPART,
NULL AS HRKFT,
NULL AS PLIKZ,
NULL AS KSTAR,
NULL AS PSPNR,
NULL AS KSTRG,
NULL AS RBELN,
NULL AS RPOSN,
NULL AS STO_BELNR,
NULL AS STO_POSNR,
NULL AS PRCTR,
NULL AS PPRCTR,
NULL AS RKESTATU,
NULL AS TIMESTMP,
NULL AS COPA_AWTYP,
NULL AS COPA_AWORG,
NULL AS COPA_BWZPT,
NULL AS COPA_AWSYS,
NULL AS AUGRU,
NULL AS PSTYV,
NULL AS WWRSN,
NULL AS WWKNU,
NULL AS ZZTYP,
NULL AS ZZSEG,
NULL AS ZZLIN,
NULL AS ZZDTP,
NULL AS ZZFIN,
NULL AS ZZHAN,
NULL AS ZZPMI,
NULL AS ZZROM,
NULL AS ZZMAJ,
NULL AS ZZMIN,
NULL AS ZZMG1,
NULL AS KVGR1,
NULL AS KVGR2,
NULL AS KVGR3,
NULL AS WWSTP,
NULL AS AUART,
NULL AS VKBUR,
NULL AS BZIRK,
NULL AS VKGRP,
NULL AS WWPCA,
NULL AS WWPCS,
NULL AS WWPFA,
NULL AS WWPFE,
NULL AS WWPFF,
NULL AS WWPFS,
NULL AS WWPII,
NULL AS WWPIP,
NULL AS WWPPY,
NULL AS WWPSH,
NULL AS WWPSL,
NULL AS WWPSR,
NULL AS WWPSS,
NULL AS WWPBT,
NULL AS WWCDV,
NULL AS WWDSP,
NULL AS WWSTC,
NULL AS WWSTS,
NULL AS WWSTZ,
NULL AS WWDTC,
NULL AS WWDTS,
NULL AS WWDTZ,
NULL AS QMNUM,
NULL AS WWDEF,
NULL AS WWCMP,
NULL AS ZZORC,
NULL AS WWACC,
NULL AS VVQTY,
NULL AS VVTRC,
NULL AS VVCRL,
NULL AS VVSBD,
NULL AS VVSBK,
NULL AS VVACL,
NULL AS VVIND,
NULL AS VVSIP,
NULL AS VVSPD,
NULL AS VVOIP,
NULL AS VVDIP,
NULL AS VVDCI,
NULL AS VVMOD,
NULL AS VVOVR,
NULL AS VVGRS,
NULL AS VVGIS,
NULL AS VVRST,
NULL AS VVHDL,
NULL AS VVFRA,
NULL AS VVFRC,
NULL AS VVFRM,
NULL AS VVACD,
NULL AS VVART,
NULL AS VVAAL,
NULL AS VVHFR,
NULL AS VVANS,
NULL AS VVCST,
NULL AS VVGMG,
NULL AS VVICP,
NULL AS VVAGM,
NULL AS VVVBW,
NULL AS VVVMW,
NULL AS VVERW,
NULL AS VVVBR,
NULL AS VVERR,
NULL AS VVCRR,
NULL AS VVFRO,
NULL AS VVCMW,
NULL AS VVCMR,
NULL AS VVCMG,
NULL AS VVMKT,
NULL AS VVADV,
NULL AS VVSEV,
NULL AS VVSEF,
NULL AS VVRND,
NULL AS VVDFR,
NULL AS VVDEF,
NULL AS VVDEV,
NULL AS VVCBA,
NULL AS VVADM,
NULL AS VVOCC,
NULL AS VVAFC,
NULL AS VVMKV,
NULL AS VVTHR,
NULL AS VVCES,
NULL AS VVBON,
NULL AS VVRET,
NULL AS VVMIN,
NULL AS VVACQ,
NULL AS VVCJA,
NULL AS VVDSP,
NULL AS VVEDI,
NULL AS VVHCD,
NULL AS VVLTS,
NULL AS VVOPN,
NULL AS VVPRO,
NULL AS VVSHW,
NULL AS VVSPC,
NULL AS VVSPS,
NULL AS VVTSD,
NULL AS VVVPO,
NULL AS VVBLD,
NULL AS VVCOP,
NULL AS VVGRR,
NULL AS VVMKF,
NULL AS VVMWP,
NULL AS VVNCD,
NULL AS VVPRD,
NULL AS VVPRV,
NULL AS VVSOD,
NULL AS VVSSA,
NULL AS VVSTS,
NULL AS VVSUP,
NULL AS VVTRK,
NULL AS VVVIP,
NULL AS VVVLR,
NULL AS VVWHS,
NULL AS VVRFC,
NULL AS VVDSA,
NULL AS VVOTC,
NULL AS VVPRT,
NULL AS VVRCD,
NULL AS VVSBN,
NULL AS VVCDR,
NULL AS VVCJP,
NULL AS VVPRP,
NULL AS VVVPP,
NULL AS VVFPP,
NULL AS VVNET,
NULL AS VVGBP,
NULL AS VVGRI,
NULL AS VVNSA,
NULL AS VVCMB,
NULL AS VVSDP,
NULL AS VVQTY_ME,
NULL AS GLDELFLAG,
NULL AS GLCHANGETIME,
NULL AS GLSOURCESYSTEM,
'1900-01-01'::TIMESTAMP AS PSA_LOAD_DTS,
NULL AS PSA_RECORD_SOURCE,
'N' AS PSA_DELETE_IND,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC,
''::BINARY AS HASHDIFF
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
