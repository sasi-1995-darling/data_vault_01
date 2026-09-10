---- SRC LAYER ----
WITH
SRC_pursap         as ( SELECT * FROM {{ ref('v_psa_stg_purchase_requisition__winn_sap') }} as SRC 
                         {% if is_incremental() %}
                              where src.load_dts > (select dateadd('HOUR',-1,max(load_dts)) from {{ this }})
                            {% endif %}   )

/*
SRC_pursap         as ( SELECT * FROM staging.v_psa_stg_purchase_requisition__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_pursap as (
    SELECT
        PURCHASE_REQUISITION_HK
      , BANFN
      , BNFPO
      , MANDT
      , GLREQUEST
      , GLSOURCESYSTEM
      , BSART
      , BSTYP
      , BSAKZ
      , LOEKZ
      , STATU
      , ESTKZ
      , FRGKZ
      , FRGZU
      , FRGST
      , EKGRP
      , ERNAM
      , ERDAT
      , AFNAM
      , TXZ01
      , MATNR
      , EMATN
      , WERKS
      , LGORT
      , BEDNR
      , MATKL
      , RESWK
      , MENGE
      , MEINS
      , BUMNG
      , BADAT
      , LPEIN
      , LFDAT
      , FRGDT
      , WEBAZ
      , PREIS
      , PEINH
      , PSTYP
      , KNTTP
      , KZVBR
      , KFLAG
      , VRTKZ
      , TWRKZ
      , WEPOS
      , WEUNB
      , REPOS
      , LIFNR
      , FLIEF
      , EKORG
      , VRTYP
      , KONNR
      , KTPNR
      , INFNR
      , ZUGBA
      , QUNUM
      , QUPOS
      , DISPO
      , SERNR
      , BVDAT
      , BATOL
      , BVDRK
      , EBELN
      , EBELP
      , BEDAT
      , BSMNG
      , LBLNI
      , BWTAR
      , XOBLR
      , EBAKZ
      , RSNUM
      , SOBKZ
      , ARSNR
      , ARSPS
      , FIXKZ
      , BMEIN
      , REVLV
      , VORAB
      , PACKNO
      , KANBA
      , BPUEB
      , CUOBJ
      , FRGGR
      , FRGRL
      , AKTNR
      , CHARG
      , UMSOK
      , VERID
      , FIPOS
      , FISTL
      , GEBER
      , KZKFG
      , SATNR
      , MNG02
      , DAT01
      , ATTYP
      , ADRNR
      , ADRN2
      , KUNNR
      , EMLIF
      , LBLKZ
      , KZBWS
      , WAERS
      , IDNLF
      , GSFRG
      , MPROF
      , KZFME
      , SPRAS
      , TECHS
      , MFRPN
      , MFRNR
      , EMNFR
      , FORDN
      , FORDP
      , PLIFZ
      , BERID
      , UZEIT
      , FKBER
      , GRANT_NBR
      , MEMORY
      , BANPR
      , RLWRT
      , BLCKD
      , REVNO
      , BLCKT
      , BESWK
      , EPROFILE
      , EPREFDOC
      , EPREFITM
      , GMMNG
      , WRTKZ
      , RESLO
      , KBLNR
      , KBLPOS
      , PRIO_URG
      , PRIO_REQ
      , MEMORYTYPE
      , ANZSN
      , MHDRZ
      , IPRKZ
      , NODISP
      , SRM_CONTRACT_ID
      , SRM_CONTRACT_ITM
      , BUDGET_PD
      , ZZRELNAM
      , ZZATPCAT
      , ZZPROCESSED
      , ZZPLNUM
      , ZZMDV01
      , ZZVERID
      , ZZPROCDATE
      , ZZBSMNG
      , ZZUSED
      , ZZ_O8_REF
      , ZZ_O8_COLOR
      , ZZ_O8_BUFFER
      , STORENETWORKID
      , STORESUPPLIERID
      , FMFGUS_KEY
      , ADVCODE
      , STACODE
      , BANFN_CS
      , BNFPO_CS
      , ITEM_CS
      , BSMNG_SND
      , NO_MARD_DATA
      , SERRU
      , DISUB_SOBKZ
      , DISUB_PSPNR
      , DISUB_KUNNR
      , DISUB_VBELN
      , DISUB_POSNR
      , DISUB_OWNER
      , FSH_VAS_REL
      , FSH_VAS_PRNT_ID
      , FSH_TRANSACTION
      , FSH_ITEM_GROUP
      , FSH_ITEM
      , IUID_RELEVANT
      , SGT_SCAT
      , SGT_RCAT
      , WRF_CHARSTC1
      , WRF_CHARSTC2
      , WRF_CHARSTC3
      , GLDELFLAG
      , GLCHANGETIME
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , LOAD_DTS
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM SRC_pursap
)
---- RENAME LAYER ----

, RENAME_pursap as (
    SELECT
        PURCHASE_REQUISITION_HK
      , BANFN
      , BNFPO
      , MANDT
      , GLREQUEST
      , GLSOURCESYSTEM
      , BSART
      , BSTYP
      , BSAKZ
      , LOEKZ
      , STATU
      , ESTKZ
      , FRGKZ
      , FRGZU
      , FRGST
      , EKGRP
      , ERNAM
      , ERDAT
      , AFNAM
      , TXZ01
      , MATNR
      , EMATN
      , WERKS
      , LGORT
      , BEDNR
      , MATKL
      , RESWK
      , MENGE
      , MEINS
      , BUMNG
      , BADAT
      , LPEIN
      , LFDAT
      , FRGDT
      , WEBAZ
      , PREIS
      , PEINH
      , PSTYP
      , KNTTP
      , KZVBR
      , KFLAG
      , VRTKZ
      , TWRKZ
      , WEPOS
      , WEUNB
      , REPOS
      , LIFNR
      , FLIEF
      , EKORG
      , VRTYP
      , KONNR
      , KTPNR
      , INFNR
      , ZUGBA
      , QUNUM
      , QUPOS
      , DISPO
      , SERNR
      , BVDAT
      , BATOL
      , BVDRK
      , EBELN
      , EBELP
      , BEDAT
      , BSMNG
      , LBLNI
      , BWTAR
      , XOBLR
      , EBAKZ
      , RSNUM
      , SOBKZ
      , ARSNR
      , ARSPS
      , FIXKZ
      , BMEIN
      , REVLV
      , VORAB
      , PACKNO
      , KANBA
      , BPUEB
      , CUOBJ
      , FRGGR
      , FRGRL
      , AKTNR
      , CHARG
      , UMSOK
      , VERID
      , FIPOS
      , FISTL
      , GEBER
      , KZKFG
      , SATNR
      , MNG02
      , DAT01
      , ATTYP
      , ADRNR
      , ADRN2
      , KUNNR
      , EMLIF
      , LBLKZ
      , KZBWS
      , WAERS
      , IDNLF
      , GSFRG
      , MPROF
      , KZFME
      , SPRAS
      , TECHS
      , MFRPN
      , MFRNR
      , EMNFR
      , FORDN
      , FORDP
      , PLIFZ
      , BERID
      , UZEIT
      , FKBER
      , GRANT_NBR
      , MEMORY
      , BANPR
      , RLWRT
      , BLCKD
      , REVNO
      , BLCKT
      , BESWK
      , EPROFILE
      , EPREFDOC
      , EPREFITM
      , GMMNG
      , WRTKZ
      , RESLO
      , KBLNR
      , KBLPOS
      , PRIO_URG
      , PRIO_REQ
      , MEMORYTYPE
      , ANZSN
      , MHDRZ
      , IPRKZ
      , NODISP
      , SRM_CONTRACT_ID
      , SRM_CONTRACT_ITM
      , BUDGET_PD
      , ZZRELNAM
      , ZZATPCAT
      , ZZPROCESSED
      , ZZPLNUM
      , ZZMDV01
      , ZZVERID
      , ZZPROCDATE
      , ZZBSMNG
      , ZZUSED
      , ZZ_O8_REF
      , ZZ_O8_COLOR
      , ZZ_O8_BUFFER
      , STORENETWORKID
      , STORESUPPLIERID
      , FMFGUS_KEY
      , ADVCODE
      , STACODE
      , BANFN_CS
      , BNFPO_CS
      , ITEM_CS
      , BSMNG_SND
      , NO_MARD_DATA
      , SERRU
      , DISUB_SOBKZ
      , DISUB_PSPNR
      , DISUB_KUNNR
      , DISUB_VBELN
      , DISUB_POSNR
      , DISUB_OWNER
      , FSH_VAS_REL
      , FSH_VAS_PRNT_ID
      , FSH_TRANSACTION
      , FSH_ITEM_GROUP
      , FSH_ITEM
      , IUID_RELEVANT
      , SGT_SCAT
      , SGT_RCAT
      , WRF_CHARSTC1
      , WRF_CHARSTC2
      , WRF_CHARSTC3
      , GLDELFLAG
      , GLCHANGETIME
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , LOAD_DTS
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM LOGIC_pursap
)
---- FILTER LAYER ----

, FILTER_pursap as (
    SELECT *
    FROM RENAME_pursap
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_pursap
)

---- FINAL LAYER ----
SELECT
          PURCHASE_REQUISITION_HK
        , BANFN
        , BNFPO
        , MANDT
        , GLREQUEST
        , GLSOURCESYSTEM
        , BSART
        , BSTYP
        , BSAKZ
        , LOEKZ
        , STATU
        , ESTKZ
        , FRGKZ
        , FRGZU
        , FRGST
        , EKGRP
        , ERNAM
        , ERDAT
        , AFNAM
        , TXZ01
        , MATNR
        , EMATN
        , WERKS
        , LGORT
        , BEDNR
        , MATKL
        , RESWK
        , MENGE
        , MEINS
        , BUMNG
        , BADAT
        , LPEIN
        , LFDAT
        , FRGDT
        , WEBAZ
        , PREIS
        , PEINH
        , PSTYP
        , KNTTP
        , KZVBR
        , KFLAG
        , VRTKZ
        , TWRKZ
        , WEPOS
        , WEUNB
        , REPOS
        , LIFNR
        , FLIEF
        , EKORG
        , VRTYP
        , KONNR
        , KTPNR
        , INFNR
        , ZUGBA
        , QUNUM
        , QUPOS
        , DISPO
        , SERNR
        , BVDAT
        , BATOL
        , BVDRK
        , EBELN
        , EBELP
        , BEDAT
        , BSMNG
        , LBLNI
        , BWTAR
        , XOBLR
        , EBAKZ
        , RSNUM
        , SOBKZ
        , ARSNR
        , ARSPS
        , FIXKZ
        , BMEIN
        , REVLV
        , VORAB
        , PACKNO
        , KANBA
        , BPUEB
        , CUOBJ
        , FRGGR
        , FRGRL
        , AKTNR
        , CHARG
        , UMSOK
        , VERID
        , FIPOS
        , FISTL
        , GEBER
        , KZKFG
        , SATNR
        , MNG02
        , DAT01
        , ATTYP
        , ADRNR
        , ADRN2
        , KUNNR
        , EMLIF
        , LBLKZ
        , KZBWS
        , WAERS
        , IDNLF
        , GSFRG
        , MPROF
        , KZFME
        , SPRAS
        , TECHS
        , MFRPN
        , MFRNR
        , EMNFR
        , FORDN
        , FORDP
        , PLIFZ
        , BERID
        , UZEIT
        , FKBER
        , GRANT_NBR
        , MEMORY
        , BANPR
        , RLWRT
        , BLCKD
        , REVNO
        , BLCKT
        , BESWK
        , EPROFILE
        , EPREFDOC
        , EPREFITM
        , GMMNG
        , WRTKZ
        , RESLO
        , KBLNR
        , KBLPOS
        , PRIO_URG
        , PRIO_REQ
        , MEMORYTYPE
        , ANZSN
        , MHDRZ
        , IPRKZ
        , NODISP
        , SRM_CONTRACT_ID
        , SRM_CONTRACT_ITM
        , BUDGET_PD
        , ZZRELNAM
        , ZZATPCAT
        , ZZPROCESSED
        , ZZPLNUM
        , ZZMDV01
        , ZZVERID
        , ZZPROCDATE
        , ZZBSMNG
        , ZZUSED
        , ZZ_O8_REF
        , ZZ_O8_COLOR
        , ZZ_O8_BUFFER
        , STORENETWORKID
        , STORESUPPLIERID
        , FMFGUS_KEY
        , ADVCODE
        , STACODE
        , BANFN_CS
        , BNFPO_CS
        , ITEM_CS
        , BSMNG_SND
        , NO_MARD_DATA
        , SERRU
        , DISUB_SOBKZ
        , DISUB_PSPNR
        , DISUB_KUNNR
        , DISUB_VBELN
        , DISUB_POSNR
        , DISUB_OWNER
        , FSH_VAS_REL
        , FSH_VAS_PRNT_ID
        , FSH_TRANSACTION
        , FSH_ITEM_GROUP
        , FSH_ITEM
        , IUID_RELEVANT
        , SGT_SCAT
        , SGT_RCAT
        , WRF_CHARSTC1
        , WRF_CHARSTC2
        , WRF_CHARSTC3
        , GLDELFLAG
        , GLCHANGETIME
        , PSA_DELETE_IND
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , HASHDIFF
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.PURCHASE_REQUISITION_HK = JOIN_RESULT.PURCHASE_REQUISITION_HK 
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %}
{% if not is_incremental() %}

/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per HK and hashdiff. */
qualify 1 = row_number() over (partition by PURCHASE_REQUISITION_HK, HASHDIFF order by PSA_LOAD_DTS)

