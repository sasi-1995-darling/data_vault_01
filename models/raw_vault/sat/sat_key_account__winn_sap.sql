---- SRC LAYER ----
WITH
SRC_s              as ( SELECT KEY_ACCOUNT_HK, MANDT, SPRAS, KVGR1, GLREQUEST, BEZEI, GLDELFLAG, GLCHANGETIME, GLSOURCESYSTEM, PSA_LOAD_DTS, PSA_RECORD_SOURCE, PSA_DELETE_IND, LOAD_DTS, HASHDIFF, REC_SRC FROM {{ ref('v_psa_stg_key_account__winn_sap') }} as SRC 
                        {% if is_incremental() %}
                        WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}}){% endif %} )

/*
SRC_s              as ( SELECT * FROM STAGING.V_PSA_STG_KEY_ACCOUNT__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_s as (
    SELECT
        KEY_ACCOUNT_HK
      , MANDT
      , SPRAS
      , KVGR1
      , GLREQUEST
      , BEZEI
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , HASHDIFF
      , REC_SRC
    FROM SRC_s
)
---- RENAME LAYER ----

, RENAME_s as (
    SELECT
        KEY_ACCOUNT_HK
      , MANDT
      , SPRAS
      , KVGR1
      , GLREQUEST
      , BEZEI
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , HASHDIFF
      , REC_SRC
    FROM LOGIC_s
)
---- FILTER LAYER ----

, FILTER_s as (
    SELECT *
    FROM RENAME_s
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_s
)

---- FINAL LAYER ----
SELECT
          KEY_ACCOUNT_HK
        , MANDT
        , SPRAS
        , KVGR1
        , GLREQUEST
        , BEZEI
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
    WHERE existing.KEY_ACCOUNT_HK = JOIN_RESULT.KEY_ACCOUNT_HK  AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %}
{% if not is_incremental() %}

/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per HK and hashdiff. */
qualify 1 = row_number() over (partition by KEY_ACCOUNT_HK, HASHDIFF order by PSA_LOAD_DTS)

union all
SELECT 
MD5_BINARY(GR.VALUE) AS KEY_ACCOUNT_HK,
NULL AS MANDT,
GR.VALUE::text AS SPRAS,
GR.VALUE::text AS KVGR1,
NULL AS GLREQUEST,
NULL AS BEZEI,
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
