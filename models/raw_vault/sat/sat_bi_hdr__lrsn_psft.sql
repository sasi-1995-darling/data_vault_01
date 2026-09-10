---- SRC LAYER ----
WITH
SRC_SBIHLR         as ( SELECT * FROM {{ ref('v_psa_stg_bi_hdr__lrsn_psft') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_SBIHLR         as ( SELECT * FROM STAGING.v_psa_stg_bi_hdr__lrsn_psft )
*/
---- LOGIC LAYER ----

, LOGIC_SBIHLR as (
    SELECT
        INVOICE_HK
      , INVOICE
      , BUSINESS_UNIT
      , BILL_TO_CUST_ID
      , BILL_STATUS
      , CONTRACT_NUM
      , INVOICE_TYPE
      , CONSOL_HDR
      , CONSOL_KEY
      , CONSOL_SETID
      , CONSOL_CUST_ID
      , CONSOL_BUS_UNIT
      , CONSOL_INVOICE
      , ORIGINAL_INVOICE
      , PRIOR_ADJ_INVOICE
      , NEXT_ADJ_INVOICE
      , LATEST_INVOICE
      , ADJUSTED_FLAG
      , BILL_TYPE_ID
      , BILL_SOURCE_ID
      , BILL_CYCLE_ID
      , BILL_BY_ID
      , HDR_FIELDS_KEY
      , BILLING_FREQUENCY
      , TEMPLATE_IVC_FLG
      , TEMPLATE_INVOICE
      , RECURRING_START_DT
      , RECURRING_END_DT
      , AUTO_GEN_IVC_NUM
      , FROM_DT
      , TO_DT
      , ADDRESS_SEQ_NUM
      , BILL_TO_COPIES
      , BILL_TO_MEDIA
      , CNTCT_SEQ_NUM
      , NAME1
      , BUSINESS_UNIT_TO
      , CR_CARD_FLG
      , SUBCUST_QUAL1
      , SUBCUST_QUAL2
      , BILL_INQUIRY_PHONE
      , BILLING_SPECIALIST
      , BILLING_AUTHORITY
      , COLLECTOR
      , SALES_PERSON
      , CR_ANALYST
      , PYMNT_TERMS_CD
      , BANK_CD
      , BANK_ACCT_KEY
      , BI_CURRENCY_CD
      , BASE_CURRENCY
      , CURRENCY_CD_XEU
      , FINAL_CURCNV_FLG
      , CUR_RT_TYPE
      , CUR_RT_SOURCE
      , RATE_MULT
      , RATE_DIV
      , RATE_MULT_XEU
      , RATE_DIV_XEU
      , RATE_MULT_IU
      , RATE_DIV_IU
      , RATE_DATE
      , BI_PAID_AT_SRC
      , PAID_AMT
      , FORWARD_BAL_AMT
      , INVOICE_AMT_PRETAX
      , INVOICE_AMOUNT
      , PAID_AMT_BSE
      , FORWARD_BAL_BSE
      , INVOICE_PRETAX_BSE
      , INVOICE_AMT_BSE
      , FORWARD_BAL_XEU
      , INVOICE_PRETAX_XEU
      , INVOICE_AMT_XEU
      , PAID_AMT_XEU
      , INVOICE_DT
      , ACCOUNTING_DT
      , DT_INVOICED
      , DUE_DT
      , INVOICE_FORM_ID
      , IVC_PRINTED_FLG
      , IVC_PRINTED_DT
      , EDI_SENT_FLG
      , CF_ACTION_FLG
      , PRELOAD_IND
      , ENTRY_TYPE
      , ENTRY_REASON
      , AR_LVL
      , AR_DST_OPT
      , AR_ENTRY_CREATED
      , GEN_AR_ITEM_FLG
      , BUSINESS_UNIT_GL
      , GL_LVL
      , GL_ENTRY_CREATED
      , ENABLE_DFR_REV_FLG
      , DFR_ACCTG_DT_CD
      , DFR_REV_PRORATION
      , DFR_MID_PERIOD_DAY
      , DST_ID_DFR
      , BILL_STATUS_TEXT
      , MANUAL_LIN_NUM_FLG
      , LAST_LINE_SEQ_NUM
      , LAST_LINE_AAUX_SEQ
      , LAST_NOTE_SEQ_NUM
      , ACCRUE_UNBILLED
      , DOC_TYPE
      , DOC_SEQ_NBR
      , DOC_SEQ_DATE
      , PC_DISTRIB_STATUS
      , PO_REF
      , BUSINESS_UNIT_CA
      , CONTRACT_DT
      , CONTRACT_TYPE
      , DIRECT_INVOICING
      , BUSINESS_UNIT_OM
      , ORDER_NO
      , RMA_ID
      , ORDER_DATE
      , FREIGHT_TERMS
      , BILL_OF_LADING
      , SHIP_TO_CUST_ID
      , SHIP_TO_ADDR_NUM
      , SHIP_ID
      , SHIP_TYPE_ID
      , SHIP_FROM_BU
      , SOLD_TO_CUST_ID
      , SOLD_TO_ADDR_NUM
      , ACTIVITY_TYPE
      , SYSTEM_SOURCE
      , RANGE_SELECTION_ID
      , EMPLID
      , SSN
      , SERVICE_CUST_ID
      , SERVICE_ADDR_NUM
      , START_DT
      , END_DT
      , ERROR_STATUS_BI
      , COUNTRY_SHIP_TO
      , COUNTRY_SHIP_FROM
      , GEN_AP_VCHR_FLG
      , AP_CREATED_DT
      , DOC_SEQ_STATUS
      , EARLY_PY_DSCNT_PCT
      , DS_PY_TRMS_TIME_ID
      , VAT_ENTITY
      , MAX_TAX_FLG
      , TOT_SU_TAX
      , TOT_SU_TAX_BSE
      , TOT_SU_TAX_XEU
      , TOT_VAT
      , TOT_VAT_BSE
      , TOT_VAT_XEU
      , TOT_VAT_BASIS
      , TOT_VAT_BASIS_BSE
      , TOT_VAT_BASIS_XEU
      , PAYMENT_METHOD
      , PACKSLIP_NO
      , LC_ID
      , LOC_DOC_ID
      , PAID_REFERENCE
      , PPRC_PROMO_CD
      , EMAILID
      , FAX
      , LANGUAGE_CD
      , ENTRY_EVENT
      , REIMB_AGREEMENT
      , BI_BU_TAX_IND
      , EXD_INVOICE_NO
      , STX_TAX_AUTH_CD
      , TOT_EXD_AMT
      , TOT_EXD_AMT_BSE
      , TOT_STX_AMT
      , TOT_STX_AMT_BSE
      , PHYSICAL_NATURE
      , VAT_TREATMENT_GRP
      , COUNTRY_VAT_BILLFR
      , COUNTRY_VAT_BILLTO
      , STATE_SHIP_TO
      , STATE_SHIP_FROM
      , REPRINT_GROUP_ID
      , MAST_CONTR_ID
      , BUSINESS_UNIT_AM
      , SO_ID
      , BUSINESS_UNIT_RF
      , SOURCE_REF_TYPE
      , SOURCE_REF_NO
      , SOURCE_REF_KEY
      , ACCEPTGIRO_IND
      , AG_REF_NBR
      , IVC_DELIVERED_FLG
      , IVC_DELIVERED_DT
      , SUMMARIZE_IVC_FLG
      , BUSINESS_UNIT_PC
      , PROJECT_ID
      , ACTIVITY_ID
      , RESOURCE_TYPE
      , RESOURCE_CATEGORY
      , RESOURCE_SUB_CAT
      , ANALYSIS_TYPE
      , ATT_IVC_IMG_FLG
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
      , PROCESS_INSTANCE
      , BILL_FSS_STATUS
      , OFAC_STATUS
      , SDN_PUBLISH_DATE
      , FSS_ACTIVITY_DT
      , FSS_CLEAR_OPRID
      , FSS_USER_OVR
      , REASON_CD
      , REASON_TYPE
      , PUBLIC_VOUCHER_NBR
      , PVN_GEN_LVL
      , CONTRACT_LINE_NUM
      , FINAL_FF_EXT_IND
      , TARGET_PYMT_DT
      , HOLD_UNTIL_DT
      , BI_APPROVAL_STATUS
      , TOT_VAT_RVC
      , TOT_VAT_RVC_BSE
      , TOT_VAT_RVC_XEU
      , BI_CREATE_PROC
      , BI_AP_LVL
      , EIVC_COPY_IND
      , ADD_DTTM
      , CREATEOPRID
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
    FROM SRC_SBIHLR
)
---- RENAME LAYER ----

, RENAME_SBIHLR as (
    SELECT
        INVOICE_HK
      , INVOICE
      , BUSINESS_UNIT
      , BILL_TO_CUST_ID
      , BILL_STATUS
      , CONTRACT_NUM
      , INVOICE_TYPE
      , CONSOL_HDR
      , CONSOL_KEY
      , CONSOL_SETID
      , CONSOL_CUST_ID
      , CONSOL_BUS_UNIT
      , CONSOL_INVOICE
      , ORIGINAL_INVOICE
      , PRIOR_ADJ_INVOICE
      , NEXT_ADJ_INVOICE
      , LATEST_INVOICE
      , ADJUSTED_FLAG
      , BILL_TYPE_ID
      , BILL_SOURCE_ID
      , BILL_CYCLE_ID
      , BILL_BY_ID
      , HDR_FIELDS_KEY
      , BILLING_FREQUENCY
      , TEMPLATE_IVC_FLG
      , TEMPLATE_INVOICE
      , RECURRING_START_DT
      , RECURRING_END_DT
      , AUTO_GEN_IVC_NUM
      , FROM_DT
      , TO_DT
      , ADDRESS_SEQ_NUM
      , BILL_TO_COPIES
      , BILL_TO_MEDIA
      , CNTCT_SEQ_NUM
      , NAME1
      , BUSINESS_UNIT_TO
      , CR_CARD_FLG
      , SUBCUST_QUAL1
      , SUBCUST_QUAL2
      , BILL_INQUIRY_PHONE
      , BILLING_SPECIALIST
      , BILLING_AUTHORITY
      , COLLECTOR
      , SALES_PERSON
      , CR_ANALYST
      , PYMNT_TERMS_CD
      , BANK_CD
      , BANK_ACCT_KEY
      , BI_CURRENCY_CD
      , BASE_CURRENCY
      , CURRENCY_CD_XEU
      , FINAL_CURCNV_FLG
      , CUR_RT_TYPE
      , CUR_RT_SOURCE
      , RATE_MULT
      , RATE_DIV
      , RATE_MULT_XEU
      , RATE_DIV_XEU
      , RATE_MULT_IU
      , RATE_DIV_IU
      , RATE_DATE
      , BI_PAID_AT_SRC
      , PAID_AMT
      , FORWARD_BAL_AMT
      , INVOICE_AMT_PRETAX
      , INVOICE_AMOUNT
      , PAID_AMT_BSE
      , FORWARD_BAL_BSE
      , INVOICE_PRETAX_BSE
      , INVOICE_AMT_BSE
      , FORWARD_BAL_XEU
      , INVOICE_PRETAX_XEU
      , INVOICE_AMT_XEU
      , PAID_AMT_XEU
      , INVOICE_DT
      , ACCOUNTING_DT
      , DT_INVOICED
      , DUE_DT
      , INVOICE_FORM_ID
      , IVC_PRINTED_FLG
      , IVC_PRINTED_DT
      , EDI_SENT_FLG
      , CF_ACTION_FLG
      , PRELOAD_IND
      , ENTRY_TYPE
      , ENTRY_REASON
      , AR_LVL
      , AR_DST_OPT
      , AR_ENTRY_CREATED
      , GEN_AR_ITEM_FLG
      , BUSINESS_UNIT_GL
      , GL_LVL
      , GL_ENTRY_CREATED
      , ENABLE_DFR_REV_FLG
      , DFR_ACCTG_DT_CD
      , DFR_REV_PRORATION
      , DFR_MID_PERIOD_DAY
      , DST_ID_DFR
      , BILL_STATUS_TEXT
      , MANUAL_LIN_NUM_FLG
      , LAST_LINE_SEQ_NUM
      , LAST_LINE_AAUX_SEQ
      , LAST_NOTE_SEQ_NUM
      , ACCRUE_UNBILLED
      , DOC_TYPE
      , DOC_SEQ_NBR
      , DOC_SEQ_DATE
      , PC_DISTRIB_STATUS
      , PO_REF
      , BUSINESS_UNIT_CA
      , CONTRACT_DT
      , CONTRACT_TYPE
      , DIRECT_INVOICING
      , BUSINESS_UNIT_OM
      , ORDER_NO
      , RMA_ID
      , ORDER_DATE
      , FREIGHT_TERMS
      , BILL_OF_LADING
      , SHIP_TO_CUST_ID
      , SHIP_TO_ADDR_NUM
      , SHIP_ID
      , SHIP_TYPE_ID
      , SHIP_FROM_BU
      , SOLD_TO_CUST_ID
      , SOLD_TO_ADDR_NUM
      , ACTIVITY_TYPE
      , SYSTEM_SOURCE
      , RANGE_SELECTION_ID
      , EMPLID
      , SSN
      , SERVICE_CUST_ID
      , SERVICE_ADDR_NUM
      , START_DT
      , END_DT
      , ERROR_STATUS_BI
      , COUNTRY_SHIP_TO
      , COUNTRY_SHIP_FROM
      , GEN_AP_VCHR_FLG
      , AP_CREATED_DT
      , DOC_SEQ_STATUS
      , EARLY_PY_DSCNT_PCT
      , DS_PY_TRMS_TIME_ID
      , VAT_ENTITY
      , MAX_TAX_FLG
      , TOT_SU_TAX
      , TOT_SU_TAX_BSE
      , TOT_SU_TAX_XEU
      , TOT_VAT
      , TOT_VAT_BSE
      , TOT_VAT_XEU
      , TOT_VAT_BASIS
      , TOT_VAT_BASIS_BSE
      , TOT_VAT_BASIS_XEU
      , PAYMENT_METHOD
      , PACKSLIP_NO
      , LC_ID
      , LOC_DOC_ID
      , PAID_REFERENCE
      , PPRC_PROMO_CD
      , EMAILID
      , FAX
      , LANGUAGE_CD
      , ENTRY_EVENT
      , REIMB_AGREEMENT
      , BI_BU_TAX_IND
      , EXD_INVOICE_NO
      , STX_TAX_AUTH_CD
      , TOT_EXD_AMT
      , TOT_EXD_AMT_BSE
      , TOT_STX_AMT
      , TOT_STX_AMT_BSE
      , PHYSICAL_NATURE
      , VAT_TREATMENT_GRP
      , COUNTRY_VAT_BILLFR
      , COUNTRY_VAT_BILLTO
      , STATE_SHIP_TO
      , STATE_SHIP_FROM
      , REPRINT_GROUP_ID
      , MAST_CONTR_ID
      , BUSINESS_UNIT_AM
      , SO_ID
      , BUSINESS_UNIT_RF
      , SOURCE_REF_TYPE
      , SOURCE_REF_NO
      , SOURCE_REF_KEY
      , ACCEPTGIRO_IND
      , AG_REF_NBR
      , IVC_DELIVERED_FLG
      , IVC_DELIVERED_DT
      , SUMMARIZE_IVC_FLG
      , BUSINESS_UNIT_PC
      , PROJECT_ID
      , ACTIVITY_ID
      , RESOURCE_TYPE
      , RESOURCE_CATEGORY
      , RESOURCE_SUB_CAT
      , ANALYSIS_TYPE
      , ATT_IVC_IMG_FLG
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
      , PROCESS_INSTANCE
      , BILL_FSS_STATUS
      , OFAC_STATUS
      , SDN_PUBLISH_DATE
      , FSS_ACTIVITY_DT
      , FSS_CLEAR_OPRID
      , FSS_USER_OVR
      , REASON_CD
      , REASON_TYPE
      , PUBLIC_VOUCHER_NBR
      , PVN_GEN_LVL
      , CONTRACT_LINE_NUM
      , FINAL_FF_EXT_IND
      , TARGET_PYMT_DT
      , HOLD_UNTIL_DT
      , BI_APPROVAL_STATUS
      , TOT_VAT_RVC
      , TOT_VAT_RVC_BSE
      , TOT_VAT_RVC_XEU
      , BI_CREATE_PROC
      , BI_AP_LVL
      , EIVC_COPY_IND
      , ADD_DTTM
      , CREATEOPRID
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
    FROM LOGIC_SBIHLR
)
---- FILTER LAYER ----

, FILTER_SBIHLR as (
    SELECT *
    FROM RENAME_SBIHLR
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_SBIHLR
)

---- FINAL LAYER ----
SELECT
          INVOICE_HK
        , INVOICE
        , BUSINESS_UNIT
        , BILL_TO_CUST_ID
        , BILL_STATUS
        , CONTRACT_NUM
        , INVOICE_TYPE
        , CONSOL_HDR
        , CONSOL_KEY
        , CONSOL_SETID
        , CONSOL_CUST_ID
        , CONSOL_BUS_UNIT
        , CONSOL_INVOICE
        , ORIGINAL_INVOICE
        , PRIOR_ADJ_INVOICE
        , NEXT_ADJ_INVOICE
        , LATEST_INVOICE
        , ADJUSTED_FLAG
        , BILL_TYPE_ID
        , BILL_SOURCE_ID
        , BILL_CYCLE_ID
        , BILL_BY_ID
        , HDR_FIELDS_KEY
        , BILLING_FREQUENCY
        , TEMPLATE_IVC_FLG
        , TEMPLATE_INVOICE
        , RECURRING_START_DT
        , RECURRING_END_DT
        , AUTO_GEN_IVC_NUM
        , FROM_DT
        , TO_DT
        , ADDRESS_SEQ_NUM
        , BILL_TO_COPIES
        , BILL_TO_MEDIA
        , CNTCT_SEQ_NUM
        , NAME1
        , BUSINESS_UNIT_TO
        , CR_CARD_FLG
        , SUBCUST_QUAL1
        , SUBCUST_QUAL2
        , BILL_INQUIRY_PHONE
        , BILLING_SPECIALIST
        , BILLING_AUTHORITY
        , COLLECTOR
        , SALES_PERSON
        , CR_ANALYST
        , PYMNT_TERMS_CD
        , BANK_CD
        , BANK_ACCT_KEY
        , BI_CURRENCY_CD
        , BASE_CURRENCY
        , CURRENCY_CD_XEU
        , FINAL_CURCNV_FLG
        , CUR_RT_TYPE
        , CUR_RT_SOURCE
        , RATE_MULT
        , RATE_DIV
        , RATE_MULT_XEU
        , RATE_DIV_XEU
        , RATE_MULT_IU
        , RATE_DIV_IU
        , RATE_DATE
        , BI_PAID_AT_SRC
        , PAID_AMT
        , FORWARD_BAL_AMT
        , INVOICE_AMT_PRETAX
        , INVOICE_AMOUNT
        , PAID_AMT_BSE
        , FORWARD_BAL_BSE
        , INVOICE_PRETAX_BSE
        , INVOICE_AMT_BSE
        , FORWARD_BAL_XEU
        , INVOICE_PRETAX_XEU
        , INVOICE_AMT_XEU
        , PAID_AMT_XEU
        , INVOICE_DT
        , ACCOUNTING_DT
        , DT_INVOICED
        , DUE_DT
        , INVOICE_FORM_ID
        , IVC_PRINTED_FLG
        , IVC_PRINTED_DT
        , EDI_SENT_FLG
        , CF_ACTION_FLG
        , PRELOAD_IND
        , ENTRY_TYPE
        , ENTRY_REASON
        , AR_LVL
        , AR_DST_OPT
        , AR_ENTRY_CREATED
        , GEN_AR_ITEM_FLG
        , BUSINESS_UNIT_GL
        , GL_LVL
        , GL_ENTRY_CREATED
        , ENABLE_DFR_REV_FLG
        , DFR_ACCTG_DT_CD
        , DFR_REV_PRORATION
        , DFR_MID_PERIOD_DAY
        , DST_ID_DFR
        , BILL_STATUS_TEXT
        , MANUAL_LIN_NUM_FLG
        , LAST_LINE_SEQ_NUM
        , LAST_LINE_AAUX_SEQ
        , LAST_NOTE_SEQ_NUM
        , ACCRUE_UNBILLED
        , DOC_TYPE
        , DOC_SEQ_NBR
        , DOC_SEQ_DATE
        , PC_DISTRIB_STATUS
        , PO_REF
        , BUSINESS_UNIT_CA
        , CONTRACT_DT
        , CONTRACT_TYPE
        , DIRECT_INVOICING
        , BUSINESS_UNIT_OM
        , ORDER_NO
        , RMA_ID
        , ORDER_DATE
        , FREIGHT_TERMS
        , BILL_OF_LADING
        , SHIP_TO_CUST_ID
        , SHIP_TO_ADDR_NUM
        , SHIP_ID
        , SHIP_TYPE_ID
        , SHIP_FROM_BU
        , SOLD_TO_CUST_ID
        , SOLD_TO_ADDR_NUM
        , ACTIVITY_TYPE
        , SYSTEM_SOURCE
        , RANGE_SELECTION_ID
        , EMPLID
        , SSN
        , SERVICE_CUST_ID
        , SERVICE_ADDR_NUM
        , START_DT
        , END_DT
        , ERROR_STATUS_BI
        , COUNTRY_SHIP_TO
        , COUNTRY_SHIP_FROM
        , GEN_AP_VCHR_FLG
        , AP_CREATED_DT
        , DOC_SEQ_STATUS
        , EARLY_PY_DSCNT_PCT
        , DS_PY_TRMS_TIME_ID
        , VAT_ENTITY
        , MAX_TAX_FLG
        , TOT_SU_TAX
        , TOT_SU_TAX_BSE
        , TOT_SU_TAX_XEU
        , TOT_VAT
        , TOT_VAT_BSE
        , TOT_VAT_XEU
        , TOT_VAT_BASIS
        , TOT_VAT_BASIS_BSE
        , TOT_VAT_BASIS_XEU
        , PAYMENT_METHOD
        , PACKSLIP_NO
        , LC_ID
        , LOC_DOC_ID
        , PAID_REFERENCE
        , PPRC_PROMO_CD
        , EMAILID
        , FAX
        , LANGUAGE_CD
        , ENTRY_EVENT
        , REIMB_AGREEMENT
        , BI_BU_TAX_IND
        , EXD_INVOICE_NO
        , STX_TAX_AUTH_CD
        , TOT_EXD_AMT
        , TOT_EXD_AMT_BSE
        , TOT_STX_AMT
        , TOT_STX_AMT_BSE
        , PHYSICAL_NATURE
        , VAT_TREATMENT_GRP
        , COUNTRY_VAT_BILLFR
        , COUNTRY_VAT_BILLTO
        , STATE_SHIP_TO
        , STATE_SHIP_FROM
        , REPRINT_GROUP_ID
        , MAST_CONTR_ID
        , BUSINESS_UNIT_AM
        , SO_ID
        , BUSINESS_UNIT_RF
        , SOURCE_REF_TYPE
        , SOURCE_REF_NO
        , SOURCE_REF_KEY
        , ACCEPTGIRO_IND
        , AG_REF_NBR
        , IVC_DELIVERED_FLG
        , IVC_DELIVERED_DT
        , SUMMARIZE_IVC_FLG
        , BUSINESS_UNIT_PC
        , PROJECT_ID
        , ACTIVITY_ID
        , RESOURCE_TYPE
        , RESOURCE_CATEGORY
        , RESOURCE_SUB_CAT
        , ANALYSIS_TYPE
        , ATT_IVC_IMG_FLG
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
        , PROCESS_INSTANCE
        , BILL_FSS_STATUS
        , OFAC_STATUS
        , SDN_PUBLISH_DATE
        , FSS_ACTIVITY_DT
        , FSS_CLEAR_OPRID
        , FSS_USER_OVR
        , REASON_CD
        , REASON_TYPE
        , PUBLIC_VOUCHER_NBR
        , PVN_GEN_LVL
        , CONTRACT_LINE_NUM
        , FINAL_FF_EXT_IND
        , TARGET_PYMT_DT
        , HOLD_UNTIL_DT
        , BI_APPROVAL_STATUS
        , TOT_VAT_RVC
        , TOT_VAT_RVC_BSE
        , TOT_VAT_RVC_XEU
        , BI_CREATE_PROC
        , BI_AP_LVL
        , EIVC_COPY_IND
        , ADD_DTTM
        , CREATEOPRID
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
    WHERE existing.INVOICE_HK = JOIN_RESULT.INVOICE_HK 
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %} 
{% if not is_incremental() %}
/*the following qualify is to restrict multiple loads of touched records during the initial build. Ex: multiple row per hk, hashdiff */
qualify 1= row_number()over(partition by INVOICE_HK , HASHDIFF order by PSA_LOAD_DTS)
union all
    SELECT        MD5_BINARY(GR.VALUE) AS INVOICE_HK
, GR.VALUE AS INVOICE
    , null as BUSINESS_UNIT
    , null as BILL_TO_CUST_ID
    , null as BILL_STATUS
    , null as CONTRACT_NUM
    , null as INVOICE_TYPE
    , null as CONSOL_HDR
    , null as CONSOL_KEY
    , null as CONSOL_SETID
    , null as CONSOL_CUST_ID
    , null as CONSOL_BUS_UNIT
    , null as CONSOL_INVOICE
    , null as ORIGINAL_INVOICE
    , null as PRIOR_ADJ_INVOICE
    , null as NEXT_ADJ_INVOICE
    , null as LATEST_INVOICE
    , null as ADJUSTED_FLAG
    , null as BILL_TYPE_ID
    , null as BILL_SOURCE_ID
    , null as BILL_CYCLE_ID
    , null as BILL_BY_ID
    , null as HDR_FIELDS_KEY
    , null as BILLING_FREQUENCY
    , null as TEMPLATE_IVC_FLG
    , null as TEMPLATE_INVOICE
    , null as RECURRING_START_DT
    , null as RECURRING_END_DT
    , null as AUTO_GEN_IVC_NUM
    , null as FROM_DT
    , null as TO_DT
    , null as ADDRESS_SEQ_NUM
    , null as BILL_TO_COPIES
    , null as BILL_TO_MEDIA
    , null as CNTCT_SEQ_NUM
    , null as NAME1
    , null as BUSINESS_UNIT_TO
    , null as CR_CARD_FLG
    , null as SUBCUST_QUAL1
    , null as SUBCUST_QUAL2
    , null as BILL_INQUIRY_PHONE
    , null as BILLING_SPECIALIST
    , null as BILLING_AUTHORITY
    , null as COLLECTOR
    , null as SALES_PERSON
    , null as CR_ANALYST
    , null as PYMNT_TERMS_CD
    , null as BANK_CD
    , null as BANK_ACCT_KEY
    , null as BI_CURRENCY_CD
    , null as BASE_CURRENCY
    , null as CURRENCY_CD_XEU
    , null as FINAL_CURCNV_FLG
    , null as CUR_RT_TYPE
    , null as CUR_RT_SOURCE
    , null as RATE_MULT
    , null as RATE_DIV
    , null as RATE_MULT_XEU
    , null as RATE_DIV_XEU
    , null as RATE_MULT_IU
    , null as RATE_DIV_IU
    , null as RATE_DATE
    , null as BI_PAID_AT_SRC
    , null as PAID_AMT
    , null as FORWARD_BAL_AMT
    , null as INVOICE_AMT_PRETAX
    , null as INVOICE_AMOUNT
    , null as PAID_AMT_BSE
    , null as FORWARD_BAL_BSE
    , null as INVOICE_PRETAX_BSE
    , null as INVOICE_AMT_BSE
    , null as FORWARD_BAL_XEU
    , null as INVOICE_PRETAX_XEU
    , null as INVOICE_AMT_XEU
    , null as PAID_AMT_XEU
    , null as INVOICE_DT
    , null as ACCOUNTING_DT
    , null as DT_INVOICED
    , null as DUE_DT
    , null as INVOICE_FORM_ID
    , null as IVC_PRINTED_FLG
    , null as IVC_PRINTED_DT
    , null as EDI_SENT_FLG
    , null as CF_ACTION_FLG
    , null as PRELOAD_IND
    , null as ENTRY_TYPE
    , null as ENTRY_REASON
    , null as AR_LVL
    , null as AR_DST_OPT
    , null as AR_ENTRY_CREATED
    , null as GEN_AR_ITEM_FLG
    , null as BUSINESS_UNIT_GL
    , null as GL_LVL
    , null as GL_ENTRY_CREATED
    , null as ENABLE_DFR_REV_FLG
    , null as DFR_ACCTG_DT_CD
    , null as DFR_REV_PRORATION
    , null as DFR_MID_PERIOD_DAY
    , null as DST_ID_DFR
    , null as BILL_STATUS_TEXT
    , null as MANUAL_LIN_NUM_FLG
    , null as LAST_LINE_SEQ_NUM
    , null as LAST_LINE_AAUX_SEQ
    , null as LAST_NOTE_SEQ_NUM
    , null as ACCRUE_UNBILLED
    , null as DOC_TYPE
    , null as DOC_SEQ_NBR
    , null as DOC_SEQ_DATE
    , null as PC_DISTRIB_STATUS
    , null as PO_REF
    , null as BUSINESS_UNIT_CA
    , null as CONTRACT_DT
    , null as CONTRACT_TYPE
    , null as DIRECT_INVOICING
    , null as BUSINESS_UNIT_OM
    , null as ORDER_NO
    , null as RMA_ID
    , null as ORDER_DATE
    , null as FREIGHT_TERMS
    , null as BILL_OF_LADING
    , null as SHIP_TO_CUST_ID
    , null as SHIP_TO_ADDR_NUM
    , null as SHIP_ID
    , null as SHIP_TYPE_ID
    , null as SHIP_FROM_BU
    , null as SOLD_TO_CUST_ID
    , null as SOLD_TO_ADDR_NUM
    , null as ACTIVITY_TYPE
    , null as SYSTEM_SOURCE
    , null as RANGE_SELECTION_ID
    , null as EMPLID
    , null as SSN
    , null as SERVICE_CUST_ID
    , null as SERVICE_ADDR_NUM
    , null as START_DT
    , null as END_DT
    , null as ERROR_STATUS_BI
    , null as COUNTRY_SHIP_TO
    , null as COUNTRY_SHIP_FROM
    , null as GEN_AP_VCHR_FLG
    , null as AP_CREATED_DT
    , null as DOC_SEQ_STATUS
    , null as EARLY_PY_DSCNT_PCT
    , null as DS_PY_TRMS_TIME_ID
    , null as VAT_ENTITY
    , null as MAX_TAX_FLG
    , null as TOT_SU_TAX
    , null as TOT_SU_TAX_BSE
    , null as TOT_SU_TAX_XEU
    , null as TOT_VAT
    , null as TOT_VAT_BSE
    , null as TOT_VAT_XEU
    , null as TOT_VAT_BASIS
    , null as TOT_VAT_BASIS_BSE
    , null as TOT_VAT_BASIS_XEU
    , null as PAYMENT_METHOD
    , null as PACKSLIP_NO
    , null as LC_ID
    , null as LOC_DOC_ID
    , null as PAID_REFERENCE
    , null as PPRC_PROMO_CD
    , null as EMAILID
    , null as FAX
    , null as LANGUAGE_CD
    , null as ENTRY_EVENT
    , null as REIMB_AGREEMENT
    , null as BI_BU_TAX_IND
    , null as EXD_INVOICE_NO
    , null as STX_TAX_AUTH_CD
    , null as TOT_EXD_AMT
    , null as TOT_EXD_AMT_BSE
    , null as TOT_STX_AMT
    , null as TOT_STX_AMT_BSE
    , null as PHYSICAL_NATURE
    , null as VAT_TREATMENT_GRP
    , null as COUNTRY_VAT_BILLFR
    , null as COUNTRY_VAT_BILLTO
    , null as STATE_SHIP_TO
    , null as STATE_SHIP_FROM
    , null as REPRINT_GROUP_ID
    , null as MAST_CONTR_ID
    , null as BUSINESS_UNIT_AM
    , null as SO_ID
    , null as BUSINESS_UNIT_RF
    , null as SOURCE_REF_TYPE
    , null as SOURCE_REF_NO
    , null as SOURCE_REF_KEY
    , null as ACCEPTGIRO_IND
    , null as AG_REF_NBR
    , null as IVC_DELIVERED_FLG
    , null as IVC_DELIVERED_DT
    , null as SUMMARIZE_IVC_FLG
    , null as BUSINESS_UNIT_PC
    , null as PROJECT_ID
    , null as ACTIVITY_ID
    , null as RESOURCE_TYPE
    , null as RESOURCE_CATEGORY
    , null as RESOURCE_SUB_CAT
    , null as ANALYSIS_TYPE
    , null as ATT_IVC_IMG_FLG
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
    , null as PROCESS_INSTANCE
    , null as BILL_FSS_STATUS
    , null as OFAC_STATUS
    , null as SDN_PUBLISH_DATE
    , null as FSS_ACTIVITY_DT
    , null as FSS_CLEAR_OPRID
    , null as FSS_USER_OVR
    , null as REASON_CD
    , null as REASON_TYPE
    , null as PUBLIC_VOUCHER_NBR
    , null as PVN_GEN_LVL
    , null as CONTRACT_LINE_NUM
    , null as FINAL_FF_EXT_IND
    , null as TARGET_PYMT_DT
    , null as HOLD_UNTIL_DT
    , null as BI_APPROVAL_STATUS
    , null as TOT_VAT_RVC
    , null as TOT_VAT_RVC_BSE
    , null as TOT_VAT_RVC_XEU
    , null as BI_CREATE_PROC
    , null as BI_AP_LVL
    , null as EIVC_COPY_IND
, null as ADD_DTTM
, null as CREATEOPRID
, null as LAST_MAINT_OPRID
, null as LAST_UPDATE_DTTM
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