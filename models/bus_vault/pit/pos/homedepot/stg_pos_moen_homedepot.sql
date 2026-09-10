{{
    config(
        materialized='ephemeral'
    )
}}


with moen_known_item_attributes as (
    select distinct
        sku_nbr
        , first_value(manuf_part_number) over (partition by sku_nbr order by run_date desc) as manuf_part_number
    from {{ ref('ref_pos_home_depot_itemattributes') }}
    where manuf_part_number != 'UNKNOWN'
)

, pos_moen_resolve_unknowns_from_knowns as (
    select
        pos.* exclude item
        , kim.manuf_part_number as item
    from {{ ref('stg_pit_pos_fbin_homedepot') }} as pos
        left join moen_known_item_attributes as kim on pos.sku = kim.sku_nbr
    where pos.item = 'UNKNOWN' and pos.brand like 'Moen%'
)

, moen_pos_base as (
    select
        pos.* exclude item
        , pos.item
    from {{ ref('stg_pit_pos_fbin_homedepot') }} as pos
    where pos.item != 'UNKNOWN' and pos.brand like 'Moen%'
    union all
    select
        * exclude item
        , coalesce(item, 'UNKNOWN') as item
    from pos_moen_resolve_unknowns_from_knowns
)

, moen_item_no_match_master as (
    select distinct item as item_id from moen_pos_base
    minus
    select distinct item_id from {{ ref('pb_items_by_plant') }}
)

, moen_item_match_master as (
    select distinct
        item as pos_item_id
        , rim.item_hk as rim_item_id
    from moen_pos_base as pos
        left join (select item_hk,brand,item_number from 
		{{ ref('pb_items_by_plant') }}
		where brand='MOEN'
		qualify row_number() over(partition by item_number,brand order by SAT_PLANT_ITEM_LOAD_DTS desc )=1
		) as rim on pos.item = rim.item_number
    where pos.brand like 'Moen%'
)

, moen_item_map as (
    select
        pos_item_id
        , rim_item_id
    from moen_item_match_master where rim_item_id is not null
    union
    select
        pos.item_id as pos_item_id
        , rim.item_hk as rim_item_id
    from moen_item_no_match_master as pos
        left join (select item_hk,brand,item_number from 
		{{ ref('pb_items_by_plant') }} 
		where brand='MOEN'
		qualify row_number() over(partition by item_number,brand order by SAT_PLANT_ITEM_LOAD_DTS desc )=1
		) as rim on upper(rim.item_number) = upper(split_part(pos.item_id, '-', 0))
)


select
    mim.rim_item_id as item_id
    , pos.store_hk
    , pos.transaction_date
    , pos.transaction_datekey
    , pos.reporting_channel
    , pos.sku
    , pos.store_id
    , pos.sku_status
    , pos.pos_qty
    , pos.consumer_dollars
    , pos.gross_dollars
    , pos.inv_qty
    , pos.inv_consumer_dollars
    , 'HOME DEPOT' as reporting_customer
    , 'MOEN' as brand
    , pos.bkcc
    , pos.rec_src
from moen_pos_base as pos
    left join moen_item_map as mim on pos.item = mim.pos_item_id



