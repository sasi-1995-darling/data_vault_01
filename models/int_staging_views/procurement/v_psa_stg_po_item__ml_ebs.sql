---- SRC LAYER ----
WITH
SRC_polml          as ( SELECT ALLOW_PRICE_OVERRIDE_FLAG, AMOUNT, ATTRIBUTE1, ATTRIBUTE10, ATTRIBUTE11, ATTRIBUTE12, ATTRIBUTE13, ATTRIBUTE14, ATTRIBUTE15, ATTRIBUTE2, ATTRIBUTE3, ATTRIBUTE4, ATTRIBUTE5, ATTRIBUTE6, ATTRIBUTE7, ATTRIBUTE8, ATTRIBUTE9, ATTRIBUTE_CATEGORY, AUCTION_DISPLAY_NUMBER, AUCTION_HEADER_ID, AUCTION_LINE_NUMBER, BASE_QTY, BASE_UNIT_PRICE, BASE_UOM, BID_LINE_NUMBER, BID_NUMBER, CANCELLED_BY, CANCEL_DATE, CANCEL_FLAG, CANCEL_REASON, CAPITAL_EXPENSE_FLAG, CATALOG_NAME, CATEGORY_ID, CLM_BASE_LINE_NUM, CLM_EXERCISED_DATE, CLM_EXERCISED_FLAG, CLM_FUNDED_FLAG, CLM_IDC_TYPE, CLM_INFO_FLAG, CLM_OPTION_FROM_DATE, CLM_OPTION_INDICATOR, CLM_OPTION_NUM, CLM_OPTION_TO_DATE, CLOSED_BY, CLOSED_CODE, CLOSED_DATE, CLOSED_FLAG, CLOSED_REASON, COMMITTED_AMOUNT, CONTRACTOR_FIRST_NAME, CONTRACTOR_LAST_NAME, CONTRACT_ID, CONTRACT_NUM, CONTRACT_TYPE, COST_CONSTRAINT, CREATED_BY, CREATION_DATE, DRAFT_ID, EXPIRATION_DATE, FIRM_DATE, FIRM_STATUS_LOOKUP_CODE, FROM_HEADER_ID, FROM_LINE_ID, FROM_LINE_LOCATION_ID, GLOBAL_ATTRIBUTE1, GLOBAL_ATTRIBUTE10, GLOBAL_ATTRIBUTE11, GLOBAL_ATTRIBUTE12, GLOBAL_ATTRIBUTE13, GLOBAL_ATTRIBUTE14, GLOBAL_ATTRIBUTE15, GLOBAL_ATTRIBUTE16, GLOBAL_ATTRIBUTE17, GLOBAL_ATTRIBUTE18, GLOBAL_ATTRIBUTE19, GLOBAL_ATTRIBUTE2, GLOBAL_ATTRIBUTE20, GLOBAL_ATTRIBUTE3, GLOBAL_ATTRIBUTE4, GLOBAL_ATTRIBUTE5, GLOBAL_ATTRIBUTE6, GLOBAL_ATTRIBUTE7, GLOBAL_ATTRIBUTE8, GLOBAL_ATTRIBUTE9, GLOBAL_ATTRIBUTE_CATEGORY, GOVERNMENT_CONTEXT, GROUP_LINE_ID, HAZARD_CLASS_ID, IP_CATEGORY_ID, ITEM_DESCRIPTION, ITEM_ID, ITEM_REVISION, JOB_ID, LAST_UPDATED_BY, LAST_UPDATED_PROGRAM, LAST_UPDATE_DATE, LAST_UPDATE_LOGIN, LINE_NUM, LINE_NUM_DISPLAY, LINE_REFERENCE_NUM, LINE_TYPE_ID, LIST_PRICE_PER_UNIT, MANUAL_PRICE_CHANGE_FLAG, MARKET_PRICE, MATCHING_BASIS, MAX_ORDER_QUANTITY, MAX_RETAINAGE_AMOUNT, MIN_ORDER_QUANTITY, MIN_RELEASE_AMOUNT, NEGOTIATED_BY_PREPARER_FLAG, NOTE_TO_VENDOR, NOT_TO_EXCEED_PRICE, OKE_CONTRACT_HEADER_ID, OKE_CONTRACT_VERSION_ID, ORDER_TYPE_LOOKUP_CODE, ORG_ID, OVER_TOLERANCE_ERROR_FLAG, PO_HEADER_ID, PO_LINE_ID, PREFERRED_GRADE, PRICE_BREAK_LOOKUP_CODE, PRICE_TYPE_LOOKUP_CODE, PROGRAM_APPLICATION_ID, PROGRAM_ID, PROGRAM_UPDATE_DATE, PROGRESS_PAYMENT_RATE, PROJECT_ID, PSA_DELETE_IND, PSA_LOAD_DTS, PURCHASE_BASIS, QC_GRADE, QTY_RCV_TOLERANCE, QUANTITY, QUANTITY_COMMITTED, RECOUPMENT_RATE, REFERENCE_NUM, REQUEST_ID, RETAINAGE_RATE, RETROACTIVE_DATE, SECONDARY_QTY, SECONDARY_QUANTITY, SECONDARY_UNIT_OF_MEASURE, SECONDARY_UOM, START_DATE, SUPPLIER_PART_AUXID, SUPPLIER_REF_NUMBER, SVC_AMOUNT_NOTIF_SENT, SVC_COMPLETION_NOTIF_SENT, TASK_ID, TAXABLE_FLAG, TAX_ATTRIBUTE_UPDATE_CODE, TAX_CODE_ID, TAX_NAME, TRANSACTION_REASON_CODE, TYPE_1099, UDA_TEMPLATE_ID, UNIT_MEAS_LOOKUP_CODE, UNIT_PRICE, UNORDERED_FLAG, UN_NUMBER_ID, USER_DOCUMENT_STATUS, USER_HOLD_FLAG, USSGL_TRANSACTION_CODE, VENDOR_PRODUCT_NUM, _FIVETRAN_DELETED, _FIVETRAN_ID, _FIVETRAN_SYNCED FROM {{ source('ml_ebs_po', 'po_lines_all') }} as SRC  ),
SRC_poml           as ( SELECT CREATION_DATE, PO_HEADER_ID, VENDOR_ID FROM {{ source('ml_ebs_po', 'po_headers_all') }} as SRC 
                        qualify 1= row_number()over(partition by po_header_id order by _fivetran_synced desc, psa_load_dts desc) ),
