---- SRC LAYER ----
WITH
SRC_LOB            as ( SELECT EQUIPMENT_HK, ITEM_HK, LNK_OBJECT_LIST_DETAIL_HK, LOAD_DTS, OBJECT_LIST_HK, REC_SRC FROM {{ ref('v_psa_stg_object_list_detail__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY LNK_OBJECT_LIST_DETAIL_HK ORDER BY LOAD_DTS DESC))=1 )

/*
SRC_LOB            as ( SELECT * FROM STAGING.v_psa_stg_object_list_detail__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_LOB as (
    SELECT
        LNK_OBJECT_LIST_DETAIL_HK
      , OBJECT_LIST_HK
      , ITEM_HK
      , EQUIPMENT_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_LOB
)
---- RENAME LAYER ----

, RENAME_LOB as (
    SELECT
        LNK_OBJECT_LIST_DETAIL_HK
      , OBJECT_LIST_HK
      , ITEM_HK
      , EQUIPMENT_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_LOB
)
---- FILTER LAYER ----

, FILTER_LOB as (
    SELECT *
    FROM RENAME_LOB
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_LOB
)

---- FINAL LAYER ----
SELECT
          LNK_OBJECT_LIST_DETAIL_HK
        , OBJECT_LIST_HK
        , ITEM_HK
        , EQUIPMENT_HK
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.LNK_OBJECT_LIST_DETAIL_HK = JOIN_RESULT.LNK_OBJECT_LIST_DETAIL_HK
)
{% endif %}
--this is to consolidate records coming from 2 diff tables with the same bkcc
QUALIFY (ROW_NUMBER() OVER(PARTITION BY LNK_OBJECT_LIST_DETAIL_HK ORDER BY LOAD_DTS DESC))=1
{% if not is_incremental() %}

union all
SELECT 
 MD5_BINARY(GR.VALUE) AS LNK_OBJECT_LIST_DETAIL_HK
, MD5_BINARY(GR.VALUE) AS OBJECT_LIST_HK
, MD5_BINARY(GR.VALUE) AS ITEM_HK
, MD5_BINARY(GR.VALUE) AS EQUIPMENT_HK
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)  AS LOAD_DTS
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}