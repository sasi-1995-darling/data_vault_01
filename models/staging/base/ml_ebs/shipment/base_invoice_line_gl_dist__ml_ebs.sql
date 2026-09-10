with cte_gl_dist as (
    select distinct
        customer_trx_id
        , customer_trx_line_id
        , gl_date
        , gl_posted_date
        , account_set_flag
        , account_class
    from {{ source('bronze_ml_ebs_ar', 'ra_cust_trx_line_gl_dist_all') }}
    where account_class = 'REV' and gl_posted_date is not null and _fivetran_deleted = 'FALSE'
)

select
    customer_trx_id
    , customer_trx_line_id
    , max(gl_date) as gl_date
    , max(gl_posted_date) as gl_posted_date
    , account_set_flag
    , account_class
from cte_gl_dist
group by
    customer_trx_id
    , customer_trx_line_id
    , account_set_flag
    , account_class
