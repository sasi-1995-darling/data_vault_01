SELECT * FROM (
    {{ check_not_null_v2(
        'fact_daily_cumulative_product_rating_v2',
        [
            'PRODUCT_BK',
            'RETAILER_BK',
            'BRAND_BK',
            'BKCC',
            'REC_SRC'
        ],
        'BKCC',
        'Flying_Sausage'
    ) }}
)
UNION ALL
SELECT * FROM (
    {{ check_not_null_v2(
        'fact_daily_cumulative_product_rating_v2',
        [
            'PRODUCT_BK',
            'RETAILER_BK',
            'BRAND_BK',
            'BKCC',
            'REC_SRC'
        ],
        'BKCC',
        'Reviewing_Ballon'
    ) }}
)
UNION ALL
SELECT * FROM (
    {{ check_not_null_v2(
        'fact_daily_cumulative_product_rating_v2',
        [
            'PRODUCT_BK',
            'RETAILER_BK',
            'BRAND_BK',
            'BKCC',
            'REC_SRC'
        ],
        'BKCC',
        'Grouping_Brand'
    ) }}
)
UNION ALL
SELECT * FROM (
    {{ check_not_null_v2(
        'fact_daily_cumulative_product_rating_v2',
        [
            'PRODUCT_BK',
            'RETAILER_BK',
            'BRAND_BK',
            'BKCC',
            'REC_SRC'
        ],
        'BKCC',
        'Cackling_Mouth'
    ) }}
)
UNION ALL
SELECT * FROM (
    {{ check_not_null_v2(
        'fact_daily_cumulative_product_rating_v2',
        [
            'PRODUCT_BK',
            'RETAILER_BK',
            'BRAND_BK',
            'BKCC',
            'REC_SRC'
        ],
        'BKCC',
        'Leaping_Cricket'
    ) }}
)
UNION ALL
SELECT * FROM (
    {{ check_not_null_v2(
        'fact_daily_cumulative_product_rating_v2',
        [
            'PRODUCT_BK',
            'RETAILER_BK',
            'BRAND_BK',
            'BKCC',
            'REC_SRC'
        ],
        'BKCC',
        'Questioning_Minds'
    ) }}
)