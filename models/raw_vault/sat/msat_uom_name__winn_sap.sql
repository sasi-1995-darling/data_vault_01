---- SRC LAYER ----
WITH
SRC_uom            as ( SELECT * FROM {{ ref('v_psa_stg_uom_name__winn_sap') }} as SRC 
                        {% if is_incremental() %}
                        WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}}){% endif %} )

/*
SRC_uom            as ( SELECT * FROM STAGING.V_PSA_STG_UOM_NAME__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_uom as (
    SELECT
        UOM_HK
      , MANDT
      , SPRAS
      , MSEHI
      , GLREQUEST
      , GLSOURCESYSTEM
      , MSEH3
      , MSEH6
      , MSEHT
      , MSEHL
      , GLDELFLAG
      , GLCHANGETIME
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , HASHDIFF
      , REC_SRC
    FROM SRC_uom
)
---- RENAME LAYER ----

, RENAME_uom as (
    SELECT
        UOM_HK
      , MANDT
      , SPRAS
      , MSEHI
      , GLREQUEST
      , GLSOURCESYSTEM
      , MSEH3
      , MSEH6
      , MSEHT
      , MSEHL
      , GLDELFLAG
      , GLCHANGETIME
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , HASHDIFF
      , REC_SRC
    FROM LOGIC_uom
)
---- FILTER LAYER ----

, FILTER_uom as (
    SELECT *
    FROM RENAME_uom
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_uom
)

---- FINAL LAYER ----
SELECT
          UOM_HK
        , MANDT
        , SPRAS
        , MSEHI
        , GLREQUEST
        , GLSOURCESYSTEM
        , MSEH3
        , MSEH6
        , MSEHT
        , MSEHL
        , GLDELFLAG
        , GLCHANGETIME
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
    WHERE existing.UOM_HK = JOIN_RESULT.UOM_HK
    AND existing.SPRAS = JOIN_RESULT.SPRAS 
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %}
{% if not is_incremental() %}

/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per HK and hashdiff. */
qualify 1 = row_number() over (partition by UOM_HK, SPRAS, HASHDIFF order by PSA_LOAD_DTS)

union all
SELECT 
MD5_BINARY(GR.VALUE) AS UOM_HK,
NULL AS MANDT,
NULL AS SPRAS,
GR.VALUE::text AS MSEHI,
NULL AS GLREQUEST,
NULL AS GLSOURCESYSTEM,
NULL AS MSEH3,
NULL AS MSEH6,
NULL AS MSEHT,
NULL AS MSEHL,
NULL AS GLDELFLAG,
NULL AS GLCHANGETIME,
'1900-01-01'::TIMESTAMP AS PSA_LOAD_DTS,
NULL AS PSA_RECORD_SOURCE,
'N' AS PSA_DELETE_IND,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
''::BINARY AS HASHDIFF,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
