-- dim customer

with cte_hub_customer as (
    select * from {{ ref('hub_customer') }}
)

, cte_sat_customer_detail__emtk_ebs as (
    select * from {{ ref('sat_customer_detail__emtk_ebs') }}
)

, cte_sat_customer_detail__emtk_ebs__latest as (
    {{ generate_cte_satellite_latest(
        cte_name='cte_sat_customer_detail__emtk_ebs'
        ,hk_field='customer_hk') }}
)

, cte_sat_customer_detail__emtk_ebs__renamed as (
    select
        customer_hk
        , account_number
        , cust_account_id
        , party_id
        , request_id
        , program_application_id
        , program_id
        , program_update_date
        , attribute1
        , attribute2
        , attribute3
        , attribute4
        , attribute10
        , attribute11
        , attribute13
        , attribute15
        , attribute16
        , attribute17
        , attribute19
        , attribute20
        , orig_system_reference
        , status as customer_status
        , customer_class_code
        , freight_term
        , ship_via
        , payment_term_id
        , tax_header_level_flag
        , account_name as customer_account_name
        , creation_date as src_created_at
        , last_update_date as src_last_updated_at
        , load_dts as valid_from
    from cte_sat_customer_detail__emtk_ebs__latest
)

, cte_default as (
    select
        CAST(MD5_BINARY(-1) as BINARY(16)) as dim_customer_pk
        , null as customer_bk
        , null as sub_brand
        , null as account_number
        , null as cust_account_id
        , null as party_id
        , null as request_id
        , null as program_application_id
        , null as program_id
        , null as program_update_date
        , null as attribute1
        , null as attribute2
        , null as attribute3
        , null as attribute4
        , null as attribute10
        , null as attribute11
        , null as attribute13
        , null as attribute15
        , null as attribute16
        , null as attribute17
        , null as attribute19
        , null as attribute20
        , null as orig_system_reference
        , null as customer_status
        , null as customer_class_code
        , null as freight_term
        , null as ship_via
        , null as payment_term_id
        , null as tax_header_level_flag
        , null as customer_account_name
        , null as src_created_at
        , null as src_last_updated_at
        , TO_TIMESTAMP('1900-01-01') as valid_from

)

, cte_customer as (
    select
        hub.customer_hk as dim_customer_pk
        , hub.customer_bk
        , hub.brand
        , sat.account_number
        , sat.cust_account_id
        , sat.party_id
        , sat.request_id
        , sat.program_application_id
        , sat.program_id
        , sat.program_update_date
        , sat.attribute1
        , sat.attribute2
        , sat.attribute3
        , sat.attribute4
        , sat.attribute10
        , sat.attribute11
        , sat.attribute13
        , sat.attribute15
        , sat.attribute16
        , sat.attribute17
        , sat.attribute19
        , sat.attribute20
        , sat.orig_system_reference
        , sat.customer_status
        , sat.customer_class_code
        , sat.freight_term
        , sat.ship_via
        , sat.payment_term_id
        , sat.tax_header_level_flag
        , sat.customer_account_name
        , sat.src_created_at
        , sat.src_last_updated_at
        , sat.valid_from
    from cte_hub_customer as hub
        inner join cte_sat_customer_detail__emtk_ebs__renamed as sat
            on hub.customer_hk = sat.customer_hk
)

, cte_final as (
    select * from cte_customer
    union all
    select * from cte_default
)

select * from cte_final
