SELECT * FROM (
    {{ check_not_null_v2(
        'dim_device_account',
        [
            'DEVICE_ACCOUNT_BK',
            'ACCOUNT_ID',
            'BKCC',
            'REC_SRC'
        ],
        'BKCC',
        'Leaking_Water'
    ) }}
)