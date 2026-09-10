WITH
farmers_partner_number AS (
    SELECT PARTNER_NUMBER
    FROM {{ ref('ref_insurance_partner_name') }}
    WHERE LOWER(INSURANCE_PARTNER) LIKE 'farmers%'
        AND PARTNER_NUMBER IS NOT NULL

    UNION

    SELECT 'YO_00000071570' AS PARTNER_NUMBER
),

farmers_partner AS (
    SELECT
        COALESCE(dim.INSURANCE_PARTNER, ao.ORDER_TAG) AS ORDER_TAG,
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
        ao.REC_SRC,
        CASE
            WHEN ao.ORDER_TAG IN (SELECT PARTNER_NUMBER FROM farmers_partner_number) THEN 0
            WHEN ao.PARTNER_NUMBER IN (SELECT PARTNER_NUMBER FROM farmers_partner_number) THEN 1
            WHEN LOWER(COALESCE(ao.PARTNER_CODE, '')) LIKE 'farmers%' THEN 2
            ELSE 3
        END AS FARMERS_TAG_PRIORITY
    FROM {{ ref('pb_insurance_order_device_matched') }} AS ao
    LEFT JOIN {{ ref('ref_insurance_partner_name') }} AS dim
        ON dim.PARTNER_NUMBER = COALESCE(ao.PARTNER_NUMBER, ao.ORDER_TAG)
    WHERE (
            LOWER(COALESCE(ao.PARTNER_CODE, '')) LIKE 'farmers%'
            OR ao.PARTNER_NUMBER IN (SELECT PARTNER_NUMBER FROM farmers_partner_number)
            OR ao.ORDER_TAG IN (SELECT PARTNER_NUMBER FROM farmers_partner_number)
            OR LOWER(COALESCE(dim.INSURANCE_PARTNER, ao.ORDER_TAG, '')) LIKE 'farmers%'
        )
        AND COALESCE(ao.ORDER_TAG, '') <> 'High risk cancelled'
),

fos AS (
    SELECT
        ORDER_ID,
        FRONTDOOR_STATUS,
        FRONTDOOR_STATUS_ORIG AS FRONTDOOR_ORIG_STATUS,
        MOEN_ORDER_STATUS
    FROM {{ ref('pit_order_status_latest') }}
),

status_layer AS (
    SELECT
        fr.*,
        fos.FRONTDOOR_STATUS,
        fos.FRONTDOOR_ORIG_STATUS,
        CASE
            WHEN fos.FRONTDOOR_STATUS NOT IN ('Successful Installation', 'Future Appointment Scheduled')
                AND fr.LAST_ONLINE_DATE IS NOT NULL
                AND fr.MOEN_INSTALL_ACTIVE_DATE IS NOT NULL
                AND fr.VENDOR_INSTALL_DATE IS NULL
            THEN '3rd party'
            ELSE ''
        END AS WHO_INSTALLED,
        CASE
            WHEN fr.ORDER_STATUS = 'delivered'
                OR fr.MOEN_INSTALL_ACTIVE_DATE IS NOT NULL
                OR fr.VENDOR_INSTALL_DATE IS NOT NULL
                OR fos.FRONTDOOR_STATUS = 'Successful Installation'
            THEN 'Delivered'
            ELSE 'Not Delivered'
        END AS DELIVERED_PRELIM
    FROM farmers_partner AS fr
    LEFT JOIN fos
        ON fos.ORDER_ID = fr.ORDER_ID
),

status_layer2 AS (
    SELECT
        s.*,
        CASE
            WHEN s.FRONTDOOR_STATUS = 'Order Cancelled'
                AND s.WHO_INSTALLED <> '3rd party'
                AND s.ORDER_STATUS <> 'cancelled/returned'
            THEN 'Pending Cancel'
            ELSE ''
        END AS PENDING_CANCELLATION,
        CASE
            WHEN s.WHO_INSTALLED = '3rd party' THEN 'Delivered'
            ELSE s.DELIVERED_PRELIM
        END AS DELIVERED
    FROM status_layer AS s
),

