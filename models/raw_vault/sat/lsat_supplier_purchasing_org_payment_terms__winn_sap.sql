---- SRC LAYER ----
WITH
SRC_swinn          as ( SELECT * FROM {{ ref('v_psa_stg_supplier_purchasing_org__winn_sap') }} as SRC 
{% if is_incremental() %}
      where src.load_dts > (select dateadd('HOUR',-1,max(load_dts)) from {{ this }})
    {% endif %} )

/*
SRC_swinn          as ( SELECT * FROM staging.v_psa_stg_supplier_purchasing_org__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_swinn as (
    SELECT
        LNK_SUPPLIER_PURCHASING_ORG_PAYMENT_TERM_HK
      , LIFNR
      , EKORG
      , ZTERM
      , MANDT
      , GLREQUEST
      , GLSOURCESYSTEM
      , ERDAT
      , ERNAM
      , SPERM
      , LOEVM
      , LFABC
      , WAERS
      , VERKF
      , TELF1
      , MINBW
      , INCO1
      , INCO2
      , WEBRE
      , KZABS
      , KALSK
      , KZAUT
      , EXPVZ
      , ZOLLA
      , MEPRF
      , EKGRP
      , XERSY
      , PLIFZ
      , MRPPP
      , LFRHY
      , LIBES
      , LIPRE
      , LISER
      , INCOV
      , INCO2_L
      , INCO3_L
      , PRFRE
      , NRGEW
      , BOIND
      , BLIND
      , KZRET
      , SKRIT
      , BSTAE
      , RDPRF
      , MEGRU
      , VENSL
      , BOPNR
      , XERSR
      , EIKTO
      , ABUEB
      , PAPRF
      , AGREL
      , XNBWY
      , VSBED
      , LEBRE
      , BOLRE
      , UMSAE
      , VENDOR_RMA_REQ
      , FSH_SC_CID
      , FSH_VAS_DETC
      , ACTIVITY_PROFIL
      , TRANSPORT_CHAIN
      , STAGING_TIME
      , ZZDANZAS
      , ZZSEGMENT
      , ZZVENDKEYAC
      , ZZQUOTE
      , ZZQUOTE_UNAME
      , ZZQUOTE_LAEDA
      , ZZCALENDAR
      , ZZSHPIND
      , ZZFRMSVP
      , ZZBSTAE
      , ZZDPTYP
      , ZZDPPCT
      , ZZCMFG
      , GLDELFLAG
      , GLCHANGETIME
      , GLCHANGETIME_DTTM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM SRC_swinn
)
---- RENAME LAYER ----

, RENAME_swinn as (
    SELECT
        LNK_SUPPLIER_PURCHASING_ORG_PAYMENT_TERM_HK
      , LIFNR
      , EKORG
      , ZTERM
      , MANDT
      , GLREQUEST
      , GLSOURCESYSTEM
      , ERDAT
      , ERNAM
      , SPERM
      , LOEVM
      , LFABC
      , WAERS
      , VERKF
      , TELF1
      , MINBW
      , INCO1
      , INCO2
      , WEBRE
      , KZABS
      , KALSK
      , KZAUT
      , EXPVZ
      , ZOLLA
      , MEPRF
      , EKGRP
      , XERSY
      , PLIFZ
      , MRPPP
      , LFRHY
      , LIBES
      , LIPRE
      , LISER
      , INCOV
      , INCO2_L
      , INCO3_L
      , PRFRE
      , NRGEW
      , BOIND
      , BLIND
      , KZRET
      , SKRIT
      , BSTAE
      , RDPRF
      , MEGRU
      , VENSL
      , BOPNR
      , XERSR
      , EIKTO
      , ABUEB
      , PAPRF
      , AGREL
      , XNBWY
      , VSBED
      , LEBRE
      , BOLRE
      , UMSAE
      , VENDOR_RMA_REQ
      , FSH_SC_CID
      , FSH_VAS_DETC
      , ACTIVITY_PROFIL
      , TRANSPORT_CHAIN
      , STAGING_TIME
      , ZZDANZAS
      , ZZSEGMENT
      , ZZVENDKEYAC
      , ZZQUOTE
      , ZZQUOTE_UNAME
      , ZZQUOTE_LAEDA
      , ZZCALENDAR
      , ZZSHPIND
      , ZZFRMSVP
      , ZZBSTAE
      , ZZDPTYP
      , ZZDPPCT
      , ZZCMFG
      , GLDELFLAG
      , GLCHANGETIME
      , GLCHANGETIME_DTTM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM LOGIC_swinn
)
---- FILTER LAYER ----

, FILTER_swinn as (
    SELECT *
    FROM RENAME_swinn
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_swinn
)

---- FINAL LAYER ----
SELECT
          LNK_SUPPLIER_PURCHASING_ORG_PAYMENT_TERM_HK
        , LIFNR
        , EKORG
        , ZTERM
        , MANDT
        , GLREQUEST
        , GLSOURCESYSTEM
        , ERDAT
        , ERNAM
        , SPERM
        , LOEVM
        , LFABC
        , WAERS
        , VERKF
        , TELF1
        , MINBW
        , INCO1
        , INCO2
        , WEBRE
        , KZABS
        , KALSK
        , KZAUT
        , EXPVZ
        , ZOLLA
        , MEPRF
        , EKGRP
        , XERSY
        , PLIFZ
        , MRPPP
        , LFRHY
        , LIBES
        , LIPRE
        , LISER
        , INCOV
        , INCO2_L
        , INCO3_L
        , PRFRE
        , NRGEW
        , BOIND
        , BLIND
        , KZRET
        , SKRIT
        , BSTAE
        , RDPRF
        , MEGRU
        , VENSL
        , BOPNR
        , XERSR
        , EIKTO
        , ABUEB
        , PAPRF
        , AGREL
        , XNBWY
        , VSBED
        , LEBRE
        , BOLRE
        , UMSAE
        , VENDOR_RMA_REQ
        , FSH_SC_CID
        , FSH_VAS_DETC
        , ACTIVITY_PROFIL
        , TRANSPORT_CHAIN
        , STAGING_TIME
        , ZZDANZAS
        , ZZSEGMENT
        , ZZVENDKEYAC
        , ZZQUOTE
        , ZZQUOTE_UNAME
        , ZZQUOTE_LAEDA
        , ZZCALENDAR
        , ZZSHPIND
        , ZZFRMSVP
        , ZZBSTAE
        , ZZDPTYP
        , ZZDPPCT
        , ZZCMFG
        , GLDELFLAG
        , GLCHANGETIME
        , GLCHANGETIME_DTTM
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , HASHDIFF
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.LNK_SUPPLIER_PURCHASING_ORG_PAYMENT_TERM_HK = JOIN_RESULT.LNK_SUPPLIER_PURCHASING_ORG_PAYMENT_TERM_HK
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %}
{% if not is_incremental() %}

/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per HK and hashdiff. */
qualify 1 = row_number() over (partition by LNK_SUPPLIER_PURCHASING_ORG_PAYMENT_TERM_HK, HASHDIFF order by PSA_LOAD_DTS)

