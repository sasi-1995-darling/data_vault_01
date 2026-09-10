---- SRC LAYER ----
WITH
SRC_E              as ( SELECT ENTITY_HK, ENTITY_BK, BKCC, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_entity__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY ENTITY_HK ORDER BY LOAD_DTS ))=1 )

/*
SRC_E              as ( SELECT * FROM STAGING.v_psa_stg_entity__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_E as (
    SELECT
        ENTITY_HK
      , ENTITY_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_E
)
---- RENAME LAYER ----

, RENAME_E as (
    SELECT
        ENTITY_HK
      , ENTITY_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_E
)
---- FILTER LAYER ----

, FILTER_E as (
    SELECT *
    FROM RENAME_E
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_E
)

---- FINAL LAYER ----
SELECT
          ENTITY_HK
        , ENTITY_BK
        , BKCC
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.ENTITY_HK= JOIN_RESULT.ENTITY_HK
)
{% endif %}

{% if not is_incremental() %}
 union all
 
 SELECT MD5_BINARY(GR.VALUE) ENTITY_HK
 , GR.VALUE AS ENTITY_BK
 , DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC
 , CONVERT_TIMEZONE('UTC','1900-01-01') AS LOAD_DTS
 , 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
 FROM
 TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
 {% endif %}