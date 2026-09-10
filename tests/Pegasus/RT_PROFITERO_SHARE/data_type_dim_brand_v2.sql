SELECT * 
FROM (
    {{
        check_column_data_type(
            'dim_brand_v2',
            [
                ('BRAND_BK', 'TEXT'),
                ('FULL_NAME', 'TEXT'),
                ('BKCC', 'TEXT'),
                ('REC_SRC', 'TEXT'),
                ('OWNER', 'TEXT'),
                ('BRAND', 'TEXT'),
                ('SUBBRAND', 'TEXT'),
                ('SUBSUBBRAND', 'TEXT'),
                ('SYSTEM_BRAND', 'TEXT'),
                ('BUSINESS_UNIT', 'TEXT'),
                ('COMPETITOR_IND', 'TEXT')
            ]
        )
    }}
)