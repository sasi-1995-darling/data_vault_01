SELECT *
FROM (
    {{
        check_column_data_type(
            'dim_device_inventory',
            [
                ('PAIRED_DEVICE_BK', 'TEXT'),
                ('DEVICE_BK', 'TEXT'),
                ('BKCC', 'TEXT'),
                ('REC_SRC', 'TEXT'),
                ('SKU', 'TEXT'),
                ('MFG_NUMBER', 'TEXT'),
                ('SERIAL_NUMBER', 'TEXT'),
                ('PALLET_ID', 'TEXT'),
                ('ORIG_FW_VER', 'TEXT'),
                ('SHEET_NUMBER', 'TEXT'),
                ('VTECH_CARTON', 'TEXT'),
                ('TIN', 'TEXT'),
                ('NEW_SERIAL_NUMBER', 'TEXT'),
                ('REMARK', 'TEXT')
            ]
        )
    }}
)