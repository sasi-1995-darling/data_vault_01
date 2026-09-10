---- SRC LAYER ----
WITH
SRC_G              as ( SELECT *  FROM {{ source('sap_ecc_prd', 'z_glpca') }} as SRC),
SRC_A              as ( SELECT REC_SRC, BKCC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_G              as ( SELECT * FROM sap_ecc_prd.Z_GLPCA )
SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_G as (
    SELECT    
      RCLNT
      , GL_SIRID
      , GLREQUEST
      , RLDNR
      , RRCTY
      , RVERS
      , RYEAR
      , RTCUR
      , RUNIT
      , DRCRK
      , POPER
      , DOCCT
      , DOCNR
      , DOCLN
      , RBUKRS
      , RPRCTR
      , RHOART
      , RFAREA
      , KOKRS
      , RACCT
      , HRKFT
      , RASSC
      , EPRCTR
      , ACTIV
      , AFABE
      , OCLNT
      , SBUKRS
      , SPRCTR
      , SHOART
      , SFAREA
      , TSL
      , HSL
      , KSL
      , MSL
      , CPUDT
      , CPUTM
      , USNAM
      , SGTXT
      , AUTOM
      , DOCTY
      , BLDAT
      , BUDAT
      , WSDAT
      , REFDOCNR
      , REFRYEAR
      , REFDOCLN
      , REFDOCCT
      , REFACTIV
      , AWTYP
      , AWORG
      , WERKS
      , GSBER
      , KOSTL
      , LSTAR
      , AUFNR
      , AUFPL
      , ANLN1
      , ANLN2
      , MATNR
      , BWKEY
      , BWTAR
      , ANBWA
      , KUNNR
      , LIFNR
      , RMVCT
      , EBELN
      , EBELP
      , KSTRG
      , ERKRS
      , PAOBJNR
      , PASUBNR
      , PS_PSP_PNR
      , KDAUF
      , KDPOS
      , FKART
      , VKORG
      , VTWEG
      , AUBEL
      , AUPOS
      , SPART
      , VBELN
      , POSNR
      , VKGRP
      , VKBUR
      , VBUND
      , LOGSYS
      , ALEBN
      , AWSYS
      , VERSA
      , STFLG
      , STOKZ
      , STAGR
      , GRTYP
      , REP_MATNR
      , CO_PRZNR
      , IMKEY
      , DABRZ
      , VALUT
      , RSCOPE
      , AWREF_REV
      , AWORG_REV
      , BWART
      , BLART
      , GLDELFLAG
      , GLSOURCESYSTEM
      , PSA_DELETE_IND
      , PSA_RECORD_SOURCE
      , PSA_LOAD_DTS
      , CONVERT_TIMEZONE('UTC',PSA_LOAD_DTS)                         as                                           LOAD_DTS
    FROM SRC_G
)

, LOGIC_A as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_A
)
---- RENAME LAYER ----

