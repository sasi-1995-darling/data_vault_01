-- fact invoice line

with cte_link_invoice_adj_invoice_line as (
    select * from {{ ref('link_invoice_adj_invoice_line') }}
)

, cte_link_invoice_adjustment_customer as (
    select * from {{ ref('link_invoice_adjustment_customer') }}
)

, cte_link_invoice_customer as (
    select * from {{ ref('link_invoice_customer') }}
)

, cte_link_invoice_invoice_line as (
    select * from {{ ref('link_invoice_invoice_line') }}
)

, cte_link_invoice_line_item as (
    select * from {{ ref('link_invoice_line_item') }}
)

, cte_link_invoice_sales_agency as (
    select * from {{ ref('link_invoice_sales_agency') }}
)


, cte_link_sales_agency_group_latest as (   --replaced old cte reference to link_sales_agency_group to fix duplication issue SNOW INC0249235 AC 4-23-25
    select *
        , ROW_NUMBER() over (
            partition by sales_agency_hk
            order by load_dts desc
            ) AS row_num
    from {{ ref('link_sales_agency_group') }}
    qualify row_num = 1
)

, cte_link_invoice_delivery as (
    select * from {{ ref('link_invoice_delivery') }}
)

, cte_link_invoice_adj_sales_agency as (
    select * from {{ ref('link_invoice_adj_sales_agency') }}
)

-- invoice adjustment: latest satellite
, cte_sat_invoice_adjustment_detail__emtk_ebs as (
    select * from {{ ref('sat_invoice_adjustment_detail__emtk_ebs') }}
)

, cte_sat_invoice_adjustment as (
    {{ generate_cte_satellite_latest(
        cte_name='cte_sat_invoice_adjustment_detail__emtk_ebs'
        ,hk_field='invoice_adjustment_hk') }}
)

-- invoice: latest satellite
, cte_sat_invoice_detail__emtk_ebs as (
    select * from {{ ref('sat_invoice_detail__emtk_ebs') }}
)

, cte_sat_invoice as (
    {{ generate_cte_satellite_latest(
        cte_name='cte_sat_invoice_detail__emtk_ebs'
        ,hk_field='invoice_hk') }}
)

-- invoice line: latest satellite
, cte_sat_invoice_line_detail__emtk_ebs as (
    select * from {{ ref('sat_invoice_line_detail__emtk_ebs') }}
)

, cte_sat_invoice_line as (
    {{ generate_cte_satellite_latest(
        cte_name='cte_sat_invoice_line_detail__emtk_ebs'
        ,hk_field='invoice_line_hk') }}
)

-- customer: latest satellite
, cte_sat_customer_detail__emtk_ebs as (
    select * from {{ ref('sat_customer_detail__emtk_ebs') }}
)

, cte_sat_customer as (
    {{ generate_cte_satellite_latest(
        cte_name='cte_sat_customer_detail__emtk_ebs'
        ,hk_field='customer_hk') }}
)

-- customer bill location: latest satellite
, cte_sat_customer_bill_detail__emtk_ebs as (
    select * from {{ ref('sat_customer_bill_detail__emtk_ebs') }}
)

, cte_sat_bill_location as (
    {{ generate_cte_satellite_latest(
        cte_name='cte_sat_customer_bill_detail__emtk_ebs'
        ,hk_field='customer_bill_location_hk') }}
)

-- customer ship location: latest satellite
, cte_sat_customer_ship_detail__emtk_ebs as (
    select * from {{ ref('sat_customer_ship_detail__emtk_ebs') }}
)

, cte_sat_ship_location as (
    {{ generate_cte_satellite_latest(
        cte_name='cte_sat_customer_ship_detail__emtk_ebs'
        ,hk_field='customer_ship_location_hk') }}
)

-- delivery: latest satellite
, cte_sat_delivery_detail__emtk_ebs as (
    select * from {{ ref('sat_delivery_detail__emtk_ebs') }}
)

, cte_sat_delivery as (
    {{ generate_cte_satellite_latest(
        cte_name='cte_sat_delivery_detail__emtk_ebs'
        ,hk_field='delivery_hk') }}
)

