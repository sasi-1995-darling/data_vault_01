--dim_supplier type 1
with cte_hub_supplier as (
    select * from {{ ref('hub_supplier') }}
)

, cte_sat_supplier_detail__emtk_ebs as (
    select * from {{ ref('sat_supplier_detail__emtk_ebs') }}
)

, cte_sat_supplier_detail__emtk_ebs__latest as (
    {{ generate_cte_satellite_latest(
        cte_name='cte_sat_supplier_detail__emtk_ebs'
        ,hk_field='supplier_hk') }}
)

, cte_sat_supplier_detail__emtk_ebs_renamed as (
    select
        supplier_hk
        , vendor_id as src_supplier_id
        , vendor_name as supplier_name
        , vendor_name_alt as supplier_name_alt
        , tax_reporting_name
        , try_to_boolean(state_reportable_flag) as is_state_reportable
        , try_to_boolean(federal_reportable_flag) as is_federal_reportable
        , creation_date as src_created_at
        , last_update_date as src_last_updated_at
        , load_dts as valid_from
    from cte_sat_supplier_detail__emtk_ebs__latest
)

, cte_final as (

    select
        hub_s.supplier_hk as dim_supplier_pk
        , hub_s.supplier_bk as src_supplier_bk
        , hub_s.brand
        , sat_sd.src_supplier_id
        , sat_sd.supplier_name
        , sat_sd.supplier_name_alt
        , sat_sd.tax_reporting_name
        , sat_sd.is_state_reportable
        , sat_sd.is_federal_reportable
        , sat_sd.src_created_at
        , sat_sd.src_last_updated_at
        , sat_sd.valid_from
    from cte_hub_supplier as hub_s
        inner join cte_sat_supplier_detail__emtk_ebs_renamed as sat_sd
            on hub_s.supplier_hk = sat_sd.supplier_hk
)

select * from cte_final
