SELECT * FROM (
    {{ check_not_null_v2(
        'fact_app_active_user_period',
        [
            'BKCC',
            'REC_SRC',
            'PERIOD_TYPE',
            'PERIOD_START_DATE',
            'YEAR',
            'MONTH',
            'QUARTER',
            'PLATFORM',
            'APP_SOURCE',
            'ACTIVE_USER_COUNT'
        ],
        'REC_SRC',
        'US.ANDROID.SCREENS'
    ) }}
)
UNION ALL
SELECT * FROM (
    {{ check_not_null_v2(
        'fact_app_active_user_period',
        [
            'BKCC',
            'REC_SRC',
            'PERIOD_TYPE',
            'PERIOD_START_DATE',
            'YEAR',
            'MONTH',
            'QUARTER',
            'PLATFORM',
            'APP_SOURCE',
            'ACTIVE_USER_COUNT'
        ],
        'REC_SRC',
        'US.ANDROID.TRACKS'
    ) }}
)
UNION ALL
SELECT * FROM (
    {{ check_not_null_v2(
        'fact_app_active_user_period',
        [
            'BKCC',
            'REC_SRC',
            'PERIOD_TYPE',
            'PERIOD_START_DATE',
            'YEAR',
            'MONTH',
            'QUARTER',
            'PLATFORM',
            'APP_SOURCE',
            'ACTIVE_USER_COUNT'
        ],
        'REC_SRC',
        'US.ANDROID_MOEN.SCREENS'
    ) }}
)
UNION ALL
SELECT * FROM (
    {{ check_not_null_v2(
        'fact_app_active_user_period',
        [
            'BKCC',
            'REC_SRC',
            'PERIOD_TYPE',
            'PERIOD_START_DATE',
            'YEAR',
            'MONTH',
            'QUARTER',
            'PLATFORM',
            'APP_SOURCE',
            'ACTIVE_USER_COUNT'
        ],
        'REC_SRC',
        'US.ANDROID_MOEN.TRACKS'
    ) }}
)
UNION ALL
SELECT * FROM (
    {{ check_not_null_v2(
        'fact_app_active_user_period',
        [
            'BKCC',
            'REC_SRC',
            'PERIOD_TYPE',
            'PERIOD_START_DATE',
            'YEAR',
            'MONTH',
            'QUARTER',
            'PLATFORM',
            'APP_SOURCE',
            'ACTIVE_USER_COUNT'
        ],
        'REC_SRC',
        'US.IOS.SCREENS'
    ) }}
)
UNION ALL
SELECT * FROM (
    {{ check_not_null_v2(
        'fact_app_active_user_period',
        [
            'BKCC',
            'REC_SRC',
            'PERIOD_TYPE',
            'PERIOD_START_DATE',
            'YEAR',
            'MONTH',
            'QUARTER',
            'PLATFORM',
            'APP_SOURCE',
            'ACTIVE_USER_COUNT'
        ],
        'REC_SRC',
        'US.IOS.TRACKS'
    ) }}
)
UNION ALL
SELECT * FROM (
    {{ check_not_null_v2(
        'fact_app_active_user_period',
        [
            'BKCC',
            'REC_SRC',
            'PERIOD_TYPE',
            'PERIOD_START_DATE',
            'YEAR',
            'MONTH',
            'QUARTER',
            'PLATFORM',
            'APP_SOURCE',
            'ACTIVE_USER_COUNT'
        ],
        'REC_SRC',
        'US.IOS_MOEN.SCREENS'
    ) }}
)
UNION ALL
SELECT * FROM (
    {{ check_not_null_v2(
        'fact_app_active_user_period',
        [
            'BKCC',
            'REC_SRC',
            'PERIOD_TYPE',
            'PERIOD_START_DATE',
            'YEAR',
            'MONTH',
            'QUARTER',
            'PLATFORM',
            'APP_SOURCE',
            'ACTIVE_USER_COUNT'
        ],
        'REC_SRC',
        'US.IOS_MOEN.TRACKS'
    ) }}
)