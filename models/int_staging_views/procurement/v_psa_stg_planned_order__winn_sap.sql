---- SRC LAYER ----
WITH
SRC_plnsap         as ( SELECT * FROM {{ source('sap_ecc_prd', 'z_plaf') }} as SRC 
                        /* The filter OBART = 1is for planned orders. Other values such as 6 is for simulation orders.
                                                So for the model context these values are being excluded. */
                                                where obart = 1 ),
SRC_a              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  ),
SRC_eina           as ( SELECT * FROM {{ source('sap_ecc_prd', 'z_eina') }} as SRC 
                         qualify 1= row_number()over(partition by matnr, lifnr order by glchangetime desc)  )

/*
SRC_plnsap         as ( SELECT * FROM sap_ecc_prd.z_plaf )
, SRC_a              as ( SELECT * FROM raw_vault.ref_business_key_collision )
, SRC_eina           as ( SELECT * FROM sap_ecc_prd.z_eina )
*/
---- LOGIC LAYER ----

, LOGIC_plnsap as (
    SELECT
        PLNUM                                                        as                                   PLANNED_ORDER_BK
      , PLNUM
      , MANDT
      , GLREQUEST
      , GLSOURCESYSTEM
      , MATNR
      , PLWRK
      , PWWRK
      , PAART
      , BESKZ
      , SOBES
      , GSMNG
      , TLMNG
      , AVMNG
      , BDMNG
      , PSTTR
      , PEDTR
      , PERTR
      , WEBAZ
      , DISPO
      , UMSKZ
      , AUFFX
      , STLFX
      , KNTTP
      , KDAUF
      , KDPOS
      , KDEIN
      , PROJN
      , RSNUM
      , QUNUM
      , QUPOS
      , FLIEF
      , KONNR
      , KTPNR
      , EKORG
      , LGORT
      , NUMVR
      , KZVBR
      , SOBKZ
      , PSPEL
      , SERNR
      , PALTR
      , TECHS
      , STLAN
      , STALT
      , STSTA
      , AENNR
      , ARSNR
      , ARSPS
      , VERTO
      , VERID
      , AUFNR
      , TRART
      , PLGRP
      , TERST
      , TERED
      , BEDID
      , AUFPL
      , LINID
      , TRMKZ
      , TRMER
      , REDKZ
      , TRMHK
      , PLNNR
      , PLNAL
      , PLNTY
      , FRTHW
      , RGEKZ
      , MEINS
      , CUOBJ
      , REVLV
      , ABMNG
      , RATID
      , GROID
      , RATER
      , GROER
      , OBART
      , PLSCN
      , SBNUM
      , KBNKZ
      , KAPFX
      , SEQNR
      , PSTTI
      , PEDTI
      , MONKZ
      , PRNKZ
      , MDPBV
      , VFMNG
      , MDACH
      , MDACC
      , MDACD
      , MDACT
      , GSBTR
      , PLETX
      , PRSCH
      , LVSCH
      , KZAVC
      , VRPLA
      , PBDNR
      , AGREQ
      , UMREZ
      , UMREN
      , ERFMG
      , ERFME
      , RQNUM
      , KZBWS
      , WEMNG
      , WAMNG
      , EDGNO
      , LBLKZ
      , EMLIF
      , BERID
      , UBERI
      , EMATN
      , REMFL
      , PSTMP
      , PUSER
      , BADI
      , STAEX
      , RESLO
      , SRM_CONTRACT_ID
      , SRM_CONTRACT_ITM
      , ZZGSMNG
      , ZZ_O8_REF
      , ZZ_O8_COLOR
      , ZZ_O8_BUFFER
      , MEDKZ
      , CNFQTY
      , SGT_SCAT
      , KUNNR
      , FLG_BUNDLE
      , FSH_MPLND_ORD
      , GLDELFLAG
      , GLCHANGETIME
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , CONVERT_TIMEZONE('UTC', PSA_LOAD_DTS)                        as                                           LOAD_DTS
      , CONDITIONAL_CHANGE_EVENT(HASH(* EXCLUDE(PSA_LOAD_DTS, GLDELFLAG, GLCHANGETIME, GLREQUEST, GLSOURCESYSTEM, PSTMP, PUSER ))) OVER(PARTITION BY PLNUM ORDER BY PSA_LOAD_DTS) as                                   REVERSIONS_ORDER
    FROM SRC_plnsap
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
      , INFNR
    FROM SRC_eina
)
---- RENAME LAYER ----

