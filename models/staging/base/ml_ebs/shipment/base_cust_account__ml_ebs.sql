select *, ATTRIBUTE14 as key_account_number from {{ source('bronze_ml_ebs_ar', 'hz_cust_accounts') }}
where _fivetran_deleted = 'FALSE'
