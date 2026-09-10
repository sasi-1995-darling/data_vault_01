---- SRC LAYER ----
WITH
SRC_b              as ( SELECT * FROM {{ ref('v_psa_stg_production_order_header__winn_sap') }} as SRC 
                        {% if is_incremental() %}
                        WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}}){% endif %} )

/*
SRC_b              as ( SELECT * FROM STAGING.V_PSA_STG_PRODUCTION_ORDER__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_b as (
    SELECT
        PRODUCTION_ORDER_HK
      , MANDT
      , AUFNR
      , GLREQUEST
      , GLTRP
      , GSTRP
      , FTRMS
      , GLTRS
      , GSTRS
      , GSTRI
      , GETRI
      , GLTRI
      , FTRMI
      , FTRMP
      , RSNUM
      , GASMG
      , GAMNG
      , GMEIN
      , PLNBEZ
      , PLNTY
      , PLNNR
      , PLNAW
      , PLNAL
      , PVERW
      , PLAUF
      , PLSVB
      , PLNME
      , PLSVN
      , PDATV
      , PAENR
      , PLGRP
      , LODIV
      , STLTY
      , STLBEZ
      , STLST
      , STLNR
      , SDATV
      , SBMNG
      , SBMEH
      , SAENR
      , STLAL
      , STLAN
      , SLSVN
      , SLSBS
      , AUFLD
      , DISPO
      , AUFPL
      , FEVOR
      , FHORI
      , TERKZ
      , REDKZ
      , APRIO
      , NTZUE
      , VORUE
      , PROFID
      , VORGZ
      , SICHZ
      , FREIZ
      , UPTER
      , BEDID
      , PRONR
      , ZAEHL
      , MZAEHL
      , ZKRIZ
      , PRUEFLOS
      , KLVARP
      , KLVARI
      , RGEKZ
      , PLART
      , FLG_AOB
      , FLG_ARBEI
      , GLTPP
      , GSTPP
      , GLTPS
      , GSTPS
      , FTRPS
      , RDKZP
      , TRKZP
      , RUECK
      , RMZHL
      , IGMNG
      , RATID
      , GROID
      , CUOBJ
      , GLUZS
      , GSUZS
      , REVLV
      , RSHTY
      , RSHID
      , RSNTY
      , RSNID
      , NAUTERM
      , NAUCOST
      , STUFE
      , WEGXX
      , VWEGX
      , ARSNR
      , ARSPS
      , MAUFNR
      , LKNOT
      , RKNOT
      , PRODNET
      , IASMG
      , ABARB
      , AUFNT
      , AUFPT
      , APLZT
      , NO_DISP
      , CSPLIT
      , AENNR
      , CY_SEQNR
      , BREAKS
      , VORGZ_TRM
      , SICHZ_TRM
      , TRMDT
      , GLUZP
      , GSUZP
      , GSUZI
      , GEUZI
      , GLUPP
      , GSUPP
      , GLUPS
      , GSUPS
      , CHSCH
      , KAPT_VORGZ
      , KAPT_SICHZ
      , LEAD_AUFNR
      , PNETSTARTD
      , PNETSTARTT
      , PNETENDD
      , PNETENDT
      , KBED
      , KKALKR
      , SFCPF
      , RMNGA
      , GSBTR
      , VFMNG
      , NOPCOST
      , NETZKONT
      , ATRKZ
      , OBJTYPE
      , CH_PROC
      , KAPVERSA
      , COLORDPROC
      , KZERB
      , CONF_KEY
      , ST_ARBID
      , VSNMR_V
      , TERHW
      , SPLSTAT
      , COSTUPD
      , MAX_GAMNG
      , MES_ROUTINGID
      , ADPSP
      , RMANR
      , POSNR_RMA
      , POSNV_RMA
      , CFB_MAXLZ
      , CFB_LZEIH
      , CFB_ADTDAYS
      , CFB_DATOFM
      , CFB_BBDPI
      , OIHANTYP
      , FSH_MPROD_ORD
      , FLG_BUNDLE
      , MILL_RATIO
      , BMEINS
      , BMENGE
      , MILL_OC_ZUSKZ
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , HASHDIFF
      , REC_SRC
    FROM SRC_b
)
---- RENAME LAYER ----

, RENAME_b as (
    SELECT
        PRODUCTION_ORDER_HK
      , MANDT
      , AUFNR
      , GLREQUEST
      , GLTRP
      , GSTRP
      , FTRMS
      , GLTRS
      , GSTRS
      , GSTRI
      , GETRI
      , GLTRI
      , FTRMI
      , FTRMP
      , RSNUM
      , GASMG
      , GAMNG
      , GMEIN
      , PLNBEZ
      , PLNTY
      , PLNNR
      , PLNAW
      , PLNAL
      , PVERW
      , PLAUF
      , PLSVB
      , PLNME
      , PLSVN
      , PDATV
      , PAENR
      , PLGRP
      , LODIV
      , STLTY
      , STLBEZ
      , STLST
      , STLNR
      , SDATV
      , SBMNG
      , SBMEH
      , SAENR
      , STLAL
      , STLAN
      , SLSVN
      , SLSBS
      , AUFLD
      , DISPO
      , AUFPL
      , FEVOR
      , FHORI
      , TERKZ
      , REDKZ
      , APRIO
      , NTZUE
      , VORUE
      , PROFID
      , VORGZ
      , SICHZ
      , FREIZ
      , UPTER
      , BEDID
      , PRONR
      , ZAEHL
      , MZAEHL
      , ZKRIZ
      , PRUEFLOS
      , KLVARP
      , KLVARI
      , RGEKZ
      , PLART
      , FLG_AOB
      , FLG_ARBEI
      , GLTPP
      , GSTPP
      , GLTPS
      , GSTPS
      , FTRPS
      , RDKZP
      , TRKZP
      , RUECK
      , RMZHL
      , IGMNG
      , RATID
      , GROID
      , CUOBJ
      , GLUZS
      , GSUZS
      , REVLV
      , RSHTY
      , RSHID
      , RSNTY
      , RSNID
      , NAUTERM
      , NAUCOST
      , STUFE
      , WEGXX
      , VWEGX
      , ARSNR
      , ARSPS
      , MAUFNR
      , LKNOT
      , RKNOT
      , PRODNET
      , IASMG
      , ABARB
      , AUFNT
      , AUFPT
      , APLZT
      , NO_DISP
      , CSPLIT
      , AENNR
      , CY_SEQNR
      , BREAKS
      , VORGZ_TRM
      , SICHZ_TRM
      , TRMDT
      , GLUZP
      , GSUZP
      , GSUZI
      , GEUZI
      , GLUPP
      , GSUPP
      , GLUPS
      , GSUPS
      , CHSCH
      , KAPT_VORGZ
      , KAPT_SICHZ
      , LEAD_AUFNR
      , PNETSTARTD
      , PNETSTARTT
      , PNETENDD
      , PNETENDT
      , KBED
      , KKALKR
      , SFCPF
      , RMNGA
      , GSBTR
      , VFMNG
      , NOPCOST
      , NETZKONT
      , ATRKZ
      , OBJTYPE
      , CH_PROC
      , KAPVERSA
      , COLORDPROC
      , KZERB
      , CONF_KEY
      , ST_ARBID
      , VSNMR_V
      , TERHW
      , SPLSTAT
      , COSTUPD
      , MAX_GAMNG
      , MES_ROUTINGID
      , ADPSP
      , RMANR
      , POSNR_RMA
      , POSNV_RMA
      , CFB_MAXLZ
      , CFB_LZEIH
      , CFB_ADTDAYS
      , CFB_DATOFM
      , CFB_BBDPI
      , OIHANTYP
      , FSH_MPROD_ORD
      , FLG_BUNDLE
      , MILL_RATIO
      , BMEINS
      , BMENGE
      , MILL_OC_ZUSKZ
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , HASHDIFF
      , REC_SRC
    FROM LOGIC_b
)
---- FILTER LAYER ----

, FILTER_b as (
    SELECT *
    FROM RENAME_b
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_b
)

---- FINAL LAYER ----
SELECT
          PRODUCTION_ORDER_HK
        , MANDT
        , AUFNR
        , GLREQUEST
        , GLTRP
        , GSTRP
        , FTRMS
        , GLTRS
        , GSTRS
        , GSTRI
        , GETRI
        , GLTRI
        , FTRMI
        , FTRMP
        , RSNUM
        , GASMG
        , GAMNG
        , GMEIN
        , PLNBEZ
        , PLNTY
        , PLNNR
        , PLNAW
        , PLNAL
        , PVERW
        , PLAUF
        , PLSVB
        , PLNME
        , PLSVN
        , PDATV
        , PAENR
        , PLGRP
        , LODIV
        , STLTY
        , STLBEZ
        , STLST
        , STLNR
        , SDATV
        , SBMNG
        , SBMEH
        , SAENR
        , STLAL
        , STLAN
        , SLSVN
        , SLSBS
        , AUFLD
        , DISPO
        , AUFPL
        , FEVOR
        , FHORI
        , TERKZ
        , REDKZ
        , APRIO
        , NTZUE
        , VORUE
        , PROFID
        , VORGZ
        , SICHZ
        , FREIZ
        , UPTER
        , BEDID
        , PRONR
        , ZAEHL
        , MZAEHL
        , ZKRIZ
        , PRUEFLOS
        , KLVARP
        , KLVARI
        , RGEKZ
        , PLART
        , FLG_AOB
        , FLG_ARBEI
        , GLTPP
        , GSTPP
        , GLTPS
        , GSTPS
        , FTRPS
        , RDKZP
        , TRKZP
        , RUECK
        , RMZHL
        , IGMNG
        , RATID
        , GROID
        , CUOBJ
        , GLUZS
        , GSUZS
        , REVLV
        , RSHTY
        , RSHID
        , RSNTY
        , RSNID
        , NAUTERM
        , NAUCOST
        , STUFE
        , WEGXX
        , VWEGX
        , ARSNR
        , ARSPS
        , MAUFNR
        , LKNOT
        , RKNOT
        , PRODNET
        , IASMG
        , ABARB
        , AUFNT
        , AUFPT
        , APLZT
        , NO_DISP
        , CSPLIT
        , AENNR
        , CY_SEQNR
        , BREAKS
        , VORGZ_TRM
        , SICHZ_TRM
        , TRMDT
        , GLUZP
        , GSUZP
        , GSUZI
        , GEUZI
        , GLUPP
        , GSUPP
        , GLUPS
        , GSUPS
        , CHSCH
        , KAPT_VORGZ
        , KAPT_SICHZ
        , LEAD_AUFNR
        , PNETSTARTD
        , PNETSTARTT
        , PNETENDD
        , PNETENDT
        , KBED
        , KKALKR
        , SFCPF
        , RMNGA
        , GSBTR
        , VFMNG
        , NOPCOST
        , NETZKONT
        , ATRKZ
        , OBJTYPE
        , CH_PROC
        , KAPVERSA
        , COLORDPROC
        , KZERB
        , CONF_KEY
        , ST_ARBID
        , VSNMR_V
        , TERHW
        , SPLSTAT
        , COSTUPD
        , MAX_GAMNG
        , MES_ROUTINGID
        , ADPSP
        , RMANR
        , POSNR_RMA
        , POSNV_RMA
        , CFB_MAXLZ
        , CFB_LZEIH
        , CFB_ADTDAYS
        , CFB_DATOFM
        , CFB_BBDPI
        , OIHANTYP
        , FSH_MPROD_ORD
        , FLG_BUNDLE
        , MILL_RATIO
        , BMEINS
        , BMENGE
        , MILL_OC_ZUSKZ
        , GLDELFLAG
        , GLCHANGETIME
        , GLSOURCESYSTEM
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , HASHDIFF
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.PRODUCTION_ORDER_HK = JOIN_RESULT.PRODUCTION_ORDER_HK  
   AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %}
{% if not is_incremental() %}

/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per HK and hashdiff. */
qualify 1 = row_number() over (partition by PRODUCTION_ORDER_HK, HASHDIFF order by PSA_LOAD_DTS)

