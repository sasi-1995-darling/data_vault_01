with cb as (select * from {{ source('bronze_ml_ebs_inv', 'mtl_categories_b') }})

select 
    cb.category_id
    , cb.segment1
    , cb.segment2
    , cb.segment3
    , cb.segment4
from cb
where cb._fivetran_deleted = 'FALSE'
