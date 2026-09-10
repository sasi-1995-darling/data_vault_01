SELECT * FROM (
    {{ check_not_null_v2(
        'dim_paired_device',
        [
            'PAIRED_DEVICE_BK',
            'ID',
            'BKCC',
            'REC_SRC'
        ],
        'BKCC',
        'Leaking_Water'
    ) }}
)