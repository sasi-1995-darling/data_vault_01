-- dim sales region

with cte_hub_sales_region as (
    select * from {{ ref('hub_sales_region') }}
)

, cte_sat_sales_region_detail__emtk_ebs as (
    select * from {{ ref('sat_sales_region_detail__emtk_ebs') }}
)

, cte_sat_sales_region_detail__emtk_ebs__latest as (
    {{ generate_cte_satellite_latest(
        cte_name='cte_sat_sales_region_detail__emtk_ebs'
        ,hk_field='sales_region_hk') }}
)

, cte_sat_sales_region_detail__emtk_ebs__renamed as (
    select
        sales_region_hk
        , group_name
        , group_id
        , group_desc
        , creation_date as src_created_at
        , last_update_date as src_last_updated_at
        , load_dts as valid_from
    from cte_sat_sales_region_detail__emtk_ebs__latest
)

, cte_sales_region as (
    select
        hub.sales_region_hk as dim_sales_region_pk
        , hub.sales_region_bk
        , hub.brand
        , sat.group_name
        , sat.group_id
        , sat.group_desc
        , sat.src_created_at
        , sat.src_last_updated_at
        , sat.valid_from
    from cte_hub_sales_region as hub
        inner join cte_sat_sales_region_detail__emtk_ebs__renamed as sat
            on hub.sales_region_hk = sat.sales_region_hk
)

, cte_default as (
    select
        CAST(MD5_BINARY(-1) as BINARY(16)) as dim_sales_region_pk
        , null as sales_region_bk
        , null as sub_brand
        , null as group_name
        , null as group_id
        , null as group_desc
        , null as src_created_at
        , null as src_last_updated_at
        , TO_TIMESTAMP('1900-01-01') as valid_from
)

, cte_final as (
    select * from cte_sales_region
    union all
    select * from cte_default
)

select * from cte_final
