with
tmlc as (select * from {{ ref('pb_items_by_plant_ml') }})

-- moen already has item_style / first_ship_date / when_new_date / d_chain_code in its output,
-- but they sit in the middle of the SELECT list.  The non-moen branches append those four
-- columns at the END via "select *, ...".  UNION ALL matches by position, so we must put
-- the same four columns at the END for moen too — otherwise d_chain_code (VARCHAR 'S5')
-- lands at a numeric column position from the first branch and raises error 100038.
, moen as (
    select
        * EXCLUDE (item_style, first_ship_date, when_new_date, d_chain_code)
        , item_style
        , first_ship_date
        , when_new_date
        , d_chain_code
    from {{ ref('pb_items_by_plant_moen') }}
)

, lrsn as (select * from {{ ref('pb_items_by_plant_lrsn') }})

, fib as (select * from {{ ref('pb_items_by_plant_fib') }})

, tt as (select * from {{ ref('pb_items_by_plant_tt') }})

, emtk as (select * from {{ ref('pb_items_by_plant_emtk') }})


, cte_all_items_by_plant as (
    select *, 'N/A' as item_style, null as first_ship_date, null as when_new_date, null as d_chain_code from tmlc
    union all
    select * from moen
    union all
    select *, 'N/A' as item_style, null as first_ship_date, null as when_new_date, null as d_chain_code from lrsn
    union all
    select *, 'N/A' as item_style, null as first_ship_date, null as when_new_date, null as d_chain_code from fib
    union all
    select *, 'N/A' as item_style, null as first_ship_date, null as when_new_date, null as d_chain_code from tt
    union all
    select *, 'N/A' as item_style, null as first_ship_date, null as when_new_date, null as d_chain_code from emtk
)

select
    random() as seq_id
    , current_timestamp as snapshot_dts
    , *
from cte_all_items_by_plant
