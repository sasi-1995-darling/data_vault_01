select
    case when s.home_depot_account in ('Moen_CSI', 'Moen_Vendordrill_Data') then 'MOEN'
        when s.home_depot_account = 'Masterlock' then 'MASTER LOCK'
        when s.home_depot_account = 'Larson' then 'LARSON'
        else s.home_depot_account
    end as brand
    , 'HOME_DEPOT US' as customer
    , case when s.home_depot_account = 'Masterlock' then '53'
        when s.home_depot_account in ('Moen_CSI', 'Moen_Vendordrill_Data') then '102'
    end as key_account_number
    , s.day
    , case when r.hd_item is null then s.manuf_part_number else r.master_lock_item_description end as base_material
    , trunc((sum(s.sales) / sum(s.sales_units)), 2) as price
    , s.rec_src
from
    (
        select * from {{ ref('sat_pos_product_customer__hd_askuity') }}
        qualify row_number() over (partition by product_customer_hk order by load_dts desc) = 1
    ) as s
    left join
        {{ source('homedepot_bronze_reference', 'hd_tmlc_cross_ref') }} as r
        on s.sku_nbr = r.hd_item
where (coalesce(s.sales_units, 0) > 0 and coalesce(s.sales, 0) > 0)
group by s.day, base_material, brand, s.rec_src, key_account_number

union

select
    brand
    , 'LOWES' as customer
    , '' as key_account_customer
    , l.end_date as day
    , case
        when to_varchar(xref.lowes_sku) is null then to_varchar(l.item_id)
        else to_varchar(xref.lowes_sku)
    end as base_material
    , trunc((sum(l.ty_fulfilled_internet_sales) / sum(l.ty_fulfilled_internet_units)), 2) as price
    , rec_src
from
    (
        select * from {{ ref('sat_pos_customer_sales__lowes') }}
        qualify row_number() over (partition by customer_sales_hk order by load_dts desc) = 1
    ) as l
    left join (select * from {{ source('lowes_xref','lowes_moen_cross_reference') }} 
            qualify 1=row_number() over(partition by lowes_sku order by _fivetran_synced desc)) xref
        on l.item_id = xref.lowes_sku
where (
    coalesce(l.ty_fulfilled_internet_units, 0) > 0
    and coalesce(l.ty_fulfilled_internet_sales, 0) > 0
) and brand = 'MOEN'
group by l.end_date, base_material, brand, rec_src, key_account_customer


union

select
    brand
    , 'LOWES' as customer
    , '' as key_account_customer
    , l.end_date as day
    , case
        when to_varchar(xref.tmlc_sku) is null then to_varchar(l.item_id)
        else to_varchar(xref.tmlc_sku)
    end as base_material
    , trunc((sum(l.ty_fulfilled_internet_sales) / sum(l.ty_fulfilled_internet_units)), 2) as price
    , 'LOWES_VPP' as rec_src
from
    (
        select * from {{ ref('sat_pos_customer_sales__lowes') }}
        qualify row_number() over (partition by customer_sales_hk order by load_dts desc) = 1
    ) as l
    left join {{ source('lowes_xref','lowes_tmlc_cross_reference') }} as xref
        on l.item_id = xref.tmlc_sku
where (
    coalesce(l.ty_fulfilled_internet_units, 0) > 0
    and coalesce(l.ty_fulfilled_internet_sales, 0) > 0
) and brand = 'MASTER LOCK'
group by l.end_date, base_material, brand, rec_src, key_account_customer