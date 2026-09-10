select * from {{ source('bronze_ml_ebs_ar', 'hz_party_sites') }}
where _fivetran_deleted = 'FALSE'
