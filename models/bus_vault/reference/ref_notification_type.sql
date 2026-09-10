---- SRC LAYER ----
WITH
SRC_a              as ( SELECT * FROM {{ ref('v_psa_stg_notification_types') }} as SRC  )

/*
SRC_a              as ( SELECT * FROM SAP_ECC_PRD.Z_TQ80 )
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
      , REC_SRC
      , GLSOURCESYSTEM
      , GLCHANGETIME                                                 as                                           LOAD_DTS
      , HASHDIFF
    FROM SRC_a
)
---- RENAME LAYER ----

, RENAME_a as (
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
      , REC_SRC 
      , GLSOURCESYSTEM
      , LOAD_DTS
      , HASHDIFF
    FROM LOGIC_a
)
---- FILTER LAYER ----

, FILTER_a as (
    SELECT *
    FROM RENAME_a
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_a
)

---- FINAL LAYER ----
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
        , REC_SRC 
        , GLSOURCESYSTEM
        , LOAD_DTS
        , HASHDIFF
FROM JOIN_RESULT
