---- SRC LAYER ----
WITH
SRC_wct            as ( SELECT * FROM {{ ref('v_psa_stg_work_center__winn_sap') }} as SRC 
                        {% if is_incremental() %}
                        WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}}){% endif %} )

/*
SRC_wct            as ( SELECT * FROM STAGING.V_PSA_STG_WORK_CENTER__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_wct as (
    SELECT
        WORK_CENTER_HK
      , ARBPL
      , MANDT
      , OBJTY
      , OBJID
      , SPRAS
      , GLREQUEST
      , AEDAT_TEXT
      , AENAM_TEXT
      , KTEXT
      , KTEXT_UP
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , LOAD_DTS
      , HASHDIFF
      , REC_SRC
    FROM SRC_wct
)
---- RENAME LAYER ----

, RENAME_wct as (
    SELECT
        WORK_CENTER_HK
      , ARBPL
      , MANDT
      , OBJTY
      , OBJID
      , SPRAS
      , GLREQUEST
      , AEDAT_TEXT
      , AENAM_TEXT
      , KTEXT
      , KTEXT_UP
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , LOAD_DTS
      , HASHDIFF
      , REC_SRC
    FROM LOGIC_wct
)
---- FILTER LAYER ----

, FILTER_wct as (
    SELECT *
    FROM RENAME_wct
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_wct
)

---- FINAL LAYER ----
SELECT
          WORK_CENTER_HK
        , ARBPL
        , MANDT
        , OBJTY
        , OBJID
        , SPRAS
        , GLREQUEST
        , AEDAT_TEXT
        , AENAM_TEXT
        , KTEXT
        , KTEXT_UP
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
    WHERE existing.WORK_CENTER_HK = JOIN_RESULT.WORK_CENTER_HK
    AND existing.OBJTY = JOIN_RESULT.OBJTY
    AND existing.OBJID = JOIN_RESULT.OBJID
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %}
{% if not is_incremental() %}

/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per HK and hashdiff. */
qualify 1 = row_number() over (partition by WORK_CENTER_HK, OBJTY, OBJID, HASHDIFF order by PSA_LOAD_DTS)

union all
SELECT 
MD5_BINARY(GR.VALUE) AS WORK_CENTER_HK,
GR.VALUE::text AS ARBPL,
NULL AS MANDT,
GR.VALUE::text AS OBJTY,
GR.VALUE::text AS OBJID,
NULL AS SPRAS,
NULL AS GLREQUEST,
NULL AS AEDAT_TEXT,
NULL AS AENAM_TEXT,
NULL AS KTEXT,
NULL AS KTEXT_UP,
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