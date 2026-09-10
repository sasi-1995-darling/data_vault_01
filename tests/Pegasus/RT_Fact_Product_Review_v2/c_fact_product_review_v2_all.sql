SELECT * FROM (
    {{ check_not_null_v2(
        'fact_product_review_v2',
        [
            'PRODUCT_BK',
            'RETAILER_BK',
            'BRAND_BK',
            'BKCC',
            'REC_SRC',
            'UKEY',
            'PRODUCT_ID'
        ],
        'BKCC',
        'Reviewing_Ballon'
    ) }}
)
UNION ALL
SELECT * FROM (
    {{ check_not_null_v2(
        'fact_product_review_v2',
        [
            'PRODUCT_BK',
            'RETAILER_BK',
            'BRAND_BK',
            'BKCC',
            'REC_SRC',
            'UKEY',
            'PRODUCT_ID'
        ],
        'BKCC',
        'Flying_Sausage'
    ) }}
)
UNION ALL
SELECT * FROM (
    {{ check_not_null_v2(
        'fact_product_review_v2',
        [
            'PRODUCT_BK',
            'RETAILER_BK',
            'BRAND_BK',
            'BKCC',
            'REC_SRC',
            'UKEY',
            'PRODUCT_ID'
        ],
        'BKCC',
        'Grouping_Brand'
    ) }}
)
UNION ALL
SELECT * FROM (
    {{ check_not_null_v2(
        'fact_product_review_v2',
        [
            'PRODUCT_BK',
            'RETAILER_BK',
            'BRAND_BK',
            'BKCC',
            'REC_SRC',
            'UKEY',
            'PRODUCT_ID'
        ],
        'BKCC',
        'Cackling_Mouth'
    ) }}
)
UNION ALL
SELECT * FROM (
    {{ check_not_null_v2(
        'fact_product_review_v2',
        [
            'PRODUCT_BK',
            'RETAILER_BK',
            'BRAND_BK',
            'BKCC',
            'REC_SRC',
            'UKEY',
            'PRODUCT_ID'
        ],
        'BKCC',
        'Leaping_Cricket'
    ) }}
)
UNION ALL
SELECT * FROM (
    {{ check_not_null_v2(
        'fact_product_review_v2',
        [
            'PRODUCT_BK',
            'RETAILER_BK',
            'BRAND_BK',
            'BKCC',
            'REC_SRC',
            'UKEY',
            'PRODUCT_ID'
        ],
        'BKCC',
        'Questioning_Minds'
    ) }}
)