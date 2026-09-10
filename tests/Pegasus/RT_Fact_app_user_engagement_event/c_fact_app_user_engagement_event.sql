SELECT * FROM (
    {{ check_not_null_v2(
        'fact_app_user_engagement_event',
        [
            'CONSUMER_BK',
            'BKCC',
            'REC_SRC',
            'CONSUMER_HK',
            'EVENT_TRAIT_ID',
            'EVENT_TRACKING_ID',
            'EVENT_DESCRIPTION',
            'EVENT',
            'EVENT_ACTION_TS',
            'PLATFORM'
        ],
        'REC_SRC',
        'US.ANDROID_MOEN.SCREENS'
    ) }}
)
UNION ALL
SELECT * FROM (
    {{ check_not_null_v2(
        'fact_app_user_engagement_event',
        [
            'CONSUMER_BK',
            'BKCC',
            'REC_SRC',
            'CONSUMER_HK',
            'EVENT_TRAIT_ID',
            'EVENT_TRACKING_ID',
            'EVENT_DESCRIPTION',
            'EVENT',
            'EVENT_ACTION_TS',
            'PLATFORM'
        ],
        'REC_SRC',
        'US.ANDROID_MOEN.TRACKS'
    ) }}
)
UNION ALL
SELECT * FROM (
    {{ check_not_null_v2(
        'fact_app_user_engagement_event',
        [
            'CONSUMER_BK',
            'BKCC',
            'REC_SRC',
            'CONSUMER_HK',
            'EVENT_TRAIT_ID',
            'EVENT_TRACKING_ID',
            'EVENT_DESCRIPTION',
            'EVENT',
            'EVENT_ACTION_TS',
            'PLATFORM'
        ],
        'REC_SRC',
        'US.IOS_MOEN.SCREENS'
    ) }}
)
UNION ALL
SELECT * FROM (
    {{ check_not_null_v2(
        'fact_app_user_engagement_event',
        [
            'CONSUMER_BK',
            'BKCC',
            'REC_SRC',
            'CONSUMER_HK',
            'EVENT_TRAIT_ID',
            'EVENT_TRACKING_ID',
            'EVENT_DESCRIPTION',
            'EVENT',
            'EVENT_ACTION_TS',
            'PLATFORM'
        ],
        'REC_SRC',
        'US.IOS_MOEN.TRACKS'
    ) }}
)