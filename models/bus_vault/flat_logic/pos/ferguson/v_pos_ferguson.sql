{{
    config(
        materialized='table'
    )
}}

with

cte_sat_pos_product_customer__ferguson_extract as (

    select * from {{ ref('sat_pos_product_customer__ferguson_extract') }}
)

, cte_sat_pos_product_customer__ferguson_extract__latest as (
    {{ generate_cte_satellite_latest(
        cte_name='cte_sat_pos_product_customer__ferguson_extract'
        ,hk_field='product_customer_hk') }}
)

, cte_sat_pos_customer_location__ferguson_extract as (

    select * from {{ ref('sat_pos_customer_location__ferguson_extract') }}
)

, cte_sat_pos_customer_location__ferguson_extract_latest as (
    {{ generate_cte_satellite_latest(
        cte_name='cte_sat_pos_customer_location__ferguson_extract'
        ,hk_field='customer_location_hk') }}
)

, mapped_pos as (
    select distinct
        t1.*
        , x.sap_material_number
    from cte_sat_pos_product_customer__ferguson_extract__latest as t1
        left join {{ ref('ref_pos_product_code_sap_xref__ferguson_extract') }} as x
            on t1.fei_product_code = x.fei_product_code

)

, consumer_price as (
    select distinct
        t2.model
        , t1.date
        , first_value(t2.price)
            over (partition by t2.model, t1.date order by abs(datediff('day', t1.date, t2.date)))
            as price
    from mapped_pos as t1
        left join
            (
                select distinct
                    m.model
                    , p.date
                    , case
                        when
                            p.promotion_price is null
                            then first_value(p.regular_price)
                                    over (
                                        partition by m.model, p.date
                                        order by
                                            decode(
                                                p.retailer_id, -8821, 1, -11039, 2, -3029, 3, -2637, 4, -1333, 5, 1000
                                            )
                                    )
                        else first_value(p.promotion_price)
                                over (
                                    partition by m.model, p.date
                                    order by
                                        decode(p.retailer_id, -8821, 1, -11039, 2, -3029, 3, -2637, 4, -1333, 5, 1000)
                                )
                    end as price
                from {{ ref('ref_product_master__profitero') }} as m
                    left join {{ ref('ref_price_availability_history__profitero') }} as p
                        on m.base_product_id = p.product_id
                where m.source = 'US WINN' and p.first_party_won_buy_box = 'TRUE'
                    and p.retailer_id in (-8821, -11039, -3029, -2637, -1333)
                    and (p.promotion_price is not null or p.regular_price is not null)
            )
                as t2
            on upper(t1.sap_material_number) = upper(t2.model)
                -- and abs(datediff('day', t1.date, t2.date)) < 30
)

, consumer_dollars as (
    select distinct
        t1.*
        , round(t1.shipped_qty * t2.price, 2) as consumer_dollars
    from mapped_pos as t1
        left join consumer_price as t2
            on t1.sap_material_number = t2.model
                and t1.date = t2.date
)

select distinct
    p.product_customer_hk
    , p.date as transaction_date
    , 'WH' as reporting_channel
    , coalesce(p.sap_material_number, 'N/A') as item
    , p.fei_product_code as sku
    , null as location_id
    , 'N/A' as sku_status
    , p.shipped_qty as pos_qty
    , p.consumer_dollars
    , null as inv_qty
    , null as inv_consumer_dollars
    , p.rec_src as brand
    , l.city as shipping_city
    , l.state as shipping_state
    , l.zip as shipping_zip
    , p.product_dest_zip
    , 'FERGUSON' as reporting_customer
    , p.shipped_qty * s.gross_sales_before_incentives as gross_dollars
from consumer_dollars as p
    left join cte_sat_pos_customer_location__ferguson_extract_latest as l
        on p.ship_location_id_hk = l.customer_location_hk
    left join {{ ref('ferguson_pos_gross_price') }} as s
        on p.sap_material_number = s.sap_material_number
            and p.date = s.date
            and (case when p.rec_src like 'MOEN%' then 'MOEN' when p.rec_src like 'HOFR%' then 'HOFR' else p.rec_src end) = s.brand
