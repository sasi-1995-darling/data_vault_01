{{
    config(
        materialized='ephemeral'
    )
}}

with cte_sat_sales__homedepot as
(
 select * from   
    {{ ref('sat_sales__homedepot') }}    where day<'2026-04-04'

),
cte_sat_sales__homedepot__latest as (
    select * from cte_sat_sales__homedepot
    where sales is not null
    qualify row_number() over(partition by day,sku_nbr,d_store_nbr,merch_vendor,manuf_part_number,fulfillment_channel,home_depot_account,sku_status order by load_dts desc)=1
),
cte_sat_store__homedepot as
(
 select * from   
    {{ ref('sat_store__homedepot') }}   

),
cte_sat_store__homedepot__latest as (
select * from cte_sat_store__homedepot
qualify row_number() over(partition by D_STORE_NBR order by load_dts desc)=1
),
cte_sat_inventory__homedepot as
(
 select * from   
    {{ ref('sat_inventory__homedepot') }}    where day<'2026-04-04'

),
cte_sat_inventory__homedepot__latest as (
    select * from cte_sat_inventory__homedepot
    where str_oh is not null
    qualify row_number() over(partition by store_hk, day, sku_nbr, manuf_part_number, d_store_nbr, merch_vendor, sku_status, home_depot_account order by load_dts desc)=1
),
cte_sat_dc_inv as (
    select * from 
    {{ ref('sat_dc_inventory_with_store__homedepot_ft') }}
),
cte_sat_dc_inv__latest as (
    select *,'EC' as fulfillment_channel from cte_sat_dc_inv
    where m_dc_oh_units is not null
    qualify row_number() over(partition by home_depot_account,day_1,manuf_part_number,sku_nbr,store_hk order by load_dts desc)=1
),
cte_sat_store__homedepot_ft as
(
 select * from   
    {{ ref('sat_store__homedepot_ft') }}

),
cte_sat_store__homedepot_ft__latest as (
select * from cte_sat_store__homedepot_ft
where PSA_DELETE_IND = 'N'
qualify row_number() over(partition by D_STORE_NBR order by load_dts desc)=1
),
cte_union_stores as (
select store_hk,d_city,state_territory_code, d_postal_code,load_dts
from cte_sat_store__homedepot_ft__latest
union all
select store_hk,d_city,state_territory_code, d_postal_code,load_dts
from cte_sat_store__homedepot__latest
),
cte_dedup_stores as  (
select
store_hk,d_city,state_territory_code,d_postal_code
from cte_union_stores
qualify row_number() over(partition by store_hk order by load_dts desc)=1
),
cte_stores as (
select store_hk,d_city,state_territory_code,d_postal_code
from
cte_dedup_stores
union
select store_hk,null as d_city,null as state_territory_code,null as d_postal_code
from
cte_sat_dc_inv__latest
group by all
),
cte_sat_sales__homedepot_ft as
(
 select * from   
    {{ ref('sat_sales__homedepot_ft') }}    where day>='2026-04-04'
),
cte_sat_sales__homedepot_ft__latest as (
    select * from cte_sat_sales__homedepot_ft
    where sales is not null
    qualify row_number() over(partition by day,sku_nbr,d_store_nbr,merch_vendor,manuf_part_number,fulfillment_channel,home_depot_account,sku_status order by load_dts desc)=1
),
cte_sat_inventory__homedepot_ft as
(
 select * from   
    {{ ref('sat_inventory__homedepot_ft') }}    where day>='2026-04-04'

),
cte_sat_inventory__homedepot_ft__latest as (
    select * from cte_sat_inventory__homedepot_ft
    where str_oh is not null
    qualify row_number() over(partition by store_hk, day, sku_nbr, manuf_part_number, d_store_nbr, merch_vendor, sku_status, home_depot_account order by load_dts desc)=1
),
cte_sales as (
select store_hk,d_store_nbr,day,fulfillment_channel,manuf_part_number,sku_nbr,sku_status,merch_vendor,sales_units,sales,home_depot_account,load_dts
from 
cte_sat_sales__homedepot__latest
union
select store_hk,d_store_nbr,day,fulfillment_channel,manuf_part_number,sku_nbr,sku_status,merch_vendor,sales_units,sales,home_depot_account,load_dts
from 
cte_sat_sales__homedepot_ft__latest
),
cte_inventory as (
select store_hk,d_store_nbr,day,manuf_part_number,sku_nbr,sku_status,merch_vendor,str_oh,str_oh_units_dly,home_depot_account
from cte_sat_inventory__homedepot__latest
union 
select store_hk,d_store_nbr,day,manuf_part_number,sku_nbr,sku_status,merch_vendor,str_oh,str_oh_units_dly,home_depot_account
from cte_sat_inventory__homedepot_ft__latest
)
select
      hcl.store_hk
    , dateadd(day, 1, p.day) as transaction_date    
    , to_char(transaction_date, 'YYYYMMDD') as transaction_datekey
    , case when p.fulfillment_channel = 'In Store' then  'RT'
            when p.fulfillment_channel = 'DTC' then  'EC'
            else 'EC'
    end as reporting_channel
    , p.manuf_part_number as item
    , p.sku_nbr as sku
    , p.d_store_nbr as store_id
    , p.sku_status
    , p.sales_units::FLOAT as pos_qty
    , p.sales as consumer_dollars
    , null as gross_dollars
    , p.str_oh_units_dly    as inv_qty
    , p.str_oh              as inv_consumer_dollars
    , p.home_depot_account as brand
    , l.d_city as shipping_city
    , l.state_territory_code as shipping_state
    , l.d_postal_code as shipping_zip
    , null as product_dest_zip
    , hcl.bkcc
    , hcl.rec_src
from {{ ref('hub_store') }} as hcl
    inner join cte_stores as l
        on hcl.store_hk = l.store_hk 
    inner join 
    (select
    coalesce(h.day,s.day) as day
    , coalesce(h.fulfillment_channel,'In Store')        as fulfillment_channel
    , coalesce(h.manuf_part_number,s.manuf_part_number) as manuf_part_number
    , coalesce(h.sku_nbr,s.sku_nbr) as sku_nbr
    , coalesce(h.d_store_nbr,s.d_store_nbr) as d_store_nbr
    , coalesce(h.sku_status,s.sku_status) as sku_status
    , h.sales_units as sales_units
    , h.sales as sales
    , null as gross_dollars
    , s.str_oh as str_oh
    , s.str_oh_units_dly as str_oh_units_dly
    , coalesce(h.home_depot_account,s.home_depot_account) as home_depot_account
    , coalesce(h.store_hk,s.store_hk) as store_hk
    from
      cte_sales h
      full join
      cte_inventory s
      on
      h.store_hk=s.store_hk and
      h.day=s.day and
      h.sku_nbr=s.sku_nbr and 
      h.manuf_part_number=s.manuf_part_number and
      h.d_store_nbr=s.d_store_nbr and
      h.merch_vendor=s.merch_vendor and
      h.fulfillment_channel = 'In Store' and
      h.home_depot_account=s.home_depot_account
	  union
	  select
	  day_1 as day,
	  fulfillment_channel,
	  manuf_part_number,
	  sku_nbr,
	  d_dh_dc_nbr as d_store_nbr,
	  '' as sku_status,
	  0 as sales_units,
	  0 as sales,
	  null as gross_dollars,
	  m_dc_oh_amt as str_oh,
	  m_dc_oh_units as str_oh_units_dly,
	  home_depot_account,
	  store_hk
	 from
	 cte_sat_dc_inv__latest
	  ) as p
      on hcl.store_hk = p.store_hk