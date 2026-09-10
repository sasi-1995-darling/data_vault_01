select * from (
    {{ check_not_null_v2(
        'fact_po_item',
        [
            'po_header_id',
            'po_line_number',
            'supplier_bk',
            'legal_entity_bk',
            'PO_CREATION_DATE__YYYYMMDD',
            'net_price',
            'price_unit',
            'item_hk',
            'supplier_hk',
            'PO_LINE_RECEIPT_IND_HK',
            'PURCHASING_RECORD_HK',
            'PURCHASING_ORG_HK'
        ],
        'BKCC',
        'Hiding_Tiger'
    ) }})
union all
select * from (
    {{ check_not_null_v2(
        'fact_po_item',
        [
            'po_header_id',
            'po_line_number',
            'supplier_bk',
            'legal_entity_bk',
            'PO_CREATION_DATE__YYYYMMDD',
            'net_price',
            'price_unit',
            'item_hk',
            'supplier_hk',
            'PO_LINE_RECEIPT_IND_HK',
            'PURCHASING_RECORD_HK',
            'PURCHASING_ORG_HK'
        ],
        'BKCC',
        'Crouching_Dragon'
    ) }})
union all
select * from (
    {{ check_not_null_v2(
        'fact_po_item',
        [
            'po_header_id',
            'po_line_number',
            'supplier_bk',
            'legal_entity_bk',
            'PO_CREATION_DATE__YYYYMMDD',
            'net_price',
            'price_unit',
            'item_hk',
            'supplier_hk',
            'PO_LINE_RECEIPT_IND_HK',
            'PURCHASING_RECORD_HK',
            'PURCHASING_ORG_HK'
        ],
        'BKCC',
        'Swimming_Ocean'
    ) }})
union all
select * from (
    {{ check_not_null_v2(
        'fact_po_item',
        [
            'po_header_id',
            'po_line_number',
            'supplier_bk',
            'item_bk',
            'legal_entity_bk',
            'PO_CREATION_DATE__YYYYMMDD',
            'order_quantity',
            'net_price',
            'price_unit',
            'net_value',
            'item_hk',
            'supplier_hk',
            'PO_LINE_RECEIPT_IND_HK',
            'PURCHASING_RECORD_HK',
            'PURCHASING_ORG_HK'
        ],
        'REC_SRC',
        'USWIOC.ORCL.EBSEMTK.PO_LINES_ALL'
    ) }})
    union all
select * from (
    {{ check_not_null_v2(
        'fact_po_item',
        [
            'po_header_id',
            'po_line_number',
            'supplier_bk',
            'item_bk',
            'legal_entity_bk',
            'PO_CREATION_DATE__YYYYMMDD',
            'order_quantity',
            'net_price',
            'price_unit',
            'net_value',
            'item_hk',
            'supplier_hk',
            'PO_HEADER_HK',
            'LEGAL_ENTITY_HK',
            'PO_LINE_RECEIPT_IND_HK',
            'PURCHASING_RECORD_HK',
            'PURCHASING_ORG_HK',
            'REC_SRC',
            'BKCC'
        ],
        'REC_SRC',
        'USCLOUD.ORCL.OCFPRD.PO_LINES_ALL'
    ) }})