SRC_a              as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  ),
SRC_sup            as ( SELECT SEGMENT1, VENDOR_ID FROM {{ source('ml_ebs_ap', 'ap_suppliers') }} as SRC 
                        qualify 1= row_number()over(partition by vendor_id order by _fivetran_synced desc, psa_load_dts desc) ),
SRC_itm            as ( SELECT INVENTORY_ITEM_ID, ORGANIZATION_ID, SEGMENT1 FROM {{ source('ml_ebs_inv', 'mtl_system_items_b') }} as SRC 
                        where organization_id = 1 
                        qualify 1= row_number()over(partition by inventory_item_id order by _fivetran_synced desc, psa_load_dts desc) )

/*
SRC_polml          as ( SELECT * FROM ml_ebs_po.po_lines_all )
SRC_poml           as ( SELECT * FROM ml_ebs_po.po_headers_all )
SRC_a              as ( SELECT * FROM raw_vault.ref_business_key_collision )
SRC_sup            as ( SELECT * FROM ml_ebs_ap.ap_suppliers )
SRC_itm            as ( SELECT * FROM ml_ebs_inv.mtl_system_items_b )
*/
---- LOGIC LAYER ----

, LOGIC_polml as (
    SELECT
        CONCAT_WS('||', COALESCE(PO_HEADER_ID, ''), COALESCE(LINE_NUM::TEXT, '')) as                                         PO_ITEM_BK
      , COALESCE(PO_HEADER_ID::TEXT, '')                             as                                       PO_HEADER_BK
      , COALESCE(ORG_ID::TEXT, '')                                   as                                    LEGAL_ENTITY_BK
      , PO_HEADER_ID
      , LINE_NUM
      , CATEGORY_ID
      , ORG_ID
      , PRICE_BREAK_LOOKUP_CODE
      , OKE_CONTRACT_VERSION_ID
      , UNIT_PRICE
      , SVC_COMPLETION_NOTIF_SENT
      , PROGRAM_ID
      , UDA_TEMPLATE_ID
      , GLOBAL_ATTRIBUTE5
      , GLOBAL_ATTRIBUTE4
      , GLOBAL_ATTRIBUTE7
      , GLOBAL_ATTRIBUTE6
      , GLOBAL_ATTRIBUTE1
      , AMOUNT
      , GLOBAL_ATTRIBUTE3
      , GLOBAL_ATTRIBUTE2
      , FROM_LINE_LOCATION_ID
      , BASE_UNIT_PRICE
      , GROUP_LINE_ID
      , GLOBAL_ATTRIBUTE9
      , GLOBAL_ATTRIBUTE8
      , MAX_ORDER_QUANTITY
      , UNORDERED_FLAG
      , NOT_TO_EXCEED_PRICE
      , ALLOW_PRICE_OVERRIDE_FLAG
      , ATTRIBUTE3
      , ATTRIBUTE2
      , ATTRIBUTE1
      , CONTRACT_NUM
      , VENDOR_PRODUCT_NUM
      , ITEM_ID
      , ATTRIBUTE9
      , SECONDARY_QTY
      , ATTRIBUTE8
      , ATTRIBUTE7
      , USSGL_TRANSACTION_CODE
      , ATTRIBUTE6
      , ATTRIBUTE5
      , AUCTION_DISPLAY_NUMBER
      , ATTRIBUTE4
      , CLM_EXERCISED_DATE
      , SECONDARY_UNIT_OF_MEASURE
      , EXPIRATION_DATE
      , BASE_QTY
      , NOTE_TO_VENDOR
      , TASK_ID
      , PROGRESS_PAYMENT_RATE
      , ATTRIBUTE10
      , CLM_OPTION_FROM_DATE
      , JOB_ID
      , OKE_CONTRACT_HEADER_ID
      , AUCTION_LINE_NUMBER
      , CAPITAL_EXPENSE_FLAG
      , ATTRIBUTE14
      , ATTRIBUTE13
      , ATTRIBUTE12
      , ATTRIBUTE11
      , CANCEL_REASON
      , CONTRACTOR_FIRST_NAME
      , FROM_LINE_ID
      , TAX_CODE_ID
      , CLM_FUNDED_FLAG
      , MIN_ORDER_QUANTITY
      , CLM_OPTION_TO_DATE
      , CLOSED_BY
      , COMMITTED_AMOUNT
      , PROJECT_ID
      , SUPPLIER_REF_NUMBER
      , TAX_NAME
      , FROM_HEADER_ID
      , CATALOG_NAME
      , CLOSED_FLAG
      , ITEM_REVISION
      , FIRM_DATE
      , GLOBAL_ATTRIBUTE20
      , ORDER_TYPE_LOOKUP_CODE
      , START_DATE
      , REFERENCE_NUM
      , MIN_RELEASE_AMOUNT
      , SUPPLIER_PART_AUXID
      , LAST_UPDATED_PROGRAM
      , GLOBAL_ATTRIBUTE17
      , GLOBAL_ATTRIBUTE18
      , GLOBAL_ATTRIBUTE15
      , QUANTITY_COMMITTED
      , CANCEL_FLAG
      , GLOBAL_ATTRIBUTE16
      , MAX_RETAINAGE_AMOUNT
      , GLOBAL_ATTRIBUTE13
      , GLOBAL_ATTRIBUTE14
      , BID_NUMBER
      , GLOBAL_ATTRIBUTE11
      , GLOBAL_ATTRIBUTE12
      , CLM_OPTION_INDICATOR
      , ATTRIBUTE15
      , TAXABLE_FLAG
      , GLOBAL_ATTRIBUTE19
      , CLOSED_REASON
      , QUANTITY
      , USER_HOLD_FLAG
      , SECONDARY_UOM
      , GLOBAL_ATTRIBUTE10
      , ITEM_DESCRIPTION
      , CONTRACTOR_LAST_NAME
      , SVC_AMOUNT_NOTIF_SENT
      , RECOUPMENT_RATE
      , CLM_BASE_LINE_NUM
      , CLM_IDC_TYPE
      , BASE_UOM
      , COST_CONSTRAINT
      , MARKET_PRICE
      , CREATED_BY
      , LAST_UPDATED_BY
      , TRANSACTION_REASON_CODE
      , CANCELLED_BY
      , LINE_REFERENCE_NUM
      , SECONDARY_QUANTITY
      , LINE_NUM_DISPLAY
      , CONTRACT_ID
      , HAZARD_CLASS_ID
      , CLM_OPTION_NUM
      , CONTRACT_TYPE
      , CLM_INFO_FLAG
      , AUCTION_HEADER_ID
      , ATTRIBUTE_CATEGORY
      , PROGRAM_APPLICATION_ID
      , GOVERNMENT_CONTEXT
      , LINE_TYPE_ID
      , UNIT_MEAS_LOOKUP_CODE
      , PREFERRED_GRADE
      , MATCHING_BASIS
      , REQUEST_ID
      , FIRM_STATUS_LOOKUP_CODE
      , MANUAL_PRICE_CHANGE_FLAG
      , BID_LINE_NUMBER
      , USER_DOCUMENT_STATUS
      , CLOSED_CODE
      , TYPE_1099
      , LIST_PRICE_PER_UNIT
      , NEGOTIATED_BY_PREPARER_FLAG
      , QC_GRADE
      , DRAFT_ID
      , QTY_RCV_TOLERANCE
      , TAX_ATTRIBUTE_UPDATE_CODE
      , PRICE_TYPE_LOOKUP_CODE
      , OVER_TOLERANCE_ERROR_FLAG
      , PURCHASE_BASIS
      , LAST_UPDATE_LOGIN
      , RETAINAGE_RATE
      , GLOBAL_ATTRIBUTE_CATEGORY
      , UN_NUMBER_ID
      , CLM_EXERCISED_FLAG
      , IP_CATEGORY_ID
      , PO_LINE_ID
      , _FIVETRAN_DELETED
      , _FIVETRAN_ID
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_DELETE_IND
      , PROGRAM_UPDATE_DATE
      , CLOSED_DATE
      , CANCEL_DATE
      , RETROACTIVE_DATE
      , CREATION_DATE
      , LAST_UPDATE_DATE
      /*Updated the LOAD_DTS logic from _FIVETRAN_SYNCED to PSA_LOAD_DTS to resolve the duplicate issue caused by fivetran connector issue.
      We have historically(before Nov 2024) updated the PSA_LOAD_DTS field, so the duplicate issue does not come again  */
      , CONVERT_TIMEZONE('UTC', PSA_LOAD_DTS)                    as                                           LOAD_DTS
    FROM SRC_polml
)

