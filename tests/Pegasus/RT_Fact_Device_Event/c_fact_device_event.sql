SELECT *
FROM (
    {{
        check_not_null_v2(
            'fact_device_event',
            [
                'PAIRED_DEVICE_BK',
                'DEVICE_LOCATION_BK',
                'BKCC',
                'REC_SRC',
                'EVENT',
                'EVENT_DESCRIPTION',
                'CREATED_AT',
                'SOURCE'
            ],
            'BKCC',
            'Leaking_Water'
        )
    }}
)