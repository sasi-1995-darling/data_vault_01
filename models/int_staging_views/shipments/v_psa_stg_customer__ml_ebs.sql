---- SRC LAYER ----
WITH
SRC_a              as ( SELECT * FROM {{ source('ml_ebs_ar', 'hz_cust_accounts') }} as SRC  ),
SRC_b              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_a              as ( SELECT * FROM ml_ebs_ar.hz_cust_accounts )
, SRC_b              as ( SELECT * FROM raw_vault.REF_BUSINESS_KEY_COLLISION )
*/
---- LOGIC LAYER ----

, LOGIC_a as (
    SELECT
        ACCOUNT_NUMBER                                               as                                        CUSTOMER_BK
      , ACCOUNT_ACTIVATION_DATE
      , ACCOUNT_ESTABLISHED_DATE
      , ACCOUNT_LIABLE_FLAG
      , ACCOUNT_NAME
      , ACCOUNT_NUMBER
      , ACCOUNT_REPLICATION_KEY
      , ACCOUNT_TERMINATION_DATE
      , ACCT_LIFE_CYCLE_STATUS
      , APPLICATION_ID
      , ARRIVALSETS_INCLUDE_LINES_FLAG
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
      , ATTRIBUTE16
      , ATTRIBUTE17
      , ATTRIBUTE18
      , ATTRIBUTE19
      , ATTRIBUTE20
      , ATTRIBUTE_CATEGORY
      , AUTOPAY_FLAG
      , COMMENTS
      , COMPETITOR_TYPE
      , COTERMINATE_DAY_MONTH
      , CREATED_BY
      , CREATED_BY_MODULE
      , CREATION_DATE
      , CREDIT_CLASSIFICATION_CODE
      , CURRENT_BALANCE
      , CUSTOMER_CLASS_CODE
      , CUSTOMER_TYPE
      , CUST_ACCOUNT_ID
      , DATES_NEGATIVE_TOLERANCE
      , DATES_POSITIVE_TOLERANCE
      , DATE_TYPE_PREFERENCE
      , DEPARTMENT
      , DEPOSIT_REFUND_METHOD
      , DORMANT_ACCOUNT_FLAG
      , FOB_POINT
      , FREIGHT_TERM
      , GEO_CODE
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
      , GLOBAL_ATTRIBUTE_CATEGORY
      , HELD_BILL_EXPIRATION_DATE
      , HIGH_PRIORITY_INDICATOR
      , HIGH_PRIORITY_REMARKS
      , HOLD_BILL_FLAG
      , HOTWATCH_SERVICE_FLAG
      , HOTWATCH_SVC_BAL_IND
      , INVOICE_QUANTITY_RULE
      , ITEM_CROSS_REF_PREF
      , LAST_BATCH_ID
      , LAST_UPDATED_BY
      , LAST_UPDATE_DATE
      , LAST_UPDATE_LOGIN
      , MAJOR_ACCOUNT_NUMBER
      , NOTIFY_FLAG
      , NPA_NUMBER
      , OBJECT_VERSION_NUMBER
      , ORDER_TYPE_ID
      , ORG_ID
      , ORIG_SYSTEM_REFERENCE
      , OVER_RETURN_TOLERANCE
      , OVER_SHIPMENT_TOLERANCE
      , PARTY_ID
      , PASSWORD_TEXT
      , PAYMENT_TERM_ID
      , PIN_NUMBER
      , PO_EFFECTIVE_DATE
      , PO_EXPIRATION_DATE
      , PRICE_LIST_ID
      , PRICING_EVENT
      , PRIMARY_SALESREP_ID
      , PRIMARY_SPECIALIST_ID
      , PROGRAM_APPLICATION_ID
      , PROGRAM_ID
      , PROGRAM_UPDATE_DATE
      , REALTIME_RATE_FLAG
      , REQUEST_ID
      , RESTRICTION_LIMIT_AMOUNT
      , SALES_CHANNEL_CODE
      , SCHED_DATE_PUSH_FLAG
      , SECONDARY_SPECIALIST_ID
      , SELLING_PARTY_ID
      , SHIP_PARTIAL
      , SHIP_SETS_INCLUDE_LINES_FLAG
      , SHIP_VIA
      , SINGLE_USER_FLAG
      , SOURCE_CODE
      , STATUS
      , STATUS_UPDATE_DATE
      , SUBCATEGORY_CODE
      , SUSPENSION_DATE
      , TAX_CODE
      , TAX_HEADER_LEVEL_FLAG
      , TAX_ROUNDING_RULE
      , UNDER_RETURN_TOLERANCE
      , UNDER_SHIPMENT_TOLERANCE
      , WAREHOUSE_ID
      , WATCH_ACCOUNT_FLAG
      , WATCH_BALANCE_INDICATOR
      , WH_UPDATE_DATE
      , WRITE_OFF_ADJUSTMENT_AMOUNT
      , WRITE_OFF_AMOUNT
      , WRITE_OFF_PAYMENT_AMOUNT
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , CONVERT_TIMEZONE('UTC', PSA_LOAD_DTS)                        as                                           LOAD_DTS
    FROM SRC_a
)