final_base AS (
    SELECT
        ORDER_TAG,
        ORIG_ORDER_TAG,
        SHOPIFY_NUMERIC_ID,
        ORDER_ID,
        ORDER_DATE,
        ORDER_FIRST_NAME,
        ORDER_LAST_NAME,
        ORDER_EMAIL,
        ORDER_PHONE,
        ORDER_ADDRESS_1,
        ORDER_ADDRESS_2,
        ORDER_CITY,
        ORDER_STATE,
        ORDER_POSTCODE,
        ORDER_POSTCODE_ADD_ON,
        ORDER_STATUS,
        ORDER_QUANTITY,
        RETURN_QUANTITY,
        ORDER_VALUE,
        DISCOUNT_VALUE,
        DISCOUNT_CODE,
        ACTUAL_DELIVERY_DATE,
        SKU,
        VALVE_SIZE,
        LASTMODIFIED,
        INSTALLATION_FLAG,
        SUBSCRIPTION_FLAG,
        AFFIRM_FLAG,
        PARTNER_CODE,
        PARTNER_NUMBER,
        UTILITY_ACCOUNT_NUMBER,
        INSTALLATION_ADDRESS_LINE1,
        INSTALLATION_ADDRESS_LINE2,
        INSTALLATION_CITY,
        INSTALLATION_STATE,
        INSTALLATION_ZIP,
        ORDER_LINE_ID,
        SERIAL_ID,
        DEVICE_ID,
        USER_ID,
        FIRSTNAME,
        LASTNAME,
        EMAIL,
        PHONE_MOBILE,
        ADDRESS,
        CITY,
        STATE,
        POSTALCODE,
        MOEN_INSTALL_ACTIVE_DATE,
        PAIRED_DATE,
        IS_PAIRED,
        LAST_ONLINE_DATE,
        WATER_USAGE_LAST_MONTH,
        VENDOR_ID,
        VENDOR_NAME,
        VENDOR_INSTALL_DATE,
        SRC,
        WHO_INSTALLED,
        PENDING_CANCELLATION,
        DELIVERED,
        FRONTDOOR_STATUS,
        FRONTDOOR_ORIG_STATUS,
        BKCC,
        REC_SRC,
        CASE
            WHEN WHO_INSTALLED = '3rd party' THEN WHO_INSTALLED
            WHEN PENDING_CANCELLATION = 'Pending Cancel' THEN PENDING_CANCELLATION
            WHEN ORDER_STATUS = 'cancelled/returned'
                AND FRONTDOOR_STATUS <> 'Successful Installation'
            THEN 'Order Cancelled'
            WHEN FRONTDOOR_STATUS IS NULL THEN DELIVERED
            ELSE FRONTDOOR_STATUS
        END AS MOEN_STATUS
    FROM status_layer2
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY
            ORDER_ID,
            SKU,
            ORDER_LINE_ID,
            COALESCE(SERIAL_ID, ''),
            COALESCE(DEVICE_ID, '')
        ORDER BY
            FARMERS_TAG_PRIORITY ASC,
            VENDOR_INSTALL_DATE DESC NULLS LAST,
            MOEN_INSTALL_ACTIVE_DATE DESC NULLS LAST,
            FRONTDOOR_STATUS ASC NULLS LAST,
            SRC ASC NULLS LAST,
            ORIG_ORDER_TAG ASC NULLS LAST
    ) = 1
)

SELECT
    ROW_NUMBER() OVER (
        ORDER BY ORDER_ID, ORDER_LINE_ID, COALESCE(SERIAL_ID, ''), COALESCE(DEVICE_ID, '')
    ) AS SEQ_ID,
    CURRENT_DATE AS SNAPSHOTDATE,
    CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP) AS PB_LOAD_DTS,
    ORDER_TAG,
    ORIG_ORDER_TAG,
    SHOPIFY_NUMERIC_ID,
    ORDER_ID,
    ORDER_DATE,
    ORDER_FIRST_NAME,
    ORDER_LAST_NAME,
    ORDER_EMAIL,
    ORDER_PHONE,
    ORDER_ADDRESS_1,
    ORDER_ADDRESS_2,
    ORDER_CITY,
    ORDER_STATE,
    ORDER_POSTCODE,
    ORDER_POSTCODE_ADD_ON,
    ORDER_STATUS,
    ORDER_QUANTITY,
    RETURN_QUANTITY,
    ORDER_VALUE,
    DISCOUNT_VALUE,
    DISCOUNT_CODE,
    ACTUAL_DELIVERY_DATE,
    SKU,
    VALVE_SIZE,
    LASTMODIFIED,
    INSTALLATION_FLAG,
    SUBSCRIPTION_FLAG,
    AFFIRM_FLAG,
    PARTNER_CODE,
    PARTNER_NUMBER,
    UTILITY_ACCOUNT_NUMBER,
    INSTALLATION_ADDRESS_LINE1,
    INSTALLATION_ADDRESS_LINE2,
    INSTALLATION_CITY,
    INSTALLATION_STATE,
    INSTALLATION_ZIP,
    ORDER_LINE_ID,
    SERIAL_ID,
    DEVICE_ID,
    USER_ID,
    FIRSTNAME,
    LASTNAME,
    EMAIL,
    PHONE_MOBILE,
    ADDRESS,
    CITY,
    STATE,
    POSTALCODE,
    MOEN_INSTALL_ACTIVE_DATE,
    PAIRED_DATE,
    IS_PAIRED,
    LAST_ONLINE_DATE,
    WATER_USAGE_LAST_MONTH,
    VENDOR_ID,
    VENDOR_NAME,
    VENDOR_INSTALL_DATE,
    SRC,
    WHO_INSTALLED,
    PENDING_CANCELLATION,
    DELIVERED,
    FRONTDOOR_STATUS,
    FRONTDOOR_ORIG_STATUS,
    BKCC,
    REC_SRC,
    MOEN_STATUS
FROM final_base
