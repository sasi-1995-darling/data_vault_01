SELECT * FROM (
    {{
        check_not_null_v2(
            'fact_pos_weekly',
            [
                'REPORTING_CUSTOMER',
                'BRAND',
                'STORE_ID',
                'TRANSACTION_DATE',
                'TRANSACTION_DATEKEY',
                'REPORTING_CHANNEL',
                'SKU',
                'CAST(STORE_KEY AS VARCHAR)'
            ],
            'BRAND',
            'SENTRYSAFE'
        )
    }}
)
UNION ALL

-- Brand: MASTER LOCK
SELECT *
FROM (
    {{
        check_not_null_v2(
            'fact_pos_weekly',
            [
                'REPORTING_CUSTOMER',
                'BRAND',
                'STORE_ID',
                'TRANSACTION_DATE',
                'TRANSACTION_DATEKEY',
                'REPORTING_CHANNEL',
                'SKU',
                'CAST(STORE_KEY AS VARCHAR)'
            ],
            'BRAND',
            'MASTER LOCK'
        )
    }}
)
UNION ALL

-- Brand: MOEN
SELECT *
FROM (
    {{
        check_not_null_v2(
            'fact_pos_weekly',
            [
                'REPORTING_CUSTOMER',
                'BRAND',
                'STORE_ID',
                'TRANSACTION_DATE',
                'TRANSACTION_DATEKEY',
                'REPORTING_CHANNEL',
                'CAST(STORE_KEY AS VARCHAR)'
            ],
            'BRAND',
            'MOEN'
        )
    }}
)
UNION ALL

-- Brand: LARSON
SELECT *
FROM (
    {{
        check_not_null_v2(
            'fact_pos_weekly',
            [
               'REPORTING_CUSTOMER',
                'BRAND',
                'STORE_ID',
                'TRANSACTION_DATE',
                'TRANSACTION_DATEKEY',
                'REPORTING_CHANNEL',
                'SKU',
                'CAST(STORE_KEY AS VARCHAR)'
            ],
            'BRAND',
            'LARSON'
        )
    }}
)
UNION ALL

-- Brand: THERMA-TRU
SELECT *
FROM (
    {{
        check_not_null_v2(
            'fact_pos_weekly',
            [
               'REPORTING_CUSTOMER',
                'BRAND',
                'STORE_ID',
                'TRANSACTION_DATE',
                'TRANSACTION_DATEKEY',
                'REPORTING_CHANNEL',
                'SKU',
                'CAST(STORE_KEY AS VARCHAR)'
            ],
            'BRAND',
            'THERMA-TRU'
        )
    }}
)
UNION ALL

-- Brand: FIBERON
SELECT *
FROM (
    {{
        check_not_null_v2(
            'fact_pos_weekly',
            [
               'REPORTING_CUSTOMER',
                'BRAND',
                'STORE_ID',
                'TRANSACTION_DATE',
                'TRANSACTION_DATEKEY',
                'REPORTING_CHANNEL',
                'SKU',
                'CAST(STORE_KEY AS VARCHAR)'
            ],
            'BRAND',
            'FIBERON'
        )
    }}
)
