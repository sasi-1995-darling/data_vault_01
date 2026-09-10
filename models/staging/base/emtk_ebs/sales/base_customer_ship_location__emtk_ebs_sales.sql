/*
    HUB: Customer ship location
*/

with cte_duplicates as (
    /* two site_use_ids map to the same location_id - just keep the one used more often */
    select duplicate_victim
    from {{ ref('duplicate_victims') }}
    where source_system = 'emtk_ebs'
    and source_table = 'hz_cust_site_uses_all'
    and field_name = 'site_use_id'        
)

, cte_hz_cust_site_uses_all as (
    select
        hcsu.location
        , hcsu.site_use_id
        , hcsu.cust_acct_site_id
        , _fivetran_synced
    from {{ source('emtk_ebs_sales__ar', 'hz_cust_site_uses_all') }} as hcsu
    where hcsu._fivetran_deleted = false
        and exists (
            select 1 as constant
            from {{ source('emtk_ebs_sales__ar', 'ra_customer_trx_all') }} as rcta
            where hcsu.site_use_id = rcta.ship_to_site_use_id
                and rcta._fivetran_deleted = false
        ) --restrict to just sites used as invoice ship_to
        and not exists (
            select 1 as constant
            from cte_duplicates as dup
            where dup.duplicate_victim = hcsu.site_use_id
        ) -- remove true duplicates
)

, cte_hz_cust_acct_sites_all as (
    select
        hcas.cust_acct_site_id
        , hcas.party_site_id
    from {{ source('emtk_ebs_sales__ar', 'hz_cust_acct_sites_all') }} as hcas
    where hcas._fivetran_deleted = false
)

, cte_hz_party_sites as (
    select
        hps.party_site_id
        , hps.location_id
    from {{ source('emtk_ebs_sales__ar', 'hz_party_sites') }} as hps
    where hps._fivetran_deleted = false
)

, cte_hz_locations as (
    select
        hl.location_id::varchar as location_id
        , hl.last_update_date
        , hl.last_updated_by
        , hl._fivetran_synced
        , hl.creation_date
        , hl.created_by
        , hl.last_update_login
        , hl.request_id
        , hl.program_application_id
        , hl.program_id
        , hl.program_update_date
        , hl.orig_system_reference
        , hl.country
        , hl.address1
        , hl.address2
        , hl.address3
        , hl.address4
        , hl.city
        , hl.postal_code
        , hl.state
        , hl.province
        , hl.county
        , hl.address_key
        , hl.address_style
        , hl.address_lines_phonetic
        , hl.address_effective_date
        , hl.object_version_number
        , hl.created_by_module
        , hl.application_id
        , hl.timezone_id
    from {{ source('emtk_ebs_sales__ar', 'hz_locations') }} as hl
    where hl._fivetran_deleted = false
)

, cte_final as (
    select
        hl.location_id-- BK
        , hcsu.location
        , hcsu.site_use_id
        , hl.last_update_date
        , {{ greatest_date(['hl._fivetran_synced','hcsu._fivetran_synced']) }} as _fivetran_synced
        , hl.last_updated_by
        , hl.creation_date
        , hl.created_by
        , hl.last_update_login
        , hl.request_id
        , hl.program_application_id
        , hl.program_id
        , hl.program_update_date
        , hl.orig_system_reference
        , hl.country
        , hl.address1
        , hl.address2
        , hl.address3
        , hl.address4
        , hl.city
        , hl.postal_code
        , hl.state
        , hl.province
        , hl.county
        , hl.address_key
        , hl.address_style
        , hl.address_lines_phonetic
        , hl.address_effective_date
        , hl.object_version_number
        , hl.created_by_module
        , hl.application_id
        , hl.timezone_id
    from cte_hz_cust_site_uses_all as hcsu
        inner join cte_hz_cust_acct_sites_all as hcas on hcsu.cust_acct_site_id = hcas.cust_acct_site_id
        inner join cte_hz_party_sites as hps on hcas.party_site_id = hps.party_site_id
        inner join cte_hz_locations as hl on hps.location_id = hl.location_id
)

select * from cte_final
