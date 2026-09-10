select * from (
    {{ check_not_null_v2(
        'dim_supplier_site_v2',
        [
            'supplier_bk',
            'mdm_supplier_bk',
            'mdm_supplier_site_bk',
            'mdm_golden_record',
            'mdm_address_type',
            'MDM_SOURCE_LAST_RUN_DATE__YYYYMMDD',
            'mdm_site_status',
            'rec_src',
            'bkcc',
            'mdm_bkcc',
            'mdm_rec_src'
        ],
        'bkcc',
        'Hiding_Tiger'
    ) }})
union all
select * from (
    {{ check_not_null_v2(
        'dim_supplier_site_v2',
        [
            'supplier_bk',
            'mdm_supplier_bk',
            'mdm_supplier_site_bk',
            'mdm_golden_record',
            'mdm_address_type',
            'MDM_SOURCE_LAST_RUN_DATE__YYYYMMDD',
            'mdm_site_status',
            'rec_src',
            'bkcc',
            'mdm_bkcc',
            'mdm_rec_src'
        ],
        'bkcc',
        'Crouching_Dragon'
    ) }})
union all
select * from (
    {{ check_not_null_v2(
        'dim_supplier_site_v2',
        [
            'supplier_bk',
            'mdm_supplier_bk',
            'mdm_supplier_site_bk',
            'mdm_golden_record',
            'mdm_address_type',
            'MDM_SOURCE_LAST_RUN_DATE__YYYYMMDD',
            'mdm_site_status',
            'rec_src',
            'bkcc',
            'mdm_bkcc',
            'mdm_rec_src'
        ],
        'bkcc',
        'Kicking_Panda'
    ) }})