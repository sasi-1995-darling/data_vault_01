---- SRC LAYER ----
WITH
SRC_s              as ( SELECT APP_ID, BILLING_ADDRESS_ADDRESS_1, BILLING_ADDRESS_ADDRESS_2, BILLING_ADDRESS_CITY, BILLING_ADDRESS_COMPANY, BILLING_ADDRESS_COUNTRY, 
                        BILLING_ADDRESS_COUNTRY_CODE, BILLING_ADDRESS_FIRST_NAME, BILLING_ADDRESS_LAST_NAME, BILLING_ADDRESS_LATITUDE, BILLING_ADDRESS_LONGITUDE, 
                        BILLING_ADDRESS_NAME, BILLING_ADDRESS_PHONE, BILLING_ADDRESS_PROVINCE, BILLING_ADDRESS_PROVINCE_CODE, BILLING_ADDRESS_ZIP, BROWSER_IP, 
                        BUYER_ACCEPTS_MARKETING, CANCELLED_AT, CANCEL_REASON, CART_TOKEN, CHECKOUT_ID, CHECKOUT_TOKEN, CLIENT_DETAILS_USER_AGENT, CLOSED_AT, 
                        COMPANY_ID, COMPANY_LOCATION_ID, CONFIRMED, CREATED_AT, CURRENCY, CURRENT_SUBTOTAL_PRICE, CURRENT_SUBTOTAL_PRICE_SET, 
                        CURRENT_TOTAL_DISCOUNTS, CURRENT_TOTAL_DISCOUNTS_SET, CURRENT_TOTAL_DUTIES_SET, CURRENT_TOTAL_PRICE, CURRENT_TOTAL_PRICE_SET, 
                        CURRENT_TOTAL_TAX, CURRENT_TOTAL_TAX_SET, CUSTOMER_ID, CUSTOMER_LOCALE, DEVICE_ID, EMAIL, FINANCIAL_STATUS, FULFILLMENT_STATUS, ID, 
                        LANDING_SITE_BASE_URL, LANDING_SITE_REF, LOCATION_ID, NAME, NOTE, NOTE_ATTRIBUTES, NUMBER, ORDER_NUMBER, ORDER_STATUS_URL, 
                        ORIGINAL_TOTAL_DUTIES_SET, PAYMENT_GATEWAY_NAMES, PRESENTMENT_CURRENCY, PROCESSED_AT, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, 
                        REFERENCE, REFERRING_SITE, SHIPPING_ADDRESS_ADDRESS_1, SHIPPING_ADDRESS_ADDRESS_2, SHIPPING_ADDRESS_CITY, SHIPPING_ADDRESS_COMPANY, 
                        SHIPPING_ADDRESS_COUNTRY, SHIPPING_ADDRESS_COUNTRY_CODE, SHIPPING_ADDRESS_FIRST_NAME, SHIPPING_ADDRESS_LAST_NAME, SHIPPING_ADDRESS_LATITUDE, 
                        SHIPPING_ADDRESS_LONGITUDE, SHIPPING_ADDRESS_NAME, SHIPPING_ADDRESS_PHONE, SHIPPING_ADDRESS_PROVINCE, SHIPPING_ADDRESS_PROVINCE_CODE, 
                        SHIPPING_ADDRESS_ZIP, SOURCE_IDENTIFIER, SOURCE_NAME, SOURCE_URL, SUBTOTAL_PRICE, SUBTOTAL_PRICE_SET, TAXES_INCLUDED, TEST, TOKEN, 
                        TOTAL_DISCOUNTS, TOTAL_DISCOUNTS_SET, TOTAL_LINE_ITEMS_PRICE, TOTAL_LINE_ITEMS_PRICE_SET, TOTAL_PRICE, TOTAL_PRICE_SET, 
                        TOTAL_SHIPPING_PRICE_SET, TOTAL_TAX, TOTAL_TAX_SET, TOTAL_TIP_RECEIVED, TOTAL_WEIGHT, UPDATED_AT, USER_ID, _FIVETRAN_DELETED, 
                        _FIVETRAN_SYNCED
                        /* Syndicate delete filter: suppress truncate-reload artifact deletes (Y+N in same batch) */
                        , CASE WHEN PSA_DELETE_IND = 'Y'
                               AND COUNT_IF(PSA_DELETE_IND = 'N') OVER (PARTITION BY ID, PSA_LOAD_DTS) > 0
                               THEN TRUE ELSE FALSE END AS TRUNCATE_RELOAD_FLAG
                        FROM {{ source('shopify_moen', 'ORDER') }} as SRC 
                        /*The following qualify clause is required to pull the latest row synced by fivetran based on these PK columns, 
                        only the most recent record present in the source is needed.*/
                        QUALIFY NOT TRUNCATE_RELOAD_FLAG
                            AND 1 = row_number() over(partition by id order by _fivetran_synced desc)  ),