-- common: item inventory category 1/3
, cte_msat_item_category__emtk_ebs as (
    select * from {{ ref('msat_item_category__emtk_ebs') }}
)

-- common: item inventory category 2/3
, cte_msat_item_category__emtk_ebs__latest as (
    {{ generate_cte_satellite_latest(
        cte_name='cte_msat_item_category__emtk_ebs'
        ,hk_field='item_category_hk') }}
)

-- common: item inventory category 3/3
, cte_item_inventory_category as (
    select
        item_hk
        , item_category_hk
        , row_number() over (
            partition by item_hk
            order by last_update_date desc
        ) as row_num
    from cte_msat_item_category__emtk_ebs__latest
    where category_set_id = 1 -- inventory
)

, cte_item_product_brand_category as (
    select
        item_hk
        , item_category_hk
        , row_number() over (
            partition by item_hk
            order by last_update_date desc
        ) as row_num
    from cte_msat_item_category__emtk_ebs__latest
    where category_set_id = 1100000045 -- product brand
)

-- future ToDo: make fact_invoice_delivery table at the lower grain
, cte_tracking_number_rollup as (
    select
        lid.invoice_hk
        , sd.tracking_number
        , row_number() over (partition by lid.invoice_hk order by sd.creation_date desc) as row_num
    from cte_link_invoice_delivery as lid
        inner join cte_sat_delivery as sd
            on lid.delivery_hk = sd.delivery_hk
    where sd.tracking_number is not null
    qualify row_num = 1
)

, cte_invoice_line as (
    select
        liil.invoice_invoice_line_hk as fact_invoice_line_pk
        , sil.invoice_line_hk as dim_invoice_line_pk
        , si.invoice_hk as dim_invoice_pk
        , cast(md5_binary(-1) as BINARY(16)) as dim_invoice_adjustment_pk -- no adjustment
        , sc.customer_hk as dim_customer_pk
        , sbl.customer_bill_location_hk as dim_customer_bill_location_pk
        , ssl.customer_ship_location_hk as dim_customer_ship_location_pk
        , lsag.sales_territory_hk as dim_sales_agency_pk  --NOTE: raw vault has sales_agency and territories switched
        , lsag.sales_region_hk as dim_sales_region_pk
        , lisa.sales_agency_hk as dim_sales_territory_pk --NOTE: raw vault has sales_agency and territories switched
        --item_Hk ghost record created in raw vault
        , coalesce(lili.item_hk, cast(md5_binary('-1||-1||EMTEK') as BINARY(16))) as dim_item_pk
        , coalesce(iic.item_category_hk, cast(md5_binary(-1) as BINARY(16))) as dim_item_inventory_category_pk
        , ipbc.item_category_hk as dim_item_product_brand_category_pk
        , tnr.tracking_number
    from cte_sat_invoice_line as sil -- sat: invoice-line
        inner join cte_link_invoice_invoice_line as liil -- link: invoice to invoice-line
            on sil.invoice_line_hk = liil.invoice_line_hk
        inner join cte_sat_invoice as si -- sat: invoice
            on liil.invoice_hk = si.invoice_hk
        inner join cte_link_invoice_customer as lic -- link: invoice to customer
            on si.invoice_hk = lic.invoice_hk
        inner join cte_sat_customer as sc -- sat: customer
            on lic.customer_hk = sc.customer_hk
        inner join cte_sat_bill_location as sbl -- sat: bill-location
            on lic.customer_bill_location_hk = sbl.customer_bill_location_hk
        inner join cte_sat_ship_location as ssl -- sat: ship-location
            on lic.customer_ship_location_hk = ssl.customer_ship_location_hk
        inner join cte_link_invoice_sales_agency as lisa -- link: invoice to sales-agency
            on si.invoice_hk = lisa.invoice_hk
        inner join cte_link_sales_agency_group_latest as lsag -- link: sales agency group, replaced w latest cte to correct duplication issue SNOW INC0249235 AC 4-23-25
            on lisa.sales_agency_hk = lsag.sales_agency_hk
        inner join cte_link_invoice_line_item as lili -- link: invoice-line to item
            on sil.invoice_line_hk = lili.invoice_line_hk
        left outer join cte_item_inventory_category as iic -- common sat: item category
            on lili.item_hk = iic.item_hk
                and iic.row_num = 1
        left outer join cte_item_product_brand_category as ipbc -- product brand
            on lili.item_hk = ipbc.item_hk
                and ipbc.row_num = 1
        left outer join cte_tracking_number_rollup as tnr -- link: invoice to delivery (left only)
            on liil.invoice_hk = tnr.invoice_hk
                and tnr.row_num = 1

)

