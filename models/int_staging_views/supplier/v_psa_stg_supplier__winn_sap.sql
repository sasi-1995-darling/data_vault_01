---- SRC LAYER ----
WITH
SRC_S              as ( SELECT * FROM {{ source('sap_ecc_prd', 'z_lfa1') }} as SRC  ),
SRC_A              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S              as ( SELECT * FROM sap_ecc_prd.z_lfa1 )
, SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        LIFNR                                                        as                                        SUPPLIER_BK
      , LIFNR
      , CONVERT_TIMEZONE('UTC', PSA_LOAD_DTS)                        as                                           LOAD_DTS
      , GLREQUEST
      , GLSOURCESYSTEM
      , LAND1
      , NAME1
      , NAME2
      , NAME3
      , NAME4
      , ORT01
      , ORT02
      , PFACH
      , PSTL2
      , PSTLZ
      , REGIO
      , SORTL
      , STRAS
      , ADRNR
      , MCOD1
      , MCOD2
      , MCOD3
      , ANRED
      , BAHNS
      , BBBNR
      , BBSNR
      , BEGRU
      , BRSCH
      , BUBKZ
      , DATLT
      , DTAMS
      , DTAWS
      , ERDAT
      , ERNAM
      , ESRNR
      , KONZS
      , KTOKK
      , KUNNR
      , LNRZA
      , LOEVM
      , SPERR
      , SPERM
      , SPRAS
      , STCD1
      , STCD2
      , STKZA
      , STKZU
      , TELBX
      , TELF1
      , TELF2
      , TELFX
      , TELTX
      , TELX1
      , XCPDK
      , XZEMP
      , VBUND
      , FISKN
      , STCEG
      , STKZN
      , SPERQ
      , GBORT
      , GBDAT
      , SEXKZ
      , KRAUS
      , REVDB
      , QSSYS
      , KTOCK
      , PFORT
      , WERKS
      , LTSNA
      , WERKR
      , PLKAL
      , DUEFL
      , TXJCD
      , SPERZ
      , SCACD
      , SFRGR
      , LZONE
      , XLFZA
      , DLGRP
      , FITYP
      , STCDT
      , REGSS
      , ACTSS
      , STCD3
      , STCD4
      , STCD5
      , IPISP
      , TAXBS
      , PROFS
      , STGDL
      , EMNFR
      , LFURL
      , J_1KFREPRE
      , J_1KFTBUS
      , J_1KFTIND
      , CONFS
      , UPDAT
      , UPTIM
      , NODEL
      , QSSYSDAT
      , PODKZB
      , FISKU
      , STENR
      , CARRIER_CONF
      , MIN_COMP
      , TERM_LI
      , CRC_NUM
      , CVP_XBLCK
      , RG
      , EXP
      , UF
      , RGDATE
      , RIC
      , RNE
      , RNEDATE
      , CNAE
      , LEGALNAT
      , CRTN
      , ICMSTAXPAY
      , INDTYP
      , TDT
      , COMSIZE
      , DECREGPC
      , J_SC_CAPITAL
      , J_SC_CURRENCY
      , ALC
      , PMT_OFFICE
      , PPA_RELEVANT
      , PSOFG
      , PSOIS
      , PSON1
      , PSON2
      , PSON3
      , PSOVN
      , PSOTL
      , PSOHS
      , PSOST
      , TRANSPORT_CHAIN
      , STAGING_TIME
      , SCHEDULING_TYPE
      , SUBMI_RELEVANT
      , ZZPASS
      , ZZGROUPKEY
      , ZZSUPIND
      , ZZRIMSCAR
      , ZZRIMSSPL
      , ZZTRANZACT
      , ZZAIREXP
      , ZZPLANTIND
      , ZZUNION
      , ZZUNION_EXP
      , ZZUNION_TYPE
      , ZZUNION_EXP1
      , ZZUNION_TYPE1
      , ZZASN_ACTIVE
      , ZZASN_NUMBER
      , ZZACTIVE_DT
      , ZZASN_DT
      , ZZRPT_COUNTRY
      , ZZRPT_CONTINENT
      , ZZCALENDAR
      , ZZ3RDPARTY
      , ZZMASTR_VEND
      , ZZBRGEW
      , ZZGEWEI
      , ZZSDABW
      , ZZQUOTE
      , ZZQUOTE_UNAME
      , ZZQUOTE_LAEDA
      , ZZSUPPLIERKEY
      , ZZSUPINVKEY
      , ZZTMSSCAC
      , ZZTMSMODE
      , ZZTMSSERVICE
      , ZZSCACWJEF
      , GLDELFLAG
      , GLCHANGETIME
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
        SUPPLIER_BK
      , LIFNR
      , LOAD_DTS
      , GLREQUEST
      , GLSOURCESYSTEM
      , LAND1
      , NAME1
      , NAME2
      , NAME3
      , NAME4
      , ORT01
      , ORT02
      , PFACH
      , PSTL2
      , PSTLZ
      , REGIO
      , SORTL
      , STRAS
      , ADRNR
      , MCOD1
      , MCOD2
      , MCOD3
      , ANRED
      , BAHNS
      , BBBNR
      , BBSNR
      , BEGRU
      , BRSCH
      , BUBKZ
      , DATLT
      , DTAMS
      , DTAWS
      , ERDAT
      , ERNAM
      , ESRNR
      , KONZS
      , KTOKK
      , KUNNR
      , LNRZA
      , LOEVM
      , SPERR
      , SPERM
      , SPRAS
      , STCD1
      , STCD2
      , STKZA
      , STKZU
      , TELBX
      , TELF1
      , TELF2
      , TELFX
      , TELTX
      , TELX1
      , XCPDK
      , XZEMP
      , VBUND
      , FISKN
      , STCEG
      , STKZN
      , SPERQ
      , GBORT
      , GBDAT
      , SEXKZ
      , KRAUS
      , REVDB
      , QSSYS
      , KTOCK
      , PFORT
      , WERKS
      , LTSNA
      , WERKR
      , PLKAL
      , DUEFL
      , TXJCD
      , SPERZ
      , SCACD
      , SFRGR
      , LZONE
      , XLFZA
      , DLGRP
      , FITYP
      , STCDT
      , REGSS
      , ACTSS
      , STCD3
      , STCD4
      , STCD5
      , IPISP
      , TAXBS
      , PROFS
      , STGDL
      , EMNFR
      , LFURL
      , J_1KFREPRE
      , J_1KFTBUS
      , J_1KFTIND
      , CONFS
      , UPDAT
      , UPTIM
      , NODEL
      , QSSYSDAT
      , PODKZB
      , FISKU
      , STENR
      , CARRIER_CONF
      , MIN_COMP
      , TERM_LI
      , CRC_NUM
      , CVP_XBLCK
      , RG
      , EXP
      , UF
      , RGDATE
      , RIC
      , RNE
      , RNEDATE
      , CNAE
      , LEGALNAT
      , CRTN
      , ICMSTAXPAY
      , INDTYP
      , TDT
      , COMSIZE
      , DECREGPC
      , J_SC_CAPITAL
      , J_SC_CURRENCY
      , ALC
      , PMT_OFFICE
      , PPA_RELEVANT
      , PSOFG
      , PSOIS
      , PSON1
      , PSON2
      , PSON3
      , PSOVN
      , PSOTL
      , PSOHS
      , PSOST
      , TRANSPORT_CHAIN
      , STAGING_TIME
      , SCHEDULING_TYPE
      , SUBMI_RELEVANT
      , ZZPASS
      , ZZGROUPKEY
      , ZZSUPIND
      , ZZRIMSCAR
      , ZZRIMSSPL
      , ZZTRANZACT
      , ZZAIREXP
      , ZZPLANTIND
      , ZZUNION
      , ZZUNION_EXP
      , ZZUNION_TYPE
      , ZZUNION_EXP1
      , ZZUNION_TYPE1
      , ZZASN_ACTIVE
      , ZZASN_NUMBER
      , ZZACTIVE_DT
      , ZZASN_DT
      , ZZRPT_COUNTRY
      , ZZRPT_CONTINENT
      , ZZCALENDAR
      , ZZ3RDPARTY
      , ZZMASTR_VEND
      , ZZBRGEW
      , ZZGEWEI
      , ZZSDABW
      , ZZQUOTE
      , ZZQUOTE_UNAME
      , ZZQUOTE_LAEDA
      , ZZSUPPLIERKEY
      , ZZSUPINVKEY
      , ZZTMSSCAC
      , ZZTMSMODE
      , ZZTMSSERVICE
      , ZZSCACWJEF
      , GLDELFLAG
      , GLCHANGETIME
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
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_LFA1'
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
          SUPPLIER_BK
        , LIFNR
        , LOAD_DTS
        , GLREQUEST
        , GLSOURCESYSTEM
        , LAND1
        , NAME1
        , NAME2
        , NAME3
        , NAME4
        , ORT01
        , ORT02
        , PFACH
        , PSTL2
        , PSTLZ
        , REGIO
        , SORTL
        , STRAS
        , ADRNR
        , MCOD1
        , MCOD2
        , MCOD3
        , ANRED
        , BAHNS
        , BBBNR
        , BBSNR
        , BEGRU
        , BRSCH
        , BUBKZ
        , DATLT
        , DTAMS
        , DTAWS
        , ERDAT
        , ERNAM
        , ESRNR
        , KONZS
        , KTOKK
        , KUNNR
        , LNRZA
        , LOEVM
        , SPERR
        , SPERM
        , SPRAS
        , STCD1
        , STCD2
        , STKZA
        , STKZU
        , TELBX
        , TELF1
        , TELF2
        , TELFX
        , TELTX
        , TELX1
        , XCPDK
        , XZEMP
        , VBUND
        , FISKN
        , STCEG
        , STKZN
        , SPERQ
        , GBORT
        , GBDAT
        , SEXKZ
        , KRAUS
        , REVDB
        , QSSYS
        , KTOCK
        , PFORT
        , WERKS
        , LTSNA
        , WERKR
        , PLKAL
        , DUEFL
        , TXJCD
        , SPERZ
        , SCACD
        , SFRGR
        , LZONE
        , XLFZA
        , DLGRP
        , FITYP
        , STCDT
        , REGSS
        , ACTSS
        , STCD3
        , STCD4
        , STCD5
        , IPISP
        , TAXBS
        , PROFS
        , STGDL
        , EMNFR
        , LFURL
        , J_1KFREPRE
        , J_1KFTBUS
        , J_1KFTIND
        , CONFS
        , UPDAT
        , UPTIM
        , NODEL
        , QSSYSDAT
        , PODKZB
        , FISKU
        , STENR
        , CARRIER_CONF
        , MIN_COMP
        , TERM_LI
        , CRC_NUM
        , CVP_XBLCK
        , RG
        , EXP
        , UF
        , RGDATE
        , RIC
        , RNE
        , RNEDATE
        , CNAE
        , LEGALNAT
        , CRTN
        , ICMSTAXPAY
        , INDTYP
        , TDT
        , COMSIZE
        , DECREGPC
        , J_SC_CAPITAL
        , J_SC_CURRENCY
        , ALC
        , PMT_OFFICE
        , PPA_RELEVANT
        , PSOFG
        , PSOIS
        , PSON1
        , PSON2
        , PSON3
        , PSOVN
        , PSOTL
        , PSOHS
        , PSOST
        , TRANSPORT_CHAIN
        , STAGING_TIME
        , SCHEDULING_TYPE
        , SUBMI_RELEVANT
        , ZZPASS
        , ZZGROUPKEY
        , ZZSUPIND
        , ZZRIMSCAR
        , ZZRIMSSPL
        , ZZTRANZACT
        , ZZAIREXP
        , ZZPLANTIND
        , ZZUNION
        , ZZUNION_EXP
        , ZZUNION_TYPE
        , ZZUNION_EXP1
        , ZZUNION_TYPE1
        , ZZASN_ACTIVE
        , ZZASN_NUMBER
        , ZZACTIVE_DT
        , ZZASN_DT
        , ZZRPT_COUNTRY
        , ZZRPT_CONTINENT
        , ZZCALENDAR
        , ZZ3RDPARTY
        , ZZMASTR_VEND
        , ZZBRGEW
        , ZZGEWEI
        , ZZSDABW
        , ZZQUOTE
        , ZZQUOTE_UNAME
        , ZZQUOTE_LAEDA
        , ZZSUPPLIERKEY
        , ZZSUPINVKEY
        , ZZTMSSCAC
        , ZZTMSMODE
        , ZZTMSSERVICE
        , ZZSCACWJEF
        , GLDELFLAG
        , GLCHANGETIME
        , GLCHANGETIME_DTTM
        , PSA_DELETE_IND
        , PSA_LOAD_DTS
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(LIFNR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as SUPPLIER_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(LAND1::text), '^^') 
            , '||', IFNULL(TRIM(NAME1::text), '^^') 
            , '||', IFNULL(TRIM(NAME2::text), '^^') 
            , '||', IFNULL(TRIM(NAME3::text), '^^') 
            , '||', IFNULL(TRIM(NAME4::text), '^^') 
            , '||', IFNULL(TRIM(ORT01::text), '^^') 
            , '||', IFNULL(TRIM(ORT02::text), '^^') 
            , '||', IFNULL(TRIM(PFACH::text), '^^') 
            , '||', IFNULL(TRIM(PSTL2::text), '^^') 
            , '||', IFNULL(TRIM(PSTLZ::text), '^^') 
            , '||', IFNULL(TRIM(REGIO::text), '^^') 
            , '||', IFNULL(TRIM(SORTL::text), '^^') 
            , '||', IFNULL(TRIM(STRAS::text), '^^') 
            , '||', IFNULL(TRIM(ADRNR::text), '^^') 
            , '||', IFNULL(TRIM(MCOD1::text), '^^') 
            , '||', IFNULL(TRIM(MCOD2::text), '^^') 
            , '||', IFNULL(TRIM(MCOD3::text), '^^') 
            , '||', IFNULL(TRIM(ANRED::text), '^^') 
            , '||', IFNULL(TRIM(BAHNS::text), '^^') 
            , '||', IFNULL(TRIM(BBBNR::text), '^^') 
            , '||', IFNULL(TRIM(BBSNR::text), '^^') 
            , '||', IFNULL(TRIM(BEGRU::text), '^^') 
            , '||', IFNULL(TRIM(BRSCH::text), '^^') 
            , '||', IFNULL(TRIM(BUBKZ::text), '^^') 
            , '||', IFNULL(TRIM(DATLT::text), '^^') 
            , '||', IFNULL(TRIM(DTAMS::text), '^^') 
            , '||', IFNULL(TRIM(DTAWS::text), '^^') 
            , '||', IFNULL(TRIM(ERDAT::text), '^^') 
            , '||', IFNULL(TRIM(ERNAM::text), '^^') 
            , '||', IFNULL(TRIM(ESRNR::text), '^^') 
            , '||', IFNULL(TRIM(KONZS::text), '^^') 
            , '||', IFNULL(TRIM(KTOKK::text), '^^') 
            , '||', IFNULL(TRIM(KUNNR::text), '^^') 
            , '||', IFNULL(TRIM(LNRZA::text), '^^') 
            , '||', IFNULL(TRIM(LOEVM::text), '^^') 
            , '||', IFNULL(TRIM(SPERR::text), '^^') 
            , '||', IFNULL(TRIM(SPERM::text), '^^') 
            , '||', IFNULL(TRIM(SPRAS::text), '^^') 
            , '||', IFNULL(TRIM(STCD1::text), '^^') 
            , '||', IFNULL(TRIM(STCD2::text), '^^') 
            , '||', IFNULL(TRIM(STKZA::text), '^^') 
            , '||', IFNULL(TRIM(STKZU::text), '^^') 
            , '||', IFNULL(TRIM(TELBX::text), '^^') 
            , '||', IFNULL(TRIM(TELF1::text), '^^') 
            , '||', IFNULL(TRIM(TELF2::text), '^^') 
            , '||', IFNULL(TRIM(TELFX::text), '^^') 
            , '||', IFNULL(TRIM(TELTX::text), '^^') 
            , '||', IFNULL(TRIM(TELX1::text), '^^') 
            , '||', IFNULL(TRIM(XCPDK::text), '^^') 
            , '||', IFNULL(TRIM(XZEMP::text), '^^') 
            , '||', IFNULL(TRIM(VBUND::text), '^^') 
            , '||', IFNULL(TRIM(FISKN::text), '^^') 
            , '||', IFNULL(TRIM(STCEG::text), '^^') 
            , '||', IFNULL(TRIM(STKZN::text), '^^') 
            , '||', IFNULL(TRIM(SPERQ::text), '^^') 
            , '||', IFNULL(TRIM(GBORT::text), '^^') 
            , '||', IFNULL(TRIM(GBDAT::text), '^^') 
            , '||', IFNULL(TRIM(SEXKZ::text), '^^') 
            , '||', IFNULL(TRIM(KRAUS::text), '^^') 
            , '||', IFNULL(TRIM(REVDB::text), '^^') 
            , '||', IFNULL(TRIM(QSSYS::text), '^^') 
            , '||', IFNULL(TRIM(KTOCK::text), '^^') 
            , '||', IFNULL(TRIM(PFORT::text), '^^') 
            , '||', IFNULL(TRIM(WERKS::text), '^^') 
            , '||', IFNULL(TRIM(LTSNA::text), '^^') 
            , '||', IFNULL(TRIM(WERKR::text), '^^') 
            , '||', IFNULL(TRIM(PLKAL::text), '^^') 
            , '||', IFNULL(TRIM(DUEFL::text), '^^') 
            , '||', IFNULL(TRIM(TXJCD::text), '^^') 
            , '||', IFNULL(TRIM(SPERZ::text), '^^') 
            , '||', IFNULL(TRIM(SCACD::text), '^^') 
            , '||', IFNULL(TRIM(SFRGR::text), '^^') 
            , '||', IFNULL(TRIM(LZONE::text), '^^') 
            , '||', IFNULL(TRIM(XLFZA::text), '^^') 
            , '||', IFNULL(TRIM(DLGRP::text), '^^') 
            , '||', IFNULL(TRIM(FITYP::text), '^^') 
            , '||', IFNULL(TRIM(STCDT::text), '^^') 
            , '||', IFNULL(TRIM(REGSS::text), '^^') 
            , '||', IFNULL(TRIM(ACTSS::text), '^^') 
            , '||', IFNULL(TRIM(STCD3::text), '^^') 
            , '||', IFNULL(TRIM(STCD4::text), '^^') 
            , '||', IFNULL(TRIM(STCD5::text), '^^') 
            , '||', IFNULL(TRIM(IPISP::text), '^^') 
            , '||', IFNULL(TRIM(TAXBS::text), '^^') 
            , '||', IFNULL(TRIM(PROFS::text), '^^') 
            , '||', IFNULL(TRIM(STGDL::text), '^^') 
            , '||', IFNULL(TRIM(EMNFR::text), '^^') 
            , '||', IFNULL(TRIM(LFURL::text), '^^') 
            , '||', IFNULL(TRIM(J_1KFREPRE::text), '^^') 
            , '||', IFNULL(TRIM(J_1KFTBUS::text), '^^') 
            , '||', IFNULL(TRIM(J_1KFTIND::text), '^^') 
            , '||', IFNULL(TRIM(CONFS::text), '^^') 
            , '||', IFNULL(TRIM(UPDAT::text), '^^') 
            , '||', IFNULL(TRIM(UPTIM::text), '^^') 
            , '||', IFNULL(TRIM(NODEL::text), '^^') 
            , '||', IFNULL(TRIM(QSSYSDAT::text), '^^') 
            , '||', IFNULL(TRIM(PODKZB::text), '^^') 
            , '||', IFNULL(TRIM(FISKU::text), '^^') 
            , '||', IFNULL(TRIM(STENR::text), '^^') 
            , '||', IFNULL(TRIM(CARRIER_CONF::text), '^^') 
            , '||', IFNULL(TRIM(MIN_COMP::text), '^^') 
            , '||', IFNULL(TRIM(TERM_LI::text), '^^') 
            , '||', IFNULL(TRIM(CRC_NUM::text), '^^') 
            , '||', IFNULL(TRIM(CVP_XBLCK::text), '^^') 
            , '||', IFNULL(TRIM(RG::text), '^^') 
            , '||', IFNULL(TRIM(EXP::text), '^^') 
            , '||', IFNULL(TRIM(UF::text), '^^') 
            , '||', IFNULL(TRIM(RGDATE::text), '^^') 
            , '||', IFNULL(TRIM(RIC::text), '^^') 
            , '||', IFNULL(TRIM(RNE::text), '^^') 
            , '||', IFNULL(TRIM(RNEDATE::text), '^^') 
            , '||', IFNULL(TRIM(CNAE::text), '^^') 
            , '||', IFNULL(TRIM(LEGALNAT::text), '^^') 
            , '||', IFNULL(TRIM(CRTN::text), '^^') 
            , '||', IFNULL(TRIM(ICMSTAXPAY::text), '^^') 
            , '||', IFNULL(TRIM(INDTYP::text), '^^') 
            , '||', IFNULL(TRIM(TDT::text), '^^') 
            , '||', IFNULL(TRIM(COMSIZE::text), '^^') 
            , '||', IFNULL(TRIM(DECREGPC::text), '^^') 
            , '||', IFNULL(TRIM(J_SC_CAPITAL::text), '^^') 
            , '||', IFNULL(TRIM(J_SC_CURRENCY::text), '^^') 
            , '||', IFNULL(TRIM(ALC::text), '^^') 
            , '||', IFNULL(TRIM(PMT_OFFICE::text), '^^') 
            , '||', IFNULL(TRIM(PPA_RELEVANT::text), '^^') 
            , '||', IFNULL(TRIM(PSOFG::text), '^^') 
            , '||', IFNULL(TRIM(PSOIS::text), '^^') 
            , '||', IFNULL(TRIM(PSON1::text), '^^') 
            , '||', IFNULL(TRIM(PSON2::text), '^^') 
            , '||', IFNULL(TRIM(PSON3::text), '^^') 
            , '||', IFNULL(TRIM(PSOVN::text), '^^') 
            , '||', IFNULL(TRIM(PSOTL::text), '^^') 
            , '||', IFNULL(TRIM(PSOHS::text), '^^') 
            , '||', IFNULL(TRIM(PSOST::text), '^^') 
            , '||', IFNULL(TRIM(TRANSPORT_CHAIN::text), '^^') 
            , '||', IFNULL(TRIM(STAGING_TIME::text), '^^') 
            , '||', IFNULL(TRIM(SCHEDULING_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(SUBMI_RELEVANT::text), '^^') 
            , '||', IFNULL(TRIM(ZZPASS::text), '^^') 
            , '||', IFNULL(TRIM(ZZGROUPKEY::text), '^^') 
            , '||', IFNULL(TRIM(ZZSUPIND::text), '^^') 
            , '||', IFNULL(TRIM(ZZRIMSCAR::text), '^^') 
            , '||', IFNULL(TRIM(ZZRIMSSPL::text), '^^') 
            , '||', IFNULL(TRIM(ZZTRANZACT::text), '^^') 
            , '||', IFNULL(TRIM(ZZAIREXP::text), '^^') 
            , '||', IFNULL(TRIM(ZZPLANTIND::text), '^^') 
            , '||', IFNULL(TRIM(ZZUNION::text), '^^') 
            , '||', IFNULL(TRIM(ZZUNION_EXP::text), '^^') 
            , '||', IFNULL(TRIM(ZZUNION_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(ZZUNION_EXP1::text), '^^') 
            , '||', IFNULL(TRIM(ZZUNION_TYPE1::text), '^^') 
            , '||', IFNULL(TRIM(ZZASN_ACTIVE::text), '^^') 
            , '||', IFNULL(TRIM(ZZASN_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(ZZACTIVE_DT::text), '^^') 
            , '||', IFNULL(TRIM(ZZASN_DT::text), '^^') 
            , '||', IFNULL(TRIM(ZZRPT_COUNTRY::text), '^^') 
            , '||', IFNULL(TRIM(ZZRPT_CONTINENT::text), '^^') 
            , '||', IFNULL(TRIM(ZZCALENDAR::text), '^^') 
            , '||', IFNULL(TRIM(ZZ3RDPARTY::text), '^^') 
            , '||', IFNULL(TRIM(ZZMASTR_VEND::text), '^^') 
            , '||', IFNULL(TRIM(ZZBRGEW::text), '^^') 
            , '||', IFNULL(TRIM(ZZGEWEI::text), '^^') 
            , '||', IFNULL(TRIM(ZZSDABW::text), '^^') 
            , '||', IFNULL(TRIM(ZZQUOTE::text), '^^') 
            , '||', IFNULL(TRIM(ZZQUOTE_UNAME::text), '^^') 
            , '||', IFNULL(TRIM(ZZQUOTE_LAEDA::text), '^^') 
            , '||', IFNULL(TRIM(ZZSUPPLIERKEY::text), '^^') 
            , '||', IFNULL(TRIM(ZZSUPINVKEY::text), '^^') 
            , '||', IFNULL(TRIM(ZZTMSSCAC::text), '^^') 
            , '||', IFNULL(TRIM(ZZTMSMODE::text), '^^') 
            , '||', IFNULL(TRIM(ZZTMSSERVICE::text), '^^') 
            , '||', IFNULL(TRIM(ZZSCACWJEF::text), '^^') 
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