, LOGIC_poml as (
    SELECT
        VENDOR_ID
      , CREATION_DATE                                                as                                  HDR_CREATION_DATE
      , HDR_CREATION_DATE::DATE                                      as                               PO_HDR_CREATION_DATE
      , PO_HEADER_ID                                                 as                                  POML_PO_HEADER_ID
    FROM SRC_poml
)

, LOGIC_a as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_a
)

, LOGIC_sup as (
    SELECT
        COALESCE(SEGMENT1::TEXT, '')                                 as                                        SUPPLIER_BK
      , SEGMENT1                                                     as                                       SUP_SEGMENT1
      , VENDOR_ID                                                    as                                      SUP_VENDOR_ID
    FROM SRC_sup
)

, LOGIC_itm as (
    SELECT
        COALESCE(SEGMENT1::TEXT, '')                                 as                                            ITEM_BK
      , SEGMENT1                                                     as                                       ITM_SEGMENT1
      , INVENTORY_ITEM_ID
      , ORGANIZATION_ID
    FROM SRC_itm
)
---- RENAME LAYER ----

, RENAME_polml as (
    SELECT
        PO_ITEM_BK
      , PO_HEADER_BK
      , LEGAL_ENTITY_BK
      , PO_HEADER_ID
      , LINE_NUM
      , CATEGORY_ID
      , ORG_ID
      , PRICE_BREAK_LOOKUP_CODE
      , OKE_CONTRACT_VERSION_ID
      , UNIT_PRICE
      , SVC_COMPLETION_NOTIF_SENT
      , PROGRAM_ID
      , UDA_TEMPLATE_ID
      , GLOBAL_ATTRIBUTE5
      , GLOBAL_ATTRIBUTE4
      , GLOBAL_ATTRIBUTE7
      , GLOBAL_ATTRIBUTE6
      , GLOBAL_ATTRIBUTE1
      , AMOUNT
      , GLOBAL_ATTRIBUTE3
      , GLOBAL_ATTRIBUTE2
      , FROM_LINE_LOCATION_ID
      , BASE_UNIT_PRICE
      , GROUP_LINE_ID
      , GLOBAL_ATTRIBUTE9
      , GLOBAL_ATTRIBUTE8
      , MAX_ORDER_QUANTITY
      , UNORDERED_FLAG
      , NOT_TO_EXCEED_PRICE
      , ALLOW_PRICE_OVERRIDE_FLAG
      , ATTRIBUTE3
      , ATTRIBUTE2
      , ATTRIBUTE1
      , CONTRACT_NUM
      , VENDOR_PRODUCT_NUM
      , ITEM_ID
      , ATTRIBUTE9
      , SECONDARY_QTY
      , ATTRIBUTE8
      , ATTRIBUTE7
      , USSGL_TRANSACTION_CODE
      , ATTRIBUTE6
      , ATTRIBUTE5
      , AUCTION_DISPLAY_NUMBER
      , ATTRIBUTE4
      , CLM_EXERCISED_DATE
      , SECONDARY_UNIT_OF_MEASURE
      , EXPIRATION_DATE
      , BASE_QTY
      , NOTE_TO_VENDOR
      , TASK_ID
      , PROGRESS_PAYMENT_RATE
      , ATTRIBUTE10
      , CLM_OPTION_FROM_DATE
      , JOB_ID
      , OKE_CONTRACT_HEADER_ID
      , AUCTION_LINE_NUMBER
      , CAPITAL_EXPENSE_FLAG
      , ATTRIBUTE14
      , ATTRIBUTE13
      , ATTRIBUTE12
      , ATTRIBUTE11
      , CANCEL_REASON
      , CONTRACTOR_FIRST_NAME
      , FROM_LINE_ID
      , TAX_CODE_ID
      , CLM_FUNDED_FLAG
      , MIN_ORDER_QUANTITY
      , CLM_OPTION_TO_DATE
      , CLOSED_BY
      , COMMITTED_AMOUNT
      , PROJECT_ID
      , SUPPLIER_REF_NUMBER
      , TAX_NAME
      , FROM_HEADER_ID
      , CATALOG_NAME
      , CLOSED_FLAG
      , ITEM_REVISION
      , FIRM_DATE
      , GLOBAL_ATTRIBUTE20
      , ORDER_TYPE_LOOKUP_CODE
      , START_DATE
      , REFERENCE_NUM
      , MIN_RELEASE_AMOUNT
      , SUPPLIER_PART_AUXID
      , LAST_UPDATED_PROGRAM
      , GLOBAL_ATTRIBUTE17
      , GLOBAL_ATTRIBUTE18
      , GLOBAL_ATTRIBUTE15
      , QUANTITY_COMMITTED
      , CANCEL_FLAG
      , GLOBAL_ATTRIBUTE16
      , MAX_RETAINAGE_AMOUNT
      , GLOBAL_ATTRIBUTE13
      , GLOBAL_ATTRIBUTE14
      , BID_NUMBER
      , GLOBAL_ATTRIBUTE11
      , GLOBAL_ATTRIBUTE12
      , CLM_OPTION_INDICATOR
      , ATTRIBUTE15
      , TAXABLE_FLAG
      , GLOBAL_ATTRIBUTE19
      , CLOSED_REASON
      , QUANTITY
      , USER_HOLD_FLAG
      , SECONDARY_UOM
      , GLOBAL_ATTRIBUTE10
      , ITEM_DESCRIPTION
      , CONTRACTOR_LAST_NAME
      , SVC_AMOUNT_NOTIF_SENT
      , RECOUPMENT_RATE
      , CLM_BASE_LINE_NUM
      , CLM_IDC_TYPE
      , BASE_UOM
      , COST_CONSTRAINT
      , MARKET_PRICE
      , CREATED_BY
      , LAST_UPDATED_BY
      , TRANSACTION_REASON_CODE
      , CANCELLED_BY
      , LINE_REFERENCE_NUM
      , SECONDARY_QUANTITY
      , LINE_NUM_DISPLAY
      , CONTRACT_ID
      , HAZARD_CLASS_ID
      , CLM_OPTION_NUM
      , CONTRACT_TYPE
      , CLM_INFO_FLAG
      , AUCTION_HEADER_ID
      , ATTRIBUTE_CATEGORY
      , PROGRAM_APPLICATION_ID
      , GOVERNMENT_CONTEXT
      , LINE_TYPE_ID
      , UNIT_MEAS_LOOKUP_CODE
      , PREFERRED_GRADE
      , MATCHING_BASIS
      , REQUEST_ID
      , FIRM_STATUS_LOOKUP_CODE
      , MANUAL_PRICE_CHANGE_FLAG
      , BID_LINE_NUMBER
      , USER_DOCUMENT_STATUS
      , CLOSED_CODE
      , TYPE_1099
      , LIST_PRICE_PER_UNIT
      , NEGOTIATED_BY_PREPARER_FLAG
      , QC_GRADE
      , DRAFT_ID
      , QTY_RCV_TOLERANCE
      , TAX_ATTRIBUTE_UPDATE_CODE
      , PRICE_TYPE_LOOKUP_CODE
      , OVER_TOLERANCE_ERROR_FLAG
      , PURCHASE_BASIS
      , LAST_UPDATE_LOGIN
      , RETAINAGE_RATE
      , GLOBAL_ATTRIBUTE_CATEGORY
      , UN_NUMBER_ID
      , CLM_EXERCISED_FLAG
      , IP_CATEGORY_ID
      , PO_LINE_ID
      , _FIVETRAN_DELETED
      , _FIVETRAN_ID
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_DELETE_IND
      , PROGRAM_UPDATE_DATE
      , CLOSED_DATE
      , CANCEL_DATE
      , RETROACTIVE_DATE
      , CREATION_DATE
      , LAST_UPDATE_DATE
      , LOAD_DTS
    FROM LOGIC_polml
)