, LOGIC_b as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_b
)
---- RENAME LAYER ----

, RENAME_a as (
    SELECT
        CUSTOMER_BK
      , ACCOUNT_ACTIVATION_DATE
      , ACCOUNT_ESTABLISHED_DATE
      , ACCOUNT_LIABLE_FLAG
      , ACCOUNT_NAME
      , ACCOUNT_NUMBER
      , ACCOUNT_REPLICATION_KEY
      , ACCOUNT_TERMINATION_DATE
      , ACCT_LIFE_CYCLE_STATUS
      , APPLICATION_ID
      , ARRIVALSETS_INCLUDE_LINES_FLAG
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
      , ATTRIBUTE16
      , ATTRIBUTE17
      , ATTRIBUTE18
      , ATTRIBUTE19
      , ATTRIBUTE20
      , ATTRIBUTE_CATEGORY
      , AUTOPAY_FLAG
      , COMMENTS
      , COMPETITOR_TYPE
      , COTERMINATE_DAY_MONTH
      , CREATED_BY
      , CREATED_BY_MODULE
      , CREATION_DATE
      , CREDIT_CLASSIFICATION_CODE
      , CURRENT_BALANCE
      , CUSTOMER_CLASS_CODE
      , CUSTOMER_TYPE
      , CUST_ACCOUNT_ID
      , DATES_NEGATIVE_TOLERANCE
      , DATES_POSITIVE_TOLERANCE
      , DATE_TYPE_PREFERENCE
      , DEPARTMENT
      , DEPOSIT_REFUND_METHOD
      , DORMANT_ACCOUNT_FLAG
      , FOB_POINT
      , FREIGHT_TERM
      , GEO_CODE
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
      , GLOBAL_ATTRIBUTE_CATEGORY
      , HELD_BILL_EXPIRATION_DATE
      , HIGH_PRIORITY_INDICATOR
      , HIGH_PRIORITY_REMARKS
      , HOLD_BILL_FLAG
      , HOTWATCH_SERVICE_FLAG
      , HOTWATCH_SVC_BAL_IND
      , INVOICE_QUANTITY_RULE
      , ITEM_CROSS_REF_PREF
      , LAST_BATCH_ID
      , LAST_UPDATED_BY
      , LAST_UPDATE_DATE
      , LAST_UPDATE_LOGIN
      , MAJOR_ACCOUNT_NUMBER
      , NOTIFY_FLAG
      , NPA_NUMBER
      , OBJECT_VERSION_NUMBER
      , ORDER_TYPE_ID
      , ORG_ID
      , ORIG_SYSTEM_REFERENCE
      , OVER_RETURN_TOLERANCE
      , OVER_SHIPMENT_TOLERANCE
      , PARTY_ID
      , PASSWORD_TEXT
      , PAYMENT_TERM_ID
      , PIN_NUMBER
      , PO_EFFECTIVE_DATE
      , PO_EXPIRATION_DATE
      , PRICE_LIST_ID
      , PRICING_EVENT
      , PRIMARY_SALESREP_ID
      , PRIMARY_SPECIALIST_ID
      , PROGRAM_APPLICATION_ID
      , PROGRAM_ID
      , PROGRAM_UPDATE_DATE
      , REALTIME_RATE_FLAG
      , REQUEST_ID
      , RESTRICTION_LIMIT_AMOUNT
      , SALES_CHANNEL_CODE
      , SCHED_DATE_PUSH_FLAG
      , SECONDARY_SPECIALIST_ID
      , SELLING_PARTY_ID
      , SHIP_PARTIAL
      , SHIP_SETS_INCLUDE_LINES_FLAG
      , SHIP_VIA
      , SINGLE_USER_FLAG
      , SOURCE_CODE
      , STATUS
      , STATUS_UPDATE_DATE
      , SUBCATEGORY_CODE
      , SUSPENSION_DATE
      , TAX_CODE
      , TAX_HEADER_LEVEL_FLAG
      , TAX_ROUNDING_RULE
      , UNDER_RETURN_TOLERANCE
      , UNDER_SHIPMENT_TOLERANCE
      , WAREHOUSE_ID
      , WATCH_ACCOUNT_FLAG
      , WATCH_BALANCE_INDICATOR
      , WH_UPDATE_DATE
      , WRITE_OFF_ADJUSTMENT_AMOUNT
      , WRITE_OFF_AMOUNT
      , WRITE_OFF_PAYMENT_AMOUNT
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , LOAD_DTS
    FROM LOGIC_a
)

