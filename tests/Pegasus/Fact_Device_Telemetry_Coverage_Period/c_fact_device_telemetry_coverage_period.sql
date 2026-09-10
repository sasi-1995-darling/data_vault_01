SELECT * FROM (
    {{ check_not_null_v2(
        'fact_device_telemetry_coverage_period',
        [
            'DEVICE_ID',
            'PERIOD_TYPE',
            'PERIOD_START_DATE_KEY',
            'YEAR_NUM',
            'QUARTER_NUM',
            'MONTH_NUM',
            'TELEMETRY_DAYS',
            'DAYS_IN_PERIOD',
            'TELEMETRY_DAYS_PERCENT',
            'BKCC',
            'REC_SRC',
            'IS_TELEMETRY_QUALIFIED'
        ],
        'REC_SRC',
        'US.FLO_TELEMETRY.FLO_DEVICE_DAILY'
    ) }}
)



