SELECT *
FROM (
    {{
        check_column_data_type(
            'fact_dtc_order_line',
            [
                ('ORDER_HEADER_KEY',       'BINARY'),
                ('ORDER_HEADER_BK',        'TEXT'),
                ('ORDER_ID',               'NUMBER'),
                ('ORDER_LINE_KEY',         'BINARY'),
                ('ORDER_LINE_BK',          'TEXT'),
                ('ORDER_LINE_ID',          'NUMBER'),
                ('ORDER_LINE_NUMBER',      'NUMBER'),
                ('REFUND_LINE_RECORD_ID',  'NUMBER'),
                ('ADJUSTMENT_ID',          'NUMBER'),
                ('BASE_MATERIAL_KEY',      'BINARY'),
                ('BASE_MATERIAL',          'TEXT'),
                ('ITEM_KEY',               'BINARY'),
                ('ITEM_NUMBER',            'TEXT'),
                ('SKU',                    'NUMBER'),
                ('VARIANT_ID',             'NUMBER'),
                ('PRICE',                  'FLOAT'),
                ('LINE_DOLLARS',           'FLOAT'),
                ('LINE_QUANTITY',          'FLOAT'),
                ('CREATED_DATE_KEY',       'NUMBER'),
                ('ORIGIN',                 'TEXT'),
                ('STORE',                  'TEXT'),
                ('REC_SRC',                'TEXT'),
                ('BKCC',                   'TEXT')

            ]
        )
    }}
)