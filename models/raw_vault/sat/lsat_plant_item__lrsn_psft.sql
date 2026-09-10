---- SRC LAYER ----
WITH
SRC_SITMLR         as ( SELECT * FROM {{ ref('v_psa_stg_plant_item__lrsn_psft') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_SITMLR         as ( SELECT * FROM STAGING.v_psa_stg_plant_item__LRSN_PSFT )
*/
---- LOGIC LAYER ----

, LOGIC_SITMLR as (
    SELECT
        PLANT_ITEM_HK
      , BUSINESS_UNIT
      , INV_ITEM_ID
      , ITM_STATUS_EFFDT
      , ITM_STATUS_CURRENT
      , ITM_STAT_DT_FUTURE
      , ITM_STATUS_FUTURE
      , LAST_ADJUSTMENT
      , LAST_ORDER
      , LAST_ORDER_DATE
      , LAST_PUTAWAY_DATE
      , QTY_AVAILABLE
      , QTY_RESERVED
      , QTY_OWNED
      , QTY_ONHAND
      , LAST_DEMAND_CALC
      , LAST_MO_DEMAND
      , LAST_QTR_DEMAND
      , LAST_2QTR_DEMAND
      , LAST_ANNUAL_DEMAND
      , LAST_UD_DEMAND
      , LAST_DEMAND_DATE
      , REPLENISH_CLASS
      , REPL_CALC_PERIOD
      , REPLENISH_LEAD
      , HISTORICAL_LEAD
      , PROJECTED_LEAD
      , SAFETY_STOCK
      , STOCKOUT_RATE
      , REORDER_POINT
      , REORDER_QTY
      , QTY_IUT_PAR
      , EOQ
      , AOQ
      , FOQ
      , QTY_MAXIMUM
      , DAYS_SUPPLY
      , ORDER_MULTIPLE
      , SAFETY_LEAD_TIME
      , TARGET_LEVEL
      , EXCESS_BU
      , LAST_ISS_EXCESS
      , USE_UP_QOH
      , INSPECT_TIME
      , DOCK_TO_STOCK
      , COST_ELEMENT
      , COST_GROUP_CD
      , LAST_CYCLE_COUNT
      , LAST_PIT_COUNT
      , LAST_UTIL_REVIEW
      , NEXT_UTIL_REVIEW
      , RELATED_ITEM_ID
      , ROPC_INSTANCE
      , ROPC_STATUS
      , SSTC_INSTANCE
      , SSTC_STATUS
      , EOQC_INSTANCE
      , EOQC_STATUS
      , HLDC_INSTANCE
      , HLDC_STATUS
      , ANNDM_INSTANCE
      , ANNDM_STATUS
      , CYCLE_INSTANCE
      , NO_REPLENISH_FLG
      , SOURCE_CODE
      , PHANTOM_ITEM_FLAG
      , BOM_USAGE
      , DT_TIMESTAMP
      , LAST_PRICE_PAID
      , AVERAGE_COST
      , AVERAGE_COST_MAT
      , CURRENT_COST
      , DFLT_ACTUAL_COST
      , EXCESS_INVENTORY
      , REVISION_CONTROL
      , EN_AUTO_REV
      , ISSUE_METHOD
      , STAGED_DATE_FLAG
      , ISSUE_MULTIPLE
      , REPLENISH_POINT
      , WIP_MIN_QTY
      , IP_PLANNING_FLG
      , PLANNER_CD
      , YIELD_CALC_FLG
      , PRDN_AREA_CODE
      , TRANSIT_COST_TYP
      , UOM_CONV_FLAG
      , MASTER_RTG_OPT
      , REF_ROUTING_ITEM
      , STD_PACK_UOM
      , FORECAST_ITEM_FLAG
      , FORECASTER
      , COUNTRY_IST_ORIGIN
      , IST_REGION_ORIGIN
      , TRANSFER_MIN_ORDER
      , TRANSFER_YIELD
      , NON_OWN_FLAG
      , INV_STOCK_TYPE
      , SHIP_TYPE_ID
      , ISOLATE_ITEM_FLG
      , INVENTORY_ITEM
      , MG_PRDN_OPTION
      , MG_VALID_PRDN_OPT
      , MG_ASSOCIATED_BOM
      , SHELF_LIFE
      , AVAIL_LEAD_TIME
      , RETEST_LEAD_TIME
      , MATERIAL_RECON_FLG
      , USG_TRCKNG_METHOD
      , CHARGE_MARKUP_PCNT
      , CHARGE_MARKUP_AMT
      , CHARGE_CODE
      , MFG_COSTED_FLAG
      , CONSIGNED_FLAG
      , VENDOR_ID
      , VNDR_LOC
      , BOM_CODE
      , RTG_CODE
      , MFG_LEADTIME_F
      , MFG_LEADTIME_V
      , MFG_LTRATEF
      , MFG_LTRATEV
      , OVERSIZED
      , ADD_HANDLING
      , ITEM_FIELD_C30_A
      , ITEM_FIELD_C30_B
      , ITEM_FIELD_C30_C
      , ITEM_FIELD_C30_D
      , ITEM_FIELD_C1_A
      , ITEM_FIELD_C1_B
      , ITEM_FIELD_C1_C
      , ITEM_FIELD_C1_D
      , ITEM_FIELD_C10_A
      , ITEM_FIELD_C10_B
      , ITEM_FIELD_C10_C
      , ITEM_FIELD_C10_D
      , ITEM_FIELD_C2
      , ITEM_FIELD_C4
      , ITEM_FIELD_C6
      , ITEM_FIELD_C8
      , ITEM_FIELD_N12_A
      , ITEM_FIELD_N12_B
      , ITEM_FIELD_N12_C
      , ITEM_FIELD_N12_D
      , ITEM_FIELD_N15_A
      , ITEM_FIELD_N15_B
      , ITEM_FIELD_N15_C
      , ITEM_FIELD_N15_D
      , EXPORTER_ECCN
      , EXPORT_LIC_NBR
      , INCL_WIP_QTY_FLG
      , DECLARED_VALUE
      , SF_WIP_MAX_QTY
      , SF_RPL_MODE
      , SF_RPL_SOURCE
      , SF_RPL_METHOD
      , SF_RPL_TYPE
      , SF_DISPATCH_MODE
      , SF_RPL_STOR_AREA
      , SF_RPL_STOR_LEV1
      , SF_RPL_STOR_LEV2
      , SF_RPL_STOR_LEV3
      , SF_RPL_STOR_LEV4
      , SF_RPL_VENDOR_ID
      , SF_RPL_VNDR_LOC
      , SF_RPL_PRDN_AREA
      , DP_PUBLISH_DATE
      , DP_POLICYSET
      , DP_POLICYCONTROL
      , DP_PUBLISHNAME
      , PRODUCT_ID
      , VMI_REPLEN_UOM
      , REORD_QTY_OPTION
      , REPL_INCL_DEMAND
      , REPL_DMD_DAYS_OPT
      , OFFSET_DAYS
      , LOT_BACKFLUSH_OPT
      , _FIVETRAN_DELETED
      , _FIVETRAN_ID
      , _FIVETRAN_SYNCED
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , LOAD_DTS
      , REC_SRC
      , HASHDIFF
    FROM SRC_SITMLR
)
---- RENAME LAYER ----

, RENAME_SITMLR as (
    SELECT
        PLANT_ITEM_HK
      , BUSINESS_UNIT
      , INV_ITEM_ID
      , ITM_STATUS_EFFDT
      , ITM_STATUS_CURRENT
      , ITM_STAT_DT_FUTURE
      , ITM_STATUS_FUTURE
      , LAST_ADJUSTMENT
      , LAST_ORDER
      , LAST_ORDER_DATE
      , LAST_PUTAWAY_DATE
      , QTY_AVAILABLE
      , QTY_RESERVED
      , QTY_OWNED
      , QTY_ONHAND
      , LAST_DEMAND_CALC
      , LAST_MO_DEMAND
      , LAST_QTR_DEMAND
      , LAST_2QTR_DEMAND
      , LAST_ANNUAL_DEMAND
      , LAST_UD_DEMAND
      , LAST_DEMAND_DATE
      , REPLENISH_CLASS
      , REPL_CALC_PERIOD
      , REPLENISH_LEAD
      , HISTORICAL_LEAD
      , PROJECTED_LEAD
      , SAFETY_STOCK
      , STOCKOUT_RATE
      , REORDER_POINT
      , REORDER_QTY
      , QTY_IUT_PAR
      , EOQ
      , AOQ
      , FOQ
      , QTY_MAXIMUM
      , DAYS_SUPPLY
      , ORDER_MULTIPLE
      , SAFETY_LEAD_TIME
      , TARGET_LEVEL
      , EXCESS_BU
      , LAST_ISS_EXCESS
      , USE_UP_QOH
      , INSPECT_TIME
      , DOCK_TO_STOCK
      , COST_ELEMENT
      , COST_GROUP_CD
      , LAST_CYCLE_COUNT
      , LAST_PIT_COUNT
      , LAST_UTIL_REVIEW
      , NEXT_UTIL_REVIEW
      , RELATED_ITEM_ID
      , ROPC_INSTANCE
      , ROPC_STATUS
      , SSTC_INSTANCE
      , SSTC_STATUS
      , EOQC_INSTANCE
      , EOQC_STATUS
      , HLDC_INSTANCE
      , HLDC_STATUS
      , ANNDM_INSTANCE
      , ANNDM_STATUS
      , CYCLE_INSTANCE
      , NO_REPLENISH_FLG
      , SOURCE_CODE
      , PHANTOM_ITEM_FLAG
      , BOM_USAGE
      , DT_TIMESTAMP
      , LAST_PRICE_PAID
      , AVERAGE_COST
      , AVERAGE_COST_MAT
      , CURRENT_COST
      , DFLT_ACTUAL_COST
      , EXCESS_INVENTORY
      , REVISION_CONTROL
      , EN_AUTO_REV
      , ISSUE_METHOD
      , STAGED_DATE_FLAG
      , ISSUE_MULTIPLE
      , REPLENISH_POINT
      , WIP_MIN_QTY
      , IP_PLANNING_FLG
      , PLANNER_CD
      , YIELD_CALC_FLG
      , PRDN_AREA_CODE
      , TRANSIT_COST_TYP
      , UOM_CONV_FLAG
      , MASTER_RTG_OPT
      , REF_ROUTING_ITEM
      , STD_PACK_UOM
      , FORECAST_ITEM_FLAG
      , FORECASTER
      , COUNTRY_IST_ORIGIN
      , IST_REGION_ORIGIN
      , TRANSFER_MIN_ORDER
      , TRANSFER_YIELD
      , NON_OWN_FLAG
      , INV_STOCK_TYPE
      , SHIP_TYPE_ID
      , ISOLATE_ITEM_FLG
      , INVENTORY_ITEM
      , MG_PRDN_OPTION
      , MG_VALID_PRDN_OPT
      , MG_ASSOCIATED_BOM
      , SHELF_LIFE
      , AVAIL_LEAD_TIME
      , RETEST_LEAD_TIME
      , MATERIAL_RECON_FLG
      , USG_TRCKNG_METHOD
      , CHARGE_MARKUP_PCNT
      , CHARGE_MARKUP_AMT
      , CHARGE_CODE
      , MFG_COSTED_FLAG
      , CONSIGNED_FLAG
      , VENDOR_ID
      , VNDR_LOC
      , BOM_CODE
      , RTG_CODE
      , MFG_LEADTIME_F
      , MFG_LEADTIME_V
      , MFG_LTRATEF
      , MFG_LTRATEV
      , OVERSIZED
      , ADD_HANDLING
      , ITEM_FIELD_C30_A
      , ITEM_FIELD_C30_B
      , ITEM_FIELD_C30_C
      , ITEM_FIELD_C30_D
      , ITEM_FIELD_C1_A
      , ITEM_FIELD_C1_B
      , ITEM_FIELD_C1_C
      , ITEM_FIELD_C1_D
      , ITEM_FIELD_C10_A
      , ITEM_FIELD_C10_B
      , ITEM_FIELD_C10_C
      , ITEM_FIELD_C10_D
      , ITEM_FIELD_C2
      , ITEM_FIELD_C4
      , ITEM_FIELD_C6
      , ITEM_FIELD_C8
      , ITEM_FIELD_N12_A
      , ITEM_FIELD_N12_B
      , ITEM_FIELD_N12_C
      , ITEM_FIELD_N12_D
      , ITEM_FIELD_N15_A
      , ITEM_FIELD_N15_B
      , ITEM_FIELD_N15_C
      , ITEM_FIELD_N15_D
      , EXPORTER_ECCN
      , EXPORT_LIC_NBR
      , INCL_WIP_QTY_FLG
      , DECLARED_VALUE
      , SF_WIP_MAX_QTY
      , SF_RPL_MODE
      , SF_RPL_SOURCE
      , SF_RPL_METHOD
      , SF_RPL_TYPE
      , SF_DISPATCH_MODE
      , SF_RPL_STOR_AREA
      , SF_RPL_STOR_LEV1
      , SF_RPL_STOR_LEV2
      , SF_RPL_STOR_LEV3
      , SF_RPL_STOR_LEV4
      , SF_RPL_VENDOR_ID
      , SF_RPL_VNDR_LOC
      , SF_RPL_PRDN_AREA
      , DP_PUBLISH_DATE
      , DP_POLICYSET
      , DP_POLICYCONTROL
      , DP_PUBLISHNAME
      , PRODUCT_ID
      , VMI_REPLEN_UOM
      , REORD_QTY_OPTION
      , REPL_INCL_DEMAND
      , REPL_DMD_DAYS_OPT
      , OFFSET_DAYS
      , LOT_BACKFLUSH_OPT
      , _FIVETRAN_DELETED
      , _FIVETRAN_ID
      , _FIVETRAN_SYNCED
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , LOAD_DTS
      , REC_SRC
      , HASHDIFF
    FROM LOGIC_SITMLR
)
---- FILTER LAYER ----

, FILTER_SITMLR as (
    SELECT *
    FROM RENAME_SITMLR
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_SITMLR
)

---- FINAL LAYER ----
SELECT
          PLANT_ITEM_HK
        , BUSINESS_UNIT
        , INV_ITEM_ID
        , ITM_STATUS_EFFDT
        , ITM_STATUS_CURRENT
        , ITM_STAT_DT_FUTURE
        , ITM_STATUS_FUTURE
        , LAST_ADJUSTMENT
        , LAST_ORDER
        , LAST_ORDER_DATE
        , LAST_PUTAWAY_DATE
        , QTY_AVAILABLE
        , QTY_RESERVED
        , QTY_OWNED
        , QTY_ONHAND
        , LAST_DEMAND_CALC
        , LAST_MO_DEMAND
        , LAST_QTR_DEMAND
        , LAST_2QTR_DEMAND
        , LAST_ANNUAL_DEMAND
        , LAST_UD_DEMAND
        , LAST_DEMAND_DATE
        , REPLENISH_CLASS
        , REPL_CALC_PERIOD
        , REPLENISH_LEAD
        , HISTORICAL_LEAD
        , PROJECTED_LEAD
        , SAFETY_STOCK
        , STOCKOUT_RATE
        , REORDER_POINT
        , REORDER_QTY
        , QTY_IUT_PAR
        , EOQ
        , AOQ
        , FOQ
        , QTY_MAXIMUM
        , DAYS_SUPPLY
        , ORDER_MULTIPLE
        , SAFETY_LEAD_TIME
        , TARGET_LEVEL
        , EXCESS_BU
        , LAST_ISS_EXCESS
        , USE_UP_QOH
        , INSPECT_TIME
        , DOCK_TO_STOCK
        , COST_ELEMENT
        , COST_GROUP_CD
        , LAST_CYCLE_COUNT
        , LAST_PIT_COUNT
        , LAST_UTIL_REVIEW
        , NEXT_UTIL_REVIEW
        , RELATED_ITEM_ID
        , ROPC_INSTANCE
        , ROPC_STATUS
        , SSTC_INSTANCE
        , SSTC_STATUS
        , EOQC_INSTANCE
        , EOQC_STATUS
        , HLDC_INSTANCE
        , HLDC_STATUS
        , ANNDM_INSTANCE
        , ANNDM_STATUS
        , CYCLE_INSTANCE
        , NO_REPLENISH_FLG
        , SOURCE_CODE
        , PHANTOM_ITEM_FLAG
        , BOM_USAGE
        , DT_TIMESTAMP
        , LAST_PRICE_PAID
        , AVERAGE_COST
        , AVERAGE_COST_MAT
        , CURRENT_COST
        , DFLT_ACTUAL_COST
        , EXCESS_INVENTORY
        , REVISION_CONTROL
        , EN_AUTO_REV
        , ISSUE_METHOD
        , STAGED_DATE_FLAG
        , ISSUE_MULTIPLE
        , REPLENISH_POINT
        , WIP_MIN_QTY
        , IP_PLANNING_FLG
        , PLANNER_CD
        , YIELD_CALC_FLG
        , PRDN_AREA_CODE
        , TRANSIT_COST_TYP
        , UOM_CONV_FLAG
        , MASTER_RTG_OPT
        , REF_ROUTING_ITEM
        , STD_PACK_UOM
        , FORECAST_ITEM_FLAG
        , FORECASTER
        , COUNTRY_IST_ORIGIN
        , IST_REGION_ORIGIN
        , TRANSFER_MIN_ORDER
        , TRANSFER_YIELD
        , NON_OWN_FLAG
        , INV_STOCK_TYPE
        , SHIP_TYPE_ID
        , ISOLATE_ITEM_FLG
        , INVENTORY_ITEM
        , MG_PRDN_OPTION
        , MG_VALID_PRDN_OPT
        , MG_ASSOCIATED_BOM
        , SHELF_LIFE
        , AVAIL_LEAD_TIME
        , RETEST_LEAD_TIME
        , MATERIAL_RECON_FLG
        , USG_TRCKNG_METHOD
        , CHARGE_MARKUP_PCNT
        , CHARGE_MARKUP_AMT
        , CHARGE_CODE
        , MFG_COSTED_FLAG
        , CONSIGNED_FLAG
        , VENDOR_ID
        , VNDR_LOC
        , BOM_CODE
        , RTG_CODE
        , MFG_LEADTIME_F
        , MFG_LEADTIME_V
        , MFG_LTRATEF
        , MFG_LTRATEV
        , OVERSIZED
        , ADD_HANDLING
        , ITEM_FIELD_C30_A
        , ITEM_FIELD_C30_B
        , ITEM_FIELD_C30_C
        , ITEM_FIELD_C30_D
        , ITEM_FIELD_C1_A
        , ITEM_FIELD_C1_B
        , ITEM_FIELD_C1_C
        , ITEM_FIELD_C1_D
        , ITEM_FIELD_C10_A
        , ITEM_FIELD_C10_B
        , ITEM_FIELD_C10_C
        , ITEM_FIELD_C10_D
        , ITEM_FIELD_C2
        , ITEM_FIELD_C4
        , ITEM_FIELD_C6
        , ITEM_FIELD_C8
        , ITEM_FIELD_N12_A
        , ITEM_FIELD_N12_B
        , ITEM_FIELD_N12_C
        , ITEM_FIELD_N12_D
        , ITEM_FIELD_N15_A
        , ITEM_FIELD_N15_B
        , ITEM_FIELD_N15_C
        , ITEM_FIELD_N15_D
        , EXPORTER_ECCN
        , EXPORT_LIC_NBR
        , INCL_WIP_QTY_FLG
        , DECLARED_VALUE
        , SF_WIP_MAX_QTY
        , SF_RPL_MODE
        , SF_RPL_SOURCE
        , SF_RPL_METHOD
        , SF_RPL_TYPE
        , SF_DISPATCH_MODE
        , SF_RPL_STOR_AREA
        , SF_RPL_STOR_LEV1
        , SF_RPL_STOR_LEV2
        , SF_RPL_STOR_LEV3
        , SF_RPL_STOR_LEV4
        , SF_RPL_VENDOR_ID
        , SF_RPL_VNDR_LOC
        , SF_RPL_PRDN_AREA
        , DP_PUBLISH_DATE
        , DP_POLICYSET
        , DP_POLICYCONTROL
        , DP_PUBLISHNAME
        , PRODUCT_ID
        , VMI_REPLEN_UOM
        , REORD_QTY_OPTION
        , REPL_INCL_DEMAND
        , REPL_DMD_DAYS_OPT
        , OFFSET_DAYS
        , LOT_BACKFLUSH_OPT
        , _FIVETRAN_DELETED
        , _FIVETRAN_ID
        , _FIVETRAN_SYNCED
        , PSA_DELETE_IND
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , LOAD_DTS
        , REC_SRC
        , HASHDIFF
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.PLANT_ITEM_HK= JOIN_RESULT.PLANT_ITEM_HK
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %} 
{% if not is_incremental() %}
/*the following qualify is to restrict multiple loads of touched records during the initial build. Ex: multiple row per hk, hashdiff */
qualify 1= row_number()over(partition by PLANT_ITEM_HK, HASHDIFF order by PSA_LOAD_DTS)
union all
    SELECT        MD5_BINARY(GR.VALUE) AS PLANT_ITEM_HK     
       , GR.VALUE as BUSINESS_UNIT
    , GR.VALUE as INV_ITEM_ID
    , null as ITM_STATUS_EFFDT
    , null as ITM_STATUS_CURRENT
    , null as ITM_STAT_DT_FUTURE
    , null as ITM_STATUS_FUTURE
    , null as LAST_ADJUSTMENT
    , null as LAST_ORDER
    , null as LAST_ORDER_DATE
    , null as LAST_PUTAWAY_DATE
    , null as QTY_AVAILABLE
    , null as QTY_RESERVED
    , null as QTY_OWNED
    , null as QTY_ONHAND
    , null as LAST_DEMAND_CALC
    , null as LAST_MO_DEMAND
    , null as LAST_QTR_DEMAND
    , null as LAST_2QTR_DEMAND
    , null as LAST_ANNUAL_DEMAND
    , null as LAST_UD_DEMAND
    , null as LAST_DEMAND_DATE
    , null as REPLENISH_CLASS
    , null as REPL_CALC_PERIOD
    , null as REPLENISH_LEAD
    , null as HISTORICAL_LEAD
    , null as PROJECTED_LEAD
    , null as SAFETY_STOCK
    , null as STOCKOUT_RATE
    , null as REORDER_POINT
    , null as REORDER_QTY
    , null as QTY_IUT_PAR
    , null as EOQ
    , null as AOQ
    , null as FOQ
    , null as QTY_MAXIMUM
    , null as DAYS_SUPPLY
    , null as ORDER_MULTIPLE
    , null as SAFETY_LEAD_TIME
    , null as TARGET_LEVEL
    , null as EXCESS_BU
    , null as LAST_ISS_EXCESS
    , null as USE_UP_QOH
    , null as INSPECT_TIME
    , null as DOCK_TO_STOCK
    , null as COST_ELEMENT
    , null as COST_GROUP_CD
    , null as LAST_CYCLE_COUNT
    , null as LAST_PIT_COUNT
    , null as LAST_UTIL_REVIEW
    , null as NEXT_UTIL_REVIEW
    , null as RELATED_ITEM_ID
    , null as ROPC_INSTANCE
    , null as ROPC_STATUS
    , null as SSTC_INSTANCE
    , null as SSTC_STATUS
    , null as EOQC_INSTANCE
    , null as EOQC_STATUS
    , null as HLDC_INSTANCE
    , null as HLDC_STATUS
    , null as ANNDM_INSTANCE
    , null as ANNDM_STATUS
    , null as CYCLE_INSTANCE
    , null as NO_REPLENISH_FLG
    , null as SOURCE_CODE
    , null as PHANTOM_ITEM_FLAG
    , null as BOM_USAGE
    , null as DT_TIMESTAMP
    , null as LAST_PRICE_PAID
    , null as AVERAGE_COST
    , null as AVERAGE_COST_MAT
    , null as CURRENT_COST
    , null as DFLT_ACTUAL_COST
    , null as EXCESS_INVENTORY
    , null as REVISION_CONTROL
    , null as EN_AUTO_REV
    , null as ISSUE_METHOD
    , null as STAGED_DATE_FLAG
    , null as ISSUE_MULTIPLE
    , null as REPLENISH_POINT
    , null as WIP_MIN_QTY
    , null as IP_PLANNING_FLG
    , null as PLANNER_CD
    , null as YIELD_CALC_FLG
    , null as PRDN_AREA_CODE
    , null as TRANSIT_COST_TYP
    , null as UOM_CONV_FLAG
    , null as MASTER_RTG_OPT
    , null as REF_ROUTING_ITEM
    , null as STD_PACK_UOM
    , null as FORECAST_ITEM_FLAG
    , null as FORECASTER
    , null as COUNTRY_IST_ORIGIN
    , null as IST_REGION_ORIGIN
    , null as TRANSFER_MIN_ORDER
    , null as TRANSFER_YIELD
    , null as NON_OWN_FLAG
    , null as INV_STOCK_TYPE
    , null as SHIP_TYPE_ID
    , null as ISOLATE_ITEM_FLG
    , null as INVENTORY_ITEM
    , null as MG_PRDN_OPTION
    , null as MG_VALID_PRDN_OPT
    , null as MG_ASSOCIATED_BOM
    , null as SHELF_LIFE
    , null as AVAIL_LEAD_TIME
    , null as RETEST_LEAD_TIME
    , null as MATERIAL_RECON_FLG
    , null as USG_TRCKNG_METHOD
    , null as CHARGE_MARKUP_PCNT
    , null as CHARGE_MARKUP_AMT
    , null as CHARGE_CODE
    , null as MFG_COSTED_FLAG
    , null as CONSIGNED_FLAG
    , null as VENDOR_ID
    , null as VNDR_LOC
    , null as BOM_CODE
    , null as RTG_CODE
    , null as MFG_LEADTIME_F
    , null as MFG_LEADTIME_V
    , null as MFG_LTRATEF
    , null as MFG_LTRATEV
    , null as OVERSIZED
    , null as ADD_HANDLING
    , null as ITEM_FIELD_C30_A
    , null as ITEM_FIELD_C30_B
    , null as ITEM_FIELD_C30_C
    , null as ITEM_FIELD_C30_D
    , null as ITEM_FIELD_C1_A
    , null as ITEM_FIELD_C1_B
    , null as ITEM_FIELD_C1_C
    , null as ITEM_FIELD_C1_D
    , null as ITEM_FIELD_C10_A
    , null as ITEM_FIELD_C10_B
    , null as ITEM_FIELD_C10_C
    , null as ITEM_FIELD_C10_D
    , null as ITEM_FIELD_C2
    , null as ITEM_FIELD_C4
    , null as ITEM_FIELD_C6
    , null as ITEM_FIELD_C8
    , null as ITEM_FIELD_N12_A
    , null as ITEM_FIELD_N12_B
    , null as ITEM_FIELD_N12_C
    , null as ITEM_FIELD_N12_D
    , null as ITEM_FIELD_N15_A
    , null as ITEM_FIELD_N15_B
    , null as ITEM_FIELD_N15_C
    , null as ITEM_FIELD_N15_D
    , null as EXPORTER_ECCN
    , null as EXPORT_LIC_NBR
    , null as INCL_WIP_QTY_FLG
    , null as DECLARED_VALUE
    , null as SF_WIP_MAX_QTY
    , null as SF_RPL_MODE
    , null as SF_RPL_SOURCE
    , null as SF_RPL_METHOD
    , null as SF_RPL_TYPE
    , null as SF_DISPATCH_MODE
    , null as SF_RPL_STOR_AREA
    , null as SF_RPL_STOR_LEV1
    , null as SF_RPL_STOR_LEV2
    , null as SF_RPL_STOR_LEV3
    , null as SF_RPL_STOR_LEV4
    , null as SF_RPL_VENDOR_ID
    , null as SF_RPL_VNDR_LOC
    , null as SF_RPL_PRDN_AREA
    , null as DP_PUBLISH_DATE
    , null as DP_POLICYSET
    , null as DP_POLICYCONTROL
    , null as DP_PUBLISHNAME
    , null as PRODUCT_ID
    , null as VMI_REPLEN_UOM
    , null as REORD_QTY_OPTION
    , null as REPL_INCL_DEMAND
    , null as REPL_DMD_DAYS_OPT
    , null as OFFSET_DAYS
    , null as LOT_BACKFLUSH_OPT
    , null as _FIVETRAN_DELETED
    , null as _FIVETRAN_ID
    , null as _FIVETRAN_SYNCED
    , null as PSA_DELETE_IND
    , null as PSA_LOAD_DTS
    , null as PSA_RECORD_SOURCE
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)::TIMESTAMP as LOAD_DTS
,'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
, ''::BINARY as HASHDIFF
  FROM
        TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}