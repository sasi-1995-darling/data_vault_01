-- dim sales territory
/*
    NOTE - on 2024-06-05 - it was discovered that Emtek business users have an
    opposite understanding of "sales agencies" and "territories" from how
    they are stored in Oracle. The values stored in emtk_ebs_jtf.jtf_rs_salesreps
    are what they call "territories". The "sales agencies" are stored in emtk_ebs_ar.ra_territories.
    One sales agencie can have multiple territories.

    Eveutnally the raw_vault can get renamed, but just handling the swap
    here in the infomart for now.

*/
with cte_hub_sales_territory as (
    select * from {{ ref('hub_sales_agency') }}
)

, cte_sat_sales_territory_detail__emtk_ebs as (
    select * from {{ ref('sat_sales_agency_detail__emtk_ebs') }}
)

, cte_sat_sales_territory_detail__emtk_ebs__latest as (
    {{ generate_cte_satellite_latest(
        cte_name='cte_sat_sales_territory_detail__emtk_ebs'
        ,hk_field='sales_agency_hk') }}
)

--fixing names here: sales_agency >> territory
, cte_sat_sales_territory_detail__emtk_ebs__renamed as (
    select
        sales_agency_hk as sales_territory_hk
        , org_id as operating_unit_code
        , salesrep_number as territory_number
        , salesrep_id as src_system_id
        , resource_id
        , name as territory_name
        , start_date_active
        , end_date_active
        , email_address
        , creation_date as src_created_at
        , last_update_date as src_last_updated_at
        , load_dts as valid_from
    from cte_sat_sales_territory_detail__emtk_ebs__latest
)

, cte_sales_territory as (
    select
        hub.sales_agency_hk as dim_sales_territory_pk
        , hub.sales_agency_bk as sales_territory_bk
        , hub.brand
        , sat.operating_unit_code
        , sat.territory_number
        , sat.src_system_id
        , sat.resource_id
        , sat.territory_name
        , sat.start_date_active
        , sat.end_date_active
        , sat.email_address
        , sat.src_created_at
        , sat.src_last_updated_at
        , sat.valid_from
    from cte_hub_sales_territory as hub
        inner join cte_sat_sales_territory_detail__emtk_ebs__renamed as sat
            on hub.sales_agency_hk = sat.sales_territory_hk
)

, cte_default as (
    select
        CAST(MD5_BINARY(-1) as BINARY(16)) as dim_sales_territory_pk
        , null as sales_territory_bk
        , null as brand
        , null as operating_unit_code
        , null as territory_number
        , null as src_system_id
        , null as resource_id
        , null as territory_name
        , null as start_date_active
        , null as end_date_active
        , null as email_address
        , null as src_created_at
        , null as src_last_updated_at
        , TO_TIMESTAMP('1900-01-01') as valid_from
)

, cte_final as (
    select * from cte_sales_territory
    union all
    select * from cte_default
)

select * from cte_final
