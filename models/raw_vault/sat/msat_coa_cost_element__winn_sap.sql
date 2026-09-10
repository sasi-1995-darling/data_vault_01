---- SRC LAYER ----
WITH
SRC_SWINN          as ( SELECT * FROM {{ ref('v_psa_stg_coa_cost_element__winn_sap') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_SWINN          as ( SELECT * FROM STAGING.V_PSA_STG_COA_COST_ELEMENT__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_SWINN as (
    SELECT
        COA_COST_ELEMENT_HK
      , CHART_OF_ACCOUNTS_HK
      , COST_ELEMENT_HK
      , MANDT
      , KTOPL
      , KSTAR
      , GLREQUEST
      , ERSDA
      , USNAM
      , STEKZ
      , ZAHKZ
      , KSTSN
      , FUNC_AREA
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
        COA_COST_ELEMENT_HK
      , CHART_OF_ACCOUNTS_HK
      , COST_ELEMENT_HK
      , MANDT
      , KTOPL
      , KSTAR
      , GLREQUEST
      , ERSDA
      , USNAM
      , STEKZ
      , ZAHKZ
      , KSTSN
      , FUNC_AREA
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
          COA_COST_ELEMENT_HK
        , CHART_OF_ACCOUNTS_HK
        , COST_ELEMENT_HK
        , MANDT
        , KTOPL
        , KSTAR
        , GLREQUEST
        , ERSDA
        , USNAM
        , STEKZ
        , ZAHKZ
        , KSTSN
        , FUNC_AREA
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
    WHERE existing.COST_ELEMENT_HK= JOIN_RESULT.COST_ELEMENT_HK
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %} 
{% if not is_incremental() %}
/*the following qualify is to restrict multiple loads of touched records during the initial build. Ex: multiple row per hk, hashdiff */
qualify 1= row_number()over(partition by COA_COST_ELEMENT_HK, HASHDIFF order by LOAD_DTS)
union all
    SELECT        
    MD5_BINARY(GR.VALUE) AS COA_COST_ELEMENT_HK
   , MD5_BINARY(GR.VALUE) AS CHART_OF_ACCOUNTS_HK
   , MD5_BINARY(GR.VALUE) AS  COST_ELEMENT_HK
  , CAST(NULL AS STRING) AS MANDT
, CAST(NULL AS STRING) AS KTOPL
, CAST(NULL AS STRING) AS KSTAR
, CAST(NULL AS NUMBER) AS GLREQUEST
, CAST(NULL AS STRING) AS ERSDA
, CAST(NULL AS STRING) AS USNAM
, CAST(NULL AS STRING) AS STEKZ
, CAST(NULL AS STRING) AS ZAHKZ
, CAST(NULL AS STRING) AS KSTSN
, CAST(NULL AS STRING) AS FUNC_AREA
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