, RENAME_G as (
    SELECT
        coalesce(nullif(trim(RCLNT), ''), '-1')                                as                                          CLIENT_BK
      , coalesce(nullif(trim(GL_SIRID), ''), '-1')                             as                  RECORD_NUM_OF_LINE_ITEM_RECORD_BK
      , coalesce(nullif(trim(RBUKRS), ''), '-1')                               as                                    LEGAL_ENTITY_BK
      , coalesce(nullif(trim(DOCNR), ''), '-1')                                as                                      GL_ACCOUNT_BK
      , coalesce(nullif(trim(PAOBJNR), ''), '-1')                              as                                   OBJECT_NUMBER_BK
      , coalesce(nullif(trim(DOCLN), ''), '-1')                                as                                   DOCUMENT_LINE_BK
      , coalesce(nullif(trim(BUDAT), ''), '-1')                                as                                    POSTING_DATE_BK
      , coalesce(nullif(trim(RYEAR), ''), '-1')                                as                        ACCOUNTING_FISCAL_PERIOD_BK
      , coalesce(nullif(trim(RPRCTR), ''), '-1')                               as                                   PROFIT_CENTER_BK
      , coalesce(nullif(trim(RLDNR), ''), '-1')                                as                                          LEDGER_BK
      , LOAD_DTS
      , RCLNT
      , GL_SIRID
      , GLREQUEST
      , RLDNR
      , RRCTY
      , RVERS
      , RYEAR
      , RTCUR
      , RUNIT
      , DRCRK
      , POPER
      , DOCCT
      , DOCNR
      , DOCLN
      , RBUKRS
      , RPRCTR
      , RHOART
      , RFAREA
      , KOKRS
      , RACCT
      , HRKFT
      , RASSC
      , EPRCTR
      , ACTIV
      , AFABE
      , OCLNT
      , SBUKRS
      , SPRCTR
      , SHOART
      , SFAREA
      , TSL
      , HSL
      , KSL
      , MSL
      , CPUDT
      , CPUTM
      , USNAM
      , SGTXT
      , AUTOM
      , DOCTY
      , BLDAT
      , BUDAT
      , WSDAT
      , REFDOCNR
      , REFRYEAR
      , REFDOCLN
      , REFDOCCT
      , REFACTIV
      , AWTYP
      , AWORG
      , WERKS
      , GSBER
      , KOSTL
      , LSTAR
      , AUFNR
      , AUFPL
      , ANLN1
      , ANLN2
      , MATNR
      , BWKEY
      , BWTAR
      , ANBWA
      , KUNNR
      , LIFNR
      , RMVCT
      , EBELN
      , EBELP
      , KSTRG
      , ERKRS
      , PAOBJNR
      , PASUBNR
      , PS_PSP_PNR
      , KDAUF
      , KDPOS
      , FKART
      , VKORG
      , VTWEG
      , AUBEL
      , AUPOS
      , SPART
      , VBELN
      , POSNR
      , VKGRP
      , VKBUR
      , VBUND
      , LOGSYS
      , ALEBN
      , AWSYS
      , VERSA
      , STFLG
      , STOKZ
      , STAGR
      , GRTYP
      , REP_MATNR
      , CO_PRZNR
      , IMKEY
      , DABRZ
      , VALUT
      , RSCOPE
      , AWREF_REV
      , AWORG_REV
      , BWART
      , BLART
      , GLDELFLAG
      , GLSOURCESYSTEM
      , PSA_DELETE_IND
      , PSA_RECORD_SOURCE
      , PSA_LOAD_DTS
    FROM LOGIC_G
)

, RENAME_A as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_A
)
---- FILTER LAYER ----

, FILTER_G as (
    SELECT *
    FROM RENAME_G
)

