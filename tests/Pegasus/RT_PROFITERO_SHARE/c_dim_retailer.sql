SELECT * FROM (
    {{ check_not_null_v2(
        'dim_retailer',
        [
            'RETAILER_BK',
            'BKCC',
            'REC_SRC'
        ],
        'BKCC',
        'grouping_retailer'
    ) }}
)