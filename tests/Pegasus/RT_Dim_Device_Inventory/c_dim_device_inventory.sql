SELECT *
FROM (
    {{
        check_not_null_v2(
            'dim_device_inventory',
            [
                'PAIRED_DEVICE_BK',
                'DEVICE_BK',
                'BKCC',
                'REC_SRC',
                'SERIAL_NUMBER',
                'SHEET_NUMBER'
            ],
            'REC_SRC',
            'US.FLO_DYNAMODB.PROD_ICD'
        )
    }}
)