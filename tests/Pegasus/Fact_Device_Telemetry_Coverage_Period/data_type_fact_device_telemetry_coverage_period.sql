SELECT * FROM (
    {{ check_column_data_type(
        'fact_device_telemetry_coverage_period',
        [
            ('DEVICE_ID', 'TEXT'),
            ('PERIOD_TYPE', 'TEXT'),
            ('PERIOD_START_DATE_KEY', 'NUMBER'),
            ('YEAR_NUM', 'NUMBER'),
            ('QUARTER_NUM', 'NUMBER'),
            ('MONTH_NUM', 'NUMBER'),
            ('TELEMETRY_DAYS', 'NUMBER'),
            ('TELEMETRY_DAYS_PERCENT', 'NUMBER'),
            ('DAYS_IN_PERIOD', 'NUMBER'),
            ('IS_TELEMETRY_QUALIFIED', 'NUMBER'),
            ('BKCC', 'TEXT'),
            ('REC_SRC', 'TEXT')
        ]
    ) }}
)