SRC_a              as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_s              as ( SELECT * FROM shopify_moen.ORDER )
SRC_a              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_s as (
    SELECT
        ID
      , NOTE
      , EMAIL
      , TAXES_INCLUDED
      , CURRENCY
      , SUBTOTAL_PRICE
      , SUBTOTAL_PRICE_SET
      , TOTAL_TAX
      , TOTAL_TAX_SET
      , TOTAL_PRICE
      , TOTAL_PRICE_SET
      , CREATED_AT
      , UPDATED_AT
      , NAME
      , SHIPPING_ADDRESS_NAME
      , SHIPPING_ADDRESS_FIRST_NAME
      , SHIPPING_ADDRESS_LAST_NAME
      , SHIPPING_ADDRESS_COMPANY
      , SHIPPING_ADDRESS_PHONE
      , SHIPPING_ADDRESS_ADDRESS_1
      , SHIPPING_ADDRESS_ADDRESS_2
      , SHIPPING_ADDRESS_CITY
      , SHIPPING_ADDRESS_COUNTRY
      , SHIPPING_ADDRESS_COUNTRY_CODE
      , SHIPPING_ADDRESS_PROVINCE
      , SHIPPING_ADDRESS_PROVINCE_CODE
      , SHIPPING_ADDRESS_ZIP
      , SHIPPING_ADDRESS_LATITUDE
      , SHIPPING_ADDRESS_LONGITUDE
      , BILLING_ADDRESS_NAME
      , BILLING_ADDRESS_FIRST_NAME
      , BILLING_ADDRESS_LAST_NAME
      , BILLING_ADDRESS_COMPANY
      , BILLING_ADDRESS_PHONE
      , BILLING_ADDRESS_ADDRESS_1
      , BILLING_ADDRESS_ADDRESS_2
      , BILLING_ADDRESS_CITY
      , BILLING_ADDRESS_COUNTRY
      , BILLING_ADDRESS_COUNTRY_CODE
      , BILLING_ADDRESS_PROVINCE
      , BILLING_ADDRESS_PROVINCE_CODE
      , BILLING_ADDRESS_ZIP
      , BILLING_ADDRESS_LATITUDE
      , BILLING_ADDRESS_LONGITUDE
      , CUSTOMER_ID
      , LOCATION_ID
      , USER_ID
      , APP_ID
      , NUMBER
      , ORDER_NUMBER
      , FINANCIAL_STATUS
      , FULFILLMENT_STATUS
      , PROCESSED_AT
      , REFERRING_SITE
      , CANCEL_REASON
      , CANCELLED_AT
      , CLOSED_AT
      , TOTAL_DISCOUNTS
      , TOTAL_TIP_RECEIVED
      , CURRENT_TOTAL_PRICE
      , CURRENT_TOTAL_DISCOUNTS
      , CURRENT_SUBTOTAL_PRICE
      , CURRENT_TOTAL_TAX
      , CURRENT_TOTAL_DISCOUNTS_SET
      , CURRENT_TOTAL_DUTIES_SET
      , CURRENT_TOTAL_PRICE_SET
      , CURRENT_SUBTOTAL_PRICE_SET
      , CURRENT_TOTAL_TAX_SET
      , TOTAL_DISCOUNTS_SET
      , TOTAL_SHIPPING_PRICE_SET
      , TOTAL_LINE_ITEMS_PRICE
      , TOTAL_LINE_ITEMS_PRICE_SET
      , ORIGINAL_TOTAL_DUTIES_SET
      , TOTAL_WEIGHT
      , SOURCE_NAME
      , BROWSER_IP
      , BUYER_ACCEPTS_MARKETING
      , CONFIRMED
      , TOKEN
      , CART_TOKEN
      , CHECKOUT_TOKEN
      , CHECKOUT_ID
      , CUSTOMER_LOCALE
      , DEVICE_ID
      , LANDING_SITE_REF
      , PRESENTMENT_CURRENCY
      , REFERENCE
      , SOURCE_IDENTIFIER
      , SOURCE_URL
      , _FIVETRAN_DELETED
      , ORDER_STATUS_URL
      , TEST
      , PAYMENT_GATEWAY_NAMES
      , NOTE_ATTRIBUTES
      , CLIENT_DETAILS_USER_AGENT
      , LANDING_SITE_BASE_URL
      , _FIVETRAN_SYNCED
      , COMPANY_ID
      , COMPANY_LOCATION_ID
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
    FROM SRC_s
)

