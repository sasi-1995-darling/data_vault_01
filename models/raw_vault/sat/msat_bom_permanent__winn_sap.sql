---- SRC LAYER ----
WITH
SRC_bom            as ( SELECT * FROM {{ ref('v_psa_stg_bom_permanent__winn_sap') }} as SRC 
                        {% if is_incremental() %}
                        WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}}){% endif %} )

/*
SRC_bom            as ( SELECT * FROM STAGING.V_PSA_STG_BOM_PERMANENT__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_bom as (
    SELECT
        BOM_HK
      , MANDT
      , STLTY
      , STLNR
      , GLREQUEST
      , STLAN
      , EXSTL
      , ALTST
      , VARST
      , KBAUS
      , LTXSP
      , STLBE
      , ZTEXT
      , WRKAN
      , HISDT
      , HISSR
      , HISTK
      , STUEZ
      , MAXKN
      , KZPLN
      , AENRL
      , CLSMX
      , STLDT
      , STLTM
      , MAXKAN
      , TSTMP
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
      , GLREQUEST
      , STLAN
      , EXSTL
      , ALTST
      , VARST
      , KBAUS
      , LTXSP
      , STLBE
      , ZTEXT
      , WRKAN
      , HISDT
      , HISSR
      , HISTK
      , STUEZ
      , MAXKN
      , KZPLN
      , AENRL
      , CLSMX
      , STLDT
      , STLTM
      , MAXKAN
      , TSTMP
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
        , GLREQUEST
        , STLAN
        , EXSTL
        , ALTST
        , VARST
        , KBAUS
        , LTXSP
        , STLBE
        , ZTEXT
        , WRKAN
        , HISDT
        , HISSR
        , HISTK
        , STUEZ
        , MAXKN
        , KZPLN
        , AENRL
        , CLSMX
        , STLDT
        , STLTM
        , MAXKAN
        , TSTMP
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
NULL AS GLREQUEST,
NULL AS STLAN,
NULL AS EXSTL,
NULL AS ALTST,
NULL AS VARST,
NULL AS KBAUS,
NULL AS LTXSP,
NULL AS STLBE,
NULL AS ZTEXT,
NULL AS WRKAN,
NULL AS HISDT,
NULL AS HISSR,
NULL AS HISTK,
NULL AS STUEZ,
NULL AS MAXKN,
NULL AS KZPLN,
NULL AS AENRL,
NULL AS CLSMX,
NULL AS STLDT,
NULL AS STLTM,
NULL AS MAXKAN,
NULL AS TSTMP,
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
