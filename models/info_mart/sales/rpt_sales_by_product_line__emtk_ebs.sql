-- report sales by product line

with cte_fact_invoice_line as (
    select * from {{ ref('fact_invoice_line') }}
    -- where brand = 'EMTEK'
)

, cte_fact_invoice_line_transaction as (
    select * from {{ ref('fact_invoice_line_transaction') }}
    -- where brand = 'EMTEK'
)

, cte_dim_item as (
    select * from {{ ref('dim_item') }}
)

, cte_dim_item_category as (
    select * from {{ ref('dim_item_category') }}
)

, cte_dim_customer as (
    select * from {{ ref('dim_customer') }}
)

, cte_dim_customer_bill_location as (
    select * from {{ ref('dim_customer_bill_location') }}
)

, cte_dim_customer_ship_location as (
    select * from {{ ref('dim_customer_ship_location') }}
)

, cte_dim_invoice as (
    select * from {{ ref('dim_invoice') }}
)

, cte_dim_invoice_adjustment as (
    select * from {{ ref('dim_invoice_adjustment') }}
)

, cte_dim_invoice_line as (
    select * from {{ ref('dim_invoice_line') }}
)

, cte_dim_sales_agency as (
    select * from {{ ref('dim_sales_agency') }}
)

-- , cte_dim_sales_region as (
--     select * from {{ ref('dim_sales_region') }}
-- )

-- , cte_dim_sales_territory as (
--     select * from {{ ref('dim_sales_territory') }}
-- )

, cte_actual_cost as (
    select
        dim_invoice_line_pk
        , actual_cost
        , ROW_NUMBER()
            over (partition by dim_invoice_line_pk order by transaction_date desc, transaction_id desc)
            as row_num
    from cte_fact_invoice_line_transaction
    qualify row_num = 1
)

