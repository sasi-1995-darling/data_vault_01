---- SRC LAYER ----
WITH
SRC_S              as ( SELECT * FROM {{ source('sap_ecc_prd', 'z_vbrk') }} as SRC  ),
SRC_A              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S              as ( SELECT * FROM sap_ecc_prd.z_vbrk )
, SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        to_char(coalesce(VBELN,'-1')) as SALES_INVOICE_BK
      , VBELN
      , to_char(coalesce(KUNAG,'-1')) as PAYER_CUST_BK
      , to_char(coalesce(KUNRG,'-1')) as SOLD_TO_CUST_BK
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
        ))   as                                    LOAD_DTS 
      , MANDT
      , GLREQUEST
      , FKART
      , FKTYP
      , VBTYP
      , WAERK
      , VKORG
      , VTWEG
      , KALSM
      , KNUMV
      , VSBED
      , FKDAT
      , BELNR
      , GJAHR
      , POPER
      , KONDA
      , KDGRP
      , BZIRK
      , PLTYP
      , INCO1
      , INCO2
      , EXPKZ
      , RFBSK
      , MRNKZ
      , KURRF
      , CPKUR
      , VALTG
      , VALDT
      , ZTERM
      , ZLSCH
      , KTGRD
      , LAND1
      , REGIO
      , COUNC
      , CITYC
      , BUKRS
      , TAXK1
      , TAXK2
      , TAXK3
      , TAXK4
      , TAXK5
      , TAXK6
      , TAXK7
      , TAXK8
      , TAXK9
      , NETWR
      , ZUKRI
      , ERNAM
      , ERZET
      , ERDAT
      , STAFO
      , KUNRG
      , KUNAG
      , MABER
      , STWAE
      , EXNUM
      , STCEG
      , AEDAT
      , SFAKN
      , KNUMA
      , FKART_RL
      , FKDAT_RL
      , KURST
      , MSCHL
      , MANSP
      , SPART
      , KKBER
      , KNKLI
      , CMWAE
      , CMKUF
      , HITYP_PR
      , BSTNK_VF
      , VBUND
      , FKART_AB
      , KAPPL
      , LANDTX
      , STCEG_H
      , STCEG_L
      , XBLNR
      , ZUONR
      , MWSBK
      , LOGSYS
      , FKSTO
      , XEGDR
      , RPLNR
      , LCNUM
      , J_1AFITP
      , KURRF_DAT
      , AKWAE
      , AKKUR
      , KIDNO
      , BVTYP
      , NUMPG
      , BUPLA
      , VKONT
      , FKK_DOCSTAT
      , NRZAS
      , SPE_BILLING_IND
      , VTREF
      , FK_SOURCE_SYS
      , FKTYP_CRM
      , STGRD
      , VBTYP_EXT
      , J_1TPBUPL
      , INCOV
      , INCO2_L
      , INCO3_L
      , DPC_REL
      , MNDID
      , PAY_TYPE
      , SEPON
      , MNDVG
      , SPPAYM
      , SPPORD
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , CONVERT_TIMEZONE('UTC', TO_TIMESTAMP(
            SUBSTR(GLCHANGETIME, 1, 8) || ' ' ||
            SUBSTR(GLCHANGETIME, 9, 2) || ':' ||
            SUBSTR(GLCHANGETIME, 11, 2) || ':' ||
            SUBSTR(GLCHANGETIME, 13, 2) || '.' ||
            REGEXP_REPLACE(SUBSTR(GLCHANGETIME, 16), '^\\.', ''),
            'YYYYMMDD HH24:MI:SS.FF9'
        ))                                                           as                                  GLCHANGETIME_DTTM
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
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
        SALES_INVOICE_BK
      , VBELN
      , PAYER_CUST_BK
      , SOLD_TO_CUST_BK
      , LOAD_DTS
      , MANDT
      , GLREQUEST
      , FKART
      , FKTYP
      , VBTYP
      , WAERK
      , VKORG
      , VTWEG
      , KALSM
      , KNUMV
      , VSBED
      , FKDAT
      , BELNR
      , GJAHR
      , POPER
      , KONDA
      , KDGRP
      , BZIRK
      , PLTYP
      , INCO1
      , INCO2
      , EXPKZ
      , RFBSK
      , MRNKZ
      , KURRF
      , CPKUR
      , VALTG
      , VALDT
      , ZTERM
      , ZLSCH
      , KTGRD
      , LAND1
      , REGIO
      , COUNC
      , CITYC
      , BUKRS
      , TAXK1
      , TAXK2
      , TAXK3
      , TAXK4
      , TAXK5
      , TAXK6
      , TAXK7
      , TAXK8
      , TAXK9
      , NETWR
      , ZUKRI
      , ERNAM
      , ERZET
      , ERDAT
      , STAFO
      , KUNRG
      , KUNAG
      , MABER
      , STWAE
      , EXNUM
      , STCEG
      , AEDAT
      , SFAKN
      , KNUMA
      , FKART_RL
      , FKDAT_RL
      , KURST
      , MSCHL
      , MANSP
      , SPART
      , KKBER
      , KNKLI
      , CMWAE
      , CMKUF
      , HITYP_PR
      , BSTNK_VF
      , VBUND
      , FKART_AB
      , KAPPL
      , LANDTX
      , STCEG_H
      , STCEG_L
      , XBLNR
      , ZUONR
      , MWSBK
      , LOGSYS
      , FKSTO
      , XEGDR
      , RPLNR
      , LCNUM
      , J_1AFITP
      , KURRF_DAT
      , AKWAE
      , AKKUR
      , KIDNO
      , BVTYP
      , NUMPG
      , BUPLA
      , VKONT
      , FKK_DOCSTAT
      , NRZAS
      , SPE_BILLING_IND
      , VTREF
      , FK_SOURCE_SYS
      , FKTYP_CRM
      , STGRD
      , VBTYP_EXT
      , J_1TPBUPL
      , INCOV
      , INCO2_L
      , INCO3_L
      , DPC_REL
      , MNDID
      , PAY_TYPE
      , SEPON
      , MNDVG
      , SPPAYM
      , SPPORD
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , GLCHANGETIME_DTTM
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
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
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_VBRK'
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
          SALES_INVOICE_BK
        , VBELN
        , PAYER_CUST_BK
        , SOLD_TO_CUST_BK
        , LOAD_DTS
        , MANDT
        , GLREQUEST
        , FKART
        , FKTYP
        , VBTYP
        , WAERK
        , VKORG
        , VTWEG
        , KALSM
        , KNUMV
        , VSBED
        , FKDAT
        , BELNR
        , GJAHR
        , POPER
        , KONDA
        , KDGRP
        , BZIRK
        , PLTYP
        , INCO1
        , INCO2
        , EXPKZ
        , RFBSK
        , MRNKZ
        , KURRF
        , CPKUR
        , VALTG
        , VALDT
        , ZTERM
        , ZLSCH
        , KTGRD
        , LAND1
        , REGIO
        , COUNC
        , CITYC
        , BUKRS
        , TAXK1
        , TAXK2
        , TAXK3
        , TAXK4
        , TAXK5
        , TAXK6
        , TAXK7
        , TAXK8
        , TAXK9
        , NETWR
        , ZUKRI
        , ERNAM
        , ERZET
        , ERDAT
        , STAFO
        , KUNRG
        , KUNAG
        , MABER
        , STWAE
        , EXNUM
        , STCEG
        , AEDAT
        , SFAKN
        , KNUMA
        , FKART_RL
        , FKDAT_RL
        , KURST
        , MSCHL
        , MANSP
        , SPART
        , KKBER
        , KNKLI
        , CMWAE
        , CMKUF
        , HITYP_PR
        , BSTNK_VF
        , VBUND
        , FKART_AB
        , KAPPL
        , LANDTX
        , STCEG_H
        , STCEG_L
        , XBLNR
        , ZUONR
        , MWSBK
        , LOGSYS
        , FKSTO
        , XEGDR
        , RPLNR
        , LCNUM
        , J_1AFITP
        , KURRF_DAT
        , AKWAE
        , AKKUR
        , KIDNO
        , BVTYP
        , NUMPG
        , BUPLA
        , VKONT
        , FKK_DOCSTAT
        , NRZAS
        , SPE_BILLING_IND
        , VTREF
        , FK_SOURCE_SYS
        , FKTYP_CRM
        , STGRD
        , VBTYP_EXT
        , J_1TPBUPL
        , INCOV
        , INCO2_L
        , INCO3_L
        , DPC_REL
        , MNDID
        , PAY_TYPE
        , SEPON
        , MNDVG
        , SPPAYM
        , SPPORD
        , GLDELFLAG
        , GLCHANGETIME
        , GLSOURCESYSTEM
        , GLCHANGETIME_DTTM
        , PSA_DELETE_IND
        , PSA_LOAD_DTS
        , REC_SRC
        , BKCC
        , IFF(VBELN IS NULL, '-1', CONCAT_WS('||', VBELN, BKCC)) as drvd_si_bkcc
        , IFF(KUNAG IS NULL, '-1', CONCAT_WS('||', KUNAG, BKCC)) as drvd_pc_bkcc
        , IFF(KUNRG IS NULL, '-1', CONCAT_WS('||', KUNRG, BKCC)) as drvd_stc_bkcc
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(drvd_si_bkcc as VARCHAR)),''), '^^')
        ))) as SALES_INVOICE_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(drvd_pc_bkcc as VARCHAR)),''), '^^')
        ))) as  PAYER_CUST_HK
      , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(drvd_stc_bkcc as VARCHAR)),''), '^^')
        )))   as SOLD_TO_CUST_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(VBELN::text), '^^') 
            , '||', IFNULL(TRIM(FKART::text), '^^') 
            , '||', IFNULL(TRIM(FKTYP::text), '^^') 
            , '||', IFNULL(TRIM(VBTYP::text), '^^') 
            , '||', IFNULL(TRIM(WAERK::text), '^^') 
            , '||', IFNULL(TRIM(VKORG::text), '^^') 
            , '||', IFNULL(TRIM(VTWEG::text), '^^') 
            , '||', IFNULL(TRIM(KALSM::text), '^^') 
            , '||', IFNULL(TRIM(KNUMV::text), '^^') 
            , '||', IFNULL(TRIM(VSBED::text), '^^') 
            , '||', IFNULL(TRIM(FKDAT::text), '^^') 
            , '||', IFNULL(TRIM(BELNR::text), '^^') 
            , '||', IFNULL(TRIM(GJAHR::text), '^^') 
            , '||', IFNULL(TRIM(POPER::text), '^^') 
            , '||', IFNULL(TRIM(KONDA::text), '^^') 
            , '||', IFNULL(TRIM(KDGRP::text), '^^') 
            , '||', IFNULL(TRIM(BZIRK::text), '^^') 
            , '||', IFNULL(TRIM(PLTYP::text), '^^') 
            , '||', IFNULL(TRIM(INCO1::text), '^^') 
            , '||', IFNULL(TRIM(INCO2::text), '^^') 
            , '||', IFNULL(TRIM(EXPKZ::text), '^^') 
            , '||', IFNULL(TRIM(RFBSK::text), '^^') 
            , '||', IFNULL(TRIM(MRNKZ::text), '^^') 
            , '||', IFNULL(TRIM(KURRF::text), '^^') 
            , '||', IFNULL(TRIM(CPKUR::text), '^^') 
            , '||', IFNULL(TRIM(VALTG::text), '^^') 
            , '||', IFNULL(TRIM(VALDT::text), '^^') 
            , '||', IFNULL(TRIM(ZTERM::text), '^^') 
            , '||', IFNULL(TRIM(ZLSCH::text), '^^') 
            , '||', IFNULL(TRIM(KTGRD::text), '^^') 
            , '||', IFNULL(TRIM(LAND1::text), '^^') 
            , '||', IFNULL(TRIM(REGIO::text), '^^') 
            , '||', IFNULL(TRIM(COUNC::text), '^^') 
            , '||', IFNULL(TRIM(CITYC::text), '^^') 
            , '||', IFNULL(TRIM(BUKRS::text), '^^') 
            , '||', IFNULL(TRIM(TAXK1::text), '^^') 
            , '||', IFNULL(TRIM(TAXK2::text), '^^') 
            , '||', IFNULL(TRIM(TAXK3::text), '^^') 
            , '||', IFNULL(TRIM(TAXK4::text), '^^') 
            , '||', IFNULL(TRIM(TAXK5::text), '^^') 
            , '||', IFNULL(TRIM(TAXK6::text), '^^') 
            , '||', IFNULL(TRIM(TAXK7::text), '^^') 
            , '||', IFNULL(TRIM(TAXK8::text), '^^') 
            , '||', IFNULL(TRIM(TAXK9::text), '^^') 
            , '||', IFNULL(TRIM(NETWR::text), '^^') 
            , '||', IFNULL(TRIM(ZUKRI::text), '^^') 
            , '||', IFNULL(TRIM(ERNAM::text), '^^') 
            , '||', IFNULL(TRIM(ERZET::text), '^^') 
            , '||', IFNULL(TRIM(ERDAT::text), '^^') 
            , '||', IFNULL(TRIM(STAFO::text), '^^') 
            , '||', IFNULL(TRIM(KUNRG::text), '^^') 
            , '||', IFNULL(TRIM(KUNAG::text), '^^') 
            , '||', IFNULL(TRIM(MABER::text), '^^') 
            , '||', IFNULL(TRIM(STWAE::text), '^^') 
            , '||', IFNULL(TRIM(EXNUM::text), '^^') 
            , '||', IFNULL(TRIM(STCEG::text), '^^') 
            , '||', IFNULL(TRIM(AEDAT::text), '^^') 
            , '||', IFNULL(TRIM(SFAKN::text), '^^') 
            , '||', IFNULL(TRIM(KNUMA::text), '^^') 
            , '||', IFNULL(TRIM(FKART_RL::text), '^^') 
            , '||', IFNULL(TRIM(FKDAT_RL::text), '^^') 
            , '||', IFNULL(TRIM(KURST::text), '^^') 
            , '||', IFNULL(TRIM(MSCHL::text), '^^') 
            , '||', IFNULL(TRIM(MANSP::text), '^^') 
            , '||', IFNULL(TRIM(SPART::text), '^^') 
            , '||', IFNULL(TRIM(KKBER::text), '^^') 
            , '||', IFNULL(TRIM(KNKLI::text), '^^') 
            , '||', IFNULL(TRIM(CMWAE::text), '^^') 
            , '||', IFNULL(TRIM(CMKUF::text), '^^') 
            , '||', IFNULL(TRIM(HITYP_PR::text), '^^') 
            , '||', IFNULL(TRIM(BSTNK_VF::text), '^^') 
            , '||', IFNULL(TRIM(VBUND::text), '^^') 
            , '||', IFNULL(TRIM(FKART_AB::text), '^^') 
            , '||', IFNULL(TRIM(KAPPL::text), '^^') 
            , '||', IFNULL(TRIM(LANDTX::text), '^^') 
            , '||', IFNULL(TRIM(STCEG_H::text), '^^') 
            , '||', IFNULL(TRIM(STCEG_L::text), '^^') 
            , '||', IFNULL(TRIM(XBLNR::text), '^^') 
            , '||', IFNULL(TRIM(ZUONR::text), '^^') 
            , '||', IFNULL(TRIM(MWSBK::text), '^^') 
            , '||', IFNULL(TRIM(LOGSYS::text), '^^') 
            , '||', IFNULL(TRIM(FKSTO::text), '^^') 
            , '||', IFNULL(TRIM(XEGDR::text), '^^') 
            , '||', IFNULL(TRIM(RPLNR::text), '^^') 
            , '||', IFNULL(TRIM(LCNUM::text), '^^') 
            , '||', IFNULL(TRIM(J_1AFITP::text), '^^') 
            , '||', IFNULL(TRIM(KURRF_DAT::text), '^^') 
            , '||', IFNULL(TRIM(AKWAE::text), '^^') 
            , '||', IFNULL(TRIM(AKKUR::text), '^^') 
            , '||', IFNULL(TRIM(KIDNO::text), '^^') 
            , '||', IFNULL(TRIM(BVTYP::text), '^^') 
            , '||', IFNULL(TRIM(NUMPG::text), '^^') 
            , '||', IFNULL(TRIM(BUPLA::text), '^^') 
            , '||', IFNULL(TRIM(VKONT::text), '^^') 
            , '||', IFNULL(TRIM(FKK_DOCSTAT::text), '^^') 
            , '||', IFNULL(TRIM(NRZAS::text), '^^') 
            , '||', IFNULL(TRIM(SPE_BILLING_IND::text), '^^') 
            , '||', IFNULL(TRIM(VTREF::text), '^^') 
            , '||', IFNULL(TRIM(FK_SOURCE_SYS::text), '^^') 
            , '||', IFNULL(TRIM(FKTYP_CRM::text), '^^') 
            , '||', IFNULL(TRIM(STGRD::text), '^^') 
            , '||', IFNULL(TRIM(VBTYP_EXT::text), '^^') 
            , '||', IFNULL(TRIM(J_1TPBUPL::text), '^^') 
            , '||', IFNULL(TRIM(INCOV::text), '^^') 
            , '||', IFNULL(TRIM(INCO2_L::text), '^^') 
            , '||', IFNULL(TRIM(INCO3_L::text), '^^') 
            , '||', IFNULL(TRIM(DPC_REL::text), '^^') 
            , '||', IFNULL(TRIM(MNDID::text), '^^') 
            , '||', IFNULL(TRIM(PAY_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(SEPON::text), '^^') 
            , '||', IFNULL(TRIM(MNDVG::text), '^^') 
            , '||', IFNULL(TRIM(SPPAYM::text), '^^') 
            , '||', IFNULL(TRIM(SPPORD::text), '^^') 
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
