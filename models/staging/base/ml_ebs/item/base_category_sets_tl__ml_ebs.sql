with cte_stl as (select * from {{ source('bronze_ml_ebs_inv', 'mtl_category_sets_tl') }})

select
    cte_stl.category_set_id
    , cte_stl.category_set_name
from cte_stl
where cte_stl._fivetran_deleted = 'FALSE'
