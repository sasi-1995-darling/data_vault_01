SELECT *
FROM (
    {{
        check_column_data_type(
            'fact_device_event',
            [
                ('PAIRED_DEVICE_BK', 'TEXT'),
                ('DEVICE_LOCATION_BK', 'TEXT'),
                ('BKCC', 'TEXT'),
                ('REC_SRC', 'TEXT'),
                ('EVENT_DESCRIPTION', 'TEXT'),
                ('EVENT', 'NUMBER'),
                ('CREATED_AT', 'TIMESTAMP_TZ'),
                ('SOURCE', 'TEXT')
            ]
        )
    }}
)
