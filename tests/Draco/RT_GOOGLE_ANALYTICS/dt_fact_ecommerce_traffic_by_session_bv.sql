SELECT *
FROM (
    {{
        check_column_data_type(
            'fact_ecommerce_traffic_by_session',
            [
                ('ecommerce_account_hk', 'BINARY'),
                ('ecommerce_account_bk', 'TEXT'),
                ('ecommerce_property_hk', 'BINARY'),
                ('ecommerce_property_bk', 'TEXT'),
                ('ecommerce_account_country', 'TEXT'),
                ('ecommerce_analytics_service', 'TEXT'),
                ('ecommerce_property_id', 'TEXT'),
                ('ecommerce_property_type', 'TEXT'),
                ('ecommerce_property_timezone', 'TEXT'),
                ('session_date__yyyymmdd', 'NUMBER'),
                ('week_ending_datekey', 'TEXT'),
                ('session_channel_group', 'TEXT'),
                ('sessions', 'NUMBER'),
                ('engagement_rate', 'FLOAT'),
                ('key_events', 'FLOAT'),
                ('total_users', 'NUMBER'),
                ('engaged_sessions', 'NUMBER'),
                ('event_count', 'NUMBER'),
                ('events_per_session', 'NUMBER'),
                ('events_per_engaged_session', 'NUMBER'),
                ('sessions_per_user', 'NUMBER'),
                ('total_revenue', 'FLOAT'),
                ('ecommerce_property_currency_code', 'TEXT'),
                ('rec_src', 'TEXT'),
                ('bkcc', 'TEXT')
            ]
        )
    }}
)