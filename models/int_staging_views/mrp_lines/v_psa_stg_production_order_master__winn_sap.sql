---- SRC LAYER ----
WITH
SRC_v              as ( SELECT * FROM {{ source('sap_ecc_prd', 'z_aufk') }} as SRC  ),
SRC_bkcc           as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_v              as ( SELECT * FROM sap_ecc_prd.z_aufk )
, SRC_bkcc           as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_v as (
    SELECT
        AUFNR                                                        as                                PRODUCTION_ORDER_BK
      , MANDT
      , AUFNR
      , GLREQUEST
      , AUART
      , AUTYP
      , REFNR
      , ERNAM
      , ERDAT
      , AENAM
      , AEDAT
      , KTEXT
      , LTEXT
      , BUKRS
      , WERKS
      , GSBER
      , KOKRS
      , CCKEY
      , KOSTV
      , STORT
      , SOWRK
      , ASTKZ
      , WAERS
      , ASTNR
      , STDAT
      , ESTNR
      , PHAS0
      , PHAS1
      , PHAS2
      , PHAS3
      , PDAT1
      , PDAT2
      , PDAT3
      , IDAT1
      , IDAT2
      , IDAT3
      , OBJID
      , VOGRP
      , LOEKZ
      , PLGKZ
      , KVEWE
      , KAPPL
      , KALSM
      , ZSCHL
      , ABKRS
      , KSTAR
      , KOSTL
      , SAKNR
      , SETNM
      , CYCLE
      , SDATE
      , SEQNR
      , USER0
      , USER1
      , USER2
      , USER3
      , USER4
      , USER5
      , USER6
      , USER7
      , USER8
      , USER9
      , OBJNR
      , PRCTR
      , PSPEL
      , AWSLS
      , ABGSL
      , TXJCD
      , FUNC_AREA
      , SCOPE
      , PLINT
      , KDAUF
      , KDPOS
      , AUFEX
      , IVPRO
      , LOGSYSTEM
      , FLG_MLTPS
      , ABUKR
      , AKSTL
      , SIZECL
      , IZWEK
      , UMWKZ
      , KSTEMPF
      , ZSCHM
      , PKOSA
      , ANFAUFNR
      , PROCNR
      , PROTY
      , RSORD
      , BEMOT
      , ADRNRA
      , ERFZEIT
      , AEZEIT
      , CSTG_VRNT
      , COSTESTNR
      , VERAA_USER
      , ZZ_FUND_TYPE
      , ZZ_USE_COST
      , ZZ_O8_REF
      , ZZ_O8_COLOR
      , ZZ_O8_BUFFER
      , VNAME
      , RECID
      , ETYPE
      , OTYPE
      , JV_JIBCL
      , JV_JIBSA
      , JV_OCO
      , "/CUM/INDCU"
      , "/CUM/CMNUM"
      , "/CUM/AUEST"
      , "/CUM/DESNUM"
      , VAPLZ
      , WAWRK
      , FERC_IND
      , CLAIM_CONTROL
      , UPDATE_NEEDED
      , UPDATE_CONTROL
      , GLDELFLAG
      , GLSOURCESYSTEM
      , GLCHANGETIME
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
    FROM SRC_v
)

, LOGIC_bkcc as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_bkcc
)
---- RENAME LAYER ----

