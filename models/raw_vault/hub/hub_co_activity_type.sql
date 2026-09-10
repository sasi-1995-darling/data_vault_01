---- SRC LAYER ----
WITH
SRC_AT             as ( SELECT * FROM {{ ref('v_psa_stg_co_activity_type__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY CO_ACTIVITY_TYPE_HK ORDER BY LOAD_DTS ))=1 )
/*
SRC_AT             as ( SELECT * FROM STAGING.v_psa_stg_co_activity_type__winn_sap )

*/
---- LOGIC LAYER ----

, LOGIC_AT as (
    SELECT
        CO_ACTIVITY_TYPE_HK
      , ACTIVITY_TYPE_BK
      , VALID_DATE_BK
      , CONTROLLING_AREA_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_AT
)

---- RENAME LAYER ----

, RENAME_AT as (
    SELECT
        CO_ACTIVITY_TYPE_HK
      , ACTIVITY_TYPE_BK
      , VALID_DATE_BK
      , CONTROLLING_AREA_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_AT
)

---- FILTER LAYER ----

, FILTER_AT as (
    SELECT *
    FROM RENAME_AT
)


---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_AT
)

---- FINAL LAYER ----
SELECT
          CO_ACTIVITY_TYPE_HK
        , ACTIVITY_TYPE_BK
        , VALID_DATE_BK
        , CONTROLLING_AREA_BK
        , BKCC
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
  WHERE NOT EXISTS (
      SELECT 1 
      FROM {{ this }} existing
      WHERE existing.CO_ACTIVITY_TYPE_HK = JOIN_RESULT.CO_ACTIVITY_TYPE_HK
)
{% endif %}
{% if not is_incremental() %}
union all  
SELECT 
MD5_BINARY(GR.VALUE) CO_ACTIVITY_TYPE_HK 
, GR.VALUE AS ACTIVITY_TYPE_BK
, GR.VALUE AS VALID_DATE_BK
, GR.VALUE AS CONTROLLING_AREA_BK 
, DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC 
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS 
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC 
FROM TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR {% endif %}