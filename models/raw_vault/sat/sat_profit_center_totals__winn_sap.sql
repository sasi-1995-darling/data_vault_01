---- SRC LAYER ----
WITH
SRC_SWINN          as ( SELECT * FROM {{ ref('v_psa_stg_profit_center_totals__winn_sap') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_SWINN          as ( SELECT * FROM STAGING.V_PSA_STG_PROFIT_CENTER_TOTALS__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_SWINN as (
    SELECT
        PROFIT_CENTER_TOTALS_HK
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
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM SRC_SWINN
)
---- RENAME LAYER ----

, RENAME_SWINN as (
    SELECT
        PROFIT_CENTER_TOTALS_HK
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
      , PSA_DELETE_IND
      , LOAD_DTS
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
          PROFIT_CENTER_TOTALS_HK
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
        , PSA_DELETE_IND
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , HASHDIFF
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.PROFIT_CENTER_TOTALS_HK= JOIN_RESULT.PROFIT_CENTER_TOTALS_HK
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %} 
{% if not is_incremental() %}
/*the following qualify is to restrict multiple loads of touched records during the initial build. Ex: multiple row per hk, hashdiff */
qualify 1= row_number()over(partition by PROFIT_CENTER_TOTALS_HK, HASHDIFF order by LOAD_DTS)
union all
    SELECT        
    MD5_BINARY(GR.VALUE) AS PROFIT_CENTER_TOTALS_HK
      , NULL AS RCLNT
, NULL AS RLDNR
, NULL AS RRCTY
, NULL AS RVERS
, NULL AS RYEAR
, NULL AS ROBJNR
, NULL AS COBJNR
, NULL AS SOBJNR
, NULL AS RTCUR
, NULL AS RUNIT
, NULL AS DRCRK
, NULL AS RPMAX
, NULL AS GLREQUEST
, NULL AS RBUKRS
, NULL AS RPRCTR
, NULL AS RHOART
, NULL AS RFAREA
, NULL AS KOKRS
, NULL AS RACCT
, NULL AS HRKFT
, NULL AS RASSC
, NULL AS EPRCTR
, NULL AS ACTIV
, NULL AS AFABE
, NULL AS OCLNT
, NULL AS LOGSYS
, NULL AS SBUKRS
, NULL AS SPRCTR
, NULL AS SHOART
, NULL AS SFAREA
, NULL AS VERSA
, NULL AS TSLVT
, NULL AS TSL01
, NULL AS TSL02
, NULL AS TSL03
, NULL AS TSL04
, NULL AS TSL05
, NULL AS TSL06
, NULL AS TSL07
, NULL AS TSL08
, NULL AS TSL09
, NULL AS TSL10
, NULL AS TSL11
, NULL AS TSL12
, NULL AS TSL13
, NULL AS TSL14
, NULL AS TSL15
, NULL AS TSL16
, NULL AS HSLVT
, NULL AS HSL01
, NULL AS HSL02
, NULL AS HSL03
, NULL AS HSL04
, NULL AS HSL05
, NULL AS HSL06
, NULL AS HSL07
, NULL AS HSL08
, NULL AS HSL09
, NULL AS HSL10
, NULL AS HSL11
, NULL AS HSL12
, NULL AS HSL13
, NULL AS HSL14
, NULL AS HSL15
, NULL AS HSL16
, NULL AS KSLVT
, NULL AS KSL01
, NULL AS KSL02
, NULL AS KSL03
, NULL AS KSL04
, NULL AS KSL05
, NULL AS KSL06
, NULL AS KSL07
, NULL AS KSL08
, NULL AS KSL09
, NULL AS KSL10
, NULL AS KSL11
, NULL AS KSL12
, NULL AS KSL13
, NULL AS KSL14
, NULL AS KSL15
, NULL AS KSL16
, NULL AS MSLVT
, NULL AS MSL01
, NULL AS MSL02
, NULL AS MSL03
, NULL AS MSL04
, NULL AS MSL05
, NULL AS MSL06
, NULL AS MSL07
, NULL AS MSL08
, NULL AS MSL09
, NULL AS MSL10
, NULL AS MSL11
, NULL AS MSL12
, NULL AS MSL13
, NULL AS MSL14
, NULL AS MSL15
, NULL AS MSL16
, NULL AS CSPRED
, NULL AS QSPRED
, NULL AS STAGR
, NULL AS WERKS
, NULL AS REP_MATNR
, NULL AS RSCOPE
, NULL AS RMVCT
, NULL AS GLDELFLAG
, NULL AS GLCHANGETIME
, NULL AS GLSOURCESYSTEM
    , NULL  AS PSA_DELETE_IND
, CONVERT_TIMEZONE('UTC','1900-01-01')  as  LOAD_DTS
,'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
, DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS BKCC
, ''::BINARY as HASH_DIFF FROM
        TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}