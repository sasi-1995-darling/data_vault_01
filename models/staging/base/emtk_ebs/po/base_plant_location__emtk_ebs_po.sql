with
cte_po_line_locations_all as (

    select distinct
        pla.org_id
        , pll.ship_to_location_id
    from {{ source('emtk_ebs_po__po', 'po_lines_all') }} as pla
        inner join {{ source('emtk_ebs_po__po', 'po_line_locations_all') }} as pll on pla.po_line_id = pll.po_line_id
            and pll._fivetran_deleted = false
    where pla._fivetran_deleted = false

)

, cte_hr_locations_all as (

    select
        location_id
        , location_code
        , description
        , ship_to_location_id
        , ship_to_site_flag
        , receiving_site_flag
        , bill_to_site_flag
        , in_organization_flag
        , office_site_flag
        , inventory_organization_id
        , style
        , address_line_1
        , address_line_2
        , town_or_city
        , country
        , postal_code
        , region_1
        , region_2
        , telephone_number_1
        , telephone_number_2
        , last_update_date
        , _fivetran_synced
        , last_updated_by
        , last_update_login
        , created_by
        , creation_date
        , entered_by
        , ece_tp_location_code
        , object_version_number
        , derived_locale
        , legal_address_flag
    from {{ source("emtk_ebs_po__hr", "hr_locations_all") }}
    where _fivetran_deleted = false
)

, cte_financials_system_params_all as (
    select
        org_id
        , inventory_organization_id
    from {{ source('emtk_ebs_po__ap', 'financials_system_params_all') }}
    where _fivetran_deleted = false
)

, cte_mtl_parameters as (
    select
        organization_id
        , organization_code
    from {{ source('emtk_ebs_po__inv', 'mtl_parameters') }}
    where _fivetran_deleted = false
)

, cte_plant_location_final as (
    select
        mp.organization_code
        , hla.location_code
        , hla.location_id
        , hla.description
        , hla.ship_to_location_id
        , hla.ship_to_site_flag
        , hla.receiving_site_flag
        , hla.bill_to_site_flag
        , hla.in_organization_flag
        , hla.office_site_flag
        , hla.inventory_organization_id
        , hla.style
        , hla.address_line_1
        , hla.address_line_2
        , hla.town_or_city
        , hla.country
        , hla.postal_code
        , hla.region_1
        , hla.region_2
        , hla.telephone_number_1
        , hla.telephone_number_2
        , hla.last_update_date
        , hla._fivetran_synced
        , hla.last_updated_by
        , hla.last_update_login
        , hla.created_by
        , hla.creation_date
        , hla.entered_by
        , hla.ece_tp_location_code
        , hla.object_version_number
        , hla.derived_locale
        , hla.legal_address_flag
    from cte_hr_locations_all as hla
        inner join cte_po_line_locations_all as plla on hla.location_id = plla.ship_to_location_id
        left join cte_financials_system_params_all as fspa on plla.org_id = fspa.org_id
        left join cte_mtl_parameters as mp on fspa.inventory_organization_id = mp.organization_id
)

select * from cte_plant_location_final
