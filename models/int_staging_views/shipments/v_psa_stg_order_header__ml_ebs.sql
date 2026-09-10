---- SRC LAYER ----
WITH
SRC_S              as ( SELECT * FROM {{ source('ml_ebs_ont', 'oe_order_headers_all') }} as SRC  ),
SRC_A              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S              as ( SELECT * FROM ml_ebs_ont.oe_order_headers_all )
, SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        to_char(ORDER_NUMBER)                                        as                                    ORDER_HEADER_BK
      , ORDER_NUMBER
      , HEADER_ID
      , SOLD_TO_PHONE_ID
      , ORG_ID
      , SOURCE_DOCUMENT_VERSION_NUMBER
      , IB_CURRENT_LOCATION
      , CONVERSION_RATE_DATE
      , PROGRAM_ID
      , CONTEXT
      , SHIPMENT_PRIORITY_CODE
      , CANCELLED_FLAG
      , DELIVER_TO_ORG_ID
      , PARTIAL_SHIPMENTS_ALLOWED
      , DELIVER_TO_CONTACT_ID
      , CUSTOMER_SIGNATURE_DATE
      , GLOBAL_ATTRIBUTE5
      , GLOBAL_ATTRIBUTE4
      , GLOBAL_ATTRIBUTE7
      , GLOBAL_ATTRIBUTE6
      , GLOBAL_ATTRIBUTE1
      , ORDER_FIRMED_DATE
      , GLOBAL_ATTRIBUTE3
      , GLOBAL_ATTRIBUTE2
      , PAYMENT_TYPE_CODE
      , UPGRADED_FLAG
      , FOB_POINT_CODE
      , GLOBAL_ATTRIBUTE9
      , GLOBAL_ATTRIBUTE8
      , TAX_EXEMPT_REASON_CODE
      , ORDER_SOURCE_ID
      , ATTRIBUTE3
      , ATTRIBUTE2
      , DEFAULT_FULFILLMENT_SET
      , ATTRIBUTE1
      , CREDIT_CARD_APPROVAL_CODE
      , TP_ATTRIBUTE15
      , FREIGHT_CARRIER_CODE
      , TP_ATTRIBUTE14
      , CREDIT_CARD_EXPIRATION_DATE
      , LAST_ACK_DATE
      , TP_ATTRIBUTE13
      , TP_ATTRIBUTE12
      , TP_ATTRIBUTE11
      , TP_ATTRIBUTE10
      , ATTRIBUTE9
      , BOOKED_FLAG
      , ATTRIBUTE8
      , ATTRIBUTE7
      , ATTRIBUTE6
      , SUPPLIER_SIGNATURE_DATE
      , ATTRIBUTE5
      , ATTRIBUTE4
      , CUST_PO_NUMBER
      , TRANSACTION_PHASE_CODE
      , AGREEMENT_ID
      , CONVERSION_TYPE_CODE
      , SHIP_TOLERANCE_BELOW
      , BLANKET_NUMBER
      , TRANSACTIONAL_CURR_CODE
      , ORDER_CATEGORY_CODE
      , ATTRIBUTE10
      , ORIG_SYS_DOCUMENT_REF
      , SHIP_TO_CONTACT_ID
      , TP_CONTEXT
      , ATTRIBUTE14
      , CUSTOMER_SIGNATURE
      , ATTRIBUTE13
      , CUSTOMER_PAYMENT_TERM_ID
      , ATTRIBUTE12
      , ATTRIBUTE11
      , IB_INSTALLED_AT_LOCATION
      , DROP_SHIP_FLAG
      , SHIP_TOLERANCE_ABOVE
      , FLOW_STATUS_CODE
      , VERSION_NUMBER
      , SALES_CHANNEL_CODE
      , SOLD_TO_CONTACT_ID
      , CHECK_NUMBER
      , SALESREP_ID
      , ACCOUNTING_RULE_DURATION
      , ORDER_TYPE_ID
      , LINE_SET_NAME
      , INVOICE_TO_CONTACT_ID
      , ATTRIBUTE20
      , SUPPLIER_SIGNATURE
      , GLOBAL_ATTRIBUTE20
      , SALES_DOCUMENT_NAME
      , GLOBAL_ATTRIBUTE17
      , GLOBAL_ATTRIBUTE18
      , GLOBAL_ATTRIBUTE15
      , GLOBAL_ATTRIBUTE16
      , GLOBAL_ATTRIBUTE13
      , GLOBAL_ATTRIBUTE14
      , RETURN_REASON_CODE
      , GLOBAL_ATTRIBUTE11
      , GLOBAL_ATTRIBUTE12
      , ATTRIBUTE18
      , ATTRIBUTE17
      , ATTRIBUTE16
      , ATTRIBUTE15
      , GLOBAL_ATTRIBUTE19
      , ATTRIBUTE19
      , FIRST_ACK_CODE
      , TAX_POINT_CODE
      , USER_STATUS_CODE
      , GLOBAL_ATTRIBUTE10
      , LOCK_CONTROL
      , SHIP_TO_ORG_ID
      , INVOICE_TO_ORG_ID
      , CHANGE_SEQUENCE
      , TP_ATTRIBUTE9
      , SOURCE_DOCUMENT_TYPE_ID
      , SOLD_TO_SITE_USE_ID
      , SOLD_FROM_ORG_ID
      , CREATED_BY
      , SHIPPING_INSTRUCTIONS
      , LAST_UPDATED_BY
      , EARLIEST_SCHEDULE_LIMIT
      , PAYMENT_TERM_ID
      , SHIPPING_METHOD_CODE
      , SOURCE_DOCUMENT_ID
      , PRICE_LIST_ID
      , TP_ATTRIBUTE8
      , INVOICING_RULE_ID
      , TP_ATTRIBUTE7
      , TP_ATTRIBUTE6
      , TP_ATTRIBUTE5
      , TP_ATTRIBUTE4
      , FULFILLMENT_SET_NAME
      , TP_ATTRIBUTE3
      , TP_ATTRIBUTE2
      , TP_ATTRIBUTE1
      , CUSTOMER_PREFERENCE_SET_CODE
      , END_CUSTOMER_CONTACT_ID
      , CREDIT_CARD_HOLDER_NAME
      , PAYMENT_AMOUNT
      , PROGRAM_APPLICATION_ID
      , PACKING_INSTRUCTIONS
      , END_CUSTOMER_ID
      , OPEN_FLAG
      , CREDIT_CARD_CODE
      , SHIP_FROM_ORG_ID
      , IB_OWNER
      , FIRST_ACK_DATE
      , QUOTE_NUMBER
      , SALES_DOCUMENT_TYPE_CODE
      , TAX_EXEMPT_NUMBER
      , REQUEST_ID
      , BATCH_ID
      , MARKETING_SOURCE_CODE_ID
      , DRAFT_SUBMITTED_FLAG
      , XML_MESSAGE_ID
      , LATEST_SCHEDULE_LIMIT
      , TAX_EXEMPT_FLAG
      , CREDIT_CARD_NUMBER
      , LAST_ACK_CODE
      , SOLD_TO_ORG_ID
      , CONVERSION_RATE
      , PRICE_REQUEST_CODE
      , ORDER_DATE_TYPE_CODE
      , LAST_UPDATE_LOGIN
      , ACCOUNTING_RULE_ID
      , END_CUSTOMER_SITE_USE_ID
      , GLOBAL_ATTRIBUTE_CATEGORY
      , DEMAND_CLASS_CODE
      , FREIGHT_TERMS_CODE
      , PROGRAM_UPDATE_DATE
      , MINISITE_ID
      , CREDIT_CARD_APPROVAL_DATE
      , BOOKED_DATE
      , ORDERED_DATE
      , REQUEST_DATE
      , CREATION_DATE
      , QUOTE_DATE
      , PRICING_DATE
      , EXPIRATION_DATE
      , LAST_UPDATE_DATE
      , _FIVETRAN_DELETED
      , _FIVETRAN_ID
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED )                   as                                           LOAD_DTS
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
        ORDER_HEADER_BK
      , ORDER_NUMBER
      , HEADER_ID
      , SOLD_TO_PHONE_ID
      , ORG_ID
      , SOURCE_DOCUMENT_VERSION_NUMBER
      , IB_CURRENT_LOCATION
      , CONVERSION_RATE_DATE
      , PROGRAM_ID
      , CONTEXT
      , SHIPMENT_PRIORITY_CODE
      , CANCELLED_FLAG
      , DELIVER_TO_ORG_ID
      , PARTIAL_SHIPMENTS_ALLOWED
      , DELIVER_TO_CONTACT_ID
      , CUSTOMER_SIGNATURE_DATE
      , GLOBAL_ATTRIBUTE5
      , GLOBAL_ATTRIBUTE4
      , GLOBAL_ATTRIBUTE7
      , GLOBAL_ATTRIBUTE6
      , GLOBAL_ATTRIBUTE1
      , ORDER_FIRMED_DATE
      , GLOBAL_ATTRIBUTE3
      , GLOBAL_ATTRIBUTE2
      , PAYMENT_TYPE_CODE
      , UPGRADED_FLAG
      , FOB_POINT_CODE
      , GLOBAL_ATTRIBUTE9
      , GLOBAL_ATTRIBUTE8
      , TAX_EXEMPT_REASON_CODE
      , ORDER_SOURCE_ID
      , ATTRIBUTE3
      , ATTRIBUTE2
      , DEFAULT_FULFILLMENT_SET
      , ATTRIBUTE1
      , CREDIT_CARD_APPROVAL_CODE
      , TP_ATTRIBUTE15
      , FREIGHT_CARRIER_CODE
      , TP_ATTRIBUTE14
      , CREDIT_CARD_EXPIRATION_DATE
      , LAST_ACK_DATE
      , TP_ATTRIBUTE13
      , TP_ATTRIBUTE12
      , TP_ATTRIBUTE11
      , TP_ATTRIBUTE10
      , ATTRIBUTE9
      , BOOKED_FLAG
      , ATTRIBUTE8
      , ATTRIBUTE7
      , ATTRIBUTE6
      , SUPPLIER_SIGNATURE_DATE
      , ATTRIBUTE5
      , ATTRIBUTE4
      , CUST_PO_NUMBER
      , TRANSACTION_PHASE_CODE
      , AGREEMENT_ID
      , CONVERSION_TYPE_CODE
      , SHIP_TOLERANCE_BELOW
      , BLANKET_NUMBER
      , TRANSACTIONAL_CURR_CODE
      , ORDER_CATEGORY_CODE
      , ATTRIBUTE10
      , ORIG_SYS_DOCUMENT_REF
      , SHIP_TO_CONTACT_ID
      , TP_CONTEXT
      , ATTRIBUTE14
      , CUSTOMER_SIGNATURE
      , ATTRIBUTE13
      , CUSTOMER_PAYMENT_TERM_ID
      , ATTRIBUTE12
      , ATTRIBUTE11
      , IB_INSTALLED_AT_LOCATION
      , DROP_SHIP_FLAG
      , SHIP_TOLERANCE_ABOVE
      , FLOW_STATUS_CODE
      , VERSION_NUMBER
      , SALES_CHANNEL_CODE
      , SOLD_TO_CONTACT_ID
      , CHECK_NUMBER
      , SALESREP_ID
      , ACCOUNTING_RULE_DURATION
      , ORDER_TYPE_ID
      , LINE_SET_NAME
      , INVOICE_TO_CONTACT_ID
      , ATTRIBUTE20
      , SUPPLIER_SIGNATURE
      , GLOBAL_ATTRIBUTE20
      , SALES_DOCUMENT_NAME
      , GLOBAL_ATTRIBUTE17
      , GLOBAL_ATTRIBUTE18
      , GLOBAL_ATTRIBUTE15
      , GLOBAL_ATTRIBUTE16
      , GLOBAL_ATTRIBUTE13
      , GLOBAL_ATTRIBUTE14
      , RETURN_REASON_CODE
      , GLOBAL_ATTRIBUTE11
      , GLOBAL_ATTRIBUTE12
      , ATTRIBUTE18
      , ATTRIBUTE17
      , ATTRIBUTE16
      , ATTRIBUTE15
      , GLOBAL_ATTRIBUTE19
      , ATTRIBUTE19
      , FIRST_ACK_CODE
      , TAX_POINT_CODE
      , USER_STATUS_CODE
      , GLOBAL_ATTRIBUTE10
      , LOCK_CONTROL
      , SHIP_TO_ORG_ID
      , INVOICE_TO_ORG_ID
      , CHANGE_SEQUENCE
      , TP_ATTRIBUTE9
      , SOURCE_DOCUMENT_TYPE_ID
      , SOLD_TO_SITE_USE_ID
      , SOLD_FROM_ORG_ID
      , CREATED_BY
      , SHIPPING_INSTRUCTIONS
      , LAST_UPDATED_BY
      , EARLIEST_SCHEDULE_LIMIT
      , PAYMENT_TERM_ID
      , SHIPPING_METHOD_CODE
      , SOURCE_DOCUMENT_ID
      , PRICE_LIST_ID
      , TP_ATTRIBUTE8
      , INVOICING_RULE_ID
      , TP_ATTRIBUTE7
      , TP_ATTRIBUTE6
      , TP_ATTRIBUTE5
      , TP_ATTRIBUTE4
      , FULFILLMENT_SET_NAME
      , TP_ATTRIBUTE3
      , TP_ATTRIBUTE2
      , TP_ATTRIBUTE1
      , CUSTOMER_PREFERENCE_SET_CODE
      , END_CUSTOMER_CONTACT_ID
      , CREDIT_CARD_HOLDER_NAME
      , PAYMENT_AMOUNT
      , PROGRAM_APPLICATION_ID
      , PACKING_INSTRUCTIONS
      , END_CUSTOMER_ID
      , OPEN_FLAG
      , CREDIT_CARD_CODE
      , SHIP_FROM_ORG_ID
      , IB_OWNER
      , FIRST_ACK_DATE
      , QUOTE_NUMBER
      , SALES_DOCUMENT_TYPE_CODE
      , TAX_EXEMPT_NUMBER
      , REQUEST_ID
      , BATCH_ID
      , MARKETING_SOURCE_CODE_ID
      , DRAFT_SUBMITTED_FLAG
      , XML_MESSAGE_ID
      , LATEST_SCHEDULE_LIMIT
      , TAX_EXEMPT_FLAG
      , CREDIT_CARD_NUMBER
      , LAST_ACK_CODE
      , SOLD_TO_ORG_ID
      , CONVERSION_RATE
      , PRICE_REQUEST_CODE
      , ORDER_DATE_TYPE_CODE
      , LAST_UPDATE_LOGIN
      , ACCOUNTING_RULE_ID
      , END_CUSTOMER_SITE_USE_ID
      , GLOBAL_ATTRIBUTE_CATEGORY
      , DEMAND_CLASS_CODE
      , FREIGHT_TERMS_CODE
      , PROGRAM_UPDATE_DATE
      , MINISITE_ID
      , CREDIT_CARD_APPROVAL_DATE
      , BOOKED_DATE
      , ORDERED_DATE
      , REQUEST_DATE
      , CREATION_DATE
      , QUOTE_DATE
      , PRICING_DATE
      , EXPIRATION_DATE
      , LAST_UPDATE_DATE
      , _FIVETRAN_DELETED
      , _FIVETRAN_ID
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
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
    WHERE rec_src = 'USWIOC.ORCL.EBSPRD.ORDER_HEADERS'
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
          ORDER_HEADER_BK
        , ORDER_NUMBER
        , HEADER_ID
        , SOLD_TO_PHONE_ID
        , ORG_ID
        , SOURCE_DOCUMENT_VERSION_NUMBER
        , IB_CURRENT_LOCATION
        , CONVERSION_RATE_DATE
        , PROGRAM_ID
        , CONTEXT
        , SHIPMENT_PRIORITY_CODE
        , CANCELLED_FLAG
        , DELIVER_TO_ORG_ID
        , PARTIAL_SHIPMENTS_ALLOWED
        , DELIVER_TO_CONTACT_ID
        , CUSTOMER_SIGNATURE_DATE
        , GLOBAL_ATTRIBUTE5
        , GLOBAL_ATTRIBUTE4
        , GLOBAL_ATTRIBUTE7
        , GLOBAL_ATTRIBUTE6
        , GLOBAL_ATTRIBUTE1
        , ORDER_FIRMED_DATE
        , GLOBAL_ATTRIBUTE3
        , GLOBAL_ATTRIBUTE2
        , PAYMENT_TYPE_CODE
        , UPGRADED_FLAG
        , FOB_POINT_CODE
        , GLOBAL_ATTRIBUTE9
        , GLOBAL_ATTRIBUTE8
        , TAX_EXEMPT_REASON_CODE
        , ORDER_SOURCE_ID
        , ATTRIBUTE3
        , ATTRIBUTE2
        , DEFAULT_FULFILLMENT_SET
        , ATTRIBUTE1
        , CREDIT_CARD_APPROVAL_CODE
        , TP_ATTRIBUTE15
        , FREIGHT_CARRIER_CODE
        , TP_ATTRIBUTE14
        , CREDIT_CARD_EXPIRATION_DATE
        , LAST_ACK_DATE
        , TP_ATTRIBUTE13
        , TP_ATTRIBUTE12
        , TP_ATTRIBUTE11
        , TP_ATTRIBUTE10
        , ATTRIBUTE9
        , BOOKED_FLAG
        , ATTRIBUTE8
        , ATTRIBUTE7
        , ATTRIBUTE6
        , SUPPLIER_SIGNATURE_DATE
        , ATTRIBUTE5
        , ATTRIBUTE4
        , CUST_PO_NUMBER
        , TRANSACTION_PHASE_CODE
        , AGREEMENT_ID
        , CONVERSION_TYPE_CODE
        , SHIP_TOLERANCE_BELOW
        , BLANKET_NUMBER
        , TRANSACTIONAL_CURR_CODE
        , ORDER_CATEGORY_CODE
        , ATTRIBUTE10
        , ORIG_SYS_DOCUMENT_REF
        , SHIP_TO_CONTACT_ID
        , TP_CONTEXT
        , ATTRIBUTE14
        , CUSTOMER_SIGNATURE
        , ATTRIBUTE13
        , CUSTOMER_PAYMENT_TERM_ID
        , ATTRIBUTE12
        , ATTRIBUTE11
        , IB_INSTALLED_AT_LOCATION
        , DROP_SHIP_FLAG
        , SHIP_TOLERANCE_ABOVE
        , FLOW_STATUS_CODE
        , VERSION_NUMBER
        , SALES_CHANNEL_CODE
        , SOLD_TO_CONTACT_ID
        , CHECK_NUMBER
        , SALESREP_ID
        , ACCOUNTING_RULE_DURATION
        , ORDER_TYPE_ID
        , LINE_SET_NAME
        , INVOICE_TO_CONTACT_ID
        , ATTRIBUTE20
        , SUPPLIER_SIGNATURE
        , GLOBAL_ATTRIBUTE20
        , SALES_DOCUMENT_NAME
        , GLOBAL_ATTRIBUTE17
        , GLOBAL_ATTRIBUTE18
        , GLOBAL_ATTRIBUTE15
        , GLOBAL_ATTRIBUTE16
        , GLOBAL_ATTRIBUTE13
        , GLOBAL_ATTRIBUTE14
        , RETURN_REASON_CODE
        , GLOBAL_ATTRIBUTE11
        , GLOBAL_ATTRIBUTE12
        , ATTRIBUTE18
        , ATTRIBUTE17
        , ATTRIBUTE16
        , ATTRIBUTE15
        , GLOBAL_ATTRIBUTE19
        , ATTRIBUTE19
        , FIRST_ACK_CODE
        , TAX_POINT_CODE
        , USER_STATUS_CODE
        , GLOBAL_ATTRIBUTE10
        , LOCK_CONTROL
        , SHIP_TO_ORG_ID
        , INVOICE_TO_ORG_ID
        , CHANGE_SEQUENCE
        , TP_ATTRIBUTE9
        , SOURCE_DOCUMENT_TYPE_ID
        , SOLD_TO_SITE_USE_ID
        , SOLD_FROM_ORG_ID
        , CREATED_BY
        , SHIPPING_INSTRUCTIONS
        , LAST_UPDATED_BY
        , EARLIEST_SCHEDULE_LIMIT
        , PAYMENT_TERM_ID
        , SHIPPING_METHOD_CODE
        , SOURCE_DOCUMENT_ID
        , PRICE_LIST_ID
        , TP_ATTRIBUTE8
        , INVOICING_RULE_ID
        , TP_ATTRIBUTE7
        , TP_ATTRIBUTE6
        , TP_ATTRIBUTE5
        , TP_ATTRIBUTE4
        , FULFILLMENT_SET_NAME
        , TP_ATTRIBUTE3
        , TP_ATTRIBUTE2
        , TP_ATTRIBUTE1
        , CUSTOMER_PREFERENCE_SET_CODE
        , END_CUSTOMER_CONTACT_ID
        , CREDIT_CARD_HOLDER_NAME
        , PAYMENT_AMOUNT
        , PROGRAM_APPLICATION_ID
        , PACKING_INSTRUCTIONS
        , END_CUSTOMER_ID
        , OPEN_FLAG
        , CREDIT_CARD_CODE
        , SHIP_FROM_ORG_ID
        , IB_OWNER
        , FIRST_ACK_DATE
        , QUOTE_NUMBER
        , SALES_DOCUMENT_TYPE_CODE
        , TAX_EXEMPT_NUMBER
        , REQUEST_ID
        , BATCH_ID
        , MARKETING_SOURCE_CODE_ID
        , DRAFT_SUBMITTED_FLAG
        , XML_MESSAGE_ID
        , LATEST_SCHEDULE_LIMIT
        , TAX_EXEMPT_FLAG
        , CREDIT_CARD_NUMBER
        , LAST_ACK_CODE
        , SOLD_TO_ORG_ID
        , CONVERSION_RATE
        , PRICE_REQUEST_CODE
        , ORDER_DATE_TYPE_CODE
        , LAST_UPDATE_LOGIN
        , ACCOUNTING_RULE_ID
        , END_CUSTOMER_SITE_USE_ID
        , GLOBAL_ATTRIBUTE_CATEGORY
        , DEMAND_CLASS_CODE
        , FREIGHT_TERMS_CODE
        , PROGRAM_UPDATE_DATE
        , MINISITE_ID
        , CREDIT_CARD_APPROVAL_DATE
        , BOOKED_DATE
        , ORDERED_DATE
        , REQUEST_DATE
        , CREATION_DATE
        , QUOTE_DATE
        , PRICING_DATE
        , EXPIRATION_DATE
        , LAST_UPDATE_DATE
        , _FIVETRAN_DELETED
        , _FIVETRAN_ID
        , _FIVETRAN_SYNCED
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ORDER_NUMBER as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ORDER_HEADER_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(ORDER_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(HEADER_ID::text), '^^') 
            , '||', IFNULL(TRIM(SOLD_TO_PHONE_ID::text), '^^') 
            , '||', IFNULL(TRIM(ORG_ID::text), '^^') 
            , '||', IFNULL(TRIM(SOURCE_DOCUMENT_VERSION_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(IB_CURRENT_LOCATION::text), '^^') 
            , '||', IFNULL(TRIM(CONVERSION_RATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_ID::text), '^^') 
            , '||', IFNULL(TRIM(CONTEXT::text), '^^') 
            , '||', IFNULL(TRIM(SHIPMENT_PRIORITY_CODE::text), '^^') 
            , '||', IFNULL(TRIM(CANCELLED_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(DELIVER_TO_ORG_ID::text), '^^') 
            , '||', IFNULL(TRIM(PARTIAL_SHIPMENTS_ALLOWED::text), '^^') 
            , '||', IFNULL(TRIM(DELIVER_TO_CONTACT_ID::text), '^^') 
            , '||', IFNULL(TRIM(CUSTOMER_SIGNATURE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE5::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE4::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE7::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE6::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE1::text), '^^') 
            , '||', IFNULL(TRIM(ORDER_FIRMED_DATE::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE3::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE2::text), '^^') 
            , '||', IFNULL(TRIM(PAYMENT_TYPE_CODE::text), '^^') 
            , '||', IFNULL(TRIM(UPGRADED_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(FOB_POINT_CODE::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE9::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE8::text), '^^') 
            , '||', IFNULL(TRIM(TAX_EXEMPT_REASON_CODE::text), '^^') 
            , '||', IFNULL(TRIM(ORDER_SOURCE_ID::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE3::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE2::text), '^^') 
            , '||', IFNULL(TRIM(DEFAULT_FULFILLMENT_SET::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE1::text), '^^') 
            , '||', IFNULL(TRIM(CREDIT_CARD_APPROVAL_CODE::text), '^^') 
            , '||', IFNULL(TRIM(TP_ATTRIBUTE15::text), '^^') 
            , '||', IFNULL(TRIM(FREIGHT_CARRIER_CODE::text), '^^') 
            , '||', IFNULL(TRIM(TP_ATTRIBUTE14::text), '^^') 
            , '||', IFNULL(TRIM(CREDIT_CARD_EXPIRATION_DATE::text), '^^') 
            , '||', IFNULL(TRIM(LAST_ACK_DATE::text), '^^') 
            , '||', IFNULL(TRIM(TP_ATTRIBUTE13::text), '^^') 
            , '||', IFNULL(TRIM(TP_ATTRIBUTE12::text), '^^') 
            , '||', IFNULL(TRIM(TP_ATTRIBUTE11::text), '^^') 
            , '||', IFNULL(TRIM(TP_ATTRIBUTE10::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE9::text), '^^') 
            , '||', IFNULL(TRIM(BOOKED_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE8::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE7::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE6::text), '^^') 
            , '||', IFNULL(TRIM(SUPPLIER_SIGNATURE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE5::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE4::text), '^^') 
            , '||', IFNULL(TRIM(CUST_PO_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(TRANSACTION_PHASE_CODE::text), '^^') 
            , '||', IFNULL(TRIM(AGREEMENT_ID::text), '^^') 
            , '||', IFNULL(TRIM(CONVERSION_TYPE_CODE::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_TOLERANCE_BELOW::text), '^^') 
            , '||', IFNULL(TRIM(BLANKET_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(TRANSACTIONAL_CURR_CODE::text), '^^') 
            , '||', IFNULL(TRIM(ORDER_CATEGORY_CODE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE10::text), '^^') 
            , '||', IFNULL(TRIM(ORIG_SYS_DOCUMENT_REF::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_TO_CONTACT_ID::text), '^^') 
            , '||', IFNULL(TRIM(TP_CONTEXT::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE14::text), '^^') 
            , '||', IFNULL(TRIM(CUSTOMER_SIGNATURE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE13::text), '^^') 
            , '||', IFNULL(TRIM(CUSTOMER_PAYMENT_TERM_ID::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE12::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE11::text), '^^') 
            , '||', IFNULL(TRIM(IB_INSTALLED_AT_LOCATION::text), '^^') 
            , '||', IFNULL(TRIM(DROP_SHIP_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_TOLERANCE_ABOVE::text), '^^') 
            , '||', IFNULL(TRIM(FLOW_STATUS_CODE::text), '^^') 
            , '||', IFNULL(TRIM(VERSION_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(SALES_CHANNEL_CODE::text), '^^') 
            , '||', IFNULL(TRIM(SOLD_TO_CONTACT_ID::text), '^^') 
            , '||', IFNULL(TRIM(CHECK_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(SALESREP_ID::text), '^^') 
            , '||', IFNULL(TRIM(ACCOUNTING_RULE_DURATION::text), '^^') 
            , '||', IFNULL(TRIM(ORDER_TYPE_ID::text), '^^') 
            , '||', IFNULL(TRIM(LINE_SET_NAME::text), '^^') 
            , '||', IFNULL(TRIM(INVOICE_TO_CONTACT_ID::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE20::text), '^^') 
            , '||', IFNULL(TRIM(SUPPLIER_SIGNATURE::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE20::text), '^^') 
            , '||', IFNULL(TRIM(SALES_DOCUMENT_NAME::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE17::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE18::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE15::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE16::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE13::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE14::text), '^^') 
            , '||', IFNULL(TRIM(RETURN_REASON_CODE::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE11::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE12::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE18::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE17::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE16::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE15::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE19::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE19::text), '^^') 
            , '||', IFNULL(TRIM(FIRST_ACK_CODE::text), '^^') 
            , '||', IFNULL(TRIM(TAX_POINT_CODE::text), '^^') 
            , '||', IFNULL(TRIM(USER_STATUS_CODE::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE10::text), '^^') 
            , '||', IFNULL(TRIM(LOCK_CONTROL::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_TO_ORG_ID::text), '^^') 
            , '||', IFNULL(TRIM(INVOICE_TO_ORG_ID::text), '^^') 
            , '||', IFNULL(TRIM(CHANGE_SEQUENCE::text), '^^') 
            , '||', IFNULL(TRIM(TP_ATTRIBUTE9::text), '^^') 
            , '||', IFNULL(TRIM(SOURCE_DOCUMENT_TYPE_ID::text), '^^') 
            , '||', IFNULL(TRIM(SOLD_TO_SITE_USE_ID::text), '^^') 
            , '||', IFNULL(TRIM(SOLD_FROM_ORG_ID::text), '^^') 
            , '||', IFNULL(TRIM(CREATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(SHIPPING_INSTRUCTIONS::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(EARLIEST_SCHEDULE_LIMIT::text), '^^') 
            , '||', IFNULL(TRIM(PAYMENT_TERM_ID::text), '^^') 
            , '||', IFNULL(TRIM(SHIPPING_METHOD_CODE::text), '^^') 
            , '||', IFNULL(TRIM(SOURCE_DOCUMENT_ID::text), '^^') 
            , '||', IFNULL(TRIM(PRICE_LIST_ID::text), '^^') 
            , '||', IFNULL(TRIM(TP_ATTRIBUTE8::text), '^^') 
            , '||', IFNULL(TRIM(INVOICING_RULE_ID::text), '^^') 
            , '||', IFNULL(TRIM(TP_ATTRIBUTE7::text), '^^') 
            , '||', IFNULL(TRIM(TP_ATTRIBUTE6::text), '^^') 
            , '||', IFNULL(TRIM(TP_ATTRIBUTE5::text), '^^') 
            , '||', IFNULL(TRIM(TP_ATTRIBUTE4::text), '^^') 
            , '||', IFNULL(TRIM(FULFILLMENT_SET_NAME::text), '^^') 
            , '||', IFNULL(TRIM(TP_ATTRIBUTE3::text), '^^') 
            , '||', IFNULL(TRIM(TP_ATTRIBUTE2::text), '^^') 
            , '||', IFNULL(TRIM(TP_ATTRIBUTE1::text), '^^') 
            , '||', IFNULL(TRIM(CUSTOMER_PREFERENCE_SET_CODE::text), '^^') 
            , '||', IFNULL(TRIM(END_CUSTOMER_CONTACT_ID::text), '^^') 
            , '||', IFNULL(TRIM(CREDIT_CARD_HOLDER_NAME::text), '^^') 
            , '||', IFNULL(TRIM(PAYMENT_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_APPLICATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(PACKING_INSTRUCTIONS::text), '^^') 
            , '||', IFNULL(TRIM(END_CUSTOMER_ID::text), '^^') 
            , '||', IFNULL(TRIM(OPEN_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(CREDIT_CARD_CODE::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_FROM_ORG_ID::text), '^^') 
            , '||', IFNULL(TRIM(IB_OWNER::text), '^^') 
            , '||', IFNULL(TRIM(FIRST_ACK_DATE::text), '^^') 
            , '||', IFNULL(TRIM(QUOTE_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(SALES_DOCUMENT_TYPE_CODE::text), '^^') 
            , '||', IFNULL(TRIM(TAX_EXEMPT_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(REQUEST_ID::text), '^^') 
            , '||', IFNULL(TRIM(BATCH_ID::text), '^^') 
            , '||', IFNULL(TRIM(MARKETING_SOURCE_CODE_ID::text), '^^') 
            , '||', IFNULL(TRIM(DRAFT_SUBMITTED_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(XML_MESSAGE_ID::text), '^^') 
            , '||', IFNULL(TRIM(LATEST_SCHEDULE_LIMIT::text), '^^') 
            , '||', IFNULL(TRIM(TAX_EXEMPT_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(CREDIT_CARD_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(LAST_ACK_CODE::text), '^^') 
            , '||', IFNULL(TRIM(SOLD_TO_ORG_ID::text), '^^') 
            , '||', IFNULL(TRIM(CONVERSION_RATE::text), '^^') 
            , '||', IFNULL(TRIM(PRICE_REQUEST_CODE::text), '^^') 
            , '||', IFNULL(TRIM(ORDER_DATE_TYPE_CODE::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_LOGIN::text), '^^') 
            , '||', IFNULL(TRIM(ACCOUNTING_RULE_ID::text), '^^') 
            , '||', IFNULL(TRIM(END_CUSTOMER_SITE_USE_ID::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(DEMAND_CLASS_CODE::text), '^^') 
            , '||', IFNULL(TRIM(FREIGHT_TERMS_CODE::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_UPDATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(MINISITE_ID::text), '^^') 
            , '||', IFNULL(TRIM(CREDIT_CARD_APPROVAL_DATE::text), '^^') 
            , '||', IFNULL(TRIM(BOOKED_DATE::text), '^^') 
            , '||', IFNULL(TRIM(ORDERED_DATE::text), '^^') 
            , '||', IFNULL(TRIM(REQUEST_DATE::text), '^^') 
            , '||', IFNULL(TRIM(CREATION_DATE::text), '^^') 
            , '||', IFNULL(TRIM(QUOTE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(PRICING_DATE::text), '^^') 
            , '||', IFNULL(TRIM(EXPIRATION_DATE::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
