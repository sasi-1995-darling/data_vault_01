WITH fr AS (
    SELECT *
    FROM {{ ref('pb_insurance_partner_tagged') }}
),

fos AS (
    SELECT
        order_id,
        frontdoor_status,
        frontdoor_status_orig AS frontdoor_orig_status,
        moen_order_status
    FROM {{ ref('pit_order_status_latest') }}
),

status_layer AS (
    SELECT
        fr.*,
        fos.frontdoor_status,
        fos.frontdoor_orig_status,
        CASE
            WHEN fos.frontdoor_status NOT IN ('Successful Installation', 'Future Appointment Scheduled')
                AND fr.last_online_date IS NOT NULL
                AND fr.moen_install_active_date IS NOT NULL
                AND fr.vendor_install_date IS NULL
            THEN '3rd party'
            ELSE ''
        END AS who_installed,
        CASE
            WHEN fr.order_status = 'delivered'
                OR fr.moen_install_active_date IS NOT NULL
                OR fr.vendor_install_date IS NOT NULL
                OR fos.frontdoor_status = 'Successful Installation'
            THEN 'Delivered'
            ELSE 'Not Delivered'
        END AS delivered_prelim
    FROM fr
    LEFT JOIN fos
        ON fos.order_id = fr.order_id
),

status_layer2 AS (
    SELECT
        s.*,
        CASE
            WHEN s.frontdoor_status = 'Order Cancelled'
                AND s.who_installed <> '3rd party'
                AND s.order_status <> 'cancelled/returned'
            THEN 'Pending Cancel'
            ELSE ''
        END AS pending_cancellation,
        CASE
            WHEN s.who_installed = '3rd party' THEN 'Delivered'
            ELSE s.delivered_prelim
        END AS delivered
    FROM status_layer s
)

SELECT
    ROW_NUMBER() OVER (ORDER BY 1) AS seq_id,
    CURRENT_DATE AS snapshotdate,
    CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP) AS pb_load_dts,
    order_tag,
    orig_order_tag,
    shopify_numeric_id,
    order_id,
    order_date,
    order_first_name,
    order_last_name,
    order_email,
    order_phone,
    order_address_1,
    order_address_2,
    order_city,
    order_state,
    order_postcode,
    order_postcode_add_on,
    order_status,
    order_quantity,
    return_quantity,
    order_value,
    discount_value,
    discount_code,
    actual_delivery_date,
    sku,
    valve_size,
    lastmodified,
    installation_flag,
    subscription_flag,
    affirm_flag,
    partner_code,
    partner_number,
    utility_account_number,
    installation_address_line1,
    installation_address_line2,
    installation_city,
    installation_state,
    installation_zip,
    order_line_id,
    serial_id,
    device_id,
    user_id,
    firstname,
    lastname,
    email,
    phone_mobile,
    address,
    city,
    state,
    postalcode,
    moen_install_active_date,
    paired_date,
    is_paired,
    last_online_date,
    water_usage_last_month,
    vendor_id,
    vendor_name,
    vendor_install_date,
    src,
    who_installed,
    pending_cancellation,
    delivered,
    frontdoor_status,
    frontdoor_orig_status,
    bkcc,
    rec_src,
    CASE
        WHEN who_installed = '3rd party' THEN who_installed
        WHEN pending_cancellation = 'Pending Cancel' THEN pending_cancellation
        WHEN order_status = 'cancelled/returned'
            AND frontdoor_status <> 'Successful Installation'
        THEN 'Order Cancelled'
        WHEN frontdoor_status IS NULL THEN delivered
        ELSE frontdoor_status
    END AS moen_status
FROM status_layer2
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY
        order_id,
        sku,
        order_line_id,
        COALESCE(orig_order_tag, '_no_tag_'),
        COALESCE(serial_id, '')
    ORDER BY
        vendor_install_date DESC NULLS LAST,
        moen_install_active_date DESC NULLS LAST,
        frontdoor_status ASC NULLS LAST,
        src ASC NULLS LAST
) = 1