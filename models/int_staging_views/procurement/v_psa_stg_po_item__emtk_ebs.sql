---- SRC LAYER ----
WITH
SRC_polemtk        as ( SELECT ALLOW_PRICE_OVERRIDE_FLAG, AMOUNT, ATTRIBUTE1, ATTRIBUTE10, ATTRIBUTE11, ATTRIBUTE12, ATTRIBUTE13, ATTRIBUTE14, ATTRIBUTE15, ATTRIBUTE2, ATTRIBUTE3, ATTRIBUTE4, ATTRIBUTE5, ATTRIBUTE6, ATTRIBUTE7, ATTRIBUTE8, ATTRIBUTE9, ATTRIBUTE_CATEGORY, AUCTION_DISPLAY_NUMBER, AUCTION_HEADER_ID, AUCTION_LINE_NUMBER, BASE_QTY, BASE_UNIT_PRICE, BASE_UOM, BID_LINE_NUMBER, BID_NUMBER, CANCELLED_BY, CANCEL_DATE, CANCEL_FLAG, CANCEL_REASON_1, CAPITAL_EXPENSE_FLAG, CATALOG_NAME, CATEGORY_ID, CLM_APPROVED_UNDEF_AMOUNT, CLM_BASE_LINE_NUM, CLM_DELIVERY_EVENT_CODE, CLM_EXERCISED_DATE, CLM_EXERCISED_FLAG, CLM_EXHIBIT_NAME, CLM_FSC_PSC, CLM_FUNDED_FLAG, CLM_IDC_TYPE, CLM_INFO_FLAG, CLM_MAX_ORDER_AMOUNT, CLM_MAX_ORDER_QUANTITY, CLM_MAX_TOTAL_AMOUNT, CLM_MAX_TOTAL_QUANTITY, CLM_MDAPS_MAIS, CLM_MIN_ORDER_AMOUNT, CLM_MIN_ORDER_QUANTITY, CLM_MIN_TOTAL_AMOUNT, CLM_MIN_TOTAL_QUANTITY, CLM_NAICS, CLM_OPTION_FROM_DATE, CLM_OPTION_INDICATOR, CLM_OPTION_NUM, CLM_OPTION_TO_DATE, CLM_ORDER_END_DATE, CLM_ORDER_START_DATE, CLM_PAYMENT_INSTR_CODE, CLM_POP_EXCEPTION_REASON, CLM_TOTAL_AMOUNT_ORDERED, CLM_TOTAL_QUANTITY_ORDERED, CLM_UDA_PRICING_TOTAL, CLM_UNDEF_ACTION_CODE, CLM_UNDEF_FLAG, CLOSED_BY, CLOSED_CODE, CLOSED_DATE, CLOSED_FLAG, CLOSED_REASON_1, COMMITTED_AMOUNT, CONTRACTOR_FIRST_NAME, CONTRACTOR_LAST_NAME, CONTRACT_ID, CONTRACT_NUM, CONTRACT_TYPE, COST_CONSTRAINT, CREATED_BY, CREATION_DATE, DRAFT_ID, EXPIRATION_DATE, FIRM_DATE, FIRM_STATUS_LOOKUP_CODE, FROM_HEADER_ID, FROM_LINE_ID, FROM_LINE_LOCATION_ID, GLOBAL_ATTRIBUTE1, GLOBAL_ATTRIBUTE10, GLOBAL_ATTRIBUTE11, GLOBAL_ATTRIBUTE12, GLOBAL_ATTRIBUTE13, GLOBAL_ATTRIBUTE14, GLOBAL_ATTRIBUTE15, GLOBAL_ATTRIBUTE16, GLOBAL_ATTRIBUTE17, GLOBAL_ATTRIBUTE18, GLOBAL_ATTRIBUTE19, GLOBAL_ATTRIBUTE2, GLOBAL_ATTRIBUTE20, GLOBAL_ATTRIBUTE3, GLOBAL_ATTRIBUTE4, GLOBAL_ATTRIBUTE5, GLOBAL_ATTRIBUTE6, GLOBAL_ATTRIBUTE7, GLOBAL_ATTRIBUTE8, GLOBAL_ATTRIBUTE9, GLOBAL_ATTRIBUTE_CATEGORY, GOVERNMENT_CONTEXT, GROUP_LINE_ID, HAZARD_CLASS_ID, IGT_LINE_STATUS, IP_CATEGORY_ID, ITEM_DESCRIPTION, ITEM_ID, ITEM_REVISION, JOB_ID, LAST_UPDATED_BY, LAST_UPDATED_PROGRAM, LAST_UPDATE_DATE, LAST_UPDATE_LOGIN, LINE_NUM, LINE_NUM_DISPLAY, LINE_REFERENCE_NUM, LINE_TYPE_ID, LIST_PRICE_PER_UNIT, MANUAL_PRICE_CHANGE_FLAG, MARKET_PRICE, MATCHING_BASIS, MAX_ORDER_QUANTITY, MAX_RETAINAGE_AMOUNT, MIN_ORDER_QUANTITY, MIN_RELEASE_AMOUNT, NEGOTIATED_BY_PREPARER_FLAG, NOTE_TO_VENDOR, NOT_TO_EXCEED_PRICE, OKE_CONTRACT_HEADER_ID, OKE_CONTRACT_VERSION_ID, ORDER_TYPE_LOOKUP_CODE, ORG_ID, OVER_TOLERANCE_ERROR_FLAG, PO_HEADER_ID, PO_LINE_ID, PREFERRED_GRADE, PRICE_BREAK_LOOKUP_CODE, PRICE_TYPE_LOOKUP_CODE, PROGRAM_APPLICATION_ID, PROGRAM_ID, PROGRAM_UPDATE_DATE, PROGRESS_PAYMENT_RATE, PROJECT_ID, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, PURCHASE_BASIS, QC_GRADE, QTY_RCV_TOLERANCE, QUANTITY, QUANTITY_COMMITTED, RECOUPMENT_RATE, REFERENCE_NUM, REQUEST_ID, RETAINAGE_RATE, RETROACTIVE_DATE, REVISION_NUM, SCHEDULES_REQUIRED_FLAG, SECONDARY_QTY, SECONDARY_QUANTITY, SECONDARY_UNIT_OF_MEASURE, SECONDARY_UOM, START_DATE, SUPPLIER_PART_AUXID, SUPPLIER_REF_NUMBER, SVC_AMOUNT_NOTIF_SENT, SVC_COMPLETION_NOTIF_SENT, TASK_ID, TAXABLE_FLAG, TAX_ATTRIBUTE_UPDATE_CODE, TAX_CODE_ID, TAX_NAME, TRANSACTION_REASON_CODE, TYPE_1099, UDA_TEMPLATE_ID, UNIT_MEAS_LOOKUP_CODE, UNIT_PRICE, UNORDERED_FLAG, UN_NUMBER_ID, USER_DOCUMENT_STATUS, USER_HOLD_FLAG, USSGL_TRANSACTION_CODE, VENDOR_PRODUCT_NUM, _FIVETRAN_DELETED, _FIVETRAN_ID, _FIVETRAN_SYNCED FROM {{ source('emtk_ebs_po', 'po_lines_all') }} as SRC  ),
SRC_poemtk         as ( SELECT PO_HEADER_ID, VENDOR_ID FROM {{ source('emtk_ebs_po', 'po_headers_all') }} as SRC 
                        qualify 1= row_number()over(partition by po_header_id order by _fivetran_synced desc, psa_load_dts desc) ),
