---- SRC LAYER ----
WITH
SRC_D              as ( SELECT BKCC, CARRIER_ID, OVERALL_STATUS, REC_SRC, SHIPMENT_BK, SHIPMENT_HK, SHIPMENT_ID, SHIPMENT_TYPE, SHIPPING_TYPE FROM {{ ref('pit_shipment') }} as SRC  )

/*
SRC_D              as ( SELECT * FROM BUS_VAULT.pit_shipment )
*/
---- LOGIC LAYER ----

, LOGIC_D as (
    SELECT
        REC_SRC
      , SHIPMENT_BK
      , SHIPMENT_HK
      , SHIPMENT_ID
      , SHIPMENT_TYPE
      , CARRIER_ID
      , SHIPPING_TYPE
      , OVERALL_STATUS
      , BKCC
    FROM SRC_D
)
---- RENAME LAYER ----

, RENAME_D as (
    SELECT
        REC_SRC
      , SHIPMENT_BK
      , SHIPMENT_HK
      , SHIPMENT_ID
      , SHIPMENT_TYPE
      , CARRIER_ID
      , SHIPPING_TYPE
      , OVERALL_STATUS
      , BKCC
    FROM LOGIC_D
)
---- FILTER LAYER ----

, FILTER_D as (
    SELECT *
    FROM RENAME_D
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_D
)

---- FINAL LAYER ----
SELECT
          REC_SRC
        , SHIPMENT_BK
        , SHIPMENT_HK
        , SHIPMENT_ID
        , SHIPMENT_TYPE
        , CARRIER_ID
        , SHIPPING_TYPE
        , OVERALL_STATUS
        , BKCC
FROM JOIN_RESULT
