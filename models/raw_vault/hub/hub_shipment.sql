---- SRC LAYER ----
WITH
SRC_TGWINN         as ( SELECT BKCC, LOAD_DTS, REC_SRC, SHIPMENT_BK, SHIPMENT_HK FROM {{ ref('v_psa_stg_shipment__winn_sap') }} as SRC  ),
SRC_TGOPWINN       as ( SELECT BKCC, LOAD_DTS, REC_SRC, SHIPMENT_BK, SHIPMENT_HK FROM {{ ref('v_psa_stg_shipment_item__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY shipment_hk ORDER BY LOAD_DTS ))=1 )

/*
SRC_TGWINN         as ( SELECT * FROM STAGING.v_psa_stg_shipment__winn_sap )
SRC_TGOPWINN       as ( SELECT * FROM STAGING.v_psa_stg_shipment_item__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_TGWINN as (
    SELECT
        SHIPMENT_HK
      , SHIPMENT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_TGWINN
)

, LOGIC_TGOPWINN as (
    SELECT
        SHIPMENT_HK
      , SHIPMENT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_TGOPWINN
)
---- RENAME LAYER ----

, RENAME_TGWINN as (
    SELECT
        SHIPMENT_HK
      , SHIPMENT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_TGWINN
)

, RENAME_TGOPWINN as (
    SELECT
        SHIPMENT_HK
      , SHIPMENT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_TGOPWINN
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
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_TGWINN
    UNION ALL
    SELECT * FROM FILTER_TGOPWINN
)

---- FINAL LAYER ----
SELECT
          SHIPMENT_HK
        , SHIPMENT_BK
        , BKCC
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
 WHERE NOT EXISTS (
  SELECT 1 
  FROM {{ this }} existing
  WHERE existing.shipment_hk= JOIN_RESULT.shipment_hk
 )
 {% endif %}
 /* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per BKs and BKCC. */
 qualify 1 = row_number() over (partition by shipment_hk order by LOAD_DTS)
{% if not is_incremental() %}

union all
SELECT 
MD5_BINARY(GR.VALUE) AS SHIPMENT_HK,
GR.VALUE::text AS SHIPMENT_BK,
DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
