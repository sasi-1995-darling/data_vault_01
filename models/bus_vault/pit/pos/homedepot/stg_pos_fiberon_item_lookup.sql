{{
    config(
        materialized='ephemeral'
    )
}}

with cte_sat_sales__homedepot as
(
 select * from   
    {{ ref('sat_sales__homedepot') }}    

),
cte_sat_sales__homedepot__latest as (
    select * from cte_sat_sales__homedepot
    where sales is not null and home_depot_account='Fiberon'
    qualify row_number() over(partition by day,sku_nbr,d_store_nbr,merch_vendor,manuf_part_number,fulfillment_channel,home_depot_account,sku_status order by load_dts desc)=1
), 
cte_sat_sales__homedepot__distinct as (
    select sku_nbr,manuf_part_number
    from cte_sat_sales__homedepot__latest
    group by all
),
xref as 
(select * 
    from {{ ref('ref_pos_home_depot_fiberon_xref') }}
    qualify row_number() over (partition by customer_sku_hk,fiberon_item_num_hk,fiberon_part_num_hk order by load_dts desc)=1
),
hdx_sku_join as 
(select hd.manuf_part_number,hd.sku_nbr,xref.oracle_item_id from cte_sat_sales__homedepot__distinct hd inner join xref on hd.sku_nbr=xref.sku),
hdx_mpn_join as 
(select hd.manuf_part_number,hd.sku_nbr,xref.oracle_item_id  from cte_sat_sales__homedepot__distinct hd inner join xref on hd.manuf_part_number=xref.manuf_part_number
 where xref.oracle_item_id not in(select oracle_item_id from hdx_sku_join)
),
pb as 
(select distinct item_number,item_hk,base_material from {{ ref('pb_items_by_plant') }} where bkcc='Jumping_River'
),
hdx_opn_join as 
(select hd.manuf_part_number,hd.sku_nbr,xref.oracle_item_id  from cte_sat_sales__homedepot__distinct hd inner join xref on hd.manuf_part_number=xref.oracle_item_id::varchar
 where xref.oracle_item_id not in(select oracle_item_id from hdx_mpn_join)
)
,full_xref as 
(select * from hdx_mpn_join union select * from hdx_sku_join union select * from hdx_opn_join)
select hd.sku_nbr,pb.item_hk
from cte_sat_sales__homedepot__distinct hd
left join full_xref f
on f.sku_nbr=hd.sku_nbr
left join pb
on f.oracle_item_id::varchar=pb.item_number