, LOGIC_a as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_a
)
---- RENAME LAYER ----

, RENAME_s as (
    SELECT
        ID
      , NOTE
      , EMAIL
      , TAXES_INCLUDED
      , CURRENCY
      , SUBTOTAL_PRICE
      , SUBTOTAL_PRICE_SET
      , TOTAL_TAX
      , TOTAL_TAX_SET
      , TOTAL_PRICE
      , TOTAL_PRICE_SET
      , CREATED_AT
      , UPDATED_AT
      , NAME
      , SHIPPING_ADDRESS_NAME
      , SHIPPING_ADDRESS_FIRST_NAME
      , SHIPPING_ADDRESS_LAST_NAME
      , SHIPPING_ADDRESS_COMPANY
      , SHIPPING_ADDRESS_PHONE
      , SHIPPING_ADDRESS_ADDRESS_1
      , SHIPPING_ADDRESS_ADDRESS_2
      , SHIPPING_ADDRESS_CITY
      , SHIPPING_ADDRESS_COUNTRY
      , SHIPPING_ADDRESS_COUNTRY_CODE
      , SHIPPING_ADDRESS_PROVINCE
      , SHIPPING_ADDRESS_PROVINCE_CODE
      , SHIPPING_ADDRESS_ZIP
      , SHIPPING_ADDRESS_LATITUDE
      , SHIPPING_ADDRESS_LONGITUDE
      , BILLING_ADDRESS_NAME
      , BILLING_ADDRESS_FIRST_NAME
      , BILLING_ADDRESS_LAST_NAME
      , BILLING_ADDRESS_COMPANY
      , BILLING_ADDRESS_PHONE
      , BILLING_ADDRESS_ADDRESS_1
      , BILLING_ADDRESS_ADDRESS_2
      , BILLING_ADDRESS_CITY
      , BILLING_ADDRESS_COUNTRY
      , BILLING_ADDRESS_COUNTRY_CODE
      , BILLING_ADDRESS_PROVINCE
      , BILLING_ADDRESS_PROVINCE_CODE
      , BILLING_ADDRESS_ZIP
      , BILLING_ADDRESS_LATITUDE
      , BILLING_ADDRESS_LONGITUDE
      , CUSTOMER_ID
      , LOCATION_ID
      , USER_ID
      , APP_ID
      , NUMBER
      , ORDER_NUMBER
      , FINANCIAL_STATUS
      , FULFILLMENT_STATUS
      , PROCESSED_AT
      , REFERRING_SITE
      , CANCEL_REASON
      , CANCELLED_AT
      , CLOSED_AT
      , TOTAL_DISCOUNTS
      , TOTAL_TIP_RECEIVED
      , CURRENT_TOTAL_PRICE
      , CURRENT_TOTAL_DISCOUNTS
      , CURRENT_SUBTOTAL_PRICE
      , CURRENT_TOTAL_TAX
      , CURRENT_TOTAL_DISCOUNTS_SET
      , CURRENT_TOTAL_DUTIES_SET
      , CURRENT_TOTAL_PRICE_SET
      , CURRENT_SUBTOTAL_PRICE_SET
      , CURRENT_TOTAL_TAX_SET
      , TOTAL_DISCOUNTS_SET
      , TOTAL_SHIPPING_PRICE_SET
      , TOTAL_LINE_ITEMS_PRICE
      , TOTAL_LINE_ITEMS_PRICE_SET
      , ORIGINAL_TOTAL_DUTIES_SET
      , TOTAL_WEIGHT
      , SOURCE_NAME
      , BROWSER_IP
      , BUYER_ACCEPTS_MARKETING
      , CONFIRMED
      , TOKEN
      , CART_TOKEN
      , CHECKOUT_TOKEN
      , CHECKOUT_ID
      , CUSTOMER_LOCALE
      , DEVICE_ID
      , LANDING_SITE_REF
      , PRESENTMENT_CURRENCY
      , REFERENCE
      , SOURCE_IDENTIFIER
      , SOURCE_URL
      , _FIVETRAN_DELETED
      , ORDER_STATUS_URL
      , TEST
      , PAYMENT_GATEWAY_NAMES
      , NOTE_ATTRIBUTES
      , CLIENT_DETAILS_USER_AGENT
      , LANDING_SITE_BASE_URL
      , _FIVETRAN_SYNCED
      , COMPANY_ID
      , COMPANY_LOCATION_ID
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
    FROM LOGIC_s
)

