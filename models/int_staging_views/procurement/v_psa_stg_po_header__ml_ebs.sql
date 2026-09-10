---- SRC LAYER ----
WITH
SRC_PO_HDR         as ( SELECT ACCEPTANCE_DUE_DATE, ACCEPTANCE_REQUIRED_FLAG, AGENT_ID, AME_APPROVAL_ID, AME_TRANSACTION_TYPE, AMOUNT_LIMIT, APPROVAL_REQUIRED_FLAG, APPROVED_DATE, APPROVED_FLAG, ATTRIBUTE1, ATTRIBUTE10, ATTRIBUTE11, ATTRIBUTE12, ATTRIBUTE13, ATTRIBUTE14, ATTRIBUTE15, ATTRIBUTE2, ATTRIBUTE3, ATTRIBUTE4, ATTRIBUTE5, ATTRIBUTE6, ATTRIBUTE7, ATTRIBUTE8, ATTRIBUTE9, ATTRIBUTE_CATEGORY, AUTHORIZATION_STATUS, AUTO_SOURCING_FLAG, BILL_TO_LOCATION_ID, BLANKET_TOTAL_AMOUNT, CANCEL_FLAG, CAT_ADMIN_AUTH_ENABLED_FLAG, CBC_ACCOUNTING_DATE, CHANGE_REQUESTED_BY, CHANGE_SUMMARY, CLM_DOCUMENT_NUMBER, CLOSED_CODE, CLOSED_DATE, COMMENTS, COMM_REV_NUM, CONFIRMING_ORDER_FLAG, CONSIGNED_CONSUMPTION_FLAG, CONSUME_REQ_DEMAND_FLAG, CONTERMS_ARTICLES_UPD_DATE, CONTERMS_DELIV_UPD_DATE, CONTERMS_EXIST_FLAG, CPA_REFERENCE, CREATED_BY, CREATED_LANGUAGE, CREATION_DATE, CURRENCY_CODE, DOCUMENT_CREATION_METHOD, EDI_PROCESSED_FLAG, EDI_PROCESSED_STATUS, EMAIL_ADDRESS, ENABLED_FLAG, ENABLE_ALL_SITES, ENCUMBRANCE_REQUIRED_FLAG, END_DATE, END_DATE_ACTIVE, FAX, FIRM_DATE, FIRM_STATUS_LOOKUP_CODE, FOB_LOOKUP_CODE, FREIGHT_TERMS_LOOKUP_CODE, FROM_HEADER_ID, FROM_TYPE_LOOKUP_CODE, FROZEN_FLAG, GLOBAL_AGREEMENT_FLAG, GLOBAL_ATTRIBUTE1, GLOBAL_ATTRIBUTE10, GLOBAL_ATTRIBUTE11, GLOBAL_ATTRIBUTE12, GLOBAL_ATTRIBUTE13, GLOBAL_ATTRIBUTE14, GLOBAL_ATTRIBUTE15, GLOBAL_ATTRIBUTE16, GLOBAL_ATTRIBUTE17, GLOBAL_ATTRIBUTE18, GLOBAL_ATTRIBUTE19, GLOBAL_ATTRIBUTE2, GLOBAL_ATTRIBUTE20, GLOBAL_ATTRIBUTE3, GLOBAL_ATTRIBUTE4, GLOBAL_ATTRIBUTE5, GLOBAL_ATTRIBUTE6, GLOBAL_ATTRIBUTE7, GLOBAL_ATTRIBUTE8, GLOBAL_ATTRIBUTE9, GLOBAL_ATTRIBUTE_CATEGORY, GOVERNMENT_CONTEXT, INTERFACE_SOURCE_CODE, LAST_UPDATED_BY, LAST_UPDATED_PROGRAM, LAST_UPDATE_DATE, LAST_UPDATE_LOGIN, LOCK_OWNER_ROLE, LOCK_OWNER_USER_ID, MIN_RELEASE_AMOUNT, MRC_RATE, MRC_RATE_DATE, MRC_RATE_TYPE, NOTE_TO_AUTHORIZER, NOTE_TO_RECEIVER, NOTE_TO_VENDOR, ORG_ID, OTM_RECOVERY_FLAG, OTM_STATUS_CODE, PAY_ON_CODE, PAY_WHEN_PAID, PCARD_ID, PENDING_SIGNATURE_FLAG, PO_HEADER_ID, PRICE_UPDATE_TOLERANCE, PRINTED_DATE, PRINT_COUNT, PROGRAM_APPLICATION_ID, PROGRAM_ID, PROGRAM_UPDATE_DATE, PSA_DELETE_IND, PSA_LOAD_DTS, QUOTATION_CLASS_CODE, QUOTE_TYPE_LOOKUP_CODE, QUOTE_VENDOR_QUOTE_NUMBER, QUOTE_WARNING_DELAY, QUOTE_WARNING_DELAY_UNIT, RATE, RATE_DATE, RATE_TYPE, REFERENCE_NUM, REPLY_DATE, REPLY_METHOD_LOOKUP_CODE, REQUEST_ID, RETRO_PRICE_APPLY_UPDATES_FLAG, RETRO_PRICE_COMM_UPDATES_FLAG, REVISED_DATE, REVISION_NUM, RFQ_CLOSE_DATE, SEGMENT1, SEGMENT2, SEGMENT3, SEGMENT4, SEGMENT5, SHIPPING_CONTROL, SHIP_TO_LOCATION_ID, SHIP_VIA_LOOKUP_CODE, START_DATE, START_DATE_ACTIVE, STATUS_LOOKUP_CODE, STYLE_ID, SUBMIT_DATE, SUMMARY_FLAG, SUPPLIER_AUTH_ENABLED_FLAG, SUPPLIER_NOTIF_METHOD, SUPPLY_AGREEMENT_FLAG, TAX_ATTRIBUTE_UPDATE_CODE, TERMS_ID, TYPE_LOOKUP_CODE, UPDATE_SOURCING_RULES_FLAG, USER_HOLD_FLAG, USSGL_TRANSACTION_CODE, VENDOR_CONTACT_ID, VENDOR_ID, VENDOR_ORDER_NUM, VENDOR_SITE_ID, WF_ITEM_KEY, WF_ITEM_TYPE, XML_CHANGE_SEND_DATE, XML_FLAG, XML_SEND_DATE, _FIVETRAN_DELETED, _FIVETRAN_ID, _FIVETRAN_SYNCED FROM {{ source('ml_ebs_po', 'po_headers_all') }} as SRC  ),
SRC_A              as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  ),
SRC_AP             as ( SELECT DESCRIPTION, TERM_ID FROM {{ source('ml_ebs_ap', 'ap_terms_tl') }} as SRC 
                        qualify 1= row_number()over(partition by term_id order by _fivetran_synced desc, psa_load_dts desc) ),
