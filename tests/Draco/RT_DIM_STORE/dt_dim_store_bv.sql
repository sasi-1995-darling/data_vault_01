SELECT *
FROM (
    {{
        check_column_data_type(
            'dim_store',
            [
                ('store_key',           'BINARY'),
                ('store_id',            'TEXT'),
                ('store_name',          'TEXT'),
                ('address1',            'TEXT'),
                ('city',                'TEXT'),
                ('state',               'TEXT'),
                ('postal_code',         'TEXT'),
                ('reporting_customer',  'TEXT')
            ]
        )
    }}
)