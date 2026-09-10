---- SRC LAYER ----
WITH
SRC_S              as ( SELECT * FROM {{ source('lrsn_psft_sysadm', 'ps_bus_unit_tbl_in') }} as SRC 
                        /* The following qualify clause is required to pick the latest change for a day when there are Intra day changes,
                            when Fivetran resync triggered by manual sync multiple times in a day(Resync Happens usually once per week currently). Ex. cust_id ='36196' */
                            qualify 1 = row_number() over(partition by BUSINESS_UNIT, _fivetran_synced order by psa_load_dts desc) ),
SRC_A              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S              as ( SELECT * FROM lrsn_psft_sysadm.ps_bus_unit_tbl_in )
, SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        BUSINESS_UNIT                                                as                                           PLANT_BK
      , BUSINESS_UNIT
      , BASE_CURRENCY
      , BUSINESS_UNIT_GL
      , DOWNTIME_FLAG
      , IBU_GROUP
      , BU_STATUS
      , WRKFL_SHIPPING
      , LOCATION
      , INVENTORY_TAG_ID
      , STAGING_ID
      , PICK_BATCH_ID
      , SHIPPING_ID
      , COUNTING_EVENT_ID
      , REPLENISH_ID
      , ACCTG_LINE_NO
      , CART_COUNT_ID
      , RUN_CNTL_SEQ_NBR
      , BUSIN_UNIT_TYPE
      , BUSINESS_UNIT_BI
      , BILL_TYPE_ID
      , BILL_SOURCE_ID
      , INCL_QUAR_AVAIL
      , LOT_AUTO_ADD_FLG
      , LOT_ALLOC_FLG
      , LOT_ALLOC_WL_FLG
      , COMBO_EDIT_FLG
      , COMBO_VALID_FLG
      , SPEEDTYPE_LVL
      , FREIGHT_PROD_ID
      , MISC_CHRG_PROD_ID
      , TRANSIT_COST_TYP
      , DST_ID_REV
      , DST_ID_DIS
      , DST_ID_SUR
      , APPL_JRNL_ID
      , ALLOW_NEG_INV_FLG
      , DISPLAY_MESSAGE
      , PICK_EXT_FILE_CNT
      , CART_REPLEN_OPT
      , CONS_NON_STOCK
      , BCKORDR_CNCL_FLAG
      , PTWY_PLAN_ID
      , TAXPAYER_ID
      , MSR_MONTHS
      , REASON_CD
      , RETURN_TO_IBU
      , DISTRIB_TYPE
      , ACCOUNT
      , ALTACCT
      , DEPTID
      , OPERATING_UNIT
      , PRODUCT
      , FUND_CODE
      , CLASS_FLD
      , PROGRAM_CODE
      , BUDGET_REF
      , AFFILIATE
      , AFFILIATE_INTRA1
      , AFFILIATE_INTRA2
      , CHARTFIELD1
      , CHARTFIELD2
      , CHARTFIELD3
      , BUSINESS_UNIT_PC
      , PROJECT_ID
      , ACTIVITY_ID
      , RESOURCE_TYPE
      , RESOURCE_CATEGORY
      , RESOURCE_SUB_CAT
      , ANALYSIS_TYPE
      , STATISTICS_CODE
      , TSE_TRIGGER
      , GENERATE_ASN_FLG
      , PICK_RELEASE_ID
      , USE_ROUTE_FLAG
      , BUS_UNIT_BI_TR
      , BILL_SOURCE_TR
      , BILL_TYPE_TR
      , FRT_RULE_CD
      , ALLOW_XFR_INV_FLG
      , BUSINESS_UNIT_AP
      , CUR_RT_TYPE
      , FREIGHT_TERMS
      , FRT_CHRG_METHOD
      , FREIGHT_CALC
      , EXPORT_INT
      , EXPORT_HOLD
      , VALIDATE_ALL
      , AUTO_CLOSE_RCV_FLG
      , AUTO_ROUND_OPT
      , EST_SHIP_ID_SEQ
      , EXPORTER_ECCN
      , EXPORT_LIC_NBR
      , EXT_WHSE_CNTL_FLG
      , WARN_TEMPL_CHG
      , INT_LOC_EXP_RCPT
      , OMBI_DIS_DTL_FLG
      , PENALTY_PROD_ID
      , REBATE_PROD_ID
      , PACK_PARTIAL_FLG
      , ORD_CANCEL_OPT
      , HOLD_CD
      , RESTOCK_PROD_ID
      , SHIP_TO_CUST_ID
      , ADDRESS_SEQ_NUM
      , AUTO_PUTAWAY_FLAG
      , RUN_AUTOPTWY_FLAG
      , RMA_BILL_BY_ID
      , REASON_CD_SHIP
      , USE_TMS_KEY_FLG
      , VMI_UNIT_FLG
      , VMI_APPROVAL
      , TRFT_RULE_CD
      , TAX_CD
      , SSRC_ITEM_OPTION
      , SSRC_ITEM_TMPLT
      , BU_FSS_FLG
      , ALLOW_MV_REL_FLG
      , IN_IUT_PRICE_FLAG
      , IN_EXP_TPRC_FLAG
      , IN_SOB_TPRC_FLAG
      , AII_GROUP
      , ALLOW_MASS_CHANGE
      , BARCD_PARSE
      , BARCD_PARSE_VLE_TO
      , INV_BARCD_PARSE
      , _FIVETRAN_DELETED
      , _FIVETRAN_ID
      , _FIVETRAN_SYNCED
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED )                   as                                           LOAD_DTS
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
        PLANT_BK
      , BUSINESS_UNIT
      , BASE_CURRENCY
      , BUSINESS_UNIT_GL
      , DOWNTIME_FLAG
      , IBU_GROUP
      , BU_STATUS
      , WRKFL_SHIPPING
      , LOCATION
      , INVENTORY_TAG_ID
      , STAGING_ID
      , PICK_BATCH_ID
      , SHIPPING_ID
      , COUNTING_EVENT_ID
      , REPLENISH_ID
      , ACCTG_LINE_NO
      , CART_COUNT_ID
      , RUN_CNTL_SEQ_NBR
      , BUSIN_UNIT_TYPE
      , BUSINESS_UNIT_BI
      , BILL_TYPE_ID
      , BILL_SOURCE_ID
      , INCL_QUAR_AVAIL
      , LOT_AUTO_ADD_FLG
      , LOT_ALLOC_FLG
      , LOT_ALLOC_WL_FLG
      , COMBO_EDIT_FLG
      , COMBO_VALID_FLG
      , SPEEDTYPE_LVL
      , FREIGHT_PROD_ID
      , MISC_CHRG_PROD_ID
      , TRANSIT_COST_TYP
      , DST_ID_REV
      , DST_ID_DIS
      , DST_ID_SUR
      , APPL_JRNL_ID
      , ALLOW_NEG_INV_FLG
      , DISPLAY_MESSAGE
      , PICK_EXT_FILE_CNT
      , CART_REPLEN_OPT
      , CONS_NON_STOCK
      , BCKORDR_CNCL_FLAG
      , PTWY_PLAN_ID
      , TAXPAYER_ID
      , MSR_MONTHS
      , REASON_CD
      , RETURN_TO_IBU
      , DISTRIB_TYPE
      , ACCOUNT
      , ALTACCT
      , DEPTID
      , OPERATING_UNIT
      , PRODUCT
      , FUND_CODE
      , CLASS_FLD
      , PROGRAM_CODE
      , BUDGET_REF
      , AFFILIATE
      , AFFILIATE_INTRA1
      , AFFILIATE_INTRA2
      , CHARTFIELD1
      , CHARTFIELD2
      , CHARTFIELD3
      , BUSINESS_UNIT_PC
      , PROJECT_ID
      , ACTIVITY_ID
      , RESOURCE_TYPE
      , RESOURCE_CATEGORY
      , RESOURCE_SUB_CAT
      , ANALYSIS_TYPE
      , STATISTICS_CODE
      , TSE_TRIGGER
      , GENERATE_ASN_FLG
      , PICK_RELEASE_ID
      , USE_ROUTE_FLAG
      , BUS_UNIT_BI_TR
      , BILL_SOURCE_TR
      , BILL_TYPE_TR
      , FRT_RULE_CD
      , ALLOW_XFR_INV_FLG
      , BUSINESS_UNIT_AP
      , CUR_RT_TYPE
      , FREIGHT_TERMS
      , FRT_CHRG_METHOD
      , FREIGHT_CALC
      , EXPORT_INT
      , EXPORT_HOLD
      , VALIDATE_ALL
      , AUTO_CLOSE_RCV_FLG
      , AUTO_ROUND_OPT
      , EST_SHIP_ID_SEQ
      , EXPORTER_ECCN
      , EXPORT_LIC_NBR
      , EXT_WHSE_CNTL_FLG
      , WARN_TEMPL_CHG
      , INT_LOC_EXP_RCPT
      , OMBI_DIS_DTL_FLG
      , PENALTY_PROD_ID
      , REBATE_PROD_ID
      , PACK_PARTIAL_FLG
      , ORD_CANCEL_OPT
      , HOLD_CD
      , RESTOCK_PROD_ID
      , SHIP_TO_CUST_ID
      , ADDRESS_SEQ_NUM
      , AUTO_PUTAWAY_FLAG
      , RUN_AUTOPTWY_FLAG
      , RMA_BILL_BY_ID
      , REASON_CD_SHIP
      , USE_TMS_KEY_FLG
      , VMI_UNIT_FLG
      , VMI_APPROVAL
      , TRFT_RULE_CD
      , TAX_CD
      , SSRC_ITEM_OPTION
      , SSRC_ITEM_TMPLT
      , BU_FSS_FLG
      , ALLOW_MV_REL_FLG
      , IN_IUT_PRICE_FLAG
      , IN_EXP_TPRC_FLAG
      , IN_SOB_TPRC_FLAG
      , AII_GROUP
      , ALLOW_MASS_CHANGE
      , BARCD_PARSE
      , BARCD_PARSE_VLE_TO
      , INV_BARCD_PARSE
      , _FIVETRAN_DELETED
      , _FIVETRAN_ID
      , _FIVETRAN_SYNCED
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , LOAD_DTS
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
    WHERE rec_src = 'USSDBR.ORCL.PSFTPRD.PS_BUS_UNIT_TBL_IN'
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
          PLANT_BK
        , BUSINESS_UNIT
        , BASE_CURRENCY
        , BUSINESS_UNIT_GL
        , DOWNTIME_FLAG
        , IBU_GROUP
        , BU_STATUS
        , WRKFL_SHIPPING
        , LOCATION
        , INVENTORY_TAG_ID
        , STAGING_ID
        , PICK_BATCH_ID
        , SHIPPING_ID
        , COUNTING_EVENT_ID
        , REPLENISH_ID
        , ACCTG_LINE_NO
        , CART_COUNT_ID
        , RUN_CNTL_SEQ_NBR
        , BUSIN_UNIT_TYPE
        , BUSINESS_UNIT_BI
        , BILL_TYPE_ID
        , BILL_SOURCE_ID
        , INCL_QUAR_AVAIL
        , LOT_AUTO_ADD_FLG
        , LOT_ALLOC_FLG
        , LOT_ALLOC_WL_FLG
        , COMBO_EDIT_FLG
        , COMBO_VALID_FLG
        , SPEEDTYPE_LVL
        , FREIGHT_PROD_ID
        , MISC_CHRG_PROD_ID
        , TRANSIT_COST_TYP
        , DST_ID_REV
        , DST_ID_DIS
        , DST_ID_SUR
        , APPL_JRNL_ID
        , ALLOW_NEG_INV_FLG
        , DISPLAY_MESSAGE
        , PICK_EXT_FILE_CNT
        , CART_REPLEN_OPT
        , CONS_NON_STOCK
        , BCKORDR_CNCL_FLAG
        , PTWY_PLAN_ID
        , TAXPAYER_ID
        , MSR_MONTHS
        , REASON_CD
        , RETURN_TO_IBU
        , DISTRIB_TYPE
        , ACCOUNT
        , ALTACCT
        , DEPTID
        , OPERATING_UNIT
        , PRODUCT
        , FUND_CODE
        , CLASS_FLD
        , PROGRAM_CODE
        , BUDGET_REF
        , AFFILIATE
        , AFFILIATE_INTRA1
        , AFFILIATE_INTRA2
        , CHARTFIELD1
        , CHARTFIELD2
        , CHARTFIELD3
        , BUSINESS_UNIT_PC
        , PROJECT_ID
        , ACTIVITY_ID
        , RESOURCE_TYPE
        , RESOURCE_CATEGORY
        , RESOURCE_SUB_CAT
        , ANALYSIS_TYPE
        , STATISTICS_CODE
        , TSE_TRIGGER
        , GENERATE_ASN_FLG
        , PICK_RELEASE_ID
        , USE_ROUTE_FLAG
        , BUS_UNIT_BI_TR
        , BILL_SOURCE_TR
        , BILL_TYPE_TR
        , FRT_RULE_CD
        , ALLOW_XFR_INV_FLG
        , BUSINESS_UNIT_AP
        , CUR_RT_TYPE
        , FREIGHT_TERMS
        , FRT_CHRG_METHOD
        , FREIGHT_CALC
        , EXPORT_INT
        , EXPORT_HOLD
        , VALIDATE_ALL
        , AUTO_CLOSE_RCV_FLG
        , AUTO_ROUND_OPT
        , EST_SHIP_ID_SEQ
        , EXPORTER_ECCN
        , EXPORT_LIC_NBR
        , EXT_WHSE_CNTL_FLG
        , WARN_TEMPL_CHG
        , INT_LOC_EXP_RCPT
        , OMBI_DIS_DTL_FLG
        , PENALTY_PROD_ID
        , REBATE_PROD_ID
        , PACK_PARTIAL_FLG
        , ORD_CANCEL_OPT
        , HOLD_CD
        , RESTOCK_PROD_ID
        , SHIP_TO_CUST_ID
        , ADDRESS_SEQ_NUM
        , AUTO_PUTAWAY_FLAG
        , RUN_AUTOPTWY_FLAG
        , RMA_BILL_BY_ID
        , REASON_CD_SHIP
        , USE_TMS_KEY_FLG
        , VMI_UNIT_FLG
        , VMI_APPROVAL
        , TRFT_RULE_CD
        , TAX_CD
        , SSRC_ITEM_OPTION
        , SSRC_ITEM_TMPLT
        , BU_FSS_FLG
        , ALLOW_MV_REL_FLG
        , IN_IUT_PRICE_FLAG
        , IN_EXP_TPRC_FLAG
        , IN_SOB_TPRC_FLAG
        , AII_GROUP
        , ALLOW_MASS_CHANGE
        , BARCD_PARSE
        , BARCD_PARSE_VLE_TO
        , INV_BARCD_PARSE
        , _FIVETRAN_DELETED
        , _FIVETRAN_ID
        , _FIVETRAN_SYNCED
        , PSA_DELETE_IND
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PLANT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PLANT_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(BASE_CURRENCY::text), '^^') 
            , '||', IFNULL(TRIM(BUSINESS_UNIT_GL::text), '^^') 
            , '||', IFNULL(TRIM(DOWNTIME_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(IBU_GROUP::text), '^^') 
            , '||', IFNULL(TRIM(BU_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(WRKFL_SHIPPING::text), '^^') 
            , '||', IFNULL(TRIM(LOCATION::text), '^^') 
            , '||', IFNULL(TRIM(INVENTORY_TAG_ID::text), '^^') 
            , '||', IFNULL(TRIM(STAGING_ID::text), '^^') 
            , '||', IFNULL(TRIM(PICK_BATCH_ID::text), '^^') 
            , '||', IFNULL(TRIM(SHIPPING_ID::text), '^^') 
            , '||', IFNULL(TRIM(COUNTING_EVENT_ID::text), '^^') 
            , '||', IFNULL(TRIM(REPLENISH_ID::text), '^^') 
            , '||', IFNULL(TRIM(ACCTG_LINE_NO::text), '^^') 
            , '||', IFNULL(TRIM(CART_COUNT_ID::text), '^^') 
            , '||', IFNULL(TRIM(RUN_CNTL_SEQ_NBR::text), '^^') 
            , '||', IFNULL(TRIM(BUSIN_UNIT_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(BUSINESS_UNIT_BI::text), '^^') 
            , '||', IFNULL(TRIM(BILL_TYPE_ID::text), '^^') 
            , '||', IFNULL(TRIM(BILL_SOURCE_ID::text), '^^') 
            , '||', IFNULL(TRIM(INCL_QUAR_AVAIL::text), '^^') 
            , '||', IFNULL(TRIM(LOT_AUTO_ADD_FLG::text), '^^') 
            , '||', IFNULL(TRIM(LOT_ALLOC_FLG::text), '^^') 
            , '||', IFNULL(TRIM(LOT_ALLOC_WL_FLG::text), '^^') 
            , '||', IFNULL(TRIM(COMBO_EDIT_FLG::text), '^^') 
            , '||', IFNULL(TRIM(COMBO_VALID_FLG::text), '^^') 
            , '||', IFNULL(TRIM(SPEEDTYPE_LVL::text), '^^') 
            , '||', IFNULL(TRIM(FREIGHT_PROD_ID::text), '^^') 
            , '||', IFNULL(TRIM(MISC_CHRG_PROD_ID::text), '^^') 
            , '||', IFNULL(TRIM(TRANSIT_COST_TYP::text), '^^') 
            , '||', IFNULL(TRIM(DST_ID_REV::text), '^^') 
            , '||', IFNULL(TRIM(DST_ID_DIS::text), '^^') 
            , '||', IFNULL(TRIM(DST_ID_SUR::text), '^^') 
            , '||', IFNULL(TRIM(APPL_JRNL_ID::text), '^^') 
            , '||', IFNULL(TRIM(ALLOW_NEG_INV_FLG::text), '^^') 
            , '||', IFNULL(TRIM(DISPLAY_MESSAGE::text), '^^') 
            , '||', IFNULL(TRIM(PICK_EXT_FILE_CNT::text), '^^') 
            , '||', IFNULL(TRIM(CART_REPLEN_OPT::text), '^^') 
            , '||', IFNULL(TRIM(CONS_NON_STOCK::text), '^^') 
            , '||', IFNULL(TRIM(BCKORDR_CNCL_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(PTWY_PLAN_ID::text), '^^') 
            , '||', IFNULL(TRIM(TAXPAYER_ID::text), '^^') 
            , '||', IFNULL(TRIM(MSR_MONTHS::text), '^^') 
            , '||', IFNULL(TRIM(REASON_CD::text), '^^') 
            , '||', IFNULL(TRIM(RETURN_TO_IBU::text), '^^') 
            , '||', IFNULL(TRIM(DISTRIB_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(ACCOUNT::text), '^^') 
            , '||', IFNULL(TRIM(ALTACCT::text), '^^') 
            , '||', IFNULL(TRIM(DEPTID::text), '^^') 
            , '||', IFNULL(TRIM(OPERATING_UNIT::text), '^^') 
            , '||', IFNULL(TRIM(PRODUCT::text), '^^') 
            , '||', IFNULL(TRIM(FUND_CODE::text), '^^') 
            , '||', IFNULL(TRIM(CLASS_FLD::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_CODE::text), '^^') 
            , '||', IFNULL(TRIM(BUDGET_REF::text), '^^') 
            , '||', IFNULL(TRIM(AFFILIATE::text), '^^') 
            , '||', IFNULL(TRIM(AFFILIATE_INTRA1::text), '^^') 
            , '||', IFNULL(TRIM(AFFILIATE_INTRA2::text), '^^') 
            , '||', IFNULL(TRIM(CHARTFIELD1::text), '^^') 
            , '||', IFNULL(TRIM(CHARTFIELD2::text), '^^') 
            , '||', IFNULL(TRIM(CHARTFIELD3::text), '^^') 
            , '||', IFNULL(TRIM(BUSINESS_UNIT_PC::text), '^^') 
            , '||', IFNULL(TRIM(PROJECT_ID::text), '^^') 
            , '||', IFNULL(TRIM(ACTIVITY_ID::text), '^^') 
            , '||', IFNULL(TRIM(RESOURCE_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(RESOURCE_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(RESOURCE_SUB_CAT::text), '^^') 
            , '||', IFNULL(TRIM(ANALYSIS_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(STATISTICS_CODE::text), '^^') 
            , '||', IFNULL(TRIM(TSE_TRIGGER::text), '^^') 
            , '||', IFNULL(TRIM(GENERATE_ASN_FLG::text), '^^') 
            , '||', IFNULL(TRIM(PICK_RELEASE_ID::text), '^^') 
            , '||', IFNULL(TRIM(USE_ROUTE_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(BUS_UNIT_BI_TR::text), '^^') 
            , '||', IFNULL(TRIM(BILL_SOURCE_TR::text), '^^') 
            , '||', IFNULL(TRIM(BILL_TYPE_TR::text), '^^') 
            , '||', IFNULL(TRIM(FRT_RULE_CD::text), '^^') 
            , '||', IFNULL(TRIM(ALLOW_XFR_INV_FLG::text), '^^') 
            , '||', IFNULL(TRIM(BUSINESS_UNIT_AP::text), '^^') 
            , '||', IFNULL(TRIM(CUR_RT_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(FREIGHT_TERMS::text), '^^') 
            , '||', IFNULL(TRIM(FRT_CHRG_METHOD::text), '^^') 
            , '||', IFNULL(TRIM(FREIGHT_CALC::text), '^^') 
            , '||', IFNULL(TRIM(EXPORT_INT::text), '^^') 
            , '||', IFNULL(TRIM(EXPORT_HOLD::text), '^^') 
            , '||', IFNULL(TRIM(VALIDATE_ALL::text), '^^') 
            , '||', IFNULL(TRIM(AUTO_CLOSE_RCV_FLG::text), '^^') 
            , '||', IFNULL(TRIM(AUTO_ROUND_OPT::text), '^^') 
            , '||', IFNULL(TRIM(EST_SHIP_ID_SEQ::text), '^^') 
            , '||', IFNULL(TRIM(EXPORTER_ECCN::text), '^^') 
            , '||', IFNULL(TRIM(EXPORT_LIC_NBR::text), '^^') 
            , '||', IFNULL(TRIM(EXT_WHSE_CNTL_FLG::text), '^^') 
            , '||', IFNULL(TRIM(WARN_TEMPL_CHG::text), '^^') 
            , '||', IFNULL(TRIM(INT_LOC_EXP_RCPT::text), '^^') 
            , '||', IFNULL(TRIM(OMBI_DIS_DTL_FLG::text), '^^') 
            , '||', IFNULL(TRIM(PENALTY_PROD_ID::text), '^^') 
            , '||', IFNULL(TRIM(REBATE_PROD_ID::text), '^^') 
            , '||', IFNULL(TRIM(PACK_PARTIAL_FLG::text), '^^') 
            , '||', IFNULL(TRIM(ORD_CANCEL_OPT::text), '^^') 
            , '||', IFNULL(TRIM(HOLD_CD::text), '^^') 
            , '||', IFNULL(TRIM(RESTOCK_PROD_ID::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_TO_CUST_ID::text), '^^') 
            , '||', IFNULL(TRIM(ADDRESS_SEQ_NUM::text), '^^') 
            , '||', IFNULL(TRIM(AUTO_PUTAWAY_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(RUN_AUTOPTWY_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(RMA_BILL_BY_ID::text), '^^') 
            , '||', IFNULL(TRIM(REASON_CD_SHIP::text), '^^') 
            , '||', IFNULL(TRIM(USE_TMS_KEY_FLG::text), '^^') 
            , '||', IFNULL(TRIM(VMI_UNIT_FLG::text), '^^') 
            , '||', IFNULL(TRIM(VMI_APPROVAL::text), '^^') 
            , '||', IFNULL(TRIM(TRFT_RULE_CD::text), '^^') 
            , '||', IFNULL(TRIM(TAX_CD::text), '^^') 
            , '||', IFNULL(TRIM(SSRC_ITEM_OPTION::text), '^^') 
            , '||', IFNULL(TRIM(SSRC_ITEM_TMPLT::text), '^^') 
            , '||', IFNULL(TRIM(BU_FSS_FLG::text), '^^') 
            , '||', IFNULL(TRIM(ALLOW_MV_REL_FLG::text), '^^') 
            , '||', IFNULL(TRIM(IN_IUT_PRICE_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(IN_EXP_TPRC_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(IN_SOB_TPRC_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(AII_GROUP::text), '^^') 
            , '||', IFNULL(TRIM(ALLOW_MASS_CHANGE::text), '^^') 
            , '||', IFNULL(TRIM(BARCD_PARSE::text), '^^') 
            , '||', IFNULL(TRIM(BARCD_PARSE_VLE_TO::text), '^^') 
            , '||', IFNULL(TRIM(INV_BARCD_PARSE::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
