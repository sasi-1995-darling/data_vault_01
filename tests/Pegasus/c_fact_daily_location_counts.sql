SELECT *
FROM (
    {{
        check_not_null_v2(
            'fact_daily_location_counts',
            [
                'BKCC',
                'REC_SRC',
                'DATE_KEY_YYYYMMDD'
            ],
            'BKCC',
            'Leaking_Water'
        )
    }}
)