SELECT *
FROM (
    {{
        check_not_null_v2(
            'fact_competitive_share_weekly',
            [
                'DATE',
                'ASIN',
                'ASIN_KEY',
                'PLATFORM',
                'CATEGORY_NAME',
                'CATEGORY_TYPE',
                'BRAND_ID',
                'BRAND_BK',
                'BRAND_KEY',
                'BUSINESS_UNIT',                
                'BKCC'


            ],
            'BKCC',
            'Sprinting_Cat'
        )
    }}
)
UNION ALL
SELECT *
FROM (
    {{
        check_not_null_v2(
            'fact_competitive_share_weekly',
            [
                'DATE',
                'ASIN',
                'ASIN_KEY',
                'PLATFORM',
                'CATEGORY_NAME',
                'CATEGORY_TYPE',
                'PRODUCT_NAME',
                'MODEL',
                'BRAND_ID',
                'BRAND_BK',
                'BRAND_KEY',
                'BUSINESS_UNIT',                
                'BKCC'
            ],
            'BKCC',
            'Grouping_Brand'
        )
    }}
)