union all
SELECT 
MD5_BINARY(GR.VALUE) AS PURCHASE_REQUISITION_HK,
GR.VALUE::text AS BANFN,
GR.VALUE::text AS BNFPO,
NULL AS MANDT,
NULL AS GLREQUEST,
NULL AS GLSOURCESYSTEM,
NULL AS BSART,
NULL AS BSTYP,
NULL AS BSAKZ,
NULL AS LOEKZ,
NULL AS STATU,
NULL AS ESTKZ,
NULL AS FRGKZ,
NULL AS FRGZU,
NULL AS FRGST,
NULL AS EKGRP,
NULL AS ERNAM,
NULL AS ERDAT,
NULL AS AFNAM,
NULL AS TXZ01,
NULL AS MATNR,
NULL AS EMATN,
NULL AS WERKS,
NULL AS LGORT,
NULL AS BEDNR,
NULL AS MATKL,
NULL AS RESWK,
NULL AS MENGE,
NULL AS MEINS,
NULL AS BUMNG,
NULL AS BADAT,
NULL AS LPEIN,
NULL AS LFDAT,
NULL AS FRGDT,
NULL AS WEBAZ,
NULL AS PREIS,
NULL AS PEINH,
NULL AS PSTYP,
NULL AS KNTTP,
NULL AS KZVBR,
NULL AS KFLAG,
NULL AS VRTKZ,
NULL AS TWRKZ,
NULL AS WEPOS,
NULL AS WEUNB,
NULL AS REPOS,
NULL AS LIFNR,
NULL AS FLIEF,
NULL AS EKORG,
NULL AS VRTYP,
NULL AS KONNR,
NULL AS KTPNR,
NULL AS INFNR,
NULL AS ZUGBA,
NULL AS QUNUM,
NULL AS QUPOS,
NULL AS DISPO,
NULL AS SERNR,
NULL AS BVDAT,
NULL AS BATOL,
NULL AS BVDRK,
NULL AS EBELN,
NULL AS EBELP,
NULL AS BEDAT,
NULL AS BSMNG,
NULL AS LBLNI,
NULL AS BWTAR,
NULL AS XOBLR,
NULL AS EBAKZ,
NULL AS RSNUM,
NULL AS SOBKZ,
NULL AS ARSNR,
NULL AS ARSPS,
NULL AS FIXKZ,
NULL AS BMEIN,
NULL AS REVLV,
NULL AS VORAB,
NULL AS PACKNO,
NULL AS KANBA,
NULL AS BPUEB,
NULL AS CUOBJ,
NULL AS FRGGR,
NULL AS FRGRL,
NULL AS AKTNR,
NULL AS CHARG,
NULL AS UMSOK,
NULL AS VERID,
NULL AS FIPOS,
NULL AS FISTL,
NULL AS GEBER,
NULL AS KZKFG,
NULL AS SATNR,
NULL AS MNG02,
NULL AS DAT01,
NULL AS ATTYP,
NULL AS ADRNR,
NULL AS ADRN2,
NULL AS KUNNR,
NULL AS EMLIF,
NULL AS LBLKZ,
NULL AS KZBWS,
NULL AS WAERS,
NULL AS IDNLF,
NULL AS GSFRG,
NULL AS MPROF,
NULL AS KZFME,
NULL AS SPRAS,
NULL AS TECHS,
NULL AS MFRPN,
NULL AS MFRNR,
NULL AS EMNFR,
NULL AS FORDN,
NULL AS FORDP,
NULL AS PLIFZ,
NULL AS BERID,
NULL AS UZEIT,
NULL AS FKBER,
NULL AS GRANT_NBR,
NULL AS MEMORY,
NULL AS BANPR,
NULL AS RLWRT,
NULL AS BLCKD,
NULL AS REVNO,
NULL AS BLCKT,
NULL AS BESWK,
NULL AS EPROFILE,
NULL AS EPREFDOC,
NULL AS EPREFITM,
NULL AS GMMNG,
NULL AS WRTKZ,
NULL AS RESLO,
NULL AS KBLNR,
NULL AS KBLPOS,
NULL AS PRIO_URG,
NULL AS PRIO_REQ,
NULL AS MEMORYTYPE,
NULL AS ANZSN,
NULL AS MHDRZ,
NULL AS IPRKZ,
NULL AS NODISP,
NULL AS SRM_CONTRACT_ID,
NULL AS SRM_CONTRACT_ITM,
NULL AS BUDGET_PD,
NULL AS ZZRELNAM,
NULL AS ZZATPCAT,
NULL AS ZZPROCESSED,
NULL AS ZZPLNUM,
NULL AS ZZMDV01,
NULL AS ZZVERID,
NULL AS ZZPROCDATE,
NULL AS ZZBSMNG,
NULL AS ZZUSED,
NULL AS ZZ_O8_REF,
NULL AS ZZ_O8_COLOR,
NULL AS ZZ_O8_BUFFER,
NULL AS STORENETWORKID,
NULL AS STORESUPPLIERID,
NULL AS FMFGUS_KEY,
NULL AS ADVCODE,
NULL AS STACODE,
NULL AS BANFN_CS,
NULL AS BNFPO_CS,
NULL AS ITEM_CS,
NULL AS BSMNG_SND,
NULL AS NO_MARD_DATA,
NULL AS SERRU,
NULL AS DISUB_SOBKZ,
NULL AS DISUB_PSPNR,
NULL AS DISUB_KUNNR,
NULL AS DISUB_VBELN,
NULL AS DISUB_POSNR,
NULL AS DISUB_OWNER,
NULL AS FSH_VAS_REL,
NULL AS FSH_VAS_PRNT_ID,
NULL AS FSH_TRANSACTION,
NULL AS FSH_ITEM_GROUP,
NULL AS FSH_ITEM,
NULL AS IUID_RELEVANT,
NULL AS SGT_SCAT,
NULL AS SGT_RCAT,
NULL AS WRF_CHARSTC1,
NULL AS WRF_CHARSTC2,
NULL AS WRF_CHARSTC3,
NULL AS GLDELFLAG,
NULL AS GLCHANGETIME,
'N' AS PSA_DELETE_IND,
'1900-01-01'::TIMESTAMP AS PSA_LOAD_DTS,
NULL AS PSA_RECORD_SOURCE,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC,
DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC,
''::BINARY AS HASHDIFF
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
