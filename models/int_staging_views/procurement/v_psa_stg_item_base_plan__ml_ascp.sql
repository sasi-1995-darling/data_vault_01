---- SRC LAYER ----
WITH
SRC_itmml          as ( SELECT * FROM {{ source('mlc_ascp', 'msc_system_items') }} as SRC  ),
SRC_a              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_itmml          as ( SELECT * FROM mlc_ascp.msc_system_items )
, SRC_a              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_itmml as (
    SELECT
        ITEM_NAME                                                    as                                            ITEM_BK
      , ITEM_NAME
      , PLAN_ID
      , ORGANIZATION_ID
      , INVENTORY_ITEM_ID
      , SR_INSTANCE_ID
      , SR_INVENTORY_ITEM_ID
      , LOTS_EXPIRATION
      , LOT_CONTROL_CODE
      , SHRINKAGE_RATE
      , FIXED_DAYS_SUPPLY
      , FIXED_ORDER_QUANTITY
      , FIXED_LOT_MULTIPLIER
      , MINIMUM_ORDER_QUANTITY
      , MAXIMUM_ORDER_QUANTITY
      , ROUNDING_CONTROL_TYPE
      , PLANNING_TIME_FENCE_DAYS
      , PLANNING_TIME_FENCE_DATE
      , DEMAND_TIME_FENCE_DAYS
      , DEMAND_TIME_FENCE_DATE
      , DESCRIPTION
      , RELEASE_TIME_FENCE_CODE
      , RELEASE_TIME_FENCE_DAYS
      , IN_SOURCE_PLAN
      , REVISION
      , SR_CATEGORY_ID
      , ABC_CLASS
      , CATEGORY_NAME
      , MRP_PLANNING_CODE
      , FIXED_LEAD_TIME
      , VARIABLE_LEAD_TIME
      , PREPROCESSING_LEAD_TIME
      , POSTPROCESSING_LEAD_TIME
      , FULL_LEAD_TIME
      , CUMULATIVE_TOTAL_LEAD_TIME
      , CUM_MANUFACTURING_LEAD_TIME
      , UOM_CODE
      , UNIT_WEIGHT
      , UNIT_VOLUME
      , WEIGHT_UOM
      , VOLUME_UOM
      , PRODUCT_FAMILY_ID
      , ATP_RULE_ID
      , ATP_COMPONENTS_FLAG
      , BUILD_IN_WIP_FLAG
      , PURCHASING_ENABLED_FLAG
      , PLANNING_MAKE_BUY_CODE
      , REPETITIVE_TYPE
      , REPETITIVE_VARIANCE
      , STANDARD_COST
      , CARRYING_COST
      , ORDER_COST
      , MATERIAL_COST
      , DMD_LATENESS_COST
      , RESOURCE_COST
      , SS_PENALTY_COST
      , SUPPLIER_CAP_OVERUTIL_COST
      , LIST_PRICE
      , AVERAGE_DISCOUNT
      , ENGINEERING_ITEM_FLAG
      , WIP_SUPPLY_TYPE
      , SAFETY_STOCK_CODE
      , SAFETY_STOCK_PERCENT
      , SAFETY_STOCK_BUCKET_DAYS
      , INVENTORY_USE_UP_DATE
      , BUYER_NAME
      , PLANNER_CODE
      , PLANNING_EXCEPTION_SET
      , EXCESS_QUANTITY
      , EXCEPTION_SHORTAGE_DAYS
      , EXCEPTION_EXCESS_DAYS
      , EXCEPTION_OVERPROMISED_DAYS
      , EXCEPTION_CODE
      , BOM_ITEM_TYPE
      , ATO_FORECAST_CONTROL
      , EFFECTIVITY_CONTROL
      , ORGANIZATION_CODE
      , ACCEPTABLE_RATE_INCREASE
      , ACCEPTABLE_RATE_DECREASE
      , EXCEPTION_REP_VARIANCE_DAYS
      , OVERRUN_PERCENTAGE
      , INVENTORY_PLANNING_CODE
      , ACCEPTABLE_EARLY_DELIVERY
      , CALCULATE_ATP
      , END_ASSEMBLY_PEGGING_FLAG
      , END_ASSEMBLY_PEGGING
      , FULL_PEGGING
      , INVENTORY_ITEM_FLAG
      , SOURCE_ORG_ID
      , BASE_ITEM_ID
      , ABC_CLASS_NAME
      , FIXED_SAFETY_STOCK_QTY
      , PRIMARY_SUPPLIER_ID
      , ATP_FLAG
      , LOW_LEVEL_CODE
      , PLANNER_STATUS_CODE
      , NETTABLE_INVENTORY_QUANTITY
      , NONNETTABLE_INVENTORY_QUANTITY
      , REFRESH_NUMBER
      , LAST_UPDATE_DATE
      , LAST_UPDATED_BY
      , CREATION_DATE
      , CREATED_BY
      , LAST_UPDATE_LOGIN
      , REQUEST_ID
      , PROGRAM_APPLICATION_ID
      , PROGRAM_ID
      , PROGRAM_UPDATE_DATE
      , ATTRIBUTE_CATEGORY
      , ATTRIBUTE1
      , ATTRIBUTE2
      , ATTRIBUTE3
      , ATTRIBUTE4
      , ATTRIBUTE5
      , ATTRIBUTE6
      , ATTRIBUTE7
      , ATTRIBUTE8
      , ATTRIBUTE9
      , ATTRIBUTE10
      , ATTRIBUTE11
      , ATTRIBUTE12
      , ATTRIBUTE13
      , ATTRIBUTE14
      , ATTRIBUTE15
      , REVISION_QTY_CONTROL_CODE
      , EXPENSE_ACCOUNT
      , INVENTORY_ASSET_FLAG
      , BUYER_ID
      , REPETITIVE_PLANNING_FLAG
      , PICK_COMPONENTS_FLAG
      , SERVICE_LEVEL
      , REPLENISH_TO_ORDER_FLAG
      , PIP_FLAG
      , YIELD_CONV_FACTOR
      , MIN_MINMAX_QUANTITY
      , MAX_MINMAX_QUANTITY
      , NEW_ATP_FLAG
      , SOURCE_TYPE
      , SUBSTITUTION_WINDOW
      , CREATE_SUPPLY_FLAG
      , REORDER_POINT
      , AVERAGE_ANNUAL_DEMAND
      , ECONOMIC_ORDER_QUANTITY
      , SERIAL_NUMBER_CONTROL_CODE
      , CONVERGENCE
      , DIVERGENCE
      , CONTINOUS_TRANSFER
      , CRITICAL_COMPONENT_FLAG
      , REDUCE_MPS
      , CONSIGNED_FLAG
      , VMI_MINIMUM_UNITS
      , VMI_MINIMUM_DAYS
      , VMI_MAXIMUM_UNITS
      , VMI_MAXIMUM_DAYS
      , AVERAGE_DAILY_DEMAND
      , VMI_FIXED_ORDER_QUANTITY
      , SO_AUTHORIZATION_FLAG
      , VMI_FORECAST_TYPE
      , FORECAST_HORIZON
      , ASN_AUTOEXPIRE_FLAG
      , VMI_REFRESH_FLAG
      , BUDGET_CONSTRAINED
      , MAX_QUANTITY
      , MAX_QUANTITY_DOS
      , DAYS_TGT_INV_WINDOW
      , DAYS_MAX_INV_WINDOW
      , DAYS_TGT_INV_SUPPLY
      , DAYS_MAX_INV_SUPPLY
      , DRP_PLANNED
      , AGGREGATE_TIME_FENCE_DATE
      , INFERRED_CRITICAL_FLAG
      , SS_WINDOW_SIZE
      , LOWEST_LEVEL_SRC
      , EAM_ITEM_TYPE
      , LOTS_EXIST
      , LEADTIME_VARIABILITY
      , MIN_SHELF_LIFE_DAYS
      , GROUP_ID
      , REPAIR_YIELD
      , REPAIR_PROGRAM
      , REPAIR_LEAD_TIME
      , PRE_POSITION_INVENTORY
      , PREPOSITION_POINT
      , REPAIR_LEADTIME
      , DEMAND_FULFILLMENT_LT
      , ITEM_CREATION_DATE
      , SHORTAGE_TYPE
      , EXCESS_TYPE
      , PLANNING_TIME_FENCE_CODE
      , PEGGING_DEMAND_WINDOW_DAYS
      , PEGGING_SUPPLY_WINDOW_DAYS
      , FORECAST_RULE_FOR_DEMANDS
      , FORECAST_RULE_FOR_RETURNS
      , DEMAND_DISTRIBUTION
      , INTERARRIVAL_TIME
      , END_OF_LIFE_DATE
      , STD_DMD_OVER_HORIZON
      , LIFE_TIME_BUY_DATE
      , REPAIR_COST
      , CRITICALITY_CATEGORY
      , AVG_DEMAND_BEYOND_PH
      , AVG_RETURNS_BEYOND_PH
      , RETURN_FORECAST_TIME_FENCE
      , DEFECTIVE_ITEM_COST
      , STD_DEVIATION_FOR_DEMAND
      , MEAN_INTER_ARRIVAL
      , STD_DEVIATION_INTER_ARRIVAL
      , INTERARRIVAL_DIST_METHOD
      , BASIS_AVG_DAILY_DEMAND
      , COEFFICIENT_OF_VARIATION
      , STANDARD_DEVIATION
      , LAST_REPLAN_DATE
      , NETCHANGE_REPLAN_FLAG
      , REPLAN_PERIOD
      , SAFETY_LEAD_TIME
      , UNSATISFIED_DEMAND_FACTOR
      , MAX_USAGE_FACTOR
      , MIN_SUP_DEM_PERCENT
      , DMD_SATISFIED_PERCENT
      , NEW_PLAN_ID
      , NEW_PLAN_LIST
      , SIMULATION_SET_ID
      , NO_PL_ORD_BEFORE_WIP_WIN
      , PLANNING_UNITS_OF_WORK
      , EXCESS_HORIZON
      , OBSOLESCENCE_DATE
      , COMPUTE_EOQ
      , COMPUTE_SS
      , ROP_SAFETY_STOCK
      , CONSIDER_IN_CTB_FLAG
      , CALCULATE_CTB_FLAG
      , CTB_KPI_HORIZON
      , APPLIED
      , INTERMITTENT_DEMAND
      , COMP_SUBSTITUTION_FLAG
      , CONSUME_BEF_PRIMARY_FLAG
      , REPAIR_MODULE
      , SCRAP_RATE
      , REBUILD_ACTIVITY
      , ORDER_PERIOD
      , INV_DAYS_INCREMENT
      , AVERAGE_CYCLE_STOCK
      , IS_MODIFIED
      , ADS_CALC_DAYS
      , SAFETY_STOCK_MRSL
      , MRSL_INGREDIENT
      , MRSL_INGREDIENT_ID
      , ANNUAL_SALES_QTY
      , ANNUAL_SALES_COUNT
      , ANNUAL_SALES_VALUE
      , ANNUAL_SHIP_QTY
      , ANNUAL_SHIP_COUNT
      , ANNUAL_SHIP_VALUE
      , DEMAND_VARIANCE
      , INVENTORY_POLICY
      , POLICY_UOM
      , MIN_UNITS
      , MAX_UNITS
      , MIN_DAYS
      , MAX_DAYS
      , ANNUAL_ORDER_CNT
      , ORDER_CYCLE_CAL
      , FCST_ERROR
      , PM_SNAPSHOT_DATE
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , CONVERT_TIMEZONE('UTC',PM_SNAPSHOT_DATE)                     as                                           LOAD_DTS
    FROM SRC_itmml
)

