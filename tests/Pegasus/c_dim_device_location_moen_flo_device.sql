SELECT * FROM (
    {{ check_not_null_v2(
        'dim_device_location',
        [
            'DEVICE_LOCATION_BK',
            'LOCATION_ID',
            'ACCOUNT_ID',
            'BKCC',
            'REC_SRC'
        ],
        'BKCC',
        'Leaking_Water'
    ) }}
)