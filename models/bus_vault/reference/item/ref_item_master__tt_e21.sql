{{
    config(
        materialized='ephemeral'
    )
}}

with cte_sat_item_master__tt_e21 as (select * from {{ ref('sat_item_master__tt_e21') }})

, cte_sat_item_master__tt_e21_latest as (
    {{ generate_cte_satellite_latest('cte_sat_item_master__tt_e21','item_hk') }}
)

select
    hi.item_hk
    , sim.part_code as item_id
    , sim.part_desc as item_title
    , sim.part_code as base_material_number
    , case when sim.part_status = 'A' then 'ACTIVE'
        when sim.part_status = 'I' then 'INACTIVE'
        else 'OBSOLETE'
    end as item_status
    , sim.part_type as item_type_code
    , isg.part_sgrp_desc as item_category
    , isg2.part_sgrp2_desc as item_subcategory
    , isg3.part_sgrp3_desc as item_class
    , null as item_sub_class
    , null as pricing
    , sim.tt_color as finish
    , 'WHSE' as business_segment
    , hi.brand
    , sim.uom as primary_unit_of_measure
    , {{
        concatenate_fields(
            [
                'part_length',
                'part_width',
                'part_height'
            ]
        )
    }} as size_attribute
    , ig.part_grp_desc as item_area
from {{ ref('hub_item') }} as hi
    inner join cte_sat_item_master__tt_e21_latest as sim on hi.item_hk = sim.item_hk
    left join {{ ref('ref_item_group__tt_e21') }} as ig on sim.part_grp = ig.part_grp
    left join {{ ref('ref_item_subgroup__tt_e21') }} as isg on sim.part_subgrp = isg.part_subgrp
    left join {{ ref('ref_item_subgroup_2__tt_e21') }} as isg2 on sim.part_subgrp2 = isg2.part_subgrp2
    left join {{ ref('ref_item_subgroup_3__tt_e21') }} as isg3 on sim.part_subgrp3 = isg3.part_subgrp3
        and hi.brand = 'THTRU'