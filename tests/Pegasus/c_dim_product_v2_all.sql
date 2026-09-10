SELECT * FROM (
    {{ check_not_null_v2(
        'dim_product_v2',
        [
            'PRODUCT_BK',
            'CUSTOMER_PRODUCT_ID',
            'BKCC',
            'REC_SRC',
            'CONNECTED_FLAG'
        ],
        'BKCC',
        'Flying_Sausage'
    ) }}
)
UNION ALL
SELECT * FROM (
    {{ check_not_null_v2(
        'dim_product_v2',
        [
            'PRODUCT_BK',
            'CUSTOMER_PRODUCT_ID',
            'BKCC',
            'REC_SRC',
            'CONNECTED_FLAG'
        ],
        'BKCC',
        'Reviewing_Ballon'
    ) }}
)
UNION ALL
SELECT * FROM (
    {{ check_not_null_v2(
        'dim_product_v2',
        [
            'PRODUCT_BK',
            'CUSTOMER_PRODUCT_ID',
            'BKCC',
            'REC_SRC',
            'CONNECTED_FLAG'
        ],
        'BKCC',
        'Grouping_Brand'
    ) }}
)
UNION ALL
SELECT * FROM (
    {{ check_not_null_v2(
        'dim_product_v2',
        [
            'PRODUCT_BK',
            'CUSTOMER_PRODUCT_ID',
            'BKCC',
            'REC_SRC',
            'CONNECTED_FLAG'
        ],
        'BKCC',
        'Cackling_Mouth'
    ) }}
)
UNION ALL
SELECT * FROM (
    {{ check_not_null_v2(
        'dim_product_v2',
        [
            'PRODUCT_BK',
            'CUSTOMER_PRODUCT_ID',
            'BKCC',
            'REC_SRC',
            'CONNECTED_FLAG'
        ],
        'BKCC',
        'Leaping_Cricket'
    ) }}
)