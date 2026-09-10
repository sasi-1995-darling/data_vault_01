select * from {{ source('bronze_ml_ebs_ar', 'ar_payment_schedules_all') }}
where _fivetran_deleted = 'FALSE'
and (customer_trx_id is not null and customer_trx_id != -1)