SRC_sup            as ( SELECT SEGMENT1, VENDOR_ID FROM {{ source('ml_ebs_ap', 'ap_suppliers') }} as SRC 
                        qualify 1= row_number()over(partition by vendor_id order by _fivetran_synced desc, psa_load_dts desc) )

/*
SRC_PO_HDR         as ( SELECT * FROM ml_ebs_po.po_headers_all )
SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
SRC_AP             as ( SELECT * FROM ml_ebs_ap.ap_terms_tl )
SRC_sup            as ( SELECT * FROM ml_ebs_ap.ap_suppliers )
*/
---- LOGIC LAYER ----

, LOGIC_PO_HDR as (
    SELECT
        COALESCE(PO_HEADER_ID::TEXT,'')                              as                                       PO_HEADER_BK
      , PO_HEADER_ID
      , ORG_ID
      , FREIGHT_TERMS_LOOKUP_CODE
      , XML_FLAG
      , APPROVED_FLAG
      , LOCK_OWNER_USER_ID
      , PROGRAM_ID
      , GLOBAL_ATTRIBUTE5
      , GLOBAL_ATTRIBUTE4
      , CONSIGNED_CONSUMPTION_FLAG
      , RATE_DATE
      , GLOBAL_ATTRIBUTE7
      , WF_ITEM_TYPE
      , AUTHORIZATION_STATUS
      , GLOBAL_ATTRIBUTE6
      , GLOBAL_ATTRIBUTE1
      , EMAIL_ADDRESS
      , SEGMENT4
      , ACCEPTANCE_REQUIRED_FLAG
      , SEGMENT3
      , GLOBAL_ATTRIBUTE3
      , GLOBAL_ATTRIBUTE2
      , SEGMENT5
      , QUOTE_WARNING_DELAY_UNIT
      , GLOBAL_ATTRIBUTE9
      , GLOBAL_ATTRIBUTE8
      , GLOBAL_AGREEMENT_FLAG
      , END_DATE_ACTIVE
      , INTERFACE_SOURCE_CODE
      , ATTRIBUTE3
      , CREATED_LANGUAGE
      , ATTRIBUTE2
      , RFQ_CLOSE_DATE
      , ATTRIBUTE1
      , REPLY_METHOD_LOOKUP_CODE
      , CONTERMS_EXIST_FLAG
      , SUPPLY_AGREEMENT_FLAG
      , PRINT_COUNT
      , AMOUNT_LIMIT
      , AME_TRANSACTION_TYPE
      , ATTRIBUTE9
      , ATTRIBUTE8
      , SUPPLIER_NOTIF_METHOD
      , ATTRIBUTE7
      , USSGL_TRANSACTION_CODE
      , ATTRIBUTE6
      , ATTRIBUTE5
      , ATTRIBUTE4
      , VENDOR_ID
      , VENDOR_ORDER_NUM
      , NOTE_TO_AUTHORIZER
      , CPA_REFERENCE
      , RETRO_PRICE_APPLY_UPDATES_FLAG
      , STYLE_ID
      , APPROVAL_REQUIRED_FLAG
      , NOTE_TO_VENDOR
      , EDI_PROCESSED_STATUS
      , ATTRIBUTE10
      , AME_APPROVAL_ID
      , ATTRIBUTE14
      , OTM_RECOVERY_FLAG
      , ATTRIBUTE13
      , ATTRIBUTE12
      , ATTRIBUTE11
      , UPDATE_SOURCING_RULES_FLAG
      , BILL_TO_LOCATION_ID
      , COMMENTS
      , PAY_WHEN_PAID
      , MRC_RATE_TYPE
      , START_DATE_ACTIVE
      , FROM_HEADER_ID
      , QUOTE_TYPE_LOOKUP_CODE
      , FIRM_DATE
      , GLOBAL_ATTRIBUTE20
      , START_DATE
      , REFERENCE_NUM
      , MIN_RELEASE_AMOUNT
      , MRC_RATE
      , PAY_ON_CODE
      , LAST_UPDATED_PROGRAM
      , GLOBAL_ATTRIBUTE17
      , GLOBAL_ATTRIBUTE18
      , FROZEN_FLAG
      , GLOBAL_ATTRIBUTE15
      , CANCEL_FLAG
      , GLOBAL_ATTRIBUTE16
      , GLOBAL_ATTRIBUTE13
      , PCARD_ID
      , GLOBAL_ATTRIBUTE14
      , GLOBAL_ATTRIBUTE11
      , QUOTE_WARNING_DELAY
      , GLOBAL_ATTRIBUTE12
      , ENCUMBRANCE_REQUIRED_FLAG
      , ACCEPTANCE_DUE_DATE
      , ATTRIBUTE15
      , GLOBAL_ATTRIBUTE19
      , CLM_DOCUMENT_NUMBER
      , AUTO_SOURCING_FLAG
      , AGENT_ID
      , USER_HOLD_FLAG
      , GLOBAL_ATTRIBUTE10
      , END_DATE
      , VENDOR_CONTACT_ID
      , XML_CHANGE_SEND_DATE
      , SUPPLIER_AUTH_ENABLED_FLAG
      , WF_ITEM_KEY
      , CHANGE_REQUESTED_BY
      , LOCK_OWNER_ROLE
      , SHIP_TO_LOCATION_ID
      , CREATED_BY
      , CONTERMS_DELIV_UPD_DATE
      , LAST_UPDATED_BY
      , OTM_STATUS_CODE
      , PRICE_UPDATE_TOLERANCE
      , TYPE_LOOKUP_CODE
      , REVISION_NUM
      , TERMS_ID
      , QUOTATION_CLASS_CODE
      , CAT_ADMIN_AUTH_ENABLED_FLAG
      , ATTRIBUTE_CATEGORY
      , PROGRAM_APPLICATION_ID
      , GOVERNMENT_CONTEXT
      , XML_SEND_DATE
      , PENDING_SIGNATURE_FLAG
      , ENABLE_ALL_SITES
      , COMM_REV_NUM
      , MRC_RATE_DATE
      , QUOTE_VENDOR_QUOTE_NUMBER
      , CONSUME_REQ_DEMAND_FLAG
      , REQUEST_ID
      , FROM_TYPE_LOOKUP_CODE
      , FIRM_STATUS_LOOKUP_CODE
      , CURRENCY_CODE
      , NOTE_TO_RECEIVER
      , RETRO_PRICE_COMM_UPDATES_FLAG
      , VENDOR_SITE_ID
      , DOCUMENT_CREATION_METHOD
      , STATUS_LOOKUP_CODE
      , CBC_ACCOUNTING_DATE
      , CHANGE_SUMMARY
      , CLOSED_CODE
      , CONTERMS_ARTICLES_UPD_DATE
      , SUMMARY_FLAG
      , BLANKET_TOTAL_AMOUNT
      , CONFIRMING_ORDER_FLAG
      , TAX_ATTRIBUTE_UPDATE_CODE
      , SEGMENT2
      , REPLY_DATE
      , EDI_PROCESSED_FLAG
      , SEGMENT1
      , LAST_UPDATE_LOGIN
      , ENABLED_FLAG
      , GLOBAL_ATTRIBUTE_CATEGORY
      , SHIP_VIA_LOOKUP_CODE
      , SHIPPING_CONTROL
      , FOB_LOOKUP_CODE
      , FAX
      , RATE_TYPE
      , _FIVETRAN_DELETED
      , _FIVETRAN_ID
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_DELETE_IND
      , PROGRAM_UPDATE_DATE
      , PRINTED_DATE
      , CLOSED_DATE
      , RATE
      , CREATION_DATE
      , APPROVED_DATE
      , SUBMIT_DATE
      , REVISED_DATE
      , LAST_UPDATE_DATE
      /*Updated the LOAD_DTS logic from _FIVETRAN_SYNCED to PSA_LOAD_DTS to resolve the duplicate issue caused by fivetran connector issue.
      We have historically(before Nov 2024) updated the PSA_LOAD_DTS field, so the duplicate issu does not come again  */
      , CONVERT_TIMEZONE('UTC', PSA_LOAD_DTS)                    as                                           LOAD_DTS
    FROM SRC_PO_HDR
)

