SELECT * FROM (
    {{ check_not_null_v2(
        'fact_installer_order',
        [
            'ORDER_ID',
            'SKU',
            'ORDER_LINE_ID',
            'GRAIN_KEY',
            'BKCC',
            'REC_SRC'
        ],
        'REC_SRC',
        'US.SHOPIFY_MOEN.PRODUCT_VARIANT'
    ) }}
)