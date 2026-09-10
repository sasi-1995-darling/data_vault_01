SELECT * FROM (
    {{ check_not_null_v2(
        'fact_app_user_engagement_screen',
        [
            'CONSUMER_BK',
            'BKCC',
            'REC_SRC',
            'CONSUMER_HK',
            'SCREEN_TRAIT_ID',
            'SCREEN_TRACKING_ID',
            'SCREEN_NAME',
            'SCREEN_ACTION_TS',
            'PLATFORM'
        ],
        'REC_SRC',
        'US.ANDROID_MOEN.SCREENS'
    ) }}
)
UNION ALL
SELECT * FROM (
    {{ check_not_null_v2(
        'fact_app_user_engagement_screen',
        [
            'CONSUMER_BK',
            'BKCC',
            'REC_SRC',
            'CONSUMER_HK',
            'SCREEN_TRAIT_ID',
            'SCREEN_TRACKING_ID',
            'SCREEN_NAME',
            'SCREEN_ACTION_TS',
            'PLATFORM'
        ],
        'REC_SRC',
        'US.ANDROID_MOEN.TRACKS'
    ) }}
)
UNION ALL
SELECT * FROM (
    {{ check_not_null_v2(
        'fact_app_user_engagement_screen',
        [
            'CONSUMER_BK',
            'BKCC',
            'REC_SRC',
            'CONSUMER_HK',
            'SCREEN_TRAIT_ID',
            'SCREEN_TRACKING_ID',
            'SCREEN_NAME',
            'SCREEN_ACTION_TS',
            'PLATFORM'
        ],
        'REC_SRC',
        'US.IOS_MOEN.SCREENS'
    ) }}
)
UNION ALL
SELECT * FROM (
    {{ check_not_null_v2(
        'fact_app_user_engagement_screen',
        [
            'CONSUMER_BK',
            'BKCC',
            'REC_SRC',
            'CONSUMER_HK',
            'SCREEN_TRAIT_ID',
            'SCREEN_TRACKING_ID',
            'SCREEN_NAME',
            'SCREEN_ACTION_TS',
            'PLATFORM'
        ],
        'REC_SRC',
        'US.IOS_MOEN.TRACKS'
    ) }}
)