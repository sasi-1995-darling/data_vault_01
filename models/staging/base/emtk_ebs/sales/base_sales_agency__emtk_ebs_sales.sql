/*
    HUB: Sales Agency
*/

with
cte_jtf_rs_salesreps as (
    select
        org_id -- BK
        , salesrep_number -- BK 
        , salesrep_id
        , resource_id
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

, cte_union_default as (
    /* because primary_salesrep_id can be NULL on ra_customer_trx_all */
    select
        101 as org_id -- BK
        , '-1' as salesrep_number -- BK 
        , null as salesrep_id 
        , null as resource_id 
        , null as last_update_date
        , '1900-01-01' as _fivetran_synced
        , null as last_updated_by
        , null as creation_date
        , null as created_by
        , null as last_update_login
        , null as name
        , null as start_date_active
        , null as end_date_active
        , null as email_address
        , null as object_version_number

    union all
    
    select
        181 as org_id -- BK
        , '-1' as salesrep_number -- BK 
        , null as salesrep_id 
        , null as resource_id 
        , null as last_update_date
        , '1900-01-01' as _fivetran_synced
        , null as last_updated_by
        , null as creation_date
        , null as created_by
        , null as last_update_login
        , null as name
        , null as start_date_active
        , null as end_date_active
        , null as email_address
        , null as object_version_number

)

, cte_final as (
    select
        rs.org_id -- BK
        , rs.salesrep_number -- BK 
        , rs.salesrep_id
        , rs.resource_id
        , rs.last_update_date
        , rs._fivetran_synced
        , rs.last_updated_by
        , rs.creation_date
        , rs.created_by
        , rs.last_update_login
        , rs.name
        , rs.start_date_active
        , rs.end_date_active
        , rs.email_address
        , rs.object_version_number

    from cte_jtf_rs_salesreps as rs

    union all

    select * from cte_union_default
)

select * from cte_final
