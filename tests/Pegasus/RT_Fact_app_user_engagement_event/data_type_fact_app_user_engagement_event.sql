SELECT * FROM (
    {{ check_column_data_type(
        'fact_app_user_engagement_event',
        [
            ('CONSUMER_BK', 'TEXT'),
            ('BKCC', 'TEXT'),
            ('REC_SRC', 'TEXT'),
            ('CONSUMER_HK', 'BINARY'),
            ('EVENT_DESCRIPTION', 'TEXT'),
            ('EVENT', 'TEXT'),
            ('EVENT_TRAIT_ID', 'TEXT'),
            ('EVENT_TRACKING_ID', 'TEXT'),
            ('PLATFORM', 'TEXT'),
            ('EVENT_ACTION_TS', 'TIMESTAMP_NTZ')
        ]
    ) }}
)