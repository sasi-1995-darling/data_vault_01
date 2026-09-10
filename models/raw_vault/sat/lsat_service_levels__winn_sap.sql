---- SRC LAYER ----
WITH
SRC_ZSERVLEVEL     as ( SELECT * FROM {{ ref('v_psa_stg_service_levels__winn_sap') }} as SRC 
                        {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %} )

/*
SRC_ZSERVLEVEL     as ( SELECT * FROM STAGING.v_psa_stg_service_levels__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_ZSERVLEVEL as (
    SELECT
        LNK_SERVICE_LEVELS_HK
      , MANDT
      , ERDAT
      , ERDAT_DT
      , VBELN
      , POSNR
      , KUNNR
      , VKORG
      , VTWEG
      , SPART
      , ZSERVCODE
      , GLREQUEST
      , ZSERVTYPE
      , WERKS
      , LGORT
      , MATNR
      , NETPR
      , WADAT
      , WADAT_DT
      , WADAT_IST
      , WADAT_IST_DT
      , KWMENG
      , LFIMG
      , NETWR
      , SNETWR
      , ZLINEFILL
      , ZONTIME
      , ZRELEASED
      , WAERK
      , PSTYV
      , MEINS
      , PERFECTORDER
      , ORDEVALDT
      , ORDEVALDT_DT
      , MULTONTIME
      , VSTEL
      , ONT_PIKMG
      , KODAT_IST
      , KODAT_IST_DT
      , PIKMG
      , PNETWR
      , ZPLINEFILL
      , ZPONTIME
      , ZFILLDIFF
      , ZONTIMEDIFF
      , ZZENDSHPDTE
      , ZZGRACE
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , HASHDIFF
    FROM SRC_ZSERVLEVEL
)
---- RENAME LAYER ----

, RENAME_ZSERVLEVEL as (
    SELECT
        LNK_SERVICE_LEVELS_HK
      , MANDT
      , ERDAT
      , ERDAT_DT
      , VBELN
      , POSNR
      , KUNNR
      , VKORG
      , VTWEG
      , SPART
      , ZSERVCODE
      , GLREQUEST
      , ZSERVTYPE
      , WERKS
      , LGORT
      , MATNR
      , NETPR
      , WADAT
      , WADAT_DT
      , WADAT_IST
      , WADAT_IST_DT
      , KWMENG
      , LFIMG
      , NETWR
      , SNETWR
      , ZLINEFILL
      , ZONTIME
      , ZRELEASED
      , WAERK
      , PSTYV
      , MEINS
      , PERFECTORDER
      , ORDEVALDT
      , ORDEVALDT_DT
      , MULTONTIME
      , VSTEL
      , ONT_PIKMG
      , KODAT_IST
      , KODAT_IST_DT
      , PIKMG
      , PNETWR
      , ZPLINEFILL
      , ZPONTIME
      , ZFILLDIFF
      , ZONTIMEDIFF
      , ZZENDSHPDTE
      , ZZGRACE
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , HASHDIFF
    FROM LOGIC_ZSERVLEVEL
)
---- FILTER LAYER ----

, FILTER_ZSERVLEVEL as (
    SELECT *
    FROM RENAME_ZSERVLEVEL
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_ZSERVLEVEL
)

---- FINAL LAYER ----
SELECT
          LNK_SERVICE_LEVELS_HK
        , MANDT
        , ERDAT
        , ERDAT_DT
        , VBELN
        , POSNR
        , KUNNR
        , VKORG
        , VTWEG
        , SPART
        , ZSERVCODE
        , GLREQUEST
        , ZSERVTYPE
        , WERKS
        , LGORT
        , MATNR
        , NETPR
        , WADAT
        , WADAT_DT
        , WADAT_IST
        , WADAT_IST_DT
        , KWMENG
        , LFIMG
        , NETWR
        , SNETWR
        , ZLINEFILL
        , ZONTIME
        , ZRELEASED
        , WAERK
        , PSTYV
        , MEINS
        , PERFECTORDER
        , ORDEVALDT
        , ORDEVALDT_DT
        , MULTONTIME
        , VSTEL
        , ONT_PIKMG
        , KODAT_IST
        , KODAT_IST_DT
        , PIKMG
        , PNETWR
        , ZPLINEFILL
        , ZPONTIME
        , ZFILLDIFF
        , ZONTIMEDIFF
        , ZZENDSHPDTE
        , ZZGRACE
        , GLDELFLAG
        , GLCHANGETIME
        , GLSOURCESYSTEM
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , REC_SRC
        , HASHDIFF
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.LNK_SERVICE_LEVELS_HK = JOIN_RESULT.LNK_SERVICE_LEVELS_HK
	AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF	
)
{% endif %}
{% if not is_incremental() %}

/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per HK and hashdiff. */
qualify 1 = row_number() over (partition by LNK_SERVICE_LEVELS_HK, HASHDIFF order by PSA_LOAD_DTS)

union all
SELECT 
MD5_BINARY(GR.VALUE) AS LNK_SERVICE_LEVELS_HK,
NULL AS MANDT,
NULL AS ERDAT,
NULL AS ERDAT_DT,
GR.VALUE::text AS VBELN,
GR.VALUE::text AS POSNR,
GR.VALUE::text AS KUNNR,
GR.VALUE::text AS VKORG,
GR.VALUE::text AS VTWEG,
GR.VALUE::text AS SPART,
GR.VALUE::text AS ZSERVCODE,
NULL AS GLREQUEST,
NULL AS ZSERVTYPE,
GR.VALUE::text AS WERKS,
GR.VALUE::text AS LGORT,
GR.VALUE::text AS MATNR,
NULL AS NETPR,
NULL AS WADAT,
NULL AS WADAT_DT,
NULL AS WADAT_IST,
NULL AS WADAT_IST_DT,
NULL AS KWMENG,
NULL AS LFIMG,
NULL AS NETWR,
NULL AS SNETWR,
NULL AS ZLINEFILL,
NULL AS ZONTIME,
NULL AS ZRELEASED,
NULL AS WAERK,
NULL AS PSTYV,
NULL AS MEINS,
NULL AS PERFECTORDER,
NULL AS ORDEVALDT,
NULL AS ORDEVALDT_DT,
NULL AS MULTONTIME,
NULL AS VSTEL,
NULL AS ONT_PIKMG,
NULL AS KODAT_IST,
NULL AS KODAT_IST_DT,
NULL AS PIKMG,
NULL AS PNETWR,
NULL AS ZPLINEFILL,
NULL AS ZPONTIME,
NULL AS ZFILLDIFF,
NULL AS ZONTIMEDIFF,
NULL AS ZZENDSHPDTE,
NULL AS ZZGRACE,
NULL AS GLDELFLAG,
NULL AS GLCHANGETIME,
NULL AS GLSOURCESYSTEM,
'1900-01-01'::TIMESTAMP AS PSA_LOAD_DTS,
NULL AS PSA_RECORD_SOURCE,
'N' AS PSA_DELETE_IND,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC,
''::BINARY AS HASHDIFF
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
