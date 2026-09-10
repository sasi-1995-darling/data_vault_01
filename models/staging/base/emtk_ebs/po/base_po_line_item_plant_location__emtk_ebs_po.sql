with cte_po_lines_all as (
    select
        po_line_id::varchar as po_line_id
        , item_id
        , org_id
        , creation_date
        , _fivetran_synced
    from {{ source('emtk_ebs_po__po', 'po_lines_all') }}
    where _fivetran_deleted = false
)

, cte_mtl_system_items_b as (
    select
        inventory_item_id
        , segment1
        , organization_id
    from {{ source('emtk_ebs_common__inv', 'mtl_system_items_b') }}
    where _fivetran_deleted = false
)

, cte_financials_system_params_all as (
    select
        inventory_organization_id
        , org_id
    from {{ source('emtk_ebs_po__ap', 'financials_system_params_all') }}
    where _fivetran_deleted = false
)

, cte_mtl_parameters as (
    select
        organization_id
        , COALESCE(organization_code, '-2') as organization_code
    from {{ source('emtk_ebs_po__inv', 'mtl_parameters') }}
    where _fivetran_deleted = false
)

, cte_line_location_latest as (
    select
        pll.po_line_id::varchar as po_line_id
        , lat.location_code
        , pll.creation_date
        , pll._fivetran_synced
        , ROW_NUMBER() over (partition by pll.po_line_id order by pll.creation_date desc) as row_num
    from {{ source('emtk_ebs_po__po', 'po_line_locations_all') }} as pll
        inner join {{ source('emtk_ebs_po__hr', 'hr_locations_all') }} as lat
            on pll.ship_to_location_id = lat.location_id
                and lat._fivetran_deleted = false
    where pll._fivetran_deleted = false
    qualify row_num = 1
)

, cte_final as (
    select
        pla.po_line_id
        , mp.organization_code
        , pll.location_code
        , fp.org_id
        , si.segment1
        , LEAST(pla.creation_date, pll.creation_date) as creation_date
        , LEAST(pla._fivetran_synced, pll._fivetran_synced) as _fivetran_synced
    from cte_po_lines_all as pla
        inner join cte_line_location_latest as pll on pla.po_line_id = pll.po_line_id
        inner join cte_mtl_system_items_b as si on pla.item_id = si.inventory_item_id
        inner join
            cte_financials_system_params_all
                as fp
            on si.organization_id = fp.inventory_organization_id
                and pla.org_id = fp.org_id
        left join cte_mtl_parameters as mp on fp.inventory_organization_id = mp.organization_id
)

select * from cte_final
