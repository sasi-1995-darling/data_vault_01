---- SRC LAYER ----
WITH
SRC_R              as ( SELECT * FROM {{ ref('v_psa_stg_delivery_line_detail__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY DELIVERY_LINE_HK ORDER BY LOAD_DTS ))=1 ),
SRC_INVENTORY      as ( SELECT * FROM {{ ref('v_psa_stg_goods_movement__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY DELIVERY_LINE_HK ORDER BY LOAD_DTS ))=1 )

/*
SRC_R              as ( SELECT * FROM STAGING.V_PSA_STG_DELIVERY_LINE_DETAIL__WINN_SAP )
SRC_INVENTORY      as ( SELECT * FROM STAGING.v_psa_stg_goods_movement__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_R as (
    SELECT
        DELIVERY_BK
      , DELIVERY_LINE_HK
      , DELIVERY_LINE_ITEM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_R
)

, LOGIC_INVENTORY as (
    SELECT
        DELIVERY_BK
      , DELIVERY_LINE_HK
      , DELIVERY_LINE_ITEM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_INVENTORY
)
---- RENAME LAYER ----

, RENAME_R as (
    SELECT
        DELIVERY_BK
      , DELIVERY_LINE_HK
      , DELIVERY_LINE_ITEM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_R
)

, RENAME_INVENTORY as (
    SELECT
        DELIVERY_BK
      , DELIVERY_LINE_HK
      , DELIVERY_LINE_ITEM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_INVENTORY
)
---- FILTER LAYER ----

, FILTER_R as (
    SELECT *
    FROM RENAME_R
)

, FILTER_INVENTORY as (
    SELECT *
    FROM RENAME_INVENTORY
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_R
    UNION ALL
    SELECT *
    FROM FILTER_INVENTORY
)

---- FINAL LAYER ----
SELECT
          DELIVERY_BK
        , DELIVERY_LINE_HK
        , DELIVERY_LINE_ITEM_BK
        , BKCC
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.DELIVERY_LINE_HK = JOIN_RESULT.DELIVERY_LINE_HK
)
{% endif %}
QUALIFY 1= ROW_NUMBER() OVER (PARTITION BY DELIVERY_LINE_HK ORDER BY LOAD_DTS)
{% if not is_incremental() %}

union all
SELECT 
GR.VALUE::text AS DELIVERY_BK,
MD5_BINARY(GR.VALUE) AS DELIVERY_LINE_HK,
GR.VALUE::text AS DELIVERY_LINE_ITEM_BK,
DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}