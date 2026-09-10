SELECT * FROM (
    {{ check_column_data_type(
        'fact_flow_events_device_period',
        [
            ('DEVICE_ID', 'TEXT'),
            ('PERIOD_TYPE', 'TEXT'),
            ('PERIOD_START_DATE_KEY', 'NUMBER'),
            ('YEAR_NUM', 'NUMBER'),
            ('QUARTER_NUM', 'NUMBER'),
            ('MONTH_NUM', 'NUMBER'),
            ('NUM_FLOW_EVENTS', 'NUMBER'),
            ('BKCC', 'TEXT'),
            ('REC_SRC', 'TEXT')
        ]
    ) }}
)