SELECT * FROM (
    {{ check_not_null_v2(
        'fact_critical_alert_device_event',
        [
            'DEVICE_ID',
            'INCIDENT_ID',
            'INCIDENT_TIMESTAMP',
            'CRITICAL_ALARM_ID',
            'BKCC',
            'REC_SRC'
        ],
        'REC_SRC',
        'US.NOTIFICATION_API.CLEANED_FLO_PROD_NOTIFICATION_API_INCIDENT'
    ) }}
)