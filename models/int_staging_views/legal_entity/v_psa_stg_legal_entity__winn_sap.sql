---- SRC LAYER ----
WITH
SRC_O              as ( SELECT * FROM {{ source('sap_ecc_prd', 'z_t001') }} as SRC  ),
SRC_A              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_O              as ( SELECT * FROM sap_ecc_prd.z_t001 )
, SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_O as (
    SELECT
        CONVERT_TIMEZONE('UTC', PSA_LOAD_DTS)                        as                                           LOAD_DTS
      , MANDT
      , BUKRS
      , GLREQUEST
      , BUTXT
      , ORT01
      , LAND1
      , WAERS
      , SPRAS
      , KTOPL
      , WAABW
      , PERIV
      , KOKFI
      , RCOMP
      , ADRNR
      , STCEG
      , FIKRS
      , XFMCO
      , XFMCB
      , XFMCA
      , TXJCD
      , FMHRDATE
      , BUVAR
      , FDBUK
      , XFDIS
      , XVALV
      , XSKFN
      , KKBER
      , XMWSN
      , MREGL
      , XGSBE
      , XGJRV
      , XKDFT
      , XPROD
      , XEINK
      , XJVAA
      , XVVWA
      , XSLTA
      , XFDMM
      , XFDSD
      , XEXTB
      , EBUKR
      , KTOP2
      , UMKRS
      , BUKRS_GLOB
      , FSTVA
      , OPVAR
      , XCOVR
      , TXKRS
      , WFVAR
      , XBBBF
      , XBBBE
      , XBBBA
      , XBBKO
      , XSTDT
      , MWSKV
      , MWSKA
      , IMPDA
      , XNEGP
      , XKKBI
      , WT_NEWWT
      , PP_PDATE
      , INFMT
      , FSTVARE
      , KOPIM
      , DKWEG
      , OFFSACCT
      , BAPOVAR
      , XCOS
      , XCESSION
      , XSPLT
      , SURCCM
      , DTPROV
      , DTAMTC
      , DTTAXC
      , DTTDSP
      , DTAXR
      , XVATDATE
      , PST_PER_VAR
      , XBBSC
      , FM_DERIVE_ACC
      , GLDELFLAG
      , GLSOURCESYSTEM
      , GLCHANGETIME
      , TO_TIMESTAMP(
            SUBSTR(GLCHANGETIME, 1, 8) || ' ' ||
            SUBSTR(GLCHANGETIME, 9, 2) || ':' ||
            SUBSTR(GLCHANGETIME, 11, 2) || ':' ||
            SUBSTR(GLCHANGETIME, 13, 2) || '.' ||
            REGEXP_REPLACE(SUBSTR(GLCHANGETIME, 16), '^\\.', ''),
            'YYYYMMDD HH24:MI:SS.FF9'
        )                                                            as                                      GLCHANGE_DTTM
      , PSA_LOAD_DTS
      , PSA_DELETE_IND
    FROM SRC_O
)

, LOGIC_A as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_A
)
---- RENAME LAYER ----

, RENAME_O as (
    SELECT
        LOAD_DTS
      , MANDT
      , BUKRS
      , GLREQUEST
      , BUTXT
      , ORT01
      , LAND1
      , WAERS
      , SPRAS
      , KTOPL
      , WAABW
      , PERIV
      , KOKFI
      , RCOMP
      , ADRNR
      , STCEG
      , FIKRS
      , XFMCO
      , XFMCB
      , XFMCA
      , TXJCD
      , FMHRDATE
      , BUVAR
      , FDBUK
      , XFDIS
      , XVALV
      , XSKFN
      , KKBER
      , XMWSN
      , MREGL
      , XGSBE
      , XGJRV
      , XKDFT
      , XPROD
      , XEINK
      , XJVAA
      , XVVWA
      , XSLTA
      , XFDMM
      , XFDSD
      , XEXTB
      , EBUKR
      , KTOP2
      , UMKRS
      , BUKRS_GLOB
      , FSTVA
      , OPVAR
      , XCOVR
      , TXKRS
      , WFVAR
      , XBBBF
      , XBBBE
      , XBBBA
      , XBBKO
      , XSTDT
      , MWSKV
      , MWSKA
      , IMPDA
      , XNEGP
      , XKKBI
      , WT_NEWWT
      , PP_PDATE
      , INFMT
      , FSTVARE
      , KOPIM
      , DKWEG
      , OFFSACCT
      , BAPOVAR
      , XCOS
      , XCESSION
      , XSPLT
      , SURCCM
      , DTPROV
      , DTAMTC
      , DTTAXC
      , DTTDSP
      , DTAXR
      , XVATDATE
      , PST_PER_VAR
      , XBBSC
      , FM_DERIVE_ACC
      , GLDELFLAG
      , GLSOURCESYSTEM
      , GLCHANGETIME
      , GLCHANGE_DTTM
      , PSA_LOAD_DTS
      , PSA_DELETE_IND
    FROM LOGIC_O
)

