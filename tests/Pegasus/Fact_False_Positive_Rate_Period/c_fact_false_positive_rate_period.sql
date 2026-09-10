SELECT * FROM (
    {{ check_not_null_v2(
        'fact_false_positive_rate_period',
        [
            'PERIOD_TYPE',
            'PERIOD_START_DATE_KEY',
            'YEAR_NUM',
            'QUARTER_NUM',
            'MONTH_NUM',
            'QUALIFIED_DEVICE_COUNT',
            'FALSE_ALARM_COUNT',
            'TOTAL_ALERT_COUNT',
            'NUM_FLOW_EVENTS',
            'BKCC',
            'REC_SRC'
        ],
        'REC_SRC',
        'US.FLO_TELEMETRY.FLODETECT_EVENTS_DEVICE_DAILY_AGG'
    ) }}
)