SRC_a              as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  ),
SRC_sup            as ( SELECT SEGMENT1, VENDOR_ID FROM {{ source('emtk_ebs_ap', 'ap_suppliers') }} as SRC 
                        qualify 1= row_number()over(partition by vendor_id order by _fivetran_synced desc, psa_load_dts desc) ),
SRC_itm            as ( SELECT INVENTORY_ITEM_ID, SEGMENT1 FROM {{ source('emtk_ebs_inv', 'mtl_system_items_b') }} as SRC 
                        WHERE  organization_id = 101 -- master organization 
                        qualify 1= row_number()over(partition by inventory_item_id order by _fivetran_synced desc, psa_load_dts desc) ),
SRC_org            as ( SELECT NAME, ORGANIZATION_ID FROM {{ source('emtk_ebs_hr', 'hr_all_organization_units') }} as SRC 
                        qualify 1= row_number()over(partition by organization_id order by _fivetran_synced desc, psa_load_dts desc) )

/*
SRC_polemtk        as ( SELECT * FROM emtk_ebs_po.po_lines_all )
SRC_poemtk         as ( SELECT * FROM emtk_ebs_po.po_headers_all )
SRC_a              as ( SELECT * FROM raw_vault.ref_business_key_collision )
SRC_sup            as ( SELECT * FROM emtk_ebs_ap.ap_suppliers )
SRC_itm            as ( SELECT * FROM emtk_ebs_inv.mtl_system_items_b )
SRC_org            as ( SELECT * FROM emtk_ebs_hr.hr_all_organization_units )
*/
---- LOGIC LAYER ----

