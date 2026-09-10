with hofr as (select * from {{ ref('stg_pb_shipment_hofr') }})

, winn as (select * exclude (row_id, load_date) from {{ ref('stg_pb_shipment_winn') }})

, winn_hist as (select * exclude row_id from {{ ref('stg_pb_shipment_winn_hist') }})

, tmlc as (select * from {{ ref('stg_pb_shipment_ml') }})

, lrsn as (select * from {{ ref('stg_pb_shipment_lrsn') }})

, fib as (select * from {{ ref('stg_pb_shipment_fib') }})


, cte_all_shipment as (
    select * from hofr
    union all
    select * from winn
    union all
    select * from winn_hist
    union all
    select * from tmlc
    union all
    select * from lrsn
    union all
    select * from fib
)

select
    random() as seq_id
    , current_timestamp as snapshot_dts
    , *
from cte_all_shipment