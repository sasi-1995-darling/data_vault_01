/*
    RSAT: rst invoice Line

    Base table gets the most recent record (may include deletes) for each business key.
    Goal is to provide this information in a sat to track when records are deleted from the source
    business key is customer_trx_line_id

*/

with

max_synced as ( -- get the most current version of each record in the source table.
    select 
        _fivetran_id
        , customer_trx_line_id
    from {{ source('emtk_ebs_sales__ar', 'ra_customer_trx_lines_all') }}
    -- asc means false will always come first
    -- window function pulls the current record from the table. due to how fivetran deletes work _fivetran_sync is not enough to determine this
    QUALIFY ROW_NUMBER() OVER (PARTITION BY customer_trx_line_id ORDER BY _fivetran_deleted asc, _fivetran_synced desc) = 1
)

, cte_ra_customer_trx_lines_all as (
    select
        tgt.customer_trx_line_id::varchar as customer_trx_line_id -- BK
        , tgt._fivetran_synced
        , tgt._fivetran_deleted
    from {{ source('emtk_ebs_sales__ar', 'ra_customer_trx_lines_all') }} tgt
    inner join max_synced ms 
    on tgt._fivetran_id = ms._fivetran_id
)

, cte_final as (
    select
        rctla.customer_trx_line_id -- BK
        , rctla._fivetran_synced
        , case 
            when rctla._fivetran_deleted = true then 'D'
            when rctla._fivetran_deleted = false then 'I/U'
        end as status
    from cte_ra_customer_trx_lines_all as rctla
)

select * from cte_final
