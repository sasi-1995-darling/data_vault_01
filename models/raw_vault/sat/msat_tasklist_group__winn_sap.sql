---- SRC LAYER ----
WITH
SRC_a              as ( SELECT * FROM {{ ref('v_psa_stg_tasklist_group__winn_sap') }} as SRC 
                        {% if is_incremental() %}
                        WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}}){% endif %} )

/*
SRC_a              as ( SELECT * FROM STAGING.V_PSA_STG_TASKLIST_GROUP__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_a as (
    SELECT
        TASKLIST_GROUP_HK
      , MANDT
      , PLNTY
      , PLNNR
      , PLNAL
      , ZAEHL
      , GLREQUEST
      , DATUV
      , TECHV
      , AENNR
      , LOEKZ
      , PARKZ
      , ANDAT
      , ANNAM
      , AEDAT
      , AENAM
      , VERWE
      , WERKS
      , STATU
      , PLNME
      , LOSVN
      , LOSBS
      , VAGRP
      , AESZN
      , KTEXT
      , TXTSP
      , ABDAT
      , ABANZ
      , PROFIDNETZ
      , KOKRS
      , QVEWERKS
      , QVEMENGE
      , QVEVERSION
      , QVEDATUM
      , QVEGRUPPE
      , QVECODE
      , QDYNREGEL
      , QDYNHEAD
      , QPRZIEHVER
      , QVERSNPRZV
      , QKZRASTER
      , QDYNSTRING
      , STRAT
      , PPOOL
      , ISTRU
      , IWERK
      , ANLZU
      , ARBID
      , EXTNUM
      , DELKZ
      , ARBTY
      , STUPR
      , CLNDR
      , PRTYP
      , REODAT
      , NETID
      , FLG_CHK
      , PSPNR
      , TTRAS
      , KZKFG
      , PLNNR_ALT
      , FLG_CAPO
      , STLTY
      , STLNR
      , STLAL
      , SLWBEZ
      , PPKZTLZU
      , CHRULE
      , CCOAA
      , ST_ARBID
      , MEINH
      , UMREZ
      , UMREN
      , BMSCH
      , ADPSP
      , MS_FLAG
      , TSTMP_BW
      , MES_ROUTINGID
      , XHIERTL
      , TL_EXTID
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , HASHDIFF
      , REC_SRC
    FROM SRC_a
)
---- RENAME LAYER ----

, RENAME_a as (
    SELECT
        TASKLIST_GROUP_HK
      , MANDT
      , PLNTY
      , PLNNR
      , PLNAL
      , ZAEHL
      , GLREQUEST
      , DATUV
      , TECHV
      , AENNR
      , LOEKZ
      , PARKZ
      , ANDAT
      , ANNAM
      , AEDAT
      , AENAM
      , VERWE
      , WERKS
      , STATU
      , PLNME
      , LOSVN
      , LOSBS
      , VAGRP
      , AESZN
      , KTEXT
      , TXTSP
      , ABDAT
      , ABANZ
      , PROFIDNETZ
      , KOKRS
      , QVEWERKS
      , QVEMENGE
      , QVEVERSION
      , QVEDATUM
      , QVEGRUPPE
      , QVECODE
      , QDYNREGEL
      , QDYNHEAD
      , QPRZIEHVER
      , QVERSNPRZV
      , QKZRASTER
      , QDYNSTRING
      , STRAT
      , PPOOL
      , ISTRU
      , IWERK
      , ANLZU
      , ARBID
      , EXTNUM
      , DELKZ
      , ARBTY
      , STUPR
      , CLNDR
      , PRTYP
      , REODAT
      , NETID
      , FLG_CHK
      , PSPNR
      , TTRAS
      , KZKFG
      , PLNNR_ALT
      , FLG_CAPO
      , STLTY
      , STLNR
      , STLAL
      , SLWBEZ
      , PPKZTLZU
      , CHRULE
      , CCOAA
      , ST_ARBID
      , MEINH
      , UMREZ
      , UMREN
      , BMSCH
      , ADPSP
      , MS_FLAG
      , TSTMP_BW
      , MES_ROUTINGID
      , XHIERTL
      , TL_EXTID
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , HASHDIFF
      , REC_SRC
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
          TASKLIST_GROUP_HK
        , MANDT
        , PLNTY
        , PLNNR
        , PLNAL
        , ZAEHL
        , GLREQUEST
        , DATUV
        , TECHV
        , AENNR
        , LOEKZ
        , PARKZ
        , ANDAT
        , ANNAM
        , AEDAT
        , AENAM
        , VERWE
        , WERKS
        , STATU
        , PLNME
        , LOSVN
        , LOSBS
        , VAGRP
        , AESZN
        , KTEXT
        , TXTSP
        , ABDAT
        , ABANZ
        , PROFIDNETZ
        , KOKRS
        , QVEWERKS
        , QVEMENGE
        , QVEVERSION
        , QVEDATUM
        , QVEGRUPPE
        , QVECODE
        , QDYNREGEL
        , QDYNHEAD
        , QPRZIEHVER
        , QVERSNPRZV
        , QKZRASTER
        , QDYNSTRING
        , STRAT
        , PPOOL
        , ISTRU
        , IWERK
        , ANLZU
        , ARBID
        , EXTNUM
        , DELKZ
        , ARBTY
        , STUPR
        , CLNDR
        , PRTYP
        , REODAT
        , NETID
        , FLG_CHK
        , PSPNR
        , TTRAS
        , KZKFG
        , PLNNR_ALT
        , FLG_CAPO
        , STLTY
        , STLNR
        , STLAL
        , SLWBEZ
        , PPKZTLZU
        , CHRULE
        , CCOAA
        , ST_ARBID
        , MEINH
        , UMREZ
        , UMREN
        , BMSCH
        , ADPSP
        , MS_FLAG
        , TSTMP_BW
        , MES_ROUTINGID
        , XHIERTL
        , TL_EXTID
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
    WHERE existing.TASKLIST_GROUP_HK = JOIN_RESULT.TASKLIST_GROUP_HK 
AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %}
{% if not is_incremental() %}

/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per HK and hashdiff. */
qualify 1 = row_number() over (partition by TASKLIST_GROUP_HK, HASHDIFF order by PSA_LOAD_DTS)

