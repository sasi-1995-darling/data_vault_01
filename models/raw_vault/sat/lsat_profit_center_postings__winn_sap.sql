---- SRC LAYER ----
WITH
SRC_PROFIT          as ( SELECT * FROM {{ ref('v_psa_stg_profit_center_line_item__winn_sap') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_SWINN          as ( SELECT * FROM STAGING.v_psa_stg_profit_center_line_item__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_PROFIT as (
    SELECT
        PROFIT_CENTER_POSTINGS_HK
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
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM SRC_PROFIT
)
---- RENAME LAYER ----

, RENAME_PROFIT as (
    SELECT
        PROFIT_CENTER_POSTINGS_HK
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
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM LOGIC_PROFIT
)
---- FILTER LAYER ----

, FILTER_PROFIT as (
    SELECT *
    FROM RENAME_PROFIT
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_PROFIT
)

---- FINAL LAYER ----
SELECT
        PROFIT_CENTER_POSTINGS_HK
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
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
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
    WHERE existing.PROFIT_CENTER_POSTINGS_HK= JOIN_RESULT.PROFIT_CENTER_POSTINGS_HK
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %} 
{% if not is_incremental() %}
/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per HK and hashdiff. */
qualify 1= row_number()over(partition by PROFIT_CENTER_POSTINGS_HK, HASHDIFF order by PSA_LOAD_DTS)
union all
    SELECT        
    MD5_BINARY(GR.VALUE) AS PROFIT_CENTER_POSTINGS_HK
    , NULL AS RCLNT
    , NULL AS GL_SIRID
    , NULL AS GLREQUEST
    , NULL AS RLDNR
    , NULL AS RRCTY
    , NULL AS RVERS
    , NULL AS RYEAR
    , NULL AS RTCUR
    , NULL AS RUNIT
    , NULL AS DRCRK
    , NULL AS POPER
    , NULL AS DOCCT
    , NULL AS DOCNR
    , NULL AS DOCLN
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
    , NULL AS SBUKRS
    , NULL AS SPRCTR
    , NULL AS SHOART
    , NULL AS SFAREA
    , NULL AS TSL
    , NULL AS HSL
    , NULL AS KSL
    , NULL AS MSL
    , NULL AS CPUDT
    , NULL AS CPUTM
    , NULL AS USNAM
    , NULL AS SGTXT
    , NULL AS AUTOM
    , NULL AS DOCTY
    , NULL AS BLDAT
    , NULL AS BUDAT
    , NULL AS WSDAT
    , NULL AS REFDOCNR
    , NULL AS REFRYEAR
    , NULL AS REFDOCLN
    , NULL AS REFDOCCT
    , NULL AS REFACTIV
    , NULL AS AWTYP
    , NULL AS AWORG
    , NULL AS WERKS
    , NULL AS GSBER
    , NULL AS KOSTL
    , NULL AS LSTAR
    , NULL AS AUFNR
    , NULL AS AUFPL
    , NULL AS ANLN1
    , NULL AS ANLN2
    , NULL AS MATNR
    , NULL AS BWKEY
    , NULL AS BWTAR
    , NULL AS ANBWA
    , NULL AS KUNNR
    , NULL AS LIFNR
    , NULL AS RMVCT
    , NULL AS EBELN
    , NULL AS EBELP
    , NULL AS KSTRG
    , NULL AS ERKRS
    , NULL AS PAOBJNR
    , NULL AS PASUBNR
    , NULL AS PS_PSP_PNR
    , NULL AS KDAUF
    , NULL AS KDPOS
    , NULL AS FKART
    , NULL AS VKORG
    , NULL AS VTWEG
    , NULL AS AUBEL
    , NULL AS AUPOS
    , NULL AS SPART
    , NULL AS VBELN
    , NULL AS POSNR
    , NULL AS VKGRP
    , NULL AS VKBUR
    , NULL AS VBUND
    , NULL AS LOGSYS
    , NULL AS ALEBN
    , NULL AS AWSYS
    , NULL AS VERSA
    , NULL AS STFLG
    , NULL AS STOKZ
    , NULL AS STAGR
    , NULL AS GRTYP
    , NULL AS REP_MATNR
    , NULL AS CO_PRZNR
    , NULL AS IMKEY
    , NULL AS DABRZ
    , NULL AS VALUT
    , NULL AS RSCOPE
    , NULL AS AWREF_REV
    , NULL AS AWORG_REV
    , NULL AS BWART
    , NULL AS BLART
    , NULL AS GLDELFLAG
    , NULL AS GLSOURCESYSTEM
    , NULL AS PSA_LOAD_DTS
    , NULL AS PSA_RECORD_SOURCE
    , NULL AS PSA_DELETE_IND
, CONVERT_TIMEZONE('UTC','1900-01-01')  as  LOAD_DTS
,'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
, DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS BKCC
, ''::BINARY as HASHDIFF FROM
        TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}