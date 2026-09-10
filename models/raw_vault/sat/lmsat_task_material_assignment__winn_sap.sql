---- SRC LAYER ----
WITH
SRC_a              as ( SELECT AEDAT, AENAM, AENNR, ANDAT, ANNAM, DATUV, GLCHANGETIME, GLDELFLAG, GLREQUEST, GLSOURCESYSTEM, HASHDIFF, KUNR, LIFNR, LNK_PLANT_TASKLIST_ITEM_ASSIGNMENT_HK, LOAD_DTS, LOEKZ, MANDT, MATNR, MS_OBJECT, MS_OBJTYPE, PARKZ, PLNAL, PLNNR, PLNTY, POSNR, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, PSPNR, REC_SRC, SUCHFELD, TECHV, VBELN, WERKS, ZAEHL, ZKRIZ FROM {{ ref('v_psa_stg_tasklist_assignment__winn_sap') }} as SRC 
                        {% if is_incremental() %}
                        WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}}){% endif %} )

/*
SRC_a              as ( SELECT * FROM STAGING.V_PSA_STG_TASKLIST_ASSIGNMENT__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_a as (
    SELECT
        LNK_PLANT_TASKLIST_ITEM_ASSIGNMENT_HK
      , MANDT
      , MATNR
      , WERKS
      , PLNTY
      , PLNNR
      , PLNAL
      , ZKRIZ
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
      , LIFNR
      , KUNR
      , SUCHFELD
      , VBELN
      , POSNR
      , PSPNR
      , MS_OBJECT
      , MS_OBJTYPE
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
        LNK_PLANT_TASKLIST_ITEM_ASSIGNMENT_HK
      , MANDT
      , MATNR
      , WERKS
      , PLNTY
      , PLNNR
      , PLNAL
      , ZKRIZ
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
      , LIFNR
      , KUNR
      , SUCHFELD
      , VBELN
      , POSNR
      , PSPNR
      , MS_OBJECT
      , MS_OBJTYPE
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
          LNK_PLANT_TASKLIST_ITEM_ASSIGNMENT_HK
        , MANDT
        , MATNR
        , WERKS
        , PLNTY
        , PLNNR
        , PLNAL
        , ZKRIZ
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
        , LIFNR
        , KUNR
        , SUCHFELD
        , VBELN
        , POSNR
        , PSPNR
        , MS_OBJECT
        , MS_OBJTYPE
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
    WHERE existing.LNK_PLANT_TASKLIST_ITEM_ASSIGNMENT_HK = JOIN_RESULT.LNK_PLANT_TASKLIST_ITEM_ASSIGNMENT_HK 
AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %}

{% if not is_incremental() %}

/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per HK and hashdiff. */
qualify 1 = row_number() over (partition by LNK_PLANT_TASKLIST_ITEM_ASSIGNMENT_HK, HASHDIFF order by PSA_LOAD_DTS)

union all
SELECT
MD5_BINARY(GR.VALUE) AS LNK_PLANT_TASKLIST_ITEM_ASSIGNMENT_HK,
NULL AS MANDT,
VALUE::TEXT AS MATNR,
VALUE::TEXT AS WERKS,
VALUE::TEXT AS PLNTY,
VALUE::TEXT AS PLNNR,
VALUE::TEXT AS PLNAL,
VALUE::TEXT AS ZKRIZ,
VALUE::TEXT AS ZAEHL,
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
NULL AS LIFNR,
NULL AS KUNR,
NULL AS SUCHFELD,
NULL AS VBELN,
NULL AS POSNR,
NULL AS PSPNR,
NULL AS MS_OBJECT,
NULL AS MS_OBJTYPE,
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