---- SRC LAYER ----
WITH
SRC_S              as ( SELECT * FROM {{ source('lrsn_psft_sysadm', 'ps_bi_line') }} as SRC  ),
SRC_A              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S              as ( SELECT * FROM lrsn_psft_sysadm.ps_bi_line )
, SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        CONCAT(INVOICE, '||',LINE_SEQ_NUM)                           as                                    INVOICE_LINE_BK
      , INVOICE                                                      as                                         INVOICE_BK
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
      , CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED )                   as                                           LOAD_DTS
      , coalesce(nullif(trim(PRODUCT_ID), ''), '-1')                 as                                            ITEM_BK
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
        INVOICE_LINE_BK
      , INVOICE_BK
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
      , ITEM_BK
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
    WHERE rec_src = 'USSDBR.ORCL.PSFTPRD.BI_LINE'
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
          INVOICE_LINE_BK
        , INVOICE_BK
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
        , BKCC
        , ITEM_BK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(INVOICE_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as INVOICE_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(INVOICE_LINE_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as INVOICE_LINE_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ITEM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ITEM_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(INVOICE_LINE_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(ITEM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as INVOICE_INVOICE_LINE_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(BUSINESS_UNIT::text), '^^') 
            , '||', IFNULL(TRIM(INVOICE_LINE::text), '^^') 
            , '||', IFNULL(TRIM(ORIGINAL_INVOICE::text), '^^') 
            , '||', IFNULL(TRIM(ORIGINAL_LINE_SEQ::text), '^^') 
            , '||', IFNULL(TRIM(NEXT_ADJ_INVOICE::text), '^^') 
            , '||', IFNULL(TRIM(NEXT_ADJ_LINE_SEQ::text), '^^') 
            , '||', IFNULL(TRIM(PRIOR_ADJ_INVOICE::text), '^^') 
            , '||', IFNULL(TRIM(PRIOR_ADJ_LINE_SEQ::text), '^^') 
            , '||', IFNULL(TRIM(LATEST_INVOICE::text), '^^') 
            , '||', IFNULL(TRIM(LATEST_LINE_SEQ::text), '^^') 
            , '||', IFNULL(TRIM(BILL_SOURCE_ID::text), '^^') 
            , '||', IFNULL(TRIM(SUBCUST_QUAL1::text), '^^') 
            , '||', IFNULL(TRIM(SUBCUST_QUAL2::text), '^^') 
            , '||', IFNULL(TRIM(ADJ_LINE_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(ADJUSTED_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(LINE_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(BI_CURRENCY_CD::text), '^^') 
            , '||', IFNULL(TRIM(BASE_CURRENCY::text), '^^') 
            , '||', IFNULL(TRIM(CURRENCY_CD_XEU::text), '^^') 
            , '||', IFNULL(TRIM(RT_EFFDT::text), '^^') 
            , '||', IFNULL(TRIM(CHARGE_FROM_DT::text), '^^') 
            , '||', IFNULL(TRIM(CHARGE_TO_DT::text), '^^') 
            , '||', IFNULL(TRIM(IDENTIFIER::text), '^^') 
            , '||', IFNULL(TRIM(DESCR::text), '^^') 
            , '||', IFNULL(TRIM(UNIT_OF_MEASURE::text), '^^') 
            , '||', IFNULL(TRIM(QTY::text), '^^') 
            , '||', IFNULL(TRIM(ORIG_QTY::text), '^^') 
            , '||', IFNULL(TRIM(UNIT_AMT::text), '^^') 
            , '||', IFNULL(TRIM(PRICE_RECALC_FLG::text), '^^') 
            , '||', IFNULL(TRIM(TAX_CD::text), '^^') 
            , '||', IFNULL(TRIM(TAX_EXEMPT_CERT::text), '^^') 
            , '||', IFNULL(TRIM(TAX_EXEMPT_FLG::text), '^^') 
            , '||', IFNULL(TRIM(GROSS_EXTENDED_AMT::text), '^^') 
            , '||', IFNULL(TRIM(NET_EXTENDED_AMT::text), '^^') 
            , '||', IFNULL(TRIM(ORIG_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(GROSS_EXTENDED_BSE::text), '^^') 
            , '||', IFNULL(TRIM(NET_EXTENDED_BSE::text), '^^') 
            , '||', IFNULL(TRIM(GROSS_EXTENDED_XEU::text), '^^') 
            , '||', IFNULL(TRIM(NET_EXTENDED_XEU::text), '^^') 
            , '||', IFNULL(TRIM(TAX_AMT::text), '^^') 
            , '||', IFNULL(TRIM(TAX_AMT_BSE::text), '^^') 
            , '||', IFNULL(TRIM(TAX_AMT_XEU::text), '^^') 
            , '||', IFNULL(TRIM(TAX_PCT::text), '^^') 
            , '||', IFNULL(TRIM(FINAL_TAX_FLG::text), '^^') 
            , '||', IFNULL(TRIM(MAX_TAX_FLG::text), '^^') 
            , '||', IFNULL(TRIM(BI_TAX_TIMING::text), '^^') 
            , '||', IFNULL(TRIM(VAT_BASIS_AMT::text), '^^') 
            , '||', IFNULL(TRIM(VAT_BASIS_AMT_BSE::text), '^^') 
            , '||', IFNULL(TRIM(VAT_BASIS_AMT_XEU::text), '^^') 
            , '||', IFNULL(TRIM(VAT_AMT::text), '^^') 
            , '||', IFNULL(TRIM(VAT_AMT_BSE::text), '^^') 
            , '||', IFNULL(TRIM(VAT_AMT_XEU::text), '^^') 
            , '||', IFNULL(TRIM(VAT_TRANS_AMT::text), '^^') 
            , '||', IFNULL(TRIM(VAT_TRANS_AMT_BSE::text), '^^') 
            , '||', IFNULL(TRIM(VAT_TXN_TYPE_CD::text), '^^') 
            , '||', IFNULL(TRIM(TAX_CD_VAT::text), '^^') 
            , '||', IFNULL(TRIM(TAX_CD_VAT_PCT::text), '^^') 
            , '||', IFNULL(TRIM(VAT_APPLICABILITY::text), '^^') 
            , '||', IFNULL(TRIM(PROD_GRP_SETID::text), '^^') 
            , '||', IFNULL(TRIM(VAT_PRODUCT_GROUP::text), '^^') 
            , '||', IFNULL(TRIM(PRODUCT_KIT_ID::text), '^^') 
            , '||', IFNULL(TRIM(VAT_DISTRIB_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(TAX_VAT_FLG::text), '^^') 
            , '||', IFNULL(TRIM(REV_RECOG_BASIS::text), '^^') 
            , '||', IFNULL(TRIM(DEFERRED_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(ACCRUE_DT::text), '^^') 
            , '||', IFNULL(TRIM(TOT_LINE_DST_PCT::text), '^^') 
            , '||', IFNULL(TRIM(TOT_LINE_DFR_PCT::text), '^^') 
            , '||', IFNULL(TRIM(TOT_LINE_UAR_PCT::text), '^^') 
            , '||', IFNULL(TRIM(TOT_LINE_DST_AMT::text), '^^') 
            , '||', IFNULL(TRIM(TOT_LINE_DFR_AMT::text), '^^') 
            , '||', IFNULL(TRIM(TOT_LINE_UAR_AMT::text), '^^') 
            , '||', IFNULL(TRIM(TOT_LINE_DST_BSE::text), '^^') 
            , '||', IFNULL(TRIM(TOT_LINE_DFR_BSE::text), '^^') 
            , '||', IFNULL(TRIM(TOT_LINE_UAR_BSE::text), '^^') 
            , '||', IFNULL(TRIM(TOT_LINE_DST_XEU::text), '^^') 
            , '||', IFNULL(TRIM(TOT_LINE_DFR_XEU::text), '^^') 
            , '||', IFNULL(TRIM(TOT_LINE_UAR_XEU::text), '^^') 
            , '||', IFNULL(TRIM(TOT_DISCOUNT_AMT::text), '^^') 
            , '||', IFNULL(TRIM(TOT_SURCHARGE_AMT::text), '^^') 
            , '||', IFNULL(TRIM(TOT_DISCOUNT_BSE::text), '^^') 
            , '||', IFNULL(TRIM(TOT_SURCHARGE_BSE::text), '^^') 
            , '||', IFNULL(TRIM(TOT_DISCOUNT_XEU::text), '^^') 
            , '||', IFNULL(TRIM(TOT_SURCHARGE_XEU::text), '^^') 
            , '||', IFNULL(TRIM(LINE_DST_SEQ_NUM::text), '^^') 
            , '||', IFNULL(TRIM(LINE_DFR_SEQ_NUM::text), '^^') 
            , '||', IFNULL(TRIM(LINE_UAR_SEQ_NUM::text), '^^') 
            , '||', IFNULL(TRIM(LAST_NOTE_SEQ_NUM::text), '^^') 
            , '||', IFNULL(TRIM(ENTRY_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(ENTRY_REASON::text), '^^') 
            , '||', IFNULL(TRIM(PC_DISTRIB_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(PO_REF::text), '^^') 
            , '||', IFNULL(TRIM(PO_LINE::text), '^^') 
            , '||', IFNULL(TRIM(BUSINESS_UNIT_CA::text), '^^') 
            , '||', IFNULL(TRIM(CONTRACT_NUM::text), '^^') 
            , '||', IFNULL(TRIM(CONTRACT_DT::text), '^^') 
            , '||', IFNULL(TRIM(CONTRACT_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(BILL_PLAN_ID::text), '^^') 
            , '||', IFNULL(TRIM(BPLAN_LN_NBR::text), '^^') 
            , '||', IFNULL(TRIM(EVENT_OCCURRENCE::text), '^^') 
            , '||', IFNULL(TRIM(XREF_SEQ_NUM::text), '^^') 
            , '||', IFNULL(TRIM(CONTRACT_PPD_SEQ::text), '^^') 
            , '||', IFNULL(TRIM(BUSINESS_UNIT_OM::text), '^^') 
            , '||', IFNULL(TRIM(ORDER_NO::text), '^^') 
            , '||', IFNULL(TRIM(ORDER_DATE::text), '^^') 
            , '||', IFNULL(TRIM(ORDER_INT_LINE_NO::text), '^^') 
            , '||', IFNULL(TRIM(SCHED_LINE_NBR::text), '^^') 
            , '||', IFNULL(TRIM(BUSINESS_UNIT_RMA::text), '^^') 
            , '||', IFNULL(TRIM(RMA_ID::text), '^^') 
            , '||', IFNULL(TRIM(RMA_LINE_NBR::text), '^^') 
            , '||', IFNULL(TRIM(PRODUCT_ID::text), '^^') 
            , '||', IFNULL(TRIM(DIST_CFG_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(FREIGHT_TERMS::text), '^^') 
            , '||', IFNULL(TRIM(BILL_OF_LADING::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_TO_CUST_ID::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_TO_ADDR_NUM::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_ID::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_TYPE_ID::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_FROM_BU::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_DATE::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_TIME::text), '^^') 
            , '||', IFNULL(TRIM(SEQUENCE_NBR::text), '^^') 
            , '||', IFNULL(TRIM(SOLD_TO_CUST_ID::text), '^^') 
            , '||', IFNULL(TRIM(SOLD_TO_ADDR_NUM::text), '^^') 
            , '||', IFNULL(TRIM(RESOURCE_ID::text), '^^') 
            , '||', IFNULL(TRIM(ACTIVITY_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(SYSTEM_SOURCE::text), '^^') 
            , '||', IFNULL(TRIM(EMPLID::text), '^^') 
            , '||', IFNULL(TRIM(SSN::text), '^^') 
            , '||', IFNULL(TRIM(EMPL_RCD::text), '^^') 
            , '||', IFNULL(TRIM(SERVICE_CUST_ID::text), '^^') 
            , '||', IFNULL(TRIM(SERVICE_ADDR_NUM::text), '^^') 
            , '||', IFNULL(TRIM(START_DT::text), '^^') 
            , '||', IFNULL(TRIM(END_DT::text), '^^') 
            , '||', IFNULL(TRIM(ACCUMULATE::text), '^^') 
            , '||', IFNULL(TRIM(ERROR_STATUS_BI::text), '^^') 
            , '||', IFNULL(TRIM(CONTRACT_LINE_NUM::text), '^^') 
            , '||', IFNULL(TRIM(BUSINESS_UNIT_TO::text), '^^') 
            , '||', IFNULL(TRIM(IST_TXN_FLG::text), '^^') 
            , '||', IFNULL(TRIM(IST_DISTRIB_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(INVENTORY_ITEM::text), '^^') 
            , '||', IFNULL(TRIM(FISCAL_REGIME::text), '^^') 
            , '||', IFNULL(TRIM(NATURE_OF_TXN1::text), '^^') 
            , '||', IFNULL(TRIM(NATURE_OF_TXN2::text), '^^') 
            , '||', IFNULL(TRIM(IDENTIFIER_TBL::text), '^^') 
            , '||', IFNULL(TRIM(PACKSLIP_NO::text), '^^') 
            , '||', IFNULL(TRIM(DEFER_DT::text), '^^') 
            , '||', IFNULL(TRIM(PPRC_PROMO_CD::text), '^^') 
            , '||', IFNULL(TRIM(MERCH_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(LIST_PRICE::text), '^^') 
            , '||', IFNULL(TRIM(ENTRY_EVENT::text), '^^') 
            , '||', IFNULL(TRIM(PHYSICAL_NATURE::text), '^^') 
            , '||', IFNULL(TRIM(VAT_TREATMENT::text), '^^') 
            , '||', IFNULL(TRIM(VAT_SVC_SUPPLY_FLG::text), '^^') 
            , '||', IFNULL(TRIM(VAT_SERVICE_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(VAT_DST_ACCT_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(VAT_ADVPAY_FLG::text), '^^') 
            , '||', IFNULL(TRIM(VOUCHER_STYLE::text), '^^') 
            , '||', IFNULL(TRIM(COUNTRY_LOC_BUYER::text), '^^') 
            , '||', IFNULL(TRIM(STATE_LOC_BUYER::text), '^^') 
            , '||', IFNULL(TRIM(COUNTRY_LOC_SELLER::text), '^^') 
            , '||', IFNULL(TRIM(STATE_LOC_SELLER::text), '^^') 
            , '||', IFNULL(TRIM(COUNTRY_VAT_SUPPLY::text), '^^') 
            , '||', IFNULL(TRIM(STATE_VAT_SUPPLY::text), '^^') 
            , '||', IFNULL(TRIM(COUNTRY_VAT_PERFRM::text), '^^') 
            , '||', IFNULL(TRIM(STATE_VAT_PERFRM::text), '^^') 
            , '||', IFNULL(TRIM(STATE_SHIP_TO::text), '^^') 
            , '||', IFNULL(TRIM(STATE_SHIP_FROM::text), '^^') 
            , '||', IFNULL(TRIM(EXD_CUST_CATG_CD::text), '^^') 
            , '||', IFNULL(TRIM(STX_CUST_CATG_CD::text), '^^') 
            , '||', IFNULL(TRIM(VAT_DFLT_DONE_FLG::text), '^^') 
            , '||', IFNULL(TRIM(INV_ITEM_ID::text), '^^') 
            , '||', IFNULL(TRIM(QTY_BASE::text), '^^') 
            , '||', IFNULL(TRIM(EXD_INVOICE_NO::text), '^^') 
            , '||', IFNULL(TRIM(EXD_INVOICE_LINE::text), '^^') 
            , '||', IFNULL(TRIM(ORG_SETID::text), '^^') 
            , '||', IFNULL(TRIM(ORG_CODE::text), '^^') 
            , '||', IFNULL(TRIM(ORG_TAX_LOC_CD::text), '^^') 
            , '||', IFNULL(TRIM(EXD_APPL_FLG::text), '^^') 
            , '||', IFNULL(TRIM(STX_APPL_FLG::text), '^^') 
            , '||', IFNULL(TRIM(EXS_DFLTS_APPLIED::text), '^^') 
            , '||', IFNULL(TRIM(EXS_TAX_TXN_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(STX_TAX_AUTH_CD::text), '^^') 
            , '||', IFNULL(TRIM(COUNTRY_SHIP_TO::text), '^^') 
            , '||', IFNULL(TRIM(COUNTRY_SHIP_FROM::text), '^^') 
            , '||', IFNULL(TRIM(EXD_ITM_CATG_CD::text), '^^') 
            , '||', IFNULL(TRIM(STX_ITM_CATG_CD::text), '^^') 
            , '||', IFNULL(TRIM(EXS_SERV_TAX_FLG::text), '^^') 
            , '||', IFNULL(TRIM(STX_FORM_CD::text), '^^') 
            , '||', IFNULL(TRIM(FORM_DISTRIB_STAT::text), '^^') 
            , '||', IFNULL(TRIM(EXD_ASSESS_VALUE::text), '^^') 
            , '||', IFNULL(TRIM(EXD_UOM::text), '^^') 
            , '||', IFNULL(TRIM(EXD_CONVERSION_RT::text), '^^') 
            , '||', IFNULL(TRIM(EXD_USE_AV_FLG::text), '^^') 
            , '||', IFNULL(TRIM(EXD_TAX_RATE_CD::text), '^^') 
            , '||', IFNULL(TRIM(EXD_TAX_RATE_SRC::text), '^^') 
            , '||', IFNULL(TRIM(EXD_TAX_AMT::text), '^^') 
            , '||', IFNULL(TRIM(EXD_TAX_AMT_BSE::text), '^^') 
            , '||', IFNULL(TRIM(EXD_TAX_AMT_RPT::text), '^^') 
            , '||', IFNULL(TRIM(STX_TAX_RATE_CD::text), '^^') 
            , '||', IFNULL(TRIM(STX_TAX_RATE_SRC::text), '^^') 
            , '||', IFNULL(TRIM(STX_TAX_AMT::text), '^^') 
            , '||', IFNULL(TRIM(STX_TAX_AMT_BSE::text), '^^') 
            , '||', IFNULL(TRIM(STX_TAX_AMT_RPT::text), '^^') 
            , '||', IFNULL(TRIM(EXS_CURRENCY_RPTG::text), '^^') 
            , '||', IFNULL(TRIM(BUSINESS_UNIT_AMTO::text), '^^') 
            , '||', IFNULL(TRIM(ASSET_ID::text), '^^') 
            , '||', IFNULL(TRIM(PROFILE_ID::text), '^^') 
            , '||', IFNULL(TRIM(COST_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(COUNTRY_VAT_BILLFR::text), '^^') 
            , '||', IFNULL(TRIM(COUNTRY_VAT_BILLTO::text), '^^') 
            , '||', IFNULL(TRIM(STATE_VAT_DEFAULT::text), '^^') 
            , '||', IFNULL(TRIM(LANG_DESCR_OVR::text), '^^') 
            , '||', IFNULL(TRIM(SO_ID::text), '^^') 
            , '||', IFNULL(TRIM(BUSINESS_UNIT_RF::text), '^^') 
            , '||', IFNULL(TRIM(SOURCE_REF_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(SOURCE_REF_NO::text), '^^') 
            , '||', IFNULL(TRIM(SOURCE_REF_KEY::text), '^^') 
            , '||', IFNULL(TRIM(CA_PGP_SEQ::text), '^^') 
            , '||', IFNULL(TRIM(SUM_TEMPLATE_ID::text), '^^') 
            , '||', IFNULL(TRIM(SUM_GROUP_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(SUM_GROUP_ID::text), '^^') 
            , '||', IFNULL(TRIM(CUST_DEPOSIT_ID::text), '^^') 
            , '||', IFNULL(TRIM(BUSINESS_UNIT_PC::text), '^^') 
            , '||', IFNULL(TRIM(PROJECT_ID::text), '^^') 
            , '||', IFNULL(TRIM(ACTIVITY_ID::text), '^^') 
            , '||', IFNULL(TRIM(RESOURCE_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(RESOURCE_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(RESOURCE_SUB_CAT::text), '^^') 
            , '||', IFNULL(TRIM(ANALYSIS_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(USER_AMT1::text), '^^') 
            , '||', IFNULL(TRIM(USER_AMT2::text), '^^') 
            , '||', IFNULL(TRIM(USER_AMT1_BSE::text), '^^') 
            , '||', IFNULL(TRIM(USER_AMT2_BSE::text), '^^') 
            , '||', IFNULL(TRIM(USER_AMT1_XEU::text), '^^') 
            , '||', IFNULL(TRIM(USER_AMT2_XEU::text), '^^') 
            , '||', IFNULL(TRIM(USER_DT1::text), '^^') 
            , '||', IFNULL(TRIM(USER_DT2::text), '^^') 
            , '||', IFNULL(TRIM(USER1::text), '^^') 
            , '||', IFNULL(TRIM(USER2::text), '^^') 
            , '||', IFNULL(TRIM(USER3::text), '^^') 
            , '||', IFNULL(TRIM(USER4::text), '^^') 
            , '||', IFNULL(TRIM(USER5::text), '^^') 
            , '||', IFNULL(TRIM(USER6::text), '^^') 
            , '||', IFNULL(TRIM(USER7::text), '^^') 
            , '||', IFNULL(TRIM(USER8::text), '^^') 
            , '||', IFNULL(TRIM(USER9::text), '^^') 
            , '||', IFNULL(TRIM(OFAC_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(SDN_PUBLISH_DATE::text), '^^') 
            , '||', IFNULL(TRIM(FSS_ACTIVITY_DT::text), '^^') 
            , '||', IFNULL(TRIM(FSS_USER_OVR::text), '^^') 
            , '||', IFNULL(TRIM(CUSTOMER_PO_LINE::text), '^^') 
            , '||', IFNULL(TRIM(CUSTOMER_PO_SCHED::text), '^^') 
            , '||', IFNULL(TRIM(PC_CF_CHANGE_FLG::text), '^^') 
            , '||', IFNULL(TRIM(CREDIT_REASON::text), '^^') 
            , '||', IFNULL(TRIM(VAT_RVRSE_CHG_GDS::text), '^^') 
            , '||', IFNULL(TRIM(TAX_CD_VAT_RVC::text), '^^') 
            , '||', IFNULL(TRIM(TAX_CD_VAT_RVC_PCT::text), '^^') 
            , '||', IFNULL(TRIM(VAT_AMT_RVC::text), '^^') 
            , '||', IFNULL(TRIM(VAT_AMT_RVC_BSE::text), '^^') 
            , '||', IFNULL(TRIM(VAT_AMT_RVC_XEU::text), '^^') 
            , '||', IFNULL(TRIM(TEMP_INVOICE::text), '^^') 
            , '||', IFNULL(TRIM(PROCESS_INSTANCE::text), '^^') 
            , '||', IFNULL(TRIM(ADD_DTTM::text), '^^') 
            , '||', IFNULL(TRIM(LAST_MAINT_OPRID::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_DTTM::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
