---- SRC LAYER ----
WITH
SRC_a              as ( SELECT * FROM {{ source('sap_ecc_prd', 'z_rkpf') }} as SRC  ),
SRC_bkcc           as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_a              as ( SELECT * FROM sap_ecc_prd.z_rkpf )
, SRC_bkcc           as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_a as (
    SELECT
        RSNUM                                                        as                                     RESERVATION_BK
      , MANDT
      , RSNUM
      , GLREQUEST
      , KZVER
      , XCALE
      , RSDAT
      , USNAM
      , BWART
      , WEMPF
      , KOSTL
      , PROJN
      , ANLN1
      , ANLN2
      , KUNNR
      , EBELN
      , EBELP
      , AUFNR
      , KDAUF
      , KDPOS
      , KDEIN
      , UMWRK
      , UMLGO
      , SERIE
      , KOKRS
      , PARBU
      , PARGB
      , IMKEY
      , KSTRG
      , PAOBJNR
      , PRCTR
      , PS_PSP_PNR
      , NPLNR
      , AUFPL
      , APLZL
      , VPTNR
      , FIPOS
      , ZZALTKT
      , RECID
      , FKBER
      , DABRZ
      , FISTL
      , GEBER
      , PRZNR
      , LSTAR
      , GRANT_NBR
      , BUDGET_PD
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
    FROM SRC_a
)

, LOGIC_bkcc as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_bkcc
)
---- RENAME LAYER ----

, RENAME_a as (
    SELECT
        RESERVATION_BK
      , MANDT
      , RSNUM
      , GLREQUEST
      , KZVER
      , XCALE
      , RSDAT
      , USNAM
      , BWART
      , WEMPF
      , KOSTL
      , PROJN
      , ANLN1
      , ANLN2
      , KUNNR
      , EBELN
      , EBELP
      , AUFNR
      , KDAUF
      , KDPOS
      , KDEIN
      , UMWRK
      , UMLGO
      , SERIE
      , KOKRS
      , PARBU
      , PARGB
      , IMKEY
      , KSTRG
      , PAOBJNR
      , PRCTR
      , PS_PSP_PNR
      , NPLNR
      , AUFPL
      , APLZL
      , VPTNR
      , FIPOS
      , ZZALTKT
      , RECID
      , FKBER
      , DABRZ
      , FISTL
      , GEBER
      , PRZNR
      , LSTAR
      , GRANT_NBR
      , BUDGET_PD
      , GLDELFLAG
      , GLSOURCESYSTEM
      , GLCHANGETIME
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
    FROM LOGIC_a
)

, RENAME_bkcc as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_bkcc
)
---- FILTER LAYER ----

, FILTER_a as (
    SELECT *
    FROM RENAME_a
)

, FILTER_bkcc as (
    SELECT *
    FROM RENAME_bkcc
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_RKPF' 
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_a
    INNER JOIN FILTER_bkcc
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          RESERVATION_BK
        , MANDT
        , RSNUM
        , GLREQUEST
        , KZVER
        , XCALE
        , RSDAT
        , USNAM
        , BWART
        , WEMPF
        , KOSTL
        , PROJN
        , ANLN1
        , ANLN2
        , KUNNR
        , EBELN
        , EBELP
        , AUFNR
        , KDAUF
        , KDPOS
        , KDEIN
        , UMWRK
        , UMLGO
        , SERIE
        , KOKRS
        , PARBU
        , PARGB
        , IMKEY
        , KSTRG
        , PAOBJNR
        , PRCTR
        , PS_PSP_PNR
        , NPLNR
        , AUFPL
        , APLZL
        , VPTNR
        , FIPOS
        , ZZALTKT
        , RECID
        , FKBER
        , DABRZ
        , FISTL
        , GEBER
        , PRZNR
        , LSTAR
        , GRANT_NBR
        , BUDGET_PD
        , GLDELFLAG
        , GLSOURCESYSTEM
        , GLCHANGETIME
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(RSNUM as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as RESERVATION_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(MANDT::text), '^^') 
            , '||', IFNULL(TRIM(RSNUM::text), '^^') 
            , '||', IFNULL(TRIM(KZVER::text), '^^') 
            , '||', IFNULL(TRIM(XCALE::text), '^^') 
            , '||', IFNULL(TRIM(RSDAT::text), '^^') 
            , '||', IFNULL(TRIM(USNAM::text), '^^') 
            , '||', IFNULL(TRIM(BWART::text), '^^') 
            , '||', IFNULL(TRIM(WEMPF::text), '^^') 
            , '||', IFNULL(TRIM(KOSTL::text), '^^') 
            , '||', IFNULL(TRIM(PROJN::text), '^^') 
            , '||', IFNULL(TRIM(ANLN1::text), '^^') 
            , '||', IFNULL(TRIM(ANLN2::text), '^^') 
            , '||', IFNULL(TRIM(KUNNR::text), '^^') 
            , '||', IFNULL(TRIM(EBELN::text), '^^') 
            , '||', IFNULL(TRIM(EBELP::text), '^^') 
            , '||', IFNULL(TRIM(AUFNR::text), '^^') 
            , '||', IFNULL(TRIM(KDAUF::text), '^^') 
            , '||', IFNULL(TRIM(KDPOS::text), '^^') 
            , '||', IFNULL(TRIM(KDEIN::text), '^^') 
            , '||', IFNULL(TRIM(UMWRK::text), '^^') 
            , '||', IFNULL(TRIM(UMLGO::text), '^^') 
            , '||', IFNULL(TRIM(SERIE::text), '^^') 
            , '||', IFNULL(TRIM(KOKRS::text), '^^') 
            , '||', IFNULL(TRIM(PARBU::text), '^^') 
            , '||', IFNULL(TRIM(PARGB::text), '^^') 
            , '||', IFNULL(TRIM(IMKEY::text), '^^') 
            , '||', IFNULL(TRIM(KSTRG::text), '^^') 
            , '||', IFNULL(TRIM(PAOBJNR::text), '^^') 
            , '||', IFNULL(TRIM(PRCTR::text), '^^') 
            , '||', IFNULL(TRIM(PS_PSP_PNR::text), '^^') 
            , '||', IFNULL(TRIM(NPLNR::text), '^^') 
            , '||', IFNULL(TRIM(AUFPL::text), '^^') 
            , '||', IFNULL(TRIM(APLZL::text), '^^') 
            , '||', IFNULL(TRIM(VPTNR::text), '^^') 
            , '||', IFNULL(TRIM(FIPOS::text), '^^') 
            , '||', IFNULL(TRIM(ZZALTKT::text), '^^') 
            , '||', IFNULL(TRIM(RECID::text), '^^') 
            , '||', IFNULL(TRIM(FKBER::text), '^^') 
            , '||', IFNULL(TRIM(DABRZ::text), '^^') 
            , '||', IFNULL(TRIM(FISTL::text), '^^') 
            , '||', IFNULL(TRIM(GEBER::text), '^^') 
            , '||', IFNULL(TRIM(PRZNR::text), '^^') 
            , '||', IFNULL(TRIM(LSTAR::text), '^^') 
            , '||', IFNULL(TRIM(GRANT_NBR::text), '^^') 
            , '||', IFNULL(TRIM(BUDGET_PD::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
