-- dim_item_category type 1
with cte_msat_item_category__emtk_ebs as (
    select * from {{ ref('msat_item_category__emtk_ebs') }}
)

, cte_ref_item_category__emtk_ebs as (
    select * from {{ ref('ref_item_category__emtk_ebs') }}
)

, cte_ref_item_category_group__emtk_ebs as (
    select * from {{ ref('ref_item_category_group__emtk_ebs') }}
)

, cte_msat_item_category__emtk_ebs__latest as (
    {{ generate_cte_satellite_latest(
        cte_name='cte_msat_item_category__emtk_ebs'
        ,hk_field='item_category_hk') }}
)

, cte_msat_item_category__emtk_ebs_renamed as (
    select
        item_category_hk as dim_item_category_pk
        , item_hk as dim_item_pk
        , segment1 as item_number
        , category_id as src_category_id
        , category_set_id as src_category_group_id
        , inventory_item_id as src_item_id
        , org_id as operating_unit_code
        , decode(org_id, 101, 'EMTEK', 181, 'SCHAUB') as operating_unit_name
        , creation_date as src_created_at
        , last_update_date as src_last_updated_at
        , load_dts as valid_from
    from cte_msat_item_category__emtk_ebs__latest
)

, cte_ref_item_category__emtk_ebs_renamed as (
    select
        category_id as src_category_id
        , brand
        , coalesce(category_description, 'Misc Charges') as category_description
        , structure_id
        , item_category
        , item_sub_category
        , item_category || '.' || item_sub_category as item_category_set
        , try_to_boolean(enabled_flag) as is_enabled
    from cte_ref_item_category__emtk_ebs
)

, cte_ref_item_category_group__emtk_ebs_renamed as (
    select
        category_set_id as src_category_group_id
        , category_set_name as category_group_name
        , description as category_group_description
    from cte_ref_item_category_group__emtk_ebs
)

, cte_item_category as (
    select
        msat_ic.dim_item_category_pk
        , msat_ic.dim_item_pk
        , msat_ic.item_number
        , msat_ic.src_category_id
        , msat_ic.src_category_group_id
        , msat_ic.src_item_id
        , msat_ic.operating_unit_code
        , msat_ic.operating_unit_name
        , ref_ic.brand
        , ref_ic.item_category
        , ref_ic.category_description
        , ref_ic.structure_id
        , ref_ic.item_sub_category
        , ref_ic.item_category_set
        , ref_ic.is_enabled
        , ref_icg.category_group_name
        , ref_icg.category_group_description
        , msat_ic.src_created_at
        , msat_ic.src_last_updated_at
        , msat_ic.valid_from
    from cte_msat_item_category__emtk_ebs_renamed as msat_ic
        inner join cte_ref_item_category__emtk_ebs_renamed as ref_ic
            on msat_ic.src_category_id = ref_ic.src_category_id
        inner join cte_ref_item_category_group__emtk_ebs_renamed as ref_icg
            on msat_ic.src_category_group_id = ref_icg.src_category_group_id
)

, cte_default as (
    select
        cast(md5_binary(-1) as BINARY(16)) as dim_item_category_pk
        , null as dim_item_pk
        , null as item_number
        , null as src_category_id
        , null as src_category_group_id
        , null as src_item_id
        , null as operating_unit_code
        , null as operating_unit_name
        , null as brand
        , null as item_category
        , null as category_description
        , null as structure_id
        , null as item_sub_category
        , null as item_category_set
        , null as is_enabled
        , null as category_group_name
        , null as category_group_description
        , null as src_created_at
        , null as src_last_updated_at
        , to_timestamp('1900-01-01') as valid_from
)

, cte_final as (
    select * from cte_item_category
    union all
    select * from cte_default
)

select * from cte_final
