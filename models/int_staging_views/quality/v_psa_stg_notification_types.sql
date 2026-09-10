---- SRC LAYER ----
WITH
SRC_a              as ( SELECT * FROM {{ source('sap_ecc_prd', 'z_tq80') }} as SRC  ),
SRC_b              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_a              as ( SELECT * FROM SAP_ECC_PRD.Z_TQ80 )
, SRC_b              as ( SELECT * FROM RAW_VAULT.REF_BUSINESS_KEY_COLLISION )
*/
---- LOGIC LAYER ----

, LOGIC_a as (
    SELECT
        QMART
      , MANDT
      , GLREQUEST
      , QMTYP
      , RBNR
      , HERKZ
      , BEZZT
      , QMNUK
      , AUART
      , HSCRTP
      , OSCRTP
      , PSCRTP
      , PARGR
      , STSMA
      , SMSTSMA
      , ARTPR
      , SDAUART
      , COAUART
      , PARVW_KUND
      , PARVW_AP
      , PARVW_INT
      , PARVW_LIEF
      , PARVW_HER
      , PARVW_VERA
      , PARVW_AUTO
      , PARVW_QMSM
      , KLAKT
      , INFO_WIND
      , SERWI
      , ESCAL
      , FEKAT
      , URKAT
      , MAKAT
      , MFKAT
      , OTKAT
      , SAKAT
      , STAFO
      , QMWAERS
      , QMWERT
      , FBS_CREATE
      , FBS_DYNNR
      , TDFORMAT
      , KZEILE
      , USERSCR1
      , USERSCR2
      , USERSCR3
      , USERSCR4
      , USERSCR5
      , QMLTXT01
      , QMLTXT02
      , AUART2
      , EARLY_NUM
      , AUTOM_CONT
      , MATKZ
      , KUKZ
      , MATKUKZ
      , LIKZ
      , MATLIKZ
      , MATCHKZ
      , MATCHKUKZ
      , MATCHLIKZ
      , FEGRPKZ
      , FECODKZ
      , FOGRPKZ
      , FOCODKZ
      , MOD
      , ICON1
      , ICON2
      , VERS
      , ZEITRAUM
      , TDOBJECT
      , TDNAME
      , TDID
      , CMCHECK_SM
      , CMGRA
      , PARVW_PAGE
      , CUA_FBS
      , ROLE_VERA
      , PERMIT
      , PARVW_GEH
      , ROLE_GEH
      , ROLE_QMSM
      , PROCESS
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , CONVERT_TIMEZONE('UTC', PSA_LOAD_DTS)                          as                                  LOAD_DTS
    FROM SRC_a
)

, LOGIC_b as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_b
)
---- RENAME LAYER ----

, RENAME_a as (
    SELECT
        MANDT
      , QMART
      , GLREQUEST
      , QMTYP
      , RBNR
      , HERKZ
      , BEZZT
      , QMNUK
      , AUART
      , HSCRTP
      , OSCRTP
      , PSCRTP
      , PARGR
      , STSMA
      , SMSTSMA
      , ARTPR
      , SDAUART
      , COAUART
      , PARVW_KUND
      , PARVW_AP
      , PARVW_INT
      , PARVW_LIEF
      , PARVW_HER
      , PARVW_VERA
      , PARVW_AUTO
      , PARVW_QMSM
      , KLAKT
      , INFO_WIND
      , SERWI
      , ESCAL
      , FEKAT
      , URKAT
      , MAKAT
      , MFKAT
      , OTKAT
      , SAKAT
      , STAFO
      , QMWAERS
      , QMWERT
      , FBS_CREATE
      , FBS_DYNNR
      , TDFORMAT
      , KZEILE
      , USERSCR1
      , USERSCR2
      , USERSCR3
      , USERSCR4
      , USERSCR5
      , QMLTXT01
      , QMLTXT02
      , AUART2
      , EARLY_NUM
      , AUTOM_CONT
      , MATKZ
      , KUKZ
      , MATKUKZ
      , LIKZ
      , MATLIKZ
      , MATCHKZ
      , MATCHKUKZ
      , MATCHLIKZ
      , FEGRPKZ
      , FECODKZ
      , FOGRPKZ
      , FOCODKZ
      , MOD
      , ICON1
      , ICON2
      , VERS
      , ZEITRAUM
      , TDOBJECT
      , TDNAME
      , TDID
      , CMCHECK_SM
      , CMGRA
      , PARVW_PAGE
      , CUA_FBS
      , ROLE_VERA
      , PERMIT
      , PARVW_GEH
      , ROLE_GEH
      , ROLE_QMSM
      , PROCESS
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , LOAD_DTS
    FROM LOGIC_a
)

