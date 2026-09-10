SELECT * FROM (
    {{ check_not_null_v2(
        'fact_incident_false_alarm_device_period',
        [
            'DEVICE_ID',
            'BKCC',
            'REC_SRC',
            'PERIOD_TYPE',
            'PERIOD_START_DATE_KEY',
            'YEAR_NUM',
            'QUARTER_NUM',
            'MONTH_NUM',
            'TOTAL_ALERT_COUNT',
            'FALSE_ALARM_COUNT'
        ],
        'REC_SRC',
        'US.FLO_PROD.INCIDENTS_ALERT_FEEDBACK'
    ) }}
)