, RENAME_sup as (
    SELECT
        SUPPLIER_BK
      , SUP_SEGMENT1
      , SUP_VENDOR_ID
    FROM LOGIC_sup
)

, RENAME_itm as (
    SELECT
        ITEM_BK
      , ITM_SEGMENT1
      , INVENTORY_ITEM_ID
      , ORGANIZATION_ID
    FROM LOGIC_itm
)

, RENAME_poml as (
    SELECT
        VENDOR_ID
      , HDR_CREATION_DATE
      , PO_HDR_CREATION_DATE
      , POML_PO_HEADER_ID
    FROM LOGIC_poml
)

, RENAME_a as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_a
)
---- FILTER LAYER ----

, FILTER_polml as (
    SELECT *
    FROM RENAME_polml
)

, FILTER_poml as (
    SELECT *
    FROM RENAME_poml
)

, FILTER_a as (
    SELECT *
    FROM RENAME_a
    WHERE rec_src = 'USWIOC.ORCL.EBSPRD.PO_LINES_ALL'
)

, FILTER_sup as (
    SELECT *
    FROM RENAME_sup
)

, FILTER_itm as (
    SELECT *
    FROM RENAME_itm
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_polml
    LEFT JOIN FILTER_poml
        ON FILTER_polml.PO_HEADER_ID = FILTER_poml.POML_PO_HEADER_ID
    INNER JOIN FILTER_a
        ON '1' = '1'
    LEFT JOIN FILTER_itm
        ON FILTER_polml.ITEM_ID = FILTER_itm.INVENTORY_ITEM_ID 
    LEFT JOIN FILTER_sup
        ON FILTER_poml.VENDOR_ID = sup_vendor_id
)

---- FINAL LAYER ----
SELECT
          PO_ITEM_BK
        , PO_HEADER_BK
        , LEGAL_ENTITY_BK
        , PO_HEADER_ID
        , LINE_NUM
        , CATEGORY_ID
        , ORG_ID
        , PRICE_BREAK_LOOKUP_CODE
        , OKE_CONTRACT_VERSION_ID
        , UNIT_PRICE
        , SVC_COMPLETION_NOTIF_SENT
        , PROGRAM_ID
        , UDA_TEMPLATE_ID
        , GLOBAL_ATTRIBUTE5
        , GLOBAL_ATTRIBUTE4
        , GLOBAL_ATTRIBUTE7
        , GLOBAL_ATTRIBUTE6
        , GLOBAL_ATTRIBUTE1
        , AMOUNT
        , GLOBAL_ATTRIBUTE3
        , GLOBAL_ATTRIBUTE2
        , FROM_LINE_LOCATION_ID
        , BASE_UNIT_PRICE
        , GROUP_LINE_ID
        , GLOBAL_ATTRIBUTE9
        , GLOBAL_ATTRIBUTE8
        , MAX_ORDER_QUANTITY
        , UNORDERED_FLAG
        , NOT_TO_EXCEED_PRICE
        , ALLOW_PRICE_OVERRIDE_FLAG
        , ATTRIBUTE3
        , ATTRIBUTE2
        , ATTRIBUTE1
        , CONTRACT_NUM
        , VENDOR_PRODUCT_NUM
        , ITEM_ID
        , ATTRIBUTE9
        , SECONDARY_QTY
        , ATTRIBUTE8
        , ATTRIBUTE7
        , USSGL_TRANSACTION_CODE
        , ATTRIBUTE6
        , ATTRIBUTE5
        , AUCTION_DISPLAY_NUMBER
        , ATTRIBUTE4
        , CLM_EXERCISED_DATE
        , SECONDARY_UNIT_OF_MEASURE
        , EXPIRATION_DATE
        , BASE_QTY
        , NOTE_TO_VENDOR
        , TASK_ID
        , PROGRESS_PAYMENT_RATE
        , ATTRIBUTE10
        , CLM_OPTION_FROM_DATE
        , JOB_ID
        , OKE_CONTRACT_HEADER_ID
        , AUCTION_LINE_NUMBER
        , CAPITAL_EXPENSE_FLAG
        , ATTRIBUTE14
        , ATTRIBUTE13
        , ATTRIBUTE12
        , ATTRIBUTE11
        , CANCEL_REASON
        , CONTRACTOR_FIRST_NAME
        , FROM_LINE_ID
        , TAX_CODE_ID
        , CLM_FUNDED_FLAG
        , MIN_ORDER_QUANTITY
        , CLM_OPTION_TO_DATE
        , CLOSED_BY
        , COMMITTED_AMOUNT
        , PROJECT_ID
        , SUPPLIER_REF_NUMBER
        , TAX_NAME
        , FROM_HEADER_ID
        , CATALOG_NAME
        , CLOSED_FLAG
        , ITEM_REVISION
        , FIRM_DATE
        , GLOBAL_ATTRIBUTE20
        , ORDER_TYPE_LOOKUP_CODE
        , START_DATE
        , REFERENCE_NUM
        , MIN_RELEASE_AMOUNT
        , SUPPLIER_PART_AUXID
        , LAST_UPDATED_PROGRAM
        , GLOBAL_ATTRIBUTE17
        , GLOBAL_ATTRIBUTE18
        , GLOBAL_ATTRIBUTE15
        , QUANTITY_COMMITTED
        , CANCEL_FLAG
        , GLOBAL_ATTRIBUTE16
        , MAX_RETAINAGE_AMOUNT
        , GLOBAL_ATTRIBUTE13
        , GLOBAL_ATTRIBUTE14
        , BID_NUMBER
        , GLOBAL_ATTRIBUTE11
        , GLOBAL_ATTRIBUTE12
        , CLM_OPTION_INDICATOR
        , ATTRIBUTE15
        , TAXABLE_FLAG
        , GLOBAL_ATTRIBUTE19
        , CLOSED_REASON
        , QUANTITY
        , USER_HOLD_FLAG
        , SECONDARY_UOM
        , GLOBAL_ATTRIBUTE10
        , ITEM_DESCRIPTION
        , CONTRACTOR_LAST_NAME
        , SVC_AMOUNT_NOTIF_SENT
        , RECOUPMENT_RATE
        , CLM_BASE_LINE_NUM
        , CLM_IDC_TYPE
        , BASE_UOM
        , COST_CONSTRAINT
        , MARKET_PRICE
        , CREATED_BY
        , LAST_UPDATED_BY
        , TRANSACTION_REASON_CODE
        , CANCELLED_BY
        , LINE_REFERENCE_NUM
        , SECONDARY_QUANTITY
        , LINE_NUM_DISPLAY
        , CONTRACT_ID
        , HAZARD_CLASS_ID
        , CLM_OPTION_NUM
        , CONTRACT_TYPE
        , CLM_INFO_FLAG
        , AUCTION_HEADER_ID
        , ATTRIBUTE_CATEGORY
        , PROGRAM_APPLICATION_ID
        , GOVERNMENT_CONTEXT
        , LINE_TYPE_ID
        , UNIT_MEAS_LOOKUP_CODE
        , PREFERRED_GRADE
        , MATCHING_BASIS
        , REQUEST_ID
        , FIRM_STATUS_LOOKUP_CODE
        , MANUAL_PRICE_CHANGE_FLAG
        , BID_LINE_NUMBER
        , USER_DOCUMENT_STATUS
        , CLOSED_CODE
        , TYPE_1099
        , LIST_PRICE_PER_UNIT
        , NEGOTIATED_BY_PREPARER_FLAG
        , QC_GRADE
        , DRAFT_ID
        , QTY_RCV_TOLERANCE
        , TAX_ATTRIBUTE_UPDATE_CODE
        , PRICE_TYPE_LOOKUP_CODE
        , OVER_TOLERANCE_ERROR_FLAG
        , PURCHASE_BASIS
        , LAST_UPDATE_LOGIN
        , RETAINAGE_RATE
        , GLOBAL_ATTRIBUTE_CATEGORY
        , UN_NUMBER_ID
        , CLM_EXERCISED_FLAG
        , IP_CATEGORY_ID
        , PO_LINE_ID
        , _FIVETRAN_DELETED
        , _FIVETRAN_ID
        , _FIVETRAN_SYNCED
        , PSA_LOAD_DTS
        , PSA_DELETE_IND
        , PROGRAM_UPDATE_DATE
        , CLOSED_DATE
        , CANCEL_DATE
        , RETROACTIVE_DATE
        , CREATION_DATE
        , LAST_UPDATE_DATE
        , LOAD_DTS
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
        , COALESCE(NULLIF(TRIM(CAST(ORG_ID as VARCHAR)),''), '^^')
        ))) as LNK_PO_ITEM_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PO_HEADER_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PO_HEADER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(SUP_SEGMENT1 as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as SUPPLIER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ITM_SEGMENT1 as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ITEM_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ORG_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as LEGAL_ENTITY_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(CATEGORY_ID::text), '^^') 
            , '||', IFNULL(TRIM(ORG_ID::text), '^^') 
            , '||', IFNULL(TRIM(PRICE_BREAK_LOOKUP_CODE::text), '^^') 
            , '||', IFNULL(TRIM(OKE_CONTRACT_VERSION_ID::text), '^^') 
            , '||', IFNULL(TRIM(UNIT_PRICE::text), '^^') 
            , '||', IFNULL(TRIM(SVC_COMPLETION_NOTIF_SENT::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_ID::text), '^^') 
            , '||', IFNULL(TRIM(UDA_TEMPLATE_ID::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE5::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE4::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE7::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE6::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE1::text), '^^') 
            , '||', IFNULL(TRIM(AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE3::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE2::text), '^^') 
            , '||', IFNULL(TRIM(FROM_LINE_LOCATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(BASE_UNIT_PRICE::text), '^^') 
            , '||', IFNULL(TRIM(GROUP_LINE_ID::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE9::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE8::text), '^^') 
            , '||', IFNULL(TRIM(MAX_ORDER_QUANTITY::text), '^^') 
            , '||', IFNULL(TRIM(UNORDERED_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(NOT_TO_EXCEED_PRICE::text), '^^') 
            , '||', IFNULL(TRIM(ALLOW_PRICE_OVERRIDE_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE3::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE2::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE1::text), '^^') 
            , '||', IFNULL(TRIM(CONTRACT_NUM::text), '^^') 
            , '||', IFNULL(TRIM(VENDOR_PRODUCT_NUM::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_ID::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE9::text), '^^') 
            , '||', IFNULL(TRIM(SECONDARY_QTY::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE8::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE7::text), '^^') 
            , '||', IFNULL(TRIM(USSGL_TRANSACTION_CODE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE6::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE5::text), '^^') 
            , '||', IFNULL(TRIM(AUCTION_DISPLAY_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE4::text), '^^') 
            , '||', IFNULL(TRIM(CLM_EXERCISED_DATE::text), '^^') 
            , '||', IFNULL(TRIM(SECONDARY_UNIT_OF_MEASURE::text), '^^') 
            , '||', IFNULL(TRIM(EXPIRATION_DATE::text), '^^') 
            , '||', IFNULL(TRIM(BASE_QTY::text), '^^') 
            , '||', IFNULL(TRIM(NOTE_TO_VENDOR::text), '^^') 
            , '||', IFNULL(TRIM(TASK_ID::text), '^^') 
            , '||', IFNULL(TRIM(PROGRESS_PAYMENT_RATE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE10::text), '^^') 
            , '||', IFNULL(TRIM(CLM_OPTION_FROM_DATE::text), '^^') 
            , '||', IFNULL(TRIM(JOB_ID::text), '^^') 
            , '||', IFNULL(TRIM(OKE_CONTRACT_HEADER_ID::text), '^^') 
            , '||', IFNULL(TRIM(AUCTION_LINE_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(CAPITAL_EXPENSE_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE14::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE13::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE12::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE11::text), '^^') 
            , '||', IFNULL(TRIM(CANCEL_REASON::text), '^^') 
            , '||', IFNULL(TRIM(CONTRACTOR_FIRST_NAME::text), '^^') 
            , '||', IFNULL(TRIM(FROM_LINE_ID::text), '^^') 
            , '||', IFNULL(TRIM(TAX_CODE_ID::text), '^^') 
            , '||', IFNULL(TRIM(CLM_FUNDED_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(MIN_ORDER_QUANTITY::text), '^^') 
            , '||', IFNULL(TRIM(CLM_OPTION_TO_DATE::text), '^^') 
            , '||', IFNULL(TRIM(CLOSED_BY::text), '^^') 
            , '||', IFNULL(TRIM(COMMITTED_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(PROJECT_ID::text), '^^') 
            , '||', IFNULL(TRIM(SUPPLIER_REF_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(TAX_NAME::text), '^^') 
            , '||', IFNULL(TRIM(FROM_HEADER_ID::text), '^^') 
            , '||', IFNULL(TRIM(CATALOG_NAME::text), '^^') 
            , '||', IFNULL(TRIM(CLOSED_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_REVISION::text), '^^') 
            , '||', IFNULL(TRIM(FIRM_DATE::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE20::text), '^^') 
            , '||', IFNULL(TRIM(ORDER_TYPE_LOOKUP_CODE::text), '^^') 
            , '||', IFNULL(TRIM(START_DATE::text), '^^') 
            , '||', IFNULL(TRIM(REFERENCE_NUM::text), '^^') 
            , '||', IFNULL(TRIM(MIN_RELEASE_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(SUPPLIER_PART_AUXID::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATED_PROGRAM::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE17::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE18::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE15::text), '^^') 
            , '||', IFNULL(TRIM(QUANTITY_COMMITTED::text), '^^') 
            , '||', IFNULL(TRIM(CANCEL_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE16::text), '^^') 
            , '||', IFNULL(TRIM(MAX_RETAINAGE_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE13::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE14::text), '^^') 
            , '||', IFNULL(TRIM(BID_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE11::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE12::text), '^^') 
            , '||', IFNULL(TRIM(CLM_OPTION_INDICATOR::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE15::text), '^^') 
            , '||', IFNULL(TRIM(TAXABLE_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE19::text), '^^') 
            , '||', IFNULL(TRIM(CLOSED_REASON::text), '^^') 
            , '||', IFNULL(TRIM(QUANTITY::text), '^^') 
            , '||', IFNULL(TRIM(USER_HOLD_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(SECONDARY_UOM::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE10::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_DESCRIPTION::text), '^^') 
            , '||', IFNULL(TRIM(CONTRACTOR_LAST_NAME::text), '^^') 
            , '||', IFNULL(TRIM(SVC_AMOUNT_NOTIF_SENT::text), '^^') 
            , '||', IFNULL(TRIM(RECOUPMENT_RATE::text), '^^') 
            , '||', IFNULL(TRIM(CLM_BASE_LINE_NUM::text), '^^') 
            , '||', IFNULL(TRIM(CLM_IDC_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(BASE_UOM::text), '^^') 
            , '||', IFNULL(TRIM(COST_CONSTRAINT::text), '^^') 
            , '||', IFNULL(TRIM(MARKET_PRICE::text), '^^') 
            , '||', IFNULL(TRIM(CREATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(TRANSACTION_REASON_CODE::text), '^^') 
            , '||', IFNULL(TRIM(CANCELLED_BY::text), '^^') 
            , '||', IFNULL(TRIM(LINE_REFERENCE_NUM::text), '^^') 
            , '||', IFNULL(TRIM(SECONDARY_QUANTITY::text), '^^') 
            , '||', IFNULL(TRIM(LINE_NUM_DISPLAY::text), '^^') 
            , '||', IFNULL(TRIM(CONTRACT_ID::text), '^^') 
            , '||', IFNULL(TRIM(HAZARD_CLASS_ID::text), '^^') 
            , '||', IFNULL(TRIM(CLM_OPTION_NUM::text), '^^') 
            , '||', IFNULL(TRIM(CONTRACT_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(CLM_INFO_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(AUCTION_HEADER_ID::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_APPLICATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(GOVERNMENT_CONTEXT::text), '^^') 
            , '||', IFNULL(TRIM(LINE_TYPE_ID::text), '^^') 
            , '||', IFNULL(TRIM(UNIT_MEAS_LOOKUP_CODE::text), '^^') 
            , '||', IFNULL(TRIM(PREFERRED_GRADE::text), '^^') 
            , '||', IFNULL(TRIM(MATCHING_BASIS::text), '^^') 
            , '||', IFNULL(TRIM(REQUEST_ID::text), '^^') 
            , '||', IFNULL(TRIM(FIRM_STATUS_LOOKUP_CODE::text), '^^') 
            , '||', IFNULL(TRIM(MANUAL_PRICE_CHANGE_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(BID_LINE_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(USER_DOCUMENT_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(CLOSED_CODE::text), '^^') 
            , '||', IFNULL(TRIM(TYPE_1099::text), '^^') 
            , '||', IFNULL(TRIM(LIST_PRICE_PER_UNIT::text), '^^') 
            , '||', IFNULL(TRIM(NEGOTIATED_BY_PREPARER_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(QC_GRADE::text), '^^') 
            , '||', IFNULL(TRIM(DRAFT_ID::text), '^^') 
            , '||', IFNULL(TRIM(QTY_RCV_TOLERANCE::text), '^^') 
            , '||', IFNULL(TRIM(TAX_ATTRIBUTE_UPDATE_CODE::text), '^^') 
            , '||', IFNULL(TRIM(PRICE_TYPE_LOOKUP_CODE::text), '^^') 
            , '||', IFNULL(TRIM(OVER_TOLERANCE_ERROR_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(PURCHASE_BASIS::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_LOGIN::text), '^^') 
            , '||', IFNULL(TRIM(RETAINAGE_RATE::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(UN_NUMBER_ID::text), '^^') 
            , '||', IFNULL(TRIM(CLM_EXERCISED_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(IP_CATEGORY_ID::text), '^^') 
            , '||', IFNULL(TRIM(PO_LINE_ID::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_UPDATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(CLOSED_DATE::text), '^^') 
            , '||', IFNULL(TRIM(CANCEL_DATE::text), '^^') 
            , '||', IFNULL(TRIM(RETROACTIVE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(CREATION_DATE::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
