select * from (
    {{ check_not_null_v2(
        'fact_planned_order_spend_detail',
        [
            'PLANNED_ORDER_BK',
            'PLANNED_ORDER_FINISH_DATE_KEY',
            'CAL_YEAR',
            'CAL_MONTH',
            'volume',
            'opco_category',
            'category_leader_name',
			'director_name',
            'fbin_category_i',
            'fbin_category_ii',
            'fbin_category_iii',
            'item_bk',
            'plant_bk',
            'planned_order_finish_date_YYYYMMDD',
			'planned_order_hk',
            'supplier_hk',
            'purchasing_org_hk',
            'PURCHASING_RECORD_HK',
			'BUSINESS_UNIT',
			'SOURCE'
        ],
        'BKCC',
        'Hiding_Tiger'
    ) }})
union all
select * from (
    {{ check_not_null_v2(
        'fact_planned_order_spend_detail',
        [
            'PLANNED_ORDER_BK',
            'PLANNED_ORDER_FINISH_DATE_KEY',
            'CAL_YEAR',
            'CAL_MONTH',
            'volume',
            'opco_category',
            'category_leader_name',
			'director_name',
            'fbin_category_i',
            'fbin_category_ii',
            'fbin_category_iii',
            'item_bk',
            'plant_bk',
            'planned_order_finish_date_YYYYMMDD',
			'planned_order_hk',
            'supplier_hk',
            'purchasing_org_hk',
            'PURCHASING_RECORD_HK',
			'BUSINESS_UNIT',
			'SOURCE'
        ],
        'BKCC',
        'Crouching_Dragon'
    ) }})