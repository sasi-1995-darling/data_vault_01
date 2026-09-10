---- SRC LAYER ----
WITH
SRC_a              as ( SELECT * FROM {{ ref('v_psa_stg_customer__moen_sap') }} as SRC 
                        {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_a              as ( SELECT * FROM STAGING.v_psa_stg_customer__moen_sap )
*/
---- LOGIC LAYER ----

, LOGIC_a as (
    SELECT
        CUSTOMER_HK
      , LOAD_DTS
      , HASHDIFF
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
      , REC_SRC
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
    FROM SRC_a
)
---- RENAME LAYER ----

, RENAME_a as (
    SELECT
        CUSTOMER_HK
      , LOAD_DTS
      , HASHDIFF
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
      , REC_SRC
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
    FROM LOGIC_a
)
---- FILTER LAYER ----

, FILTER_a as (
    SELECT *
    FROM RENAME_a
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_a
)

---- FINAL LAYER ----
SELECT
          CUSTOMER_HK
        , LOAD_DTS
        , HASHDIFF
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
        , REC_SRC
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.CUSTOMER_HK = JOIN_RESULT.CUSTOMER_HK 
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %}
{% if not is_incremental() %}

/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per HK and hashdiff. */
qualify 1 = row_number() over (partition by CUSTOMER_HK, HASHDIFF order by PSA_LOAD_DTS)

union all
SELECT 
MD5_BINARY(GR.VALUE) AS CUSTOMER_HK,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
''::BINARY AS HASHDIFF,
NULL AS MANDT,
GR.VALUE::text AS KUNNR,
NULL AS GLREQUEST,
NULL AS LAND1,
NULL AS NAME1,
NULL AS NAME2,
NULL AS ORT01,
NULL AS PSTLZ,
NULL AS REGIO,
NULL AS SORTL,
NULL AS STRAS,
NULL AS TELF1,
NULL AS TELFX,
NULL AS XCPDK,
NULL AS ADRNR,
NULL AS MCOD1,
NULL AS MCOD2,
NULL AS MCOD3,
NULL AS ANRED,
NULL AS AUFSD,
NULL AS BAHNE,
NULL AS BAHNS,
NULL AS BBBNR,
NULL AS BBSNR,
NULL AS BEGRU,
NULL AS BRSCH,
NULL AS BUBKZ,
NULL AS DATLT,
NULL AS ERDAT,
NULL AS ERNAM,
NULL AS EXABL,
NULL AS FAKSD,
NULL AS FISKN,
NULL AS KNAZK,
NULL AS KNRZA,
NULL AS KONZS,
NULL AS KTOKD,
NULL AS KUKLA,
NULL AS LIFNR,
NULL AS LIFSD,
NULL AS LOCCO,
NULL AS LOEVM,
NULL AS NAME3,
NULL AS NAME4,
NULL AS NIELS,
NULL AS ORT02,
NULL AS PFACH,
NULL AS PSTL2,
NULL AS COUNC,
NULL AS CITYC,
NULL AS RPMKR,
NULL AS SPERR,
NULL AS SPRAS,
NULL AS STCD1,
NULL AS STCD2,
NULL AS STKZA,
NULL AS STKZU,
NULL AS TELBX,
NULL AS TELF2,
NULL AS TELTX,
NULL AS TELX1,
NULL AS LZONE,
NULL AS XZEMP,
NULL AS VBUND,
NULL AS STCEG,
NULL AS DEAR1,
NULL AS DEAR2,
NULL AS DEAR3,
NULL AS DEAR4,
NULL AS DEAR5,
NULL AS GFORM,
NULL AS BRAN1,
NULL AS BRAN2,
NULL AS BRAN3,
NULL AS BRAN4,
NULL AS BRAN5,
NULL AS EKONT,
NULL AS UMSAT,
NULL AS UMJAH,
NULL AS UWAER,
NULL AS JMZAH,
NULL AS JMJAH,
NULL AS KATR1,
NULL AS KATR2,
NULL AS KATR3,
NULL AS KATR4,
NULL AS KATR5,
NULL AS KATR6,
NULL AS KATR7,
NULL AS KATR8,
NULL AS KATR9,
NULL AS KATR10,
NULL AS STKZN,
NULL AS UMSA1,
NULL AS TXJCD,
NULL AS PERIV,
NULL AS ABRVW,
NULL AS INSPBYDEBI,
NULL AS INSPATDEBI,
NULL AS KTOCD,
NULL AS PFORT,
NULL AS WERKS,
NULL AS DTAMS,
NULL AS DTAWS,
NULL AS DUEFL,
NULL AS HZUOR,
NULL AS SPERZ,
NULL AS ETIKG,
NULL AS CIVVE,
NULL AS MILVE,
NULL AS KDKG1,
NULL AS KDKG2,
NULL AS KDKG3,
NULL AS KDKG4,
NULL AS KDKG5,
NULL AS XKNZA,
NULL AS FITYP,
NULL AS STCDT,
NULL AS STCD3,
NULL AS STCD4,
NULL AS STCD5,
NULL AS XICMS,
NULL AS XXIPI,
NULL AS XSUBT,
NULL AS CFOPC,
NULL AS TXLW1,
NULL AS TXLW2,
NULL AS CCC01,
NULL AS CCC02,
NULL AS CCC03,
NULL AS CCC04,
NULL AS CASSD,
NULL AS KNURL,
NULL AS J_1KFREPRE,
NULL AS J_1KFTBUS,
NULL AS J_1KFTIND,
NULL AS CONFS,
NULL AS UPDAT,
NULL AS UPTIM,
NULL AS NODEL,
NULL AS DEAR6,
NULL AS CVP_XBLCK,
NULL AS SUFRAMA,
NULL AS RG,
NULL AS EXP,
NULL AS UF,
NULL AS RGDATE,
NULL AS RIC,
NULL AS RNE,
NULL AS RNEDATE,
NULL AS CNAE,
NULL AS LEGALNAT,
NULL AS CRTN,
NULL AS ICMSTAXPAY,
NULL AS INDTYP,
NULL AS TDT,
NULL AS COMSIZE,
NULL AS DECREGPC,
NULL AS VSO_R_PALHGT,
NULL AS VSO_R_PAL_UL,
NULL AS VSO_R_PK_MAT,
NULL AS VSO_R_MATPAL,
NULL AS VSO_R_I_NO_LYR,
NULL AS VSO_R_ONE_MAT,
NULL AS VSO_R_ONE_SORT,
NULL AS VSO_R_ULD_SIDE,
NULL AS VSO_R_LOAD_PREF,
NULL AS VSO_R_DPOINT,
NULL AS ALC,
NULL AS PMT_OFFICE,
NULL AS FEE_SCHEDULE,
NULL AS DUNS,
NULL AS DUNS4,
NULL AS PSOFG,
NULL AS PSOIS,
NULL AS PSON1,
NULL AS PSON2,
NULL AS PSON3,
NULL AS PSOVN,
NULL AS PSOTL,
NULL AS PSOHS,
NULL AS PSOST,
NULL AS PSOO1,
NULL AS PSOO2,
NULL AS PSOO3,
NULL AS PSOO4,
NULL AS PSOO5,
NULL AS GLDELFLAG,
NULL AS GLCHANGETIME,
NULL AS GLSOURCESYSTEM,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC,
'1900-01-01'::TIMESTAMP AS PSA_LOAD_DTS,
NULL AS PSA_RECORD_SOURCE,
'N' AS PSA_DELETE_IND
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}