, RENAME_v as (
    SELECT
        PRODUCTION_ORDER_BK
      , MANDT
      , AUFNR
      , GLREQUEST
      , AUART
      , AUTYP
      , REFNR
      , ERNAM
      , ERDAT
      , AENAM
      , AEDAT
      , KTEXT
      , LTEXT
      , BUKRS
      , WERKS
      , GSBER
      , KOKRS
      , CCKEY
      , KOSTV
      , STORT
      , SOWRK
      , ASTKZ
      , WAERS
      , ASTNR
      , STDAT
      , ESTNR
      , PHAS0
      , PHAS1
      , PHAS2
      , PHAS3
      , PDAT1
      , PDAT2
      , PDAT3
      , IDAT1
      , IDAT2
      , IDAT3
      , OBJID
      , VOGRP
      , LOEKZ
      , PLGKZ
      , KVEWE
      , KAPPL
      , KALSM
      , ZSCHL
      , ABKRS
      , KSTAR
      , KOSTL
      , SAKNR
      , SETNM
      , CYCLE
      , SDATE
      , SEQNR
      , USER0
      , USER1
      , USER2
      , USER3
      , USER4
      , USER5
      , USER6
      , USER7
      , USER8
      , USER9
      , OBJNR
      , PRCTR
      , PSPEL
      , AWSLS
      , ABGSL
      , TXJCD
      , FUNC_AREA
      , SCOPE
      , PLINT
      , KDAUF
      , KDPOS
      , AUFEX
      , IVPRO
      , LOGSYSTEM
      , FLG_MLTPS
      , ABUKR
      , AKSTL
      , SIZECL
      , IZWEK
      , UMWKZ
      , KSTEMPF
      , ZSCHM
      , PKOSA
      , ANFAUFNR
      , PROCNR
      , PROTY
      , RSORD
      , BEMOT
      , ADRNRA
      , ERFZEIT
      , AEZEIT
      , CSTG_VRNT
      , COSTESTNR
      , VERAA_USER
      , ZZ_FUND_TYPE
      , ZZ_USE_COST
      , ZZ_O8_REF
      , ZZ_O8_COLOR
      , ZZ_O8_BUFFER
      , VNAME
      , RECID
      , ETYPE
      , OTYPE
      , JV_JIBCL
      , JV_JIBSA
      , JV_OCO
      , "/CUM/INDCU"
      , "/CUM/CMNUM"
      , "/CUM/AUEST"
      , "/CUM/DESNUM"
      , VAPLZ
      , WAWRK
      , FERC_IND
      , CLAIM_CONTROL
      , UPDATE_NEEDED
      , UPDATE_CONTROL
      , GLDELFLAG
      , GLSOURCESYSTEM
      , GLCHANGETIME
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
    FROM LOGIC_v
)

, RENAME_bkcc as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_bkcc
)
---- FILTER LAYER ----

, FILTER_v as (
    SELECT *
    FROM RENAME_v
)

