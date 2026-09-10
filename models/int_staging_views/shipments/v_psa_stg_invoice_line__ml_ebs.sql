---- SRC LAYER ----
WITH
SRC_S              as ( SELECT * FROM {{ source('ml_ebs_ar', 'ra_customer_trx_lines_all') }} as SRC  ),
SRC_A              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  ),
SRC_S2             as ( SELECT * FROM {{ source('ml_ebs_inv', 'mtl_system_items_b') }} as SRC 
                        where organization_id = 1
                         
                        qualify 1 = row_number()over (partition by inventory_item_id order by psa_load_dts )  )

/*
SRC_S              as ( SELECT * FROM ml_ebs_ar.ra_customer_trx_lines_all )
, SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
, SRC_S2             as ( SELECT * FROM ml_ebs_inv.mtl_system_items_b )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        TO_CHAR(CUSTOMER_TRX_LINE_ID)                                as                                    INVOICE_LINE_BK
      , CUSTOMER_TRX_LINE_ID
      , ORG_ID
      , AMOUNT_DUE_ORIGINAL
      , HISTORICAL_FLAG
      , SOURCE_DATA_KEY4
      , LINE_RECOVERABLE
      , SALES_ORDER_DATE
      , SOURCE_DATA_KEY5
      , SOURCE_DATA_KEY2
      , SOURCE_DATA_KEY3
      , OVERRIDE_AUTO_ACCOUNTING_FLAG
      , INTERFACE_LINE_CONTEXT
      , PROGRAM_ID
      , SOURCE_DATA_KEY1
      , INTEREST_LINE_ID
      , INTERFACE_LINE_ATTRIBUTE8
      , GLOBAL_ATTRIBUTE5
      , INTERFACE_LINE_ATTRIBUTE7
      , GLOBAL_ATTRIBUTE4
      , FRT_ADJ_ACCTD_REMAINING
      , GLOBAL_ATTRIBUTE7
      , INTERFACE_LINE_ATTRIBUTE9
      , GLOBAL_ATTRIBUTE6
      , GLOBAL_ATTRIBUTE1
      , SALES_ORDER
      , GLOBAL_ATTRIBUTE3
      , GLOBAL_ATTRIBUTE2
      , CONTRACT_LINE_ID
      , GLOBAL_ATTRIBUTE9
      , FRT_ADJ_REMAINING
      , GLOBAL_ATTRIBUTE8
      , TAX_EXEMPT_REASON_CODE
      , PAYMENT_SET_ID
      , ATTRIBUTE3
      , ATTRIBUTE2
      , ATTRIBUTE1
      , CHRG_ACCTD_AMOUNT_REMAINING
      , FRT_ED_ACCTD_AMOUNT
      , ATTRIBUTE9
      , AMOUNT_INCLUDES_TAX_FLAG
      , ACCTD_AMOUNT_DUE_ORIGINAL
      , ATTRIBUTE8
      , ATTRIBUTE7
      , ATTRIBUTE6
      , ATTRIBUTE5
      , ATTRIBUTE4
      , LINK_TO_CUST_TRX_LINE_ID
      , INVENTORY_ITEM_ID
      , SHIP_TO_CUSTOMER_ID
      , UOM_CODE
      , VAT_TAX_ID
      , AUTORULE_DURATION_PROCESSED
      , MOVEMENT_ID
      , AUTOTAX
      , LAST_PERIOD_TO_CREDIT
      , DEFAULT_USSGL_TRANSACTION_CODE
      , ATTRIBUTE10
      , SHIP_TO_CONTACT_ID
      , ATTRIBUTE14
      , ATTRIBUTE13
      , ITEM_CONTEXT
      , ATTRIBUTE12
      , ATTRIBUTE11
      , DOC_LINE_ID_INT_5
      , DOC_LINE_ID_INT_4
      , LINE_NUMBER
      , PREVIOUS_CUSTOMER_TRX_LINE_ID
      , TAX_CLASSIFICATION_CODE
      , DOC_LINE_ID_INT_1
      , DOC_LINE_ID_INT_3
      , DOC_LINE_ID_INT_2
      , TAX_CALC_ACCTD_AMT
      , AUTORULE_COMPLETE_FLAG
      , DESCRIPTION
      , TAX_PRECEDENCE
      , ACCOUNTING_RULE_DURATION
      , TRANSLATED_DESCRIPTION
      , FRT_UNED_ACCTD_AMOUNT
      , LINE_TYPE
      , GLOBAL_ATTRIBUTE20
      , INTERFACE_LINE_ATTRIBUTE2
      , INTERFACE_LINE_ATTRIBUTE1
      , INTERFACE_LINE_ATTRIBUTE4
      , INTERFACE_LINE_ATTRIBUTE3
      , SALES_TAX_ID
      , INTERFACE_LINE_ATTRIBUTE6
      , MEMO_LINE_ID
      , INTERFACE_LINE_ATTRIBUTE5
      , GLOBAL_ATTRIBUTE17
      , GROSS_UNIT_SELLING_PRICE
      , GLOBAL_ATTRIBUTE18
      , GLOBAL_ATTRIBUTE15
      , GLOBAL_ATTRIBUTE16
      , PAYMENT_TRXN_EXTENSION_ID
      , GLOBAL_ATTRIBUTE13
      , GLOBAL_ATTRIBUTE14
      , GLOBAL_ATTRIBUTE11
      , GLOBAL_ATTRIBUTE12
      , LOCATION_SEGMENT_ID
      , ATTRIBUTE15
      , TAXABLE_FLAG
      , GLOBAL_ATTRIBUTE19
      , INVOICED_LINE_ACCTG_LEVEL
      , EXTENDED_ACCTD_AMOUNT
      , DOC_LINE_ID_CHAR_5
      , DOC_LINE_ID_CHAR_1
      , FRT_ED_AMOUNT
      , DOC_LINE_ID_CHAR_2
      , DOC_LINE_ID_CHAR_3
      , DOC_LINE_ID_CHAR_4
      , GLOBAL_ATTRIBUTE10
      , FRT_UNED_AMOUNT
      , TAX_LINE_ID
      , DEFAULT_USSGL_TRX_CODE_CONTEXT
      , QUANTITY_ORDERED
      , TAX_RECOVERABLE
      , ACCTD_AMOUNT_DUE_REMAINING
      , SALES_ORDER_SOURCE
      , CREATED_BY
      , LAST_UPDATED_BY
      , BR_REF_CUSTOMER_TRX_ID
      , BR_REF_PAYMENT_SCHEDULE_ID
      , AMOUNT_DUE_REMAINING
      , QUANTITY_INVOICED
      , PREVIOUS_CUSTOMER_TRX_ID
      , WAREHOUSE_ID
      , SALES_ORDER_REVISION
      , ATTRIBUTE_CATEGORY
      , PROGRAM_APPLICATION_ID
      , INITIAL_CUSTOMER_TRX_LINE_ID
      , TAX_VENDOR_RETURN_CODE
      , GROSS_EXTENDED_AMOUNT
      , SALES_ORDER_LINE
      , SET_OF_BOOKS_ID
      , SHIP_TO_SITE_USE_ID
      , REQUEST_ID
      , TAX_EXEMPT_NUMBER
      , RULE_END_DATE
      , BR_ADJUSTMENT_ID
      , RULE_START_DATE
      , MRC_EXTENDED_ACCTD_AMOUNT
      , TAX_EXEMPT_FLAG
      , DEFERRAL_EXCLUSION_FLAG
      , CUSTOMER_TRX_ID
      , REASON_CODE
      , LAST_UPDATE_LOGIN
      , ACCOUNTING_RULE_ID
      , TAX_EXEMPTION_ID
      , GLOBAL_ATTRIBUTE_CATEGORY
      , WH_UPDATE_DATE
      , INTERFACE_LINE_ATTRIBUTE15
      , INTERFACE_LINE_ATTRIBUTE14
      , SHIP_TO_ADDRESS_ID
      , INTERFACE_LINE_ATTRIBUTE13
      , INTERFACE_LINE_ATTRIBUTE12
      , ITEM_EXCEPTION_RATE_ID
      , INTERFACE_LINE_ATTRIBUTE11
      , INTERFACE_LINE_ATTRIBUTE10
      , PROGRAM_UPDATE_DATE
      , UNIT_STANDARD_PRICE
      , REVENUE_AMOUNT
      , QUANTITY_CREDITED
      , CREATION_DATE
      , TAXABLE_AMOUNT
      , UNIT_SELLING_PRICE
      , TAX_RATE
      , EXTENDED_AMOUNT
      , LAST_UPDATE_DATE
      , _FIVETRAN_DELETED
      , _FIVETRAN_ID
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED )                   as                                           LOAD_DTS
      , TO_CHAR(CUSTOMER_TRX_ID)                                     as                                         INVOICE_BK
      , COALESCE(UPPER(INTERFACE_LINE_ATTRIBUTE6),'-1')              as                                      ORDER_LINE_BK
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
        SEGMENT1                                                     as                                            ITEM_BK
      , INVENTORY_ITEM_ID                                            as                               S2_INVENTORY_ITEM_ID
      , organization_id
    FROM SRC_S2
)
---- RENAME LAYER ----

, RENAME_S as (
    SELECT
        INVOICE_LINE_BK
      , CUSTOMER_TRX_LINE_ID
      , ORG_ID
      , AMOUNT_DUE_ORIGINAL
      , HISTORICAL_FLAG
      , SOURCE_DATA_KEY4
      , LINE_RECOVERABLE
      , SALES_ORDER_DATE
      , SOURCE_DATA_KEY5
      , SOURCE_DATA_KEY2
      , SOURCE_DATA_KEY3
      , OVERRIDE_AUTO_ACCOUNTING_FLAG
      , INTERFACE_LINE_CONTEXT
      , PROGRAM_ID
      , SOURCE_DATA_KEY1
      , INTEREST_LINE_ID
      , INTERFACE_LINE_ATTRIBUTE8
      , GLOBAL_ATTRIBUTE5
      , INTERFACE_LINE_ATTRIBUTE7
      , GLOBAL_ATTRIBUTE4
      , FRT_ADJ_ACCTD_REMAINING
      , GLOBAL_ATTRIBUTE7
      , INTERFACE_LINE_ATTRIBUTE9
      , GLOBAL_ATTRIBUTE6
      , GLOBAL_ATTRIBUTE1
      , SALES_ORDER
      , GLOBAL_ATTRIBUTE3
      , GLOBAL_ATTRIBUTE2
      , CONTRACT_LINE_ID
      , GLOBAL_ATTRIBUTE9
      , FRT_ADJ_REMAINING
      , GLOBAL_ATTRIBUTE8
      , TAX_EXEMPT_REASON_CODE
      , PAYMENT_SET_ID
      , ATTRIBUTE3
      , ATTRIBUTE2
      , ATTRIBUTE1
      , CHRG_ACCTD_AMOUNT_REMAINING
      , FRT_ED_ACCTD_AMOUNT
      , ATTRIBUTE9
      , AMOUNT_INCLUDES_TAX_FLAG
      , ACCTD_AMOUNT_DUE_ORIGINAL
      , ATTRIBUTE8
      , ATTRIBUTE7
      , ATTRIBUTE6
      , ATTRIBUTE5
      , ATTRIBUTE4
      , LINK_TO_CUST_TRX_LINE_ID
      , INVENTORY_ITEM_ID
      , SHIP_TO_CUSTOMER_ID
      , UOM_CODE
      , VAT_TAX_ID
      , AUTORULE_DURATION_PROCESSED
      , MOVEMENT_ID
      , AUTOTAX
      , LAST_PERIOD_TO_CREDIT
      , DEFAULT_USSGL_TRANSACTION_CODE
      , ATTRIBUTE10
      , SHIP_TO_CONTACT_ID
      , ATTRIBUTE14
      , ATTRIBUTE13
      , ITEM_CONTEXT
      , ATTRIBUTE12
      , ATTRIBUTE11
      , DOC_LINE_ID_INT_5
      , DOC_LINE_ID_INT_4
      , LINE_NUMBER
      , PREVIOUS_CUSTOMER_TRX_LINE_ID
      , TAX_CLASSIFICATION_CODE
      , DOC_LINE_ID_INT_1
      , DOC_LINE_ID_INT_3
      , DOC_LINE_ID_INT_2
      , TAX_CALC_ACCTD_AMT
      , AUTORULE_COMPLETE_FLAG
      , DESCRIPTION
      , TAX_PRECEDENCE
      , ACCOUNTING_RULE_DURATION
      , TRANSLATED_DESCRIPTION
      , FRT_UNED_ACCTD_AMOUNT
      , LINE_TYPE
      , GLOBAL_ATTRIBUTE20
      , INTERFACE_LINE_ATTRIBUTE2
      , INTERFACE_LINE_ATTRIBUTE1
      , INTERFACE_LINE_ATTRIBUTE4
      , INTERFACE_LINE_ATTRIBUTE3
      , SALES_TAX_ID
      , INTERFACE_LINE_ATTRIBUTE6
      , MEMO_LINE_ID
      , INTERFACE_LINE_ATTRIBUTE5
      , GLOBAL_ATTRIBUTE17
      , GROSS_UNIT_SELLING_PRICE
      , GLOBAL_ATTRIBUTE18
      , GLOBAL_ATTRIBUTE15
      , GLOBAL_ATTRIBUTE16
      , PAYMENT_TRXN_EXTENSION_ID
      , GLOBAL_ATTRIBUTE13
      , GLOBAL_ATTRIBUTE14
      , GLOBAL_ATTRIBUTE11
      , GLOBAL_ATTRIBUTE12
      , LOCATION_SEGMENT_ID
      , ATTRIBUTE15
      , TAXABLE_FLAG
      , GLOBAL_ATTRIBUTE19
      , INVOICED_LINE_ACCTG_LEVEL
      , EXTENDED_ACCTD_AMOUNT
      , DOC_LINE_ID_CHAR_5
      , DOC_LINE_ID_CHAR_1
      , FRT_ED_AMOUNT
      , DOC_LINE_ID_CHAR_2
      , DOC_LINE_ID_CHAR_3
      , DOC_LINE_ID_CHAR_4
      , GLOBAL_ATTRIBUTE10
      , FRT_UNED_AMOUNT
      , TAX_LINE_ID
      , DEFAULT_USSGL_TRX_CODE_CONTEXT
      , QUANTITY_ORDERED
      , TAX_RECOVERABLE
      , ACCTD_AMOUNT_DUE_REMAINING
      , SALES_ORDER_SOURCE
      , CREATED_BY
      , LAST_UPDATED_BY
      , BR_REF_CUSTOMER_TRX_ID
      , BR_REF_PAYMENT_SCHEDULE_ID
      , AMOUNT_DUE_REMAINING
      , QUANTITY_INVOICED
      , PREVIOUS_CUSTOMER_TRX_ID
      , WAREHOUSE_ID
      , SALES_ORDER_REVISION
      , ATTRIBUTE_CATEGORY
      , PROGRAM_APPLICATION_ID
      , INITIAL_CUSTOMER_TRX_LINE_ID
      , TAX_VENDOR_RETURN_CODE
      , GROSS_EXTENDED_AMOUNT
      , SALES_ORDER_LINE
      , SET_OF_BOOKS_ID
      , SHIP_TO_SITE_USE_ID
      , REQUEST_ID
      , TAX_EXEMPT_NUMBER
      , RULE_END_DATE
      , BR_ADJUSTMENT_ID
      , RULE_START_DATE
      , MRC_EXTENDED_ACCTD_AMOUNT
      , TAX_EXEMPT_FLAG
      , DEFERRAL_EXCLUSION_FLAG
      , CUSTOMER_TRX_ID
      , REASON_CODE
      , LAST_UPDATE_LOGIN
      , ACCOUNTING_RULE_ID
      , TAX_EXEMPTION_ID
      , GLOBAL_ATTRIBUTE_CATEGORY
      , WH_UPDATE_DATE
      , INTERFACE_LINE_ATTRIBUTE15
      , INTERFACE_LINE_ATTRIBUTE14
      , SHIP_TO_ADDRESS_ID
      , INTERFACE_LINE_ATTRIBUTE13
      , INTERFACE_LINE_ATTRIBUTE12
      , ITEM_EXCEPTION_RATE_ID
      , INTERFACE_LINE_ATTRIBUTE11
      , INTERFACE_LINE_ATTRIBUTE10
      , PROGRAM_UPDATE_DATE
      , UNIT_STANDARD_PRICE
      , REVENUE_AMOUNT
      , QUANTITY_CREDITED
      , CREATION_DATE
      , TAXABLE_AMOUNT
      , UNIT_SELLING_PRICE
      , TAX_RATE
      , EXTENDED_AMOUNT
      , LAST_UPDATE_DATE
      , _FIVETRAN_DELETED
      , _FIVETRAN_ID
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , INVOICE_BK
      , ORDER_LINE_BK
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
        ITEM_BK
      , S2_INVENTORY_ITEM_ID
      , organization_id
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
    WHERE rec_src = 'USWIOC.ORCL.EBSPRD.CUSTOMER_TRX_LINES_ALL'
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
        , ORG_ID
        , AMOUNT_DUE_ORIGINAL
        , HISTORICAL_FLAG
        , SOURCE_DATA_KEY4
        , LINE_RECOVERABLE
        , SALES_ORDER_DATE
        , SOURCE_DATA_KEY5
        , SOURCE_DATA_KEY2
        , SOURCE_DATA_KEY3
        , OVERRIDE_AUTO_ACCOUNTING_FLAG
        , INTERFACE_LINE_CONTEXT
        , PROGRAM_ID
        , SOURCE_DATA_KEY1
        , INTEREST_LINE_ID
        , INTERFACE_LINE_ATTRIBUTE8
        , GLOBAL_ATTRIBUTE5
        , INTERFACE_LINE_ATTRIBUTE7
        , GLOBAL_ATTRIBUTE4
        , FRT_ADJ_ACCTD_REMAINING
        , GLOBAL_ATTRIBUTE7
        , INTERFACE_LINE_ATTRIBUTE9
        , GLOBAL_ATTRIBUTE6
        , GLOBAL_ATTRIBUTE1
        , SALES_ORDER
        , GLOBAL_ATTRIBUTE3
        , GLOBAL_ATTRIBUTE2
        , CONTRACT_LINE_ID
        , GLOBAL_ATTRIBUTE9
        , FRT_ADJ_REMAINING
        , GLOBAL_ATTRIBUTE8
        , TAX_EXEMPT_REASON_CODE
        , PAYMENT_SET_ID
        , ATTRIBUTE3
        , ATTRIBUTE2
        , ATTRIBUTE1
        , CHRG_ACCTD_AMOUNT_REMAINING
        , FRT_ED_ACCTD_AMOUNT
        , ATTRIBUTE9
        , AMOUNT_INCLUDES_TAX_FLAG
        , ACCTD_AMOUNT_DUE_ORIGINAL
        , ATTRIBUTE8
        , ATTRIBUTE7
        , ATTRIBUTE6
        , ATTRIBUTE5
        , ATTRIBUTE4
        , LINK_TO_CUST_TRX_LINE_ID
        , INVENTORY_ITEM_ID
        , SHIP_TO_CUSTOMER_ID
        , UOM_CODE
        , VAT_TAX_ID
        , AUTORULE_DURATION_PROCESSED
        , MOVEMENT_ID
        , AUTOTAX
        , LAST_PERIOD_TO_CREDIT
        , DEFAULT_USSGL_TRANSACTION_CODE
        , ATTRIBUTE10
        , SHIP_TO_CONTACT_ID
        , ATTRIBUTE14
        , ATTRIBUTE13
        , ITEM_CONTEXT
        , ATTRIBUTE12
        , ATTRIBUTE11
        , DOC_LINE_ID_INT_5
        , DOC_LINE_ID_INT_4
        , LINE_NUMBER
        , PREVIOUS_CUSTOMER_TRX_LINE_ID
        , TAX_CLASSIFICATION_CODE
        , DOC_LINE_ID_INT_1
        , DOC_LINE_ID_INT_3
        , DOC_LINE_ID_INT_2
        , TAX_CALC_ACCTD_AMT
        , AUTORULE_COMPLETE_FLAG
        , DESCRIPTION
        , TAX_PRECEDENCE
        , ACCOUNTING_RULE_DURATION
        , TRANSLATED_DESCRIPTION
        , FRT_UNED_ACCTD_AMOUNT
        , LINE_TYPE
        , GLOBAL_ATTRIBUTE20
        , INTERFACE_LINE_ATTRIBUTE2
        , INTERFACE_LINE_ATTRIBUTE1
        , INTERFACE_LINE_ATTRIBUTE4
        , INTERFACE_LINE_ATTRIBUTE3
        , SALES_TAX_ID
        , INTERFACE_LINE_ATTRIBUTE6
        , MEMO_LINE_ID
        , INTERFACE_LINE_ATTRIBUTE5
        , GLOBAL_ATTRIBUTE17
        , GROSS_UNIT_SELLING_PRICE
        , GLOBAL_ATTRIBUTE18
        , GLOBAL_ATTRIBUTE15
        , GLOBAL_ATTRIBUTE16
        , PAYMENT_TRXN_EXTENSION_ID
        , GLOBAL_ATTRIBUTE13
        , GLOBAL_ATTRIBUTE14
        , GLOBAL_ATTRIBUTE11
        , GLOBAL_ATTRIBUTE12
        , LOCATION_SEGMENT_ID
        , ATTRIBUTE15
        , TAXABLE_FLAG
        , GLOBAL_ATTRIBUTE19
        , INVOICED_LINE_ACCTG_LEVEL
        , EXTENDED_ACCTD_AMOUNT
        , DOC_LINE_ID_CHAR_5
        , DOC_LINE_ID_CHAR_1
        , FRT_ED_AMOUNT
        , DOC_LINE_ID_CHAR_2
        , DOC_LINE_ID_CHAR_3
        , DOC_LINE_ID_CHAR_4
        , GLOBAL_ATTRIBUTE10
        , FRT_UNED_AMOUNT
        , TAX_LINE_ID
        , DEFAULT_USSGL_TRX_CODE_CONTEXT
        , QUANTITY_ORDERED
        , TAX_RECOVERABLE
        , ACCTD_AMOUNT_DUE_REMAINING
        , SALES_ORDER_SOURCE
        , CREATED_BY
        , LAST_UPDATED_BY
        , BR_REF_CUSTOMER_TRX_ID
        , BR_REF_PAYMENT_SCHEDULE_ID
        , AMOUNT_DUE_REMAINING
        , QUANTITY_INVOICED
        , PREVIOUS_CUSTOMER_TRX_ID
        , WAREHOUSE_ID
        , SALES_ORDER_REVISION
        , ATTRIBUTE_CATEGORY
        , PROGRAM_APPLICATION_ID
        , INITIAL_CUSTOMER_TRX_LINE_ID
        , TAX_VENDOR_RETURN_CODE
        , GROSS_EXTENDED_AMOUNT
        , SALES_ORDER_LINE
        , SET_OF_BOOKS_ID
        , SHIP_TO_SITE_USE_ID
        , REQUEST_ID
        , TAX_EXEMPT_NUMBER
        , RULE_END_DATE
        , BR_ADJUSTMENT_ID
        , RULE_START_DATE
        , MRC_EXTENDED_ACCTD_AMOUNT
        , TAX_EXEMPT_FLAG
        , DEFERRAL_EXCLUSION_FLAG
        , CUSTOMER_TRX_ID
        , REASON_CODE
        , LAST_UPDATE_LOGIN
        , ACCOUNTING_RULE_ID
        , TAX_EXEMPTION_ID
        , GLOBAL_ATTRIBUTE_CATEGORY
        , WH_UPDATE_DATE
        , INTERFACE_LINE_ATTRIBUTE15
        , INTERFACE_LINE_ATTRIBUTE14
        , SHIP_TO_ADDRESS_ID
        , INTERFACE_LINE_ATTRIBUTE13
        , INTERFACE_LINE_ATTRIBUTE12
        , ITEM_EXCEPTION_RATE_ID
        , INTERFACE_LINE_ATTRIBUTE11
        , INTERFACE_LINE_ATTRIBUTE10
        , PROGRAM_UPDATE_DATE
        , UNIT_STANDARD_PRICE
        , REVENUE_AMOUNT
        , QUANTITY_CREDITED
        , CREATION_DATE
        , TAXABLE_AMOUNT
        , UNIT_SELLING_PRICE
        , TAX_RATE
        , EXTENDED_AMOUNT
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
        , INVOICE_BK
        , ITEM_BK
        , ORDER_LINE_BK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(CUSTOMER_TRX_LINE_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as INVOICE_LINE_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(CUSTOMER_TRX_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as INVOICE_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ITEM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ITEM_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(CUSTOMER_TRX_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(CUSTOMER_TRX_LINE_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(ITEM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as INVOICE_INVOICE_LINE_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ORDER_LINE_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ORDER_LINE_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(CUSTOMER_TRX_LINE_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(INTERFACE_LINE_ATTRIBUTE6 as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as INVOICE_LINE_ORDER_LINE_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(ORG_ID::text), '^^') 
            , '||', IFNULL(TRIM(AMOUNT_DUE_ORIGINAL::text), '^^') 
            , '||', IFNULL(TRIM(HISTORICAL_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(LINE_RECOVERABLE::text), '^^') 
            , '||', IFNULL(TRIM(SALES_ORDER_DATE::text), '^^') 
            , '||', IFNULL(TRIM(SOURCE_DATA_KEY5::text), '^^') 
            , '||', IFNULL(TRIM(SOURCE_DATA_KEY2::text), '^^') 
            , '||', IFNULL(TRIM(SOURCE_DATA_KEY3::text), '^^') 
            , '||', IFNULL(TRIM(OVERRIDE_AUTO_ACCOUNTING_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(INTERFACE_LINE_CONTEXT::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_ID::text), '^^') 
            , '||', IFNULL(TRIM(SOURCE_DATA_KEY1::text), '^^') 
            , '||', IFNULL(TRIM(INTEREST_LINE_ID::text), '^^') 
            , '||', IFNULL(TRIM(INTERFACE_LINE_ATTRIBUTE8::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE5::text), '^^') 
            , '||', IFNULL(TRIM(INTERFACE_LINE_ATTRIBUTE7::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE4::text), '^^') 
            , '||', IFNULL(TRIM(FRT_ADJ_ACCTD_REMAINING::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE7::text), '^^') 
            , '||', IFNULL(TRIM(INTERFACE_LINE_ATTRIBUTE9::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE6::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE1::text), '^^') 
            , '||', IFNULL(TRIM(SALES_ORDER::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE3::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE2::text), '^^') 
            , '||', IFNULL(TRIM(CONTRACT_LINE_ID::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE9::text), '^^') 
            , '||', IFNULL(TRIM(FRT_ADJ_REMAINING::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE8::text), '^^') 
            , '||', IFNULL(TRIM(TAX_EXEMPT_REASON_CODE::text), '^^') 
            , '||', IFNULL(TRIM(PAYMENT_SET_ID::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE3::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE2::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE1::text), '^^') 
            , '||', IFNULL(TRIM(CHRG_ACCTD_AMOUNT_REMAINING::text), '^^') 
            , '||', IFNULL(TRIM(FRT_ED_ACCTD_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE9::text), '^^') 
            , '||', IFNULL(TRIM(AMOUNT_INCLUDES_TAX_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(ACCTD_AMOUNT_DUE_ORIGINAL::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE8::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE7::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE6::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE5::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE4::text), '^^') 
            , '||', IFNULL(TRIM(LINK_TO_CUST_TRX_LINE_ID::text), '^^') 
            , '||', IFNULL(TRIM(INVENTORY_ITEM_ID::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_TO_CUSTOMER_ID::text), '^^') 
            , '||', IFNULL(TRIM(UOM_CODE::text), '^^') 
            , '||', IFNULL(TRIM(VAT_TAX_ID::text), '^^') 
            , '||', IFNULL(TRIM(AUTORULE_DURATION_PROCESSED::text), '^^') 
            , '||', IFNULL(TRIM(MOVEMENT_ID::text), '^^') 
            , '||', IFNULL(TRIM(AUTOTAX::text), '^^') 
            , '||', IFNULL(TRIM(LAST_PERIOD_TO_CREDIT::text), '^^') 
            , '||', IFNULL(TRIM(DEFAULT_USSGL_TRANSACTION_CODE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE10::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_TO_CONTACT_ID::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE14::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE13::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_CONTEXT::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE12::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE11::text), '^^') 
            , '||', IFNULL(TRIM(DOC_LINE_ID_INT_5::text), '^^') 
            , '||', IFNULL(TRIM(DOC_LINE_ID_INT_4::text), '^^') 
            , '||', IFNULL(TRIM(LINE_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(PREVIOUS_CUSTOMER_TRX_LINE_ID::text), '^^') 
            , '||', IFNULL(TRIM(TAX_CLASSIFICATION_CODE::text), '^^') 
            , '||', IFNULL(TRIM(DOC_LINE_ID_INT_1::text), '^^') 
            , '||', IFNULL(TRIM(DOC_LINE_ID_INT_3::text), '^^') 
            , '||', IFNULL(TRIM(DOC_LINE_ID_INT_2::text), '^^') 
            , '||', IFNULL(TRIM(TAX_CALC_ACCTD_AMT::text), '^^') 
            , '||', IFNULL(TRIM(AUTORULE_COMPLETE_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(DESCRIPTION::text), '^^') 
            , '||', IFNULL(TRIM(TAX_PRECEDENCE::text), '^^') 
            , '||', IFNULL(TRIM(ACCOUNTING_RULE_DURATION::text), '^^') 
            , '||', IFNULL(TRIM(TRANSLATED_DESCRIPTION::text), '^^') 
            , '||', IFNULL(TRIM(FRT_UNED_ACCTD_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(LINE_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE20::text), '^^') 
            , '||', IFNULL(TRIM(INTERFACE_LINE_ATTRIBUTE2::text), '^^') 
            , '||', IFNULL(TRIM(INTERFACE_LINE_ATTRIBUTE1::text), '^^') 
            , '||', IFNULL(TRIM(INTERFACE_LINE_ATTRIBUTE4::text), '^^') 
            , '||', IFNULL(TRIM(INTERFACE_LINE_ATTRIBUTE3::text), '^^') 
            , '||', IFNULL(TRIM(SALES_TAX_ID::text), '^^') 
            , '||', IFNULL(TRIM(INTERFACE_LINE_ATTRIBUTE6::text), '^^') 
            , '||', IFNULL(TRIM(MEMO_LINE_ID::text), '^^') 
            , '||', IFNULL(TRIM(INTERFACE_LINE_ATTRIBUTE5::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE17::text), '^^') 
            , '||', IFNULL(TRIM(GROSS_UNIT_SELLING_PRICE::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE18::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE15::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE16::text), '^^') 
            , '||', IFNULL(TRIM(PAYMENT_TRXN_EXTENSION_ID::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE13::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE14::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE11::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE12::text), '^^') 
            , '||', IFNULL(TRIM(LOCATION_SEGMENT_ID::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE15::text), '^^') 
            , '||', IFNULL(TRIM(TAXABLE_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE19::text), '^^') 
            , '||', IFNULL(TRIM(INVOICED_LINE_ACCTG_LEVEL::text), '^^') 
            , '||', IFNULL(TRIM(EXTENDED_ACCTD_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(DOC_LINE_ID_CHAR_5::text), '^^') 
            , '||', IFNULL(TRIM(DOC_LINE_ID_CHAR_1::text), '^^') 
            , '||', IFNULL(TRIM(FRT_ED_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(DOC_LINE_ID_CHAR_2::text), '^^') 
            , '||', IFNULL(TRIM(DOC_LINE_ID_CHAR_3::text), '^^') 
            , '||', IFNULL(TRIM(DOC_LINE_ID_CHAR_4::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE10::text), '^^') 
            , '||', IFNULL(TRIM(FRT_UNED_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(TAX_LINE_ID::text), '^^') 
            , '||', IFNULL(TRIM(DEFAULT_USSGL_TRX_CODE_CONTEXT::text), '^^') 
            , '||', IFNULL(TRIM(QUANTITY_ORDERED::text), '^^') 
            , '||', IFNULL(TRIM(TAX_RECOVERABLE::text), '^^') 
            , '||', IFNULL(TRIM(ACCTD_AMOUNT_DUE_REMAINING::text), '^^') 
            , '||', IFNULL(TRIM(SALES_ORDER_SOURCE::text), '^^') 
            , '||', IFNULL(TRIM(CREATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(BR_REF_CUSTOMER_TRX_ID::text), '^^') 
            , '||', IFNULL(TRIM(BR_REF_PAYMENT_SCHEDULE_ID::text), '^^') 
            , '||', IFNULL(TRIM(AMOUNT_DUE_REMAINING::text), '^^') 
            , '||', IFNULL(TRIM(QUANTITY_INVOICED::text), '^^') 
            , '||', IFNULL(TRIM(PREVIOUS_CUSTOMER_TRX_ID::text), '^^') 
            , '||', IFNULL(TRIM(WAREHOUSE_ID::text), '^^') 
            , '||', IFNULL(TRIM(SALES_ORDER_REVISION::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_APPLICATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(INITIAL_CUSTOMER_TRX_LINE_ID::text), '^^') 
            , '||', IFNULL(TRIM(TAX_VENDOR_RETURN_CODE::text), '^^') 
            , '||', IFNULL(TRIM(GROSS_EXTENDED_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(SALES_ORDER_LINE::text), '^^') 
            , '||', IFNULL(TRIM(SET_OF_BOOKS_ID::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_TO_SITE_USE_ID::text), '^^') 
            , '||', IFNULL(TRIM(REQUEST_ID::text), '^^') 
            , '||', IFNULL(TRIM(TAX_EXEMPT_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(RULE_END_DATE::text), '^^') 
            , '||', IFNULL(TRIM(BR_ADJUSTMENT_ID::text), '^^') 
            , '||', IFNULL(TRIM(RULE_START_DATE::text), '^^') 
            , '||', IFNULL(TRIM(MRC_EXTENDED_ACCTD_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(TAX_EXEMPT_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(DEFERRAL_EXCLUSION_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(CUSTOMER_TRX_ID::text), '^^') 
            , '||', IFNULL(TRIM(REASON_CODE::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_LOGIN::text), '^^') 
            , '||', IFNULL(TRIM(ACCOUNTING_RULE_ID::text), '^^') 
            , '||', IFNULL(TRIM(TAX_EXEMPTION_ID::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(WH_UPDATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(INTERFACE_LINE_ATTRIBUTE15::text), '^^') 
            , '||', IFNULL(TRIM(INTERFACE_LINE_ATTRIBUTE14::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_TO_ADDRESS_ID::text), '^^') 
            , '||', IFNULL(TRIM(INTERFACE_LINE_ATTRIBUTE13::text), '^^') 
            , '||', IFNULL(TRIM(INTERFACE_LINE_ATTRIBUTE12::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_EXCEPTION_RATE_ID::text), '^^') 
            , '||', IFNULL(TRIM(INTERFACE_LINE_ATTRIBUTE11::text), '^^') 
            , '||', IFNULL(TRIM(INTERFACE_LINE_ATTRIBUTE10::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_UPDATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(UNIT_STANDARD_PRICE::text), '^^') 
            , '||', IFNULL(TRIM(REVENUE_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(QUANTITY_CREDITED::text), '^^') 
            , '||', IFNULL(TRIM(CREATION_DATE::text), '^^') 
            , '||', IFNULL(TRIM(TAXABLE_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(UNIT_SELLING_PRICE::text), '^^') 
            , '||', IFNULL(TRIM(TAX_RATE::text), '^^') 
            , '||', IFNULL(TRIM(EXTENDED_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