union all
SELECT 
MD5_BINARY(GR.VALUE) AS TASKLIST_GROUP_HK,
NULL AS MANDT,
GR.VALUE::text AS PLNTY,
GR.VALUE::text AS PLNNR,
GR.VALUE::text AS PLNAL,
GR.VALUE::text AS ZAEHL,
NULL AS GLREQUEST,
NULL AS DATUV,
NULL AS TECHV,
NULL AS AENNR,
NULL AS LOEKZ,
NULL AS PARKZ,
NULL AS ANDAT,
NULL AS ANNAM,
NULL AS AEDAT,
NULL AS AENAM,
NULL AS VERWE,
NULL AS WERKS,
NULL AS STATU,
NULL AS PLNME,
NULL AS LOSVN,
NULL AS LOSBS,
NULL AS VAGRP,
NULL AS AESZN,
NULL AS KTEXT,
NULL AS TXTSP,
NULL AS ABDAT,
NULL AS ABANZ,
NULL AS PROFIDNETZ,
NULL AS KOKRS,
NULL AS QVEWERKS,
NULL AS QVEMENGE,
NULL AS QVEVERSION,
NULL AS QVEDATUM,
NULL AS QVEGRUPPE,
NULL AS QVECODE,
NULL AS QDYNREGEL,
NULL AS QDYNHEAD,
NULL AS QPRZIEHVER,
NULL AS QVERSNPRZV,
NULL AS QKZRASTER,
NULL AS QDYNSTRING,
NULL AS STRAT,
NULL AS PPOOL,
NULL AS ISTRU,
NULL AS IWERK,
NULL AS ANLZU,
NULL AS ARBID,
NULL AS EXTNUM,
NULL AS DELKZ,
NULL AS ARBTY,
NULL AS STUPR,
NULL AS CLNDR,
NULL AS PRTYP,
NULL AS REODAT,
NULL AS NETID,
NULL AS FLG_CHK,
NULL AS PSPNR,
NULL AS TTRAS,
NULL AS KZKFG,
NULL AS PLNNR_ALT,
NULL AS FLG_CAPO,
NULL AS STLTY,
NULL AS STLNR,
NULL AS STLAL,
NULL AS SLWBEZ,
NULL AS PPKZTLZU,
NULL AS CHRULE,
NULL AS CCOAA,
NULL AS ST_ARBID,
NULL AS MEINH,
NULL AS UMREZ,
NULL AS UMREN,
NULL AS BMSCH,
NULL AS ADPSP,
NULL AS MS_FLAG,
NULL AS TSTMP_BW,
NULL AS MES_ROUTINGID,
NULL AS XHIERTL,
NULL AS TL_EXTID,
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
