select * from (
    {{ check_not_null_v2(
        'fact_purchase_requisition_spend_detail',
        [
            'PURCHASE_REQUISITION_NUMBER',
            'PURCHASE_REQUISITION_ITEM_NUMBER',
            'VOLUME',
            'NET_PRICE',
            'PRICE_UNIT',
            'spend',
            'category_leader_name',
			'director_name',
            'fbin_category_i',
            'fbin_category_ii',
            'fbin_category_iii',
            'item_bk',
            'plant_bk',
            'ITEM_DELIVERY_DATE_BK',
			'PURCHASE_REQUISITION_HK',
            'SUPPLIER_HK',
            'ITEM_HK',
            'PLANT_HK',
            'PURCHASING_ORG_HK',
            'SOURCE',
            'BUSINESS_UNIT',
			'PURCHASING_RECORD_HK'
        ],
        'BKCC',
        'Hiding_Tiger'
    ) }})
union all
select * from (
    {{ check_not_null_v2(
        'fact_purchase_requisition_spend_detail',
        [
            'PURCHASE_REQUISITION_NUMBER',
            'PURCHASE_REQUISITION_ITEM_NUMBER',
            'VOLUME',
            'NET_PRICE',
            'PRICE_UNIT',
            'spend',
            'category_leader_name',
			'director_name',
            'fbin_category_i',
            'fbin_category_ii',
            'fbin_category_iii',
            'item_bk',
            'plant_bk',
            'ITEM_DELIVERY_DATE_BK',
			'PURCHASE_REQUISITION_HK',
            'SUPPLIER_HK',
            'ITEM_HK',
            'PLANT_HK',
            'PURCHASING_ORG_HK',
            'SOURCE',
            'BUSINESS_UNIT',
			'PURCHASING_RECORD_HK'
        ],
        'BKCC',
        'Crouching_Dragon'
    ) }})
union ALL
select * from (
    {{ check_not_null_v2(
        'fact_purchase_requisition_spend_summary',
        [
            'VOLUME',
            'spend',
            'category_leader_name',
            'director_name',
            'fbin_category_i',
            'fbin_category_ii',
            'fbin_category_iii',
            'item_bk',
            'plant_bk'
        ],
        'BKCC',
        'Hiding_Tiger'
    ) }})
union all
select * from (
    {{ check_not_null_v2(
        'fact_purchase_requisition_spend_summary',
        [
             'VOLUME',
            'spend',
            'category_leader_name',
            'director_name',
            'fbin_category_i',
            'fbin_category_ii',
            'fbin_category_iii',
            'item_bk',
            'plant_bk'
        ],
        'BKCC',
        'Crouching_Dragon'
    ) }})