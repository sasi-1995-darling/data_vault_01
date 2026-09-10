---- SRC LAYER ----
WITH
SRC_SRC            as ( SELECT * FROM {{ source('outd_ocf_ap', 'ap_invoice_lines_all') }} as SRC  ),
SRC_ref_bkcc       as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC 
                        WHERE rec_src = 'USCLOUD.ORCL.OCFPRD.AP_INVOICE_LINES_ALL' )

/*
SRC_SRC            as ( SELECT * FROM outd_ocf_ap.ap_invoice_lines_all )
SRC_ref_bkcc       as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_SRC as (
    SELECT
        INVOICE_ID                                                   as                                      INVOICE_ID_BK
      , INVOICE_ID
      , LINE_NUMBER                                                  as                                    INVOICE_LINE_BK
      , LINE_NUMBER
      , ATTRIBUTE_6
      , ATTRIBUTE_7
      , ORIGINAL_BASE_AMOUNT
      , INCOME_TAX_REGION
      , GLOBAL_ATTRIBUTE_DATE_1
      , PJC_CONTEXT_CATEGORY
      , PJC_PROJECT_ID
      , PJC_RESERVED_ATTRIBUTE_8
      , PJC_RESERVED_ATTRIBUTE_9
      , PJC_RESERVED_ATTRIBUTE_10
      , PJC_USER_DEF_ATTRIBUTE_1
      , PJC_USER_DEF_ATTRIBUTE_2
      , GLOBAL_ATTRIBUTE_7
      , GLOBAL_ATTRIBUTE_8
      , ATTRIBUTE_DATE_4
      , PJC_FUNDING_ALLOCATION_ID
      , PJC_TASK_ID
      , PJC_EXPENDITURE_TYPE_ID
      , PJC_EXPENDITURE_ITEM_DATE
      , PJC_RESERVED_ATTRIBUTE_1
      , PJC_RESERVED_ATTRIBUTE_5
      , PJC_RESERVED_ATTRIBUTE_6
      , SOURCE_TRX_LEVEL_TYPE
      , RETAINED_AMOUNT
      , RETAINED_AMOUNT_REMAINING
      , RETAINED_INVOICE_ID
      , RETAINED_LINE_NUMBER
      , LINE_SELECTED_FOR_RELEASE_FLAG
      , PJC_USER_DEF_ATTRIBUTE_3
      , PJC_USER_DEF_ATTRIBUTE_4
      , PJC_USER_DEF_ATTRIBUTE_5
      , DEF_ACCTG_NUMBER_OF_PERIODS
      , DEF_ACCTG_PERIOD_TYPE
      , SET_OF_BOOKS_ID
      , MODEL_NUMBER
      , LINE_TYPE_LOOKUP_CODE
      , DISTRIBUTION_SET_ID
      , QUANTITY_INVOICED
      , UNIT_MEAS_LOOKUP_CODE
      , UNIT_PRICE
      , SHIP_FROM_LOCATION_ID
      , TASK_ID
      , EXPENDITURE_TYPE
      , EXPENDITURE_ITEM_DATE
      , CORRECTED_LINE_NUMBER
      , PO_HEADER_ID
      , PO_LINE_LOCATION_ID
      , BASE_AMOUNT
      , ROUNDING_AMT
      , AMOUNT
      , CONSUMPTION_ADVICE_LINE_ID
      , GLOBAL_ATTRIBUTE_NUMBER_4
      , GLOBAL_ATTRIBUTE_NUMBER_5
      , OBJECT_VERSION_NUMBER
      , JOB_DEFINITION_NAME
      , GLOBAL_ATTRIBUTE_NUMBER_3
      , INVOICE_INCLUDES_PREPAY_FLAG
      , PA_CC_AR_INVOICE_ID
      , WEB_PARAMETER_ID
      , ADJUSTMENT_REASON
      , MERCHANT_DOCUMENT_NUMBER
      , TRANSACTION_LINE_GEOGRAPHY_ID
      , GLOBAL_ATTRIBUTE_5
      , ATTRIBUTE_DATE_5
      , GLOBAL_ATTRIBUTE_NUMBER_1
      , GLOBAL_ATTRIBUTE_6
      , GLOBAL_ATTRIBUTE_18
      , GLOBAL_ATTRIBUTE_19
      , GLOBAL_ATTRIBUTE_20
      , LINE_SELECTED_FOR_APPL_FLAG
      , PA_CC_PROCESSED_CODE
      , AWARD_ID
      , PA_CC_AR_INVOICE_LINE_NUM
      , AWT_GROUP_ID
      , REFERENCE_1
      , REFERENCE_2
      , RECEIPT_VERIFIED_FLAG
      , RECEIPT_REQUIRED_FLAG
      , RECEIPT_MISSING_FLAG
      , START_EXPENSE_DATE
      , END_EXPENSE_DATE
      , PREPAY_APPL_REQUEST_ID
      , APPLICATION_ID
      , REFERENCE_KEY_1
      , REFERENCE_KEY_2
      , REFERENCE_KEY_3
      , PRODUCT_TABLE
      , ATTRIBUTE_14
      , ATTRIBUTE_15
      , PA_QUANTITY
      , COMPANY_PREPAID_INVOICE_ID
      , CC_REVERSAL_FLAG
      , ATTRIBUTE_3
      , ATTRIBUTE_4
      , ATTRIBUTE_5
      , ATTRIBUTE_10
      , ATTRIBUTE_11
      , ATTRIBUTE_12
      , ATTRIBUTE_8
      , ATTRIBUTE_9
      , GLOBAL_ATTRIBUTE_4
      , PJC_RESERVED_ATTRIBUTE_7
      , PJC_CONTRACT_ID
      , PJC_CONTRACT_LINE_ID
      , BUDGET_DATE
      , FUNDS_STATUS
      , PERIOD_NAME
      , DEFERRED_ACCTG_FLAG
      , DEF_ACCTG_START_DATE
      , PJC_USER_DEF_ATTRIBUTE_8
      , PJC_USER_DEF_ATTRIBUTE_9
      , PJC_USER_DEF_ATTRIBUTE_10
      , ATTRIBUTE_NUMBER_1
      , ATTRIBUTE_NUMBER_2
      , ATTRIBUTE_NUMBER_3
      , ATTRIBUTE_NUMBER_4
      , ATTRIBUTE_NUMBER_5
      , GLOBAL_ATTRIBUTE_13
      , PRORATE_ACROSS_ALL_ITEMS
      , WARRANTY_NUMBER
      , ACCOUNT_SEGMENT
      , DEF_ACCTG_END_DATE
      , TOTAL_REC_TAX_AMOUNT
      , PJC_USER_DEF_ATTRIBUTE_6
      , PJC_USER_DEF_ATTRIBUTE_7
      , ATTRIBUTE_13
      , COST_FACTOR_ID
      , CONTROL_AMOUNT
      , ASSESSABLE_VALUE
      , BALANCING_SEGMENT
      , COST_CENTER_SEGMENT
      , OVERLAY_DIST_CODE_CONCAT
      , DEFAULT_DIST_CCID
      , ACCOUNTING_DATE
      , GLOBAL_ATTRIBUTE_10
      , GLOBAL_ATTRIBUTE_11
      , GLOBAL_ATTRIBUTE_12
      , INCLUDED_TAX_AMOUNT
      , PJC_RESERVED_ATTRIBUTE_2
      , PJC_RESERVED_ATTRIBUTE_3
      , PJC_RESERVED_ATTRIBUTE_4
      , PURCHASING_CATEGORY_ID
      , ORIGINAL_ROUNDING_AMT
      , CANCELLED_FLAG
      , TYPE_1099
      , DISCARDED_FLAG
      , ORIGINAL_AMOUNT
      , WFAPPROVAL_STATUS
      , USSGL_TRANSACTION_CODE
      , JUSTIFICATION
      , EXPENSE_GROUP
      , PO_RELEASE_ID
      , PO_LINE_ID
      , CREATION_DATE
      , CREATED_BY
      , LAST_UPDATED_BY
      , EXPENDITURE_ORGANIZATION_ID
      , CREDIT_CARD_TRX_ID
      , LAST_UPDATE_LOGIN
      , PROGRAM_APPLICATION_ID
      , LAST_UPDATE_DATE
      , ACC_REFERENCE_VALUE_1
      , GLOBAL_ATTRIBUTE_DATE_2
      , GLOBAL_ATTRIBUTE_DATE_3
      , GLOBAL_ATTRIBUTE_DATE_4
      , GLOBAL_ATTRIBUTE_DATE_5
      , CORRECTED_INV_ID
      , TOTAL_NREC_TAX_AMOUNT
      , MATCH_TYPE
      , RCV_TRANSACTION_ID
      , FINAL_MATCH_FLAG
      , ASSETS_TRACKING_FLAG
      , ASSET_BOOK_TYPE_CODE
      , ASSET_CATEGORY_ID
      , PO_DISTRIBUTION_ID
      , REFERENCE_KEY_4
      , REFERENCE_KEY_5
      , TAX_ALREADY_CALCULATED_FLAG
      , SHIP_TO_LOCATION_ID
      , TOTAL_REC_TAX_AMT_FUNCL_CURR
      , TOTAL_NREC_TAX_AMT_FUNCL_CURR
      , GLOBAL_ATTRIBUTE_9
      , INTENDED_USE_CLASSIF_ID
      , PRIMARY_INTENDED_USE
      , TAX
      , TAX_JURISDICTION_CODE
      , REQUESTER_ID
      , DESCRIPTION
      , LINE_SOURCE
      , ORG_ID
      , LINE_GROUP_NUMBER
      , INVENTORY_ITEM_ID
      , ITEM_DESCRIPTION
      , FISCAL_CHARGE_TYPE
      , GLOBAL_ATTRIBUTE_1
      , GLOBAL_ATTRIBUTE_2
      , RECEIPT_CURRENCY_CODE
      , RECEIPT_CONVERSION_RATE
      , RECEIPT_CURRENCY_AMOUNT
      , DAILY_AMOUNT
      , PROGRAM_ID
      , PROGRAM_UPDATE_DATE
      , REQUEST_ID
      , GLOBAL_ATTRIBUTE_16
      , GLOBAL_ATTRIBUTE_17
      , GLOBAL_ATTRIBUTE_14
      , GLOBAL_ATTRIBUTE_15
      , GLOBAL_ATTRIBUTE_CATEGORY
      , GLOBAL_ATTRIBUTE_3
      , DEF_ACCTG_ACCRUAL_CCID
      , SHIP_TO_CUST_LOCATION_ID
      , STAT_AMOUNT
      , PREPAY_INVOICE_ID
      , PREPAY_LINE_NUMBER
      , PROJECT_ID
      , GENERATE_DISTS
      , TAX_REGIME_CODE
      , SERIAL_NUMBER
      , MANUFACTURER
      , JOB_DEFINITION_PACKAGE
      , FINAL_DISCHARGE_LOCATION_ID
      , FOS_XFACE_FLAG
      , MATCHING_RULE_SET_ID
      , MATCHING_RULE_ID
      , RCV_SHIPMENT_LINE_ID
      , PJC_ORGANIZATION_ID
      , TAX_STATUS_CODE
      , TAX_RATE
      , TAX_CODE_ID
      , HISTORICAL_FLAG
      , DISPUTABLE_FLAG
      , USER_DEFINED_FISC_CLASS
      , TRX_BUSINESS_CATEGORY
      , SUMMARY_TAX_LINE_ID
      , PRODUCT_TYPE
      , PRODUCT_CATEGORY
      , TAX_RATE_ID
      , TAX_RATE_CODE
      , PRODUCT_FISC_CLASSIFICATION
      , PROD_FC_CATEG_ID
      , LINE_OWNER_ROLE
      , MERCHANT_NAME
      , MERCHANT_REFERENCE
      , MERCHANT_TAX_REG_NUMBER
      , MERCHANT_TAXPAYER_ID
      , PJC_BILLABLE_FLAG
      , PJC_CAPITALIZABLE_FLAG
      , PJC_WORK_TYPE_ID
      , ATTRIBUTE_CATEGORY
      , ATTRIBUTE_1
      , ATTRIBUTE_2
      , GLOBAL_ATTRIBUTE_NUMBER_2
      , TAX_CLASSIFICATION_CODE
      , SOURCE_EVENT_CLASS_CODE
      , SOURCE_ENTITY_CODE
      , SOURCE_TRX_ID
      , COUNTRY_OF_SUPPLY
      , ATTRIBUTE_DATE_1
      , ATTRIBUTE_DATE_2
      , ATTRIBUTE_DATE_3
      , SOURCE_LINE_ID
      , SOURCE_APPLICATION_ID
      , CONSUMPTION_ADVICE_HEADER_ID
      , LCM_ENABLED_FLAG
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
          INVOICE_ID_BK
        , INVOICE_ID
        , INVOICE_LINE_BK
        , LINE_NUMBER
        , ATTRIBUTE_6
        , ATTRIBUTE_7
        , ORIGINAL_BASE_AMOUNT
        , INCOME_TAX_REGION
        , GLOBAL_ATTRIBUTE_DATE_1
        , PJC_CONTEXT_CATEGORY
        , PJC_PROJECT_ID
        , PJC_RESERVED_ATTRIBUTE_8
        , PJC_RESERVED_ATTRIBUTE_9
        , PJC_RESERVED_ATTRIBUTE_10
        , PJC_USER_DEF_ATTRIBUTE_1
        , PJC_USER_DEF_ATTRIBUTE_2
        , GLOBAL_ATTRIBUTE_7
        , GLOBAL_ATTRIBUTE_8
        , ATTRIBUTE_DATE_4
        , PJC_FUNDING_ALLOCATION_ID
        , PJC_TASK_ID
        , PJC_EXPENDITURE_TYPE_ID
        , PJC_EXPENDITURE_ITEM_DATE
        , PJC_RESERVED_ATTRIBUTE_1
        , PJC_RESERVED_ATTRIBUTE_5
        , PJC_RESERVED_ATTRIBUTE_6
        , SOURCE_TRX_LEVEL_TYPE
        , RETAINED_AMOUNT
        , RETAINED_AMOUNT_REMAINING
        , RETAINED_INVOICE_ID
        , RETAINED_LINE_NUMBER
        , LINE_SELECTED_FOR_RELEASE_FLAG
        , PJC_USER_DEF_ATTRIBUTE_3
        , PJC_USER_DEF_ATTRIBUTE_4
        , PJC_USER_DEF_ATTRIBUTE_5
        , DEF_ACCTG_NUMBER_OF_PERIODS
        , DEF_ACCTG_PERIOD_TYPE
        , SET_OF_BOOKS_ID
        , MODEL_NUMBER
        , LINE_TYPE_LOOKUP_CODE
        , DISTRIBUTION_SET_ID
        , QUANTITY_INVOICED
        , UNIT_MEAS_LOOKUP_CODE
        , UNIT_PRICE
        , SHIP_FROM_LOCATION_ID
        , TASK_ID
        , EXPENDITURE_TYPE
        , EXPENDITURE_ITEM_DATE
        , CORRECTED_LINE_NUMBER
        , PO_HEADER_ID
        , PO_LINE_LOCATION_ID
        , BASE_AMOUNT
        , ROUNDING_AMT
        , AMOUNT
        , CONSUMPTION_ADVICE_LINE_ID
        , GLOBAL_ATTRIBUTE_NUMBER_4
        , GLOBAL_ATTRIBUTE_NUMBER_5
        , OBJECT_VERSION_NUMBER
        , JOB_DEFINITION_NAME
        , GLOBAL_ATTRIBUTE_NUMBER_3
        , INVOICE_INCLUDES_PREPAY_FLAG
        , PA_CC_AR_INVOICE_ID
        , WEB_PARAMETER_ID
        , ADJUSTMENT_REASON
        , MERCHANT_DOCUMENT_NUMBER
        , TRANSACTION_LINE_GEOGRAPHY_ID
        , GLOBAL_ATTRIBUTE_5
        , ATTRIBUTE_DATE_5
        , GLOBAL_ATTRIBUTE_NUMBER_1
        , GLOBAL_ATTRIBUTE_6
        , GLOBAL_ATTRIBUTE_18
        , GLOBAL_ATTRIBUTE_19
        , GLOBAL_ATTRIBUTE_20
        , LINE_SELECTED_FOR_APPL_FLAG
        , PA_CC_PROCESSED_CODE
        , AWARD_ID
        , PA_CC_AR_INVOICE_LINE_NUM
        , AWT_GROUP_ID
        , REFERENCE_1
        , REFERENCE_2
        , RECEIPT_VERIFIED_FLAG
        , RECEIPT_REQUIRED_FLAG
        , RECEIPT_MISSING_FLAG
        , START_EXPENSE_DATE
        , END_EXPENSE_DATE
        , PREPAY_APPL_REQUEST_ID
        , APPLICATION_ID
        , REFERENCE_KEY_1
        , REFERENCE_KEY_2
        , REFERENCE_KEY_3
        , PRODUCT_TABLE
        , ATTRIBUTE_14
        , ATTRIBUTE_15
        , PA_QUANTITY
        , COMPANY_PREPAID_INVOICE_ID
        , CC_REVERSAL_FLAG
        , ATTRIBUTE_3
        , ATTRIBUTE_4
        , ATTRIBUTE_5
        , ATTRIBUTE_10
        , ATTRIBUTE_11
        , ATTRIBUTE_12
        , ATTRIBUTE_8
        , ATTRIBUTE_9
        , GLOBAL_ATTRIBUTE_4
        , PJC_RESERVED_ATTRIBUTE_7
        , PJC_CONTRACT_ID
        , PJC_CONTRACT_LINE_ID
        , BUDGET_DATE
        , FUNDS_STATUS
        , PERIOD_NAME
        , DEFERRED_ACCTG_FLAG
        , DEF_ACCTG_START_DATE
        , PJC_USER_DEF_ATTRIBUTE_8
        , PJC_USER_DEF_ATTRIBUTE_9
        , PJC_USER_DEF_ATTRIBUTE_10
        , ATTRIBUTE_NUMBER_1
        , ATTRIBUTE_NUMBER_2
        , ATTRIBUTE_NUMBER_3
        , ATTRIBUTE_NUMBER_4
        , ATTRIBUTE_NUMBER_5
        , GLOBAL_ATTRIBUTE_13
        , PRORATE_ACROSS_ALL_ITEMS
        , WARRANTY_NUMBER
        , ACCOUNT_SEGMENT
        , DEF_ACCTG_END_DATE
        , TOTAL_REC_TAX_AMOUNT
        , PJC_USER_DEF_ATTRIBUTE_6
        , PJC_USER_DEF_ATTRIBUTE_7
        , ATTRIBUTE_13
        , COST_FACTOR_ID
        , CONTROL_AMOUNT
        , ASSESSABLE_VALUE
        , BALANCING_SEGMENT
        , COST_CENTER_SEGMENT
        , OVERLAY_DIST_CODE_CONCAT
        , DEFAULT_DIST_CCID
        , ACCOUNTING_DATE
        , GLOBAL_ATTRIBUTE_10
        , GLOBAL_ATTRIBUTE_11
        , GLOBAL_ATTRIBUTE_12
        , INCLUDED_TAX_AMOUNT
        , PJC_RESERVED_ATTRIBUTE_2
        , PJC_RESERVED_ATTRIBUTE_3
        , PJC_RESERVED_ATTRIBUTE_4
        , PURCHASING_CATEGORY_ID
        , ORIGINAL_ROUNDING_AMT
        , CANCELLED_FLAG
        , TYPE_1099
        , DISCARDED_FLAG
        , ORIGINAL_AMOUNT
        , WFAPPROVAL_STATUS
        , USSGL_TRANSACTION_CODE
        , JUSTIFICATION
        , EXPENSE_GROUP
        , PO_RELEASE_ID
        , PO_LINE_ID
        , CREATION_DATE
        , CREATED_BY
        , LAST_UPDATED_BY
        , EXPENDITURE_ORGANIZATION_ID
        , CREDIT_CARD_TRX_ID
        , LAST_UPDATE_LOGIN
        , PROGRAM_APPLICATION_ID
        , LAST_UPDATE_DATE
        , ACC_REFERENCE_VALUE_1
        , GLOBAL_ATTRIBUTE_DATE_2
        , GLOBAL_ATTRIBUTE_DATE_3
        , GLOBAL_ATTRIBUTE_DATE_4
        , GLOBAL_ATTRIBUTE_DATE_5
        , CORRECTED_INV_ID
        , TOTAL_NREC_TAX_AMOUNT
        , MATCH_TYPE
        , RCV_TRANSACTION_ID
        , FINAL_MATCH_FLAG
        , ASSETS_TRACKING_FLAG
        , ASSET_BOOK_TYPE_CODE
        , ASSET_CATEGORY_ID
        , PO_DISTRIBUTION_ID
        , REFERENCE_KEY_4
        , REFERENCE_KEY_5
        , TAX_ALREADY_CALCULATED_FLAG
        , SHIP_TO_LOCATION_ID
        , TOTAL_REC_TAX_AMT_FUNCL_CURR
        , TOTAL_NREC_TAX_AMT_FUNCL_CURR
        , GLOBAL_ATTRIBUTE_9
        , INTENDED_USE_CLASSIF_ID
        , PRIMARY_INTENDED_USE
        , TAX
        , TAX_JURISDICTION_CODE
        , REQUESTER_ID
        , DESCRIPTION
        , LINE_SOURCE
        , ORG_ID
        , LINE_GROUP_NUMBER
        , INVENTORY_ITEM_ID
        , ITEM_DESCRIPTION
        , FISCAL_CHARGE_TYPE
        , GLOBAL_ATTRIBUTE_1
        , GLOBAL_ATTRIBUTE_2
        , RECEIPT_CURRENCY_CODE
        , RECEIPT_CONVERSION_RATE
        , RECEIPT_CURRENCY_AMOUNT
        , DAILY_AMOUNT
        , PROGRAM_ID
        , PROGRAM_UPDATE_DATE
        , REQUEST_ID
        , GLOBAL_ATTRIBUTE_16
        , GLOBAL_ATTRIBUTE_17
        , GLOBAL_ATTRIBUTE_14
        , GLOBAL_ATTRIBUTE_15
        , GLOBAL_ATTRIBUTE_CATEGORY
        , GLOBAL_ATTRIBUTE_3
        , DEF_ACCTG_ACCRUAL_CCID
        , SHIP_TO_CUST_LOCATION_ID
        , STAT_AMOUNT
        , PREPAY_INVOICE_ID
        , PREPAY_LINE_NUMBER
        , PROJECT_ID
        , GENERATE_DISTS
        , TAX_REGIME_CODE
        , SERIAL_NUMBER
        , MANUFACTURER
        , JOB_DEFINITION_PACKAGE
        , FINAL_DISCHARGE_LOCATION_ID
        , FOS_XFACE_FLAG
        , MATCHING_RULE_SET_ID
        , MATCHING_RULE_ID
        , RCV_SHIPMENT_LINE_ID
        , PJC_ORGANIZATION_ID
        , TAX_STATUS_CODE
        , TAX_RATE
        , TAX_CODE_ID
        , HISTORICAL_FLAG
        , DISPUTABLE_FLAG
        , USER_DEFINED_FISC_CLASS
        , TRX_BUSINESS_CATEGORY
        , SUMMARY_TAX_LINE_ID
        , PRODUCT_TYPE
        , PRODUCT_CATEGORY
        , TAX_RATE_ID
        , TAX_RATE_CODE
        , PRODUCT_FISC_CLASSIFICATION
        , PROD_FC_CATEG_ID
        , LINE_OWNER_ROLE
        , MERCHANT_NAME
        , MERCHANT_REFERENCE
        , MERCHANT_TAX_REG_NUMBER
        , MERCHANT_TAXPAYER_ID
        , PJC_BILLABLE_FLAG
        , PJC_CAPITALIZABLE_FLAG
        , PJC_WORK_TYPE_ID
        , ATTRIBUTE_CATEGORY
        , ATTRIBUTE_1
        , ATTRIBUTE_2
        , GLOBAL_ATTRIBUTE_NUMBER_2
        , TAX_CLASSIFICATION_CODE
        , SOURCE_EVENT_CLASS_CODE
        , SOURCE_ENTITY_CODE
        , SOURCE_TRX_ID
        , COUNTRY_OF_SUPPLY
        , ATTRIBUTE_DATE_1
        , ATTRIBUTE_DATE_2
        , ATTRIBUTE_DATE_3
        , SOURCE_LINE_ID
        , SOURCE_APPLICATION_ID
        , CONSUMPTION_ADVICE_HEADER_ID
        , LCM_ENABLED_FLAG
        , _FIVETRAN_DELETED
        , _FIVETRAN_SYNCED
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , BKCC
        , REC_SRC
        , LOAD_DTS
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(INVOICE_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(LINE_NUMBER as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as SUPPLIER_INVOICE_LINE_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(INVOICE_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as SUPPLIER_INVOICE_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(INVOICE_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(INVOICE_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(LINE_NUMBER as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as LNK_SUPPLIER_INVOICE_LINE_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(ATTRIBUTE_6::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_7::text), '^^') 
            , '||', IFNULL(TRIM(ORIGINAL_BASE_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(INCOME_TAX_REGION::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_DATE_1::text), '^^') 
            , '||', IFNULL(TRIM(PJC_CONTEXT_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(PJC_PROJECT_ID::text), '^^') 
            , '||', IFNULL(TRIM(PJC_RESERVED_ATTRIBUTE_8::text), '^^') 
            , '||', IFNULL(TRIM(PJC_RESERVED_ATTRIBUTE_9::text), '^^') 
            , '||', IFNULL(TRIM(PJC_RESERVED_ATTRIBUTE_10::text), '^^') 
            , '||', IFNULL(TRIM(PJC_USER_DEF_ATTRIBUTE_1::text), '^^') 
            , '||', IFNULL(TRIM(PJC_USER_DEF_ATTRIBUTE_2::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_7::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_8::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_DATE_4::text), '^^') 
            , '||', IFNULL(TRIM(PJC_FUNDING_ALLOCATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(PJC_TASK_ID::text), '^^') 
            , '||', IFNULL(TRIM(PJC_EXPENDITURE_TYPE_ID::text), '^^') 
            , '||', IFNULL(TRIM(PJC_EXPENDITURE_ITEM_DATE::text), '^^') 
            , '||', IFNULL(TRIM(PJC_RESERVED_ATTRIBUTE_1::text), '^^') 
            , '||', IFNULL(TRIM(PJC_RESERVED_ATTRIBUTE_5::text), '^^') 
            , '||', IFNULL(TRIM(PJC_RESERVED_ATTRIBUTE_6::text), '^^') 
            , '||', IFNULL(TRIM(SOURCE_TRX_LEVEL_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(RETAINED_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(RETAINED_AMOUNT_REMAINING::text), '^^') 
            , '||', IFNULL(TRIM(RETAINED_INVOICE_ID::text), '^^') 
            , '||', IFNULL(TRIM(RETAINED_LINE_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(LINE_SELECTED_FOR_RELEASE_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(PJC_USER_DEF_ATTRIBUTE_3::text), '^^') 
            , '||', IFNULL(TRIM(PJC_USER_DEF_ATTRIBUTE_4::text), '^^') 
            , '||', IFNULL(TRIM(PJC_USER_DEF_ATTRIBUTE_5::text), '^^') 
            , '||', IFNULL(TRIM(DEF_ACCTG_NUMBER_OF_PERIODS::text), '^^') 
            , '||', IFNULL(TRIM(DEF_ACCTG_PERIOD_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(SET_OF_BOOKS_ID::text), '^^') 
            , '||', IFNULL(TRIM(MODEL_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(LINE_TYPE_LOOKUP_CODE::text), '^^') 
            , '||', IFNULL(TRIM(DISTRIBUTION_SET_ID::text), '^^') 
            , '||', IFNULL(TRIM(QUANTITY_INVOICED::text), '^^') 
            , '||', IFNULL(TRIM(UNIT_MEAS_LOOKUP_CODE::text), '^^') 
            , '||', IFNULL(TRIM(UNIT_PRICE::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_FROM_LOCATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(TASK_ID::text), '^^') 
            , '||', IFNULL(TRIM(EXPENDITURE_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(EXPENDITURE_ITEM_DATE::text), '^^') 
            , '||', IFNULL(TRIM(CORRECTED_LINE_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(PO_HEADER_ID::text), '^^') 
            , '||', IFNULL(TRIM(PO_LINE_LOCATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(BASE_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(ROUNDING_AMT::text), '^^') 
            , '||', IFNULL(TRIM(AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(CONSUMPTION_ADVICE_LINE_ID::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_NUMBER_4::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_NUMBER_5::text), '^^') 
            , '||', IFNULL(TRIM(OBJECT_VERSION_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(JOB_DEFINITION_NAME::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_NUMBER_3::text), '^^') 
            , '||', IFNULL(TRIM(INVOICE_INCLUDES_PREPAY_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(PA_CC_AR_INVOICE_ID::text), '^^') 
            , '||', IFNULL(TRIM(WEB_PARAMETER_ID::text), '^^') 
            , '||', IFNULL(TRIM(ADJUSTMENT_REASON::text), '^^') 
            , '||', IFNULL(TRIM(MERCHANT_DOCUMENT_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(TRANSACTION_LINE_GEOGRAPHY_ID::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_5::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_DATE_5::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_NUMBER_1::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_6::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_18::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_19::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_20::text), '^^') 
            , '||', IFNULL(TRIM(LINE_SELECTED_FOR_APPL_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(PA_CC_PROCESSED_CODE::text), '^^') 
            , '||', IFNULL(TRIM(AWARD_ID::text), '^^') 
            , '||', IFNULL(TRIM(PA_CC_AR_INVOICE_LINE_NUM::text), '^^') 
            , '||', IFNULL(TRIM(AWT_GROUP_ID::text), '^^') 
            , '||', IFNULL(TRIM(REFERENCE_1::text), '^^') 
            , '||', IFNULL(TRIM(REFERENCE_2::text), '^^') 
            , '||', IFNULL(TRIM(RECEIPT_VERIFIED_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(RECEIPT_REQUIRED_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(RECEIPT_MISSING_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(START_EXPENSE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(END_EXPENSE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(PREPAY_APPL_REQUEST_ID::text), '^^') 
            , '||', IFNULL(TRIM(APPLICATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(REFERENCE_KEY_1::text), '^^') 
            , '||', IFNULL(TRIM(REFERENCE_KEY_2::text), '^^') 
            , '||', IFNULL(TRIM(REFERENCE_KEY_3::text), '^^') 
            , '||', IFNULL(TRIM(PRODUCT_TABLE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_14::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_15::text), '^^') 
            , '||', IFNULL(TRIM(PA_QUANTITY::text), '^^') 
            , '||', IFNULL(TRIM(COMPANY_PREPAID_INVOICE_ID::text), '^^') 
            , '||', IFNULL(TRIM(CC_REVERSAL_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_3::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_4::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_5::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_10::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_11::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_12::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_8::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_9::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_4::text), '^^') 
            , '||', IFNULL(TRIM(PJC_RESERVED_ATTRIBUTE_7::text), '^^') 
            , '||', IFNULL(TRIM(PJC_CONTRACT_ID::text), '^^') 
            , '||', IFNULL(TRIM(PJC_CONTRACT_LINE_ID::text), '^^') 
            , '||', IFNULL(TRIM(BUDGET_DATE::text), '^^') 
            , '||', IFNULL(TRIM(FUNDS_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(PERIOD_NAME::text), '^^') 
            , '||', IFNULL(TRIM(DEFERRED_ACCTG_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(DEF_ACCTG_START_DATE::text), '^^') 
            , '||', IFNULL(TRIM(PJC_USER_DEF_ATTRIBUTE_8::text), '^^') 
            , '||', IFNULL(TRIM(PJC_USER_DEF_ATTRIBUTE_9::text), '^^') 
            , '||', IFNULL(TRIM(PJC_USER_DEF_ATTRIBUTE_10::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_1::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_2::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_3::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_4::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_5::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_13::text), '^^') 
            , '||', IFNULL(TRIM(PRORATE_ACROSS_ALL_ITEMS::text), '^^') 
            , '||', IFNULL(TRIM(WARRANTY_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(ACCOUNT_SEGMENT::text), '^^') 
            , '||', IFNULL(TRIM(DEF_ACCTG_END_DATE::text), '^^') 
            , '||', IFNULL(TRIM(TOTAL_REC_TAX_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(PJC_USER_DEF_ATTRIBUTE_6::text), '^^') 
            , '||', IFNULL(TRIM(PJC_USER_DEF_ATTRIBUTE_7::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_13::text), '^^') 
            , '||', IFNULL(TRIM(COST_FACTOR_ID::text), '^^') 
            , '||', IFNULL(TRIM(CONTROL_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(ASSESSABLE_VALUE::text), '^^') 
            , '||', IFNULL(TRIM(BALANCING_SEGMENT::text), '^^') 
            , '||', IFNULL(TRIM(COST_CENTER_SEGMENT::text), '^^') 
            , '||', IFNULL(TRIM(OVERLAY_DIST_CODE_CONCAT::text), '^^') 
            , '||', IFNULL(TRIM(DEFAULT_DIST_CCID::text), '^^') 
            , '||', IFNULL(TRIM(ACCOUNTING_DATE::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_10::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_11::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_12::text), '^^') 
            , '||', IFNULL(TRIM(INCLUDED_TAX_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(PJC_RESERVED_ATTRIBUTE_2::text), '^^') 
            , '||', IFNULL(TRIM(PJC_RESERVED_ATTRIBUTE_3::text), '^^') 
            , '||', IFNULL(TRIM(PJC_RESERVED_ATTRIBUTE_4::text), '^^') 
            , '||', IFNULL(TRIM(PURCHASING_CATEGORY_ID::text), '^^') 
            , '||', IFNULL(TRIM(ORIGINAL_ROUNDING_AMT::text), '^^') 
            , '||', IFNULL(TRIM(CANCELLED_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(TYPE_1099::text), '^^') 
            , '||', IFNULL(TRIM(DISCARDED_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(ORIGINAL_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(WFAPPROVAL_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(USSGL_TRANSACTION_CODE::text), '^^') 
            , '||', IFNULL(TRIM(JUSTIFICATION::text), '^^') 
            , '||', IFNULL(TRIM(EXPENSE_GROUP::text), '^^') 
            , '||', IFNULL(TRIM(PO_RELEASE_ID::text), '^^') 
            , '||', IFNULL(TRIM(PO_LINE_ID::text), '^^') 
            , '||', IFNULL(TRIM(CREATION_DATE::text), '^^') 
            , '||', IFNULL(TRIM(CREATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(EXPENDITURE_ORGANIZATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(CREDIT_CARD_TRX_ID::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_LOGIN::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_APPLICATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(ACC_REFERENCE_VALUE_1::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_DATE_2::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_DATE_3::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_DATE_4::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_DATE_5::text), '^^') 
            , '||', IFNULL(TRIM(CORRECTED_INV_ID::text), '^^') 
            , '||', IFNULL(TRIM(TOTAL_NREC_TAX_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(MATCH_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(RCV_TRANSACTION_ID::text), '^^') 
            , '||', IFNULL(TRIM(FINAL_MATCH_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(ASSETS_TRACKING_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(ASSET_BOOK_TYPE_CODE::text), '^^') 
            , '||', IFNULL(TRIM(ASSET_CATEGORY_ID::text), '^^') 
            , '||', IFNULL(TRIM(PO_DISTRIBUTION_ID::text), '^^') 
            , '||', IFNULL(TRIM(REFERENCE_KEY_4::text), '^^') 
            , '||', IFNULL(TRIM(REFERENCE_KEY_5::text), '^^') 
            , '||', IFNULL(TRIM(TAX_ALREADY_CALCULATED_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_TO_LOCATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(TOTAL_REC_TAX_AMT_FUNCL_CURR::text), '^^') 
            , '||', IFNULL(TRIM(TOTAL_NREC_TAX_AMT_FUNCL_CURR::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_9::text), '^^') 
            , '||', IFNULL(TRIM(INTENDED_USE_CLASSIF_ID::text), '^^') 
            , '||', IFNULL(TRIM(PRIMARY_INTENDED_USE::text), '^^') 
            , '||', IFNULL(TRIM(TAX::text), '^^') 
            , '||', IFNULL(TRIM(TAX_JURISDICTION_CODE::text), '^^') 
            , '||', IFNULL(TRIM(REQUESTER_ID::text), '^^') 
            , '||', IFNULL(TRIM(DESCRIPTION::text), '^^') 
            , '||', IFNULL(TRIM(LINE_SOURCE::text), '^^') 
            , '||', IFNULL(TRIM(ORG_ID::text), '^^') 
            , '||', IFNULL(TRIM(LINE_GROUP_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(INVENTORY_ITEM_ID::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_DESCRIPTION::text), '^^') 
            , '||', IFNULL(TRIM(FISCAL_CHARGE_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_1::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_2::text), '^^') 
            , '||', IFNULL(TRIM(RECEIPT_CURRENCY_CODE::text), '^^') 
            , '||', IFNULL(TRIM(RECEIPT_CONVERSION_RATE::text), '^^') 
            , '||', IFNULL(TRIM(RECEIPT_CURRENCY_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(DAILY_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_ID::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_UPDATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(REQUEST_ID::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_16::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_17::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_14::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_15::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_3::text), '^^') 
            , '||', IFNULL(TRIM(DEF_ACCTG_ACCRUAL_CCID::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_TO_CUST_LOCATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(STAT_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(PREPAY_INVOICE_ID::text), '^^') 
            , '||', IFNULL(TRIM(PREPAY_LINE_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(PROJECT_ID::text), '^^') 
            , '||', IFNULL(TRIM(GENERATE_DISTS::text), '^^') 
            , '||', IFNULL(TRIM(TAX_REGIME_CODE::text), '^^') 
            , '||', IFNULL(TRIM(SERIAL_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(MANUFACTURER::text), '^^') 
            , '||', IFNULL(TRIM(JOB_DEFINITION_PACKAGE::text), '^^') 
            , '||', IFNULL(TRIM(FINAL_DISCHARGE_LOCATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(FOS_XFACE_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(MATCHING_RULE_SET_ID::text), '^^') 
            , '||', IFNULL(TRIM(MATCHING_RULE_ID::text), '^^') 
            , '||', IFNULL(TRIM(RCV_SHIPMENT_LINE_ID::text), '^^') 
            , '||', IFNULL(TRIM(PJC_ORGANIZATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(TAX_STATUS_CODE::text), '^^') 
            , '||', IFNULL(TRIM(TAX_RATE::text), '^^') 
            , '||', IFNULL(TRIM(TAX_CODE_ID::text), '^^') 
            , '||', IFNULL(TRIM(HISTORICAL_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(DISPUTABLE_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(USER_DEFINED_FISC_CLASS::text), '^^') 
            , '||', IFNULL(TRIM(TRX_BUSINESS_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(SUMMARY_TAX_LINE_ID::text), '^^') 
            , '||', IFNULL(TRIM(PRODUCT_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(PRODUCT_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(TAX_RATE_ID::text), '^^') 
            , '||', IFNULL(TRIM(TAX_RATE_CODE::text), '^^') 
            , '||', IFNULL(TRIM(PRODUCT_FISC_CLASSIFICATION::text), '^^') 
            , '||', IFNULL(TRIM(PROD_FC_CATEG_ID::text), '^^') 
            , '||', IFNULL(TRIM(LINE_OWNER_ROLE::text), '^^') 
            , '||', IFNULL(TRIM(MERCHANT_NAME::text), '^^') 
            , '||', IFNULL(TRIM(MERCHANT_REFERENCE::text), '^^') 
            , '||', IFNULL(TRIM(MERCHANT_TAX_REG_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(MERCHANT_TAXPAYER_ID::text), '^^') 
            , '||', IFNULL(TRIM(PJC_BILLABLE_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(PJC_CAPITALIZABLE_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(PJC_WORK_TYPE_ID::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_1::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_2::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_NUMBER_2::text), '^^') 
            , '||', IFNULL(TRIM(TAX_CLASSIFICATION_CODE::text), '^^') 
            , '||', IFNULL(TRIM(SOURCE_EVENT_CLASS_CODE::text), '^^') 
            , '||', IFNULL(TRIM(SOURCE_ENTITY_CODE::text), '^^') 
            , '||', IFNULL(TRIM(SOURCE_TRX_ID::text), '^^') 
            , '||', IFNULL(TRIM(COUNTRY_OF_SUPPLY::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_DATE_1::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_DATE_2::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_DATE_3::text), '^^') 
            , '||', IFNULL(TRIM(SOURCE_LINE_ID::text), '^^') 
            , '||', IFNULL(TRIM(SOURCE_APPLICATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(CONSUMPTION_ADVICE_HEADER_ID::text), '^^') 
            , '||', IFNULL(TRIM(LCM_ENABLED_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