union all
SELECT 
MD5_BINARY(GR.VALUE) AS PRODUCTION_ORDER_HK,
NULL AS MANDT,
GR.VALUE::text AS AUFNR,
NULL AS GLREQUEST,
NULL AS GLTRP,
NULL AS GSTRP,
NULL AS FTRMS,
NULL AS GLTRS,
NULL AS GSTRS,
NULL AS GSTRI,
NULL AS GETRI,
NULL AS GLTRI,
NULL AS FTRMI,
NULL AS FTRMP,
NULL AS RSNUM,
NULL AS GASMG,
NULL AS GAMNG,
NULL AS GMEIN,
NULL AS PLNBEZ,
NULL AS PLNTY,
NULL AS PLNNR,
NULL AS PLNAW,
NULL AS PLNAL,
NULL AS PVERW,
NULL AS PLAUF,
NULL AS PLSVB,
NULL AS PLNME,
NULL AS PLSVN,
NULL AS PDATV,
NULL AS PAENR,
NULL AS PLGRP,
NULL AS LODIV,
NULL AS STLTY,
NULL AS STLBEZ,
NULL AS STLST,
NULL AS STLNR,
NULL AS SDATV,
NULL AS SBMNG,
NULL AS SBMEH,
NULL AS SAENR,
NULL AS STLAL,
NULL AS STLAN,
NULL AS SLSVN,
NULL AS SLSBS,
NULL AS AUFLD,
NULL AS DISPO,
NULL AS AUFPL,
NULL AS FEVOR,
NULL AS FHORI,
NULL AS TERKZ,
NULL AS REDKZ,
NULL AS APRIO,
NULL AS NTZUE,
NULL AS VORUE,
NULL AS PROFID,
NULL AS VORGZ,
NULL AS SICHZ,
NULL AS FREIZ,
NULL AS UPTER,
NULL AS BEDID,
NULL AS PRONR,
NULL AS ZAEHL,
NULL AS MZAEHL,
NULL AS ZKRIZ,
NULL AS PRUEFLOS,
NULL AS KLVARP,
NULL AS KLVARI,
NULL AS RGEKZ,
NULL AS PLART,
NULL AS FLG_AOB,
NULL AS FLG_ARBEI,
NULL AS GLTPP,
NULL AS GSTPP,
NULL AS GLTPS,
NULL AS GSTPS,
NULL AS FTRPS,
NULL AS RDKZP,
NULL AS TRKZP,
NULL AS RUECK,
NULL AS RMZHL,
NULL AS IGMNG,
NULL AS RATID,
NULL AS GROID,
NULL AS CUOBJ,
NULL AS GLUZS,
NULL AS GSUZS,
NULL AS REVLV,
NULL AS RSHTY,
NULL AS RSHID,
NULL AS RSNTY,
NULL AS RSNID,
NULL AS NAUTERM,
NULL AS NAUCOST,
NULL AS STUFE,
NULL AS WEGXX,
NULL AS VWEGX,
NULL AS ARSNR,
NULL AS ARSPS,
NULL AS MAUFNR,
NULL AS LKNOT,
NULL AS RKNOT,
NULL AS PRODNET,
NULL AS IASMG,
NULL AS ABARB,
NULL AS AUFNT,
NULL AS AUFPT,
NULL AS APLZT,
NULL AS NO_DISP,
NULL AS CSPLIT,
NULL AS AENNR,
NULL AS CY_SEQNR,
NULL AS BREAKS,
NULL AS VORGZ_TRM,
NULL AS SICHZ_TRM,
NULL AS TRMDT,
NULL AS GLUZP,
NULL AS GSUZP,
NULL AS GSUZI,
NULL AS GEUZI,
NULL AS GLUPP,
NULL AS GSUPP,
NULL AS GLUPS,
NULL AS GSUPS,
NULL AS CHSCH,
NULL AS KAPT_VORGZ,
NULL AS KAPT_SICHZ,
NULL AS LEAD_AUFNR,
NULL AS PNETSTARTD,
NULL AS PNETSTARTT,
NULL AS PNETENDD,
NULL AS PNETENDT,
NULL AS KBED,
NULL AS KKALKR,
NULL AS SFCPF,
NULL AS RMNGA,
NULL AS GSBTR,
NULL AS VFMNG,
NULL AS NOPCOST,
NULL AS NETZKONT,
NULL AS ATRKZ,
NULL AS OBJTYPE,
NULL AS CH_PROC,
NULL AS KAPVERSA,
NULL AS COLORDPROC,
NULL AS KZERB,
NULL AS CONF_KEY,
NULL AS ST_ARBID,
NULL AS VSNMR_V,
NULL AS TERHW,
NULL AS SPLSTAT,
NULL AS COSTUPD,
NULL AS MAX_GAMNG,
NULL AS MES_ROUTINGID,
NULL AS ADPSP,
NULL AS RMANR,
NULL AS POSNR_RMA,
NULL AS POSNV_RMA,
NULL AS CFB_MAXLZ,
NULL AS CFB_LZEIH,
NULL AS CFB_ADTDAYS,
NULL AS CFB_DATOFM,
NULL AS CFB_BBDPI,
NULL AS OIHANTYP,
NULL AS FSH_MPROD_ORD,
NULL AS FLG_BUNDLE,
NULL AS MILL_RATIO,
NULL AS BMEINS,
NULL AS BMENGE,
NULL AS MILL_OC_ZUSKZ,
NULL AS GLDELFLAG,
NULL AS GLCHANGETIME,
NULL AS GLSOURCESYSTEM,
'1900-01-01'::TIMESTAMP AS PSA_LOAD_DTS,
NULL AS PSA_RECORD_SOURCE,
'N' AS PSA_DELETE_IND,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
''::BINARY AS HASHDIFF,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
