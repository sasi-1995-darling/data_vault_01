SELECT *
FROM (
    {{
        check_not_null_v2(
            'dim_item_fbin',
            [
                'item_id',
                'item_number',
                'item_status',
                'bkcc',
                'rec_src'
            ],
            'bkcc',
            'Hiding_Tiger'
        )
    }}
)
UNION ALL
SELECT *
FROM (
    {{
        check_not_null_v2(
            'dim_item_fbin',
            [
                'item_id',
                'item_number',
                'item_status',
                'bkcc',
                'rec_src'
            ],
            'bkcc',
            'Crouching_Dragon'
        )
    }}
)
UNION ALL
SELECT *
FROM (
    {{
        check_not_null_v2(
            'dim_item_fbin',
            [
                'item_id',
                'item_number',
                'item_status',
                'bkcc',
                'rec_src'
            ],
            'bkcc',
            'Jumping_River'
        )
    }}
)
UNION ALL
SELECT *
FROM (
    {{
        check_not_null_v2(
            'dim_item_fbin',
            [
                'item_id',
                'item_number',
                'item_status',
                'bkcc',
                'rec_src'
            ],
            'bkcc',
            'Kicking_Panda'
        )
    }}
)
UNION ALL
SELECT *
FROM (
    {{
        check_not_null_v2(
            'dim_item_fbin',
            [
                'item_id',
                'item_number',
                'item_status',
                'bkcc',
                'rec_src'
            ],
            'bkcc',
            'Swimming_Ocean'
        )
    }}
)
UNION ALL
SELECT *
FROM (
    {{
        check_not_null_v2(
            'dim_item_fbin',
            [
                'item_id',
                'item_number',
                
                'bkcc',
                'rec_src'
            ],
            'bkcc',
            'Diving_Sea'
        )
    }}
)
UNION ALL
SELECT *
FROM (
    {{
        check_not_null_v2(
            'dim_base_material_fbin',
            [
                'base_material_id',
                'base_material',
                'item_status',
                'bkcc',
                'rec_src'
            ],
            'bkcc',
            'Hiding_Tiger'
        )
    }}
)
UNION ALL
SELECT *
FROM (
    {{
        check_not_null_v2(
            'dim_base_material_fbin',
            [
                'base_material_id',
                'base_material',
                'item_status',
                'bkcc',
                'rec_src'
            ],
            'bkcc',
            'Crouching_Dragon'
        )
    }}
)
UNION ALL
SELECT *
FROM (
    {{
        check_not_null_v2(
            'dim_base_material_fbin',
            [
                'base_material_id',
                'base_material',
                'item_status',
                'bkcc',
                'rec_src'
            ],
            'bkcc',
            'Jumping_River'
        )
    }}
)
UNION ALL
SELECT *
FROM (
    {{
        check_not_null_v2(
            'dim_base_material_fbin',
            [
                'base_material_id',
                'base_material',
                'item_status',
                'bkcc',
                'rec_src'
            ],
            'bkcc',
            'Kicking_Panda'
        )
    }}
)
UNION ALL
SELECT *
FROM (
    {{
        check_not_null_v2(
            'dim_base_material_fbin',
            [
                'base_material_id',
                'base_material',
                'item_status',
                'bkcc',
                'rec_src'
            ],
            'bkcc',
            'Swimming_Ocean'
        )
    }}
)