, RENAME_A as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_A
)
---- FILTER LAYER ----

, FILTER_O as (
    SELECT *
    FROM RENAME_O
)

, FILTER_A as (
    SELECT *
    FROM RENAME_A
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_T001'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_O
    INNER JOIN FILTER_A
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          LOAD_DTS
        , MANDT
        , BUKRS
        , GLREQUEST
        , BUTXT
        , ORT01
        , LAND1
        , WAERS
        , SPRAS
        , KTOPL
        , WAABW
        , PERIV
        , KOKFI
        , RCOMP
        , ADRNR
        , STCEG
        , FIKRS
        , XFMCO
        , XFMCB
        , XFMCA
        , TXJCD
        , FMHRDATE
        , BUVAR
        , FDBUK
        , XFDIS
        , XVALV
        , XSKFN
        , KKBER
        , XMWSN
        , MREGL
        , XGSBE
        , XGJRV
        , XKDFT
        , XPROD
        , XEINK
        , XJVAA
        , XVVWA
        , XSLTA
        , XFDMM
        , XFDSD
        , XEXTB
        , EBUKR
        , KTOP2
        , UMKRS
        , BUKRS_GLOB
        , FSTVA
        , OPVAR
        , XCOVR
        , TXKRS
        , WFVAR
        , XBBBF
        , XBBBE
        , XBBBA
        , XBBKO
        , XSTDT
        , MWSKV
        , MWSKA
        , IMPDA
        , XNEGP
        , XKKBI
        , WT_NEWWT
        , PP_PDATE
        , INFMT
        , FSTVARE
        , KOPIM
        , DKWEG
        , OFFSACCT
        , BAPOVAR
        , XCOS
        , XCESSION
        , XSPLT
        , SURCCM
        , DTPROV
        , DTAMTC
        , DTTAXC
        , DTTDSP
        , DTAXR
        , XVATDATE
        , PST_PER_VAR
        , XBBSC
        , FM_DERIVE_ACC
        , GLDELFLAG
        , GLSOURCESYSTEM
        , GLCHANGETIME
        , GLCHANGE_DTTM
        , PSA_LOAD_DTS
        , PSA_DELETE_IND
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(BUKRS as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as LEGAL_ENTITY_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(MANDT::text), '^^') 
            , '||', IFNULL(TRIM(BUTXT::text), '^^') 
            , '||', IFNULL(TRIM(ORT01::text), '^^') 
            , '||', IFNULL(TRIM(LAND1::text), '^^') 
            , '||', IFNULL(TRIM(WAERS::text), '^^') 
            , '||', IFNULL(TRIM(SPRAS::text), '^^') 
            , '||', IFNULL(TRIM(KTOPL::text), '^^') 
            , '||', IFNULL(TRIM(WAABW::text), '^^') 
            , '||', IFNULL(TRIM(PERIV::text), '^^') 
            , '||', IFNULL(TRIM(KOKFI::text), '^^') 
            , '||', IFNULL(TRIM(RCOMP::text), '^^') 
            , '||', IFNULL(TRIM(ADRNR::text), '^^') 
            , '||', IFNULL(TRIM(STCEG::text), '^^') 
            , '||', IFNULL(TRIM(FIKRS::text), '^^') 
            , '||', IFNULL(TRIM(XFMCO::text), '^^') 
            , '||', IFNULL(TRIM(XFMCB::text), '^^') 
            , '||', IFNULL(TRIM(XFMCA::text), '^^') 
            , '||', IFNULL(TRIM(TXJCD::text), '^^') 
            , '||', IFNULL(TRIM(FMHRDATE::text), '^^') 
            , '||', IFNULL(TRIM(BUVAR::text), '^^') 
            , '||', IFNULL(TRIM(FDBUK::text), '^^') 
            , '||', IFNULL(TRIM(XFDIS::text), '^^') 
            , '||', IFNULL(TRIM(XVALV::text), '^^') 
            , '||', IFNULL(TRIM(XSKFN::text), '^^') 
            , '||', IFNULL(TRIM(KKBER::text), '^^') 
            , '||', IFNULL(TRIM(XMWSN::text), '^^') 
            , '||', IFNULL(TRIM(MREGL::text), '^^') 
            , '||', IFNULL(TRIM(XGSBE::text), '^^') 
            , '||', IFNULL(TRIM(XGJRV::text), '^^') 
            , '||', IFNULL(TRIM(XKDFT::text), '^^') 
            , '||', IFNULL(TRIM(XPROD::text), '^^') 
            , '||', IFNULL(TRIM(XEINK::text), '^^') 
            , '||', IFNULL(TRIM(XJVAA::text), '^^') 
            , '||', IFNULL(TRIM(XVVWA::text), '^^') 
            , '||', IFNULL(TRIM(XSLTA::text), '^^') 
            , '||', IFNULL(TRIM(XFDMM::text), '^^') 
            , '||', IFNULL(TRIM(XFDSD::text), '^^') 
            , '||', IFNULL(TRIM(XEXTB::text), '^^') 
            , '||', IFNULL(TRIM(EBUKR::text), '^^') 
            , '||', IFNULL(TRIM(KTOP2::text), '^^') 
            , '||', IFNULL(TRIM(UMKRS::text), '^^') 
            , '||', IFNULL(TRIM(BUKRS_GLOB::text), '^^') 
            , '||', IFNULL(TRIM(FSTVA::text), '^^') 
            , '||', IFNULL(TRIM(OPVAR::text), '^^') 
            , '||', IFNULL(TRIM(XCOVR::text), '^^') 
            , '||', IFNULL(TRIM(TXKRS::text), '^^') 
            , '||', IFNULL(TRIM(WFVAR::text), '^^') 
            , '||', IFNULL(TRIM(XBBBF::text), '^^') 
            , '||', IFNULL(TRIM(XBBBE::text), '^^') 
            , '||', IFNULL(TRIM(XBBBA::text), '^^') 
            , '||', IFNULL(TRIM(XBBKO::text), '^^') 
            , '||', IFNULL(TRIM(XSTDT::text), '^^') 
            , '||', IFNULL(TRIM(MWSKV::text), '^^') 
            , '||', IFNULL(TRIM(MWSKA::text), '^^') 
            , '||', IFNULL(TRIM(IMPDA::text), '^^') 
            , '||', IFNULL(TRIM(XNEGP::text), '^^') 
            , '||', IFNULL(TRIM(XKKBI::text), '^^') 
            , '||', IFNULL(TRIM(WT_NEWWT::text), '^^') 
            , '||', IFNULL(TRIM(PP_PDATE::text), '^^') 
            , '||', IFNULL(TRIM(INFMT::text), '^^') 
            , '||', IFNULL(TRIM(FSTVARE::text), '^^') 
            , '||', IFNULL(TRIM(KOPIM::text), '^^') 
            , '||', IFNULL(TRIM(DKWEG::text), '^^') 
            , '||', IFNULL(TRIM(OFFSACCT::text), '^^') 
            , '||', IFNULL(TRIM(BAPOVAR::text), '^^') 
            , '||', IFNULL(TRIM(XCOS::text), '^^') 
            , '||', IFNULL(TRIM(XCESSION::text), '^^') 
            , '||', IFNULL(TRIM(XSPLT::text), '^^') 
            , '||', IFNULL(TRIM(SURCCM::text), '^^') 
            , '||', IFNULL(TRIM(DTPROV::text), '^^') 
            , '||', IFNULL(TRIM(DTAMTC::text), '^^') 
            , '||', IFNULL(TRIM(DTTAXC::text), '^^') 
            , '||', IFNULL(TRIM(DTTDSP::text), '^^') 
            , '||', IFNULL(TRIM(DTAXR::text), '^^') 
            , '||', IFNULL(TRIM(XVATDATE::text), '^^') 
            , '||', IFNULL(TRIM(PST_PER_VAR::text), '^^') 
            , '||', IFNULL(TRIM(XBBSC::text), '^^') 
            , '||', IFNULL(TRIM(FM_DERIVE_ACC::text), '^^') 
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
