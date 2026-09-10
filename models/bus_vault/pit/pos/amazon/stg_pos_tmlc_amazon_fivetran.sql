{{
    config(
        materialized='ephemeral'
    )
}}
--Start of merging sales and inventory
with 
cte_sat_sales_tmlc__amazon_fivetran as (
 select * from   
    {{ ref('sat_sales_tmlc__amazon_fivetran') }}    

)
, cte_sat_sales_tmlc__amazon_fivetran_latest as (
    select * from cte_sat_sales_tmlc__amazon_fivetran
    qualify row_number() over(partition by report_end_date, asin, vendorcentral_account,customer_returns order by load_dts desc)=1
)

, cte_sat_inventory_tmlc__amazon_fivetran as (
 select * from   
    {{ ref('sat_inventory_tmlc__amazon_fivetran') }} 

)
, cte_sat_inventory_tmlc__amazon_fivetran_latest as (
    select * from cte_sat_inventory_tmlc__amazon_fivetran
    qualify row_number() over(partition by report_end_date, asin, vendorcentral_account order by load_dts desc)=1
)
, cte_sat_inventory_tmlc__amazon_fivetran_converted_weekly as (
    select
          i.STORE_HK
        , i.LOAD_DTS
        , dateadd(
            day,
            6,
            dateadd(day, -mod(dayofweekiso(to_date(i.REPORT_START_DATE)), 7), to_date(i.REPORT_START_DATE))
          ) as REPORT_END_DATE
        , i.VENDORCENTRAL_ACCOUNT
        , i.ASIN
        , i.REPORT_START_DATE
        , i.NET_RECEIVED_INV_AMT
        , i.NET_RECEIVED_INV_CURRCD
        , i.NET_RECEIVED_INV_UNITS
        , i.OPEN_PO_UNITS
        , i.AVG_VENDOR_LEADTIME_DAYS
        , i.SELL_THROUGH_RATE
        , i.UNFILLED_CUST_ORDRD_UNITS
        , i.SELLABLE_OH_INV_AMT
        , i.SELLABLE_OH_INV_CURRCODE
        , i.SELLABLE_OH_INV_UNITS
        , i.UNSELLABLE_OH_INV_AMT
        , i.UNSELLABLE_OH_INV_CURRCODE
        , i.UNSELLABLE_OH_INV_UNITS
        , i.AGED_90DAYS_SELLABLE_INVAMT
        , i.AGED_90DAYS_SELLABLE_INVCURRCD
        , i.AGED_90DAYS_SELLABLE_INVUNITS
        , i.UNHEALTHY_INV_AMT
        , i.UNHEALTHY_INV_CURRCODE
        , i.UNHEALTHY_INV_UNITS
        , i.PSA_LOAD_DTS
        , i.PSA_RECORD_SOURCE
        , i.PSA_DELETE_IND
        , i.REC_SRC
        , i.BKCC
        , i.HASHDIFF
    from cte_sat_inventory_tmlc__amazon_fivetran_latest i
    qualify row_number() over (
        partition by
              i.VENDORCENTRAL_ACCOUNT
            , i.ASIN
            , dateadd(
                day,
                6,
                dateadd(day, -mod(dayofweekiso(to_date(i.REPORT_START_DATE)), 7), to_date(i.REPORT_START_DATE))
              )
        order by i.REPORT_START_DATE desc, i.LOAD_DTS desc
    ) = 1
)
, cte_tmlc_amazon_fivetran_data as (
    select 
    coalesce(s.store_hk,i.store_hk) as store_hk,
    coalesce(s.report_end_date,i.report_end_date) as report_end_date,
    coalesce(s.asin,i.asin) as asin,
    s.shipped_units as shipped_units,
    s.shipped_revenue_amt as shipped_revenue_amt,
    i.sellable_oh_inv_units,
    i.sellable_oh_inv_amt,
    coalesce(s.vendorcentral_account,i.vendorcentral_account) as vendorcentral_account
    from cte_sat_sales_tmlc__amazon_fivetran_latest s
    full join
    cte_sat_inventory_tmlc__amazon_fivetran_converted_weekly i
    on 
    s.report_end_date=i.report_end_date
    and
    s.asin=i.asin
    and
    s.vendorcentral_account=i.vendorcentral_account
)
, amazon_pos_base as (
    select
      hcl.store_hk
    , p.report_end_date as transaction_date    
    , to_char(p.report_end_date, 'YYYYMMDD') as transaction_datekey
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
    inner join cte_tmlc_amazon_fivetran_data as p
        on hcl.store_hk = p.store_hk
)
--End of merging sales, inventory with hub_store

-- Start of applying pos logic/ref to tmlc
, cte_basematerial_item_map as (
    select distinct
        base_material_key
        , first_value(item_hk) over (partition by base_material_key order by item_hk) as item_id
    from {{ ref('pb_items_by_plant') }}
)
, item_date as (
    select distinct
        p.sku as amazon_asin
        , map.item_id
        , x.model_number as base_material
        , p.transaction_date
    from amazon_pos_base as p
        left join {{ ref('ref_pos_amazon_tmlc_ss_xref_v1') }} as x
            on p.sku = x.asin
        left join cte_basematerial_item_map as map
            on x.base_material_hk = map.base_material_key
)
, gross_price_item_date as (
    select
        id.item_id
        , id.transaction_date
        , id.base_material
        , gp.gross_aup
        , row_number() over (partition by id.base_material, id.transaction_date order by gp.shipment_datekey) as rn
    from item_date as id
        left join {{ ref('ref_xref_gross_price') }} as gp
            on id.item_id = gp.item_hk and gp.key_account_number = '55' and gp.brand = 'MASTER LOCK'
                and TO_VARCHAR(id.transaction_date,'YYYYMMDD') >= gp.shipment_datekey
)
select
    i.item_id as item_id
    , pos.store_hk
    , pos.transaction_date
    , pos.transaction_datekey
    , pos.reporting_channel
    , pos.sku
    , pos.store_id
    , pos.sku_status
    , pos.pos_qty
    , pos.consumer_dollars
    , pos.pos_qty * gp.gross_aup as gross_dollars
    , pos.inv_qty
    , pos.inv_consumer_dollars
    , 'AMAZON' as reporting_customer
    , 'MASTER LOCK' as brand
    , pos.bkcc
    , pos.rec_src
from amazon_pos_base as pos
    left join {{ ref('ref_pos_amazon_tmlc_ss_xref_v1') }} as x
    on pos.sku = x.asin
    left join cte_basematerial_item_map as i
    on x.base_material_hk = i.base_material_key
    left join gross_price_item_date as gp
    on x.model_number = gp.base_material and gp.rn = 1 and pos.transaction_date = gp.transaction_date