, RENAME_b as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_b
)
---- FILTER LAYER ----

, FILTER_a as (
    SELECT *
    FROM RENAME_a
)

, FILTER_b as (
    SELECT *
    FROM RENAME_b
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_TQ80'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_a
    INNER JOIN FILTER_b
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          MANDT
        , QMART
        , GLREQUEST
        , QMTYP
        , RBNR
        , HERKZ
        , BEZZT
        , QMNUK
        , AUART
        , HSCRTP
        , OSCRTP
        , PSCRTP
        , PARGR
        , STSMA
        , SMSTSMA
        , ARTPR
        , SDAUART
        , COAUART
        , PARVW_KUND
        , PARVW_AP
        , PARVW_INT
        , PARVW_LIEF
        , PARVW_HER
        , PARVW_VERA
        , PARVW_AUTO
        , PARVW_QMSM
        , KLAKT
        , INFO_WIND
        , SERWI
        , ESCAL
        , FEKAT
        , URKAT
        , MAKAT
        , MFKAT
        , OTKAT
        , SAKAT
        , STAFO
        , QMWAERS
        , QMWERT
        , FBS_CREATE
        , FBS_DYNNR
        , TDFORMAT
        , KZEILE
        , USERSCR1
        , USERSCR2
        , USERSCR3
        , USERSCR4
        , USERSCR5
        , QMLTXT01
        , QMLTXT02
        , AUART2
        , EARLY_NUM
        , AUTOM_CONT
        , MATKZ
        , KUKZ
        , MATKUKZ
        , LIKZ
        , MATLIKZ
        , MATCHKZ
        , MATCHKUKZ
        , MATCHLIKZ
        , FEGRPKZ
        , FECODKZ
        , FOGRPKZ
        , FOCODKZ
        , MOD
        , ICON1
        , ICON2
        , VERS
        , ZEITRAUM
        , TDOBJECT
        , TDNAME
        , TDID
        , CMCHECK_SM
        , CMGRA
        , PARVW_PAGE
        , CUA_FBS
        , ROLE_VERA
        , PERMIT
        , PARVW_GEH
        , ROLE_GEH
        , ROLE_QMSM
        , PROCESS
        , GLDELFLAG
        , GLCHANGETIME
        , GLSOURCESYSTEM
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(MANDT::text), '^^') 
            , '||', IFNULL(TRIM(QMART::text), '^^') 
            , '||', IFNULL(TRIM(GLREQUEST::text), '^^') 
            , '||', IFNULL(TRIM(QMTYP::text), '^^') 
            , '||', IFNULL(TRIM(RBNR::text), '^^') 
            , '||', IFNULL(TRIM(HERKZ::text), '^^') 
            , '||', IFNULL(TRIM(BEZZT::text), '^^') 
            , '||', IFNULL(TRIM(QMNUK::text), '^^') 
            , '||', IFNULL(TRIM(AUART::text), '^^') 
            , '||', IFNULL(TRIM(HSCRTP::text), '^^') 
            , '||', IFNULL(TRIM(OSCRTP::text), '^^') 
            , '||', IFNULL(TRIM(PSCRTP::text), '^^') 
            , '||', IFNULL(TRIM(PARGR::text), '^^') 
            , '||', IFNULL(TRIM(STSMA::text), '^^') 
            , '||', IFNULL(TRIM(SMSTSMA::text), '^^') 
            , '||', IFNULL(TRIM(ARTPR::text), '^^') 
            , '||', IFNULL(TRIM(SDAUART::text), '^^') 
            , '||', IFNULL(TRIM(COAUART::text), '^^') 
            , '||', IFNULL(TRIM(PARVW_KUND::text), '^^') 
            , '||', IFNULL(TRIM(PARVW_AP::text), '^^') 
            , '||', IFNULL(TRIM(PARVW_INT::text), '^^') 
            , '||', IFNULL(TRIM(PARVW_LIEF::text), '^^') 
            , '||', IFNULL(TRIM(PARVW_HER::text), '^^') 
            , '||', IFNULL(TRIM(PARVW_VERA::text), '^^') 
            , '||', IFNULL(TRIM(PARVW_AUTO::text), '^^') 
            , '||', IFNULL(TRIM(PARVW_QMSM::text), '^^') 
            , '||', IFNULL(TRIM(KLAKT::text), '^^') 
            , '||', IFNULL(TRIM(INFO_WIND::text), '^^') 
            , '||', IFNULL(TRIM(SERWI::text), '^^') 
            , '||', IFNULL(TRIM(ESCAL::text), '^^') 
            , '||', IFNULL(TRIM(FEKAT::text), '^^') 
            , '||', IFNULL(TRIM(URKAT::text), '^^') 
            , '||', IFNULL(TRIM(MAKAT::text), '^^') 
            , '||', IFNULL(TRIM(MFKAT::text), '^^') 
            , '||', IFNULL(TRIM(OTKAT::text), '^^') 
            , '||', IFNULL(TRIM(SAKAT::text), '^^') 
            , '||', IFNULL(TRIM(STAFO::text), '^^') 
            , '||', IFNULL(TRIM(QMWAERS::text), '^^') 
            , '||', IFNULL(TRIM(QMWERT::text), '^^') 
            , '||', IFNULL(TRIM(FBS_CREATE::text), '^^') 
            , '||', IFNULL(TRIM(FBS_DYNNR::text), '^^') 
            , '||', IFNULL(TRIM(TDFORMAT::text), '^^') 
            , '||', IFNULL(TRIM(KZEILE::text), '^^') 
            , '||', IFNULL(TRIM(USERSCR1::text), '^^') 
            , '||', IFNULL(TRIM(USERSCR2::text), '^^') 
            , '||', IFNULL(TRIM(USERSCR3::text), '^^') 
            , '||', IFNULL(TRIM(USERSCR4::text), '^^') 
            , '||', IFNULL(TRIM(USERSCR5::text), '^^') 
            , '||', IFNULL(TRIM(QMLTXT01::text), '^^') 
            , '||', IFNULL(TRIM(QMLTXT02::text), '^^') 
            , '||', IFNULL(TRIM(AUART2::text), '^^') 
            , '||', IFNULL(TRIM(EARLY_NUM::text), '^^') 
            , '||', IFNULL(TRIM(AUTOM_CONT::text), '^^') 
            , '||', IFNULL(TRIM(MATKZ::text), '^^') 
            , '||', IFNULL(TRIM(KUKZ::text), '^^') 
            , '||', IFNULL(TRIM(MATKUKZ::text), '^^') 
            , '||', IFNULL(TRIM(LIKZ::text), '^^') 
            , '||', IFNULL(TRIM(MATLIKZ::text), '^^') 
            , '||', IFNULL(TRIM(MATCHKZ::text), '^^') 
            , '||', IFNULL(TRIM(MATCHKUKZ::text), '^^') 
            , '||', IFNULL(TRIM(MATCHLIKZ::text), '^^') 
            , '||', IFNULL(TRIM(FEGRPKZ::text), '^^') 
            , '||', IFNULL(TRIM(FECODKZ::text), '^^') 
            , '||', IFNULL(TRIM(FOGRPKZ::text), '^^') 
            , '||', IFNULL(TRIM(FOCODKZ::text), '^^') 
            , '||', IFNULL(TRIM(MOD::text), '^^') 
            , '||', IFNULL(TRIM(ICON1::text), '^^') 
            , '||', IFNULL(TRIM(ICON2::text), '^^') 
            , '||', IFNULL(TRIM(VERS::text), '^^') 
            , '||', IFNULL(TRIM(ZEITRAUM::text), '^^') 
            , '||', IFNULL(TRIM(TDOBJECT::text), '^^') 
            , '||', IFNULL(TRIM(TDNAME::text), '^^') 
            , '||', IFNULL(TRIM(TDID::text), '^^') 
            , '||', IFNULL(TRIM(CMCHECK_SM::text), '^^') 
            , '||', IFNULL(TRIM(CMGRA::text), '^^') 
            , '||', IFNULL(TRIM(PARVW_PAGE::text), '^^') 
            , '||', IFNULL(TRIM(CUA_FBS::text), '^^') 
            , '||', IFNULL(TRIM(ROLE_VERA::text), '^^') 
            , '||', IFNULL(TRIM(PERMIT::text), '^^') 
            , '||', IFNULL(TRIM(PARVW_GEH::text), '^^') 
            , '||', IFNULL(TRIM(ROLE_GEH::text), '^^') 
            , '||', IFNULL(TRIM(ROLE_QMSM::text), '^^') 
            , '||', IFNULL(TRIM(PROCESS::text), '^^') 
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
