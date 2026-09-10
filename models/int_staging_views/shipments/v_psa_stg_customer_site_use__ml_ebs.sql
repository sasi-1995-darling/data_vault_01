---- SRC LAYER ----
WITH
SRC_psa_ca         as ( SELECT * FROM {{ source('ml_ebs_ar', 'hz_cust_accounts') }} as SRC 
                        qualify 1 = row_number() over (partition by cust_account_id order by _fivetran_synced desc) ),
SRC_psa_casa       as ( SELECT * FROM {{ source('ml_ebs_ar', 'hz_cust_acct_sites_all') }} as SRC 
                        qualify 1 = row_number() over (partition by cust_acct_site_id order by _fivetran_synced desc) ),
SRC_psa_csua       as ( SELECT * FROM {{ source('ml_ebs_ar', 'hz_cust_site_uses_all') }} as SRC ),
SRC_bkcc           as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_psa_ca         as ( SELECT * FROM ml_ebs_ar.hz_cust_accounts )
, SRC_psa_casa       as ( SELECT * FROM ml_ebs_ar.hz_cust_acct_sites_all )
, SRC_psa_csua       as ( SELECT * FROM ml_ebs_ar.hz_cust_site_uses_all )
, SRC_bkcc           as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_psa_ca as (
    SELECT
        ACCOUNT_NUMBER                                               as                                        CUSTOMER_BK
      , CUST_ACCOUNT_ID
      , ACCOUNT_NUMBER
    FROM SRC_psa_ca
)

, LOGIC_psa_casa as (
    SELECT
        CUST_ACCOUNT_ID                                              as                                STG_CUST_ACCOUNT_ID
      , CUST_ACCT_SITE_ID                                            as                              STG_CUST_ACCT_SITE_ID
    FROM SRC_psa_casa
)