, RENAME_plnsap as (
    SELECT
        PLANNED_ORDER_BK
      , PLNUM
      , MANDT
      , GLREQUEST
      , GLSOURCESYSTEM
      , MATNR
      , PLWRK
      , PWWRK
      , PAART
      , BESKZ
      , SOBES
      , GSMNG
      , TLMNG
      , AVMNG
      , BDMNG
      , PSTTR
      , PEDTR
      , PERTR
      , WEBAZ
      , DISPO
      , UMSKZ
      , AUFFX
      , STLFX
      , KNTTP
      , KDAUF
      , KDPOS
      , KDEIN
      , PROJN
      , RSNUM
      , QUNUM
      , QUPOS
      , FLIEF
      , KONNR
      , KTPNR
      , EKORG
      , LGORT
      , NUMVR
      , KZVBR
      , SOBKZ
      , PSPEL
      , SERNR
      , PALTR
      , TECHS
      , STLAN
      , STALT
      , STSTA
      , AENNR
      , ARSNR
      , ARSPS
      , VERTO
      , VERID
      , AUFNR
      , TRART
      , PLGRP
      , TERST
      , TERED
      , BEDID
      , AUFPL
      , LINID
      , TRMKZ
      , TRMER
      , REDKZ
      , TRMHK
      , PLNNR
      , PLNAL
      , PLNTY
      , FRTHW
      , RGEKZ
      , MEINS
      , CUOBJ
      , REVLV
      , ABMNG
      , RATID
      , GROID
      , RATER
      , GROER
      , OBART
      , PLSCN
      , SBNUM
      , KBNKZ
      , KAPFX
      , SEQNR
      , PSTTI
      , PEDTI
      , MONKZ
      , PRNKZ
      , MDPBV
      , VFMNG
      , MDACH
      , MDACC
      , MDACD
      , MDACT
      , GSBTR
      , PLETX
      , PRSCH
      , LVSCH
      , KZAVC
      , VRPLA
      , PBDNR
      , AGREQ
      , UMREZ
      , UMREN
      , ERFMG
      , ERFME
      , RQNUM
      , KZBWS
      , WEMNG
      , WAMNG
      , EDGNO
      , LBLKZ
      , EMLIF
      , BERID
      , UBERI
      , EMATN
      , REMFL
      , PSTMP
      , PUSER
      , BADI
      , STAEX
      , RESLO
      , SRM_CONTRACT_ID
      , SRM_CONTRACT_ITM
      , ZZGSMNG
      , ZZ_O8_REF
      , ZZ_O8_COLOR
      , ZZ_O8_BUFFER
      , MEDKZ
      , CNFQTY
      , SGT_SCAT
      , KUNNR
      , FLG_BUNDLE
      , FSH_MPLND_ORD
      , GLDELFLAG
      , GLCHANGETIME
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , LOAD_DTS
      , REVERSIONS_ORDER
    FROM LOGIC_plnsap
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
      , INFNR
    FROM LOGIC_eina
)
---- FILTER LAYER ----

, FILTER_plnsap as (
    SELECT *
    FROM RENAME_plnsap
)

, FILTER_a as (
    SELECT *
    FROM RENAME_a
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_PLAF'
)

, FILTER_eina as (
    SELECT *
    FROM RENAME_eina
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_plnsap
    INNER JOIN FILTER_a
        ON '1' = '1'
    LEFT JOIN FILTER_eina
        ON FILTER_plnsap.MATNR = EINA_MATNR AND FLIEF = EINA_LIFNR
)

