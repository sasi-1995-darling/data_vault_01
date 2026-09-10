
---- SRC LAYER ----
WITH
SRC_b              as ( SELECT * FROM {{ ref('v_psa_stg_production_order_line__winn_sap') }} as SRC  
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCTION_ORDER_LINE_HK ORDER BY LOAD_DTS desc ))=1 ),
SRC_c              as ( SELECT * FROM {{ ref('v_psa_stg_order_confirmation__winn_sap') }} as SRC  
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY ORDER_CONFIRMATION_HK ORDER BY LOAD_DTS desc ))=1 )
/*
SRC_b              as ( SELECT * FROM STAGING.V_PSA_STG_PRODUCTION_ORDER_LINE__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_b as (
    SELECT
        PRODUCTION_ORDER_LINE_HK
      , PRODUCTION_ORDER_LINE_ITEM_BK
      , PRODUCTION_ORDER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_b
)

, LOGIC_c as (
    SELECT
        PRODUCTION_ORDER_LINE_HK
      , PRODUCTION_ORDER_LINE_ITEM_BK
      , PRODUCTION_ORDER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_c
)
---- RENAME LAYER ----

, RENAME_b as (
    SELECT
        PRODUCTION_ORDER_LINE_HK
      , PRODUCTION_ORDER_LINE_ITEM_BK
      , PRODUCTION_ORDER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_b
)

, RENAME_c as (
    SELECT
        PRODUCTION_ORDER_LINE_HK
      , PRODUCTION_ORDER_LINE_ITEM_BK
      , PRODUCTION_ORDER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_c
)
---- FILTER LAYER ----

, FILTER_b as (
    SELECT *
    FROM RENAME_b
)

, FILTER_c as (
    SELECT *
    FROM RENAME_c
)

    

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_b
    UNION ALL
    SELECT *
    FROM FILTER_c
)

---- FINAL LAYER ----
SELECT
          PRODUCTION_ORDER_LINE_HK
        , PRODUCTION_ORDER_LINE_ITEM_BK
        , PRODUCTION_ORDER_BK
        , BKCC
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.PRODUCTION_ORDER_LINE_HK = JOIN_RESULT.PRODUCTION_ORDER_LINE_HK
)
{% endif %}
QUALIFY 1= ROW_NUMBER() OVER (PARTITION BY PRODUCTION_ORDER_LINE_HK ORDER BY LOAD_DTS)
{% if not is_incremental() %}

union all
SELECT 
MD5_BINARY(GR.VALUE) AS PRODUCTION_ORDER_LINE_HK,
GR.VALUE::text AS PRODUCTION_ORDER_LINE_ITEM_BK,
GR.VALUE::text AS PRODUCTION_ORDER_BK,
DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}