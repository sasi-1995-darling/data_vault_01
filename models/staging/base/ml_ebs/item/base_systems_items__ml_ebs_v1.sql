with
cte_ib as (select * from {{ source('bronze_ml_ebs_inv', 'mtl_system_items_b') }})

, cte_itl as (select * from {{ source('bronze_ml_ebs_inv', 'mtl_system_items_tl') }})
, cte_bkcc as (select * from {{ ref('ref_business_key_collision') }}
where rec_src = 'USWIOC.ORCL.EBSPRD.SYSTEM_ITEM')

select
    cte_ib.inventory_item_id
    , cte_ib.organization_id
    , cte_ib.segment1 
    , cte_ib.primary_unit_of_measure
    , cte_ib.planner_code
    , cte_ib.item_type
    , cte_ib.inventory_item_status_code
    , cte_ib.creation_date as item_creation_date
    , cte_ib.lot_control_code
    , cte_ib.fixed_lot_multiplier
    , cte_ib.attribute13 as mto_rolled_up_flag
    , cte_itl.language
    , cte_itl.long_description
    , cte_ib.description
    , cte_ib.attribute1 as material
    , SUBSTR(cte_ib.attribute2, 1, 80) as key_change
    , DECODE(cte_ib.replenish_to_order_flag, 'Y', 'Special', 'Stock') as rto_flag
    , SUBSTR(cte_ib.attribute11, 1, 80) as mfg_number
    , DECODE(cte_ib.planning_make_buy_code, 2, 'Sourced', 1, DECODE(cte_ib.lot_control_code, 2, 'MTO', 1, 'MTS'))
        as sourced_mto_mts
    , cte_bkcc.rec_src
    , cte_bkcc.bkcc
from cte_ib
inner join cte_bkcc on 1=1
    inner join cte_itl
        on cte_ib.inventory_item_id = cte_itl.inventory_item_id
            and cte_ib.organization_id = cte_itl.organization_id
            and cte_itl.language = 'US'
            and cte_ib._fivetran_deleted = 'FALSE' and cte_itl._fivetran_deleted = 'FALSE'