, LOGIC_a as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_a
)
---- RENAME LAYER ----

, RENAME_itmml as (
    SELECT
        ITEM_BK
      , ITEM_NAME
      , PLAN_ID
      , ORGANIZATION_ID
      , INVENTORY_ITEM_ID
      , SR_INSTANCE_ID
      , SR_INVENTORY_ITEM_ID
      , LOTS_EXPIRATION
      , LOT_CONTROL_CODE
      , SHRINKAGE_RATE
      , FIXED_DAYS_SUPPLY
      , FIXED_ORDER_QUANTITY
      , FIXED_LOT_MULTIPLIER
      , MINIMUM_ORDER_QUANTITY
      , MAXIMUM_ORDER_QUANTITY
      , ROUNDING_CONTROL_TYPE
      , PLANNING_TIME_FENCE_DAYS
      , PLANNING_TIME_FENCE_DATE
      , DEMAND_TIME_FENCE_DAYS
      , DEMAND_TIME_FENCE_DATE
      , DESCRIPTION
      , RELEASE_TIME_FENCE_CODE
      , RELEASE_TIME_FENCE_DAYS
      , IN_SOURCE_PLAN
      , REVISION
      , SR_CATEGORY_ID
      , ABC_CLASS
      , CATEGORY_NAME
      , MRP_PLANNING_CODE
      , FIXED_LEAD_TIME
      , VARIABLE_LEAD_TIME
      , PREPROCESSING_LEAD_TIME
      , POSTPROCESSING_LEAD_TIME
      , FULL_LEAD_TIME
      , CUMULATIVE_TOTAL_LEAD_TIME
      , CUM_MANUFACTURING_LEAD_TIME
      , UOM_CODE
      , UNIT_WEIGHT
      , UNIT_VOLUME
      , WEIGHT_UOM
      , VOLUME_UOM
      , PRODUCT_FAMILY_ID
      , ATP_RULE_ID
      , ATP_COMPONENTS_FLAG
      , BUILD_IN_WIP_FLAG
      , PURCHASING_ENABLED_FLAG
      , PLANNING_MAKE_BUY_CODE
      , REPETITIVE_TYPE
      , REPETITIVE_VARIANCE
      , STANDARD_COST
      , CARRYING_COST
      , ORDER_COST
      , MATERIAL_COST
      , DMD_LATENESS_COST
      , RESOURCE_COST
      , SS_PENALTY_COST
      , SUPPLIER_CAP_OVERUTIL_COST
      , LIST_PRICE
      , AVERAGE_DISCOUNT
      , ENGINEERING_ITEM_FLAG
      , WIP_SUPPLY_TYPE
      , SAFETY_STOCK_CODE
      , SAFETY_STOCK_PERCENT
      , SAFETY_STOCK_BUCKET_DAYS
      , INVENTORY_USE_UP_DATE
      , BUYER_NAME
      , PLANNER_CODE
      , PLANNING_EXCEPTION_SET
      , EXCESS_QUANTITY
      , EXCEPTION_SHORTAGE_DAYS
      , EXCEPTION_EXCESS_DAYS
      , EXCEPTION_OVERPROMISED_DAYS
      , EXCEPTION_CODE
      , BOM_ITEM_TYPE
      , ATO_FORECAST_CONTROL
      , EFFECTIVITY_CONTROL
      , ORGANIZATION_CODE
      , ACCEPTABLE_RATE_INCREASE
      , ACCEPTABLE_RATE_DECREASE
      , EXCEPTION_REP_VARIANCE_DAYS
      , OVERRUN_PERCENTAGE
      , INVENTORY_PLANNING_CODE
      , ACCEPTABLE_EARLY_DELIVERY
      , CALCULATE_ATP
      , END_ASSEMBLY_PEGGING_FLAG
      , END_ASSEMBLY_PEGGING
      , FULL_PEGGING
      , INVENTORY_ITEM_FLAG
      , SOURCE_ORG_ID
      , BASE_ITEM_ID
      , ABC_CLASS_NAME
      , FIXED_SAFETY_STOCK_QTY
      , PRIMARY_SUPPLIER_ID
      , ATP_FLAG
      , LOW_LEVEL_CODE
      , PLANNER_STATUS_CODE
      , NETTABLE_INVENTORY_QUANTITY
      , NONNETTABLE_INVENTORY_QUANTITY
      , REFRESH_NUMBER
      , LAST_UPDATE_DATE
      , LAST_UPDATED_BY
      , CREATION_DATE
      , CREATED_BY
      , LAST_UPDATE_LOGIN
      , REQUEST_ID
      , PROGRAM_APPLICATION_ID
      , PROGRAM_ID
      , PROGRAM_UPDATE_DATE
      , ATTRIBUTE_CATEGORY
      , ATTRIBUTE1
      , ATTRIBUTE2
      , ATTRIBUTE3
      , ATTRIBUTE4
      , ATTRIBUTE5
      , ATTRIBUTE6
      , ATTRIBUTE7
      , ATTRIBUTE8
      , ATTRIBUTE9
      , ATTRIBUTE10
      , ATTRIBUTE11
      , ATTRIBUTE12
      , ATTRIBUTE13
      , ATTRIBUTE14
      , ATTRIBUTE15
      , REVISION_QTY_CONTROL_CODE
      , EXPENSE_ACCOUNT
      , INVENTORY_ASSET_FLAG
      , BUYER_ID
      , REPETITIVE_PLANNING_FLAG
      , PICK_COMPONENTS_FLAG
      , SERVICE_LEVEL
      , REPLENISH_TO_ORDER_FLAG
      , PIP_FLAG
      , YIELD_CONV_FACTOR
      , MIN_MINMAX_QUANTITY
      , MAX_MINMAX_QUANTITY
      , NEW_ATP_FLAG
      , SOURCE_TYPE
      , SUBSTITUTION_WINDOW
      , CREATE_SUPPLY_FLAG
      , REORDER_POINT
      , AVERAGE_ANNUAL_DEMAND
      , ECONOMIC_ORDER_QUANTITY
      , SERIAL_NUMBER_CONTROL_CODE
      , CONVERGENCE
      , DIVERGENCE
      , CONTINOUS_TRANSFER
      , CRITICAL_COMPONENT_FLAG
      , REDUCE_MPS
      , CONSIGNED_FLAG
      , VMI_MINIMUM_UNITS
      , VMI_MINIMUM_DAYS
      , VMI_MAXIMUM_UNITS
      , VMI_MAXIMUM_DAYS
      , AVERAGE_DAILY_DEMAND
      , VMI_FIXED_ORDER_QUANTITY
      , SO_AUTHORIZATION_FLAG
      , VMI_FORECAST_TYPE
      , FORECAST_HORIZON
      , ASN_AUTOEXPIRE_FLAG
      , VMI_REFRESH_FLAG
      , BUDGET_CONSTRAINED
      , MAX_QUANTITY
      , MAX_QUANTITY_DOS
      , DAYS_TGT_INV_WINDOW
      , DAYS_MAX_INV_WINDOW
      , DAYS_TGT_INV_SUPPLY
      , DAYS_MAX_INV_SUPPLY
      , DRP_PLANNED
      , AGGREGATE_TIME_FENCE_DATE
      , INFERRED_CRITICAL_FLAG
      , SS_WINDOW_SIZE
      , LOWEST_LEVEL_SRC
      , EAM_ITEM_TYPE
      , LOTS_EXIST
      , LEADTIME_VARIABILITY
      , MIN_SHELF_LIFE_DAYS
      , GROUP_ID
      , REPAIR_YIELD
      , REPAIR_PROGRAM
      , REPAIR_LEAD_TIME
      , PRE_POSITION_INVENTORY
      , PREPOSITION_POINT
      , REPAIR_LEADTIME
      , DEMAND_FULFILLMENT_LT
      , ITEM_CREATION_DATE
      , SHORTAGE_TYPE
      , EXCESS_TYPE
      , PLANNING_TIME_FENCE_CODE
      , PEGGING_DEMAND_WINDOW_DAYS
      , PEGGING_SUPPLY_WINDOW_DAYS
      , FORECAST_RULE_FOR_DEMANDS
      , FORECAST_RULE_FOR_RETURNS
      , DEMAND_DISTRIBUTION
      , INTERARRIVAL_TIME
      , END_OF_LIFE_DATE
      , STD_DMD_OVER_HORIZON
      , LIFE_TIME_BUY_DATE
      , REPAIR_COST
      , CRITICALITY_CATEGORY
      , AVG_DEMAND_BEYOND_PH
      , AVG_RETURNS_BEYOND_PH
      , RETURN_FORECAST_TIME_FENCE
      , DEFECTIVE_ITEM_COST
      , STD_DEVIATION_FOR_DEMAND
      , MEAN_INTER_ARRIVAL
      , STD_DEVIATION_INTER_ARRIVAL
      , INTERARRIVAL_DIST_METHOD
      , BASIS_AVG_DAILY_DEMAND
      , COEFFICIENT_OF_VARIATION
      , STANDARD_DEVIATION
      , LAST_REPLAN_DATE
      , NETCHANGE_REPLAN_FLAG
      , REPLAN_PERIOD
      , SAFETY_LEAD_TIME
      , UNSATISFIED_DEMAND_FACTOR
      , MAX_USAGE_FACTOR
      , MIN_SUP_DEM_PERCENT
      , DMD_SATISFIED_PERCENT
      , NEW_PLAN_ID
      , NEW_PLAN_LIST
      , SIMULATION_SET_ID
      , NO_PL_ORD_BEFORE_WIP_WIN
      , PLANNING_UNITS_OF_WORK
      , EXCESS_HORIZON
      , OBSOLESCENCE_DATE
      , COMPUTE_EOQ
      , COMPUTE_SS
      , ROP_SAFETY_STOCK
      , CONSIDER_IN_CTB_FLAG
      , CALCULATE_CTB_FLAG
      , CTB_KPI_HORIZON
      , APPLIED
      , INTERMITTENT_DEMAND
      , COMP_SUBSTITUTION_FLAG
      , CONSUME_BEF_PRIMARY_FLAG
      , REPAIR_MODULE
      , SCRAP_RATE
      , REBUILD_ACTIVITY
      , ORDER_PERIOD
      , INV_DAYS_INCREMENT
      , AVERAGE_CYCLE_STOCK
      , IS_MODIFIED
      , ADS_CALC_DAYS
      , SAFETY_STOCK_MRSL
      , MRSL_INGREDIENT
      , MRSL_INGREDIENT_ID
      , ANNUAL_SALES_QTY
      , ANNUAL_SALES_COUNT
      , ANNUAL_SALES_VALUE
      , ANNUAL_SHIP_QTY
      , ANNUAL_SHIP_COUNT
      , ANNUAL_SHIP_VALUE
      , DEMAND_VARIANCE
      , INVENTORY_POLICY
      , POLICY_UOM
      , MIN_UNITS
      , MAX_UNITS
      , MIN_DAYS
      , MAX_DAYS
      , ANNUAL_ORDER_CNT
      , ORDER_CYCLE_CAL
      , FCST_ERROR
      , PM_SNAPSHOT_DATE
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
    FROM LOGIC_itmml
)

