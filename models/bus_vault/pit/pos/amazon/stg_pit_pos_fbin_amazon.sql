{{
    config(
        materialized='ephemeral'
    )
}}

with cte_sat_sales__amazon as
(
 select * from   
    {{ ref('sat_sales__amazon') }}    

),
cte_sat_sales__amazon__latest as (
    select * from cte_sat_sales__amazon
    qualify row_number() over(partition by report_end_date, asin, vendorcentral_account,customer_returns order by load_dts desc)=1
), cte_sat_inventory__amazon as 
(
 select * from   
    {{ ref('sat_inventory__amazon') }} 

),
cte_sat_inventory__amazon__latest as (
    select * from cte_sat_inventory__amazon
    qualify row_number() over(partition by report_end_date, asin, vendorcentral_account order by load_dts desc)=1
),
cte_amazon_data as 
(

    select 
    coalesce(s.store_hk,i.store_hk) as store_hk,
    coalesce(s.report_end_date,i.report_end_date) as report_end_date,
    coalesce(s.asin,i.asin) as asin,
    s.shipped_units as shipped_units,
    s.shipped_revenue_amt as shipped_revenue_amt,
    i.sellable_oh_inv_units,
    i.sellable_oh_inv_amt,
    coalesce(s.vendorcentral_account,i.vendorcentral_account) as vendorcentral_account
    from cte_sat_sales__amazon__latest s
    full join
    cte_sat_inventory__amazon__latest i
    on 
    s.report_end_date=i.report_end_date
    and
    s.asin=i.asin
    and
    s.vendorcentral_account=i.vendorcentral_account

)

select
      hcl.store_hk
    , p.report_end_date as transaction_date    
    , to_char(transaction_date, 'YYYYMMDD') as transaction_datekey
    ,  'EC' as reporting_channel
    , null as item
    , p.asin as sku
    , hcl.store_bk as store_id
    , null as sku_status
    , p.shipped_units as pos_qty
    , p.shipped_revenue_amt as consumer_dollars
    , null as gross_dollars
    , sellable_oh_inv_units as inv_qty
    , sellable_oh_inv_amt as inv_consumer_dollars
    , p.vendorcentral_account as brand
    , null as shipping_city
    , null as shipping_state
    , null as shipping_zip
    , null as product_dest_zip
    , hcl.bkcc  
    , hcl.rec_src
from {{ ref('hub_store') }} as hcl
    inner join cte_amazon_data as p
        on hcl.store_hk = p.store_hk