, LOGIC_psa_csua as (
    SELECT
        CUST_ACCT_SITE_ID                                            as                                   CUSTOMER_SITE_BK
      , SITE_USE_CODE
      , STATUS
      , LOCATION
      , CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED )                   as                                   LOAD_DTS
      , CUST_ACCT_SITE_ID
      , SITE_USE_ID
      , ORG_ID
      , SHIP_PARTIAL
      , PROGRAM_ID
      , GLOBAL_ATTRIBUTE5
      , GLOBAL_ATTRIBUTE4
      , UNDER_RETURN_TOLERANCE
      , GLOBAL_ATTRIBUTE7
      , GLOBAL_ATTRIBUTE6
      , GLOBAL_ATTRIBUTE1
      , GLOBAL_ATTRIBUTE3
      , GLOBAL_ATTRIBUTE2
      , FREIGHT_TERM
      , FINCHRG_RECEIVABLES_TRX_ID
      , GLOBAL_ATTRIBUTE9
      , GLOBAL_ATTRIBUTE8
      , TERRITORY_ID
      , SORT_PRIORITY
      , CREATED_BY_MODULE
      , ATTRIBUTE3
      , ORIG_SYSTEM_REFERENCE
      , ATTRIBUTE2
      , ATTRIBUTE1
      , GL_ID_REC
      , ATTRIBUTE9
      , ATTRIBUTE8
      , GL_ID_UNBILLED
      , ATTRIBUTE7
      , ATTRIBUTE6
      , ATTRIBUTE5
      , ATTRIBUTE4
      , OVER_SHIPMENT_TOLERANCE
      , GL_ID_REV
      , LAST_UNACCRUE_CHARGE_DATE
      , GL_ID_UNPAID_REC
      , ATTRIBUTE10
      , ATTRIBUTE14
      , ATTRIBUTE13
      , TAX_CLASSIFICATION
      , ATTRIBUTE12
      , ATTRIBUTE11
      , GL_ID_UNEARNED
      , GL_ID_FACTOR
      , DATES_POSITIVE_TOLERANCE
      , OVER_RETURN_TOLERANCE
      , ATTRIBUTE21
      , ORDER_TYPE_ID
      , ATTRIBUTE20
      , TAX_HEADER_LEVEL_FLAG
      , ATTRIBUTE25
      , BILL_TO_SITE_USE_ID
      , ATTRIBUTE24
      , ATTRIBUTE23
      , ATTRIBUTE22
      , GLOBAL_ATTRIBUTE20
      , SIC_CODE
      , GLOBAL_ATTRIBUTE17
      , GLOBAL_ATTRIBUTE18
      , GLOBAL_ATTRIBUTE15
      , GLOBAL_ATTRIBUTE16
      , GLOBAL_ATTRIBUTE13
      , GLOBAL_ATTRIBUTE14
      , GLOBAL_ATTRIBUTE11
      , GLOBAL_ATTRIBUTE12
      , ATTRIBUTE18
      , ATTRIBUTE17
      , ATTRIBUTE16
      , ATTRIBUTE15
      , FOB_POINT
      , GLOBAL_ATTRIBUTE19
      , ATTRIBUTE19
      , GLOBAL_ATTRIBUTE10
      , GL_ID_CLEARING
      , SHIP_VIA
      , ARRIVALSETS_INCLUDE_LINES_FLAG
      , OBJECT_VERSION_NUMBER
      , TAX_REFERENCE
      , SHIP_SETS_INCLUDE_LINES_FLAG
      , CREATED_BY
      , LAST_UPDATED_BY
      , LAST_ACCRUE_CHARGE_DATE
      , PAYMENT_TERM_ID
      , UNDER_SHIPMENT_TOLERANCE
      , SCHED_DATE_PUSH_FLAG
      , GL_ID_REMITTANCE
      , PRICE_LIST_ID
      , SECOND_LAST_UNACCRUE_CHRG_DATE
      , WAREHOUSE_ID
      , ATTRIBUTE_CATEGORY
      , PROGRAM_APPLICATION_ID
      , SECOND_LAST_ACCRUE_CHARGE_DATE
      , TAX_ROUNDING_RULE
      , GL_ID_TAX
      , APPLICATION_ID
      , REQUEST_ID
      , DATE_TYPE_PREFERENCE
      , PRIMARY_FLAG
      , ITEM_CROSS_REF_PREF
      , INVOICE_QUANTITY_RULE
      , GL_ID_FREIGHT
      , DATES_NEGATIVE_TOLERANCE
      , LAST_UPDATE_LOGIN
      , GSA_INDICATOR
      , GLOBAL_ATTRIBUTE_CATEGORY
      , WH_UPDATE_DATE
      , PRICING_EVENT
      , DEMAND_CLASS_CODE
      , PRIMARY_SALESREP_ID
      , CONTACT_ID
      , TAX_CODE
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , PROGRAM_UPDATE_DATE
      , CREATION_DATE
      , LAST_UPDATE_DATE
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
    FROM SRC_psa_csua
)

, LOGIC_bkcc as (
    SELECT
        BKCC
      , REC_SRC
    FROM SRC_bkcc
)
---- RENAME LAYER ----

, RENAME_psa_ca as (
    SELECT
        CUSTOMER_BK
      , CUST_ACCOUNT_ID
      , ACCOUNT_NUMBER
    FROM LOGIC_psa_ca
)

