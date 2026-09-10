SELECT *
FROM (
    {{
        check_column_data_type(
            'fact_device_telemetry',
            [
                ('PAIRED_DEVICE_BK', 'TEXT'),
                ('DEVICE_BK', 'TEXT'),
                ('BKCC', 'TEXT'),
                ('REC_SRC', 'TEXT'),
                ('AGGREGATE_DATE', 'DATE'),
                ('GALLONS', 'FLOAT'),
                ('MAX_GPM', 'FLOAT'),
                ('MIN_PRESSURE', 'FLOAT'),
                ('MAX_PRESSURE', 'FLOAT'),
                ('AVG_PRESSURE', 'FLOAT'),
                ('MIN_TEMPERATURE', 'NUMBER'),
                ('MAX_TEMPERATURE', 'NUMBER'),
                ('AVG_TEMPERATURE', 'FLOAT'),
                ('RECORDS', 'NUMBER'),
                ('FLOW_RECORDS', 'NUMBER'),
                ('AVG_NIGHT_TEMPERATURE', 'FLOAT'),
                ('CREATED_AT', 'TIMESTAMP_NTZ'),
                ('UPDATED_AT', 'TIMESTAMP_NTZ'),
                ('MEDIAN_GPS', 'FLOAT'),
                ('P_STATIC', 'FLOAT')
            ]
        )
    }}
)