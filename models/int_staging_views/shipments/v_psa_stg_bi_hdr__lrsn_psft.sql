---- SRC LAYER ----
WITH
SRC_S              as ( SELECT * FROM {{ source('lrsn_psft_sysadm', 'ps_bi_hdr') }} as SRC  ),
SRC_A              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S              as ( SELECT * FROM lrsn_psft_sysadm.ps_bi_hdr )
, SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        INVOICE                                                      as                                         INVOICE_BK
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
      , CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED )                   as                                           LOAD_DTS
      , coalesce(nullif(trim(SHIP_TO_CUST_ID), ''), '-1')            as                                SHIP_TO_CUSTOMER_BK
      , coalesce(nullif(trim(SOLD_TO_CUST_ID), ''), '-1')            as                                SOLD_TO_CUSTOMER_BK
      , coalesce(nullif(trim(BILL_TO_CUST_ID), ''), '-1')            as                                BILL_TO_CUSTOMER_BK
      , SALES_PERSON                                                 as                                       SALES_REP_BK
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
        INVOICE_BK
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
      , SHIP_TO_CUSTOMER_BK
      , SOLD_TO_CUSTOMER_BK
      , BILL_TO_CUSTOMER_BK
      , SALES_REP_BK
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
    WHERE rec_src = 'USSDBR.ORCL.PSFTPRD.BI_HDR'
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
          INVOICE_BK
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
        , BKCC
        , SHIP_TO_CUSTOMER_BK
        , SOLD_TO_CUSTOMER_BK
        , BILL_TO_CUSTOMER_BK
        , SALES_REP_BK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(INVOICE_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as INVOICE_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(SOLD_TO_CUSTOMER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as CUSTOMER_SOLDTO_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(SHIP_TO_CUSTOMER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as CUSTOMER_SHIPTO_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(BILL_TO_CUSTOMER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as CUSTOMER_BILLTO_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(INVOICE_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(SOLD_TO_CUSTOMER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(SHIP_TO_CUSTOMER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BILL_TO_CUSTOMER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as INVOICE_CUSTOMER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(SALES_REP_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as SALES_REP_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(INVOICE_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(SALES_REP_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as INVOICE_SALES_REP_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(BUSINESS_UNIT::text), '^^') 
            , '||', IFNULL(TRIM(BILL_TO_CUST_ID::text), '^^') 
            , '||', IFNULL(TRIM(BILL_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(CONTRACT_NUM::text), '^^') 
            , '||', IFNULL(TRIM(INVOICE_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(CONSOL_HDR::text), '^^') 
            , '||', IFNULL(TRIM(CONSOL_KEY::text), '^^') 
            , '||', IFNULL(TRIM(CONSOL_SETID::text), '^^') 
            , '||', IFNULL(TRIM(CONSOL_CUST_ID::text), '^^') 
            , '||', IFNULL(TRIM(CONSOL_BUS_UNIT::text), '^^') 
            , '||', IFNULL(TRIM(CONSOL_INVOICE::text), '^^') 
            , '||', IFNULL(TRIM(ORIGINAL_INVOICE::text), '^^') 
            , '||', IFNULL(TRIM(PRIOR_ADJ_INVOICE::text), '^^') 
            , '||', IFNULL(TRIM(NEXT_ADJ_INVOICE::text), '^^') 
            , '||', IFNULL(TRIM(LATEST_INVOICE::text), '^^') 
            , '||', IFNULL(TRIM(ADJUSTED_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(BILL_TYPE_ID::text), '^^') 
            , '||', IFNULL(TRIM(BILL_SOURCE_ID::text), '^^') 
            , '||', IFNULL(TRIM(BILL_CYCLE_ID::text), '^^') 
            , '||', IFNULL(TRIM(BILL_BY_ID::text), '^^') 
            , '||', IFNULL(TRIM(HDR_FIELDS_KEY::text), '^^') 
            , '||', IFNULL(TRIM(BILLING_FREQUENCY::text), '^^') 
            , '||', IFNULL(TRIM(TEMPLATE_IVC_FLG::text), '^^') 
            , '||', IFNULL(TRIM(TEMPLATE_INVOICE::text), '^^') 
            , '||', IFNULL(TRIM(RECURRING_START_DT::text), '^^') 
            , '||', IFNULL(TRIM(RECURRING_END_DT::text), '^^') 
            , '||', IFNULL(TRIM(AUTO_GEN_IVC_NUM::text), '^^') 
            , '||', IFNULL(TRIM(FROM_DT::text), '^^') 
            , '||', IFNULL(TRIM(TO_DT::text), '^^') 
            , '||', IFNULL(TRIM(ADDRESS_SEQ_NUM::text), '^^') 
            , '||', IFNULL(TRIM(BILL_TO_COPIES::text), '^^') 
            , '||', IFNULL(TRIM(BILL_TO_MEDIA::text), '^^') 
            , '||', IFNULL(TRIM(CNTCT_SEQ_NUM::text), '^^') 
            , '||', IFNULL(TRIM(NAME1::text), '^^') 
            , '||', IFNULL(TRIM(BUSINESS_UNIT_TO::text), '^^') 
            , '||', IFNULL(TRIM(CR_CARD_FLG::text), '^^') 
            , '||', IFNULL(TRIM(SUBCUST_QUAL1::text), '^^') 
            , '||', IFNULL(TRIM(SUBCUST_QUAL2::text), '^^') 
            , '||', IFNULL(TRIM(BILL_INQUIRY_PHONE::text), '^^') 
            , '||', IFNULL(TRIM(BILLING_SPECIALIST::text), '^^') 
            , '||', IFNULL(TRIM(BILLING_AUTHORITY::text), '^^') 
            , '||', IFNULL(TRIM(COLLECTOR::text), '^^') 
            , '||', IFNULL(TRIM(SALES_PERSON::text), '^^') 
            , '||', IFNULL(TRIM(CR_ANALYST::text), '^^') 
            , '||', IFNULL(TRIM(PYMNT_TERMS_CD::text), '^^') 
            , '||', IFNULL(TRIM(BANK_CD::text), '^^') 
            , '||', IFNULL(TRIM(BANK_ACCT_KEY::text), '^^') 
            , '||', IFNULL(TRIM(BI_CURRENCY_CD::text), '^^') 
            , '||', IFNULL(TRIM(BASE_CURRENCY::text), '^^') 
            , '||', IFNULL(TRIM(CURRENCY_CD_XEU::text), '^^') 
            , '||', IFNULL(TRIM(FINAL_CURCNV_FLG::text), '^^') 
            , '||', IFNULL(TRIM(CUR_RT_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(CUR_RT_SOURCE::text), '^^') 
            , '||', IFNULL(TRIM(RATE_MULT::text), '^^') 
            , '||', IFNULL(TRIM(RATE_DIV::text), '^^') 
            , '||', IFNULL(TRIM(RATE_MULT_XEU::text), '^^') 
            , '||', IFNULL(TRIM(RATE_DIV_XEU::text), '^^') 
            , '||', IFNULL(TRIM(RATE_MULT_IU::text), '^^') 
            , '||', IFNULL(TRIM(RATE_DIV_IU::text), '^^') 
            , '||', IFNULL(TRIM(RATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(BI_PAID_AT_SRC::text), '^^') 
            , '||', IFNULL(TRIM(PAID_AMT::text), '^^') 
            , '||', IFNULL(TRIM(FORWARD_BAL_AMT::text), '^^') 
            , '||', IFNULL(TRIM(INVOICE_AMT_PRETAX::text), '^^') 
            , '||', IFNULL(TRIM(INVOICE_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(PAID_AMT_BSE::text), '^^') 
            , '||', IFNULL(TRIM(FORWARD_BAL_BSE::text), '^^') 
            , '||', IFNULL(TRIM(INVOICE_PRETAX_BSE::text), '^^') 
            , '||', IFNULL(TRIM(INVOICE_AMT_BSE::text), '^^') 
            , '||', IFNULL(TRIM(FORWARD_BAL_XEU::text), '^^') 
            , '||', IFNULL(TRIM(INVOICE_PRETAX_XEU::text), '^^') 
            , '||', IFNULL(TRIM(INVOICE_AMT_XEU::text), '^^') 
            , '||', IFNULL(TRIM(PAID_AMT_XEU::text), '^^') 
            , '||', IFNULL(TRIM(INVOICE_DT::text), '^^') 
            , '||', IFNULL(TRIM(ACCOUNTING_DT::text), '^^') 
            , '||', IFNULL(TRIM(DT_INVOICED::text), '^^') 
            , '||', IFNULL(TRIM(DUE_DT::text), '^^') 
            , '||', IFNULL(TRIM(INVOICE_FORM_ID::text), '^^') 
            , '||', IFNULL(TRIM(IVC_PRINTED_FLG::text), '^^') 
            , '||', IFNULL(TRIM(IVC_PRINTED_DT::text), '^^') 
            , '||', IFNULL(TRIM(EDI_SENT_FLG::text), '^^') 
            , '||', IFNULL(TRIM(CF_ACTION_FLG::text), '^^') 
            , '||', IFNULL(TRIM(PRELOAD_IND::text), '^^') 
            , '||', IFNULL(TRIM(ENTRY_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(ENTRY_REASON::text), '^^') 
            , '||', IFNULL(TRIM(AR_LVL::text), '^^') 
            , '||', IFNULL(TRIM(AR_DST_OPT::text), '^^') 
            , '||', IFNULL(TRIM(AR_ENTRY_CREATED::text), '^^') 
            , '||', IFNULL(TRIM(GEN_AR_ITEM_FLG::text), '^^') 
            , '||', IFNULL(TRIM(BUSINESS_UNIT_GL::text), '^^') 
            , '||', IFNULL(TRIM(GL_LVL::text), '^^') 
            , '||', IFNULL(TRIM(GL_ENTRY_CREATED::text), '^^') 
            , '||', IFNULL(TRIM(ENABLE_DFR_REV_FLG::text), '^^') 
            , '||', IFNULL(TRIM(DFR_ACCTG_DT_CD::text), '^^') 
            , '||', IFNULL(TRIM(DFR_REV_PRORATION::text), '^^') 
            , '||', IFNULL(TRIM(DFR_MID_PERIOD_DAY::text), '^^') 
            , '||', IFNULL(TRIM(DST_ID_DFR::text), '^^') 
            , '||', IFNULL(TRIM(BILL_STATUS_TEXT::text), '^^') 
            , '||', IFNULL(TRIM(MANUAL_LIN_NUM_FLG::text), '^^') 
            , '||', IFNULL(TRIM(LAST_LINE_SEQ_NUM::text), '^^') 
            , '||', IFNULL(TRIM(LAST_LINE_AAUX_SEQ::text), '^^') 
            , '||', IFNULL(TRIM(LAST_NOTE_SEQ_NUM::text), '^^') 
            , '||', IFNULL(TRIM(ACCRUE_UNBILLED::text), '^^') 
            , '||', IFNULL(TRIM(DOC_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(DOC_SEQ_NBR::text), '^^') 
            , '||', IFNULL(TRIM(DOC_SEQ_DATE::text), '^^') 
            , '||', IFNULL(TRIM(PC_DISTRIB_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(PO_REF::text), '^^') 
            , '||', IFNULL(TRIM(BUSINESS_UNIT_CA::text), '^^') 
            , '||', IFNULL(TRIM(CONTRACT_DT::text), '^^') 
            , '||', IFNULL(TRIM(CONTRACT_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(DIRECT_INVOICING::text), '^^') 
            , '||', IFNULL(TRIM(BUSINESS_UNIT_OM::text), '^^') 
            , '||', IFNULL(TRIM(ORDER_NO::text), '^^') 
            , '||', IFNULL(TRIM(RMA_ID::text), '^^') 
            , '||', IFNULL(TRIM(ORDER_DATE::text), '^^') 
            , '||', IFNULL(TRIM(FREIGHT_TERMS::text), '^^') 
            , '||', IFNULL(TRIM(BILL_OF_LADING::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_TO_CUST_ID::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_TO_ADDR_NUM::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_ID::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_TYPE_ID::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_FROM_BU::text), '^^') 
            , '||', IFNULL(TRIM(SOLD_TO_CUST_ID::text), '^^') 
            , '||', IFNULL(TRIM(SOLD_TO_ADDR_NUM::text), '^^') 
            , '||', IFNULL(TRIM(ACTIVITY_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(SYSTEM_SOURCE::text), '^^') 
            , '||', IFNULL(TRIM(RANGE_SELECTION_ID::text), '^^') 
            , '||', IFNULL(TRIM(EMPLID::text), '^^') 
            , '||', IFNULL(TRIM(SSN::text), '^^') 
            , '||', IFNULL(TRIM(SERVICE_CUST_ID::text), '^^') 
            , '||', IFNULL(TRIM(SERVICE_ADDR_NUM::text), '^^') 
            , '||', IFNULL(TRIM(START_DT::text), '^^') 
            , '||', IFNULL(TRIM(END_DT::text), '^^') 
            , '||', IFNULL(TRIM(ERROR_STATUS_BI::text), '^^') 
            , '||', IFNULL(TRIM(COUNTRY_SHIP_TO::text), '^^') 
            , '||', IFNULL(TRIM(COUNTRY_SHIP_FROM::text), '^^') 
            , '||', IFNULL(TRIM(GEN_AP_VCHR_FLG::text), '^^') 
            , '||', IFNULL(TRIM(AP_CREATED_DT::text), '^^') 
            , '||', IFNULL(TRIM(DOC_SEQ_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(EARLY_PY_DSCNT_PCT::text), '^^') 
            , '||', IFNULL(TRIM(DS_PY_TRMS_TIME_ID::text), '^^') 
            , '||', IFNULL(TRIM(VAT_ENTITY::text), '^^') 
            , '||', IFNULL(TRIM(MAX_TAX_FLG::text), '^^') 
            , '||', IFNULL(TRIM(TOT_SU_TAX::text), '^^') 
            , '||', IFNULL(TRIM(TOT_SU_TAX_BSE::text), '^^') 
            , '||', IFNULL(TRIM(TOT_SU_TAX_XEU::text), '^^') 
            , '||', IFNULL(TRIM(TOT_VAT::text), '^^') 
            , '||', IFNULL(TRIM(TOT_VAT_BSE::text), '^^') 
            , '||', IFNULL(TRIM(TOT_VAT_XEU::text), '^^') 
            , '||', IFNULL(TRIM(TOT_VAT_BASIS::text), '^^') 
            , '||', IFNULL(TRIM(TOT_VAT_BASIS_BSE::text), '^^') 
            , '||', IFNULL(TRIM(TOT_VAT_BASIS_XEU::text), '^^') 
            , '||', IFNULL(TRIM(PAYMENT_METHOD::text), '^^') 
            , '||', IFNULL(TRIM(PACKSLIP_NO::text), '^^') 
            , '||', IFNULL(TRIM(LC_ID::text), '^^') 
            , '||', IFNULL(TRIM(LOC_DOC_ID::text), '^^') 
            , '||', IFNULL(TRIM(PAID_REFERENCE::text), '^^') 
            , '||', IFNULL(TRIM(PPRC_PROMO_CD::text), '^^') 
            , '||', IFNULL(TRIM(EMAILID::text), '^^') 
            , '||', IFNULL(TRIM(FAX::text), '^^') 
            , '||', IFNULL(TRIM(LANGUAGE_CD::text), '^^') 
            , '||', IFNULL(TRIM(ENTRY_EVENT::text), '^^') 
            , '||', IFNULL(TRIM(REIMB_AGREEMENT::text), '^^') 
            , '||', IFNULL(TRIM(BI_BU_TAX_IND::text), '^^') 
            , '||', IFNULL(TRIM(EXD_INVOICE_NO::text), '^^') 
            , '||', IFNULL(TRIM(STX_TAX_AUTH_CD::text), '^^') 
            , '||', IFNULL(TRIM(TOT_EXD_AMT::text), '^^') 
            , '||', IFNULL(TRIM(TOT_EXD_AMT_BSE::text), '^^') 
            , '||', IFNULL(TRIM(TOT_STX_AMT::text), '^^') 
            , '||', IFNULL(TRIM(TOT_STX_AMT_BSE::text), '^^') 
            , '||', IFNULL(TRIM(PHYSICAL_NATURE::text), '^^') 
            , '||', IFNULL(TRIM(VAT_TREATMENT_GRP::text), '^^') 
            , '||', IFNULL(TRIM(COUNTRY_VAT_BILLFR::text), '^^') 
            , '||', IFNULL(TRIM(COUNTRY_VAT_BILLTO::text), '^^') 
            , '||', IFNULL(TRIM(STATE_SHIP_TO::text), '^^') 
            , '||', IFNULL(TRIM(STATE_SHIP_FROM::text), '^^') 
            , '||', IFNULL(TRIM(REPRINT_GROUP_ID::text), '^^') 
            , '||', IFNULL(TRIM(MAST_CONTR_ID::text), '^^') 
            , '||', IFNULL(TRIM(BUSINESS_UNIT_AM::text), '^^') 
            , '||', IFNULL(TRIM(SO_ID::text), '^^') 
            , '||', IFNULL(TRIM(BUSINESS_UNIT_RF::text), '^^') 
            , '||', IFNULL(TRIM(SOURCE_REF_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(SOURCE_REF_NO::text), '^^') 
            , '||', IFNULL(TRIM(SOURCE_REF_KEY::text), '^^') 
            , '||', IFNULL(TRIM(ACCEPTGIRO_IND::text), '^^') 
            , '||', IFNULL(TRIM(AG_REF_NBR::text), '^^') 
            , '||', IFNULL(TRIM(IVC_DELIVERED_FLG::text), '^^') 
            , '||', IFNULL(TRIM(IVC_DELIVERED_DT::text), '^^') 
            , '||', IFNULL(TRIM(SUMMARIZE_IVC_FLG::text), '^^') 
            , '||', IFNULL(TRIM(BUSINESS_UNIT_PC::text), '^^') 
            , '||', IFNULL(TRIM(PROJECT_ID::text), '^^') 
            , '||', IFNULL(TRIM(ACTIVITY_ID::text), '^^') 
            , '||', IFNULL(TRIM(RESOURCE_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(RESOURCE_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(RESOURCE_SUB_CAT::text), '^^') 
            , '||', IFNULL(TRIM(ANALYSIS_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(ATT_IVC_IMG_FLG::text), '^^') 
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
            , '||', IFNULL(TRIM(PROCESS_INSTANCE::text), '^^') 
            , '||', IFNULL(TRIM(BILL_FSS_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(OFAC_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(SDN_PUBLISH_DATE::text), '^^') 
            , '||', IFNULL(TRIM(FSS_ACTIVITY_DT::text), '^^') 
            , '||', IFNULL(TRIM(FSS_CLEAR_OPRID::text), '^^') 
            , '||', IFNULL(TRIM(FSS_USER_OVR::text), '^^') 
            , '||', IFNULL(TRIM(REASON_CD::text), '^^') 
            , '||', IFNULL(TRIM(REASON_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(PUBLIC_VOUCHER_NBR::text), '^^') 
            , '||', IFNULL(TRIM(PVN_GEN_LVL::text), '^^') 
            , '||', IFNULL(TRIM(CONTRACT_LINE_NUM::text), '^^') 
            , '||', IFNULL(TRIM(FINAL_FF_EXT_IND::text), '^^') 
            , '||', IFNULL(TRIM(TARGET_PYMT_DT::text), '^^') 
            , '||', IFNULL(TRIM(HOLD_UNTIL_DT::text), '^^') 
            , '||', IFNULL(TRIM(BI_APPROVAL_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(TOT_VAT_RVC::text), '^^') 
            , '||', IFNULL(TRIM(TOT_VAT_RVC_BSE::text), '^^') 
            , '||', IFNULL(TRIM(TOT_VAT_RVC_XEU::text), '^^') 
            , '||', IFNULL(TRIM(BI_CREATE_PROC::text), '^^') 
            , '||', IFNULL(TRIM(BI_AP_LVL::text), '^^') 
            , '||', IFNULL(TRIM(EIVC_COPY_IND::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
