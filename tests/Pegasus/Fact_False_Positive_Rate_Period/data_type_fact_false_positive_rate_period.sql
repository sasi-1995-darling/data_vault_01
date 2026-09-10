SELECT * FROM (
    {{ check_column_data_type(
        'fact_false_positive_rate_period',
        [
            ('PERIOD_TYPE', 'TEXT'),
            ('PERIOD_START_DATE_KEY', 'NUMBER'),
            ('YEAR_NUM', 'NUMBER'),
            ('QUARTER_NUM', 'NUMBER'),
            ('MONTH_NUM', 'NUMBER'),
            ('QUALIFIED_DEVICE_COUNT', 'NUMBER'),
            ('FALSE_ALARM_COUNT', 'NUMBER'),
            ('TOTAL_ALERT_COUNT', 'NUMBER'),
            ('NUM_FLOW_EVENTS', 'NUMBER'),
            ('FALSE_POSITIVE_RATE', 'NUMBER'),
            ('BKCC', 'TEXT'),
            ('REC_SRC', 'TEXT')
        ]
    ) }}
)
