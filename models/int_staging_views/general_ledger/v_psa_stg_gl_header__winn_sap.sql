---- SRC LAYER ----
WITH
SRC_S              as ( SELECT * FROM {{ source('sap_ecc_prd', 'z_bkpf') }} as SRC  ),
SRC_A              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S              as ( SELECT * FROM sap_ecc_prd.z_bkpf )
, SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        to_char(coalesce(BUKRS,'-1'))                                                        as                                    COMPANY_CODE_BK
      , to_char(coalesce(BELNR,'-1'))                                                        as                              ACCOUNTING_DOC_NUM_BK
      , to_char(coalesce(GJAHR,'-1'))                                                        as                                     FISCAL_YEAR_BK
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
      , MANDT
      , BUKRS
      , BELNR
      , GJAHR
      , GLREQUEST
      , BLART
      , BLDAT
      , BUDAT
      , MONAT
      , CPUDT
      , CPUTM
      , AEDAT
      , UPDDT
      , WWERT
      , USNAM
      , TCODE
      , BVORG
      , XBLNR
      , DBBLG
      , STBLG
      , STJAH
      , BKTXT
      , WAERS
      , KURSF
      , KZWRS
      , KZKRS
      , BSTAT
      , XNETB
      , FRATH
      , XRUEB
      , GLVOR
      , GRPID
      , DOKID
      , ARCID
      , IBLAR
      , AWTYP
      , AWKEY
      , FIKRS
      , HWAER
      , HWAE2
      , HWAE3
      , KURS2
      , KURS3
      , BASW2
      , BASW3
      , UMRD2
      , UMRD3
      , XSTOV
      , STODT
      , XMWST
      , CURT2
      , CURT3
      , KUTY2
      , KUTY3
      , XSNET
      , AUSBK
      , XUSVR
      , DUEFL
      , AWSYS
      , TXKRS
      , CTXKRS
      , LOTKZ
      , XWVOF
      , STGRD
      , PPNAM
      , PPDAT
      , PPTME
      , BRNCH
      , NUMPG
      , ADISC
      , XREF1_HD
      , XREF2_HD
      , XREVERSAL
      , REINDAT
      , RLDNR
      , LDGRP
      , PROPMANO
      , XBLNR_ALT
      , VATDATE
      , DOCCAT
      , XSPLIT
      , CASH_ALLOC
      , FOLLOW_ON
      , XREORG
      , SUBSET
      , KURST
      , KURSX
      , KUR2X
      , KUR3X
      , XMCA
      , RESUBMISSION
      , "/SAPF15/STATUS"                                               as                                      SAPF15_STATUS
      , PSOTY
      , PSOAK
      , PSOKS
      , PSOSG
      , PSOFN
      , INTFORM
      , INTDATE
      , PSOBT
      , PSOZL
      , PSODT
      , PSOTM
      , FM_UMART
      , CCINS
      , CCNUM
      , SSBLK
      , BATCH
      , SNAME
      , SAMPLED
      , EXCLUDE_FLAG
      , BLIND
      , OFFSET_STATUS
      , OFFSET_REFER_DAT
      , PENRC
      , KNUMV
      , PYBASTYP
      , PYBASNO
      , PYBASDAT
      , PYIBAN
      , INWARDNO_HD
      , INWARDDT_HD
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
        COMPANY_CODE_BK
      , ACCOUNTING_DOC_NUM_BK
      , FISCAL_YEAR_BK
      , LOAD_DTS
      , MANDT
      , BUKRS
      , BELNR
      , GJAHR
      , GLREQUEST
      , BLART
      , BLDAT
      , BUDAT
      , MONAT
      , CPUDT
      , CPUTM
      , AEDAT
      , UPDDT
      , WWERT
      , USNAM
      , TCODE
      , BVORG
      , XBLNR
      , DBBLG
      , STBLG
      , STJAH
      , BKTXT
      , WAERS
      , KURSF
      , KZWRS
      , KZKRS
      , BSTAT
      , XNETB
      , FRATH
      , XRUEB
      , GLVOR
      , GRPID
      , DOKID
      , ARCID
      , IBLAR
      , AWTYP
      , AWKEY
      , FIKRS
      , HWAER
      , HWAE2
      , HWAE3
      , KURS2
      , KURS3
      , BASW2
      , BASW3
      , UMRD2
      , UMRD3
      , XSTOV
      , STODT
      , XMWST
      , CURT2
      , CURT3
      , KUTY2
      , KUTY3
      , XSNET
      , AUSBK
      , XUSVR
      , DUEFL
      , AWSYS
      , TXKRS
      , CTXKRS
      , LOTKZ
      , XWVOF
      , STGRD
      , PPNAM
      , PPDAT
      , PPTME
      , BRNCH
      , NUMPG
      , ADISC
      , XREF1_HD
      , XREF2_HD
      , XREVERSAL
      , REINDAT
      , RLDNR
      , LDGRP
      , PROPMANO
      , XBLNR_ALT
      , VATDATE
      , DOCCAT
      , XSPLIT
      , CASH_ALLOC
      , FOLLOW_ON
      , XREORG
      , SUBSET
      , KURST
      , KURSX
      , KUR2X
      , KUR3X
      , XMCA
      , RESUBMISSION
      , SAPF15_STATUS
      , PSOTY
      , PSOAK
      , PSOKS
      , PSOSG
      , PSOFN
      , INTFORM
      , INTDATE
      , PSOBT
      , PSOZL
      , PSODT
      , PSOTM
      , FM_UMART
      , CCINS
      , CCNUM
      , SSBLK
      , BATCH
      , SNAME
      , SAMPLED
      , EXCLUDE_FLAG
      , BLIND
      , OFFSET_STATUS
      , OFFSET_REFER_DAT
      , PENRC
      , KNUMV
      , PYBASTYP
      , PYBASNO
      , PYBASDAT
      , PYIBAN
      , INWARDNO_HD
      , INWARDDT_HD
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
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_BKPF'
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
          COMPANY_CODE_BK
        , ACCOUNTING_DOC_NUM_BK
        , FISCAL_YEAR_BK
        , LOAD_DTS
        , MANDT
        , BUKRS
        , BELNR
        , GJAHR
        , GLREQUEST
        , BLART
        , BLDAT
        , BUDAT
        , MONAT
        , CPUDT
        , CPUTM
        , AEDAT
        , UPDDT
        , WWERT
        , USNAM
        , TCODE
        , BVORG
        , XBLNR
        , DBBLG
        , STBLG
        , STJAH
        , BKTXT
        , WAERS
        , KURSF
        , KZWRS
        , KZKRS
        , BSTAT
        , XNETB
        , FRATH
        , XRUEB
        , GLVOR
        , GRPID
        , DOKID
        , ARCID
        , IBLAR
        , AWTYP
        , AWKEY
        , FIKRS
        , HWAER
        , HWAE2
        , HWAE3
        , KURS2
        , KURS3
        , BASW2
        , BASW3
        , UMRD2
        , UMRD3
        , XSTOV
        , STODT
        , XMWST
        , CURT2
        , CURT3
        , KUTY2
        , KUTY3
        , XSNET
        , AUSBK
        , XUSVR
        , DUEFL
        , AWSYS
        , TXKRS
        , CTXKRS
        , LOTKZ
        , XWVOF
        , STGRD
        , PPNAM
        , PPDAT
        , PPTME
        , BRNCH
        , NUMPG
        , ADISC
        , XREF1_HD
        , XREF2_HD
        , XREVERSAL
        , REINDAT
        , RLDNR
        , LDGRP
        , PROPMANO
        , XBLNR_ALT
        , VATDATE
        , DOCCAT
        , XSPLIT
        , CASH_ALLOC
        , FOLLOW_ON
        , XREORG
        , SUBSET
        , KURST
        , KURSX
        , KUR2X
        , KUR3X
        , XMCA
        , RESUBMISSION
        , SAPF15_STATUS
        , PSOTY
        , PSOAK
        , PSOKS
        , PSOSG
        , PSOFN
        , INTFORM
        , INTDATE
        , PSOBT
        , PSOZL
        , PSODT
        , PSOTM
        , FM_UMART
        , CCINS
        , CCNUM
        , SSBLK
        , BATCH
        , SNAME
        , SAMPLED
        , EXCLUDE_FLAG
        , BLIND
        , OFFSET_STATUS
        , OFFSET_REFER_DAT
        , PENRC
        , KNUMV
        , PYBASTYP
        , PYBASNO
        , PYBASDAT
        , PYIBAN
        , INWARDNO_HD
        , INWARDDT_HD
        , GLDELFLAG
        , GLCHANGETIME
        , GLSOURCESYSTEM
        , GLCHANGETIME_DTTM
        , PSA_DELETE_IND
        , PSA_LOAD_DTS
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(COMPANY_CODE_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(ACCOUNTING_DOC_NUM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(FISCAL_YEAR_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as GENERAL_LEDGER_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(MANDT::text), '^^') 
            , '||', IFNULL(TRIM(BUKRS::text), '^^') 
            , '||', IFNULL(TRIM(BELNR::text), '^^') 
            , '||', IFNULL(TRIM(GJAHR::text), '^^') 
            , '||', IFNULL(TRIM(BLART::text), '^^') 
            , '||', IFNULL(TRIM(BLDAT::text), '^^') 
            , '||', IFNULL(TRIM(BUDAT::text), '^^') 
            , '||', IFNULL(TRIM(MONAT::text), '^^') 
            , '||', IFNULL(TRIM(CPUDT::text), '^^') 
            , '||', IFNULL(TRIM(CPUTM::text), '^^') 
            , '||', IFNULL(TRIM(AEDAT::text), '^^') 
            , '||', IFNULL(TRIM(UPDDT::text), '^^') 
            , '||', IFNULL(TRIM(WWERT::text), '^^') 
            , '||', IFNULL(TRIM(USNAM::text), '^^') 
            , '||', IFNULL(TRIM(TCODE::text), '^^') 
            , '||', IFNULL(TRIM(BVORG::text), '^^') 
            , '||', IFNULL(TRIM(XBLNR::text), '^^') 
            , '||', IFNULL(TRIM(DBBLG::text), '^^') 
            , '||', IFNULL(TRIM(STBLG::text), '^^') 
            , '||', IFNULL(TRIM(STJAH::text), '^^') 
            , '||', IFNULL(TRIM(BKTXT::text), '^^') 
            , '||', IFNULL(TRIM(WAERS::text), '^^') 
            , '||', IFNULL(TRIM(KURSF::text), '^^') 
            , '||', IFNULL(TRIM(KZWRS::text), '^^') 
            , '||', IFNULL(TRIM(KZKRS::text), '^^') 
            , '||', IFNULL(TRIM(BSTAT::text), '^^') 
            , '||', IFNULL(TRIM(XNETB::text), '^^') 
            , '||', IFNULL(TRIM(FRATH::text), '^^') 
            , '||', IFNULL(TRIM(XRUEB::text), '^^') 
            , '||', IFNULL(TRIM(GLVOR::text), '^^') 
            , '||', IFNULL(TRIM(GRPID::text), '^^') 
            , '||', IFNULL(TRIM(DOKID::text), '^^') 
            , '||', IFNULL(TRIM(ARCID::text), '^^') 
            , '||', IFNULL(TRIM(IBLAR::text), '^^') 
            , '||', IFNULL(TRIM(AWTYP::text), '^^') 
            , '||', IFNULL(TRIM(AWKEY::text), '^^') 
            , '||', IFNULL(TRIM(FIKRS::text), '^^') 
            , '||', IFNULL(TRIM(HWAER::text), '^^') 
            , '||', IFNULL(TRIM(HWAE2::text), '^^') 
            , '||', IFNULL(TRIM(HWAE3::text), '^^') 
            , '||', IFNULL(TRIM(KURS2::text), '^^') 
            , '||', IFNULL(TRIM(KURS3::text), '^^') 
            , '||', IFNULL(TRIM(BASW2::text), '^^') 
            , '||', IFNULL(TRIM(BASW3::text), '^^') 
            , '||', IFNULL(TRIM(UMRD2::text), '^^') 
            , '||', IFNULL(TRIM(UMRD3::text), '^^') 
            , '||', IFNULL(TRIM(XSTOV::text), '^^') 
            , '||', IFNULL(TRIM(STODT::text), '^^') 
            , '||', IFNULL(TRIM(XMWST::text), '^^') 
            , '||', IFNULL(TRIM(CURT2::text), '^^') 
            , '||', IFNULL(TRIM(CURT3::text), '^^') 
            , '||', IFNULL(TRIM(KUTY2::text), '^^') 
            , '||', IFNULL(TRIM(KUTY3::text), '^^') 
            , '||', IFNULL(TRIM(XSNET::text), '^^') 
            , '||', IFNULL(TRIM(AUSBK::text), '^^') 
            , '||', IFNULL(TRIM(XUSVR::text), '^^') 
            , '||', IFNULL(TRIM(DUEFL::text), '^^') 
            , '||', IFNULL(TRIM(AWSYS::text), '^^') 
            , '||', IFNULL(TRIM(TXKRS::text), '^^') 
            , '||', IFNULL(TRIM(CTXKRS::text), '^^') 
            , '||', IFNULL(TRIM(LOTKZ::text), '^^') 
            , '||', IFNULL(TRIM(XWVOF::text), '^^') 
            , '||', IFNULL(TRIM(STGRD::text), '^^') 
            , '||', IFNULL(TRIM(PPNAM::text), '^^') 
            , '||', IFNULL(TRIM(PPDAT::text), '^^') 
            , '||', IFNULL(TRIM(PPTME::text), '^^') 
            , '||', IFNULL(TRIM(BRNCH::text), '^^') 
            , '||', IFNULL(TRIM(NUMPG::text), '^^') 
            , '||', IFNULL(TRIM(ADISC::text), '^^') 
            , '||', IFNULL(TRIM(XREF1_HD::text), '^^') 
            , '||', IFNULL(TRIM(XREF2_HD::text), '^^') 
            , '||', IFNULL(TRIM(XREVERSAL::text), '^^') 
            , '||', IFNULL(TRIM(REINDAT::text), '^^') 
            , '||', IFNULL(TRIM(RLDNR::text), '^^') 
            , '||', IFNULL(TRIM(LDGRP::text), '^^') 
            , '||', IFNULL(TRIM(PROPMANO::text), '^^') 
            , '||', IFNULL(TRIM(XBLNR_ALT::text), '^^') 
            , '||', IFNULL(TRIM(VATDATE::text), '^^') 
            , '||', IFNULL(TRIM(DOCCAT::text), '^^') 
            , '||', IFNULL(TRIM(XSPLIT::text), '^^') 
            , '||', IFNULL(TRIM(CASH_ALLOC::text), '^^') 
            , '||', IFNULL(TRIM(FOLLOW_ON::text), '^^') 
            , '||', IFNULL(TRIM(XREORG::text), '^^') 
            , '||', IFNULL(TRIM(SUBSET::text), '^^') 
            , '||', IFNULL(TRIM(KURST::text), '^^') 
            , '||', IFNULL(TRIM(KURSX::text), '^^') 
            , '||', IFNULL(TRIM(KUR2X::text), '^^') 
            , '||', IFNULL(TRIM(KUR3X::text), '^^') 
            , '||', IFNULL(TRIM(XMCA::text), '^^') 
            , '||', IFNULL(TRIM(RESUBMISSION::text), '^^') 
            , '||', IFNULL(TRIM(SAPF15_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(PSOTY::text), '^^') 
            , '||', IFNULL(TRIM(PSOAK::text), '^^') 
            , '||', IFNULL(TRIM(PSOKS::text), '^^') 
            , '||', IFNULL(TRIM(PSOSG::text), '^^') 
            , '||', IFNULL(TRIM(PSOFN::text), '^^') 
            , '||', IFNULL(TRIM(INTFORM::text), '^^') 
            , '||', IFNULL(TRIM(INTDATE::text), '^^') 
            , '||', IFNULL(TRIM(PSOBT::text), '^^') 
            , '||', IFNULL(TRIM(PSOZL::text), '^^') 
            , '||', IFNULL(TRIM(PSODT::text), '^^') 
            , '||', IFNULL(TRIM(PSOTM::text), '^^') 
            , '||', IFNULL(TRIM(FM_UMART::text), '^^') 
            , '||', IFNULL(TRIM(CCINS::text), '^^') 
            , '||', IFNULL(TRIM(CCNUM::text), '^^') 
            , '||', IFNULL(TRIM(SSBLK::text), '^^') 
            , '||', IFNULL(TRIM(BATCH::text), '^^') 
            , '||', IFNULL(TRIM(SNAME::text), '^^') 
            , '||', IFNULL(TRIM(SAMPLED::text), '^^') 
            , '||', IFNULL(TRIM(EXCLUDE_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(BLIND::text), '^^') 
            , '||', IFNULL(TRIM(OFFSET_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(OFFSET_REFER_DAT::text), '^^') 
            , '||', IFNULL(TRIM(PENRC::text), '^^') 
            , '||', IFNULL(TRIM(KNUMV::text), '^^') 
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
