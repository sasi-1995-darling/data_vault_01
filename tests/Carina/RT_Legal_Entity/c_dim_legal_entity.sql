select * from (
    {{ check_not_null_v2(
        'dim_legal_entity',
        [
            'LEGAL_ENTITY_HK',
            'LEGAL_ENTITY_BK',
            'LEGAL_ENTITY_CODE',
            'LEGAL_ENTITY_NAME',
            'IS_DELETED',
            'REC_SRC',
            'BKCC'
        ],
        'BKCC',
        'Hiding_Tiger'
    ) }})
union all
select * from (
    {{ check_not_null_v2(
        'dim_legal_entity',
        [
             'LEGAL_ENTITY_HK',
            'LEGAL_ENTITY_BK',
            'LEGAL_ENTITY_CODE',
            'LEGAL_ENTITY_NAME',
            'IS_DELETED',
            'REC_SRC',
            'BKCC'
        ],
        'BKCC',
        'Crouching_Dragon'
    ) }})
union all
select * from (
    {{ check_not_null_v2(
        'dim_legal_entity',
        [
             'LEGAL_ENTITY_HK',
            'LEGAL_ENTITY_BK',
            'LEGAL_ENTITY_CODE',
            'LEGAL_ENTITY_NAME',
            'IS_DELETED',
            'REC_SRC',
            'BKCC'
        ],
        'BKCC',
        'Swimming_Ocean'
    ) }})
union all
select * from (
    {{ check_not_null_v2(
        'dim_legal_entity',
        [
             'LEGAL_ENTITY_HK',
            'LEGAL_ENTITY_BK',
            'LEGAL_ENTITY_CODE',
            'LEGAL_ENTITY_NAME',
            'IS_DELETED',
            'REC_SRC',
            'BKCC'
        ],
        'BKCC',
        'Diving_Sea'
    ) }})
    union all
select * from (
    {{ check_not_null_v2(
        'dim_legal_entity',
        [
             'LEGAL_ENTITY_HK',
            'LEGAL_ENTITY_BK',
            'LEGAL_ENTITY_CODE',
            'LEGAL_ENTITY_NAME',
            'IS_DELETED',
            'REC_SRC',
            'BKCC'
        ],
        'BKCC',
        'Kicking_Panda'
    ) }})
union all
select * from (
    {{ check_not_null_v2(
        'dim_legal_entity',
        [
             'LEGAL_ENTITY_HK',
            'LEGAL_ENTITY_BK',
            'LEGAL_ENTITY_CODE',
            'LEGAL_ENTITY_NAME',
            'IS_DELETED',
            'REC_SRC',
            'BKCC'
        ],
        'BKCC',
        'Jumping_River'
    ) }})
