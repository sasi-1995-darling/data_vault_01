/*
    HUB: Sales Region
*/

with
cte_jtf_rs_groups_tl as (
    select
        group_name -- BK
        , group_id
        , created_by
        , creation_date
        , last_updated_by
        , last_update_date
        , _fivetran_synced
        , last_update_login
        , group_desc
    from {{ source('emtk_ebs_sales__jtf', 'jtf_rs_groups_tl') }}
    where _fivetran_deleted = false
)

select * from cte_jtf_rs_groups_tl
