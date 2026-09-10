---- SRC LAYER ----
WITH
SRC_plnsap         as ( SELECT * FROM {{ ref('v_psa_stg_planned_order__winn_sap') }} as SRC 
                         {% if is_incremental() %}
                              where src.load_dts > (select dateadd('HOUR',-1,max(load_dts)) from {{ this }})
                            {% endif %}   )

/*
SRC_plnsap         as ( SELECT * FROM staging.v_psa_stg_planned_order__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_plnsap as (
    SELECT
        PLANNED_ORDER_HK
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
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM SRC_plnsap
)
---- RENAME LAYER ----

, RENAME_plnsap as (
    SELECT
        PLANNED_ORDER_HK
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
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM LOGIC_plnsap
)
---- FILTER LAYER ----

, FILTER_plnsap as (
    SELECT *
    FROM RENAME_plnsap
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_plnsap
)

---- FINAL LAYER ----
SELECT
          PLANNED_ORDER_HK
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
        , REC_SRC
        , BKCC
        , HASHDIFF
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.PLANNED_ORDER_HK = JOIN_RESULT.PLANNED_ORDER_HK 
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %}
{% if not is_incremental() %}

/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per HK and hashdiff. */
qualify 1 = row_number() over (partition by PLANNED_ORDER_HK, HASHDIFF order by PSA_LOAD_DTS)

union all
SELECT 
MD5_BINARY(GR.VALUE) AS PLANNED_ORDER_HK,
GR.VALUE::text AS PLNUM,
NULL AS MANDT,
NULL AS GLREQUEST,
NULL AS GLSOURCESYSTEM,
NULL AS MATNR,
NULL AS PLWRK,
NULL AS PWWRK,
NULL AS PAART,
NULL AS BESKZ,
NULL AS SOBES,
NULL AS GSMNG,
NULL AS TLMNG,
NULL AS AVMNG,
NULL AS BDMNG,
NULL AS PSTTR,
NULL AS PEDTR,
NULL AS PERTR,
NULL AS WEBAZ,
NULL AS DISPO,
NULL AS UMSKZ,
NULL AS AUFFX,
NULL AS STLFX,
NULL AS KNTTP,
NULL AS KDAUF,
NULL AS KDPOS,
NULL AS KDEIN,
NULL AS PROJN,
NULL AS RSNUM,
NULL AS QUNUM,
NULL AS QUPOS,
NULL AS FLIEF,
NULL AS KONNR,
NULL AS KTPNR,
NULL AS EKORG,
NULL AS LGORT,
NULL AS NUMVR,
NULL AS KZVBR,
NULL AS SOBKZ,
NULL AS PSPEL,
NULL AS SERNR,
NULL AS PALTR,
NULL AS TECHS,
NULL AS STLAN,
NULL AS STALT,
NULL AS STSTA,
NULL AS AENNR,
NULL AS ARSNR,
NULL AS ARSPS,
NULL AS VERTO,
NULL AS VERID,
NULL AS AUFNR,
NULL AS TRART,
NULL AS PLGRP,
NULL AS TERST,
NULL AS TERED,
NULL AS BEDID,
NULL AS AUFPL,
NULL AS LINID,
NULL AS TRMKZ,
NULL AS TRMER,
NULL AS REDKZ,
NULL AS TRMHK,
NULL AS PLNNR,
NULL AS PLNAL,
NULL AS PLNTY,
NULL AS FRTHW,
NULL AS RGEKZ,
NULL AS MEINS,
NULL AS CUOBJ,
NULL AS REVLV,
NULL AS ABMNG,
NULL AS RATID,
NULL AS GROID,
NULL AS RATER,
NULL AS GROER,
NULL AS OBART,
NULL AS PLSCN,
NULL AS SBNUM,
NULL AS KBNKZ,
NULL AS KAPFX,
NULL AS SEQNR,
NULL AS PSTTI,
NULL AS PEDTI,
NULL AS MONKZ,
NULL AS PRNKZ,
NULL AS MDPBV,
NULL AS VFMNG,
NULL AS MDACH,
NULL AS MDACC,
NULL AS MDACD,
NULL AS MDACT,
NULL AS GSBTR,
NULL AS PLETX,
NULL AS PRSCH,
NULL AS LVSCH,
NULL AS KZAVC,
NULL AS VRPLA,
NULL AS PBDNR,
NULL AS AGREQ,
NULL AS UMREZ,
NULL AS UMREN,
NULL AS ERFMG,
NULL AS ERFME,
NULL AS RQNUM,
NULL AS KZBWS,
NULL AS WEMNG,
NULL AS WAMNG,
NULL AS EDGNO,
NULL AS LBLKZ,
NULL AS EMLIF,
NULL AS BERID,
NULL AS UBERI,
NULL AS EMATN,
NULL AS REMFL,
NULL AS PSTMP,
NULL AS PUSER,
NULL AS BADI,
NULL AS STAEX,
NULL AS RESLO,
NULL AS SRM_CONTRACT_ID,
NULL AS SRM_CONTRACT_ITM,
NULL AS ZZGSMNG,
NULL AS ZZ_O8_REF,
NULL AS ZZ_O8_COLOR,
NULL AS ZZ_O8_BUFFER,
NULL AS MEDKZ,
NULL AS CNFQTY,
NULL AS SGT_SCAT,
NULL AS KUNNR,
NULL AS FLG_BUNDLE,
NULL AS FSH_MPLND_ORD,
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
