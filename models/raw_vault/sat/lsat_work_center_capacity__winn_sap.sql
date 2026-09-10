---- SRC LAYER ----
WITH
SRC_wct            as ( SELECT * FROM {{ ref('v_psa_stg_work_center_capacity_allocation__winn_sap') }} as SRC 
                        {% if is_incremental() %}
                        WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}}){% endif %} )

/*
SRC_wct            as ( SELECT * FROM STAGING.V_PSA_STG_WORK_CENTER_CAPACITY_ALLOCATION__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_wct as (
    SELECT
        LNK_WORK_CENTER_CAPACITY_HK
      , ARBPL
      , MANDT
      , OBJTY
      , OBJID
      , CANUM
      , GLREQUEST
      , BEGDA
      , ENDDA
      , AEDAT_KAPA
      , AENAM_KAPA
      , KAPID
      , FORK1
      , FORK2
      , FORK3
      , FORKN
      , PROZT
      , VERT1
      , VERT2
      , VERT3
      , VERTN
      , CAROL
      , ISTBED_KZ
      , VGWT1
      , VGWT2
      , VGWT3
      , VGWTN
      , CAP_BACKFLUSH_SU
      , CAP_BACKFLUSH_PR
      , CAP_BACKFLUSH_TD
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
        LNK_WORK_CENTER_CAPACITY_HK
      , ARBPL
      , MANDT
      , OBJTY
      , OBJID
      , CANUM
      , GLREQUEST
      , BEGDA
      , ENDDA
      , AEDAT_KAPA
      , AENAM_KAPA
      , KAPID
      , FORK1
      , FORK2
      , FORK3
      , FORKN
      , PROZT
      , VERT1
      , VERT2
      , VERT3
      , VERTN
      , CAROL
      , ISTBED_KZ
      , VGWT1
      , VGWT2
      , VGWT3
      , VGWTN
      , CAP_BACKFLUSH_SU
      , CAP_BACKFLUSH_PR
      , CAP_BACKFLUSH_TD
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
          LNK_WORK_CENTER_CAPACITY_HK
        , ARBPL
        , MANDT
        , OBJTY
        , OBJID
        , CANUM
        , GLREQUEST
        , BEGDA
        , ENDDA
        , AEDAT_KAPA
        , AENAM_KAPA
        , KAPID
        , FORK1
        , FORK2
        , FORK3
        , FORKN
        , PROZT
        , VERT1
        , VERT2
        , VERT3
        , VERTN
        , CAROL
        , ISTBED_KZ
        , VGWT1
        , VGWT2
        , VGWT3
        , VGWTN
        , CAP_BACKFLUSH_SU
        , CAP_BACKFLUSH_PR
        , CAP_BACKFLUSH_TD
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
    WHERE existing.LNK_WORK_CENTER_CAPACITY_HK = JOIN_RESULT.LNK_WORK_CENTER_CAPACITY_HK
    AND existing.KAPID = JOIN_RESULT.KAPID
    AND existing.OBJTY = JOIN_RESULT.OBJTY
    AND existing.OBJID = JOIN_RESULT.OBJID
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %}
{% if not is_incremental() %}

/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per HK and hashdiff. */
qualify 1 = row_number() over (partition by LNK_WORK_CENTER_CAPACITY_HK, KAPID, OBJTY, OBJID, HASHDIFF order by PSA_LOAD_DTS)

union all
SELECT 
MD5_BINARY(GR.VALUE) AS LNK_WORK_CENTER_CAPACITY_HK,
GR.VALUE::text AS ARBPL,
NULL AS MANDT,
GR.VALUE::text AS OBJTY,
GR.VALUE::text AS OBJID,
NULL AS CANUM,
NULL AS GLREQUEST,
NULL AS BEGDA,
NULL AS ENDDA,
NULL AS AEDAT_KAPA,
NULL AS AENAM_KAPA,
GR.VALUE::text AS KAPID,
NULL AS FORK1,
NULL AS FORK2,
NULL AS FORK3,
NULL AS FORKN,
NULL AS PROZT,
NULL AS VERT1,
NULL AS VERT2,
NULL AS VERT3,
NULL AS VERTN,
NULL AS CAROL,
NULL AS ISTBED_KZ,
NULL AS VGWT1,
NULL AS VGWT2,
NULL AS VGWT3,
NULL AS VGWTN,
NULL AS CAP_BACKFLUSH_SU,
NULL AS CAP_BACKFLUSH_PR,
NULL AS CAP_BACKFLUSH_TD,
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