{{ config(materialized='table') }}

WITH
tag_map AS (
    SELECT
        _PARTNER_NUMBER AS PARTNER_NUMBER,
        BUSINESS_NAME AS INSURANCE_PARTNER
    FROM {{ source('custom_fivetran_smartsheet_flo_insurance_partner', 'insurance_partner_name') }}
),

insurance_partner AS (
    SELECT
        tm.INSURANCE_PARTNER AS ORDER_TAG,
        ao.ORDER_TAG AS ORIG_ORDER_TAG,
        ao.SHOPIFY_NUMERIC_ID,
        ao.ORDER_ID,
        ao.ORDER_DATE,
        ao.ORDER_FIRST_NAME,
        ao.ORDER_LAST_NAME,
        ao.ORDER_EMAIL,
        ao.ORDER_PHONE,
        ao.ORDER_ADDRESS_1,
        ao.ORDER_ADDRESS_2,
        ao.ORDER_CITY,
        ao.ORDER_STATE,
        ao.ORDER_POSTCODE,
        ao.ORDER_POSTCODE_ADD_ON,
        ao.ORDER_STATUS,
        ao.ORDER_QUANTITY,
        ao.RETURN_QUANTITY,
        ao.ORDER_VALUE,
        ao.DISCOUNT_VALUE,
        ao.DISCOUNT_CODE,
        ao.ACTUAL_DELIVERY_DATE,
        ao.SKU,
        ao.VALVE_SIZE,
        ao.LASTMODIFIED,
        ao.INSTALLATION_FLAG,
        ao.SUBSCRIPTION_FLAG,
        ao.AFFIRM_FLAG,
        ao.PARTNER_CODE,
        ao.PARTNER_NUMBER,
        ao.UTILITY_ACCOUNT_NUMBER,
        ao.INSTALLATION_ADDRESS_LINE1,
        ao.INSTALLATION_ADDRESS_LINE2,
        ao.INSTALLATION_CITY,
        ao.INSTALLATION_STATE,
        ao.INSTALLATION_ZIP,
        ao.ORDER_LINE_ID,
        ao.SERIAL_ID,
        ao.DEVICE_ID,
        ao.USER_ID,
        ao.FIRSTNAME,
        ao.LASTNAME,
        ao.EMAIL,
        ao.PHONE_MOBILE,
        ao.ADDRESS,
        ao.CITY,
        ao.STATE,
        ao.POSTALCODE,
        ao.MOEN_INSTALL_ACTIVE_DATE,
        ao.PAIRED_DATE,
        ao.IS_PAIRED,
        ao.LAST_ONLINE_DATE,
        ao.WATER_USAGE_LAST_MONTH,
        ao.VENDOR_ID,
        ao.VENDOR_NAME,
        ao.VENDOR_INSTALL_DATE,
        ao.SRC,
        ao.BKCC,
        ao.REC_SRC
    FROM {{ ref('pb_insurance_order_device_matched') }} AS ao
    LEFT JOIN tag_map AS tm ON tm.PARTNER_NUMBER = COALESCE(ao.PARTNER_NUMBER, ao.ORDER_TAG)
),

high_risk_excluded AS (
    SELECT ORDER_ID
    FROM insurance_partner
    WHERE ORIG_ORDER_TAG = 'High risk cancelled'
    GROUP BY ORDER_ID
)

SELECT
    seq8() AS SEQ_ID,
    CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP) AS PB_LOAD_DTS,
    ip.ORDER_TAG,
    ip.ORIG_ORDER_TAG,
    ip.SHOPIFY_NUMERIC_ID,
    ip.ORDER_ID,
    ip.ORDER_DATE,
    ip.ORDER_FIRST_NAME,
    ip.ORDER_LAST_NAME,
    ip.ORDER_EMAIL,
    ip.ORDER_PHONE,
    ip.ORDER_ADDRESS_1,
    ip.ORDER_ADDRESS_2,
    ip.ORDER_CITY,
    ip.ORDER_STATE,
    ip.ORDER_POSTCODE,
    ip.ORDER_POSTCODE_ADD_ON,
    ip.ORDER_STATUS,
    ip.ORDER_QUANTITY,
    ip.RETURN_QUANTITY,
    ip.ORDER_VALUE,
    ip.DISCOUNT_VALUE,
    ip.DISCOUNT_CODE,
    ip.ACTUAL_DELIVERY_DATE,
    ip.SKU,
    ip.VALVE_SIZE,
    ip.LASTMODIFIED,
    ip.INSTALLATION_FLAG,
    ip.SUBSCRIPTION_FLAG,
    ip.AFFIRM_FLAG,
    ip.PARTNER_CODE,
    ip.PARTNER_NUMBER,
    ip.UTILITY_ACCOUNT_NUMBER,
    ip.INSTALLATION_ADDRESS_LINE1,
    ip.INSTALLATION_ADDRESS_LINE2,
    ip.INSTALLATION_CITY,
    ip.INSTALLATION_STATE,
    ip.INSTALLATION_ZIP,
    ip.ORDER_LINE_ID,
    ip.SERIAL_ID,
    ip.DEVICE_ID,
    ip.USER_ID,
    ip.FIRSTNAME,
    ip.LASTNAME,
    ip.EMAIL,
    ip.PHONE_MOBILE,
    ip.ADDRESS,
    ip.CITY,
    ip.STATE,
    ip.POSTALCODE,
    ip.MOEN_INSTALL_ACTIVE_DATE,
    ip.PAIRED_DATE,
    ip.IS_PAIRED,
    ip.LAST_ONLINE_DATE,
    ip.WATER_USAGE_LAST_MONTH,
    ip.VENDOR_ID,
    ip.VENDOR_NAME,
    ip.VENDOR_INSTALL_DATE,
    ip.SRC,
    ip.BKCC,
    ip.REC_SRC
FROM insurance_partner AS ip
WHERE NOT EXISTS (SELECT 1 FROM high_risk_excluded hr WHERE hr.ORDER_ID = ip.ORDER_ID)
    AND (ip.ORIG_ORDER_TAG LIKE 'YO_%' OR ip.ORIG_ORDER_TAG IS NULL)
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY
        ip.ORDER_ID, ip.SKU, ip.ORDER_LINE_ID, COALESCE(ip.ORIG_ORDER_TAG, '_no_tag')
    ORDER BY
        ip.VENDOR_INSTALL_DATE DESC NULLS LAST,
        ip.MOEN_INSTALL_ACTIVE_DATE DESC NULLS LAST,
        ip.LAST_ONLINE_DATE DESC NULLS LAST,
        ip.SERIAL_ID DESC NULLS LAST,
        ip.SRC ASC NULLS LAST
) = 1
