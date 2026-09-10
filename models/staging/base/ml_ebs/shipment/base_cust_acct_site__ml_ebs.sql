select * from {{ source('bronze_ml_ebs_ar', 'hz_cust_acct_sites_all') }}
where _fivetran_deleted = 'FALSE'
