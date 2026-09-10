select * from (
    {{ check_column_data_type(
        'fact_app_user_engagement_screen',
        [
            ('CONSUMER_BK', 'TEXT'),
            ('BKCC', 'TEXT'),
            ('REC_SRC', 'TEXT'),
            ('CONSUMER_HK', 'BINARY'),
            ('SCREEN_TRAIT_ID', 'TEXT'),
            ('SCREEN_TRACKING_ID', 'TEXT'),
            ('SCREEN_NAME', 'TEXT'),
            ('SCREEN_ACTION_TS', 'TIMESTAMP_NTZ'),
            ('PLATFORM', 'TEXT')
        ]
    ) }}
)