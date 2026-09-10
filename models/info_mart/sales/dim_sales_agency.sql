-- dim sales agency
/*
    NOTE - on 2024-06-05 - it was discovered that Emtek business users have an
    opposite understanding of "sales agencies" and "territories" from how
    they are stored in Oracle. The values stored in emtk_ebs_jtf.jtf_rs_salesreps
    are what they call "territories". The "sales agencies" are stored in emtk_ebs_ar.ra_territories.
    One sales agencie can have multiple territories.

    Eveutnally the raw_vault can get renamed, but just handling the swap
    here in the infomart for now.

*/
with cte_hub_sales_agency as (
    select * from {{ ref('hub_sales_territory') }}
)

, cte_sat_sales_agency_detail__emtk_ebs as (
    select * from {{ ref('sat_sales_territory_detail__emtk_ebs') }}
)

, cte_sat_sales_agency_detail__emtk_ebs__latest as (
    {{ generate_cte_satellite_latest(
        cte_name='cte_sat_sales_agency_detail__emtk_ebs'
        ,hk_field='sales_territory_hk') }}
)

--fixing names here: territory >> sales_agency
, cte_sat_sales_agency_detail__emtk_ebs__renamed as (
    select
        sales_territory_hk as sales_agency_hk
        , segment1 as sales_agency_number
        , territory_id as src_system_id
        , name as sales_agency_name
        , description as sales_agency_description
        , creation_date as src_created_at
        , last_update_date as src_last_updated_at
        , load_dts as valid_from
    from cte_sat_sales_agency_detail__emtk_ebs__latest
)

, cte_sales_agency as (
    select
        hub.sales_territory_hk as dim_sales_agency_pk
        , hub.sales_territory_bk as sales_agency_bk
        , hub.brand
        , sat.sales_agency_number
        , sat.src_system_id
        , sat.sales_agency_name
        , sat.sales_agency_description
        , sat.src_created_at
        , sat.src_last_updated_at
        , sat.valid_from
    from cte_hub_sales_agency as hub
        inner join cte_sat_sales_agency_detail__emtk_ebs__renamed as sat
            on hub.sales_territory_hk = sat.sales_agency_hk
)

, cte_default as (
    select
        CAST(MD5_BINARY(-1) as BINARY(16)) as dim_sales_agency_pk
        , null as sales_agency_bk
        , null as brand
        , null as sales_agency_number
        , null as src_system_id
        , null as sales_agency_name
        , null as sales_agency_description
        , null as src_created_at
        , null as src_last_updated_at
        , TO_TIMESTAMP('1900-01-01') as valid_from
)

, cte_final as (
    select * from cte_sales_agency
    union all
    select * from cte_default
)

select * from cte_final
