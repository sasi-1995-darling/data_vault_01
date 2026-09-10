SELECT * FROM (
    {{ check_column_data_type(
        'dim_device_status',
        [
            ('PAIRED_DEVICE_BK', 'TEXT'),
            ('DEVICE_BK', 'TEXT'),
            ('BKCC', 'TEXT'),
            ('REC_SRC', 'TEXT'),
            ('MAKE', 'TEXT'),
            ('MODEL', 'TEXT'),
            ('IS_CONNECTED', 'BOOLEAN'),
            ('IS_ONLINE', 'BOOLEAN'),
            ('LAST_CLOUD_CONTACT_TS', 'TIMESTAMP_TZ'),
            ('CREATED_TIME', 'TIMESTAMP_TZ'),
            ('UPDATED_TIME', 'TIMESTAMP_TZ')
        ]
    ) }}
)