, RENAME_psa_csua as (
    SELECT
        CUSTOMER_SITE_BK
      , SITE_USE_CODE
      , STATUS
      , LOCATION
      , LOAD_DTS
      , CUST_ACCT_SITE_ID
      , SITE_USE_ID
      , ORG_ID
      , SHIP_PARTIAL
      , PROGRAM_ID
      , GLOBAL_ATTRIBUTE5
      , GLOBAL_ATTRIBUTE4
      , UNDER_RETURN_TOLERANCE
      , GLOBAL_ATTRIBUTE7
      , GLOBAL_ATTRIBUTE6
      , GLOBAL_ATTRIBUTE1
      , GLOBAL_ATTRIBUTE3
      , GLOBAL_ATTRIBUTE2
      , FREIGHT_TERM
      , FINCHRG_RECEIVABLES_TRX_ID
      , GLOBAL_ATTRIBUTE9
      , GLOBAL_ATTRIBUTE8
      , TERRITORY_ID
      , SORT_PRIORITY
      , CREATED_BY_MODULE
      , ATTRIBUTE3
      , ORIG_SYSTEM_REFERENCE
      , ATTRIBUTE2
      , ATTRIBUTE1
      , GL_ID_REC
      , ATTRIBUTE9
      , ATTRIBUTE8
      , GL_ID_UNBILLED
      , ATTRIBUTE7
      , ATTRIBUTE6
      , ATTRIBUTE5
      , ATTRIBUTE4
      , OVER_SHIPMENT_TOLERANCE
      , GL_ID_REV
      , LAST_UNACCRUE_CHARGE_DATE
      , GL_ID_UNPAID_REC
      , ATTRIBUTE10
      , ATTRIBUTE14
      , ATTRIBUTE13
      , TAX_CLASSIFICATION
      , ATTRIBUTE12
      , ATTRIBUTE11
      , GL_ID_UNEARNED
      , GL_ID_FACTOR
      , DATES_POSITIVE_TOLERANCE
      , OVER_RETURN_TOLERANCE
      , ATTRIBUTE21
      , ORDER_TYPE_ID
      , ATTRIBUTE20
      , TAX_HEADER_LEVEL_FLAG
      , ATTRIBUTE25
      , BILL_TO_SITE_USE_ID
      , ATTRIBUTE24
      , ATTRIBUTE23
      , ATTRIBUTE22
      , GLOBAL_ATTRIBUTE20
      , SIC_CODE
      , GLOBAL_ATTRIBUTE17
      , GLOBAL_ATTRIBUTE18
      , GLOBAL_ATTRIBUTE15
      , GLOBAL_ATTRIBUTE16
      , GLOBAL_ATTRIBUTE13
      , GLOBAL_ATTRIBUTE14
      , GLOBAL_ATTRIBUTE11
      , GLOBAL_ATTRIBUTE12
      , ATTRIBUTE18
      , ATTRIBUTE17
      , ATTRIBUTE16
      , ATTRIBUTE15
      , FOB_POINT
      , GLOBAL_ATTRIBUTE19
      , ATTRIBUTE19
      , GLOBAL_ATTRIBUTE10
      , GL_ID_CLEARING
      , SHIP_VIA
      , ARRIVALSETS_INCLUDE_LINES_FLAG
      , OBJECT_VERSION_NUMBER
      , TAX_REFERENCE
      , SHIP_SETS_INCLUDE_LINES_FLAG
      , CREATED_BY
      , LAST_UPDATED_BY
      , LAST_ACCRUE_CHARGE_DATE
      , PAYMENT_TERM_ID
      , UNDER_SHIPMENT_TOLERANCE
      , SCHED_DATE_PUSH_FLAG
      , GL_ID_REMITTANCE
      , PRICE_LIST_ID
      , SECOND_LAST_UNACCRUE_CHRG_DATE
      , WAREHOUSE_ID
      , ATTRIBUTE_CATEGORY
      , PROGRAM_APPLICATION_ID
      , SECOND_LAST_ACCRUE_CHARGE_DATE
      , TAX_ROUNDING_RULE
      , GL_ID_TAX
      , APPLICATION_ID
      , REQUEST_ID
      , DATE_TYPE_PREFERENCE
      , PRIMARY_FLAG
      , ITEM_CROSS_REF_PREF
      , INVOICE_QUANTITY_RULE
      , GL_ID_FREIGHT
      , DATES_NEGATIVE_TOLERANCE
      , LAST_UPDATE_LOGIN
      , GSA_INDICATOR
      , GLOBAL_ATTRIBUTE_CATEGORY
      , WH_UPDATE_DATE
      , PRICING_EVENT
      , DEMAND_CLASS_CODE
      , PRIMARY_SALESREP_ID
      , CONTACT_ID
      , TAX_CODE
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , PROGRAM_UPDATE_DATE
      , CREATION_DATE
      , LAST_UPDATE_DATE
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
    FROM LOGIC_psa_csua
)

