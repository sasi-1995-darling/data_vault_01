SELECT *
FROM (
    {{
        primary_key_check(
            'fact_pos_weekly',
            [
                'TRANSACTION_DATE',
                'SKU',
                'ITEM_ID',
                'STORE_ID',
                'REPORTING_CUSTOMER',
                'BRAND',
                'REPORTING_CHANNEL',
                'SKU_STATUS',
                'PRODUCT_DEST_ZIP'
            ]
        )
    }}
)