SELECT *
FROM (
    {{
        check_column_data_type(
            'fact_pos_weekly',
            [
                ('REPORTING_CUSTOMER', 'TEXT'),
                ('BRAND', 'TEXT'),
                ('ITEM_ID', 'BINARY'),
                ('STORE_ID', 'TEXT'),
                ('TRANSACTION_DATE', 'TIMESTAMP_NTZ'),
                ('TRANSACTION_DATEKEY', 'NUMBER'),
                ('REPORTING_CHANNEL', 'TEXT'),
                ('PRODUCT_DEST_ZIP', 'TEXT'),
                ('SKU', 'TEXT'),
                ('SKU_STATUS', 'TEXT'),
                ('POS_QTY', 'FLOAT'),
                ('CONSUMER_DOLLARS', 'FLOAT'),
                ('GROSS_DOLLARS', 'FLOAT'),
                ('STORE_KEY', 'BINARY'),
                ('INV_QTY', 'FLOAT'),
                ('INV_CONSUMER_DOLLARS', 'FLOAT')
            ]
        )
    }}
)
