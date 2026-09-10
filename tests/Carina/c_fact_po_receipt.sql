select * from (
    {{ check_not_null_v2(
        'fact_po_receipt',
        [
            'po_header_hk',
            'item_hk',
            'supplier_hk',
            'plant_hk',
            'legal_entity_hk',
            'po_line_receipt_ind_hk',
            'po_receipt_date__yyyymmdd',
            'po_header_id'
        ],
        'BKCC',
        'Hiding_Tiger'
    ) }})
union all
select * from (
    {{ check_not_null_v2(
        'fact_po_receipt',
        [
            'po_header_hk',
            'item_hk',
            'supplier_hk',
            'plant_hk',
            'legal_entity_hk',
            'po_line_receipt_ind_hk',
            'po_receipt_date__yyyymmdd',
            'po_header_id'
        ],
        'BKCC',
        'Crouching_Dragon'
    ) }})
union ALL
select * from (
    {{ check_not_null_v2(
        'fact_po_receipt',
        [
            'po_header_hk',
            'item_hk',
            'supplier_hk',
            'plant_hk',
            'legal_entity_hk',
            'po_line_receipt_ind_hk',
            'po_receipt_date__yyyymmdd',
            'po_header_id'
        ],
        'BKCC',
        'Swimming_Ocean'
    ) }})
union all
select * from (
    {{ check_not_null_v2(
        'fact_po_receipt',
        [
            'po_header_id',
            'po_line_number',
            'supplier_bk',
            'item_bk',
            'legal_entity_bk',
            'release_number',
            'po_receipt_date__yyyymmdd',
            'po_receipt_quantity',
            'po_receipt_price',
            'po_receipt_value',
            'po_header_hk',
            'item_hk',
            'supplier_hk',
            'plant_hk',
            'legal_entity_hk',
            'po_line_receipt_ind_hk'
        ],
        'REC_SRC',
        'USOHMA.ORCL.E21PRD.POITEM'
    ) }})
union all
select * from (
    {{ check_not_null_v2(
        'fact_po_receipt',
        [
            'po_header_id',
            'po_line_number',
            'supplier_bk',
            'item_bk',
            'legal_entity_bk',
            'po_receipt_date__yyyymmdd',
            'po_receipt_quantity',
            'po_receipt_price',
            'po_receipt_value',
            'po_header_hk',
            'item_hk',
            'supplier_hk',
            'plant_hk',
            'legal_entity_hk',
            'po_line_receipt_ind_hk'
        ],
        'REC_SRC',
        'USWIOC.ORCL.EBSEMTK.MTL_MATERIAL_TRANSACTIONS'
    ) }})
    union all
select * from (
    {{ check_not_null_v2(
        'fact_po_receipt',
        [
            'po_header_id',
            'po_number',
            'po_line_number',
            'transaction_id',
            'supplier_bk',
            'item_bk',
            'legal_entity_bk',
            'po_receipt_date__yyyymmdd',
            'po_receipt_quantity',
            'po_receipt_price',
            'po_receipt_value',
            'po_header_hk',
            'item_hk',
            'supplier_hk',
            'plant_hk',
            'legal_entity_hk',
            'po_line_receipt_ind_hk'
        ],
        'REC_SRC',
        'USCLOUD.ORCL.OCFPRD.INV_MATERIAL_TXNS'
    ) }})