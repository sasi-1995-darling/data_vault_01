select * from (
    {{ check_not_null_v2(
        'dim_supplier_v3',
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
        'dim_supplier_v3',
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
        'dim_supplier_v3',
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
        'dim_supplier_v3',
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
        'dim_supplier_v3',
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
union all
select * from (
    {{ check_not_null_v2(
        'dim_supplier_v3',
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
        'Jumping_River'
    ) }})
union all
select * from (
    {{ check_not_null_v2(
        'dim_supplier_v3',
        [
            'supplier_bk',
            'mdm_supplier_bk',
            'mdm_supplier_name',
            'mdm_supplier_status',
            'MDM_SOURCE_CREATION_DATE__YYYYMMDD',
            'MDM_SOURCE_LAST_UPDATE_DATE__YYYYMMDD',
            'mdm_is_deleted',
            'mdm_source_pkey',
            'supplier_number',
            'supplier_name_1',
            'rec_src',
            'bkcc',
            'mdm_rec_src',
            'mdm_bkcc'
        ],
        'mdm_golden_record',
        'Y'
    ) }})
union all
select * from (
    {{ check_not_null_v2(
        'dim_supplier_v3',
        [
            'supplier_bk',
            'supplier_number',
            'supplier_name_1',
            'parent_supplier_key',
            'parent_supplier_name',
            'IS_DELETED',
            'rec_src',
            'bkcc'
        ],
        'mdm_golden_record',
        'N'
    ) }})