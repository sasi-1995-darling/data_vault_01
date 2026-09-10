---- SRC LAYER ----
WITH
SRC_lnk            as ( SELECT DEMAND_PLAN_LHK, DISTRIBUTION_CHANNEL_HK, DIVISION_HK, FORECAST_CUSTOMER_GROUP_HK, ITEM_HK, PLANT_HK, SALES_ORGANIZATION_HK, UOM_HK, PLANNING_PERIOD, REC_SRC FROM {{ ref('lnk_demand_plan') }} as SRC  ),
SRC_s_dp           as ( SELECT BIC_Z9ADFCST, BIC_ZANALIFT, BIC_ZCUSTINV, BIC_ZFINLFCST, BIC_ZFQUARTER, BIC_ZLEADIND, BIC_ZMCORHIST, BIC_ZMOENPROP, BIC_ZNEWPFCST, BIC_ZOUTTED, BIC_ZPOSQTY, BIC_ZPRMOFCST, BIC_ZPROMOQTY, BIC_ZSTATFCST, BIC_ZTRANSDMD, BIC_ZZAPOACCT, CALMONTH, CALQUARTER, CALWEEK, CALYEAR, DATE0, DEMAND_PLAN_LHK, DISTR_CHAN, DIVISION, FISCPER, FISCVARNT, GLCHANGETIME, MATERIAL, ORDER_QTY, PLANT, PSA_DELETE_IND , REQUID, SALESORG FROM {{ ref('lmsat_demand_plan_history__winn_sap') }} as SRC 
                        QUALIFY ROW_NUMBER() OVER (PARTITION BY DEMAND_PLAN_LHK ORDER BY GLCHANGETIME DESC) = 1 ),
SRC_h_mara         as ( SELECT BKCC, ITEM_BK, ITEM_HK FROM {{ ref('hub_item_v1') }} as SRC  ),
SRC_h_dis          as ( SELECT DISTRIBUTION_CHANNEL_BK, DISTRIBUTION_CHANNEL_HK FROM {{ ref('hub_distribution_channel') }} as SRC  ),
SRC_h_div          as ( SELECT DIVISION_BK, DIVISION_HK FROM {{ ref('hub_division') }} as SRC  ),
SRC_h_plant        as ( SELECT PLANT_BK, PLANT_HK FROM {{ ref('hub_plant_v1') }} as SRC  ),
SRC_h_so           as ( SELECT SALES_ORGANIZATION_BK, SALES_ORGANIZATION_HK FROM {{ ref('hub_sales_organization') }} as SRC  ),
SRC_h_uom          as ( SELECT UOM_BK, UOM_HK FROM {{ ref('hub_uom') }} as SRC  ),
SRC_h_fcg          as ( SELECT FORECAST_CUSTOMER_GROUP_BK, FORECAST_CUSTOMER_GROUP_HK FROM {{ ref('hub_forecast_customer_group') }} as SRC  )

/*
SRC_lnk            as ( SELECT * FROM RAW_VAULT.lnk_demand_plan )
SRC_s_dp           as ( SELECT * FROM RAW_VAULT.lsat_demand_plan__winn_sap )
SRC_h_mara         as ( SELECT * FROM RAW_VAULT.HUB_ITEM_V1 )
SRC_h_dis          as ( SELECT * FROM RAW_VAULT.hub_distribution_channel )
SRC_h_div          as ( SELECT * FROM RAW_VAULT.hub_division )
SRC_h_plant        as ( SELECT * FROM RAW_VAULT.hub_plant_v1 )
SRC_h_so           as ( SELECT * FROM RAW_VAULT.hub_sales_organization )
SRC_h_uom          as ( SELECT * FROM RAW_VAULT.hub_uom )
SRC_h_fcg          as ( SELECT * FROM RAW_VAULT.HUB_FORECAST_CUSTOMER_GROUP )
*/
---- LOGIC LAYER ----

, LOGIC_lnk as (
    SELECT
        DEMAND_PLAN_LHK
      , DISTRIBUTION_CHANNEL_HK                                      as                        DISTRIBUTION_CHANNEL_HK_LNK
      , DIVISION_HK                                                  as                                    DIVISION_HK_LNK
      , ITEM_HK                                                      as                                        ITEM_HK_LNK
      , PLANT_HK                                                     as                                       PLANT_HK_LNK
      , SALES_ORGANIZATION_HK                                        as                          SALES_ORGANIZATION_HK_LNK
      , UOM_HK                                                       as                                         UOM_HK_LNK
      , FORECAST_CUSTOMER_GROUP_HK                                   as                     FORECAST_CUSTOMER_GROUP_HK_LNK
      , PLANNING_PERIOD::INTEGER as PLANNING_PERIOD
      , REC_SRC
    FROM SRC_lnk
)