, cte_invoice_adjustment_line as (
    select
        liail.invoice_adj_invoice_line_hk as fact_invoice_line_pk
        , sil.invoice_line_hk as dim_invoice_line_pk
        , cast(md5_binary(-1) as BINARY(16)) as dim_invoice_pk -- no invoice
        , sia.invoice_adjustment_hk as dim_invoice_adjustment_pk
        , coalesce(sc.customer_hk, cast(md5_binary(-1) as BINARY(16))) as dim_customer_pk
        , coalesce(sbl.customer_bill_location_hk, cast(md5_binary(-1) as BINARY(16))) as dim_customer_bill_location_pk
        , cast(md5_binary(-1) as BINARY(16)) as dim_customer_ship_location_pk -- no ship location
        --NOTE: raw vault has sales_agency and territories switched
        , coalesce(lsag.sales_territory_hk, cast(md5_binary(-1) as BINARY(16))) as dim_sales_agency_pk
        , coalesce(lsag.sales_region_hk, cast(md5_binary(-1) as BINARY(16))) as dim_sales_region_pk
        --NOTE: raw vault has sales_agency and territories switched
        , coalesce(liasa.sales_agency_hk, cast(md5_binary(-1) as BINARY(16))) as dim_sales_territory_pk
        --item_Hk ghost record created in raw vault
        , coalesce(lili.item_hk, cast(md5_binary('-1||-1||EMTEK') as BINARY(16))) as dim_item_pk
        , coalesce(iic.item_category_hk, cast(md5_binary(-1) as BINARY(16))) as dim_item_inventory_category_pk
        , cast(md5_binary(-1) as BINARY(16)) as dim_item_product_brand_category_pk
        , null as tracking_number
    from cte_sat_invoice_line as sil -- sat: invoice-line
        inner join cte_link_invoice_adj_invoice_line as liail -- link: invoice-adjustment to invoice-line
            on sil.invoice_line_hk = liail.invoice_line_hk
        inner join cte_sat_invoice_adjustment as sia -- sat: invoice adjustment
            on liail.invoice_adjustment_hk = sia.invoice_adjustment_hk
        inner join cte_link_invoice_adjustment_customer as liac -- link: invoice adj to customer
            on sia.invoice_adjustment_hk = liac.invoice_adjustment_hk
        inner join cte_sat_customer as sc -- sat: customer; no outer rows
            on liac.customer_hk = sc.customer_hk
        inner join cte_sat_bill_location as sbl -- sat: bill-location; no outer rows
            on liac.customer_bill_location_hk = sbl.customer_bill_location_hk
        inner join cte_link_invoice_adj_sales_agency as liasa -- link invoice adj to sales agency   
            on sia.invoice_adjustment_hk = liasa.invoice_adjustment_hk
        inner join cte_link_sales_agency_group_latest as lsag -- link: sales agency group, replaced w latest cte to correct duplication issue SNOW INC0249235 AC 4-23-25
            on liasa.sales_agency_hk = lsag.sales_agency_hk
        inner join cte_link_invoice_line_item as lili -- link: invoice-line to item; no outer rows
            on sil.invoice_line_hk = lili.invoice_line_hk
        left outer join cte_item_inventory_category as iic -- common sat: item category
            on lili.item_hk = iic.item_hk
                and iic.row_num = 1
        left outer join cte_item_product_brand_category as ipbc -- product brand
            on lili.item_hk = ipbc.item_hk
                and ipbc.row_num = 1
)

, cte_final as (
    select * from cte_invoice_line
    union all
    select * from cte_invoice_adjustment_line
)

select * from cte_final
