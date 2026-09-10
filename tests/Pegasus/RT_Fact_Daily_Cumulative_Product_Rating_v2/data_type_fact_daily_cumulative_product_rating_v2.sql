
SELECT *
FROM (
    {{
        check_column_data_type(
            'fact_daily_cumulative_product_rating_v2',
            [
                ('PRODUCT_BK', 'TEXT'),
                ('RETAILER_BK', 'TEXT'),
                ('BRAND_BK', 'TEXT'),
                ('BKCC', 'TEXT'),
                ('REC_SRC', 'TEXT'),
                ('DATE_KEY', 'NUMBER'),
                ('CUMULATIVE_STAR_RATING', 'FLOAT'),
                ('CUMULATIVE_REVIEWS', 'NUMBER'),
                ('CUMULATIVE_5_STAR_REVIEWS', 'NUMBER'),
                ('CUMULATIVE_4_STAR_REVIEWS', 'NUMBER'),
                ('CUMULATIVE_3_STAR_REVIEWS', 'NUMBER'),
                ('CUMULATIVE_2_STAR_REVIEWS', 'NUMBER'),
                ('CUMULATIVE_1_STAR_REVIEWS', 'NUMBER'),
                ('INCRE_1_STAR', 'NUMBER'),
                ('INCRE_2_STAR', 'NUMBER'),
                ('INCRE_3_STAR', 'NUMBER'),
                ('INCRE_4_STAR', 'NUMBER'),
                ('INCRE_5_STAR', 'NUMBER'),
                ('SOURCE', 'TEXT'),
                ('COUNTRY', 'TEXT')
            ]
        )
    }}
)