, FILTER_bkcc as (
    SELECT *
    FROM RENAME_bkcc
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_AUFK'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_v
    INNER JOIN FILTER_bkcc
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          PRODUCTION_ORDER_BK
        , MANDT
        , AUFNR
        , GLREQUEST
        , AUART
        , AUTYP
        , REFNR
        , ERNAM
        , ERDAT
        , AENAM
        , AEDAT
        , KTEXT
        , LTEXT
        , BUKRS
        , WERKS
        , GSBER
        , KOKRS
        , CCKEY
        , KOSTV
        , STORT
        , SOWRK
        , ASTKZ
        , WAERS
        , ASTNR
        , STDAT
        , ESTNR
        , PHAS0
        , PHAS1
        , PHAS2
        , PHAS3
        , PDAT1
        , PDAT2
        , PDAT3
        , IDAT1
        , IDAT2
        , IDAT3
        , OBJID
        , VOGRP
        , LOEKZ
        , PLGKZ
        , KVEWE
        , KAPPL
        , KALSM
        , ZSCHL
        , ABKRS
        , KSTAR
        , KOSTL
        , SAKNR
        , SETNM
        , CYCLE
        , SDATE
        , SEQNR
        , USER0
        , USER1
        , USER2
        , USER3
        , USER4
        , USER5
        , USER6
        , USER7
        , USER8
        , USER9
        , OBJNR
        , PRCTR
        , PSPEL
        , AWSLS
        , ABGSL
        , TXJCD
        , FUNC_AREA
        , SCOPE
        , PLINT
        , KDAUF
        , KDPOS
        , AUFEX
        , IVPRO
        , LOGSYSTEM
        , FLG_MLTPS
        , ABUKR
        , AKSTL
        , SIZECL
        , IZWEK
        , UMWKZ
        , KSTEMPF
        , ZSCHM
        , PKOSA
        , ANFAUFNR
        , PROCNR
        , PROTY
        , RSORD
        , BEMOT
        , ADRNRA
        , ERFZEIT
        , AEZEIT
        , CSTG_VRNT
        , COSTESTNR
        , VERAA_USER
        , ZZ_FUND_TYPE
        , ZZ_USE_COST
        , ZZ_O8_REF
        , ZZ_O8_COLOR
        , ZZ_O8_BUFFER
        , VNAME
        , RECID
        , ETYPE
        , OTYPE
        , JV_JIBCL
        , JV_JIBSA
        , JV_OCO
        , "/CUM/INDCU"
        , "/CUM/CMNUM"
        , "/CUM/AUEST"
        , "/CUM/DESNUM"
        , VAPLZ
        , WAWRK
        , FERC_IND
        , CLAIM_CONTROL
        , UPDATE_NEEDED
        , UPDATE_CONTROL
        , GLDELFLAG
        , GLSOURCESYSTEM
        , GLCHANGETIME
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , CONVERT_TIMEZONE('UTC', IFF(
            PSA_DELETE_IND = 'Y',
            PSA_LOAD_DTS,
            TO_TIMESTAMP(
            SUBSTR(GLCHANGETIME, 1, 8) || ' ' ||
            SUBSTR(GLCHANGETIME, 9, 2) || ':' ||
            SUBSTR(GLCHANGETIME, 11, 2) || ':' ||
            SUBSTR(GLCHANGETIME, 13, 2) || '.' ||
            REGEXP_REPLACE(SUBSTR(GLCHANGETIME, 16), '^\\.', ''),
            'YYYYMMDD HH24:MI:SS.FF9'
            )
        ))                                                           as                                           LOAD_DTS
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(MANDT::text), '^^') 
            , '||', IFNULL(TRIM(AUART::text), '^^') 
            , '||', IFNULL(TRIM(AUTYP::text), '^^') 
            , '||', IFNULL(TRIM(REFNR::text), '^^') 
            , '||', IFNULL(TRIM(ERNAM::text), '^^') 
            , '||', IFNULL(TRIM(ERDAT::text), '^^') 
            , '||', IFNULL(TRIM(AENAM::text), '^^') 
            , '||', IFNULL(TRIM(AEDAT::text), '^^') 
            , '||', IFNULL(TRIM(KTEXT::text), '^^') 
            , '||', IFNULL(TRIM(LTEXT::text), '^^') 
            , '||', IFNULL(TRIM(BUKRS::text), '^^') 
            , '||', IFNULL(TRIM(WERKS::text), '^^') 
            , '||', IFNULL(TRIM(GSBER::text), '^^') 
            , '||', IFNULL(TRIM(KOKRS::text), '^^') 
            , '||', IFNULL(TRIM(CCKEY::text), '^^') 
            , '||', IFNULL(TRIM(KOSTV::text), '^^') 
            , '||', IFNULL(TRIM(STORT::text), '^^') 
            , '||', IFNULL(TRIM(SOWRK::text), '^^') 
            , '||', IFNULL(TRIM(ASTKZ::text), '^^') 
            , '||', IFNULL(TRIM(WAERS::text), '^^') 
            , '||', IFNULL(TRIM(ASTNR::text), '^^') 
            , '||', IFNULL(TRIM(STDAT::text), '^^') 
            , '||', IFNULL(TRIM(ESTNR::text), '^^') 
            , '||', IFNULL(TRIM(PHAS0::text), '^^') 
            , '||', IFNULL(TRIM(PHAS1::text), '^^') 
            , '||', IFNULL(TRIM(PHAS2::text), '^^') 
            , '||', IFNULL(TRIM(PHAS3::text), '^^') 
            , '||', IFNULL(TRIM(PDAT1::text), '^^') 
            , '||', IFNULL(TRIM(PDAT2::text), '^^') 
            , '||', IFNULL(TRIM(PDAT3::text), '^^') 
            , '||', IFNULL(TRIM(IDAT1::text), '^^') 
            , '||', IFNULL(TRIM(IDAT2::text), '^^') 
            , '||', IFNULL(TRIM(IDAT3::text), '^^') 
            , '||', IFNULL(TRIM(OBJID::text), '^^') 
            , '||', IFNULL(TRIM(VOGRP::text), '^^') 
            , '||', IFNULL(TRIM(LOEKZ::text), '^^') 
            , '||', IFNULL(TRIM(PLGKZ::text), '^^') 
            , '||', IFNULL(TRIM(KVEWE::text), '^^') 
            , '||', IFNULL(TRIM(KAPPL::text), '^^') 
            , '||', IFNULL(TRIM(KALSM::text), '^^') 
            , '||', IFNULL(TRIM(ZSCHL::text), '^^') 
            , '||', IFNULL(TRIM(ABKRS::text), '^^') 
            , '||', IFNULL(TRIM(KSTAR::text), '^^') 
            , '||', IFNULL(TRIM(KOSTL::text), '^^') 
            , '||', IFNULL(TRIM(SAKNR::text), '^^') 
            , '||', IFNULL(TRIM(SETNM::text), '^^') 
            , '||', IFNULL(TRIM(CYCLE::text), '^^') 
            , '||', IFNULL(TRIM(SDATE::text), '^^') 
            , '||', IFNULL(TRIM(SEQNR::text), '^^') 
            , '||', IFNULL(TRIM(USER0::text), '^^') 
            , '||', IFNULL(TRIM(USER1::text), '^^') 
            , '||', IFNULL(TRIM(USER2::text), '^^') 
            , '||', IFNULL(TRIM(USER3::text), '^^') 
            , '||', IFNULL(TRIM(USER4::text), '^^') 
            , '||', IFNULL(TRIM(USER5::text), '^^') 
            , '||', IFNULL(TRIM(USER6::text), '^^') 
            , '||', IFNULL(TRIM(USER7::text), '^^') 
            , '||', IFNULL(TRIM(USER8::text), '^^') 
            , '||', IFNULL(TRIM(USER9::text), '^^') 
            , '||', IFNULL(TRIM(OBJNR::text), '^^') 
            , '||', IFNULL(TRIM(PRCTR::text), '^^') 
            , '||', IFNULL(TRIM(PSPEL::text), '^^') 
            , '||', IFNULL(TRIM(AWSLS::text), '^^') 
            , '||', IFNULL(TRIM(ABGSL::text), '^^') 
            , '||', IFNULL(TRIM(TXJCD::text), '^^') 
            , '||', IFNULL(TRIM(FUNC_AREA::text), '^^') 
            , '||', IFNULL(TRIM(SCOPE::text), '^^') 
            , '||', IFNULL(TRIM(PLINT::text), '^^') 
            , '||', IFNULL(TRIM(KDAUF::text), '^^') 
            , '||', IFNULL(TRIM(KDPOS::text), '^^') 
            , '||', IFNULL(TRIM(AUFEX::text), '^^') 
            , '||', IFNULL(TRIM(IVPRO::text), '^^') 
            , '||', IFNULL(TRIM(LOGSYSTEM::text), '^^') 
            , '||', IFNULL(TRIM(FLG_MLTPS::text), '^^') 
            , '||', IFNULL(TRIM(ABUKR::text), '^^') 
            , '||', IFNULL(TRIM(AKSTL::text), '^^') 
            , '||', IFNULL(TRIM(SIZECL::text), '^^') 
            , '||', IFNULL(TRIM(IZWEK::text), '^^') 
            , '||', IFNULL(TRIM(UMWKZ::text), '^^') 
            , '||', IFNULL(TRIM(KSTEMPF::text), '^^') 
            , '||', IFNULL(TRIM(ZSCHM::text), '^^') 
            , '||', IFNULL(TRIM(PKOSA::text), '^^') 
            , '||', IFNULL(TRIM(ANFAUFNR::text), '^^') 
            , '||', IFNULL(TRIM(PROCNR::text), '^^') 
            , '||', IFNULL(TRIM(PROTY::text), '^^') 
            , '||', IFNULL(TRIM(RSORD::text), '^^') 
            , '||', IFNULL(TRIM(BEMOT::text), '^^') 
            , '||', IFNULL(TRIM(ADRNRA::text), '^^') 
            , '||', IFNULL(TRIM(ERFZEIT::text), '^^') 
            , '||', IFNULL(TRIM(AEZEIT::text), '^^') 
            , '||', IFNULL(TRIM(CSTG_VRNT::text), '^^') 
            , '||', IFNULL(TRIM(COSTESTNR::text), '^^') 
            , '||', IFNULL(TRIM(VERAA_USER::text), '^^') 
            , '||', IFNULL(TRIM(ZZ_FUND_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(ZZ_USE_COST::text), '^^') 
            , '||', IFNULL(TRIM(ZZ_O8_REF::text), '^^') 
            , '||', IFNULL(TRIM(ZZ_O8_COLOR::text), '^^') 
            , '||', IFNULL(TRIM(ZZ_O8_BUFFER::text), '^^') 
            , '||', IFNULL(TRIM(VNAME::text), '^^') 
            , '||', IFNULL(TRIM(RECID::text), '^^') 
            , '||', IFNULL(TRIM(ETYPE::text), '^^') 
            , '||', IFNULL(TRIM(OTYPE::text), '^^') 
            , '||', IFNULL(TRIM(JV_JIBCL::text), '^^') 
            , '||', IFNULL(TRIM(JV_JIBSA::text), '^^') 
            , '||', IFNULL(TRIM(JV_OCO::text), '^^') 
            , '||', IFNULL(TRIM("/CUM/INDCU"::text), '^^') 
            , '||', IFNULL(TRIM("/CUM/CMNUM"::text), '^^') 
            , '||', IFNULL(TRIM("/CUM/AUEST"::text), '^^') 
            , '||', IFNULL(TRIM("/CUM/DESNUM"::text), '^^') 
            , '||', IFNULL(TRIM(VAPLZ::text), '^^') 
            , '||', IFNULL(TRIM(WAWRK::text), '^^') 
            , '||', IFNULL(TRIM(FERC_IND::text), '^^') 
            , '||', IFNULL(TRIM(CLAIM_CONTROL::text), '^^') 
            , '||', IFNULL(TRIM(UPDATE_NEEDED::text), '^^') 
            , '||', IFNULL(TRIM(UPDATE_CONTROL::text), '^^') 
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
