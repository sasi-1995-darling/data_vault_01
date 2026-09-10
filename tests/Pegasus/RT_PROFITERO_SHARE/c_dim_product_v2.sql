SELECT * FROM (
    {{ check_not_null_v2(
        'dim_product_v2',
        [
            'PRODUCT_BK',
            'BKCC',
            'REC_SRC',
            'CUSTOMER_PRODUCT_ID'
        ],
        'BKCC',
        'grouping_product'
    ) }}
)


