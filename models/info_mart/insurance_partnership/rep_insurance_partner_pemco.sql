{{ config(
    alias='rep_insurance_partner_pemco',
    materialized='table'
) }}
---- SRC LAYER ----
WITH
SRC_IPO            as ( SELECT ORDER_TAG, ORIG_ORDER_TAG, PARTNER_CODE, PARTNER_NUMBER, UTILITY_ACCOUNT_NUMBER, INSTALLATION_ADDRESS_LINE1, INSTALLATION_ADDRESS_LINE2, INSTALLATION_CITY, INSTALLATION_STATE, INSTALLATION_ZIP, ORDER_ID, ORDER_DATE, ORDER_FIRST_NAME, ORDER_LAST_NAME, ORDER_EMAIL, ORDER_PHONE, ORDER_ADDRESS_1, ORDER_ADDRESS_2, ORDER_CITY, ORDER_STATE, ORDER_POSTCODE, ORDER_POSTCODE_ADD_ON, ORDER_STATUS, ORDER_QUANTITY, RETURN_QUANTITY, ORDER_VALUE, DISCOUNT_VALUE, DISCOUNT_CODE, ACTUAL_DELIVERY_DATE, VALVE_SIZE, LASTMODIFIED, INSTALLATION_FLAG, SUBSCRIPTION_FLAG, AFFIRM_FLAG, SERIAL_ID, DEVICE_ID, USER_ID, FIRSTNAME, LASTNAME, EMAIL, PHONE_MOBILE, ADDRESS, CITY, STATE, POSTALCODE, MOEN_INSTALL_ACTIVE_DATE, PAIRED_DATE, IS_PAIRED, LAST_ONLINE_DATE, WATER_USAGE_LAST_MONTH, VENDOR_ID, VENDOR_NAME, VENDOR_INSTALL_DATE, SRC, FRONTDOOR_STATUS, FRONTDOOR_ORIG_STATUS, MOEN_STATUS, SKU, ORDER_LINE_ID, BKCC, REC_SRC FROM {{ ref('im_fact_insurance_partner_order') }} as SRC
                                                WHERE LOWER(PARTNER_CODE) = 'pemco'
                          AND ORDER_TAG != 'High risk cancelled'
)

/*
SRC_IPO            as ( SELECT * FROM insurance_partnership.IM_FACT_INSURANCE_PARTNER_ORDER )
*/

---- BRIDGE SRC: gap rows excluded by pb_insurance_partner_tagged (non-YO_* tags, high-risk order-level exclusion) ----
, SRC_BRIDGE_DM as (
    SELECT
        dm.ORDER_TAG
      , dm.ORDER_TAG                                                           AS ORIG_ORDER_TAG
      , dm.PARTNER_CODE
      , dm.PARTNER_NUMBER
      , dm.UTILITY_ACCOUNT_NUMBER
      , dm.INSTALLATION_ADDRESS_LINE1
      , dm.INSTALLATION_ADDRESS_LINE2
      , dm.INSTALLATION_CITY
      , dm.INSTALLATION_STATE
      , dm.INSTALLATION_ZIP
      , dm.ORDER_ID
      , dm.ORDER_DATE
      , dm.ORDER_FIRST_NAME
      , dm.ORDER_LAST_NAME
      , dm.ORDER_EMAIL
      , dm.ORDER_PHONE
      , dm.ORDER_ADDRESS_1
      , dm.ORDER_ADDRESS_2
      , dm.ORDER_CITY
      , dm.ORDER_STATE
      , dm.ORDER_POSTCODE
      , dm.ORDER_POSTCODE_ADD_ON
      , dm.ORDER_STATUS
      , dm.ORDER_QUANTITY
      , dm.RETURN_QUANTITY
      , dm.ORDER_VALUE
      , dm.DISCOUNT_VALUE
      , dm.DISCOUNT_CODE
      , dm.ACTUAL_DELIVERY_DATE
      , dm.VALVE_SIZE
      , dm.LASTMODIFIED
      , dm.INSTALLATION_FLAG
      , dm.SUBSCRIPTION_FLAG
      , dm.AFFIRM_FLAG
      , dm.SERIAL_ID
      , dm.DEVICE_ID
      , dm.USER_ID
      , dm.FIRSTNAME
      , dm.LASTNAME
      , dm.EMAIL
      , dm.PHONE_MOBILE
      , dm.ADDRESS
      , dm.CITY
      , dm.STATE
      , dm.POSTALCODE
      , dm.MOEN_INSTALL_ACTIVE_DATE
      , dm.PAIRED_DATE
      , dm.IS_PAIRED
      , dm.LAST_ONLINE_DATE
      , dm.WATER_USAGE_LAST_MONTH
      , dm.VENDOR_ID
      , dm.VENDOR_NAME
      , dm.VENDOR_INSTALL_DATE
      , dm.SRC
      , fos.FRONTDOOR_STATUS
      , fos.FRONTDOOR_STATUS                                                   AS FRONTDOOR_ORIG_STATUS
      , CASE
            WHEN dm.ORDER_STATUS = 'cancelled/returned'
                AND COALESCE(fos.FRONTDOOR_STATUS, '') <> 'Successful Installation'
            THEN 'Order Cancelled'
            WHEN fos.FRONTDOOR_STATUS IS NULL
            THEN IFF(dm.MOEN_INSTALL_ACTIVE_DATE IS NOT NULL
                     OR dm.VENDOR_INSTALL_DATE IS NOT NULL, 'Delivered', 'Not Delivered')
            ELSE fos.FRONTDOOR_STATUS
        END                                                                    AS MOEN_STATUS
      , dm.SKU
      , dm.ORDER_LINE_ID
      , dm.BKCC
      , dm.REC_SRC
    FROM {{ ref('pb_insurance_order_device_matched') }} dm
    LEFT JOIN {{ ref('pit_order_status_latest') }} fos
        ON fos.ORDER_ID = dm.ORDER_ID
        WHERE LOWER(dm.PARTNER_CODE) = 'pemco'
            AND dm.ORDER_TAG != 'High risk cancelled'
            AND NOT EXISTS (
                    SELECT 1
                    FROM {{ ref('im_fact_insurance_partner_order') }} ipo
                    WHERE LOWER(ipo.PARTNER_CODE) = 'pemco'
                        AND ipo.ORDER_ID = dm.ORDER_ID
            )
)

