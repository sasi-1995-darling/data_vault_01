--dim_supplier_site type 1
with cte_hub_supplier_site as (
    select * from {{ ref('hub_supplier_site') }}
)

, cte_sat_supplier_site_detail__emtk_ebs as (
    select * from {{ ref('sat_supplier_site_detail__emtk_ebs') }}
)

, cte_sat_supplier_site_detail__emtk_ebs__latest as (
    {{ generate_cte_satellite_latest(
        cte_name='cte_sat_supplier_site_detail__emtk_ebs'
        ,hk_field='supplier_site_hk') }}
)

, cte_sat_supplier_site_detail__emtk_ebs_renamed as (
    select
        supplier_site_hk
        , vendor_site_id as src_supplier_site_id
        , vendor_site_code
        , try_to_boolean(purchasing_site_flag) as is_purchasing_site
        , try_to_boolean(pay_site_flag) as is_pay_site
        , address_line1
        , address_lines_alt
        , address_line2
        , address_line3
        , city
        , state as state_abrev
        , zip
        , province
        , country
        , creation_date as src_created_at
        , last_update_date as src_last_updated_at
        , load_dts as valid_from
    from cte_sat_supplier_site_detail__emtk_ebs__latest
)

, cte_final as (

    select
        hub_ss.supplier_site_hk as dim_supplier_site_pk
        , hub_ss.supplier_site_bk as src_supplier_site_bk
        , hub_ss.brand
        , sat_ssd.src_supplier_site_id
        , sat_ssd.vendor_site_code
        , sat_ssd.is_purchasing_site
        , sat_ssd.is_pay_site
        , sat_ssd.address_line1
        , sat_ssd.address_lines_alt
        , sat_ssd.address_line2
        , sat_ssd.address_line3
        , sat_ssd.city
        , sat_ssd.state_abrev 
        , sat_ssd.zip
        , sat_ssd.province
        , sat_ssd.country
        , sat_ssd.src_created_at
        , sat_ssd.src_last_updated_at
        , sat_ssd.valid_from
    from cte_hub_supplier_site as hub_ss
        inner join cte_sat_supplier_site_detail__emtk_ebs_renamed as sat_ssd
            on hub_ss.supplier_site_hk = sat_ssd.supplier_site_hk
)

select * from cte_final