, LOGIC_polemtk as (
    SELECT
        CONCAT_WS('||', COALESCE(PO_HEADER_ID, ''), COALESCE(LINE_NUM::TEXT, '')) as                                         PO_ITEM_BK
      , COALESCE(PO_HEADER_ID::TEXT, '')                             as                                       PO_HEADER_BK
      , PO_HEADER_ID
      , LINE_NUM
      , PO_LINE_ID
      , ITEM_ID
      , ORG_ID
      , LAST_UPDATE_DATE
      , LAST_UPDATED_BY
      , LINE_TYPE_ID
      , LAST_UPDATE_LOGIN
      , CREATION_DATE
      , CREATED_BY
      , ITEM_REVISION
      , CATEGORY_ID
      , ITEM_DESCRIPTION
      , UNIT_MEAS_LOOKUP_CODE
      , QUANTITY_COMMITTED
      , COMMITTED_AMOUNT
      , ALLOW_PRICE_OVERRIDE_FLAG
      , NOT_TO_EXCEED_PRICE
      , LIST_PRICE_PER_UNIT
      , UNIT_PRICE
      , QUANTITY
      , UN_NUMBER_ID
      , HAZARD_CLASS_ID
      , NOTE_TO_VENDOR
      , FROM_HEADER_ID
      , FROM_LINE_ID
      , MIN_ORDER_QUANTITY
      , MAX_ORDER_QUANTITY
      , QTY_RCV_TOLERANCE
      , OVER_TOLERANCE_ERROR_FLAG
      , MARKET_PRICE
      , UNORDERED_FLAG
      , CLOSED_FLAG
      , USER_HOLD_FLAG
      , CANCEL_FLAG
      , CANCELLED_BY
      , CANCEL_DATE
      , FIRM_STATUS_LOOKUP_CODE
      , FIRM_DATE
      , VENDOR_PRODUCT_NUM
      , CONTRACT_NUM
      , TAXABLE_FLAG
      , TAX_NAME
      , TYPE_1099
      , CAPITAL_EXPENSE_FLAG
      , NEGOTIATED_BY_PREPARER_FLAG
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
      , REFERENCE_NUM
      , ATTRIBUTE11
      , ATTRIBUTE12
      , ATTRIBUTE13
      , ATTRIBUTE14
      , ATTRIBUTE15
      , MIN_RELEASE_AMOUNT
      , PRICE_TYPE_LOOKUP_CODE
      , CLOSED_CODE
      , PRICE_BREAK_LOOKUP_CODE
      , USSGL_TRANSACTION_CODE
      , GOVERNMENT_CONTEXT
      , REQUEST_ID
      , PROGRAM_APPLICATION_ID
      , PROGRAM_ID
      , PROGRAM_UPDATE_DATE
      , CLOSED_DATE
      , CLOSED_BY
      , TRANSACTION_REASON_CODE
      , QC_GRADE
      , BASE_UOM
      , BASE_QTY
      , SECONDARY_UOM
      , SECONDARY_QTY
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
      , LINE_REFERENCE_NUM
      , PROJECT_ID
      , TASK_ID
      , EXPIRATION_DATE
      , TAX_CODE_ID
      , OKE_CONTRACT_HEADER_ID
      , OKE_CONTRACT_VERSION_ID
      , SECONDARY_QUANTITY
      , SECONDARY_UNIT_OF_MEASURE
      , PREFERRED_GRADE
      , AUCTION_HEADER_ID
      , AUCTION_DISPLAY_NUMBER
      , AUCTION_LINE_NUMBER
      , BID_NUMBER
      , BID_LINE_NUMBER
      , RETROACTIVE_DATE
      , FROM_LINE_LOCATION_ID
      , SUPPLIER_REF_NUMBER
      , CONTRACT_ID
      , START_DATE
      , AMOUNT
      , JOB_ID
      , CONTRACTOR_FIRST_NAME
      , CONTRACTOR_LAST_NAME
      , ORDER_TYPE_LOOKUP_CODE
      , PURCHASE_BASIS
      , MATCHING_BASIS
      , SVC_AMOUNT_NOTIF_SENT
      , SVC_COMPLETION_NOTIF_SENT
      , BASE_UNIT_PRICE
      , MANUAL_PRICE_CHANGE_FLAG
      , CATALOG_NAME
      , SUPPLIER_PART_AUXID
      , IP_CATEGORY_ID
      , LAST_UPDATED_PROGRAM
      , RETAINAGE_RATE
      , MAX_RETAINAGE_AMOUNT
      , PROGRESS_PAYMENT_RATE
      , RECOUPMENT_RATE
      , TAX_ATTRIBUTE_UPDATE_CODE
      , GROUP_LINE_ID
      , LINE_NUM_DISPLAY
      , CLM_INFO_FLAG
      , CLM_OPTION_INDICATOR
      , CLM_BASE_LINE_NUM
      , CLM_OPTION_NUM
      , CLM_OPTION_FROM_DATE
      , CLM_OPTION_TO_DATE
      , CLM_FUNDED_FLAG
      , CONTRACT_TYPE
      , COST_CONSTRAINT
      , CLM_IDC_TYPE
      , UDA_TEMPLATE_ID
      , USER_DOCUMENT_STATUS
      , DRAFT_ID
      , CLM_MIN_TOTAL_AMOUNT
      , CLM_MAX_TOTAL_AMOUNT
      , CLM_MIN_TOTAL_QUANTITY
      , CLM_MAX_TOTAL_QUANTITY
      , CLM_MIN_ORDER_AMOUNT
      , CLM_MAX_ORDER_AMOUNT
      , CLM_MIN_ORDER_QUANTITY
      , CLM_MAX_ORDER_QUANTITY
      , CLM_TOTAL_AMOUNT_ORDERED
      , CLM_TOTAL_QUANTITY_ORDERED
      , CLM_FSC_PSC
      , CLM_MDAPS_MAIS
      , CLM_NAICS
      , CLM_ORDER_START_DATE
      , CLM_ORDER_END_DATE
      , CLM_EXERCISED_FLAG
      , CLM_EXERCISED_DATE
      , REVISION_NUM
      , CLM_APPROVED_UNDEF_AMOUNT
      , CLM_DELIVERY_EVENT_CODE
      , CLM_EXHIBIT_NAME
      , CLM_PAYMENT_INSTR_CODE
      , CLM_POP_EXCEPTION_REASON
      , CLM_UDA_PRICING_TOTAL
      , CLM_UNDEF_ACTION_CODE
      , CLM_UNDEF_FLAG
      , SCHEDULES_REQUIRED_FLAG
      , CANCEL_REASON_1
      , CLOSED_REASON_1
      , IGT_LINE_STATUS
      , _FIVETRAN_ID
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED)                    as                                           LOAD_DTS
    FROM SRC_polemtk
)

, LOGIC_poemtk as (
    SELECT
        VENDOR_ID
      , PO_HEADER_ID                                                 as                                POEMTK_PO_HEADER_ID
    FROM SRC_poemtk
)

, LOGIC_a as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_a
)

, LOGIC_sup as (
    SELECT
        SEGMENT1                                                     as                                       SUP_SEGMENT1
      , VENDOR_ID                                                    as                                      SUP_VENDOR_ID
    FROM SRC_sup
)

, LOGIC_itm as (
    SELECT
        SEGMENT1                                                     as                                       ITM_SEGMENT1
      , INVENTORY_ITEM_ID
    FROM SRC_itm
)

