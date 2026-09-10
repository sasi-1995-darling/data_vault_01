---- SRC LAYER ----
WITH
SRC_G              as ( SELECT RCLNT, RLDNR, RRCTY, RVERS, RYEAR, ROBJNR, COBJNR, SOBJNR, RTCUR, RUNIT, DRCRK, RPMAX, GLREQUEST, RBUKRS, RPRCTR, RHOART, RFAREA, KOKRS, RACCT, HRKFT, RASSC, EPRCTR, ACTIV, AFABE, OCLNT, LOGSYS, SBUKRS, SPRCTR, SHOART, SFAREA, VERSA, TSLVT, TSL01, TSL02, TSL03, TSL04, TSL05, TSL06, TSL07, TSL08, TSL09, TSL10, TSL11, TSL12, TSL13, TSL14, TSL15, TSL16, HSLVT, HSL01, HSL02, HSL03, HSL04, HSL05, HSL06, HSL07, HSL08, HSL09, HSL10, HSL11, HSL12, HSL13, HSL14, HSL15, HSL16, KSLVT, KSL01, KSL02, KSL03, KSL04, KSL05, KSL06, KSL07, KSL08, KSL09, KSL10, KSL11, KSL12, KSL13, KSL14, KSL15, KSL16, MSLVT, MSL01, MSL02, MSL03, MSL04, MSL05, MSL06, MSL07, MSL08, MSL09, MSL10, MSL11, MSL12, MSL13, MSL14, MSL15, MSL16, CSPRED, QSPRED, STAGR, WERKS, REP_MATNR, RSCOPE, RMVCT, GLDELFLAG, GLCHANGETIME, GLSOURCESYSTEM, PSA_DELETE_IND, PSA_RECORD_SOURCE , PSA_LOAD_DTS FROM {{ source('sap_ecc_prd', 'z_glpct') }} as SRC  ),
SRC_A              as ( SELECT REC_SRC, BKCC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_G              as ( SELECT * FROM sap_ecc_prd.Z_GLPCT )
SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_G as (
    SELECT
        RCLNT                                                        as                                          CLIENT_BK
      , RLDNR                                                        as                                          LEDGER_BK
      , RRCTY                                                        as                                     RECORD_TYPE_BK
      , RVERS                                                        as                                         VERSION_BK
      , RYEAR                                                        as                                     FISCAL_YEAR_BK
      , ROBJNR                                                       as                                  OBJECT_NUMBER1_BK
      , COBJNR                                                       as                                  OBJECT_NUMBER2_BK
      , SOBJNR                                                       as                                  OBJECT_NUMBER3_BK
      , RTCUR                                                        as                                    CURRENCY_KEY_BK
      , RUNIT                                                        as                                        BASE_UOM_BK
      , DRCRK                                                        as                          DEBIT_CREDIT_INDICATOR_BK
      , RPMAX                                                        as                                          PERIOD_BK
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
      , RCLNT
      , RLDNR
      , RRCTY
      , RVERS
      , RYEAR
      , ROBJNR
      , COBJNR
      , SOBJNR
      , RTCUR
      , RUNIT
      , DRCRK
      , RPMAX
      , GLREQUEST
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
      , LOGSYS
      , SBUKRS
      , SPRCTR
      , SHOART
      , SFAREA
      , VERSA
      , TSLVT
      , TSL01
      , TSL02
      , TSL03
      , TSL04
      , TSL05
      , TSL06
      , TSL07
      , TSL08
      , TSL09
      , TSL10
      , TSL11
      , TSL12
      , TSL13
      , TSL14
      , TSL15
      , TSL16
      , HSLVT
      , HSL01
      , HSL02
      , HSL03
      , HSL04
      , HSL05
      , HSL06
      , HSL07
      , HSL08
      , HSL09
      , HSL10
      , HSL11
      , HSL12
      , HSL13
      , HSL14
      , HSL15
      , HSL16
      , KSLVT
      , KSL01
      , KSL02
      , KSL03
      , KSL04
      , KSL05
      , KSL06
      , KSL07
      , KSL08
      , KSL09
      , KSL10
      , KSL11
      , KSL12
      , KSL13
      , KSL14
      , KSL15
      , KSL16
      , MSLVT
      , MSL01
      , MSL02
      , MSL03
      , MSL04
      , MSL05
      , MSL06
      , MSL07
      , MSL08
      , MSL09
      , MSL10
      , MSL11
      , MSL12
      , MSL13
      , MSL14
      , MSL15
      , MSL16
      , CSPRED
      , QSPRED
      , STAGR
      , WERKS
      , REP_MATNR
      , RSCOPE
      , RMVCT
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
      , PSA_RECORD_SOURCE
      , PSA_LOAD_DTS
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
        CLIENT_BK
      , LEDGER_BK
      , RECORD_TYPE_BK
      , VERSION_BK
      , FISCAL_YEAR_BK
      , OBJECT_NUMBER1_BK
      , OBJECT_NUMBER2_BK
      , OBJECT_NUMBER3_BK
      , CURRENCY_KEY_BK
      , BASE_UOM_BK
      , DEBIT_CREDIT_INDICATOR_BK
      , PERIOD_BK
      , LOAD_DTS
      , RCLNT
      , RLDNR
      , RRCTY
      , RVERS
      , RYEAR
      , ROBJNR
      , COBJNR
      , SOBJNR
      , RTCUR
      , RUNIT
      , DRCRK
      , RPMAX
      , GLREQUEST
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
      , LOGSYS
      , SBUKRS
      , SPRCTR
      , SHOART
      , SFAREA
      , VERSA
      , TSLVT
      , TSL01
      , TSL02
      , TSL03
      , TSL04
      , TSL05
      , TSL06
      , TSL07
      , TSL08
      , TSL09
      , TSL10
      , TSL11
      , TSL12
      , TSL13
      , TSL14
      , TSL15
      , TSL16
      , HSLVT
      , HSL01
      , HSL02
      , HSL03
      , HSL04
      , HSL05
      , HSL06
      , HSL07
      , HSL08
      , HSL09
      , HSL10
      , HSL11
      , HSL12
      , HSL13
      , HSL14
      , HSL15
      , HSL16
      , KSLVT
      , KSL01
      , KSL02
      , KSL03
      , KSL04
      , KSL05
      , KSL06
      , KSL07
      , KSL08
      , KSL09
      , KSL10
      , KSL11
      , KSL12
      , KSL13
      , KSL14
      , KSL15
      , KSL16
      , MSLVT
      , MSL01
      , MSL02
      , MSL03
      , MSL04
      , MSL05
      , MSL06
      , MSL07
      , MSL08
      , MSL09
      , MSL10
      , MSL11
      , MSL12
      , MSL13
      , MSL14
      , MSL15
      , MSL16
      , CSPRED
      , QSPRED
      , STAGR
      , WERKS
      , REP_MATNR
      , RSCOPE
      , RMVCT
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , GLCHANGETIME_DTTM
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
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_GLPCT'
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
        , LEDGER_BK
        , RECORD_TYPE_BK
        , VERSION_BK
        , FISCAL_YEAR_BK
        , OBJECT_NUMBER1_BK
        , OBJECT_NUMBER2_BK
        , OBJECT_NUMBER3_BK
        , CURRENCY_KEY_BK
        , BASE_UOM_BK
        , DEBIT_CREDIT_INDICATOR_BK
        , PERIOD_BK
        , LOAD_DTS
        , RCLNT
        , RLDNR
        , RRCTY
        , RVERS
        , RYEAR
        , ROBJNR
        , COBJNR
        , SOBJNR
        , RTCUR
        , RUNIT
        , DRCRK
        , RPMAX
        , GLREQUEST
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
        , LOGSYS
        , SBUKRS
        , SPRCTR
        , SHOART
        , SFAREA
        , VERSA
        , TSLVT
        , TSL01
        , TSL02
        , TSL03
        , TSL04
        , TSL05
        , TSL06
        , TSL07
        , TSL08
        , TSL09
        , TSL10
        , TSL11
        , TSL12
        , TSL13
        , TSL14
        , TSL15
        , TSL16
        , HSLVT
        , HSL01
        , HSL02
        , HSL03
        , HSL04
        , HSL05
        , HSL06
        , HSL07
        , HSL08
        , HSL09
        , HSL10
        , HSL11
        , HSL12
        , HSL13
        , HSL14
        , HSL15
        , HSL16
        , KSLVT
        , KSL01
        , KSL02
        , KSL03
        , KSL04
        , KSL05
        , KSL06
        , KSL07
        , KSL08
        , KSL09
        , KSL10
        , KSL11
        , KSL12
        , KSL13
        , KSL14
        , KSL15
        , KSL16
        , MSLVT
        , MSL01
        , MSL02
        , MSL03
        , MSL04
        , MSL05
        , MSL06
        , MSL07
        , MSL08
        , MSL09
        , MSL10
        , MSL11
        , MSL12
        , MSL13
        , MSL14
        , MSL15
        , MSL16
        , CSPRED
        , QSPRED
        , STAGR
        , WERKS
        , REP_MATNR
        , RSCOPE
        , RMVCT
        , GLDELFLAG
        , GLSOURCESYSTEM
        , GLCHANGETIME
        , PSA_DELETE_IND
        , PSA_LOAD_DTS
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(CLIENT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(LEDGER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(RECORD_TYPE_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(VERSION_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(FISCAL_YEAR_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(OBJECT_NUMBER1_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(OBJECT_NUMBER2_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(OBJECT_NUMBER3_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(CURRENCY_KEY_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BASE_UOM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(DEBIT_CREDIT_INDICATOR_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(PERIOD_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PROFIT_CENTER_TOTALS_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(LEDGER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as LEDGER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(RECORD_TYPE_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as RECORD_TYPE_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(VERSION_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as VERSION_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(FISCAL_YEAR_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as FISCAL_YEAR_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(RCLNT::text), '^^') 
            , '||', IFNULL(TRIM(RLDNR::text), '^^') 
            , '||', IFNULL(TRIM(RRCTY::text), '^^') 
            , '||', IFNULL(TRIM(RVERS::text), '^^') 
            , '||', IFNULL(TRIM(RYEAR::text), '^^') 
            , '||', IFNULL(TRIM(ROBJNR::text), '^^') 
            , '||', IFNULL(TRIM(COBJNR::text), '^^') 
            , '||', IFNULL(TRIM(SOBJNR::text), '^^') 
            , '||', IFNULL(TRIM(RTCUR::text), '^^') 
            , '||', IFNULL(TRIM(RUNIT::text), '^^') 
            , '||', IFNULL(TRIM(DRCRK::text), '^^') 
            , '||', IFNULL(TRIM(RPMAX::text), '^^') 
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
            , '||', IFNULL(TRIM(LOGSYS::text), '^^') 
            , '||', IFNULL(TRIM(SBUKRS::text), '^^') 
            , '||', IFNULL(TRIM(SPRCTR::text), '^^') 
            , '||', IFNULL(TRIM(SHOART::text), '^^') 
            , '||', IFNULL(TRIM(SFAREA::text), '^^') 
            , '||', IFNULL(TRIM(VERSA::text), '^^') 
            , '||', IFNULL(TRIM(TSLVT::text), '^^') 
            , '||', IFNULL(TRIM(TSL01::text), '^^') 
            , '||', IFNULL(TRIM(TSL02::text), '^^') 
            , '||', IFNULL(TRIM(TSL03::text), '^^') 
            , '||', IFNULL(TRIM(TSL04::text), '^^') 
            , '||', IFNULL(TRIM(TSL05::text), '^^') 
            , '||', IFNULL(TRIM(TSL06::text), '^^') 
            , '||', IFNULL(TRIM(TSL07::text), '^^') 
            , '||', IFNULL(TRIM(TSL08::text), '^^') 
            , '||', IFNULL(TRIM(TSL09::text), '^^') 
            , '||', IFNULL(TRIM(TSL10::text), '^^') 
            , '||', IFNULL(TRIM(TSL11::text), '^^') 
            , '||', IFNULL(TRIM(TSL12::text), '^^') 
            , '||', IFNULL(TRIM(TSL13::text), '^^') 
            , '||', IFNULL(TRIM(TSL14::text), '^^') 
            , '||', IFNULL(TRIM(TSL15::text), '^^') 
            , '||', IFNULL(TRIM(TSL16::text), '^^') 
            , '||', IFNULL(TRIM(HSLVT::text), '^^') 
            , '||', IFNULL(TRIM(HSL01::text), '^^') 
            , '||', IFNULL(TRIM(HSL02::text), '^^') 
            , '||', IFNULL(TRIM(HSL03::text), '^^') 
            , '||', IFNULL(TRIM(HSL04::text), '^^') 
            , '||', IFNULL(TRIM(HSL05::text), '^^') 
            , '||', IFNULL(TRIM(HSL06::text), '^^') 
            , '||', IFNULL(TRIM(HSL07::text), '^^') 
            , '||', IFNULL(TRIM(HSL08::text), '^^') 
            , '||', IFNULL(TRIM(HSL09::text), '^^') 
            , '||', IFNULL(TRIM(HSL10::text), '^^') 
            , '||', IFNULL(TRIM(HSL11::text), '^^') 
            , '||', IFNULL(TRIM(HSL12::text), '^^') 
            , '||', IFNULL(TRIM(HSL13::text), '^^') 
            , '||', IFNULL(TRIM(HSL14::text), '^^') 
            , '||', IFNULL(TRIM(HSL15::text), '^^') 
            , '||', IFNULL(TRIM(HSL16::text), '^^') 
            , '||', IFNULL(TRIM(KSLVT::text), '^^') 
            , '||', IFNULL(TRIM(KSL01::text), '^^') 
            , '||', IFNULL(TRIM(KSL02::text), '^^') 
            , '||', IFNULL(TRIM(KSL03::text), '^^') 
            , '||', IFNULL(TRIM(KSL04::text), '^^') 
            , '||', IFNULL(TRIM(KSL05::text), '^^') 
            , '||', IFNULL(TRIM(KSL06::text), '^^') 
            , '||', IFNULL(TRIM(KSL07::text), '^^') 
            , '||', IFNULL(TRIM(KSL08::text), '^^') 
            , '||', IFNULL(TRIM(KSL09::text), '^^') 
            , '||', IFNULL(TRIM(KSL10::text), '^^') 
            , '||', IFNULL(TRIM(KSL11::text), '^^') 
            , '||', IFNULL(TRIM(KSL12::text), '^^') 
            , '||', IFNULL(TRIM(KSL13::text), '^^') 
            , '||', IFNULL(TRIM(KSL14::text), '^^') 
            , '||', IFNULL(TRIM(KSL15::text), '^^') 
            , '||', IFNULL(TRIM(KSL16::text), '^^') 
            , '||', IFNULL(TRIM(MSLVT::text), '^^') 
            , '||', IFNULL(TRIM(MSL01::text), '^^') 
            , '||', IFNULL(TRIM(MSL02::text), '^^') 
            , '||', IFNULL(TRIM(MSL03::text), '^^') 
            , '||', IFNULL(TRIM(MSL04::text), '^^') 
            , '||', IFNULL(TRIM(MSL05::text), '^^') 
            , '||', IFNULL(TRIM(MSL06::text), '^^') 
            , '||', IFNULL(TRIM(MSL07::text), '^^') 
            , '||', IFNULL(TRIM(MSL08::text), '^^') 
            , '||', IFNULL(TRIM(MSL09::text), '^^') 
            , '||', IFNULL(TRIM(MSL10::text), '^^') 
            , '||', IFNULL(TRIM(MSL11::text), '^^') 
            , '||', IFNULL(TRIM(MSL12::text), '^^') 
            , '||', IFNULL(TRIM(MSL13::text), '^^') 
            , '||', IFNULL(TRIM(MSL14::text), '^^') 
            , '||', IFNULL(TRIM(MSL15::text), '^^') 
            , '||', IFNULL(TRIM(MSL16::text), '^^') 
            , '||', IFNULL(TRIM(CSPRED::text), '^^') 
            , '||', IFNULL(TRIM(QSPRED::text), '^^') 
            , '||', IFNULL(TRIM(STAGR::text), '^^') 
            , '||', IFNULL(TRIM(WERKS::text), '^^') 
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