, RENAME_a as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_a
)
---- FILTER LAYER ----

, FILTER_itmml as (
    SELECT *
    FROM RENAME_itmml
)

, FILTER_a as (
    SELECT *
    FROM RENAME_a
    WHERE rec_src = 'USWIOC.ORCL.ASCPPRD.MSC_SYSTEM_ITEMS'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_itmml
    INNER JOIN FILTER_a
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          ITEM_BK
        , ITEM_NAME
        , PLAN_ID
        , ORGANIZATION_ID
        , INVENTORY_ITEM_ID
        , SR_INSTANCE_ID
        , SR_INVENTORY_ITEM_ID
        , LOTS_EXPIRATION
        , LOT_CONTROL_CODE
        , SHRINKAGE_RATE
        , FIXED_DAYS_SUPPLY
        , FIXED_ORDER_QUANTITY
        , FIXED_LOT_MULTIPLIER
        , MINIMUM_ORDER_QUANTITY
        , MAXIMUM_ORDER_QUANTITY
        , ROUNDING_CONTROL_TYPE
        , PLANNING_TIME_FENCE_DAYS
        , PLANNING_TIME_FENCE_DATE
        , DEMAND_TIME_FENCE_DAYS
        , DEMAND_TIME_FENCE_DATE
        , DESCRIPTION
        , RELEASE_TIME_FENCE_CODE
        , RELEASE_TIME_FENCE_DAYS
        , IN_SOURCE_PLAN
        , REVISION
        , SR_CATEGORY_ID
        , ABC_CLASS
        , CATEGORY_NAME
        , MRP_PLANNING_CODE
        , FIXED_LEAD_TIME
        , VARIABLE_LEAD_TIME
        , PREPROCESSING_LEAD_TIME
        , POSTPROCESSING_LEAD_TIME
        , FULL_LEAD_TIME
        , CUMULATIVE_TOTAL_LEAD_TIME
        , CUM_MANUFACTURING_LEAD_TIME
        , UOM_CODE
        , UNIT_WEIGHT
        , UNIT_VOLUME
        , WEIGHT_UOM
        , VOLUME_UOM
        , PRODUCT_FAMILY_ID
        , ATP_RULE_ID
        , ATP_COMPONENTS_FLAG
        , BUILD_IN_WIP_FLAG
        , PURCHASING_ENABLED_FLAG
        , PLANNING_MAKE_BUY_CODE
        , REPETITIVE_TYPE
        , REPETITIVE_VARIANCE
        , STANDARD_COST
        , CARRYING_COST
        , ORDER_COST
        , MATERIAL_COST
        , DMD_LATENESS_COST
        , RESOURCE_COST
        , SS_PENALTY_COST
        , SUPPLIER_CAP_OVERUTIL_COST
        , LIST_PRICE
        , AVERAGE_DISCOUNT
        , ENGINEERING_ITEM_FLAG
        , WIP_SUPPLY_TYPE
        , SAFETY_STOCK_CODE
        , SAFETY_STOCK_PERCENT
        , SAFETY_STOCK_BUCKET_DAYS
        , INVENTORY_USE_UP_DATE
        , BUYER_NAME
        , PLANNER_CODE
        , PLANNING_EXCEPTION_SET
        , EXCESS_QUANTITY
        , EXCEPTION_SHORTAGE_DAYS
        , EXCEPTION_EXCESS_DAYS
        , EXCEPTION_OVERPROMISED_DAYS
        , EXCEPTION_CODE
        , BOM_ITEM_TYPE
        , ATO_FORECAST_CONTROL
        , EFFECTIVITY_CONTROL
        , ORGANIZATION_CODE
        , ACCEPTABLE_RATE_INCREASE
        , ACCEPTABLE_RATE_DECREASE
        , EXCEPTION_REP_VARIANCE_DAYS
        , OVERRUN_PERCENTAGE
        , INVENTORY_PLANNING_CODE
        , ACCEPTABLE_EARLY_DELIVERY
        , CALCULATE_ATP
        , END_ASSEMBLY_PEGGING_FLAG
        , END_ASSEMBLY_PEGGING
        , FULL_PEGGING
        , INVENTORY_ITEM_FLAG
        , SOURCE_ORG_ID
        , BASE_ITEM_ID
        , ABC_CLASS_NAME
        , FIXED_SAFETY_STOCK_QTY
        , PRIMARY_SUPPLIER_ID
        , ATP_FLAG
        , LOW_LEVEL_CODE
        , PLANNER_STATUS_CODE
        , NETTABLE_INVENTORY_QUANTITY
        , NONNETTABLE_INVENTORY_QUANTITY
        , REFRESH_NUMBER
        , LAST_UPDATE_DATE
        , LAST_UPDATED_BY
        , CREATION_DATE
        , CREATED_BY
        , LAST_UPDATE_LOGIN
        , REQUEST_ID
        , PROGRAM_APPLICATION_ID
        , PROGRAM_ID
        , PROGRAM_UPDATE_DATE
        , ATTRIBUTE_CATEGORY
        , ATTRIBUTE1
        , ATTRIBUTE2
        , ATTRIBUTE3
        , ATTRIBUTE4
        , ATTRIBUTE5
        , ATTRIBUTE6
        , ATTRIBUTE7
        , ATTRIBUTE8
        , ATTRIBUTE9
        , ATTRIBUTE10
        , ATTRIBUTE11
        , ATTRIBUTE12
        , ATTRIBUTE13
        , ATTRIBUTE14
        , ATTRIBUTE15
        , REVISION_QTY_CONTROL_CODE
        , EXPENSE_ACCOUNT
        , INVENTORY_ASSET_FLAG
        , BUYER_ID
        , REPETITIVE_PLANNING_FLAG
        , PICK_COMPONENTS_FLAG
        , SERVICE_LEVEL
        , REPLENISH_TO_ORDER_FLAG
        , PIP_FLAG
        , YIELD_CONV_FACTOR
        , MIN_MINMAX_QUANTITY
        , MAX_MINMAX_QUANTITY
        , NEW_ATP_FLAG
        , SOURCE_TYPE
        , SUBSTITUTION_WINDOW
        , CREATE_SUPPLY_FLAG
        , REORDER_POINT
        , AVERAGE_ANNUAL_DEMAND
        , ECONOMIC_ORDER_QUANTITY
        , SERIAL_NUMBER_CONTROL_CODE
        , CONVERGENCE
        , DIVERGENCE
        , CONTINOUS_TRANSFER
        , CRITICAL_COMPONENT_FLAG
        , REDUCE_MPS
        , CONSIGNED_FLAG
        , VMI_MINIMUM_UNITS
        , VMI_MINIMUM_DAYS
        , VMI_MAXIMUM_UNITS
        , VMI_MAXIMUM_DAYS
        , AVERAGE_DAILY_DEMAND
        , VMI_FIXED_ORDER_QUANTITY
        , SO_AUTHORIZATION_FLAG
        , VMI_FORECAST_TYPE
        , FORECAST_HORIZON
        , ASN_AUTOEXPIRE_FLAG
        , VMI_REFRESH_FLAG
        , BUDGET_CONSTRAINED
        , MAX_QUANTITY
        , MAX_QUANTITY_DOS
        , DAYS_TGT_INV_WINDOW
        , DAYS_MAX_INV_WINDOW
        , DAYS_TGT_INV_SUPPLY
        , DAYS_MAX_INV_SUPPLY
        , DRP_PLANNED
        , AGGREGATE_TIME_FENCE_DATE
        , INFERRED_CRITICAL_FLAG
        , SS_WINDOW_SIZE
        , LOWEST_LEVEL_SRC
        , EAM_ITEM_TYPE
        , LOTS_EXIST
        , LEADTIME_VARIABILITY
        , MIN_SHELF_LIFE_DAYS
        , GROUP_ID
        , REPAIR_YIELD
        , REPAIR_PROGRAM
        , REPAIR_LEAD_TIME
        , PRE_POSITION_INVENTORY
        , PREPOSITION_POINT
        , REPAIR_LEADTIME
        , DEMAND_FULFILLMENT_LT
        , ITEM_CREATION_DATE
        , SHORTAGE_TYPE
        , EXCESS_TYPE
        , PLANNING_TIME_FENCE_CODE
        , PEGGING_DEMAND_WINDOW_DAYS
        , PEGGING_SUPPLY_WINDOW_DAYS
        , FORECAST_RULE_FOR_DEMANDS
        , FORECAST_RULE_FOR_RETURNS
        , DEMAND_DISTRIBUTION
        , INTERARRIVAL_TIME
        , END_OF_LIFE_DATE
        , STD_DMD_OVER_HORIZON
        , LIFE_TIME_BUY_DATE
        , REPAIR_COST
        , CRITICALITY_CATEGORY
        , AVG_DEMAND_BEYOND_PH
        , AVG_RETURNS_BEYOND_PH
        , RETURN_FORECAST_TIME_FENCE
        , DEFECTIVE_ITEM_COST
        , STD_DEVIATION_FOR_DEMAND
        , MEAN_INTER_ARRIVAL
        , STD_DEVIATION_INTER_ARRIVAL
        , INTERARRIVAL_DIST_METHOD
        , BASIS_AVG_DAILY_DEMAND
        , COEFFICIENT_OF_VARIATION
        , STANDARD_DEVIATION
        , LAST_REPLAN_DATE
        , NETCHANGE_REPLAN_FLAG
        , REPLAN_PERIOD
        , SAFETY_LEAD_TIME
        , UNSATISFIED_DEMAND_FACTOR
        , MAX_USAGE_FACTOR
        , MIN_SUP_DEM_PERCENT
        , DMD_SATISFIED_PERCENT
        , NEW_PLAN_ID
        , NEW_PLAN_LIST
        , SIMULATION_SET_ID
        , NO_PL_ORD_BEFORE_WIP_WIN
        , PLANNING_UNITS_OF_WORK
        , EXCESS_HORIZON
        , OBSOLESCENCE_DATE
        , COMPUTE_EOQ
        , COMPUTE_SS
        , ROP_SAFETY_STOCK
        , CONSIDER_IN_CTB_FLAG
        , CALCULATE_CTB_FLAG
        , CTB_KPI_HORIZON
        , APPLIED
        , INTERMITTENT_DEMAND
        , COMP_SUBSTITUTION_FLAG
        , CONSUME_BEF_PRIMARY_FLAG
        , REPAIR_MODULE
        , SCRAP_RATE
        , REBUILD_ACTIVITY
        , ORDER_PERIOD
        , INV_DAYS_INCREMENT
        , AVERAGE_CYCLE_STOCK
        , IS_MODIFIED
        , ADS_CALC_DAYS
        , SAFETY_STOCK_MRSL
        , MRSL_INGREDIENT
        , MRSL_INGREDIENT_ID
        , ANNUAL_SALES_QTY
        , ANNUAL_SALES_COUNT
        , ANNUAL_SALES_VALUE
        , ANNUAL_SHIP_QTY
        , ANNUAL_SHIP_COUNT
        , ANNUAL_SHIP_VALUE
        , DEMAND_VARIANCE
        , INVENTORY_POLICY
        , POLICY_UOM
        , MIN_UNITS
        , MAX_UNITS
        , MIN_DAYS
        , MAX_DAYS
        , ANNUAL_ORDER_CNT
        , ORDER_CYCLE_CAL
        , FCST_ERROR
        , PM_SNAPSHOT_DATE
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ITEM_NAME as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ITEM_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(SR_INSTANCE_ID::text), '^^') 
            , '||', IFNULL(TRIM(SR_INVENTORY_ITEM_ID::text), '^^') 
            , '||', IFNULL(TRIM(LOTS_EXPIRATION::text), '^^') 
            , '||', IFNULL(TRIM(LOT_CONTROL_CODE::text), '^^') 
            , '||', IFNULL(TRIM(SHRINKAGE_RATE::text), '^^') 
            , '||', IFNULL(TRIM(FIXED_DAYS_SUPPLY::text), '^^') 
            , '||', IFNULL(TRIM(FIXED_ORDER_QUANTITY::text), '^^') 
            , '||', IFNULL(TRIM(FIXED_LOT_MULTIPLIER::text), '^^') 
            , '||', IFNULL(TRIM(MINIMUM_ORDER_QUANTITY::text), '^^') 
            , '||', IFNULL(TRIM(MAXIMUM_ORDER_QUANTITY::text), '^^') 
            , '||', IFNULL(TRIM(ROUNDING_CONTROL_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(PLANNING_TIME_FENCE_DAYS::text), '^^') 
            , '||', IFNULL(TRIM(PLANNING_TIME_FENCE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(DEMAND_TIME_FENCE_DAYS::text), '^^') 
            , '||', IFNULL(TRIM(DEMAND_TIME_FENCE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(DESCRIPTION::text), '^^') 
            , '||', IFNULL(TRIM(RELEASE_TIME_FENCE_CODE::text), '^^') 
            , '||', IFNULL(TRIM(RELEASE_TIME_FENCE_DAYS::text), '^^') 
            , '||', IFNULL(TRIM(IN_SOURCE_PLAN::text), '^^') 
            , '||', IFNULL(TRIM(REVISION::text), '^^') 
            , '||', IFNULL(TRIM(SR_CATEGORY_ID::text), '^^') 
            , '||', IFNULL(TRIM(ABC_CLASS::text), '^^') 
            , '||', IFNULL(TRIM(CATEGORY_NAME::text), '^^') 
            , '||', IFNULL(TRIM(MRP_PLANNING_CODE::text), '^^') 
            , '||', IFNULL(TRIM(FIXED_LEAD_TIME::text), '^^') 
            , '||', IFNULL(TRIM(VARIABLE_LEAD_TIME::text), '^^') 
            , '||', IFNULL(TRIM(PREPROCESSING_LEAD_TIME::text), '^^') 
            , '||', IFNULL(TRIM(POSTPROCESSING_LEAD_TIME::text), '^^') 
            , '||', IFNULL(TRIM(FULL_LEAD_TIME::text), '^^') 
            , '||', IFNULL(TRIM(CUMULATIVE_TOTAL_LEAD_TIME::text), '^^') 
            , '||', IFNULL(TRIM(CUM_MANUFACTURING_LEAD_TIME::text), '^^') 
            , '||', IFNULL(TRIM(UOM_CODE::text), '^^') 
            , '||', IFNULL(TRIM(UNIT_WEIGHT::text), '^^') 
            , '||', IFNULL(TRIM(UNIT_VOLUME::text), '^^') 
            , '||', IFNULL(TRIM(WEIGHT_UOM::text), '^^') 
            , '||', IFNULL(TRIM(VOLUME_UOM::text), '^^') 
            , '||', IFNULL(TRIM(PRODUCT_FAMILY_ID::text), '^^') 
            , '||', IFNULL(TRIM(ATP_RULE_ID::text), '^^') 
            , '||', IFNULL(TRIM(ATP_COMPONENTS_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(BUILD_IN_WIP_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(PURCHASING_ENABLED_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(PLANNING_MAKE_BUY_CODE::text), '^^') 
            , '||', IFNULL(TRIM(REPETITIVE_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(REPETITIVE_VARIANCE::text), '^^') 
            , '||', IFNULL(TRIM(STANDARD_COST::text), '^^') 
            , '||', IFNULL(TRIM(CARRYING_COST::text), '^^') 
            , '||', IFNULL(TRIM(ORDER_COST::text), '^^') 
            , '||', IFNULL(TRIM(MATERIAL_COST::text), '^^') 
            , '||', IFNULL(TRIM(DMD_LATENESS_COST::text), '^^') 
            , '||', IFNULL(TRIM(RESOURCE_COST::text), '^^') 
            , '||', IFNULL(TRIM(SS_PENALTY_COST::text), '^^') 
            , '||', IFNULL(TRIM(SUPPLIER_CAP_OVERUTIL_COST::text), '^^') 
            , '||', IFNULL(TRIM(LIST_PRICE::text), '^^') 
            , '||', IFNULL(TRIM(AVERAGE_DISCOUNT::text), '^^') 
            , '||', IFNULL(TRIM(ENGINEERING_ITEM_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(WIP_SUPPLY_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(SAFETY_STOCK_CODE::text), '^^') 
            , '||', IFNULL(TRIM(SAFETY_STOCK_PERCENT::text), '^^') 
            , '||', IFNULL(TRIM(SAFETY_STOCK_BUCKET_DAYS::text), '^^') 
            , '||', IFNULL(TRIM(INVENTORY_USE_UP_DATE::text), '^^') 
            , '||', IFNULL(TRIM(BUYER_NAME::text), '^^') 
            , '||', IFNULL(TRIM(PLANNER_CODE::text), '^^') 
            , '||', IFNULL(TRIM(PLANNING_EXCEPTION_SET::text), '^^') 
            , '||', IFNULL(TRIM(EXCESS_QUANTITY::text), '^^') 
            , '||', IFNULL(TRIM(EXCEPTION_SHORTAGE_DAYS::text), '^^') 
            , '||', IFNULL(TRIM(EXCEPTION_EXCESS_DAYS::text), '^^') 
            , '||', IFNULL(TRIM(EXCEPTION_OVERPROMISED_DAYS::text), '^^') 
            , '||', IFNULL(TRIM(EXCEPTION_CODE::text), '^^') 
            , '||', IFNULL(TRIM(BOM_ITEM_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(ATO_FORECAST_CONTROL::text), '^^') 
            , '||', IFNULL(TRIM(EFFECTIVITY_CONTROL::text), '^^') 
            , '||', IFNULL(TRIM(ORGANIZATION_CODE::text), '^^') 
            , '||', IFNULL(TRIM(ACCEPTABLE_RATE_INCREASE::text), '^^') 
            , '||', IFNULL(TRIM(ACCEPTABLE_RATE_DECREASE::text), '^^') 
            , '||', IFNULL(TRIM(EXCEPTION_REP_VARIANCE_DAYS::text), '^^') 
            , '||', IFNULL(TRIM(OVERRUN_PERCENTAGE::text), '^^') 
            , '||', IFNULL(TRIM(INVENTORY_PLANNING_CODE::text), '^^') 
            , '||', IFNULL(TRIM(ACCEPTABLE_EARLY_DELIVERY::text), '^^') 
            , '||', IFNULL(TRIM(CALCULATE_ATP::text), '^^') 
            , '||', IFNULL(TRIM(END_ASSEMBLY_PEGGING_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(END_ASSEMBLY_PEGGING::text), '^^') 
            , '||', IFNULL(TRIM(FULL_PEGGING::text), '^^') 
            , '||', IFNULL(TRIM(INVENTORY_ITEM_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(SOURCE_ORG_ID::text), '^^') 
            , '||', IFNULL(TRIM(BASE_ITEM_ID::text), '^^') 
            , '||', IFNULL(TRIM(ABC_CLASS_NAME::text), '^^') 
            , '||', IFNULL(TRIM(FIXED_SAFETY_STOCK_QTY::text), '^^') 
            , '||', IFNULL(TRIM(PRIMARY_SUPPLIER_ID::text), '^^') 
            , '||', IFNULL(TRIM(ATP_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(LOW_LEVEL_CODE::text), '^^') 
            , '||', IFNULL(TRIM(PLANNER_STATUS_CODE::text), '^^') 
            , '||', IFNULL(TRIM(NETTABLE_INVENTORY_QUANTITY::text), '^^') 
            , '||', IFNULL(TRIM(NONNETTABLE_INVENTORY_QUANTITY::text), '^^') 
            , '||', IFNULL(TRIM(REFRESH_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(CREATION_DATE::text), '^^') 
            , '||', IFNULL(TRIM(CREATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_LOGIN::text), '^^') 
            , '||', IFNULL(TRIM(REQUEST_ID::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_APPLICATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_ID::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_UPDATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE1::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE2::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE3::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE4::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE5::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE6::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE7::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE8::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE9::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE10::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE11::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE12::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE13::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE14::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE15::text), '^^') 
            , '||', IFNULL(TRIM(REVISION_QTY_CONTROL_CODE::text), '^^') 
            , '||', IFNULL(TRIM(EXPENSE_ACCOUNT::text), '^^') 
            , '||', IFNULL(TRIM(INVENTORY_ASSET_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(BUYER_ID::text), '^^') 
            , '||', IFNULL(TRIM(REPETITIVE_PLANNING_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(PICK_COMPONENTS_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(SERVICE_LEVEL::text), '^^') 
            , '||', IFNULL(TRIM(REPLENISH_TO_ORDER_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(PIP_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(YIELD_CONV_FACTOR::text), '^^') 
            , '||', IFNULL(TRIM(MIN_MINMAX_QUANTITY::text), '^^') 
            , '||', IFNULL(TRIM(MAX_MINMAX_QUANTITY::text), '^^') 
            , '||', IFNULL(TRIM(NEW_ATP_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(SOURCE_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(SUBSTITUTION_WINDOW::text), '^^') 
            , '||', IFNULL(TRIM(CREATE_SUPPLY_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(REORDER_POINT::text), '^^') 
            , '||', IFNULL(TRIM(AVERAGE_ANNUAL_DEMAND::text), '^^') 
            , '||', IFNULL(TRIM(ECONOMIC_ORDER_QUANTITY::text), '^^') 
            , '||', IFNULL(TRIM(SERIAL_NUMBER_CONTROL_CODE::text), '^^') 
            , '||', IFNULL(TRIM(CONVERGENCE::text), '^^') 
            , '||', IFNULL(TRIM(DIVERGENCE::text), '^^') 
            , '||', IFNULL(TRIM(CONTINOUS_TRANSFER::text), '^^') 
            , '||', IFNULL(TRIM(CRITICAL_COMPONENT_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(REDUCE_MPS::text), '^^') 
            , '||', IFNULL(TRIM(CONSIGNED_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(VMI_MINIMUM_UNITS::text), '^^') 
            , '||', IFNULL(TRIM(VMI_MINIMUM_DAYS::text), '^^') 
            , '||', IFNULL(TRIM(VMI_MAXIMUM_UNITS::text), '^^') 
            , '||', IFNULL(TRIM(VMI_MAXIMUM_DAYS::text), '^^') 
            , '||', IFNULL(TRIM(AVERAGE_DAILY_DEMAND::text), '^^') 
            , '||', IFNULL(TRIM(VMI_FIXED_ORDER_QUANTITY::text), '^^') 
            , '||', IFNULL(TRIM(SO_AUTHORIZATION_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(VMI_FORECAST_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(FORECAST_HORIZON::text), '^^') 
            , '||', IFNULL(TRIM(ASN_AUTOEXPIRE_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(VMI_REFRESH_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(BUDGET_CONSTRAINED::text), '^^') 
            , '||', IFNULL(TRIM(MAX_QUANTITY::text), '^^') 
            , '||', IFNULL(TRIM(MAX_QUANTITY_DOS::text), '^^') 
            , '||', IFNULL(TRIM(DAYS_TGT_INV_WINDOW::text), '^^') 
            , '||', IFNULL(TRIM(DAYS_MAX_INV_WINDOW::text), '^^') 
            , '||', IFNULL(TRIM(DAYS_TGT_INV_SUPPLY::text), '^^') 
            , '||', IFNULL(TRIM(DAYS_MAX_INV_SUPPLY::text), '^^') 
            , '||', IFNULL(TRIM(DRP_PLANNED::text), '^^') 
            , '||', IFNULL(TRIM(AGGREGATE_TIME_FENCE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(INFERRED_CRITICAL_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(SS_WINDOW_SIZE::text), '^^') 
            , '||', IFNULL(TRIM(LOWEST_LEVEL_SRC::text), '^^') 
            , '||', IFNULL(TRIM(EAM_ITEM_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(LOTS_EXIST::text), '^^') 
            , '||', IFNULL(TRIM(LEADTIME_VARIABILITY::text), '^^') 
            , '||', IFNULL(TRIM(MIN_SHELF_LIFE_DAYS::text), '^^') 
            , '||', IFNULL(TRIM(GROUP_ID::text), '^^') 
            , '||', IFNULL(TRIM(REPAIR_YIELD::text), '^^') 
            , '||', IFNULL(TRIM(REPAIR_PROGRAM::text), '^^') 
            , '||', IFNULL(TRIM(REPAIR_LEAD_TIME::text), '^^') 
            , '||', IFNULL(TRIM(PRE_POSITION_INVENTORY::text), '^^') 
            , '||', IFNULL(TRIM(PREPOSITION_POINT::text), '^^') 
            , '||', IFNULL(TRIM(REPAIR_LEADTIME::text), '^^') 
            , '||', IFNULL(TRIM(DEMAND_FULFILLMENT_LT::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_CREATION_DATE::text), '^^') 
            , '||', IFNULL(TRIM(SHORTAGE_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(EXCESS_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(PLANNING_TIME_FENCE_CODE::text), '^^') 
            , '||', IFNULL(TRIM(PEGGING_DEMAND_WINDOW_DAYS::text), '^^') 
            , '||', IFNULL(TRIM(PEGGING_SUPPLY_WINDOW_DAYS::text), '^^') 
            , '||', IFNULL(TRIM(FORECAST_RULE_FOR_DEMANDS::text), '^^') 
            , '||', IFNULL(TRIM(FORECAST_RULE_FOR_RETURNS::text), '^^') 
            , '||', IFNULL(TRIM(DEMAND_DISTRIBUTION::text), '^^') 
            , '||', IFNULL(TRIM(INTERARRIVAL_TIME::text), '^^') 
            , '||', IFNULL(TRIM(END_OF_LIFE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(STD_DMD_OVER_HORIZON::text), '^^') 
            , '||', IFNULL(TRIM(LIFE_TIME_BUY_DATE::text), '^^') 
            , '||', IFNULL(TRIM(REPAIR_COST::text), '^^') 
            , '||', IFNULL(TRIM(CRITICALITY_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(AVG_DEMAND_BEYOND_PH::text), '^^') 
            , '||', IFNULL(TRIM(AVG_RETURNS_BEYOND_PH::text), '^^') 
            , '||', IFNULL(TRIM(RETURN_FORECAST_TIME_FENCE::text), '^^') 
            , '||', IFNULL(TRIM(DEFECTIVE_ITEM_COST::text), '^^') 
            , '||', IFNULL(TRIM(STD_DEVIATION_FOR_DEMAND::text), '^^') 
            , '||', IFNULL(TRIM(MEAN_INTER_ARRIVAL::text), '^^') 
            , '||', IFNULL(TRIM(STD_DEVIATION_INTER_ARRIVAL::text), '^^') 
            , '||', IFNULL(TRIM(INTERARRIVAL_DIST_METHOD::text), '^^') 
            , '||', IFNULL(TRIM(BASIS_AVG_DAILY_DEMAND::text), '^^') 
            , '||', IFNULL(TRIM(COEFFICIENT_OF_VARIATION::text), '^^') 
            , '||', IFNULL(TRIM(STANDARD_DEVIATION::text), '^^') 
            , '||', IFNULL(TRIM(LAST_REPLAN_DATE::text), '^^') 
            , '||', IFNULL(TRIM(NETCHANGE_REPLAN_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(REPLAN_PERIOD::text), '^^') 
            , '||', IFNULL(TRIM(SAFETY_LEAD_TIME::text), '^^') 
            , '||', IFNULL(TRIM(UNSATISFIED_DEMAND_FACTOR::text), '^^') 
            , '||', IFNULL(TRIM(MAX_USAGE_FACTOR::text), '^^') 
            , '||', IFNULL(TRIM(MIN_SUP_DEM_PERCENT::text), '^^') 
            , '||', IFNULL(TRIM(DMD_SATISFIED_PERCENT::text), '^^') 
            , '||', IFNULL(TRIM(NEW_PLAN_ID::text), '^^') 
            , '||', IFNULL(TRIM(NEW_PLAN_LIST::text), '^^') 
            , '||', IFNULL(TRIM(SIMULATION_SET_ID::text), '^^') 
            , '||', IFNULL(TRIM(NO_PL_ORD_BEFORE_WIP_WIN::text), '^^') 
            , '||', IFNULL(TRIM(PLANNING_UNITS_OF_WORK::text), '^^') 
            , '||', IFNULL(TRIM(EXCESS_HORIZON::text), '^^') 
            , '||', IFNULL(TRIM(OBSOLESCENCE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(COMPUTE_EOQ::text), '^^') 
            , '||', IFNULL(TRIM(COMPUTE_SS::text), '^^') 
            , '||', IFNULL(TRIM(ROP_SAFETY_STOCK::text), '^^') 
            , '||', IFNULL(TRIM(CONSIDER_IN_CTB_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(CALCULATE_CTB_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(CTB_KPI_HORIZON::text), '^^') 
            , '||', IFNULL(TRIM(APPLIED::text), '^^') 
            , '||', IFNULL(TRIM(INTERMITTENT_DEMAND::text), '^^') 
            , '||', IFNULL(TRIM(COMP_SUBSTITUTION_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(CONSUME_BEF_PRIMARY_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(REPAIR_MODULE::text), '^^') 
            , '||', IFNULL(TRIM(SCRAP_RATE::text), '^^') 
            , '||', IFNULL(TRIM(REBUILD_ACTIVITY::text), '^^') 
            , '||', IFNULL(TRIM(ORDER_PERIOD::text), '^^') 
            , '||', IFNULL(TRIM(INV_DAYS_INCREMENT::text), '^^') 
            , '||', IFNULL(TRIM(AVERAGE_CYCLE_STOCK::text), '^^') 
            , '||', IFNULL(TRIM(IS_MODIFIED::text), '^^') 
            , '||', IFNULL(TRIM(ADS_CALC_DAYS::text), '^^') 
            , '||', IFNULL(TRIM(SAFETY_STOCK_MRSL::text), '^^') 
            , '||', IFNULL(TRIM(MRSL_INGREDIENT::text), '^^') 
            , '||', IFNULL(TRIM(MRSL_INGREDIENT_ID::text), '^^') 
            , '||', IFNULL(TRIM(ANNUAL_SALES_QTY::text), '^^') 
            , '||', IFNULL(TRIM(ANNUAL_SALES_COUNT::text), '^^') 
            , '||', IFNULL(TRIM(ANNUAL_SALES_VALUE::text), '^^') 
            , '||', IFNULL(TRIM(ANNUAL_SHIP_QTY::text), '^^') 
            , '||', IFNULL(TRIM(ANNUAL_SHIP_COUNT::text), '^^') 
            , '||', IFNULL(TRIM(ANNUAL_SHIP_VALUE::text), '^^') 
            , '||', IFNULL(TRIM(DEMAND_VARIANCE::text), '^^') 
            , '||', IFNULL(TRIM(INVENTORY_POLICY::text), '^^') 
            , '||', IFNULL(TRIM(POLICY_UOM::text), '^^') 
            , '||', IFNULL(TRIM(MIN_UNITS::text), '^^') 
            , '||', IFNULL(TRIM(MAX_UNITS::text), '^^') 
            , '||', IFNULL(TRIM(MIN_DAYS::text), '^^') 
            , '||', IFNULL(TRIM(MAX_DAYS::text), '^^') 
            , '||', IFNULL(TRIM(ANNUAL_ORDER_CNT::text), '^^') 
            , '||', IFNULL(TRIM(ORDER_CYCLE_CAL::text), '^^') 
            , '||', IFNULL(TRIM(FCST_ERROR::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
