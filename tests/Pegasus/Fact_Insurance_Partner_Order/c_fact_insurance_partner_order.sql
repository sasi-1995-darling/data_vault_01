SELECT * FROM (
    {{ check_not_null_v2(
        'fact_insurance_partner_order',
        [
            'ORDER_ID',
            'SKU',
            'ORDER_LINE_ID',
            'ORIG_ORDER_TAG',
            'ORDER_DATE',
            'ORDER_EMAIL',
            'ORDER_PHONE',
            'MOEN_STATUS'
        ],
        'REC_SRC',
        'US.SHOPIFY_MOEN.PRODUCT_VARIANT'
    ) }}
)