, LOGIC_org as (
    SELECT
        NAME                                                         as                                  ORGANIZATION_NAME
      , ORGANIZATION_ID
    FROM SRC_org
)
---- RENAME LAYER ----

, RENAME_polemtk as (
    SELECT
        PO_ITEM_BK
      , PO_HEADER_BK
      , PO_HEADER_ID
      , LINE_NUM
      , PO_LINE_ID
      , ITEM_ID
      , ORG_ID
      , LAST_UPDATE_DATE
      , LAST_UPDATED_BY
      , LINE_TYPE_ID
      , LAST_UPDATE_LOGIN
      , CREATION_DATE
      , CREATED_BY
      , ITEM_REVISION
      , CATEGORY_ID
      , ITEM_DESCRIPTION
      , UNIT_MEAS_LOOKUP_CODE
      , QUANTITY_COMMITTED
      , COMMITTED_AMOUNT
      , ALLOW_PRICE_OVERRIDE_FLAG
      , NOT_TO_EXCEED_PRICE
      , LIST_PRICE_PER_UNIT
      , UNIT_PRICE
      , QUANTITY
      , UN_NUMBER_ID
      , HAZARD_CLASS_ID
      , NOTE_TO_VENDOR
      , FROM_HEADER_ID
      , FROM_LINE_ID
      , MIN_ORDER_QUANTITY
      , MAX_ORDER_QUANTITY
      , QTY_RCV_TOLERANCE
      , OVER_TOLERANCE_ERROR_FLAG
      , MARKET_PRICE
      , UNORDERED_FLAG
      , CLOSED_FLAG
      , USER_HOLD_FLAG
      , CANCEL_FLAG
      , CANCELLED_BY
      , CANCEL_DATE
      , FIRM_STATUS_LOOKUP_CODE
      , FIRM_DATE
      , VENDOR_PRODUCT_NUM
      , CONTRACT_NUM
      , TAXABLE_FLAG
      , TAX_NAME
      , TYPE_1099
      , CAPITAL_EXPENSE_FLAG
      , NEGOTIATED_BY_PREPARER_FLAG
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
      , REFERENCE_NUM
      , ATTRIBUTE11
      , ATTRIBUTE12
      , ATTRIBUTE13
      , ATTRIBUTE14
      , ATTRIBUTE15
      , MIN_RELEASE_AMOUNT
      , PRICE_TYPE_LOOKUP_CODE
      , CLOSED_CODE
      , PRICE_BREAK_LOOKUP_CODE
      , USSGL_TRANSACTION_CODE
      , GOVERNMENT_CONTEXT
      , REQUEST_ID
      , PROGRAM_APPLICATION_ID
      , PROGRAM_ID
      , PROGRAM_UPDATE_DATE
      , CLOSED_DATE
      , CLOSED_BY
      , TRANSACTION_REASON_CODE
      , QC_GRADE
      , BASE_UOM
      , BASE_QTY
      , SECONDARY_UOM
      , SECONDARY_QTY
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
      , LINE_REFERENCE_NUM
      , PROJECT_ID
      , TASK_ID
      , EXPIRATION_DATE
      , TAX_CODE_ID
      , OKE_CONTRACT_HEADER_ID
      , OKE_CONTRACT_VERSION_ID
      , SECONDARY_QUANTITY
      , SECONDARY_UNIT_OF_MEASURE
      , PREFERRED_GRADE
      , AUCTION_HEADER_ID
      , AUCTION_DISPLAY_NUMBER
      , AUCTION_LINE_NUMBER
      , BID_NUMBER
      , BID_LINE_NUMBER
      , RETROACTIVE_DATE
      , FROM_LINE_LOCATION_ID
      , SUPPLIER_REF_NUMBER
      , CONTRACT_ID
      , START_DATE
      , AMOUNT
      , JOB_ID
      , CONTRACTOR_FIRST_NAME
      , CONTRACTOR_LAST_NAME
      , ORDER_TYPE_LOOKUP_CODE
      , PURCHASE_BASIS
      , MATCHING_BASIS
      , SVC_AMOUNT_NOTIF_SENT
      , SVC_COMPLETION_NOTIF_SENT
      , BASE_UNIT_PRICE
      , MANUAL_PRICE_CHANGE_FLAG
      , CATALOG_NAME
      , SUPPLIER_PART_AUXID
      , IP_CATEGORY_ID
      , LAST_UPDATED_PROGRAM
      , RETAINAGE_RATE
      , MAX_RETAINAGE_AMOUNT
      , PROGRESS_PAYMENT_RATE
      , RECOUPMENT_RATE
      , TAX_ATTRIBUTE_UPDATE_CODE
      , GROUP_LINE_ID
      , LINE_NUM_DISPLAY
      , CLM_INFO_FLAG
      , CLM_OPTION_INDICATOR
      , CLM_BASE_LINE_NUM
      , CLM_OPTION_NUM
      , CLM_OPTION_FROM_DATE
      , CLM_OPTION_TO_DATE
      , CLM_FUNDED_FLAG
      , CONTRACT_TYPE
      , COST_CONSTRAINT
      , CLM_IDC_TYPE
      , UDA_TEMPLATE_ID
      , USER_DOCUMENT_STATUS
      , DRAFT_ID
      , CLM_MIN_TOTAL_AMOUNT
      , CLM_MAX_TOTAL_AMOUNT
      , CLM_MIN_TOTAL_QUANTITY
      , CLM_MAX_TOTAL_QUANTITY
      , CLM_MIN_ORDER_AMOUNT
      , CLM_MAX_ORDER_AMOUNT
      , CLM_MIN_ORDER_QUANTITY
      , CLM_MAX_ORDER_QUANTITY
      , CLM_TOTAL_AMOUNT_ORDERED
      , CLM_TOTAL_QUANTITY_ORDERED
      , CLM_FSC_PSC
      , CLM_MDAPS_MAIS
      , CLM_NAICS
      , CLM_ORDER_START_DATE
      , CLM_ORDER_END_DATE
      , CLM_EXERCISED_FLAG
      , CLM_EXERCISED_DATE
      , REVISION_NUM
      , CLM_APPROVED_UNDEF_AMOUNT
      , CLM_DELIVERY_EVENT_CODE
      , CLM_EXHIBIT_NAME
      , CLM_PAYMENT_INSTR_CODE
      , CLM_POP_EXCEPTION_REASON
      , CLM_UDA_PRICING_TOTAL
      , CLM_UNDEF_ACTION_CODE
      , CLM_UNDEF_FLAG
      , SCHEDULES_REQUIRED_FLAG
      , CANCEL_REASON_1
      , CLOSED_REASON_1
      , IGT_LINE_STATUS
      , _FIVETRAN_ID
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
    FROM LOGIC_polemtk
)