---- FINAL LAYER ----
SELECT
          PLANNED_ORDER_BK
        , PLNUM
        , MANDT
        , GLREQUEST
        , GLSOURCESYSTEM
        , MATNR
        , PLWRK
        , PWWRK
        , PAART
        , BESKZ
        , SOBES
        , GSMNG
        , TLMNG
        , AVMNG
        , BDMNG
        , PSTTR
        , PEDTR
        , PERTR
        , WEBAZ
        , DISPO
        , UMSKZ
        , AUFFX
        , STLFX
        , KNTTP
        , KDAUF
        , KDPOS
        , KDEIN
        , PROJN
        , RSNUM
        , QUNUM
        , QUPOS
        , FLIEF
        , KONNR
        , KTPNR
        , EKORG
        , LGORT
        , NUMVR
        , KZVBR
        , SOBKZ
        , PSPEL
        , SERNR
        , PALTR
        , TECHS
        , STLAN
        , STALT
        , STSTA
        , AENNR
        , ARSNR
        , ARSPS
        , VERTO
        , VERID
        , AUFNR
        , TRART
        , PLGRP
        , TERST
        , TERED
        , BEDID
        , AUFPL
        , LINID
        , TRMKZ
        , TRMER
        , REDKZ
        , TRMHK
        , PLNNR
        , PLNAL
        , PLNTY
        , FRTHW
        , RGEKZ
        , MEINS
        , CUOBJ
        , REVLV
        , ABMNG
        , RATID
        , GROID
        , RATER
        , GROER
        , OBART
        , PLSCN
        , SBNUM
        , KBNKZ
        , KAPFX
        , SEQNR
        , PSTTI
        , PEDTI
        , MONKZ
        , PRNKZ
        , MDPBV
        , VFMNG
        , MDACH
        , MDACC
        , MDACD
        , MDACT
        , GSBTR
        , PLETX
        , PRSCH
        , LVSCH
        , KZAVC
        , VRPLA
        , PBDNR
        , AGREQ
        , UMREZ
        , UMREN
        , ERFMG
        , ERFME
        , RQNUM
        , KZBWS
        , WEMNG
        , WAMNG
        , EDGNO
        , LBLKZ
        , EMLIF
        , BERID
        , UBERI
        , EMATN
        , REMFL
        , PSTMP
        , PUSER
        , BADI
        , STAEX
        , RESLO
        , SRM_CONTRACT_ID
        , SRM_CONTRACT_ITM
        , ZZGSMNG
        , ZZ_O8_REF
        , ZZ_O8_COLOR
        , ZZ_O8_BUFFER
        , MEDKZ
        , CNFQTY
        , SGT_SCAT
        , KUNNR
        , FLG_BUNDLE
        , FSH_MPLND_ORD
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
        , IFF(EKORG= '', '-2', CONCAT_WS('||', EKORG, BKCC))           as DRVD_EKORG_BKCC
        , IFF(INFNR is null, '-2', CONCAT_WS('||', INFNR, BKCC))       as DRVD_INFNR_BKCC
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PLNUM as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PLANNED_ORDER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(DRVD_SUPPLIER_BKCC as VARCHAR)),''), '^^')
        ))) as SUPPLIER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(MATNR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ITEM_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PLWRK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PLANT_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(DRVD_EKORG_BKCC as VARCHAR)),''), '^^')
        ))) as PURCHASING_ORG_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(DRVD_INFNR_BKCC as VARCHAR)),''), '^^')
        ))) as PURCHASING_RECORD_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PLNUM as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(FLIEF as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(MATNR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(PLWRK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(INFNR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(EKORG as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as LNK_PLANNED_ORDER_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(MANDT::text), '^^') 
            , '||', IFNULL(TRIM(MATNR::text), '^^') 
            , '||', IFNULL(TRIM(PLWRK::text), '^^') 
            , '||', IFNULL(TRIM(PWWRK::text), '^^') 
            , '||', IFNULL(TRIM(PAART::text), '^^') 
            , '||', IFNULL(TRIM(BESKZ::text), '^^') 
            , '||', IFNULL(TRIM(SOBES::text), '^^') 
            , '||', IFNULL(TRIM(GSMNG::text), '^^') 
            , '||', IFNULL(TRIM(TLMNG::text), '^^') 
            , '||', IFNULL(TRIM(AVMNG::text), '^^') 
            , '||', IFNULL(TRIM(BDMNG::text), '^^') 
            , '||', IFNULL(TRIM(PSTTR::text), '^^') 
            , '||', IFNULL(TRIM(PEDTR::text), '^^') 
            , '||', IFNULL(TRIM(PERTR::text), '^^') 
            , '||', IFNULL(TRIM(WEBAZ::text), '^^') 
            , '||', IFNULL(TRIM(DISPO::text), '^^') 
            , '||', IFNULL(TRIM(UMSKZ::text), '^^') 
            , '||', IFNULL(TRIM(AUFFX::text), '^^') 
            , '||', IFNULL(TRIM(STLFX::text), '^^') 
            , '||', IFNULL(TRIM(KNTTP::text), '^^') 
            , '||', IFNULL(TRIM(KDAUF::text), '^^') 
            , '||', IFNULL(TRIM(KDPOS::text), '^^') 
            , '||', IFNULL(TRIM(KDEIN::text), '^^') 
            , '||', IFNULL(TRIM(PROJN::text), '^^') 
            , '||', IFNULL(TRIM(RSNUM::text), '^^') 
            , '||', IFNULL(TRIM(QUNUM::text), '^^') 
            , '||', IFNULL(TRIM(QUPOS::text), '^^') 
            , '||', IFNULL(TRIM(FLIEF::text), '^^') 
            , '||', IFNULL(TRIM(KONNR::text), '^^') 
            , '||', IFNULL(TRIM(KTPNR::text), '^^') 
            , '||', IFNULL(TRIM(EKORG::text), '^^') 
            , '||', IFNULL(TRIM(LGORT::text), '^^') 
            , '||', IFNULL(TRIM(NUMVR::text), '^^') 
            , '||', IFNULL(TRIM(KZVBR::text), '^^') 
            , '||', IFNULL(TRIM(SOBKZ::text), '^^') 
            , '||', IFNULL(TRIM(PSPEL::text), '^^') 
            , '||', IFNULL(TRIM(SERNR::text), '^^') 
            , '||', IFNULL(TRIM(PALTR::text), '^^') 
            , '||', IFNULL(TRIM(TECHS::text), '^^') 
            , '||', IFNULL(TRIM(STLAN::text), '^^') 
            , '||', IFNULL(TRIM(STALT::text), '^^') 
            , '||', IFNULL(TRIM(STSTA::text), '^^') 
            , '||', IFNULL(TRIM(AENNR::text), '^^') 
            , '||', IFNULL(TRIM(ARSNR::text), '^^') 
            , '||', IFNULL(TRIM(ARSPS::text), '^^') 
            , '||', IFNULL(TRIM(VERTO::text), '^^') 
            , '||', IFNULL(TRIM(VERID::text), '^^') 
            , '||', IFNULL(TRIM(AUFNR::text), '^^') 
            , '||', IFNULL(TRIM(TRART::text), '^^') 
            , '||', IFNULL(TRIM(PLGRP::text), '^^') 
            , '||', IFNULL(TRIM(TERST::text), '^^') 
            , '||', IFNULL(TRIM(TERED::text), '^^') 
            , '||', IFNULL(TRIM(BEDID::text), '^^') 
            , '||', IFNULL(TRIM(AUFPL::text), '^^') 
            , '||', IFNULL(TRIM(LINID::text), '^^') 
            , '||', IFNULL(TRIM(TRMKZ::text), '^^') 
            , '||', IFNULL(TRIM(TRMER::text), '^^') 
            , '||', IFNULL(TRIM(REDKZ::text), '^^') 
            , '||', IFNULL(TRIM(TRMHK::text), '^^') 
            , '||', IFNULL(TRIM(PLNNR::text), '^^') 
            , '||', IFNULL(TRIM(PLNAL::text), '^^') 
            , '||', IFNULL(TRIM(PLNTY::text), '^^') 
            , '||', IFNULL(TRIM(FRTHW::text), '^^') 
            , '||', IFNULL(TRIM(RGEKZ::text), '^^') 
            , '||', IFNULL(TRIM(MEINS::text), '^^') 
            , '||', IFNULL(TRIM(CUOBJ::text), '^^') 
            , '||', IFNULL(TRIM(REVLV::text), '^^') 
            , '||', IFNULL(TRIM(ABMNG::text), '^^') 
            , '||', IFNULL(TRIM(RATID::text), '^^') 
            , '||', IFNULL(TRIM(GROID::text), '^^') 
            , '||', IFNULL(TRIM(RATER::text), '^^') 
            , '||', IFNULL(TRIM(GROER::text), '^^') 
            , '||', IFNULL(TRIM(OBART::text), '^^') 
            , '||', IFNULL(TRIM(PLSCN::text), '^^') 
            , '||', IFNULL(TRIM(SBNUM::text), '^^') 
            , '||', IFNULL(TRIM(KBNKZ::text), '^^') 
            , '||', IFNULL(TRIM(KAPFX::text), '^^') 
            , '||', IFNULL(TRIM(SEQNR::text), '^^') 
            , '||', IFNULL(TRIM(PSTTI::text), '^^') 
            , '||', IFNULL(TRIM(PEDTI::text), '^^') 
            , '||', IFNULL(TRIM(MONKZ::text), '^^') 
            , '||', IFNULL(TRIM(PRNKZ::text), '^^') 
            , '||', IFNULL(TRIM(MDPBV::text), '^^') 
            , '||', IFNULL(TRIM(VFMNG::text), '^^') 
            , '||', IFNULL(TRIM(MDACH::text), '^^') 
            , '||', IFNULL(TRIM(MDACC::text), '^^') 
            , '||', IFNULL(TRIM(MDACD::text), '^^') 
            , '||', IFNULL(TRIM(MDACT::text), '^^') 
            , '||', IFNULL(TRIM(GSBTR::text), '^^') 
            , '||', IFNULL(TRIM(PLETX::text), '^^') 
            , '||', IFNULL(TRIM(PRSCH::text), '^^') 
            , '||', IFNULL(TRIM(LVSCH::text), '^^') 
            , '||', IFNULL(TRIM(KZAVC::text), '^^') 
            , '||', IFNULL(TRIM(VRPLA::text), '^^') 
            , '||', IFNULL(TRIM(PBDNR::text), '^^') 
            , '||', IFNULL(TRIM(AGREQ::text), '^^') 
            , '||', IFNULL(TRIM(UMREZ::text), '^^') 
            , '||', IFNULL(TRIM(UMREN::text), '^^') 
            , '||', IFNULL(TRIM(ERFMG::text), '^^') 
            , '||', IFNULL(TRIM(ERFME::text), '^^') 
            , '||', IFNULL(TRIM(RQNUM::text), '^^') 
            , '||', IFNULL(TRIM(KZBWS::text), '^^') 
            , '||', IFNULL(TRIM(WEMNG::text), '^^') 
            , '||', IFNULL(TRIM(WAMNG::text), '^^') 
            , '||', IFNULL(TRIM(EDGNO::text), '^^') 
            , '||', IFNULL(TRIM(LBLKZ::text), '^^') 
            , '||', IFNULL(TRIM(EMLIF::text), '^^') 
            , '||', IFNULL(TRIM(BERID::text), '^^') 
            , '||', IFNULL(TRIM(UBERI::text), '^^') 
            , '||', IFNULL(TRIM(EMATN::text), '^^') 
            , '||', IFNULL(TRIM(REMFL::text), '^^') 
            , '||', IFNULL(TRIM(BADI::text), '^^') 
            , '||', IFNULL(TRIM(STAEX::text), '^^') 
            , '||', IFNULL(TRIM(RESLO::text), '^^') 
            , '||', IFNULL(TRIM(SRM_CONTRACT_ID::text), '^^') 
            , '||', IFNULL(TRIM(SRM_CONTRACT_ITM::text), '^^') 
            , '||', IFNULL(TRIM(ZZGSMNG::text), '^^') 
            , '||', IFNULL(TRIM(ZZ_O8_REF::text), '^^') 
            , '||', IFNULL(TRIM(ZZ_O8_COLOR::text), '^^') 
            , '||', IFNULL(TRIM(ZZ_O8_BUFFER::text), '^^') 
            , '||', IFNULL(TRIM(MEDKZ::text), '^^') 
            , '||', IFNULL(TRIM(CNFQTY::text), '^^') 
            , '||', IFNULL(TRIM(SGT_SCAT::text), '^^') 
            , '||', IFNULL(TRIM(KUNNR::text), '^^') 
            , '||', IFNULL(TRIM(FLG_BUNDLE::text), '^^') 
            , '||', IFNULL(TRIM(FSH_MPLND_ORD::text), '^^') 
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
            , '||', IFNULL(TRIM(REVERSIONS_ORDER::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
