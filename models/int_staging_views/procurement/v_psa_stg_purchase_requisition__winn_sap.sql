---- SRC LAYER ----
WITH
SRC_pursap         as ( SELECT * FROM {{ source('sap_ecc_prd', 'z_eban') }} as SRC  ),
SRC_a              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  ),
SRC_eina           as ( SELECT * FROM {{ source('sap_ecc_prd', 'z_eina') }} as SRC 
                         qualify 1= row_number()over(partition by matnr, lifnr order by glchangetime desc)  )

/*
SRC_pursap         as ( SELECT * FROM sap_ecc_prd.z_eban )
, SRC_a              as ( SELECT * FROM raw_vault.ref_business_key_collision )
, SRC_eina           as ( SELECT * FROM sap_ecc_prd.z_eina )
*/
---- LOGIC LAYER ----

, LOGIC_pursap as (
    SELECT
        CONCAT_WS('||', BANFN, BNFPO)                                as                            PURCHASE_REQUISITION_BK
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
      , CONVERT_TIMEZONE('UTC', PSA_LOAD_DTS)                        as                                           LOAD_DTS
      , /*to handle the reversions and capture if it is a true change*/
        CONDITIONAL_CHANGE_EVENT(HASH(* EXCLUDE(PSA_LOAD_DTS, GLDELFLAG, GLCHANGETIME, GLREQUEST, GLSOURCESYSTEM ))) OVER(PARTITION BY  BANFN, BNFPO ORDER BY PSA_LOAD_DTS) as                                   REVERSIONS_ORDER
    FROM SRC_pursap
)

, LOGIC_a as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_a
)

, LOGIC_eina as (
    SELECT
        MATNR                                                        as                                        EINA_MATNR
      , LIFNR                                                        as                                         EINA_LIFNR
      , INFNR                                                        as                                         EINA_INFNR
    FROM SRC_eina
)
---- RENAME LAYER ----

, RENAME_pursap as (
    SELECT
        PURCHASE_REQUISITION_BK
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
      , REVERSIONS_ORDER
    FROM LOGIC_pursap
)

, RENAME_a as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_a
)

, RENAME_eina as (
    SELECT
        EINA_MATNR 
      , EINA_LIFNR
      , EINA_INFNR
    FROM LOGIC_eina
)
---- FILTER LAYER ----

, FILTER_pursap as (
    SELECT *
    FROM RENAME_pursap
)

, FILTER_a as (
    SELECT *
    FROM RENAME_a
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_EBAN'
)

, FILTER_eina as (
    SELECT *
    FROM RENAME_eina
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_pursap
    INNER JOIN FILTER_a
        ON '1' = '1'
    LEFT JOIN FILTER_eina
        ON MATNR = EINA_MATNR AND FLIEF = EINA_LIFNR
)

