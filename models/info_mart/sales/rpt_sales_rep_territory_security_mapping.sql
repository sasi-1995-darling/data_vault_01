with cte_final as (

    select
        sales_rep_territory_security_mapping_pk
        , sales_rep_email
        , territory_security_key
    from {{ ref('stg_sales_rep_territory_security_mapping') }}
)

select * from cte_final
