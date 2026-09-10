/*
    LINK: Invoice Delivery
*/
with cte_base_delivery as (
    select
        delivery_detail_id::varchar as delivery_detail_id -- BK
        , source_header_number -- Join Key
    from {{ ref('base_delivery__emtk_ebs_sales') }}
)

, cte_base_invoice as (
    select
        org_id -- BK
        , trx_number -- BK invoice_no
        , interface_header_attribute1 -- BK "order_num" and Join Key
        , interface_header_attribute3 -- Join Key
    from {{ ref('base_invoice__emtk_ebs_sales') }}
)

, cte_wsh_delivery_assignments as (
    select
        delivery_detail_id -- Join Key
        , delivery_id -- Join Key
        , _fivetran_synced
    from {{ source('emtk_ebs_sales__wsh', 'wsh_delivery_assignments') }}
)

, cte_delivery_combined as (
    select
        wda.delivery_detail_id
        , wda.delivery_id
        , wda._fivetran_synced
        , bd.source_header_number
    from cte_base_delivery as bd
        inner join cte_wsh_delivery_assignments as wda
            on bd.delivery_detail_id = wda.delivery_detail_id

)

, cte_final as (
    select
        bi.org_id -- Invoice BK
        , bi.trx_number -- Invoice BK invoice_no
        , bi.interface_header_attribute1 -- Invoice BK "order_num" and Join Key
        , coalesce(dc.delivery_detail_id, '-1') as delivery_detail_id -- Delivery BK
        , dc._fivetran_synced
    from cte_base_invoice as bi
        left outer join cte_delivery_combined as dc
            on dc.source_header_number = try_to_number(bi.interface_header_attribute1)
                and dc.delivery_id = try_to_number(bi.interface_header_attribute3)
)

select * from cte_final