, RENAME_a as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_a
)
---- FILTER LAYER ----

, FILTER_s as (
    SELECT *
    FROM RENAME_s
)

, FILTER_a as (
    SELECT *
    FROM RENAME_a
    WHERE rec_src = 'US.API.SHOPIFY_MOEN.ORDER'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_s
    INNER JOIN FILTER_a
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          ID
        , NOTE
        , EMAIL
        , TAXES_INCLUDED
        , CURRENCY
        , SUBTOTAL_PRICE
        , SUBTOTAL_PRICE_SET
        , TOTAL_TAX
        , TOTAL_TAX_SET
        , TOTAL_PRICE
        , TOTAL_PRICE_SET
        , CREATED_AT
        , UPDATED_AT
        , NAME
        , SHIPPING_ADDRESS_NAME
        , SHIPPING_ADDRESS_FIRST_NAME
        , SHIPPING_ADDRESS_LAST_NAME
        , SHIPPING_ADDRESS_COMPANY
        , SHIPPING_ADDRESS_PHONE
        , SHIPPING_ADDRESS_ADDRESS_1
        , SHIPPING_ADDRESS_ADDRESS_2
        , SHIPPING_ADDRESS_CITY
        , SHIPPING_ADDRESS_COUNTRY
        , SHIPPING_ADDRESS_COUNTRY_CODE
        , SHIPPING_ADDRESS_PROVINCE
        , SHIPPING_ADDRESS_PROVINCE_CODE
        , SHIPPING_ADDRESS_ZIP
        , SHIPPING_ADDRESS_LATITUDE
        , SHIPPING_ADDRESS_LONGITUDE
        , BILLING_ADDRESS_NAME
        , BILLING_ADDRESS_FIRST_NAME
        , BILLING_ADDRESS_LAST_NAME
        , BILLING_ADDRESS_COMPANY
        , BILLING_ADDRESS_PHONE
        , BILLING_ADDRESS_ADDRESS_1
        , BILLING_ADDRESS_ADDRESS_2
        , BILLING_ADDRESS_CITY
        , BILLING_ADDRESS_COUNTRY
        , BILLING_ADDRESS_COUNTRY_CODE
        , BILLING_ADDRESS_PROVINCE
        , BILLING_ADDRESS_PROVINCE_CODE
        , BILLING_ADDRESS_ZIP
        , BILLING_ADDRESS_LATITUDE
        , BILLING_ADDRESS_LONGITUDE
        , CUSTOMER_ID
        , LOCATION_ID
        , USER_ID
        , APP_ID
        , NUMBER
        , ORDER_NUMBER
        , FINANCIAL_STATUS
        , FULFILLMENT_STATUS
        , PROCESSED_AT
        , REFERRING_SITE
        , CANCEL_REASON
        , CANCELLED_AT
        , CLOSED_AT
        , TOTAL_DISCOUNTS
        , TOTAL_TIP_RECEIVED
        , CURRENT_TOTAL_PRICE
        , CURRENT_TOTAL_DISCOUNTS
        , CURRENT_SUBTOTAL_PRICE
        , CURRENT_TOTAL_TAX
        , CURRENT_TOTAL_DISCOUNTS_SET
        , CURRENT_TOTAL_DUTIES_SET
        , CURRENT_TOTAL_PRICE_SET
        , CURRENT_SUBTOTAL_PRICE_SET
        , CURRENT_TOTAL_TAX_SET
        , TOTAL_DISCOUNTS_SET
        , TOTAL_SHIPPING_PRICE_SET
        , TOTAL_LINE_ITEMS_PRICE
        , TOTAL_LINE_ITEMS_PRICE_SET
        , ORIGINAL_TOTAL_DUTIES_SET
        , TOTAL_WEIGHT
        , SOURCE_NAME
        , BROWSER_IP
        , BUYER_ACCEPTS_MARKETING
        , CONFIRMED
        , TOKEN
        , CART_TOKEN
        , CHECKOUT_TOKEN
        , CHECKOUT_ID
        , CUSTOMER_LOCALE
        , DEVICE_ID
        , LANDING_SITE_REF
        , PRESENTMENT_CURRENCY
        , REFERENCE
        , SOURCE_IDENTIFIER
        , SOURCE_URL
        , _FIVETRAN_DELETED
        , ORDER_STATUS_URL
        , TEST
        , PAYMENT_GATEWAY_NAMES
        , NOTE_ATTRIBUTES
        , CLIENT_DETAILS_USER_AGENT
        , LANDING_SITE_BASE_URL
        , _FIVETRAN_SYNCED
        , COMPANY_ID
        , COMPANY_LOCATION_ID
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , CONVERT_TIMEZONE('UTC', IFF(
            PSA_DELETE_IND = 'Y',
            PSA_LOAD_DTS,_FIVETRAN_SYNCED)) as LOAD_DTS
        , REC_SRC
        , BKCC
        , COALESCE(NAME, '-1')                                         as ORDER_HEADER_BK
        , COALESCE(CUSTOMER_ID, '-1')::VARCHAR                         as CUSTOMER_BK
        , COALESCE(NULLIF(TRIM(LOWER(EMAIL)),''),'-1')                 as CONSUMER_BK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ORDER_HEADER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ORDER_HEADER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(CUSTOMER_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as CUSTOMER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(CONSUMER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as CONSUMER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ORDER_HEADER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(CUSTOMER_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(CONSUMER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as LNK_ORDER_CUSTOMER_CONSUMER_HK
        -- Track delete-indicator flip sequence so true delete would not prevent the resurrection from going to sats/lsats.
        , CONDITIONAL_CHANGE_EVENT(PSA_DELETE_IND) OVER(PARTITION BY ID ORDER BY _FIVETRAN_SYNCED, PSA_LOAD_DTS) AS CCE
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(ID::text), '^^') 
            , '||', IFNULL(TRIM(NOTE::text), '^^') 
            , '||', IFNULL(TRIM(EMAIL::text), '^^') 
            , '||', IFNULL(TRIM(TAXES_INCLUDED::text), '^^') 
            , '||', IFNULL(TRIM(CURRENCY::text), '^^') 
            , '||', IFNULL(TRIM(SUBTOTAL_PRICE::text), '^^') 
            , '||', IFNULL(TRIM(SUBTOTAL_PRICE_SET::text), '^^') 
            , '||', IFNULL(TRIM(TOTAL_TAX::text), '^^') 
            , '||', IFNULL(TRIM(TOTAL_TAX_SET::text), '^^') 
            , '||', IFNULL(TRIM(TOTAL_PRICE::text), '^^') 
            , '||', IFNULL(TRIM(TOTAL_PRICE_SET::text), '^^') 
            , '||', IFNULL(TRIM(CREATED_AT::text), '^^') 
            , '||', IFNULL(TRIM(UPDATED_AT::text), '^^') 
            , '||', IFNULL(TRIM(NAME::text), '^^') 
            , '||', IFNULL(TRIM(SHIPPING_ADDRESS_NAME::text), '^^') 
            , '||', IFNULL(TRIM(SHIPPING_ADDRESS_FIRST_NAME::text), '^^') 
            , '||', IFNULL(TRIM(SHIPPING_ADDRESS_LAST_NAME::text), '^^') 
            , '||', IFNULL(TRIM(SHIPPING_ADDRESS_COMPANY::text), '^^') 
            , '||', IFNULL(TRIM(SHIPPING_ADDRESS_PHONE::text), '^^') 
            , '||', IFNULL(TRIM(SHIPPING_ADDRESS_ADDRESS_1::text), '^^') 
            , '||', IFNULL(TRIM(SHIPPING_ADDRESS_ADDRESS_2::text), '^^') 
            , '||', IFNULL(TRIM(SHIPPING_ADDRESS_CITY::text), '^^') 
            , '||', IFNULL(TRIM(SHIPPING_ADDRESS_COUNTRY::text), '^^') 
            , '||', IFNULL(TRIM(SHIPPING_ADDRESS_COUNTRY_CODE::text), '^^') 
            , '||', IFNULL(TRIM(SHIPPING_ADDRESS_PROVINCE::text), '^^') 
            , '||', IFNULL(TRIM(SHIPPING_ADDRESS_PROVINCE_CODE::text), '^^') 
            , '||', IFNULL(TRIM(SHIPPING_ADDRESS_ZIP::text), '^^') 
            , '||', IFNULL(TRIM(SHIPPING_ADDRESS_LATITUDE::text), '^^') 
            , '||', IFNULL(TRIM(SHIPPING_ADDRESS_LONGITUDE::text), '^^') 
            , '||', IFNULL(TRIM(BILLING_ADDRESS_NAME::text), '^^') 
            , '||', IFNULL(TRIM(BILLING_ADDRESS_FIRST_NAME::text), '^^') 
            , '||', IFNULL(TRIM(BILLING_ADDRESS_LAST_NAME::text), '^^') 
            , '||', IFNULL(TRIM(BILLING_ADDRESS_COMPANY::text), '^^') 
            , '||', IFNULL(TRIM(BILLING_ADDRESS_PHONE::text), '^^') 
            , '||', IFNULL(TRIM(BILLING_ADDRESS_ADDRESS_1::text), '^^') 
            , '||', IFNULL(TRIM(BILLING_ADDRESS_ADDRESS_2::text), '^^') 
            , '||', IFNULL(TRIM(BILLING_ADDRESS_CITY::text), '^^') 
            , '||', IFNULL(TRIM(BILLING_ADDRESS_COUNTRY::text), '^^') 
            , '||', IFNULL(TRIM(BILLING_ADDRESS_COUNTRY_CODE::text), '^^') 
            , '||', IFNULL(TRIM(BILLING_ADDRESS_PROVINCE::text), '^^') 
            , '||', IFNULL(TRIM(BILLING_ADDRESS_PROVINCE_CODE::text), '^^') 
            , '||', IFNULL(TRIM(BILLING_ADDRESS_ZIP::text), '^^') 
            , '||', IFNULL(TRIM(BILLING_ADDRESS_LATITUDE::text), '^^') 
            , '||', IFNULL(TRIM(BILLING_ADDRESS_LONGITUDE::text), '^^') 
            , '||', IFNULL(TRIM(CUSTOMER_ID::text), '^^') 
            , '||', IFNULL(TRIM(LOCATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(USER_ID::text), '^^') 
            , '||', IFNULL(TRIM(APP_ID::text), '^^') 
            , '||', IFNULL(TRIM(NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(ORDER_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(FINANCIAL_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(FULFILLMENT_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(PROCESSED_AT::text), '^^') 
            , '||', IFNULL(TRIM(REFERRING_SITE::text), '^^') 
            , '||', IFNULL(TRIM(CANCEL_REASON::text), '^^') 
            , '||', IFNULL(TRIM(CANCELLED_AT::text), '^^') 
            , '||', IFNULL(TRIM(CLOSED_AT::text), '^^') 
            , '||', IFNULL(TRIM(TOTAL_DISCOUNTS::text), '^^') 
            , '||', IFNULL(TRIM(TOTAL_TIP_RECEIVED::text), '^^') 
            , '||', IFNULL(TRIM(CURRENT_TOTAL_PRICE::text), '^^') 
            , '||', IFNULL(TRIM(CURRENT_TOTAL_DISCOUNTS::text), '^^') 
            , '||', IFNULL(TRIM(CURRENT_SUBTOTAL_PRICE::text), '^^') 
            , '||', IFNULL(TRIM(CURRENT_TOTAL_TAX::text), '^^') 
            , '||', IFNULL(TRIM(CURRENT_TOTAL_DISCOUNTS_SET::text), '^^') 
            , '||', IFNULL(TRIM(CURRENT_TOTAL_DUTIES_SET::text), '^^') 
            , '||', IFNULL(TRIM(CURRENT_TOTAL_PRICE_SET::text), '^^') 
            , '||', IFNULL(TRIM(CURRENT_SUBTOTAL_PRICE_SET::text), '^^') 
            , '||', IFNULL(TRIM(CURRENT_TOTAL_TAX_SET::text), '^^') 
            , '||', IFNULL(TRIM(TOTAL_DISCOUNTS_SET::text), '^^') 
            , '||', IFNULL(TRIM(TOTAL_SHIPPING_PRICE_SET::text), '^^') 
            , '||', IFNULL(TRIM(TOTAL_LINE_ITEMS_PRICE::text), '^^') 
            , '||', IFNULL(TRIM(TOTAL_LINE_ITEMS_PRICE_SET::text), '^^') 
            , '||', IFNULL(TRIM(ORIGINAL_TOTAL_DUTIES_SET::text), '^^') 
            , '||', IFNULL(TRIM(TOTAL_WEIGHT::text), '^^') 
            , '||', IFNULL(TRIM(SOURCE_NAME::text), '^^') 
            , '||', IFNULL(TRIM(BROWSER_IP::text), '^^') 
            , '||', IFNULL(TRIM(BUYER_ACCEPTS_MARKETING::text), '^^') 
            , '||', IFNULL(TRIM(CONFIRMED::text), '^^') 
            , '||', IFNULL(TRIM(TOKEN::text), '^^') 
            , '||', IFNULL(TRIM(CART_TOKEN::text), '^^') 
            , '||', IFNULL(TRIM(CHECKOUT_TOKEN::text), '^^') 
            , '||', IFNULL(TRIM(CHECKOUT_ID::text), '^^') 
            , '||', IFNULL(TRIM(CUSTOMER_LOCALE::text), '^^') 
            , '||', IFNULL(TRIM(DEVICE_ID::text), '^^') 
            , '||', IFNULL(TRIM(LANDING_SITE_REF::text), '^^') 
            , '||', IFNULL(TRIM(PRESENTMENT_CURRENCY::text), '^^') 
            , '||', IFNULL(TRIM(REFERENCE::text), '^^') 
            , '||', IFNULL(TRIM(SOURCE_IDENTIFIER::text), '^^') 
            , '||', IFNULL(TRIM(SOURCE_URL::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
            , '||', IFNULL(TRIM(ORDER_STATUS_URL::text), '^^') 
            , '||', IFNULL(TRIM(TEST::text), '^^') 
            , '||', IFNULL(TRIM(PAYMENT_GATEWAY_NAMES::text), '^^') 
            , '||', IFNULL(TRIM(NOTE_ATTRIBUTES::text), '^^') 
            , '||', IFNULL(TRIM(CLIENT_DETAILS_USER_AGENT::text), '^^') 
            , '||', IFNULL(TRIM(LANDING_SITE_BASE_URL::text), '^^') 
            , '||', IFNULL(TRIM(COMPANY_ID::text), '^^') 
            , '||', IFNULL(TRIM(COMPANY_LOCATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
            , '||', IFNULL(TRIM(CCE::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
