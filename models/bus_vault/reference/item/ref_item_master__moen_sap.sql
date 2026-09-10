{{
    config(
        materialized='ephemeral'
    )
}}

with cte_sat_item_master__moen_sap as (select * from {{ ref('sat_item_master__moen_sap') }})

, cte_sat_item_master__moen_sap_latest as (
    {{ generate_cte_satellite_latest('cte_sat_item_master__moen_sap','item_hk') }}
)

, base_query as (
    select
        hi.item_hk
        , sim.item_id
        , rid.material_desc as item_title
        , sim.base_material
        , case when sim.item_status in ('ZT', 'ZP', 'ZN', 'ZM', 'Z8', 'Z7', 'Z6') then 'OBSOLETE'
            else 'ACTIVE'
        end as item_status
        , case when sim.item_type_code = 'FERT' then 'FG'
            else 'COMP'
        end as item_type_code
        , case when sim.item_id in ('900-001', '900-006', '920-005', '900-002', '920-004') then 'BATH'
            when rira.room_area = 'NOT APPLICABLE' or rira.room_area = '' then null
            else trim(rira.room_area)
        end as item_category
        , trim(ripg.price_type_group) as item_sub_category
        , trim(rig.item_group) as item_class
        , trim(rip.item_platform) as item_sub_class
        , null as pricing
        , rif.finish
        , null as business_segment
        , rab.item_brand as brand
        , 'Each' as primary_unit_of_measure
        , null as size_attribute
        , rirc.reporting_category as item_area
    from {{ ref('hub_item') }} as hi
        inner join cte_sat_item_master__moen_sap_latest as sim on hi.item_hk = sim.item_hk
        inner join
            {{ ref('ref_item_description__moen_sap') }} as rid
            on sim.item_hk = rid.item_hk and rid.language = 'E'
        left join {{ ref('ref_item_room_area__moen_sap') }} as rira on sim.room_area_id_hk = rira.room_area_id_hk
        left join
            {{ ref('ref_item_price_group__moen_sap') }} as ripg
            on sim.item_price_type_group_id_hk = ripg.item_price_type_group_id_hk and ripg.language = 'E'
        left join
            {{ ref('ref_item_group__moen_sap') }} as rig
            on sim.item_group_id_hk = rig.item_group_id_hk and rig.language = 'E'
        left join
            {{ ref('ref_item_platform__moen_sap') }} as rip
            on sim.item_platform_id_hk = rip.item_platform_id_hk and rip.language = 'E'
        left join
            {{ ref('ref_item_finish__moen_sap') }} as rif
            on sim.item_finish_id_hk = rif.item_finish_id_hk and rif.language = 'E'
        left join
            {{ ref('ref_item_reporting_category__moen_sap') }} as rirc
            on sim.reporting_category_id_hk = rirc.reporting_category_id_hk and rirc.language = 'E'
        left join {{ ref('ref_ausp_brand__moen_sap') }} as rab on sim.item_hk = rab.item_hk
)

, null_cat_parent_items as (
    select
        item_hk
        , item_id
        , iff(item_id = split_part(item_id, '-', 0), null, split_part(item_id, '-', 0)) as priority_one_parent_item_id
        , iff(
            item_id = regexp_replace(split_part(item_id, '-', 0), '^T|^WS', '')
            , null
            , regexp_replace(split_part(item_id, '-', 0), '^T|^WS', '')
        )
            as priority_two_parent_item_id
        , iff(
            item_id = regexp_replace(regexp_replace(item_id, '-[^-]*$', ''), '[A-Za-z]', '')
            , null
            , regexp_replace(regexp_replace(item_id, '-[^-]*$', ''), '[A-Za-z]', '')
        )
            as priority_three_parent_item_id
        , iff(item_id = split_part(item_title, '-', 0), null, split_part(item_title, '-', 0))
            as priority_four_parent_item_id
    from base_query
    where (brand is null or brand = 'MOEN' or len(brand) = 0)
        or item_category is null
)

, priority_one_parent_cat as (
    select
        ncpi.item_hk
        , ncpi.item_id
        , b.item_category
        , b.item_sub_category
        , b.item_class
        , b.item_sub_class
        , b.brand
    from null_cat_parent_items as ncpi
        inner join base_query as b on ncpi.priority_one_parent_item_id = b.item_id
)

