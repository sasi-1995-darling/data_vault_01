select * from {{ source('bronze_ml_ebs_ar', 'hz_locations') }}
where _fivetran_deleted = 'FALSE'
