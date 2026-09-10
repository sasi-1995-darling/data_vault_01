select * from (
    {{ check_not_null_v2(
        'dim_supplier_payment_terms',
        [
            'START_DATE__YYYYMMDD',
            'IS_DELETED',
            'REC_SRC',
            'PURCHASING_ORG_BK',
            'BKCC',
            'SUPPLIER_HK',
            'END_DATE__YYYYMMDD',
            'SUPPLIER_PAYMENT_TERM_HK',
            'SUPPLIER_BK'
        ],
        'BKCC',
        'Hiding_Tiger'
    ) }})
    union all
    select * from (
    {{ check_not_null_v2(
        'dim_supplier_payment_terms',
        [
            'START_DATE__YYYYMMDD',
            'IS_DELETED',
            'REC_SRC',
            'PURCHASING_ORG_BK',
            'BKCC',
            'SUPPLIER_HK',
            'END_DATE__YYYYMMDD',
            'SUPPLIER_PAYMENT_TERM_HK',
            'SUPPLIER_BK'
        ],
        'BKCC',
        'Diving_Sea'
    ) }})
    union all
    select * from (
    {{ check_not_null_v2(
        'dim_supplier_payment_terms',
        [
            'START_DATE__YYYYMMDD',
            'IS_DELETED',
            'REC_SRC',
            'PURCHASING_ORG_BK',
            'BKCC',
            'SUPPLIER_HK',
            'END_DATE__YYYYMMDD',
            'SUPPLIER_PAYMENT_TERM_HK',
            'SUPPLIER_BK'
        ],
        'BKCC',
        'Crouching_Dragon'
    ) }})
    union all
    select * from (
    {{ check_not_null_v2(
        'dim_supplier_payment_terms',
        [
            'START_DATE__YYYYMMDD',
            'IS_DELETED',
            'REC_SRC',
            'PURCHASING_ORG_BK',
            'BKCC',
            'SUPPLIER_HK',
            'END_DATE__YYYYMMDD',
            'SUPPLIER_PAYMENT_TERM_HK',
            'SUPPLIER_BK'
        ],
        'BKCC',
        'Jumping_River'
    ) }})
    union all
    select * from (
    {{ check_not_null_v2(
        'dim_supplier_payment_terms',
        [
            'START_DATE__YYYYMMDD',
            'IS_DELETED',
            'REC_SRC',
            'PURCHASING_ORG_BK',
            'BKCC',
            'SUPPLIER_HK',
            'END_DATE__YYYYMMDD',
            'SUPPLIER_PAYMENT_TERM_HK',
            'SUPPLIER_BK'
        ],
        'BKCC',
        'Kicking_Panda'
    ) }})
    union all
    select * from (
    {{ check_not_null_v2(
        'dim_supplier_payment_terms',
        [
            'START_DATE__YYYYMMDD',
            'IS_DELETED',
            'REC_SRC',
            'PURCHASING_ORG_BK',
            'BKCC',
            'SUPPLIER_HK',
            'END_DATE__YYYYMMDD',
            'SUPPLIER_PAYMENT_TERM_HK',
            'SUPPLIER_BK'
        ],
        'BKCC',
        'Swimming_Ocean'
    ) }})
    