, LOGIC_A as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_A
)

, LOGIC_AP as (
    SELECT
        DESCRIPTION
      , TERM_ID
    FROM SRC_AP
)

, LOGIC_sup as (
    SELECT
        VENDOR_ID                                                    as                                      SUP_VENDOR_ID
      , SEGMENT1                                                     as                                       SUP_SEGMENT1
    FROM SRC_sup
)
---- RENAME LAYER ----

, RENAME_PO_HDR as (
    SELECT
        PO_HEADER_BK
      , PO_HEADER_ID
      , ORG_ID
      , FREIGHT_TERMS_LOOKUP_CODE
      , XML_FLAG
      , APPROVED_FLAG
      , LOCK_OWNER_USER_ID
      , PROGRAM_ID
      , GLOBAL_ATTRIBUTE5
      , GLOBAL_ATTRIBUTE4
      , CONSIGNED_CONSUMPTION_FLAG
      , RATE_DATE
      , GLOBAL_ATTRIBUTE7
      , WF_ITEM_TYPE
      , AUTHORIZATION_STATUS
      , GLOBAL_ATTRIBUTE6
      , GLOBAL_ATTRIBUTE1
      , EMAIL_ADDRESS
      , SEGMENT4
      , ACCEPTANCE_REQUIRED_FLAG
      , SEGMENT3
      , GLOBAL_ATTRIBUTE3
      , GLOBAL_ATTRIBUTE2
      , SEGMENT5
      , QUOTE_WARNING_DELAY_UNIT
      , GLOBAL_ATTRIBUTE9
      , GLOBAL_ATTRIBUTE8
      , GLOBAL_AGREEMENT_FLAG
      , END_DATE_ACTIVE
      , INTERFACE_SOURCE_CODE
      , ATTRIBUTE3
      , CREATED_LANGUAGE
      , ATTRIBUTE2
      , RFQ_CLOSE_DATE
      , ATTRIBUTE1
      , REPLY_METHOD_LOOKUP_CODE
      , CONTERMS_EXIST_FLAG
      , SUPPLY_AGREEMENT_FLAG
      , PRINT_COUNT
      , AMOUNT_LIMIT
      , AME_TRANSACTION_TYPE
      , ATTRIBUTE9
      , ATTRIBUTE8
      , SUPPLIER_NOTIF_METHOD
      , ATTRIBUTE7
      , USSGL_TRANSACTION_CODE
      , ATTRIBUTE6
      , ATTRIBUTE5
      , ATTRIBUTE4
      , VENDOR_ID
      , VENDOR_ORDER_NUM
      , NOTE_TO_AUTHORIZER
      , CPA_REFERENCE
      , RETRO_PRICE_APPLY_UPDATES_FLAG
      , STYLE_ID
      , APPROVAL_REQUIRED_FLAG
      , NOTE_TO_VENDOR
      , EDI_PROCESSED_STATUS
      , ATTRIBUTE10
      , AME_APPROVAL_ID
      , ATTRIBUTE14
      , OTM_RECOVERY_FLAG
      , ATTRIBUTE13
      , ATTRIBUTE12
      , ATTRIBUTE11
      , UPDATE_SOURCING_RULES_FLAG
      , BILL_TO_LOCATION_ID
      , COMMENTS
      , PAY_WHEN_PAID
      , MRC_RATE_TYPE
      , START_DATE_ACTIVE
      , FROM_HEADER_ID
      , QUOTE_TYPE_LOOKUP_CODE
      , FIRM_DATE
      , GLOBAL_ATTRIBUTE20
      , START_DATE
      , REFERENCE_NUM
      , MIN_RELEASE_AMOUNT
      , MRC_RATE
      , PAY_ON_CODE
      , LAST_UPDATED_PROGRAM
      , GLOBAL_ATTRIBUTE17
      , GLOBAL_ATTRIBUTE18
      , FROZEN_FLAG
      , GLOBAL_ATTRIBUTE15
      , CANCEL_FLAG
      , GLOBAL_ATTRIBUTE16
      , GLOBAL_ATTRIBUTE13
      , PCARD_ID
      , GLOBAL_ATTRIBUTE14
      , GLOBAL_ATTRIBUTE11
      , QUOTE_WARNING_DELAY
      , GLOBAL_ATTRIBUTE12
      , ENCUMBRANCE_REQUIRED_FLAG
      , ACCEPTANCE_DUE_DATE
      , ATTRIBUTE15
      , GLOBAL_ATTRIBUTE19
      , CLM_DOCUMENT_NUMBER
      , AUTO_SOURCING_FLAG
      , AGENT_ID
      , USER_HOLD_FLAG
      , GLOBAL_ATTRIBUTE10
      , END_DATE
      , VENDOR_CONTACT_ID
      , XML_CHANGE_SEND_DATE
      , SUPPLIER_AUTH_ENABLED_FLAG
      , WF_ITEM_KEY
      , CHANGE_REQUESTED_BY
      , LOCK_OWNER_ROLE
      , SHIP_TO_LOCATION_ID
      , CREATED_BY
      , CONTERMS_DELIV_UPD_DATE
      , LAST_UPDATED_BY
      , OTM_STATUS_CODE
      , PRICE_UPDATE_TOLERANCE
      , TYPE_LOOKUP_CODE
      , REVISION_NUM
      , TERMS_ID
      , QUOTATION_CLASS_CODE
      , CAT_ADMIN_AUTH_ENABLED_FLAG
      , ATTRIBUTE_CATEGORY
      , PROGRAM_APPLICATION_ID
      , GOVERNMENT_CONTEXT
      , XML_SEND_DATE
      , PENDING_SIGNATURE_FLAG
      , ENABLE_ALL_SITES
      , COMM_REV_NUM
      , MRC_RATE_DATE
      , QUOTE_VENDOR_QUOTE_NUMBER
      , CONSUME_REQ_DEMAND_FLAG
      , REQUEST_ID
      , FROM_TYPE_LOOKUP_CODE
      , FIRM_STATUS_LOOKUP_CODE
      , CURRENCY_CODE
      , NOTE_TO_RECEIVER
      , RETRO_PRICE_COMM_UPDATES_FLAG
      , VENDOR_SITE_ID
      , DOCUMENT_CREATION_METHOD
      , STATUS_LOOKUP_CODE
      , CBC_ACCOUNTING_DATE
      , CHANGE_SUMMARY
      , CLOSED_CODE
      , CONTERMS_ARTICLES_UPD_DATE
      , SUMMARY_FLAG
      , BLANKET_TOTAL_AMOUNT
      , CONFIRMING_ORDER_FLAG
      , TAX_ATTRIBUTE_UPDATE_CODE
      , SEGMENT2
      , REPLY_DATE
      , EDI_PROCESSED_FLAG
      , SEGMENT1
      , LAST_UPDATE_LOGIN
      , ENABLED_FLAG
      , GLOBAL_ATTRIBUTE_CATEGORY
      , SHIP_VIA_LOOKUP_CODE
      , SHIPPING_CONTROL
      , FOB_LOOKUP_CODE
      , FAX
      , RATE_TYPE
      , _FIVETRAN_DELETED
      , _FIVETRAN_ID
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_DELETE_IND
      , PROGRAM_UPDATE_DATE
      , PRINTED_DATE
      , CLOSED_DATE
      , RATE
      , CREATION_DATE
      , APPROVED_DATE
      , SUBMIT_DATE
      , REVISED_DATE
      , LAST_UPDATE_DATE
      , LOAD_DTS
    FROM LOGIC_PO_HDR
)

