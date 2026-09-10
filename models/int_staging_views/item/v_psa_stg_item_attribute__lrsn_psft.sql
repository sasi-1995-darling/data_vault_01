---- SRC LAYER ----
WITH
SRC_SRC            as ( SELECT * FROM {{ source('lrsn_psft_sysadm', 'ps_pl_item_attrib') }} as SRC  ),
SRC_ref_bkcc       as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC 
                        WHERE rec_src = 'USSDBR.ORCL.PSFTPRD.PS_PL_ITEM_ATTRIB' )

/*
SRC_SRC            as ( SELECT * FROM lrsn_psft_sysadm.ps_pl_item_attrib )
SRC_ref_bkcc       as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_SRC as (
    SELECT
        INV_ITEM_ID                                                  as                                            ITEM_BK
      , INV_ITEM_ID
      , BUSINESS_UNIT                                                as                                           PLANT_BK
      , BUSINESS_UNIT
      , RESCH_OUT_FACTOR
      , RESCH_IN_FACTOR
      , DEMAND_FENCE_OF
      , PLAN_FENCE_OFF
      , PLAN_HORIZON
      , TRANSFER_MIN_ORDER
      , TRANSFER_MAX_ORDER
      , TRANS_ORD_MULTIPLE
      , TRANSFER_ORD_MOD
      , PUR_MIN_ORDER
      , PUR_MAX_ORDER
      , PUR_ORDER_MULTIPLE
      , PUR_ORDER_MOD
      , MFG_MOD_UNIT
      , MFG_MIN_ORDER
      , MFG_MAX_ORDER
      , MFG_ORDER_MULTIPLE
      , MFG_ORDER_MOD
      , MFG_LEAD_TIME_FLAG
      , SAFETY_LEVEL
      , EXCESS_LEVEL
      , AUTO_APPROVE_MSG
      , PLANNER_CD
      , PURCHASE_YIELD
      , TRANSFER_YIELD
      , SALES_CONSUMP
      , PROD_CONSUMP
      , TRANS_CONSUMP
      , MSR_CONSUMP
      , EXTRA_CONSUMP
      , PL_AGG_DMD_FLAG
      , RELEASED_ORDER
      , FIRMED_ORDER
      , PL_PRIO_FAMILY
      , USE_SHIPTO_LOC
      , PL_FIXED_PERIOD
      , PL_ITEM_EXPL
      , PL_PROJ_USE_DT
      , PLANNED_BY
      , CAP_FENCE_OFF
      , FCST_FULFILL_SIZE
      , FCST_ADJ_ACTION
      , EARLY_FENCE
      , GBL_EARLY_FENCE
      , PL_SEARCH_DEPTH
      , SPOT_BUY_FLG
      , DP_UOMGROUP
      , USE_PUR_ORD_MOD
      , USE_REGION_VNDR
      , PL_RESCHEDULE_TOL
      , _FIVETRAN_ID
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED)                    as                                           LOAD_DTS
    FROM SRC_SRC
)

, LOGIC_ref_bkcc as (
    SELECT
        BKCC
      , REC_SRC
    FROM SRC_ref_bkcc
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM LOGIC_SRC
    INNER JOIN LOGIC_ref_bkcc
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          ITEM_BK
        , INV_ITEM_ID
        , PLANT_BK
        , BUSINESS_UNIT
        , RESCH_OUT_FACTOR
        , RESCH_IN_FACTOR
        , DEMAND_FENCE_OF
        , PLAN_FENCE_OFF
        , PLAN_HORIZON
        , TRANSFER_MIN_ORDER
        , TRANSFER_MAX_ORDER
        , TRANS_ORD_MULTIPLE
        , TRANSFER_ORD_MOD
        , PUR_MIN_ORDER
        , PUR_MAX_ORDER
        , PUR_ORDER_MULTIPLE
        , PUR_ORDER_MOD
        , MFG_MOD_UNIT
        , MFG_MIN_ORDER
        , MFG_MAX_ORDER
        , MFG_ORDER_MULTIPLE
        , MFG_ORDER_MOD
        , MFG_LEAD_TIME_FLAG
        , SAFETY_LEVEL
        , EXCESS_LEVEL
        , AUTO_APPROVE_MSG
        , PLANNER_CD
        , PURCHASE_YIELD
        , TRANSFER_YIELD
        , SALES_CONSUMP
        , PROD_CONSUMP
        , TRANS_CONSUMP
        , MSR_CONSUMP
        , EXTRA_CONSUMP
        , PL_AGG_DMD_FLAG
        , RELEASED_ORDER
        , FIRMED_ORDER
        , PL_PRIO_FAMILY
        , USE_SHIPTO_LOC
        , PL_FIXED_PERIOD
        , PL_ITEM_EXPL
        , PL_PROJ_USE_DT
        , PLANNED_BY
        , CAP_FENCE_OFF
        , FCST_FULFILL_SIZE
        , FCST_ADJ_ACTION
        , EARLY_FENCE
        , GBL_EARLY_FENCE
        , PL_SEARCH_DEPTH
        , SPOT_BUY_FLG
        , DP_UOMGROUP
        , USE_PUR_ORD_MOD
        , USE_REGION_VNDR
        , PL_RESCHEDULE_TOL
        , _FIVETRAN_ID
        , _FIVETRAN_DELETED
        , _FIVETRAN_SYNCED
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , BKCC
        , REC_SRC
        , LOAD_DTS
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(INV_ITEM_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ITEM_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(INV_ITEM_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BUSINESS_UNIT as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PLANT_ITEM_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(BUSINESS_UNIT as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PLANT_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(RESCH_OUT_FACTOR::text), '^^') 
            , '||', IFNULL(TRIM(RESCH_IN_FACTOR::text), '^^') 
            , '||', IFNULL(TRIM(DEMAND_FENCE_OF::text), '^^') 
            , '||', IFNULL(TRIM(PLAN_FENCE_OFF::text), '^^') 
            , '||', IFNULL(TRIM(PLAN_HORIZON::text), '^^') 
            , '||', IFNULL(TRIM(TRANSFER_MIN_ORDER::text), '^^') 
            , '||', IFNULL(TRIM(TRANSFER_MAX_ORDER::text), '^^') 
            , '||', IFNULL(TRIM(TRANS_ORD_MULTIPLE::text), '^^') 
            , '||', IFNULL(TRIM(TRANSFER_ORD_MOD::text), '^^') 
            , '||', IFNULL(TRIM(PUR_MIN_ORDER::text), '^^') 
            , '||', IFNULL(TRIM(PUR_MAX_ORDER::text), '^^') 
            , '||', IFNULL(TRIM(PUR_ORDER_MULTIPLE::text), '^^') 
            , '||', IFNULL(TRIM(PUR_ORDER_MOD::text), '^^') 
            , '||', IFNULL(TRIM(MFG_MOD_UNIT::text), '^^') 
            , '||', IFNULL(TRIM(MFG_MIN_ORDER::text), '^^') 
            , '||', IFNULL(TRIM(MFG_MAX_ORDER::text), '^^') 
            , '||', IFNULL(TRIM(MFG_ORDER_MULTIPLE::text), '^^') 
            , '||', IFNULL(TRIM(MFG_ORDER_MOD::text), '^^') 
            , '||', IFNULL(TRIM(MFG_LEAD_TIME_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(SAFETY_LEVEL::text), '^^') 
            , '||', IFNULL(TRIM(EXCESS_LEVEL::text), '^^') 
            , '||', IFNULL(TRIM(AUTO_APPROVE_MSG::text), '^^') 
            , '||', IFNULL(TRIM(PLANNER_CD::text), '^^') 
            , '||', IFNULL(TRIM(PURCHASE_YIELD::text), '^^') 
            , '||', IFNULL(TRIM(TRANSFER_YIELD::text), '^^') 
            , '||', IFNULL(TRIM(SALES_CONSUMP::text), '^^') 
            , '||', IFNULL(TRIM(PROD_CONSUMP::text), '^^') 
            , '||', IFNULL(TRIM(TRANS_CONSUMP::text), '^^') 
            , '||', IFNULL(TRIM(MSR_CONSUMP::text), '^^') 
            , '||', IFNULL(TRIM(EXTRA_CONSUMP::text), '^^') 
            , '||', IFNULL(TRIM(PL_AGG_DMD_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(RELEASED_ORDER::text), '^^') 
            , '||', IFNULL(TRIM(FIRMED_ORDER::text), '^^') 
            , '||', IFNULL(TRIM(PL_PRIO_FAMILY::text), '^^') 
            , '||', IFNULL(TRIM(USE_SHIPTO_LOC::text), '^^') 
            , '||', IFNULL(TRIM(PL_FIXED_PERIOD::text), '^^') 
            , '||', IFNULL(TRIM(PL_ITEM_EXPL::text), '^^') 
            , '||', IFNULL(TRIM(PL_PROJ_USE_DT::text), '^^') 
            , '||', IFNULL(TRIM(PLANNED_BY::text), '^^') 
            , '||', IFNULL(TRIM(CAP_FENCE_OFF::text), '^^') 
            , '||', IFNULL(TRIM(FCST_FULFILL_SIZE::text), '^^') 
            , '||', IFNULL(TRIM(FCST_ADJ_ACTION::text), '^^') 
            , '||', IFNULL(TRIM(EARLY_FENCE::text), '^^') 
            , '||', IFNULL(TRIM(GBL_EARLY_FENCE::text), '^^') 
            , '||', IFNULL(TRIM(PL_SEARCH_DEPTH::text), '^^') 
            , '||', IFNULL(TRIM(SPOT_BUY_FLG::text), '^^') 
            , '||', IFNULL(TRIM(DP_UOMGROUP::text), '^^') 
            , '||', IFNULL(TRIM(USE_PUR_ORD_MOD::text), '^^') 
            , '||', IFNULL(TRIM(USE_REGION_VNDR::text), '^^') 
            , '||', IFNULL(TRIM(PL_RESCHEDULE_TOL::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
