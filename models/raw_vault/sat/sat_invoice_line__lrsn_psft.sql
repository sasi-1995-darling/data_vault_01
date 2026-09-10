---- SRC LAYER ----
WITH
SRC_SBILNLR        as ( SELECT * FROM {{ ref('v_psa_stg_bi_line__lrsn_psft') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_SBILNLR        as ( SELECT * FROM STAGING.v_psa_stg_bi_line__lrsn_psft )
*/
---- LOGIC LAYER ----

, LOGIC_SBILNLR as (
    SELECT
        INVOICE_LINE_HK
      , INVOICE
      , LINE_SEQ_NUM
      , BUSINESS_UNIT
      , INVOICE_LINE
      , ORIGINAL_INVOICE
      , ORIGINAL_LINE_SEQ
      , NEXT_ADJ_INVOICE
      , NEXT_ADJ_LINE_SEQ
      , PRIOR_ADJ_INVOICE
      , PRIOR_ADJ_LINE_SEQ
      , LATEST_INVOICE
      , LATEST_LINE_SEQ
      , BILL_SOURCE_ID
      , SUBCUST_QUAL1
      , SUBCUST_QUAL2
      , ADJ_LINE_TYPE
      , ADJUSTED_FLAG
      , LINE_TYPE
      , BI_CURRENCY_CD
      , BASE_CURRENCY
      , CURRENCY_CD_XEU
      , RT_EFFDT
      , CHARGE_FROM_DT
      , CHARGE_TO_DT
      , IDENTIFIER
      , DESCR
      , UNIT_OF_MEASURE
      , QTY
      , ORIG_QTY
      , UNIT_AMT
      , PRICE_RECALC_FLG
      , TAX_CD
      , TAX_EXEMPT_CERT
      , TAX_EXEMPT_FLG
      , GROSS_EXTENDED_AMT
      , NET_EXTENDED_AMT
      , ORIG_AMOUNT
      , GROSS_EXTENDED_BSE
      , NET_EXTENDED_BSE
      , GROSS_EXTENDED_XEU
      , NET_EXTENDED_XEU
      , TAX_AMT
      , TAX_AMT_BSE
      , TAX_AMT_XEU
      , TAX_PCT
      , FINAL_TAX_FLG
      , MAX_TAX_FLG
      , BI_TAX_TIMING
      , VAT_BASIS_AMT
      , VAT_BASIS_AMT_BSE
      , VAT_BASIS_AMT_XEU
      , VAT_AMT
      , VAT_AMT_BSE
      , VAT_AMT_XEU
      , VAT_TRANS_AMT
      , VAT_TRANS_AMT_BSE
      , VAT_TXN_TYPE_CD
      , TAX_CD_VAT
      , TAX_CD_VAT_PCT
      , VAT_APPLICABILITY
      , PROD_GRP_SETID
      , VAT_PRODUCT_GROUP
      , PRODUCT_KIT_ID
      , VAT_DISTRIB_STATUS
      , TAX_VAT_FLG
      , REV_RECOG_BASIS
      , DEFERRED_STATUS
      , ACCRUE_DT
      , TOT_LINE_DST_PCT
      , TOT_LINE_DFR_PCT
      , TOT_LINE_UAR_PCT
      , TOT_LINE_DST_AMT
      , TOT_LINE_DFR_AMT
      , TOT_LINE_UAR_AMT
      , TOT_LINE_DST_BSE
      , TOT_LINE_DFR_BSE
      , TOT_LINE_UAR_BSE
      , TOT_LINE_DST_XEU
      , TOT_LINE_DFR_XEU
      , TOT_LINE_UAR_XEU
      , TOT_DISCOUNT_AMT
      , TOT_SURCHARGE_AMT
      , TOT_DISCOUNT_BSE
      , TOT_SURCHARGE_BSE
      , TOT_DISCOUNT_XEU
      , TOT_SURCHARGE_XEU
      , LINE_DST_SEQ_NUM
      , LINE_DFR_SEQ_NUM
      , LINE_UAR_SEQ_NUM
      , LAST_NOTE_SEQ_NUM
      , ENTRY_TYPE
      , ENTRY_REASON
      , PC_DISTRIB_STATUS
      , PO_REF
      , PO_LINE
      , BUSINESS_UNIT_CA
      , CONTRACT_NUM
      , CONTRACT_DT
      , CONTRACT_TYPE
      , BILL_PLAN_ID
      , BPLAN_LN_NBR
      , EVENT_OCCURRENCE
      , XREF_SEQ_NUM
      , CONTRACT_PPD_SEQ
      , BUSINESS_UNIT_OM
      , ORDER_NO
      , ORDER_DATE
      , ORDER_INT_LINE_NO
      , SCHED_LINE_NBR
      , BUSINESS_UNIT_RMA
      , RMA_ID
      , RMA_LINE_NBR
      , PRODUCT_ID
      , DIST_CFG_FLAG
      , FREIGHT_TERMS
      , BILL_OF_LADING
      , SHIP_TO_CUST_ID
      , SHIP_TO_ADDR_NUM
      , SHIP_ID
      , SHIP_TYPE_ID
      , SHIP_FROM_BU
      , SHIP_DATE
      , SHIP_TIME
      , SEQUENCE_NBR
      , SOLD_TO_CUST_ID
      , SOLD_TO_ADDR_NUM
      , RESOURCE_ID
      , ACTIVITY_TYPE
      , SYSTEM_SOURCE
      , EMPLID
      , SSN
      , EMPL_RCD
      , SERVICE_CUST_ID
      , SERVICE_ADDR_NUM
      , START_DT
      , END_DT
      , ACCUMULATE
      , ERROR_STATUS_BI
      , CONTRACT_LINE_NUM
      , BUSINESS_UNIT_TO
      , IST_TXN_FLG
      , IST_DISTRIB_STATUS
      , INVENTORY_ITEM
      , FISCAL_REGIME
      , NATURE_OF_TXN1
      , NATURE_OF_TXN2
      , IDENTIFIER_TBL
      , PACKSLIP_NO
      , DEFER_DT
      , PPRC_PROMO_CD
      , MERCH_TYPE
      , LIST_PRICE
      , ENTRY_EVENT
      , PHYSICAL_NATURE
      , VAT_TREATMENT
      , VAT_SVC_SUPPLY_FLG
      , VAT_SERVICE_TYPE
      , VAT_DST_ACCT_TYPE
      , VAT_ADVPAY_FLG
      , VOUCHER_STYLE
      , COUNTRY_LOC_BUYER
      , STATE_LOC_BUYER
      , COUNTRY_LOC_SELLER
      , STATE_LOC_SELLER
      , COUNTRY_VAT_SUPPLY
      , STATE_VAT_SUPPLY
      , COUNTRY_VAT_PERFRM
      , STATE_VAT_PERFRM
      , STATE_SHIP_TO
      , STATE_SHIP_FROM
      , EXD_CUST_CATG_CD
      , STX_CUST_CATG_CD
      , VAT_DFLT_DONE_FLG
      , INV_ITEM_ID
      , QTY_BASE
      , EXD_INVOICE_NO
      , EXD_INVOICE_LINE
      , ORG_SETID
      , ORG_CODE
      , ORG_TAX_LOC_CD
      , EXD_APPL_FLG
      , STX_APPL_FLG
      , EXS_DFLTS_APPLIED
      , EXS_TAX_TXN_TYPE
      , STX_TAX_AUTH_CD
      , COUNTRY_SHIP_TO
      , COUNTRY_SHIP_FROM
      , EXD_ITM_CATG_CD
      , STX_ITM_CATG_CD
      , EXS_SERV_TAX_FLG
      , STX_FORM_CD
      , FORM_DISTRIB_STAT
      , EXD_ASSESS_VALUE
      , EXD_UOM
      , EXD_CONVERSION_RT
      , EXD_USE_AV_FLG
      , EXD_TAX_RATE_CD
      , EXD_TAX_RATE_SRC
      , EXD_TAX_AMT
      , EXD_TAX_AMT_BSE
      , EXD_TAX_AMT_RPT
      , STX_TAX_RATE_CD
      , STX_TAX_RATE_SRC
      , STX_TAX_AMT
      , STX_TAX_AMT_BSE
      , STX_TAX_AMT_RPT
      , EXS_CURRENCY_RPTG
      , BUSINESS_UNIT_AMTO
      , ASSET_ID
      , PROFILE_ID
      , COST_TYPE
      , COUNTRY_VAT_BILLFR
      , COUNTRY_VAT_BILLTO
      , STATE_VAT_DEFAULT
      , LANG_DESCR_OVR
      , SO_ID
      , BUSINESS_UNIT_RF
      , SOURCE_REF_TYPE
      , SOURCE_REF_NO
      , SOURCE_REF_KEY
      , CA_PGP_SEQ
      , SUM_TEMPLATE_ID
      , SUM_GROUP_TYPE
      , SUM_GROUP_ID
      , CUST_DEPOSIT_ID
      , BUSINESS_UNIT_PC
      , PROJECT_ID
      , ACTIVITY_ID
      , RESOURCE_TYPE
      , RESOURCE_CATEGORY
      , RESOURCE_SUB_CAT
      , ANALYSIS_TYPE
      , USER_AMT1
      , USER_AMT2
      , USER_AMT1_BSE
      , USER_AMT2_BSE
      , USER_AMT1_XEU
      , USER_AMT2_XEU
      , USER_DT1
      , USER_DT2
      , USER1
      , USER2
      , USER3
      , USER4
      , USER5
      , USER6
      , USER7
      , USER8
      , USER9
      , OFAC_STATUS
      , SDN_PUBLISH_DATE
      , FSS_ACTIVITY_DT
      , FSS_USER_OVR
      , CUSTOMER_PO_LINE
      , CUSTOMER_PO_SCHED
      , PC_CF_CHANGE_FLG
      , CREDIT_REASON
      , VAT_RVRSE_CHG_GDS
      , TAX_CD_VAT_RVC
      , TAX_CD_VAT_RVC_PCT
      , VAT_AMT_RVC
      , VAT_AMT_RVC_BSE
      , VAT_AMT_RVC_XEU
      , TEMP_INVOICE
      , PROCESS_INSTANCE
      , ADD_DTTM
      , LAST_MAINT_OPRID
      , LAST_UPDATE_DTTM
      , _FIVETRAN_DELETED
      , _FIVETRAN_ID
      , _FIVETRAN_SYNCED
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , LOAD_DTS
      , REC_SRC
      , HASHDIFF
    FROM SRC_SBILNLR
)
---- RENAME LAYER ----

, RENAME_SBILNLR as (
    SELECT
        INVOICE_LINE_HK
      , INVOICE
      , LINE_SEQ_NUM
      , BUSINESS_UNIT
      , INVOICE_LINE
      , ORIGINAL_INVOICE
      , ORIGINAL_LINE_SEQ
      , NEXT_ADJ_INVOICE
      , NEXT_ADJ_LINE_SEQ
      , PRIOR_ADJ_INVOICE
      , PRIOR_ADJ_LINE_SEQ
      , LATEST_INVOICE
      , LATEST_LINE_SEQ
      , BILL_SOURCE_ID
      , SUBCUST_QUAL1
      , SUBCUST_QUAL2
      , ADJ_LINE_TYPE
      , ADJUSTED_FLAG
      , LINE_TYPE
      , BI_CURRENCY_CD
      , BASE_CURRENCY
      , CURRENCY_CD_XEU
      , RT_EFFDT
      , CHARGE_FROM_DT
      , CHARGE_TO_DT
      , IDENTIFIER
      , DESCR
      , UNIT_OF_MEASURE
      , QTY
      , ORIG_QTY
      , UNIT_AMT
      , PRICE_RECALC_FLG
      , TAX_CD
      , TAX_EXEMPT_CERT
      , TAX_EXEMPT_FLG
      , GROSS_EXTENDED_AMT
      , NET_EXTENDED_AMT
      , ORIG_AMOUNT
      , GROSS_EXTENDED_BSE
      , NET_EXTENDED_BSE
      , GROSS_EXTENDED_XEU
      , NET_EXTENDED_XEU
      , TAX_AMT
      , TAX_AMT_BSE
      , TAX_AMT_XEU
      , TAX_PCT
      , FINAL_TAX_FLG
      , MAX_TAX_FLG
      , BI_TAX_TIMING
      , VAT_BASIS_AMT
      , VAT_BASIS_AMT_BSE
      , VAT_BASIS_AMT_XEU
      , VAT_AMT
      , VAT_AMT_BSE
      , VAT_AMT_XEU
      , VAT_TRANS_AMT
      , VAT_TRANS_AMT_BSE
      , VAT_TXN_TYPE_CD
      , TAX_CD_VAT
      , TAX_CD_VAT_PCT
      , VAT_APPLICABILITY
      , PROD_GRP_SETID
      , VAT_PRODUCT_GROUP
      , PRODUCT_KIT_ID
      , VAT_DISTRIB_STATUS
      , TAX_VAT_FLG
      , REV_RECOG_BASIS
      , DEFERRED_STATUS
      , ACCRUE_DT
      , TOT_LINE_DST_PCT
      , TOT_LINE_DFR_PCT
      , TOT_LINE_UAR_PCT
      , TOT_LINE_DST_AMT
      , TOT_LINE_DFR_AMT
      , TOT_LINE_UAR_AMT
      , TOT_LINE_DST_BSE
      , TOT_LINE_DFR_BSE
      , TOT_LINE_UAR_BSE
      , TOT_LINE_DST_XEU
      , TOT_LINE_DFR_XEU
      , TOT_LINE_UAR_XEU
      , TOT_DISCOUNT_AMT
      , TOT_SURCHARGE_AMT
      , TOT_DISCOUNT_BSE
      , TOT_SURCHARGE_BSE
      , TOT_DISCOUNT_XEU
      , TOT_SURCHARGE_XEU
      , LINE_DST_SEQ_NUM
      , LINE_DFR_SEQ_NUM
      , LINE_UAR_SEQ_NUM
      , LAST_NOTE_SEQ_NUM
      , ENTRY_TYPE
      , ENTRY_REASON
      , PC_DISTRIB_STATUS
      , PO_REF
      , PO_LINE
      , BUSINESS_UNIT_CA
      , CONTRACT_NUM
      , CONTRACT_DT
      , CONTRACT_TYPE
      , BILL_PLAN_ID
      , BPLAN_LN_NBR
      , EVENT_OCCURRENCE
      , XREF_SEQ_NUM
      , CONTRACT_PPD_SEQ
      , BUSINESS_UNIT_OM
      , ORDER_NO
      , ORDER_DATE
      , ORDER_INT_LINE_NO
      , SCHED_LINE_NBR
      , BUSINESS_UNIT_RMA
      , RMA_ID
      , RMA_LINE_NBR
      , PRODUCT_ID
      , DIST_CFG_FLAG
      , FREIGHT_TERMS
      , BILL_OF_LADING
      , SHIP_TO_CUST_ID
      , SHIP_TO_ADDR_NUM
      , SHIP_ID
      , SHIP_TYPE_ID
      , SHIP_FROM_BU
      , SHIP_DATE
      , SHIP_TIME
      , SEQUENCE_NBR
      , SOLD_TO_CUST_ID
      , SOLD_TO_ADDR_NUM
      , RESOURCE_ID
      , ACTIVITY_TYPE
      , SYSTEM_SOURCE
      , EMPLID
      , SSN
      , EMPL_RCD
      , SERVICE_CUST_ID
      , SERVICE_ADDR_NUM
      , START_DT
      , END_DT
      , ACCUMULATE
      , ERROR_STATUS_BI
      , CONTRACT_LINE_NUM
      , BUSINESS_UNIT_TO
      , IST_TXN_FLG
      , IST_DISTRIB_STATUS
      , INVENTORY_ITEM
      , FISCAL_REGIME
      , NATURE_OF_TXN1
      , NATURE_OF_TXN2
      , IDENTIFIER_TBL
      , PACKSLIP_NO
      , DEFER_DT
      , PPRC_PROMO_CD
      , MERCH_TYPE
      , LIST_PRICE
      , ENTRY_EVENT
      , PHYSICAL_NATURE
      , VAT_TREATMENT
      , VAT_SVC_SUPPLY_FLG
      , VAT_SERVICE_TYPE
      , VAT_DST_ACCT_TYPE
      , VAT_ADVPAY_FLG
      , VOUCHER_STYLE
      , COUNTRY_LOC_BUYER
      , STATE_LOC_BUYER
      , COUNTRY_LOC_SELLER
      , STATE_LOC_SELLER
      , COUNTRY_VAT_SUPPLY
      , STATE_VAT_SUPPLY
      , COUNTRY_VAT_PERFRM
      , STATE_VAT_PERFRM
      , STATE_SHIP_TO
      , STATE_SHIP_FROM
      , EXD_CUST_CATG_CD
      , STX_CUST_CATG_CD
      , VAT_DFLT_DONE_FLG
      , INV_ITEM_ID
      , QTY_BASE
      , EXD_INVOICE_NO
      , EXD_INVOICE_LINE
      , ORG_SETID
      , ORG_CODE
      , ORG_TAX_LOC_CD
      , EXD_APPL_FLG
      , STX_APPL_FLG
      , EXS_DFLTS_APPLIED
      , EXS_TAX_TXN_TYPE
      , STX_TAX_AUTH_CD
      , COUNTRY_SHIP_TO
      , COUNTRY_SHIP_FROM
      , EXD_ITM_CATG_CD
      , STX_ITM_CATG_CD
      , EXS_SERV_TAX_FLG
      , STX_FORM_CD
      , FORM_DISTRIB_STAT
      , EXD_ASSESS_VALUE
      , EXD_UOM
      , EXD_CONVERSION_RT
      , EXD_USE_AV_FLG
      , EXD_TAX_RATE_CD
      , EXD_TAX_RATE_SRC
      , EXD_TAX_AMT
      , EXD_TAX_AMT_BSE
      , EXD_TAX_AMT_RPT
      , STX_TAX_RATE_CD
      , STX_TAX_RATE_SRC
      , STX_TAX_AMT
      , STX_TAX_AMT_BSE
      , STX_TAX_AMT_RPT
      , EXS_CURRENCY_RPTG
      , BUSINESS_UNIT_AMTO
      , ASSET_ID
      , PROFILE_ID
      , COST_TYPE
      , COUNTRY_VAT_BILLFR
      , COUNTRY_VAT_BILLTO
      , STATE_VAT_DEFAULT
      , LANG_DESCR_OVR
      , SO_ID
      , BUSINESS_UNIT_RF
      , SOURCE_REF_TYPE
      , SOURCE_REF_NO
      , SOURCE_REF_KEY
      , CA_PGP_SEQ
      , SUM_TEMPLATE_ID
      , SUM_GROUP_TYPE
      , SUM_GROUP_ID
      , CUST_DEPOSIT_ID
      , BUSINESS_UNIT_PC
      , PROJECT_ID
      , ACTIVITY_ID
      , RESOURCE_TYPE
      , RESOURCE_CATEGORY
      , RESOURCE_SUB_CAT
      , ANALYSIS_TYPE
      , USER_AMT1
      , USER_AMT2
      , USER_AMT1_BSE
      , USER_AMT2_BSE
      , USER_AMT1_XEU
      , USER_AMT2_XEU
      , USER_DT1
      , USER_DT2
      , USER1
      , USER2
      , USER3
      , USER4
      , USER5
      , USER6
      , USER7
      , USER8
      , USER9
      , OFAC_STATUS
      , SDN_PUBLISH_DATE
      , FSS_ACTIVITY_DT
      , FSS_USER_OVR
      , CUSTOMER_PO_LINE
      , CUSTOMER_PO_SCHED
      , PC_CF_CHANGE_FLG
      , CREDIT_REASON
      , VAT_RVRSE_CHG_GDS
      , TAX_CD_VAT_RVC
      , TAX_CD_VAT_RVC_PCT
      , VAT_AMT_RVC
      , VAT_AMT_RVC_BSE
      , VAT_AMT_RVC_XEU
      , TEMP_INVOICE
      , PROCESS_INSTANCE
      , ADD_DTTM
      , LAST_MAINT_OPRID
      , LAST_UPDATE_DTTM
      , _FIVETRAN_DELETED
      , _FIVETRAN_ID
      , _FIVETRAN_SYNCED
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , LOAD_DTS
      , REC_SRC
      , HASHDIFF
    FROM LOGIC_SBILNLR
)
---- FILTER LAYER ----

, FILTER_SBILNLR as (
    SELECT *
    FROM RENAME_SBILNLR
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_SBILNLR
)

---- FINAL LAYER ----
SELECT
          INVOICE_LINE_HK
        , INVOICE
        , LINE_SEQ_NUM
        , BUSINESS_UNIT
        , INVOICE_LINE
        , ORIGINAL_INVOICE
        , ORIGINAL_LINE_SEQ
        , NEXT_ADJ_INVOICE
        , NEXT_ADJ_LINE_SEQ
        , PRIOR_ADJ_INVOICE
        , PRIOR_ADJ_LINE_SEQ
        , LATEST_INVOICE
        , LATEST_LINE_SEQ
        , BILL_SOURCE_ID
        , SUBCUST_QUAL1
        , SUBCUST_QUAL2
        , ADJ_LINE_TYPE
        , ADJUSTED_FLAG
        , LINE_TYPE
        , BI_CURRENCY_CD
        , BASE_CURRENCY
        , CURRENCY_CD_XEU
        , RT_EFFDT
        , CHARGE_FROM_DT
        , CHARGE_TO_DT
        , IDENTIFIER
        , DESCR
        , UNIT_OF_MEASURE
        , QTY
        , ORIG_QTY
        , UNIT_AMT
        , PRICE_RECALC_FLG
        , TAX_CD
        , TAX_EXEMPT_CERT
        , TAX_EXEMPT_FLG
        , GROSS_EXTENDED_AMT
        , NET_EXTENDED_AMT
        , ORIG_AMOUNT
        , GROSS_EXTENDED_BSE
        , NET_EXTENDED_BSE
        , GROSS_EXTENDED_XEU
        , NET_EXTENDED_XEU
        , TAX_AMT
        , TAX_AMT_BSE
        , TAX_AMT_XEU
        , TAX_PCT
        , FINAL_TAX_FLG
        , MAX_TAX_FLG
        , BI_TAX_TIMING
        , VAT_BASIS_AMT
        , VAT_BASIS_AMT_BSE
        , VAT_BASIS_AMT_XEU
        , VAT_AMT
        , VAT_AMT_BSE
        , VAT_AMT_XEU
        , VAT_TRANS_AMT
        , VAT_TRANS_AMT_BSE
        , VAT_TXN_TYPE_CD
        , TAX_CD_VAT
        , TAX_CD_VAT_PCT
        , VAT_APPLICABILITY
        , PROD_GRP_SETID
        , VAT_PRODUCT_GROUP
        , PRODUCT_KIT_ID
        , VAT_DISTRIB_STATUS
        , TAX_VAT_FLG
        , REV_RECOG_BASIS
        , DEFERRED_STATUS
        , ACCRUE_DT
        , TOT_LINE_DST_PCT
        , TOT_LINE_DFR_PCT
        , TOT_LINE_UAR_PCT
        , TOT_LINE_DST_AMT
        , TOT_LINE_DFR_AMT
        , TOT_LINE_UAR_AMT
        , TOT_LINE_DST_BSE
        , TOT_LINE_DFR_BSE
        , TOT_LINE_UAR_BSE
        , TOT_LINE_DST_XEU
        , TOT_LINE_DFR_XEU
        , TOT_LINE_UAR_XEU
        , TOT_DISCOUNT_AMT
        , TOT_SURCHARGE_AMT
        , TOT_DISCOUNT_BSE
        , TOT_SURCHARGE_BSE
        , TOT_DISCOUNT_XEU
        , TOT_SURCHARGE_XEU
        , LINE_DST_SEQ_NUM
        , LINE_DFR_SEQ_NUM
        , LINE_UAR_SEQ_NUM
        , LAST_NOTE_SEQ_NUM
        , ENTRY_TYPE
        , ENTRY_REASON
        , PC_DISTRIB_STATUS
        , PO_REF
        , PO_LINE
        , BUSINESS_UNIT_CA
        , CONTRACT_NUM
        , CONTRACT_DT
        , CONTRACT_TYPE
        , BILL_PLAN_ID
        , BPLAN_LN_NBR
        , EVENT_OCCURRENCE
        , XREF_SEQ_NUM
        , CONTRACT_PPD_SEQ
        , BUSINESS_UNIT_OM
        , ORDER_NO
        , ORDER_DATE
        , ORDER_INT_LINE_NO
        , SCHED_LINE_NBR
        , BUSINESS_UNIT_RMA
        , RMA_ID
        , RMA_LINE_NBR
        , PRODUCT_ID
        , DIST_CFG_FLAG
        , FREIGHT_TERMS
        , BILL_OF_LADING
        , SHIP_TO_CUST_ID
        , SHIP_TO_ADDR_NUM
        , SHIP_ID
        , SHIP_TYPE_ID
        , SHIP_FROM_BU
        , SHIP_DATE
        , SHIP_TIME
        , SEQUENCE_NBR
        , SOLD_TO_CUST_ID
        , SOLD_TO_ADDR_NUM
        , RESOURCE_ID
        , ACTIVITY_TYPE
        , SYSTEM_SOURCE
        , EMPLID
        , SSN
        , EMPL_RCD
        , SERVICE_CUST_ID
        , SERVICE_ADDR_NUM
        , START_DT
        , END_DT
        , ACCUMULATE
        , ERROR_STATUS_BI
        , CONTRACT_LINE_NUM
        , BUSINESS_UNIT_TO
        , IST_TXN_FLG
        , IST_DISTRIB_STATUS
        , INVENTORY_ITEM
        , FISCAL_REGIME
        , NATURE_OF_TXN1
        , NATURE_OF_TXN2
        , IDENTIFIER_TBL
        , PACKSLIP_NO
        , DEFER_DT
        , PPRC_PROMO_CD
        , MERCH_TYPE
        , LIST_PRICE
        , ENTRY_EVENT
        , PHYSICAL_NATURE
        , VAT_TREATMENT
        , VAT_SVC_SUPPLY_FLG
        , VAT_SERVICE_TYPE
        , VAT_DST_ACCT_TYPE
        , VAT_ADVPAY_FLG
        , VOUCHER_STYLE
        , COUNTRY_LOC_BUYER
        , STATE_LOC_BUYER
        , COUNTRY_LOC_SELLER
        , STATE_LOC_SELLER
        , COUNTRY_VAT_SUPPLY
        , STATE_VAT_SUPPLY
        , COUNTRY_VAT_PERFRM
        , STATE_VAT_PERFRM
        , STATE_SHIP_TO
        , STATE_SHIP_FROM
        , EXD_CUST_CATG_CD
        , STX_CUST_CATG_CD
        , VAT_DFLT_DONE_FLG
        , INV_ITEM_ID
        , QTY_BASE
        , EXD_INVOICE_NO
        , EXD_INVOICE_LINE
        , ORG_SETID
        , ORG_CODE
        , ORG_TAX_LOC_CD
        , EXD_APPL_FLG
        , STX_APPL_FLG
        , EXS_DFLTS_APPLIED
        , EXS_TAX_TXN_TYPE
        , STX_TAX_AUTH_CD
        , COUNTRY_SHIP_TO
        , COUNTRY_SHIP_FROM
        , EXD_ITM_CATG_CD
        , STX_ITM_CATG_CD
        , EXS_SERV_TAX_FLG
        , STX_FORM_CD
        , FORM_DISTRIB_STAT
        , EXD_ASSESS_VALUE
        , EXD_UOM
        , EXD_CONVERSION_RT
        , EXD_USE_AV_FLG
        , EXD_TAX_RATE_CD
        , EXD_TAX_RATE_SRC
        , EXD_TAX_AMT
        , EXD_TAX_AMT_BSE
        , EXD_TAX_AMT_RPT
        , STX_TAX_RATE_CD
        , STX_TAX_RATE_SRC
        , STX_TAX_AMT
        , STX_TAX_AMT_BSE
        , STX_TAX_AMT_RPT
        , EXS_CURRENCY_RPTG
        , BUSINESS_UNIT_AMTO
        , ASSET_ID
        , PROFILE_ID
        , COST_TYPE
        , COUNTRY_VAT_BILLFR
        , COUNTRY_VAT_BILLTO
        , STATE_VAT_DEFAULT
        , LANG_DESCR_OVR
        , SO_ID
        , BUSINESS_UNIT_RF
        , SOURCE_REF_TYPE
        , SOURCE_REF_NO
        , SOURCE_REF_KEY
        , CA_PGP_SEQ
        , SUM_TEMPLATE_ID
        , SUM_GROUP_TYPE
        , SUM_GROUP_ID
        , CUST_DEPOSIT_ID
        , BUSINESS_UNIT_PC
        , PROJECT_ID
        , ACTIVITY_ID
        , RESOURCE_TYPE
        , RESOURCE_CATEGORY
        , RESOURCE_SUB_CAT
        , ANALYSIS_TYPE
        , USER_AMT1
        , USER_AMT2
        , USER_AMT1_BSE
        , USER_AMT2_BSE
        , USER_AMT1_XEU
        , USER_AMT2_XEU
        , USER_DT1
        , USER_DT2
        , USER1
        , USER2
        , USER3
        , USER4
        , USER5
        , USER6
        , USER7
        , USER8
        , USER9
        , OFAC_STATUS
        , SDN_PUBLISH_DATE
        , FSS_ACTIVITY_DT
        , FSS_USER_OVR
        , CUSTOMER_PO_LINE
        , CUSTOMER_PO_SCHED
        , PC_CF_CHANGE_FLG
        , CREDIT_REASON
        , VAT_RVRSE_CHG_GDS
        , TAX_CD_VAT_RVC
        , TAX_CD_VAT_RVC_PCT
        , VAT_AMT_RVC
        , VAT_AMT_RVC_BSE
        , VAT_AMT_RVC_XEU
        , TEMP_INVOICE
        , PROCESS_INSTANCE
        , ADD_DTTM
        , LAST_MAINT_OPRID
        , LAST_UPDATE_DTTM
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
    WHERE existing.INVOICE_LINE_HK = JOIN_RESULT.INVOICE_LINE_HK
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %} 
{% if not is_incremental() %}
/*the following qualify is to restrict multiple loads of touched records during the initial build. Ex: multiple row per hk, hashdiff */
qualify 1= row_number()over(partition by INVOICE_LINE_HK, HASHDIFF order by PSA_LOAD_DTS)
union all
    SELECT         MD5_BINARY(GR.VALUE) AS INVOICE_LINE_HK
, GR.VALUE AS INVOICE
, GR.VALUE::NUMBER as  LINE_SEQ_NUM
    , null as BUSINESS_UNIT
    , null as INVOICE_LINE
    , null as ORIGINAL_INVOICE
    , null as ORIGINAL_LINE_SEQ
    , null as NEXT_ADJ_INVOICE
    , null as NEXT_ADJ_LINE_SEQ
    , null as PRIOR_ADJ_INVOICE
    , null as PRIOR_ADJ_LINE_SEQ
    , null as LATEST_INVOICE
    , null as LATEST_LINE_SEQ
    , null as BILL_SOURCE_ID
    , null as SUBCUST_QUAL1
    , null as SUBCUST_QUAL2
    , null as ADJ_LINE_TYPE
    , null as ADJUSTED_FLAG
    , null as LINE_TYPE
    , null as BI_CURRENCY_CD
    , null as BASE_CURRENCY
    , null as CURRENCY_CD_XEU
    , null as RT_EFFDT
    , null as CHARGE_FROM_DT
    , null as CHARGE_TO_DT
    , null as IDENTIFIER
    , null as DESCR
    , null as UNIT_OF_MEASURE
    , null as QTY
    , null as ORIG_QTY
    , null as UNIT_AMT
    , null as PRICE_RECALC_FLG
    , null as TAX_CD
    , null as TAX_EXEMPT_CERT
    , null as TAX_EXEMPT_FLG
    , null as GROSS_EXTENDED_AMT
    , null as NET_EXTENDED_AMT
    , null as ORIG_AMOUNT
    , null as GROSS_EXTENDED_BSE
    , null as NET_EXTENDED_BSE
    , null as GROSS_EXTENDED_XEU
    , null as NET_EXTENDED_XEU
    , null as TAX_AMT
    , null as TAX_AMT_BSE
    , null as TAX_AMT_XEU
    , null as TAX_PCT
    , null as FINAL_TAX_FLG
    , null as MAX_TAX_FLG
    , null as BI_TAX_TIMING
    , null as VAT_BASIS_AMT
    , null as VAT_BASIS_AMT_BSE
    , null as VAT_BASIS_AMT_XEU
    , null as VAT_AMT
    , null as VAT_AMT_BSE
    , null as VAT_AMT_XEU
    , null as VAT_TRANS_AMT
    , null as VAT_TRANS_AMT_BSE
    , null as VAT_TXN_TYPE_CD
    , null as TAX_CD_VAT
    , null as TAX_CD_VAT_PCT
    , null as VAT_APPLICABILITY
    , null as PROD_GRP_SETID
    , null as VAT_PRODUCT_GROUP
    , null as PRODUCT_KIT_ID
    , null as VAT_DISTRIB_STATUS
    , null as TAX_VAT_FLG
    , null as REV_RECOG_BASIS
    , null as DEFERRED_STATUS
    , null as ACCRUE_DT
    , null as TOT_LINE_DST_PCT
    , null as TOT_LINE_DFR_PCT
    , null as TOT_LINE_UAR_PCT
    , null as TOT_LINE_DST_AMT
    , null as TOT_LINE_DFR_AMT
    , null as TOT_LINE_UAR_AMT
    , null as TOT_LINE_DST_BSE
    , null as TOT_LINE_DFR_BSE
    , null as TOT_LINE_UAR_BSE
    , null as TOT_LINE_DST_XEU
    , null as TOT_LINE_DFR_XEU
    , null as TOT_LINE_UAR_XEU
    , null as TOT_DISCOUNT_AMT
    , null as TOT_SURCHARGE_AMT
    , null as TOT_DISCOUNT_BSE
    , null as TOT_SURCHARGE_BSE
    , null as TOT_DISCOUNT_XEU
    , null as TOT_SURCHARGE_XEU
    , null as LINE_DST_SEQ_NUM
    , null as LINE_DFR_SEQ_NUM
    , null as LINE_UAR_SEQ_NUM
    , null as LAST_NOTE_SEQ_NUM
    , null as ENTRY_TYPE
    , null as ENTRY_REASON
    , null as PC_DISTRIB_STATUS
    , null as PO_REF
    , null as PO_LINE
    , null as BUSINESS_UNIT_CA
    , null as CONTRACT_NUM
    , null as CONTRACT_DT
    , null as CONTRACT_TYPE
    , null as BILL_PLAN_ID
    , null as BPLAN_LN_NBR
    , null as EVENT_OCCURRENCE
    , null as XREF_SEQ_NUM
    , null as CONTRACT_PPD_SEQ
    , null as BUSINESS_UNIT_OM
    , null as ORDER_NO
    , null as ORDER_DATE
    , null as ORDER_INT_LINE_NO
    , null as SCHED_LINE_NBR
    , null as BUSINESS_UNIT_RMA
    , null as RMA_ID
    , null as RMA_LINE_NBR
    , null as PRODUCT_ID
    , null as DIST_CFG_FLAG
    , null as FREIGHT_TERMS
    , null as BILL_OF_LADING
    , null as SHIP_TO_CUST_ID
    , null as SHIP_TO_ADDR_NUM
    , null as SHIP_ID
    , null as SHIP_TYPE_ID
    , null as SHIP_FROM_BU
    , null as SHIP_DATE
    , null as SHIP_TIME
    , null as SEQUENCE_NBR
    , null as SOLD_TO_CUST_ID
    , null as SOLD_TO_ADDR_NUM
    , null as RESOURCE_ID
    , null as ACTIVITY_TYPE
    , null as SYSTEM_SOURCE
    , null as EMPLID
    , null as SSN
    , null as EMPL_RCD
    , null as SERVICE_CUST_ID
    , null as SERVICE_ADDR_NUM
    , null as START_DT
    , null as END_DT
    , null as ACCUMULATE
    , null as ERROR_STATUS_BI
    , null as CONTRACT_LINE_NUM
    , null as BUSINESS_UNIT_TO
    , null as IST_TXN_FLG
    , null as IST_DISTRIB_STATUS
    , null as INVENTORY_ITEM
    , null as FISCAL_REGIME
    , null as NATURE_OF_TXN1
    , null as NATURE_OF_TXN2
    , null as IDENTIFIER_TBL
    , null as PACKSLIP_NO
    , null as DEFER_DT
    , null as PPRC_PROMO_CD
    , null as MERCH_TYPE
    , null as LIST_PRICE
    , null as ENTRY_EVENT
    , null as PHYSICAL_NATURE
    , null as VAT_TREATMENT
    , null as VAT_SVC_SUPPLY_FLG
    , null as VAT_SERVICE_TYPE
    , null as VAT_DST_ACCT_TYPE
    , null as VAT_ADVPAY_FLG
    , null as VOUCHER_STYLE
    , null as COUNTRY_LOC_BUYER
    , null as STATE_LOC_BUYER
    , null as COUNTRY_LOC_SELLER
    , null as STATE_LOC_SELLER
    , null as COUNTRY_VAT_SUPPLY
    , null as STATE_VAT_SUPPLY
    , null as COUNTRY_VAT_PERFRM
    , null as STATE_VAT_PERFRM
    , null as STATE_SHIP_TO
    , null as STATE_SHIP_FROM
    , null as EXD_CUST_CATG_CD
    , null as STX_CUST_CATG_CD
    , null as VAT_DFLT_DONE_FLG
    , null as INV_ITEM_ID
    , null as QTY_BASE
    , null as EXD_INVOICE_NO
    , null as EXD_INVOICE_LINE
    , null as ORG_SETID
    , null as ORG_CODE
    , null as ORG_TAX_LOC_CD
    , null as EXD_APPL_FLG
    , null as STX_APPL_FLG
    , null as EXS_DFLTS_APPLIED
    , null as EXS_TAX_TXN_TYPE
    , null as STX_TAX_AUTH_CD
    , null as COUNTRY_SHIP_TO
    , null as COUNTRY_SHIP_FROM
    , null as EXD_ITM_CATG_CD
    , null as STX_ITM_CATG_CD
    , null as EXS_SERV_TAX_FLG
    , null as STX_FORM_CD
    , null as FORM_DISTRIB_STAT
    , null as EXD_ASSESS_VALUE
    , null as EXD_UOM
    , null as EXD_CONVERSION_RT
    , null as EXD_USE_AV_FLG
    , null as EXD_TAX_RATE_CD
    , null as EXD_TAX_RATE_SRC
    , null as EXD_TAX_AMT
    , null as EXD_TAX_AMT_BSE
    , null as EXD_TAX_AMT_RPT
    , null as STX_TAX_RATE_CD
    , null as STX_TAX_RATE_SRC
    , null as STX_TAX_AMT
    , null as STX_TAX_AMT_BSE
    , null as STX_TAX_AMT_RPT
    , null as EXS_CURRENCY_RPTG
    , null as BUSINESS_UNIT_AMTO
    , null as ASSET_ID
    , null as PROFILE_ID
    , null as COST_TYPE
    , null as COUNTRY_VAT_BILLFR
    , null as COUNTRY_VAT_BILLTO
    , null as STATE_VAT_DEFAULT
    , null as LANG_DESCR_OVR
    , null as SO_ID
    , null as BUSINESS_UNIT_RF
    , null as SOURCE_REF_TYPE
    , null as SOURCE_REF_NO
    , null as SOURCE_REF_KEY
    , null as CA_PGP_SEQ
    , null as SUM_TEMPLATE_ID
    , null as SUM_GROUP_TYPE
    , null as SUM_GROUP_ID
    , null as CUST_DEPOSIT_ID
    , null as BUSINESS_UNIT_PC
    , null as PROJECT_ID
    , null as ACTIVITY_ID
    , null as RESOURCE_TYPE
    , null as RESOURCE_CATEGORY
    , null as RESOURCE_SUB_CAT
    , null as ANALYSIS_TYPE
    , null as USER_AMT1
    , null as USER_AMT2
    , null as USER_AMT1_BSE
    , null as USER_AMT2_BSE
    , null as USER_AMT1_XEU
    , null as USER_AMT2_XEU
    , null as USER_DT1
    , null as USER_DT2
    , null as USER1
    , null as USER2
    , null as USER3
    , null as USER4
    , null as USER5
    , null as USER6
    , null as USER7
    , null as USER8
    , null as USER9
    , null as OFAC_STATUS
    , null as SDN_PUBLISH_DATE
    , null as FSS_ACTIVITY_DT
    , null as FSS_USER_OVR
    , null as CUSTOMER_PO_LINE
    , null as CUSTOMER_PO_SCHED
    , null as PC_CF_CHANGE_FLG
    , null as CREDIT_REASON
    , null as VAT_RVRSE_CHG_GDS
    , null as TAX_CD_VAT_RVC
    , null as TAX_CD_VAT_RVC_PCT
    , null as VAT_AMT_RVC
    , null as VAT_AMT_RVC_BSE
    , null as VAT_AMT_RVC_XEU
    , null as TEMP_INVOICE
    , null as PROCESS_INSTANCE
    , null as ADD_DTTM
    , null as LAST_MAINT_OPRID
    , null as LAST_UPDATE_DTTM
    , null as _FIVETRAN_DELETED
    , null as _FIVETRAN_ID
    , null as _FIVETRAN_SYNCED
    , null as PSA_DELETE_IND
    , null as PSA_LOAD_DTS
    , null as PSA_RECORD_SOURCE
    , CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)::TIMESTAMP  as LOAD_DTS
    ,'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
    , ''::BINARY as HASHDIFF
FROM
    TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}