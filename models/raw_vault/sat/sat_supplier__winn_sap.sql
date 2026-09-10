---- SRC LAYER ----
WITH
SRC_SWINN          as ( SELECT * FROM {{ ref('v_psa_stg_supplier__winn_sap') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_SWINN          as ( SELECT * FROM STAGING.v_psa_stg_supplier__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_SWINN as (
    SELECT
        SUPPLIER_HK
      , LIFNR
      , LOAD_DTS
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
      , GLREQUEST
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM SRC_SWINN
)
---- RENAME LAYER ----

, RENAME_SWINN as (
    SELECT
        SUPPLIER_HK
      , LIFNR
      , LOAD_DTS
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
      , GLREQUEST
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM LOGIC_SWINN
)
---- FILTER LAYER ----

, FILTER_SWINN as (
    SELECT *
    FROM RENAME_SWINN
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_SWINN
)

---- FINAL LAYER ----
SELECT
          SUPPLIER_HK
        , LIFNR
        , LOAD_DTS
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
        , GLREQUEST
        , GLSOURCESYSTEM
        , PSA_LOAD_DTS
        , PSA_DELETE_IND
        , REC_SRC
        , BKCC
        , HASHDIFF
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.SUPPLIER_HK = JOIN_RESULT.SUPPLIER_HK 
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %} 
{% if not is_incremental() %}
/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per HK and hashdiff. */
qualify 1= row_number()over(partition by SUPPLIER_HK, HASHDIFF order by PSA_LOAD_DTS)

union all
    SELECT MD5_BINARY(GR.VALUE)  SUPPLIER_HK
, GR.VALUE AS LIFNR
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)  AS LOAD_DTS
, NULL AS LAND1
, NULL AS NAME1
, NULL AS NAME2
, NULL AS NAME3
, NULL AS NAME4
, NULL AS ORT01
, NULL AS ORT02
, NULL AS PFACH
, NULL AS PSTL2
, NULL AS PSTLZ
, NULL AS REGIO
, NULL AS SORTL
, NULL AS STRAS
, NULL AS ADRNR
, NULL AS MCOD1
, NULL AS MCOD2
, NULL AS MCOD3
, NULL AS ANRED
, NULL AS BAHNS
, NULL AS BBBNR
, NULL AS BBSNR
, NULL AS BEGRU
, NULL AS BRSCH
, NULL AS BUBKZ
, NULL AS DATLT
, NULL AS DTAMS
, NULL AS DTAWS
, NULL AS ERDAT
, NULL AS ERNAM
, NULL AS ESRNR
, NULL AS KONZS
, NULL AS KTOKK
, NULL AS KUNNR
, NULL AS LNRZA
, NULL AS LOEVM
, NULL AS SPERR
, NULL AS SPERM
, NULL AS SPRAS
, NULL AS STCD1
, NULL AS STCD2
, NULL AS STKZA
, NULL AS STKZU
, NULL AS TELBX
, NULL AS TELF1
, NULL AS TELF2
, NULL AS TELFX
, NULL AS TELTX
, NULL AS TELX1
, NULL AS XCPDK
, NULL AS XZEMP
, NULL AS VBUND
, NULL AS FISKN
, NULL AS STCEG
, NULL AS STKZN
, NULL AS SPERQ
, NULL AS GBORT
, NULL AS GBDAT
, NULL AS SEXKZ
, NULL AS KRAUS
, NULL AS REVDB
, NULL AS QSSYS
, NULL AS KTOCK
, NULL AS PFORT
, NULL AS WERKS
, NULL AS LTSNA
, NULL AS WERKR
, NULL AS PLKAL
, NULL AS DUEFL
, NULL AS TXJCD
, NULL AS SPERZ
, NULL AS SCACD
, NULL AS SFRGR
, NULL AS LZONE
, NULL AS XLFZA
, NULL AS DLGRP
, NULL AS FITYP
, NULL AS STCDT
, NULL AS REGSS
, NULL AS ACTSS
, NULL AS STCD3
, NULL AS STCD4
, NULL AS STCD5
, NULL AS IPISP
, NULL AS TAXBS
, NULL AS PROFS
, NULL AS STGDL
, NULL AS EMNFR
, NULL AS LFURL
, NULL AS J_1KFREPRE
, NULL AS J_1KFTBUS
, NULL AS J_1KFTIND
, NULL AS CONFS
, NULL AS UPDAT
, NULL AS UPTIM
, NULL AS NODEL
, NULL AS QSSYSDAT
, NULL AS PODKZB
, NULL AS FISKU
, NULL AS STENR
, NULL AS CARRIER_CONF
, NULL AS MIN_COMP
, NULL AS TERM_LI
, NULL AS CRC_NUM
, NULL AS CVP_XBLCK
, NULL AS RG
, NULL AS EXP
, NULL AS UF
, NULL AS RGDATE
, NULL AS RIC
, NULL AS RNE
, NULL AS RNEDATE
, NULL AS CNAE
, NULL AS LEGALNAT
, NULL AS CRTN
, NULL AS ICMSTAXPAY
, NULL AS INDTYP
, NULL AS TDT
, NULL AS COMSIZE
, NULL AS DECREGPC
, NULL AS J_SC_CAPITAL
, NULL AS J_SC_CURRENCY
, NULL AS ALC
, NULL AS PMT_OFFICE
, NULL AS PPA_RELEVANT
, NULL AS PSOFG
, NULL AS PSOIS
, NULL AS PSON1
, NULL AS PSON2
, NULL AS PSON3
, NULL AS PSOVN
, NULL AS PSOTL
, NULL AS PSOHS
, NULL AS PSOST
, NULL AS TRANSPORT_CHAIN
, NULL AS STAGING_TIME
, NULL AS SCHEDULING_TYPE
, NULL AS SUBMI_RELEVANT
, NULL AS ZZPASS
, NULL AS ZZGROUPKEY
, NULL AS ZZSUPIND
, NULL AS ZZRIMSCAR
, NULL AS ZZRIMSSPL
, NULL AS ZZTRANZACT
, NULL AS ZZAIREXP
, NULL AS ZZPLANTIND
, NULL AS ZZUNION
, NULL AS ZZUNION_EXP
, NULL AS ZZUNION_TYPE
, NULL AS ZZUNION_EXP1
, NULL AS ZZUNION_TYPE1
, NULL AS ZZASN_ACTIVE
, NULL AS ZZASN_NUMBER
, NULL AS ZZACTIVE_DT
, NULL AS ZZASN_DT
, NULL AS ZZRPT_COUNTRY
, NULL AS ZZRPT_CONTINENT
, NULL AS ZZCALENDAR
, NULL AS ZZ3RDPARTY
, NULL AS ZZMASTR_VEND
, NULL AS ZZBRGEW
, NULL AS ZZGEWEI
, NULL AS ZZSDABW
, NULL AS ZZQUOTE
, NULL AS ZZQUOTE_UNAME
, NULL AS ZZQUOTE_LAEDA
, NULL AS ZZSUPPLIERKEY
, NULL AS ZZSUPINVKEY
, NULL AS ZZTMSSCAC
, NULL AS ZZTMSMODE
, NULL AS ZZTMSSERVICE
, NULL AS ZZSCACWJEF
, NULL AS GLDELFLAG
, NULL AS GLCHANGETIME
, NULL AS GLCHANGETIME_DTTM
, NULL AS GLREQUEST
, NULL AS GLSOURCESYSTEM
, '1900-01-01'::TIMESTAMP AS PSA_LOAD_DTS
, 'N' AS PSA_DELETE_IND
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
, DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS BKCC
, ''::BINARY as HASH_DIFF
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}