---- SRC LAYER ----
WITH
SRC_bom            as ( SELECT * FROM {{ ref('v_psa_stg_bom_header__winn_sap') }} as SRC 
                        {% if is_incremental() %}
                        WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}}){% endif %} )

/*
SRC_bom            as ( SELECT * FROM STAGING.V_PSA_STG_BOM_HEADER__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_bom as (
    SELECT
        BOM_HK
      , MANDT
      , STLTY
      , STLNR
      , STLAL
      , STKOZ
      , GLREQUEST
      , DATUV
      , TECHV
      , AENNR
      , LKENZ
      , LOEKZ
      , VGKZL
      , ANDAT
      , ANNAM
      , AEDAT
      , AENAM
      , BMEIN
      , BMENG
      , CADKZ
      , LABOR
      , LTXSP
      , STKTX
      , STLST
      , WRKAN
      , DVDAT
      , DVNAM
      , AEHLP
      , ALEKZ
      , GUIDX
      , VALID_TO
      , VALID_TO_RKEY
      , ECN_TO
      , ECN_TO_RKEY
      , ZZSCALE_COUNT
      , ZZWGT_TOLERANCE
      , ZZLGHT_CUR_SET
      , ZZVALVE_TESTER
      , ZZSPOUT_TESTER
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , HASHDIFF
      , REC_SRC
      , BKCC
    FROM SRC_bom
)
---- RENAME LAYER ----

, RENAME_bom as (
    SELECT
        BOM_HK
      , MANDT
      , STLTY
      , STLNR
      , STLAL
      , STKOZ
      , GLREQUEST
      , DATUV
      , TECHV
      , AENNR
      , LKENZ
      , LOEKZ
      , VGKZL
      , ANDAT
      , ANNAM
      , AEDAT
      , AENAM
      , BMEIN
      , BMENG
      , CADKZ
      , LABOR
      , LTXSP
      , STKTX
      , STLST
      , WRKAN
      , DVDAT
      , DVNAM
      , AEHLP
      , ALEKZ
      , GUIDX
      , VALID_TO
      , VALID_TO_RKEY
      , ECN_TO
      , ECN_TO_RKEY
      , ZZSCALE_COUNT
      , ZZWGT_TOLERANCE
      , ZZLGHT_CUR_SET
      , ZZVALVE_TESTER
      , ZZSPOUT_TESTER
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , HASHDIFF
      , REC_SRC
      , BKCC
    FROM LOGIC_bom
)
---- FILTER LAYER ----

, FILTER_bom as (
    SELECT *
    FROM RENAME_bom
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_bom
)

---- FINAL LAYER ----
SELECT
          BOM_HK
        , MANDT
        , STLTY
        , STLNR
        , STLAL
        , STKOZ
        , GLREQUEST
        , DATUV
        , TECHV
        , AENNR
        , LKENZ
        , LOEKZ
        , VGKZL
        , ANDAT
        , ANNAM
        , AEDAT
        , AENAM
        , BMEIN
        , BMENG
        , CADKZ
        , LABOR
        , LTXSP
        , STKTX
        , STLST
        , WRKAN
        , DVDAT
        , DVNAM
        , AEHLP
        , ALEKZ
        , GUIDX
        , VALID_TO
        , VALID_TO_RKEY
        , ECN_TO
        , ECN_TO_RKEY
        , ZZSCALE_COUNT
        , ZZWGT_TOLERANCE
        , ZZLGHT_CUR_SET
        , ZZVALVE_TESTER
        , ZZSPOUT_TESTER
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
    WHERE existing.BOM_HK = JOIN_RESULT.BOM_HK  
   AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %}
{% if not is_incremental() %}

/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per HK and hashdiff. */
qualify 1 = row_number() over (partition by BOM_HK, HASHDIFF order by PSA_LOAD_DTS)

union all
SELECT 
MD5_BINARY(GR.VALUE) AS BOM_HK,
NULL AS MANDT,
GR.VALUE::text AS STLTY,
GR.VALUE::text AS STLNR,
GR.VALUE::text AS STLAL,
GR.VALUE::text AS STKOZ,
NULL AS GLREQUEST,
NULL AS DATUV,
NULL AS TECHV,
NULL AS AENNR,
NULL AS LKENZ,
NULL AS LOEKZ,
NULL AS VGKZL,
NULL AS ANDAT,
NULL AS ANNAM,
NULL AS AEDAT,
NULL AS AENAM,
NULL AS BMEIN,
NULL AS BMENG,
NULL AS CADKZ,
NULL AS LABOR,
NULL AS LTXSP,
NULL AS STKTX,
NULL AS STLST,
NULL AS WRKAN,
NULL AS DVDAT,
NULL AS DVNAM,
NULL AS AEHLP,
NULL AS ALEKZ,
NULL AS GUIDX,
NULL AS VALID_TO,
NULL AS VALID_TO_RKEY,
NULL AS ECN_TO,
NULL AS ECN_TO_RKEY,
NULL AS ZZSCALE_COUNT,
NULL AS ZZWGT_TOLERANCE,
NULL AS ZZLGHT_CUR_SET,
NULL AS ZZVALVE_TESTER,
NULL AS ZZSPOUT_TESTER,
NULL AS GLDELFLAG,
NULL AS GLCHANGETIME,
NULL AS GLSOURCESYSTEM,
NULL AS PSA_LOAD_DTS,
NULL AS PSA_RECORD_SOURCE,
NULL AS PSA_DELETE_IND,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
''::BINARY AS HASHDIFF,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