, cte_final as (
    select
        DECODE(COALESCE(dim_inv.org_id, dim_iadj.org_id), 101, 'EMTEK', 181, 'SCHAUB') as operating_unit
        , dim_itm.src_item_id
        , dim_il.customer_trx_line_id
        , dim_icat.item_number
        , dim_itm.description as item_desc
        , dim_itm.collection
        , dim_itm.item_department
        , dim_itm.is_purchasing_item -- purchasing_enabled_flag
        , COALESCE(dim_inv.customer_trx_id, dim_iadj.customer_trx_id) as customer_trx_id
        , COALESCE(dim_inv.trx_number, dim_iadj.trx_number) as trx_number
        , COALESCE(dim_inv.order_num, dim_iadj.order_num) as order_num
        , COALESCE(dim_inv.order_type, dim_iadj.order_type) as order_type
        , COALESCE(dim_inv.purchase_order, dim_iadj.purchase_order) as purchase_order
        , COALESCE(dim_inv.ship_via, dim_iadj.ship_via) as ship_via
        , fact_il.tracking_number
        , dim_il.unit_standard_price
        , dim_il.unit_selling_price
        , dim_il.line_order_type
        , dim_il.description as invoice_line_description
        , dim_il.sales_order
        , dim_il.sales_order_line
        , dim_il.line_type
        , COALESCE(dim_inv.bill_to_customer_id, dim_iadj.bill_to_customer_id) as bill_to_customer_id
        , dim_inv.primary_salesrep_id
        , dim_il.quantity_invoiced
        , dim_il.quantity_credited
        , dim_il.extended_amount
        , COALESCE(dim_inv.trx_date, dim_iadj.trx_date) as trx_date
        , TO_DATE(COALESCE(dim_inv.src_created_at, dim_iadj.src_created_at)) as invoice_date
        , TO_CHAR(COALESCE(dim_inv.trx_date, dim_iadj.trx_date), 'MON-YYYY') as trans_month
        , TO_CHAR(COALESCE(dim_inv.trx_date, dim_iadj.trx_date), 'YYYY') as trans_yr
        , dim_icat.src_category_id
        , dim_icat.src_category_group_id
        , dim_icat.structure_id
        , dim_icat.item_category || '.' || dim_icat.item_sub_category as category_set
        , dim_icat.item_category
        , dim_icat.item_sub_category
        , COALESCE(dim_icat.category_description, 'Misc Charges') as category_description
        , dim_cust.account_number
        , dim_cust.attribute15 as product_channel
        , dim_sa.sales_agency_number
        , dim_sa.sales_agency_description
        , dim_itm.item_cost
        , dim_itm.item_number || ' - ' || dim_itm.description as item_with_description
        , COALESCE(dim_inv.ship_to_site_use_id, dim_iadj.ship_to_site_use_id) as ship_to_site_use_id
        , COALESCE(dim_inv.bill_to_site_use_id, dim_iadj.bill_to_site_use_id) as bill_to_site_use_id
        -- , flv.meaning AS customer_class --missing FND_LOOKUP_VALUES
        -- , hp.party_id -- missing HZ_PARTIES
        -- , hp.party_name -- missing HZ_PARTIES
        , dim_cust.cust_account_id
        , dim_cust.src_created_at as customer_created_date
        , dim_cust.customer_class_code
        , dim_cust.customer_account_name
        , dim_cust.attribute2 as commission_rate
        , dim_cust.attribute15 as cust_prod_channel

        , dim_cbill.address1 as bill_to_add1
        , dim_cbill.address2 as bill_to_add2
        , dim_cbill.city as bill_to_city
        , dim_cbill.state as bill_to_state
        , dim_cbill.county as bill_to_county
        , dim_cbill.postal_code as bill_to_postal_code
        , dim_cbill.country as bill_to_country
        , dim_cbill.location as bill_to_location

        , dim_cship.address1 as ship_to_add1
        , dim_cship.address2 as ship_to_add2
        , dim_cship.city as ship_to_city
        , dim_cship.state as ship_to_state
        , dim_cship.county as ship_to_county
        , dim_cship.postal_code as ship_to_postal_code
        , dim_cship.country as ship_to_country
        , dim_cship.location as ship_to_location

        -- missing lookup to RA_CUST_TRX_TYPES_ALL.name
        , DECODE(
            COALESCE(dim_inv.cust_trx_type_id, dim_iadj.cust_trx_type_id)
            , 1001
            , 'Emtek Invoice'
            , 1064
            , 'Schaub Invoice'
            , 'Adjustment'
        )
            as transaction_type
        , COALESCE(dim_inv.transaction_type, dim_iadj.transaction_type) as transaction_class
        , ac.actual_cost
        , COALESCE(
            DECODE(dim_iadj.transaction_type, 'CM', dim_il.quantity_credited, dim_il.quantity_invoiced), 0
        ) as trans_pieces
        , dim_itm.launch_date
    from cte_fact_invoice_line as fact_il
        inner join cte_dim_invoice_line as dim_il
            on fact_il.dim_invoice_line_pk = dim_il.dim_invoice_line_pk
        inner join cte_dim_customer as dim_cust
            on fact_il.dim_customer_pk = dim_cust.dim_customer_pk
        inner join cte_dim_customer_bill_location as dim_cbill
            on fact_il.dim_customer_bill_location_pk = dim_cbill.dim_customer_bill_location_pk
        inner join cte_dim_customer_ship_location as dim_cship
            on fact_il.dim_customer_ship_location_pk = dim_cship.dim_customer_ship_location_pk
        left outer join cte_dim_invoice as dim_inv
            on fact_il.dim_invoice_pk = dim_inv.dim_invoice_pk
        left outer join cte_dim_invoice_adjustment as dim_iadj
            on fact_il.dim_invoice_adjustment_pk = dim_iadj.dim_invoice_adjustment_pk
        inner join cte_dim_sales_agency as dim_sa
            on fact_il.dim_sales_agency_pk = dim_sa.dim_sales_agency_pk
        inner join cte_dim_item as dim_itm
            on fact_il.dim_item_pk = dim_itm.dim_item_pk
        inner join cte_dim_item_category as dim_icat
            on fact_il.dim_item_inventory_category_pk = dim_icat.dim_item_category_pk
        left join cte_actual_cost as ac
            on fact_il.dim_invoice_line_pk = ac.dim_invoice_line_pk
    -- limit to 5 years of data for Tableau                   
    where (
        dim_inv.trx_date is not null and dim_inv.trx_date >= DATEADD(year, -5, CURRENT_DATE)
        or dim_iadj.trx_date is not null and dim_iadj.trx_date >= DATEADD(year, -5, CURRENT_DATE)
    )
)

select * from cte_final
