---- SRC LAYER ----
WITH
SRC_SRC            as ( SELECT * FROM {{ source('ml_ebs_po', 'po_line_locations_all') }} as SRC  ),
SRC_LINES          as ( SELECT LINE_NUM, PO_LINE_ID FROM {{ source('ml_ebs_po', 'po_lines_all') }} as SRC 
                        QUALIFY ROW_NUMBER() OVER(PARTITION BY PO_LINE_ID ORDER BY _FIVETRAN_SYNCED DESC) = 1 ),
SRC_ref_bkcc       as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC 
                        WHERE rec_src = 'USWIOC.ORCL.EBSPRD.PO_LINE_LOCATIONS_ALL' )

/*
SRC_SRC            as ( SELECT * FROM ml_ebs_po.po_line_locations_all )
SRC_LINES          as ( SELECT * FROM ml_ebs_po.po_lines_all )
SRC_ref_bkcc       as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_SRC as (
    SELECT
        PO_HEADER_ID::TEXT                                                 as                                       PO_HEADER_BK
      , ORG_ID
      , FREIGHT_TERMS_LOOKUP_CODE
      , APPROVED_FLAG
      , ESTIMATED_TAX_AMOUNT
      , PROGRAM_ID
      , GLOBAL_ATTRIBUTE5
      , UDA_TEMPLATE_ID
      , BID_PAYMENT_ID
      , GLOBAL_ATTRIBUTE4
      , QUANTITY_ACCEPTED
      , GLOBAL_ATTRIBUTE7
      , GLOBAL_ATTRIBUTE6
      , GLOBAL_ATTRIBUTE1
      , QUANTITY_RECOUPED
      , PRICE_OVERRIDE
      , AMOUNT
      , GLOBAL_ATTRIBUTE3
      , GLOBAL_ATTRIBUTE2
      , FROM_LINE_LOCATION_ID
      , TAX_USER_OVERRIDE_FLAG
      , AMOUNT_ACCEPTED
      , GLOBAL_ATTRIBUTE9
      , GLOBAL_ATTRIBUTE8
      , ATTRIBUTE3
      , ATTRIBUTE2
      , DAYS_LATE_RECEIPT_ALLOWED
      , ATTRIBUTE1
      , ATTRIBUTE9
      , SALES_ORDER_UPDATE_DATE
      , ATTRIBUTE8
      , ATTRIBUTE7
      , USSGL_TRANSACTION_CODE
      , ATTRIBUTE6
      , QTY_RCV_EXCEPTION_CODE
      , ATTRIBUTE5
      , UNENCUMBERED_QUANTITY
      , ATTRIBUTE4
      , AMOUNT_BILLED
      , LEAD_TIME
      , SECONDARY_UNIT_OF_MEASURE
      , RECEIVE_CLOSE_TOLERANCE
      , ATTRIBUTE10
      , ATTRIBUTE14
      , ATTRIBUTE13
      , ATTRIBUTE12
      , ATTRIBUTE11
      , COUNTRY_OF_ORIGIN_CODE
      , SUPPLIER_ORDER_LINE_NUMBER
      , DROP_SHIP_FLAG
      , CANCEL_REASON
      , FROM_LINE_ID
      , TAX_CODE_ID
      , WORK_APPROVER_ID
      , DESCRIPTION
      , CLOSED_BY
      , TAX_NAME
      , QUANTITY_CANCELLED
      , FROM_HEADER_ID
      , CLOSED_FLAG
      , FIRM_DATE
      , GLOBAL_ATTRIBUTE20
      , START_DATE
      , SOURCE_SHIPMENT_ID
      , GLOBAL_ATTRIBUTE17
      , RETAINAGE_RELEASED_AMOUNT
      , GLOBAL_ATTRIBUTE18
      , CANCEL_FLAG
      , GLOBAL_ATTRIBUTE15
      , GLOBAL_ATTRIBUTE16
      , GLOBAL_ATTRIBUTE13
      , PO_HEADER_ID
      , GLOBAL_ATTRIBUTE14
      , GLOBAL_ATTRIBUTE11
      , GLOBAL_ATTRIBUTE12
      , CHANGE_PROMISED_DATE_REASON
      , ATTRIBUTE15
      , RECEIVING_ROUTING_ID
      , TAXABLE_FLAG
      , PRICE_DISCOUNT
      , SHIPMENT_TYPE
      , GLOBAL_ATTRIBUTE19
      , ORIGINAL_SHIPMENT_ID
      , CLOSED_REASON
      , QUANTITY
      , TRANSACTION_FLOW_HEADER_ID
      , END_DATE
      , GLOBAL_ATTRIBUTE10
      , ACCRUE_ON_RECEIPT_FLAG
      , LCM_FLAG
      , QUANTITY_RECEIVED
      , INSPECTION_REQUIRED_FLAG
      , SHIP_TO_LOCATION_ID
      , AMOUNT_RECEIVED
      , CREATED_BY
      , QUANTITY_SHIPPED
      , LAST_UPDATED_BY
      , CANCELLED_BY
      , SECONDARY_QUANTITY
      , SECONDARY_QUANTITY_REJECTED
      , RECEIPT_REQUIRED_FLAG
      , SHIPMENT_NUM
      , PO_RELEASE_ID
      , ENFORCE_SHIP_TO_LOCATION_CODE
      , PAYMENT_TYPE
      , TERMS_ID
      , CALCULATE_TAX_FLAG
      , CONSIGNED_FLAG
      , ENCUMBERED_FLAG
      , ATTRIBUTE_CATEGORY
      , PROGRAM_APPLICATION_ID
      , GOVERNMENT_CONTEXT
      , UNIT_MEAS_LOOKUP_CODE
      , PREFERRED_GRADE
      , OUTSOURCED_ASSEMBLY
      , MATCHING_BASIS
      , ALLOW_SUBSTITUTE_RECEIPTS_FLAG
      , SECONDARY_QUANTITY_ACCEPTED
      , QUANTITY_REJECTED
      , AMOUNT_SHIPPED
      , VALUE_BASIS
      , REQUEST_ID
      , VMI_FLAG
      , FIRM_STATUS_LOOKUP_CODE
      , MANUAL_PRICE_CHANGE_FLAG
      , NOTE_TO_RECEIVER
      , SECONDARY_QUANTITY_SHIPPED
      , ENCUMBER_NOW
      , RECEIPT_DAYS_EXCEPTION_CODE
      , INVOICE_CLOSE_TOLERANCE
      , CLOSED_CODE
      , SECONDARY_QUANTITY_RECEIVED
      , LEAD_TIME_UNIT
      , QUANTITY_FINANCED
      , AMOUNT_FINANCED
      , AMOUNT_REJECTED
      , DRAFT_ID
      , QTY_RCV_TOLERANCE
      , UNIT_OF_MEASURE_CLASS
      , TAX_ATTRIBUTE_UPDATE_CODE
      , AMOUNT_RECOUPED
      , ENCUMBERED_DATE
      , SECONDARY_QUANTITY_CANCELLED
      , MATCH_OPTION
      , LAST_UPDATE_LOGIN
      , AMOUNT_CANCELLED
      , GLOBAL_ATTRIBUTE_CATEGORY
      , SHIP_VIA_LOOKUP_CODE
      , FINAL_MATCH_FLAG
      , FOB_LOOKUP_CODE
      , LINE_LOCATION_ID
      , SHIP_TO_ORGANIZATION_ID
      , RETAINAGE_WITHHELD_AMOUNT
      , DAYS_EARLY_RECEIPT_ALLOWED
      , PO_LINE_ID
      , CLOSED_DATE
      , SHIPMENT_CLOSED_DATE
      , CREATION_DATE
      , APPROVED_DATE
      , PROGRAM_UPDATE_DATE
      , CLOSED_FOR_RECEIVING_DATE
      , NEED_BY_DATE
      , LAST_ACCEPT_DATE
      , CANCEL_DATE
      , CLOSED_FOR_INVOICE_DATE
      , RETROACTIVE_DATE
      , QUANTITY_BILLED
      , PROMISED_DATE
      , LAST_UPDATE_DATE
      , _FIVETRAN_DELETED
      , _FIVETRAN_ID
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      /*Updated the LOAD_DTS logic from _FIVETRAN_SYNCED to PSA_LOAD_DTS to resolve the duplicate issue caused by fivetran connector issue.
      We have historically(before Nov 2024) updated the PSA_LOAD_DTS field, so the duplicate issu does not come again  */
      , CONVERT_TIMEZONE('UTC', PSA_LOAD_DTS)                    as                                           LOAD_DTS
    FROM SRC_SRC
)

