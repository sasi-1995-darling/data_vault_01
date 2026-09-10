-- HUB: Customer

with
cte_hz_cust_accounts as (
    select
        account_number -- BK
        , cust_account_id
        , party_id
        , last_update_date
        , _fivetran_synced
        , last_updated_by
        , creation_date
        , created_by
        , last_update_login
        , request_id
        , program_application_id
        , program_id
        , program_update_date
        , attribute1
        , attribute2
        , attribute3
        , attribute4
        , attribute10
        , attribute11
        , attribute13
        , attribute15
        , attribute16
        , attribute17
        , attribute19
        , attribute20
        , orig_system_reference
        , status
        , customer_class_code
        , freight_term
        , ship_via
        , payment_term_id
        , tax_header_level_flag
        , account_name
        , account_replication_key
        , object_version_number
        , created_by_module
        , application_id
    from {{ source('emtk_ebs_sales__ar', 'hz_cust_accounts') }}
    where _fivetran_deleted = false
)

select * from cte_hz_cust_accounts
