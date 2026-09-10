---- SRC LAYER ----
WITH
SRC_OR            as ( SELECT * FROM {{ ref('v_psa_stg_order_reason__winn_sap') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_OR            as ( SELECT * FROM STAGING.v_psa_stg_order_reason__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_OR as (
    SELECT
        ORDER_REASON_BK
      , MANDT
      , SPRAS
      , AUGRU
      , BEZEI
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , HASHDIFF
    FROM SRC_OR
)
---- RENAME LAYER ----

, RENAME_OR as (
    SELECT
        ORDER_REASON_BK
      , MANDT
      , SPRAS
      , AUGRU
      , BEZEI
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , HASHDIFF
    FROM LOGIC_OR
)
---- FILTER LAYER ----

, FILTER_OR as (
    SELECT *
    FROM RENAME_OR
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_OR
)

---- FINAL LAYER ----
SELECT
          ORDER_REASON_BK
        , MANDT
        , SPRAS
        , AUGRU
        , BEZEI
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
    WHERE existing.CURR_RATES_BK = JOIN_RESULT.CURR_RATES_BK
    AND   existing.CONVERSION_TYPE = JOIN_RESULT.CONVERSION_TYPE
    AND existing.HASH_DIFF = JOIN_RESULT.HASH_DIFF
)
{% endif %}