, LOGIC_s_dp as (
    SELECT
        DEMAND_PLAN_LHK                                              as                               DEMAND_PLAN_LHK_S_DP
      , DISTR_CHAN                                                   as                               Distribution_Channel
      , DIVISION                                                     as                                           division
      , MATERIAL                                                     as                                           material
      , PLANT                                                        as                                              plant
      , SALESORG                                                     as                                          Sales_Org
      , BIC_ZZAPOACCT                                                as                                        APO_ACCOUNT
      , CALYEAR::INTEGER                                             as                                           cal_year
      , CALQUARTER::INTEGER                                          as                                        cal_quarter
      , CALMONTH::INTEGER                                            as                                          cal_month
      , CALWEEK::INTEGER                                             as                                           cal_week
      , FISCPER::INTEGER                                             as                                      Fiscal_Period
      , FISCVARNT                                                    as                                     Fiscal_Variant
      , BIC_ZFQUARTER                                                as                                     Fiscal_Quarter
      , ORDER_QTY                                                    as                                          order_qty
      , ORDER_QTY                                                    as                         APO_ORDER_QUANTITY_HISTORY
      , BIC_Z9ADFCST                                                 as                            STATISTICAL_FORECAST_T1
      , BIC_ZCUSTINV                                                 as                               CUSTOMER_QTY_ON_HAND
      , BIC_ZANALIFT                                                 as                                       ANALYST_LIFT
      , BIC_ZMCORHIST                                                as                         MANUALLY_CORRECTED_HISTORY
      , BIC_ZPOSQTY                                                  as                         QUANTITY_SOLD_CUSTOMER_POS
      , BIC_ZPROMOQTY                                                as                                     PROMOTIONS_QTY
      , BIC_ZSTATFCST                                                as                                     NAIVE_FORECAST
      , BIC_ZLEADIND                                                 as                                   WORKING_FORECAST
      , BIC_ZFINLFCST                                                as                                     FINAL_FORECAST
      , BIC_ZOUTTED                                                  as                                      OUTED_DEMAND
      , BIC_ZPRMOFCST                                                as                              TRANSFERABLE_FORECAST
      , BIC_ZNEWPFCST                                                as                               NEW_PRODUCT_FORECAST
      , BIC_ZMOENPROP                                                as                                   MOEN_PROP_FACTOR
      , BIC_ZTRANSDMD                                                as                                TRANSFERABLE_DEMAND
      , DATE0::NUMBER                                                         as                          ACQUISITION_DATE__YYYYMMDD
      , REQUID                                                       as                                      BW_REQUEST_ID
      , GLCHANGETIME                                                 as                                           LOAD_DTS
      , PSA_DELETE_IND
    FROM SRC_s_dp
)

, LOGIC_h_mara as (
    SELECT
        ITEM_HK
      , ITEM_BK
      , BKCC
    FROM SRC_h_mara
)

, LOGIC_h_dis as (
    SELECT
        DISTRIBUTION_CHANNEL_HK
      , DISTRIBUTION_CHANNEL_BK
    FROM SRC_h_dis
)

, LOGIC_h_div as (
    SELECT
        DIVISION_HK
      , DIVISION_BK
    FROM SRC_h_div
)

, LOGIC_h_plant as (
    SELECT
        PLANT_HK
      , PLANT_BK
    FROM SRC_h_plant
)

, LOGIC_h_so as (
    SELECT
        SALES_ORGANIZATION_HK
      , SALES_ORGANIZATION_BK
    FROM SRC_h_so
)

, LOGIC_h_uom as (
    SELECT
        UOM_HK
      , UOM_BK
    FROM SRC_h_uom
)


, LOGIC_h_fcg as (
    SELECT
        FORECAST_CUSTOMER_GROUP_HK
      , FORECAST_CUSTOMER_GROUP_BK
    FROM SRC_h_fcg
)
---- RENAME LAYER ----

, RENAME_lnk as (
    SELECT
        DEMAND_PLAN_LHK
      , DISTRIBUTION_CHANNEL_HK_LNK
      , DIVISION_HK_LNK
      , ITEM_HK_LNK
      , PLANT_HK_LNK
      , SALES_ORGANIZATION_HK_LNK
      , UOM_HK_LNK
      , FORECAST_CUSTOMER_GROUP_HK_LNK
      , PLANNING_PERIOD
      , REC_SRC
    FROM LOGIC_lnk
)

