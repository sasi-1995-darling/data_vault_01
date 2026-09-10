---- SRC LAYER ----
WITH
SRC_TVAGT          as ( SELECT * FROM {{ ref('v_psa_stg_sales_rejection_reason__winn_sap') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_TVAGT          as ( SELECT * FROM STAGING.v_psa_stg_sales_rejection_reason__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_TVAGT as (
    SELECT
        SALES_REJECTION_REASON_BK
      , MANDT                                                        as                                             CLIENT
      , SPRAS                                                        as                                       LANGUAGE_KEY
      , ABGRU                                                        as                        SALES_REJECTION_REASON_CODE
      , GLREQUEST
      , Z_BEZEI                                                      as                                              BEZEI
      , BEZEI                                                        as                 SALES_REJECTION_REASON_DESCRIPTION
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , HASHDIFF
    FROM SRC_TVAGT
)
---- RENAME LAYER ----

, RENAME_TVAGT as (
    SELECT
        SALES_REJECTION_REASON_BK
      , CLIENT
      , LANGUAGE_KEY
      , SALES_REJECTION_REASON_CODE
      , GLREQUEST
      , BEZEI
      , SALES_REJECTION_REASON_DESCRIPTION
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , HASHDIFF
    FROM LOGIC_TVAGT
)
---- FILTER LAYER ----

, FILTER_TVAGT as (
    SELECT *
    FROM RENAME_TVAGT
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_TVAGT
)

---- FINAL LAYER ----
SELECT
          SALES_REJECTION_REASON_BK
        , CLIENT
        , LANGUAGE_KEY
        , SALES_REJECTION_REASON_CODE
        , GLREQUEST
        , BEZEI
        , SALES_REJECTION_REASON_DESCRIPTION
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
    WHERE existing.SALES_REJECTION_REASON_BK = JOIN_RESULT.SALES_REJECTION_REASON_BK
    AND existing.LANGUAGE_KEY = JOIN_RESULT.LANGUAGE_KEY
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %}
{% if not is_incremental() %}

/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per HK and hashdiff. */
qualify 1 = row_number() over (partition by SALES_REJECTION_REASON_BK, LANGUAGE_KEY, HASHDIFF order by PSA_LOAD_DTS)

union all
SELECT 
GR.VALUE::text AS SALES_REJECTION_REASON_BK,
NULL AS CLIENT,
GR.VALUE::text AS LANGUAGE_KEY,
NULL AS SALES_REJECTION_REASON_CODE,
NULL AS GLREQUEST,
NULL AS BEZEI,
NULL AS SALES_REJECTION_REASON_DESCRIPTION,
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
