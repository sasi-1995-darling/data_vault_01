with cte_shipment as (
    select
        s.shipment_id
        , s.customer_id
        , s.customer
        , s.key_account_number
        , s.customer_account_name
        , i.business_unit
        , i.brand
        , i.sub_brand_name
        , s.item_id
        , i.item_number
        , i.base_material
        , i.item_type_code
        , i.item_status
        , i.item_category
        , i.item_sub_category
        , i.item_class
        , i.item_sub_class
        , s.sales_org
        , s.channel
        , s.invoiced_qty
        , s.return_qty
        , s.revenue_dollars
        , s.actual_returns_dollars
        , s.shipment_type
        , d.date as posted_date
        , d.fiscal_445_cal_day
        , d.fiscal_445_cal_week
        , d.fiscal_445_cal_month
        , d.fiscal_445_cal_quarter
        , d.fiscal_445_cal_year
        , d.fiscal_445_cal_quarter_yyyyqq
        , d.fiscal_445_cal_month_yyyymm
        , d.fiscal_445_cal_week_yyyyww
        , d.fiscal_445_working_day_flag
        , d.is_completed_fiscal_month
        , d.is_completed_fiscal_week
        , d.fiscal_last_week_flag
        , d.fiscal_last_4_weeks_flag
        , d.fiscal_last_13_weeks_flag
        , d.fiscal_last_month_flag
        , d.fiscal_last_3_months_flag
        , d.month_name
        , d.month_name_abbr
        , d.epoch_day
        , d.epoch_week
        , d.epoch_month
        , d.weeks_in_month
        , d.month_number_leading_zero
        , d.fiscal_day_of_year
        , d.fiscal_ytd_flag
        , d.fiscal_rolling_52_week_flag
        , d.fiscal_last_quarter_flag
        , d.fiscal_last_12_months_flag
        , d.fiscal_qtd_flag
        , s.brand as data_source
        , s.sales_document  --added for moen shipment enhancement 2025-09-12
        , s.sales_deal  --added for moen shipment enhancement 2025-09-12
        , s.customer_purchase_order_type --added for moen shipment enhancement 2025-09-12
        , s.order_category  --added for moen shipment enhancement 2025-10-28
        , s.copa_record_type  --added for moen shipment enhancement 2025-10-28
        , i.item_description  --added for moen shipment enhancement 2025-10-28
        , i.item_reporting_category  --added for moen shipment enhancement 2025-10-28
        , i.item_room_area_detail  --added for moen shipment enhancement 2025-10-28
        , i.item_price_band  --added for moen shipment enhancement 2025-10-28
        , i.pns_price_band  --added for moen shipment enhancement 2025-10-28
        , i.item_product_line  --added for moen shipment enhancement 2025-10-28
        , i.item_finish  --added for moen shipment enhancement 2025-10-28
        , i.item_product_type --added for moen item enhancement 2026-01-20
        , s.division_bk as division  --added for moen shipment enhancement 2025-10-28
        , cs.buying_group_id as customer_buying_group_id  --added for moen shipment enhancement 2025-10-28
        , cs.reporting_district  --added for moen shipment enhancement 2025-10-28
        , cs.sales_group  --added for moen shipment enhancement 2025-10-28
        , cs.sales_office  --added for moen shipment enhancement 2025-10-28
        , c.region as customer_state  --added for moen shipment enhancement 2025-10-28
        , c.city as customer_city  --added for moen shipment enhancement 2025-10-28
        , c.postal_code as customer_postal_code  --added for moen shipment enhancement 2025-10-28
        , s.rec_src --added 2025-09-12
        , s.bkcc --added 2025-09-12
    from {{ ref('fact_shipment') }} as s
        left join {{ ref('dim_item_brand') }} as i
            on s.item_id = i.item_id
        left join {{ ref('im_shipments_dim_date_fiscal_445') }} as d
            on s.posted_datekey = d.date_bk
        left join {{ ref('im_shipments_dim_customer_sales_attributes') }} as cs
            on s.customer_sales_attributes_key = cs.customer_sales_attributes_key
        left join {{ ref('im_shipments_dim_customer') }} as c
            on cs.customer_hk = c.customer_hk
)

select
    shipment_id
    , cast(customer_id as varchar(100)) as customer_id
    , customer
    , key_account_number
    , customer_account_name
    , cast(business_unit as varchar(100)) as business_unit
    , cast(brand as varchar(100)) as brand
    , cast(sub_brand_name as varchar(100)) as sub_brand_name
    , item_id
    , cast(item_number as varchar(100)) as item_number
    , cast(base_material as varchar(250)) as base_material
    , cast(item_type_code as varchar(100)) as item_type_code
    , item_status
    , cast(item_category as varchar(100)) as item_category
    , item_sub_category
    , cast(item_class as varchar(100)) as item_class
    , cast(item_sub_class as varchar(100)) as item_sub_class
    , cast(sales_org as varchar(100)) as sales_org
    , cast(channel as varchar(100)) as channel
    , invoiced_qty
    , return_qty
    , revenue_dollars
    , actual_returns_dollars
    , cast(shipment_type as varchar(100)) as shipment_type
    , posted_date
    , fiscal_445_cal_day
    , fiscal_445_cal_week
    , fiscal_445_cal_month
    , fiscal_445_cal_quarter
    , fiscal_445_cal_year
    , fiscal_445_cal_quarter_yyyyqq
    , fiscal_445_cal_month_yyyymm
    , fiscal_445_cal_week_yyyyww
    , cast(fiscal_445_working_day_flag as varchar(100)) as fiscal_445_working_day_flag
    , is_completed_fiscal_month
    , is_completed_fiscal_week
    , fiscal_last_week_flag
    , fiscal_last_4_weeks_flag
    , fiscal_last_13_weeks_flag
    , fiscal_last_month_flag
    , fiscal_last_3_months_flag
    , month_name
    , month_name_abbr
    , epoch_day
    , epoch_week
    , epoch_month
    , weeks_in_month
    , month_number_leading_zero
    , fiscal_day_of_year
    , fiscal_ytd_flag
    , fiscal_rolling_52_week_flag
    , fiscal_last_quarter_flag
    , fiscal_last_12_months_flag
    , fiscal_qtd_flag
    , data_source
    , sales_document   
    , sales_deal    
    , customer_purchase_order_type 
    , order_category
    , copa_record_type
    , item_description
    , item_reporting_category
    , item_room_area_detail
    , item_price_band
    , pns_price_band
    , item_product_line
    , item_finish
    , item_product_type
    , division
    , customer_buying_group_id
    , reporting_district
    , sales_group
    , sales_office
    , customer_state
    , customer_city
    , customer_postal_code
    , rec_src   
    , bkcc  
from cte_shipment
