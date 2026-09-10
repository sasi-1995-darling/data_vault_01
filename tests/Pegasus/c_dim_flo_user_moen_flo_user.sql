SELECT * FROM (
    {{ check_not_null_v2(
        'dim_flo_user',
        [
            'FLO_USER_BK',
            'DEVICE_ACCOUNT_BK',
            'BKCC',
            'REC_SRC'
        ],
        'BKCC',
        'Leaking_Water'
    ) }}
)