/*
    HUB: Sales Territory
*/

with
cte_ra_territories as (
    select
        segment1 -- BK
        , territory_id
        , last_update_date
        , _fivetran_synced
        , creation_date
        , last_update_login
        , name
        , description
    from {{ source('emtk_ebs_sales__ar', 'ra_territories') }}
    where _fivetran_deleted = false
)

select * from cte_ra_territories
