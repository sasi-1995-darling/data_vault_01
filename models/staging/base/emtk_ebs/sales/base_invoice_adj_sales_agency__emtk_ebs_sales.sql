/*
    LINK: Invoice Adjustment - Sales Agency
*/
with cte_base_invoice_adj as (
    select
        org_id -- BK
        , trx_number -- BK, invoice adj number 
        , interface_header_attribute1 -- BK, order number
        , trx_date -- BK, tie breaker
        , primary_salesrep_id -- Join key
        , _fivetran_synced
    from {{ ref('base_invoice_adjustment__emtk_ebs_sales') }}
)

, cte_base_sales_agency as (
    select
        org_id -- BK
        , salesrep_number -- BK
        , salesrep_id -- Join Key
        , _fivetran_synced
    from {{ ref('base_sales_agency__emtk_ebs_sales') }}
)

, cte_final as (
    select
        bia.org_id as inva_org_id -- inv adj
        , bia.trx_number -- inv adj
        , bia.interface_header_attribute1 -- inv adj
        , bia.trx_date -- inv adj
        , coalesce(bsa.org_id, 101) as salea_org_id -- sales agency
        , coalesce(bsa.salesrep_number, '-1') as salesrep_number -- sales agency
        , bia._fivetran_synced
    from cte_base_invoice_adj as bia
    --invoice adjusment is the driving key
        left outer join cte_base_sales_agency as bsa
            on bia.primary_salesrep_id = bsa.salesrep_id
)

select * from cte_final
