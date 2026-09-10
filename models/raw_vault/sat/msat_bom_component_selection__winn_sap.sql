---- SRC LAYER ----
WITH
SRC_bom            as ( SELECT * FROM {{ ref('v_psa_stg_bom_component_selection__winn_sap') }} as SRC 
                        {% if is_incremental() %}
                        WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}}){% endif %} )

/*
SRC_bom            as ( SELECT * FROM STAGING.V_PSA_STG_BOM_COMPONENT_SELECTION__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_bom as (
    SELECT
        BOM_HK
      , MANDT
      , STLTY
      , STLNR
      , STLAL
      , STLKN
      , STASZ
      , GLREQUEST
      , DATUV
      , TECHV
      , AENNR
      , LKENZ
      , ANDAT
      , ANNAM
      , AEDAT
      , AENAM
      , DVDAT
      , DVNAM
      , AEHLP
      , STVKN
      , IDPOS
      , IDVAR
      , LPSRT
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , LOAD_DTS
      , HASHDIFF
      , REC_SRC
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
      , STLKN
      , STASZ
      , GLREQUEST
      , DATUV
      , TECHV
      , AENNR
      , LKENZ
      , ANDAT
      , ANNAM
      , AEDAT
      , AENAM
      , DVDAT
      , DVNAM
      , AEHLP
      , STVKN
      , IDPOS
      , IDVAR
      , LPSRT
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , LOAD_DTS
      , HASHDIFF
      , REC_SRC
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
        , STLKN
        , STASZ
        , GLREQUEST
        , DATUV
        , TECHV
        , AENNR
        , LKENZ
        , ANDAT
        , ANNAM
        , AEDAT
        , AENAM
        , DVDAT
        , DVNAM
        , AEHLP
        , STVKN
        , IDPOS
        , IDVAR
        , LPSRT
        , GLDELFLAG
        , GLCHANGETIME
        , GLSOURCESYSTEM
        , PSA_DELETE_IND
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , LOAD_DTS
        , HASHDIFF
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.BOM_HK = JOIN_RESULT.BOM_HK  
    AND existing.STLTY = JOIN_RESULT.STLTY    
    AND existing.STLAL = JOIN_RESULT.STLAL
    AND existing.STLKN = JOIN_RESULT.STLKN
    AND existing.STASZ = JOIN_RESULT.STASZ
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
GR.VALUE::text AS STLKN,
GR.VALUE::text AS STASZ,
NULL AS GLREQUEST,
NULL AS DATUV,
NULL AS TECHV,
NULL AS AENNR,
NULL AS LKENZ,
NULL AS ANDAT,
NULL AS ANNAM,
NULL AS AEDAT,
NULL AS AENAM,
NULL AS DVDAT,
NULL AS DVNAM,
NULL AS AEHLP,
NULL AS STVKN,
NULL AS IDPOS,
NULL AS IDVAR,
NULL AS LPSRT,
NULL AS GLDELFLAG,
NULL AS GLCHANGETIME,
NULL AS GLSOURCESYSTEM,
'N' AS PSA_DELETE_IND,
'1900-01-01'::TIMESTAMP AS PSA_LOAD_DTS,
NULL AS PSA_RECORD_SOURCE,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
''::BINARY AS HASHDIFF,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
