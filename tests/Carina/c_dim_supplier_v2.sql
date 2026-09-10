select * from (
    {{ check_not_null_v2(
        'dim_supplier_v2',
        [
            'supplier_hk',
            'supplier_bk',
            'bkcc',
            'SUPPLIER_NUMBER',
            'supplier_name_1',
            'is_deleted',
            'rec_src'
        ],
        'BKCC',
        'Hiding_Tiger'
    ) }})
union all
select * from (
    {{ check_not_null_v2(
        'dim_supplier_v2',
        [
            'supplier_hk',
            'supplier_bk',
            'bkcc',
            'SUPPLIER_NUMBER',
            'supplier_name_1',
            'is_deleted',
            'rec_src'
        ],
        'BKCC',
        'Crouching_Dragon'
    ) }})
union all
select * from (
    {{ check_not_null_v2(
        'dim_supplier_v2',
        [
            'supplier_hk',
            'supplier_bk',
            'bkcc',
            'SUPPLIER_NUMBER',
            'supplier_name_1',
            'is_deleted',
            'rec_src'
        ],
        'BKCC',
        'Kicking_Panda'
    ) }})
union all
select * from (
    {{ check_not_null_v2(
        'dim_supplier_v2',
        [
            'supplier_hk',
            'supplier_bk',
            'bkcc',
            'SUPPLIER_NUMBER',
            'supplier_name_1',
            'is_deleted',
            'rec_src'
        ],
        'BKCC',
        'Swimming_Ocean'
    ) }})
union all
select * from (
    {{ check_not_null_v2(
        'dim_supplier_v2',
        [
            'supplier_hk',
            'supplier_bk',
            'bkcc',
            'SUPPLIER_NUMBER',
            'supplier_name_1',
            'is_deleted',
            'rec_src'
        ],
        'BKCC',
        'Diving_Sea'
    ) }})