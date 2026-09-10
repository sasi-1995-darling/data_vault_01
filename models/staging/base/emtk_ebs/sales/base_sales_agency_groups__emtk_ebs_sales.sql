/*
    LINK: Sales Agency Groups
*/

with
cte_ra_territories as (
    select
        segment1 -- sales territory BK
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

, cte_jtf_rs_groups_tl as (
    select
        group_name -- sales region BK
        , group_id
        , created_by
        , creation_date
        , last_updated_by
        , last_update_date
        , _fivetran_synced
        , last_update_login
        , group_desc
        , language
    from {{ source('emtk_ebs_sales__jtf', 'jtf_rs_groups_tl') }}
    where _fivetran_deleted = false
)

, cte_jtf_rs_salesreps as (
    select
        salesrep_number -- sales agency BK
        , org_id -- sales agency BK
        , salesrep_id -- join key
        , resource_id -- join key
        , last_update_date
        , _fivetran_synced
        , last_updated_by
        , creation_date
        , created_by
        , last_update_login
        , name
        , start_date_active
        , end_date_active
        , email_address
        , object_version_number
    from {{ source('emtk_ebs_sales__jtf', 'jtf_rs_salesreps') }}
    where _fivetran_deleted = false
)

, cte_ra_salesrep_territories as (
    select
        salesrep_territory_id
        , last_update_date
        , creation_date
        , last_update_login
        , salesrep_id
        , territory_id
        , start_date_active
        , object_version_number
    from {{ source('emtk_ebs_sales__ar', 'ra_salesrep_territories') }}
    where _fivetran_deleted = false
)

, cte_jtf_rs_group_members as (
    select
        group_member_id
        , group_id -- join key
        , resource_id -- join key
        , creation_date
        , last_update_date
        , last_update_login
    from {{ source('emtk_ebs_sales__jtf', 'jtf_rs_group_members') }}
    where _fivetran_deleted = false
    and  delete_flag = 'N'
)

, cte_sales_agency_groups as (
    -- just BK's from the 3 hub tables + creation date (pick best one somehow), and _fivetran_synced
    select
        rs.salesrep_number -- Sales Agency BK
        , rs.org_id -- Sales Agency BK
        , gr.group_name -- Sales Region BK
        , t.segment1
        , least(t._fivetran_synced, gr._fivetran_synced) as _fivetran_synced
    from cte_jtf_rs_salesreps as rs
        inner join cte_ra_salesrep_territories as srt on rs.salesrep_id = srt.salesrep_id
        inner join cte_ra_territories as t on srt.territory_id = t.territory_id
        inner join cte_jtf_rs_group_members as gm on rs.resource_id = gm.resource_id
        inner join cte_jtf_rs_groups_tl as gr on gm.group_id = gr.group_id
)

select * from cte_sales_agency_groups