, RENAME_sup as (
    SELECT
        SUP_SEGMENT1
      , SUP_VENDOR_ID
    FROM LOGIC_sup
)

, RENAME_itm as (
    SELECT
        ITM_SEGMENT1
      , INVENTORY_ITEM_ID
    FROM LOGIC_itm
)

, RENAME_org as (
    SELECT
        ORGANIZATION_NAME
      , ORGANIZATION_ID
    FROM LOGIC_org
)

, RENAME_poemtk as (
    SELECT
        VENDOR_ID
      , POEMTK_PO_HEADER_ID
    FROM LOGIC_poemtk
)

, RENAME_a as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_a
)
---- FILTER LAYER ----

, FILTER_polemtk as (
    SELECT *
    FROM RENAME_polemtk
)

, FILTER_poemtk as (
    SELECT *
    FROM RENAME_poemtk
)

, FILTER_a as (
    SELECT *
    FROM RENAME_a
    WHERE rec_src = 'USWIOC.ORCL.EBSEMTK.PO_LINES_ALL'
)

, FILTER_sup as (
    SELECT *
    FROM RENAME_sup
)

, FILTER_itm as (
    SELECT *
    FROM RENAME_itm
)

, FILTER_org as (
    SELECT *
    FROM RENAME_org
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_polemtk
    LEFT JOIN FILTER_poemtk
        ON FILTER_polemtk.PO_HEADER_ID = FILTER_poemtk.POEMTK_PO_HEADER_ID
    INNER JOIN FILTER_a
        ON '1' = '1'
    LEFT JOIN FILTER_itm
        ON FILTER_polemtk.ITEM_ID = FILTER_itm.INVENTORY_ITEM_ID 
    LEFT JOIN FILTER_org
        ON FILTER_polemtk.ORG_ID = FILTER_org.ORGANIZATION_ID
    LEFT JOIN FILTER_sup
        ON FILTER_poemtk.VENDOR_ID = FILTER_sup.sup_vendor_id
)

