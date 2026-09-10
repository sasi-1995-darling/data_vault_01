SELECT * FROM (
    {{ check_column_data_type(
        'fact_incident_false_alarm_device_period',
        [
            ('DEVICE_ID', 'TEXT'),
            ('PERIOD_TYPE', 'TEXT'),
            ('PERIOD_START_DATE_KEY', 'NUMBER'),
            ('YEAR_NUM', 'NUMBER'),
            ('QUARTER_NUM', 'NUMBER'),
            ('MONTH_NUM', 'NUMBER'),
            ('TOTAL_ALERT_COUNT', 'NUMBER'),
            ('FALSE_ALARM_COUNT', 'NUMBER'),
            ('BKCC', 'TEXT'),
            ('REC_SRC', 'TEXT')
        ]
    ) }}
)