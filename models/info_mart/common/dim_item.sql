-- dim_item type 1
with cte_hub_item as (
    select * from {{ ref('hub_item') }}
)

, cte_sat_item_base__emtk_ebs as (
    select * from {{ ref('sat_item_base__emtk_ebs') }}
)

, cte_sat_item_language__emtk_ebs as (
    select * from {{ ref('sat_item_language__emtk_ebs') }}
)

, cte_sat_item_cost__emtk_ebs as (
    select * from {{ ref('sat_item_cost__emtk_ebs') }}
)

, cte_sat_item_base__emtk_ebs__latest as (
    {{ generate_cte_satellite_latest(
        cte_name='cte_sat_item_base__emtk_ebs'
        ,hk_field='item_hk') }}
)

, cte_sat_item_language__emtk_ebs__latest as (
    {{ generate_cte_satellite_latest(
        cte_name='cte_sat_item_language__emtk_ebs'
        ,hk_field='item_hk') }}
)

, cte_sat_item_cost__emtk_ebs__latest as (
    {{ generate_cte_satellite_latest(
        cte_name='cte_sat_item_cost__emtk_ebs'
        ,hk_field='item_hk') }}
)

, cte_sat_item_base__emtk_ebs__renamed as (
    select
        item_hk
        , segment1 as item_number
        , inventory_item_id as src_item_id
        , org_id as operating_unit_code
        , decode(org_id, 101, 'EMTEK', 181, 'SCHAUB') as operating_unit_name
        , attribute11 as item_department
        , attribute_category
        , attribute2 as collection
        , attribute3 as finish
        , item_type
        , try_to_boolean(purchasing_item_flag) as is_purchasing_item
        , try_to_boolean(shippable_item_flag) as is_shippable_item
        , try_to_boolean(customer_order_flag) as is_customer_order_item
        , web_status
        , list_price_per_unit
        , primary_unit_of_measure
        , inventory_item_status_code
        , creation_date as src_created_at
        , last_update_date as src_last_updated_at
        , load_dts as valid_from
        , coalesce(try_to_date(left(attribute12,10), 'YYYY/MM/dd'), to_date(creation_date)) as launch_date
    from cte_sat_item_base__emtk_ebs__latest
)

, cte_sat_item_language__emtk_ebs__renamed as (
    select
        item_hk
        , description
        , language as description_language
    from cte_sat_item_language__emtk_ebs__latest
)

, cte_sat_item_cost__emtk_ebs__renamed as (
    select
        item_hk
        , item_cost
    from cte_sat_item_cost__emtk_ebs__latest
)

, cte_final as (
    select
        hub_i.item_hk as dim_item_pk
        , hub_i.item_bk as src_item_bk
        , hub_i.brand
        , sat_ib.item_number
        , sat_ib.src_item_id
        , sat_il.description
        , sat_il.description_language
        , sat_ib.operating_unit_code
        , sat_ib.operating_unit_name
        , sat_ib.item_department
        , sat_ib.attribute_category
        , sat_ib.collection
        , sat_ib.finish
        , sat_ib.item_type
        , sat_ib.is_purchasing_item
        , sat_ib.is_shippable_item
        , sat_ib.is_customer_order_item
        , sat_ib.web_status
        , sat_ib.list_price_per_unit
        , sat_ib.primary_unit_of_measure
        , sat_ib.inventory_item_status_code
        , sat_ib.src_created_at
        , sat_ib.src_last_updated_at
        , sat_ib.valid_from
        , sat_ic.item_cost
        , sat_ib.launch_date
    from cte_hub_item as hub_i
        inner join cte_sat_item_base__emtk_ebs__renamed as sat_ib
            on hub_i.item_hk = sat_ib.item_hk
        --sat_item_language does not have the ghost record, so just left join for now
        --attributes are okay to be NULL
        left join cte_sat_item_language__emtk_ebs__renamed as sat_il
            on hub_i.item_hk = sat_il.item_hk
        left join cte_sat_item_cost__emtk_ebs__renamed as sat_ic
            on hub_i.item_hk = sat_ic.item_hk
)

select * from cte_final
