SELECT * 
FROM (
    {{
        check_column_data_type(
            'dim_retailer',
            [
                ('RETAILER_BK', 'TEXT'),
                ('ALIAS', 'TEXT'),
                ('COUNTRY', 'TEXT'),
                ('BKCC', 'TEXT'),
                ('REC_SRC', 'TEXT')
            ]
        )
    }}
)





