SELECT * FROM (
    {{ check_column_data_type(
        'fact_app_active_user_period',
        [
            ('BKCC', 'TEXT'),
            ('REC_SRC', 'TEXT'),
            ('PERIOD_TYPE', 'TEXT'),
            ('PERIOD_START_DATE', 'DATE'),
            ('YEAR', 'NUMBER'),
            ('MONTH', 'NUMBER'),
            ('QUARTER', 'NUMBER'),
            ('PLATFORM', 'TEXT'),
            ('APP_SOURCE', 'TEXT'),
            ('ACTIVE_USER_COUNT', 'NUMBER')
        ]
    ) }}
)