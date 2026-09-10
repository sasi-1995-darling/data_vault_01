select * from (
    {{ check_not_null_v2(
        'dim_po_header',
        [
            'po_header_hk',
            'po_header_bk',
            'PO_NUMBER',
            'PO_HEADER_DEL_IND',
            'BKCC',
            'REC_SRC'
        ],
        'BKCC',
        'Hiding_Tiger'
    ) }})
union all
select * from (
    {{ check_not_null_v2(
        'dim_po_header',
        [
            'po_header_hk',
            'po_header_bk',
            'PO_NUMBER',
            'PO_HEADER_DEL_IND',
            'BKCC',
            'REC_SRC'
        ],
        'BKCC',
        'Crouching_Dragon'
    ) }})
union ALL
select * from (
    {{ check_not_null_v2(
        'dim_po_header',
        [
            'po_header_hk',
            'po_header_bk',
            'PO_NUMBER',
            'PO_HEADER_DEL_IND',
            'BKCC',
            'REC_SRC'
        ],
        'BKCC',
        'Kicking_Panda'
    ) }})
union ALL
select * from (
    {{ check_not_null_v2(
        'dim_po_header',
        [
            'po_header_hk',
            'po_header_bk',
            'PO_NUMBER',
            'PO_HEADER_DEL_IND',
            'BKCC',
            'REC_SRC'
        ],
        'BKCC',
        'Swimming_Ocean'
    ) }})
union all
select * from (
    {{ check_not_null_v2(
        'dim_po_header',
        [
            'po_header_hk',
            'po_header_bk',
            'PO_NUMBER',
            'PO_HEADER_DEL_IND',
            'BKCC',
            'REC_SRC'
        ],
        'BKCC',
        'Diving_Sea'
    ) }})
union all
select * from (
    {{ check_not_null_v2(
        'dim_po_header',
        [
            'po_header_hk',
            'po_header_bk',
            'PO_NUMBER',
            'PO_HEADER_DEL_IND',
            'BKCC',
            'REC_SRC'
        ],
        'BKCC',
        'Jumping_River'
    ) }})