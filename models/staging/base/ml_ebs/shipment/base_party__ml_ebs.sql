select * from {{ source('bronze_ml_ebs_ar', 'hz_parties') }}
where _fivetran_deleted = 'FALSE'
