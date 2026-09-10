SELECT *
FROM (
    {{
        check_column_data_type(
            'fact_daily_location_counts',
            [
                ('BKCC', 'TEXT'),
                ('REC_SRC', 'TEXT'),
                ('DATE_KEY_YYYYMMDD', 'NUMBER'),
                ('LOCATIONS_TO_DATE', 'NUMBER'),
                ('SWS_ONLY_LOCATIONS', 'NUMBER'),
                ('SWD_ONLY_LOCATIONS', 'NUMBER'),
                ('SWS_AND_SWD_LOCATIONS', 'NUMBER'),
                ('FLO_PROTECT_LOCATIONS', 'NUMBER')
            ]
        )
    }}
)