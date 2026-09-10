with cte_bkcc as 
(
    select * from {{ ref('ref_business_key_collision_snowflake') }}
    where rec_src = 'USWIOC.ORCL.EBSPRD.MTL_CATEGORIES_B'
),
ebs_brand as (
    select distinct 
            d.segment1 as registered_brand
    from {{ source('bronze_ml_ebs_inv', 'mtl_system_items_b') }}     a,
        {{ source('bronze_ml_ebs_inv', 'mtl_item_categories') }}     b,
        {{ source('bronze_ml_ebs_inv', 'mtl_category_sets_tl') }}    c,
        {{ source('bronze_ml_ebs_inv', 'mtl_categories_b') }}        d
    where true
    and a.inventory_item_id = b.inventory_item_id
    and a.organization_id = b.organization_id
    and b.category_set_id = c.category_set_id
    and c.category_set_name = 'Registered Brand'
    and b.category_id = d.category_id
    and a.organization_id = 1
)

select b.*
       , cte_bkcc.rec_src
from ebs_brand b
inner join cte_bkcc on 1=1
