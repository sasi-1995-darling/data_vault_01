select * from {{ source('bronze_ml_ebs_ar', 'ra_customer_trx_lines_all') }}
where _fivetran_deleted = 'FALSE'
