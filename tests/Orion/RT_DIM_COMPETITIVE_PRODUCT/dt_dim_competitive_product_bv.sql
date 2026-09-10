SELECT *
FROM (
    {{
        check_column_data_type(
            'dim_competitive_product',
            [
                ('COMPETITIVE_PRODUCT_HK', 'BINARY'),
                ('COMPETITIVE_PRODUCT_BK', 'TEXT'),
                ('RETAILER_HK', 'BINARY'),
                ('RETAILER_BK', 'TEXT'),
                ('RANKING_PRODUCT_ID', 'NUMBER'),
                ('RPC', 'TEXT'),
                ('EAN', 'TEXT'),
                ('UPC', 'TEXT'),
                ('MODEL', 'TEXT'),
                ('URL', 'TEXT'),
                ('SOURCE', 'TEXT'),
                ('BKCC', 'TEXT')
            ]
        )
    }}
)