---- FINAL LAYER ----
SELECT
          PO_ITEM_BK
        , PO_HEADER_BK
        , PO_HEADER_ID
        , LINE_NUM
        , SUP_SEGMENT1
        , ITM_SEGMENT1
        , ORGANIZATION_NAME
        , VENDOR_ID
        , PO_LINE_ID
        , ITEM_ID
        , ORG_ID
        , LAST_UPDATE_DATE
        , LAST_UPDATED_BY
        , LINE_TYPE_ID
        , LAST_UPDATE_LOGIN
        , CREATION_DATE
        , CREATED_BY
        , ITEM_REVISION
        , CATEGORY_ID
        , ITEM_DESCRIPTION
        , UNIT_MEAS_LOOKUP_CODE
        , QUANTITY_COMMITTED
        , COMMITTED_AMOUNT
        , ALLOW_PRICE_OVERRIDE_FLAG
        , NOT_TO_EXCEED_PRICE
        , LIST_PRICE_PER_UNIT
        , UNIT_PRICE
        , QUANTITY
        , UN_NUMBER_ID
        , HAZARD_CLASS_ID
        , NOTE_TO_VENDOR
        , FROM_HEADER_ID
        , FROM_LINE_ID
        , MIN_ORDER_QUANTITY
        , MAX_ORDER_QUANTITY
        , QTY_RCV_TOLERANCE
        , OVER_TOLERANCE_ERROR_FLAG
        , MARKET_PRICE
        , UNORDERED_FLAG
        , CLOSED_FLAG
        , USER_HOLD_FLAG
        , CANCEL_FLAG
        , CANCELLED_BY
        , CANCEL_DATE
        , FIRM_STATUS_LOOKUP_CODE
        , FIRM_DATE
        , VENDOR_PRODUCT_NUM
        , CONTRACT_NUM
        , TAXABLE_FLAG
        , TAX_NAME
        , TYPE_1099
        , CAPITAL_EXPENSE_FLAG
        , NEGOTIATED_BY_PREPARER_FLAG
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
        , REFERENCE_NUM
        , ATTRIBUTE11
        , ATTRIBUTE12
        , ATTRIBUTE13
        , ATTRIBUTE14
        , ATTRIBUTE15
        , MIN_RELEASE_AMOUNT
        , PRICE_TYPE_LOOKUP_CODE
        , CLOSED_CODE
        , PRICE_BREAK_LOOKUP_CODE
        , USSGL_TRANSACTION_CODE
        , GOVERNMENT_CONTEXT
        , REQUEST_ID
        , PROGRAM_APPLICATION_ID
        , PROGRAM_ID
        , PROGRAM_UPDATE_DATE
        , CLOSED_DATE
        , CLOSED_BY
        , TRANSACTION_REASON_CODE
        , QC_GRADE
        , BASE_UOM
        , BASE_QTY
        , SECONDARY_UOM
        , SECONDARY_QTY
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
        , LINE_REFERENCE_NUM
        , PROJECT_ID
        , TASK_ID
        , EXPIRATION_DATE
        , TAX_CODE_ID
        , OKE_CONTRACT_HEADER_ID
        , OKE_CONTRACT_VERSION_ID
        , SECONDARY_QUANTITY
        , SECONDARY_UNIT_OF_MEASURE
        , PREFERRED_GRADE
        , AUCTION_HEADER_ID
        , AUCTION_DISPLAY_NUMBER
        , AUCTION_LINE_NUMBER
        , BID_NUMBER
        , BID_LINE_NUMBER
        , RETROACTIVE_DATE
        , FROM_LINE_LOCATION_ID
        , SUPPLIER_REF_NUMBER
        , CONTRACT_ID
        , START_DATE
        , AMOUNT
        , JOB_ID
        , CONTRACTOR_FIRST_NAME
        , CONTRACTOR_LAST_NAME
        , ORDER_TYPE_LOOKUP_CODE
        , PURCHASE_BASIS
        , MATCHING_BASIS
        , SVC_AMOUNT_NOTIF_SENT
        , SVC_COMPLETION_NOTIF_SENT
        , BASE_UNIT_PRICE
        , MANUAL_PRICE_CHANGE_FLAG
        , CATALOG_NAME
        , SUPPLIER_PART_AUXID
        , IP_CATEGORY_ID
        , LAST_UPDATED_PROGRAM
        , RETAINAGE_RATE
        , MAX_RETAINAGE_AMOUNT
        , PROGRESS_PAYMENT_RATE
        , RECOUPMENT_RATE
        , TAX_ATTRIBUTE_UPDATE_CODE
        , GROUP_LINE_ID
        , LINE_NUM_DISPLAY
        , CLM_INFO_FLAG
        , CLM_OPTION_INDICATOR
        , CLM_BASE_LINE_NUM
        , CLM_OPTION_NUM
        , CLM_OPTION_FROM_DATE
        , CLM_OPTION_TO_DATE
        , CLM_FUNDED_FLAG
        , CONTRACT_TYPE
        , COST_CONSTRAINT
        , CLM_IDC_TYPE
        , UDA_TEMPLATE_ID
        , USER_DOCUMENT_STATUS
        , DRAFT_ID
        , CLM_MIN_TOTAL_AMOUNT
        , CLM_MAX_TOTAL_AMOUNT
        , CLM_MIN_TOTAL_QUANTITY
        , CLM_MAX_TOTAL_QUANTITY
        , CLM_MIN_ORDER_AMOUNT
        , CLM_MAX_ORDER_AMOUNT
        , CLM_MIN_ORDER_QUANTITY
        , CLM_MAX_ORDER_QUANTITY
        , CLM_TOTAL_AMOUNT_ORDERED
        , CLM_TOTAL_QUANTITY_ORDERED
        , CLM_FSC_PSC
        , CLM_MDAPS_MAIS
        , CLM_NAICS
        , CLM_ORDER_START_DATE
        , CLM_ORDER_END_DATE
        , CLM_EXERCISED_FLAG
        , CLM_EXERCISED_DATE
        , REVISION_NUM
        , CLM_APPROVED_UNDEF_AMOUNT
        , CLM_DELIVERY_EVENT_CODE
        , CLM_EXHIBIT_NAME
        , CLM_PAYMENT_INSTR_CODE
        , CLM_POP_EXCEPTION_REASON
        , CLM_UDA_PRICING_TOTAL
        , CLM_UNDEF_ACTION_CODE
        , CLM_UNDEF_FLAG
        , SCHEDULES_REQUIRED_FLAG
        , CANCEL_REASON_1
        , CLOSED_REASON_1
        , IGT_LINE_STATUS
        , _FIVETRAN_ID
        , _FIVETRAN_DELETED
        , _FIVETRAN_SYNCED
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        ,     IFF(ITM_SEGMENT1 IS NULL, '-2', CONCAT_WS('||',  ITM_SEGMENT1, BKCC)) as DRVD_ITEM_BKCC
        ,     IFF( SUP_SEGMENT1 IS NULL, '-2', CONCAT_WS('||',  SUP_SEGMENT1, BKCC)) as DRVD_SUPPLIER_BKCC
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PO_HEADER_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(LINE_NUM as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PO_ITEM_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PO_HEADER_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(LINE_NUM as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(SUP_SEGMENT1 as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(ITM_SEGMENT1 as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(ORGANIZATION_NAME as VARCHAR)),''), '^^')
        ))) as LNK_PO_ITEM_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PO_HEADER_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PO_HEADER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(DRVD_SUPPLIER_BKCC as VARCHAR)),''), '^^')
        ))) as SUPPLIER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(DRVD_ITEM_BKCC as VARCHAR)),''), '^^')
        ))) as ITEM_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ORGANIZATION_NAME as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as LEGAL_ENTITY_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST('-2' as VARCHAR)),''), '^^')
        ))) as PURCHASING_RECORD_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST('-2' as VARCHAR)),''), '^^')
        ))) as PURCHASING_ORG_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(PO_LINE_ID::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_ID::text), '^^') 
            , '||', IFNULL(TRIM(ORG_ID::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(LINE_TYPE_ID::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_LOGIN::text), '^^') 
            , '||', IFNULL(TRIM(CREATION_DATE::text), '^^') 
            , '||', IFNULL(TRIM(CREATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_REVISION::text), '^^') 
            , '||', IFNULL(TRIM(CATEGORY_ID::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_DESCRIPTION::text), '^^') 
            , '||', IFNULL(TRIM(UNIT_MEAS_LOOKUP_CODE::text), '^^') 
            , '||', IFNULL(TRIM(QUANTITY_COMMITTED::text), '^^') 
            , '||', IFNULL(TRIM(COMMITTED_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(ALLOW_PRICE_OVERRIDE_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(NOT_TO_EXCEED_PRICE::text), '^^') 
            , '||', IFNULL(TRIM(LIST_PRICE_PER_UNIT::text), '^^') 
            , '||', IFNULL(TRIM(UNIT_PRICE::text), '^^') 
            , '||', IFNULL(TRIM(QUANTITY::text), '^^') 
            , '||', IFNULL(TRIM(UN_NUMBER_ID::text), '^^') 
            , '||', IFNULL(TRIM(HAZARD_CLASS_ID::text), '^^') 
            , '||', IFNULL(TRIM(NOTE_TO_VENDOR::text), '^^') 
            , '||', IFNULL(TRIM(FROM_HEADER_ID::text), '^^') 
            , '||', IFNULL(TRIM(FROM_LINE_ID::text), '^^') 
            , '||', IFNULL(TRIM(MIN_ORDER_QUANTITY::text), '^^') 
            , '||', IFNULL(TRIM(MAX_ORDER_QUANTITY::text), '^^') 
            , '||', IFNULL(TRIM(QTY_RCV_TOLERANCE::text), '^^') 
            , '||', IFNULL(TRIM(OVER_TOLERANCE_ERROR_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(MARKET_PRICE::text), '^^') 
            , '||', IFNULL(TRIM(UNORDERED_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(CLOSED_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(USER_HOLD_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(CANCEL_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(CANCELLED_BY::text), '^^') 
            , '||', IFNULL(TRIM(CANCEL_DATE::text), '^^') 
            , '||', IFNULL(TRIM(FIRM_STATUS_LOOKUP_CODE::text), '^^') 
            , '||', IFNULL(TRIM(FIRM_DATE::text), '^^') 
            , '||', IFNULL(TRIM(VENDOR_PRODUCT_NUM::text), '^^') 
            , '||', IFNULL(TRIM(CONTRACT_NUM::text), '^^') 
            , '||', IFNULL(TRIM(TAXABLE_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(TAX_NAME::text), '^^') 
            , '||', IFNULL(TRIM(TYPE_1099::text), '^^') 
            , '||', IFNULL(TRIM(CAPITAL_EXPENSE_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(NEGOTIATED_BY_PREPARER_FLAG::text), '^^') 
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
            , '||', IFNULL(TRIM(REFERENCE_NUM::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE11::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE12::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE13::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE14::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE15::text), '^^') 
            , '||', IFNULL(TRIM(MIN_RELEASE_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(PRICE_TYPE_LOOKUP_CODE::text), '^^') 
            , '||', IFNULL(TRIM(CLOSED_CODE::text), '^^') 
            , '||', IFNULL(TRIM(PRICE_BREAK_LOOKUP_CODE::text), '^^') 
            , '||', IFNULL(TRIM(USSGL_TRANSACTION_CODE::text), '^^') 
            , '||', IFNULL(TRIM(GOVERNMENT_CONTEXT::text), '^^') 
            , '||', IFNULL(TRIM(REQUEST_ID::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_APPLICATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_ID::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_UPDATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(CLOSED_DATE::text), '^^') 
            , '||', IFNULL(TRIM(CLOSED_BY::text), '^^') 
            , '||', IFNULL(TRIM(TRANSACTION_REASON_CODE::text), '^^') 
            , '||', IFNULL(TRIM(QC_GRADE::text), '^^') 
            , '||', IFNULL(TRIM(BASE_UOM::text), '^^') 
            , '||', IFNULL(TRIM(BASE_QTY::text), '^^') 
            , '||', IFNULL(TRIM(SECONDARY_UOM::text), '^^') 
            , '||', IFNULL(TRIM(SECONDARY_QTY::text), '^^') 
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
            , '||', IFNULL(TRIM(LINE_REFERENCE_NUM::text), '^^') 
            , '||', IFNULL(TRIM(PROJECT_ID::text), '^^') 
            , '||', IFNULL(TRIM(TASK_ID::text), '^^') 
            , '||', IFNULL(TRIM(EXPIRATION_DATE::text), '^^') 
            , '||', IFNULL(TRIM(TAX_CODE_ID::text), '^^') 
            , '||', IFNULL(TRIM(OKE_CONTRACT_HEADER_ID::text), '^^') 
            , '||', IFNULL(TRIM(OKE_CONTRACT_VERSION_ID::text), '^^') 
            , '||', IFNULL(TRIM(SECONDARY_QUANTITY::text), '^^') 
            , '||', IFNULL(TRIM(SECONDARY_UNIT_OF_MEASURE::text), '^^') 
            , '||', IFNULL(TRIM(PREFERRED_GRADE::text), '^^') 
            , '||', IFNULL(TRIM(AUCTION_HEADER_ID::text), '^^') 
            , '||', IFNULL(TRIM(AUCTION_DISPLAY_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(AUCTION_LINE_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(BID_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(BID_LINE_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(RETROACTIVE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(FROM_LINE_LOCATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(SUPPLIER_REF_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(CONTRACT_ID::text), '^^') 
            , '||', IFNULL(TRIM(START_DATE::text), '^^') 
            , '||', IFNULL(TRIM(AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(JOB_ID::text), '^^') 
            , '||', IFNULL(TRIM(CONTRACTOR_FIRST_NAME::text), '^^') 
            , '||', IFNULL(TRIM(CONTRACTOR_LAST_NAME::text), '^^') 
            , '||', IFNULL(TRIM(ORDER_TYPE_LOOKUP_CODE::text), '^^') 
            , '||', IFNULL(TRIM(PURCHASE_BASIS::text), '^^') 
            , '||', IFNULL(TRIM(MATCHING_BASIS::text), '^^') 
            , '||', IFNULL(TRIM(SVC_AMOUNT_NOTIF_SENT::text), '^^') 
            , '||', IFNULL(TRIM(SVC_COMPLETION_NOTIF_SENT::text), '^^') 
            , '||', IFNULL(TRIM(BASE_UNIT_PRICE::text), '^^') 
            , '||', IFNULL(TRIM(MANUAL_PRICE_CHANGE_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(CATALOG_NAME::text), '^^') 
            , '||', IFNULL(TRIM(SUPPLIER_PART_AUXID::text), '^^') 
            , '||', IFNULL(TRIM(IP_CATEGORY_ID::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATED_PROGRAM::text), '^^') 
            , '||', IFNULL(TRIM(RETAINAGE_RATE::text), '^^') 
            , '||', IFNULL(TRIM(MAX_RETAINAGE_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(PROGRESS_PAYMENT_RATE::text), '^^') 
            , '||', IFNULL(TRIM(RECOUPMENT_RATE::text), '^^') 
            , '||', IFNULL(TRIM(TAX_ATTRIBUTE_UPDATE_CODE::text), '^^') 
            , '||', IFNULL(TRIM(GROUP_LINE_ID::text), '^^') 
            , '||', IFNULL(TRIM(LINE_NUM_DISPLAY::text), '^^') 
            , '||', IFNULL(TRIM(CLM_INFO_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(CLM_OPTION_INDICATOR::text), '^^') 
            , '||', IFNULL(TRIM(CLM_BASE_LINE_NUM::text), '^^') 
            , '||', IFNULL(TRIM(CLM_OPTION_NUM::text), '^^') 
            , '||', IFNULL(TRIM(CLM_OPTION_FROM_DATE::text), '^^') 
            , '||', IFNULL(TRIM(CLM_OPTION_TO_DATE::text), '^^') 
            , '||', IFNULL(TRIM(CLM_FUNDED_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(CONTRACT_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(COST_CONSTRAINT::text), '^^') 
            , '||', IFNULL(TRIM(CLM_IDC_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(UDA_TEMPLATE_ID::text), '^^') 
            , '||', IFNULL(TRIM(USER_DOCUMENT_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(DRAFT_ID::text), '^^') 
            , '||', IFNULL(TRIM(CLM_MIN_TOTAL_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(CLM_MAX_TOTAL_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(CLM_MIN_TOTAL_QUANTITY::text), '^^') 
            , '||', IFNULL(TRIM(CLM_MAX_TOTAL_QUANTITY::text), '^^') 
            , '||', IFNULL(TRIM(CLM_MIN_ORDER_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(CLM_MAX_ORDER_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(CLM_MIN_ORDER_QUANTITY::text), '^^') 
            , '||', IFNULL(TRIM(CLM_MAX_ORDER_QUANTITY::text), '^^') 
            , '||', IFNULL(TRIM(CLM_TOTAL_AMOUNT_ORDERED::text), '^^') 
            , '||', IFNULL(TRIM(CLM_TOTAL_QUANTITY_ORDERED::text), '^^') 
            , '||', IFNULL(TRIM(CLM_FSC_PSC::text), '^^') 
            , '||', IFNULL(TRIM(CLM_MDAPS_MAIS::text), '^^') 
            , '||', IFNULL(TRIM(CLM_NAICS::text), '^^') 
            , '||', IFNULL(TRIM(CLM_ORDER_START_DATE::text), '^^') 
            , '||', IFNULL(TRIM(CLM_ORDER_END_DATE::text), '^^') 
            , '||', IFNULL(TRIM(CLM_EXERCISED_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(CLM_EXERCISED_DATE::text), '^^') 
            , '||', IFNULL(TRIM(REVISION_NUM::text), '^^') 
            , '||', IFNULL(TRIM(CLM_APPROVED_UNDEF_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(CLM_DELIVERY_EVENT_CODE::text), '^^') 
            , '||', IFNULL(TRIM(CLM_EXHIBIT_NAME::text), '^^') 
            , '||', IFNULL(TRIM(CLM_PAYMENT_INSTR_CODE::text), '^^') 
            , '||', IFNULL(TRIM(CLM_POP_EXCEPTION_REASON::text), '^^') 
            , '||', IFNULL(TRIM(CLM_UDA_PRICING_TOTAL::text), '^^') 
            , '||', IFNULL(TRIM(CLM_UNDEF_ACTION_CODE::text), '^^') 
            , '||', IFNULL(TRIM(CLM_UNDEF_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(SCHEDULES_REQUIRED_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(CANCEL_REASON_1::text), '^^') 
            , '||', IFNULL(TRIM(CLOSED_REASON_1::text), '^^') 
            , '||', IFNULL(TRIM(IGT_LINE_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
