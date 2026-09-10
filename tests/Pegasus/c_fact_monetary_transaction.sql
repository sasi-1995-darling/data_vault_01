SELECT * FROM (
    {{ check_not_null_v2(
        'fact_monetary_transaction',
        [
            'TRANSACTION_BK',
            'BKCC',
            'REC_SRC',
            'AMOUNT_CENTS',
            'FEE_CENTS',
            'NET_CENTS',
            'AVAILABLE_ON_TS',
            'CREATED_TS',
            'STATUS',
            'TYPE',
            'AMOUNT_USD',
            'FEE_USD',
            'NET_USD',
            'IS_ARR_ELIGIBLE',
            'MONTH_START',
            'YEAR_NUM',
            'MONTH_NUM'
        ],
        'REC_SRC',
        'US.STRIPE_FLOSENSE.BALANCE_TRANSACTION'
    ) }}
)