union all
SELECT 
MD5_BINARY(GR.VALUE) AS LNK_SUPPLIER_PURCHASING_ORG_PAYMENT_TERM_HK,
GR.VALUE::text AS LIFNR,
NULL AS EKORG,
NULL AS ZTERM,
NULL AS MANDT,
NULL AS GLREQUEST,
NULL AS GLSOURCESYSTEM,
NULL AS ERDAT,
NULL AS ERNAM,
NULL AS SPERM,
NULL AS LOEVM,
NULL AS LFABC,
NULL AS WAERS,
NULL AS VERKF,
NULL AS TELF1,
NULL AS MINBW,
NULL AS INCO1,
NULL AS INCO2,
NULL AS WEBRE,
NULL AS KZABS,
NULL AS KALSK,
NULL AS KZAUT,
NULL AS EXPVZ,
NULL AS ZOLLA,
NULL AS MEPRF,
NULL AS EKGRP,
NULL AS XERSY,
NULL AS PLIFZ,
NULL AS MRPPP,
NULL AS LFRHY,
NULL AS LIBES,
NULL AS LIPRE,
NULL AS LISER,
NULL AS INCOV,
NULL AS INCO2_L,
NULL AS INCO3_L,
NULL AS PRFRE,
NULL AS NRGEW,
NULL AS BOIND,
NULL AS BLIND,
NULL AS KZRET,
NULL AS SKRIT,
NULL AS BSTAE,
NULL AS RDPRF,
NULL AS MEGRU,
NULL AS VENSL,
NULL AS BOPNR,
NULL AS XERSR,
NULL AS EIKTO,
NULL AS ABUEB,
NULL AS PAPRF,
NULL AS AGREL,
NULL AS XNBWY,
NULL AS VSBED,
NULL AS LEBRE,
NULL AS BOLRE,
NULL AS UMSAE,
NULL AS VENDOR_RMA_REQ,
NULL AS FSH_SC_CID,
NULL AS FSH_VAS_DETC,
NULL AS ACTIVITY_PROFIL,
NULL AS TRANSPORT_CHAIN,
NULL AS STAGING_TIME,
NULL AS ZZDANZAS,
NULL AS ZZSEGMENT,
NULL AS ZZVENDKEYAC,
NULL AS ZZQUOTE,
NULL AS ZZQUOTE_UNAME,
NULL AS ZZQUOTE_LAEDA,
NULL AS ZZCALENDAR,
NULL AS ZZSHPIND,
NULL AS ZZFRMSVP,
NULL AS ZZBSTAE,
NULL AS ZZDPTYP,
NULL AS ZZDPPCT,
NULL AS ZZCMFG,
NULL AS GLDELFLAG,
NULL AS GLCHANGETIME,
NULL AS GLCHANGETIME_DTTM,
'1900-01-01'::TIMESTAMP AS PSA_LOAD_DTS,
NULL AS PSA_RECORD_SOURCE,
'N' AS PSA_DELETE_IND,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC,
DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC,
''::BINARY AS HASHDIFF
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
