select * from (
    {{ check_not_null_v2(
        'fact_open_po_spend_detail',
        [
            'po_header_id',
            'OPEN_PO_HK',
            'po_line_number',
            'po_creation_date__yyyymmdd',
            'volume',
            'spend',
            'BUSINESS_UNIT',
            'plant_bk',
            'legal_entity_bk',
            'po_header_hk',
            'po_item_hk',
            'item_hk',
            'supplier_hk',
			'legal_entity_hk',
            'PURCHASING_RECORD_HK',
            'PURCHASING_ORG_HK',
            'SOURCE'
        ],
        'BKCC',
        'Hiding_Tiger'
    ) }})
union all
select * from (
    {{ check_not_null_v2(
        'fact_open_po_spend_detail',
        [
            'po_header_id',
            'OPEN_PO_HK',
            'po_line_number',
            'po_creation_date__yyyymmdd',
            'volume',
            'spend',
            'BUSINESS_UNIT',
            'plant_bk',
            'legal_entity_bk',
            'po_header_hk',
            'po_item_hk',
            'item_hk',
            'supplier_hk',
			'legal_entity_hk',
            'PURCHASING_RECORD_HK',
            'PURCHASING_ORG_HK',
            'SOURCE'
        ],
        'BKCC',
        'Crouching_Dragon'
    ) }})
union ALL
select * from (
    {{ check_not_null_v2(
        'fact_open_po_spend_summary',
        [
            'PAYMENT_TERMS',
            'DOCUMENT_TYPE',
            'NET_PRICE',
            'ORDER_QTY',
            'VOLUME',
            'SPEND',
            'PLANT_BK',
            'LEGAL_ENTITY_BK',
			'SOURCE',
			'SCHEDULE_LINE_DELIVERY_DATE__YYYYMMDD',
			'ITEM_HK'
        ],
        'BKCC',
        'Hiding_Tiger'
    ) }})
union all
select * from (
    {{ check_not_null_v2(
        'fact_open_po_spend_summary',
        [
            'PAYMENT_TERMS',
            'DOCUMENT_TYPE',
            'NET_PRICE',
            'ORDER_QTY',
            'VOLUME',
            'SPEND',
            'PLANT_BK',
            'LEGAL_ENTITY_BK',
			'SOURCE',
			'SCHEDULE_LINE_DELIVERY_DATE__YYYYMMDD',
			'ITEM_HK'
        ],
        'BKCC',
        'Crouching_Dragon'
    ) }})

    /*
            'item_bk', as confirmed by Sri item bk can be null or blank corresponding to indirect spend 
            */
union all
select * from (
    {{ check_not_null_v2(
        'fact_open_po_spend_detail',
        [
            'po_header_id',
            'OPEN_PO_HK',
            'po_line_number',
            'po_schedule_line_number',
            'schedule_line_delivery_date_key',
            'po_creation_date__yyyymmdd',
            'po_item_uom',
            'order_qty',
            'received_qty',
            'net_price',
            'volume',
            'spend',
            'BUSINESS_UNIT',
            'drvd_opco',
            'opco_item',
            'supplier_number_parent',
            'supplier_name_parent',
            'payment_terms',
            'document_type',
            'plant_bk',
            'legal_entity_bk',
            'po_header_hk',
            'po_item_hk',
            'item_hk',
            'supplier_hk',
			'legal_entity_hk',
            'PURCHASING_RECORD_HK',
            'PURCHASING_ORG_HK',
            'SOURCE'
        ],
        'BKCC',
        'Swimming_Ocean'
    ) }})

union all
select * from (
    {{ check_not_null_v2(
        'fact_open_po_spend_summary',
        [
            'supplier_number_parent',
            'supplier_name_parent',
            'supplier_number_child',
            'supplier_name_child',
            'payment_terms',
            'document_type',
            'opco_item',
            'po_item_uom',
            'NET_PRICE',
            'ORDER_QTY',
            'VOLUME',
            'SPEND',
            'PLANT_BK',
            'LEGAL_ENTITY_BK',
			'SOURCE',
			'SCHEDULE_LINE_DELIVERY_DATE__YYYYMMDD',
			'ITEM_HK'
        ],
        'BKCC',
        'Swimming_Ocean'
    ) }})