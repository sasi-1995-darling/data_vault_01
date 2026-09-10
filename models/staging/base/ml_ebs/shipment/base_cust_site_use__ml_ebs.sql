select * from {{ source('bronze_ml_ebs_ar', 'hz_cust_site_uses_all') }}
where _fivetran_deleted = 'FALSE'