, FILTER_A as (
    SELECT *
    FROM RENAME_A
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_GLPCA'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_G
    INNER JOIN FILTER_A
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          CLIENT_BK
        , RECORD_NUM_OF_LINE_ITEM_RECORD_BK
        , LEGAL_ENTITY_BK
        , LEDGER_BK
        , ACCOUNTING_FISCAL_PERIOD_BK
        , GL_ACCOUNT_BK
        , OBJECT_NUMBER_BK
        , PROFIT_CENTER_BK
        , LOAD_DTS
        , RCLNT
        , GL_SIRID
        , GLREQUEST
        , RLDNR
        , RRCTY
        , RVERS
        , RYEAR
        , RTCUR
        , RUNIT
        , DRCRK
        , POPER
        , DOCCT
        , DOCNR
        , DOCLN
        , RBUKRS
        , RPRCTR
        , RHOART
        , RFAREA
        , KOKRS
        , RACCT
        , HRKFT
        , RASSC
        , EPRCTR
        , ACTIV
        , AFABE
        , OCLNT
        , SBUKRS
        , SPRCTR
        , SHOART
        , SFAREA
        , TSL
        , HSL
        , KSL
        , MSL
        , CPUDT
        , CPUTM
        , USNAM
        , SGTXT
        , AUTOM
        , DOCTY
        , BLDAT
        , BUDAT
        , WSDAT
        , REFDOCNR
        , REFRYEAR
        , REFDOCLN
        , REFDOCCT
        , REFACTIV
        , AWTYP
        , AWORG
        , WERKS
        , GSBER
        , KOSTL
        , LSTAR
        , AUFNR
        , AUFPL
        , ANLN1
        , ANLN2
        , MATNR
        , BWKEY
        , BWTAR
        , ANBWA
        , KUNNR
        , LIFNR
        , RMVCT
        , EBELN
        , EBELP
        , KSTRG
        , ERKRS
        , PAOBJNR
        , PASUBNR
        , PS_PSP_PNR
        , KDAUF
        , KDPOS
        , FKART
        , VKORG
        , VTWEG
        , AUBEL
        , AUPOS
        , SPART
        , VBELN
        , POSNR
        , VKGRP
        , VKBUR
        , VBUND
        , LOGSYS
        , ALEBN
        , AWSYS
        , VERSA
        , STFLG
        , STOKZ
        , STAGR
        , GRTYP
        , REP_MATNR
        , CO_PRZNR
        , IMKEY
        , DABRZ
        , VALUT
        , RSCOPE
        , AWREF_REV
        , AWORG_REV
        , BWART
        , BLART
        , GLDELFLAG
        , GLSOURCESYSTEM
        , PSA_DELETE_IND
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(CLIENT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as CLIENT_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(RECORD_NUM_OF_LINE_ITEM_RECORD_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as RECORD_NUM_OF_LINE_ITEM_RECORD_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(LEGAL_ENTITY_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as LEGAL_ENTITY_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(LEDGER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as LEDGER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(GL_ACCOUNT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as GL_ACCOUNT_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(OBJECT_NUMBER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as OBJECT_NUMBER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PROFIT_CENTER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PROFIT_CENTER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ACCOUNTING_FISCAL_PERIOD_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ACCOUNTING_FISCAL_PERIOD_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(RECORD_NUM_OF_LINE_ITEM_RECORD_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(LEGAL_ENTITY_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(LEDGER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(PROFIT_CENTER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(GL_ACCOUNT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(ACCOUNTING_FISCAL_PERIOD_BK as VARCHAR)),''), '^^')                        
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PROFIT_CENTER_POSTINGS_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(RCLNT::text), '^^') 
            , '||', IFNULL(TRIM(GL_SIRID::text), '^^') 
            , '||', IFNULL(TRIM(RLDNR::text), '^^') 
            , '||', IFNULL(TRIM(RRCTY::text), '^^') 
            , '||', IFNULL(TRIM(RVERS::text), '^^') 
            , '||', IFNULL(TRIM(RYEAR::text), '^^') 
            , '||', IFNULL(TRIM(RTCUR::text), '^^') 
            , '||', IFNULL(TRIM(RUNIT::text), '^^') 
            , '||', IFNULL(TRIM(DRCRK::text), '^^') 
            , '||', IFNULL(TRIM(POPER::text), '^^') 
            , '||', IFNULL(TRIM(DOCCT::text), '^^') 
            , '||', IFNULL(TRIM(DOCNR::text), '^^') 
            , '||', IFNULL(TRIM(DOCLN::text), '^^') 
            , '||', IFNULL(TRIM(RBUKRS::text), '^^') 
            , '||', IFNULL(TRIM(RPRCTR::text), '^^') 
            , '||', IFNULL(TRIM(RHOART::text), '^^') 
            , '||', IFNULL(TRIM(RFAREA::text), '^^') 
            , '||', IFNULL(TRIM(KOKRS::text), '^^') 
            , '||', IFNULL(TRIM(RACCT::text), '^^') 
            , '||', IFNULL(TRIM(HRKFT::text), '^^') 
            , '||', IFNULL(TRIM(RASSC::text), '^^') 
            , '||', IFNULL(TRIM(EPRCTR::text), '^^') 
            , '||', IFNULL(TRIM(ACTIV::text), '^^') 
            , '||', IFNULL(TRIM(AFABE::text), '^^') 
            , '||', IFNULL(TRIM(OCLNT::text), '^^') 
            , '||', IFNULL(TRIM(SBUKRS::text), '^^') 
            , '||', IFNULL(TRIM(SPRCTR::text), '^^') 
            , '||', IFNULL(TRIM(SHOART::text), '^^') 
            , '||', IFNULL(TRIM(SFAREA::text), '^^') 
            , '||', IFNULL(TRIM(TSL::text), '^^') 
            , '||', IFNULL(TRIM(HSL::text), '^^') 
            , '||', IFNULL(TRIM(KSL::text), '^^') 
            , '||', IFNULL(TRIM(MSL::text), '^^') 
            , '||', IFNULL(TRIM(CPUDT::text), '^^') 
            , '||', IFNULL(TRIM(CPUTM::text), '^^') 
            , '||', IFNULL(TRIM(USNAM::text), '^^') 
            , '||', IFNULL(TRIM(SGTXT::text), '^^') 
            , '||', IFNULL(TRIM(AUTOM::text), '^^') 
            , '||', IFNULL(TRIM(DOCTY::text), '^^') 
            , '||', IFNULL(TRIM(BLDAT::text), '^^') 
            , '||', IFNULL(TRIM(BUDAT::text), '^^') 
            , '||', IFNULL(TRIM(WSDAT::text), '^^') 
            , '||', IFNULL(TRIM(REFDOCNR::text), '^^') 
            , '||', IFNULL(TRIM(REFRYEAR::text), '^^') 
            , '||', IFNULL(TRIM(REFDOCLN::text), '^^') 
            , '||', IFNULL(TRIM(REFDOCCT::text), '^^') 
            , '||', IFNULL(TRIM(REFACTIV::text), '^^') 
            , '||', IFNULL(TRIM(AWTYP::text), '^^') 
            , '||', IFNULL(TRIM(AWORG::text), '^^') 
            , '||', IFNULL(TRIM(WERKS::text), '^^') 
            , '||', IFNULL(TRIM(GSBER::text), '^^') 
            , '||', IFNULL(TRIM(KOSTL::text), '^^') 
            , '||', IFNULL(TRIM(LSTAR::text), '^^') 
            , '||', IFNULL(TRIM(AUFNR::text), '^^') 
            , '||', IFNULL(TRIM(AUFPL::text), '^^') 
            , '||', IFNULL(TRIM(ANLN1::text), '^^') 
            , '||', IFNULL(TRIM(ANLN2::text), '^^') 
            , '||', IFNULL(TRIM(MATNR::text), '^^') 
            , '||', IFNULL(TRIM(BWKEY::text), '^^') 
            , '||', IFNULL(TRIM(BWTAR::text), '^^') 
            , '||', IFNULL(TRIM(ANBWA::text), '^^') 
            , '||', IFNULL(TRIM(KUNNR::text), '^^') 
            , '||', IFNULL(TRIM(LIFNR::text), '^^') 
            , '||', IFNULL(TRIM(RMVCT::text), '^^') 
            , '||', IFNULL(TRIM(EBELN::text), '^^') 
            , '||', IFNULL(TRIM(EBELP::text), '^^') 
            , '||', IFNULL(TRIM(KSTRG::text), '^^') 
            , '||', IFNULL(TRIM(ERKRS::text), '^^') 
            , '||', IFNULL(TRIM(PAOBJNR::text), '^^') 
            , '||', IFNULL(TRIM(PASUBNR::text), '^^') 
            , '||', IFNULL(TRIM(PS_PSP_PNR::text), '^^') 
            , '||', IFNULL(TRIM(KDAUF::text), '^^') 
            , '||', IFNULL(TRIM(KDPOS::text), '^^') 
            , '||', IFNULL(TRIM(FKART::text), '^^') 
            , '||', IFNULL(TRIM(VKORG::text), '^^') 
            , '||', IFNULL(TRIM(VTWEG::text), '^^') 
            , '||', IFNULL(TRIM(AUBEL::text), '^^') 
            , '||', IFNULL(TRIM(AUPOS::text), '^^') 
            , '||', IFNULL(TRIM(SPART::text), '^^') 
            , '||', IFNULL(TRIM(VBELN::text), '^^') 
            , '||', IFNULL(TRIM(POSNR::text), '^^') 
            , '||', IFNULL(TRIM(VKGRP::text), '^^') 
            , '||', IFNULL(TRIM(VKBUR::text), '^^') 
            , '||', IFNULL(TRIM(VBUND::text), '^^') 
            , '||', IFNULL(TRIM(LOGSYS::text), '^^') 
            , '||', IFNULL(TRIM(ALEBN::text), '^^') 
            , '||', IFNULL(TRIM(AWSYS::text), '^^') 
            , '||', IFNULL(TRIM(VERSA::text), '^^') 
            , '||', IFNULL(TRIM(STFLG::text), '^^') 
            , '||', IFNULL(TRIM(STOKZ::text), '^^') 
            , '||', IFNULL(TRIM(STAGR::text), '^^') 
            , '||', IFNULL(TRIM(GRTYP::text), '^^') 
            , '||', IFNULL(TRIM(REP_MATNR::text), '^^') 
            , '||', IFNULL(TRIM(CO_PRZNR::text), '^^') 
            , '||', IFNULL(TRIM(IMKEY::text), '^^') 
            , '||', IFNULL(TRIM(DABRZ::text), '^^') 
            , '||', IFNULL(TRIM(VALUT::text), '^^') 
            , '||', IFNULL(TRIM(RSCOPE::text), '^^') 
            , '||', IFNULL(TRIM(AWREF_REV::text), '^^') 
            , '||', IFNULL(TRIM(AWORG_REV::text), '^^') 
            , '||', IFNULL(TRIM(BWART::text), '^^') 
            , '||', IFNULL(TRIM(BLART::text), '^^') 
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