, priority_two_parent_cat as (
    select
        ncpi.item_hk
        , ncpi.item_id
        , b.item_category
        , b.item_sub_category
        , b.item_class
        , b.item_sub_class
        , b.brand
    from null_cat_parent_items as ncpi
        inner join base_query as b on ncpi.priority_two_parent_item_id = b.item_id
)

, priority_three_parent_cat as (
    select
        ncpi.item_hk
        , ncpi.item_id
        , b.item_category
        , b.item_sub_category
        , b.item_class
        , b.item_sub_class
        , b.brand
    from null_cat_parent_items as ncpi
        inner join base_query as b on ncpi.priority_three_parent_item_id = b.item_id
)

, priority_four_parent_cat as (
    select
        ncpi.item_hk
        , ncpi.item_id
        , b.item_category
        , b.item_sub_category
        , b.item_class
        , b.item_sub_class
        , 'MOEN' as brand
    from null_cat_parent_items as ncpi
        inner join base_query as b on ncpi.priority_four_parent_item_id = b.item_id
)

, t_w_resolved_cat as (
    select distinct
        b.item_hk
        , b.item_id
        , b.item_title
        , b.base_material
        , b.item_status
        , b.item_type_code
        , coalesce(p1pc.item_category, p2pc.item_category, p3pc.item_category, p4pc.item_category, b.item_category)
            as item_category
        , coalesce(
            p1pc.item_sub_category
            , p2pc.item_sub_category
            , p3pc.item_sub_category
            , p4pc.item_sub_category
            , b.item_sub_category
        ) as item_sub_category
        , coalesce(p1pc.item_class, p2pc.item_class, p3pc.item_class, p4pc.item_class, b.item_class) as item_class
        , coalesce(
            p1pc.item_sub_class, p2pc.item_sub_class, p3pc.item_sub_class, p4pc.item_sub_class, b.item_sub_class
        ) as item_sub_class
        , b.pricing
        , b.finish
        , b.business_segment
        , coalesce(p1pc.brand, p2pc.brand, b.brand, p3pc.brand, p4pc.brand) as brand
        , b.primary_unit_of_measure
        , b.size_attribute
        , b.item_area
    from base_query as b
        left join priority_one_parent_cat as p1pc on b.item_id = p1pc.item_id
        left join priority_two_parent_cat as p2pc on b.item_id = p2pc.item_id
        left join priority_three_parent_cat as p3pc on b.item_id = p3pc.item_id
        left join priority_three_parent_cat as p4pc on b.item_id = p4pc.item_id

)

, bundle_item_categories as (
    select distinct
        rib.item_bundle_id
        , twrc.item_category
    from {{ ref('ref_item_bundle__moen_sap') }} as rib
        left join t_w_resolved_cat as twrc on rib.item_id = twrc.item_id
)

, bundle_items as (
    select
        twrc.* exclude (brand, item_category, item_sub_category, item_class, item_sub_class)
        , bic.item_category
        , 'MOEN' as brand
        , 'KIT' as item_sub_category
        , 'KIT' as item_class
        , 'KIT' as item_sub_class
    from t_w_resolved_cat as twrc
        left join bundle_item_categories as bic on twrc.item_id = bic.item_bundle_id
    where item_id in (select item_bundle_id from {{ ref('ref_item_bundle__moen_sap') }})
)

, combined_items as (
    select
        item_hk
        , item_id
        , item_title
        , base_material
        , item_status
        , item_type_code
        , item_category
        , item_sub_category
        , item_class
        , item_sub_class
        , pricing
        , finish
        , business_segment
        , brand
        , primary_unit_of_measure
        , size_attribute
        , item_area
    from t_w_resolved_cat
    where item_id not in (select item_bundle_id from {{ ref('ref_item_bundle__moen_sap') }})
    union
    select
        item_hk
        , item_id
        , item_title
        , base_material
        , item_status
        , item_type_code
        , item_category
        , item_sub_category
        , item_class
        , item_sub_class
        , pricing
        , finish
        , business_segment
        , brand
        , primary_unit_of_measure
        , size_attribute
        , item_area
    from bundle_items
)

select * from combined_items
