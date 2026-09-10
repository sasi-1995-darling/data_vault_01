SELECT *
FROM (
    {{
        check_column_data_type(
            'fact_pricing_competitive_weekly',
            [
                ('DATE', 'DATE'),
                ('CUSTOMER_PRODUCT_ID', 'TEXT'),
                ('PRODUCT_ID', 'TEXT'),
                ('PRODUCT_BK', 'TEXT'),
                ('PRODUCT_KEY', 'BINARY'),
                ('RETAILER_BK', 'TEXT'),
                ('RETAILER_KEY', 'BINARY'),
                ('DATA_SOURCE', 'TEXT'),
                ('BRAND_BK', 'TEXT'),
                ('BRAND_KEY', 'BINARY'),
                ('AVAILABILITY_PERCENT', 'NUMBER'),
                ('AVERAGE_REGULAR_PRICE', 'FLOAT'),
                ('MINIMUM_REGULAR_PRICE', 'FLOAT'),
                ('MAXIMUM_REGULAR_PRICE', 'FLOAT'),
                ('MODE_REGULAR_PRICE', 'FLOAT'),
                ('AVERAGE_PROMOTION_PRICE', 'FLOAT'),
                ('MINIMUM_PROMOTION_PRICE', 'FLOAT'),
                ('MAXIMUM_PROMOTION_PRICE', 'FLOAT'),
                ('MODE_PROMOTION_PRICE', 'FLOAT')
            ]
        )
    }}
)