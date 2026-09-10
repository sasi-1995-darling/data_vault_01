select * from (
    {{ check_not_null_v2(
        'dim_po_line_receipt_ind',
        [
            'PO_LINE_RECEIPT_IND_HK',
            'BKCC',
            'REC_SRC'
        ],
        'BKCC',
        'Hiding_Tiger'
    ) }})
union all
select * from (
    {{ check_not_null_v2(
        'dim_po_line_receipt_ind',
        [
            'PO_LINE_RECEIPT_IND_HK',
            'BKCC',
            'REC_SRC'
        ],
        'BKCC',
        'Crouching_Dragon'
    ) }})
union all
select * from (
    {{ check_not_null_v2(
        'dim_po_line_receipt_ind',
        [
            'PO_LINE_RECEIPT_IND_HK',
            'BKCC',
            'REC_SRC'
        ],
        'BKCC',
        'Swimming_Ocean'
    ) }})