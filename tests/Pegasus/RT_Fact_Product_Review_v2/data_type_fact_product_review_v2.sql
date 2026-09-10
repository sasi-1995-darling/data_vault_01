SELECT *
FROM (
    {{
        check_column_data_type(
            'fact_product_review_v2',
            [
                ('PRODUCT_BK', 'TEXT'),
                ('RETAILER_BK', 'TEXT'),
                ('BRAND_BK', 'TEXT'),
                ('BKCC', 'TEXT'),
                ('REC_SRC', 'TEXT'),
                ('REVIEW_DATE_KEY', 'NUMBER'),
                ('REVIEW_TITLE', 'TEXT'),
                ('REVIEW_TEXT', 'TEXT'),
                ('STAR_RATING', 'FLOAT'),
                ('REVIEW_URL', 'TEXT'),
                ('UKEY', 'TEXT'),
                ('AUTHOR', 'TEXT'),
                ('COUNTRY', 'TEXT'),
                ('DB_CREATED_AT_KEY', 'NUMBER'),
                ('UPDATED_AT_DATE_KEY', 'NUMBER'),
                ('MANUFACTURER_COMMENT_TEXT', 'TEXT'),
                ('MANUFACTURER_COMMENT_DATE_KEY', 'NUMBER'),
                ('SOURCE', 'TEXT'),
                ('PRODUCT_ID', 'TEXT'),
                ('IS_DELETED', 'TEXT'),
                ('SENTIMENT_PROCESSED', 'TEXT'),
                ('PURCHASE_SOURCE', 'TEXT')
            ]
        )
    }}
)