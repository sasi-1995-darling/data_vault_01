with cte_cb as (select * from {{ source('bronze_ml_ebs_inv', 'mtl_categories_b') }})

select
    cte_cb.category_id
    , cte_cb.segment2
    , cte_cb.segment3
    , cte_cb.segment4
from cte_cb
where cte_cb._fivetran_deleted = 'FALSE'
    and cte_cb.segment2 is not null
