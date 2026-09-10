
with cte_base as (
    select
        md5_binary(upper(concat_ws(
            '||'
            , coalesce(nullif(trim(cast(hb.bom_bk as varchar)), ''), '^^')
            , coalesce(nullif(trim(cast(hp.plant_bk as varchar)), ''), '^^')
            , coalesce(nullif(trim(cast(hi.item_bk as varchar)), ''), '^^')
            , coalesce(nullif(trim(cast(hichild.item_bk as varchar)), ''), '^^')
            , coalesce(nullif(trim(cast(hb.bkcc as varchar)), ''), '^^')
        ))) as lnk_bom_plant_assembly_component_hk
        , hb.bom_hk
        , hp.plant_hk
        , hi.item_hk as assembly_item_hk
        , hichild.item_hk as component_item_hk
        , lnk.rec_src
    from {{ ref('lnk_bom_plant_item') }} as lnk
        inner join {{ ref('hub_bom') }} as hb
            on lnk.bom_hk = hb.bom_hk 
        inner join {{ ref('hub_item_v1') }} as hi
            on lnk.item_hk = hi.item_hk 
        inner join {{ ref('hub_plant_v1') }} as hp
            on lnk.plant_hk = hp.plant_hk 
        inner join {{ ref('lnk_bom_item') }} as lnkbi
            on lnk.bom_hk = lnkbi.bom_hk
        inner join {{ ref('hub_item_v1') }} as hichild
            on lnkbi.item_hk = hichild.item_hk 
)

select
    *
    , convert_timezone('UTC',current_timestamp::timestamp) as load_dts
from cte_base