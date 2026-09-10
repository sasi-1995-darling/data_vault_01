---- SRC LAYER ----
WITH
SRC_gp             as ( SELECT * FROM {{ source('tt_gpd', 'dbo_pm00200') }} as SRC  ),
SRC_A              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_gp             as ( SELECT * FROM tt_gpd.dbo_pm00200 )
, SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_gp as (
    SELECT
        VENDORID                                                     as                                        SUPPLIER_BK
      , PYMTRMID                                                     as                                       PAYMENT_TERM_BK
      , VENDORID
      , VENDNAME
      , VNDCHKNM
      , VENDSHNM
      , VADDCDPR
      , VADCDPAD
      , VADCDSFR
      , VADCDTRO
      , VNDCLSID
      , VNDCNTCT
      , ADDRESS1
      , ADDRESS2
      , ADDRESS3
      , CITY
      , STATE
      , ZIPCODE
      , COUNTRY
      , PHNUMBR1
      , PHNUMBR2
      , PHONE3
      , FAXNUMBR
      , UPSZONE
      , SHIPMTHD
      , TAXSCHID
      , ACNMVNDR
      , TXIDNMBR
      , VENDSTTS
      , CURNCYID
      , TXRGNNUM
      , PARVENID
      , TRDDISCT
      , TEN99TYPE
      , MINORDER
      , PYMTRMID
      , MINPYTYP
      , MINPYPCT
      , MINPYDLR
      , MXIAFVND
      , MAXINDLR
      , COMMENT1
      , COMMENT2
      , USERDEF1
      , USERDEF2
      , CRLMTDLR
      , PYMNTPRI
      , KPCALHST
      , KGLDSTHS
      , KPERHIST
      , KPTRXHST
      , HOLD
      , PTCSHACF
      , CREDTLMT
      , WRITEOFF
      , MXWOFAMT
      , SBPPSDED
      , PPSTAXRT
      , DXVARNUM
      , CRTCOMDT
      , CRTEXPDT
      , RTOBUTKN
      , XPDTOBLG
      , PRSPAYEE
      , PMAPINDX
      , PMCSHIDX
      , PMDAVIDX
      , PMDTKIDX
      , PMFINIDX
      , PMMSCHIX
      , PMFRTIDX
      , PMTAXIDX
      , PMWRTIDX
      , PMPRCHIX
      , PMRTNGIX
      , PMTDSCIX
      , ACPURIDX
      , PURPVIDX
      , NOTEINDX
      , CHEKBKID
      , MODIFDT
      , CREATDDT
      , RATETPID
      , REVALUE_VENDOR
      , POST_RESULTS_TO
      , FREEONBOARD
      , GOVCRPID
      , GOVINDID
      , DISGRPER
      , DUEGRPER
      , DOCFMTID
      , TAXINVRECVD
      , USERLANG
      , WITHHOLDINGTYPE
      , WITHHOLDINGFORMTYPE
      , WITHHOLDINGENTITYTYPE
      , TAXFILENUMMODE
      , BRTHDATE
      , LABORPMTTYPE
      , CCODE
      , DECLID
      , CBVAT
      , DEX_ROW_ID
      , PSA_LOAD_DTS
      , PSA_DELETE_IND
      , CONVERT_TIMEZONE('UTC', PSA_LOAD_DTS)                        as                                           LOAD_DTS
    FROM SRC_gp
)

, LOGIC_A as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_A
)
---- RENAME LAYER ----

