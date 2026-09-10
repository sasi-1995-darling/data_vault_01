---- SRC LAYER ----
WITH
SRC_OB             as ( SELECT BKCC, LOAD_DTS, OBJECT_LIST_BK, OBJECT_LIST_HK, REC_SRC FROM {{ ref('v_psa_stg_object_list_detail__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY OBJECT_LIST_HK ORDER BY LOAD_DTS ))=1 )

/*
SRC_OB             as ( SELECT * FROM STAGING.v_psa_stg_object_list_detail__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_OB as (
    SELECT
        OBJECT_LIST_HK
      , OBJECT_LIST_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_OB
)
---- RENAME LAYER ----

, RENAME_OB as (
    SELECT
        OBJECT_LIST_HK
      , OBJECT_LIST_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_OB
)
---- FILTER LAYER ----

, FILTER_OB as (
    SELECT *
    FROM RENAME_OB
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_OB
)

---- FINAL LAYER ----
SELECT
          OBJECT_LIST_HK
        , TO_NUMBER(OBJECT_LIST_BK,38,0) as OBJECT_LIST_BK
        , BKCC
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.OBJECT_LIST_HK = JOIN_RESULT.OBJECT_LIST_HK
)
{% endif %}
{% if not is_incremental() %}

union all

SELECT MD5_BINARY(GR.VALUE)  as OBJECT_LIST_HK
, TO_NUMBER(GR.VALUE,38,0)  AS OBJECT_LIST_BK
, DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS BKCC
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)  AS LOAD_DTS
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}