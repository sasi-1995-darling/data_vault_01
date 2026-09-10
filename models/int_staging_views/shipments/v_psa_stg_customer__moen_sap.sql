---- SRC LAYER ----
WITH
SRC_S              as ( SELECT * FROM {{ source('sap_ecc_prd', 'z_kna1') }} as SRC  ),
SRC_A              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S              as ( SELECT * FROM sap_ecc_prd.z_kna1 )
, SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        KUNNR                                                        as                                        CUSTOMER_BK
      , MANDT
      , KUNNR
      , GLREQUEST
      , LAND1
      , NAME1
      , NAME2
      , ORT01
      , PSTLZ
      , REGIO
      , SORTL
      , STRAS
      , TELF1
      , TELFX
      , XCPDK
      , ADRNR
      , MCOD1
      , MCOD2
      , MCOD3
      , ANRED
      , AUFSD
      , BAHNE
      , BAHNS
      , BBBNR
      , BBSNR
      , BEGRU
      , BRSCH
      , BUBKZ
      , DATLT
      , ERDAT
      , ERNAM
      , EXABL
      , FAKSD
      , FISKN
      , KNAZK
      , KNRZA
      , KONZS
      , KTOKD
      , KUKLA
      , LIFNR
      , LIFSD
      , LOCCO
      , LOEVM
      , NAME3
      , NAME4
      , NIELS
      , ORT02
      , PFACH
      , PSTL2
      , COUNC
      , CITYC
      , RPMKR
      , SPERR
      , SPRAS
      , STCD1
      , STCD2
      , STKZA
      , STKZU
      , TELBX
      , TELF2
      , TELTX
      , TELX1
      , LZONE
      , XZEMP
      , VBUND
      , STCEG
      , DEAR1
      , DEAR2
      , DEAR3
      , DEAR4
      , DEAR5
      , GFORM
      , BRAN1
      , BRAN2
      , BRAN3
      , BRAN4
      , BRAN5
      , EKONT
      , UMSAT
      , UMJAH
      , UWAER
      , JMZAH
      , JMJAH
      , KATR1
      , KATR2
      , KATR3
      , KATR4
      , KATR5
      , KATR6
      , KATR7
      , KATR8
      , KATR9
      , KATR10
      , STKZN
      , UMSA1
      , TXJCD
      , PERIV
      , ABRVW
      , INSPBYDEBI
      , INSPATDEBI
      , KTOCD
      , PFORT
      , WERKS
      , DTAMS
      , DTAWS
      , DUEFL
      , HZUOR
      , SPERZ
      , ETIKG
      , CIVVE
      , MILVE
      , KDKG1
      , KDKG2
      , KDKG3
      , KDKG4
      , KDKG5
      , XKNZA
      , FITYP
      , STCDT
      , STCD3
      , STCD4
      , STCD5
      , XICMS
      , XXIPI
      , XSUBT
      , CFOPC
      , TXLW1
      , TXLW2
      , CCC01
      , CCC02
      , CCC03
      , CCC04
      , CASSD
      , KNURL
      , J_1KFREPRE
      , J_1KFTBUS
      , J_1KFTIND
      , CONFS
      , UPDAT
      , UPTIM
      , NODEL
      , DEAR6
      , CVP_XBLCK
      , SUFRAMA
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
      , "/VSO/R_PALHGT"                                                as                                       VSO_R_PALHGT
      , "/VSO/R_PAL_UL"                                                as                                       VSO_R_PAL_UL
      , "/VSO/R_PK_MAT"                                                as                                       VSO_R_PK_MAT
      , "/VSO/R_MATPAL"                                               as                                       VSO_R_MATPAL
      , "/VSO/R_I_NO_LYR"                                             as                                     VSO_R_I_NO_LYR
      , "/VSO/R_ONE_MAT"                                               as                                      VSO_R_ONE_MAT
      , "/VSO/R_ONE_SORT"                                              as                                     VSO_R_ONE_SORT
      , "/VSO/R_ULD_SIDE"                                             as                                     VSO_R_ULD_SIDE
      , "/VSO/R_LOAD_PREF"                                            as                                    VSO_R_LOAD_PREF
      , "/VSO/R_DPOINT"                                               as                                       VSO_R_DPOINT
      , ALC
      , PMT_OFFICE
      , FEE_SCHEDULE
      , DUNS
      , DUNS4
      , PSOFG
      , PSOIS
      , PSON1
      , PSON2
      , PSON3
      , PSOVN
      , PSOTL
      , PSOHS
      , PSOST
      , PSOO1
      , PSOO2
      , PSOO3
      , PSOO4
      , PSOO5
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , CONVERT_TIMEZONE('UTC', TO_TIMESTAMP(
            SUBSTR(GLCHANGETIME, 1, 8) || ' ' ||
            SUBSTR(GLCHANGETIME, 9, 2) || ':' ||
            SUBSTR(GLCHANGETIME, 11, 2) || ':' ||
            SUBSTR(GLCHANGETIME, 13, 2) || '.' ||
            REGEXP_REPLACE(SUBSTR(GLCHANGETIME, 16), '^\\.', ''),
            'YYYYMMDD HH24:MI:SS.FF9'
        ))                                                           as                                           LOAD_DTS
      , ADRNR                                                        as                                        LOCATION_BK
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
        CUSTOMER_BK
      , MANDT
      , KUNNR
      , GLREQUEST
      , LAND1
      , NAME1
      , NAME2
      , ORT01
      , PSTLZ
      , REGIO
      , SORTL
      , STRAS
      , TELF1
      , TELFX
      , XCPDK
      , ADRNR
      , MCOD1
      , MCOD2
      , MCOD3
      , ANRED
      , AUFSD
      , BAHNE
      , BAHNS
      , BBBNR
      , BBSNR
      , BEGRU
      , BRSCH
      , BUBKZ
      , DATLT
      , ERDAT
      , ERNAM
      , EXABL
      , FAKSD
      , FISKN
      , KNAZK
      , KNRZA
      , KONZS
      , KTOKD
      , KUKLA
      , LIFNR
      , LIFSD
      , LOCCO
      , LOEVM
      , NAME3
      , NAME4
      , NIELS
      , ORT02
      , PFACH
      , PSTL2
      , COUNC
      , CITYC
      , RPMKR
      , SPERR
      , SPRAS
      , STCD1
      , STCD2
      , STKZA
      , STKZU
      , TELBX
      , TELF2
      , TELTX
      , TELX1
      , LZONE
      , XZEMP
      , VBUND
      , STCEG
      , DEAR1
      , DEAR2
      , DEAR3
      , DEAR4
      , DEAR5
      , GFORM
      , BRAN1
      , BRAN2
      , BRAN3
      , BRAN4
      , BRAN5
      , EKONT
      , UMSAT
      , UMJAH
      , UWAER
      , JMZAH
      , JMJAH
      , KATR1
      , KATR2
      , KATR3
      , KATR4
      , KATR5
      , KATR6
      , KATR7
      , KATR8
      , KATR9
      , KATR10
      , STKZN
      , UMSA1
      , TXJCD
      , PERIV
      , ABRVW
      , INSPBYDEBI
      , INSPATDEBI
      , KTOCD
      , PFORT
      , WERKS
      , DTAMS
      , DTAWS
      , DUEFL
      , HZUOR
      , SPERZ
      , ETIKG
      , CIVVE
      , MILVE
      , KDKG1
      , KDKG2
      , KDKG3
      , KDKG4
      , KDKG5
      , XKNZA
      , FITYP
      , STCDT
      , STCD3
      , STCD4
      , STCD5
      , XICMS
      , XXIPI
      , XSUBT
      , CFOPC
      , TXLW1
      , TXLW2
      , CCC01
      , CCC02
      , CCC03
      , CCC04
      , CASSD
      , KNURL
      , J_1KFREPRE
      , J_1KFTBUS
      , J_1KFTIND
      , CONFS
      , UPDAT
      , UPTIM
      , NODEL
      , DEAR6
      , CVP_XBLCK
      , SUFRAMA
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
      , VSO_R_PALHGT
      , VSO_R_PAL_UL
      , VSO_R_PK_MAT
      , VSO_R_MATPAL
      , VSO_R_I_NO_LYR
      , VSO_R_ONE_MAT
      , VSO_R_ONE_SORT
      , VSO_R_ULD_SIDE
      , VSO_R_LOAD_PREF
      , VSO_R_DPOINT
      , ALC
      , PMT_OFFICE
      , FEE_SCHEDULE
      , DUNS
      , DUNS4
      , PSOFG
      , PSOIS
      , PSON1
      , PSON2
      , PSON3
      , PSOVN
      , PSOTL
      , PSOHS
      , PSOST
      , PSOO1
      , PSOO2
      , PSOO3
      , PSOO4
      , PSOO5
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , LOCATION_BK
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
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_KNA1'
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
          CUSTOMER_BK
        , MANDT
        , KUNNR
        , GLREQUEST
        , LAND1
        , NAME1
        , NAME2
        , ORT01
        , PSTLZ
        , REGIO
        , SORTL
        , STRAS
        , TELF1
        , TELFX
        , XCPDK
        , ADRNR
        , MCOD1
        , MCOD2
        , MCOD3
        , ANRED
        , AUFSD
        , BAHNE
        , BAHNS
        , BBBNR
        , BBSNR
        , BEGRU
        , BRSCH
        , BUBKZ
        , DATLT
        , ERDAT
        , ERNAM
        , EXABL
        , FAKSD
        , FISKN
        , KNAZK
        , KNRZA
        , KONZS
        , KTOKD
        , KUKLA
        , LIFNR
        , LIFSD
        , LOCCO
        , LOEVM
        , NAME3
        , NAME4
        , NIELS
        , ORT02
        , PFACH
        , PSTL2
        , COUNC
        , CITYC
        , RPMKR
        , SPERR
        , SPRAS
        , STCD1
        , STCD2
        , STKZA
        , STKZU
        , TELBX
        , TELF2
        , TELTX
        , TELX1
        , LZONE
        , XZEMP
        , VBUND
        , STCEG
        , DEAR1
        , DEAR2
        , DEAR3
        , DEAR4
        , DEAR5
        , GFORM
        , BRAN1
        , BRAN2
        , BRAN3
        , BRAN4
        , BRAN5
        , EKONT
        , UMSAT
        , UMJAH
        , UWAER
        , JMZAH
        , JMJAH
        , KATR1
        , KATR2
        , KATR3
        , KATR4
        , KATR5
        , KATR6
        , KATR7
        , KATR8
        , KATR9
        , KATR10
        , STKZN
        , UMSA1
        , TXJCD
        , PERIV
        , ABRVW
        , INSPBYDEBI
        , INSPATDEBI
        , KTOCD
        , PFORT
        , WERKS
        , DTAMS
        , DTAWS
        , DUEFL
        , HZUOR
        , SPERZ
        , ETIKG
        , CIVVE
        , MILVE
        , KDKG1
        , KDKG2
        , KDKG3
        , KDKG4
        , KDKG5
        , XKNZA
        , FITYP
        , STCDT
        , STCD3
        , STCD4
        , STCD5
        , XICMS
        , XXIPI
        , XSUBT
        , CFOPC
        , TXLW1
        , TXLW2
        , CCC01
        , CCC02
        , CCC03
        , CCC04
        , CASSD
        , KNURL
        , J_1KFREPRE
        , J_1KFTBUS
        , J_1KFTIND
        , CONFS
        , UPDAT
        , UPTIM
        , NODEL
        , DEAR6
        , CVP_XBLCK
        , SUFRAMA
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
        , VSO_R_PALHGT
        , VSO_R_PAL_UL
        , VSO_R_PK_MAT
        , VSO_R_MATPAL
        , VSO_R_I_NO_LYR
        , VSO_R_ONE_MAT
        , VSO_R_ONE_SORT
        , VSO_R_ULD_SIDE
        , VSO_R_LOAD_PREF
        , VSO_R_DPOINT
        , ALC
        , PMT_OFFICE
        , FEE_SCHEDULE
        , DUNS
        , DUNS4
        , PSOFG
        , PSOIS
        , PSON1
        , PSON2
        , PSON3
        , PSOVN
        , PSOTL
        , PSOHS
        , PSOST
        , PSOO1
        , PSOO2
        , PSOO3
        , PSOO4
        , PSOO5
        , GLDELFLAG
        , GLCHANGETIME
        , GLSOURCESYSTEM
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , LOCATION_BK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(CUSTOMER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as CUSTOMER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(LOCATION_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as LOCATION_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(MANDT::text), '^^') 
            , '||', IFNULL(TRIM(GLREQUEST::text), '^^') 
            , '||', IFNULL(TRIM(LAND1::text), '^^') 
            , '||', IFNULL(TRIM(NAME1::text), '^^') 
            , '||', IFNULL(TRIM(NAME2::text), '^^') 
            , '||', IFNULL(TRIM(ORT01::text), '^^') 
            , '||', IFNULL(TRIM(PSTLZ::text), '^^') 
            , '||', IFNULL(TRIM(REGIO::text), '^^') 
            , '||', IFNULL(TRIM(SORTL::text), '^^') 
            , '||', IFNULL(TRIM(STRAS::text), '^^') 
            , '||', IFNULL(TRIM(TELF1::text), '^^') 
            , '||', IFNULL(TRIM(TELFX::text), '^^') 
            , '||', IFNULL(TRIM(XCPDK::text), '^^') 
            , '||', IFNULL(TRIM(ADRNR::text), '^^') 
            , '||', IFNULL(TRIM(MCOD1::text), '^^') 
            , '||', IFNULL(TRIM(MCOD2::text), '^^') 
            , '||', IFNULL(TRIM(MCOD3::text), '^^') 
            , '||', IFNULL(TRIM(ANRED::text), '^^') 
            , '||', IFNULL(TRIM(AUFSD::text), '^^') 
            , '||', IFNULL(TRIM(BAHNE::text), '^^') 
            , '||', IFNULL(TRIM(BAHNS::text), '^^') 
            , '||', IFNULL(TRIM(BBBNR::text), '^^') 
            , '||', IFNULL(TRIM(BBSNR::text), '^^') 
            , '||', IFNULL(TRIM(BEGRU::text), '^^') 
            , '||', IFNULL(TRIM(BRSCH::text), '^^') 
            , '||', IFNULL(TRIM(BUBKZ::text), '^^') 
            , '||', IFNULL(TRIM(DATLT::text), '^^') 
            , '||', IFNULL(TRIM(ERDAT::text), '^^') 
            , '||', IFNULL(TRIM(ERNAM::text), '^^') 
            , '||', IFNULL(TRIM(EXABL::text), '^^') 
            , '||', IFNULL(TRIM(FAKSD::text), '^^') 
            , '||', IFNULL(TRIM(FISKN::text), '^^') 
            , '||', IFNULL(TRIM(KNAZK::text), '^^') 
            , '||', IFNULL(TRIM(KNRZA::text), '^^') 
            , '||', IFNULL(TRIM(KONZS::text), '^^') 
            , '||', IFNULL(TRIM(KTOKD::text), '^^') 
            , '||', IFNULL(TRIM(KUKLA::text), '^^') 
            , '||', IFNULL(TRIM(LIFNR::text), '^^') 
            , '||', IFNULL(TRIM(LIFSD::text), '^^') 
            , '||', IFNULL(TRIM(LOCCO::text), '^^') 
            , '||', IFNULL(TRIM(LOEVM::text), '^^') 
            , '||', IFNULL(TRIM(NAME3::text), '^^') 
            , '||', IFNULL(TRIM(NAME4::text), '^^') 
            , '||', IFNULL(TRIM(NIELS::text), '^^') 
            , '||', IFNULL(TRIM(ORT02::text), '^^') 
            , '||', IFNULL(TRIM(PFACH::text), '^^') 
            , '||', IFNULL(TRIM(PSTL2::text), '^^') 
            , '||', IFNULL(TRIM(COUNC::text), '^^') 
            , '||', IFNULL(TRIM(CITYC::text), '^^') 
            , '||', IFNULL(TRIM(RPMKR::text), '^^') 
            , '||', IFNULL(TRIM(SPERR::text), '^^') 
            , '||', IFNULL(TRIM(SPRAS::text), '^^') 
            , '||', IFNULL(TRIM(STCD1::text), '^^') 
            , '||', IFNULL(TRIM(STCD2::text), '^^') 
            , '||', IFNULL(TRIM(STKZA::text), '^^') 
            , '||', IFNULL(TRIM(STKZU::text), '^^') 
            , '||', IFNULL(TRIM(TELBX::text), '^^') 
            , '||', IFNULL(TRIM(TELF2::text), '^^') 
            , '||', IFNULL(TRIM(TELTX::text), '^^') 
            , '||', IFNULL(TRIM(TELX1::text), '^^') 
            , '||', IFNULL(TRIM(LZONE::text), '^^') 
            , '||', IFNULL(TRIM(XZEMP::text), '^^') 
            , '||', IFNULL(TRIM(VBUND::text), '^^') 
            , '||', IFNULL(TRIM(STCEG::text), '^^') 
            , '||', IFNULL(TRIM(DEAR1::text), '^^') 
            , '||', IFNULL(TRIM(DEAR2::text), '^^') 
            , '||', IFNULL(TRIM(DEAR3::text), '^^') 
            , '||', IFNULL(TRIM(DEAR4::text), '^^') 
            , '||', IFNULL(TRIM(DEAR5::text), '^^') 
            , '||', IFNULL(TRIM(GFORM::text), '^^') 
            , '||', IFNULL(TRIM(BRAN1::text), '^^') 
            , '||', IFNULL(TRIM(BRAN2::text), '^^') 
            , '||', IFNULL(TRIM(BRAN3::text), '^^') 
            , '||', IFNULL(TRIM(BRAN4::text), '^^') 
            , '||', IFNULL(TRIM(BRAN5::text), '^^') 
            , '||', IFNULL(TRIM(EKONT::text), '^^') 
            , '||', IFNULL(TRIM(UMSAT::text), '^^') 
            , '||', IFNULL(TRIM(UMJAH::text), '^^') 
            , '||', IFNULL(TRIM(UWAER::text), '^^') 
            , '||', IFNULL(TRIM(JMZAH::text), '^^') 
            , '||', IFNULL(TRIM(JMJAH::text), '^^') 
            , '||', IFNULL(TRIM(KATR1::text), '^^') 
            , '||', IFNULL(TRIM(KATR2::text), '^^') 
            , '||', IFNULL(TRIM(KATR3::text), '^^') 
            , '||', IFNULL(TRIM(KATR4::text), '^^') 
            , '||', IFNULL(TRIM(KATR5::text), '^^') 
            , '||', IFNULL(TRIM(KATR6::text), '^^') 
            , '||', IFNULL(TRIM(KATR7::text), '^^') 
            , '||', IFNULL(TRIM(KATR8::text), '^^') 
            , '||', IFNULL(TRIM(KATR9::text), '^^') 
            , '||', IFNULL(TRIM(KATR10::text), '^^') 
            , '||', IFNULL(TRIM(STKZN::text), '^^') 
            , '||', IFNULL(TRIM(UMSA1::text), '^^') 
            , '||', IFNULL(TRIM(TXJCD::text), '^^') 
            , '||', IFNULL(TRIM(PERIV::text), '^^') 
            , '||', IFNULL(TRIM(ABRVW::text), '^^') 
            , '||', IFNULL(TRIM(INSPBYDEBI::text), '^^') 
            , '||', IFNULL(TRIM(INSPATDEBI::text), '^^') 
            , '||', IFNULL(TRIM(KTOCD::text), '^^') 
            , '||', IFNULL(TRIM(PFORT::text), '^^') 
            , '||', IFNULL(TRIM(WERKS::text), '^^') 
            , '||', IFNULL(TRIM(DTAMS::text), '^^') 
            , '||', IFNULL(TRIM(DTAWS::text), '^^') 
            , '||', IFNULL(TRIM(DUEFL::text), '^^') 
            , '||', IFNULL(TRIM(HZUOR::text), '^^') 
            , '||', IFNULL(TRIM(SPERZ::text), '^^') 
            , '||', IFNULL(TRIM(ETIKG::text), '^^') 
            , '||', IFNULL(TRIM(CIVVE::text), '^^') 
            , '||', IFNULL(TRIM(MILVE::text), '^^') 
            , '||', IFNULL(TRIM(KDKG1::text), '^^') 
            , '||', IFNULL(TRIM(KDKG2::text), '^^') 
            , '||', IFNULL(TRIM(KDKG3::text), '^^') 
            , '||', IFNULL(TRIM(KDKG4::text), '^^') 
            , '||', IFNULL(TRIM(KDKG5::text), '^^') 
            , '||', IFNULL(TRIM(XKNZA::text), '^^') 
            , '||', IFNULL(TRIM(FITYP::text), '^^') 
            , '||', IFNULL(TRIM(STCDT::text), '^^') 
            , '||', IFNULL(TRIM(STCD3::text), '^^') 
            , '||', IFNULL(TRIM(STCD4::text), '^^') 
            , '||', IFNULL(TRIM(STCD5::text), '^^') 
            , '||', IFNULL(TRIM(XICMS::text), '^^') 
            , '||', IFNULL(TRIM(XXIPI::text), '^^') 
            , '||', IFNULL(TRIM(XSUBT::text), '^^') 
            , '||', IFNULL(TRIM(CFOPC::text), '^^') 
            , '||', IFNULL(TRIM(TXLW1::text), '^^') 
            , '||', IFNULL(TRIM(TXLW2::text), '^^') 
            , '||', IFNULL(TRIM(CCC01::text), '^^') 
            , '||', IFNULL(TRIM(CCC02::text), '^^') 
            , '||', IFNULL(TRIM(CCC03::text), '^^') 
            , '||', IFNULL(TRIM(CCC04::text), '^^') 
            , '||', IFNULL(TRIM(CASSD::text), '^^') 
            , '||', IFNULL(TRIM(KNURL::text), '^^') 
            , '||', IFNULL(TRIM(J_1KFREPRE::text), '^^') 
            , '||', IFNULL(TRIM(J_1KFTBUS::text), '^^') 
            , '||', IFNULL(TRIM(J_1KFTIND::text), '^^') 
            , '||', IFNULL(TRIM(CONFS::text), '^^') 
            , '||', IFNULL(TRIM(UPDAT::text), '^^') 
            , '||', IFNULL(TRIM(UPTIM::text), '^^') 
            , '||', IFNULL(TRIM(NODEL::text), '^^') 
            , '||', IFNULL(TRIM(DEAR6::text), '^^') 
            , '||', IFNULL(TRIM(CVP_XBLCK::text), '^^') 
            , '||', IFNULL(TRIM(SUFRAMA::text), '^^') 
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
            , '||', IFNULL(TRIM(VSO_R_PALHGT::text), '^^') 
            , '||', IFNULL(TRIM(VSO_R_PAL_UL::text), '^^') 
            , '||', IFNULL(TRIM(VSO_R_PK_MAT::text), '^^') 
            , '||', IFNULL(TRIM(VSO_R_MATPAL::text), '^^') 
            , '||', IFNULL(TRIM(VSO_R_I_NO_LYR::text), '^^') 
            , '||', IFNULL(TRIM(VSO_R_ONE_MAT::text), '^^') 
            , '||', IFNULL(TRIM(VSO_R_ONE_SORT::text), '^^') 
            , '||', IFNULL(TRIM(VSO_R_ULD_SIDE::text), '^^') 
            , '||', IFNULL(TRIM(VSO_R_LOAD_PREF::text), '^^') 
            , '||', IFNULL(TRIM(VSO_R_DPOINT::text), '^^')
            , '||', IFNULL(TRIM(ALC::text), '^^') 
            , '||', IFNULL(TRIM(PMT_OFFICE::text), '^^') 
            , '||', IFNULL(TRIM(FEE_SCHEDULE::text), '^^') 
            , '||', IFNULL(TRIM(DUNS::text), '^^') 
            , '||', IFNULL(TRIM(DUNS4::text), '^^') 
            , '||', IFNULL(TRIM(PSOFG::text), '^^') 
            , '||', IFNULL(TRIM(PSOIS::text), '^^') 
            , '||', IFNULL(TRIM(PSON1::text), '^^') 
            , '||', IFNULL(TRIM(PSON2::text), '^^') 
            , '||', IFNULL(TRIM(PSON3::text), '^^') 
            , '||', IFNULL(TRIM(PSOVN::text), '^^') 
            , '||', IFNULL(TRIM(PSOTL::text), '^^') 
            , '||', IFNULL(TRIM(PSOHS::text), '^^') 
            , '||', IFNULL(TRIM(PSOST::text), '^^') 
            , '||', IFNULL(TRIM(PSOO1::text), '^^') 
            , '||', IFNULL(TRIM(PSOO2::text), '^^') 
            , '||', IFNULL(TRIM(PSOO3::text), '^^') 
            , '||', IFNULL(TRIM(PSOO4::text), '^^') 
            , '||', IFNULL(TRIM(PSOO5::text), '^^') 
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT