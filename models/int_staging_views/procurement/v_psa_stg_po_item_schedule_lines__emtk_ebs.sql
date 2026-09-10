---- SRC LAYER ----
WITH
SRC_SRC            as ( SELECT * FROM {{ source('emtk_ebs_po', 'po_line_locations_all') }} as SRC  ),
SRC_LINES          as ( SELECT LINE_NUM, PO_LINE_ID FROM {{ source('emtk_ebs_po', 'po_lines_all') }} as SRC 
                        QUALIFY ROW_NUMBER() OVER(PARTITION BY PO_LINE_ID ORDER BY _FIVETRAN_SYNCED DESC) = 1 ),
SRC_ref_bkcc       as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC 
                        WHERE rec_src = 'USWIOC.ORCL.EBSEMTK.PO_LINE_LOCATIONS_ALL' )

/*
SRC_SRC            as ( SELECT * FROM emtk_ebs_po.po_line_locations_all )
SRC_LINES          as ( SELECT * FROM emtk_ebs_po.po_lines_all )
SRC_ref_bkcc       as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_SRC as (
    SELECT
        PO_HEADER_ID::TEXT                                                 as                                       PO_HEADER_BK
      , LINE_LOCATION_ID
      , LAST_UPDATE_DATE
      , LAST_UPDATED_BY
      , PO_HEADER_ID
      , PO_LINE_ID
      , LAST_UPDATE_LOGIN
      , CREATION_DATE
      , CREATED_BY
      , QUANTITY
      , QUANTITY_RECEIVED
      , QUANTITY_ACCEPTED
      , QUANTITY_REJECTED
      , QUANTITY_BILLED
      , QUANTITY_CANCELLED
      , UNIT_MEAS_LOOKUP_CODE
      , PO_RELEASE_ID
      , SHIP_TO_LOCATION_ID
      , SHIP_VIA_LOOKUP_CODE
      , NEED_BY_DATE
      , PROMISED_DATE
      , LAST_ACCEPT_DATE
      , PRICE_OVERRIDE
      , ENCUMBERED_FLAG
      , ENCUMBERED_DATE
      , UNENCUMBERED_QUANTITY
      , FOB_LOOKUP_CODE
      , FREIGHT_TERMS_LOOKUP_CODE
      , TAXABLE_FLAG
      , TAX_NAME
      , ESTIMATED_TAX_AMOUNT
      , FROM_HEADER_ID
      , FROM_LINE_ID
      , FROM_LINE_LOCATION_ID
      , START_DATE
      , END_DATE
      , LEAD_TIME
      , LEAD_TIME_UNIT
      , PRICE_DISCOUNT
      , TERMS_ID
      , APPROVED_FLAG
      , APPROVED_DATE
      , CLOSED_FLAG
      , CANCEL_FLAG
      , CANCELLED_BY
      , CANCEL_DATE
      , FIRM_STATUS_LOOKUP_CODE
      , FIRM_DATE
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
      , UNIT_OF_MEASURE_CLASS
      , ENCUMBER_NOW
      , ATTRIBUTE11
      , ATTRIBUTE12
      , ATTRIBUTE13
      , ATTRIBUTE14
      , ATTRIBUTE15
      , INSPECTION_REQUIRED_FLAG
      , RECEIPT_REQUIRED_FLAG
      , QTY_RCV_TOLERANCE
      , QTY_RCV_EXCEPTION_CODE
      , ENFORCE_SHIP_TO_LOCATION_CODE
      , ALLOW_SUBSTITUTE_RECEIPTS_FLAG
      , DAYS_EARLY_RECEIPT_ALLOWED
      , DAYS_LATE_RECEIPT_ALLOWED
      , RECEIPT_DAYS_EXCEPTION_CODE
      , INVOICE_CLOSE_TOLERANCE
      , RECEIVE_CLOSE_TOLERANCE
      , SHIP_TO_ORGANIZATION_ID
      , SHIPMENT_NUM
      , SOURCE_SHIPMENT_ID
      , SHIPMENT_TYPE
      , CLOSED_CODE
      , REQUEST_ID
      , PROGRAM_APPLICATION_ID
      , PROGRAM_ID
      , PROGRAM_UPDATE_DATE
      , USSGL_TRANSACTION_CODE
      , GOVERNMENT_CONTEXT
      , RECEIVING_ROUTING_ID
      , ACCRUE_ON_RECEIPT_FLAG
      , CLOSED_DATE
      , CLOSED_BY
      , ORG_ID
      , QUANTITY_SHIPPED
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
      , COUNTRY_OF_ORIGIN_CODE
      , TAX_USER_OVERRIDE_FLAG
      , MATCH_OPTION
      , TAX_CODE_ID
      , CALCULATE_TAX_FLAG
      , CHANGE_PROMISED_DATE_REASON
      , NOTE_TO_RECEIVER
      , SECONDARY_QUANTITY
      , SECONDARY_UNIT_OF_MEASURE
      , PREFERRED_GRADE
      , SECONDARY_QUANTITY_RECEIVED
      , SECONDARY_QUANTITY_ACCEPTED
      , SECONDARY_QUANTITY_REJECTED
      , SECONDARY_QUANTITY_CANCELLED
      , VMI_FLAG
      , CONSIGNED_FLAG
      , RETROACTIVE_DATE
      , SUPPLIER_ORDER_LINE_NUMBER
      , AMOUNT
      , AMOUNT_RECEIVED
      , AMOUNT_BILLED
      , AMOUNT_CANCELLED
      , AMOUNT_REJECTED
      , AMOUNT_ACCEPTED
      , DROP_SHIP_FLAG
      , SALES_ORDER_UPDATE_DATE
      , TRANSACTION_FLOW_HEADER_ID
      , FINAL_MATCH_FLAG
      , MANUAL_PRICE_CHANGE_FLAG
      , SHIPMENT_CLOSED_DATE
      , CLOSED_FOR_RECEIVING_DATE
      , CLOSED_FOR_INVOICE_DATE
      , SECONDARY_QUANTITY_SHIPPED
      , VALUE_BASIS
      , MATCHING_BASIS
      , PAYMENT_TYPE
      , DESCRIPTION
      , WORK_APPROVER_ID
      , BID_PAYMENT_ID
      , QUANTITY_FINANCED
      , AMOUNT_FINANCED
      , QUANTITY_RECOUPED
      , AMOUNT_RECOUPED
      , RETAINAGE_WITHHELD_AMOUNT
      , RETAINAGE_RELEASED_AMOUNT
      , AMOUNT_SHIPPED
      , TAX_ATTRIBUTE_UPDATE_CODE
      , ORIGINAL_SHIPMENT_ID
      , LCM_FLAG
      , UDA_TEMPLATE_ID
      , DRAFT_ID
      , CLM_PERIOD_PERF_END_DATE
      , CLM_PERIOD_PERF_START_DATE
      , REVISION_NUM
      , CLM_DELIVERY_PERIOD
      , CLM_DELIVERY_PERIOD_UOM
      , CLM_POP_DURATION
      , CLM_POP_DURATION_UOM
      , CLM_PROMISE_PERIOD
      , CLM_PROMISE_PERIOD_UOM
      , CANCEL_REASON_1
      , OUTSOURCED_ASSEMBLY_1
      , CLOSED_REASON_1
      , IGT_SCHEDULE_STATUS
      , ADVANCE_PAYMENT_INDICATOR
      , _FIVETRAN_ID
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED)                        as                                           LOAD_DTS
    FROM SRC_SRC
)

, LOGIC_LINES as (
    SELECT
        PO_LINE_ID                                                   as                                   LINES_PO_LINE_ID
      , LINE_NUM
    FROM SRC_LINES
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
    /*Using inner join below with master po line table. 
    To exclude the orphan records that are left behind in locations once the line is deleted as confirmed with business*/
    INNER JOIN LOGIC_LINES
        ON PO_LINE_ID = LOGIC_LINES.LINES_PO_LINE_ID
    INNER JOIN LOGIC_ref_bkcc
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          LINE_NUM::TEXT                                                     as PO_ITEM_BK
        , PO_HEADER_BK
        , LINE_LOCATION_ID
        , LAST_UPDATE_DATE
        , LAST_UPDATED_BY
        , PO_HEADER_ID
        , PO_LINE_ID
        , LAST_UPDATE_LOGIN
        , CREATION_DATE
        , CREATED_BY
        , QUANTITY
        , QUANTITY_RECEIVED
        , QUANTITY_ACCEPTED
        , QUANTITY_REJECTED
        , QUANTITY_BILLED
        , QUANTITY_CANCELLED
        , UNIT_MEAS_LOOKUP_CODE
        , PO_RELEASE_ID
        , SHIP_TO_LOCATION_ID
        , SHIP_VIA_LOOKUP_CODE
        , NEED_BY_DATE
        , PROMISED_DATE
        , LAST_ACCEPT_DATE
        , PRICE_OVERRIDE
        , ENCUMBERED_FLAG
        , ENCUMBERED_DATE
        , UNENCUMBERED_QUANTITY
        , FOB_LOOKUP_CODE
        , FREIGHT_TERMS_LOOKUP_CODE
        , TAXABLE_FLAG
        , TAX_NAME
        , ESTIMATED_TAX_AMOUNT
        , FROM_HEADER_ID
        , FROM_LINE_ID
        , FROM_LINE_LOCATION_ID
        , START_DATE
        , END_DATE
        , LEAD_TIME
        , LEAD_TIME_UNIT
        , PRICE_DISCOUNT
        , TERMS_ID
        , APPROVED_FLAG
        , APPROVED_DATE
        , CLOSED_FLAG
        , CANCEL_FLAG
        , CANCELLED_BY
        , CANCEL_DATE
        , FIRM_STATUS_LOOKUP_CODE
        , FIRM_DATE
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
        , UNIT_OF_MEASURE_CLASS
        , ENCUMBER_NOW
        , ATTRIBUTE11
        , ATTRIBUTE12
        , ATTRIBUTE13
        , ATTRIBUTE14
        , ATTRIBUTE15
        , INSPECTION_REQUIRED_FLAG
        , RECEIPT_REQUIRED_FLAG
        , QTY_RCV_TOLERANCE
        , QTY_RCV_EXCEPTION_CODE
        , ENFORCE_SHIP_TO_LOCATION_CODE
        , ALLOW_SUBSTITUTE_RECEIPTS_FLAG
        , DAYS_EARLY_RECEIPT_ALLOWED
        , DAYS_LATE_RECEIPT_ALLOWED
        , RECEIPT_DAYS_EXCEPTION_CODE
        , INVOICE_CLOSE_TOLERANCE
        , RECEIVE_CLOSE_TOLERANCE
        , SHIP_TO_ORGANIZATION_ID
        , SHIPMENT_NUM
        , SOURCE_SHIPMENT_ID
        , SHIPMENT_TYPE
        , CLOSED_CODE
        , REQUEST_ID
        , PROGRAM_APPLICATION_ID
        , PROGRAM_ID
        , PROGRAM_UPDATE_DATE
        , USSGL_TRANSACTION_CODE
        , GOVERNMENT_CONTEXT
        , RECEIVING_ROUTING_ID
        , ACCRUE_ON_RECEIPT_FLAG
        , CLOSED_DATE
        , CLOSED_BY
        , ORG_ID
        , QUANTITY_SHIPPED
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
        , COUNTRY_OF_ORIGIN_CODE
        , TAX_USER_OVERRIDE_FLAG
        , MATCH_OPTION
        , TAX_CODE_ID
        , CALCULATE_TAX_FLAG
        , CHANGE_PROMISED_DATE_REASON
        , NOTE_TO_RECEIVER
        , SECONDARY_QUANTITY
        , SECONDARY_UNIT_OF_MEASURE
        , PREFERRED_GRADE
        , SECONDARY_QUANTITY_RECEIVED
        , SECONDARY_QUANTITY_ACCEPTED
        , SECONDARY_QUANTITY_REJECTED
        , SECONDARY_QUANTITY_CANCELLED
        , VMI_FLAG
        , CONSIGNED_FLAG
        , RETROACTIVE_DATE
        , SUPPLIER_ORDER_LINE_NUMBER
        , AMOUNT
        , AMOUNT_RECEIVED
        , AMOUNT_BILLED
        , AMOUNT_CANCELLED
        , AMOUNT_REJECTED
        , AMOUNT_ACCEPTED
        , DROP_SHIP_FLAG
        , SALES_ORDER_UPDATE_DATE
        , TRANSACTION_FLOW_HEADER_ID
        , FINAL_MATCH_FLAG
        , MANUAL_PRICE_CHANGE_FLAG
        , SHIPMENT_CLOSED_DATE
        , CLOSED_FOR_RECEIVING_DATE
        , CLOSED_FOR_INVOICE_DATE
        , SECONDARY_QUANTITY_SHIPPED
        , VALUE_BASIS
        , MATCHING_BASIS
        , PAYMENT_TYPE
        , DESCRIPTION
        , WORK_APPROVER_ID
        , BID_PAYMENT_ID
        , QUANTITY_FINANCED
        , AMOUNT_FINANCED
        , QUANTITY_RECOUPED
        , AMOUNT_RECOUPED
        , RETAINAGE_WITHHELD_AMOUNT
        , RETAINAGE_RELEASED_AMOUNT
        , AMOUNT_SHIPPED
        , TAX_ATTRIBUTE_UPDATE_CODE
        , ORIGINAL_SHIPMENT_ID
        , LCM_FLAG
        , UDA_TEMPLATE_ID
        , DRAFT_ID
        , CLM_PERIOD_PERF_END_DATE
        , CLM_PERIOD_PERF_START_DATE
        , REVISION_NUM
        , CLM_DELIVERY_PERIOD
        , CLM_DELIVERY_PERIOD_UOM
        , CLM_POP_DURATION
        , CLM_POP_DURATION_UOM
        , CLM_PROMISE_PERIOD
        , CLM_PROMISE_PERIOD_UOM
        , CANCEL_REASON_1
        , OUTSOURCED_ASSEMBLY_1
        , CLOSED_REASON_1
        , IGT_SCHEDULE_STATUS
        , ADVANCE_PAYMENT_INDICATOR
        , LINES_PO_LINE_ID
        , LINE_NUM
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
          COALESCE(NULLIF(TRIM(CAST(PO_HEADER_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(LINE_NUM as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PO_ITEM_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PO_HEADER_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PO_HEADER_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(LAST_UPDATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(PO_HEADER_ID::text), '^^') 
            , '||', IFNULL(TRIM(PO_LINE_ID::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_LOGIN::text), '^^') 
            , '||', IFNULL(TRIM(CREATION_DATE::text), '^^') 
            , '||', IFNULL(TRIM(CREATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(QUANTITY::text), '^^') 
            , '||', IFNULL(TRIM(QUANTITY_RECEIVED::text), '^^') 
            , '||', IFNULL(TRIM(QUANTITY_ACCEPTED::text), '^^') 
            , '||', IFNULL(TRIM(QUANTITY_REJECTED::text), '^^') 
            , '||', IFNULL(TRIM(QUANTITY_BILLED::text), '^^') 
            , '||', IFNULL(TRIM(QUANTITY_CANCELLED::text), '^^') 
            , '||', IFNULL(TRIM(UNIT_MEAS_LOOKUP_CODE::text), '^^') 
            , '||', IFNULL(TRIM(PO_RELEASE_ID::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_TO_LOCATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_VIA_LOOKUP_CODE::text), '^^') 
            , '||', IFNULL(TRIM(NEED_BY_DATE::text), '^^') 
            , '||', IFNULL(TRIM(PROMISED_DATE::text), '^^') 
            , '||', IFNULL(TRIM(LAST_ACCEPT_DATE::text), '^^') 
            , '||', IFNULL(TRIM(PRICE_OVERRIDE::text), '^^') 
            , '||', IFNULL(TRIM(ENCUMBERED_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(ENCUMBERED_DATE::text), '^^') 
            , '||', IFNULL(TRIM(UNENCUMBERED_QUANTITY::text), '^^') 
            , '||', IFNULL(TRIM(FOB_LOOKUP_CODE::text), '^^') 
            , '||', IFNULL(TRIM(FREIGHT_TERMS_LOOKUP_CODE::text), '^^') 
            , '||', IFNULL(TRIM(TAXABLE_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(TAX_NAME::text), '^^') 
            , '||', IFNULL(TRIM(ESTIMATED_TAX_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(FROM_HEADER_ID::text), '^^') 
            , '||', IFNULL(TRIM(FROM_LINE_ID::text), '^^') 
            , '||', IFNULL(TRIM(FROM_LINE_LOCATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(START_DATE::text), '^^') 
            , '||', IFNULL(TRIM(END_DATE::text), '^^') 
            , '||', IFNULL(TRIM(LEAD_TIME::text), '^^') 
            , '||', IFNULL(TRIM(LEAD_TIME_UNIT::text), '^^') 
            , '||', IFNULL(TRIM(PRICE_DISCOUNT::text), '^^') 
            , '||', IFNULL(TRIM(TERMS_ID::text), '^^') 
            , '||', IFNULL(TRIM(APPROVED_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(APPROVED_DATE::text), '^^') 
            , '||', IFNULL(TRIM(CLOSED_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(CANCEL_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(CANCELLED_BY::text), '^^') 
            , '||', IFNULL(TRIM(CANCEL_DATE::text), '^^') 
            , '||', IFNULL(TRIM(FIRM_STATUS_LOOKUP_CODE::text), '^^') 
            , '||', IFNULL(TRIM(FIRM_DATE::text), '^^') 
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
            , '||', IFNULL(TRIM(UNIT_OF_MEASURE_CLASS::text), '^^') 
            , '||', IFNULL(TRIM(ENCUMBER_NOW::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE11::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE12::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE13::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE14::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE15::text), '^^') 
            , '||', IFNULL(TRIM(INSPECTION_REQUIRED_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(RECEIPT_REQUIRED_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(QTY_RCV_TOLERANCE::text), '^^') 
            , '||', IFNULL(TRIM(QTY_RCV_EXCEPTION_CODE::text), '^^') 
            , '||', IFNULL(TRIM(ENFORCE_SHIP_TO_LOCATION_CODE::text), '^^') 
            , '||', IFNULL(TRIM(ALLOW_SUBSTITUTE_RECEIPTS_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(DAYS_EARLY_RECEIPT_ALLOWED::text), '^^') 
            , '||', IFNULL(TRIM(DAYS_LATE_RECEIPT_ALLOWED::text), '^^') 
            , '||', IFNULL(TRIM(RECEIPT_DAYS_EXCEPTION_CODE::text), '^^') 
            , '||', IFNULL(TRIM(INVOICE_CLOSE_TOLERANCE::text), '^^') 
            , '||', IFNULL(TRIM(RECEIVE_CLOSE_TOLERANCE::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_TO_ORGANIZATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(SHIPMENT_NUM::text), '^^') 
            , '||', IFNULL(TRIM(SOURCE_SHIPMENT_ID::text), '^^') 
            , '||', IFNULL(TRIM(SHIPMENT_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(CLOSED_CODE::text), '^^') 
            , '||', IFNULL(TRIM(REQUEST_ID::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_APPLICATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_ID::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_UPDATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(USSGL_TRANSACTION_CODE::text), '^^') 
            , '||', IFNULL(TRIM(GOVERNMENT_CONTEXT::text), '^^') 
            , '||', IFNULL(TRIM(RECEIVING_ROUTING_ID::text), '^^') 
            , '||', IFNULL(TRIM(ACCRUE_ON_RECEIPT_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(CLOSED_DATE::text), '^^') 
            , '||', IFNULL(TRIM(CLOSED_BY::text), '^^') 
            , '||', IFNULL(TRIM(ORG_ID::text), '^^') 
            , '||', IFNULL(TRIM(QUANTITY_SHIPPED::text), '^^') 
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
            , '||', IFNULL(TRIM(COUNTRY_OF_ORIGIN_CODE::text), '^^') 
            , '||', IFNULL(TRIM(TAX_USER_OVERRIDE_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(MATCH_OPTION::text), '^^') 
            , '||', IFNULL(TRIM(TAX_CODE_ID::text), '^^') 
            , '||', IFNULL(TRIM(CALCULATE_TAX_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(CHANGE_PROMISED_DATE_REASON::text), '^^') 
            , '||', IFNULL(TRIM(NOTE_TO_RECEIVER::text), '^^') 
            , '||', IFNULL(TRIM(SECONDARY_QUANTITY::text), '^^') 
            , '||', IFNULL(TRIM(SECONDARY_UNIT_OF_MEASURE::text), '^^') 
            , '||', IFNULL(TRIM(PREFERRED_GRADE::text), '^^') 
            , '||', IFNULL(TRIM(SECONDARY_QUANTITY_RECEIVED::text), '^^') 
            , '||', IFNULL(TRIM(SECONDARY_QUANTITY_ACCEPTED::text), '^^') 
            , '||', IFNULL(TRIM(SECONDARY_QUANTITY_REJECTED::text), '^^') 
            , '||', IFNULL(TRIM(SECONDARY_QUANTITY_CANCELLED::text), '^^') 
            , '||', IFNULL(TRIM(VMI_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(CONSIGNED_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(RETROACTIVE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(SUPPLIER_ORDER_LINE_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(AMOUNT_RECEIVED::text), '^^') 
            , '||', IFNULL(TRIM(AMOUNT_BILLED::text), '^^') 
            , '||', IFNULL(TRIM(AMOUNT_CANCELLED::text), '^^') 
            , '||', IFNULL(TRIM(AMOUNT_REJECTED::text), '^^') 
            , '||', IFNULL(TRIM(AMOUNT_ACCEPTED::text), '^^') 
            , '||', IFNULL(TRIM(DROP_SHIP_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(SALES_ORDER_UPDATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(TRANSACTION_FLOW_HEADER_ID::text), '^^') 
            , '||', IFNULL(TRIM(FINAL_MATCH_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(MANUAL_PRICE_CHANGE_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(SHIPMENT_CLOSED_DATE::text), '^^') 
            , '||', IFNULL(TRIM(CLOSED_FOR_RECEIVING_DATE::text), '^^') 
            , '||', IFNULL(TRIM(CLOSED_FOR_INVOICE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(SECONDARY_QUANTITY_SHIPPED::text), '^^') 
            , '||', IFNULL(TRIM(VALUE_BASIS::text), '^^') 
            , '||', IFNULL(TRIM(MATCHING_BASIS::text), '^^') 
            , '||', IFNULL(TRIM(PAYMENT_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(DESCRIPTION::text), '^^') 
            , '||', IFNULL(TRIM(WORK_APPROVER_ID::text), '^^') 
            , '||', IFNULL(TRIM(BID_PAYMENT_ID::text), '^^') 
            , '||', IFNULL(TRIM(QUANTITY_FINANCED::text), '^^') 
            , '||', IFNULL(TRIM(AMOUNT_FINANCED::text), '^^') 
            , '||', IFNULL(TRIM(QUANTITY_RECOUPED::text), '^^') 
            , '||', IFNULL(TRIM(AMOUNT_RECOUPED::text), '^^') 
            , '||', IFNULL(TRIM(RETAINAGE_WITHHELD_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(RETAINAGE_RELEASED_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(AMOUNT_SHIPPED::text), '^^') 
            , '||', IFNULL(TRIM(TAX_ATTRIBUTE_UPDATE_CODE::text), '^^') 
            , '||', IFNULL(TRIM(ORIGINAL_SHIPMENT_ID::text), '^^') 
            , '||', IFNULL(TRIM(LCM_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(UDA_TEMPLATE_ID::text), '^^') 
            , '||', IFNULL(TRIM(DRAFT_ID::text), '^^') 
            , '||', IFNULL(TRIM(CLM_PERIOD_PERF_END_DATE::text), '^^') 
            , '||', IFNULL(TRIM(CLM_PERIOD_PERF_START_DATE::text), '^^') 
            , '||', IFNULL(TRIM(REVISION_NUM::text), '^^') 
            , '||', IFNULL(TRIM(CLM_DELIVERY_PERIOD::text), '^^') 
            , '||', IFNULL(TRIM(CLM_DELIVERY_PERIOD_UOM::text), '^^') 
            , '||', IFNULL(TRIM(CLM_POP_DURATION::text), '^^') 
            , '||', IFNULL(TRIM(CLM_POP_DURATION_UOM::text), '^^') 
            , '||', IFNULL(TRIM(CLM_PROMISE_PERIOD::text), '^^') 
            , '||', IFNULL(TRIM(CLM_PROMISE_PERIOD_UOM::text), '^^') 
            , '||', IFNULL(TRIM(CANCEL_REASON_1::text), '^^') 
            , '||', IFNULL(TRIM(OUTSOURCED_ASSEMBLY_1::text), '^^') 
            , '||', IFNULL(TRIM(CLOSED_REASON_1::text), '^^') 
            , '||', IFNULL(TRIM(IGT_SCHEDULE_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(ADVANCE_PAYMENT_INDICATOR::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