, RENAME_gp as (
    SELECT
        SUPPLIER_BK
      , PAYMENT_TERM_BK
      , VENDORID
      , VENDNAME
      , VNDCHKNM
      , VENDSHNM
      , VADDCDPR
      , VADCDPAD
      , VADCDSFR
      , VADCDTRO
      , VNDCLSID
      , VNDCNTCT
      , ADDRESS1
      , ADDRESS2
      , ADDRESS3
      , CITY
      , STATE
      , ZIPCODE
      , COUNTRY
      , PHNUMBR1
      , PHNUMBR2
      , PHONE3
      , FAXNUMBR
      , UPSZONE
      , SHIPMTHD
      , TAXSCHID
      , ACNMVNDR
      , TXIDNMBR
      , VENDSTTS
      , CURNCYID
      , TXRGNNUM
      , PARVENID
      , TRDDISCT
      , TEN99TYPE
      , MINORDER
      , PYMTRMID
      , MINPYTYP
      , MINPYPCT
      , MINPYDLR
      , MXIAFVND
      , MAXINDLR
      , COMMENT1
      , COMMENT2
      , USERDEF1
      , USERDEF2
      , CRLMTDLR
      , PYMNTPRI
      , KPCALHST
      , KGLDSTHS
      , KPERHIST
      , KPTRXHST
      , HOLD
      , PTCSHACF
      , CREDTLMT
      , WRITEOFF
      , MXWOFAMT
      , SBPPSDED
      , PPSTAXRT
      , DXVARNUM
      , CRTCOMDT
      , CRTEXPDT
      , RTOBUTKN
      , XPDTOBLG
      , PRSPAYEE
      , PMAPINDX
      , PMCSHIDX
      , PMDAVIDX
      , PMDTKIDX
      , PMFINIDX
      , PMMSCHIX
      , PMFRTIDX
      , PMTAXIDX
      , PMWRTIDX
      , PMPRCHIX
      , PMRTNGIX
      , PMTDSCIX
      , ACPURIDX
      , PURPVIDX
      , NOTEINDX
      , CHEKBKID
      , MODIFDT
      , CREATDDT
      , RATETPID
      , REVALUE_VENDOR
      , POST_RESULTS_TO
      , FREEONBOARD
      , GOVCRPID
      , GOVINDID
      , DISGRPER
      , DUEGRPER
      , DOCFMTID
      , TAXINVRECVD
      , USERLANG
      , WITHHOLDINGTYPE
      , WITHHOLDINGFORMTYPE
      , WITHHOLDINGENTITYTYPE
      , TAXFILENUMMODE
      , BRTHDATE
      , LABORPMTTYPE
      , CCODE
      , DECLID
      , CBVAT
      , DEX_ROW_ID
      , PSA_LOAD_DTS
      , PSA_DELETE_IND
      , LOAD_DTS
    FROM LOGIC_gp
)

, RENAME_A as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_A
)
---- FILTER LAYER ----

, FILTER_gp as (
    SELECT *
    FROM RENAME_gp
)