, RENAME_b as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_b
)
---- FILTER LAYER ----

, FILTER_a as (
    SELECT *
    FROM RENAME_a
)

, FILTER_b as (
    SELECT *
    FROM RENAME_b
    WHERE rec_src = 'USWIOC.ORCL.EBSPRD.HZ_CUST_ACCOUNTS'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_a
    INNER JOIN FILTER_b
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          CUSTOMER_BK
        , ACCOUNT_ACTIVATION_DATE
        , ACCOUNT_ESTABLISHED_DATE
        , ACCOUNT_LIABLE_FLAG
        , ACCOUNT_NAME
        , ACCOUNT_NUMBER
        , ACCOUNT_REPLICATION_KEY
        , ACCOUNT_TERMINATION_DATE
        , ACCT_LIFE_CYCLE_STATUS
        , APPLICATION_ID
        , ARRIVALSETS_INCLUDE_LINES_FLAG
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
        , ATTRIBUTE16
        , ATTRIBUTE17
        , ATTRIBUTE18
        , ATTRIBUTE19
        , ATTRIBUTE20
        , ATTRIBUTE_CATEGORY
        , AUTOPAY_FLAG
        , COMMENTS
        , COMPETITOR_TYPE
        , COTERMINATE_DAY_MONTH
        , CREATED_BY
        , CREATED_BY_MODULE
        , CREATION_DATE
        , CREDIT_CLASSIFICATION_CODE
        , CURRENT_BALANCE
        , CUSTOMER_CLASS_CODE
        , CUSTOMER_TYPE
        , CUST_ACCOUNT_ID
        , DATES_NEGATIVE_TOLERANCE
        , DATES_POSITIVE_TOLERANCE
        , DATE_TYPE_PREFERENCE
        , DEPARTMENT
        , DEPOSIT_REFUND_METHOD
        , DORMANT_ACCOUNT_FLAG
        , FOB_POINT
        , FREIGHT_TERM
        , GEO_CODE
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
        , GLOBAL_ATTRIBUTE_CATEGORY
        , HELD_BILL_EXPIRATION_DATE
        , HIGH_PRIORITY_INDICATOR
        , HIGH_PRIORITY_REMARKS
        , HOLD_BILL_FLAG
        , HOTWATCH_SERVICE_FLAG
        , HOTWATCH_SVC_BAL_IND
        , INVOICE_QUANTITY_RULE
        , ITEM_CROSS_REF_PREF
        , LAST_BATCH_ID
        , LAST_UPDATED_BY
        , LAST_UPDATE_DATE
        , LAST_UPDATE_LOGIN
        , MAJOR_ACCOUNT_NUMBER
        , NOTIFY_FLAG
        , NPA_NUMBER
        , OBJECT_VERSION_NUMBER
        , ORDER_TYPE_ID
        , ORG_ID
        , ORIG_SYSTEM_REFERENCE
        , OVER_RETURN_TOLERANCE
        , OVER_SHIPMENT_TOLERANCE
        , PARTY_ID
        , PASSWORD_TEXT
        , PAYMENT_TERM_ID
        , PIN_NUMBER
        , PO_EFFECTIVE_DATE
        , PO_EXPIRATION_DATE
        , PRICE_LIST_ID
        , PRICING_EVENT
        , PRIMARY_SALESREP_ID
        , PRIMARY_SPECIALIST_ID
        , PROGRAM_APPLICATION_ID
        , PROGRAM_ID
        , PROGRAM_UPDATE_DATE
        , REALTIME_RATE_FLAG
        , REQUEST_ID
        , RESTRICTION_LIMIT_AMOUNT
        , SALES_CHANNEL_CODE
        , SCHED_DATE_PUSH_FLAG
        , SECONDARY_SPECIALIST_ID
        , SELLING_PARTY_ID
        , SHIP_PARTIAL
        , SHIP_SETS_INCLUDE_LINES_FLAG
        , SHIP_VIA
        , SINGLE_USER_FLAG
        , SOURCE_CODE
        , STATUS
        , STATUS_UPDATE_DATE
        , SUBCATEGORY_CODE
        , SUSPENSION_DATE
        , TAX_CODE
        , TAX_HEADER_LEVEL_FLAG
        , TAX_ROUNDING_RULE
        , UNDER_RETURN_TOLERANCE
        , UNDER_SHIPMENT_TOLERANCE
        , WAREHOUSE_ID
        , WATCH_ACCOUNT_FLAG
        , WATCH_BALANCE_INDICATOR
        , WH_UPDATE_DATE
        , WRITE_OFF_ADJUSTMENT_AMOUNT
        , WRITE_OFF_AMOUNT
        , WRITE_OFF_PAYMENT_AMOUNT
        , _FIVETRAN_DELETED
        , _FIVETRAN_SYNCED
        , PSA_DELETE_IND
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ACCOUNT_NUMBER as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as CUSTOMER_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(ACCOUNT_ACTIVATION_DATE::text), '^^') 
            , '||', IFNULL(TRIM(ACCOUNT_ESTABLISHED_DATE::text), '^^') 
            , '||', IFNULL(TRIM(ACCOUNT_LIABLE_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(ACCOUNT_NAME::text), '^^') 
            , '||', IFNULL(TRIM(ACCOUNT_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(ACCOUNT_REPLICATION_KEY::text), '^^') 
            , '||', IFNULL(TRIM(ACCOUNT_TERMINATION_DATE::text), '^^') 
            , '||', IFNULL(TRIM(ACCT_LIFE_CYCLE_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(APPLICATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(ARRIVALSETS_INCLUDE_LINES_FLAG::text), '^^') 
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
            , '||', IFNULL(TRIM(ATTRIBUTE16::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE17::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE18::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE19::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE20::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(AUTOPAY_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(COMMENTS::text), '^^') 
            , '||', IFNULL(TRIM(COMPETITOR_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(COTERMINATE_DAY_MONTH::text), '^^') 
            , '||', IFNULL(TRIM(CREATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(CREATED_BY_MODULE::text), '^^') 
            , '||', IFNULL(TRIM(CREATION_DATE::text), '^^') 
            , '||', IFNULL(TRIM(CREDIT_CLASSIFICATION_CODE::text), '^^') 
            , '||', IFNULL(TRIM(CURRENT_BALANCE::text), '^^') 
            , '||', IFNULL(TRIM(CUSTOMER_CLASS_CODE::text), '^^') 
            , '||', IFNULL(TRIM(CUSTOMER_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(CUST_ACCOUNT_ID::text), '^^') 
            , '||', IFNULL(TRIM(DATES_NEGATIVE_TOLERANCE::text), '^^') 
            , '||', IFNULL(TRIM(DATES_POSITIVE_TOLERANCE::text), '^^') 
            , '||', IFNULL(TRIM(DATE_TYPE_PREFERENCE::text), '^^') 
            , '||', IFNULL(TRIM(DEPARTMENT::text), '^^') 
            , '||', IFNULL(TRIM(DEPOSIT_REFUND_METHOD::text), '^^') 
            , '||', IFNULL(TRIM(DORMANT_ACCOUNT_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(FOB_POINT::text), '^^') 
            , '||', IFNULL(TRIM(FREIGHT_TERM::text), '^^') 
            , '||', IFNULL(TRIM(GEO_CODE::text), '^^') 
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
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(HELD_BILL_EXPIRATION_DATE::text), '^^') 
            , '||', IFNULL(TRIM(HIGH_PRIORITY_INDICATOR::text), '^^') 
            , '||', IFNULL(TRIM(HIGH_PRIORITY_REMARKS::text), '^^') 
            , '||', IFNULL(TRIM(HOLD_BILL_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(HOTWATCH_SERVICE_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(HOTWATCH_SVC_BAL_IND::text), '^^') 
            , '||', IFNULL(TRIM(INVOICE_QUANTITY_RULE::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_CROSS_REF_PREF::text), '^^') 
            , '||', IFNULL(TRIM(LAST_BATCH_ID::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_LOGIN::text), '^^') 
            , '||', IFNULL(TRIM(MAJOR_ACCOUNT_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(NOTIFY_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(NPA_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(OBJECT_VERSION_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(ORDER_TYPE_ID::text), '^^') 
            , '||', IFNULL(TRIM(ORG_ID::text), '^^') 
            , '||', IFNULL(TRIM(ORIG_SYSTEM_REFERENCE::text), '^^') 
            , '||', IFNULL(TRIM(OVER_RETURN_TOLERANCE::text), '^^') 
            , '||', IFNULL(TRIM(OVER_SHIPMENT_TOLERANCE::text), '^^') 
            , '||', IFNULL(TRIM(PARTY_ID::text), '^^') 
            , '||', IFNULL(TRIM(PASSWORD_TEXT::text), '^^') 
            , '||', IFNULL(TRIM(PAYMENT_TERM_ID::text), '^^') 
            , '||', IFNULL(TRIM(PIN_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(PO_EFFECTIVE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(PO_EXPIRATION_DATE::text), '^^') 
            , '||', IFNULL(TRIM(PRICE_LIST_ID::text), '^^') 
            , '||', IFNULL(TRIM(PRICING_EVENT::text), '^^') 
            , '||', IFNULL(TRIM(PRIMARY_SALESREP_ID::text), '^^') 
            , '||', IFNULL(TRIM(PRIMARY_SPECIALIST_ID::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_APPLICATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_ID::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_UPDATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(REALTIME_RATE_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(REQUEST_ID::text), '^^') 
            , '||', IFNULL(TRIM(RESTRICTION_LIMIT_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(SALES_CHANNEL_CODE::text), '^^') 
            , '||', IFNULL(TRIM(SCHED_DATE_PUSH_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(SECONDARY_SPECIALIST_ID::text), '^^') 
            , '||', IFNULL(TRIM(SELLING_PARTY_ID::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_PARTIAL::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_SETS_INCLUDE_LINES_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_VIA::text), '^^') 
            , '||', IFNULL(TRIM(SINGLE_USER_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(SOURCE_CODE::text), '^^') 
            , '||', IFNULL(TRIM(STATUS::text), '^^') 
            , '||', IFNULL(TRIM(STATUS_UPDATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(SUBCATEGORY_CODE::text), '^^') 
            , '||', IFNULL(TRIM(SUSPENSION_DATE::text), '^^') 
            , '||', IFNULL(TRIM(TAX_CODE::text), '^^') 
            , '||', IFNULL(TRIM(TAX_HEADER_LEVEL_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(TAX_ROUNDING_RULE::text), '^^') 
            , '||', IFNULL(TRIM(UNDER_RETURN_TOLERANCE::text), '^^') 
            , '||', IFNULL(TRIM(UNDER_SHIPMENT_TOLERANCE::text), '^^') 
            , '||', IFNULL(TRIM(WAREHOUSE_ID::text), '^^') 
            , '||', IFNULL(TRIM(WATCH_ACCOUNT_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(WATCH_BALANCE_INDICATOR::text), '^^') 
            , '||', IFNULL(TRIM(WH_UPDATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(WRITE_OFF_ADJUSTMENT_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(WRITE_OFF_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(WRITE_OFF_PAYMENT_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_SYNCED::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
            , '||', IFNULL(TRIM(PSA_RECORD_SOURCE::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
