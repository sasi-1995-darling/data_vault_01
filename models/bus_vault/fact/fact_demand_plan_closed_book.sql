---- SRC LAYER ----
WITH
SRC_dc             as ( SELECT ANALYST_LIFT, APO_ACCOUNT, APO_ORDER_QUANTITY_HISTORY, ACQUISITION_DATE__YYYYMMDD, BW_REQUEST_ID, CUSTOMER_QTY_ON_HAND, DEMAND_PLAN_LHK,  DISTRIBUTION_CHANNEL_BK, DISTRIBUTION_CHANNEL_HK, DIVISION_BK, DIVISION_HK, Distribution_Channel, FINAL_FORECAST, FORECAST_CUSTOMER_GROUP_BK, FORECAST_CUSTOMER_GROUP_HK, Fiscal_Period, Fiscal_Quarter, Fiscal_Variant, ITEM_BK, ITEM_HK,  MANUALLY_CORRECTED_HISTORY, MOEN_PROP_FACTOR, NAIVE_FORECAST, NEW_PRODUCT_FORECAST, OUTED_DEMAND, PLANNING_PERIOD, PLANT_BK, PLANT_HK, PROMOTIONS_QTY, PSA_DELETE_IND, QUANTITY_SOLD_CUSTOMER_POS, SALES_ORGANIZATION_BK, SALES_ORGANIZATION_HK, SEQ_ID, STATISTICAL_FORECAST_T1, Sales_Org, TRANSFERABLE_DEMAND, TRANSFERABLE_FORECAST, UOM_BK, UOM_HK, WORKING_FORECAST, cal_month, cal_quarter, cal_week, cal_year, division, material, order_qty, plant, REC_SRC, BKCC FROM {{ ref('pb_demand_plan_closed_book') }} as SRC  )

/*
SRC_dc             as ( SELECT * FROM BUS_VAULT.pb_Demand_Plan_Closed_Book )
*/
---- LOGIC LAYER ----

, LOGIC_dc as (
    SELECT
        DEMAND_PLAN_LHK
      , ITEM_HK
      , DISTRIBUTION_CHANNEL_HK
      , DIVISION_HK
      , PLANT_HK
      , SALES_ORGANIZATION_HK
      , UOM_HK
      , FORECAST_CUSTOMER_GROUP_HK
      , ITEM_BK
      , DISTRIBUTION_CHANNEL_BK
      , DIVISION_BK
      , PLANT_BK
      , SALES_ORGANIZATION_BK
      , UOM_BK
      , FORECAST_CUSTOMER_GROUP_BK
      , Distribution_Channel
      , division
      , material
      , plant
      , Sales_Org
      , APO_ACCOUNT
      , PLANNING_PERIOD
      , cal_year
      , cal_quarter
      , cal_month
      , cal_week
      , Fiscal_Period
      , Fiscal_Variant
      , Fiscal_Quarter
      , order_qty
      , APO_ORDER_QUANTITY_HISTORY
      , STATISTICAL_FORECAST_T1
      , CUSTOMER_QTY_ON_HAND
      , ANALYST_LIFT
      , MANUALLY_CORRECTED_HISTORY
      , QUANTITY_SOLD_CUSTOMER_POS
      , PROMOTIONS_QTY
      , NAIVE_FORECAST
      , WORKING_FORECAST
      , FINAL_FORECAST
      , OUTED_DEMAND
      , TRANSFERABLE_FORECAST
      , NEW_PRODUCT_FORECAST
      , MOEN_PROP_FACTOR
      , TRANSFERABLE_DEMAND
      , ACQUISITION_DATE__YYYYMMDD
      , PSA_DELETE_IND
      , SEQ_ID
      , BW_REQUEST_ID
      ,BKCC
      ,REC_SRC
    FROM SRC_dc
)
---- RENAME LAYER ----

, RENAME_dc as (
    SELECT
        DEMAND_PLAN_LHK
      , ITEM_HK
      , DISTRIBUTION_CHANNEL_HK
      , DIVISION_HK
      , PLANT_HK
      , SALES_ORGANIZATION_HK
      , UOM_HK
      , FORECAST_CUSTOMER_GROUP_HK
      , ITEM_BK
      , DISTRIBUTION_CHANNEL_BK
      , DIVISION_BK
      , PLANT_BK
      , SALES_ORGANIZATION_BK
      , UOM_BK
      , FORECAST_CUSTOMER_GROUP_BK
      , Distribution_Channel
      , division
      , material
      , plant
      , Sales_Org
      , APO_ACCOUNT
      , PLANNING_PERIOD
      , cal_year
      , cal_quarter
      , cal_month
      , cal_week
      , Fiscal_Period
      , Fiscal_Variant
      , Fiscal_Quarter
      , order_qty
      , APO_ORDER_QUANTITY_HISTORY
      , STATISTICAL_FORECAST_T1
      , CUSTOMER_QTY_ON_HAND
      , ANALYST_LIFT
      , MANUALLY_CORRECTED_HISTORY
      , QUANTITY_SOLD_CUSTOMER_POS
      , PROMOTIONS_QTY
      , NAIVE_FORECAST
      , WORKING_FORECAST
      , FINAL_FORECAST
      , OUTED_DEMAND
      , TRANSFERABLE_FORECAST
      , NEW_PRODUCT_FORECAST
      , MOEN_PROP_FACTOR
      , TRANSFERABLE_DEMAND
      , ACQUISITION_DATE__YYYYMMDD
      , PSA_DELETE_IND
      , SEQ_ID
      , BW_REQUEST_ID
      , BKCC
      , REC_SRC
    FROM LOGIC_dc
)
---- FILTER LAYER ----

, FILTER_dc as (
    SELECT *
    FROM RENAME_dc
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_dc
)

---- FINAL LAYER ----
SELECT
          DEMAND_PLAN_LHK
        , ITEM_HK
        , DISTRIBUTION_CHANNEL_HK
        , DIVISION_HK
        , PLANT_HK
        , SALES_ORGANIZATION_HK
        , UOM_HK
        , FORECAST_CUSTOMER_GROUP_HK
        , ITEM_BK
        , DISTRIBUTION_CHANNEL_BK
        , DIVISION_BK
        , PLANT_BK
        , SALES_ORGANIZATION_BK
        , UOM_BK
        , FORECAST_CUSTOMER_GROUP_BK
        , DISTRIBUTION_CHANNEL
        , DIVISION
        , MATERIAL
        , PLANT
        , SALES_ORG
        , APO_ACCOUNT
        , PLANNING_PERIOD
        , CAL_YEAR
        , CAL_QUARTER
        , CAL_MONTH
        , CAL_WEEK
        , FISCAL_PERIOD
        , Fiscal_Variant
        , FISCAL_QUARTER
        , ORDER_QTY
        , APO_ORDER_QUANTITY_HISTORY
        , STATISTICAL_FORECAST_T1
        , CUSTOMER_QTY_ON_HAND
        , ANALYST_LIFT
        , MANUALLY_CORRECTED_HISTORY
        , QUANTITY_SOLD_CUSTOMER_POS
        , PROMOTIONS_QTY
        , NAIVE_FORECAST
        , WORKING_FORECAST
        , FINAL_FORECAST
        , OUTED_DEMAND
        , TRANSFERABLE_FORECAST
        , NEW_PRODUCT_FORECAST
        , MOEN_PROP_FACTOR
        , TRANSFERABLE_DEMAND
        , ACQUISITION_DATE__YYYYMMDD
        , PSA_DELETE_IND
        , SEQ_ID
        , BW_REQUEST_ID
        , BKCC
        , REC_SRC
FROM JOIN_RESULT