---- SRC LAYER ----
WITH
SRC_S              as ( SELECT * FROM {{ source('lrsn_psft_sysadm', 'ps_bu_items_inv') }} as SRC 
                        /* The following qualify clause is required to pick the latest change for a day when there are Intra day changes,
                            when Fivetran resync triggered by manual sync multiple times in a day(Resync Happens usually once per week currently). Ex. cust_id ='36196' */
                            qualify 1 = row_number() over(partition by INV_ITEM_ID,BUSINESS_UNIT, _fivetran_synced order by psa_load_dts desc) ),
SRC_A              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S              as ( SELECT * FROM lrsn_psft_sysadm.ps_bu_items_inv )
, SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        INV_ITEM_ID                                                  as                                            ITEM_BK
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
      , CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED )                   as                                           LOAD_DTS
      , BUSINESS_UNIT                                                as                                           PLANT_BK
    FROM SRC_S
)

, LOGIC_A as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_A
)
---- RENAME LAYER ----

, RENAME_S as (
    SELECT
        ITEM_BK
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
      , PLANT_BK
    FROM LOGIC_S
)

, RENAME_A as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_A
)
---- FILTER LAYER ----

, FILTER_S as (
    SELECT *
    FROM RENAME_S
)

, FILTER_A as (
    SELECT *
    FROM RENAME_A
    WHERE rec_src = 'USSDBR.ORCL.PSFTPRD.PS_BU_ITEMS_INV'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_S
    INNER JOIN FILTER_A
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          ITEM_BK
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
        , BKCC
        , PLANT_BK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ITEM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ITEM_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PLANT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PLANT_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ITEM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(PLANT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PLANT_ITEM_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(ITM_STATUS_EFFDT::text), '^^') 
            , '||', IFNULL(TRIM(ITM_STATUS_CURRENT::text), '^^') 
            , '||', IFNULL(TRIM(ITM_STAT_DT_FUTURE::text), '^^') 
            , '||', IFNULL(TRIM(ITM_STATUS_FUTURE::text), '^^') 
            , '||', IFNULL(TRIM(LAST_ADJUSTMENT::text), '^^') 
            , '||', IFNULL(TRIM(LAST_ORDER::text), '^^') 
            , '||', IFNULL(TRIM(LAST_ORDER_DATE::text), '^^') 
            , '||', IFNULL(TRIM(LAST_PUTAWAY_DATE::text), '^^') 
            , '||', IFNULL(TRIM(QTY_AVAILABLE::text), '^^') 
            , '||', IFNULL(TRIM(QTY_RESERVED::text), '^^') 
            , '||', IFNULL(TRIM(QTY_OWNED::text), '^^') 
            , '||', IFNULL(TRIM(QTY_ONHAND::text), '^^') 
            , '||', IFNULL(TRIM(LAST_DEMAND_CALC::text), '^^') 
            , '||', IFNULL(TRIM(LAST_MO_DEMAND::text), '^^') 
            , '||', IFNULL(TRIM(LAST_QTR_DEMAND::text), '^^') 
            , '||', IFNULL(TRIM(LAST_2QTR_DEMAND::text), '^^') 
            , '||', IFNULL(TRIM(LAST_ANNUAL_DEMAND::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UD_DEMAND::text), '^^') 
            , '||', IFNULL(TRIM(LAST_DEMAND_DATE::text), '^^') 
            , '||', IFNULL(TRIM(REPLENISH_CLASS::text), '^^') 
            , '||', IFNULL(TRIM(REPL_CALC_PERIOD::text), '^^') 
            , '||', IFNULL(TRIM(REPLENISH_LEAD::text), '^^') 
            , '||', IFNULL(TRIM(HISTORICAL_LEAD::text), '^^') 
            , '||', IFNULL(TRIM(PROJECTED_LEAD::text), '^^') 
            , '||', IFNULL(TRIM(SAFETY_STOCK::text), '^^') 
            , '||', IFNULL(TRIM(STOCKOUT_RATE::text), '^^') 
            , '||', IFNULL(TRIM(REORDER_POINT::text), '^^') 
            , '||', IFNULL(TRIM(REORDER_QTY::text), '^^') 
            , '||', IFNULL(TRIM(QTY_IUT_PAR::text), '^^') 
            , '||', IFNULL(TRIM(EOQ::text), '^^') 
            , '||', IFNULL(TRIM(AOQ::text), '^^') 
            , '||', IFNULL(TRIM(FOQ::text), '^^') 
            , '||', IFNULL(TRIM(QTY_MAXIMUM::text), '^^') 
            , '||', IFNULL(TRIM(DAYS_SUPPLY::text), '^^') 
            , '||', IFNULL(TRIM(ORDER_MULTIPLE::text), '^^') 
            , '||', IFNULL(TRIM(SAFETY_LEAD_TIME::text), '^^') 
            , '||', IFNULL(TRIM(TARGET_LEVEL::text), '^^') 
            , '||', IFNULL(TRIM(EXCESS_BU::text), '^^') 
            , '||', IFNULL(TRIM(LAST_ISS_EXCESS::text), '^^') 
            , '||', IFNULL(TRIM(USE_UP_QOH::text), '^^') 
            , '||', IFNULL(TRIM(INSPECT_TIME::text), '^^') 
            , '||', IFNULL(TRIM(DOCK_TO_STOCK::text), '^^') 
            , '||', IFNULL(TRIM(COST_ELEMENT::text), '^^') 
            , '||', IFNULL(TRIM(COST_GROUP_CD::text), '^^') 
            , '||', IFNULL(TRIM(LAST_CYCLE_COUNT::text), '^^') 
            , '||', IFNULL(TRIM(LAST_PIT_COUNT::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UTIL_REVIEW::text), '^^') 
            , '||', IFNULL(TRIM(NEXT_UTIL_REVIEW::text), '^^') 
            , '||', IFNULL(TRIM(RELATED_ITEM_ID::text), '^^') 
            , '||', IFNULL(TRIM(ROPC_INSTANCE::text), '^^') 
            , '||', IFNULL(TRIM(ROPC_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(SSTC_INSTANCE::text), '^^') 
            , '||', IFNULL(TRIM(SSTC_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(EOQC_INSTANCE::text), '^^') 
            , '||', IFNULL(TRIM(EOQC_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(HLDC_INSTANCE::text), '^^') 
            , '||', IFNULL(TRIM(HLDC_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(ANNDM_INSTANCE::text), '^^') 
            , '||', IFNULL(TRIM(ANNDM_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(CYCLE_INSTANCE::text), '^^') 
            , '||', IFNULL(TRIM(NO_REPLENISH_FLG::text), '^^') 
            , '||', IFNULL(TRIM(SOURCE_CODE::text), '^^') 
            , '||', IFNULL(TRIM(PHANTOM_ITEM_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(BOM_USAGE::text), '^^') 
            , '||', IFNULL(TRIM(DT_TIMESTAMP::text), '^^') 
            , '||', IFNULL(TRIM(LAST_PRICE_PAID::text), '^^') 
            , '||', IFNULL(TRIM(AVERAGE_COST::text), '^^') 
            , '||', IFNULL(TRIM(AVERAGE_COST_MAT::text), '^^') 
            , '||', IFNULL(TRIM(CURRENT_COST::text), '^^') 
            , '||', IFNULL(TRIM(DFLT_ACTUAL_COST::text), '^^') 
            , '||', IFNULL(TRIM(EXCESS_INVENTORY::text), '^^') 
            , '||', IFNULL(TRIM(REVISION_CONTROL::text), '^^') 
            , '||', IFNULL(TRIM(EN_AUTO_REV::text), '^^') 
            , '||', IFNULL(TRIM(ISSUE_METHOD::text), '^^') 
            , '||', IFNULL(TRIM(STAGED_DATE_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(ISSUE_MULTIPLE::text), '^^') 
            , '||', IFNULL(TRIM(REPLENISH_POINT::text), '^^') 
            , '||', IFNULL(TRIM(WIP_MIN_QTY::text), '^^') 
            , '||', IFNULL(TRIM(IP_PLANNING_FLG::text), '^^') 
            , '||', IFNULL(TRIM(PLANNER_CD::text), '^^') 
            , '||', IFNULL(TRIM(YIELD_CALC_FLG::text), '^^') 
            , '||', IFNULL(TRIM(PRDN_AREA_CODE::text), '^^') 
            , '||', IFNULL(TRIM(TRANSIT_COST_TYP::text), '^^') 
            , '||', IFNULL(TRIM(UOM_CONV_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(MASTER_RTG_OPT::text), '^^') 
            , '||', IFNULL(TRIM(REF_ROUTING_ITEM::text), '^^') 
            , '||', IFNULL(TRIM(STD_PACK_UOM::text), '^^') 
            , '||', IFNULL(TRIM(FORECAST_ITEM_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(FORECASTER::text), '^^') 
            , '||', IFNULL(TRIM(COUNTRY_IST_ORIGIN::text), '^^') 
            , '||', IFNULL(TRIM(IST_REGION_ORIGIN::text), '^^') 
            , '||', IFNULL(TRIM(TRANSFER_MIN_ORDER::text), '^^') 
            , '||', IFNULL(TRIM(TRANSFER_YIELD::text), '^^') 
            , '||', IFNULL(TRIM(NON_OWN_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(INV_STOCK_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_TYPE_ID::text), '^^') 
            , '||', IFNULL(TRIM(ISOLATE_ITEM_FLG::text), '^^') 
            , '||', IFNULL(TRIM(INVENTORY_ITEM::text), '^^') 
            , '||', IFNULL(TRIM(MG_PRDN_OPTION::text), '^^') 
            , '||', IFNULL(TRIM(MG_VALID_PRDN_OPT::text), '^^') 
            , '||', IFNULL(TRIM(MG_ASSOCIATED_BOM::text), '^^') 
            , '||', IFNULL(TRIM(SHELF_LIFE::text), '^^') 
            , '||', IFNULL(TRIM(AVAIL_LEAD_TIME::text), '^^') 
            , '||', IFNULL(TRIM(RETEST_LEAD_TIME::text), '^^') 
            , '||', IFNULL(TRIM(MATERIAL_RECON_FLG::text), '^^') 
            , '||', IFNULL(TRIM(USG_TRCKNG_METHOD::text), '^^') 
            , '||', IFNULL(TRIM(CHARGE_MARKUP_PCNT::text), '^^') 
            , '||', IFNULL(TRIM(CHARGE_MARKUP_AMT::text), '^^') 
            , '||', IFNULL(TRIM(CHARGE_CODE::text), '^^') 
            , '||', IFNULL(TRIM(MFG_COSTED_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(CONSIGNED_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(VENDOR_ID::text), '^^') 
            , '||', IFNULL(TRIM(VNDR_LOC::text), '^^') 
            , '||', IFNULL(TRIM(BOM_CODE::text), '^^') 
            , '||', IFNULL(TRIM(RTG_CODE::text), '^^') 
            , '||', IFNULL(TRIM(MFG_LEADTIME_F::text), '^^') 
            , '||', IFNULL(TRIM(MFG_LEADTIME_V::text), '^^') 
            , '||', IFNULL(TRIM(MFG_LTRATEF::text), '^^') 
            , '||', IFNULL(TRIM(MFG_LTRATEV::text), '^^') 
            , '||', IFNULL(TRIM(OVERSIZED::text), '^^') 
            , '||', IFNULL(TRIM(ADD_HANDLING::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_FIELD_C30_A::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_FIELD_C30_B::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_FIELD_C30_C::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_FIELD_C30_D::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_FIELD_C1_A::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_FIELD_C1_B::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_FIELD_C1_C::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_FIELD_C1_D::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_FIELD_C10_A::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_FIELD_C10_B::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_FIELD_C10_C::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_FIELD_C10_D::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_FIELD_C2::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_FIELD_C4::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_FIELD_C6::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_FIELD_C8::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_FIELD_N12_A::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_FIELD_N12_B::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_FIELD_N12_C::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_FIELD_N12_D::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_FIELD_N15_A::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_FIELD_N15_B::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_FIELD_N15_C::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_FIELD_N15_D::text), '^^') 
            , '||', IFNULL(TRIM(EXPORTER_ECCN::text), '^^') 
            , '||', IFNULL(TRIM(EXPORT_LIC_NBR::text), '^^') 
            , '||', IFNULL(TRIM(INCL_WIP_QTY_FLG::text), '^^') 
            , '||', IFNULL(TRIM(DECLARED_VALUE::text), '^^') 
            , '||', IFNULL(TRIM(SF_WIP_MAX_QTY::text), '^^') 
            , '||', IFNULL(TRIM(SF_RPL_MODE::text), '^^') 
            , '||', IFNULL(TRIM(SF_RPL_SOURCE::text), '^^') 
            , '||', IFNULL(TRIM(SF_RPL_METHOD::text), '^^') 
            , '||', IFNULL(TRIM(SF_RPL_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(SF_DISPATCH_MODE::text), '^^') 
            , '||', IFNULL(TRIM(SF_RPL_STOR_AREA::text), '^^') 
            , '||', IFNULL(TRIM(SF_RPL_STOR_LEV1::text), '^^') 
            , '||', IFNULL(TRIM(SF_RPL_STOR_LEV2::text), '^^') 
            , '||', IFNULL(TRIM(SF_RPL_STOR_LEV3::text), '^^') 
            , '||', IFNULL(TRIM(SF_RPL_STOR_LEV4::text), '^^') 
            , '||', IFNULL(TRIM(SF_RPL_VENDOR_ID::text), '^^') 
            , '||', IFNULL(TRIM(SF_RPL_VNDR_LOC::text), '^^') 
            , '||', IFNULL(TRIM(SF_RPL_PRDN_AREA::text), '^^') 
            , '||', IFNULL(TRIM(DP_PUBLISH_DATE::text), '^^') 
            , '||', IFNULL(TRIM(DP_POLICYSET::text), '^^') 
            , '||', IFNULL(TRIM(DP_POLICYCONTROL::text), '^^') 
            , '||', IFNULL(TRIM(DP_PUBLISHNAME::text), '^^') 
            , '||', IFNULL(TRIM(PRODUCT_ID::text), '^^') 
            , '||', IFNULL(TRIM(VMI_REPLEN_UOM::text), '^^') 
            , '||', IFNULL(TRIM(REORD_QTY_OPTION::text), '^^') 
            , '||', IFNULL(TRIM(REPL_INCL_DEMAND::text), '^^') 
            , '||', IFNULL(TRIM(REPL_DMD_DAYS_OPT::text), '^^') 
            , '||', IFNULL(TRIM(OFFSET_DAYS::text), '^^') 
            , '||', IFNULL(TRIM(LOT_BACKFLUSH_OPT::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
