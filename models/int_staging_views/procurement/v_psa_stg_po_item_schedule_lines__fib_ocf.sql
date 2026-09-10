---- SRC LAYER ----
WITH
SRC_SRC            as ( SELECT * FROM {{ source('outd_ocf_po', 'po_line_locations_all') }} as SRC  ),
SRC_PO_LOCATION    as ( SELECT LINE_NUM, PO_LINE_ID FROM {{ source('outd_ocf_po', 'po_lines_all') }} as SRC 
                        QUALIFY ROW_NUMBER() OVER(PARTITION BY PO_LINE_ID ORDER BY _FIVETRAN_SYNCED DESC) = 1 ),
SRC_ref_bkcc       as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC 
                        WHERE rec_src = 'USCLOUD.ORCL.OCFPRD.PO_LINE_LOCATIONS_ALL' )

/*
SRC_SRC            as ( SELECT * FROM outd_ocf_po.po_line_locations_all )
SRC_PO_LOCATION    as ( SELECT * FROM outd_ocf_po.po_lines_all )
SRC_ref_bkcc       as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_SRC as (
    SELECT
        COALESCE(PO_HEADER_ID, '-2')::TEXT                                                 as                                       PO_HEADER_BK
      , LINE_LOCATION_ID
      , PRICE_DISCOUNT
      , DESCRIPTION
      , QUANTITY_ACCEPTED
      , GLOBAL_ATTRIBUTE_DATE_2
      , AMOUNT_RECOUPED
      , RETAINAGE_WITHHELD_AMOUNT
      , RECEIPT_REQUIRED_FLAG
      , ATTRIBUTE_NUMBER_2
      , ATTRIBUTE_18
      , ATTRIBUTE_20
      , PJC_CONTEXT_CATEGORY
      , TAX_ATTRIBUTE_UPDATE_CODE
      , LAST_UPDATE_LOGIN
      , ATTRIBUTE_6
      , RETAINAGE_RELEASED_AMOUNT
      , GLOBAL_ATTRIBUTE_2
      , ATTRIBUTE_DATE_2
      , ATTRIBUTE_DATE_6
      , ATTRIBUTE_TIMESTAMP_2
      , SHIPMENT_NUM
      , ATTRIBUTE_17
      , SHIPPING_UOM_QUANTITY_SHIPPED
      , CREATED_BY
      , PRICE_OVERRIDE
      , GLOBAL_ATTRIBUTE_11
      , PRODUCT_CATEGORY
      , SHIPMENT_TYPE
      , SHIPPING_UOM_QUANTITY
      , TAX_NAME
      , GLOBAL_ATTRIBUTE_DATE_3
      , SALES_ORDER_SCHEDULE_NUMBER
      , ATTRIBUTE_7
      , CHANGE_PROMISED_DATE_REASON
      , ATTRIBUTE_10
      , TAX_CODE_ID
      , WORK_ORDER_NUMBER
      , QUANTITY_RECEIVED
      , SERVICE_LEVEL
      , CANCEL_DATE
      , SOLDTO_BU_ID
      , LAST_ACCEPT_DATE
      , AMOUNT_REJECTED
      , CUSTOMER_ITEM_DESC
      , ENCUMBERED_DATE
      , ATTRIBUTE_TIMESTAMP_9
      , ATTRIBUTE_DATE_7
      , ATTRIBUTE_TIMESTAMP_8
      , PRODUCT_FISC_CLASSIFICATION
      , CONSIGNED_FLAG
      , CUSTOMER_PO_SCHEDULE_NUMBER
      , GLOBAL_ATTRIBUTE_1
      , INVOICE_CLOSE_TOLERANCE
      , ATTRIBUTE_19
      , ESTIMATED_TAX_AMOUNT
      , ATTRIBUTE_DATE_4
      , SECONDARY_QUANTITY_RECEIVED
      , SFO_AGREEMENT_NUMBER
      , CREATION_DATE
      , RETAINAGE_RATE
      , GLOBAL_ATTRIBUTE_NUMBER_1
      , WORK_APPROVER_ID
      , PROMISED_SHIP_DATE
      , DELIVERY_DATE_CONFIRMATION_REQ
      , SHIP_TO_CUST_CONTACT_ID
      , RETROACTIVE_DATE
      , ENFORCE_SHIP_TO_LOCATION_CODE
      , ATTRIBUTE_CATEGORY
      , ORIGINAL_SHIPMENT_ID
      , CALCULATE_TAX_FLAG
      , CANCEL_BUDGET_DATE
      , GLOBAL_ATTRIBUTE_15
      , BID_PAYMENT_ID
      , EXTERNAL_SYS_RCV_INTF_STATUS
      , SUPPLIER_ORDER_LINE_NUMBER
      , ALLOW_SUBSTITUTE_RECEIPTS_FLAG
      , COUNTRY_OF_ORIGIN_CODE
      , PAYMENT_TYPE
      , CLOSED_DATE
      , SHIP_TO_CUST_LOCATION_ID
      , GLOBAL_ATTRIBUTE_16
      , REINSTATE_BUDGET_DATE_OPTION
      , ATTRIBUTE_15
      , AMOUNT_BILLED
      , FIRMED_BY
      , SECONDARY_QUANTITY_CANCELLED
      , QUANTITY_CANCELLED
      , RECEIVE_CLOSE_TOLERANCE
      , MATCHING_BASIS
      , QTY_RCV_TOLERANCE
      , LINE_INTENDED_USE
      , ATTRIBUTE_TIMESTAMP_5
      , SHIPMENT_CLOSED_DATE
      , SECONDARY_QUANTITY_SHIPPED
      , SALES_ORDER_UPDATE_DATE
      , EXTERNAL_SYS_RCV_GROUP_ID
      , ATTRIBUTE_4
      , SALES_ORDER_LINE_NUMBER
      , FUNDS_STATUS
      , FIRM_DATE
      , SECONDARY_UOM_CODE
      , TRANSACTION_FLOW_HEADER_ID
      , ATTRIBUTE_11
      , LEAD_TIME
      , UOM_CODE
      , SHIP_TO_CUST_ID
      , GLOBAL_ATTRIBUTE_18
      , START_DATE
      , LAST_UPDATE_DATE
      , SECONDARY_QUANTITY_ACCEPTED
      , CUSTOMER_PO_LINE_NUMBER
      , TAXABLE_FLAG
      , ATTRIBUTE_NUMBER_10
      , ATTRIBUTE_TIMESTAMP_10
      , ATTRIBUTE_DATE_5
      , GLOBAL_ATTRIBUTE_8
      , QTY_RCV_EXCEPTION_CODE
      , ATTRIBUTE_DATE_1
      , BACK_TO_BACK_FLAG
      , ATTRIBUTE_1
      , ATTRIBUTE_NUMBER_7
      , CANCEL_BUDGET_DATE_OPTION
      , FIRM_REASON
      , FROM_HEADER_ID
      , SHIP_TO_LOCATION_ID
      , JOB_DEFINITION_NAME
      , SALES_ORDER_NUMBER
      , FROM_LINE_ID
      , GROUP_NAME
      , WORK_ORDER_OPERATION_ID
      , CARRIER_ID
      , SFO_AGREEMENT_LINE_NUMBER
      , AMOUNT
      , VMI_FLAG
      , LEAD_TIME_UNIT
      , ORIG_SCHEDULE_STATUS
      , GLOBAL_ATTRIBUTE_DATE_4
      , GLOBAL_ATTRIBUTE_NUMBER_5
      , SHIP_TO_ORGANIZATION_ID
      , TAX_USER_OVERRIDE_FLAG
      , ATTRIBUTE_DATE_3
      , PO_LINE_ID
      , EXTERNAL_SYS_RCV_INTF_CO_SEQ
      , ATTRIBUTE_TIMESTAMP_7
      , SECONDARY_QUANTITY
      , GLOBAL_ATTRIBUTE_NUMBER_3
      , ATTRIBUTE_16
      , AMOUNT_FINANCED
      , REQ_BU_ID
      , GLOBAL_ATTRIBUTE_12
      , GLOBAL_ATTRIBUTE_20
      , SCHEDULE_STATUS
      , PO_TRADING_ORGANIZATION_ID
      , PRC_BU_ID
      , ATTRIBUTE_NUMBER_1
      , PRODUCT_FISC_CLASS_ID
      , REOPEN_FINAL_CLOSE_DATE
      , ATTRIBUTE_9
      , ATTRIBUTE_DATE_10
      , SFO_PTR_ID
      , DROP_SHIP_FLAG
      , ATTRIBUTE_3
      , QUANTITY
      , MATCH_OPTION
      , QUANTITY_RECOUPED
      , CANCELLED_BY
      , QUANTITY_REJECTED
      , VALUE_BASIS
      , INPUT_TAX_CLASSIFICATION_CODE
      , ATTRIBUTE_NUMBER_9
      , CUSTOMER_PO_NUMBER
      , ATTRIBUTE_14
      , GLOBAL_ATTRIBUTE_NUMBER_2
      , REINSTATE_BUDGET_DATE
      , ATTRIBUTE_8
      , RECEIVING_ROUTING_ID
      , RECEIPT_DAYS_EXCEPTION_CODE
      , SHIPPING_UOM_QUANTITY_RECEIVED
      , ATTRIBUTE_2
      , ATTRIBUTE_NUMBER_4
      , PRODUCT_TYPE
      , TAX_EXCLUSIVE_PRICE
      , WORK_ORDER_SUB_TYPE
      , ENCUMBERED_FLAG
      , SHIPPING_UOM_QUANTITY_CANCELED
      , ATTRIBUTE_5
      , NOTE_TO_RECEIVER
      , FIRM_FLAG
      , PREFERRED_GRADE
      , MODE_OF_TRANSPORT
      , FINAL_DISCHARGE_LOCATION_ID
      , SHIPPING_UOM_QUANTITY_REJECTED
      , GLOBAL_ATTRIBUTE_3
      , ATTRIBUTE_13
      , PO_HEADER_ID
      , AMOUNT_SHIPPED
      , GLOBAL_ATTRIBUTE_13
      , PROMISED_DATE
      , SOURCE_SHIPMENT_ID
      , NEED_BY_DATE
      , ATTRIBUTE_TIMESTAMP_1
      , INSPECTION_REQUIRED_FLAG
      , OUTSOURCED_ASSEMBLY
      , SHIPPING_UOM_QUANTITY_ACCEPTED
      , CANCEL_REASON
      , GLOBAL_ATTRIBUTE_19
      , CLOSED_REASON
      , ORCHESTRATION_CODE
      , AMOUNT_CANCELLED
      , GLOBAL_ATTRIBUTE_CATEGORY
      , MANUAL_PRICE_CHANGE_FLAG
      , REQUESTED_SHIP_DATE
      , DESTINATION_TYPE_CODE
      , ATTRIBUTE_TIMESTAMP_4
      , SECONDARY_QUANTITY_REJECTED
      , ATTRIBUTE_NUMBER_5
      , GLOBAL_ATTRIBUTE_DATE_1
      , UNENCUMBERED_QUANTITY
      , WORK_ORDER_ID
      , PROGRAM_NAME
      , ATTRIBUTE_TIMESTAMP_6
      , REQUEST_ID
      , USER_DEFINED_FISC_CLASS
      , ATTRIBUTE_NUMBER_3
      , PROGRAM_APP_NAME
      , CLOSED_FOR_INVOICE_DATE
      , AUTO_CLOSURE_MODE
      , CANCEL_FLAG
      , GLOBAL_ATTRIBUTE_4
      , ASSESSABLE_VALUE
      , FOB_LOOKUP_CODE
      , WORK_ORDER_OPERATION_SEQ
      , AMOUNT_ACCEPTED
      , ATTRIBUTE_DATE_9
      , ATTRIBUTE_NUMBER_8
      , GLOBAL_ATTRIBUTE_14
      , GLOBAL_ATTRIBUTE_DATE_5
      , UNIT_OF_MEASURE_CLASS
      , GLOBAL_ATTRIBUTE_5
      , OBJECT_VERSION_NUMBER
      , AMOUNT_RECEIVED
      , SHIPPING_UOM_CODE
      , FIRM_STATUS_LOOKUP_CODE
      , TERMS_ID
      , QUANTITY_SHIPPED
      , ATTRIBUTE_12
      , DAYS_EARLY_RECEIPT_ALLOWED
      , GLOBAL_ATTRIBUTE_NUMBER_4
      , ENCUMBER_NOW
      , FROM_LINE_LOCATION_ID
      , ANTICIPATED_ARRIVAL_DATE
      , LINE_INTENDED_USE_ID
      , LAST_UPDATED_BY
      , GLOBAL_ATTRIBUTE_9
      , QUANTITY_BILLED
      , CUSTOMER_ITEM
      , FREIGHT_TERMS_LOOKUP_CODE
      , GOVERNMENT_CONTEXT
      , ATTRIBUTE_TIMESTAMP_3
      , CLOSED_FOR_RECEIVING_DATE
      , GLOBAL_ATTRIBUTE_6
      , ATTRIBUTE_DATE_8
      , DAYS_LATE_RECEIPT_ALLOWED
      , GLOBAL_ATTRIBUTE_7
      , CLOSED_BY
      , END_DATE
      , ACCRUE_ON_RECEIPT_FLAG
      , GLOBAL_ATTRIBUTE_10
      , TRX_BUSINESS_CATEGORY
      , JOB_DEFINITION_PACKAGE
      , FINAL_MATCH_FLAG
      , QUANTITY_FINANCED
      , ATTRIBUTE_NUMBER_6
      , GLOBAL_ATTRIBUTE_17
      , KANBAN_CARD_NUMBER
      , RETURN_TO_VENDOR_TYPE
      , _FIVETRAN_SYNCED
      , _FIVETRAN_DELETED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED)                        as                                           LOAD_DTS
    FROM SRC_SRC
)

, LOGIC_PO_LOCATION as (
    SELECT
        LINE_NUM::TEXT                                                     as                                   PO_ITEM_BK
      , PO_LINE_ID                                                   as                             PO_LOCATION_PO_LINE_ID
      , LINE_NUM
    FROM SRC_PO_LOCATION
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
    INNER JOIN LOGIC_PO_LOCATION
        ON PO_LINE_ID = LOGIC_PO_LOCATION.PO_LOCATION_PO_LINE_ID
    INNER JOIN LOGIC_ref_bkcc
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          PO_ITEM_BK
        , PO_HEADER_BK
        , LINE_LOCATION_ID
        , PRICE_DISCOUNT
        , DESCRIPTION
        , QUANTITY_ACCEPTED
        , GLOBAL_ATTRIBUTE_DATE_2
        , AMOUNT_RECOUPED
        , RETAINAGE_WITHHELD_AMOUNT
        , RECEIPT_REQUIRED_FLAG
        , ATTRIBUTE_NUMBER_2
        , ATTRIBUTE_18
        , ATTRIBUTE_20
        , PJC_CONTEXT_CATEGORY
        , TAX_ATTRIBUTE_UPDATE_CODE
        , LAST_UPDATE_LOGIN
        , ATTRIBUTE_6
        , RETAINAGE_RELEASED_AMOUNT
        , GLOBAL_ATTRIBUTE_2
        , ATTRIBUTE_DATE_2
        , ATTRIBUTE_DATE_6
        , ATTRIBUTE_TIMESTAMP_2
        , SHIPMENT_NUM
        , ATTRIBUTE_17
        , SHIPPING_UOM_QUANTITY_SHIPPED
        , CREATED_BY
        , PRICE_OVERRIDE
        , GLOBAL_ATTRIBUTE_11
        , PRODUCT_CATEGORY
        , SHIPMENT_TYPE
        , SHIPPING_UOM_QUANTITY
        , TAX_NAME
        , GLOBAL_ATTRIBUTE_DATE_3
        , SALES_ORDER_SCHEDULE_NUMBER
        , ATTRIBUTE_7
        , CHANGE_PROMISED_DATE_REASON
        , ATTRIBUTE_10
        , TAX_CODE_ID
        , WORK_ORDER_NUMBER
        , QUANTITY_RECEIVED
        , SERVICE_LEVEL
        , CANCEL_DATE
        , SOLDTO_BU_ID
        , LAST_ACCEPT_DATE
        , AMOUNT_REJECTED
        , CUSTOMER_ITEM_DESC
        , ENCUMBERED_DATE
        , ATTRIBUTE_TIMESTAMP_9
        , ATTRIBUTE_DATE_7
        , ATTRIBUTE_TIMESTAMP_8
        , PRODUCT_FISC_CLASSIFICATION
        , CONSIGNED_FLAG
        , CUSTOMER_PO_SCHEDULE_NUMBER
        , GLOBAL_ATTRIBUTE_1
        , INVOICE_CLOSE_TOLERANCE
        , ATTRIBUTE_19
        , ESTIMATED_TAX_AMOUNT
        , ATTRIBUTE_DATE_4
        , SECONDARY_QUANTITY_RECEIVED
        , SFO_AGREEMENT_NUMBER
        , CREATION_DATE
        , RETAINAGE_RATE
        , GLOBAL_ATTRIBUTE_NUMBER_1
        , WORK_APPROVER_ID
        , PROMISED_SHIP_DATE
        , DELIVERY_DATE_CONFIRMATION_REQ
        , SHIP_TO_CUST_CONTACT_ID
        , RETROACTIVE_DATE
        , ENFORCE_SHIP_TO_LOCATION_CODE
        , ATTRIBUTE_CATEGORY
        , ORIGINAL_SHIPMENT_ID
        , CALCULATE_TAX_FLAG
        , CANCEL_BUDGET_DATE
        , GLOBAL_ATTRIBUTE_15
        , BID_PAYMENT_ID
        , EXTERNAL_SYS_RCV_INTF_STATUS
        , SUPPLIER_ORDER_LINE_NUMBER
        , ALLOW_SUBSTITUTE_RECEIPTS_FLAG
        , COUNTRY_OF_ORIGIN_CODE
        , PAYMENT_TYPE
        , CLOSED_DATE
        , SHIP_TO_CUST_LOCATION_ID
        , GLOBAL_ATTRIBUTE_16
        , REINSTATE_BUDGET_DATE_OPTION
        , ATTRIBUTE_15
        , AMOUNT_BILLED
        , FIRMED_BY
        , SECONDARY_QUANTITY_CANCELLED
        , QUANTITY_CANCELLED
        , RECEIVE_CLOSE_TOLERANCE
        , MATCHING_BASIS
        , QTY_RCV_TOLERANCE
        , LINE_INTENDED_USE
        , ATTRIBUTE_TIMESTAMP_5
        , SHIPMENT_CLOSED_DATE
        , SECONDARY_QUANTITY_SHIPPED
        , SALES_ORDER_UPDATE_DATE
        , EXTERNAL_SYS_RCV_GROUP_ID
        , ATTRIBUTE_4
        , SALES_ORDER_LINE_NUMBER
        , FUNDS_STATUS
        , FIRM_DATE
        , SECONDARY_UOM_CODE
        , TRANSACTION_FLOW_HEADER_ID
        , ATTRIBUTE_11
        , LEAD_TIME
        , UOM_CODE
        , SHIP_TO_CUST_ID
        , GLOBAL_ATTRIBUTE_18
        , START_DATE
        , LAST_UPDATE_DATE
        , SECONDARY_QUANTITY_ACCEPTED
        , CUSTOMER_PO_LINE_NUMBER
        , TAXABLE_FLAG
        , ATTRIBUTE_NUMBER_10
        , ATTRIBUTE_TIMESTAMP_10
        , ATTRIBUTE_DATE_5
        , GLOBAL_ATTRIBUTE_8
        , QTY_RCV_EXCEPTION_CODE
        , ATTRIBUTE_DATE_1
        , BACK_TO_BACK_FLAG
        , ATTRIBUTE_1
        , ATTRIBUTE_NUMBER_7
        , CANCEL_BUDGET_DATE_OPTION
        , FIRM_REASON
        , FROM_HEADER_ID
        , SHIP_TO_LOCATION_ID
        , JOB_DEFINITION_NAME
        , SALES_ORDER_NUMBER
        , FROM_LINE_ID
        , GROUP_NAME
        , WORK_ORDER_OPERATION_ID
        , CARRIER_ID
        , SFO_AGREEMENT_LINE_NUMBER
        , AMOUNT
        , VMI_FLAG
        , LEAD_TIME_UNIT
        , ORIG_SCHEDULE_STATUS
        , GLOBAL_ATTRIBUTE_DATE_4
        , GLOBAL_ATTRIBUTE_NUMBER_5
        , SHIP_TO_ORGANIZATION_ID
        , TAX_USER_OVERRIDE_FLAG
        , ATTRIBUTE_DATE_3
        , PO_LINE_ID
        , EXTERNAL_SYS_RCV_INTF_CO_SEQ
        , ATTRIBUTE_TIMESTAMP_7
        , SECONDARY_QUANTITY
        , GLOBAL_ATTRIBUTE_NUMBER_3
        , ATTRIBUTE_16
        , AMOUNT_FINANCED
        , REQ_BU_ID
        , GLOBAL_ATTRIBUTE_12
        , GLOBAL_ATTRIBUTE_20
        , SCHEDULE_STATUS
        , PO_TRADING_ORGANIZATION_ID
        , PRC_BU_ID
        , ATTRIBUTE_NUMBER_1
        , PRODUCT_FISC_CLASS_ID
        , REOPEN_FINAL_CLOSE_DATE
        , ATTRIBUTE_9
        , ATTRIBUTE_DATE_10
        , SFO_PTR_ID
        , DROP_SHIP_FLAG
        , ATTRIBUTE_3
        , QUANTITY
        , MATCH_OPTION
        , QUANTITY_RECOUPED
        , CANCELLED_BY
        , QUANTITY_REJECTED
        , VALUE_BASIS
        , INPUT_TAX_CLASSIFICATION_CODE
        , ATTRIBUTE_NUMBER_9
        , CUSTOMER_PO_NUMBER
        , ATTRIBUTE_14
        , GLOBAL_ATTRIBUTE_NUMBER_2
        , REINSTATE_BUDGET_DATE
        , ATTRIBUTE_8
        , RECEIVING_ROUTING_ID
        , RECEIPT_DAYS_EXCEPTION_CODE
        , SHIPPING_UOM_QUANTITY_RECEIVED
        , ATTRIBUTE_2
        , ATTRIBUTE_NUMBER_4
        , PRODUCT_TYPE
        , TAX_EXCLUSIVE_PRICE
        , WORK_ORDER_SUB_TYPE
        , ENCUMBERED_FLAG
        , SHIPPING_UOM_QUANTITY_CANCELED
        , ATTRIBUTE_5
        , NOTE_TO_RECEIVER
        , FIRM_FLAG
        , PREFERRED_GRADE
        , MODE_OF_TRANSPORT
        , FINAL_DISCHARGE_LOCATION_ID
        , SHIPPING_UOM_QUANTITY_REJECTED
        , GLOBAL_ATTRIBUTE_3
        , ATTRIBUTE_13
        , PO_HEADER_ID
        , AMOUNT_SHIPPED
        , GLOBAL_ATTRIBUTE_13
        , PROMISED_DATE
        , SOURCE_SHIPMENT_ID
        , NEED_BY_DATE
        , ATTRIBUTE_TIMESTAMP_1
        , INSPECTION_REQUIRED_FLAG
        , OUTSOURCED_ASSEMBLY
        , SHIPPING_UOM_QUANTITY_ACCEPTED
        , CANCEL_REASON
        , GLOBAL_ATTRIBUTE_19
        , CLOSED_REASON
        , ORCHESTRATION_CODE
        , AMOUNT_CANCELLED
        , GLOBAL_ATTRIBUTE_CATEGORY
        , MANUAL_PRICE_CHANGE_FLAG
        , REQUESTED_SHIP_DATE
        , DESTINATION_TYPE_CODE
        , ATTRIBUTE_TIMESTAMP_4
        , SECONDARY_QUANTITY_REJECTED
        , ATTRIBUTE_NUMBER_5
        , GLOBAL_ATTRIBUTE_DATE_1
        , UNENCUMBERED_QUANTITY
        , WORK_ORDER_ID
        , PROGRAM_NAME
        , ATTRIBUTE_TIMESTAMP_6
        , REQUEST_ID
        , USER_DEFINED_FISC_CLASS
        , ATTRIBUTE_NUMBER_3
        , PROGRAM_APP_NAME
        , CLOSED_FOR_INVOICE_DATE
        , AUTO_CLOSURE_MODE
        , CANCEL_FLAG
        , GLOBAL_ATTRIBUTE_4
        , ASSESSABLE_VALUE
        , FOB_LOOKUP_CODE
        , WORK_ORDER_OPERATION_SEQ
        , AMOUNT_ACCEPTED
        , ATTRIBUTE_DATE_9
        , ATTRIBUTE_NUMBER_8
        , GLOBAL_ATTRIBUTE_14
        , GLOBAL_ATTRIBUTE_DATE_5
        , UNIT_OF_MEASURE_CLASS
        , GLOBAL_ATTRIBUTE_5
        , OBJECT_VERSION_NUMBER
        , AMOUNT_RECEIVED
        , SHIPPING_UOM_CODE
        , FIRM_STATUS_LOOKUP_CODE
        , TERMS_ID
        , QUANTITY_SHIPPED
        , ATTRIBUTE_12
        , DAYS_EARLY_RECEIPT_ALLOWED
        , GLOBAL_ATTRIBUTE_NUMBER_4
        , ENCUMBER_NOW
        , FROM_LINE_LOCATION_ID
        , ANTICIPATED_ARRIVAL_DATE
        , LINE_INTENDED_USE_ID
        , LAST_UPDATED_BY
        , GLOBAL_ATTRIBUTE_9
        , QUANTITY_BILLED
        , CUSTOMER_ITEM
        , FREIGHT_TERMS_LOOKUP_CODE
        , GOVERNMENT_CONTEXT
        , ATTRIBUTE_TIMESTAMP_3
        , CLOSED_FOR_RECEIVING_DATE
        , GLOBAL_ATTRIBUTE_6
        , ATTRIBUTE_DATE_8
        , DAYS_LATE_RECEIPT_ALLOWED
        , GLOBAL_ATTRIBUTE_7
        , CLOSED_BY
        , END_DATE
        , ACCRUE_ON_RECEIPT_FLAG
        , GLOBAL_ATTRIBUTE_10
        , TRX_BUSINESS_CATEGORY
        , JOB_DEFINITION_PACKAGE
        , FINAL_MATCH_FLAG
        , QUANTITY_FINANCED
        , ATTRIBUTE_NUMBER_6
        , GLOBAL_ATTRIBUTE_17
        , KANBAN_CARD_NUMBER
        , RETURN_TO_VENDOR_TYPE
        , PO_LOCATION_PO_LINE_ID
        , LINE_NUM
        , _FIVETRAN_SYNCED
        , _FIVETRAN_DELETED
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
              IFNULL(TRIM(PRICE_DISCOUNT::text), '^^') 
            , '||', IFNULL(TRIM(DESCRIPTION::text), '^^') 
            , '||', IFNULL(TRIM(QUANTITY_ACCEPTED::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_DATE_2::text), '^^') 
            , '||', IFNULL(TRIM(AMOUNT_RECOUPED::text), '^^') 
            , '||', IFNULL(TRIM(RETAINAGE_WITHHELD_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(RECEIPT_REQUIRED_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_2::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_18::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_20::text), '^^') 
            , '||', IFNULL(TRIM(PJC_CONTEXT_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(TAX_ATTRIBUTE_UPDATE_CODE::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_LOGIN::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_6::text), '^^') 
            , '||', IFNULL(TRIM(RETAINAGE_RELEASED_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_2::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_DATE_2::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_DATE_6::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_TIMESTAMP_2::text), '^^') 
            , '||', IFNULL(TRIM(SHIPMENT_NUM::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_17::text), '^^') 
            , '||', IFNULL(TRIM(SHIPPING_UOM_QUANTITY_SHIPPED::text), '^^') 
            , '||', IFNULL(TRIM(CREATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(PRICE_OVERRIDE::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_11::text), '^^') 
            , '||', IFNULL(TRIM(PRODUCT_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(SHIPMENT_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(SHIPPING_UOM_QUANTITY::text), '^^') 
            , '||', IFNULL(TRIM(TAX_NAME::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_DATE_3::text), '^^') 
            , '||', IFNULL(TRIM(SALES_ORDER_SCHEDULE_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_7::text), '^^') 
            , '||', IFNULL(TRIM(CHANGE_PROMISED_DATE_REASON::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_10::text), '^^') 
            , '||', IFNULL(TRIM(TAX_CODE_ID::text), '^^') 
            , '||', IFNULL(TRIM(WORK_ORDER_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(QUANTITY_RECEIVED::text), '^^') 
            , '||', IFNULL(TRIM(SERVICE_LEVEL::text), '^^') 
            , '||', IFNULL(TRIM(CANCEL_DATE::text), '^^') 
            , '||', IFNULL(TRIM(SOLDTO_BU_ID::text), '^^') 
            , '||', IFNULL(TRIM(LAST_ACCEPT_DATE::text), '^^') 
            , '||', IFNULL(TRIM(AMOUNT_REJECTED::text), '^^') 
            , '||', IFNULL(TRIM(CUSTOMER_ITEM_DESC::text), '^^') 
            , '||', IFNULL(TRIM(ENCUMBERED_DATE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_TIMESTAMP_9::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_DATE_7::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_TIMESTAMP_8::text), '^^') 
            , '||', IFNULL(TRIM(PRODUCT_FISC_CLASSIFICATION::text), '^^') 
            , '||', IFNULL(TRIM(CONSIGNED_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(CUSTOMER_PO_SCHEDULE_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_1::text), '^^') 
            , '||', IFNULL(TRIM(INVOICE_CLOSE_TOLERANCE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_19::text), '^^') 
            , '||', IFNULL(TRIM(ESTIMATED_TAX_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_DATE_4::text), '^^') 
            , '||', IFNULL(TRIM(SECONDARY_QUANTITY_RECEIVED::text), '^^') 
            , '||', IFNULL(TRIM(SFO_AGREEMENT_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(CREATION_DATE::text), '^^') 
            , '||', IFNULL(TRIM(RETAINAGE_RATE::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_NUMBER_1::text), '^^') 
            , '||', IFNULL(TRIM(WORK_APPROVER_ID::text), '^^') 
            , '||', IFNULL(TRIM(PROMISED_SHIP_DATE::text), '^^') 
            , '||', IFNULL(TRIM(DELIVERY_DATE_CONFIRMATION_REQ::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_TO_CUST_CONTACT_ID::text), '^^') 
            , '||', IFNULL(TRIM(RETROACTIVE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(ENFORCE_SHIP_TO_LOCATION_CODE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(ORIGINAL_SHIPMENT_ID::text), '^^') 
            , '||', IFNULL(TRIM(CALCULATE_TAX_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(CANCEL_BUDGET_DATE::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_15::text), '^^') 
            , '||', IFNULL(TRIM(BID_PAYMENT_ID::text), '^^') 
            , '||', IFNULL(TRIM(EXTERNAL_SYS_RCV_INTF_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(SUPPLIER_ORDER_LINE_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(ALLOW_SUBSTITUTE_RECEIPTS_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(COUNTRY_OF_ORIGIN_CODE::text), '^^') 
            , '||', IFNULL(TRIM(PAYMENT_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(CLOSED_DATE::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_TO_CUST_LOCATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_16::text), '^^') 
            , '||', IFNULL(TRIM(REINSTATE_BUDGET_DATE_OPTION::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_15::text), '^^') 
            , '||', IFNULL(TRIM(AMOUNT_BILLED::text), '^^') 
            , '||', IFNULL(TRIM(FIRMED_BY::text), '^^') 
            , '||', IFNULL(TRIM(SECONDARY_QUANTITY_CANCELLED::text), '^^') 
            , '||', IFNULL(TRIM(QUANTITY_CANCELLED::text), '^^') 
            , '||', IFNULL(TRIM(RECEIVE_CLOSE_TOLERANCE::text), '^^') 
            , '||', IFNULL(TRIM(MATCHING_BASIS::text), '^^') 
            , '||', IFNULL(TRIM(QTY_RCV_TOLERANCE::text), '^^') 
            , '||', IFNULL(TRIM(LINE_INTENDED_USE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_TIMESTAMP_5::text), '^^') 
            , '||', IFNULL(TRIM(SHIPMENT_CLOSED_DATE::text), '^^') 
            , '||', IFNULL(TRIM(SECONDARY_QUANTITY_SHIPPED::text), '^^') 
            , '||', IFNULL(TRIM(SALES_ORDER_UPDATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(EXTERNAL_SYS_RCV_GROUP_ID::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_4::text), '^^') 
            , '||', IFNULL(TRIM(SALES_ORDER_LINE_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(FUNDS_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(FIRM_DATE::text), '^^') 
            , '||', IFNULL(TRIM(SECONDARY_UOM_CODE::text), '^^') 
            , '||', IFNULL(TRIM(TRANSACTION_FLOW_HEADER_ID::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_11::text), '^^') 
            , '||', IFNULL(TRIM(LEAD_TIME::text), '^^') 
            , '||', IFNULL(TRIM(UOM_CODE::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_TO_CUST_ID::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_18::text), '^^') 
            , '||', IFNULL(TRIM(START_DATE::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(SECONDARY_QUANTITY_ACCEPTED::text), '^^') 
            , '||', IFNULL(TRIM(CUSTOMER_PO_LINE_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(TAXABLE_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_10::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_TIMESTAMP_10::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_DATE_5::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_8::text), '^^') 
            , '||', IFNULL(TRIM(QTY_RCV_EXCEPTION_CODE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_DATE_1::text), '^^') 
            , '||', IFNULL(TRIM(BACK_TO_BACK_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_1::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_7::text), '^^') 
            , '||', IFNULL(TRIM(CANCEL_BUDGET_DATE_OPTION::text), '^^') 
            , '||', IFNULL(TRIM(FIRM_REASON::text), '^^') 
            , '||', IFNULL(TRIM(FROM_HEADER_ID::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_TO_LOCATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(JOB_DEFINITION_NAME::text), '^^') 
            , '||', IFNULL(TRIM(SALES_ORDER_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(FROM_LINE_ID::text), '^^') 
            , '||', IFNULL(TRIM(GROUP_NAME::text), '^^') 
            , '||', IFNULL(TRIM(WORK_ORDER_OPERATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(CARRIER_ID::text), '^^') 
            , '||', IFNULL(TRIM(SFO_AGREEMENT_LINE_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(VMI_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(LEAD_TIME_UNIT::text), '^^') 
            , '||', IFNULL(TRIM(ORIG_SCHEDULE_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_DATE_4::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_NUMBER_5::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_TO_ORGANIZATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(TAX_USER_OVERRIDE_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_DATE_3::text), '^^') 
            , '||', IFNULL(TRIM(PO_LINE_ID::text), '^^') 
            , '||', IFNULL(TRIM(EXTERNAL_SYS_RCV_INTF_CO_SEQ::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_TIMESTAMP_7::text), '^^') 
            , '||', IFNULL(TRIM(SECONDARY_QUANTITY::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_NUMBER_3::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_16::text), '^^') 
            , '||', IFNULL(TRIM(AMOUNT_FINANCED::text), '^^') 
            , '||', IFNULL(TRIM(REQ_BU_ID::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_12::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_20::text), '^^') 
            , '||', IFNULL(TRIM(SCHEDULE_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(PO_TRADING_ORGANIZATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(PRC_BU_ID::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_1::text), '^^') 
            , '||', IFNULL(TRIM(PRODUCT_FISC_CLASS_ID::text), '^^') 
            , '||', IFNULL(TRIM(REOPEN_FINAL_CLOSE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_9::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_DATE_10::text), '^^') 
            , '||', IFNULL(TRIM(SFO_PTR_ID::text), '^^') 
            , '||', IFNULL(TRIM(DROP_SHIP_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_3::text), '^^') 
            , '||', IFNULL(TRIM(QUANTITY::text), '^^') 
            , '||', IFNULL(TRIM(MATCH_OPTION::text), '^^') 
            , '||', IFNULL(TRIM(QUANTITY_RECOUPED::text), '^^') 
            , '||', IFNULL(TRIM(CANCELLED_BY::text), '^^') 
            , '||', IFNULL(TRIM(QUANTITY_REJECTED::text), '^^') 
            , '||', IFNULL(TRIM(VALUE_BASIS::text), '^^') 
            , '||', IFNULL(TRIM(INPUT_TAX_CLASSIFICATION_CODE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_9::text), '^^') 
            , '||', IFNULL(TRIM(CUSTOMER_PO_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_14::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_NUMBER_2::text), '^^') 
            , '||', IFNULL(TRIM(REINSTATE_BUDGET_DATE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_8::text), '^^') 
            , '||', IFNULL(TRIM(RECEIVING_ROUTING_ID::text), '^^') 
            , '||', IFNULL(TRIM(RECEIPT_DAYS_EXCEPTION_CODE::text), '^^') 
            , '||', IFNULL(TRIM(SHIPPING_UOM_QUANTITY_RECEIVED::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_2::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_4::text), '^^') 
            , '||', IFNULL(TRIM(PRODUCT_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(TAX_EXCLUSIVE_PRICE::text), '^^') 
            , '||', IFNULL(TRIM(WORK_ORDER_SUB_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(ENCUMBERED_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(SHIPPING_UOM_QUANTITY_CANCELED::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_5::text), '^^') 
            , '||', IFNULL(TRIM(NOTE_TO_RECEIVER::text), '^^') 
            , '||', IFNULL(TRIM(FIRM_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(PREFERRED_GRADE::text), '^^') 
            , '||', IFNULL(TRIM(MODE_OF_TRANSPORT::text), '^^') 
            , '||', IFNULL(TRIM(FINAL_DISCHARGE_LOCATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(SHIPPING_UOM_QUANTITY_REJECTED::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_3::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_13::text), '^^') 
            , '||', IFNULL(TRIM(PO_HEADER_ID::text), '^^') 
            , '||', IFNULL(TRIM(AMOUNT_SHIPPED::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_13::text), '^^') 
            , '||', IFNULL(TRIM(PROMISED_DATE::text), '^^') 
            , '||', IFNULL(TRIM(SOURCE_SHIPMENT_ID::text), '^^') 
            , '||', IFNULL(TRIM(NEED_BY_DATE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_TIMESTAMP_1::text), '^^') 
            , '||', IFNULL(TRIM(INSPECTION_REQUIRED_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(OUTSOURCED_ASSEMBLY::text), '^^') 
            , '||', IFNULL(TRIM(SHIPPING_UOM_QUANTITY_ACCEPTED::text), '^^') 
            , '||', IFNULL(TRIM(CANCEL_REASON::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_19::text), '^^') 
            , '||', IFNULL(TRIM(CLOSED_REASON::text), '^^') 
            , '||', IFNULL(TRIM(ORCHESTRATION_CODE::text), '^^') 
            , '||', IFNULL(TRIM(AMOUNT_CANCELLED::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(MANUAL_PRICE_CHANGE_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(REQUESTED_SHIP_DATE::text), '^^') 
            , '||', IFNULL(TRIM(DESTINATION_TYPE_CODE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_TIMESTAMP_4::text), '^^') 
            , '||', IFNULL(TRIM(SECONDARY_QUANTITY_REJECTED::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_5::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_DATE_1::text), '^^') 
            , '||', IFNULL(TRIM(UNENCUMBERED_QUANTITY::text), '^^') 
            , '||', IFNULL(TRIM(WORK_ORDER_ID::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_NAME::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_TIMESTAMP_6::text), '^^') 
            , '||', IFNULL(TRIM(REQUEST_ID::text), '^^') 
            , '||', IFNULL(TRIM(USER_DEFINED_FISC_CLASS::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_3::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_APP_NAME::text), '^^') 
            , '||', IFNULL(TRIM(CLOSED_FOR_INVOICE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(AUTO_CLOSURE_MODE::text), '^^') 
            , '||', IFNULL(TRIM(CANCEL_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_4::text), '^^') 
            , '||', IFNULL(TRIM(ASSESSABLE_VALUE::text), '^^') 
            , '||', IFNULL(TRIM(FOB_LOOKUP_CODE::text), '^^') 
            , '||', IFNULL(TRIM(WORK_ORDER_OPERATION_SEQ::text), '^^') 
            , '||', IFNULL(TRIM(AMOUNT_ACCEPTED::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_DATE_9::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_8::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_14::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_DATE_5::text), '^^') 
            , '||', IFNULL(TRIM(UNIT_OF_MEASURE_CLASS::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_5::text), '^^') 
            , '||', IFNULL(TRIM(OBJECT_VERSION_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(AMOUNT_RECEIVED::text), '^^') 
            , '||', IFNULL(TRIM(SHIPPING_UOM_CODE::text), '^^') 
            , '||', IFNULL(TRIM(FIRM_STATUS_LOOKUP_CODE::text), '^^') 
            , '||', IFNULL(TRIM(TERMS_ID::text), '^^') 
            , '||', IFNULL(TRIM(QUANTITY_SHIPPED::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_12::text), '^^') 
            , '||', IFNULL(TRIM(DAYS_EARLY_RECEIPT_ALLOWED::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_NUMBER_4::text), '^^') 
            , '||', IFNULL(TRIM(ENCUMBER_NOW::text), '^^') 
            , '||', IFNULL(TRIM(FROM_LINE_LOCATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(ANTICIPATED_ARRIVAL_DATE::text), '^^') 
            , '||', IFNULL(TRIM(LINE_INTENDED_USE_ID::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_9::text), '^^') 
            , '||', IFNULL(TRIM(QUANTITY_BILLED::text), '^^') 
            , '||', IFNULL(TRIM(CUSTOMER_ITEM::text), '^^') 
            , '||', IFNULL(TRIM(FREIGHT_TERMS_LOOKUP_CODE::text), '^^') 
            , '||', IFNULL(TRIM(GOVERNMENT_CONTEXT::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_TIMESTAMP_3::text), '^^') 
            , '||', IFNULL(TRIM(CLOSED_FOR_RECEIVING_DATE::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_6::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_DATE_8::text), '^^') 
            , '||', IFNULL(TRIM(DAYS_LATE_RECEIPT_ALLOWED::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_7::text), '^^') 
            , '||', IFNULL(TRIM(CLOSED_BY::text), '^^') 
            , '||', IFNULL(TRIM(END_DATE::text), '^^') 
            , '||', IFNULL(TRIM(ACCRUE_ON_RECEIPT_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_10::text), '^^') 
            , '||', IFNULL(TRIM(TRX_BUSINESS_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(JOB_DEFINITION_PACKAGE::text), '^^') 
            , '||', IFNULL(TRIM(FINAL_MATCH_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(QUANTITY_FINANCED::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_6::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_17::text), '^^') 
            , '||', IFNULL(TRIM(KANBAN_CARD_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(RETURN_TO_VENDOR_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
