---- SRC LAYER ----
WITH
SRC_v1             as ( SELECT DELIVERIES_IN_SHIPMENT_LHK, DELIVERY_HK, LOAD_DTS, REC_SRC, SHIPMENT_HK FROM {{ ref('v_psa_stg_shipment_item__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY DELIVERIES_IN_SHIPMENT_LHK ORDER BY LOAD_DTS ))=1 )

/*
SRC_v1             as ( SELECT * FROM STAGING.v_psa_stg_shipment_item__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_v1 as (
    SELECT
        DELIVERIES_IN_SHIPMENT_LHK
      , SHIPMENT_HK
      , DELIVERY_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_v1
)
---- RENAME LAYER ----

, RENAME_v1 as (
    SELECT
        DELIVERIES_IN_SHIPMENT_LHK
      , SHIPMENT_HK
      , DELIVERY_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_v1
)
---- FILTER LAYER ----

, FILTER_v1 as (
    SELECT *
    FROM RENAME_v1
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_v1
)

---- FINAL LAYER ----
SELECT
          DELIVERIES_IN_SHIPMENT_LHK
        , SHIPMENT_HK
        , DELIVERY_HK
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
 WHERE NOT EXISTS (
  SELECT 1 
  FROM {{ this }} existing
  WHERE existing.DELIVERIES_IN_SHIPMENT_LHK= JOIN_RESULT.DELIVERIES_IN_SHIPMENT_LHK
 )
 {% endif %}
{% if not is_incremental() %}

union all
SELECT 
MD5_BINARY(GR.VALUE) AS DELIVERIES_IN_SHIPMENT_LHK,
MD5_BINARY(GR.VALUE) AS SHIPMENT_HK,
MD5_BINARY(GR.VALUE) AS DELIVERY_HK,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
