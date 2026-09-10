---- SRC LAYER ----
WITH
SRC_SBPLLR         as ( SELECT * FROM {{ ref('v_psa_stg_plant__lrsn_psft') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_SBPLLR         as ( SELECT * FROM STAGING.v_psa_stg_plant__lrsn_psft  )
*/
---- LOGIC LAYER ----

, LOGIC_SBPLLR as (
    SELECT
        PLANT_HK
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
      , HASHDIFF
    FROM SRC_SBPLLR
)
---- RENAME LAYER ----

, RENAME_SBPLLR as (
    SELECT
        PLANT_HK
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
      , HASHDIFF
    FROM LOGIC_SBPLLR
)
---- FILTER LAYER ----

, FILTER_SBPLLR as (
    SELECT *
    FROM RENAME_SBPLLR
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_SBPLLR
)

---- FINAL LAYER ----
SELECT
          PLANT_HK
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
        , HASHDIFF
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.PLANT_HK = JOIN_RESULT.PLANT_HK 
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %} 
{% if not is_incremental() %}
/*the following qualify is to restrict multiple loads of touched records during the initial build. Ex: multiple row per hk, hashdiff */
qualify 1= row_number()over(partition by PLANT_HK , HASHDIFF order by PSA_LOAD_DTS)
union all
    SELECT        MD5_BINARY(GR.VALUE) AS PLANT_HK
    , GR.VALUE as BUSINESS_UNIT
    , null as BASE_CURRENCY
    , null as BUSINESS_UNIT_GL
    , null as DOWNTIME_FLAG
    , null as IBU_GROUP
    , null as BU_STATUS
    , null as WRKFL_SHIPPING
    , null as LOCATION
    , null as INVENTORY_TAG_ID
    , null as STAGING_ID
    , null as PICK_BATCH_ID
    , null as SHIPPING_ID
    , null as COUNTING_EVENT_ID
    , null as REPLENISH_ID
    , null as ACCTG_LINE_NO
    , null as CART_COUNT_ID
    , null as RUN_CNTL_SEQ_NBR
    , null as BUSIN_UNIT_TYPE
    , null as BUSINESS_UNIT_BI
    , null as BILL_TYPE_ID
    , null as BILL_SOURCE_ID
    , null as INCL_QUAR_AVAIL
    , null as LOT_AUTO_ADD_FLG
    , null as LOT_ALLOC_FLG
    , null as LOT_ALLOC_WL_FLG
    , null as COMBO_EDIT_FLG
    , null as COMBO_VALID_FLG
    , null as SPEEDTYPE_LVL
    , null as FREIGHT_PROD_ID
    , null as MISC_CHRG_PROD_ID
    , null as TRANSIT_COST_TYP
    , null as DST_ID_REV
    , null as DST_ID_DIS
    , null as DST_ID_SUR
    , null as APPL_JRNL_ID
    , null as ALLOW_NEG_INV_FLG
    , null as DISPLAY_MESSAGE
    , null as PICK_EXT_FILE_CNT
    , null as CART_REPLEN_OPT
    , null as CONS_NON_STOCK
    , null as BCKORDR_CNCL_FLAG
    , null as PTWY_PLAN_ID
    , null as TAXPAYER_ID
    , null as MSR_MONTHS
    , null as REASON_CD
    , null as RETURN_TO_IBU
    , null as DISTRIB_TYPE
    , null as ACCOUNT
    , null as ALTACCT
    , null as DEPTID
    , null as OPERATING_UNIT
    , null as PRODUCT
    , null as FUND_CODE
    , null as CLASS_FLD
    , null as PROGRAM_CODE
    , null as BUDGET_REF
    , null as AFFILIATE
    , null as AFFILIATE_INTRA1
    , null as AFFILIATE_INTRA2
    , null as CHARTFIELD1
    , null as CHARTFIELD2
    , null as CHARTFIELD3
    , null as BUSINESS_UNIT_PC
    , null as PROJECT_ID
    , null as ACTIVITY_ID
    , null as RESOURCE_TYPE
    , null as RESOURCE_CATEGORY
    , null as RESOURCE_SUB_CAT
    , null as ANALYSIS_TYPE
    , null as STATISTICS_CODE
    , null as TSE_TRIGGER
    , null as GENERATE_ASN_FLG
    , null as PICK_RELEASE_ID
    , null as USE_ROUTE_FLAG
    , null as BUS_UNIT_BI_TR
    , null as BILL_SOURCE_TR
    , null as BILL_TYPE_TR
    , null as FRT_RULE_CD
    , null as ALLOW_XFR_INV_FLG
    , null as BUSINESS_UNIT_AP
    , null as CUR_RT_TYPE
    , null as FREIGHT_TERMS
    , null as FRT_CHRG_METHOD
    , null as FREIGHT_CALC
    , null as EXPORT_INT
    , null as EXPORT_HOLD
    , null as VALIDATE_ALL
    , null as AUTO_CLOSE_RCV_FLG
    , null as AUTO_ROUND_OPT
    , null as EST_SHIP_ID_SEQ
    , null as EXPORTER_ECCN
    , null as EXPORT_LIC_NBR
    , null as EXT_WHSE_CNTL_FLG
    , null as WARN_TEMPL_CHG
    , null as INT_LOC_EXP_RCPT
    , null as OMBI_DIS_DTL_FLG
    , null as PENALTY_PROD_ID
    , null as REBATE_PROD_ID
    , null as PACK_PARTIAL_FLG
    , null as ORD_CANCEL_OPT
    , null as HOLD_CD
    , null as RESTOCK_PROD_ID
    , null as SHIP_TO_CUST_ID
    , null as ADDRESS_SEQ_NUM
    , null as AUTO_PUTAWAY_FLAG
    , null as RUN_AUTOPTWY_FLAG
    , null as RMA_BILL_BY_ID
    , null as REASON_CD_SHIP
    , null as USE_TMS_KEY_FLG
    , null as VMI_UNIT_FLG
    , null as VMI_APPROVAL
    , null as TRFT_RULE_CD
    , null as TAX_CD
    , null as SSRC_ITEM_OPTION
    , null as SSRC_ITEM_TMPLT
    , null as BU_FSS_FLG
    , null as ALLOW_MV_REL_FLG
    , null as IN_IUT_PRICE_FLAG
    , null as IN_EXP_TPRC_FLAG
    , null as IN_SOB_TPRC_FLAG
    , null as AII_GROUP
    , null as ALLOW_MASS_CHANGE
    , null as BARCD_PARSE
    , null as BARCD_PARSE_VLE_TO
    , null as INV_BARCD_PARSE
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