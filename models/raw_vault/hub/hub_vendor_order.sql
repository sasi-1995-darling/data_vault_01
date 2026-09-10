---- SRC LAYER ----
WITH
SRC_TGWINN         as ( SELECT BKCC, LOAD_DTS, REC_SRC, VENDOR_ORDER_BK, VENDOR_ORDER_HK FROM {{ ref('v_psa_stg_vendor_retail_procurement_order__amazon') }} as SRC  ),
SRC_TGOPWINN       as ( SELECT BKCC, LOAD_DTS, REC_SRC, VENDOR_ORDER_BK, VENDOR_ORDER_HK FROM {{ ref('v_psa_stg_vendor_retail_procurement_order_status__amazon') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY VENDOR_ORDER_HK ORDER BY LOAD_DTS ))=1 ),
SRC_VOD            as ( SELECT BKCC, LOAD_DTS, REC_SRC, VENDOR_ORDER_BK, VENDOR_ORDER_HK FROM {{ ref('v_psa_stg_vendor_order_details__amazon') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY VENDOR_ORDER_HK ORDER BY LOAD_DTS ))=1 )

/*
SRC_TGWINN         as ( SELECT * FROM STAGING.v_psa_stg_vendor_retail_procurement_order__amazon )
SRC_TGOPWINN       as ( SELECT * FROM STAGING.v_psa_stg_vendor_retail_procurement_order_status__amazon )
SRC_VOD            as ( SELECT * FROM STAGING.v_psa_stg_vendor_order_details__amazon)
*/
---- LOGIC LAYER ----

, LOGIC_TGWINN as (
    SELECT
        VENDOR_ORDER_HK
      , VENDOR_ORDER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_TGWINN
)

, LOGIC_TGOPWINN as (
    SELECT
        VENDOR_ORDER_HK
      , VENDOR_ORDER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_TGOPWINN
)

, LOGIC_VOD as (
    SELECT
        VENDOR_ORDER_HK
      , VENDOR_ORDER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_VOD
)
---- RENAME LAYER ----

, RENAME_TGWINN as (
    SELECT
        VENDOR_ORDER_HK
      , VENDOR_ORDER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_TGWINN
)

, RENAME_TGOPWINN as (
    SELECT
        VENDOR_ORDER_HK
      , VENDOR_ORDER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_TGOPWINN
)

, RENAME_VOD as (
    SELECT
        VENDOR_ORDER_HK
      , VENDOR_ORDER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_VOD
)
---- FILTER LAYER ----

, FILTER_TGWINN as (
    SELECT *
    FROM RENAME_TGWINN
)

, FILTER_TGOPWINN as (
    SELECT *
    FROM RENAME_TGOPWINN
)

, FILTER_VOD as (
    SELECT *
    FROM RENAME_VOD
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_TGWINN
    UNION ALL
    SELECT * FROM FILTER_TGOPWINN
    UNION ALL
    SELECT * FROM FILTER_VOD
)

---- FINAL LAYER ----
SELECT
          VENDOR_ORDER_HK
        , VENDOR_ORDER_BK
        , BKCC
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
 WHERE NOT EXISTS (
  SELECT 1 
  FROM {{ this }} existing
  WHERE existing.VENDOR_ORDER_HK= JOIN_RESULT.VENDOR_ORDER_HK
 )
 {% endif %}
 /* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per BKs and BKCC. */
 qualify 1 = row_number() over (partition by VENDOR_ORDER_HK order by LOAD_DTS)
{% if not is_incremental() %}

union all
SELECT 
MD5_BINARY(GR.VALUE) AS VENDOR_ORDER_HK,
GR.VALUE::text AS VENDOR_ORDER_BK,
DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