, LOGIC_LINES as (
    SELECT
        LINE_NUM::TEXT                                                     as                                   PO_ITEM_BK
      , LINE_NUM
      , PO_LINE_ID                                                   as                                   LINES_PO_LINE_ID
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
          PO_ITEM_BK
        , LINE_NUM
        , PO_HEADER_BK
        , ORG_ID
        , FREIGHT_TERMS_LOOKUP_CODE
        , APPROVED_FLAG
        , ESTIMATED_TAX_AMOUNT
        , PROGRAM_ID
        , GLOBAL_ATTRIBUTE5
        , UDA_TEMPLATE_ID
        , BID_PAYMENT_ID
        , GLOBAL_ATTRIBUTE4
        , QUANTITY_ACCEPTED
        , GLOBAL_ATTRIBUTE7
        , GLOBAL_ATTRIBUTE6
        , GLOBAL_ATTRIBUTE1
        , QUANTITY_RECOUPED
        , PRICE_OVERRIDE
        , AMOUNT
        , GLOBAL_ATTRIBUTE3
        , GLOBAL_ATTRIBUTE2
        , FROM_LINE_LOCATION_ID
        , TAX_USER_OVERRIDE_FLAG
        , AMOUNT_ACCEPTED
        , GLOBAL_ATTRIBUTE9
        , GLOBAL_ATTRIBUTE8
        , ATTRIBUTE3
        , ATTRIBUTE2
        , DAYS_LATE_RECEIPT_ALLOWED
        , ATTRIBUTE1
        , ATTRIBUTE9
        , SALES_ORDER_UPDATE_DATE
        , ATTRIBUTE8
        , ATTRIBUTE7
        , USSGL_TRANSACTION_CODE
        , ATTRIBUTE6
        , QTY_RCV_EXCEPTION_CODE
        , ATTRIBUTE5
        , UNENCUMBERED_QUANTITY
        , ATTRIBUTE4
        , AMOUNT_BILLED
        , LEAD_TIME
        , SECONDARY_UNIT_OF_MEASURE
        , RECEIVE_CLOSE_TOLERANCE
        , ATTRIBUTE10
        , ATTRIBUTE14
        , ATTRIBUTE13
        , ATTRIBUTE12
        , ATTRIBUTE11
        , COUNTRY_OF_ORIGIN_CODE
        , SUPPLIER_ORDER_LINE_NUMBER
        , DROP_SHIP_FLAG
        , CANCEL_REASON
        , FROM_LINE_ID
        , TAX_CODE_ID
        , WORK_APPROVER_ID
        , DESCRIPTION
        , CLOSED_BY
        , TAX_NAME
        , QUANTITY_CANCELLED
        , FROM_HEADER_ID
        , CLOSED_FLAG
        , FIRM_DATE
        , GLOBAL_ATTRIBUTE20
        , START_DATE
        , SOURCE_SHIPMENT_ID
        , GLOBAL_ATTRIBUTE17
        , RETAINAGE_RELEASED_AMOUNT
        , GLOBAL_ATTRIBUTE18
        , CANCEL_FLAG
        , GLOBAL_ATTRIBUTE15
        , GLOBAL_ATTRIBUTE16
        , GLOBAL_ATTRIBUTE13
        , PO_HEADER_ID
        , GLOBAL_ATTRIBUTE14
        , GLOBAL_ATTRIBUTE11
        , GLOBAL_ATTRIBUTE12
        , CHANGE_PROMISED_DATE_REASON
        , ATTRIBUTE15
        , RECEIVING_ROUTING_ID
        , TAXABLE_FLAG
        , PRICE_DISCOUNT
        , SHIPMENT_TYPE
        , GLOBAL_ATTRIBUTE19
        , ORIGINAL_SHIPMENT_ID
        , CLOSED_REASON
        , QUANTITY
        , TRANSACTION_FLOW_HEADER_ID
        , END_DATE
        , GLOBAL_ATTRIBUTE10
        , ACCRUE_ON_RECEIPT_FLAG
        , LCM_FLAG
        , QUANTITY_RECEIVED
        , INSPECTION_REQUIRED_FLAG
        , SHIP_TO_LOCATION_ID
        , AMOUNT_RECEIVED
        , CREATED_BY
        , QUANTITY_SHIPPED
        , LAST_UPDATED_BY
        , CANCELLED_BY
        , SECONDARY_QUANTITY
        , SECONDARY_QUANTITY_REJECTED
        , RECEIPT_REQUIRED_FLAG
        , SHIPMENT_NUM
        , PO_RELEASE_ID
        , ENFORCE_SHIP_TO_LOCATION_CODE
        , PAYMENT_TYPE
        , TERMS_ID
        , CALCULATE_TAX_FLAG
        , CONSIGNED_FLAG
        , ENCUMBERED_FLAG
        , ATTRIBUTE_CATEGORY
        , PROGRAM_APPLICATION_ID
        , GOVERNMENT_CONTEXT
        , UNIT_MEAS_LOOKUP_CODE
        , PREFERRED_GRADE
        , OUTSOURCED_ASSEMBLY
        , MATCHING_BASIS
        , ALLOW_SUBSTITUTE_RECEIPTS_FLAG
        , SECONDARY_QUANTITY_ACCEPTED
        , QUANTITY_REJECTED
        , AMOUNT_SHIPPED
        , VALUE_BASIS
        , REQUEST_ID
        , VMI_FLAG
        , FIRM_STATUS_LOOKUP_CODE
        , MANUAL_PRICE_CHANGE_FLAG
        , NOTE_TO_RECEIVER
        , SECONDARY_QUANTITY_SHIPPED
        , ENCUMBER_NOW
        , RECEIPT_DAYS_EXCEPTION_CODE
        , INVOICE_CLOSE_TOLERANCE
        , CLOSED_CODE
        , SECONDARY_QUANTITY_RECEIVED
        , LEAD_TIME_UNIT
        , QUANTITY_FINANCED
        , AMOUNT_FINANCED
        , AMOUNT_REJECTED
        , DRAFT_ID
        , QTY_RCV_TOLERANCE
        , UNIT_OF_MEASURE_CLASS
        , TAX_ATTRIBUTE_UPDATE_CODE
        , AMOUNT_RECOUPED
        , ENCUMBERED_DATE
        , SECONDARY_QUANTITY_CANCELLED
        , MATCH_OPTION
        , LAST_UPDATE_LOGIN
        , AMOUNT_CANCELLED
        , GLOBAL_ATTRIBUTE_CATEGORY
        , SHIP_VIA_LOOKUP_CODE
        , FINAL_MATCH_FLAG
        , FOB_LOOKUP_CODE
        , LINE_LOCATION_ID
        , SHIP_TO_ORGANIZATION_ID
        , RETAINAGE_WITHHELD_AMOUNT
        , DAYS_EARLY_RECEIPT_ALLOWED
        , PO_LINE_ID
        , CLOSED_DATE
        , SHIPMENT_CLOSED_DATE
        , CREATION_DATE
        , APPROVED_DATE
        , PROGRAM_UPDATE_DATE
        , CLOSED_FOR_RECEIVING_DATE
        , NEED_BY_DATE
        , LAST_ACCEPT_DATE
        , CANCEL_DATE
        , CLOSED_FOR_INVOICE_DATE
        , RETROACTIVE_DATE
        , QUANTITY_BILLED
        , PROMISED_DATE
        , LAST_UPDATE_DATE
        , LINES_PO_LINE_ID
        , _FIVETRAN_DELETED
        , _FIVETRAN_ID
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
              IFNULL(TRIM(ORG_ID::text), '^^') 
            , '||', IFNULL(TRIM(FREIGHT_TERMS_LOOKUP_CODE::text), '^^') 
            , '||', IFNULL(TRIM(APPROVED_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(ESTIMATED_TAX_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_ID::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE5::text), '^^') 
            , '||', IFNULL(TRIM(UDA_TEMPLATE_ID::text), '^^') 
            , '||', IFNULL(TRIM(BID_PAYMENT_ID::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE4::text), '^^') 
            , '||', IFNULL(TRIM(QUANTITY_ACCEPTED::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE7::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE6::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE1::text), '^^') 
            , '||', IFNULL(TRIM(QUANTITY_RECOUPED::text), '^^') 
            , '||', IFNULL(TRIM(PRICE_OVERRIDE::text), '^^') 
            , '||', IFNULL(TRIM(AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE3::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE2::text), '^^') 
            , '||', IFNULL(TRIM(FROM_LINE_LOCATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(TAX_USER_OVERRIDE_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(AMOUNT_ACCEPTED::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE9::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE8::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE3::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE2::text), '^^') 
            , '||', IFNULL(TRIM(DAYS_LATE_RECEIPT_ALLOWED::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE1::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE9::text), '^^') 
            , '||', IFNULL(TRIM(SALES_ORDER_UPDATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE8::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE7::text), '^^') 
            , '||', IFNULL(TRIM(USSGL_TRANSACTION_CODE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE6::text), '^^') 
            , '||', IFNULL(TRIM(QTY_RCV_EXCEPTION_CODE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE5::text), '^^') 
            , '||', IFNULL(TRIM(UNENCUMBERED_QUANTITY::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE4::text), '^^') 
            , '||', IFNULL(TRIM(AMOUNT_BILLED::text), '^^') 
            , '||', IFNULL(TRIM(LEAD_TIME::text), '^^') 
            , '||', IFNULL(TRIM(SECONDARY_UNIT_OF_MEASURE::text), '^^') 
            , '||', IFNULL(TRIM(RECEIVE_CLOSE_TOLERANCE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE10::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE14::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE13::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE12::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE11::text), '^^') 
            , '||', IFNULL(TRIM(COUNTRY_OF_ORIGIN_CODE::text), '^^') 
            , '||', IFNULL(TRIM(SUPPLIER_ORDER_LINE_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(DROP_SHIP_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(CANCEL_REASON::text), '^^') 
            , '||', IFNULL(TRIM(FROM_LINE_ID::text), '^^') 
            , '||', IFNULL(TRIM(TAX_CODE_ID::text), '^^') 
            , '||', IFNULL(TRIM(WORK_APPROVER_ID::text), '^^') 
            , '||', IFNULL(TRIM(DESCRIPTION::text), '^^') 
            , '||', IFNULL(TRIM(CLOSED_BY::text), '^^') 
            , '||', IFNULL(TRIM(TAX_NAME::text), '^^') 
            , '||', IFNULL(TRIM(QUANTITY_CANCELLED::text), '^^') 
            , '||', IFNULL(TRIM(FROM_HEADER_ID::text), '^^') 
            , '||', IFNULL(TRIM(CLOSED_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(FIRM_DATE::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE20::text), '^^') 
            , '||', IFNULL(TRIM(START_DATE::text), '^^') 
            , '||', IFNULL(TRIM(SOURCE_SHIPMENT_ID::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE17::text), '^^') 
            , '||', IFNULL(TRIM(RETAINAGE_RELEASED_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE18::text), '^^') 
            , '||', IFNULL(TRIM(CANCEL_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE15::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE16::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE13::text), '^^') 
            , '||', IFNULL(TRIM(PO_HEADER_ID::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE14::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE11::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE12::text), '^^') 
            , '||', IFNULL(TRIM(CHANGE_PROMISED_DATE_REASON::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE15::text), '^^') 
            , '||', IFNULL(TRIM(RECEIVING_ROUTING_ID::text), '^^') 
            , '||', IFNULL(TRIM(TAXABLE_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(PRICE_DISCOUNT::text), '^^') 
            , '||', IFNULL(TRIM(SHIPMENT_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE19::text), '^^') 
            , '||', IFNULL(TRIM(ORIGINAL_SHIPMENT_ID::text), '^^') 
            , '||', IFNULL(TRIM(CLOSED_REASON::text), '^^') 
            , '||', IFNULL(TRIM(QUANTITY::text), '^^') 
            , '||', IFNULL(TRIM(TRANSACTION_FLOW_HEADER_ID::text), '^^') 
            , '||', IFNULL(TRIM(END_DATE::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE10::text), '^^') 
            , '||', IFNULL(TRIM(ACCRUE_ON_RECEIPT_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(LCM_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(QUANTITY_RECEIVED::text), '^^') 
            , '||', IFNULL(TRIM(INSPECTION_REQUIRED_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_TO_LOCATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(AMOUNT_RECEIVED::text), '^^') 
            , '||', IFNULL(TRIM(CREATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(QUANTITY_SHIPPED::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(CANCELLED_BY::text), '^^') 
            , '||', IFNULL(TRIM(SECONDARY_QUANTITY::text), '^^') 
            , '||', IFNULL(TRIM(SECONDARY_QUANTITY_REJECTED::text), '^^') 
            , '||', IFNULL(TRIM(RECEIPT_REQUIRED_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(SHIPMENT_NUM::text), '^^') 
            , '||', IFNULL(TRIM(PO_RELEASE_ID::text), '^^') 
            , '||', IFNULL(TRIM(ENFORCE_SHIP_TO_LOCATION_CODE::text), '^^') 
            , '||', IFNULL(TRIM(PAYMENT_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(TERMS_ID::text), '^^') 
            , '||', IFNULL(TRIM(CALCULATE_TAX_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(CONSIGNED_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(ENCUMBERED_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_APPLICATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(GOVERNMENT_CONTEXT::text), '^^') 
            , '||', IFNULL(TRIM(UNIT_MEAS_LOOKUP_CODE::text), '^^') 
            , '||', IFNULL(TRIM(PREFERRED_GRADE::text), '^^') 
            , '||', IFNULL(TRIM(OUTSOURCED_ASSEMBLY::text), '^^') 
            , '||', IFNULL(TRIM(MATCHING_BASIS::text), '^^') 
            , '||', IFNULL(TRIM(ALLOW_SUBSTITUTE_RECEIPTS_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(SECONDARY_QUANTITY_ACCEPTED::text), '^^') 
            , '||', IFNULL(TRIM(QUANTITY_REJECTED::text), '^^') 
            , '||', IFNULL(TRIM(AMOUNT_SHIPPED::text), '^^') 
            , '||', IFNULL(TRIM(VALUE_BASIS::text), '^^') 
            , '||', IFNULL(TRIM(REQUEST_ID::text), '^^') 
            , '||', IFNULL(TRIM(VMI_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(FIRM_STATUS_LOOKUP_CODE::text), '^^') 
            , '||', IFNULL(TRIM(MANUAL_PRICE_CHANGE_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(NOTE_TO_RECEIVER::text), '^^') 
            , '||', IFNULL(TRIM(SECONDARY_QUANTITY_SHIPPED::text), '^^') 
            , '||', IFNULL(TRIM(ENCUMBER_NOW::text), '^^') 
            , '||', IFNULL(TRIM(RECEIPT_DAYS_EXCEPTION_CODE::text), '^^') 
            , '||', IFNULL(TRIM(INVOICE_CLOSE_TOLERANCE::text), '^^') 
            , '||', IFNULL(TRIM(CLOSED_CODE::text), '^^') 
            , '||', IFNULL(TRIM(SECONDARY_QUANTITY_RECEIVED::text), '^^') 
            , '||', IFNULL(TRIM(LEAD_TIME_UNIT::text), '^^') 
            , '||', IFNULL(TRIM(QUANTITY_FINANCED::text), '^^') 
            , '||', IFNULL(TRIM(AMOUNT_FINANCED::text), '^^') 
            , '||', IFNULL(TRIM(AMOUNT_REJECTED::text), '^^') 
            , '||', IFNULL(TRIM(DRAFT_ID::text), '^^') 
            , '||', IFNULL(TRIM(QTY_RCV_TOLERANCE::text), '^^') 
            , '||', IFNULL(TRIM(UNIT_OF_MEASURE_CLASS::text), '^^') 
            , '||', IFNULL(TRIM(TAX_ATTRIBUTE_UPDATE_CODE::text), '^^') 
            , '||', IFNULL(TRIM(AMOUNT_RECOUPED::text), '^^') 
            , '||', IFNULL(TRIM(ENCUMBERED_DATE::text), '^^') 
            , '||', IFNULL(TRIM(SECONDARY_QUANTITY_CANCELLED::text), '^^') 
            , '||', IFNULL(TRIM(MATCH_OPTION::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_LOGIN::text), '^^') 
            , '||', IFNULL(TRIM(AMOUNT_CANCELLED::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_VIA_LOOKUP_CODE::text), '^^') 
            , '||', IFNULL(TRIM(FINAL_MATCH_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(FOB_LOOKUP_CODE::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_TO_ORGANIZATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(RETAINAGE_WITHHELD_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(DAYS_EARLY_RECEIPT_ALLOWED::text), '^^') 
            , '||', IFNULL(TRIM(PO_LINE_ID::text), '^^') 
            , '||', IFNULL(TRIM(CLOSED_DATE::text), '^^') 
            , '||', IFNULL(TRIM(SHIPMENT_CLOSED_DATE::text), '^^') 
            , '||', IFNULL(TRIM(CREATION_DATE::text), '^^') 
            , '||', IFNULL(TRIM(APPROVED_DATE::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_UPDATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(CLOSED_FOR_RECEIVING_DATE::text), '^^') 
            , '||', IFNULL(TRIM(NEED_BY_DATE::text), '^^') 
            , '||', IFNULL(TRIM(LAST_ACCEPT_DATE::text), '^^') 
            , '||', IFNULL(TRIM(CANCEL_DATE::text), '^^') 
            , '||', IFNULL(TRIM(CLOSED_FOR_INVOICE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(RETROACTIVE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(QUANTITY_BILLED::text), '^^') 
            , '||', IFNULL(TRIM(PROMISED_DATE::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
