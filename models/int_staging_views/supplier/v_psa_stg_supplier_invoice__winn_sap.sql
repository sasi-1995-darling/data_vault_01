---- SRC LAYER ----
WITH
SRC_SRC            as ( SELECT * FROM {{ source('sap_ecc_prd', 'z_rbkp') }} as SRC  ),
SRC_ref_bkcc       as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC 
                        WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_RBKP' )

/*
SRC_SRC            as ( SELECT * FROM sap_ecc_prd.z_rbkp )
SRC_ref_bkcc       as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_SRC as (
    SELECT
        BELNR                                                        as                                      INVOICE_ID_BK
      , BELNR
      , MANDT
      , GJAHR
      , BLART
      , BLDAT
      , BUDAT
      , USNAM
      , TCODE
      , CPUDT
      , CPUTM
      , VGART
      , XBLNR
      , BUKRS
      , LIFNR
      , WAERS
      , KURSF
      , RMWWR
      , BEZNK
      , WMWST1
      , MWSKZ1
      , WMWST2
      , MWSKZ2
      , ZTERM
      , ZBD1T
      , ZBD1P
      , ZBD2T
      , ZBD2P
      , ZBD3T
      , WSKTO
      , XRECH
      , BKTXT
      , SAPRL
      , LOGSYS
      , XMWST
      , STBLG
      , STJAH
      , MWSKZ_BNK
      , TXJCD_BNK
      , IVTYP
      , XRBTX
      , REPART
      , RBSTAT
      , KNUMVE
      , KNUMVL
      , ARKUEN
      , ARKUEMW
      , MAKZN
      , MAKZMW
      , LIEFFN
      , LIEFFMW
      , XAUTAKZ
      , ESRNR
      , ESRPZ
      , ESRRE
      , QSSHB
      , QSFBT
      , QSSKZ
      , DIEKZ
      , LANDL
      , LZBKZ
      , TXKRS
      , CTXKRS
      , EMPFB
      , BVTYP
      , HBKID
      , ZUONR
      , ZLSPR
      , ZLSCH
      , ZFBDT
      , KIDNO
      , REBZG
      , REBZJ
      , XINVE
      , EGMLD
      , XEGDR
      , VATDATE
      , HKONT
      , J_1BNFTYPE
      , BRNCH
      , ERFPR
      , SECCO
      , NAME1
      , NAME2
      , NAME3
      , NAME4
      , PSTLZ
      , ORT01
      , LAND1
      , STRAS
      , PFACH
      , PSTL2
      , PSKTO
      , BANKN
      , BANKL
      , BANKS
      , STCD1
      , STCD2
      , STKZU
      , STKZA
      , REGIO
      , BKONT
      , DTAWS
      , DTAMS
      , SPRAS
      , XCPDK
      , EMPFG
      , FITYP
      , STCDT
      , STKZN
      , STCD3
      , STCD4
      , BKREF
      , J_1KFREPRE
      , J_1KFTBUS
      , J_1KFTIND
      , ANRED
      , STCEG
      , ERNAME
      , REINDAT
      , UZAWE
      , FDLEV
      , FDTAG
      , ZBFIX
      , FRGKZ
      , ERFNAM
      , BUPLA
      , FILKD
      , GSBER
      , LOTKZ
      , SGTXT
      , INV_TRAN
      , PREPAY_STATUS
      , PREPAY_AWKEY
      , ASSIGN_STATUS
      , ASSIGN_NEXT_DATE
      , ASSIGN_END_DATE
      , COPY_BY_BELNR
      , COPY_BY_YEAR
      , COPY_TO_BELNR
      , COPY_TO_YEAR
      , COPY_USER
      , KURSX
      , WWERT
      , XREF3
      , J_1TPBUPL
      , PYBASTYP
      , PYBASNO
      , PYBASDAT
      , PYIBAN
      , INWARDNO_HD
      , INWARDDT_HD
      , GLREQUEST
      , GLDELFLAG
      , GLSOURCESYSTEM
      , GLCHANGETIME
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , IFF(PSA_DELETE_IND = 'Y', PSA_LOAD_DTS, CONVERT_TIMEZONE('UTC', TO_TIMESTAMP_NTZ(SUBSTR(GLCHANGETIME, 1, 14) || '.' || SUBSTR(GLCHANGETIME, 16), 'YYYYMMDDHH24MISS.FF9'))) as                                           LOAD_DTS
    FROM SRC_SRC
)

, LOGIC_ref_bkcc as (
    SELECT
        BKCC
      , REC_SRC
    FROM SRC_ref_bkcc
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM LOGIC_SRC
    INNER JOIN LOGIC_ref_bkcc
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          INVOICE_ID_BK
        , BELNR
        , MANDT
        , GJAHR
        , BLART
        , BLDAT
        , BUDAT
        , USNAM
        , TCODE
        , CPUDT
        , CPUTM
        , VGART
        , XBLNR
        , BUKRS
        , LIFNR
        , WAERS
        , KURSF
        , RMWWR
        , BEZNK
        , WMWST1
        , MWSKZ1
        , WMWST2
        , MWSKZ2
        , ZTERM
        , ZBD1T
        , ZBD1P
        , ZBD2T
        , ZBD2P
        , ZBD3T
        , WSKTO
        , XRECH
        , BKTXT
        , SAPRL
        , LOGSYS
        , XMWST
        , STBLG
        , STJAH
        , MWSKZ_BNK
        , TXJCD_BNK
        , IVTYP
        , XRBTX
        , REPART
        , RBSTAT
        , KNUMVE
        , KNUMVL
        , ARKUEN
        , ARKUEMW
        , MAKZN
        , MAKZMW
        , LIEFFN
        , LIEFFMW
        , XAUTAKZ
        , ESRNR
        , ESRPZ
        , ESRRE
        , QSSHB
        , QSFBT
        , QSSKZ
        , DIEKZ
        , LANDL
        , LZBKZ
        , TXKRS
        , CTXKRS
        , EMPFB
        , BVTYP
        , HBKID
        , ZUONR
        , ZLSPR
        , ZLSCH
        , ZFBDT
        , KIDNO
        , REBZG
        , REBZJ
        , XINVE
        , EGMLD
        , XEGDR
        , VATDATE
        , HKONT
        , J_1BNFTYPE
        , BRNCH
        , ERFPR
        , SECCO
        , NAME1
        , NAME2
        , NAME3
        , NAME4
        , PSTLZ
        , ORT01
        , LAND1
        , STRAS
        , PFACH
        , PSTL2
        , PSKTO
        , BANKN
        , BANKL
        , BANKS
        , STCD1
        , STCD2
        , STKZU
        , STKZA
        , REGIO
        , BKONT
        , DTAWS
        , DTAMS
        , SPRAS
        , XCPDK
        , EMPFG
        , FITYP
        , STCDT
        , STKZN
        , STCD3
        , STCD4
        , BKREF
        , J_1KFREPRE
        , J_1KFTBUS
        , J_1KFTIND
        , ANRED
        , STCEG
        , ERNAME
        , REINDAT
        , UZAWE
        , FDLEV
        , FDTAG
        , ZBFIX
        , FRGKZ
        , ERFNAM
        , BUPLA
        , FILKD
        , GSBER
        , LOTKZ
        , SGTXT
        , INV_TRAN
        , PREPAY_STATUS
        , PREPAY_AWKEY
        , ASSIGN_STATUS
        , ASSIGN_NEXT_DATE
        , ASSIGN_END_DATE
        , COPY_BY_BELNR
        , COPY_BY_YEAR
        , COPY_TO_BELNR
        , COPY_TO_YEAR
        , COPY_USER
        , KURSX
        , WWERT
        , XREF3
        , J_1TPBUPL
        , PYBASTYP
        , PYBASNO
        , PYBASDAT
        , PYIBAN
        , INWARDNO_HD
        , INWARDDT_HD
        , GLREQUEST
        , GLDELFLAG
        , GLSOURCESYSTEM
        , GLCHANGETIME
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , BKCC
        , REC_SRC
        , LOAD_DTS
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(BELNR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as SUPPLIER_INVOICE_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(LIFNR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as SUPPLIER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(BELNR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(LIFNR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as LNK_SUPPLIER_INVOICE_SUPPLIER_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(MANDT::text), '^^') 
            , '||', IFNULL(TRIM(GJAHR::text), '^^') 
            , '||', IFNULL(TRIM(BLART::text), '^^') 
            , '||', IFNULL(TRIM(BLDAT::text), '^^') 
            , '||', IFNULL(TRIM(BUDAT::text), '^^') 
            , '||', IFNULL(TRIM(USNAM::text), '^^') 
            , '||', IFNULL(TRIM(TCODE::text), '^^') 
            , '||', IFNULL(TRIM(CPUDT::text), '^^') 
            , '||', IFNULL(TRIM(CPUTM::text), '^^') 
            , '||', IFNULL(TRIM(VGART::text), '^^') 
            , '||', IFNULL(TRIM(XBLNR::text), '^^') 
            , '||', IFNULL(TRIM(BUKRS::text), '^^') 
            , '||', IFNULL(TRIM(LIFNR::text), '^^') 
            , '||', IFNULL(TRIM(WAERS::text), '^^') 
            , '||', IFNULL(TRIM(KURSF::text), '^^') 
            , '||', IFNULL(TRIM(RMWWR::text), '^^') 
            , '||', IFNULL(TRIM(BEZNK::text), '^^') 
            , '||', IFNULL(TRIM(WMWST1::text), '^^') 
            , '||', IFNULL(TRIM(MWSKZ1::text), '^^') 
            , '||', IFNULL(TRIM(WMWST2::text), '^^') 
            , '||', IFNULL(TRIM(MWSKZ2::text), '^^') 
            , '||', IFNULL(TRIM(ZTERM::text), '^^') 
            , '||', IFNULL(TRIM(ZBD1T::text), '^^') 
            , '||', IFNULL(TRIM(ZBD1P::text), '^^') 
            , '||', IFNULL(TRIM(ZBD2T::text), '^^') 
            , '||', IFNULL(TRIM(ZBD2P::text), '^^') 
            , '||', IFNULL(TRIM(ZBD3T::text), '^^') 
            , '||', IFNULL(TRIM(WSKTO::text), '^^') 
            , '||', IFNULL(TRIM(XRECH::text), '^^') 
            , '||', IFNULL(TRIM(BKTXT::text), '^^') 
            , '||', IFNULL(TRIM(SAPRL::text), '^^') 
            , '||', IFNULL(TRIM(LOGSYS::text), '^^') 
            , '||', IFNULL(TRIM(XMWST::text), '^^') 
            , '||', IFNULL(TRIM(STBLG::text), '^^') 
            , '||', IFNULL(TRIM(STJAH::text), '^^') 
            , '||', IFNULL(TRIM(MWSKZ_BNK::text), '^^') 
            , '||', IFNULL(TRIM(TXJCD_BNK::text), '^^') 
            , '||', IFNULL(TRIM(IVTYP::text), '^^') 
            , '||', IFNULL(TRIM(XRBTX::text), '^^') 
            , '||', IFNULL(TRIM(REPART::text), '^^') 
            , '||', IFNULL(TRIM(RBSTAT::text), '^^') 
            , '||', IFNULL(TRIM(KNUMVE::text), '^^') 
            , '||', IFNULL(TRIM(KNUMVL::text), '^^') 
            , '||', IFNULL(TRIM(ARKUEN::text), '^^') 
            , '||', IFNULL(TRIM(ARKUEMW::text), '^^') 
            , '||', IFNULL(TRIM(MAKZN::text), '^^') 
            , '||', IFNULL(TRIM(MAKZMW::text), '^^') 
            , '||', IFNULL(TRIM(LIEFFN::text), '^^') 
            , '||', IFNULL(TRIM(LIEFFMW::text), '^^') 
            , '||', IFNULL(TRIM(XAUTAKZ::text), '^^') 
            , '||', IFNULL(TRIM(ESRNR::text), '^^') 
            , '||', IFNULL(TRIM(ESRPZ::text), '^^') 
            , '||', IFNULL(TRIM(ESRRE::text), '^^') 
            , '||', IFNULL(TRIM(QSSHB::text), '^^') 
            , '||', IFNULL(TRIM(QSFBT::text), '^^') 
            , '||', IFNULL(TRIM(QSSKZ::text), '^^') 
            , '||', IFNULL(TRIM(DIEKZ::text), '^^') 
            , '||', IFNULL(TRIM(LANDL::text), '^^') 
            , '||', IFNULL(TRIM(LZBKZ::text), '^^') 
            , '||', IFNULL(TRIM(TXKRS::text), '^^') 
            , '||', IFNULL(TRIM(CTXKRS::text), '^^') 
            , '||', IFNULL(TRIM(EMPFB::text), '^^') 
            , '||', IFNULL(TRIM(BVTYP::text), '^^') 
            , '||', IFNULL(TRIM(HBKID::text), '^^') 
            , '||', IFNULL(TRIM(ZUONR::text), '^^') 
            , '||', IFNULL(TRIM(ZLSPR::text), '^^') 
            , '||', IFNULL(TRIM(ZLSCH::text), '^^') 
            , '||', IFNULL(TRIM(ZFBDT::text), '^^') 
            , '||', IFNULL(TRIM(KIDNO::text), '^^') 
            , '||', IFNULL(TRIM(REBZG::text), '^^') 
            , '||', IFNULL(TRIM(REBZJ::text), '^^') 
            , '||', IFNULL(TRIM(XINVE::text), '^^') 
            , '||', IFNULL(TRIM(EGMLD::text), '^^') 
            , '||', IFNULL(TRIM(XEGDR::text), '^^') 
            , '||', IFNULL(TRIM(VATDATE::text), '^^') 
            , '||', IFNULL(TRIM(HKONT::text), '^^') 
            , '||', IFNULL(TRIM(J_1BNFTYPE::text), '^^') 
            , '||', IFNULL(TRIM(BRNCH::text), '^^') 
            , '||', IFNULL(TRIM(ERFPR::text), '^^') 
            , '||', IFNULL(TRIM(SECCO::text), '^^') 
            , '||', IFNULL(TRIM(NAME1::text), '^^') 
            , '||', IFNULL(TRIM(NAME2::text), '^^') 
            , '||', IFNULL(TRIM(NAME3::text), '^^') 
            , '||', IFNULL(TRIM(NAME4::text), '^^') 
            , '||', IFNULL(TRIM(PSTLZ::text), '^^') 
            , '||', IFNULL(TRIM(ORT01::text), '^^') 
            , '||', IFNULL(TRIM(LAND1::text), '^^') 
            , '||', IFNULL(TRIM(STRAS::text), '^^') 
            , '||', IFNULL(TRIM(PFACH::text), '^^') 
            , '||', IFNULL(TRIM(PSTL2::text), '^^') 
            , '||', IFNULL(TRIM(PSKTO::text), '^^') 
            , '||', IFNULL(TRIM(BANKN::text), '^^') 
            , '||', IFNULL(TRIM(BANKL::text), '^^') 
            , '||', IFNULL(TRIM(BANKS::text), '^^') 
            , '||', IFNULL(TRIM(STCD1::text), '^^') 
            , '||', IFNULL(TRIM(STCD2::text), '^^') 
            , '||', IFNULL(TRIM(STKZU::text), '^^') 
            , '||', IFNULL(TRIM(STKZA::text), '^^') 
            , '||', IFNULL(TRIM(REGIO::text), '^^') 
            , '||', IFNULL(TRIM(BKONT::text), '^^') 
            , '||', IFNULL(TRIM(DTAWS::text), '^^') 
            , '||', IFNULL(TRIM(DTAMS::text), '^^') 
            , '||', IFNULL(TRIM(SPRAS::text), '^^') 
            , '||', IFNULL(TRIM(XCPDK::text), '^^') 
            , '||', IFNULL(TRIM(EMPFG::text), '^^') 
            , '||', IFNULL(TRIM(FITYP::text), '^^') 
            , '||', IFNULL(TRIM(STCDT::text), '^^') 
            , '||', IFNULL(TRIM(STKZN::text), '^^') 
            , '||', IFNULL(TRIM(STCD3::text), '^^') 
            , '||', IFNULL(TRIM(STCD4::text), '^^') 
            , '||', IFNULL(TRIM(BKREF::text), '^^') 
            , '||', IFNULL(TRIM(J_1KFREPRE::text), '^^') 
            , '||', IFNULL(TRIM(J_1KFTBUS::text), '^^') 
            , '||', IFNULL(TRIM(J_1KFTIND::text), '^^') 
            , '||', IFNULL(TRIM(ANRED::text), '^^') 
            , '||', IFNULL(TRIM(STCEG::text), '^^') 
            , '||', IFNULL(TRIM(ERNAME::text), '^^') 
            , '||', IFNULL(TRIM(REINDAT::text), '^^') 
            , '||', IFNULL(TRIM(UZAWE::text), '^^') 
            , '||', IFNULL(TRIM(FDLEV::text), '^^') 
            , '||', IFNULL(TRIM(FDTAG::text), '^^') 
            , '||', IFNULL(TRIM(ZBFIX::text), '^^') 
            , '||', IFNULL(TRIM(FRGKZ::text), '^^') 
            , '||', IFNULL(TRIM(ERFNAM::text), '^^') 
            , '||', IFNULL(TRIM(BUPLA::text), '^^') 
            , '||', IFNULL(TRIM(FILKD::text), '^^') 
            , '||', IFNULL(TRIM(GSBER::text), '^^') 
            , '||', IFNULL(TRIM(LOTKZ::text), '^^') 
            , '||', IFNULL(TRIM(SGTXT::text), '^^') 
            , '||', IFNULL(TRIM(INV_TRAN::text), '^^') 
            , '||', IFNULL(TRIM(PREPAY_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(PREPAY_AWKEY::text), '^^') 
            , '||', IFNULL(TRIM(ASSIGN_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(ASSIGN_NEXT_DATE::text), '^^') 
            , '||', IFNULL(TRIM(ASSIGN_END_DATE::text), '^^') 
            , '||', IFNULL(TRIM(COPY_BY_BELNR::text), '^^') 
            , '||', IFNULL(TRIM(COPY_BY_YEAR::text), '^^') 
            , '||', IFNULL(TRIM(COPY_TO_BELNR::text), '^^') 
            , '||', IFNULL(TRIM(COPY_TO_YEAR::text), '^^') 
            , '||', IFNULL(TRIM(COPY_USER::text), '^^') 
            , '||', IFNULL(TRIM(KURSX::text), '^^') 
            , '||', IFNULL(TRIM(WWERT::text), '^^') 
            , '||', IFNULL(TRIM(XREF3::text), '^^') 
            , '||', IFNULL(TRIM(J_1TPBUPL::text), '^^') 
            , '||', IFNULL(TRIM(PYBASTYP::text), '^^') 
            , '||', IFNULL(TRIM(PYBASNO::text), '^^') 
            , '||', IFNULL(TRIM(PYBASDAT::text), '^^') 
            , '||', IFNULL(TRIM(PYIBAN::text), '^^') 
            , '||', IFNULL(TRIM(INWARDNO_HD::text), '^^') 
            , '||', IFNULL(TRIM(INWARDDT_HD::text), '^^') 
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