---- LOGIC LAYER ----

, LOGIC_IPO    as ( SELECT * FROM SRC_IPO )

, LOGIC_BRIDGE as ( SELECT * FROM SRC_BRIDGE_DM )
---- RENAME LAYER ----

, RENAME_IPO as (
    SELECT * FROM LOGIC_IPO
)

, RENAME_BRIDGE as (
    SELECT * FROM LOGIC_BRIDGE
)
---- FILTER LAYER ----

, FILTER_IPO as (
    SELECT * FROM RENAME_IPO
)

, FILTER_BRIDGE as (
    SELECT * FROM RENAME_BRIDGE
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_IPO
    UNION ALL
    SELECT * FROM FILTER_BRIDGE
)

---- FINAL LAYER ----
SELECT DISTINCT
        --  PARTNER_CODE,
          ORDER_ID
        , ORDER_DATE
        , ORDER_FIRST_NAME
        , ORDER_LAST_NAME
        , ORDER_EMAIL
    , LTRIM(REPLACE(REPLACE(REPLACE(REGEXP_REPLACE(ORDER_PHONE,'[()\\-]',''),'+1',''),' ',''),'+',''),'1') AS ORDER_PHONE
        , ORDER_ADDRESS_1
        , ORDER_ADDRESS_2
        , ORDER_CITY
        , ORDER_STATE
    , SPLIT_PART(ORDER_POSTCODE, '-', 1) AS ORDER_POSTCODE
    , COALESCE(NULLIF(ORDER_POSTCODE_ADD_ON, ''), SPLIT_PART(ORDER_POSTCODE, '-', 2)) AS ORDER_POSTCODE_ADD_ON
        , ORDER_STATUS
        , ORDER_QUANTITY
        , RETURN_QUANTITY
        , ACTUAL_DELIVERY_DATE
        , VALVE_SIZE
        , LASTMODIFIED
        , DEVICE_ID
        , SUBSCRIPTION_FLAG
        , NULL AS SUBSCRIPTION_STATUS
        , INSTALLATION_FLAG
        , INSTALLATION_ADDRESS_LINE1
        , INSTALLATION_ADDRESS_LINE2
        , INSTALLATION_CITY
        , INSTALLATION_STATE
        , INSTALLATION_ZIP
        , FIRSTNAME AS ACCOUNT_FIRSTNAME
        , LASTNAME AS ACCOUNT_LASTNAME
        , EMAIL AS ACCOUNT_EMAIL
        , PHONE_MOBILE AS ACCOUNT_PHONE_MOBILE
        , ADDRESS AS ACCOUNT_ADDRESS
        , CASE WHEN ASCII(CITY) > 127 THEN NULL ELSE CITY END AS ACCOUNT_CITY
        , STATE AS ACCOUNT_STATE
        , POSTALCODE AS ACCOUNT_POSTALCODE
        , MOEN_INSTALL_ACTIVE_DATE
        , PAIRED_DATE
        , IS_PAIRED
        , LAST_ONLINE_DATE
        , WATER_USAGE_LAST_MONTH
        , VENDOR_NAME
        , VENDOR_INSTALL_DATE
        , REPLACE(FRONTDOOR_STATUS, 'Contacted,', 'Contacted:') AS VENDOR_STATUS
        , MOEN_STATUS
FROM JOIN_RESULT
