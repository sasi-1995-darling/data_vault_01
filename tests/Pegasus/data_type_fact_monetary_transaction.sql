SELECT * FROM (
    {{ check_column_data_type(
        'fact_monetary_transaction',
        [
            ('TRANSACTION_BK', 'TEXT'),
            ('BKCC', 'TEXT'),
            ('REC_SRC', 'TEXT'),
            ('AMOUNT_CENTS', 'NUMBER'),
            ('FEE_CENTS', 'NUMBER'),
            ('NET_CENTS', 'NUMBER'),
            ('AVAILABLE_ON_TS', 'TIMESTAMP_TZ'),
            ('CREATED_TS', 'TIMESTAMP_TZ'),
            ('DESCRIPTION', 'TEXT'),
            ('STATUS', 'TEXT'),
            ('TYPE', 'TEXT'),
            ('AMOUNT_USD', 'NUMBER'),
            ('FEE_USD', 'NUMBER'),
            ('NET_USD', 'NUMBER'),
            ('IS_ARR_ELIGIBLE', 'NUMBER'),
            ('MONTH_START', 'TIMESTAMP_TZ'),
            ('YEAR_NUM', 'NUMBER'),
            ('MONTH_NUM', 'NUMBER')
        ]
    ) }}
)