SELECT * FROM (
    {{ check_not_null_v2(
        'dim_device_status',
        [
            'PAIRED_DEVICE_BK',
            'DEVICE_BK',
            'BKCC',
            'REC_SRC',
            'MAKE',
            'MODEL',
            'IS_CONNECTED',
            'IS_ONLINE',
            'LAST_CLOUD_CONTACT_TS',
            'CREATED_TIME',
            'UPDATED_TIME'
        ],
        'REC_SRC',
        'US.FLO_DYNAMODB.PROD_ICD'
    ) }}
)