, FILTER_A as (
    SELECT *
    FROM RENAME_A
    WHERE rec_src = 'USOHMA.MSSQL.GPPRD.DBO_PM00200'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_gp
    INNER JOIN FILTER_A
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          SUPPLIER_BK
        , PAYMENT_TERM_BK
        , VENDORID
        , VENDNAME
        , VNDCHKNM
        , VENDSHNM
        , VADDCDPR
        , VADCDPAD
        , VADCDSFR
        , VADCDTRO
        , VNDCLSID
        , VNDCNTCT
        , ADDRESS1
        , ADDRESS2
        , ADDRESS3
        , CITY
        , STATE
        , ZIPCODE
        , COUNTRY
        , PHNUMBR1
        , PHNUMBR2
        , PHONE3
        , FAXNUMBR
        , UPSZONE
        , SHIPMTHD
        , TAXSCHID
        , ACNMVNDR
        , TXIDNMBR
        , VENDSTTS
        , CURNCYID
        , TXRGNNUM
        , PARVENID
        , TRDDISCT
        , TEN99TYPE
        , MINORDER
        , PYMTRMID
        , MINPYTYP
        , MINPYPCT
        , MINPYDLR
        , MXIAFVND
        , MAXINDLR
        , COMMENT1
        , COMMENT2
        , USERDEF1
        , USERDEF2
        , CRLMTDLR
        , PYMNTPRI
        , KPCALHST
        , KGLDSTHS
        , KPERHIST
        , KPTRXHST
        , HOLD
        , PTCSHACF
        , CREDTLMT
        , WRITEOFF
        , MXWOFAMT
        , SBPPSDED
        , PPSTAXRT
        , DXVARNUM
        , CRTCOMDT
        , CRTEXPDT
        , RTOBUTKN
        , XPDTOBLG
        , PRSPAYEE
        , PMAPINDX
        , PMCSHIDX
        , PMDAVIDX
        , PMDTKIDX
        , PMFINIDX
        , PMMSCHIX
        , PMFRTIDX
        , PMTAXIDX
        , PMWRTIDX
        , PMPRCHIX
        , PMRTNGIX
        , PMTDSCIX
        , ACPURIDX
        , PURPVIDX
        , NOTEINDX
        , CHEKBKID
        , MODIFDT
        , CREATDDT
        , RATETPID
        , REVALUE_VENDOR
        , POST_RESULTS_TO
        , FREEONBOARD
        , GOVCRPID
        , GOVINDID
        , DISGRPER
        , DUEGRPER
        , DOCFMTID
        , TAXINVRECVD
        , USERLANG
        , WITHHOLDINGTYPE
        , WITHHOLDINGFORMTYPE
        , WITHHOLDINGENTITYTYPE
        , TAXFILENUMMODE
        , BRTHDATE
        , LABORPMTTYPE
        , CCODE
        , DECLID
        , CBVAT
        , DEX_ROW_ID
        , PSA_LOAD_DTS
        , PSA_DELETE_IND
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , IFF(
               COALESCE(NULLIF(TRIM(CAST(PYMTRMID as VARCHAR)), ''), '^^') = '^^'
             , '-2'
             , CONCAT_WS('||',
                   COALESCE(NULLIF(TRIM(CAST(PYMTRMID as VARCHAR)), ''), '^^')
                 , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)), ''), '^^')
               )
           )  as DRVD_PAYMENT_TERM_BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(VENDORID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as SUPPLIER_HK
        ,MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(DRVD_PAYMENT_TERM_BKCC as VARCHAR)),''), '^^')
        ))) as PAYMENT_TERM_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(VENDORID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(PYMTRMID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as LNK_SUPPLIER_PAYMENT_TERM_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(VENDNAME::text), '^^') 
            , '||', IFNULL(TRIM(VNDCHKNM::text), '^^') 
            , '||', IFNULL(TRIM(VENDSHNM::text), '^^') 
            , '||', IFNULL(TRIM(VADDCDPR::text), '^^') 
            , '||', IFNULL(TRIM(VADCDPAD::text), '^^') 
            , '||', IFNULL(TRIM(VADCDSFR::text), '^^') 
            , '||', IFNULL(TRIM(VADCDTRO::text), '^^') 
            , '||', IFNULL(TRIM(VNDCLSID::text), '^^') 
            , '||', IFNULL(TRIM(VNDCNTCT::text), '^^') 
            , '||', IFNULL(TRIM(ADDRESS1::text), '^^') 
            , '||', IFNULL(TRIM(ADDRESS2::text), '^^') 
            , '||', IFNULL(TRIM(ADDRESS3::text), '^^') 
            , '||', IFNULL(TRIM(CITY::text), '^^') 
            , '||', IFNULL(TRIM(STATE::text), '^^') 
            , '||', IFNULL(TRIM(ZIPCODE::text), '^^') 
            , '||', IFNULL(TRIM(COUNTRY::text), '^^') 
            , '||', IFNULL(TRIM(PHNUMBR1::text), '^^') 
            , '||', IFNULL(TRIM(PHNUMBR2::text), '^^') 
            , '||', IFNULL(TRIM(PHONE3::text), '^^') 
            , '||', IFNULL(TRIM(FAXNUMBR::text), '^^') 
            , '||', IFNULL(TRIM(UPSZONE::text), '^^') 
            , '||', IFNULL(TRIM(SHIPMTHD::text), '^^') 
            , '||', IFNULL(TRIM(TAXSCHID::text), '^^') 
            , '||', IFNULL(TRIM(ACNMVNDR::text), '^^') 
            , '||', IFNULL(TRIM(TXIDNMBR::text), '^^') 
            , '||', IFNULL(TRIM(VENDSTTS::text), '^^') 
            , '||', IFNULL(TRIM(CURNCYID::text), '^^') 
            , '||', IFNULL(TRIM(TXRGNNUM::text), '^^') 
            , '||', IFNULL(TRIM(PARVENID::text), '^^') 
            , '||', IFNULL(TRIM(TRDDISCT::text), '^^') 
            , '||', IFNULL(TRIM(TEN99TYPE::text), '^^') 
            , '||', IFNULL(TRIM(MINORDER::text), '^^') 
            , '||', IFNULL(TRIM(PYMTRMID::text), '^^') 
            , '||', IFNULL(TRIM(MINPYTYP::text), '^^') 
            , '||', IFNULL(TRIM(MINPYPCT::text), '^^') 
            , '||', IFNULL(TRIM(MINPYDLR::text), '^^') 
            , '||', IFNULL(TRIM(MXIAFVND::text), '^^') 
            , '||', IFNULL(TRIM(MAXINDLR::text), '^^') 
            , '||', IFNULL(TRIM(COMMENT1::text), '^^') 
            , '||', IFNULL(TRIM(COMMENT2::text), '^^') 
            , '||', IFNULL(TRIM(USERDEF1::text), '^^') 
            , '||', IFNULL(TRIM(USERDEF2::text), '^^') 
            , '||', IFNULL(TRIM(CRLMTDLR::text), '^^') 
            , '||', IFNULL(TRIM(PYMNTPRI::text), '^^') 
            , '||', IFNULL(TRIM(KPCALHST::text), '^^') 
            , '||', IFNULL(TRIM(KGLDSTHS::text), '^^') 
            , '||', IFNULL(TRIM(KPERHIST::text), '^^') 
            , '||', IFNULL(TRIM(KPTRXHST::text), '^^') 
            , '||', IFNULL(TRIM(HOLD::text), '^^') 
            , '||', IFNULL(TRIM(PTCSHACF::text), '^^') 
            , '||', IFNULL(TRIM(CREDTLMT::text), '^^') 
            , '||', IFNULL(TRIM(WRITEOFF::text), '^^') 
            , '||', IFNULL(TRIM(MXWOFAMT::text), '^^') 
            , '||', IFNULL(TRIM(SBPPSDED::text), '^^') 
            , '||', IFNULL(TRIM(PPSTAXRT::text), '^^') 
            , '||', IFNULL(TRIM(DXVARNUM::text), '^^') 
            , '||', IFNULL(TRIM(CRTCOMDT::text), '^^') 
            , '||', IFNULL(TRIM(CRTEXPDT::text), '^^') 
            , '||', IFNULL(TRIM(RTOBUTKN::text), '^^') 
            , '||', IFNULL(TRIM(XPDTOBLG::text), '^^') 
            , '||', IFNULL(TRIM(PRSPAYEE::text), '^^') 
            , '||', IFNULL(TRIM(PMAPINDX::text), '^^') 
            , '||', IFNULL(TRIM(PMCSHIDX::text), '^^') 
            , '||', IFNULL(TRIM(PMDAVIDX::text), '^^') 
            , '||', IFNULL(TRIM(PMDTKIDX::text), '^^') 
            , '||', IFNULL(TRIM(PMFINIDX::text), '^^') 
            , '||', IFNULL(TRIM(PMMSCHIX::text), '^^') 
            , '||', IFNULL(TRIM(PMFRTIDX::text), '^^') 
            , '||', IFNULL(TRIM(PMTAXIDX::text), '^^') 
            , '||', IFNULL(TRIM(PMWRTIDX::text), '^^') 
            , '||', IFNULL(TRIM(PMPRCHIX::text), '^^') 
            , '||', IFNULL(TRIM(PMRTNGIX::text), '^^') 
            , '||', IFNULL(TRIM(PMTDSCIX::text), '^^') 
            , '||', IFNULL(TRIM(ACPURIDX::text), '^^') 
            , '||', IFNULL(TRIM(PURPVIDX::text), '^^') 
            , '||', IFNULL(TRIM(NOTEINDX::text), '^^') 
            , '||', IFNULL(TRIM(CHEKBKID::text), '^^') 
            , '||', IFNULL(TRIM(CREATDDT::text), '^^') 
            , '||', IFNULL(TRIM(RATETPID::text), '^^') 
            , '||', IFNULL(TRIM(REVALUE_VENDOR::text), '^^') 
            , '||', IFNULL(TRIM(POST_RESULTS_TO::text), '^^') 
            , '||', IFNULL(TRIM(FREEONBOARD::text), '^^') 
            , '||', IFNULL(TRIM(GOVCRPID::text), '^^') 
            , '||', IFNULL(TRIM(GOVINDID::text), '^^') 
            , '||', IFNULL(TRIM(DISGRPER::text), '^^') 
            , '||', IFNULL(TRIM(DUEGRPER::text), '^^') 
            , '||', IFNULL(TRIM(DOCFMTID::text), '^^') 
            , '||', IFNULL(TRIM(TAXINVRECVD::text), '^^') 
            , '||', IFNULL(TRIM(USERLANG::text), '^^') 
            , '||', IFNULL(TRIM(WITHHOLDINGTYPE::text), '^^') 
            , '||', IFNULL(TRIM(WITHHOLDINGFORMTYPE::text), '^^') 
            , '||', IFNULL(TRIM(WITHHOLDINGENTITYTYPE::text), '^^') 
            , '||', IFNULL(TRIM(TAXFILENUMMODE::text), '^^') 
            , '||', IFNULL(TRIM(BRTHDATE::text), '^^') 
            , '||', IFNULL(TRIM(LABORPMTTYPE::text), '^^') 
            , '||', IFNULL(TRIM(CCODE::text), '^^') 
            , '||', IFNULL(TRIM(DECLID::text), '^^') 
            , '||', IFNULL(TRIM(CBVAT::text), '^^') 
            , '||', IFNULL(TRIM(DEX_ROW_ID::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
