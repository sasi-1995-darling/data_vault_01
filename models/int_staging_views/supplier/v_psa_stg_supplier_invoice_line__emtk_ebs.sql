---- SRC LAYER ----
WITH
SRC_SRC            as ( SELECT * FROM {{ source('emtk_ebs_ap', 'ap_invoice_lines_all') }} as SRC  ),
SRC_ref_bkcc       as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC 
                        WHERE rec_src = 'USWIOC.ORCL.EBSEMTK.AP_INVOICE_LINES_ALL' )

/*
SRC_SRC            as ( SELECT * FROM emtk_ebs_ap.ap_invoice_lines_all )
SRC_ref_bkcc       as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_SRC as (
    SELECT
        INVOICE_ID                                                   as                                      INVOICE_ID_BK
      , INVOICE_ID
      , LINE_NUMBER                                                  as                                    INVOICE_LINE_BK
      , LINE_NUMBER
      , LINE_TYPE_LOOKUP_CODE
      , REQUESTER_ID
      , DESCRIPTION
      , LINE_SOURCE
      , ORG_ID
      , LINE_GROUP_NUMBER
      , INVENTORY_ITEM_ID
      , ITEM_DESCRIPTION
      , SERIAL_NUMBER
      , MANUFACTURER
      , MODEL_NUMBER
      , WARRANTY_NUMBER
      , GENERATE_DISTS
      , MATCH_TYPE
      , DISTRIBUTION_SET_ID
      , ACCOUNT_SEGMENT
      , BALANCING_SEGMENT
      , COST_CENTER_SEGMENT
      , OVERLAY_DIST_CODE_CONCAT
      , DEFAULT_DIST_CCID
      , PRORATE_ACROSS_ALL_ITEMS
      , ACCOUNTING_DATE
      , PERIOD_NAME
      , DEFERRED_ACCTG_FLAG
      , DEF_ACCTG_START_DATE
      , DEF_ACCTG_END_DATE
      , DEF_ACCTG_NUMBER_OF_PERIODS
      , DEF_ACCTG_PERIOD_TYPE
      , SET_OF_BOOKS_ID
      , AMOUNT
      , BASE_AMOUNT
      , ROUNDING_AMT
      , QUANTITY_INVOICED
      , UNIT_MEAS_LOOKUP_CODE
      , UNIT_PRICE
      , WFAPPROVAL_STATUS
      , USSGL_TRANSACTION_CODE
      , DISCARDED_FLAG
      , ORIGINAL_AMOUNT
      , ORIGINAL_BASE_AMOUNT
      , ORIGINAL_ROUNDING_AMT
      , CANCELLED_FLAG
      , INCOME_TAX_REGION
      , TYPE_1099
      , STAT_AMOUNT
      , PREPAY_INVOICE_ID
      , PREPAY_LINE_NUMBER
      , INVOICE_INCLUDES_PREPAY_FLAG
      , CORRECTED_INV_ID
      , CORRECTED_LINE_NUMBER
      , PO_HEADER_ID
      , PO_LINE_ID
      , PO_RELEASE_ID
      , PO_LINE_LOCATION_ID
      , PO_DISTRIBUTION_ID
      , RCV_TRANSACTION_ID
      , FINAL_MATCH_FLAG
      , ASSETS_TRACKING_FLAG
      , ASSET_BOOK_TYPE_CODE
      , ASSET_CATEGORY_ID
      , PROJECT_ID
      , TASK_ID
      , EXPENDITURE_TYPE
      , EXPENDITURE_ITEM_DATE
      , EXPENDITURE_ORGANIZATION_ID
      , PA_QUANTITY
      , PA_CC_AR_INVOICE_ID
      , PA_CC_AR_INVOICE_LINE_NUM
      , PA_CC_PROCESSED_CODE
      , AWARD_ID
      , AWT_GROUP_ID
      , REFERENCE_1
      , REFERENCE_2
      , RECEIPT_VERIFIED_FLAG
      , RECEIPT_REQUIRED_FLAG
      , RECEIPT_MISSING_FLAG
      , JUSTIFICATION
      , EXPENSE_GROUP
      , START_EXPENSE_DATE
      , END_EXPENSE_DATE
      , RECEIPT_CURRENCY_CODE
      , RECEIPT_CONVERSION_RATE
      , RECEIPT_CURRENCY_AMOUNT
      , DAILY_AMOUNT
      , WEB_PARAMETER_ID
      , ADJUSTMENT_REASON
      , MERCHANT_DOCUMENT_NUMBER
      , MERCHANT_REFERENCE
      , MERCHANT_TAX_REG_NUMBER
      , MERCHANT_TAXPAYER_ID
      , COUNTRY_OF_SUPPLY
      , CREDIT_CARD_TRX_ID
      , COMPANY_PREPAID_INVOICE_ID
      , CC_REVERSAL_FLAG
      , CREATION_DATE
      , CREATED_BY
      , LAST_UPDATED_BY
      , LAST_UPDATE_DATE
      , LAST_UPDATE_LOGIN
      , PROGRAM_APPLICATION_ID
      , PROGRAM_ID
      , PROGRAM_UPDATE_DATE
      , REQUEST_ID
      , ATTRIBUTE_CATEGORY
      , ATTRIBUTE1
      , ATTRIBUTE2
      , ATTRIBUTE3
      , ATTRIBUTE4
      , ATTRIBUTE5
      , ATTRIBUTE6
      , ATTRIBUTE7
      , ATTRIBUTE8
      , ATTRIBUTE9
      , ATTRIBUTE10
      , ATTRIBUTE11
      , ATTRIBUTE12
      , ATTRIBUTE13
      , ATTRIBUTE14
      , ATTRIBUTE15
      , GLOBAL_ATTRIBUTE_CATEGORY
      , GLOBAL_ATTRIBUTE1
      , GLOBAL_ATTRIBUTE2
      , GLOBAL_ATTRIBUTE3
      , GLOBAL_ATTRIBUTE4
      , GLOBAL_ATTRIBUTE5
      , GLOBAL_ATTRIBUTE6
      , GLOBAL_ATTRIBUTE7
      , GLOBAL_ATTRIBUTE8
      , GLOBAL_ATTRIBUTE9
      , GLOBAL_ATTRIBUTE10
      , GLOBAL_ATTRIBUTE11
      , GLOBAL_ATTRIBUTE12
      , GLOBAL_ATTRIBUTE13
      , GLOBAL_ATTRIBUTE14
      , GLOBAL_ATTRIBUTE15
      , GLOBAL_ATTRIBUTE16
      , GLOBAL_ATTRIBUTE17
      , GLOBAL_ATTRIBUTE18
      , GLOBAL_ATTRIBUTE19
      , GLOBAL_ATTRIBUTE20
      , LINE_SELECTED_FOR_APPL_FLAG
      , PREPAY_APPL_REQUEST_ID
      , APPLICATION_ID
      , PRODUCT_TABLE
      , REFERENCE_KEY1
      , REFERENCE_KEY2
      , REFERENCE_KEY3
      , REFERENCE_KEY4
      , REFERENCE_KEY5
      , PURCHASING_CATEGORY_ID
      , COST_FACTOR_ID
      , CONTROL_AMOUNT
      , ASSESSABLE_VALUE
      , TOTAL_REC_TAX_AMOUNT
      , TOTAL_NREC_TAX_AMOUNT
      , TOTAL_REC_TAX_AMT_FUNCL_CURR
      , TOTAL_NREC_TAX_AMT_FUNCL_CURR
      , INCLUDED_TAX_AMOUNT
      , PRIMARY_INTENDED_USE
      , TAX_ALREADY_CALCULATED_FLAG
      , SHIP_TO_LOCATION_ID
      , PRODUCT_TYPE
      , PRODUCT_CATEGORY
      , PRODUCT_FISC_CLASSIFICATION
      , USER_DEFINED_FISC_CLASS
      , TRX_BUSINESS_CATEGORY
      , SUMMARY_TAX_LINE_ID
      , TAX_REGIME_CODE
      , TAX
      , TAX_JURISDICTION_CODE
      , TAX_STATUS_CODE
      , TAX_RATE_ID
      , TAX_RATE_CODE
      , TAX_RATE
      , TAX_CODE_ID
      , HISTORICAL_FLAG
      , TAX_CLASSIFICATION_CODE
      , SOURCE_APPLICATION_ID
      , SOURCE_EVENT_CLASS_CODE
      , SOURCE_ENTITY_CODE
      , SOURCE_TRX_ID
      , SOURCE_LINE_ID
      , SOURCE_TRX_LEVEL_TYPE
      , RETAINED_AMOUNT
      , RETAINED_AMOUNT_REMAINING
      , RETAINED_INVOICE_ID
      , RETAINED_LINE_NUMBER
      , LINE_SELECTED_FOR_RELEASE_FLAG
      , LINE_OWNER_ROLE
      , DISPUTABLE_FLAG
      , RCV_SHIPMENT_LINE_ID
      , AIL_INVOICE_ID
      , AIL_DISTRIBUTION_LINE_NUMBER
      , AIL_INVOICE_ID2
      , AIL_DISTRIBUTION_LINE_NUMBER2
      , AIL_INVOICE_ID3
      , AIL_DISTRIBUTION_LINE_NUMBER3
      , AIL_INVOICE_ID4
      , PAY_AWT_GROUP_ID
      , MERCHANT_NAME_1
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
          INVOICE_ID_BK
        , INVOICE_ID
        , INVOICE_LINE_BK
        , LINE_NUMBER
        , LINE_TYPE_LOOKUP_CODE
        , REQUESTER_ID
        , DESCRIPTION
        , LINE_SOURCE
        , ORG_ID
        , LINE_GROUP_NUMBER
        , INVENTORY_ITEM_ID
        , ITEM_DESCRIPTION
        , SERIAL_NUMBER
        , MANUFACTURER
        , MODEL_NUMBER
        , WARRANTY_NUMBER
        , GENERATE_DISTS
        , MATCH_TYPE
        , DISTRIBUTION_SET_ID
        , ACCOUNT_SEGMENT
        , BALANCING_SEGMENT
        , COST_CENTER_SEGMENT
        , OVERLAY_DIST_CODE_CONCAT
        , DEFAULT_DIST_CCID
        , PRORATE_ACROSS_ALL_ITEMS
        , ACCOUNTING_DATE
        , PERIOD_NAME
        , DEFERRED_ACCTG_FLAG
        , DEF_ACCTG_START_DATE
        , DEF_ACCTG_END_DATE
        , DEF_ACCTG_NUMBER_OF_PERIODS
        , DEF_ACCTG_PERIOD_TYPE
        , SET_OF_BOOKS_ID
        , AMOUNT
        , BASE_AMOUNT
        , ROUNDING_AMT
        , QUANTITY_INVOICED
        , UNIT_MEAS_LOOKUP_CODE
        , UNIT_PRICE
        , WFAPPROVAL_STATUS
        , USSGL_TRANSACTION_CODE
        , DISCARDED_FLAG
        , ORIGINAL_AMOUNT
        , ORIGINAL_BASE_AMOUNT
        , ORIGINAL_ROUNDING_AMT
        , CANCELLED_FLAG
        , INCOME_TAX_REGION
        , TYPE_1099
        , STAT_AMOUNT
        , PREPAY_INVOICE_ID
        , PREPAY_LINE_NUMBER
        , INVOICE_INCLUDES_PREPAY_FLAG
        , CORRECTED_INV_ID
        , CORRECTED_LINE_NUMBER
        , PO_HEADER_ID
        , PO_LINE_ID
        , PO_RELEASE_ID
        , PO_LINE_LOCATION_ID
        , PO_DISTRIBUTION_ID
        , RCV_TRANSACTION_ID
        , FINAL_MATCH_FLAG
        , ASSETS_TRACKING_FLAG
        , ASSET_BOOK_TYPE_CODE
        , ASSET_CATEGORY_ID
        , PROJECT_ID
        , TASK_ID
        , EXPENDITURE_TYPE
        , EXPENDITURE_ITEM_DATE
        , EXPENDITURE_ORGANIZATION_ID
        , PA_QUANTITY
        , PA_CC_AR_INVOICE_ID
        , PA_CC_AR_INVOICE_LINE_NUM
        , PA_CC_PROCESSED_CODE
        , AWARD_ID
        , AWT_GROUP_ID
        , REFERENCE_1
        , REFERENCE_2
        , RECEIPT_VERIFIED_FLAG
        , RECEIPT_REQUIRED_FLAG
        , RECEIPT_MISSING_FLAG
        , JUSTIFICATION
        , EXPENSE_GROUP
        , START_EXPENSE_DATE
        , END_EXPENSE_DATE
        , RECEIPT_CURRENCY_CODE
        , RECEIPT_CONVERSION_RATE
        , RECEIPT_CURRENCY_AMOUNT
        , DAILY_AMOUNT
        , WEB_PARAMETER_ID
        , ADJUSTMENT_REASON
        , MERCHANT_DOCUMENT_NUMBER
        , MERCHANT_REFERENCE
        , MERCHANT_TAX_REG_NUMBER
        , MERCHANT_TAXPAYER_ID
        , COUNTRY_OF_SUPPLY
        , CREDIT_CARD_TRX_ID
        , COMPANY_PREPAID_INVOICE_ID
        , CC_REVERSAL_FLAG
        , CREATION_DATE
        , CREATED_BY
        , LAST_UPDATED_BY
        , LAST_UPDATE_DATE
        , LAST_UPDATE_LOGIN
        , PROGRAM_APPLICATION_ID
        , PROGRAM_ID
        , PROGRAM_UPDATE_DATE
        , REQUEST_ID
        , ATTRIBUTE_CATEGORY
        , ATTRIBUTE1
        , ATTRIBUTE2
        , ATTRIBUTE3
        , ATTRIBUTE4
        , ATTRIBUTE5
        , ATTRIBUTE6
        , ATTRIBUTE7
        , ATTRIBUTE8
        , ATTRIBUTE9
        , ATTRIBUTE10
        , ATTRIBUTE11
        , ATTRIBUTE12
        , ATTRIBUTE13
        , ATTRIBUTE14
        , ATTRIBUTE15
        , GLOBAL_ATTRIBUTE_CATEGORY
        , GLOBAL_ATTRIBUTE1
        , GLOBAL_ATTRIBUTE2
        , GLOBAL_ATTRIBUTE3
        , GLOBAL_ATTRIBUTE4
        , GLOBAL_ATTRIBUTE5
        , GLOBAL_ATTRIBUTE6
        , GLOBAL_ATTRIBUTE7
        , GLOBAL_ATTRIBUTE8
        , GLOBAL_ATTRIBUTE9
        , GLOBAL_ATTRIBUTE10
        , GLOBAL_ATTRIBUTE11
        , GLOBAL_ATTRIBUTE12
        , GLOBAL_ATTRIBUTE13
        , GLOBAL_ATTRIBUTE14
        , GLOBAL_ATTRIBUTE15
        , GLOBAL_ATTRIBUTE16
        , GLOBAL_ATTRIBUTE17
        , GLOBAL_ATTRIBUTE18
        , GLOBAL_ATTRIBUTE19
        , GLOBAL_ATTRIBUTE20
        , LINE_SELECTED_FOR_APPL_FLAG
        , PREPAY_APPL_REQUEST_ID
        , APPLICATION_ID
        , PRODUCT_TABLE
        , REFERENCE_KEY1
        , REFERENCE_KEY2
        , REFERENCE_KEY3
        , REFERENCE_KEY4
        , REFERENCE_KEY5
        , PURCHASING_CATEGORY_ID
        , COST_FACTOR_ID
        , CONTROL_AMOUNT
        , ASSESSABLE_VALUE
        , TOTAL_REC_TAX_AMOUNT
        , TOTAL_NREC_TAX_AMOUNT
        , TOTAL_REC_TAX_AMT_FUNCL_CURR
        , TOTAL_NREC_TAX_AMT_FUNCL_CURR
        , INCLUDED_TAX_AMOUNT
        , PRIMARY_INTENDED_USE
        , TAX_ALREADY_CALCULATED_FLAG
        , SHIP_TO_LOCATION_ID
        , PRODUCT_TYPE
        , PRODUCT_CATEGORY
        , PRODUCT_FISC_CLASSIFICATION
        , USER_DEFINED_FISC_CLASS
        , TRX_BUSINESS_CATEGORY
        , SUMMARY_TAX_LINE_ID
        , TAX_REGIME_CODE
        , TAX
        , TAX_JURISDICTION_CODE
        , TAX_STATUS_CODE
        , TAX_RATE_ID
        , TAX_RATE_CODE
        , TAX_RATE
        , TAX_CODE_ID
        , HISTORICAL_FLAG
        , TAX_CLASSIFICATION_CODE
        , SOURCE_APPLICATION_ID
        , SOURCE_EVENT_CLASS_CODE
        , SOURCE_ENTITY_CODE
        , SOURCE_TRX_ID
        , SOURCE_LINE_ID
        , SOURCE_TRX_LEVEL_TYPE
        , RETAINED_AMOUNT
        , RETAINED_AMOUNT_REMAINING
        , RETAINED_INVOICE_ID
        , RETAINED_LINE_NUMBER
        , LINE_SELECTED_FOR_RELEASE_FLAG
        , LINE_OWNER_ROLE
        , DISPUTABLE_FLAG
        , RCV_SHIPMENT_LINE_ID
        , AIL_INVOICE_ID
        , AIL_DISTRIBUTION_LINE_NUMBER
        , AIL_INVOICE_ID2
        , AIL_DISTRIBUTION_LINE_NUMBER2
        , AIL_INVOICE_ID3
        , AIL_DISTRIBUTION_LINE_NUMBER3
        , AIL_INVOICE_ID4
        , PAY_AWT_GROUP_ID
        , MERCHANT_NAME_1
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
              IFNULL(TRIM(LINE_TYPE_LOOKUP_CODE::text), '^^') 
            , '||', IFNULL(TRIM(REQUESTER_ID::text), '^^') 
            , '||', IFNULL(TRIM(DESCRIPTION::text), '^^') 
            , '||', IFNULL(TRIM(LINE_SOURCE::text), '^^') 
            , '||', IFNULL(TRIM(ORG_ID::text), '^^') 
            , '||', IFNULL(TRIM(LINE_GROUP_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(INVENTORY_ITEM_ID::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_DESCRIPTION::text), '^^') 
            , '||', IFNULL(TRIM(SERIAL_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(MANUFACTURER::text), '^^') 
            , '||', IFNULL(TRIM(MODEL_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(WARRANTY_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(GENERATE_DISTS::text), '^^') 
            , '||', IFNULL(TRIM(MATCH_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(DISTRIBUTION_SET_ID::text), '^^') 
            , '||', IFNULL(TRIM(ACCOUNT_SEGMENT::text), '^^') 
            , '||', IFNULL(TRIM(BALANCING_SEGMENT::text), '^^') 
            , '||', IFNULL(TRIM(COST_CENTER_SEGMENT::text), '^^') 
            , '||', IFNULL(TRIM(OVERLAY_DIST_CODE_CONCAT::text), '^^') 
            , '||', IFNULL(TRIM(DEFAULT_DIST_CCID::text), '^^') 
            , '||', IFNULL(TRIM(PRORATE_ACROSS_ALL_ITEMS::text), '^^') 
            , '||', IFNULL(TRIM(ACCOUNTING_DATE::text), '^^') 
            , '||', IFNULL(TRIM(PERIOD_NAME::text), '^^') 
            , '||', IFNULL(TRIM(DEFERRED_ACCTG_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(DEF_ACCTG_START_DATE::text), '^^') 
            , '||', IFNULL(TRIM(DEF_ACCTG_END_DATE::text), '^^') 
            , '||', IFNULL(TRIM(DEF_ACCTG_NUMBER_OF_PERIODS::text), '^^') 
            , '||', IFNULL(TRIM(DEF_ACCTG_PERIOD_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(SET_OF_BOOKS_ID::text), '^^') 
            , '||', IFNULL(TRIM(AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(BASE_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(ROUNDING_AMT::text), '^^') 
            , '||', IFNULL(TRIM(QUANTITY_INVOICED::text), '^^') 
            , '||', IFNULL(TRIM(UNIT_MEAS_LOOKUP_CODE::text), '^^') 
            , '||', IFNULL(TRIM(UNIT_PRICE::text), '^^') 
            , '||', IFNULL(TRIM(WFAPPROVAL_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(USSGL_TRANSACTION_CODE::text), '^^') 
            , '||', IFNULL(TRIM(DISCARDED_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(ORIGINAL_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(ORIGINAL_BASE_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(ORIGINAL_ROUNDING_AMT::text), '^^') 
            , '||', IFNULL(TRIM(CANCELLED_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(INCOME_TAX_REGION::text), '^^') 
            , '||', IFNULL(TRIM(TYPE_1099::text), '^^') 
            , '||', IFNULL(TRIM(STAT_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(PREPAY_INVOICE_ID::text), '^^') 
            , '||', IFNULL(TRIM(PREPAY_LINE_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(INVOICE_INCLUDES_PREPAY_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(CORRECTED_INV_ID::text), '^^') 
            , '||', IFNULL(TRIM(CORRECTED_LINE_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(PO_HEADER_ID::text), '^^') 
            , '||', IFNULL(TRIM(PO_LINE_ID::text), '^^') 
            , '||', IFNULL(TRIM(PO_RELEASE_ID::text), '^^') 
            , '||', IFNULL(TRIM(PO_LINE_LOCATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(PO_DISTRIBUTION_ID::text), '^^') 
            , '||', IFNULL(TRIM(RCV_TRANSACTION_ID::text), '^^') 
            , '||', IFNULL(TRIM(FINAL_MATCH_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(ASSETS_TRACKING_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(ASSET_BOOK_TYPE_CODE::text), '^^') 
            , '||', IFNULL(TRIM(ASSET_CATEGORY_ID::text), '^^') 
            , '||', IFNULL(TRIM(PROJECT_ID::text), '^^') 
            , '||', IFNULL(TRIM(TASK_ID::text), '^^') 
            , '||', IFNULL(TRIM(EXPENDITURE_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(EXPENDITURE_ITEM_DATE::text), '^^') 
            , '||', IFNULL(TRIM(EXPENDITURE_ORGANIZATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(PA_QUANTITY::text), '^^') 
            , '||', IFNULL(TRIM(PA_CC_AR_INVOICE_ID::text), '^^') 
            , '||', IFNULL(TRIM(PA_CC_AR_INVOICE_LINE_NUM::text), '^^') 
            , '||', IFNULL(TRIM(PA_CC_PROCESSED_CODE::text), '^^') 
            , '||', IFNULL(TRIM(AWARD_ID::text), '^^') 
            , '||', IFNULL(TRIM(AWT_GROUP_ID::text), '^^') 
            , '||', IFNULL(TRIM(REFERENCE_1::text), '^^') 
            , '||', IFNULL(TRIM(REFERENCE_2::text), '^^') 
            , '||', IFNULL(TRIM(RECEIPT_VERIFIED_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(RECEIPT_REQUIRED_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(RECEIPT_MISSING_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(JUSTIFICATION::text), '^^') 
            , '||', IFNULL(TRIM(EXPENSE_GROUP::text), '^^') 
            , '||', IFNULL(TRIM(START_EXPENSE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(END_EXPENSE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(RECEIPT_CURRENCY_CODE::text), '^^') 
            , '||', IFNULL(TRIM(RECEIPT_CONVERSION_RATE::text), '^^') 
            , '||', IFNULL(TRIM(RECEIPT_CURRENCY_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(DAILY_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(WEB_PARAMETER_ID::text), '^^') 
            , '||', IFNULL(TRIM(ADJUSTMENT_REASON::text), '^^') 
            , '||', IFNULL(TRIM(MERCHANT_DOCUMENT_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(MERCHANT_REFERENCE::text), '^^') 
            , '||', IFNULL(TRIM(MERCHANT_TAX_REG_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(MERCHANT_TAXPAYER_ID::text), '^^') 
            , '||', IFNULL(TRIM(COUNTRY_OF_SUPPLY::text), '^^') 
            , '||', IFNULL(TRIM(CREDIT_CARD_TRX_ID::text), '^^') 
            , '||', IFNULL(TRIM(COMPANY_PREPAID_INVOICE_ID::text), '^^') 
            , '||', IFNULL(TRIM(CC_REVERSAL_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(CREATION_DATE::text), '^^') 
            , '||', IFNULL(TRIM(CREATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_LOGIN::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_APPLICATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_ID::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_UPDATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(REQUEST_ID::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE1::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE2::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE3::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE4::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE5::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE6::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE7::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE8::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE9::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE10::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE11::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE12::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE13::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE14::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE15::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE1::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE2::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE3::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE4::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE5::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE6::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE7::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE8::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE9::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE10::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE11::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE12::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE13::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE14::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE15::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE16::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE17::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE18::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE19::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE20::text), '^^') 
            , '||', IFNULL(TRIM(LINE_SELECTED_FOR_APPL_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(PREPAY_APPL_REQUEST_ID::text), '^^') 
            , '||', IFNULL(TRIM(APPLICATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(PRODUCT_TABLE::text), '^^') 
            , '||', IFNULL(TRIM(REFERENCE_KEY1::text), '^^') 
            , '||', IFNULL(TRIM(REFERENCE_KEY2::text), '^^') 
            , '||', IFNULL(TRIM(REFERENCE_KEY3::text), '^^') 
            , '||', IFNULL(TRIM(REFERENCE_KEY4::text), '^^') 
            , '||', IFNULL(TRIM(REFERENCE_KEY5::text), '^^') 
            , '||', IFNULL(TRIM(PURCHASING_CATEGORY_ID::text), '^^') 
            , '||', IFNULL(TRIM(COST_FACTOR_ID::text), '^^') 
            , '||', IFNULL(TRIM(CONTROL_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(ASSESSABLE_VALUE::text), '^^') 
            , '||', IFNULL(TRIM(TOTAL_REC_TAX_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(TOTAL_NREC_TAX_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(TOTAL_REC_TAX_AMT_FUNCL_CURR::text), '^^') 
            , '||', IFNULL(TRIM(TOTAL_NREC_TAX_AMT_FUNCL_CURR::text), '^^') 
            , '||', IFNULL(TRIM(INCLUDED_TAX_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(PRIMARY_INTENDED_USE::text), '^^') 
            , '||', IFNULL(TRIM(TAX_ALREADY_CALCULATED_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_TO_LOCATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(PRODUCT_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(PRODUCT_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(PRODUCT_FISC_CLASSIFICATION::text), '^^') 
            , '||', IFNULL(TRIM(USER_DEFINED_FISC_CLASS::text), '^^') 
            , '||', IFNULL(TRIM(TRX_BUSINESS_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(SUMMARY_TAX_LINE_ID::text), '^^') 
            , '||', IFNULL(TRIM(TAX_REGIME_CODE::text), '^^') 
            , '||', IFNULL(TRIM(TAX::text), '^^') 
            , '||', IFNULL(TRIM(TAX_JURISDICTION_CODE::text), '^^') 
            , '||', IFNULL(TRIM(TAX_STATUS_CODE::text), '^^') 
            , '||', IFNULL(TRIM(TAX_RATE_ID::text), '^^') 
            , '||', IFNULL(TRIM(TAX_RATE_CODE::text), '^^') 
            , '||', IFNULL(TRIM(TAX_RATE::text), '^^') 
            , '||', IFNULL(TRIM(TAX_CODE_ID::text), '^^') 
            , '||', IFNULL(TRIM(HISTORICAL_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(TAX_CLASSIFICATION_CODE::text), '^^') 
            , '||', IFNULL(TRIM(SOURCE_APPLICATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(SOURCE_EVENT_CLASS_CODE::text), '^^') 
            , '||', IFNULL(TRIM(SOURCE_ENTITY_CODE::text), '^^') 
            , '||', IFNULL(TRIM(SOURCE_TRX_ID::text), '^^') 
            , '||', IFNULL(TRIM(SOURCE_LINE_ID::text), '^^') 
            , '||', IFNULL(TRIM(SOURCE_TRX_LEVEL_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(RETAINED_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(RETAINED_AMOUNT_REMAINING::text), '^^') 
            , '||', IFNULL(TRIM(RETAINED_INVOICE_ID::text), '^^') 
            , '||', IFNULL(TRIM(RETAINED_LINE_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(LINE_SELECTED_FOR_RELEASE_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(LINE_OWNER_ROLE::text), '^^') 
            , '||', IFNULL(TRIM(DISPUTABLE_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(RCV_SHIPMENT_LINE_ID::text), '^^') 
            , '||', IFNULL(TRIM(AIL_INVOICE_ID::text), '^^') 
            , '||', IFNULL(TRIM(AIL_DISTRIBUTION_LINE_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(AIL_INVOICE_ID2::text), '^^') 
            , '||', IFNULL(TRIM(AIL_DISTRIBUTION_LINE_NUMBER2::text), '^^') 
            , '||', IFNULL(TRIM(AIL_INVOICE_ID3::text), '^^') 
            , '||', IFNULL(TRIM(AIL_DISTRIBUTION_LINE_NUMBER3::text), '^^') 
            , '||', IFNULL(TRIM(AIL_INVOICE_ID4::text), '^^') 
            , '||', IFNULL(TRIM(PAY_AWT_GROUP_ID::text), '^^') 
            , '||', IFNULL(TRIM(MERCHANT_NAME_1::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
