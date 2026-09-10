---- SRC LAYER ----
WITH
SRC_SRC            as ( SELECT * FROM {{ ref('v_psa_stg_location_assignment__winn_sap') }} as SRC 
{% if is_incremental() %}
      where src.load_dts > (select dateadd('HOUR',-1,max(load_dts)) from {{ this }})
    {% endif %} )

/*
SRC_SRC            as ( SELECT * FROM int_staging_views.v_psa_stg_location_assignment__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_SRC as (
    SELECT
        LNK_LOCATION_ASSIGNMENT_DETAIL_HK
      , ILOAN
      , MANDT
      , GLREQUEST
      , TPLNR
      , ABCKZ
      , ABCKZI
      , EQFNR
      , EQFNRI
      , SWERK
      , SWERKI
      , STORT
      , STORTI
      , MSGRP
      , MSGRPI
      , BEBER
      , BEBERI
      , CR_OBJTY
      , PPSID
      , PPSIDI
      , GSBER
      , GSBERI
      , KOKRS
      , KOKRSI
      , KOSTL
      , KOSTLI
      , PROID
      , PROIDI
      , BUKRS
      , BUKRSI
      , ANLNR
      , ANLNRI
      , ANLUN
      , ANLUNI
      , DAUFN
      , DAUFNI
      , AUFNR
      , AUFNRI
      , TPLNRI
      , VKORG
      , VKORGI
      , VTWEG
      , VTWEGI
      , SPART
      , SPARTI
      , ADRNR
      , ADRNRI
      , OWNER
      , VKBUR
      , VKGRP
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , LOAD_DTS
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM SRC_SRC
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM LOGIC_SRC
)

---- FINAL LAYER ----
SELECT
          LNK_LOCATION_ASSIGNMENT_DETAIL_HK
        , ILOAN
        , MANDT
        , GLREQUEST
        , TPLNR
        , ABCKZ
        , ABCKZI
        , EQFNR
        , EQFNRI
        , SWERK
        , SWERKI
        , STORT
        , STORTI
        , MSGRP
        , MSGRPI
        , BEBER
        , BEBERI
        , CR_OBJTY
        , PPSID
        , PPSIDI
        , GSBER
        , GSBERI
        , KOKRS
        , KOKRSI
        , KOSTL
        , KOSTLI
        , PROID
        , PROIDI
        , BUKRS
        , BUKRSI
        , ANLNR
        , ANLNRI
        , ANLUN
        , ANLUNI
        , DAUFN
        , DAUFNI
        , AUFNR
        , AUFNRI
        , TPLNRI
        , VKORG
        , VKORGI
        , VTWEG
        , VTWEGI
        , SPART
        , SPARTI
        , ADRNR
        , ADRNRI
        , OWNER
        , VKBUR
        , VKGRP
        , GLDELFLAG
        , GLCHANGETIME
        , GLSOURCESYSTEM
        , PSA_DELETE_IND
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , HASHDIFF
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1
    FROM {{ this }} existing
    WHERE existing.LNK_LOCATION_ASSIGNMENT_DETAIL_HK = JOIN_RESULT.LNK_LOCATION_ASSIGNMENT_DETAIL_HK
      AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %}
{% if not is_incremental() %}

/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per HK and hashdiff. */
qualify 1 = row_number() over (partition by LNK_LOCATION_ASSIGNMENT_DETAIL_HK, HASHDIFF order by PSA_LOAD_DTS)

union all
SELECT 
MD5_BINARY(GR.VALUE) AS LNK_LOCATION_ASSIGNMENT_DETAIL_HK,
NULL AS ILOAN,
NULL AS MANDT,
NULL AS GLREQUEST,
NULL AS TPLNR,
NULL AS ABCKZ,
NULL AS ABCKZI,
NULL AS EQFNR,
NULL AS EQFNRI,
NULL AS SWERK,
NULL AS SWERKI,
NULL AS STORT,
NULL AS STORTI,
NULL AS MSGRP,
NULL AS MSGRPI,
NULL AS BEBER,
NULL AS BEBERI,
NULL AS CR_OBJTY,
NULL AS PPSID,
NULL AS PPSIDI,
NULL AS GSBER,
NULL AS GSBERI,
NULL AS KOKRS,
NULL AS KOKRSI,
NULL AS KOSTL,
NULL AS KOSTLI,
NULL AS PROID,
NULL AS PROIDI,
NULL AS BUKRS,
NULL AS BUKRSI,
NULL AS ANLNR,
NULL AS ANLNRI,
NULL AS ANLUN,
NULL AS ANLUNI,
NULL AS DAUFN,
NULL AS DAUFNI,
NULL AS AUFNR,
NULL AS AUFNRI,
NULL AS TPLNRI,
NULL AS VKORG,
NULL AS VKORGI,
NULL AS VTWEG,
NULL AS VTWEGI,
NULL AS SPART,
NULL AS SPARTI,
NULL AS ADRNR,
NULL AS ADRNRI,
NULL AS OWNER,
NULL AS VKBUR,
NULL AS VKGRP,
NULL AS GLDELFLAG,
NULL AS GLCHANGETIME,
NULL AS GLSOURCESYSTEM,
'N' AS PSA_DELETE_IND,
'1900-01-01'::TIMESTAMP AS PSA_LOAD_DTS,
NULL AS PSA_RECORD_SOURCE,
'1900-01-01T00:00:00'::TIMESTAMP_NTZ AS LOAD_DTS,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC,
DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC,
MD5_BINARY('') AS HASHDIFF
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
