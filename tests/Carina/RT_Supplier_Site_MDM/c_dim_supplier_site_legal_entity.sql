select * from (
    {{ check_not_null_v2(
        'dim_supplier_site_legal_entity',
        [
            'supplier_bk',
            'mdm_supplier_bk',
            'mdm_supplier_site_bk',
            'mdm_golden_record',
            'mdm_legal_entity_code',
            'MDM_SOURCE_LAST_RUN_DATE__YYYYMMDD',
            'mdm_is_deleted',
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
        'dim_supplier_site_legal_entity',
        [
            'supplier_bk',
            'mdm_supplier_bk',
            'mdm_supplier_site_bk',
            'mdm_golden_record',
            'mdm_legal_entity_code',
            'MDM_SOURCE_LAST_RUN_DATE__YYYYMMDD',
            'mdm_is_deleted',
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
        'dim_supplier_site_legal_entity',
        [
            'supplier_bk',
            'mdm_supplier_bk',
            'mdm_supplier_site_bk',
            'mdm_golden_record',
            'mdm_legal_entity_code',
            'MDM_SOURCE_LAST_RUN_DATE__YYYYMMDD',
            'mdm_is_deleted',
            'rec_src',
            'bkcc',
            'mdm_bkcc',
            'mdm_rec_src'
        ],
        'bkcc',
        'Kicking_Panda'
    ) }})