with cte_hsales as (
    select * from {{ source('bronze_hofr_eclipse', 'hofr_us_sales') }}
)

, cte_xref as (
    select * from {{ source('bronze_hofr_eclipse', 'eclipse_sap_cust_xref') }}
)

select
    cte_hsales.fiscaldate_key
    , cte_hsales.datasource
    , cte_hsales.datatype
    , coalesce(cte_xref.customer_as_sap, lpad(cte_hsales.customer_number, 10, '0')) as customer_number
    , cte_hsales.customer
    , cte_hsales.item
    , nvl(cte_hsales.item_number1,'') as item_number1
    , cte_hsales.qty
    , cte_hsales.sales
    , cte_hsales.cogs
    , cte_hsales.shpstate
    , cte_hsales.state
    , cte_hsales.company
    , cte_hsales.date
    , cte_hsales.year
    , cte_hsales.month
    , cte_hsales.ferg_or_non_ferg
    , cte_hsales.product_group
    , cte_hsales.brand_forecast
    , cte_hsales.customer_forecast
    , cte_hsales.universal_customer_name
    , cte_hsales.agency
    , cte_hsales.agency_temp
    , cte_hsales.region
    , cte_hsales.territory
    , cte_hsales.buying_group1
    , cte_hsales.original_zip
    , cte_hsales.program_level1
    , cte_hsales.channel
    , cte_hsales.msa
    , cte_hsales.sapcode
    , cte_hsales.month_week
    , cte_hsales.branch
    , cte_hsales.week_number
    , cte_hsales.buying_group2
    , cte_hsales.program_level2
    , nvl(cte_hsales.invoice_no,'') as invoice_no
    , cte_hsales.required_date
    , cte_hsales.order_date
    , cte_hsales.customer_key
    , cte_hsales.customer_description
    , cte_hsales.customersaleskey
    , cte_hsales.item_desc
    , cte_hsales.base_material_description
    , cte_hsales.item_number_temp
    , cte_hsales.item_number2
    , cte_hsales.material_key
    , cte_hsales.shipped_qty
    , cte_hsales.gross_sales_before_freight
    , cte_hsales.fp_fiscal_year
    , cte_hsales.unique_key
from cte_hsales
    left join cte_xref
        on lpad(cte_hsales.customer_number, 10, '0') = cte_xref.eclipse_id
