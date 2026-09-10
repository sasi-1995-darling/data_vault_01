---- SRC LAYER ----
WITH
SRC_PC             as ( SELECT * FROM {{ ref('v_psa_stg_profit_center_master_data__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY OBJECT_NUMBER_HK ORDER BY LOAD_DTS ))=1 )

/*
SRC_PC             as ( SELECT * FROM STAGING.v_psa_stg_profit_center_master_data__winn_sap )

*/
---- LOGIC LAYER ----

, LOGIC_PC as (
    SELECT
        OBJECT_NUMBER_HK
      , PROFIT_CENTER_BK
      , VALID_DATE_BK
      , CONTROLLING_AREA_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PC
)

---- RENAME LAYER ----

, RENAME_PC as (
    SELECT
        OBJECT_NUMBER_HK
      , PROFIT_CENTER_BK
      , VALID_DATE_BK
      , CONTROLLING_AREA_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PC
)


---- FILTER LAYER ----

, FILTER_PC as (
    SELECT *
    FROM RENAME_PC
)


---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_PC
)

---- FINAL LAYER ----
SELECT
          OBJECT_NUMBER_HK
        , PROFIT_CENTER_BK
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
      WHERE existing.OBJECT_NUMBER_HK = JOIN_RESULT.OBJECT_NUMBER_HK
)
{% endif %}
{% if not is_incremental() %}
union all

 SELECT MD5_BINARY(GR.VALUE) OBJECT_NUMBER_HK
 , GR.VALUE AS PROFIT_CENTER_BK
, GR.VALUE AS VALID_DATE_BK
, GR.VALUE AS CONTROLLING_AREA_BK
 , DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC
 , CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS
 , 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
 FROM
 TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
 {% endif %}