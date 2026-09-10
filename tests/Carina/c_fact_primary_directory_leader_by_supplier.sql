  select * from ({{ check_not_null_v2(
        'fact_primary_director_leader_spend_by_supplier',
        [
            'SUPPLIER_HK',
            'MDM_GOLDEN_RECORD',
            'UNIFIED_SUPPLIER_KEY',
            'UNIFIED_SUPPLIER_NAME',
            'PRIMARY_DIRECTOR_NAME',
            'PRIMARY_DIRECTOR_LTM_SPEND_USD',
            'PRIMARY_CATEGORY_LEADER_NAME',
            'PRIMARY_CATEGORY_LEADER_LTM_SPEND_USD',
            'UNIFIED_BKCC',
            'UNIFIED_REC_SRC'
        ],
        'UNIFIED_BKCC',
        'Jumping_River'
    ) }})
    union all
    select * from ( {{ check_not_null_v2(
        'fact_primary_director_leader_spend_by_supplier',
        [
            'SUPPLIER_HK',
            'MDM_GOLDEN_RECORD',
            'UNIFIED_SUPPLIER_KEY',
            'UNIFIED_SUPPLIER_NAME',
            'PRIMARY_DIRECTOR_NAME',
            'PRIMARY_DIRECTOR_LTM_SPEND_USD',
            'PRIMARY_CATEGORY_LEADER_NAME',
            'PRIMARY_CATEGORY_LEADER_LTM_SPEND_USD',
            'UNIFIED_BKCC',
            'UNIFIED_REC_SRC'
        ],
        'UNIFIED_BKCC',
        'Hiding_Tiger'
    ) }})
    union all  
    select * from ({{ check_not_null_v2(
        'fact_primary_director_leader_spend_by_supplier',
        [
            'SUPPLIER_HK',
            'MDM_GOLDEN_RECORD',
            'UNIFIED_SUPPLIER_KEY',
            'UNIFIED_SUPPLIER_NAME',
            'PRIMARY_DIRECTOR_NAME',
            'PRIMARY_DIRECTOR_LTM_SPEND_USD',
            'PRIMARY_CATEGORY_LEADER_NAME',
            'PRIMARY_CATEGORY_LEADER_LTM_SPEND_USD',
            'UNIFIED_BKCC',
            'UNIFIED_REC_SRC'
        ],
        'UNIFIED_BKCC',
        'Swimming_Ocean'
    ) }})
  union all
    select * from ({{ check_not_null_v2(
        'fact_primary_director_leader_spend_by_supplier',
        [
            'SUPPLIER_HK',
            'MDM_SUPPLIER_BK',
            'MDM_GOLDEN_RECORD',
            'UNIFIED_SUPPLIER_KEY',
            'UNIFIED_SUPPLIER_NAME',
            'PRIMARY_DIRECTOR_NAME',
            'PRIMARY_DIRECTOR_LTM_SPEND_USD',
            'PRIMARY_CATEGORY_LEADER_NAME',
            'PRIMARY_CATEGORY_LEADER_LTM_SPEND_USD',
            'UNIFIED_BKCC',
            'UNIFIED_REC_SRC'
        ],
        'UNIFIED_BKCC',
        'Laying_Goose'
    ) }})