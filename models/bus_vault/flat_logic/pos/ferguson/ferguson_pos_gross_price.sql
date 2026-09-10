{{
    config(
        materialized='table'
    )
}}

with weekly_pos as (
    select distinct
        t1.date
        , x.sap_material_number
    from {{ ref('sat_pos_product_customer__ferguson_extract') }} as t1
        left join {{ ref('ref_pos_product_code_sap_xref__ferguson_extract') }} as x
            on t1.fei_product_code = x.fei_product_code
)

, base_material_gross_price as (
    select gp.* exclude(brand), rim.* from {{ ref('ref_xref_gross_price') }} as gp
    left join {{ ref('ref_item_master') }} rim 
            on rim.item_id = gp.item_id
)

, hofr_gross_price_dollrzn as (
    select
        p.sap_material_number
        , p.date
        , gp.shipment_date
        , gp.gross_aup
        , row_number() over (partition by p.sap_material_number, p.date order by gp.shipment_date desc) as rn
        , brand
    from weekly_pos as p
        left join base_material_gross_price as gp
            on p.sap_material_number = gp.base_material
                and gp.key_account_number = '101'
                and gp.brand in ('HOUSE OF ROHL', 'ROHL')
                and p.date >= gp.shipment_date
    qualify rn = 1

)

, moen_gross_price_dollrzn as (
    select
        p.sap_material_number
        , p.date
        , gp.shipment_date
        , gp.gross_aup
        , row_number() over (partition by p.sap_material_number, p.date order by gp.shipment_date desc) as rn
        , brand
    from weekly_pos as p
        left join base_material_gross_price as gp
            on p.sap_material_number = gp.base_material
                and gp.key_account_number = '101'
                and gp.brand in ('MOEN')
                and p.date >= gp.shipment_date
    qualify rn = 1

)

, gross_price_dollrzn as (
    select * from hofr_gross_price_dollrzn
    union
    select * from moen_gross_price_dollrzn
)


, gross_price as (
    select
        sap_material_number
        , date
        , gross_aup as gross_sales_before_incentives
        , case when brand in ('ROHL', 'HOUSE OF ROHL') then 'HOFR'
            else brand
        end as brand
    from gross_price_dollrzn where rn = 1
)

select * from gross_price
where gross_sales_before_incentives is not null
