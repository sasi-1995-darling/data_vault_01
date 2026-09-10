SELECT * FROM (
    {{ check_not_null_v2(
        'fact_flow_events_device_period',
        [
            'DEVICE_ID',
            'PERIOD_TYPE',
            'PERIOD_START_DATE_KEY',
            'YEAR_NUM',
            'QUARTER_NUM',
            'MONTH_NUM',
            'BKCC',
            'REC_SRC',
            'NUM_FLOW_EVENTS'
        ],
        'REC_SRC',
        'US.FLO_TELEMETRY.FLODETECT_EVENTS_DEVICE_DAILY_AGG'
    ) }}
)