with

cte_ap_supplier_sites_all as (

    select
        vendor_site_id::varchar as vendor_site_id -- BK
        , last_update_date
        , _fivetran_synced
        , last_updated_by
        , vendor_id
        , vendor_site_code
        , vendor_site_code_alt
        , last_update_login
        , creation_date
        , created_by
        , purchasing_site_flag
        , rfq_only_site_flag
        , pay_site_flag
        , address_line1
        , address_lines_alt
        , address_line2
        , address_line3
        , city
        , state
        , zip
        , province
        , country
        , area_code
        , phone
        , ship_to_location_id
        , bill_to_location_id
        , freight_terms_lookup_code
        , inactive_date
        , fax
        , fax_area_code
        , telex
        , payment_method_lookup_code
        , accts_pay_code_combination_id
        , prepay_code_combination_id
        , pay_group_lookup_code
        , terms_id
        , pay_date_basis_lookup_code
        , always_take_disc_flag
        , ap_tax_rounding_rule
        , tax_reporting_site_flag
        , attribute1
        , program_update_date
        , org_id
        , address_line4
        , county
        , address_style
        , tp_header_id
        , ece_tp_location_code
        , country_of_origin_code
        , supplier_notif_method
        , email_address
        , primary_pay_site_flag
        , location_id
        , party_site_id
        , tca_sync_state
        , tca_sync_province
        , tca_sync_county
        , tca_sync_city
        , tca_sync_zip
        , tca_sync_country
        , legal_business_name
    from {{ source('emtk_ebs_po__ap', 'ap_supplier_sites_all') }}
    where _fivetran_deleted = false

)

, cte_union_default as (
    /* because vendor_site_id can be NULL on po_headers_all */
    select
        '-1' as vendor_site_id
        , null as last_update_date
        , '1900-01-01' as _fivetran_synced
        , null as last_updated_by
        , null as vendor_id
        , null as vendor_site_code
        , null as vendor_site_code_alt
        , null as last_update_login
        , null as creation_date
        , null as created_by
        , null as purchasing_site_flag
        , null as rfq_only_site_flag
        , null as pay_site_flag
        , null as address_line1
        , null as address_lines_alt
        , null as address_line2
        , null as address_line3
        , null as city
        , null as state
        , null as zip
        , null as province
        , null as country
        , null as area_code
        , null as phone
        , null as ship_to_location_id
        , null as bill_to_location_id
        , null as freight_terms_lookup_code
        , null as inactive_date
        , null as fax
        , null as fax_area_code
        , null as telex
        , null as payment_method_lookup_code
        , null as accts_pay_code_combination_id
        , null as prepay_code_combination_id
        , null as pay_group_lookup_code
        , null as terms_id
        , null as pay_date_basis_lookup_code
        , null as always_take_disc_flag
        , null as ap_tax_rounding_rule
        , null as tax_reporting_site_flag
        , null as attribute1
        , null as program_update_date
        , null as org_id
        , null as address_line4
        , null as county
        , null as address_style
        , null as tp_header_id
        , null as ece_tp_location_code
        , null as country_of_origin_code
        , null as supplier_notif_method
        , null as email_address
        , null as primary_pay_site_flag
        , null as location_id
        , null as party_site_id
        , null as tca_sync_state
        , null as tca_sync_province
        , null as tca_sync_county
        , null as tca_sync_city
        , null as tca_sync_zip
        , null as tca_sync_country
        , null as legal_business_name
)

, cte_final as (
    select * from cte_ap_supplier_sites_all

    union all

    select * from cte_union_default
)

select * from cte_final
