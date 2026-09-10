SELECT * FROM (
    {{ check_column_data_type(
        'fact_critical_alert_device_event',
        [
            ('DEVICE_ID', 'TEXT'),
            ('USER_ID', 'TEXT'),
            ('INCIDENT_ID', 'TEXT'),
            ('INCIDENT_TIMESTAMP', 'TIMESTAMP_NTZ'),
            ('CRITICAL_ALARM_ID', 'NUMBER'),
            ('SHUTOFF_ID', 'TEXT'),
            ('SHUTOFF_TIMESTAMP', 'TIMESTAMP_NTZ'),
            ('VALVE_OPEN_ID', 'TEXT'),
            ('VALVE_OPEN_TYPE', 'TEXT'),
            ('VALVE_OPEN_TIMESTAMP', 'TIMESTAMP_NTZ'),
            ('FEEDBACK_NORMAL', 'BOOLEAN'),
            ('PLUMBING_FAILURE', 'NUMBER'),
            ('PLUMBING_FAILURE_OTHER', 'TEXT'),
            ('FEEDBACK_LABEL', 'NUMBER'),
            ('FEEDBACK_TIMESTAMP', 'TIMESTAMP_NTZ'),
            ('BKCC', 'TEXT'),
            ('REC_SRC', 'TEXT')
        ]
    ) }}
)