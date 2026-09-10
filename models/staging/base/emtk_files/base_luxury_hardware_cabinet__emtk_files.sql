with cte_source as (
    select *
    from {{ source('emtk_files', 'luxury_hardware_cabinet') }}
)

, cte_deduped as (
    {{ dbt_utils.deduplicate(
        relation='cte_source',
        partition_by='part_number',
        order_by='_modified desc, _fivetran_synced desc, _line desc',
    )
    }}
)

, cte_final as (
    select
        part_number
        , part_number_with_seperation
        , status
        , current_year_pricing
        , base_cost_wayfair
        , product_name
        , upc
        , brand
        , category
        , style
        , collection
        , function
        , mounting
        , product_code
        , stem
        , stem_finish
        , bar_pull_or_knob
        , bar_pull_or_knob_finish
        , finish_code
        , handing
        , nullif(center_to_center, 'Does Not Apply') as center_to_center
        , knob_dimension
        , nullif(projection_without_disc, 'Does Not Apply') as projection_without_disc
        , projection_with_disc
        , nullif(base_diameter, 'Does Not Apply') as base_diameter
        , width
        , overall
        , nullif(pull_type, 'Does Not Apply') as pull_type
        , screw_type
        , is_prop_65
        , image_link
        , image_2_link
        , marketing_copy
        , feature_bullet_1
        , feature_bullet_2
        , feature_bullet_3
        , country_of_manufacturer
        , product_weight_pounds
        , minimum_order_quantity
        , force_quantity_multiplier
        , display_set_quantity
        , ship_type_small_parcel
        , lead_time
        , replacement_lead_time
        , material_type
        , carton_1_weight_est
        , carton_1_height_est
        , carton_1_width_est_based_on_overall
        , carton_1_depth_est
        , number_of_mounting_holes_required
        , is_backplate_included
        , number_of_backplates_included
        , chemicals
        , chemical_toxicity
        , screws_included
        , supplier_intended_and_approved_use
        , accessory_type_latches
        , hinge_type
        , number_of_hooks
        , number_of_bars
        , ring_type
        , overall_shape
        , mount_type
        , roll_capacity
        , roller_type
        , launch_date

    from cte_deduped
)

select * from cte_final
