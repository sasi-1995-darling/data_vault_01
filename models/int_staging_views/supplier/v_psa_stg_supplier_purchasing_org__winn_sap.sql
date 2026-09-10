---- SRC LAYER ----
WITH
SRC_S              as ( SELECT ABUEB, ACTIVITY_PROFIL, AGREL, BLIND, BOIND, BOLRE, BOPNR, BSTAE, EIKTO, EKGRP, EKORG, ERDAT, ERNAM, EXPVZ, FSH_SC_CID, FSH_VAS_DETC, GLCHANGETIME, GLDELFLAG, GLREQUEST, GLSOURCESYSTEM, INCO1, INCO2, INCO2_L, INCO3_L, INCOV, KALSK, KZABS, KZAUT, KZRET, LEBRE, LFABC, LFRHY, LIBES, LIFNR, LIPRE, LISER, LOEVM, MANDT, MEGRU, MEPRF, MINBW, MRPPP, NRGEW, PAPRF, PLIFZ, PRFRE, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, RDPRF, SKRIT, SPERM, STAGING_TIME, TELF1, TRANSPORT_CHAIN, UMSAE, VENDOR_RMA_REQ, VENSL, VERKF, VSBED, WAERS, WEBRE, XERSR, XERSY, XNBWY, ZOLLA, ZTERM, ZZBSTAE, ZZCALENDAR, ZZCMFG, ZZDANZAS, ZZDPPCT, ZZDPTYP, ZZFRMSVP, ZZQUOTE, ZZQUOTE_LAEDA, ZZQUOTE_UNAME, ZZSEGMENT, ZZSHPIND, ZZVENDKEYAC FROM {{ source('sap_ecc_prd', 'z_lfm1') }} as SRC  ),
SRC_A              as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S              as ( SELECT * FROM sap_ecc_prd.z_lfm1 )
SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        LIFNR                                                        as                                        SUPPLIER_BK
      , EKORG                                                        as                                  PURCHASING_ORG_BK
      , ZTERM                                                        as                                    PAYMENT_TERM_BK
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
      , CONVERT_TIMEZONE('UTC', TO_TIMESTAMP(
            SUBSTR(GLCHANGETIME, 1, 8) || ' ' ||
            SUBSTR(GLCHANGETIME, 9, 2) || ':' ||
            SUBSTR(GLCHANGETIME, 11, 2) || ':' ||
            SUBSTR(GLCHANGETIME, 13, 2) || '.' ||
            REGEXP_REPLACE(SUBSTR(GLCHANGETIME, 16), '^\\.', ''),
            'YYYYMMDD HH24:MI:SS.FF9'
        ))                                                           as                                  GLCHANGETIME_DTTM
      , CONVERT_TIMEZONE('UTC', IFF(PSA_DELETE_IND = 'Y',PSA_LOAD_DTS,GLCHANGETIME_DTTM)) as                                           LOAD_DTS
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
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
        SUPPLIER_BK
      , PURCHASING_ORG_BK
      , PAYMENT_TERM_BK
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
      , LOAD_DTS
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
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
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_LFM1'
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
          SUPPLIER_BK
        , PURCHASING_ORG_BK
        , PAYMENT_TERM_BK
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
        , LOAD_DTS
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , /* The PAYMENT_TERM_HK values are modified to handle the optional null default for the Hash key generation.
          This derived field prevents BKCC being included in the HK generation when the Paymern Term key is null/Blank */
            IFF(ZTERM = '', '-2', CONCAT_WS('||', ZTERM, BKCC)) as DRVD_PAYMENT_TERM_BKCC
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(LIFNR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as SUPPLIER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(DRVD_PAYMENT_TERM_BKCC as VARCHAR)),''), '^^')
        ))) as PAYMENT_TERM_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(EKORG as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PURCHASING_ORG_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(LIFNR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(EKORG as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(ZTERM as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as LNK_SUPPLIER_PURCHASING_ORG_PAYMENT_TERM_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(EKORG::text), '^^') 
            , '||', IFNULL(TRIM(ZTERM::text), '^^') 
            , '||', IFNULL(TRIM(MANDT::text), '^^') 
            , '||', IFNULL(TRIM(GLREQUEST::text), '^^') 
            , '||', IFNULL(TRIM(GLSOURCESYSTEM::text), '^^') 
            , '||', IFNULL(TRIM(ERDAT::text), '^^') 
            , '||', IFNULL(TRIM(ERNAM::text), '^^') 
            , '||', IFNULL(TRIM(SPERM::text), '^^') 
            , '||', IFNULL(TRIM(LOEVM::text), '^^') 
            , '||', IFNULL(TRIM(LFABC::text), '^^') 
            , '||', IFNULL(TRIM(WAERS::text), '^^') 
            , '||', IFNULL(TRIM(VERKF::text), '^^') 
            , '||', IFNULL(TRIM(TELF1::text), '^^') 
            , '||', IFNULL(TRIM(MINBW::text), '^^') 
            , '||', IFNULL(TRIM(INCO1::text), '^^') 
            , '||', IFNULL(TRIM(INCO2::text), '^^') 
            , '||', IFNULL(TRIM(WEBRE::text), '^^') 
            , '||', IFNULL(TRIM(KZABS::text), '^^') 
            , '||', IFNULL(TRIM(KALSK::text), '^^') 
            , '||', IFNULL(TRIM(KZAUT::text), '^^') 
            , '||', IFNULL(TRIM(EXPVZ::text), '^^') 
            , '||', IFNULL(TRIM(ZOLLA::text), '^^') 
            , '||', IFNULL(TRIM(MEPRF::text), '^^') 
            , '||', IFNULL(TRIM(EKGRP::text), '^^') 
            , '||', IFNULL(TRIM(XERSY::text), '^^') 
            , '||', IFNULL(TRIM(PLIFZ::text), '^^') 
            , '||', IFNULL(TRIM(MRPPP::text), '^^') 
            , '||', IFNULL(TRIM(LFRHY::text), '^^') 
            , '||', IFNULL(TRIM(LIBES::text), '^^') 
            , '||', IFNULL(TRIM(LIPRE::text), '^^') 
            , '||', IFNULL(TRIM(LISER::text), '^^') 
            , '||', IFNULL(TRIM(INCOV::text), '^^') 
            , '||', IFNULL(TRIM(INCO2_L::text), '^^') 
            , '||', IFNULL(TRIM(INCO3_L::text), '^^') 
            , '||', IFNULL(TRIM(PRFRE::text), '^^') 
            , '||', IFNULL(TRIM(NRGEW::text), '^^') 
            , '||', IFNULL(TRIM(BOIND::text), '^^') 
            , '||', IFNULL(TRIM(BLIND::text), '^^') 
            , '||', IFNULL(TRIM(KZRET::text), '^^') 
            , '||', IFNULL(TRIM(SKRIT::text), '^^') 
            , '||', IFNULL(TRIM(BSTAE::text), '^^') 
            , '||', IFNULL(TRIM(RDPRF::text), '^^') 
            , '||', IFNULL(TRIM(MEGRU::text), '^^') 
            , '||', IFNULL(TRIM(VENSL::text), '^^') 
            , '||', IFNULL(TRIM(BOPNR::text), '^^') 
            , '||', IFNULL(TRIM(XERSR::text), '^^') 
            , '||', IFNULL(TRIM(EIKTO::text), '^^') 
            , '||', IFNULL(TRIM(ABUEB::text), '^^') 
            , '||', IFNULL(TRIM(PAPRF::text), '^^') 
            , '||', IFNULL(TRIM(AGREL::text), '^^') 
            , '||', IFNULL(TRIM(XNBWY::text), '^^') 
            , '||', IFNULL(TRIM(VSBED::text), '^^') 
            , '||', IFNULL(TRIM(LEBRE::text), '^^') 
            , '||', IFNULL(TRIM(BOLRE::text), '^^') 
            , '||', IFNULL(TRIM(UMSAE::text), '^^') 
            , '||', IFNULL(TRIM(VENDOR_RMA_REQ::text), '^^') 
            , '||', IFNULL(TRIM(FSH_SC_CID::text), '^^') 
            , '||', IFNULL(TRIM(FSH_VAS_DETC::text), '^^') 
            , '||', IFNULL(TRIM(ACTIVITY_PROFIL::text), '^^') 
            , '||', IFNULL(TRIM(TRANSPORT_CHAIN::text), '^^') 
            , '||', IFNULL(TRIM(STAGING_TIME::text), '^^') 
            , '||', IFNULL(TRIM(ZZDANZAS::text), '^^') 
            , '||', IFNULL(TRIM(ZZSEGMENT::text), '^^') 
            , '||', IFNULL(TRIM(ZZVENDKEYAC::text), '^^') 
            , '||', IFNULL(TRIM(ZZQUOTE::text), '^^') 
            , '||', IFNULL(TRIM(ZZQUOTE_UNAME::text), '^^') 
            , '||', IFNULL(TRIM(ZZQUOTE_LAEDA::text), '^^') 
            , '||', IFNULL(TRIM(ZZCALENDAR::text), '^^') 
            , '||', IFNULL(TRIM(ZZSHPIND::text), '^^') 
            , '||', IFNULL(TRIM(ZZFRMSVP::text), '^^') 
            , '||', IFNULL(TRIM(ZZBSTAE::text), '^^') 
            , '||', IFNULL(TRIM(ZZDPTYP::text), '^^') 
            , '||', IFNULL(TRIM(ZZDPPCT::text), '^^') 
            , '||', IFNULL(TRIM(ZZCMFG::text), '^^') 
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