, RENAME_h_mara as (
    SELECT
        ITEM_HK
      , ITEM_BK
      , BKCC
    FROM LOGIC_h_mara
)

, RENAME_h_dis as (
    SELECT
        DISTRIBUTION_CHANNEL_HK
      , DISTRIBUTION_CHANNEL_BK
    FROM LOGIC_h_dis
)

, RENAME_h_div as (
    SELECT
        DIVISION_HK
      , DIVISION_BK
    FROM LOGIC_h_div
)

, RENAME_h_plant as (
    SELECT
        PLANT_HK
      , PLANT_BK
    FROM LOGIC_h_plant
)

, RENAME_h_so as (
    SELECT
        SALES_ORGANIZATION_HK
      , SALES_ORGANIZATION_BK
    FROM LOGIC_h_so
)

, RENAME_h_uom as (
    SELECT
        UOM_HK
      , UOM_BK
    FROM LOGIC_h_uom
)


, RENAME_h_fcg as (
    SELECT
        FORECAST_CUSTOMER_GROUP_HK
      , FORECAST_CUSTOMER_GROUP_BK
    FROM LOGIC_h_fcg
)

, RENAME_s_dp as (
    SELECT
        DEMAND_PLAN_LHK_S_DP
      , Distribution_Channel
      , division
      , material
      , plant
      , Sales_Org
      , APO_ACCOUNT
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
      , BW_REQUEST_ID
      , LOAD_DTS
      , PSA_DELETE_IND 
    FROM LOGIC_s_dp
)
---- FILTER LAYER ----

, FILTER_lnk as (
    SELECT *
    FROM RENAME_lnk
    WHERE REC_SRC <> 'USAZET.SNOWFLAKE.FBIN.DERIVED'
)

, FILTER_s_dp as (
    SELECT *
    FROM RENAME_s_dp
)

, FILTER_h_mara as (
    SELECT *
    FROM RENAME_h_mara
)

, FILTER_h_dis as (
    SELECT *
    FROM RENAME_h_dis
)

, FILTER_h_div as (
    SELECT *
    FROM RENAME_h_div
)

, FILTER_h_plant as (
    SELECT *
    FROM RENAME_h_plant
)

, FILTER_h_so as (
    SELECT *
    FROM RENAME_h_so
)

, FILTER_h_uom as (
    SELECT *
    FROM RENAME_h_uom
)

, FILTER_h_fcg as (
    SELECT *
    FROM RENAME_h_fcg
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_lnk
    INNER JOIN FILTER_s_dp
        ON FILTER_s_dp.DEMAND_PLAN_LHK_S_DP = FILTER_lnk.DEMAND_PLAN_LHK
    INNER JOIN FILTER_h_mara
        ON FILTER_lnk.ITEM_HK_LNK = FILTER_h_mara.ITEM_HK
    INNER JOIN FILTER_h_dis
        ON FILTER_lnk.DISTRIBUTION_CHANNEL_HK_LNK = FILTER_h_dis.DISTRIBUTION_CHANNEL_HK
    INNER JOIN FILTER_h_div
        ON FILTER_lnk.DIVISION_HK_LNK = FILTER_h_div.DIVISION_HK
    INNER JOIN FILTER_h_plant
        ON FILTER_lnk.PLANT_HK_LNK = FILTER_h_plant.PLANT_HK
    INNER JOIN FILTER_h_so
        ON FILTER_lnk.SALES_ORGANIZATION_HK_LNK = FILTER_h_so.SALES_ORGANIZATION_HK
    INNER JOIN FILTER_h_uom
        ON FILTER_lnk.UOM_HK_LNK = FILTER_h_uom.UOM_HK
    INNER JOIN FILTER_h_fcg
        ON FILTER_lnk.FORECAST_CUSTOMER_GROUP_HK_LNK = FILTER_h_fcg.FORECAST_CUSTOMER_GROUP_HK
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
        , BW_REQUEST_ID
        , LOAD_DTS
        , CURRENT_TIMESTAMP()                                          as SNAPSHOT_DTS
        , 'PB_DEMAND_PLAN_CLOSED_BOOK'                                       as PB_REC_SRC
        , CASE BKCC WHEN 'Hiding_Tiger' THEN PSA_DELETE_IND END        as PSA_DELETE_IND
        , SEQ8()                                                       as SEQ_ID
        , CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP )                  as PB_LOAD_DTS
        , REC_SRC
        , BKCC
FROM JOIN_RESULT