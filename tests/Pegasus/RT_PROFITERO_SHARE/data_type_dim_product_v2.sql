SELECT * 
FROM (
    {{
        check_column_data_type(
            'dim_product_v2',
            [
                ('PRODUCT_BK', 'TEXT'),
                ('PRODUCT_NAME', 'TEXT'),
                ('BRAND_ID', 'NUMBER'),
                ('REC_SRC', 'TEXT'),
                ('ROOM_AREA', 'TEXT'),
                ('RPC', 'TEXT'),
                ('FIRE_RESISTANT_ATTR', 'TEXT'),
                ('UPC', 'TEXT'),
                ('MAP_PRICE', 'FLOAT'),
                ('SENTIMENT_SRC', 'TEXT'),
                ('SRC_ID', 'TEXT'),
                ('CUSTOMER_PRODUCT_ID', 'TEXT'),
                ('SMART_ATTR', 'BOOLEAN'),
                ('EAN', 'TEXT'),
                ('LEVEL_1', 'TEXT'),
                ('LEVEL_2', 'TEXT'),
                ('CONNECTED_PRODUCTS_CLASS', 'TEXT'),
                ('CONNECTED_FLAG', 'TEXT'),
                ('PRODUCT_FAMILY', 'TEXT'),
                ('MODEL', 'TEXT')
            ]
        )
    }}
)