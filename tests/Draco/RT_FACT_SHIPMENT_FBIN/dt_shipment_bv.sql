SELECT *
FROM (
    {{
        check_column_data_type(
            'fact_shipment_fbin',
            [
                ('SHIPMENT_ID',            'BINARY'),
                ('CUSTOMER_ID',            'TEXT'),
                ('ITEM_ID',                'BINARY'),
                ('POSTED_DATEKEY',         'TEXT'),
                ('LOCATION_ID',            'TEXT'),
                ('BRAND',                  'TEXT'),
                ('CUSTOMER',               'TEXT'),
                ('KEY_ACCOUNT_NUMBER',     'TEXT'),
                ('CUSTOMER_ACCOUNT_NAME',  'TEXT'),
                ('SALES_ORG',              'TEXT'),
                ('CHANNEL',                'TEXT'),
                ('INVOICED_QTY',           'FLOAT'),
                ('RETURN_QTY',             'FLOAT'),
                ('REVENUE_DOLLARS',        'FLOAT'),
                ('ACTUAL_RETURNS_DOLLARS', 'FLOAT'),
                ('SHIPMENT_TYPE',          'TEXT')
            ]
        )
    }}
)