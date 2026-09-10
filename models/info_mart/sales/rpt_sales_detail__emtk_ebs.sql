-- report: sales detail

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

, cte_dim_sales_region as (
    select * from {{ ref('dim_sales_region') }}
)

, cte_dim_sales_territory as (
    select * from {{ ref('dim_sales_territory') }}
)

, cte_ref_oracle_lookup_values as (      --replaced comment out w/ qualify to remove duplicated records and pull the most recent loaded version of unique lookup_codes AC 6-10-2025
    select * 
    ,ROW_NUMBER() over ( partition by LOOKUP_CODE, LOOKUP_TYPE
    order by  _fivetran_synced desc ) AS row_num
    from {{ ref('ref_oracle_lookup_values__emtk_ebs') }}
    qualify row_num = 1
)

, cte_customer_class_lkup as (
    select
        lookup_code
        , meaning
    from cte_ref_oracle_lookup_values
    where lookup_type = 'CUSTOMER CLASS'
)

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
        , dim_icat.item_number
        , dim_itm.description as item_desc
        , dim_itm.finish
        , dim_itm.collection
        , dim_itm.item_department
        , dim_itm.is_purchasing_item
        , COALESCE(dim_inv.customer_trx_id, dim_iadj.customer_trx_id) as customer_trx_id
        , COALESCE(dim_inv.trx_number, dim_iadj.trx_number) as trx_number
        , COALESCE(dim_inv.purchase_order, dim_iadj.purchase_order) as purchase_order
        , COALESCE(dim_inv.order_num, dim_iadj.order_num) as order_num
        , COALESCE(dim_inv.order_type, dim_iadj.order_type) as order_type
        , dim_il.unit_standard_price
        , dim_il.unit_selling_price
        , dim_il.line_order_type
        , dim_il.description as invoice_line_description
        , COALESCE(dim_inv.bill_to_customer_id, dim_iadj.bill_to_customer_id) as bill_to_customer_id
        , COALESCE(dim_inv.primary_salesrep_id, dim_iadj.primary_salesrep_id) as primary_salesrep_id
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
        , dim_sa.sales_agency_number
        , dim_sa.sales_agency_description
        , dim_itm.item_cost
        , dim_itm.item_number || ' - ' || dim_itm.description as item_with_description
        , COALESCE(dim_inv.ship_to_site_use_id, dim_iadj.ship_to_site_use_id) as ship_to_site_use_id
        , COALESCE(dim_inv.bill_to_site_use_id, dim_iadj.bill_to_site_use_id) as bill_to_site_use_id
        , ccl.meaning as customer_class  --restored to facilitate use in dashboard AC 6-10-25
        -- , dim_cust.party_name
        , dim_cust.customer_account_name
        , dim_cust.account_number
        , dim_cust.attribute15 as product_channel
        , dim_cust.src_created_at as customer_created_date
        , dim_cust.customer_class_code
        , dim_cust.customer_account_name as customer_name
        , dim_cust.attribute2 as commission_rate
        , dim_cust.attribute15 as cust_prod_channel
        , dim_cust.attribute19 as cust_sales_region

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
        ) as transaction_type -- existing transaction type
        , COALESCE(dim_inv.transaction_type, dim_iadj.transaction_type) as transaction_class
        , dim_sr.group_desc as sales_region
        , dim_sr.group_desc as region_description
        , dim_il.attribute3 as linecomment2
        , dim_il.attribute4 as linecomment3
        , dim_st.territory_number
        , dim_st.territory_name
        , dim_pbcat.item_category as product_brand
        , ac.actual_cost
        , dim_il.line_number as invoice_line_number
        , dim_il.customer_trx_line_id as global_unique_line_number
        , fact_il.tracking_number
    from cte_fact_invoice_line as fact_il
        inner join cte_dim_customer as dim_cust
            on fact_il.dim_customer_pk = dim_cust.dim_customer_pk
        inner join cte_dim_customer_bill_location as dim_cbill
            on fact_il.dim_customer_bill_location_pk = dim_cbill.dim_customer_bill_location_pk
        inner join cte_dim_customer_ship_location as dim_cship
            on fact_il.dim_customer_ship_location_pk = dim_cship.dim_customer_ship_location_pk
        inner join cte_dim_invoice_line as dim_il
            on fact_il.dim_invoice_line_pk = dim_il.dim_invoice_line_pk
        left outer join cte_dim_invoice as dim_inv -- left join to invoice
            on fact_il.dim_invoice_pk = dim_inv.dim_invoice_pk
        left outer join cte_dim_invoice_adjustment as dim_iadj -- left join invoice adjustment
            on fact_il.dim_invoice_adjustment_pk = dim_iadj.dim_invoice_adjustment_pk
        inner join cte_dim_sales_agency as dim_sa
            on fact_il.dim_sales_agency_pk = dim_sa.dim_sales_agency_pk
        inner join cte_dim_sales_region as dim_sr
            on fact_il.dim_sales_region_pk = dim_sr.dim_sales_region_pk
        inner join cte_dim_sales_territory as dim_st
            on fact_il.dim_sales_territory_pk = dim_st.dim_sales_territory_pk
        inner join cte_dim_item as dim_itm
            on fact_il.dim_item_pk = dim_itm.dim_item_pk
        inner join cte_dim_item_category as dim_icat
            on fact_il.dim_item_inventory_category_pk = dim_icat.dim_item_category_pk
        left join cte_dim_item_category as dim_pbcat
            on fact_il.dim_item_product_brand_category_pk = dim_pbcat.dim_item_category_pk
        left join cte_customer_class_lkup as ccl --restored to facilitate customer discount code field in dashboard AC 6-10-2025
            on dim_cust.customer_class_code = ccl.lookup_code
        left join cte_actual_cost as ac
            on fact_il.dim_invoice_line_pk = ac.dim_invoice_line_pk
    -- limit to 5 years of data for Tableau                   
    where dim_il.line_type = 'LINE' --excluding TAX and FREIGHT
    --Tung confirmed these hidden filters from Oracle to enforce qualified invoices for "Commission Reporting"
        and (dim_icat.category_description is null or dim_icat.category_description <> 'F_CODES')
        and (dim_iadj.transaction_type is null or dim_iadj.transaction_type <> 'DM')
        and (dim_inv.order_type is null or dim_inv.order_type not ilike '%Display%')
        --limit data based on sliding yearly window based on trx_date (invoice date)
        and (
            (dim_inv.trx_date is not null and dim_inv.trx_date >= DATEADD(year, -5, CURRENT_DATE))
            or (dim_iadj.trx_date is not null and dim_iadj.trx_date >= DATEADD(year, -5, CURRENT_DATE))
        )
    /* This order is an invoice adjustment, and a fix for the Credit Memo was applied in Oracle to stop this problem. Since we can't change a closed order,
     a filter was added at the transaction level to manually exclude the record. These changes were made on 08/21/2024. */
         and not dim_il.customer_trx_id  in (7904898,7897601)
)

select * from cte_final
