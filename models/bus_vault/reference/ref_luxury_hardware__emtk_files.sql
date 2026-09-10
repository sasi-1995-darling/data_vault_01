with cte_stg_luxury_hardware as (
    select * from {{ ref('stg_luxury_hardware__emtk_files') }}
)

, cte_final as (

    select
        case when _dbt_source_relation ilike '%_bath_%' then 'BATH'
            when _dbt_source_relation ilike '%_cabinet_%' then 'CABINET'
            else 'UNKNOWN'
        end as hardware_category
        , part_number
        , part_number_with_seperation
        , status
        , brand
        , category
        , style
        , collection
        , function
        , product_code
        , rosette
        , finish_code
        , handing
        , knob_dimension
        , projection_without_disc
        , projection_with_disc
        , width
        , overall
        , pull_type
        , is_prop_65
        , image_link
        , country_of_manufacturer
        , product_weight_pounds
        , minimum_order_quantity
        , force_quantity_multiplier
        , display_set_quantity
        , ship_type_small_parcel
        , lead_time
        , replacement_lead_time
        , material_type
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
        , number_of_hooks
        , mount_type
        , roll_capacity
        , launch_date
        , current_year_pricing
        , base_cost_wayfair
        , center_to_center
        , stem_finish
        , bar_pull_or_knob_finish
        , upc
        , bar_pull_or_knob
        , product_name
        , stem
    from cte_stg_luxury_hardware
)

select * from cte_final