, RENAME_AP as (
    SELECT
        DESCRIPTION
      , TERM_ID
    FROM LOGIC_AP
)

, RENAME_A as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_A
)

, RENAME_sup as (
    SELECT
        SUP_VENDOR_ID
      , SUP_SEGMENT1
    FROM LOGIC_sup
)
---- FILTER LAYER ----

, FILTER_PO_HDR as (
    SELECT *
    FROM RENAME_PO_HDR
)

, FILTER_A as (
    SELECT *
    FROM RENAME_A
    WHERE rec_src = 'USWIOC.ORCL.EBSPRD.PO_HEADERS_ALL'
)

, FILTER_AP as (
    SELECT *
    FROM RENAME_AP
)

, FILTER_sup as (
    SELECT *
    FROM RENAME_sup
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_PO_HDR
    INNER JOIN FILTER_A
        ON '1' = '1'
    LEFT JOIN FILTER_AP
        ON FILTER_PO_HDR.TERMS_ID = FILTER_AP.TERM_ID
    LEFT JOIN FILTER_sup
        ON FILTER_PO_HDR.VENDOR_ID = SUP_VENDOR_ID
)

---- FINAL LAYER ----
SELECT
          PO_HEADER_BK
        , PO_HEADER_ID
        , ORG_ID
        , FREIGHT_TERMS_LOOKUP_CODE
        , XML_FLAG
        , APPROVED_FLAG
        , LOCK_OWNER_USER_ID
        , PROGRAM_ID
        , GLOBAL_ATTRIBUTE5
        , GLOBAL_ATTRIBUTE4
        , CONSIGNED_CONSUMPTION_FLAG
        , RATE_DATE
        , GLOBAL_ATTRIBUTE7
        , WF_ITEM_TYPE
        , AUTHORIZATION_STATUS
        , GLOBAL_ATTRIBUTE6
        , GLOBAL_ATTRIBUTE1
        , EMAIL_ADDRESS
        , SEGMENT4
        , ACCEPTANCE_REQUIRED_FLAG
        , SEGMENT3
        , GLOBAL_ATTRIBUTE3
        , GLOBAL_ATTRIBUTE2
        , SEGMENT5
        , QUOTE_WARNING_DELAY_UNIT
        , GLOBAL_ATTRIBUTE9
        , GLOBAL_ATTRIBUTE8
        , GLOBAL_AGREEMENT_FLAG
        , END_DATE_ACTIVE
        , INTERFACE_SOURCE_CODE
        , ATTRIBUTE3
        , CREATED_LANGUAGE
        , ATTRIBUTE2
        , RFQ_CLOSE_DATE
        , ATTRIBUTE1
        , REPLY_METHOD_LOOKUP_CODE
        , CONTERMS_EXIST_FLAG
        , SUPPLY_AGREEMENT_FLAG
        , PRINT_COUNT
        , AMOUNT_LIMIT
        , AME_TRANSACTION_TYPE
        , ATTRIBUTE9
        , ATTRIBUTE8
        , SUPPLIER_NOTIF_METHOD
        , ATTRIBUTE7
        , USSGL_TRANSACTION_CODE
        , ATTRIBUTE6
        , ATTRIBUTE5
        , ATTRIBUTE4
        , VENDOR_ID
        , VENDOR_ORDER_NUM
        , NOTE_TO_AUTHORIZER
        , CPA_REFERENCE
        , RETRO_PRICE_APPLY_UPDATES_FLAG
        , STYLE_ID
        , APPROVAL_REQUIRED_FLAG
        , NOTE_TO_VENDOR
        , EDI_PROCESSED_STATUS
        , ATTRIBUTE10
        , AME_APPROVAL_ID
        , ATTRIBUTE14
        , OTM_RECOVERY_FLAG
        , ATTRIBUTE13
        , ATTRIBUTE12
        , ATTRIBUTE11
        , UPDATE_SOURCING_RULES_FLAG
        , BILL_TO_LOCATION_ID
        , COMMENTS
        , PAY_WHEN_PAID
        , MRC_RATE_TYPE
        , START_DATE_ACTIVE
        , FROM_HEADER_ID
        , QUOTE_TYPE_LOOKUP_CODE
        , FIRM_DATE
        , GLOBAL_ATTRIBUTE20
        , START_DATE
        , REFERENCE_NUM
        , MIN_RELEASE_AMOUNT
        , MRC_RATE
        , PAY_ON_CODE
        , LAST_UPDATED_PROGRAM
        , GLOBAL_ATTRIBUTE17
        , GLOBAL_ATTRIBUTE18
        , FROZEN_FLAG
        , GLOBAL_ATTRIBUTE15
        , CANCEL_FLAG
        , GLOBAL_ATTRIBUTE16
        , GLOBAL_ATTRIBUTE13
        , PCARD_ID
        , GLOBAL_ATTRIBUTE14
        , GLOBAL_ATTRIBUTE11
        , QUOTE_WARNING_DELAY
        , GLOBAL_ATTRIBUTE12
        , ENCUMBRANCE_REQUIRED_FLAG
        , ACCEPTANCE_DUE_DATE
        , ATTRIBUTE15
        , GLOBAL_ATTRIBUTE19
        , CLM_DOCUMENT_NUMBER
        , AUTO_SOURCING_FLAG
        , AGENT_ID
        , USER_HOLD_FLAG
        , GLOBAL_ATTRIBUTE10
        , END_DATE
        , VENDOR_CONTACT_ID
        , XML_CHANGE_SEND_DATE
        , SUPPLIER_AUTH_ENABLED_FLAG
        , WF_ITEM_KEY
        , CHANGE_REQUESTED_BY
        , LOCK_OWNER_ROLE
        , SHIP_TO_LOCATION_ID
        , CREATED_BY
        , CONTERMS_DELIV_UPD_DATE
        , LAST_UPDATED_BY
        , OTM_STATUS_CODE
        , PRICE_UPDATE_TOLERANCE
        , TYPE_LOOKUP_CODE
        , REVISION_NUM
        , TERMS_ID
        , QUOTATION_CLASS_CODE
        , CAT_ADMIN_AUTH_ENABLED_FLAG
        , ATTRIBUTE_CATEGORY
        , PROGRAM_APPLICATION_ID
        , GOVERNMENT_CONTEXT
        , XML_SEND_DATE
        , PENDING_SIGNATURE_FLAG
        , ENABLE_ALL_SITES
        , COMM_REV_NUM
        , MRC_RATE_DATE
        , QUOTE_VENDOR_QUOTE_NUMBER
        , CONSUME_REQ_DEMAND_FLAG
        , REQUEST_ID
        , FROM_TYPE_LOOKUP_CODE
        , FIRM_STATUS_LOOKUP_CODE
        , CURRENCY_CODE
        , NOTE_TO_RECEIVER
        , RETRO_PRICE_COMM_UPDATES_FLAG
        , VENDOR_SITE_ID
        , DOCUMENT_CREATION_METHOD
        , STATUS_LOOKUP_CODE
        , CBC_ACCOUNTING_DATE
        , CHANGE_SUMMARY
        , CLOSED_CODE
        , CONTERMS_ARTICLES_UPD_DATE
        , SUMMARY_FLAG
        , BLANKET_TOTAL_AMOUNT
        , CONFIRMING_ORDER_FLAG
        , TAX_ATTRIBUTE_UPDATE_CODE
        , SEGMENT2
        , REPLY_DATE
        , EDI_PROCESSED_FLAG
        , SEGMENT1
        , LAST_UPDATE_LOGIN
        , ENABLED_FLAG
        , GLOBAL_ATTRIBUTE_CATEGORY
        , SHIP_VIA_LOOKUP_CODE
        , SHIPPING_CONTROL
        , FOB_LOOKUP_CODE
        , FAX
        , RATE_TYPE
        , _FIVETRAN_DELETED
        , _FIVETRAN_ID
        , _FIVETRAN_SYNCED
        , PSA_LOAD_DTS
        , PSA_DELETE_IND
        , PROGRAM_UPDATE_DATE
        , PRINTED_DATE
        , CLOSED_DATE
        , RATE
        , CREATION_DATE
        , APPROVED_DATE
        , SUBMIT_DATE
        , REVISED_DATE
        , LAST_UPDATE_DATE
        , DESCRIPTION
        , /*To handle the optional null default for the Hash key generation and to match with the Ghost Key Hash value */
        IFF(SUP_SEGMENT1 IS NULL, '-2', CONCAT_WS('||', SUP_SEGMENT1, BKCC)) as DRVD_SUPPLIER_BKCC
        , /*To handle the optional null default for the Hash key generation and to match with the Ghost Key Hash value */
        IFF((SUP_SEGMENT1 IS NULL OR VENDOR_SITE_ID IS NULL) , '-2', CONCAT_WS('||',SUP_SEGMENT1,VENDOR_SITE_ID,BKCC)) as DRVD_SUPPLIER_SITE_BKCC
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PO_HEADER_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PO_HEADER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(DRVD_SUPPLIER_BKCC as VARCHAR)),''), '^^')
        ))) as SUPPLIER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(DRVD_SUPPLIER_SITE_BKCC as VARCHAR)),''), '^^')
        ))) as SUPPLIER_SITE_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PO_HEADER_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(SUP_SEGMENT1 as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(VENDOR_SITE_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as LNK_PO_HEADER_SUPPLIER_SITE_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(ORG_ID::text), '^^') 
            , '||', IFNULL(TRIM(FREIGHT_TERMS_LOOKUP_CODE::text), '^^') 
            , '||', IFNULL(TRIM(XML_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(APPROVED_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(LOCK_OWNER_USER_ID::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_ID::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE5::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE4::text), '^^') 
            , '||', IFNULL(TRIM(CONSIGNED_CONSUMPTION_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(RATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE7::text), '^^') 
            , '||', IFNULL(TRIM(WF_ITEM_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(AUTHORIZATION_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE6::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE1::text), '^^') 
            , '||', IFNULL(TRIM(EMAIL_ADDRESS::text), '^^') 
            , '||', IFNULL(TRIM(SEGMENT4::text), '^^') 
            , '||', IFNULL(TRIM(ACCEPTANCE_REQUIRED_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(SEGMENT3::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE3::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE2::text), '^^') 
            , '||', IFNULL(TRIM(SEGMENT5::text), '^^') 
            , '||', IFNULL(TRIM(QUOTE_WARNING_DELAY_UNIT::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE9::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE8::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_AGREEMENT_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(END_DATE_ACTIVE::text), '^^') 
            , '||', IFNULL(TRIM(INTERFACE_SOURCE_CODE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE3::text), '^^') 
            , '||', IFNULL(TRIM(CREATED_LANGUAGE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE2::text), '^^') 
            , '||', IFNULL(TRIM(RFQ_CLOSE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE1::text), '^^') 
            , '||', IFNULL(TRIM(REPLY_METHOD_LOOKUP_CODE::text), '^^') 
            , '||', IFNULL(TRIM(CONTERMS_EXIST_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(SUPPLY_AGREEMENT_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(PRINT_COUNT::text), '^^') 
            , '||', IFNULL(TRIM(AMOUNT_LIMIT::text), '^^') 
            , '||', IFNULL(TRIM(AME_TRANSACTION_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE9::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE8::text), '^^') 
            , '||', IFNULL(TRIM(SUPPLIER_NOTIF_METHOD::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE7::text), '^^') 
            , '||', IFNULL(TRIM(USSGL_TRANSACTION_CODE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE6::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE5::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE4::text), '^^') 
            , '||', IFNULL(TRIM(VENDOR_ID::text), '^^') 
            , '||', IFNULL(TRIM(VENDOR_ORDER_NUM::text), '^^') 
            , '||', IFNULL(TRIM(NOTE_TO_AUTHORIZER::text), '^^') 
            , '||', IFNULL(TRIM(CPA_REFERENCE::text), '^^') 
            , '||', IFNULL(TRIM(RETRO_PRICE_APPLY_UPDATES_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(STYLE_ID::text), '^^') 
            , '||', IFNULL(TRIM(APPROVAL_REQUIRED_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(NOTE_TO_VENDOR::text), '^^') 
            , '||', IFNULL(TRIM(EDI_PROCESSED_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE10::text), '^^') 
            , '||', IFNULL(TRIM(AME_APPROVAL_ID::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE14::text), '^^') 
            , '||', IFNULL(TRIM(OTM_RECOVERY_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE13::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE12::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE11::text), '^^') 
            , '||', IFNULL(TRIM(UPDATE_SOURCING_RULES_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(BILL_TO_LOCATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(COMMENTS::text), '^^') 
            , '||', IFNULL(TRIM(PAY_WHEN_PAID::text), '^^') 
            , '||', IFNULL(TRIM(MRC_RATE_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(START_DATE_ACTIVE::text), '^^') 
            , '||', IFNULL(TRIM(FROM_HEADER_ID::text), '^^') 
            , '||', IFNULL(TRIM(QUOTE_TYPE_LOOKUP_CODE::text), '^^') 
            , '||', IFNULL(TRIM(FIRM_DATE::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE20::text), '^^') 
            , '||', IFNULL(TRIM(START_DATE::text), '^^') 
            , '||', IFNULL(TRIM(REFERENCE_NUM::text), '^^') 
            , '||', IFNULL(TRIM(MIN_RELEASE_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(MRC_RATE::text), '^^') 
            , '||', IFNULL(TRIM(PAY_ON_CODE::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATED_PROGRAM::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE17::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE18::text), '^^') 
            , '||', IFNULL(TRIM(FROZEN_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE15::text), '^^') 
            , '||', IFNULL(TRIM(CANCEL_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE16::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE13::text), '^^') 
            , '||', IFNULL(TRIM(PCARD_ID::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE14::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE11::text), '^^') 
            , '||', IFNULL(TRIM(QUOTE_WARNING_DELAY::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE12::text), '^^') 
            , '||', IFNULL(TRIM(ENCUMBRANCE_REQUIRED_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(ACCEPTANCE_DUE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE15::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE19::text), '^^') 
            , '||', IFNULL(TRIM(CLM_DOCUMENT_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(AUTO_SOURCING_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(AGENT_ID::text), '^^') 
            , '||', IFNULL(TRIM(USER_HOLD_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE10::text), '^^') 
            , '||', IFNULL(TRIM(END_DATE::text), '^^') 
            , '||', IFNULL(TRIM(VENDOR_CONTACT_ID::text), '^^') 
            , '||', IFNULL(TRIM(XML_CHANGE_SEND_DATE::text), '^^') 
            , '||', IFNULL(TRIM(SUPPLIER_AUTH_ENABLED_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(WF_ITEM_KEY::text), '^^') 
            , '||', IFNULL(TRIM(CHANGE_REQUESTED_BY::text), '^^') 
            , '||', IFNULL(TRIM(LOCK_OWNER_ROLE::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_TO_LOCATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(CREATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(CONTERMS_DELIV_UPD_DATE::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(OTM_STATUS_CODE::text), '^^') 
            , '||', IFNULL(TRIM(PRICE_UPDATE_TOLERANCE::text), '^^') 
            , '||', IFNULL(TRIM(TYPE_LOOKUP_CODE::text), '^^') 
            , '||', IFNULL(TRIM(REVISION_NUM::text), '^^') 
            , '||', IFNULL(TRIM(TERMS_ID::text), '^^') 
            , '||', IFNULL(TRIM(QUOTATION_CLASS_CODE::text), '^^') 
            , '||', IFNULL(TRIM(CAT_ADMIN_AUTH_ENABLED_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_APPLICATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(GOVERNMENT_CONTEXT::text), '^^') 
            , '||', IFNULL(TRIM(XML_SEND_DATE::text), '^^') 
            , '||', IFNULL(TRIM(PENDING_SIGNATURE_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(ENABLE_ALL_SITES::text), '^^') 
            , '||', IFNULL(TRIM(COMM_REV_NUM::text), '^^') 
            , '||', IFNULL(TRIM(MRC_RATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(QUOTE_VENDOR_QUOTE_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(CONSUME_REQ_DEMAND_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(REQUEST_ID::text), '^^') 
            , '||', IFNULL(TRIM(FROM_TYPE_LOOKUP_CODE::text), '^^') 
            , '||', IFNULL(TRIM(FIRM_STATUS_LOOKUP_CODE::text), '^^') 
            , '||', IFNULL(TRIM(CURRENCY_CODE::text), '^^') 
            , '||', IFNULL(TRIM(NOTE_TO_RECEIVER::text), '^^') 
            , '||', IFNULL(TRIM(RETRO_PRICE_COMM_UPDATES_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(VENDOR_SITE_ID::text), '^^') 
            , '||', IFNULL(TRIM(DOCUMENT_CREATION_METHOD::text), '^^') 
            , '||', IFNULL(TRIM(STATUS_LOOKUP_CODE::text), '^^') 
            , '||', IFNULL(TRIM(CBC_ACCOUNTING_DATE::text), '^^') 
            , '||', IFNULL(TRIM(CHANGE_SUMMARY::text), '^^') 
            , '||', IFNULL(TRIM(CLOSED_CODE::text), '^^') 
            , '||', IFNULL(TRIM(CONTERMS_ARTICLES_UPD_DATE::text), '^^') 
            , '||', IFNULL(TRIM(SUMMARY_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(BLANKET_TOTAL_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(CONFIRMING_ORDER_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(TAX_ATTRIBUTE_UPDATE_CODE::text), '^^') 
            , '||', IFNULL(TRIM(SEGMENT2::text), '^^') 
            , '||', IFNULL(TRIM(REPLY_DATE::text), '^^') 
            , '||', IFNULL(TRIM(EDI_PROCESSED_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(SEGMENT1::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_LOGIN::text), '^^') 
            , '||', IFNULL(TRIM(ENABLED_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_VIA_LOOKUP_CODE::text), '^^') 
            , '||', IFNULL(TRIM(SHIPPING_CONTROL::text), '^^') 
            , '||', IFNULL(TRIM(FOB_LOOKUP_CODE::text), '^^') 
            , '||', IFNULL(TRIM(FAX::text), '^^') 
            , '||', IFNULL(TRIM(RATE_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_UPDATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(PRINTED_DATE::text), '^^') 
            , '||', IFNULL(TRIM(CLOSED_DATE::text), '^^') 
            , '||', IFNULL(TRIM(RATE::text), '^^') 
            , '||', IFNULL(TRIM(CREATION_DATE::text), '^^') 
            , '||', IFNULL(TRIM(APPROVED_DATE::text), '^^') 
            , '||', IFNULL(TRIM(SUBMIT_DATE::text), '^^') 
            , '||', IFNULL(TRIM(REVISED_DATE::text), '^^') 
            , '||', IFNULL(TRIM(DESCRIPTION::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
