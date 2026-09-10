---- SRC LAYER ----
WITH
SRC_D1             as ( SELECT ABSSC, ABTNR, ACDATV, AKKUR, AKPRZ, AKWAE, BEMOT, BSARK, BSARK_E, BSTDK, BSTDK_E, BSTKD, BSTKD_E, BSTKD_M, BZIRK, CAMPAIGN, COMPREAS, DELCO, DPBP_REF_FPLNR, DPBP_REF_FPLTR, EMPST, FAKTF, FARR_RELTYPE, FBUDA, FFPRF, FKBER, FKDAT, FORMC1, FORMC2, FPLNR, GJAHR, GLCHANGETIME, GLDELFLAG, GLREQUEST, GLSOURCESYSTEM, IHREZ, IHREZ_E, INCO1, INCO2, INCO2_L, INCO3_L, INCOV, J_1ADTYP, J_1AFITP, J_1AGICD, J_1AIDATEP, J_1AINDXP, J_1AREGIO, J_1ARFZ, J_1ATXREL, J_1TPBUPL, KDGRP, KDKG1, KDKG2, KDKG3, KDKG4, KDKG5, KONDA, KTGRD, KURRF, KURRF_DAT, KURSK, KURSK_DAT, KZAZU, LCNUM, MANDT, MANSP, MNDID, MNDVG, MRNKZ, MSCHL, PAY_TYPE, PERFK, PEROP_BEG, PEROP_END, PERRL, PLTYP, PODKZ, POPER, POSEX_E, POSNR, PRSDT, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, REVEVTYP, REVSP, RRREL, SDABW, SEPON, STCODE, STCUR, STEUC, TRATY, TRMTYP, VALDT, VALTG, VBELN, VKONT, VSART, VTREF, WAKTION, WKKUR, WKWAE, WMINR, ZLSCH, ZTERM, _DATAAGING FROM {{ source('sap_ecc_prd', 'z_vbkd') }} as SRC  ),
SRC_A1             as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_D1             as ( SELECT * FROM SAP_ECC_PRD.Z_VBKD )
SRC_A1             as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_D1 as (
    SELECT
        COALESCE(NULLIF(TRIM(VBELN), ''), '-1')                      as                                    ORDER_HEADER_BK
      , CONCAT_WS('||', COALESCE(NULLIF(TRIM(VBELN), ''), '-1'), COALESCE(NULLIF(TRIM(POSNR), ''), '-1')) as                                      ORDER_LINE_BK
      , CONVERT_TIMEZONE('UTC', PSA_LOAD_DTS)                        as                                           LOAD_DTS
      , MANDT
      , VBELN
      , POSNR
      , GLREQUEST
      , KONDA
      , KDGRP
      , BZIRK
      , PLTYP
      , INCO1
      , INCO2
      , KZAZU
      , PERFK
      , PERRL
      , MRNKZ
      , KURRF
      , VALTG
      , VALDT
      , ZTERM
      , ZLSCH
      , KTGRD
      , KURSK
      , PRSDT
      , FKDAT
      , FBUDA
      , GJAHR
      , POPER
      , STCUR
      , MSCHL
      , MANSP
      , FPLNR
      , WAKTION
      , ABSSC
      , LCNUM
      , J_1AFITP
      , J_1ARFZ
      , J_1AREGIO
      , J_1AGICD
      , J_1ADTYP
      , J_1ATXREL
      , ABTNR
      , EMPST
      , BSTKD
      , BSTDK
      , BSARK
      , IHREZ
      , BSTKD_E
      , BSTDK_E
      , BSARK_E
      , IHREZ_E
      , POSEX_E
      , KURSK_DAT
      , KURRF_DAT
      , KDKG1
      , KDKG2
      , KDKG3
      , KDKG4
      , KDKG5
      , WKWAE
      , WKKUR
      , AKWAE
      , AKKUR
      , AKPRZ
      , J_1AINDXP
      , J_1AIDATEP
      , BSTKD_M
      , DELCO
      , FFPRF
      , BEMOT
      , FAKTF
      , RRREL
      , ACDATV
      , VSART
      , TRATY
      , TRMTYP
      , SDABW
      , WMINR
      , FKBER
      , PODKZ
      , CAMPAIGN
      , VKONT
      , DPBP_REF_FPLNR
      , DPBP_REF_FPLTR
      , REVSP
      , REVEVTYP
      , FARR_RELTYPE
      , VTREF
      , _DATAAGING
      , J_1TPBUPL
      , INCOV
      , INCO2_L
      , INCO3_L
      , PEROP_BEG
      , PEROP_END
      , STCODE
      , FORMC1
      , FORMC2
      , STEUC
      , COMPREAS
      , MNDID
      , PAY_TYPE
      , SEPON
      , MNDVG
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
    FROM SRC_D1
)