, RENAME_psa_casa as (
    SELECT
        STG_CUST_ACCOUNT_ID
      , STG_CUST_ACCT_SITE_ID
    FROM LOGIC_psa_casa
)

, RENAME_bkcc as (
    SELECT
        BKCC
      , REC_SRC
    FROM LOGIC_bkcc
)
---- FILTER LAYER ----

, FILTER_psa_ca as (
    SELECT *
    FROM RENAME_psa_ca
)

, FILTER_psa_casa as (
    SELECT *
    FROM RENAME_psa_casa
)

, FILTER_psa_csua as (
    SELECT *
    FROM RENAME_psa_csua
)

, FILTER_bkcc as (
    SELECT *
    FROM RENAME_bkcc
    WHERE rec_src = 'USWIOC.ORCL.EBSPRD.HZ_CUST_SITE_USES_ALL'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_psa_ca
    INNER JOIN FILTER_psa_casa
        ON FILTER_psa_ca.CUST_ACCOUNT_ID = FILTER_psa_casa.STG_CUST_ACCOUNT_ID
    INNER JOIN FILTER_psa_csua
        ON FILTER_psa_casa.STG_cust_acct_site_id = FILTER_psa_csua.cust_acct_site_id
    INNER JOIN FILTER_bkcc
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          CUSTOMER_BK
        , CUSTOMER_SITE_BK
        , ACCOUNT_NUMBER
        , SITE_USE_CODE
        , STATUS
        , LOCATION
        , CUST_ACCT_SITE_ID
        , SITE_USE_ID
        , ORG_ID
        , SHIP_PARTIAL
        , PROGRAM_ID
        , GLOBAL_ATTRIBUTE5
        , GLOBAL_ATTRIBUTE4
        , UNDER_RETURN_TOLERANCE
        , GLOBAL_ATTRIBUTE7
        , GLOBAL_ATTRIBUTE6
        , GLOBAL_ATTRIBUTE1
        , GLOBAL_ATTRIBUTE3
        , GLOBAL_ATTRIBUTE2
        , FREIGHT_TERM
        , FINCHRG_RECEIVABLES_TRX_ID
        , GLOBAL_ATTRIBUTE9
        , GLOBAL_ATTRIBUTE8
        , TERRITORY_ID
        , SORT_PRIORITY
        , CREATED_BY_MODULE
        , ATTRIBUTE3
        , ORIG_SYSTEM_REFERENCE
        , ATTRIBUTE2
        , ATTRIBUTE1
        , GL_ID_REC
        , ATTRIBUTE9
        , ATTRIBUTE8
        , GL_ID_UNBILLED
        , ATTRIBUTE7
        , ATTRIBUTE6
        , ATTRIBUTE5
        , ATTRIBUTE4
        , OVER_SHIPMENT_TOLERANCE
        , GL_ID_REV
        , LAST_UNACCRUE_CHARGE_DATE
        , GL_ID_UNPAID_REC
        , ATTRIBUTE10
        , ATTRIBUTE14
        , ATTRIBUTE13
        , TAX_CLASSIFICATION
        , ATTRIBUTE12
        , ATTRIBUTE11
        , GL_ID_UNEARNED
        , GL_ID_FACTOR
        , DATES_POSITIVE_TOLERANCE
        , OVER_RETURN_TOLERANCE
        , ATTRIBUTE21
        , ORDER_TYPE_ID
        , ATTRIBUTE20
        , TAX_HEADER_LEVEL_FLAG
        , ATTRIBUTE25
        , BILL_TO_SITE_USE_ID
        , ATTRIBUTE24
        , ATTRIBUTE23
        , ATTRIBUTE22
        , GLOBAL_ATTRIBUTE20
        , SIC_CODE
        , GLOBAL_ATTRIBUTE17
        , GLOBAL_ATTRIBUTE18
        , GLOBAL_ATTRIBUTE15
        , GLOBAL_ATTRIBUTE16
        , GLOBAL_ATTRIBUTE13
        , GLOBAL_ATTRIBUTE14
        , GLOBAL_ATTRIBUTE11
        , GLOBAL_ATTRIBUTE12
        , ATTRIBUTE18
        , ATTRIBUTE17
        , ATTRIBUTE16
        , ATTRIBUTE15
        , FOB_POINT
        , GLOBAL_ATTRIBUTE19
        , ATTRIBUTE19
        , GLOBAL_ATTRIBUTE10
        , GL_ID_CLEARING
        , SHIP_VIA
        , ARRIVALSETS_INCLUDE_LINES_FLAG
        , OBJECT_VERSION_NUMBER
        , TAX_REFERENCE
        , SHIP_SETS_INCLUDE_LINES_FLAG
        , CREATED_BY
        , LAST_UPDATED_BY
        , LAST_ACCRUE_CHARGE_DATE
        , PAYMENT_TERM_ID
        , UNDER_SHIPMENT_TOLERANCE
        , SCHED_DATE_PUSH_FLAG
        , GL_ID_REMITTANCE
        , PRICE_LIST_ID
        , SECOND_LAST_UNACCRUE_CHRG_DATE
        , WAREHOUSE_ID
        , ATTRIBUTE_CATEGORY
        , PROGRAM_APPLICATION_ID
        , SECOND_LAST_ACCRUE_CHARGE_DATE
        , TAX_ROUNDING_RULE
        , GL_ID_TAX
        , APPLICATION_ID
        , REQUEST_ID
        , DATE_TYPE_PREFERENCE
        , PRIMARY_FLAG
        , ITEM_CROSS_REF_PREF
        , INVOICE_QUANTITY_RULE
        , GL_ID_FREIGHT
        , DATES_NEGATIVE_TOLERANCE
        , LAST_UPDATE_LOGIN
        , GSA_INDICATOR
        , GLOBAL_ATTRIBUTE_CATEGORY
        , WH_UPDATE_DATE
        , PRICING_EVENT
        , DEMAND_CLASS_CODE
        , PRIMARY_SALESREP_ID
        , CONTACT_ID
        , TAX_CODE
        , _FIVETRAN_DELETED
        , _FIVETRAN_SYNCED
        , PROGRAM_UPDATE_DATE
        , CREATION_DATE
        , LAST_UPDATE_DATE
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , BKCC
        , REC_SRC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(CUSTOMER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(CUST_ACCT_SITE_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as CUSTOMER_SITE_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(SITE_USE_CODE::text), '^^') 
            , '||', IFNULL(TRIM(STATUS::text), '^^') 
            , '||', IFNULL(TRIM(LOCATION::text), '^^')             
            , '||', IFNULL(TRIM(SITE_USE_ID::text), '^^') 
            , '||', IFNULL(TRIM(ORG_ID::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_PARTIAL::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_ID::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE5::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE4::text), '^^') 
            , '||', IFNULL(TRIM(UNDER_RETURN_TOLERANCE::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE7::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE6::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE1::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE3::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE2::text), '^^') 
            , '||', IFNULL(TRIM(FREIGHT_TERM::text), '^^') 
            , '||', IFNULL(TRIM(FINCHRG_RECEIVABLES_TRX_ID::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE9::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE8::text), '^^') 
            , '||', IFNULL(TRIM(TERRITORY_ID::text), '^^') 
            , '||', IFNULL(TRIM(SORT_PRIORITY::text), '^^') 
            , '||', IFNULL(TRIM(CREATED_BY_MODULE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE3::text), '^^') 
            , '||', IFNULL(TRIM(ORIG_SYSTEM_REFERENCE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE2::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE1::text), '^^') 
            , '||', IFNULL(TRIM(GL_ID_REC::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE9::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE8::text), '^^') 
            , '||', IFNULL(TRIM(GL_ID_UNBILLED::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE7::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE6::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE5::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE4::text), '^^') 
            , '||', IFNULL(TRIM(OVER_SHIPMENT_TOLERANCE::text), '^^') 
            , '||', IFNULL(TRIM(GL_ID_REV::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UNACCRUE_CHARGE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(GL_ID_UNPAID_REC::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE10::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE14::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE13::text), '^^') 
            , '||', IFNULL(TRIM(TAX_CLASSIFICATION::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE12::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE11::text), '^^') 
            , '||', IFNULL(TRIM(GL_ID_UNEARNED::text), '^^') 
            , '||', IFNULL(TRIM(GL_ID_FACTOR::text), '^^') 
            , '||', IFNULL(TRIM(DATES_POSITIVE_TOLERANCE::text), '^^') 
            , '||', IFNULL(TRIM(OVER_RETURN_TOLERANCE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE21::text), '^^') 
            , '||', IFNULL(TRIM(ORDER_TYPE_ID::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE20::text), '^^') 
            , '||', IFNULL(TRIM(TAX_HEADER_LEVEL_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE25::text), '^^') 
            , '||', IFNULL(TRIM(BILL_TO_SITE_USE_ID::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE24::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE23::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE22::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE20::text), '^^') 
            , '||', IFNULL(TRIM(SIC_CODE::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE17::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE18::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE15::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE16::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE13::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE14::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE11::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE12::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE18::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE17::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE16::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE15::text), '^^') 
            , '||', IFNULL(TRIM(FOB_POINT::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE19::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE19::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE10::text), '^^') 
            , '||', IFNULL(TRIM(GL_ID_CLEARING::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_VIA::text), '^^') 
            , '||', IFNULL(TRIM(ARRIVALSETS_INCLUDE_LINES_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(OBJECT_VERSION_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(TAX_REFERENCE::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_SETS_INCLUDE_LINES_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(CREATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(LAST_ACCRUE_CHARGE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(PAYMENT_TERM_ID::text), '^^') 
            , '||', IFNULL(TRIM(UNDER_SHIPMENT_TOLERANCE::text), '^^') 
            , '||', IFNULL(TRIM(SCHED_DATE_PUSH_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(GL_ID_REMITTANCE::text), '^^') 
            , '||', IFNULL(TRIM(PRICE_LIST_ID::text), '^^') 
            , '||', IFNULL(TRIM(SECOND_LAST_UNACCRUE_CHRG_DATE::text), '^^') 
            , '||', IFNULL(TRIM(WAREHOUSE_ID::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_APPLICATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(SECOND_LAST_ACCRUE_CHARGE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(TAX_ROUNDING_RULE::text), '^^') 
            , '||', IFNULL(TRIM(GL_ID_TAX::text), '^^') 
            , '||', IFNULL(TRIM(APPLICATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(REQUEST_ID::text), '^^') 
            , '||', IFNULL(TRIM(DATE_TYPE_PREFERENCE::text), '^^') 
            , '||', IFNULL(TRIM(PRIMARY_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_CROSS_REF_PREF::text), '^^') 
            , '||', IFNULL(TRIM(INVOICE_QUANTITY_RULE::text), '^^') 
            , '||', IFNULL(TRIM(GL_ID_FREIGHT::text), '^^') 
            , '||', IFNULL(TRIM(DATES_NEGATIVE_TOLERANCE::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_LOGIN::text), '^^') 
            , '||', IFNULL(TRIM(GSA_INDICATOR::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(WH_UPDATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(PRICING_EVENT::text), '^^') 
            , '||', IFNULL(TRIM(DEMAND_CLASS_CODE::text), '^^') 
            , '||', IFNULL(TRIM(PRIMARY_SALESREP_ID::text), '^^') 
            , '||', IFNULL(TRIM(CONTACT_ID::text), '^^') 
            , '||', IFNULL(TRIM(TAX_CODE::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_UPDATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(CREATION_DATE::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
