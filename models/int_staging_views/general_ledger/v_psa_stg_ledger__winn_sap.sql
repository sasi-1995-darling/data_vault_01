---- SRC LAYER ----
WITH
SRC_S          as ( SELECT MANDT, RLDNR, GLREQUEST, GCURR, CLASS, TYP, TRCUR, LCCUR, RCCUR, OCCUR, QUANT, ATQNT, TAB, RCOPY, SHKZ, GLSIP, VORTRAG, DLDNR, XDLDNR, CURT1, CURT2, CURT3, V2POST, LCTYP, FIX, POST, ROLLUP, DEPLD, APPL, SUBAPPL, KOMP, GZLEDGER, EXIT, KLDNR, LOGSYS, VALUTYP, GCOMPRESS, SPLITMETHD, DATE_DET_POPER, GLFLEX, XLEADING, ORIENT_LEDGER, AVG_ROLLUP, XCASH_LEDGER, GLDELFLAG, GLCHANGETIME, GLSOURCESYSTEM, PSA_LOAD_DTS, PSA_RECORD_SOURCE, PSA_DELETE_IND FROM {{ source('sap_ecc_prd', 'z_t881') }} as SRC  ),
SRC_A          as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S          as ( SELECT * FROM sap_ecc_prd.z_t881 )
SRC_A          as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        MANDT
      , RLDNR
      , GLREQUEST
      , GCURR
      , CLASS
      , TYP
      , TRCUR
      , LCCUR
      , RCCUR
      , OCCUR
      , QUANT
      , ATQNT
      , TAB
      , RCOPY
      , SHKZ
      , GLSIP
      , VORTRAG
      , DLDNR
      , XDLDNR
      , CURT1
      , CURT2
      , CURT3
      , V2POST
      , LCTYP
      , FIX
      , POST
      , ROLLUP
      , DEPLD
      , APPL
      , SUBAPPL
      , KOMP
      , GZLEDGER
      , EXIT
      , KLDNR
      , LOGSYS
      , VALUTYP
      , GCOMPRESS
      , SPLITMETHD
      , DATE_DET_POPER
      , GLFLEX
      , XLEADING
      , ORIENT_LEDGER
      , AVG_ROLLUP
      , XCASH_LEDGER
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
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
        MANDT
      , RLDNR
      , GLREQUEST
      , GCURR
      , CLASS
      , TYP
      , TRCUR
      , LCCUR
      , RCCUR
      , OCCUR
      , QUANT
      , ATQNT
      , TAB
      , RCOPY
      , SHKZ
      , GLSIP
      , VORTRAG
      , DLDNR
      , XDLDNR
      , CURT1
      , CURT2
      , CURT3
      , V2POST
      , LCTYP
      , FIX
      , POST
      , ROLLUP
      , DEPLD
      , APPL
      , SUBAPPL
      , KOMP
      , GZLEDGER
      , EXIT
      , KLDNR
      , LOGSYS
      , VALUTYP
      , GCOMPRESS
      , SPLITMETHD
      , DATE_DET_POPER
      , GLFLEX
      , XLEADING
      , ORIENT_LEDGER
      , AVG_ROLLUP
      , XCASH_LEDGER
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
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
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_T881'
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
          to_char(coalesce(nullif(trim(RLDNR), ''), '-1'))                                as LEDGER_BK
        , MANDT
        , RLDNR
        , GLREQUEST
        , GCURR
        , CLASS
        , TYP
        , TRCUR
        , LCCUR
        , RCCUR
        , OCCUR
        , QUANT
        , ATQNT
        , TAB
        , RCOPY
        , SHKZ
        , GLSIP
        , VORTRAG
        , DLDNR
        , XDLDNR
        , CURT1
        , CURT2
        , CURT3
        , V2POST
        , LCTYP
        , FIX
        , POST
        , ROLLUP
        , DEPLD
        , APPL
        , SUBAPPL
        , KOMP
        , GZLEDGER
        , EXIT
        , KLDNR
        , LOGSYS
        , VALUTYP
        , GCOMPRESS
        , SPLITMETHD
        , DATE_DET_POPER
        , GLFLEX
        , XLEADING
        , ORIENT_LEDGER
        , AVG_ROLLUP
        , XCASH_LEDGER
        , GLDELFLAG
        , GLCHANGETIME
        , GLSOURCESYSTEM
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
        ))  as LOAD_DTS
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(LEDGER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as LEDGER_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(MANDT::text), '^^') 
            , '||', IFNULL(TRIM(RLDNR::text), '^^') 
            , '||', IFNULL(TRIM(GCURR::text), '^^') 
            , '||', IFNULL(TRIM(CLASS::text), '^^') 
            , '||', IFNULL(TRIM(TYP::text), '^^') 
            , '||', IFNULL(TRIM(TRCUR::text), '^^') 
            , '||', IFNULL(TRIM(LCCUR::text), '^^') 
            , '||', IFNULL(TRIM(RCCUR::text), '^^') 
            , '||', IFNULL(TRIM(OCCUR::text), '^^') 
            , '||', IFNULL(TRIM(QUANT::text), '^^') 
            , '||', IFNULL(TRIM(ATQNT::text), '^^') 
            , '||', IFNULL(TRIM(TAB::text), '^^') 
            , '||', IFNULL(TRIM(RCOPY::text), '^^') 
            , '||', IFNULL(TRIM(SHKZ::text), '^^') 
            , '||', IFNULL(TRIM(GLSIP::text), '^^') 
            , '||', IFNULL(TRIM(VORTRAG::text), '^^') 
            , '||', IFNULL(TRIM(DLDNR::text), '^^') 
            , '||', IFNULL(TRIM(XDLDNR::text), '^^') 
            , '||', IFNULL(TRIM(CURT1::text), '^^') 
            , '||', IFNULL(TRIM(CURT2::text), '^^') 
            , '||', IFNULL(TRIM(CURT3::text), '^^') 
            , '||', IFNULL(TRIM(V2POST::text), '^^') 
            , '||', IFNULL(TRIM(LCTYP::text), '^^') 
            , '||', IFNULL(TRIM(FIX::text), '^^') 
            , '||', IFNULL(TRIM(POST::text), '^^') 
            , '||', IFNULL(TRIM(ROLLUP::text), '^^') 
            , '||', IFNULL(TRIM(DEPLD::text), '^^') 
            , '||', IFNULL(TRIM(APPL::text), '^^') 
            , '||', IFNULL(TRIM(SUBAPPL::text), '^^') 
            , '||', IFNULL(TRIM(KOMP::text), '^^') 
            , '||', IFNULL(TRIM(GZLEDGER::text), '^^') 
            , '||', IFNULL(TRIM(EXIT::text), '^^') 
            , '||', IFNULL(TRIM(KLDNR::text), '^^') 
            , '||', IFNULL(TRIM(LOGSYS::text), '^^') 
            , '||', IFNULL(TRIM(VALUTYP::text), '^^') 
            , '||', IFNULL(TRIM(GCOMPRESS::text), '^^') 
            , '||', IFNULL(TRIM(SPLITMETHD::text), '^^') 
            , '||', IFNULL(TRIM(DATE_DET_POPER::text), '^^') 
            , '||', IFNULL(TRIM(GLFLEX::text), '^^') 
            , '||', IFNULL(TRIM(XLEADING::text), '^^') 
            , '||', IFNULL(TRIM(ORIENT_LEDGER::text), '^^') 
            , '||', IFNULL(TRIM(AVG_ROLLUP::text), '^^') 
            , '||', IFNULL(TRIM(XCASH_LEDGER::text), '^^') 
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
