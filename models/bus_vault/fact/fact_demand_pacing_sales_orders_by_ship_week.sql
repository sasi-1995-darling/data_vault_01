---- SRC LAYER ----
WITH
SRC_PB as (
    SELECT
          DISTRIBUTION_CHANNEL_HK
        , DISTRIBUTION_CHANNEL_BK
        , DIVISION_HK
        , DIVISION_BK
        , ITEM_HK
        , ITEM_BK
        , PLANT_HK
        , PLANT_BK
        , CUSTOMER_SOLDTO_HK
        , CUSTOMER_SOLDTO_BK
        , SALES_ORGANIZATION_HK
        , SALES_ORGANIZATION_BK
        , APO_CUSTOMER_GROUP
        , REQUESTED_SHIP_WEEK__YYYYWW
        , REC_SRC
        , BKCC
        , WEEKLY_ORDERED_QUANTITY
    FROM {{ ref('pb_demand_pacing_sales_orders_by_ship_week') }}
)

---- LOGIC LAYER ----

, LOGIC_PB as (
    SELECT
          DISTRIBUTION_CHANNEL_HK
        , DISTRIBUTION_CHANNEL_BK
        , DIVISION_HK
        , DIVISION_BK
        , ITEM_HK
        , ITEM_BK
        , PLANT_HK
        , PLANT_BK
        , CUSTOMER_SOLDTO_HK
        , CUSTOMER_SOLDTO_BK
        , SALES_ORGANIZATION_HK
        , SALES_ORGANIZATION_BK
        , APO_CUSTOMER_GROUP
        , REQUESTED_SHIP_WEEK__YYYYWW
        , REC_SRC
        , BKCC
        , WEEKLY_ORDERED_QUANTITY
    FROM SRC_PB
)


---- RENAME LAYER ----

, RENAME_PB as (
    SELECT
          DISTRIBUTION_CHANNEL_HK
        , DISTRIBUTION_CHANNEL_BK
        , DIVISION_HK
        , DIVISION_BK
        , ITEM_HK
        , ITEM_BK
        , PLANT_HK
        , PLANT_BK
        , CUSTOMER_SOLDTO_HK
        , CUSTOMER_SOLDTO_BK
        , SALES_ORGANIZATION_HK
        , SALES_ORGANIZATION_BK
        , APO_CUSTOMER_GROUP
        , REQUESTED_SHIP_WEEK__YYYYWW
        , REC_SRC
        , BKCC
        , WEEKLY_ORDERED_QUANTITY
    FROM LOGIC_PB
)

---- FILTER LAYER ----

, FILTER_PB as (
    SELECT *
    FROM RENAME_PB
)


---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_PB
)

---- FINAL LAYER ----
SELECT
          DISTRIBUTION_CHANNEL_HK
        , DISTRIBUTION_CHANNEL_BK
        , DIVISION_HK
        , DIVISION_BK
        , ITEM_HK
        , ITEM_BK
        , PLANT_HK
        , PLANT_BK
        , CUSTOMER_SOLDTO_HK
        , CUSTOMER_SOLDTO_BK
        , SALES_ORGANIZATION_HK
        , SALES_ORGANIZATION_BK
        , APO_CUSTOMER_GROUP
        , REQUESTED_SHIP_WEEK__YYYYWW
        , REC_SRC
        , BKCC
        , WEEKLY_ORDERED_QUANTITY
FROM JOIN_RESULT