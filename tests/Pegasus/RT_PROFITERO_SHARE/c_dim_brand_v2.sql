SELECT * FROM (
    {{ check_not_null_v2(
        'dim_brand_v2',
        [
            'BRAND_BK',
            'FULL_NAME',
            'BKCC',
            'REC_SRC',
            'SYSTEM_BRAND',
            'BUSINESS_UNIT'
        ],
        'BKCC',
        'grouping_brand'
    ) }}
)