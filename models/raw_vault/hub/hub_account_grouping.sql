---- SRC LAYER ----
WITH
SRC_FA             as ( SELECT BKCC, FUNCTIONAL_AREA_BK, FUNCTIONAL_AREA_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_account_grouping__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY FUNCTIONAL_AREA_HK ORDER BY LOAD_DTS ))=1 )

/*
SRC_FA             as ( SELECT * FROM STAGING.v_psa_stg_functional_area__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_FA as (
    SELECT
        FUNCTIONAL_AREA_HK
      , FUNCTIONAL_AREA_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_FA
)
---- RENAME LAYER ----

, RENAME_FA as (
    SELECT
        FUNCTIONAL_AREA_HK
      , FUNCTIONAL_AREA_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_FA
)
---- FILTER LAYER ----

, FILTER_FA as (
    SELECT *
    FROM RENAME_FA
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_FA
)

---- FINAL LAYER ----
SELECT
          FUNCTIONAL_AREA_HK
        , FUNCTIONAL_AREA_BK
        , BKCC
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
  WHERE NOT EXISTS (
      SELECT 1 
      FROM {{ this }} existing
      WHERE existing.FUNCTIONAL_AREA_HK= JOIN_RESULT.FUNCTIONAL_AREA_HK
)
{% endif %}
{% if not is_incremental() %}
 union all
 
 SELECT MD5_BINARY(GR.VALUE) FUNCTIONAL_AREA_HK
 , GR.VALUE AS FUNCTIONAL_AREA_BK
 , DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC
 , CONVERT_TIMEZONE('UTC','1900-01-01') AS LOAD_DTS
 , 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
 FROM
 TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
 {% endif %}