---- FINAL LAYER ----
SELECT
          PURCHASE_REQUISITION_BK
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
        , REVERSIONS_ORDER
        , /* The supplier HK values are modified to handle the optional null default for the Hash key generation.
          This derived field prevents BKCC being included in the HK generation when the Supplier key is null/Blank */
            IFF(FLIEF= '', '-2', CONCAT_WS('||', FLIEF, BKCC)) as DRVD_SUPPLIER_BKCC
        , IFF(MATNR= '', '-2', CONCAT_WS('||', MATNR, BKCC))           as DRVD_ITEM_BKCC
        ,             IFF(EBELN= '', '-2', CONCAT_WS('||', EBELN, BKCC)) as DRVD_PO_HEADER_BKCC
        ,             IFF(EBELN= '', '-2', CONCAT_WS('||',EBELN, EBELP, BKCC)) as DRVD_PO_LINE_BKCC
        , IFF(EKORG= '', '-2', CONCAT_WS('||', EKORG, BKCC))           as DRVD_EKORG_BKCC
        , IFF(EINA_INFNR is null, '-2', CONCAT_WS('||', EINA_INFNR, BKCC)) as DRVD_INFNR_BKCC
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(BANFN as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BNFPO as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PURCHASE_REQUISITION_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(DRVD_SUPPLIER_BKCC as VARCHAR)),''), '^^')
        ))) as SUPPLIER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(DRVD_ITEM_BKCC as VARCHAR)),''), '^^')
        ))) as ITEM_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(WERKS as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PLANT_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(DRVD_EKORG_BKCC as VARCHAR)),''), '^^')
        ))) as PURCHASING_ORG_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(DRVD_INFNR_BKCC as VARCHAR)),''), '^^')
        ))) as PURCHASING_RECORD_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(DRVD_PO_HEADER_BKCC as VARCHAR)),''), '^^')
        ))) as PO_HEADER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(DRVD_PO_LINE_BKCC as VARCHAR)),''), '^^')
        ))) as PO_ITEM_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(BANFN as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BNFPO as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(FLIEF as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(MATNR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(WERKS as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(EKORG as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(EBELN as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(EBELP as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(EINA_INFNR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as LNK_PURCHASE_REQUISITION_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(MANDT::text), '^^') 
            , '||', IFNULL(TRIM(BSART::text), '^^') 
            , '||', IFNULL(TRIM(BSTYP::text), '^^') 
            , '||', IFNULL(TRIM(BSAKZ::text), '^^') 
            , '||', IFNULL(TRIM(LOEKZ::text), '^^') 
            , '||', IFNULL(TRIM(STATU::text), '^^') 
            , '||', IFNULL(TRIM(ESTKZ::text), '^^') 
            , '||', IFNULL(TRIM(FRGKZ::text), '^^') 
            , '||', IFNULL(TRIM(FRGZU::text), '^^') 
            , '||', IFNULL(TRIM(FRGST::text), '^^') 
            , '||', IFNULL(TRIM(EKGRP::text), '^^') 
            , '||', IFNULL(TRIM(ERNAM::text), '^^') 
            , '||', IFNULL(TRIM(ERDAT::text), '^^') 
            , '||', IFNULL(TRIM(AFNAM::text), '^^') 
            , '||', IFNULL(TRIM(TXZ01::text), '^^') 
            , '||', IFNULL(TRIM(MATNR::text), '^^') 
            , '||', IFNULL(TRIM(EMATN::text), '^^') 
            , '||', IFNULL(TRIM(WERKS::text), '^^') 
            , '||', IFNULL(TRIM(LGORT::text), '^^') 
            , '||', IFNULL(TRIM(BEDNR::text), '^^') 
            , '||', IFNULL(TRIM(MATKL::text), '^^') 
            , '||', IFNULL(TRIM(RESWK::text), '^^') 
            , '||', IFNULL(TRIM(MENGE::text), '^^') 
            , '||', IFNULL(TRIM(MEINS::text), '^^') 
            , '||', IFNULL(TRIM(BUMNG::text), '^^') 
            , '||', IFNULL(TRIM(BADAT::text), '^^') 
            , '||', IFNULL(TRIM(LPEIN::text), '^^') 
            , '||', IFNULL(TRIM(LFDAT::text), '^^') 
            , '||', IFNULL(TRIM(FRGDT::text), '^^') 
            , '||', IFNULL(TRIM(WEBAZ::text), '^^') 
            , '||', IFNULL(TRIM(PREIS::text), '^^') 
            , '||', IFNULL(TRIM(PEINH::text), '^^') 
            , '||', IFNULL(TRIM(PSTYP::text), '^^') 
            , '||', IFNULL(TRIM(KNTTP::text), '^^') 
            , '||', IFNULL(TRIM(KZVBR::text), '^^') 
            , '||', IFNULL(TRIM(KFLAG::text), '^^') 
            , '||', IFNULL(TRIM(VRTKZ::text), '^^') 
            , '||', IFNULL(TRIM(TWRKZ::text), '^^') 
            , '||', IFNULL(TRIM(WEPOS::text), '^^') 
            , '||', IFNULL(TRIM(WEUNB::text), '^^') 
            , '||', IFNULL(TRIM(REPOS::text), '^^') 
            , '||', IFNULL(TRIM(LIFNR::text), '^^') 
            , '||', IFNULL(TRIM(FLIEF::text), '^^') 
            , '||', IFNULL(TRIM(EKORG::text), '^^') 
            , '||', IFNULL(TRIM(VRTYP::text), '^^') 
            , '||', IFNULL(TRIM(KONNR::text), '^^') 
            , '||', IFNULL(TRIM(KTPNR::text), '^^') 
            , '||', IFNULL(TRIM(INFNR::text), '^^') 
            , '||', IFNULL(TRIM(ZUGBA::text), '^^') 
            , '||', IFNULL(TRIM(QUNUM::text), '^^') 
            , '||', IFNULL(TRIM(QUPOS::text), '^^') 
            , '||', IFNULL(TRIM(DISPO::text), '^^') 
            , '||', IFNULL(TRIM(SERNR::text), '^^') 
            , '||', IFNULL(TRIM(BVDAT::text), '^^') 
            , '||', IFNULL(TRIM(BATOL::text), '^^') 
            , '||', IFNULL(TRIM(BVDRK::text), '^^') 
            , '||', IFNULL(TRIM(EBELN::text), '^^') 
            , '||', IFNULL(TRIM(EBELP::text), '^^') 
            , '||', IFNULL(TRIM(BEDAT::text), '^^') 
            , '||', IFNULL(TRIM(BSMNG::text), '^^') 
            , '||', IFNULL(TRIM(LBLNI::text), '^^') 
            , '||', IFNULL(TRIM(BWTAR::text), '^^') 
            , '||', IFNULL(TRIM(XOBLR::text), '^^') 
            , '||', IFNULL(TRIM(EBAKZ::text), '^^') 
            , '||', IFNULL(TRIM(RSNUM::text), '^^') 
            , '||', IFNULL(TRIM(SOBKZ::text), '^^') 
            , '||', IFNULL(TRIM(ARSNR::text), '^^') 
            , '||', IFNULL(TRIM(ARSPS::text), '^^') 
            , '||', IFNULL(TRIM(FIXKZ::text), '^^') 
            , '||', IFNULL(TRIM(BMEIN::text), '^^') 
            , '||', IFNULL(TRIM(REVLV::text), '^^') 
            , '||', IFNULL(TRIM(VORAB::text), '^^') 
            , '||', IFNULL(TRIM(PACKNO::text), '^^') 
            , '||', IFNULL(TRIM(KANBA::text), '^^') 
            , '||', IFNULL(TRIM(BPUEB::text), '^^') 
            , '||', IFNULL(TRIM(CUOBJ::text), '^^') 
            , '||', IFNULL(TRIM(FRGGR::text), '^^') 
            , '||', IFNULL(TRIM(FRGRL::text), '^^') 
            , '||', IFNULL(TRIM(AKTNR::text), '^^') 
            , '||', IFNULL(TRIM(CHARG::text), '^^') 
            , '||', IFNULL(TRIM(UMSOK::text), '^^') 
            , '||', IFNULL(TRIM(VERID::text), '^^') 
            , '||', IFNULL(TRIM(FIPOS::text), '^^') 
            , '||', IFNULL(TRIM(FISTL::text), '^^') 
            , '||', IFNULL(TRIM(GEBER::text), '^^') 
            , '||', IFNULL(TRIM(KZKFG::text), '^^') 
            , '||', IFNULL(TRIM(SATNR::text), '^^') 
            , '||', IFNULL(TRIM(MNG02::text), '^^') 
            , '||', IFNULL(TRIM(DAT01::text), '^^') 
            , '||', IFNULL(TRIM(ATTYP::text), '^^') 
            , '||', IFNULL(TRIM(ADRNR::text), '^^') 
            , '||', IFNULL(TRIM(ADRN2::text), '^^') 
            , '||', IFNULL(TRIM(KUNNR::text), '^^') 
            , '||', IFNULL(TRIM(EMLIF::text), '^^') 
            , '||', IFNULL(TRIM(LBLKZ::text), '^^') 
            , '||', IFNULL(TRIM(KZBWS::text), '^^') 
            , '||', IFNULL(TRIM(WAERS::text), '^^') 
            , '||', IFNULL(TRIM(IDNLF::text), '^^') 
            , '||', IFNULL(TRIM(GSFRG::text), '^^') 
            , '||', IFNULL(TRIM(MPROF::text), '^^') 
            , '||', IFNULL(TRIM(KZFME::text), '^^') 
            , '||', IFNULL(TRIM(SPRAS::text), '^^') 
            , '||', IFNULL(TRIM(TECHS::text), '^^') 
            , '||', IFNULL(TRIM(MFRPN::text), '^^') 
            , '||', IFNULL(TRIM(MFRNR::text), '^^') 
            , '||', IFNULL(TRIM(EMNFR::text), '^^') 
            , '||', IFNULL(TRIM(FORDN::text), '^^') 
            , '||', IFNULL(TRIM(FORDP::text), '^^') 
            , '||', IFNULL(TRIM(PLIFZ::text), '^^') 
            , '||', IFNULL(TRIM(BERID::text), '^^') 
            , '||', IFNULL(TRIM(UZEIT::text), '^^') 
            , '||', IFNULL(TRIM(FKBER::text), '^^') 
            , '||', IFNULL(TRIM(GRANT_NBR::text), '^^') 
            , '||', IFNULL(TRIM(MEMORY::text), '^^') 
            , '||', IFNULL(TRIM(BANPR::text), '^^') 
            , '||', IFNULL(TRIM(RLWRT::text), '^^') 
            , '||', IFNULL(TRIM(BLCKD::text), '^^') 
            , '||', IFNULL(TRIM(REVNO::text), '^^') 
            , '||', IFNULL(TRIM(BLCKT::text), '^^') 
            , '||', IFNULL(TRIM(BESWK::text), '^^') 
            , '||', IFNULL(TRIM(EPROFILE::text), '^^') 
            , '||', IFNULL(TRIM(EPREFDOC::text), '^^') 
            , '||', IFNULL(TRIM(EPREFITM::text), '^^') 
            , '||', IFNULL(TRIM(GMMNG::text), '^^') 
            , '||', IFNULL(TRIM(WRTKZ::text), '^^') 
            , '||', IFNULL(TRIM(RESLO::text), '^^') 
            , '||', IFNULL(TRIM(KBLNR::text), '^^') 
            , '||', IFNULL(TRIM(KBLPOS::text), '^^') 
            , '||', IFNULL(TRIM(PRIO_URG::text), '^^') 
            , '||', IFNULL(TRIM(PRIO_REQ::text), '^^') 
            , '||', IFNULL(TRIM(MEMORYTYPE::text), '^^') 
            , '||', IFNULL(TRIM(ANZSN::text), '^^') 
            , '||', IFNULL(TRIM(MHDRZ::text), '^^') 
            , '||', IFNULL(TRIM(IPRKZ::text), '^^') 
            , '||', IFNULL(TRIM(NODISP::text), '^^') 
            , '||', IFNULL(TRIM(SRM_CONTRACT_ID::text), '^^') 
            , '||', IFNULL(TRIM(SRM_CONTRACT_ITM::text), '^^') 
            , '||', IFNULL(TRIM(BUDGET_PD::text), '^^') 
            , '||', IFNULL(TRIM(ZZRELNAM::text), '^^') 
            , '||', IFNULL(TRIM(ZZATPCAT::text), '^^') 
            , '||', IFNULL(TRIM(ZZPROCESSED::text), '^^') 
            , '||', IFNULL(TRIM(ZZPLNUM::text), '^^') 
            , '||', IFNULL(TRIM(ZZMDV01::text), '^^') 
            , '||', IFNULL(TRIM(ZZVERID::text), '^^') 
            , '||', IFNULL(TRIM(ZZPROCDATE::text), '^^') 
            , '||', IFNULL(TRIM(ZZBSMNG::text), '^^') 
            , '||', IFNULL(TRIM(ZZUSED::text), '^^') 
            , '||', IFNULL(TRIM(ZZ_O8_REF::text), '^^') 
            , '||', IFNULL(TRIM(ZZ_O8_COLOR::text), '^^') 
            , '||', IFNULL(TRIM(ZZ_O8_BUFFER::text), '^^') 
            , '||', IFNULL(TRIM(STORENETWORKID::text), '^^') 
            , '||', IFNULL(TRIM(STORESUPPLIERID::text), '^^') 
            , '||', IFNULL(TRIM(FMFGUS_KEY::text), '^^') 
            , '||', IFNULL(TRIM(ADVCODE::text), '^^') 
            , '||', IFNULL(TRIM(STACODE::text), '^^') 
            , '||', IFNULL(TRIM(BANFN_CS::text), '^^') 
            , '||', IFNULL(TRIM(BNFPO_CS::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_CS::text), '^^') 
            , '||', IFNULL(TRIM(BSMNG_SND::text), '^^') 
            , '||', IFNULL(TRIM(NO_MARD_DATA::text), '^^') 
            , '||', IFNULL(TRIM(SERRU::text), '^^') 
            , '||', IFNULL(TRIM(DISUB_SOBKZ::text), '^^') 
            , '||', IFNULL(TRIM(DISUB_PSPNR::text), '^^') 
            , '||', IFNULL(TRIM(DISUB_KUNNR::text), '^^') 
            , '||', IFNULL(TRIM(DISUB_VBELN::text), '^^') 
            , '||', IFNULL(TRIM(DISUB_POSNR::text), '^^') 
            , '||', IFNULL(TRIM(DISUB_OWNER::text), '^^') 
            , '||', IFNULL(TRIM(FSH_VAS_REL::text), '^^') 
            , '||', IFNULL(TRIM(FSH_VAS_PRNT_ID::text), '^^') 
            , '||', IFNULL(TRIM(FSH_TRANSACTION::text), '^^') 
            , '||', IFNULL(TRIM(FSH_ITEM_GROUP::text), '^^') 
            , '||', IFNULL(TRIM(FSH_ITEM::text), '^^') 
            , '||', IFNULL(TRIM(IUID_RELEVANT::text), '^^') 
            , '||', IFNULL(TRIM(SGT_SCAT::text), '^^') 
            , '||', IFNULL(TRIM(SGT_RCAT::text), '^^') 
            , '||', IFNULL(TRIM(WRF_CHARSTC1::text), '^^') 
            , '||', IFNULL(TRIM(WRF_CHARSTC2::text), '^^') 
            , '||', IFNULL(TRIM(WRF_CHARSTC3::text), '^^') 
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
            , '||', IFNULL(TRIM(REVERSIONS_ORDER::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
