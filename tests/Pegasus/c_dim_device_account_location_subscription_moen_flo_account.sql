SELECT * FROM (
    {{ check_not_null_v2(
        'dim_device_account_location_subscription',
        [
            'DEVICE_ACCOUNT_BK',
            'DEVICE_LOCATION_BK',
            'ACCOUNT_ID',
            'PROVIDER_CUSTOMER_ID',
            'BKCC',
            'REC_SRC'
        ],
        'BKCC',
        'Leaking_Water'
    ) }}
)