---- SRC LAYER ----
WITH
SRC_S              as ( SELECT * FROM {{ source('outd_ocf_ar', 'ra_customer_trx_lines_all') }} as SRC  ),
SRC_A              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  ),
SRC_S2             as ( SELECT * FROM {{ source('outd_ocf_egp', 'egp_system_items_b') }} as SRC 
                        where organization_id = 300000034179011 /*Master Org*/
                         
                        qualify 1 = row_number()over (partition by inventory_item_id order by psa_load_dts )  )

/*
SRC_S              as ( SELECT * FROM outd_ocf_ar.ra_customer_trx_lines_all )
, SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
, SRC_S2             as ( SELECT * FROM outd_ocf_egp.egp_system_items_b )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        CONCAT(coalesce(CUSTOMER_TRX_ID, '-1'),'||',CUSTOMER_TRX_LINE_ID) as                                    INVOICE_LINE_BK
      , CUSTOMER_TRX_LINE_ID
      , CUSTOMER_TRX_ID
      , ATTRIBUTE_7
      , INTERFACE_LINE_ATTRIBUTE_4
      , ACCTD_AMOUNT_DUE_ORIGINAL
      , BILL_PLAN_LINE_ID
      , ATTRIBUTE_11
      , INTERFACE_LINE_ATTRIBUTE_6
      , SALES_ORDER_SOURCE
      , ACCOUNTING_RULE_ID
      , BILLING_PERIOD_START_DATE
      , GLOBAL_ATTRIBUTE_NUMBER_3
      , BR_ADJUSTMENT_ID
      , MISCELLANEOUS_CHARGE
      , TRANSLATED_DESCRIPTION
      , UNIT_STANDARD_PRICE
      , DOC_LINE_ID_CHAR_1
      , QUANTITY_INVOICED
      , TAX_INVOICE_DATE
      , GLOBAL_ATTRIBUTE_11
      , COMMERCIAL_DISCOUNT
      , OBJECT_VERSION_NUMBER
      , GLOBAL_ATTRIBUTE_20
      , ATTRIBUTE_NUMBER_3
      , PRODUCT_TYPE
      , ATTRIBUTE_NUMBER_2
      , GLOBAL_ATTRIBUTE_DATE_3
      , EXTENDED_AMOUNT
      , ATTRIBUTE_DATE_5
      , PREVIOUS_CUSTOMER_TRX_ID
      , GROSS_UNIT_SELLING_PRICE
      , FRT_ADJ_ACCTD_REMAINING
      , INTERFACE_LINE_ATTRIBUTE_14
      , ATTRIBUTE_13
      , TAX_RECOVERABLE
      , LINK_TO_PARENTLINE_ATTRIBUTE_14
      , SOURCE_DATA_KEY_5
      , LINE_INTENDED_USE
      , LINK_TO_PARENTLINE_ATTRIBUTE_4
      , CREATION_DATE
      , REVENUE_AMOUNT
      , GLOBAL_ATTRIBUTE_10
      , REASON_CODE
      , INTERFACE_LINE_ATTRIBUTE_7
      , SHIP_TO_PARTY_CONTACT_ID
      , GLOBAL_ATTRIBUTE_NUMBER_1
      , MOVEMENT_ID
      , MRC_EXTENDED_ACCTD_AMOUNT
      , TAX_PRECEDENCE
      , CONTRACT_START_DATE
      , LINE_TYPE
      , FRT_ED_AMOUNT
      , LAST_UPDATE_DATE
      , AMOUNT_INCLUDES_TAX_FLAG
      , SOURCE_DOCUMENT_LINE_ID
      , TAX_RATE
      , PROGRAM_APPLICATION_ID
      , SOURCE_DATA_KEY_2
      , LINK_TO_PARENTLINE_ATTRIBUTE_12
      , ORG_ID
      , ATTRIBUTE_1
      , DOC_LINE_ID_INT_5
      , INTERFACE_LINE_ATTRIBUTE_12
      , QUANTITY_CREDITED
      , WAREHOUSE_ID
      , INTERFACE_LINE_ATTRIBUTE_13
      , AUTH_COMPLETE_FLAG
      , DOC_LINE_ID_INT_2
      , INVENTORY_ITEM_ID
      , LINE_RECOVERABLE
      , FRT_UNED_AMOUNT
      , INTERFACE_LINE_ATTRIBUTE_5
      , INTEREST_LINE_ID
      , PROGRAM_UPDATE_DATE
      , GLOBAL_ATTRIBUTE_9
      , TAX_EXEMPTION_ID
      , SHIP_TO_SITE_USE_ID
      , INTERFACE_LINE_ATTRIBUTE_1
      , LINK_TO_PARENTLINE_ATTRIBUTE_5
      , DEFERRAL_EXCLUSION_FLAG
      , ATTRIBUTE_6
      , BR_REF_PAYMENT_SCHEDULE_ID
      , SHIP_TO_CUSTOMER_ID
      , ATTRIBUTE_NUMBER_5
      , TAX_EXEMPT_FLAG
      , AUTOTAX
      , CONTRACT_LINE_ID
      , SOURCE_DATA_KEY_4
      , DOC_LINE_ID_CHAR_3
      , FRT_UNED_ACCTD_AMOUNT
      , INTERFACE_LINE_ATTRIBUTE_10
      , GLOBAL_ATTRIBUTE_14
      , BILLING_PERIOD_END_DATE
      , ASSESSABLE_VALUE
      , DOC_LINE_ID_CHAR_2
      , PRODUCT_CATEGORY
      , GLOBAL_ATTRIBUTE_5
      , CONTRACT_END_DATE
      , DOC_LINE_ID_INT_4
      , PAYMENT_SET_ID
      , TAX_VENDOR_RETURN_CODE
      , LAST_PERIOD_TO_CREDIT
      , UOM_CODE
      , DOC_LINE_ID_INT_1
      , LINK_TO_PARENTLINE_ATTRIBUTE_7
      , LINK_TO_PARENTLINE_ATTRIBUTE_15
      , GLOBAL_ATTRIBUTE_18
      , CHRG_ACCTD_AMOUNT_REMAINING
      , FRT_ADJ_REMAINING
      , USER_DEFINED_FISC_CLASS
      , LINK_TO_PARENTLINE_ATTRIBUTE_3
      , GLOBAL_ATTRIBUTE_16
      , FAIR_MARKET_VALUE_AMOUNT
      , ATTRIBUTE_NUMBER_1
      , BR_REF_CUSTOMER_TRX_ID
      , UNIT_SELLING_PRICE
      , GLOBAL_ATTRIBUTE_DATE_5
      , EXTENDED_ACCTD_AMOUNT
      , ATTRIBUTE_9
      , ITEM_CONTEXT
      , INTERFACE_LINE_ATTRIBUTE_8
      , ATTRIBUTE_4
      , ATTRIBUTE_DATE_1
      , ATTRIBUTE_DATE_3
      , SALES_ORDER
      , TAX_CLASSIFICATION_CODE
      , SET_OF_BOOKS_ID
      , AUTHORIZATION_NUMBER
      , SALES_ORDER_LINE
      , INTERFACE_LINE_ATTRIBUTE_3
      , TAX_ACTION
      , GLOBAL_ATTRIBUTE_12
      , INTERFACE_LINE_CONTEXT
      , ACCTD_AMOUNT_DUE_REMAINING
      , DOC_LINE_ID_INT_3
      , GLOBAL_ATTRIBUTE_6
      , HISTORICAL_FLAG
      , INTERFACE_LINE_ATTRIBUTE_15
      , TAXABLE_AMOUNT
      , AUTORULE_DURATION_PROCESSED
      , TAX_LINE_ID
      , ATTRIBUTE_12
      , SHIP_TO_PARTY_ID
      , AMOUNT_DUE_REMAINING
      , DEFAULT_USSGL_TRX_CODE_CONTEXT
      , PREPAY_CUSTOMER_TRX_LINE_ID
      , DOC_LINE_ID_CHAR_4
      , PROGRAM_ID
      , LINE_NUMBER
      , ATTRIBUTE_DATE_4
      , LINK_TO_PARENTLINE_ATTRIBUTE_6
      , FINAL_DISCHARGE_LOCATION_ID
      , GLOBAL_ATTRIBUTE_13
      , INVOICED_LINE_ACCTG_LEVEL
      , OVERRIDE_AUTO_ACCOUNTING_FLAG
      , TAX_EXEMPT_NUMBER
      , ATTRIBUTE_2
      , INITIAL_CUSTOMER_TRX_LINE_ID
      , MEMO_LINE_SEQ_ID
      , LINK_TO_CUST_TRX_LINE_ID
      , SHIP_TO_PARTY_SITE_USE_ID
      , RECURRING_BILL_FLAG
      , PRODUCT_FISC_CLASSIFICATION
      , FRT_ED_ACCTD_AMOUNT
      , SOURCE_DOCUMENT_LINE_NUMBER
      , WH_UPDATE_DATE
      , TAXABLE_FLAG
      , GLOBAL_ATTRIBUTE_NUMBER_4
      , DEFAULT_USSGL_TRANSACTION_CODE
      , REQUEST_ID
      , GLOBAL_ATTRIBUTE_4
      , GLOBAL_ATTRIBUTE_DATE_4
      , ATTRIBUTE_NUMBER_4
      , SHIP_TO_CONTACT_ID
      , LINK_TO_PARENTLINE_ATTRIBUTE_1
      , INTERFACE_LINE_ATTRIBUTE_9
      , ATTRIBUTE_10
      , ATTRIBUTE_5
      , SHIP_TO_PARTY_ADDRESS_ID
      , LINK_TO_PARENTLINE_ATTRIBUTE_13
      , GLOBAL_ATTRIBUTE_3
      , SALES_ORDER_REVISION
      , VAT_TAX_ID
      , DOC_LINE_ID_CHAR_5
      , LINK_TO_PARENTLINE_ATTRIBUTE_2
      , GLOBAL_ATTRIBUTE_2
      , QUANTITY_ORDERED
      , SALES_ORDER_DATE
      , SOURCE_DATA_KEY_3
      , RULE_END_DATE
      , GLOBAL_ATTRIBUTE_CATEGORY
      , ATTRIBUTE_14
      , CREATED_BY
      , SHIP_TO_ADDRESS_ID
      , ACCOUNTING_RULE_DURATION
      , REMAINING_PREPAY_AMOUNT
      , GLOBAL_ATTRIBUTE_DATE_1
      , DESCRIPTION
      , AMOUNT_DUE_ORIGINAL
      , PREVIOUS_CUSTOMER_TRX_LINE_ID
      , GLOBAL_ATTRIBUTE_17
      , RECURRING_BILL_PLAN_LINE_ID
      , LINK_TO_PARENTLINE_ATTRIBUTE_9
      , CHRG_AMOUNT_REMAINING
      , SOURCE_DATA_KEY_1
      , LINK_TO_PARENTLINE_ATTRIBUTE_8
      , REQUIRES_MANUAL_SCHEDULING
      , GLOBAL_ATTRIBUTE_19
      , GROSS_EXTENDED_AMOUNT
      , ATTRIBUTE_15
      , GLOBAL_ATTRIBUTE_DATE_2
      , INTERFACE_LINE_ATTRIBUTE_11
      , INSURANCE_CHARGE
      , GLOBAL_ATTRIBUTE_NUMBER_5
      , LAST_UPDATE_LOGIN
      , ATTRIBUTE_8
      , LOCATION_SEGMENT_ID
      , TAX_EXEMPT_REASON_CODE
      , ATTRIBUTE_3
      , LINK_TO_PARENTLINE_ATTRIBUTE_10
      , GLOBAL_ATTRIBUTE_1
      , RULE_START_DATE
      , LINK_TO_PARENTLINE_CONTEXT
      , FREIGHT_CHARGE
      , INTERFACE_LINE_ATTRIBUTE_2
      , RECURRING_BILL_PLAN_ID
      , TRX_BUSINESS_CATEGORY
      , GLOBAL_ATTRIBUTE_NUMBER_2
      , PACKING_CHARGE
      , TAX_INVOICE_NUMBER
      , LINK_TO_PARENTLINE_ATTRIBUTE_11
      , AUTORULE_COMPLETE_FLAG
      , SALES_TAX_ID
      , ATTRIBUTE_DATE_2
      , GLOBAL_ATTRIBUTE_8
      , PREPAY_CUSTOMER_TRX_ID
      , ITEM_EXCEPTION_RATE_ID
      , LAST_UPDATED_BY
      , GLOBAL_ATTRIBUTE_15
      , ATTRIBUTE_CATEGORY
      , GLOBAL_ATTRIBUTE_7
      , PAYMENT_TRXN_EXTENSION_ID
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED )                   as                                           LOAD_DTS
      , coalesce(nullif(trim(CUSTOMER_TRX_ID), ''), '-1')            as                                         INVOICE_BK
    FROM SRC_S
)

, LOGIC_A as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_A
)

, LOGIC_S2 as (
    SELECT
        INVENTORY_ITEM_ID                                            as                               S2_INVENTORY_ITEM_ID
      , ITEM_NUMBER
    FROM SRC_S2
)
---- RENAME LAYER ----

, RENAME_S as (
    SELECT
        INVOICE_LINE_BK
      , CUSTOMER_TRX_LINE_ID
      , CUSTOMER_TRX_ID
      , ATTRIBUTE_7
      , INTERFACE_LINE_ATTRIBUTE_4
      , ACCTD_AMOUNT_DUE_ORIGINAL
      , BILL_PLAN_LINE_ID
      , ATTRIBUTE_11
      , INTERFACE_LINE_ATTRIBUTE_6
      , SALES_ORDER_SOURCE
      , ACCOUNTING_RULE_ID
      , BILLING_PERIOD_START_DATE
      , GLOBAL_ATTRIBUTE_NUMBER_3
      , BR_ADJUSTMENT_ID
      , MISCELLANEOUS_CHARGE
      , TRANSLATED_DESCRIPTION
      , UNIT_STANDARD_PRICE
      , DOC_LINE_ID_CHAR_1
      , QUANTITY_INVOICED
      , TAX_INVOICE_DATE
      , GLOBAL_ATTRIBUTE_11
      , COMMERCIAL_DISCOUNT
      , OBJECT_VERSION_NUMBER
      , GLOBAL_ATTRIBUTE_20
      , ATTRIBUTE_NUMBER_3
      , PRODUCT_TYPE
      , ATTRIBUTE_NUMBER_2
      , GLOBAL_ATTRIBUTE_DATE_3
      , EXTENDED_AMOUNT
      , ATTRIBUTE_DATE_5
      , PREVIOUS_CUSTOMER_TRX_ID
      , GROSS_UNIT_SELLING_PRICE
      , FRT_ADJ_ACCTD_REMAINING
      , INTERFACE_LINE_ATTRIBUTE_14
      , ATTRIBUTE_13
      , TAX_RECOVERABLE
      , LINK_TO_PARENTLINE_ATTRIBUTE_14
      , SOURCE_DATA_KEY_5
      , LINE_INTENDED_USE
      , LINK_TO_PARENTLINE_ATTRIBUTE_4
      , CREATION_DATE
      , REVENUE_AMOUNT
      , GLOBAL_ATTRIBUTE_10
      , REASON_CODE
      , INTERFACE_LINE_ATTRIBUTE_7
      , SHIP_TO_PARTY_CONTACT_ID
      , GLOBAL_ATTRIBUTE_NUMBER_1
      , MOVEMENT_ID
      , MRC_EXTENDED_ACCTD_AMOUNT
      , TAX_PRECEDENCE
      , CONTRACT_START_DATE
      , LINE_TYPE
      , FRT_ED_AMOUNT
      , LAST_UPDATE_DATE
      , AMOUNT_INCLUDES_TAX_FLAG
      , SOURCE_DOCUMENT_LINE_ID
      , TAX_RATE
      , PROGRAM_APPLICATION_ID
      , SOURCE_DATA_KEY_2
      , LINK_TO_PARENTLINE_ATTRIBUTE_12
      , ORG_ID
      , ATTRIBUTE_1
      , DOC_LINE_ID_INT_5
      , INTERFACE_LINE_ATTRIBUTE_12
      , QUANTITY_CREDITED
      , WAREHOUSE_ID
      , INTERFACE_LINE_ATTRIBUTE_13
      , AUTH_COMPLETE_FLAG
      , DOC_LINE_ID_INT_2
      , INVENTORY_ITEM_ID
      , LINE_RECOVERABLE
      , FRT_UNED_AMOUNT
      , INTERFACE_LINE_ATTRIBUTE_5
      , INTEREST_LINE_ID
      , PROGRAM_UPDATE_DATE
      , GLOBAL_ATTRIBUTE_9
      , TAX_EXEMPTION_ID
      , SHIP_TO_SITE_USE_ID
      , INTERFACE_LINE_ATTRIBUTE_1
      , LINK_TO_PARENTLINE_ATTRIBUTE_5
      , DEFERRAL_EXCLUSION_FLAG
      , ATTRIBUTE_6
      , BR_REF_PAYMENT_SCHEDULE_ID
      , SHIP_TO_CUSTOMER_ID
      , ATTRIBUTE_NUMBER_5
      , TAX_EXEMPT_FLAG
      , AUTOTAX
      , CONTRACT_LINE_ID
      , SOURCE_DATA_KEY_4
      , DOC_LINE_ID_CHAR_3
      , FRT_UNED_ACCTD_AMOUNT
      , INTERFACE_LINE_ATTRIBUTE_10
      , GLOBAL_ATTRIBUTE_14
      , BILLING_PERIOD_END_DATE
      , ASSESSABLE_VALUE
      , DOC_LINE_ID_CHAR_2
      , PRODUCT_CATEGORY
      , GLOBAL_ATTRIBUTE_5
      , CONTRACT_END_DATE
      , DOC_LINE_ID_INT_4
      , PAYMENT_SET_ID
      , TAX_VENDOR_RETURN_CODE
      , LAST_PERIOD_TO_CREDIT
      , UOM_CODE
      , DOC_LINE_ID_INT_1
      , LINK_TO_PARENTLINE_ATTRIBUTE_7
      , LINK_TO_PARENTLINE_ATTRIBUTE_15
      , GLOBAL_ATTRIBUTE_18
      , CHRG_ACCTD_AMOUNT_REMAINING
      , FRT_ADJ_REMAINING
      , USER_DEFINED_FISC_CLASS
      , LINK_TO_PARENTLINE_ATTRIBUTE_3
      , GLOBAL_ATTRIBUTE_16
      , FAIR_MARKET_VALUE_AMOUNT
      , ATTRIBUTE_NUMBER_1
      , BR_REF_CUSTOMER_TRX_ID
      , UNIT_SELLING_PRICE
      , GLOBAL_ATTRIBUTE_DATE_5
      , EXTENDED_ACCTD_AMOUNT
      , ATTRIBUTE_9
      , ITEM_CONTEXT
      , INTERFACE_LINE_ATTRIBUTE_8
      , ATTRIBUTE_4
      , ATTRIBUTE_DATE_1
      , ATTRIBUTE_DATE_3
      , SALES_ORDER
      , TAX_CLASSIFICATION_CODE
      , SET_OF_BOOKS_ID
      , AUTHORIZATION_NUMBER
      , SALES_ORDER_LINE
      , INTERFACE_LINE_ATTRIBUTE_3
      , TAX_ACTION
      , GLOBAL_ATTRIBUTE_12
      , INTERFACE_LINE_CONTEXT
      , ACCTD_AMOUNT_DUE_REMAINING
      , DOC_LINE_ID_INT_3
      , GLOBAL_ATTRIBUTE_6
      , HISTORICAL_FLAG
      , INTERFACE_LINE_ATTRIBUTE_15
      , TAXABLE_AMOUNT
      , AUTORULE_DURATION_PROCESSED
      , TAX_LINE_ID
      , ATTRIBUTE_12
      , SHIP_TO_PARTY_ID
      , AMOUNT_DUE_REMAINING
      , DEFAULT_USSGL_TRX_CODE_CONTEXT
      , PREPAY_CUSTOMER_TRX_LINE_ID
      , DOC_LINE_ID_CHAR_4
      , PROGRAM_ID
      , LINE_NUMBER
      , ATTRIBUTE_DATE_4
      , LINK_TO_PARENTLINE_ATTRIBUTE_6
      , FINAL_DISCHARGE_LOCATION_ID
      , GLOBAL_ATTRIBUTE_13
      , INVOICED_LINE_ACCTG_LEVEL
      , OVERRIDE_AUTO_ACCOUNTING_FLAG
      , TAX_EXEMPT_NUMBER
      , ATTRIBUTE_2
      , INITIAL_CUSTOMER_TRX_LINE_ID
      , MEMO_LINE_SEQ_ID
      , LINK_TO_CUST_TRX_LINE_ID
      , SHIP_TO_PARTY_SITE_USE_ID
      , RECURRING_BILL_FLAG
      , PRODUCT_FISC_CLASSIFICATION
      , FRT_ED_ACCTD_AMOUNT
      , SOURCE_DOCUMENT_LINE_NUMBER
      , WH_UPDATE_DATE
      , TAXABLE_FLAG
      , GLOBAL_ATTRIBUTE_NUMBER_4
      , DEFAULT_USSGL_TRANSACTION_CODE
      , REQUEST_ID
      , GLOBAL_ATTRIBUTE_4
      , GLOBAL_ATTRIBUTE_DATE_4
      , ATTRIBUTE_NUMBER_4
      , SHIP_TO_CONTACT_ID
      , LINK_TO_PARENTLINE_ATTRIBUTE_1
      , INTERFACE_LINE_ATTRIBUTE_9
      , ATTRIBUTE_10
      , ATTRIBUTE_5
      , SHIP_TO_PARTY_ADDRESS_ID
      , LINK_TO_PARENTLINE_ATTRIBUTE_13
      , GLOBAL_ATTRIBUTE_3
      , SALES_ORDER_REVISION
      , VAT_TAX_ID
      , DOC_LINE_ID_CHAR_5
      , LINK_TO_PARENTLINE_ATTRIBUTE_2
      , GLOBAL_ATTRIBUTE_2
      , QUANTITY_ORDERED
      , SALES_ORDER_DATE
      , SOURCE_DATA_KEY_3
      , RULE_END_DATE
      , GLOBAL_ATTRIBUTE_CATEGORY
      , ATTRIBUTE_14
      , CREATED_BY
      , SHIP_TO_ADDRESS_ID
      , ACCOUNTING_RULE_DURATION
      , REMAINING_PREPAY_AMOUNT
      , GLOBAL_ATTRIBUTE_DATE_1
      , DESCRIPTION
      , AMOUNT_DUE_ORIGINAL
      , PREVIOUS_CUSTOMER_TRX_LINE_ID
      , GLOBAL_ATTRIBUTE_17
      , RECURRING_BILL_PLAN_LINE_ID
      , LINK_TO_PARENTLINE_ATTRIBUTE_9
      , CHRG_AMOUNT_REMAINING
      , SOURCE_DATA_KEY_1
      , LINK_TO_PARENTLINE_ATTRIBUTE_8
      , REQUIRES_MANUAL_SCHEDULING
      , GLOBAL_ATTRIBUTE_19
      , GROSS_EXTENDED_AMOUNT
      , ATTRIBUTE_15
      , GLOBAL_ATTRIBUTE_DATE_2
      , INTERFACE_LINE_ATTRIBUTE_11
      , INSURANCE_CHARGE
      , GLOBAL_ATTRIBUTE_NUMBER_5
      , LAST_UPDATE_LOGIN
      , ATTRIBUTE_8
      , LOCATION_SEGMENT_ID
      , TAX_EXEMPT_REASON_CODE
      , ATTRIBUTE_3
      , LINK_TO_PARENTLINE_ATTRIBUTE_10
      , GLOBAL_ATTRIBUTE_1
      , RULE_START_DATE
      , LINK_TO_PARENTLINE_CONTEXT
      , FREIGHT_CHARGE
      , INTERFACE_LINE_ATTRIBUTE_2
      , RECURRING_BILL_PLAN_ID
      , TRX_BUSINESS_CATEGORY
      , GLOBAL_ATTRIBUTE_NUMBER_2
      , PACKING_CHARGE
      , TAX_INVOICE_NUMBER
      , LINK_TO_PARENTLINE_ATTRIBUTE_11
      , AUTORULE_COMPLETE_FLAG
      , SALES_TAX_ID
      , ATTRIBUTE_DATE_2
      , GLOBAL_ATTRIBUTE_8
      , PREPAY_CUSTOMER_TRX_ID
      , ITEM_EXCEPTION_RATE_ID
      , LAST_UPDATED_BY
      , GLOBAL_ATTRIBUTE_15
      , ATTRIBUTE_CATEGORY
      , GLOBAL_ATTRIBUTE_7
      , PAYMENT_TRXN_EXTENSION_ID
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , INVOICE_BK
    FROM LOGIC_S
)

, RENAME_A as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_A
)

, RENAME_S2 as (
    SELECT
        S2_INVENTORY_ITEM_ID
      , ITEM_NUMBER
    FROM LOGIC_S2
)
---- FILTER LAYER ----

, FILTER_S as (
    SELECT *
    FROM RENAME_S
)

, FILTER_A as (
    SELECT *
    FROM RENAME_A
    WHERE rec_src = 'USCLOUD.ORCL.OCFPRD.CUSTOMER_TRX_LINES_ALL'
)

, FILTER_S2 as (
    SELECT *
    FROM RENAME_S2
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_S
    INNER JOIN FILTER_A
        ON '1' = '1'
    LEFT JOIN FILTER_S2
        ON INVENTORY_ITEM_ID = S2_INVENTORY_ITEM_ID
)

---- FINAL LAYER ----
SELECT
          INVOICE_LINE_BK
        , CUSTOMER_TRX_LINE_ID
        , CUSTOMER_TRX_ID
        , ATTRIBUTE_7
        , INTERFACE_LINE_ATTRIBUTE_4
        , ACCTD_AMOUNT_DUE_ORIGINAL
        , BILL_PLAN_LINE_ID
        , ATTRIBUTE_11
        , INTERFACE_LINE_ATTRIBUTE_6
        , SALES_ORDER_SOURCE
        , ACCOUNTING_RULE_ID
        , BILLING_PERIOD_START_DATE
        , GLOBAL_ATTRIBUTE_NUMBER_3
        , BR_ADJUSTMENT_ID
        , MISCELLANEOUS_CHARGE
        , TRANSLATED_DESCRIPTION
        , UNIT_STANDARD_PRICE
        , DOC_LINE_ID_CHAR_1
        , QUANTITY_INVOICED
        , TAX_INVOICE_DATE
        , GLOBAL_ATTRIBUTE_11
        , COMMERCIAL_DISCOUNT
        , OBJECT_VERSION_NUMBER
        , GLOBAL_ATTRIBUTE_20
        , ATTRIBUTE_NUMBER_3
        , PRODUCT_TYPE
        , ATTRIBUTE_NUMBER_2
        , GLOBAL_ATTRIBUTE_DATE_3
        , EXTENDED_AMOUNT
        , ATTRIBUTE_DATE_5
        , PREVIOUS_CUSTOMER_TRX_ID
        , GROSS_UNIT_SELLING_PRICE
        , FRT_ADJ_ACCTD_REMAINING
        , INTERFACE_LINE_ATTRIBUTE_14
        , ATTRIBUTE_13
        , TAX_RECOVERABLE
        , LINK_TO_PARENTLINE_ATTRIBUTE_14
        , SOURCE_DATA_KEY_5
        , LINE_INTENDED_USE
        , LINK_TO_PARENTLINE_ATTRIBUTE_4
        , CREATION_DATE
        , REVENUE_AMOUNT
        , GLOBAL_ATTRIBUTE_10
        , REASON_CODE
        , INTERFACE_LINE_ATTRIBUTE_7
        , SHIP_TO_PARTY_CONTACT_ID
        , GLOBAL_ATTRIBUTE_NUMBER_1
        , MOVEMENT_ID
        , MRC_EXTENDED_ACCTD_AMOUNT
        , TAX_PRECEDENCE
        , CONTRACT_START_DATE
        , LINE_TYPE
        , FRT_ED_AMOUNT
        , LAST_UPDATE_DATE
        , AMOUNT_INCLUDES_TAX_FLAG
        , SOURCE_DOCUMENT_LINE_ID
        , TAX_RATE
        , PROGRAM_APPLICATION_ID
        , SOURCE_DATA_KEY_2
        , LINK_TO_PARENTLINE_ATTRIBUTE_12
        , ORG_ID
        , ATTRIBUTE_1
        , DOC_LINE_ID_INT_5
        , INTERFACE_LINE_ATTRIBUTE_12
        , QUANTITY_CREDITED
        , WAREHOUSE_ID
        , INTERFACE_LINE_ATTRIBUTE_13
        , AUTH_COMPLETE_FLAG
        , DOC_LINE_ID_INT_2
        , INVENTORY_ITEM_ID
        , LINE_RECOVERABLE
        , FRT_UNED_AMOUNT
        , INTERFACE_LINE_ATTRIBUTE_5
        , INTEREST_LINE_ID
        , PROGRAM_UPDATE_DATE
        , GLOBAL_ATTRIBUTE_9
        , TAX_EXEMPTION_ID
        , SHIP_TO_SITE_USE_ID
        , INTERFACE_LINE_ATTRIBUTE_1
        , LINK_TO_PARENTLINE_ATTRIBUTE_5
        , DEFERRAL_EXCLUSION_FLAG
        , ATTRIBUTE_6
        , BR_REF_PAYMENT_SCHEDULE_ID
        , SHIP_TO_CUSTOMER_ID
        , ATTRIBUTE_NUMBER_5
        , TAX_EXEMPT_FLAG
        , AUTOTAX
        , CONTRACT_LINE_ID
        , SOURCE_DATA_KEY_4
        , DOC_LINE_ID_CHAR_3
        , FRT_UNED_ACCTD_AMOUNT
        , INTERFACE_LINE_ATTRIBUTE_10
        , GLOBAL_ATTRIBUTE_14
        , BILLING_PERIOD_END_DATE
        , ASSESSABLE_VALUE
        , DOC_LINE_ID_CHAR_2
        , PRODUCT_CATEGORY
        , GLOBAL_ATTRIBUTE_5
        , CONTRACT_END_DATE
        , DOC_LINE_ID_INT_4
        , PAYMENT_SET_ID
        , TAX_VENDOR_RETURN_CODE
        , LAST_PERIOD_TO_CREDIT
        , UOM_CODE
        , DOC_LINE_ID_INT_1
        , LINK_TO_PARENTLINE_ATTRIBUTE_7
        , LINK_TO_PARENTLINE_ATTRIBUTE_15
        , GLOBAL_ATTRIBUTE_18
        , CHRG_ACCTD_AMOUNT_REMAINING
        , FRT_ADJ_REMAINING
        , USER_DEFINED_FISC_CLASS
        , LINK_TO_PARENTLINE_ATTRIBUTE_3
        , GLOBAL_ATTRIBUTE_16
        , FAIR_MARKET_VALUE_AMOUNT
        , ATTRIBUTE_NUMBER_1
        , BR_REF_CUSTOMER_TRX_ID
        , UNIT_SELLING_PRICE
        , GLOBAL_ATTRIBUTE_DATE_5
        , EXTENDED_ACCTD_AMOUNT
        , ATTRIBUTE_9
        , ITEM_CONTEXT
        , INTERFACE_LINE_ATTRIBUTE_8
        , ATTRIBUTE_4
        , ATTRIBUTE_DATE_1
        , ATTRIBUTE_DATE_3
        , SALES_ORDER
        , TAX_CLASSIFICATION_CODE
        , SET_OF_BOOKS_ID
        , AUTHORIZATION_NUMBER
        , SALES_ORDER_LINE
        , INTERFACE_LINE_ATTRIBUTE_3
        , TAX_ACTION
        , GLOBAL_ATTRIBUTE_12
        , INTERFACE_LINE_CONTEXT
        , ACCTD_AMOUNT_DUE_REMAINING
        , DOC_LINE_ID_INT_3
        , GLOBAL_ATTRIBUTE_6
        , HISTORICAL_FLAG
        , INTERFACE_LINE_ATTRIBUTE_15
        , TAXABLE_AMOUNT
        , AUTORULE_DURATION_PROCESSED
        , TAX_LINE_ID
        , ATTRIBUTE_12
        , SHIP_TO_PARTY_ID
        , AMOUNT_DUE_REMAINING
        , DEFAULT_USSGL_TRX_CODE_CONTEXT
        , PREPAY_CUSTOMER_TRX_LINE_ID
        , DOC_LINE_ID_CHAR_4
        , PROGRAM_ID
        , LINE_NUMBER
        , ATTRIBUTE_DATE_4
        , LINK_TO_PARENTLINE_ATTRIBUTE_6
        , FINAL_DISCHARGE_LOCATION_ID
        , GLOBAL_ATTRIBUTE_13
        , INVOICED_LINE_ACCTG_LEVEL
        , OVERRIDE_AUTO_ACCOUNTING_FLAG
        , TAX_EXEMPT_NUMBER
        , ATTRIBUTE_2
        , INITIAL_CUSTOMER_TRX_LINE_ID
        , MEMO_LINE_SEQ_ID
        , LINK_TO_CUST_TRX_LINE_ID
        , SHIP_TO_PARTY_SITE_USE_ID
        , RECURRING_BILL_FLAG
        , PRODUCT_FISC_CLASSIFICATION
        , FRT_ED_ACCTD_AMOUNT
        , SOURCE_DOCUMENT_LINE_NUMBER
        , WH_UPDATE_DATE
        , TAXABLE_FLAG
        , GLOBAL_ATTRIBUTE_NUMBER_4
        , DEFAULT_USSGL_TRANSACTION_CODE
        , REQUEST_ID
        , GLOBAL_ATTRIBUTE_4
        , GLOBAL_ATTRIBUTE_DATE_4
        , ATTRIBUTE_NUMBER_4
        , SHIP_TO_CONTACT_ID
        , LINK_TO_PARENTLINE_ATTRIBUTE_1
        , INTERFACE_LINE_ATTRIBUTE_9
        , ATTRIBUTE_10
        , ATTRIBUTE_5
        , SHIP_TO_PARTY_ADDRESS_ID
        , LINK_TO_PARENTLINE_ATTRIBUTE_13
        , GLOBAL_ATTRIBUTE_3
        , SALES_ORDER_REVISION
        , VAT_TAX_ID
        , DOC_LINE_ID_CHAR_5
        , LINK_TO_PARENTLINE_ATTRIBUTE_2
        , GLOBAL_ATTRIBUTE_2
        , QUANTITY_ORDERED
        , SALES_ORDER_DATE
        , SOURCE_DATA_KEY_3
        , RULE_END_DATE
        , GLOBAL_ATTRIBUTE_CATEGORY
        , ATTRIBUTE_14
        , CREATED_BY
        , SHIP_TO_ADDRESS_ID
        , ACCOUNTING_RULE_DURATION
        , REMAINING_PREPAY_AMOUNT
        , GLOBAL_ATTRIBUTE_DATE_1
        , DESCRIPTION
        , AMOUNT_DUE_ORIGINAL
        , PREVIOUS_CUSTOMER_TRX_LINE_ID
        , GLOBAL_ATTRIBUTE_17
        , RECURRING_BILL_PLAN_LINE_ID
        , LINK_TO_PARENTLINE_ATTRIBUTE_9
        , CHRG_AMOUNT_REMAINING
        , SOURCE_DATA_KEY_1
        , LINK_TO_PARENTLINE_ATTRIBUTE_8
        , REQUIRES_MANUAL_SCHEDULING
        , GLOBAL_ATTRIBUTE_19
        , GROSS_EXTENDED_AMOUNT
        , ATTRIBUTE_15
        , GLOBAL_ATTRIBUTE_DATE_2
        , INTERFACE_LINE_ATTRIBUTE_11
        , INSURANCE_CHARGE
        , GLOBAL_ATTRIBUTE_NUMBER_5
        , LAST_UPDATE_LOGIN
        , ATTRIBUTE_8
        , LOCATION_SEGMENT_ID
        , TAX_EXEMPT_REASON_CODE
        , ATTRIBUTE_3
        , LINK_TO_PARENTLINE_ATTRIBUTE_10
        , GLOBAL_ATTRIBUTE_1
        , RULE_START_DATE
        , LINK_TO_PARENTLINE_CONTEXT
        , FREIGHT_CHARGE
        , INTERFACE_LINE_ATTRIBUTE_2
        , RECURRING_BILL_PLAN_ID
        , TRX_BUSINESS_CATEGORY
        , GLOBAL_ATTRIBUTE_NUMBER_2
        , PACKING_CHARGE
        , TAX_INVOICE_NUMBER
        , LINK_TO_PARENTLINE_ATTRIBUTE_11
        , AUTORULE_COMPLETE_FLAG
        , SALES_TAX_ID
        , ATTRIBUTE_DATE_2
        , GLOBAL_ATTRIBUTE_8
        , PREPAY_CUSTOMER_TRX_ID
        , ITEM_EXCEPTION_RATE_ID
        , LAST_UPDATED_BY
        , GLOBAL_ATTRIBUTE_15
        , ATTRIBUTE_CATEGORY
        , GLOBAL_ATTRIBUTE_7
        , PAYMENT_TRXN_EXTENSION_ID
        , _FIVETRAN_DELETED
        , _FIVETRAN_SYNCED
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , INVOICE_BK
        , coalesce(nullif(trim(ITEM_NUMBER), ''), '-1')                as ITEM_BK
        , conditional_change_event(hash(* exclude(psa_load_dts, load_dts, _fivetran_synced))) over(partition by INVOICE_LINE_BK order by _fivetran_synced) as CCE
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(INVOICE_LINE_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as INVOICE_LINE_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(INVOICE_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as INVOICE_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ITEM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ITEM_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(INVOICE_LINE_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(ITEM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as INVOICE_INVOICE_LINE_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(CUSTOMER_TRX_ID::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_7::text), '^^') 
            , '||', IFNULL(TRIM(INTERFACE_LINE_ATTRIBUTE_4::text), '^^') 
            , '||', IFNULL(TRIM(ACCTD_AMOUNT_DUE_ORIGINAL::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_11::text), '^^') 
            , '||', IFNULL(TRIM(INTERFACE_LINE_ATTRIBUTE_6::text), '^^') 
            , '||', IFNULL(TRIM(SALES_ORDER_SOURCE::text), '^^') 
            , '||', IFNULL(TRIM(ACCOUNTING_RULE_ID::text), '^^') 
            , '||', IFNULL(TRIM(BILLING_PERIOD_START_DATE::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_NUMBER_3::text), '^^') 
            , '||', IFNULL(TRIM(BR_ADJUSTMENT_ID::text), '^^') 
            , '||', IFNULL(TRIM(MISCELLANEOUS_CHARGE::text), '^^') 
            , '||', IFNULL(TRIM(TRANSLATED_DESCRIPTION::text), '^^') 
            , '||', IFNULL(TRIM(UNIT_STANDARD_PRICE::text), '^^') 
            , '||', IFNULL(TRIM(DOC_LINE_ID_CHAR_1::text), '^^') 
            , '||', IFNULL(TRIM(QUANTITY_INVOICED::text), '^^') 
            , '||', IFNULL(TRIM(TAX_INVOICE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_11::text), '^^') 
            , '||', IFNULL(TRIM(COMMERCIAL_DISCOUNT::text), '^^') 
            , '||', IFNULL(TRIM(OBJECT_VERSION_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_20::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_3::text), '^^') 
            , '||', IFNULL(TRIM(PRODUCT_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_2::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_DATE_3::text), '^^') 
            , '||', IFNULL(TRIM(EXTENDED_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_DATE_5::text), '^^') 
            , '||', IFNULL(TRIM(PREVIOUS_CUSTOMER_TRX_ID::text), '^^') 
            , '||', IFNULL(TRIM(GROSS_UNIT_SELLING_PRICE::text), '^^') 
            , '||', IFNULL(TRIM(FRT_ADJ_ACCTD_REMAINING::text), '^^') 
            , '||', IFNULL(TRIM(INTERFACE_LINE_ATTRIBUTE_14::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_13::text), '^^') 
            , '||', IFNULL(TRIM(TAX_RECOVERABLE::text), '^^') 
            , '||', IFNULL(TRIM(LINK_TO_PARENTLINE_ATTRIBUTE_14::text), '^^') 
            , '||', IFNULL(TRIM(SOURCE_DATA_KEY_5::text), '^^') 
            , '||', IFNULL(TRIM(LINE_INTENDED_USE::text), '^^') 
            , '||', IFNULL(TRIM(LINK_TO_PARENTLINE_ATTRIBUTE_4::text), '^^') 
            , '||', IFNULL(TRIM(CREATION_DATE::text), '^^') 
            , '||', IFNULL(TRIM(REVENUE_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_10::text), '^^') 
            , '||', IFNULL(TRIM(REASON_CODE::text), '^^') 
            , '||', IFNULL(TRIM(INTERFACE_LINE_ATTRIBUTE_7::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_TO_PARTY_CONTACT_ID::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_NUMBER_1::text), '^^') 
            , '||', IFNULL(TRIM(MOVEMENT_ID::text), '^^') 
            , '||', IFNULL(TRIM(MRC_EXTENDED_ACCTD_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(TAX_PRECEDENCE::text), '^^') 
            , '||', IFNULL(TRIM(CONTRACT_START_DATE::text), '^^') 
            , '||', IFNULL(TRIM(LINE_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(FRT_ED_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(AMOUNT_INCLUDES_TAX_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(SOURCE_DOCUMENT_LINE_ID::text), '^^') 
            , '||', IFNULL(TRIM(TAX_RATE::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_APPLICATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(SOURCE_DATA_KEY_2::text), '^^') 
            , '||', IFNULL(TRIM(LINK_TO_PARENTLINE_ATTRIBUTE_12::text), '^^') 
            , '||', IFNULL(TRIM(ORG_ID::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_1::text), '^^') 
            , '||', IFNULL(TRIM(DOC_LINE_ID_INT_5::text), '^^') 
            , '||', IFNULL(TRIM(INTERFACE_LINE_ATTRIBUTE_12::text), '^^') 
            , '||', IFNULL(TRIM(QUANTITY_CREDITED::text), '^^') 
            , '||', IFNULL(TRIM(WAREHOUSE_ID::text), '^^') 
            , '||', IFNULL(TRIM(INTERFACE_LINE_ATTRIBUTE_13::text), '^^') 
            , '||', IFNULL(TRIM(AUTH_COMPLETE_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(DOC_LINE_ID_INT_2::text), '^^') 
            , '||', IFNULL(TRIM(INVENTORY_ITEM_ID::text), '^^') 
            , '||', IFNULL(TRIM(LINE_RECOVERABLE::text), '^^') 
            , '||', IFNULL(TRIM(FRT_UNED_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(INTERFACE_LINE_ATTRIBUTE_5::text), '^^') 
            , '||', IFNULL(TRIM(INTEREST_LINE_ID::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_UPDATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_9::text), '^^') 
            , '||', IFNULL(TRIM(TAX_EXEMPTION_ID::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_TO_SITE_USE_ID::text), '^^') 
            , '||', IFNULL(TRIM(INTERFACE_LINE_ATTRIBUTE_1::text), '^^') 
            , '||', IFNULL(TRIM(LINK_TO_PARENTLINE_ATTRIBUTE_5::text), '^^') 
            , '||', IFNULL(TRIM(DEFERRAL_EXCLUSION_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_6::text), '^^') 
            , '||', IFNULL(TRIM(BR_REF_PAYMENT_SCHEDULE_ID::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_TO_CUSTOMER_ID::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_5::text), '^^') 
            , '||', IFNULL(TRIM(TAX_EXEMPT_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(AUTOTAX::text), '^^') 
            , '||', IFNULL(TRIM(CONTRACT_LINE_ID::text), '^^') 
            , '||', IFNULL(TRIM(SOURCE_DATA_KEY_4::text), '^^') 
            , '||', IFNULL(TRIM(DOC_LINE_ID_CHAR_3::text), '^^') 
            , '||', IFNULL(TRIM(FRT_UNED_ACCTD_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(INTERFACE_LINE_ATTRIBUTE_10::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_14::text), '^^') 
            , '||', IFNULL(TRIM(BILLING_PERIOD_END_DATE::text), '^^') 
            , '||', IFNULL(TRIM(ASSESSABLE_VALUE::text), '^^') 
            , '||', IFNULL(TRIM(DOC_LINE_ID_CHAR_2::text), '^^') 
            , '||', IFNULL(TRIM(PRODUCT_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_5::text), '^^') 
            , '||', IFNULL(TRIM(CONTRACT_END_DATE::text), '^^') 
            , '||', IFNULL(TRIM(DOC_LINE_ID_INT_4::text), '^^') 
            , '||', IFNULL(TRIM(PAYMENT_SET_ID::text), '^^') 
            , '||', IFNULL(TRIM(TAX_VENDOR_RETURN_CODE::text), '^^') 
            , '||', IFNULL(TRIM(LAST_PERIOD_TO_CREDIT::text), '^^') 
            , '||', IFNULL(TRIM(UOM_CODE::text), '^^') 
            , '||', IFNULL(TRIM(DOC_LINE_ID_INT_1::text), '^^') 
            , '||', IFNULL(TRIM(LINK_TO_PARENTLINE_ATTRIBUTE_7::text), '^^') 
            , '||', IFNULL(TRIM(LINK_TO_PARENTLINE_ATTRIBUTE_15::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_18::text), '^^') 
            , '||', IFNULL(TRIM(CHRG_ACCTD_AMOUNT_REMAINING::text), '^^') 
            , '||', IFNULL(TRIM(FRT_ADJ_REMAINING::text), '^^') 
            , '||', IFNULL(TRIM(USER_DEFINED_FISC_CLASS::text), '^^') 
            , '||', IFNULL(TRIM(LINK_TO_PARENTLINE_ATTRIBUTE_3::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_16::text), '^^') 
            , '||', IFNULL(TRIM(FAIR_MARKET_VALUE_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_1::text), '^^') 
            , '||', IFNULL(TRIM(BR_REF_CUSTOMER_TRX_ID::text), '^^') 
            , '||', IFNULL(TRIM(UNIT_SELLING_PRICE::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_DATE_5::text), '^^') 
            , '||', IFNULL(TRIM(EXTENDED_ACCTD_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_9::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_CONTEXT::text), '^^') 
            , '||', IFNULL(TRIM(INTERFACE_LINE_ATTRIBUTE_8::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_4::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_DATE_1::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_DATE_3::text), '^^') 
            , '||', IFNULL(TRIM(SALES_ORDER::text), '^^') 
            , '||', IFNULL(TRIM(TAX_CLASSIFICATION_CODE::text), '^^') 
            , '||', IFNULL(TRIM(SET_OF_BOOKS_ID::text), '^^') 
            , '||', IFNULL(TRIM(AUTHORIZATION_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(SALES_ORDER_LINE::text), '^^') 
            , '||', IFNULL(TRIM(INTERFACE_LINE_ATTRIBUTE_3::text), '^^') 
            , '||', IFNULL(TRIM(TAX_ACTION::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_12::text), '^^') 
            , '||', IFNULL(TRIM(INTERFACE_LINE_CONTEXT::text), '^^') 
            , '||', IFNULL(TRIM(ACCTD_AMOUNT_DUE_REMAINING::text), '^^') 
            , '||', IFNULL(TRIM(DOC_LINE_ID_INT_3::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_6::text), '^^') 
            , '||', IFNULL(TRIM(HISTORICAL_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(INTERFACE_LINE_ATTRIBUTE_15::text), '^^') 
            , '||', IFNULL(TRIM(TAXABLE_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(AUTORULE_DURATION_PROCESSED::text), '^^') 
            , '||', IFNULL(TRIM(TAX_LINE_ID::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_12::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_TO_PARTY_ID::text), '^^') 
            , '||', IFNULL(TRIM(AMOUNT_DUE_REMAINING::text), '^^') 
            , '||', IFNULL(TRIM(DEFAULT_USSGL_TRX_CODE_CONTEXT::text), '^^') 
            , '||', IFNULL(TRIM(PREPAY_CUSTOMER_TRX_LINE_ID::text), '^^') 
            , '||', IFNULL(TRIM(DOC_LINE_ID_CHAR_4::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_ID::text), '^^') 
            , '||', IFNULL(TRIM(LINE_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_DATE_4::text), '^^') 
            , '||', IFNULL(TRIM(LINK_TO_PARENTLINE_ATTRIBUTE_6::text), '^^') 
            , '||', IFNULL(TRIM(FINAL_DISCHARGE_LOCATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_13::text), '^^') 
            , '||', IFNULL(TRIM(INVOICED_LINE_ACCTG_LEVEL::text), '^^') 
            , '||', IFNULL(TRIM(OVERRIDE_AUTO_ACCOUNTING_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(TAX_EXEMPT_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_2::text), '^^') 
            , '||', IFNULL(TRIM(INITIAL_CUSTOMER_TRX_LINE_ID::text), '^^') 
            , '||', IFNULL(TRIM(MEMO_LINE_SEQ_ID::text), '^^') 
            , '||', IFNULL(TRIM(LINK_TO_CUST_TRX_LINE_ID::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_TO_PARTY_SITE_USE_ID::text), '^^') 
            , '||', IFNULL(TRIM(RECURRING_BILL_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(PRODUCT_FISC_CLASSIFICATION::text), '^^') 
            , '||', IFNULL(TRIM(FRT_ED_ACCTD_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(SOURCE_DOCUMENT_LINE_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(WH_UPDATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(TAXABLE_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_NUMBER_4::text), '^^') 
            , '||', IFNULL(TRIM(DEFAULT_USSGL_TRANSACTION_CODE::text), '^^') 
            , '||', IFNULL(TRIM(REQUEST_ID::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_4::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_DATE_4::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_4::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_TO_CONTACT_ID::text), '^^') 
            , '||', IFNULL(TRIM(LINK_TO_PARENTLINE_ATTRIBUTE_1::text), '^^') 
            , '||', IFNULL(TRIM(INTERFACE_LINE_ATTRIBUTE_9::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_10::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_5::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_TO_PARTY_ADDRESS_ID::text), '^^') 
            , '||', IFNULL(TRIM(LINK_TO_PARENTLINE_ATTRIBUTE_13::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_3::text), '^^') 
            , '||', IFNULL(TRIM(SALES_ORDER_REVISION::text), '^^') 
            , '||', IFNULL(TRIM(VAT_TAX_ID::text), '^^') 
            , '||', IFNULL(TRIM(DOC_LINE_ID_CHAR_5::text), '^^') 
            , '||', IFNULL(TRIM(LINK_TO_PARENTLINE_ATTRIBUTE_2::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_2::text), '^^') 
            , '||', IFNULL(TRIM(QUANTITY_ORDERED::text), '^^') 
            , '||', IFNULL(TRIM(SALES_ORDER_DATE::text), '^^') 
            , '||', IFNULL(TRIM(SOURCE_DATA_KEY_3::text), '^^') 
            , '||', IFNULL(TRIM(RULE_END_DATE::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_14::text), '^^') 
            , '||', IFNULL(TRIM(CREATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_TO_ADDRESS_ID::text), '^^') 
            , '||', IFNULL(TRIM(ACCOUNTING_RULE_DURATION::text), '^^') 
            , '||', IFNULL(TRIM(REMAINING_PREPAY_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_DATE_1::text), '^^') 
            , '||', IFNULL(TRIM(DESCRIPTION::text), '^^') 
            , '||', IFNULL(TRIM(AMOUNT_DUE_ORIGINAL::text), '^^') 
            , '||', IFNULL(TRIM(PREVIOUS_CUSTOMER_TRX_LINE_ID::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_17::text), '^^') 
            , '||', IFNULL(TRIM(RECURRING_BILL_PLAN_LINE_ID::text), '^^') 
            , '||', IFNULL(TRIM(LINK_TO_PARENTLINE_ATTRIBUTE_9::text), '^^') 
            , '||', IFNULL(TRIM(CHRG_AMOUNT_REMAINING::text), '^^') 
            , '||', IFNULL(TRIM(SOURCE_DATA_KEY_1::text), '^^') 
            , '||', IFNULL(TRIM(LINK_TO_PARENTLINE_ATTRIBUTE_8::text), '^^') 
            , '||', IFNULL(TRIM(REQUIRES_MANUAL_SCHEDULING::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_19::text), '^^') 
            , '||', IFNULL(TRIM(GROSS_EXTENDED_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_15::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_DATE_2::text), '^^') 
            , '||', IFNULL(TRIM(INTERFACE_LINE_ATTRIBUTE_11::text), '^^') 
            , '||', IFNULL(TRIM(INSURANCE_CHARGE::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_NUMBER_5::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_LOGIN::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_8::text), '^^') 
            , '||', IFNULL(TRIM(LOCATION_SEGMENT_ID::text), '^^') 
            , '||', IFNULL(TRIM(TAX_EXEMPT_REASON_CODE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_3::text), '^^') 
            , '||', IFNULL(TRIM(LINK_TO_PARENTLINE_ATTRIBUTE_10::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_1::text), '^^') 
            , '||', IFNULL(TRIM(RULE_START_DATE::text), '^^') 
            , '||', IFNULL(TRIM(LINK_TO_PARENTLINE_CONTEXT::text), '^^') 
            , '||', IFNULL(TRIM(FREIGHT_CHARGE::text), '^^') 
            , '||', IFNULL(TRIM(INTERFACE_LINE_ATTRIBUTE_2::text), '^^') 
            , '||', IFNULL(TRIM(RECURRING_BILL_PLAN_ID::text), '^^') 
            , '||', IFNULL(TRIM(TRX_BUSINESS_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_NUMBER_2::text), '^^') 
            , '||', IFNULL(TRIM(PACKING_CHARGE::text), '^^') 
            , '||', IFNULL(TRIM(TAX_INVOICE_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(LINK_TO_PARENTLINE_ATTRIBUTE_11::text), '^^') 
            , '||', IFNULL(TRIM(AUTORULE_COMPLETE_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(SALES_TAX_ID::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_DATE_2::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_8::text), '^^') 
            , '||', IFNULL(TRIM(PREPAY_CUSTOMER_TRX_ID::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_EXCEPTION_RATE_ID::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_15::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_7::text), '^^') 
            , '||', IFNULL(TRIM(PAYMENT_TRXN_EXTENSION_ID::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
            , '||', IFNULL(TRIM(CCE::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