, LOGIC_A1 as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_A1
)
---- RENAME LAYER ----

, RENAME_D1 as (
    SELECT
        ORDER_HEADER_BK
      , ORDER_LINE_BK
      , LOAD_DTS
      , MANDT
      , VBELN
      , POSNR
      , GLREQUEST
      , KONDA
      , KDGRP
      , BZIRK
      , PLTYP
      , INCO1
      , INCO2
      , KZAZU
      , PERFK
      , PERRL
      , MRNKZ
      , KURRF
      , VALTG
      , VALDT
      , ZTERM
      , ZLSCH
      , KTGRD
      , KURSK
      , PRSDT
      , FKDAT
      , FBUDA
      , GJAHR
      , POPER
      , STCUR
      , MSCHL
      , MANSP
      , FPLNR
      , WAKTION
      , ABSSC
      , LCNUM
      , J_1AFITP
      , J_1ARFZ
      , J_1AREGIO
      , J_1AGICD
      , J_1ADTYP
      , J_1ATXREL
      , ABTNR
      , EMPST
      , BSTKD
      , BSTDK
      , BSARK
      , IHREZ
      , BSTKD_E
      , BSTDK_E
      , BSARK_E
      , IHREZ_E
      , POSEX_E
      , KURSK_DAT
      , KURRF_DAT
      , KDKG1
      , KDKG2
      , KDKG3
      , KDKG4
      , KDKG5
      , WKWAE
      , WKKUR
      , AKWAE
      , AKKUR
      , AKPRZ
      , J_1AINDXP
      , J_1AIDATEP
      , BSTKD_M
      , DELCO
      , FFPRF
      , BEMOT
      , FAKTF
      , RRREL
      , ACDATV
      , VSART
      , TRATY
      , TRMTYP
      , SDABW
      , WMINR
      , FKBER
      , PODKZ
      , CAMPAIGN
      , VKONT
      , DPBP_REF_FPLNR
      , DPBP_REF_FPLTR
      , REVSP
      , REVEVTYP
      , FARR_RELTYPE
      , VTREF
      , _DATAAGING
      , J_1TPBUPL
      , INCOV
      , INCO2_L
      , INCO3_L
      , PEROP_BEG
      , PEROP_END
      , STCODE
      , FORMC1
      , FORMC2
      , STEUC
      , COMPREAS
      , MNDID
      , PAY_TYPE
      , SEPON
      , MNDVG
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
    FROM LOGIC_D1
)

, RENAME_A1 as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_A1
)
---- FILTER LAYER ----

, FILTER_D1 as (
    SELECT *
    FROM RENAME_D1
)

