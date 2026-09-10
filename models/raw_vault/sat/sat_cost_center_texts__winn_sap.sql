---- SRC LAYER ----
WITH
SRC_SWINN          as ( SELECT * FROM {{ ref('v_psa_stg_cost_center_texts__winn_sap') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_SWINN          as ( SELECT * FROM STAGING.V_PSA_STG_COST_CENTER_TEXTS__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_SWINN as (
    SELECT
        COST_CENTER_TEXTS_HK
      , LANGUAGE_KEY_HK
      , CONTROLLING_AREA_HK
      , COST_CENTER_HK
      , VALID_TO_DATE_HK
      , MANDT
      , SPRAS
      , KOKRS
      , KOSTL
      , DATBI
      , GLREQUEST
      , KTEXT
      , LTEXT
      , MCTXT
      , GLDELFLAG
      , GLCHANGETIME
      , GLCHANGETIME_DTTM
      , GLSOURCESYSTEM
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM SRC_SWINN
)
---- RENAME LAYER ----

, RENAME_SWINN as (
    SELECT
        COST_CENTER_TEXTS_HK
      , LANGUAGE_KEY_HK
      , CONTROLLING_AREA_HK
      , COST_CENTER_HK
      , VALID_TO_DATE_HK
      , MANDT
      , SPRAS
      , KOKRS
      , KOSTL
      , DATBI
      , GLREQUEST
      , KTEXT
      , LTEXT
      , MCTXT
      , GLDELFLAG
      , GLCHANGETIME
      , GLCHANGETIME_DTTM
      , GLSOURCESYSTEM
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM LOGIC_SWINN
)
---- FILTER LAYER ----

, FILTER_SWINN as (
    SELECT *
    FROM RENAME_SWINN
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_SWINN
)

---- FINAL LAYER ----
SELECT
          COST_CENTER_TEXTS_HK
        , LANGUAGE_KEY_HK
        , CONTROLLING_AREA_HK
        , COST_CENTER_HK
        , VALID_TO_DATE_HK
        , MANDT
        , SPRAS
        , KOKRS
        , KOSTL
        , DATBI
        , GLREQUEST
        , KTEXT
        , LTEXT
        , MCTXT
        , GLDELFLAG
        , GLCHANGETIME
        , GLCHANGETIME_DTTM
        , GLSOURCESYSTEM
        , PSA_DELETE_IND
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , HASHDIFF
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.COST_CENTER_TEXTS_HK= JOIN_RESULT.COST_CENTER_TEXTS_HK
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %} 
{% if not is_incremental() %}
/*the following qualify is to restrict multiple loads of touched records during the initial build. Ex: multiple row per hk, hashdiff */
qualify 1= row_number()over(partition by COST_CENTER_TEXTS_HK, HASHDIFF order by LOAD_DTS)
union all
    SELECT        
    MD5_BINARY(GR.VALUE) AS COST_CENTER_TEXTS_HK
   , MD5_BINARY(GR.VALUE) AS LANGUAGE_KEY_HK
   , MD5_BINARY(GR.VALUE) AS  CONTROLLING_AREA_HK
   , MD5_BINARY(GR.VALUE) AS  COST_CENTER_HK
   , MD5_BINARY(GR.VALUE) AS  VALID_TO_DATE_HK
 , CAST(NULL AS STRING) AS MANDT
, CAST(NULL AS STRING) AS SPRAS
, CAST(NULL AS STRING) AS KOKRS
, CAST(NULL AS STRING) AS KOSTL
, CAST(NULL AS STRING) AS DATBI
, CAST(NULL AS NUMBER) AS GLREQUEST
, CAST(NULL AS STRING) AS KTEXT
, CAST(NULL AS STRING) AS LTEXT
, CAST(NULL AS STRING) AS MCTXT
, CAST(NULL AS STRING) AS GLDELFLAG
, CAST(NULL AS NUMBER) AS GLCHANGETIME
, CAST(NULL AS TIMESTAMP) AS GLCHANGETIME_DTTM
, CAST(NULL AS STRING) AS GLSOURCESYSTEM
, CAST(NULL AS STRING) AS PSA_DELETE_IND
, CONVERT_TIMEZONE('UTC','1900-01-01')  as  LOAD_DTS
,'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
, DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS BKCC
, ''::BINARY as HASHDIFF FROM
        TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}