SELECT *
FROM (
    {{
        check_column_data_type(
            'fact_competitive_share_weekly',
            [
                ('DATE', 'DATE'),
                ('ASIN', 'TEXT'),
                ('ASIN_KEY', 'BINARY'),
                ('PLATFORM', 'TEXT'),
                ('SUM_FIRST_PARTY_SALES', 'NUMBER'),
                ('SUM_THIRD_PARTY_SALES', 'NUMBER'),
                ('SUM_TOTAL_SALES', 'NUMBER'),
                ('SUM_FIRST_PARTY_UNITS', 'NUMBER'),
                ('SUM_THIRD_PARTY_UNITS', 'NUMBER'),
                ('SUM_TOTAL_UNITS', 'NUMBER'),
                ('CATEGORY_NAME', 'TEXT'),
                ('CATEGORY_TYPE', 'TEXT'),
                ('PRODUCT_NAME', 'TEXT'),
                ('UPC', 'TEXT'),
                ('MODEL', 'TEXT'),
                ('BRAND_ID', 'TEXT'),
                ('BRAND_BK', 'TEXT'),
                ('BRAND_KEY', 'BINARY'),
                ('MAX_BULK_PRICE', 'NUMBER'),
                ('MAX_BULK_UNIT_THRESHOLD', 'NUMBER'),
                ('MIN_BULK_PRICE', 'NUMBER'),
                ('MIN_BULK_UNIT_THRESHOLD', 'NUMBER'),
                ('UNITS_ON_HAND_MEDIAN', 'NUMBER'),
                ('UNITS_REPLENISHED', 'NUMBER'),
                ('VALUE_ON_HAND', 'NUMBER'),
                ('VALUE_REPLENISHED', 'NUMBER'),
                ('REGION', 'TEXT'),
                ('STATE', 'TEXT'),
                ('HOMEDEPOT_REGION', 'TEXT'),
                ('LOWES_REGION', 'TEXT'),
                ('SOURCE', 'TEXT'),
                ('BKCC', 'TEXT')
            ]
        )
    }}
)