, FILTER_A1 as (
    SELECT *
    FROM RENAME_A1
    WHERE rec_src = 'US.SAP_ECC_PRD.Z_VBKD'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_D1
    INNER JOIN FILTER_A1
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          ORDER_HEADER_BK
        , ORDER_LINE_BK
        , LOAD_DTS
        , MANDT
        , VBELN
        , POSNR
        , GLREQUEST
        , KONDA
        , KDGRP
        , BZIRK
        , PLTYP
        , INCO1
        , INCO2
        , KZAZU
        , PERFK
        , PERRL
        , MRNKZ
        , KURRF
        , VALTG
        , VALDT
        , ZTERM
        , ZLSCH
        , KTGRD
        , KURSK
        , PRSDT
        , FKDAT
        , FBUDA
        , GJAHR
        , POPER
        , STCUR
        , MSCHL
        , MANSP
        , FPLNR
        , WAKTION
        , ABSSC
        , LCNUM
        , J_1AFITP
        , J_1ARFZ
        , J_1AREGIO
        , J_1AGICD
        , J_1ADTYP
        , J_1ATXREL
        , ABTNR
        , EMPST
        , BSTKD
        , BSTDK
        , BSARK
        , IHREZ
        , BSTKD_E
        , BSTDK_E
        , BSARK_E
        , IHREZ_E
        , POSEX_E
        , KURSK_DAT
        , KURRF_DAT
        , KDKG1
        , KDKG2
        , KDKG3
        , KDKG4
        , KDKG5
        , WKWAE
        , WKKUR
        , AKWAE
        , AKKUR
        , AKPRZ
        , J_1AINDXP
        , J_1AIDATEP
        , BSTKD_M
        , DELCO
        , FFPRF
        , BEMOT
        , FAKTF
        , RRREL
        , ACDATV
        , VSART
        , TRATY
        , TRMTYP
        , SDABW
        , WMINR
        , FKBER
        , PODKZ
        , CAMPAIGN
        , VKONT
        , DPBP_REF_FPLNR
        , DPBP_REF_FPLTR
        , REVSP
        , REVEVTYP
        , FARR_RELTYPE
        , VTREF
        , _DATAAGING
        , J_1TPBUPL
        , INCOV
        , INCO2_L
        , INCO3_L
        , PEROP_BEG
        , PEROP_END
        , STCODE
        , FORMC1
        , FORMC2
        , STEUC
        , COMPREAS
        , MNDID
        , PAY_TYPE
        , SEPON
        , MNDVG
        , GLDELFLAG
        , GLCHANGETIME
        , GLSOURCESYSTEM
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(VBELN as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ORDER_HEADER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(VBELN as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(POSNR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ORDER_LINE_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(MANDT::text), '^^') 
            , '||', IFNULL(TRIM(GLREQUEST::text), '^^') 
            , '||', IFNULL(TRIM(KONDA::text), '^^') 
            , '||', IFNULL(TRIM(KDGRP::text), '^^') 
            , '||', IFNULL(TRIM(BZIRK::text), '^^') 
            , '||', IFNULL(TRIM(PLTYP::text), '^^') 
            , '||', IFNULL(TRIM(INCO1::text), '^^') 
            , '||', IFNULL(TRIM(INCO2::text), '^^') 
            , '||', IFNULL(TRIM(KZAZU::text), '^^') 
            , '||', IFNULL(TRIM(PERFK::text), '^^') 
            , '||', IFNULL(TRIM(PERRL::text), '^^') 
            , '||', IFNULL(TRIM(MRNKZ::text), '^^') 
            , '||', IFNULL(TRIM(KURRF::text), '^^') 
            , '||', IFNULL(TRIM(VALTG::text), '^^') 
            , '||', IFNULL(TRIM(VALDT::text), '^^') 
            , '||', IFNULL(TRIM(ZTERM::text), '^^') 
            , '||', IFNULL(TRIM(ZLSCH::text), '^^') 
            , '||', IFNULL(TRIM(KTGRD::text), '^^') 
            , '||', IFNULL(TRIM(KURSK::text), '^^') 
            , '||', IFNULL(TRIM(PRSDT::text), '^^') 
            , '||', IFNULL(TRIM(FKDAT::text), '^^') 
            , '||', IFNULL(TRIM(FBUDA::text), '^^') 
            , '||', IFNULL(TRIM(GJAHR::text), '^^') 
            , '||', IFNULL(TRIM(POPER::text), '^^') 
            , '||', IFNULL(TRIM(STCUR::text), '^^') 
            , '||', IFNULL(TRIM(MSCHL::text), '^^') 
            , '||', IFNULL(TRIM(MANSP::text), '^^') 
            , '||', IFNULL(TRIM(FPLNR::text), '^^') 
            , '||', IFNULL(TRIM(WAKTION::text), '^^') 
            , '||', IFNULL(TRIM(ABSSC::text), '^^') 
            , '||', IFNULL(TRIM(LCNUM::text), '^^') 
            , '||', IFNULL(TRIM(J_1AFITP::text), '^^') 
            , '||', IFNULL(TRIM(J_1ARFZ::text), '^^') 
            , '||', IFNULL(TRIM(J_1AREGIO::text), '^^') 
            , '||', IFNULL(TRIM(J_1AGICD::text), '^^') 
            , '||', IFNULL(TRIM(J_1ADTYP::text), '^^') 
            , '||', IFNULL(TRIM(J_1ATXREL::text), '^^') 
            , '||', IFNULL(TRIM(ABTNR::text), '^^') 
            , '||', IFNULL(TRIM(EMPST::text), '^^') 
            , '||', IFNULL(TRIM(BSTKD::text), '^^') 
            , '||', IFNULL(TRIM(BSTDK::text), '^^') 
            , '||', IFNULL(TRIM(BSARK::text), '^^') 
            , '||', IFNULL(TRIM(IHREZ::text), '^^') 
            , '||', IFNULL(TRIM(BSTKD_E::text), '^^') 
            , '||', IFNULL(TRIM(BSTDK_E::text), '^^') 
            , '||', IFNULL(TRIM(BSARK_E::text), '^^') 
            , '||', IFNULL(TRIM(IHREZ_E::text), '^^') 
            , '||', IFNULL(TRIM(POSEX_E::text), '^^') 
            , '||', IFNULL(TRIM(KURSK_DAT::text), '^^') 
            , '||', IFNULL(TRIM(KURRF_DAT::text), '^^') 
            , '||', IFNULL(TRIM(KDKG1::text), '^^') 
            , '||', IFNULL(TRIM(KDKG2::text), '^^') 
            , '||', IFNULL(TRIM(KDKG3::text), '^^') 
            , '||', IFNULL(TRIM(KDKG4::text), '^^') 
            , '||', IFNULL(TRIM(KDKG5::text), '^^') 
            , '||', IFNULL(TRIM(WKWAE::text), '^^') 
            , '||', IFNULL(TRIM(WKKUR::text), '^^') 
            , '||', IFNULL(TRIM(AKWAE::text), '^^') 
            , '||', IFNULL(TRIM(AKKUR::text), '^^') 
            , '||', IFNULL(TRIM(AKPRZ::text), '^^') 
            , '||', IFNULL(TRIM(J_1AINDXP::text), '^^') 
            , '||', IFNULL(TRIM(J_1AIDATEP::text), '^^') 
            , '||', IFNULL(TRIM(BSTKD_M::text), '^^') 
            , '||', IFNULL(TRIM(DELCO::text), '^^') 
            , '||', IFNULL(TRIM(FFPRF::text), '^^') 
            , '||', IFNULL(TRIM(BEMOT::text), '^^') 
            , '||', IFNULL(TRIM(FAKTF::text), '^^') 
            , '||', IFNULL(TRIM(RRREL::text), '^^') 
            , '||', IFNULL(TRIM(ACDATV::text), '^^') 
            , '||', IFNULL(TRIM(VSART::text), '^^') 
            , '||', IFNULL(TRIM(TRATY::text), '^^') 
            , '||', IFNULL(TRIM(TRMTYP::text), '^^') 
            , '||', IFNULL(TRIM(SDABW::text), '^^') 
            , '||', IFNULL(TRIM(WMINR::text), '^^') 
            , '||', IFNULL(TRIM(FKBER::text), '^^') 
            , '||', IFNULL(TRIM(PODKZ::text), '^^') 
            , '||', IFNULL(TRIM(CAMPAIGN::text), '^^') 
            , '||', IFNULL(TRIM(VKONT::text), '^^') 
            , '||', IFNULL(TRIM(DPBP_REF_FPLNR::text), '^^') 
            , '||', IFNULL(TRIM(DPBP_REF_FPLTR::text), '^^') 
            , '||', IFNULL(TRIM(REVSP::text), '^^') 
            , '||', IFNULL(TRIM(REVEVTYP::text), '^^') 
            , '||', IFNULL(TRIM(FARR_RELTYPE::text), '^^') 
            , '||', IFNULL(TRIM(VTREF::text), '^^') 
            , '||', IFNULL(TRIM(_DATAAGING::text), '^^') 
            , '||', IFNULL(TRIM(J_1TPBUPL::text), '^^') 
            , '||', IFNULL(TRIM(INCOV::text), '^^') 
            , '||', IFNULL(TRIM(INCO2_L::text), '^^') 
            , '||', IFNULL(TRIM(INCO3_L::text), '^^') 
            , '||', IFNULL(TRIM(PEROP_BEG::text), '^^') 
            , '||', IFNULL(TRIM(PEROP_END::text), '^^') 
            , '||', IFNULL(TRIM(STCODE::text), '^^') 
            , '||', IFNULL(TRIM(FORMC1::text), '^^') 
            , '||', IFNULL(TRIM(FORMC2::text), '^^') 
            , '||', IFNULL(TRIM(STEUC::text), '^^') 
            , '||', IFNULL(TRIM(COMPREAS::text), '^^') 
            , '||', IFNULL(TRIM(MNDID::text), '^^') 
            , '||', IFNULL(TRIM(PAY_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(SEPON::text), '^^') 
            , '||', IFNULL(TRIM(MNDVG::text), '^^') 
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^') 
            , '||', IFNULL(TRIM(GLCHANGETIME::text), '^^') 
            , '||', IFNULL(TRIM(GLSOURCESYSTEM::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
